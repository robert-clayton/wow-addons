-- Extracts acquisition ancestry for a given node kind from All The Things'
-- compiled category files.
--
--   luajit extract-att-sources.lua <kind> <Category.lua> [<Category.lua> ...]
--
-- <kind> is the ATT factory alias: "r" recipes, "s" item sources (transmog),
-- "de" decor, "i" items, "toy", "mnt", "p" pets. Emits CSV to stdout.
--
-- Why this does not just loadfile() the category the way
-- extract-att-housing-sources.lua does: LuaJIT caps a chunk at 65536
-- constants, and every ATT category above ~1MB blows straight through it --
-- Zones (8.2MB), Instances (3.1), PVP (2.9), ExpansionFeatures (2.2),
-- NeverImplemented (1.7), WorldEvents (1.0). Those are exactly the files that
-- hold the acquisition data. The stub-factory approach only works on the small
-- categories (Housing, TradingPost).
--
-- So this reads the source as text and tracks bracket depth instead, keeping a
-- stack of (alias, id) frames. It never evaluates the Lua, so file size is
-- irrelevant. Measured at ~0.6s for all seven large categories.

local KIND = assert(arg[1], "usage: extract-att-sources.lua <kind> <file> [...]")
assert(arg[2], "usage: extract-att-sources.lua <kind> <file> [...]")

-- Frames that describe grouping, not acquisition. The source parent is the
-- nearest enclosing frame that is none of these.
--
-- Aliases are declared on line 4 of every compiled category; decode them from
-- there rather than guessing. The non-obvious ones: `ah` is Header and `h` is
-- CustomHeader (both pure grouping), `x` is Expansion, and `exp` is
-- Exploration -- NOT expansion -- so it is deliberately absent here.
-- Attributing a recipe to a header or an expansion tells a player nothing
-- about where to get it.
local STRUCTURAL = {
    h    = true,  -- CustomHeader
    ah   = true,  -- Header
    x    = true,  -- Expansion
    cat  = true,  -- Category
    flt  = true,  -- Filter
    cl   = true,  -- CharacterClass
    prof = true,  -- Profession (which profession teaches it is not a source)
    title = true,
}
-- Frames carrying a map id, used for the zone column.
local MAP_ALIAS = { m = true }

local function csv(v)
    return '"' .. tostring(v or ""):gsub('"', '""') .. '"'
end

-- Pulls "coords={{x,y}}" or "coords={[map]={{x,y}}}" out of a node's own
-- table text. Called only for the resolved source parent, on a bounded window
-- starting at the node's "(" -- coords appear in the node's own fields, well
-- before any nested g={...}.
local function coordsAt(src, pos)
    local window = src:sub(pos, pos + 600)
    local g = window:find("g%s*=%s*{")
    if g then window = window:sub(1, g) end
    local body = window:match("coords%s*=%s*(%b{})")
    if not body then return nil, nil, nil end
    local map = body:match("%[(%d+)%]")
    local x, y = body:match("{%s*(%-?[%d%.]+)%s*,%s*(%-?[%d%.]+)")
    return x, y, map
end

local rows = {}

local function scan(path)
    local fh = assert(io.open(path, "rb"), "cannot open " .. path)
    local src = fh:read("*a")
    fh:close()
    local file = path:match("[^/\\]+$")

    local stack = {}
    local i, n = 1, #src
    local inStr, strQ, esc = false, nil, false

    while i <= n do
        local c = src:sub(i, i)

        if inStr then
            if esc then esc = false
            elseif c == "\\" then esc = true
            elseif c == strQ then inStr = false end

        elseif c == '"' or c == "'" then
            inStr, strQ = true, c

        elseif c == "-" and src:sub(i + 1, i + 1) == "-" then
            -- Line comment: ATT emits trailing "-- Name" comments that can
            -- contain apostrophes and parens. Skip to end of line so they
            -- never disturb the depth or string state.
            local nl = src:find("\n", i, true)
            i = nl or n
            if not nl then break end

        elseif c == "(" then
            -- The alias is the identifier immediately left of the paren.
            local j = i - 1
            while j >= 1 and src:sub(j, j):match("[%w_]") do j = j - 1 end
            local alias = src:sub(j + 1, i - 1)
            local id = src:match("^%(%s*(%-?%d+)", i)
            stack[#stack + 1] = { alias = alias, id = id, pos = i }

            if alias == KIND and id then
                local ancestry, parent, mapID = {}, nil, nil
                for d = 1, #stack - 1 do
                    local fr = stack[d]
                    if fr.alias ~= "" and fr.id then
                        ancestry[#ancestry + 1] = fr.alias .. ":" .. fr.id
                        if MAP_ALIAS[fr.alias] then mapID = fr.id end
                        if not STRUCTURAL[fr.alias] then parent = fr end
                    end
                end
                local x, y, cmap
                if parent then x, y, cmap = coordsAt(src, parent.pos) end
                rows[#rows + 1] = {
                    id          = id,
                    file        = file,
                    parentKind  = parent and parent.alias or "",
                    parentID    = parent and parent.id or "",
                    mapID       = cmap or mapID or "",
                    x           = x or "",
                    y           = y or "",
                    ancestry    = table.concat(ancestry, ">"),
                }
            end

        elseif c == ")" then
            if #stack > 0 then stack[#stack] = nil end
        end

        i = i + 1
    end
end

for k = 2, #arg do scan(arg[k]) end

table.sort(rows, function(a, b)
    local ai, bi = tonumber(a.id) or 0, tonumber(b.id) or 0
    if ai ~= bi then return ai < bi end
    if a.file ~= b.file then return a.file < b.file end
    return a.ancestry < b.ancestry
end)

print("id,att_file,source_parent_kind,source_parent_id,map_id,coord_x,coord_y,ancestry")
for _, r in ipairs(rows) do
    print(table.concat({
        csv(r.id), csv(r.file), csv(r.parentKind), csv(r.parentID),
        csv(r.mapID), csv(r.x), csv(r.y), csv(r.ancestry),
    }, ","))
end
