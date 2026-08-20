-- Builds a name dictionary from All The Things' DATAS sources.
--
--   <list of .lua paths on stdin> | luajit extract-att-names.lua
--
-- Emits "kind,id,name" CSV for NPCs, quests and objects.
--
-- Paths arrive on stdin rather than argv because DATAS holds ~2000 files --
-- far past the Windows command-line limit -- and because directory recursion
-- from inside Lua would mean io.popen, which resolves against cmd.exe here and
-- against sh elsewhere. The caller enumerates (Get-ChildItem / find) and pipes.
--
-- Why here and not from DB2: the client's Creature export available to this
-- repo is truncated (~23k rows, missing most vendors), and the compiled ATT
-- categories strip names entirely -- they read them from the client at
-- runtime. The uncompiled DATAS sources, however, carry them as trailing
-- comments on each node:
--
--   n(4168, {  -- Elynna <Tailoring Supplies>
--
-- That comment is the only offline source for these names, so this scrapes it.

local files = {}
for line in io.lines() do
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" then files[#files + 1] = line end
end
assert(#files > 0, "no input paths on stdin")

local names = { n = {}, q = {}, o = {} }
local counts = { n = 0, q = 0, o = 0 }

for _, path in ipairs(files) do
    local fh = io.open(path, "rb")
    if fh then
        for line in fh:lines() do
            -- "n(4168, {  -- Elynna <Tailoring Supplies>"
            -- Split the trailing comment off first, then read the node that
            -- opens on the same line. Lua patterns have no alternation, so the
            -- kind is captured generically and filtered below.
            local body, name = line:match("^(.-)%-%-%s*(.+)$")
            local kind, id
            if body then kind, id = body:match("([%a_][%w_]*)%(%s*(%d+)") end
            if kind and id and names[kind] and not names[kind][id] then
                -- Strip ATT's patch/status suffixes: "[TBC+]", "[REMOVED: 4.0.3]"
                name = name:gsub("%s*%[[^%]]*%]%s*$", "")
                -- Some entries carry "/ variant" alternates; keep the first.
                name = name:gsub("%s*/%s*.*$", "")
                name = name:gsub("^%s+", ""):gsub("%s+$", "")
                if name ~= "" and not name:match("^%-%-") then
                    names[kind][id] = name
                    counts[kind] = counts[kind] + 1
                end
            end
        end
        fh:close()
    end
end

local function csv(v)
    return '"' .. tostring(v or ""):gsub('"', '""') .. '"'
end

print("kind,id,name")
for _, kind in ipairs({ "n", "q", "o" }) do
    local ids = {}
    for id in pairs(names[kind]) do ids[#ids + 1] = id end
    table.sort(ids, function(a, b) return (tonumber(a) or 0) < (tonumber(b) or 0) end)
    for _, id in ipairs(ids) do
        print(table.concat({ csv(kind), csv(id), csv(names[kind][id]) }, ","))
    end
end

io.stderr:write(string.format(
    "extract-att-names: %d files, npc=%d quest=%d object=%d\n",
    #files, counts.n, counts.q, counts.o))
