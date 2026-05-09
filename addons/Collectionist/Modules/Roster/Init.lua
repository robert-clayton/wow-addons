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
local function BuildLocalCounts()
    local counts = {}
    for _, m in ipairs(MC.modules) do
        local r = m.Scanner and m.Scanner.results
        if WIRE_KEY[m.key] and r and r.total and r.total > 0 then
            if m.key == "recipes" then
                -- Recipes' results table is keyed by skill-line.
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
                counts[m.key] = {
                    collected = r.collectedCount or 0,
                    total     = r.total,
                }
            end
        end
    end
    return counts
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

-- Local player rendered into a peer-shaped record so the Inspector can
-- treat us the same as everyone else.
function MC.GetMeRosterEntry()
    local _, classToken = UnitClass("player")
    local me = UnitName("player")
    local meRealm = (GetRealmName() or ""):gsub("%s+", "")
    return {
        name     = me .. "-" .. meRealm,
        class    = classToken or "UNKNOWN",
        version  = MC.version,
        counts   = BuildLocalCounts(),
        lastSeen = time(),
        isMe     = true,
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

    -- v2: also broadcast the per-item bitmap. Skip when disabled or
    -- before Bitmap:Init has run.
    if mod.db.shareItems and MC.Bitmap and MC.Bitmap.fingerprint then
        local bmp = MC.Bitmap:Build()
        if bmp then
            local bmpPayload = MC.Bitmap.fingerprint .. "|" .. bmp
            local bh = cheapHash(bmpPayload)
            if mod.db.lastBitmap[channel] ~= bh then
                mod.db.lastBitmap[channel] = bh
                MC.Comms:Send("b", bmpPayload, channel)
                if channel == "GUILD" and mod.db.shareBNet and MC.Comms.BroadcastBNet then
                    MC.Comms:BroadcastBNet("b", bmpPayload)
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

    MC.RosterDB[sender] = {
        name     = sender,
        class    = parsed.class,
        version  = parsed.version,
        counts   = parsed.counts,
        lastSeen = time(),
    }

    if MC.RefreshPeerPanel then MC.RefreshPeerPanel() end
    if MC.RefreshPeerIndicator then MC.RefreshPeerIndicator() end
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
    MC.Comms:RegisterPrefix("GUILD", "r", OnRequestReceived)
    MC.Comms:RegisterPrefix("GUILD", "b", OnBitmapReceived)
    -- BNET friends — same handlers, just routed from BNet
    MC.Comms:RegisterPrefix("BNET", "u", OnUpdateReceived)
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
