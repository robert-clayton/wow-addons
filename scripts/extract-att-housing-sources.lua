-- Loads All The Things' generated Housing category with lightweight factory
-- stubs and emits every decor occurrence plus its acquisition ancestry as CSV.

local path = assert(arg[1], "usage: luajit extract-att-housing-sources.lua <Housing.lua>")

local categories = {}
local app = {}

local function factory(kind)
    return function(id, data)
        data = data or {}
        data.__kind = kind
        data.__id = id
        return data
    end
end

app.CreateAchievement = factory("achievement")
app.CreateHeader = factory("header")
app.CreateWarbandScene = factory("warband_scene")
app.CreateCharacterUnlockQuest = factory("character_unlock_quest")
app.CreateAchievementCriteria = factory("criteria")
app.CreateCurrencyClass = factory("currency")
app.CreateDecor = factory("decor")
app.CreateExploration = factory("exploration")
app.CreateFilter = factory("filter")
app.CreateFlightPath = factory("flight_path")
app.CreateCustomHeader = factory("custom_header")
app.CreateHQT = factory("hqt")
app.CreateItem = factory("item")
app.CreateMap = factory("map")
app.CreateNPC = factory("npc")
app.CreateObject = factory("object")
app.CreateProfession = factory("profession")
app.CreateQuest = factory("quest")
app.CreateRecipe = factory("recipe")
app.CreateTitle = factory("title")
app.AddEventHandler = function(_, callback) callback(categories) end

assert(loadfile(path))("ATT", app)

local function csv(value)
    local text = tostring(value or "")
    return '"' .. text:gsub('"', '""') .. '"'
end

local function addMap(set, value)
    local numeric = tonumber(value)
    if numeric and numeric > 0 then set[numeric] = true end
end

local function collectMaps(node, set)
    if node.__kind == "map" then addMap(set, node.__id) end
    if type(node.maps) == "table" then
        for _, mapID in pairs(node.maps) do addMap(set, mapID) end
    end
    if type(node.coords) == "table" then
        for mapID in pairs(node.coords) do addMap(set, mapID) end
    end
end

local rows = {}
local function visit(node, ancestors)
    if type(node) ~= "table" then return end

    local nextAncestors = {}
    for index, ancestor in ipairs(ancestors) do nextAncestors[index] = ancestor end
    nextAncestors[#nextAncestors + 1] = node

    if node.__kind == "decor" then
        local maps = {}
        local ancestry = {}
        local patches = {}
        local sourceKind, sourceID = "", ""
        for _, ancestor in ipairs(nextAncestors) do
            collectMaps(ancestor, maps)
            if ancestor.__kind then
                ancestry[#ancestry + 1] = ancestor.__kind .. ":" .. tostring(ancestor.__id or "")
                if ancestor.__kind ~= "decor" and ancestor.__kind ~= "header" and
                   ancestor.__kind ~= "custom_header" and ancestor.__kind ~= "filter" then
                    sourceKind, sourceID = ancestor.__kind, ancestor.__id or ""
                end
            end
            if ancestor.awp then patches[tonumber(ancestor.awp) or ancestor.awp] = true end
        end
        local mapList, patchList = {}, {}
        for mapID in pairs(maps) do mapList[#mapList + 1] = mapID end
        for patch in pairs(patches) do patchList[#patchList + 1] = patch end
        table.sort(mapList)
        table.sort(patchList)
        rows[#rows + 1] = {
            decorID = node.__id,
            itemID = node.itemID,
            sourceKind = sourceKind,
            sourceID = sourceID,
            maps = table.concat(mapList, ";"),
            patches = table.concat(patchList, ";"),
            ancestry = table.concat(ancestry, ">"),
        }
    end

    if type(node.g) == "table" then
        for _, child in pairs(node.g) do visit(child, nextAncestors) end
    end
    -- ATT also uses array-style factory payloads whose children live directly
    -- on the node rather than under `g`.
    for key, child in pairs(node) do
        if type(key) == "number" then visit(child, nextAncestors) end
    end
end

visit(categories.Housing, {})
table.sort(rows, function(a, b)
    local aID, bID = tonumber(a.decorID) or 0, tonumber(b.decorID) or 0
    if aID ~= bID then return aID < bID end
    if a.maps ~= b.maps then return a.maps < b.maps end
    return a.ancestry < b.ancestry
end)

print("decor_id,item_id,source_kind,source_id,map_ids,available_patches,ancestry")
for _, row in ipairs(rows) do
    print(table.concat({
        csv(row.decorID), csv(row.itemID), csv(row.sourceKind), csv(row.sourceID),
        csv(row.maps), csv(row.patches), csv(row.ancestry),
    }, ","))
end
