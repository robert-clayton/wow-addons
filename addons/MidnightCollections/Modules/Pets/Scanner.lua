local _, MC = ...

local mod = MC.modulesByKey["pets"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

function Scanner:Scan()
    if not MC.PetData then return end

    wipe(self.results)

    local result = {
        total          = 0,
        collectedCount = 0,
        uncollectedCount = 0,
        bySource       = {},
        collected      = {},
    }

    local hideTradingPost = mod.db and mod.db.hideTradingPost
    for _, group in ipairs(MC.PetData) do
        if hideTradingPost and group.source == "tradingpost" then
            -- skip entirely
        else
        for _, pet in ipairs(group.pets) do
            result.total = result.total + 1

            local numCollected, maxAllowed = 0, 1
            if C_PetJournal and C_PetJournal.GetNumCollectedInfo then
                local ok, nc, ma = pcall(C_PetJournal.GetNumCollectedInfo, pet.speciesID)
                if ok and nc then numCollected = nc end
                if ok and ma then maxAllowed = ma end
            end
            local isCollected = numCollected > 0

            -- Enrich with live data
            local icon, petType = nil, pet.petType
            if C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID then
                local ok, _, petIcon, petPetType = pcall(C_PetJournal.GetPetInfoBySpeciesID, pet.speciesID)
                if ok and petIcon and petIcon ~= 0 and petIcon ~= "" then icon = petIcon end
                if ok and petPetType and petPetType > 0 then petType = petPetType end
            end

            local entry = {
                speciesID     = pet.speciesID,
                name          = pet.name,
                petType       = petType,
                source        = pet.source,
                sourceInfo    = pet.sourceInfo,
                waypoint      = pet.waypoint,
                cost          = pet.cost,
                dropInfo      = pet.dropInfo,
                achievementID = pet.achievementID,
                canBattle     = pet.canBattle,
                zone          = pet.zone,
                renown        = pet.renown,
                icon          = icon,
                collected     = isCollected,
            }

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
        end -- else (not hidden)
    end

    self.results = result
end
