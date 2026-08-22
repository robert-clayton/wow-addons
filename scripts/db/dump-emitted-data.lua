-- Loads the EMITTED Lua (build/emitted/) through the same capture harness as
-- dump-shipped-data.lua and writes the same JSONL shape.
--
--   luajit scripts/db/dump-emitted-data.lua > build/emitted.jsonl
--
-- Having both sides produced by the same encoder is the point: any difference
-- in the output is a difference in the DATA, not in how it was serialised.

local ADDON = "addons/Collectionist"
local EMITTED = "build/emitted"

local MC = {}
local captured = {}

_G.CreateFrame = function()
    return setmetatable({}, { __index = function() return function() end end })
end
_G.UnitFactionGroup = function() return "Alliance" end
_G.LibStub = function() return nil end
_G.C_Timer = { After = function() end, NewTimer = function() return { Cancel = function() end } end }

local function loadInto(path)
    local chunk, err = loadfile(path)
    if not chunk then return nil, err end
    local ok, e = pcall(chunk, "Collectionist", MC)
    if not ok then return nil, e end
    return true
end

function MC.RegisterContent(expansionKey, moduleKey, groups)
    if not (expansionKey and moduleKey and groups) then return end
    captured[#captured + 1] = { expansion = expansionKey, module = moduleKey, groups = groups }
end

-- Shared vocabulary the emitted files reference by symbol.
assert(loadInto(ADDON .. "/Data/Constants.lua"))

local symbolic = {}
local function indexConstants(tbl, prefix)
    if type(tbl) ~= "table" then return end
    for k, v in pairs(tbl) do
        if type(v) == "table" and type(k) == "string" then
            symbolic[v] = prefix .. "." .. k
        end
    end
end

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

encode = function(v)
    local tv = type(v)
    if v == nil then return "null" end
    if tv == "boolean" then return tostring(v) end
    if tv == "number" then
        if v == math.floor(v) and math.abs(v) < 2^53 then return string.format("%d", v) end
        return string.format("%.17g", v)
    end
    if tv == "string" then return '"' .. esc(v) .. '"' end
    if tv == "table" then
        local sym = symbolic[v]
        if sym then return '{"__symbol":"' .. esc(sym) .. '"}' end
        if isArray(v) then
            local parts = {}
            for i = 1, #v do parts[i] = encode(v[i]) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = tostring(k) end
        table.sort(keys)
        local parts = {}
        for _, k in ipairs(keys) do
            local val = v[k]
            if val == nil then val = v[tonumber(k)] end
            parts[#parts + 1] = '"' .. esc(k) .. '":' .. encode(val)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "null"
end

-- Locations first: the content files reference MC.LOC by symbol.
assert(loadInto(EMITTED .. "/Locations.lua"))
indexConstants(MC.CONTENT_RELEASE, "MC.CONTENT_RELEASE")
indexConstants(MC.LOC, "MC.LOC")

local function listFiles(dir)
    local out = {}
    -- io.popen is available under LuaJIT on Windows; `dir /b` avoids needing a
    -- filesystem library just to enumerate a build directory.
    local pipe = io.popen('dir /b "' .. dir:gsub("/", "\\") .. '\\*.lua" 2>nul')
    if pipe then
        for line in pipe:lines() do out[#out + 1] = line end
        pipe:close()
    end
    if #out == 0 then
        pipe = io.popen('ls -1 "' .. dir .. '"/*.lua 2>/dev/null')
        if pipe then
            for line in pipe:lines() do out[#out + 1] = line:match("[^/]+$") end
            pipe:close()
        end
    end
    table.sort(out)
    return out
end

local SKIP = { ["Locations.lua"] = true, ["RecipeWaypoints.lua"] = true, ["RecipeTrainers.lua"] = true }
local files = 0
for _, name in ipairs(listFiles(EMITTED)) do
    if not SKIP[name] then
        local ok, err = loadInto(EMITTED .. "/" .. name)
        if not ok then
            io.stderr:write("skip " .. name .. ": " .. tostring(err) .. "\n")
        else
            files = files + 1
        end
    end
end

assert(loadInto(EMITTED .. "/RecipeWaypoints.lua"))
assert(loadInto(EMITTED .. "/RecipeTrainers.lua"))

local locCount = 0
for key, value in pairs(MC.LOC or {}) do
    if type(value) == "table" then
        local tuples = (type(value[1]) == "table") and value or { value }
        for i, t in ipairs(tuples) do
            if type(t) == "table" and t[1] then
                locCount = locCount + 1
                print(encode({ __kind = "location", key = key, ord = i - 1,
                               map = t[1], x = t[2], y = t[3], label = t[4] }))
            end
        end
    end
end

local function dumpLookup(tbl, kind)
    local n = 0
    for id, value in pairs(tbl or {}) do
        if type(id) == "number" and type(value) == "table" then
            n = n + 1
            print(encode({ __kind = kind, id = id, value = value }))
        end
    end
    return n
end
local wpN = dumpLookup(MC.RecipeWaypoints, "recipe_waypoint")
local trN = dumpLookup(MC.RecipeTrainers, "recipe_trainer")

local LIST_KEY = {
    mounts = "mounts", pets = "pets", toys = "toys", decorations = "decorations",
    rares = "rares", treasures = "treasures", achievements = "achievements",
    recipes = "recipes",
}

local groupOrd = {}
local rows = 0
for _, cap in ipairs(captured) do
    local listKey = LIST_KEY[cap.module] or cap.module
    local ordKey = cap.expansion .. "/" .. cap.module
    for _, group in ipairs(cap.groups) do
        groupOrd[ordKey] = (groupOrd[ordKey] or -1) + 1
        local gOrd = groupOrd[ordKey]
        local entries = group[listKey] or group.items or {}
        local groupMeta = {}
        for k, v in pairs(group) do
            if k ~= listKey and k ~= "items" and type(v) ~= "function" then groupMeta[k] = v end
        end
        for i, entry in ipairs(entries) do
            rows = rows + 1
            print(encode({ __kind = "collectible", expansion = cap.expansion, module = cap.module,
                           groupOrd = gOrd, entryOrd = i - 1, group = groupMeta, entry = entry }))
        end
        if #entries == 0 then
            rows = rows + 1
            print(encode({ __kind = "collectible", expansion = cap.expansion, module = cap.module,
                           groupOrd = gOrd, entryOrd = 0, group = groupMeta, entry = {} }))
        end
    end
end

io.stderr:write(string.format(
    "emitted reload: %d files, %d rows, %d locations, %d recipe pins, %d trainers\n",
    files, rows, locCount, wpN, trN))
