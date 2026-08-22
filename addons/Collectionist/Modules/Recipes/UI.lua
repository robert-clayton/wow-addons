local _, MC = ...

local mod = MC.modulesByKey["recipes"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local ROW_HEIGHT     = 18
local HEADER_HEIGHT  = 24
local SECTION_PAD    = 8

-- Cached key strings for progress bars (avoid per-refresh string concat)
local BAR_KEYS = {}
local function getBarKeys(skillLine)
    local k = BAR_KEYS[skillLine]
    if not k then
        k = {
            bg   = "barBg_" .. skillLine,
            fill = "barFill_" .. skillLine,
            hl   = "barFill_" .. skillLine .. "_hl",
        }
        BAR_KEYS[skillLine] = k
    end
    return k
end

-- "unknown" is last on purpose. Most shipped recipes still carry it: DB2
-- has no acquisition column for recipes (unlike Mount/BattlePetSpecies/Toy,
-- which ship a SourceText_lang), so the catalog was generated without one.
-- Listing it here rather than letting it fall through the pairs() loop below
-- gives it a stable position at the bottom instead of a random one, and a
-- real label instead of the raw key.
local SOURCE_ORDER = {
    "trainer", "vendor", "discovery", "specialization",
    "drop", "worlddrop", "quest", "treasure", "pvp",
    "unavailable", "unknown",
}
-- Exported on MC so Search (and future callers) resolve recipe source
-- labels without a second drifting copy; the local alias keeps the two
-- render paths below unchanged.
MC.RecipeSourceLabels = {
    trainer        = "Trainer",
    vendor         = "Vendor",
    discovery      = "Discovery",
    specialization = "Specialization",
    drop           = "Drop",
    worlddrop      = "World Drop",
    quest          = "Quest",
    treasure       = "Treasure",
    pvp            = "PvP",
    -- ATT's never-implemented bucket: recipes that exist in the client but
    -- were never released, plus content pulled since. Neither is farmable.
    unavailable    = "Not obtainable",
    -- Says the addon hasn't catalogued it, not that the recipe has no source.
    unknown        = "Source not catalogued",
}
local SOURCE_LABELS = MC.RecipeSourceLabels
local SOURCE_SET = {}
for _, s in ipairs(SOURCE_ORDER) do SOURCE_SET[s] = true end

function UI:Init(panel, m)
    self.panel = panel
    self.mod = m
    -- Track which skillLines we've rendered bars for so we can hide stale ones
    self._lastBars = {}
    self._refresh = function() self:Refresh() end
end

function UI:GetConfigDefs()
    -- Show Learned toggle is auto-injected by Core.BuildConfig
    return {
        {
            type  = "checkbox",
            label = "Only professions this character has",
            get   = function() return mod.db.hideUnlearnedProfs end,
            set   = function(v)
                mod.db.hideUnlearnedProfs = v
                MC.RefreshActive()
            end,
        },
    }
end

function UI:Refresh()
    if not self.panel or not self.panel.scrollChild then return end
    if not mod.Scanner then return end

    self.panel.pool:ReleaseAll()

    local child = self.panel.scrollChild
    local yOff = 0
    local totalLearned, totalRecipes = 0, 0
    local thisRunBars = {}

    for _, skillLine in ipairs(MC.RecipeProfOrder) do
        local result = mod.Scanner.results[skillLine]
        local profInfo = mod.professions and mod.professions[skillLine]
        if result and profInfo and MC.RecipeProfessionShown(mod, skillLine) then
            totalLearned = totalLearned + result.learnedCount
            totalRecipes = totalRecipes + result.total
            yOff = self:RenderProfession(child, profInfo, result, skillLine, yOff)
            yOff = yOff + SECTION_PAD
            thisRunBars[skillLine] = true
        end
    end

    -- Hide bars for professions that disappeared since last refresh
    for sl in pairs(self._lastBars) do
        if not thisRunBars[sl] then
            local k = getBarKeys(sl)
            local kids = child._children
            if kids then
                if kids[k.bg] then kids[k.bg]:Hide() end
                if kids[k.fill] then kids[k.fill]:Hide() end
                if kids[k.hl] then kids[k.hl]:Hide() end
            end
        end
    end
    self._lastBars = thisRunBars

    if self.panel.titleProgressText then
        self.panel.titleProgressText:SetText(
            totalRecipes > 0 and format("%d / %d", totalLearned, totalRecipes) or "")
    end

    if yOff == 0 then
        yOff = MUI.ShowEmptyMessage(child, "No crafting professions detected.")
    else
        MUI.HideEmptyMessage(child)
    end

    self.panel:RefreshScrollContent(yOff)
end

function UI:RenderProfession(parent, profInfo, result, skillLine, yOff)
    local theme = MUI.Theme
    local allLearned = result.total > 0 and result.learnedCount >= result.total
    local ar, ag, ab = theme:ProfAccentColor(skillLine)
    local cr, cg, cb = MUI.CountColor(result.learnedCount, result.total)

    local _, collapsed, newY = MUI.RenderCollapsibleHeader(
        self.panel.pool, parent, yOff, {
            height        = HEADER_HEIGHT,
            indent        = 0,
            collKey       = tostring(profInfo.skillLine),
            accentR       = ar, accentG = ag, accentB = ab,
            label         = profInfo.name,
            -- A profession this character hasn't trained still lists its
            -- recipes (ownership is account-wide), but reads dimmer so
            -- the ones you can train right now stand out.
            labelColor    = allLearned and theme.colors.textComplete
                or (profInfo.learned and theme.colors.text or theme.colors.textDim),
            count         = format("%d/%d", result.learnedCount, result.total),
            countColor    = { cr, cg, cb },
            icon          = profInfo.icon,
            fontSize      = theme.fontSize,
            countFontSize = theme.fontSize - 1,
        }, mod.db, self._refresh)
    yOff = newY

    -- Progress bar (4px, theme-colored)
    local barKeys = getBarKeys(skillLine)
    local barBg = MUI.GetOrCreate(parent, barKeys.bg, function(p)
        local t = p:CreateTexture(nil, "BACKGROUND")
        t:SetHeight(4)
        return t
    end)
    barBg:ClearAllPoints()
    barBg:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -yOff)
    barBg:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
    barBg:SetColorTexture(unpack(theme.colors.progressBg))

    local fillPct = result.total > 0 and (result.learnedCount / result.total) or 0
    local barFill = MUI.GetOrCreate(parent, barKeys.fill, function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetHeight(4)
        return t
    end)
    barFill:ClearAllPoints()
    barFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
    barFill:SetWidth(math.max((parent:GetWidth() - 12) * fillPct, 1))
    barFill:SetColorTexture(unpack(theme.colors.progress))
    MUI.ApplyProgressHighlight(barFill, barKeys.hl)

    yOff = yOff + 8
    if collapsed then return yOff end

    for _, srcType in ipairs(SOURCE_ORDER) do
        local recipes = result.bySource[srcType]
        if recipes and #recipes > 0 then
            yOff = self:RenderSourceGroup(parent, srcType, recipes, skillLine, yOff)
        end
    end
    for srcType, recipes in pairs(result.bySource) do
        if not SOURCE_SET[srcType] and #recipes > 0 then
            yOff = self:RenderSourceGroup(parent, srcType, recipes, skillLine, yOff)
        end
    end

    if mod.db.showLearned and #result.learned > 0 then
        yOff = self:RenderLearnedGroup(parent, result.learned, skillLine, yOff)
    end
    return yOff
end

function UI:RenderSourceGroup(parent, srcType, recipes, skillLine, yOff)
    local sr, sg, sb = MUI.Theme:SourceColor(srcType)
    local _, collapsed, newY = MUI.RenderSourceHeader(self.panel.pool, parent, yOff, {
        label       = SOURCE_LABELS[srcType] or srcType,
        accentColor = { sr, sg, sb },
        count       = #recipes,
        collKey     = "src_" .. tostring(skillLine) .. "_" .. srcType,
        indent      = 4,
    }, mod.db, self._refresh)
    yOff = newY
    if collapsed then return yOff end
    for _, recipe in ipairs(recipes) do
        yOff = self:RenderRecipeRow(parent, recipe, skillLine, yOff, false)
    end
    return yOff
end

function UI:RenderLearnedGroup(parent, recipes, skillLine, yOff)
    return MUI.RenderCollectedSection(self.panel.pool, parent, yOff, {
        entries   = recipes,
        renderRow = function(p, recipe, y, _) return self:RenderRecipeRow(p, recipe, nil, y, true) end,
        label     = "Learned",
        collKey   = "learned_" .. tostring(skillLine),
        indent    = 4,
    }, mod.db, self._refresh)
end

function UI:RenderRecipeRow(parent, recipe, skillLine, yOff, isLearned)
    local theme = MUI.Theme
    local sr, sg, sb
    if isLearned then
        local ld = theme.colors.learnedDot
        sr, sg, sb = ld[1], ld[2], ld[3]
    else
        sr, sg, sb = theme:SourceColor(recipe.source)
    end

    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height      = ROW_HEIGHT,
        indent      = 8,
        leading     = { kind = "dot", size = 6, color = { sr, sg, sb,
                        isLearned and (theme.colors.learnedDot[4] or 0.6) or 1 } },
        name        = recipe.name,
        isCollected = isLearned,
        onEnter = function(r)
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            if GameTooltip.SetSpellByID and recipe.id then
                GameTooltip:SetSpellByID(recipe.id)
            end
            GameTooltip:Show()
            local label = SOURCE_LABELS[recipe.source] or recipe.source
            MC.ShowItemInfoTooltip(r, recipe, label, sr, sg, sb)
        end,
        onLeave = MC.RowOnLeave,
        -- Always wire onClick so shift-click (Wowhead) and ctrl-click (info)
        -- still work on learned recipes. DoItemAction handles the modifiers
        -- and the skillLine fallback for unlearned ones.
        onClick = function() MC.DoItemAction(recipe, skillLine) end,
    })
end
