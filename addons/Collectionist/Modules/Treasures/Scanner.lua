local _, MC = ...
local T = MC.SCORE_TIERS

local mod = MC.modulesByKey["treasures"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

function Scanner:Scan()
    if not MC.TreasureData then return false end
    if CanShowAchievementUI then
        local ok, ready = pcall(CanShowAchievementUI)
        if not ok or not ready then return false end
    end

    if not (GetAchievementCriteriaInfo and GetAchievementNumCriteria) then
        return false
    end

    -- Preflight: capture each achievement's live criteria count. See
    -- Rares/Scanner.lua for the rationale — scan what's queryable now,
    -- mark the result partial, let the bounded retry settle the rest.
    local criteriaCounts, pending = {}, 0
    for _, ach in ipairs(MC.TreasureData) do
        if not ach.navigationOnly then
            local ok, live = pcall(GetAchievementNumCriteria, ach.achievementID)
            live = (ok and live) or 0
            criteriaCounts[ach] = live
            local expected = ach.criteriaCount or 0
            if live < expected then pending = pending + (expected - live) end
        end
    end

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

    for _, ach in ipairs(MC.TreasureData) do
        if not ach.navigationOnly then
        local visible = MC.IsGroupVisible(ach, "treasures")
        local n = criteriaCounts[ach]
        -- When the live count disagrees with the shipped one, the criterion
        -- order may have shifted too; distrust the positional name array
        -- rather than risk pairing the wrong waypoint/steps with a treasure.
        local trustPositional = (n == (ach.criteriaCount or 0))
        for i = 1, n do
            -- pcall: the API hard-errors on criteria the client hasn't
            -- streamed in, even after the count preflight passed.
            local ok, name, _, completed, _, _, _, _, assetID =
                pcall(GetAchievementCriteriaInfo, ach.achievementID, i)
            if not ok or name == nil or completed == nil then
                pending = pending + 1
            else
                -- Metadata is keyed by the stable achievement criterion
                -- position, not the localized live name.
                local metadataName = (trustPositional and ach.criteriaNames and ach.criteriaNames[i])
                                  or name
                -- Treasure scoring: trivial default (walk-up loot),
                -- short if the treasure has a task list (live ✓/✗ steps)
                -- or a notes walkthrough (key/puzzle/prereq). Bypasses the
                -- source-default since per-zone keys are shared with Rares.
                local hasSteps = (MC.TreasureSteps and MC.TreasureSteps[metadataName])
                              or (MC.TreasureNotes and MC.TreasureNotes[metadataName])
                local w = hasSteps and T.short or T.trivial
                local exp = ach.expansion or "_unknown"
                local available = MC.IsContentAvailable(ach)
                MC.AccumulateScanEntry(result, completed, w, exp, nil, available)

                if visible then
                    local coords = MC.TreasureCoords and MC.TreasureCoords[metadataName]
                    local taskList = MC.TreasureSteps and MC.TreasureSteps[metadataName]
                    local entry = {
                        moduleKey     = "treasures",
                        name          = name,
                        -- Treasure achievements carry GAMEOBJECT IDs in assetID;
                        -- store as objectID so Wowhead links resolve to /object=.
                        objectID      = (assetID and assetID > 0) and assetID or nil,
                        source        = ach.source,
                        sourceInfo    = "Treasure in " .. ach.zone,
                        achievementID = ach.achievementID,
                        criteriaIndex = i,
                        zone          = ach.zone,
                        waypoint      = coords,
                        -- Plain text note suppressed when the richer taskList is
                        -- present so the tooltip doesn't render the same info twice.
                        steps         = (not taskList)
                            and (MC.TreasureNotes and MC.TreasureNotes[metadataName]) or nil,
                        taskList      = taskList,
                        collected     = completed and true or false,
                        expansion     = ach.expansion,
                        availableAfter = ach.availableAfter,
                        future         = not available,
                    }
                    if available then
                        result.total = result.total + 1
                        if entry.collected then
                            result.collectedCount = result.collectedCount + 1
                            result.collected[#result.collected + 1] = entry
                        else
                            result.uncollectedCount = result.uncollectedCount + 1
                        end
                    end
                    if not (available and entry.collected) then
                        MC.BucketEntry(result, ach.source, entry)
                    end
                end
            end
        end
        end
    end

    MC.BucketNavigationGroups(result, MC.TreasureData, "treasures", "treasures", "Treasure")

    result._partial = pending > 0 and pending or nil
    self.results = result
    return true
end
