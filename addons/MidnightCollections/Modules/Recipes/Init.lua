local _, MC = ...

local CRAFT_SKILLS = {
    [171] = true,   -- Alchemy
    [164] = true,   -- Blacksmithing
    [185] = true,   -- Cooking
    [333] = true,   -- Enchanting
    [202] = true,   -- Engineering
    [773] = true,   -- Inscription
    [755] = true,   -- Jewelcrafting
    [165] = true,   -- Leatherworking
    [197] = true,   -- Tailoring
}

MC.RecipeProfOrder = { 171, 164, 185, 333, 202, 773, 755, 165, 197 }

local function DetectProfessions(mod)
    wipe(mod.professions)
    local prof1, prof2, _arch, _fish, cooking = GetProfessions()
    local indices = {}
    if prof1 then indices[#indices + 1] = prof1 end
    if prof2 then indices[#indices + 1] = prof2 end
    if cooking then indices[#indices + 1] = cooking end

    for _, profIndex in ipairs(indices) do
        local name, icon, skillLevel, maxLevel, _, _, skillLine = GetProfessionInfo(profIndex)
        if name and CRAFT_SKILLS[skillLine] then
            mod.professions[skillLine] = {
                name       = name,
                icon       = icon,
                profIndex  = profIndex,
                skillLine  = skillLine,
                skillLevel = skillLevel or 0,
                maxLevel   = maxLevel or 0,
            }
        end
    end
end

local mod = MC.RegisterModule("recipes", {
    label          = "Recipes",
    icon           = "Interface\\Icons\\INV_Scroll_03",
    order          = 4,
    collectedKey   = "showLearned",
    collectedLabel = "learned",
    defaults       = {
        showLearned = false,
        collapsed   = {},
    },
    events = { "TRADE_SKILL_LIST_UPDATE", "SPELLS_CHANGED", "SKILL_LINES_CHANGED" },
    onLogin = function(m)
        m.professions = {}
        DetectProfessions(m)
    end,
    onEvent = function(m, event)
        if event == "SKILL_LINES_CHANGED" then
            DetectProfessions(m)
            MC.ThrottledScan(m)
        elseif event == "TRADE_SKILL_LIST_UPDATE" or event == "SPELLS_CHANGED" then
            MC.ThrottledScan(m)
        end
    end,
    tooltipLines = function(tt, m)
        if not m.professions or not m.Scanner then return end
        for _, skillLine in ipairs(MC.RecipeProfOrder) do
            local result = m.Scanner.results[skillLine]
            local prof = m.professions[skillLine]
            if result and prof then
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
            if result and prof then
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
