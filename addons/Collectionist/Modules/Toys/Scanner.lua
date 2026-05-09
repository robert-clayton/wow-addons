local _, MC = ...

local mod = MC.modulesByKey["toys"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

function Scanner:Scan()
    if not MC.ToyData then return end

    local result = {
        total            = 0,
        collectedCount   = 0,
        uncollectedCount = 0,
        bySource         = {},
        collected        = {},
    }

    local hasToyAPI  = PlayerHasToy ~= nil
    local hasInfoAPI = C_ToyBox and C_ToyBox.GetToyInfo

    for _, group in ipairs(MC.ToyData) do
        for _, toy in ipairs(group.toys) do
            local isCollected = false
            if hasToyAPI and toy.itemID and toy.itemID > 0 then
                isCollected = PlayerHasToy(toy.itemID) and true or false
            end

            -- Live name + icon from C_ToyBox (the data file is the canonical
            -- name; live API just refines if Wowhead and the client disagree).
            local icon, toyName = nil, toy.name
            if hasInfoAPI and toy.itemID and toy.itemID > 0 then
                local _, name, fileID = C_ToyBox.GetToyInfo(toy.itemID)
                if name and name ~= "" then toyName = name end
                if fileID and fileID ~= 0 then icon = fileID end
            end

            local entry = {
                itemID            = toy.itemID,
                name              = toyName,
                source            = toy.source,
                sourceInfo        = toy.sourceInfo,
                waypoint          = toy.waypoint,
                overworldWaypoint = toy.overworldWaypoint,
                cost              = toy.cost,
                dropInfo          = toy.dropInfo,
                achievementID     = toy.achievementID,
                taskList          = toy.taskList,
                zone              = toy.zone,
                renown            = toy.renown,
                icon              = icon,
                collected         = isCollected,
            }

            local hideUnavailable = mod.db == nil or mod.db.hideUnavailable ~= false
            if toy.unavailable and not isCollected and hideUnavailable then
                -- skip discontinued toys the player doesn't own
            else
                result.total = result.total + 1
                if isCollected then
                    result.collectedCount = result.collectedCount + 1
                    result.collected[#result.collected + 1] = entry
                else
                    result.uncollectedCount = result.uncollectedCount + 1
                    local src = toy.source
                    if not result.bySource[src] then result.bySource[src] = {} end
                    result.bySource[src][#result.bySource[src] + 1] = entry
                end
            end
        end
    end

    self.results = result
end
