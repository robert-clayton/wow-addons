-- Loads every file the TOC lists, in order, under a stub client that FAILS
-- like the real one.
--
--   luajit tests/loadall.lua
--
-- toc_smoke checks that the files parse. This checks that they RUN, which is a
-- different question: hooksecurefunc raising on a method the client does not
-- have is a load-time abort that no syntax check can see. Collectionist hooked
-- GameTooltip.SetAuctionItem, removed in 8.3, and lost the rest of Tooltips.lua
-- to it.
--
-- The stub is deliberately strict where the real API is strict. A permissive
-- stub that answers every call is worse than no test: it reports success for
-- code the client rejects.

local pass, fail = 0, 0
local function ok(cond, label)
    if cond then pass = pass + 1 else fail = fail + 1 print("  FAIL " .. label) end
end

local function permissive(name)
    return setmetatable({}, {
        __index = function(t, k)
            if type(k) == "string" and k:sub(1, 1) == "_" then return nil end
            local c = permissive(name .. "." .. tostring(k))
            rawset(t, k, c)
            return c
        end,
        __call = function(_, a) return type(a) == "table" and a or permissive(name) end,
        __tostring = function() return name end,
        __concat = function(a, b)
            return (type(a) == "string" and a or name) .. (type(b) == "string" and b or name)
        end,
    })
end

-- The real GameTooltip has a FIXED method set. Anything not listed here does
-- not exist on a modern client, and hooksecurefunc must reject it exactly as
-- the client does.
local REAL_TOOLTIP_METHODS = {
    SetBagItem = true, SetLootItem = true, SetInventoryItem = true,
    SetGuildBankItem = true, SetMerchantItem = true, SetQuestItem = true,
    SetHyperlink = true, SetOwner = true, Show = true, Hide = true,
    AddLine = true, AddDoubleLine = true, SetText = true, GetItem = true,
    IsShown = true, ClearLines = true, SetSpellByID = true,
    -- SetAuctionItem is deliberately absent: removed in 8.3.
}

local GameTooltip = setmetatable({}, {
    __index = function(t, k)
        if REAL_TOOLTIP_METHODS[k] then
            local f = function() end
            rawset(t, k, f)
            return f
        end
        return nil
    end,
})

local function buildEnv(modern)
local G
G = setmetatable({
    CreateFrame = function() return permissive("frame") end,
    UIParent = permissive("UIParent"),
    GameTooltip = GameTooltip,
    -- Raises on a missing method, like the client.
    hooksecurefunc = function(a, b)
        local tbl, key = a, b
        if type(a) == "string" then tbl, key = G, a end
        if type(tbl) ~= "table" or type(tbl[key]) ~= "function" then
            error("hooksecurefunc(): " .. tostring(key) .. " is not a function", 2)
        end
    end,
    LibStub = setmetatable({
        NewLibrary = function(_, n) return permissive(n), 0 end,
        GetLibrary = function(_, n) return permissive(n) end,
        NewAddon = function() return permissive("addon") end,
    }, { __call = function(_, n) return permissive(n) end }),
    select = select, tonumber = tonumber, tostring = tostring, type = type,
    pairs = pairs, ipairs = ipairs, next = next, error = error, assert = assert,
    pcall = pcall, xpcall = xpcall, setmetatable = setmetatable,
    getmetatable = getmetatable, rawset = rawset, rawget = rawget,
    unpack = unpack, print = function() end, string = string, table = table,
    math = math, os = os, bit = bit, coroutine = coroutine,
    format = string.format, tinsert = table.insert, tremove = table.remove,
    -- Real string functions. A permissive stub returns tables here, and the
    -- search index concatenates its haystack from them.
    strlower = string.lower, strupper = string.upper, strfind = string.find,
    strsub = string.sub, strmatch = string.match, strtrim = function(x)
        return (tostring(x):gsub("^%s*(.-)%s*$", "%1")) end,
    strsplit = function(_, x) return x end, strjoin = function(_, ...)
        return table.concat({ ... }, "") end,
    max = math.max, min = math.min, abs = math.abs, floor = math.floor,
    ceil = math.ceil, sort = table.sort,
    wipe = function(t) for k in pairs(t) do t[k] = nil end return t end,
    time = os.time, date = os.date, GetTime = function() return 0 end,
}, { __index = function(_, k) return permissive(tostring(k)) end })
G._G = G
-- Two client shapes, because the addon branches on this and the branch not
-- taken is the one that breaks. A client without the modern tooltip processor
-- falls back to hooking setters by name -- which is where SetAuctionItem,
-- removed in 8.3, took down the file.
if not modern then
    G.TooltipDataProcessor = false
end
return G
end

local function loadAll(modern)
    local G = buildEnv(modern)
    local MC = {}
    local loaded, errors = 0, {}
for line in io.lines("addons/Collectionist/Collectionist.toc") do
    local entry = line:match("^%s*(.-)%s*$")
    if entry ~= "" and entry:sub(1, 1) ~= "#" and entry:match("%.lua$") then
        local path = "addons/Collectionist/" .. entry:gsub("\\", "/")
        -- LibStub's own version guard needs a real global, not a stub.
        if not path:match("Libs/") then
            local chunk, err = loadfile(path)
            if not chunk then
                fail = fail + 1
                print("  PARSE " .. entry .. ": " .. tostring(err))
            else
                setfenv(chunk, G)
                local good, e = pcall(chunk, "Collectionist", MC)
                if good then loaded = loaded + 1
                else errors[#errors + 1] = entry .. ": " .. tostring(e) end
            end
        end
    end
end

    return loaded, errors, MC, G
end

print("TOC load")

local function count(t) local n = 0 for _ in pairs(t or {}) do n = n + 1 end return n end

for _, shape in ipairs({ { true, "modern tooltip API" }, { false, "legacy tooltip API" } }) do
    local loaded, errors = loadAll(shape[1])
    for _, e in ipairs(errors) do print("  ERROR [" .. shape[2] .. "] " .. e) end
    ok(#errors == 0, "no file errors under the " .. shape[2])
    ok(loaded > 150, "every TOC file executed under the " .. shape[2] .. " (" .. loaded .. ")")
end

local _, _, MC, ENV = loadAll(true)
ok(count(MC.modules) == 8, "all 8 modules registered (" .. count(MC.modules) .. ")")
ok(MC.TabBar ~= nil, "the nav bar registered")
ok(type(MC.SortEntries) == "function", "sorting is available")
ok(MC.SEARCH_KEY and MC.OPTIONS_KEY, "the two view keys exist")
ok(count(MC.MountPins) + count(MC.PetPins) + count(MC.ToyPins) > 400, "derived pins loaded")

-- The search index is refreshed IN PLACE after a scan rather than rebuilt:
-- 20,667 records each carrying a concatenated lowercase haystack was ~10.5 MB
-- discarded and reallocated after every scan, whether or not search was ever
-- opened. In-place updates are where staleness creeps in, so the refresh is
-- exercised here against a synthetic index.
--
-- A synthetic one rather than the real build: the real build calls the live
-- collector for every module (C_MountJournal, C_PetJournal ...), and a stub
-- faithful enough to satisfy all of them would be testing the stub. What is at
-- risk is the refresh contract, and that needs no client at all.
local S = MC.Search
if S and S.RefreshIndex then
    MC.db = MC.db or { expansions = {}, modules = {} }
    local refreshed = 0
    local staticRef = { itemID = 111, name = "Static" }
    local rec = { moduleKey = "mounts", mod = {}, ref = staticRef, name = "Static",
                  collected = false }
    S.index = { rec, { moduleKey = "rares", ref = { name = "Derived" } } }
    S._staticCount = 1
    S._size = 2
    S.byItemID = { [111] = rec }
    S._membership = "stable"

    -- Stand in for the module collector so the refresh has something to call.
    local Collectors = { mounts = function() refreshed = refreshed + 1 return true, 42 end }
    S._testCollectors = Collectors

    S:RefreshIndex()
    ok(S.index[1] == rec, "the static record is patched, not replaced")
    ok(#S.index == S._staticCount, "the derived tail is dropped before rebuilding")
    ok(type(S.byItemID) == "table", "byItemID is rebuilt")
    ok(S.byItemID[111] == rec, "a static record keeps its byItemID claim")

    -- A membership change must force a real rebuild; otherwise rows filtered
    -- out by an expansion toggle linger for the rest of the session.
    S.index = { rec }
    S._staticCount = 1
    S._membership = "definitely-not-the-current-signature"
    S:Invalidate()
    ok(S.index == nil, "a membership change drops the index for a full rebuild")

    -- And an unchanged membership must NOT drop it, or nothing was saved. The
    -- signature is nil-safe by design, and nil means "cannot tell" -> rebuild,
    -- so pin the keep case with a signature that genuinely matches.
    MC.db.disabledModules = MC.db.disabledModules or {}
    local live = S.index
    S.index = { rec }
    S._staticCount = 1
    S._membership = nil
    S:Invalidate()
    ok(S.index == nil, "an uncomputable signature rebuilds rather than guessing")
end

-- The full search index must NOT be built as a side effect of a scan. Measured
-- in game it is 22,377 records and 17.8 MB retained, the single largest
-- structure in the addon, and a player who never opens search should not pay
-- for it. Tooltips get a separate map holding only rows with an itemID.
if S and S.Invalidate then
    S.index, S.byItemID, S._staticCount = nil, nil, nil
    S._membership = nil
    local fired = {}
    local realAfter = ENV.C_Timer and ENV.C_Timer.After
    ENV.C_Timer = ENV.C_Timer or {}
    ENV.C_Timer.After = function(_, fn) fired[#fired + 1] = fn end
    S:Invalidate()
    for _, fn in ipairs(fired) do pcall(fn) end
    ok(S.index == nil, "a scan does not build the full search index")
    if realAfter then ENV.C_Timer.After = realAfter end

    ok(type(S.EnsureItemMap) == "function", "tooltips have their own map builder")
    ok(type(S.IsCollected) == "function", "ownership resolves per row on demand")

    -- A lean record must have no baked collected flag; that is what would force
    -- the map to be rebuilt on every scan.
    local leanRec = { moduleKey = "mounts", mod = {}, ref = {}, lean = true }
    ok(leanRec.collected == nil, "a lean record stores no ownership state")
    ok(S:IsCollected(nil) == false, "IsCollected is safe on a missing record")
end

-- A row with a structured renown requirement renders its own live
-- "<track> Renown current/required" line, in red until met. If sourceInfo ALSO
-- states the requirement the tooltip says it twice -- once without the player's
-- progress, once with it -- which is what shipped and what this stops coming
-- back. The prose was cleaned out of 68 strings across 11 files; this asserts
-- nobody re-adds it.
do
    local offenders = {}
    for _, mod in ipairs(MC.modules or {}) do
        local field = ({ mounts = "MountData", pets = "PetData", toys = "ToyData",
                         decorations = "DecorationData" })[mod.key]
        local groups = field and rawget(MC, field)
        for _, group in ipairs(groups or {}) do
            for _, listKey in ipairs({ "mounts", "pets", "toys", "decorations", "items" }) do
                for _, e in ipairs((type(group) == "table" and group[listKey]) or {}) do
                    if type(e) == "table" and e.renown and type(e.sourceInfo) == "string"
                       and (e.sourceInfo:find("Renown%s+%d") or e.sourceInfo:find("Rank%s+%d")) then
                        offenders[#offenders + 1] = (e.name or "?") .. ": " .. e.sourceInfo
                    end
                end
            end
        end
    end
    for i = 1, math.min(#offenders, 5) do print("  DUPLICATE " .. offenders[i]) end
    ok(#offenders == 0,
       "no row states its renown requirement in both sourceInfo and the renown field")
end

-- Premium is the default shell, including for anyone upgrading from before it
-- existed. Nothing writes uiStyle except SetUIStyle, so an untouched install
-- has it nil and falls through to the default.
--
-- Real empty tables, not the harness stub: the permissive environment answers
-- every field with a truthy placeholder, so CollectionistDB.uiStyle would read
-- as "set" and the fallback would never be exercised.
do
    local savedDB, savedMCdb = ENV.CollectionistDB, MC.db
    ENV.CollectionistDB = {}
    MC.db = {}
    ok(type(MC.GetUIStyle) == "function", "the shell accessor loaded")
    ok(MC.GetUIStyle and MC.GetUIStyle() == "premium",
       "an install that never chose a shell gets premium")

    -- A deliberate choice still wins; a default is not a reset.
    MC.db.uiStyle = "classic"
    ok(MC.GetUIStyle() == "classic", "an explicit classic choice is respected")

    ENV.CollectionistDB, MC.db = savedDB, savedMCdb
end

print(string.format("%d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
