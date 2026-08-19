local _, MC = ...

local mod = MC.modulesByKey["achievements"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

-- Count completed tasks in a taskList without re-checking completion
-- per render. Mirrors the existing taskList shape used by Treasures.
local function countTasks(taskList)
    if not (taskList and taskList.tasks) then return 0, 0 end
    local total, done = 0, 0
    for _, task in ipairs(taskList.tasks) do
        total = total + 1
        if MC.IsTaskCompleted and MC.IsTaskCompleted(task) then
            done = done + 1
        end
    end
    return done, total
end

-- Status distinguishes why a lookup failed: "invalid" (the pcall errored —
-- a removed or bad ID, permanent) vs "pending" (nil fields — completion
-- data still streaming, transient) vs "noapi" (no lookup function at all).
local function getAchievementInfo(achID)
    local getInfo = (C_AchievementInfo and C_AchievementInfo.GetAchievementInfo)
                      or GetAchievementInfo
    if not getInfo then return nil, nil, false, "noapi" end
    -- GetAchievementInfo returns icon in slot 10. pcall's status value is
    -- prepended, so keep ten API-result captures before reading it.
    local ok, id, name, _, completed, _, _, _, _, _, icon = pcall(getInfo, achID)
    if not ok then return nil, nil, false, "invalid" end
    if id == nil or completed == nil then return nil, nil, false, "pending" end
    return name, icon, completed and true or false, "ok"
end

function Scanner:Scan()
    if not MC.AchievementData then return false end
    if CanShowAchievementUI then
        local ok, ready = pcall(CanShowAchievementUI)
        if not ok or not ready then return false end
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
        -- Two-level: byCategory[category][source] = { entries... }
        byCategory         = {},
        -- Flat fallback for callers that only look up by source.
        bySource           = {},
        collected          = {},
    }

    local pending, invalid = 0, 0

    for _, group in ipairs(MC.AchievementData) do
        local visible = MC.IsGroupVisible(group)
        local category = group.category or "exploration"
        -- Guard against a missing source: `byCategory[category][nil]`
        -- would crash table.insert. Fall back to a sentinel so the
        -- entries still render (under "_unsorted") instead of erroring.
        local source = group.source or "_unsorted"
        for _, ach in ipairs(group.achievements) do
            local liveName, liveIcon, liveCompleted, status = getAchievementInfo(ach.achievementID)
            if status == "noapi" then return false end
            if status == "invalid" then
                -- Bad/removed ID: costs this one row, never the scan.
                invalid = invalid + 1
            elseif status == "pending" then
                -- Completion data still streaming; skip the row and let
                -- the bounded retry pick it up rather than publishing a
                -- false all-zero state for it.
                pending = pending + 1
            else
                local w = ach.score
                       or MC.DEFAULT_SCORE_BY_SOURCE[group.source]
                       or MC.SCORE_DEFAULT
                local exp = ach.expansion or group.expansion or "_unknown"
                local available = MC.IsContentAvailable(ach)
                MC.AccumulateScanEntry(result, liveCompleted, w, exp, nil, available)

                if visible then
                    local done, total = countTasks(ach.taskList)
                    local entry = {
                        achievementID = ach.achievementID,
                        name          = liveName or ach.name,
                        description   = ach.description,
                        category      = category,
                        source        = source,
                        sourceInfo    = ach.description,
                        zone          = ach.zone,
                        icon          = liveIcon,
                        taskList      = ach.taskList,
                        progress      = { done = done, total = total },
                        collected     = liveCompleted,
                        expansion     = ach.expansion or group.expansion,
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
                        MC.BucketEntry(result, source, entry, category)
                    end
                end
            end
        end
    end

    result._partial = pending > 0 and pending or nil
    result._invalid = invalid > 0 and invalid or nil
    if invalid > 0 and not self._warnedInvalid then
        self._warnedInvalid = true
        print(format("%s Skipped %d achievement(s) the game no longer recognizes.",
            MC.PREFIX, invalid))
    end
    self.results = result
    return true
end
