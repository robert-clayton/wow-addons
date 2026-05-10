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
--   PLAYER_LOGIN + 5s   one-shot, gated on rosterEnabled
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

    -- Old "Roster module disabled" -> new rosterEnabled = false.
    if MC.db.rosterEnabled == nil then
        if MC.db.disabledModules and MC.db.disabledModules.roster then
            MC.db.rosterEnabled = false
        else
            MC.db.rosterEnabled = true
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

    if not (MC.db and MC.db.rosterEnabled) then return end
    -- Randomized 5-30s jitter to spread login storms in big guilds. A
    -- raid /reload wave with 30 players on the same fixed timer would
    -- flood guild chat with `r` responses; jitter gives the queue time
    -- to drain.
    local delay = 5 + math.random() * 25
    C_Timer.After(delay, function()
        -- Force-announce ourselves: clears the unchanged-hash guard so
        -- peers see us after our /reload even when our counts didn't move.
        MC.RosterForceBroadcast("GUILD")
        -- Also ask online peers to re-broadcast their counts. Without
        -- this, after /reload we only show whatever's in the saved file
        -- and never learn about peers whose counts haven't changed.
        if MC.Comms then MC.Comms:Send("r", "", "GUILD") end
    end)
end

-- Wire format helpers. Single-char codes keep messages compact.
local WIRE_KEY = {
    mounts      = "m",
    pets        = "p",
    toys        = "t",
    decorations = "d",
    recipes     = "c",  -- 'c' for crafting; 'r' is taken by rares
    rares       = "r",
    treasures   = "x",
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
local function BuildLocalCounts()
    local counts = {}
    local byExpansion = {}
    for _, m in ipairs(MC.modules) do
        local r = m.Scanner and m.Scanner.results
        if WIRE_KEY[m.key] and r then
            if m.key == "recipes" then
                -- Recipes' results table is keyed by skill-line and
                -- doesn't go through the expansion filter (yet), so
                -- learnedCount/total per skill-line is already
                -- account-wide and isn't sliced by expansion.
                local learned, total = 0, 0
                for _, sub in pairs(r) do
                    if type(sub) == "table" and sub.total then
                        learned = learned + (sub.learnedCount or 0)
                        total   = total + sub.total
                    end
                end
                if total > 0 then
                    counts[m.key] = { collected = learned, total = total }
                end
            else
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
-- and legacy count (L) per module. Recipes aggregate score across all
-- skill lines (each profession returns its own per-result score).
local function BuildScorePayload()
    local parts = {}
    for _, m in ipairs(MC.modules) do
        local r = m.Scanner and m.Scanner.results
        if WIRE_KEY[m.key] and r then
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
            parts[#parts + 1] = format("%s:%d:%d", WIRE_KEY[m.key], s, l)
        end
    end
    return table.concat(parts, ",")
end

-- Aggregate the local Collection Score for tooltip / display use.
-- Returns total, legacyCount, byModule, where byModule[modKey] =
-- { score = S, legacyCount = L }. Used by the title-bar display and
-- the /mc score command.
function MC.GetLocalScore()
    local byModule = {}
    local total, legacy = 0, 0
    for _, m in ipairs(MC.modules) do
        local r = m.Scanner and m.Scanner.results
        if WIRE_KEY[m.key] and r then
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
            byModule[m.key] = { score = s, legacyCount = l }
            total = total + s
            legacy = legacy + l
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
    local counts, byExpansion = BuildLocalCounts()
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

-- Broadcast, suppressed when our payload hasn't changed.
function MC.RosterBroadcastIfChanged(channel)
    channel = channel or "GUILD"
    if not (MC.db and MC.db.rosterEnabled) then return end
    if not mod.db or not mod.db.share then return end
    if not MC.Comms then return end

    local payload = BuildPayload()
    if payload == "" then return end

    local fullPayload = payload .. "|" .. GetClassToken() .. "|" .. (MC.version or "?")
    local h = cheapHash(fullPayload)
    if mod.db.lastBroadcast[channel] ~= h then
        mod.db.lastBroadcast[channel] = h
        MC.Comms:Send("u", fullPayload, channel)
        if channel == "GUILD" and mod.db.shareBNet and MC.Comms.BroadcastBNet then
            MC.Comms:BroadcastBNet("u", fullPayload)
        end
    end

    -- Per-expansion sub-totals: one 'e' message per expansion the
    -- player has data for. Hash-deduped per (channel, expansion) so
    -- expansions whose counts haven't changed don't re-broadcast.
    -- 1.7.x peers don't have an 'e' handler and silently drop these.
    mod.db.lastBroadcastE = mod.db.lastBroadcastE or {}
    mod.db.lastBroadcastE[channel] = mod.db.lastBroadcastE[channel] or {}
    for _, ep in ipairs(BuildExpansionPayloads()) do
        local eh = cheapHash(ep.payload)
        if mod.db.lastBroadcastE[channel][ep.expKey] ~= eh then
            mod.db.lastBroadcastE[channel][ep.expKey] = eh
            MC.Comms:Send("e", ep.payload, channel)
            if channel == "GUILD" and mod.db.shareBNet and MC.Comms.BroadcastBNet then
                MC.Comms:BroadcastBNet("e", ep.payload)
            end
        end
    end

    -- Collection Score: per-module score:legacyCount. Hash-deduped per
    -- channel. 1.8.x peers without an 's' handler silently drop.
    local scorePayload = BuildScorePayload()
    if scorePayload ~= "" then
        mod.db.lastBroadcastS = mod.db.lastBroadcastS or {}
        local sh = cheapHash(scorePayload)
        if mod.db.lastBroadcastS[channel] ~= sh then
            mod.db.lastBroadcastS[channel] = sh
            MC.Comms:Send("s", scorePayload, channel)
            if channel == "GUILD" and mod.db.shareBNet and MC.Comms.BroadcastBNet then
                MC.Comms:BroadcastBNet("s", scorePayload)
            end
        end
    end

    -- v2: also broadcast the per-item bitmap. Skip when disabled or
    -- before Bitmap:Init has run. SendBitmap / BroadcastBNetBitmap
    -- transparently chunk the payload when it exceeds the 250-byte
    -- wire limit (multi-expansion data will trigger this).
    if mod.db.shareItems and MC.Bitmap and MC.Bitmap.fingerprint then
        local bmp = MC.Bitmap:Build()
        if bmp then
            local fp = MC.Bitmap.fingerprint
            local bh = cheapHash(fp .. "|" .. bmp)
            if mod.db.lastBitmap[channel] ~= bh then
                mod.db.lastBitmap[channel] = bh
                MC.Comms:SendBitmap(fp, bmp, channel)
                if channel == "GUILD" and mod.db.shareBNet and MC.Comms.BroadcastBNetBitmap then
                    MC.Comms:BroadcastBNetBitmap(fp, bmp)
                end
            end
        end
    end
end

-- /mc roster announce: bypass the skip-if-unchanged guard.
function MC.RosterForceBroadcast(channel)
    channel = channel or "GUILD"
    if not MC.Comms then return end
    local payload = BuildPayload() .. "|" .. GetClassToken() .. "|" .. (MC.version or "?")
    if mod.db then mod.db.lastBroadcast[channel] = nil end
    MC.Comms:Send("u", payload, channel)

    -- Also force-resend per-expansion sub-totals.
    if mod.db and mod.db.lastBroadcastE then mod.db.lastBroadcastE[channel] = nil end
    for _, ep in ipairs(BuildExpansionPayloads()) do
        MC.Comms:Send("e", ep.payload, channel)
    end

    -- And the Collection Score.
    if mod.db and mod.db.lastBroadcastS then mod.db.lastBroadcastS[channel] = nil end
    local scorePayload = BuildScorePayload()
    if scorePayload ~= "" then
        MC.Comms:Send("s", scorePayload, channel)
    end
end

-- 30s debounce for scanner-finished hooks.
local broadcastPending = false
function MC.RosterDebouncedBroadcast()
    if broadcastPending then return end
    broadcastPending = true
    C_Timer.After(30, function()
        broadcastPending = false
        MC.RosterBroadcastIfChanged()
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
    if not MC.RosterDB then return end
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
    if not MC.RosterDB then return end
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
    if not MC.RosterDB then return end
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

local function OnRequestReceived(_, sender)
    -- Someone (probably running /mc roster sync) wants everyone to
    -- re-broadcast. Force-send our own update.
    MC.RosterForceBroadcast("GUILD")
end

local function OnBitmapReceived(payload, sender)
    if not (MC.RosterDB and MC.Bitmap) then return end
    local fp, bmp = strsplit("|", payload, 2)
    if not (fp and bmp) then return end
    -- Drop bitmaps from peers whose bit-layout doesn't match ours: their
    -- IDs would land at different bit positions and we'd report wrong
    -- ownership. They'll see the same and silently ignore ours.
    if fp ~= MC.Bitmap.fingerprint then return end
    local owned = MC.Bitmap:Decode(bmp)
    if not owned then return end

    -- Discard own echo
    local me = UnitName("player")
    local meRealm = GetRealmName():gsub("%s+", "")
    if sender == (me .. "-" .. meRealm) or sender == me then return end

    local rec = MC.RosterDB[sender] or {}
    rec.name = sender
    rec.bitmap = { fingerprint = fp, owned = owned, when = time() }
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
        if MC.db then MC.db.rosterEnabled = true end
        print(MC.PREFIX .. " Sharing turned ON.")
        if MC.RefreshPeerIndicator then MC.RefreshPeerIndicator() end
        MC.RosterForceBroadcast("GUILD")
    elseif arg == "off" then
        if MC.db then MC.db.rosterEnabled = false end
        print(MC.PREFIX .. " Sharing turned OFF.")
        if MC.RefreshPeerIndicator then MC.RefreshPeerIndicator() end
    elseif arg == "announce" then
        MC.RosterForceBroadcast("GUILD")
        print(MC.PREFIX .. " Sharing: broadcast sent to guild.")
    elseif arg == "sync" then
        if MC.Comms then
            MC.Comms:Send("r", "", "GUILD")
            print(MC.PREFIX .. " Sharing: requested updates from guild.")
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
