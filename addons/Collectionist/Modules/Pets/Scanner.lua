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
        legacyCount        = 0,
        bySource           = {},
        collected          = {},
    }

    local hideTradingPost = mod.db and mod.db.hideTradingPost
    local hasGetNum  = C_PetJournal and C_PetJournal.GetNumCollectedInfo
    local hasGetInfo = C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID
    for _, group in ipairs(MC.PetData) do
        -- The trading-post toggle only affects what's shown; account-wide
        -- tallies below run for every group so broadcasts don't depend on
        -- per-character display settings.
        local groupVisible = MC.IsGroupVisible(group)
                             and not (hideTradingPost and group.source == "tradingpost")
        for _, pet in ipairs(group.pets) do
            local numCollected = 0
            if hasGetNum then
                numCollected = C_PetJournal.GetNumCollectedInfo(pet.speciesID) or 0
            end
            local isCollected = numCollected > 0

            local exp = pet.expansion or group.expansion or "_unknown"
            local available = MC.IsContentAvailable(pet)
            MC.AccumulateScanEntry(result, isCollected, MC.ScoreFor(pet), exp,
                pet.unavailable, available)

            local hideUnavailable = mod.db == nil or mod.db.hideUnavailable ~= false
            if not (pet.unavailable and not isCollected and hideUnavailable) then
                if groupVisible then
                    -- Take the client's name for this species, the way Mounts
                    -- and Toys already do. Two reasons, and the second matters
                    -- more than the first:
                    --
                    -- It makes a catalog typo self-correcting -- the shipped
                    -- string stops being the thing a player reads.
                    --
                    -- And it makes a WRONG speciesID visible. Collection state
                    -- is keyed on speciesID alone (GetNumCollectedInfo above);
                    -- the name is never consulted. So a row with the wrong id
                    -- silently reports a pet you own as missing, forever, with
                    -- nothing on screen to suggest anything is wrong. Showing
                    -- what the id actually points at turns that into something
                    -- you can see.
                    local icon, petType, liveName = nil, pet.petType, nil
                    if hasGetInfo then
                        local petName, petIcon, petPetType =
                            C_PetJournal.GetPetInfoBySpeciesID(pet.speciesID)
                        if petName and petName ~= "" then liveName = petName end
                        if petIcon and petIcon ~= 0 and petIcon ~= "" then icon = petIcon end
                        if petPetType and petPetType > 0 then petType = petPetType end
                    end

                    local entry = {
                        moduleKey         = "pets",
                        speciesID         = pet.speciesID,
                        name              = liveName or pet.name,
                        petType           = petType,
                        source            = pet.source,
                        sourceInfo        = pet.sourceInfo,
                        waypoint          = pet.waypoint
                            -- Derived pins fill the gap where the catalog has none; a
                            -- hand-written waypoint on the row itself always wins.
                            or (pet.speciesID and MC.PetPins and MC.PetPins[pet.speciesID]),
                        overworldWaypoint = pet.overworldWaypoint,
                        cost              = pet.cost,
                        dropInfo          = pet.dropInfo,
                        achievementID     = pet.achievementID,
                        -- Free-text "How to:" block, rendered by the shared
                        -- tooltip. Secrets like J'imothy have no quest or
                        -- criteria IDs to drive a taskList, so the write-up is
                        -- the only thing that can explain them.
                        steps             = pet.steps,
                        taskList          = pet.taskList,
                        canBattle         = pet.canBattle,
                        zone              = pet.zone,
                        renown            = pet.renown,
                        icon              = icon,
                        collected         = isCollected,
                        expansion         = pet.expansion,
                        availableAfter    = pet.availableAfter,
                        future            = not available,
                    }
                    if available then
                        result.total = result.total + 1
                        if isCollected then
                            result.collectedCount = result.collectedCount + 1
                            result.collected[#result.collected + 1] = entry
                        else
                            result.uncollectedCount = result.uncollectedCount + 1
                        end
                    end
                    if not (available and isCollected) then
                        MC.BucketEntry(result, pet.source, entry)
                    end
                end
            end
        end
    end

    self.results = result
end
