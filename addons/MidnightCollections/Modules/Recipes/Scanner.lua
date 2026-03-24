local _, MC = ...

local mod = MC.modulesByKey["recipes"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

local dataSets = {
    [171] = "AlchemyRecipes",
    [164] = "BlacksmithingRecipes",
    [185] = "CookingRecipes",
    [333] = "EnchantingRecipes",
    [202] = "EngineeringRecipes",
    [773] = "InscriptionRecipes",
    [755] = "JewelcraftingRecipes",
    [165] = "LeatherworkingRecipes",
    [197] = "TailoringRecipes",
}

function Scanner:IsRecipeKnown(recipeID)
    local ok, result = pcall(IsPlayerSpell, recipeID)
    return ok and result
end

function Scanner:Scan()
    wipe(self.results)

    if not mod.professions then return end
    for skillLine in pairs(mod.professions) do
        local recipes = MC[dataSets[skillLine]]
        if recipes then
            self:ScanProfession(skillLine, recipes)
        end
    end
end

function Scanner:ScanProfession(skillLine, recipeData)
    local result = {
        total          = 0,
        learnedCount   = 0,
        unlearnedCount = 0,
        bySource       = {},
        learned        = {},
    }

    for _, category in ipairs(recipeData) do
        for _, recipe in ipairs(category.recipes) do
            result.total = result.total + 1
            local known = recipe.id and self:IsRecipeKnown(recipe.id) or false

            local entry = {
                id         = recipe.id,
                name       = recipe.name,
                source     = recipe.source,
                sourceInfo = recipe.sourceInfo,
                priority   = recipe.priority,
                waypoint   = recipe.waypoint,
                cost       = recipe.cost,
                dropInfo   = recipe.dropInfo,
                learned    = known,
            }

            if known then
                result.learnedCount = result.learnedCount + 1
                result.learned[#result.learned + 1] = entry
            else
                result.unlearnedCount = result.unlearnedCount + 1
                local src = recipe.source or "unknown"
                if not result.bySource[src] then result.bySource[src] = {} end
                result.bySource[src][#result.bySource[src] + 1] = entry
            end
        end
    end

    self.results[skillLine] = result
end
