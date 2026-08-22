-- Dumps every shipped collectible row to JSONL by LOADING the addon's data
-- files, not by parsing them.
--
--   luajit scripts/db/dump-shipped-data.lua > build/shipped.jsonl
--
-- This is the bootstrap for the SQLite pipeline. The database is seeded from
-- the data that ships today -- the known-good state -- so the first emit can be
-- diffed against the current files byte for byte. Only once that round trip is
-- proven does upstream ingestion (DB2, ATT, HandyNotes) become the authority.
--
-- Loading rather than regexing matters: the files are Lua, and every previous
-- attempt in this repo to read them with patterns has missed something --
-- nested tables, escaped quotes, entries split across lines. MC.RegisterContent
-- is stubbed to capture exactly what the addon itself would receive.

local ADDON = "addons/Collectionist"

--------------------------------------------------------------------------
-- Minimal WoW/addon environment. The data files are pure declarations, but
-- a few reference constants or call CreateFrame at load.
--------------------------------------------------------------------------
local MC = {}
local captured = {}

-- Data files reference MC.MAP.X, MC.CURRENCY.X, MC.PROFESSION.X and
-- MC.SCORE_TIERS.x. Constants.lua defines them for real; load it first so the
-- values are the true ones rather than placeholders.
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

-- Capture instead of registering.
function MC.RegisterContent(expansionKey, moduleKey, groups)
    if not (expansionKey and moduleKey and groups) then return end
    captured[#captured + 1] = {
        expansion = expansionKey,
        module    = moduleKey,
        groups    = groups,
    }
end

-- Core.lua owns these, but loading Core would drag in the whole client API.
-- The recipe route is the only one that needs them: the nine curated
-- per-profession files assign MC.<Prof>Recipes directly instead of calling
-- RegisterContent, and Ownership.lua then adopts those tables as Midnight.
-- Without this the 715 hand-curated recipes never reach the dump.
MC.RECIPE_DATA_KEYS = {
    [171] = "AlchemyRecipes",    [164] = "BlacksmithingRecipes",
    [185] = "CookingRecipes",    [333] = "EnchantingRecipes",
    [202] = "EngineeringRecipes",[773] = "InscriptionRecipes",
    [755] = "JewelcraftingRecipes", [165] = "LeatherworkingRecipes",
    [197] = "TailoringRecipes",
}

function MC.RegisterExistingRecipeContent(expansionKey, skillLine)
    local field = MC.RECIPE_DATA_KEYS[skillLine]
    local target = field and MC[field]
    if not expansionKey or type(target) ~= "table" then return false end
    local groups = {}
    for _, group in ipairs(target) do
        if type(group.recipes) == "table" then
            group.skillLine = group.skillLine or skillLine
            groups[#groups + 1] = group
        end
    end
    if #groups > 0 then
        captured[#captured + 1] = { expansion = expansionKey, module = "recipes", groups = groups }
    end
    return true
end

--------------------------------------------------------------------------
-- JSON encoding. Small enough to hand-roll, and avoids a dependency.
--------------------------------------------------------------------------
local function esc(s)
    s = s:gsub('[\\"]', '\\%0'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
    -- WoW colour/texture escapes contain |, which is legal JSON but worth
    -- keeping literal so the round trip is exact.
    return s:gsub('[\1-\31]', function(c) return string.format('\\u%04x', c:byte()) end)
end

-- Some values in the data files are references to shared constants rather than
-- literals: MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 is one table referenced by 42
-- groups and inherited by 110 rows. Storing 110 expanded copies would lose the
-- fact that they are the same thing and make the emitter unable to write the
-- symbol back. Resolve the name here, where table identity is still available.
--
-- Only table-valued constants can be recovered this way. MC.CURRENCY.X,
-- MC.MAP.Y and T.legendary are plain numbers by load time and are
-- indistinguishable from a literal -- which is why the round-trip proof
-- compares loaded structures rather than file bytes.
local symbolic = {}
local function indexConstants(tbl, prefix)
    if type(tbl) ~= "table" then return end
    for k, v in pairs(tbl) do
        if type(v) == "table" and type(k) == "string" then
            symbolic[v] = prefix .. "." .. k
        end
    end
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
            -- NOT `v[k] ~= nil and v[k] or v[tonumber(k)]`. Lua's and/or
            -- ternary cannot carry a false value: the middle term being false
            -- falls through to the right-hand side, so every `canBattle = false`
            -- encoded as null and 83 pets lost the flag entirely.
            local val = v[k]
            if val == nil then val = v[tonumber(k)] end
            parts[#parts + 1] = '"' .. esc(k) .. '":' .. encode(val)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "null"
end

--------------------------------------------------------------------------
-- Load order matters: Core defines RegisterContent's collaborators, and the
-- per-profession recipe files assign MC.<Prof>Recipes wholesale, so expansion
-- files must come after them. Read the TOC rather than hardcoding.
--------------------------------------------------------------------------
local function tocFiles()
    local out = {}
    local fh = assert(io.open(ADDON .. "/Collectionist.toc", "r"))
    for line in fh:lines() do
        local entry = line:match("^%s*(.-)%s*$")
        if entry ~= "" and entry:sub(1, 1) ~= "#" and entry:match("%.lua$") then
            out[#out + 1] = ADDON .. "/" .. entry:gsub("\\", "/")
        end
    end
    fh:close()
    return out
end

local skipped = 0
for _, path in ipairs(tocFiles()) do
    -- Only Data/ files declare content; the rest is UI and would need far more
    -- of the client API stubbed for no gain.
    if path:match("/Data/") or path:match("/Constants%.lua$") or path:match("/Locations%.lua$")
       or path:match("/Expansions%.lua$") then
        local ok, err = loadInto(path)
        if not ok then
            io.stderr:write("skip " .. path .. ": " .. tostring(err) .. "\n")
            skipped = skipped + 1
        end
    end
end

indexConstants(MC.CONTENT_RELEASE, "MC.CONTENT_RELEASE")
indexConstants(MC.LOC, "MC.LOC")

-- MC.LOC is a shared location table: 95 named places referenced by name from
-- the data files. Emit them as first-class records so waypoints can reference
-- a location instead of carrying a duplicate copy of its coordinates.
local locCount = 0
for key, value in pairs(MC.LOC or {}) do
    if type(value) == "table" then
        -- Either one {map,x,y,label} tuple or a list of them for a roamer.
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
io.stderr:write(string.format("dumped %d location rows from MC.LOC\n", locCount))

-- Generated lookup tables the Scanner reads at scan time rather than fields on
-- a row: MC.RecipeWaypoints (recipe id -> waypoint) and MC.RecipeTrainers
-- (recipe id -> per-faction trainer). They carry thousands of pins that no
-- RegisterContent call ever mentions, so a dump that only walked registered
-- content would silently lose all of them.
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
io.stderr:write(string.format("dumped %d recipe waypoints and %d trainer entries\n", wpN, trN))

-- The per-profession recipe tables are assigned directly rather than
-- registered, so pick them up from the namespace.
local LIST_KEY = {
    mounts = "mounts", pets = "pets", toys = "toys", decorations = "decorations",
    rares = "rares", treasures = "treasures", achievements = "achievements",
    recipes = "recipes",
}

-- Group identity has to be emitted, not inferred. The group meta is repeated on
-- every row, so two distinct groups whose meta happens to match are
-- indistinguishable downstream and would collapse into one. A running ordinal
-- per expansion+module keeps them apart and preserves file order.
local groupOrd = {}

local rows = 0
for _, cap in ipairs(captured) do
    local listKey = LIST_KEY[cap.module] or cap.module
    local ordKey = cap.expansion .. "/" .. cap.module
    for _, group in ipairs(cap.groups) do
        groupOrd[ordKey] = (groupOrd[ordKey] or -1) + 1
        local gOrd = groupOrd[ordKey]
        local entries = group[listKey] or group.items or {}
        -- Group-level attributes travel with every row; the emitter regroups.
        local groupMeta = {}
        for k, v in pairs(group) do
            if k ~= listKey and k ~= "items" and type(v) ~= "function" then groupMeta[k] = v end
        end
        for i, entry in ipairs(entries) do
            rows = rows + 1
            print(encode({
                __kind    = "collectible",
                expansion = cap.expansion,
                module    = cap.module,
                groupOrd  = gOrd,
                entryOrd  = i - 1,
                group     = groupMeta,
                entry     = entry,
            }))
        end
        -- A group with no entries still carries meaning for rares/treasures,
        -- where the achievement itself is the record.
        if #entries == 0 then
            rows = rows + 1
            print(encode({
                __kind    = "collectible",
                expansion = cap.expansion,
                module    = cap.module,
                groupOrd  = gOrd,
                entryOrd  = 0,
                group     = groupMeta,
                entry     = {},
            }))
        end
    end
end

io.stderr:write(string.format("dumped %d rows from %d RegisterContent calls (%d files skipped)\n",
    rows, #captured, skipped))
