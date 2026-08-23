-- Dumps every HandyNotes map node to JSONL by LOADING the zone files.
--
--   luajit scripts/db/dump-handynotes.lua "<AddOns dir>" > build/handynotes.jsonl
--
-- Two publisher families ship Midnight/retail data and they do not agree on
-- format, coordinates, or even how many nodes a thing has:
--
--   core     ns.Map + a class hierarchy      map.nodes[55264393] = Item({...})
--   handler  ns.RegisterPoints(zone, pts)    [54534241] = {quest=..., loot={}}
--
-- Both lines above describe the SAME node -- quest 79550, item 213202 -- about
-- one percent apart on the map. That is the whole normalisation problem: the
-- quest id is the stable identity and the coordinates are not.
--
-- Loading rather than regexing matters more here than anywhere else in this
-- repo. The coordinate key is an integer, so a node at x < 10% is seven digits
-- rather than eight; the pattern-matching audit that preceded this required
-- exactly eight and silently dropped every one of them.
--
-- The class hierarchy is open-ended -- ns.node.FrogPrincess, ns.node.Coffer,
-- ns.node.DracthyrSupplyChest -- so nothing is enumerated. Any ns.<kind>.<Name>
-- auto-vivifies into a constructor that records the table it was handed.

local ADDONS = ...
if not ADDONS or ADDONS == "" then
    io.stderr:write("usage: luajit dump-handynotes.lua \"<path to Interface/AddOns>\"\n")
    os.exit(2)
end
ADDONS = ADDONS:gsub("\\", "/"):gsub("/$", "")

--------------------------------------------------------------------------
-- JSON
--------------------------------------------------------------------------
local function esc(s)
    s = s:gsub('[\\"]', '\\%0'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
    return s:gsub('[\1-\31]', function(c) return string.format('\\u%04x', c:byte()) end)
end

local encode
local function isArray(t)
    local n = 0
    for k in pairs(t) do
        if type(k) ~= "number" then return false end
        n = n + 1
    end
    return n == #t
end

encode = function(v, depth)
    depth = (depth or 0) + 1
    local tv = type(v)
    if v == nil or depth > 8 then return "null" end
    if tv == "boolean" then return tostring(v) end
    if tv == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "null" end
        if v == math.floor(v) and math.abs(v) < 2^53 then return string.format("%d", v) end
        return string.format("%.17g", v)
    end
    if tv == "string" then return '"' .. esc(v) .. '"' end
    if tv == "table" then
        if isArray(v) then
            local parts = {}
            for i = 1, #v do parts[i] = encode(v[i], depth) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local keys = {}
        for k in pairs(v) do
            if type(k) == "string" or type(k) == "number" then keys[#keys + 1] = tostring(k) end
        end
        table.sort(keys)
        local parts = {}
        for _, k in ipairs(keys) do
            local val = v[k]
            if val == nil then val = v[tonumber(k)] end
            if type(val) ~= "function" and type(val) ~= "userdata" then
                parts[#parts + 1] = '"' .. esc(k) .. '":' .. encode(val, depth)
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "null"
end

--------------------------------------------------------------------------
-- A tolerant stand-in for the WoW client and for each addon's own machinery.
--------------------------------------------------------------------------
local function anyfunc() return function() end end

local permissive
local withFallbackFwd
function permissive(name)
    -- Indexing yields another permissive table; calling yields a recorded
    -- constructor result. Zone files reach for a lot -- ns.locale strings,
    -- ns.maps lookups, ns.status colours -- and none of it can be enumerated
    -- ahead of time.
    return setmetatable({}, {
        __index = function(t, k)
            local child = permissive(name .. "." .. tostring(k))
            rawset(t, k, child)
            return child
        end,
        __call = function(_, arg)
            local out = type(arg) == "table" and arg or { value = arg }
            out.__class = name
            return withFallbackFwd(out, name)
        end,
        __tostring = function() return name end,
        __concat = function(a, b)
            return (type(a) == "string" and a or name) .. (type(b) == "string" and b or name)
        end,
    })
end

-- Gives a real table a permissive fallback: declared keys read normally, and
-- anything else yields a permissive child instead of nil. Without it a zone
-- file reaching one field past what the stub models -- map.foo.bar, or a node
-- class's own helper -- raises and takes that zone's entire node list with it.
-- Every metamethod a zone file might reach for, not just __index. These objects
-- are concatenated into label strings and called as functions, and a missing
-- __concat is what still killed four Shadowlands zones after the rest worked:
--   rlabel = ns.status.LightBlue(L['x']) .. ns.GetIconLink('portal_gy', 20)
local function withFallback(real, name)
    return setmetatable(real, {
        __index = function(t, k)
            local child = permissive(name .. "." .. tostring(k))
            rawset(t, k, child)
            return child
        end,
        __call = function(_, arg)
            if type(arg) == "table" then
                arg.__class = name
                return withFallback(arg, name)
            end
            return name
        end,
        __tostring = function() return name end,
        __concat = function(a, b)
            return (type(a) == "string" and a or name) .. (type(b) == "string" and b or name)
        end,
    })
end
-- permissive() is defined above withFallback but needs it; bind it now.
withFallbackFwd = withFallback

-- Localisation tables are indexed for STRINGS and the results are handed to
-- format() and concatenation. Returning a table there is what produced eleven
-- "string expected, got table" failures, so the key itself is the value.
local function stringTable()
    return setmetatable({}, { __index = function(_, k) return tostring(k) end })
end

local function stubGlobals()
    local G = {
        CreateFrame = function()
            return setmetatable({}, { __index = function() return anyfunc() end })
        end,
        UnitFactionGroup = function() return "Alliance" end,
        UnitClass = function() return "Warrior", "WARRIOR", 1 end,
        UnitRace = function() return "Human", "Human", 1 end,
        GetLocale = function() return "enUS" end,
        C_Timer = { After = anyfunc(), NewTicker = function() return { Cancel = anyfunc() } end },
        C_Map = permissive("C_Map"),
        C_QuestLog = permissive("C_QuestLog"),
        C_TransmogCollection = permissive("C_TransmogCollection"),
        C_MountJournal = permissive("C_MountJournal"),
        C_PetJournal = permissive("C_PetJournal"),
        C_ToyBox = permissive("C_ToyBox"),
        C_Item = permissive("C_Item"),
        C_Spell = permissive("C_Spell"),
        C_AddOns = permissive("C_AddOns"),
        -- Returning nil here means `LibStub("AceAddon-3.0"):GetAddon(...)` --
        -- the first line of several data files -- raises before any node is
        -- declared. A permissive object absorbs the whole call chain instead.
        LibStub = function(name) return permissive("LibStub." .. tostring(name)) end,
        Enum = permissive("Enum"),
        select = select, tonumber = tonumber, tostring = tostring, type = type,
        pairs = pairs, ipairs = ipairs, next = next, error = error, assert = assert,
        pcall = pcall, setmetatable = setmetatable, getmetatable = getmetatable,
        rawset = rawset, rawget = rawget, unpack = unpack, print = function() end,
        string = string, table = table, math = math, os = os, bit = bit,
        strsplit = function(_, s) return s end, format = string.format,
        strjoin = function(_, ...) return table.concat({ ... }, "") end,
        wipe = function(t) for k in pairs(t) do t[k] = nil end return t end,
        tinsert = table.insert, tremove = table.remove, sort = table.sort,
        GetAddOnMetadata = function() return "0" end,
        date = os.date, time = os.time, floor = math.floor, ceil = math.ceil,
        max = math.max, min = math.min, abs = math.abs,
    }
    -- Anything not listed resolves rather than raising. A zone file that dies
    -- on a missing global takes its whole zone's nodes with it.
    setmetatable(G, { __index = function(_, k) return permissive(tostring(k)) end })
    G._G = G
    return G
end

--------------------------------------------------------------------------
-- Per-addon capture
--------------------------------------------------------------------------
local captured = {}   -- { addon, family, map, coord, node }

local function newNamespace(addon)
    local ns = permissive("ns")

    -- core family: Map({id=...}) hands back an object whose .nodes table the
    -- zone file fills in.
    local maps = {}
    local function newMap(args, className)
        args = type(args) == "table" and args or {}
        local m = withFallback({ id = args.id, nodes = {}, __map = true,
                                 __class = className }, "map")
        maps[#maps + 1] = m
        return m
    end

    local MapClass = setmetatable({}, {
        __call = function(_, args) return newMap(args, "Map") end,
        __index = function(_, k) return permissive("ns.Map." .. tostring(k)) end,
    })
    -- Addons SUBCLASS the map and replace ns.Map with the subclass:
    -- HandyNotes_Shadowlands does `ns.Map = Class('ShadowlandsMap', Map)` and
    -- every zone then builds through that. Without propagating this marker the
    -- subclass produced an ordinary table, its nodes went into the permissive
    -- fallback, and the addon reported zero nodes while loading cleanly.
    rawset(MapClass, "__isMapClass", true)
    rawset(ns, "Map", MapClass)
    rawset(ns, "maps", setmetatable({}, { __index = function(t, k)
        local m = withFallback({ id = k, nodes = {}, __map = true }, "map")
        rawset(t, k, m)
        maps[#maps + 1] = m
        return m
    end }))
    rawset(ns, "locale", stringTable())
    rawset(ns, "L", stringTable())

    -- Class('Name', Base, defaults) -> a constructor that merges the defaults.
    rawset(ns, "Class", function(name, base, defaults)
        local isMap = type(base) == "table" and rawget(base, "__isMapClass") == true
        local cls = setmetatable({}, { __call = function(_, args)
            local out = {}
            if type(defaults) == "table" then
                for k, v in pairs(defaults) do out[k] = v end
            end
            if type(base) == "table" and rawget(base, "__defaults") then
                for k, v in pairs(base.__defaults) do
                    if out[k] == nil then out[k] = v end
                end
            end
            if type(args) == "table" then
                for k, v in pairs(args) do out[k] = v end
            end
            if isMap then return newMap(out, tostring(name)) end
            out.__class = tostring(name)
            return withFallback(out, tostring(name))
        end, __index = function(t, k)
            if k == "__defaults" then return defaults end
            return permissive(tostring(name) .. "." .. tostring(k))
        end })
        -- Carries through arbitrarily deep chains: RiftMap subclasses
        -- ShadowlandsMap subclasses Map, and all three must build real maps.
        if isMap then rawset(cls, "__isMapClass", true) end
        return cls
    end)

    -- handler family: RegisterPoints(zone, points, defaults)
    local registered = {}
    rawset(ns, "RegisterPoints", function(zone, points, defaults)
        if type(points) ~= "table" then return end
        registered[#registered + 1] = { zone = zone, points = points, defaults = defaults }
    end)
    rawset(ns, "points", setmetatable({}, { __index = function(t, k)
        local v = {}
        rawset(t, k, v)
        return v
    end }))
    rawset(ns, "nodeMaker", function(defaults)
        return function(point)
            local out = {}
            if type(defaults) == "table" then for k, v in pairs(defaults) do out[k] = v end end
            if type(point) == "table" then for k, v in pairs(point) do out[k] = v end end
            return out
        end
    end)

    return ns, maps, registered
end

-- Lua's pairs() has no defined order, so iterating a node table directly makes
-- the dump differ between runs on the same install -- and every artifact
-- derived from it, including which coordinate a consumer sees first. Sort the
-- coordinate keys so the pipeline is reproducible.
local function sortedCoordKeys(tbl)
    local keys = {}
    for k in pairs(tbl or {}) do
        if type(k) == "number" then keys[#keys + 1] = k end
    end
    table.sort(keys)
    return keys
end

local function coordToXY(key)
    -- The key is an integer, NOT a fixed-width string: 55264393 is (0.5526,
    -- 0.4393) and 5264393 is (0.0526, 0.4393). Requiring eight digits drops
    -- every node in the leftmost tenth of a map.
    if type(key) ~= "number" or key <= 0 then return nil end
    local x = math.floor(key / 10000) / 10000
    local y = (key % 10000) / 10000
    if x <= 0 or x > 1 or y <= 0 or y > 1 then return nil end
    return x, y
end

--------------------------------------------------------------------------
-- File discovery
--------------------------------------------------------------------------
local function listDir(dir, pattern)
    local out = {}
    local cmd = 'dir /b /s "' .. dir:gsub("/", "\\") .. '\\' .. (pattern or "*.lua") .. '" 2>nul'
    local pipe = io.popen(cmd)
    if pipe then
        for line in pipe:lines() do out[#out + 1] = line:gsub("\\", "/") end
        pipe:close()
    end
    if #out == 0 then
        pipe = io.popen('find "' .. dir .. '" -name "' .. (pattern or "*.lua") .. '" 2>/dev/null')
        if pipe then
            for line in pipe:lines() do out[#out + 1] = line end
            pipe:close()
        end
    end
    table.sort(out)
    return out
end

local function listAddons()
    local out = {}
    local pipe = io.popen('dir /b /ad "' .. ADDONS:gsub("/", "\\") .. '\\HandyNotes*" 2>nul')
    if pipe then
        for line in pipe:lines() do out[#out + 1] = line end
        pipe:close()
    end
    if #out == 0 then
        pipe = io.popen('ls -d "' .. ADDONS .. '"/HandyNotes*/ 2>/dev/null')
        if pipe then
            for line in pipe:lines() do
                out[#out + 1] = line:gsub("/$", ""):match("[^/]+$")
            end
            pipe:close()
        end
    end
    table.sort(out)
    return out
end

--------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------
local totals = { addons = 0, files = 0, failed = 0, nodes = 0 }

for _, addon in ipairs(listAddons()) do
    local root = ADDONS .. "/" .. addon
    local files = listDir(root)
    if #files > 0 and addon ~= "HandyNotes" then
        local ns, maps, registered = newNamespace(addon)
        local G = stubGlobals()
        local loaded, failed = 0, 0

        -- Constants live in the addon's own top-level file (ns.ARCANTINA = 2541)
        -- so those must load; the machinery under handler/, core/ and libs/ is
        -- replaced by the stubs above and must NOT.
        local order = {}
        for _, path in ipairs(files) do
            local rel = path:sub(#root + 2)
            local skip = rel:match("^[Ll]ibs/") or rel:match("^[Cc]ore/")
                      or rel:match("^handler/") or rel:match("^[Ll]ocalization/")
                      or rel:match("^[Ee]mbeds") or rel:match("[Tt]emplates")
            if not skip then
                -- Top-level files before zone files: the former define the map
                -- id constants the latter pass to RegisterPoints.
                local depth = select(2, rel:gsub("/", ""))
                order[#order + 1] = { path = path, depth = depth, rel = rel }
            end
        end
        table.sort(order, function(a, b)
            if a.depth ~= b.depth then return a.depth < b.depth end
            return a.rel < b.rel
        end)

        for _, entry in ipairs(order) do
            local chunk = loadfile(entry.path)
            if chunk then
                setfenv(chunk, G)
                local ok, err = pcall(chunk, addon, ns)
                if ok then
                    loaded = loaded + 1
                else
                    failed = failed + 1
                    io.stderr:write("   FAIL " .. entry.rel .. ": " .. tostring(err) .. "\n")
                end
            else
                failed = failed + 1
                io.stderr:write("   PARSE " .. entry.rel .. "\n")
            end
        end

        local before = totals.nodes
        for _, m in ipairs(maps) do
            for _, coord in ipairs(sortedCoordKeys(m.nodes)) do
                local node = m.nodes[coord]
                local x, y = coordToXY(coord)
                if x and type(node) == "table" then
                    totals.nodes = totals.nodes + 1
                    print(encode({ __kind = "hn_node", addon = addon, family = "core",
                                   map = m.id, coord = coord, x = x, y = y, node = node }))
                end
            end
        end
        for _, reg in ipairs(registered) do
            local zone = tonumber(reg.zone)
            for _, coord in ipairs(sortedCoordKeys(reg.points)) do
                local point = reg.points[coord]
                local x, y = coordToXY(coord)
                if x and type(point) == "table" then
                    local merged = {}
                    if type(reg.defaults) == "table" then
                        for k, v in pairs(reg.defaults) do merged[k] = v end
                    end
                    for k, v in pairs(point) do merged[k] = v end
                    totals.nodes = totals.nodes + 1
                    print(encode({ __kind = "hn_node", addon = addon, family = "handler",
                                   map = zone, coord = coord, x = x, y = y, node = merged }))
                end
            end
        end

        totals.addons = totals.addons + 1
        totals.files = totals.files + loaded
        totals.failed = totals.failed + failed
        io.stderr:write(string.format("%-42s %4d files (%d failed)  %5d nodes\n",
            addon, loaded, failed, totals.nodes - before))
    end
end

io.stderr:write(string.format("\n%d addons, %d files loaded, %d failed, %d nodes\n",
    totals.addons, totals.files, totals.failed, totals.nodes))
