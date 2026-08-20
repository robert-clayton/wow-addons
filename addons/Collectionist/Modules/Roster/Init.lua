local _, MC = ...

-- Roster: track guildies + BNet friends running the addon and surface
-- their collection progress. Used to be a tab; now lives behind the
-- "X peers" indicator on the main panel and the Collection Inspector
-- popup.
--
-- Settings: MC.db.rosterEnabled (master on/off), MC.db.roster (sub-
-- toggles for share/items/bnet, plus skip-if-unchanged caches).
--
-- Broadcasts:
--   PLAYER_LOGIN + jitter   one-way snapshot, gated on explicit consent
--   Counts changed      debounced 30s, suppressed when payload hash matches
--   /mc roster announce force broadcast
--   /mc roster sync     ask peers to re-broadcast

-- Standin so the rest of the file can keep referring to mod.db.
-- RosterInit fills it in at ADDON_LOADED.
local mod = { db = nil }
MC.Roster = mod

local DEFAULTS = {
    share          = true,            -- Broadcast our counts to guild
    shareParty     = false,           -- (Reserved for future use)
    shareItems     = true,            -- Broadcast per-item bitmap (v2)
    shareBNet      = true,            -- Broadcast to BNet WoW friends (v2)
    autoForgetDays = 30,              -- Garbage-collect peers older than this
    lastBroadcast  = {},              -- channel -> last hash sent
    lastBitmap     = {},              -- channel -> last bitmap fingerprint
}

function MC.RosterCanShare()
    return MC.db and MC.db.rosterEnabled == true
       and mod.db and mod.db.share == true
       and MC.Comms ~= nil
end

local pendingHashes = {}
local broadcastPending = false
local broadcastToken = 0

function MC.RosterCancelPendingBroadcasts()
    broadcastToken = broadcastToken + 1
    broadcastPending = false
    wipe(pendingHashes)
end

-- Peer data is fresh enough to skip an automatic sync request when any
-- peer record was heard from inside this window.
local FRESH_PEER_SECONDS = 3 * 86400
local lastAutoRequestAt = 0

local function HasFreshPeerData()
    if not MC.RosterDB then return false end
    local cutoff = time() - FRESH_PEER_SECONDS
    for name, rec in pairs(MC.RosterDB) do
        if type(name) == "string" and name:sub(1, 1) ~= "_"
           and type(rec) == "table"
           and rec.lastSeen and rec.lastSeen >= cutoff then
            return true
        end
    end
    return false
end

-- Ask guild peers to re-broadcast their counts. Peers' broadcasts are
-- hash-deduped, so without ever asking, a fresh install sees nobody until
-- someone's counts change. Automatic callers pass force=false: the request
-- only goes out when the peer list is empty or stale, so fresh installs
-- and returning players sync while guild-wide /reload waves stay quiet
-- (everyone in the wave still has minutes-old peer records). Responders
-- coalesce bursts behind their own 60s cooldown.
function MC.RosterRequestSync(force)
    if not (MC.RosterCanShare() and MC.Comms) then return false end
    if not force then
        if HasFreshPeerData() then return false end
        local now = time()
        if now - lastAutoRequestAt < 600 then return false end
        lastAutoRequestAt = now
    end
    return MC.Comms:Send("r", "", "GUILD")
end

function MC.SetRosterEnabled(enabled, announce)
    if not MC.db then return end
    MC.db.rosterEnabled = enabled and true or false
    if not enabled then
        MC.RosterCancelPendingBroadcasts()
        if MC.Comms and MC.Comms.ClearQueue then MC.Comms:ClearQueue() end
    elseif announce and MC.RosterForceBroadcast then
        MC.RosterForceBroadcast("GUILD")
        -- First-enable is the fresh-install case: ask peers to introduce
        -- themselves (no-op when we already have fresh peer data).
        MC.RosterRequestSync(false)
    end
    if MC.RefreshPeerIndicator then MC.RefreshPeerIndicator() end
end

-- Wired up from Core.lua at ADDON_LOADED.
function MC.RosterInit()
    if not MC.db then return end

    MC.db.roster = MC.db.roster or {}
    for k, v in pairs(DEFAULTS) do
        if MC.db.roster[k] == nil then
            MC.db.roster[k] = type(v) == "table" and CopyTable(v) or v
        end
    end
    mod.db = MC.db.roster

    -- Old "Roster module disabled" -> new rosterEnabled = false. Fresh
    -- installs remain opted out until onboarding records explicit consent;
    -- existing installs that already completed onboarding retain sharing.
    if MC.db.rosterEnabled == nil then
        if MC.db.disabledModules and MC.db.disabledModules.roster then
            MC.db.rosterEnabled = false
        else
            local consented = MC.db._onboardingShown
                           or (CollectionistDB and CollectionistDB._onboardingShown)
            MC.db.rosterEnabled = consented and true or false
        end
    end
end

-- Wired up from Core.lua at PLAYER_LOGIN.
function MC.RosterPostLogin()
    -- Always run cleanup so a user who briefly had the feature on
    -- ends up with a clean DB even if they later turn it off.
    if MC.RosterDB then
        for k, v in pairs(MC.RosterDB) do
            if type(k) == "string" and k:sub(1, 1) == "_" then
                -- Reserved meta key (e.g. _bnetCache) — leave alone.
            elseif type(k) ~= "string" or not k:find("-", 1, true) then
                MC.RosterDB[k] = nil
            elseif type(v) == "table" and (not v.name or v.name == "") then
                -- Back-fill name on records stored before the field was set,
                -- or where it was persisted as an empty string.
                v.name = k
            end
        end
    end

    -- Build the BNet name → account-ID cache from currently online
    -- friends. Persisted across sessions in CollectionistRosterDB
    -- so alts seen in earlier sessions can still be deduped.
    if MC.RosterRefreshBnetCache then MC.RosterRefreshBnetCache() end

    if not MC.RosterCanShare() then return end
    -- Randomized announcement. Login only asks peers for a reply when our
    -- peer data is missing or stale (see RosterRequestSync), so /reload
    -- waves in large guilds stay one-way instead of going quadratic.
    local delay = 15 + math.random() * 30
    C_Timer.After(delay, function()
        if not MC.RosterCanShare() then return end
        MC.RosterForceBroadcast("GUILD")
        -- After the force broadcast: it clears the outbound queue, which
        -- would cancel a request queued before it.
        MC.RosterRequestSync(false)
    end)
end

-- Wire format helpers. Single-char codes keep messages compact.
local WIRE_KEY = {
    mounts       = "m",
    pets         = "p",
    toys         = "t",
    decorations  = "d",
    recipes      = "c",  -- 'c' for crafting; 'r' is taken by rares
    rares        = "r",
    treasures    = "x",
    achievements = "a",
}

-- Per-module {collected, total} from the live scanners. Shared by the
-- wire payload and the "Me" entry rendered in the Inspector.
--
-- Returns two tables:
--   counts        — module -> { collected, total }                    (account-wide)
--   byExpansion   — expKey -> module -> { collected, total }          (sliced)
--
-- The account-wide counts come from r.totalAll / r.collectedCountAll
-- so peers broadcast consistent account-wide totals regardless of
-- their local expansion filter. The byExpansion slice feeds the new
-- 'e' wire messages and the Inspector's filter-aware peer columns.
local function BuildLocalCounts(includePartial)
    local counts = {}
    local byExpansion = {}
    for _, m in ipairs(MC.modules) do
        local r = m.Scanner and m.Scanner.results
        if WIRE_KEY[m.key] and r then
            if m.key == "recipes" then
                -- Recipes' results table is keyed by skill-line. Visible
                -- counters follow the expansion filter, while the All fields
                -- remain stable for account-wide sharing.
                local learned, total = 0, 0
                for _, sub in pairs(r) do
                    if type(sub) == "table" and (sub.totalAll or sub.total) then
                        learned = learned + (sub.learnedCountAll or sub.learnedCount or 0)
                        total   = total + (sub.totalAll or sub.total)
                    end
                end
                if total > 0 then
                    counts[m.key] = { collected = learned, total = total }
                end
            elseif includePartial or not r._partial then
                -- A partial snapshot (rows still streaming) would put
                -- shrunken counts on the wire; hold the module out of
                -- payloads until its scan comes back clean or settles.
                -- The next debounced broadcast after that picks it up.
                local total = r.totalAll or r.total
                if total and total > 0 then
                    counts[m.key] = {
                        collected = r.collectedCountAll or r.collectedCount or 0,
                        total     = total,
                    }
                end
                if r.byExpansion then
                    for expKey, b in pairs(r.byExpansion) do
                        if b.total and b.total > 0 then
                            byExpansion[expKey] = byExpansion[expKey] or {}
                            byExpansion[expKey][m.key] = {
                                collected = b.collected or 0,
                                total     = b.total,
                            }
                        end
                    end
                end
            end
        end
    end
    return counts, byExpansion
end

-- Build the count-summary payload from current scanner results.
local function BuildPayload()
    local counts = BuildLocalCounts()
    local parts = {}
    for _, m in ipairs(MC.modules) do
        local c = counts[m.key]
        if c then
            parts[#parts + 1] = format("%s:%d/%d", WIRE_KEY[m.key], c.collected, c.total)
        end
    end
    return table.concat(parts, ",")
end

-- Build the Collection Score payload: "m:S:L,p:S:L,...". Score (S)
-- and legacy count (L) per module. Derived from MC.GetLocalScore so
-- the broadcast and the local /mc score readout can never disagree;
-- iterate MC.modules to keep the parts in a stable wire order.
local function BuildScorePayload()
    local _, _, byModule = MC.GetLocalScore(true)
    local parts = {}
    for _, m in ipairs(MC.modules) do
        local b = byModule[m.key]
        if b then
            parts[#parts + 1] = format("%s:%d:%d", WIRE_KEY[m.key], b.score, b.legacyCount)
        end
    end
    return table.concat(parts, ",")
end

-- Aggregate the local Collection Score for tooltip / display use.
-- Returns total, legacyCount, byModule, where byModule[modKey] =
-- { score = S, legacyCount = L }. Used by the title-bar display and
-- the /mc score command. excludePartial (wire payloads) leaves out
-- modules whose snapshot is partial or that never scanned, so peers
-- aren't sent transient zero/shrunken scores.
-- Collection Score counts collectibles only. Achievements are excluded:
-- there are three times as many of them as the next-largest tracker AND
-- they carried the highest average weight, so they were 59% of the
-- possible score — the number described achievement progress more than
-- it described a collection. Excluded modules are skipped outright; no
-- achievement tally is computed, carried or displayed anywhere. The
-- game's own achievement UI is where that number belongs.
local SCORE_EXCLUDED = { achievements = true }

function MC.GetLocalScore(excludePartial)
    local byModule = {}
    local total, legacy = 0, 0
    for _, m in ipairs(MC.modules) do
        local r = m.Scanner and m.Scanner.results
        if WIRE_KEY[m.key] and r
           and not (excludePartial and (r._partial or next(r) == nil)) then
            local s, l = 0, 0
            if m.key == "recipes" then
                for _, sub in pairs(r) do
                    if type(sub) == "table" and sub.score then
                        s = s + sub.score
                    end
                end
            else
                s = r.score or 0
                l = r.legacyCount or 0
            end
            if not SCORE_EXCLUDED[m.key] then
                byModule[m.key] = { score = s, legacyCount = l }
                total = total + s
                legacy = legacy + l
            end
        end
    end
    return total, legacy, byModule
end

-- One per-expansion 'e' payload: "<expKey>:m:N/M,p:N/M,...". Returned
-- as a list (one entry per expansion the player has data for).
local function BuildExpansionPayloads()
    local _, byExpansion = BuildLocalCounts()
    local out = {}
    for expKey, modCounts in pairs(byExpansion) do
        local parts = {}
        for _, m in ipairs(MC.modules) do
            local c = modCounts[m.key]
            if c then
                parts[#parts + 1] = format("%s:%d/%d", WIRE_KEY[m.key], c.collected, c.total)
            end
        end
        if #parts > 0 then
            out[#out + 1] = { expKey = expKey, payload = expKey .. ":" .. table.concat(parts, ",") }
        end
    end
    return out
end

-- Local player rendered into a peer-shaped record so the Inspector can
-- treat us the same as everyone else.
function MC.GetMeRosterEntry()
    local _, classToken = UnitClass("player")
    local me = UnitName("player")
    local meRealm = (GetRealmName() or ""):gsub("%s+", "")
    -- includePartial: the local "Me" row should show best-known numbers
    -- even while a scan is still settling, matching the tab UI.
    local counts, byExpansion = BuildLocalCounts(true)
    return {
        name              = me .. "-" .. meRealm,
        class             = classToken or "UNKNOWN",
        version           = MC.version,
        counts            = counts,
        countsByExpansion = byExpansion,
        lastSeen          = time(),
        isMe              = true,
    }
end

local function GetClassToken()
    local _, classToken = UnitClass("player")
    return classToken or "UNKNOWN"
end

-- "Did our payload change?" hash. Cheap, not collision-safe.
local function cheapHash(s)
    local h = 0
    for i = 1, #s do
        h = (h * 31 + s:byte(i)) % 2147483647
    end
    return h
end

-- Queue one payload and write its dedupe hash only after the game API has
-- accepted it. A failed/paused send therefore remains eligible for retry.
local function QueueChanged(cache, cacheKey, hash, pendingKey, sendFn)
    if cache[cacheKey] == hash or pendingHashes[pendingKey] == hash then return false end
    pendingHashes[pendingKey] = hash
    local queued = sendFn(function(sent)
        if pendingHashes[pendingKey] == hash then pendingHashes[pendingKey] = nil end
        if sent then
            cache[cacheKey] = hash
        elseif MC.RosterCanShare() then
            MC.RosterDebouncedBroadcast(30)
        end
    end, pendingKey)
    if not queued and pendingHashes[pendingKey] == hash then
        pendingHashes[pendingKey] = nil
    end
    return queued and true or false
end

local function Destinations(channel)
    local out = {
        {
            key = channel,
            send = function(sub, payload, callback, queueKey)
                return MC.Comms:Send(sub, payload, channel, nil, callback, queueKey)
            end,
            sendBitmap = function(fp, payload, callback, queueKey)
                return MC.Comms:SendBitmap(fp, payload, channel, callback, queueKey)
            end,
        },
    }
    if channel == "GUILD" and mod.db.shareBNet and MC.Comms.BroadcastBNet then
        out[#out + 1] = {
            key = "BNET",
            send = function(sub, payload, callback, queueKey)
                return MC.Comms:BroadcastBNet(sub, payload, callback, queueKey)
            end,
            sendBitmap = function(fp, payload, callback, queueKey)
                return MC.Comms:BroadcastBNetBitmap(fp, payload, callback, queueKey)
            end,
        }
    end
    return out
end

-- Broadcast a complete state snapshot, suppressed stream-by-stream when
-- nothing changed. Guild and Battle.net keep independent delivery hashes.
function MC.RosterBroadcastIfChanged(channel)
    channel = channel or "GUILD"
    if not MC.RosterCanShare() then return false end

    local payload = BuildPayload()
    if payload == "" then return false end
    local destinations = Destinations(channel)
    local queuedAny = false

    local fullPayload = payload .. "|" .. GetClassToken() .. "|" .. (MC.version or "?")
    local h = cheapHash(fullPayload)
    for _, dest in ipairs(destinations) do
        local d = dest
        queuedAny = QueueChanged(mod.db.lastBroadcast, d.key, h,
            "u:" .. d.key,
            function(callback, queueKey)
                return d.send("u", fullPayload, callback, queueKey)
            end) or queuedAny
    end

    mod.db.lastBroadcastE = mod.db.lastBroadcastE or {}
    for _, ep in ipairs(BuildExpansionPayloads()) do
        local expansion = ep
        local eh = cheapHash(expansion.payload)
        for _, dest in ipairs(destinations) do
            local d = dest
            mod.db.lastBroadcastE[d.key] = mod.db.lastBroadcastE[d.key] or {}
            queuedAny = QueueChanged(mod.db.lastBroadcastE[d.key], expansion.expKey, eh,
                "e:" .. d.key .. ":" .. expansion.expKey,
                function(callback, queueKey)
                    return d.send("e", expansion.payload, callback, queueKey)
                end) or queuedAny
        end
    end

    local scorePayload = BuildScorePayload()
    if scorePayload ~= "" then
        mod.db.lastBroadcastS = mod.db.lastBroadcastS or {}
        local sh = cheapHash(scorePayload)
        for _, dest in ipairs(destinations) do
            local d = dest
            queuedAny = QueueChanged(mod.db.lastBroadcastS, d.key, sh,
                "s:" .. d.key,
                function(callback, queueKey)
                    return d.send("s", scorePayload, callback, queueKey)
                end) or queuedAny
        end
    end

    if mod.db.shareItems and MC.Bitmap and MC.Bitmap.fingerprint then
        local bmp = MC.Bitmap:Build()
        if bmp then
            local fp = MC.Bitmap.fingerprint
            local bh = cheapHash(fp .. "|" .. bmp)
            for _, dest in ipairs(destinations) do
                local d = dest
                queuedAny = QueueChanged(mod.db.lastBitmap, d.key, bh,
                    "b:" .. d.key,
                    function(callback, queueKey)
                        return d.sendBitmap(fp, bmp, callback, queueKey)
                    end) or queuedAny
            end
        end
    end
    return queuedAny
end

-- /mc sharing announce: clear delivery hashes, then use the same complete
-- snapshot path as automatic updates. Privacy gates still apply.
function MC.RosterForceBroadcast(channel)
    channel = channel or "GUILD"
    if not MC.RosterCanShare() then return false end
    if MC.Comms.ClearQueue then MC.Comms:ClearQueue() end
    MC.RosterCancelPendingBroadcasts()
    mod.db.lastBroadcast[channel] = nil
    mod.db.lastBroadcast.BNET = nil
    mod.db.lastBitmap[channel] = nil
    mod.db.lastBitmap.BNET = nil
    mod.db.lastBroadcastS = mod.db.lastBroadcastS or {}
    mod.db.lastBroadcastS[channel] = nil
    mod.db.lastBroadcastS.BNET = nil
    mod.db.lastBroadcastE = mod.db.lastBroadcastE or {}
    mod.db.lastBroadcastE[channel] = nil
    mod.db.lastBroadcastE.BNET = nil
    return MC.RosterBroadcastIfChanged(channel)
end

-- Debounce scanner-finished hooks into one state snapshot.
function MC.RosterDebouncedBroadcast(delay)
    if not MC.RosterCanShare() or broadcastPending then return end
    broadcastPending = true
    broadcastToken = broadcastToken + 1
    local token = broadcastToken
    C_Timer.After(delay or 30, function()
        if token ~= broadcastToken then return end
        broadcastPending = false
        if MC.RosterCanShare() then MC.RosterBroadcastIfChanged() end
    end)
end

-- Inbound handlers
local function ParseUpdate(payload)
    -- payload: "m:47/62,p:30/82,...|CLASS|version"
    local counts, class, version = strsplit("|", payload, 3)
    local result = { class = class or "UNKNOWN", version = version or "?", counts = {} }
    for code, n, total in (counts or ""):gmatch("(%a):(%d+)/(%d+)") do
        for modKey, c in pairs(WIRE_KEY) do
            if c == code then
                result.counts[modKey] = {
                    collected = tonumber(n) or 0,
                    total     = tonumber(total) or 0,
                }
            end
        end
    end
    return result
end

local function OnUpdateReceived(payload, sender)
    if not (MC.RosterDB and MC.db and MC.db.rosterEnabled) then return end
    local parsed = ParseUpdate(payload)
    if not parsed.counts or next(parsed.counts) == nil then return end

    -- Discard our own echo (some realms reflect guild messages back).
    local me = UnitName("player")
    local meRealm = GetRealmName():gsub("%s+", "")
    local myKey = me .. "-" .. meRealm
    if sender == myKey or sender == me then return end

    -- Merge into existing record so accumulated fields (countsByExpansion
    -- from prior 'e' messages, bitmap from 'b' messages) survive a
    -- subsequent 'u' broadcast.
    local rec = MC.RosterDB[sender] or {}
    rec.name     = sender
    rec.class    = parsed.class
    rec.version  = parsed.version
    rec.counts   = parsed.counts
    rec.lastSeen = time()
    MC.RosterDB[sender] = rec

    if MC.RefreshPeerPanel then MC.RefreshPeerPanel() end
    if MC.RefreshPeerIndicator then MC.RefreshPeerIndicator() end
end

-- 'e' payload: "<expKey>:m:N/M,p:N/M,...". Stored on the peer record
-- under .countsByExpansion[expKey][modKey] = { collected, total }.
-- The Inspector reads this when its filter is set to a specific
-- expansion; otherwise it falls back to the account-wide .counts.
local function OnExpansionUpdateReceived(payload, sender)
    if not (MC.RosterDB and MC.db and MC.db.rosterEnabled) then return end
    local expKey, rest = strsplit(":", payload, 2)
    if not (expKey and rest and expKey ~= "" and rest ~= "") then return end

    -- Drop unknown expansion keys so a malicious or buggy peer can't
    -- pollute our table with arbitrary keys.
    if not (MC.EXPANSION_BY_KEY and MC.EXPANSION_BY_KEY[expKey]) then return end

    -- Drop our own echo.
    local me = UnitName("player")
    local meRealm = (GetRealmName() or ""):gsub("%s+", "")
    local myKey = me .. "-" .. meRealm
    if sender == myKey or sender == me then return end

    local rec = MC.RosterDB[sender] or { name = sender }
    rec.countsByExpansion = rec.countsByExpansion or {}
    local slice = {}
    for code, n, total in (rest or ""):gmatch("(%a):(%d+)/(%d+)") do
        for modKey, c in pairs(WIRE_KEY) do
            if c == code then
                slice[modKey] = {
                    collected = tonumber(n) or 0,
                    total     = tonumber(total) or 0,
                }
            end
        end
    end
    rec.countsByExpansion[expKey] = slice
    rec.lastSeen = time()
    MC.RosterDB[sender] = rec

    if MC.RefreshPeerPanel then MC.RefreshPeerPanel() end
end

-- 's' payload: "m:S:L,p:S:L,...". Stored on peer.score[modKey] =
-- { score, legacyCount } and aggregated to peer.totalScore /
-- peer.totalLegacyCount for at-a-glance access.
local function OnScoreReceived(payload, sender)
    if not (MC.RosterDB and MC.db and MC.db.rosterEnabled) then return end
    if not (payload and payload ~= "") then return end

    -- Drop our own echo.
    local me = UnitName("player")
    local meRealm = (GetRealmName() or ""):gsub("%s+", "")
    local myKey = me .. "-" .. meRealm
    if sender == myKey or sender == me then return end

    local rec = MC.RosterDB[sender] or { name = sender }
    local score = {}
    local total, legacy = 0, 0
    for code, s, l in (payload):gmatch("(%a):(%d+):(%d+)") do
        for modKey, c in pairs(WIRE_KEY) do
            if c == code then
                local sn, ln = tonumber(s) or 0, tonumber(l) or 0
                score[modKey] = { score = sn, legacyCount = ln }
                total = total + sn
                legacy = legacy + ln
            end
        end
    end
    rec.score             = score
    rec.totalScore        = total
    rec.totalLegacyCount  = legacy
    rec.lastSeen          = time()
    MC.RosterDB[sender] = rec

    if MC.RefreshPeerPanel then MC.RefreshPeerPanel() end
end

local lastRequestResponseAt = 0
local requestResponsePending = false
local function OnRequestReceived(_, sender)
    if not MC.RosterCanShare() or requestResponsePending then return end
    local now = time()
    -- A single global cooldown coalesces simultaneous sync requests from
    -- multiple peers. Jitter keeps legitimate manual syncs from aligning.
    if now - lastRequestResponseAt < 60 then return end
    requestResponsePending = true
    C_Timer.After(2 + math.random() * 6, function()
        requestResponsePending = false
        if not MC.RosterCanShare() then return end
        lastRequestResponseAt = time()
        MC.RosterForceBroadcast("GUILD")
    end)
end

local function OnBitmapReceived(payload, sender, _, generation)
    if not (MC.RosterDB and MC.Bitmap and MC.db and MC.db.rosterEnabled) then return end
    local fp, bmp = strsplit("|", payload, 2)
    if not (fp and bmp) then return end
    -- Drop bitmaps from peers whose bit-layout doesn't match ours: their
    -- IDs would land at different bit positions and we'd report wrong
    -- ownership. They'll see the same and silently ignore ours.
    if fp ~= MC.Bitmap.fingerprint then return end
    -- Discard own echo
    local me = UnitName("player")
    local meRealm = GetRealmName():gsub("%s+", "")
    if sender == (me .. "-" .. meRealm) or sender == me then return end

    local rec = MC.RosterDB[sender] or {}
    local generationStamp = generation
        and tonumber((generation:match("^(%d+)%-"))) or nil
    local priorStamp = rec.bitmap and rec.bitmap.generationStamp
    if generationStamp and priorStamp then
        if generationStamp < priorStamp then return end
        if generationStamp == priorStamp
           and generation <= (rec.bitmap.generation or "") then return end
    end

    local owned = MC.Bitmap:Decode(bmp)
    if not owned then return end

    rec.name = sender
    rec.bitmap = {
        fingerprint = fp,
        owned = owned,
        when = time(),
        generation = generation,
        generationStamp = generationStamp,
    }
    rec.lastSeen = time()
    MC.RosterDB[sender] = rec
end

if MC.Comms then
    -- GUILD channel
    MC.Comms:RegisterPrefix("GUILD", "u", OnUpdateReceived)
    MC.Comms:RegisterPrefix("GUILD", "e", OnExpansionUpdateReceived)
    MC.Comms:RegisterPrefix("GUILD", "s", OnScoreReceived)
    MC.Comms:RegisterPrefix("GUILD", "r", OnRequestReceived)
    MC.Comms:RegisterPrefix("GUILD", "b", OnBitmapReceived)
    -- BNET friends — same handlers, just routed from BNet
    MC.Comms:RegisterPrefix("BNET", "u", OnUpdateReceived)
    MC.Comms:RegisterPrefix("BNET", "e", OnExpansionUpdateReceived)
    MC.Comms:RegisterPrefix("BNET", "s", OnScoreReceived)
    MC.Comms:RegisterPrefix("BNET", "r", OnRequestReceived)
    MC.Comms:RegisterPrefix("BNET", "b", OnBitmapReceived)
end

--------------------------------------------------------------------------
-- Garbage-collect peers we haven't heard from in a while.
--------------------------------------------------------------------------
function MC.RosterPrune()
    if not MC.RosterDB or not mod.db then return end
    local cutoff = time() - (mod.db.autoForgetDays or 30) * 86400
    for name, rec in pairs(MC.RosterDB) do
        if type(name) == "string" and name:sub(1, 1) ~= "_"
           and type(rec) == "table" and rec.lastSeen and rec.lastSeen < cutoff then
            MC.RosterDB[name] = nil
        end
    end
end

--------------------------------------------------------------------------
-- BNet alt-dedup cache. Maps "Char-Realm" → bnetAccountID for any
-- character we've ever seen attached to a BNet friend's account.
-- Persists in CollectionistRosterDB._bnetCache so alts seen in
-- prior sessions still dedupe even when offline now.
--------------------------------------------------------------------------
function MC.RosterRefreshBnetCache()
    if not MC.RosterDB then return end
    MC.RosterDB._bnetCache = MC.RosterDB._bnetCache or {}
    if not (BNGetNumFriends and C_BattleNet and C_BattleNet.GetFriendAccountInfo) then return end
    local total = BNGetNumFriends()
    for i = 1, total do
        local acct = C_BattleNet.GetFriendAccountInfo(i)
        if acct and acct.bnetAccountID and acct.gameAccountInfo then
            local g = acct.gameAccountInfo
            if g.characterName and g.realmName and g.clientProgram == "WoW" then
                local key = g.characterName .. "-" .. g.realmName:gsub("%s+", "")
                MC.RosterDB._bnetCache[key] = acct.bnetAccountID
            end
        end
    end
end

-- Wipe peer history but keep the bnet alt cache (it's not personal
-- data; rebuilding it on next login is wasted work).
function MC.RosterClearHistory()
    if not MC.RosterDB then return end
    for k in pairs(MC.RosterDB) do
        if type(k) ~= "string" or k:sub(1, 1) ~= "_" then
            MC.RosterDB[k] = nil
        end
    end
    if mod.db then
        mod.db.lastBroadcast = {}
        mod.db.lastBitmap    = {}
        mod.db.lastBroadcastE = {}
        mod.db.lastBroadcastS = {}
    end
    if MC.RefreshPeerIndicator then MC.RefreshPeerIndicator() end
    if MC.RefreshPeerPanel    then MC.RefreshPeerPanel()    end
end

-- /mc roster <subcommand> dispatcher.
function MC.RosterSlashHandler(arg)
    arg = (arg or ""):lower()
    if arg == "" or arg == "status" then
        local count = 0
        if MC.RosterDB then
            for k, v in pairs(MC.RosterDB) do
                if type(k) == "string" and k:sub(1, 1) ~= "_" and type(v) == "table" then
                    count = count + 1
                end
            end
        end
        print(format("%s Sharing: %s, %d peer%s tracked.",
            MC.PREFIX,
            (MC.db and MC.db.rosterEnabled) and "ON" or "OFF",
            count, count == 1 and "" or "s"))
    elseif arg == "on" then
        MC.SetRosterEnabled(true, true)
        print(MC.PREFIX .. " Sharing turned ON.")
    elseif arg == "off" then
        MC.SetRosterEnabled(false)
        print(MC.PREFIX .. " Sharing turned OFF.")
    elseif arg == "announce" then
        if MC.RosterForceBroadcast("GUILD") then
            print(MC.PREFIX .. " Sharing: broadcast queued for guild and enabled friends.")
        else
            print(MC.PREFIX .. " Sharing is off or no collection snapshot is ready.")
        end
    elseif arg == "sync" then
        if MC.RosterRequestSync(true) then
            print(MC.PREFIX .. " Sharing: requested updates from guild.")
        else
            print(MC.PREFIX .. " Turn Sharing on before requesting updates.")
        end
    elseif arg == "prune" then
        MC.RosterPrune()
        print(MC.PREFIX .. " Sharing: pruned stale peers.")
        if MC.RefreshPeerIndicator then MC.RefreshPeerIndicator() end
    elseif arg == "clear" then
        MC.RosterClearHistory()
        print(MC.PREFIX .. " Sharing: cleared.")
    else
        print(MC.PREFIX .. " /mc sharing on|off|announce|sync|prune|clear|status")
    end
end
