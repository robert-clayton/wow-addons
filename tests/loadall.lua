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

-- Zone text derived from the waypoint. A row carrying only a waypoint used
-- to render an empty location column while its click dropped a pin
-- correctly, so the two now come off the same field.
do
    local savedCMap = ENV.C_Map
    ENV.C_Map = {
        GetMapInfo = function(id)
            -- Ids no shipped row points at. The harness's permissive global
            -- stub answers every C_Map call with a truthy junk string, so any
            -- id the real data load already asked about is memoised before
            -- this stub exists.
            local names = { [990071] = "Tanaris", [990023] = "Eastern Plaguelands" }
            local n = names[id]
            return n and { name = n } or nil
        end,
    }

    local entries = {
        { decorID = 90001, name = "Curated", zone = "Hand Written",
          waypoint = { 990071, 0.5, 0.5, "x" } },
        { decorID = 90002, name = "One Spot",
          waypoint = { 990071, 0.5, 0.5, "x" } },
        { decorID = 90003, name = "Same Map Twice",
          waypoint = { { 990071, 0.1, 0.2, "a" }, { 990071, 0.3, 0.4, "b" } } },
        { decorID = 90004, name = "Two Zones",
          waypoint = { { 990071, 0.1, 0.2, "a" }, { 990023, 0.3, 0.4, "b" } } },
        { decorID = 90005, name = "No Location" },
        { decorID = 90006, name = "Unnamed Map",
          waypoint = { 990999, 0.5, 0.5, "x" } },
        { decorID = 90007, name = "Overworld Only",
          overworldWaypoint = { 990023, 0.5, 0.5, "x" } },
    }
    MC.RegisterContent("midnight", "decorations",
        { { source = "quest", decorations = entries } })

    local byName = {}
    for _, e in ipairs(entries) do byName[e.name] = e.zone end

    ok(byName["Curated"] == "Hand Written", "a hand-written zone is not overwritten")
    ok(byName["One Spot"] == "Tanaris", "a single waypoint names its map")
    ok(byName["Same Map Twice"] == "Tanaris", "spots sharing a map name it once")
    ok(byName["Two Zones"] == "2 locations", "spots across maps report a count")

    -- The second return tells a count apart from a place name. The tooltip
    -- needs that: it prints its own "N possible locations" line and would
    -- otherwise say the same thing twice.
    local oneZone, oneSpread = MC.DeriveZone({ waypoint = { 990071, 0.5, 0.5, "x" } })
    ok(oneZone == "Tanaris" and not oneSpread, "a named zone is not flagged as a count")
    local manyZone, manySpread = MC.DeriveZone({
        waypoint = { { 990071, 0.1, 0.2, "a" }, { 990023, 0.3, 0.4, "b" } } })
    ok(manyZone == "2 locations" and manySpread == true, "a count is flagged as one")
    local curated = select(2, MC.DeriveZone({ zone = "Hand Written",
        waypoint = { { 990071, 0.1, 0.2, "a" }, { 990023, 0.3, 0.4, "b" } } }))
    ok(not curated, "a curated zone is never flagged as a count")
    ok(byName["No Location"] == nil, "a row with no waypoint gets no zone")
    ok(byName["Unnamed Map"] == nil, "a map the client cannot name yields nothing")
    ok(byName["Overworld Only"] == "Eastern Plaguelands",
       "an overworld waypoint counts too")

    ENV.C_Map = savedCMap
end

-- Source-order arrays must not repeat a key. RenderStandardList walks the
-- order list to lay groups out, so a repeated key drew that group's header
-- and every one of its rows a second time -- which reads as duplicated data,
-- not as a layout bug. Patch120100 re-adding "coiled_isle" (already declared
-- in the base file) did exactly that to both Rares and Treasures.
--
-- The library now skips a repeat, so this guards the data rather than the
-- symptom: a duplicate here still means two files disagree about who owns a
-- source key.
do
    local orders = {
        MountSourceOrder = MC.MountSourceOrder,
        PetSourceOrder = MC.PetSourceOrder,
        ToySourceOrder = MC.ToySourceOrder,
        DecoSourceOrder = MC.DecoSourceOrder,
        RareSourceOrder = MC.RareSourceOrder,
        TreasureSourceOrder = MC.TreasureSourceOrder,
    }
    local checked = 0
    for name, arr in pairs(orders) do
        if type(arr) == "table" then
            checked = checked + 1
            local seen = {}
            for _, key in ipairs(arr) do
                ok(not seen[key], name .. " lists " .. tostring(key) .. " once")
                seen[key] = true
            end
        end
    end
    ok(checked >= 6, "found the source-order arrays (" .. checked .. ")")
end

-- Texture escapes in Blizzard's own source strings. A bare filename cannot
-- resolve to a file, and the client then prints the path where the icon
-- should be -- "Cost: 1800(INV_112_RaidTrinkets_VoidPrism.BLP)".
do
    local S = MC.SanitizeGameText
    ok(type(S) == "function", "SanitizeGameText exists")

    ok(S("Cost: 1800|TINV_112_RaidTrinkets_VoidPrism.BLP:0|t") == "Cost: 1800",
       "an escape with no directory is dropped")

    local good = "Cost: 1000|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t"
    ok(S(good) == good, "an escape naming a real directory is kept")

    local forward = "x|TInterface/Icons/Foo.blp:0|t"
    ok(S(forward) == forward, "a forward-slash path is kept")

    ok(S("no escapes here") == "no escapes here", "plain text is untouched")
    ok(S(nil) == nil, "nil passes through")
    ok(S(42) == 42, "a non-string passes through")

    -- Mixed: the resolvable one survives, the bare one goes.
    local mixed = "a|TBare.blp:0|tb|TInterface\\ICONS\\Ok.blp:0|tc"
    ok(S(mixed) == "ab|TInterface\\ICONS\\Ok.blp:0|tc",
       "only the unresolvable escape is removed")
end

-- Horrific Vision maps carry no world position, so TomTom refuses them and
-- C_Map cannot pin them: a waypoint there is one that silently never appears.
-- Both ids are named "Vision of Orgrimmar" and both got pins from the ATT
-- backfill, which had no way to know the difference.
--
-- Phased maps in general are NOT banned here. Daggerspine Point (2594) and
-- the Zul'Aman phase (2585) are legitimately used by curated rows that pair
-- them with an overworldWaypoint giving the entrance, which is what
-- GetSmartWaypoint routes to from outside. The Vision maps have no entrance
-- to offer -- you enter from the Chamber of Heart -- so nothing may point
-- there at all.
do
    local BANNED = { [1469] = "Vision of Orgrimmar (orphan)",
                     [2403] = "Vision of Orgrimmar (phased)" }
    local offenders, checked = {}, 0

    local function check(where, wp)
        if type(wp) ~= "table" then return end
        if type(wp[1]) == "number" then
            checked = checked + 1
            if BANNED[wp[1]] then
                offenders[#offenders + 1] = where .. " -> " .. BANNED[wp[1]]
            end
        else
            for _, spot in ipairs(wp) do check(where, spot) end
        end
    end

    for _, name in ipairs({ "RecipeWaypoints", "RareNPCs", "TreasureCoords",
                            "RareCoords", "LOC" }) do
        local tbl = MC[name]
        if type(tbl) == "table" then
            for key, wp in pairs(tbl) do
                if type(wp) == "table" then check(name .. "." .. tostring(key), wp) end
            end
        end
    end

    local LISTS = { mounts = "MountData", pets = "PetData", toys = "ToyData",
                    decorations = "DecorationData" }
    for listKey, field in pairs(LISTS) do
        for _, group in ipairs(MC[field] or {}) do
            for _, e in ipairs(group[listKey] or {}) do
                check(listKey .. " " .. tostring(e.name), e.waypoint)
                check(listKey .. " " .. tostring(e.name), e.overworldWaypoint)
            end
        end
    end

    ok(checked > 3000, "walked the waypoint tables (" .. checked .. " spots)")
    ok(#offenders == 0, "no waypoint points into a Horrific Vision ("
       .. #offenders .. ": " .. table.concat(offenders, ", ", 1,
          math.min(#offenders, 3)) .. ")")
end

-- API tuples, ID namespaces and navigation paths that previously failed with
-- real journal/provider responses. Use a fresh loaded namespace for isolation.
do
    local _, errors, A, G = loadAll(true)
    ok(#errors == 0, "audit regression fixture loads")
    local currentMap = 2393
    G.UnitFactionGroup = function() return "Alliance" end
    G.C_Map = { GetBestMapForUnit = function() return currentMap end }
    G.IsShiftKeyDown = function() return false end
    G.IsControlKeyDown = function() return false end
    G.IsAltKeyDown = function() return false end
    G.InCombatLockdown = function() return false end
    G.CanShowAchievementUI = function() return true end
    G.C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
    A.IsGroupVisible = function() return true end
    A.IsContentAvailable = function() return true end
    A.PORTALS = nil
    G.C_MountJournal = { GetMountInfoByID = function(id)
        return "Brown Horse", 458, 132261, false, true, 2, false, false, nil, id == 7, id == 6, id
    end }
    G.C_ToyBox = { GetToyInfo = function(id) return id, "Orb of Deception", 133711 end }
    G.PlayerHasToy = function() return false end
    local S = A.Search
    S.index = {
        { moduleKey = "mounts", ref = { mountID = 6, itemID = 5656 } },
        { moduleKey = "mounts", ref = { mountID = 7 } },
        { moduleKey = "toys", ref = { itemID = 1973 } },
    }
    S._staticCount = #S.index
    S:RefreshIndex()
    ok(S.index[1].collected and S.index[1].icon == 132261, "owned mount search uses collected and icon API slots")
    ok(not S.index[2].collected, "hidden unowned mount does not appear collected")
    ok(S.index[3].icon == 133711, "toy search icon is the texture ID")
    ok(S:IsCollected({ moduleKey = "mounts", ref = { mountID = 6 }, lean = true }), "lean item tooltip reports owned mount")

    local recipe = { id = 1261659, name = "Ironforge Chandelier", moduleKey = "recipes" }
    ok(A.RecipeWaypoints[recipe.id] ~= nil, "real supplemental recipe pin exists")
    ok(A.GetSmartWaypoint(recipe) == A.RecipeWaypoints[recipe.id], "raw search recipe resolves supplemental pin")
    local trainerID, trainer
    for id, row in pairs(A.RecipeTrainers) do
        if not A.RecipeWaypoints[id] and row.a and row.h then trainerID, trainer = id, row; break end
    end
    ok(trainerID and A.GetEntryWaypoint({id=trainerID}) == trainer.a, "raw trainer pin uses Alliance location")
    G.UnitFactionGroup = function() return "Horde" end
    ok(trainerID and A.GetEntryWaypoint({id=trainerID}) == trainer.h, "raw trainer pin follows faction on use")
    for _, pair in ipairs({ {"MountPins", "mountID"}, {"PetPins", "speciesID"}, {"ToyPins", "itemID"} }) do
        local id, pin = next(A[pair[1]])
        ok(A.GetEntryWaypoint({[pair[2]]=id}) == pin, pair[1] .. " resolves on raw entries")
        local manual = {1,.4,.4}
        ok(A.GetEntryWaypoint({[pair[2]]=id, waypoint=manual}) == manual, pair[1] .. " preserves curated pin")
    end

    local jimothy
    for _, group in ipairs(A.PetData) do for _, pet in ipairs(group.pets) do
        if pet.speciesID == 5164 then jimothy = pet end
    end end
    local routed = A.GetSmartWaypoint(jimothy)
    ok(A._isWaypointList(routed) and #routed == 3, "all three J'imothy bushes remain marked in Silvermoon")
    local mixed = { waypoint = {{2393,.1,.2}, {2393,.3,.4}, {2395,.5,.6}} }
    ok(#A.GetSmartWaypoint(mixed) == 2, "multi-zone route keeps every local spawn")
    currentMap = 2395
    ok(A.GetSmartWaypoint(mixed) == mixed.waypoint[3], "one local spawn remains a tuple")
    currentMap = nil
    ok(A.GetSmartWaypoint(mixed) == mixed.waypoint, "unknown current map keeps all spawns")
    currentMap = 2393

    local messages, calls = {}, 0
    G.print = function(message) messages[#messages+1] = message end
    G.TomTom = { AddWaypoint = function()
        calls = calls + 1
        if calls == 1 then error("provider rejected map") end
        if calls == 2 then return nil end
        return "uid"
    end }
    ok(pcall(A.DoItemAction, jimothy), "multi-spawn provider error is contained")
    ok(calls == 3 and messages[#messages]:find("Set 1 of 3",1,true), "multi-spawn success counts only accepted pins")
    calls, messages = 0, {}
    local taskItem = {name="Prerequisites", taskList={tasks={
        {questID=1, pickupWaypoint={2393,.1,.2}, waypoint={2393,.3,.4}},
        {questID=2, waypoint={2393,.5,.6}},
    }}}
    ok(pcall(A.DoItemAction, taskItem), "task provider error is contained")
    ok(calls == 3 and messages[#messages]:find("Set 1 of 3",1,true), "task success counts only accepted pins")
    messages = {}
    G.TomTom.AddWaypoint = function() return nil end
    A.DoItemAction(taskItem)
    local claimed = false
    for _, message in ipairs(messages) do if message:find("Set ",1,true) then claimed=true end end
    ok(not claimed, "refused task markers never claim success")

    local types = {27,29,68,0}
    G.GetAchievementNumCriteria = function() return 4 end
    G.GetAchievementCriteriaInfo = function(_, index)
        return "Localized criterion "..index, types[index], false, 0, 1, "", 0, 31284
    end
    A.TreasureData = {{achievementID=7284, criteriaCount=4, source="pandaria",zone="Pandaria",expansion="mop"}}
    local T = A.modulesByKey.treasures.Scanner
    ok(T:Scan(), "typed treasure criteria scan")
    local rows = T.results.bySource.pandaria
    ok(rows[1].questID == 31284 and rows[1].objectID == nil, "quest criterion keeps quest namespace")
    ok(rows[1].waypoint == A.CriteriaWaypoints.quest[31284], "localized criterion finds stable quest coordinates")
    ok(rows[2].objectID == nil and rows[2].npcID == nil and rows[2].questID == nil, "spell criterion is not a physical entity")
    ok(rows[3].objectID == 31284 and rows[3].questID == nil, "object criterion keeps object namespace")
    ok(rows[4].npcID == 31284 and rows[4].questID == nil, "kill criterion keeps NPC namespace")
    local url
    G.StaticPopup_Show = function(_,_,_,value) url=value end
    A.OpenItemWowhead(rows[1]); ok(url == "https://www.wowhead.com/quest=31284", "treasure link is a quest")
    A.OpenItemWowhead(rows[2]); ok(url == "https://www.wowhead.com/achievement=7284", "spell-backed treasure links to achievement")
    A.OpenItemWowhead({npcID=123,questID=456}); ok(url == "https://www.wowhead.com/npc=123", "rare links prefer known NPC over completion flag")
    A.RareData = {{achievementID=1,criteriaCount=3,criteriaNPCIDs={1,2,3},source="pandaria",zone="Pandaria",expansion="mop"}}
    local R=A.modulesByKey.rares.Scanner
    ok(R:Scan(), "rare scan survives changed criterion count")
    ok(R.results.bySource.pandaria[1].npcID == nil and R.results.bySource.pandaria[1].questID == 31284,
       "count mismatch never converts a quest asset to an NPC")

    local decorations = {}
    for _, group in ipairs(A.DecorationData) do for _, item in ipairs(group.decorations or group.items or {}) do
        decorations[item.decorID] = item
    end end
    ok(decorations[1198].itemID == 245290 and decorations[1198].renown.level == 7, "Long Silvermoon Table ID and unlock")
    ok(decorations[1120].itemID == 245291 and decorations[1120].waypoint[1] == 1186, "Mole Machine ID and allied-race map")
    ok(A.CriteriaWaypoints.npc[18695] ~= nil, "Outland rare coordinates are loaded")
    local points=0
    for _, namespace in pairs(A.CriteriaWaypoints) do for id, pins in pairs(namespace) do
        local list = type(pins[1]) == "table" and pins or {pins}
        for _, point in ipairs(list) do
            assert(id > 0 and point[1] > 0 and point[2] > 0 and point[2] < 1 and point[3] > 0 and point[3] < 1,
                "invalid criterion waypoint "..id)
            points=points+1
        end
    end end
    ok(points == 2715, "all audited criterion coordinates are present")
    -- BattlePetSpecies.PetTypeEnum is zero-based; the journal uses 1..10.
    local expected = { [168]=10, [179]=2, [242]=6, [248]=1, [249]=4, [665]=5, [3362]=9, [3243]=10, [3244]=4, [3250]=5, [3251]=3, [3252]=1, [3255]=8, [3297]=9, [3582]=9, [4253]=3, [4286]=6, [4311]=5, [4402]=5, [4407]=5, [4408]=5, [4436]=6, [4548]=1, [4565]=1, [4595]=6, [4615]=1, [4617]=10, [4618]=10, [3542]=7, [4566]=1, [4602]=9, [4669]=6, [4718]=10, [4719]=10, [4728]=1, [4729]=1, [4757]=1, [4793]=8, [4853]=8, [4900]=9 }
    local matched=0
    for _, group in ipairs(A.PetData) do for _, pet in ipairs(group.pets) do
        if expected[pet.speciesID] then
            ok(pet.petType == expected[pet.speciesID], "DB2 family for "..pet.name)
            matched=matched+1
        end
    end end
    ok(matched == 40, "all corrected pet families are present")

end

print(string.format("%d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
