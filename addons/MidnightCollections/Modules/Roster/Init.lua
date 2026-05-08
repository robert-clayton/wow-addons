local _, MC = ...

--------------------------------------------------------------------------
-- Roster: tracks guildies who run MidnightCollections and surfaces their
-- per-module collection counts. v1 broadcasts only count summaries; v2
-- adds a bitmap of which specific items each player owns.
--
-- Broadcast triggers:
--   * PLAYER_LOGIN + 5s — once per session
--   * Any module's count changes — debounced 30s, suppressed if the
--     hash of our outbound payload hasn't changed since last send
--   * /mc roster announce — manual force-broadcast
--   * /mc roster sync — request peers re-broadcast theirs
--------------------------------------------------------------------------

local mod = MC.RegisterModule("roster", {
    label    = "Roster",
    icon     = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend",
    order    = 8,
    -- Roster is not a collectible tracker; skip collectedKey/Label.
    defaults = {
        share          = true,            -- Broadcast our counts to guild
        shareParty     = false,           -- (Reserved for future use)
        shareItems     = true,            -- Broadcast per-item bitmap (v2)
        shareBNet      = true,            -- Broadcast to BNet WoW friends (v2)
        autoForgetDays = 30,              -- Garbage-collect peers older than this
        lastBroadcast  = {},              -- channel -> last hash sent (skip-if-unchanged)
        lastBitmap     = {},              -- channel -> last bitmap fingerprint
        collapsed      = {},
    },
    events = { "PLAYER_GUILD_UPDATE", "GUILD_ROSTER_UPDATE" },
    onEvent = function(m, event)
        -- These are passive — Roster doesn't scan, just keeps the live
        -- guild member list current for "who's online" rendering.
    end,
    onLogin = function(m)
        -- One-time cleanup of bad keys from earlier 1.6.x builds, where
        -- a failed BNet sender resolution stored entries under literal
        -- "BNet" instead of the friend's Name-Realm. Drop anything that
        -- doesn't look like a Name-Realm so the Roster tab is clean.
        if MC.RosterDB then
            for k in pairs(MC.RosterDB) do
                if type(k) ~= "string" or not k:find("-", 1, true) then
                    MC.RosterDB[k] = nil
                end
            end
        end

        -- Stagger the initial broadcast so we don't fight for addon
        -- bandwidth with every other addon's login chatter.
        C_Timer.After(5, function() MC.RosterBroadcastIfChanged() end)
    end,
})

--------------------------------------------------------------------------
-- Wire format helpers (v1: counts only)
--------------------------------------------------------------------------
-- Module-key -> single-char wire code. Single chars keep messages short.
local WIRE_KEY = {
    mounts      = "m",
    pets        = "p",
    toys        = "t",
    decorations = "d",
    recipes     = "c",  -- 'c' for crafting; 'r' is taken by rares
    rares       = "r",
    treasures   = "x",
}

-- Walk the scanners and produce a per-module {collected, total} table.
-- Used both for the wire payload (BuildPayload) and for rendering the
-- "Me" row/column in the Roster tab and PeerPanel.
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

-- Roster-shaped entry for the local player, suitable for rendering by
-- the Roster UI and PeerPanel. Mirrors the per-peer record shape so
-- consumers can use a single code path.
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

-- A throwaway hash for "did our payload change?". Doesn't need to be
-- collision-resistant; it just needs to differ when the counts differ.
local function cheapHash(s)
    local h = 0
    for i = 1, #s do
        h = (h * 31 + s:byte(i)) % 2147483647
    end
    return h
end

--------------------------------------------------------------------------
-- Broadcast (skip-if-unchanged)
--------------------------------------------------------------------------
function MC.RosterBroadcastIfChanged(channel)
    channel = channel or "GUILD"
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

    -- v2: also broadcast the per-item bitmap. Skipped if disabled or if
    -- the bitmap module didn't initialize (no PLAYER_LOGIN yet).
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

-- Force-broadcast (used by /mc roster announce). Skips the unchanged check.
function MC.RosterForceBroadcast(channel)
    channel = channel or "GUILD"
    if not MC.Comms then return end
    local payload = BuildPayload() .. "|" .. GetClassToken() .. "|" .. (MC.version or "?")
    if mod.db then mod.db.lastBroadcast[channel] = nil end
    MC.Comms:Send("u", payload, channel)
end

-- Debounced version: bound to scanner-finished hooks. Coalesces multiple
-- rapid count changes into one broadcast every 30s.
local broadcastPending = false
function MC.RosterDebouncedBroadcast()
    if broadcastPending then return end
    broadcastPending = true
    C_Timer.After(30, function()
        broadcastPending = false
        MC.RosterBroadcastIfChanged()
    end)
end

--------------------------------------------------------------------------
-- Receive handlers
--------------------------------------------------------------------------
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
        class    = parsed.class,
        version  = parsed.version,
        counts   = parsed.counts,
        lastSeen = time(),
    }

    if MC.activeModule == "roster" and MC.RefreshActive then
        MC.RefreshActive()
    end
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
        if rec.lastSeen and rec.lastSeen < cutoff then
            MC.RosterDB[name] = nil
        end
    end
end

--------------------------------------------------------------------------
-- Slash-command handlers (registered against the existing /mc dispatcher
-- via MC.RegisterRosterSlash, called from Core after both load).
--------------------------------------------------------------------------
function MC.RosterSlashHandler(arg)
    arg = (arg or ""):lower()
    if arg == "" or arg == "status" then
        local count = 0
        if MC.RosterDB then
            for _ in pairs(MC.RosterDB) do count = count + 1 end
        end
        print(format("%s Roster: sharing %s, %d peers tracked.",
            MC.PREFIX, mod.db and mod.db.share and "ON" or "OFF", count))
    elseif arg == "on" then
        if mod.db then mod.db.share = true end
        print(MC.PREFIX .. " Roster sharing turned ON.")
        MC.RosterForceBroadcast("GUILD")
    elseif arg == "off" then
        if mod.db then mod.db.share = false end
        print(MC.PREFIX .. " Roster sharing turned OFF.")
    elseif arg == "announce" then
        MC.RosterForceBroadcast("GUILD")
        print(MC.PREFIX .. " Roster: broadcast sent to guild.")
    elseif arg == "sync" then
        if MC.Comms then
            MC.Comms:Send("r", "", "GUILD")
            print(MC.PREFIX .. " Roster: requested updates from guild.")
        end
    elseif arg == "prune" then
        MC.RosterPrune()
        print(MC.PREFIX .. " Roster: pruned stale peers.")
    elseif arg == "clear" then
        if MC.RosterDB then wipe(MC.RosterDB) end
        if MC.activeModule == "roster" and MC.RefreshActive then MC.RefreshActive() end
        print(MC.PREFIX .. " Roster: cleared.")
    else
        print(MC.PREFIX .. " /mc roster on|off|announce|sync|prune|clear|status")
    end
end
