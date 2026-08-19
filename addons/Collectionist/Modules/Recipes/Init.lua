local _, MC = ...

-- Recipes covers all 9 crafting professions
MC.RecipeProfOrder = MC.PROFESSION_ORDER

local CRAFT_SKILLS = {}
for _, sl in ipairs(MC.PROFESSION_ORDER) do CRAFT_SKILLS[sl] = true end

-- Stand-in art for a profession this character never learned. The real
-- icon comes from GetProfessionInfo, which only answers for professions
-- the character actually has.
local UNLEARNED_ICON = "Interface\\Icons\\INV_Scroll_03"

-- Every crafting profession is present, whether or not this character
-- learned it: recipe ownership is account-wide, so the catalog a player
-- can work toward is all nine. `learned` says which ones this character
-- can train right now, and drives the optional hide filter and the
-- skill-level line.
local function DetectProfessions(mod)
    wipe(mod.professions)
    for _, skillLine in ipairs(MC.PROFESSION_ORDER) do
        mod.professions[skillLine] = {
            name       = MC.PROFESSION_LABELS[skillLine] or "?",
            icon       = UNLEARNED_ICON,
            skillLine  = skillLine,
            skillLevel = 0,
            maxLevel   = 0,
            learned    = false,
        }
    end

    local prof1, prof2, _arch, _fish, cooking = GetProfessions()
    local indices = {}
    if prof1 then indices[#indices + 1] = prof1 end
    if prof2 then indices[#indices + 1] = prof2 end
    if cooking then indices[#indices + 1] = cooking end

    for _, profIndex in ipairs(indices) do
        local name, icon, skillLevel, maxLevel, _, _, skillLine = GetProfessionInfo(profIndex)
        if name and CRAFT_SKILLS[skillLine] then
            local p = mod.professions[skillLine]
            p.name       = name
            p.icon       = icon
            p.profIndex  = profIndex
            p.skillLevel = skillLevel or 0
            p.maxLevel   = maxLevel or 0
            p.learned    = true
        end
    end
end

-- Professions to show in the browser: all of them, unless the player
-- asked to see only what this character can train.
function MC.RecipeProfessionShown(mod, skillLine)
    local p = mod.professions and mod.professions[skillLine]
    if not p then return false end
    if mod.db and mod.db.hideUnlearnedProfs then return p.learned end
    return true
end

local mod = MC.RegisterModule("recipes", {
    label          = "Recipes",
    icon           = "Interface\\Icons\\INV_Scroll_03",
    order          = 5,
    collectedKey   = "showLearned",
    collectedLabel = "learned",
    defaults       = {
        showLearned        = false,
        -- Off by default: recipes are account-wide, so the whole
        -- catalog is what a player can work toward.
        hideUnlearnedProfs = false,
        collapsed          = {},
    },
    -- SPELLS_CHANGED dropped: it fires on every spell cast / talent swap, far
    -- noisier than the recipe-specific signals below.
    events = { "TRADE_SKILL_LIST_UPDATE", "SKILL_LINES_CHANGED", "NEW_RECIPE_LEARNED" },
    onLogin = function(m)
        m.professions = {}
        DetectProfessions(m)
    end,
    onEvent = function(m, event)
        if event == "SKILL_LINES_CHANGED" then
            DetectProfessions(m)
            MC.ThrottledScan(m)
        else
            MC.ThrottledScan(m)
        end
    end,
    tooltipLines = function(tt, m)
        if not m.professions or not m.Scanner then return end
        for _, skillLine in ipairs(MC.RecipeProfOrder) do
            local result = m.Scanner.results[skillLine]
            local prof = m.professions[skillLine]
            if result and prof and MC.RecipeProfessionShown(m, skillLine) then
                tt:AddLine(format("  %s: %d / %d", prof.name, result.learnedCount, result.total), 0.7, 0.7, 0.7)
            end
        end
    end,
    printSummary = function(m)
        if not m.professions or not m.Scanner then return end
        local totalLearned, totalRecipes = 0, 0
        for _, skillLine in ipairs(MC.RecipeProfOrder) do
            local result = m.Scanner.results[skillLine]
            local prof = m.professions[skillLine]
            if result and prof and MC.RecipeProfessionShown(m, skillLine) then
                totalLearned = totalLearned + result.learnedCount
                totalRecipes = totalRecipes + result.total
                print(format("%s [Recipes] %s: %d / %d learned (%d remaining)",
                    MC.PREFIX, prof.name, result.learnedCount, result.total, result.unlearnedCount))
            end
        end
        if totalRecipes > 0 then
            print(format("%s [Recipes] Total: %d / %d", MC.PREFIX, totalLearned, totalRecipes))
        end
    end,
})
