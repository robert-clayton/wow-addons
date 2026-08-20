-- Loads All The Things' generated Trading Post category with lightweight
-- factory stubs and emits every mount, pet, and toy occurrence as CSV.

local path = assert(arg[1], "usage: luajit extract-att-trading-post-sources.lua <TradingPost.lua>")

local categories = {}
local app = {}

local function factory(kind)
    return function(id, data, extra)
        if type(data) ~= "table" then data = type(extra) == "table" and extra or {} end
        data.__kind = kind
        data.__id = id
        return data
    end
end

app.CreateAchievement = factory("achievement")
app.CreateAchievementCriteria = factory("criteria")
app.CreateEnsemble = factory("ensemble")
app.CreateFilter = factory("filter")
app.CreateCustomHeader = factory("header")
app.CreateMount = factory("mount")
app.CreateNPC = factory("npc")
app.CreateSpecies = factory("pet")
app.CreateQuest = factory("quest")
app.CreateItemSource = factory("item_source")
app.CreateToy = factory("toy")
app.AddEventHandler = function(_, callback) callback(categories) end

assert(loadfile(path))("ATT", app)

local function csv(value)
    local text = tostring(value or "")
    return '"' .. text:gsub('"', '""') .. '"'
end

local rows = {}
local function visit(node, context)
    if type(node) ~= "table" then return end

    local availablePatch = context.availablePatch
    local removedPatch = context.removedPatch
    if node.awp then availablePatch = tonumber(node.awp) or node.awp end
    if node.rwp then removedPatch = tonumber(node.rwp) or node.rwp end

    if node.__kind == "mount" or node.__kind == "pet" or node.__kind == "toy" then
        rows[#rows + 1] = {
            kind = node.__kind,
            sourceID = node.__id,
            itemID = node.itemID,
            spellID = node.spellID,
            availablePatch = availablePatch,
            removedPatch = removedPatch,
            availability = node.u,
        }
    end

    if type(node.g) == "table" then
        local nextContext = {
            availablePatch = availablePatch,
            removedPatch = removedPatch,
        }
        for _, child in ipairs(node.g) do visit(child, nextContext) end
    end
    local nextContext = {
        availablePatch = availablePatch,
        removedPatch = removedPatch,
    }
    for key, child in pairs(node) do
        if type(key) == "number" then visit(child, nextContext) end
    end
end

visit(categories.TradingPost, {})
table.sort(rows, function(a, b)
    if a.kind ~= b.kind then return a.kind < b.kind end
    local aID, bID = tonumber(a.sourceID) or 0, tonumber(b.sourceID) or 0
    if aID ~= bID then return aID < bID end
    return (tonumber(a.availablePatch) or 0) < (tonumber(b.availablePatch) or 0)
end)

print("kind,source_id,item_id,spell_id,available_patch,removed_patch,availability")
for _, row in ipairs(rows) do
    print(table.concat({
        csv(row.kind), csv(row.sourceID), csv(row.itemID), csv(row.spellID),
        csv(row.availablePatch), csv(row.removedPatch), csv(row.availability),
    }, ","))
end
