local _, MC = ...
local T = MC.SCORE_TIERS

local mod = MC.modulesByKey["rares"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

function Scanner:Scan()
    if not MC.RareData then return false end
    if CanShowAchievementUI then
        local ok, ready = pcall(CanShowAchievementUI)
        if not ok or not ready then return false end
    end

    if not (GetAchievementCriteriaInfo and GetAchievementNumCriteria) then
        return false
    end

    -- Preflight: capture each achievement's live criteria count. Criteria
    -- arrive as a streamed cache, so a short count usually means "still
    -- loading" — scan what's queryable now, mark the result partial, and
    -- let the bounded retry settle whether the shortfall is permanent
    -- (hotfix) or transient. A live count above the shipped one means
    -- Blizzard added criteria; scan those too.
    local criteriaCounts, pending = {}, 0
    for _, ach in ipairs(MC.RareData) do
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

    for _, ach in ipairs(MC.RareData) do
        if not ach.navigationOnly then
        local visible = MC.IsGroupVisible(ach, "rares")
        local n = criteriaCounts[ach]
        -- When the live count disagrees with the shipped one, the criterion
        -- order may have shifted too; distrust the positional metadata
        -- arrays rather than risk pairing the wrong waypoint/score.
        local trustPositional = (n == (ach.criteriaCount or 0))
        for i = 1, n do
            -- Returns: name, type, completed, qty, totalQty, charName, flags, assetID, ...
            -- The Midnight zone-rare criteria are quest-complete type (27),
            -- so assetID is a QUEST ID there — the positional NPC map is the
            -- only npcID source and the assetID fallback only helps if a
            -- future achievement uses kill-creature criteria (type 0).
            -- pcall: the API hard-errors on criteria the client hasn't
            -- streamed in, even after the count preflight passed.
            local ok, name, _, completed, _, _, _, _, assetID =
                pcall(GetAchievementCriteriaInfo, ach.achievementID, i)
            if not ok or name == nil or completed == nil then
                pending = pending + 1
            else
                -- Criterion order is stable across locales; the shipped NPC
                -- map also covers criteria whose assetID reuses another NPC.
                -- Some older "Adventurer" achievements mix rare NPCs with
                -- interactable objects while exposing completion-quest IDs
                -- through the achievement API. When a generated positional
                -- entity map exists, do not fall back to that quest ID.
                local hasPositionalEntityMap = trustPositional
                    and (ach.criteriaNPCIDs or ach.criteriaObjectIDs)
                local npcID = hasPositionalEntityMap
                    and ach.criteriaNPCIDs and ach.criteriaNPCIDs[i] or nil
                local objectID = hasPositionalEntityMap
                    and ach.criteriaObjectIDs and ach.criteriaObjectIDs[i] or nil
                if not hasPositionalEntityMap then
                    npcID = (assetID and assetID > 0) and assetID or nil
                end
                -- Per-rare stable NPC-ID override wins over
                -- the achievement-level source default. Used to bump
                -- rare-elites + PvP-zone rares above the standard per-zone tier.
                local override = MC.RareScoreOverrides and MC.RareScoreOverrides[npcID]
                local exp = ach.expansion or "_unknown"
                local available = MC.IsContentAvailable(ach)
                MC.AccumulateScanEntry(result, completed, override or MC.ScoreFor(ach), exp,
                    nil, available)

                if visible then
                    local coords = (npcID and MC.RareNPCs and MC.RareNPCs[npcID])
                                or (name and MC.RareCoords and MC.RareCoords[name])
                    local entry = {
                        moduleKey     = "rares",
                        name          = name,
                        npcID         = npcID,
                        objectID      = objectID,
                        source        = ach.source,
                        sourceInfo    = "Rare in " .. ach.zone,
                        achievementID = ach.achievementID,
                        criteriaIndex = i,
                        zone          = ach.zone,
                        waypoint      = coords,
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


    result._partial = pending > 0 and pending or nil
    self.results = result
    return true
end
