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
        autoForgetDays = 30,              -- Garbage-collect peers older than this
        lastBroadcast  = {},              -- channel -> last hash sent (skip-if-unchanged)
        collapsed      = {},
    },
    events = { "PLAYER_GUILD_UPDATE", "GUILD_ROSTER_UPDATE" },
    onEvent = function(m, event)
        -- These are passive — Roster doesn't scan, just keeps the live
        -- guild member list current for "who's online" rendering.
    end,
    onLogin = function(m)
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

-- Build the count-summary payload from current scanner results.
local function BuildPayload()
    local parts = {}
    for _, m in ipairs(MC.modules) do
        local code = WIRE_KEY[m.key]
        local r    = m.Scanner and m.Scanner.results
        if code and r and r.total and r.total > 0 then
            -- Recipes' results table is keyed by skill-line, not flat.
            -- Aggregate it.
            if m.key == "recipes" then
                local learned, total = 0, 0
                for _, sub in pairs(r) do
                    if type(sub) == "table" and sub.total then
                        learned = learned + (sub.learnedCount or 0)
                        total   = total + sub.total
                    end
                end
                if total > 0 then
                    parts[#parts + 1] = format("%s:%d/%d", code, learned, total)
                end
            else
                parts[#parts + 1] = format("%s:%d/%d", code,
                    r.collectedCount or 0, r.total)
            end
        end
    end
    return table.concat(parts, ",")
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
    if mod.db.lastBroadcast[channel] == h then return end
    mod.db.lastBroadcast[channel] = h

    MC.Comms:Send("u", fullPayload, channel)
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

if MC.Comms then
    MC.Comms:RegisterPrefix("GUILD", "u", OnUpdateReceived)
    MC.Comms:RegisterPrefix("GUILD", "r", OnRequestReceived)
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
