local addonName, MC = ...

--------------------------------------------------------------------------
-- /mc mem — a measuring instrument, not a fix.
--
-- The player sees ~55 MB with one expansion enabled and ~160 MB with all of
-- them, and it does NOT come back down when they are disabled again. That is
-- retention or a permanent high-water mark, not garbage, and no number this
-- addon prints today can tell those two apart. This can.
--
-- The report is ordered by what could produce a monotonic mark:
--
--   1. Frames. WoW never destroys a Frame. lib.Pool parks released frames in
--      an inactive list and never shrinks, so #active + #inactive IS the
--      high-water mark of every row the session ever painted -- it can only
--      go up. Sub-widgets cached on those frames (lib.GetOrCreate's _children,
--      _decorTex's _decor) are per-frame and equally permanent, and a frame
--      recycled by a DIFFERENT consumer accumulates that consumer's keys on
--      top of the ones it already had.
--   2. Retained Lua tables: the search index, one live set of scanner entry
--      tables per module, and the SavedVariables roots.
--   3. The raw totals, which are the thing being explained.
--
-- `/mc mem gc` runs a full collect and prints before/after. That is the one
-- step that separates "we are still holding it" from "the collector has not
-- got to it yet", and every proposed fix has to survive it: memory that is
-- still there after a full collect is memory something still references.
--
-- Every API here is guarded. This command must never be the thing that
-- errors while someone is trying to diagnose an error.
--------------------------------------------------------------------------

MC.Memory = MC.Memory or {}
local Mem = MC.Memory

local sformat, sfloor = string.format, math.floor

--------------------------------------------------------------------------
-- Guards
--------------------------------------------------------------------------

-- rawget so a stubbed or metatable-backed environment cannot answer with
-- something that merely looks callable.
local function apiFn(tbl, name)
    if type(tbl) ~= "table" then return nil end
    local ok, v = pcall(rawget, tbl, name)
    if ok and type(v) == "function" then return v end
    return nil
end

-- Blizzard has been moving addon APIs into C_AddOns one release at a time.
-- Look in both places and report unavailability rather than erroring.
local function resolve(name)
    local g = _G
    if type(g) ~= "table" then return nil end
    return apiFn(g, name) or apiFn(rawget(g, "C_AddOns"), name)
end

local function countKeys(t)
    if type(t) ~= "table" then return 0 end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function comma(n)
    n = sfloor((tonumber(n) or 0) + 0.5)
    local neg = n < 0
    local s = tostring(neg and -n or n)
    local rev = s:reverse():gsub("(%d%d%d)", "%1,")
    local out = rev:reverse():gsub("^,", "")
    return (neg and "-" or "") .. out
end

-- KB in, "12,345 KB (12.1 MB)" out. nil stays visibly nil: a report that
-- prints 0 for an unavailable API is worse than one that says so.
local function kbStr(v)
    if type(v) ~= "number" then return "unavailable" end
    if v >= 1024 then
        return sformat("%s KB (%.1f MB)", comma(v), v / 1024)
    end
    return comma(v) .. " KB"
end

--------------------------------------------------------------------------
-- Samples
--------------------------------------------------------------------------

-- GetAddOnMemoryUsage reports a cached figure; UpdateAddOnMemoryUsage is what
-- refreshes it. Calling the getter alone reports whatever the last caller
-- (usually the Blizzard addon list, possibly never) left behind.
function Mem.AddonKB()
    local update, get = resolve("UpdateAddOnMemoryUsage"), resolve("GetAddOnMemoryUsage")
    if not (update and get) then return nil end
    if not pcall(update) then return nil end
    local ok, v = pcall(get, MC.name or addonName or "Collectionist")
    if ok and type(v) == "number" then return v end
    return nil
end

function Mem.LuaKB()
    if type(collectgarbage) ~= "function" then return nil end
    local ok, v = pcall(collectgarbage, "count")
    if ok and type(v) == "number" then return v end
    return nil
end

--------------------------------------------------------------------------
-- Frames
--------------------------------------------------------------------------

-- Deduplicated: the lib registry and MC.panel normally name the same pool,
-- and double-counting the frame high-water would be the one number here that
-- must not be wrong.
function Mem.Pools()
    local pools, seen = {}, {}
    local function add(p)
        if type(p) == "table" and type(p.active) == "table"
           and type(p.inactive) == "table" and not seen[p] then
            seen[p] = true
            pools[#pools + 1] = p
        end
    end
    local ok, MUI = pcall(LibStub, "MidnightUI-1.0", true)
    if ok and type(MUI) == "table" and type(rawget(MUI, "_pools")) == "table" then
        for _, p in ipairs(MUI._pools) do add(p) end
    end
    if type(MC.panel) == "table" then add(rawget(MC.panel, "pool")) end
    return pools
end

-- active / idle / children / decor.
--   active + idle = frames created this session. WoW never frees a Frame, so
--   that sum only ever rises; it is the permanent floor under the addon.
--   children + decor = widgets cached ON those frames by GetOrCreate and
--   _decorTex, keyed by string and never evicted.
function Mem.FrameStats()
    local active, idle, children, decor = 0, 0, 0, 0
    for _, pool in ipairs(Mem.Pools()) do
        active = active + #pool.active
        idle   = idle + #pool.inactive
        for _, list in ipairs({ pool.active, pool.inactive }) do
            for i = 1, #list do
                local f = list[i]
                if type(f) == "table" then
                    children = children + countKeys(rawget(f, "_children"))
                    decor    = decor + countKeys(rawget(f, "_decor"))
                end
            end
        end
    end
    return active, idle, children, decor
end

--------------------------------------------------------------------------
-- Retained Lua tables
--------------------------------------------------------------------------

-- Scanner results come in two shapes. Most modules publish one result table
-- with `collected` + `bySource`; Recipes publishes one such table per skill
-- line under Scanner.results[skillLine]. byCategory is deliberately NOT
-- counted: it holds the same entry tables bySource already does, and counting
-- both would report twice the entries that exist.
local function countEntries(r)
    if type(r) ~= "table" then return 0, false end
    local n, shaped = 0, false
    local c = rawget(r, "collected")
    if type(c) == "table" then n, shaped = n + #c, true end
    local l = rawget(r, "learned")
    if type(l) == "table" then n, shaped = n + #l, true end
    local bs = rawget(r, "bySource")
    if type(bs) == "table" then
        shaped = true
        for _, bucket in pairs(bs) do
            if type(bucket) == "table" then n = n + #bucket end
        end
    end
    return n, shaped
end

function Mem.ModuleEntries(mod)
    local r = mod and mod.Scanner and mod.Scanner.results
    if type(r) ~= "table" then return nil end
    local n, shaped = countEntries(r)
    if shaped then return n end
    local total = 0
    for _, sub in pairs(r) do
        total = total + (countEntries(sub))
    end
    return total
end

-- Structural weight of a table graph: tables reached, keys held, bytes of
-- string held. Deliberately NOT converted to a byte total -- the per-slot
-- overhead of a Lua table is an implementation detail this addon has no way
-- to observe, and a made-up multiplier would be a fabricated number in a
-- report whose whole purpose is to stop the guessing.
--
-- Budgeted and cycle-safe: SavedVariables graphs are player-sized and this
-- runs on a manual command, but an unbounded walk of a cyclic table is a
-- freeze, not a slow report.
local WEIGH_BUDGET = 200000

function Mem.Weigh(root)
    if type(root) ~= "table" then return nil end
    local seen, stack = {}, { root }
    local tables, keys, strBytes, visited = 0, 0, 0, 0
    seen[root] = true
    while #stack > 0 do
        local t = stack[#stack]
        stack[#stack] = nil
        tables = tables + 1
        for k, v in pairs(t) do
            visited = visited + 1
            keys = keys + 1
            if type(k) == "string" then strBytes = strBytes + #k end
            if type(v) == "string" then
                strBytes = strBytes + #v
            elseif type(v) == "table" and not seen[v] then
                seen[v] = true
                stack[#stack + 1] = v
            end
            if visited > WEIGH_BUDGET then
                return tables, keys, strBytes, true
            end
        end
    end
    return tables, keys, strBytes, false
end

local function weighLine(label, root)
    local tables, keys, strBytes, capped = Mem.Weigh(root)
    if not tables then return nil end
    return sformat("%s %s tables / %s keys / %s string bytes%s",
        label, comma(tables), comma(keys), comma(strBytes), capped and " (capped)" or "")
end

--------------------------------------------------------------------------
-- Roster
--------------------------------------------------------------------------

-- Two numbers, because they differ: records is what is HELD, peers is what is
-- renderable. A partial record (an 's'/'e'/'b' that arrived before its 'u')
-- costs memory without ever showing up in the peer indicator.
function Mem.RosterCounts()
    local db = MC.RosterDB
    if type(db) ~= "table" then return nil, nil end
    local records, peers = 0, 0
    for k, v in pairs(db) do
        if type(k) == "string" and k:sub(1, 1) ~= "_" and type(v) == "table" then
            records = records + 1
            if rawget(v, "counts") then peers = peers + 1 end
        end
    end
    return peers, records
end

--------------------------------------------------------------------------
-- Report
--------------------------------------------------------------------------

local function enabledCount(list, isEnabled)
    if type(list) ~= "table" or type(isEnabled) ~= "function" then return nil, nil end
    local ok, on, total = pcall(function()
        local n, t = 0, 0
        for _, e in ipairs(list) do
            t = t + 1
            if isEnabled(e.key) ~= false then n = n + 1 end
        end
        return n, t
    end)
    if not ok then return nil, nil end
    return on, total
end

local function signed(n)
    if type(n) ~= "number" then return "n/a" end
    return (n >= 0 and "+" or "") .. comma(n)
end

-- Deltas against the previous /mc mem, because the observation that needs
-- explaining is a difference between two states, not an absolute. Run it,
-- toggle expansions, run it again, toggle back, run it a third time: if the
-- third reading does not return to the first, the delta line says so in the
-- same breath as saying which counter moved.

-- Highest addon figure this command has seen this session. Only ever sampled
-- when the player asks, so it is a floor on the true session peak, never an
-- overstatement -- which is the safe direction for a high-water claim.

function Mem.Report()
    local P = MC.PREFIX or "Collectionist"
    local addonKB, luaKB = Mem.AddonKB(), Mem.LuaKB()
    if type(addonKB) == "number" and (not Mem.peakKB or addonKB > Mem.peakKB) then
        Mem.peakKB = addonKB
    end

    print(P .. " memory report")
    print(sformat("  addon: %s    lua heap: %s", kbStr(addonKB), kbStr(luaKB)))
    if Mem.peakKB and addonKB and Mem.peakKB > addonKB then
        print(sformat("  highest seen by this command: %s", kbStr(Mem.peakKB)))
    end

    -- Frames first: this is the only figure here that CANNOT go back down.
    local active, idle, children, decor = Mem.FrameStats()
    print(sformat("  frames: %s created (%s active + %s idle) - WoW never frees these",
        comma(active + idle), comma(active), comma(idle)))
    print(sformat("    widgets cached on them: %s children + %s decor",
        comma(children), comma(decor)))

    local frames = active + idle
    local last = Mem.last
    if last then
        print(sformat("  since your last /mc mem: addon %s KB, lua %s KB, frames %s",
            (type(addonKB) == "number" and type(last.addon) == "number")
                and signed(addonKB - last.addon) or "n/a",
            (type(luaKB) == "number" and type(last.lua) == "number")
                and signed(luaKB - last.lua) or "n/a",
            signed(frames - last.frames)))
    end
    Mem.last = { addon = addonKB, lua = luaKB, frames = frames }

    local S = MC.Search
    if type(S) == "table" then
        local idx = rawget(S, "index")
        if type(idx) == "table" then
            local static = tonumber(rawget(S, "_staticCount")) or 0
            print(sformat("  search index: %s records (%s static + %s derived), byItemID %s, dirty %s",
                comma(#idx), comma(static), comma(#idx - static),
                comma(countKeys(rawget(S, "byItemID"))),
                tostring(rawget(S, "_dirty") and true or false)))
        else
            print("  search index: not built")
        end
    end

    if type(MC.modules) == "table" then
        local total, parts = 0, {}
        for _, mod in ipairs(MC.modules) do
            local n = Mem.ModuleEntries(mod)
            if n then
                total = total + n
                parts[#parts + 1] = sformat("%s %s", mod.key or "?", comma(n))
            end
        end
        print(sformat("  scanner entries: %s live entry tables", comma(total)))
        if #parts > 0 then print("    " .. table.concat(parts, " | ")) end
    end

    local peers, records = Mem.RosterCounts()
    if peers then
        local w = weighLine("", MC.RosterDB) or ""
        print(sformat("  roster: %s peers (%s records held)%s",
            comma(peers), comma(records), w ~= "" and ("  " .. w) or ""))
    end

    -- MC.db is the per-character primary (CollectionistCharDB); MC.snapshotDB
    -- is the account-wide seed pool (CollectionistDB), which holds the
    -- never-erased recipe ledger.
    for _, root in ipairs({
        { "char (MC.db):", MC.db },
        { "account (MC.snapshotDB):", MC.snapshotDB },
    }) do
        local line = weighLine(root[1], root[2])
        if line then print("  saved vars " .. line) end
    end

    local expOn, expTotal = enabledCount(MC.EXPANSIONS, MC.IsExpansionEnabled)
    local modOn, modTotal = enabledCount(MC.modules, MC.IsModuleEnabled)
    if expOn then
        print(sformat("  expansions enabled: %d / %d%s", expOn, expTotal,
            modOn and sformat("    modules enabled: %d / %d", modOn, modTotal) or ""))
    end
end

-- Before/after around a full collect. The "after" figure is the one that
-- matters: anything still attributed to the addon once the collector has run
-- is memory something in this addon still holds a reference to.
function Mem.ReportGC()
    local P = MC.PREFIX or "Collectionist"
    if type(collectgarbage) ~= "function" then
        print(P .. " collectgarbage is unavailable on this client.")
        return
    end

    local beforeAddon, beforeLua = Mem.AddonKB(), Mem.LuaKB()
    print(P .. " full collect")
    print(sformat("  before: addon %s    lua %s", kbStr(beforeAddon), kbStr(beforeLua)))

    local ok, err = pcall(collectgarbage, "collect")
    if not ok then
        print(sformat("  collect failed: %s", tostring(err)))
        return
    end

    local afterAddon, afterLua = Mem.AddonKB(), Mem.LuaKB()
    print(sformat("  after:  addon %s    lua %s", kbStr(afterAddon), kbStr(afterLua)))

    if type(beforeAddon) == "number" and type(afterAddon) == "number" then
        local freed = beforeAddon - afterAddon
        local pct = beforeAddon > 0 and (freed / beforeAddon * 100) or 0
        print(sformat("  freed:  %s (%.1f%% was uncollected garbage)", kbStr(freed), pct))
        print(sformat("  RETAINED after collect: %s - this is what is actually held",
            kbStr(afterAddon)))
    end

    Mem.Report()
end

-- Single entry point for the slash dispatch. `arg` is the already-lowercased
-- remainder of the command line.
function MC.MemReport(arg)
    local sub = type(arg) == "string" and arg or ""
    sub = sub:match("^%s*(%S*)") or ""
    local ok, err
    if sub == "gc" or sub == "collect" then
        ok, err = pcall(Mem.ReportGC)
    else
        ok, err = pcall(Mem.Report)
    end
    if not ok then
        print((MC.PREFIX or "Collectionist") .. " memory report failed: " .. tostring(err))
    end
end
