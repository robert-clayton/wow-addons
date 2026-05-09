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

local function getAchievementInfo(achID)
    local getInfo = (C_AchievementInfo and C_AchievementInfo.GetAchievementInfo)
                      or GetAchievementInfo
    if not getInfo then return nil, nil, false end
    local ok, _, name, _, completed, _, _, _, _, icon = pcall(getInfo, achID)
    if not ok then return nil, nil, false end
    return name, icon, completed and true or false
end

function Scanner:Scan()
    if not MC.AchievementData then return end

    local result = {
        total            = 0,
        collectedCount   = 0,
        uncollectedCount = 0,
        -- Two-level: byCategory[category][source] = { entries... }
        byCategory       = {},
        -- Flat fallback for callers that only look up by source.
        bySource         = {},
        collected        = {},
    }

    for _, group in ipairs(MC.AchievementData) do
        local category = group.category or "exploration"
        -- Guard against a missing source: `byCategory[category][nil]`
        -- would crash table.insert. Fall back to a sentinel so the
        -- entries still render (under "_unsorted") instead of erroring.
        local source = group.source or "_unsorted"
        for _, ach in ipairs(group.achievements) do
            local liveName, liveIcon, liveCompleted = getAchievementInfo(ach.achievementID)
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
            }
            result.total = result.total + 1
            if entry.collected then
                result.collectedCount = result.collectedCount + 1
                result.collected[#result.collected + 1] = entry
            else
                result.uncollectedCount = result.uncollectedCount + 1
                if not result.byCategory[category] then
                    result.byCategory[category] = {}
                end
                if not result.byCategory[category][source] then
                    result.byCategory[category][source] = {}
                end
                table.insert(result.byCategory[category][source], entry)
                if not result.bySource[source] then result.bySource[source] = {} end
                table.insert(result.bySource[source], entry)
            end
        end
    end

    self.results = result
end
