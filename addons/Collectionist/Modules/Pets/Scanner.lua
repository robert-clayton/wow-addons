local _, MC = ...

local mod = MC.modulesByKey["pets"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

function Scanner:Scan()
    if not MC.PetData then return end

    -- See Mounts/Scanner.lua for the rationale on totalAll.
    local result = {
        total              = 0,
        collectedCount     = 0,
        uncollectedCount   = 0,
        totalAll           = 0,
        collectedCountAll  = 0,
        byExpansion        = {},
        score              = 0,
        legacyScore        = 0,
        legacyCount        = 0,
        bySource           = {},
        collected          = {},
    }

    local hideTradingPost = mod.db and mod.db.hideTradingPost
    local hasGetNum  = C_PetJournal and C_PetJournal.GetNumCollectedInfo
    local hasGetInfo = C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID
    for _, group in ipairs(MC.PetData) do
        local visible = MC.IsGroupVisible(group)
        if not (hideTradingPost and group.source == "tradingpost") then
            for _, pet in ipairs(group.pets) do
                local numCollected = 0
                if hasGetNum then
                    numCollected = C_PetJournal.GetNumCollectedInfo(pet.speciesID) or 0
                end
                local isCollected = numCollected > 0

                local hideUnavailable = mod.db == nil or mod.db.hideUnavailable ~= false
                if not (pet.unavailable and not isCollected and hideUnavailable) then
                    result.totalAll = result.totalAll + 1
                    if isCollected then
                        result.collectedCountAll = result.collectedCountAll + 1
                        local w = MC.ScoreFor(pet)
                        if pet.unavailable then
                            result.legacyCount = result.legacyCount + 1
                            result.legacyScore = result.legacyScore + w
                        else
                            result.score = result.score + w
                        end
                    end

                    local exp = pet.expansion or group.expansion or "_unknown"
                    local b = result.byExpansion[exp]
                    if not b then
                        b = { total = 0, collected = 0 }
                        result.byExpansion[exp] = b
                    end
                    b.total = b.total + 1
                    if isCollected then b.collected = b.collected + 1 end

                    if visible then
                        local icon, petType = nil, pet.petType
                        if hasGetInfo then
                            local _, petIcon, petPetType = C_PetJournal.GetPetInfoBySpeciesID(pet.speciesID)
                            if petIcon and petIcon ~= 0 and petIcon ~= "" then icon = petIcon end
                            if petPetType and petPetType > 0 then petType = petPetType end
                        end

                        local entry = {
                            speciesID         = pet.speciesID,
                            name              = pet.name,
                            petType           = petType,
                            source            = pet.source,
                            sourceInfo        = pet.sourceInfo,
                            waypoint          = pet.waypoint,
                            overworldWaypoint = pet.overworldWaypoint,
                            cost              = pet.cost,
                            dropInfo          = pet.dropInfo,
                            achievementID     = pet.achievementID,
                            taskList          = pet.taskList,
                            canBattle         = pet.canBattle,
                            zone              = pet.zone,
                            renown            = pet.renown,
                            icon              = icon,
                            collected         = isCollected,
                            expansion         = pet.expansion,
                        }
                        result.total = result.total + 1
                        if isCollected then
                            result.collectedCount = result.collectedCount + 1
                            result.collected[#result.collected + 1] = entry
                        else
                            result.uncollectedCount = result.uncollectedCount + 1
                            local src = pet.source
                            if not result.bySource[src] then result.bySource[src] = {} end
                            result.bySource[src][#result.bySource[src] + 1] = entry
                        end
                    end
                end
            end
        end
    end

    self.results = result
end
