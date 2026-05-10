local _, MC = ...

local mod = MC.modulesByKey["rares"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

function Scanner:Scan()
    if not MC.RareData then return end

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

    local hasCriteria = GetAchievementCriteriaInfo and GetAchievementNumCriteria

    for _, ach in ipairs(MC.RareData) do
        local visible = MC.IsGroupVisible(ach)
        local n = hasCriteria and GetAchievementNumCriteria(ach.achievementID) or 0
        for i = 1, n do
            -- Returns: name, type, completed, qty, totalQty, charName, flags, assetID, ...
            -- For "kill creature" criteria (type 0), assetID is the NPC ID.
            local name, _, completed, _, _, _, _, assetID = GetAchievementCriteriaInfo(ach.achievementID, i)
            if name then
                result.totalAll = result.totalAll + 1
                if completed then
                    result.collectedCountAll = result.collectedCountAll + 1
                    -- Rares don't have per-criterion `unavailable` flags; the
                    -- ach-level entry's source default applies. No legacy
                    -- bucket for rares today.
                    result.score = result.score + MC.ScoreFor(ach)
                end

                local exp = ach.expansion or "_unknown"
                local b = result.byExpansion[exp]
                if not b then
                    b = { total = 0, collected = 0 }
                    result.byExpansion[exp] = b
                end
                b.total = b.total + 1
                if completed then b.collected = b.collected + 1 end

                if visible then
                    result.total = result.total + 1
                    local npcID = (assetID and assetID > 0) and assetID or nil
                    local coords = (name  and MC.RareCoords and MC.RareCoords[name])
                                or (npcID and MC.RareNPCs   and MC.RareNPCs[npcID])
                    local entry = {
                        name          = name,
                        npcID         = npcID,
                        source        = ach.source,
                        sourceInfo    = "Rare in " .. ach.zone,
                        achievementID = ach.achievementID,
                        criteriaIndex = i,
                        zone          = ach.zone,
                        waypoint      = coords,
                        collected     = completed and true or false,
                        expansion     = ach.expansion,
                    }
                    if entry.collected then
                        result.collectedCount = result.collectedCount + 1
                        result.collected[#result.collected + 1] = entry
                    else
                        result.uncollectedCount = result.uncollectedCount + 1
                        if not result.bySource[ach.source] then
                            result.bySource[ach.source] = {}
                        end
                        result.bySource[ach.source][#result.bySource[ach.source] + 1] = entry
                    end
                end
            end
        end
    end

    self.results = result
end
