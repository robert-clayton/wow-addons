local _, MC = ...

local mod = MC.modulesByKey["recipes"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

-- Stands in for sourceInfo on recipes the catalog hasn't been enriched for
-- yet. Points at the one action that always works for them — Wowhead —
-- rather than leaving the tooltip's Source line empty.
local UNSOURCED_HINT = "Acquisition not catalogued yet. Shift-click for Wowhead."

-- skillLine -> per-profession recipe table name, shared with Core's
-- RegisterContent recipes route (Core.lua loads first per the TOC).
local dataSets = MC.RECIPE_DATA_KEYS

function Scanner:IsRecipeKnown(recipeID)
    return IsPlayerSpell(recipeID) and true or false
end

-- Account-wide ledger of every recipe any alt has ever learned.
-- Persisted in CollectionistDB.recipesLearned. Never erases — only
-- adds — so an alt that hasn't learned recipe X yet still scores it
-- if some other alt has.
local function ensureLedger()
    if not CollectionistDB then return nil end
    CollectionistDB.recipesLearned = CollectionistDB.recipesLearned or {}
    return CollectionistDB.recipesLearned
end

function Scanner:Scan()
    wipe(self.results)
    local professions = mod.professions or {}
    for skillLine in pairs(professions) do
        local recipes = MC[dataSets[skillLine]]
        if recipes then
            self:ScanProfession(skillLine, recipes)
        end
    end

    -- Off-profession pass. DetectProfessions now seeds all nine, so this
    -- normally finds nothing: ScanProfession credits ledger score for
    -- every profession, trained or not. It still matters in the window
    -- before detection has run (professions is empty at first scan),
    -- where it is the only thing crediting the account's score.
    -- Professions already present are skipped — ScanProfession credited
    -- them above, and double-counting would inflate the CS.
    -- Stored with a score field ONLY: Roster's GetLocalScore sums any
    -- results sub-table with .score, while BuildLocalCounts requires
    -- .total, so this entry feeds the score without touching counts.
    local ledger = ensureLedger()
    local offScore = 0
    if ledger then
        for skillLine, dataKey in pairs(dataSets) do
            if not professions[skillLine] then
                local recipeData = MC[dataKey]
                if recipeData then
                    for _, category in ipairs(recipeData) do
                        -- Account score is independent of the browse filter.
                        -- Off-profession recipes never render here, so there
                        -- is no display work to gate on IsGroupVisible.
                        for _, recipe in ipairs(category.recipes) do
                            if recipe.id and ledger[recipe.id] == true
                               and recipe.source ~= "unavailable" and not recipe.unavailable then
                                offScore = offScore + MC.ScoreFor(recipe)
                            end
                        end
                    end
                end
            end
        end
    end
    self.results._offProfession = { score = offScore }
end

function Scanner:ScanProfession(skillLine, recipeData)
    local ledger = ensureLedger()
    local result = {
        total          = 0,
        learnedCount   = 0,
        unlearnedCount = 0,
        totalAll       = 0,
        learnedCountAll = 0,
        score          = 0,
        -- Learned recipes that can no longer be obtained. Counted, never
        -- scored -- the same split MC.AccumulateScanEntry applies for every
        -- other module, so "Legacies" means the same thing everywhere.
        legacyCount    = 0,
        bySource       = {},
        learned        = {},
    }

    for _, category in ipairs(recipeData) do
        local visible = MC.IsGroupVisible(category, "recipes")
        for _, recipe in ipairs(category.recipes) do
            result.totalAll = result.totalAll + 1
            local known = recipe.id and self:IsRecipeKnown(recipe.id) or false

            -- Update the account-wide ledger even when this expansion is
            -- hidden, so browsing cannot erase newly observed ownership.
            if known and ledger and recipe.id then
                ledger[recipe.id] = true
            end

            local accountKnown = known
                or (ledger and recipe.id and ledger[recipe.id] == true)
            if accountKnown then
                result.learnedCountAll = result.learnedCountAll + 1
                -- source="unavailable" is ATT's never-implemented bucket:
                -- present in the client, never released, or pulled since.
                -- Owning one is a legacy, not an achievement to score, and
                -- every other module already splits it that way.
                if recipe.source == "unavailable" or recipe.unavailable then
                    result.legacyCount = result.legacyCount + 1
                else
                    result.score = result.score + MC.ScoreFor(recipe)
                end
            end

            if visible then
                result.total = result.total + 1
                local entry = {
                    id         = recipe.id,
                    name       = recipe.name,
                    source     = recipe.source,
                    -- Uncatalogued recipes have no sourceInfo, which would
                    -- leave the info tooltip's Source line blank. Substituting
                    -- here rather than in the data files keeps 8,900-odd rows
                    -- out of the shipped catalog, and covers the pinned-target
                    -- overlay and Collection Inspector too — they read this
                    -- same scanned entry.
                    sourceInfo = recipe.sourceInfo
                        or ((recipe.source == nil or recipe.source == "unknown")
                            and UNSOURCED_HINT or nil),
                    priority   = recipe.priority,
                    -- Hand-written waypoints on the curated profession files
                    -- win; everything else falls back to the generated table,
                    -- attached here rather than inlined on thousands of rows.
                    -- Mirrors how Rares/Scanner.lua attaches MC.RareNPCs.
                    waypoint   = recipe.waypoint
                        or (recipe.id and MC.RecipeWaypoints and MC.RecipeWaypoints[recipe.id])
                        or (MC.RecipeTrainerWaypoint and MC.RecipeTrainerWaypoint(recipe.id)),
                    cost       = recipe.cost,
                    dropInfo   = recipe.dropInfo,
                    -- MC.ShowItemInfoTooltip gates its "Click to open
                    -- profession" hint on item.skillLine, which recipe entries
                    -- never carried -- so the hint was missing on every row
                    -- while the click itself worked. Also hardens the
                    -- item.skillLine fallback in Targets.ToggleTargetPin.
                    skillLine  = skillLine,
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
    end

    self.results[skillLine] = result
end
