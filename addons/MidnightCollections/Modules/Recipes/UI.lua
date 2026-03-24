local _, MC = ...

local mod = MC.modulesByKey["recipes"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local ROW_HEIGHT     = 18
local HEADER_HEIGHT  = 24
local SECTION_PAD    = 8
local PADDING        = 6

local SOURCE_ORDER = { "trainer", "vendor", "discovery", "specialization", "drop", "quest" }
local SOURCE_LABELS = {
    trainer        = "Trainer",
    vendor         = "Vendor",
    discovery      = "Discovery",
    specialization = "Specialization",
    drop           = "Drop",
    quest          = "Quest",
}

local SOURCE_SET = {}
for _, s in ipairs(SOURCE_ORDER) do SOURCE_SET[s] = true end

--------------------------------------------------------------------------
-- Init (called once on first tab activation)
--------------------------------------------------------------------------
function UI:Init(panel, m)
    self.panel = panel
    self.mod = m
end

--------------------------------------------------------------------------
-- Config definitions for shared config panel
--------------------------------------------------------------------------
function UI:GetConfigDefs()
    local db = mod.db
    return {
        { type = "checkbox", label = "Show Learned Recipes",
            get = function() return db.showLearned end,
            set = function(v) db.showLearned = v; MC.RefreshActive() end },
    }
end

--------------------------------------------------------------------------
-- Refresh
--------------------------------------------------------------------------
function UI:Refresh()
    if not self.panel or not self.panel.scrollChild then return end
    if not mod.Scanner then return end

    self.panel.pool:ReleaseAll()

    local child = self.panel.scrollChild
    local yOff = 0
    local totalLearned, totalRecipes = 0, 0

    for _, skillLine in ipairs(MC.RecipeProfOrder) do
        local result = mod.Scanner.results[skillLine]
        local profInfo = mod.professions and mod.professions[skillLine]
        if result and profInfo then
            totalLearned = totalLearned + result.learnedCount
            totalRecipes = totalRecipes + result.total
            yOff = self:RenderProfession(child, profInfo, result, skillLine, yOff)
            yOff = yOff + SECTION_PAD
        end
    end

    -- Update title bar progress counter
    if self.panel.titleProgressText then
        if totalRecipes > 0 then
            self.panel.titleProgressText:SetText(format("%d / %d", totalLearned, totalRecipes))
        else
            self.panel.titleProgressText:SetText("")
        end
    end

    -- emptyText: show when no content, hide otherwise
    local theme = MUI.Theme
    local noProf = MUI.GetOrCreate(child, "emptyText", function(p)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize, "OUTLINE")
        return fs
    end)
    if yOff == 0 then
        noProf:SetPoint("TOP", child, "TOP", 0, -20)
        noProf:SetText("No crafting professions detected.")
        noProf:SetTextColor(0.7, 0.7, 0.7)
        noProf:Show()
        yOff = 60
    else
        noProf:Hide()
    end

    self.panel:RefreshScrollContent(yOff)
end

--------------------------------------------------------------------------
-- Render: Profession
--------------------------------------------------------------------------
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
            labelColor    = allLearned and theme.colors.textComplete or theme.colors.text,
            count         = format("%d/%d", result.learnedCount, result.total),
            countColor    = { cr, cg, cb },
            icon          = profInfo.icon,
            fontSize      = theme.fontSize,
            countFontSize = theme.fontSize - 1,
        }, mod.db, function() self:Refresh() end)
    yOff = newY

    -- Progress bar (4px, teal fill)
    local barBg = MUI.GetOrCreate(parent, "barBg_" .. skillLine, function(p)
        local t = p:CreateTexture(nil, "BACKGROUND")
        t:SetHeight(4)
        return t
    end)
    barBg:ClearAllPoints()
    barBg:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -yOff)
    barBg:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
    barBg:SetColorTexture(unpack(theme.colors.progressBg))

    local fillPct = result.total > 0 and (result.learnedCount / result.total) or 0
    local barFill = MUI.GetOrCreate(parent, "barFill_" .. skillLine, function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetHeight(4)
        return t
    end)
    barFill:ClearAllPoints()
    barFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
    barFill:SetWidth(math.max((parent:GetWidth() - 12) * fillPct, 1))
    barFill:SetColorTexture(unpack(theme.colors.progress))

    yOff = yOff + 8

    if collapsed then return yOff end

    -- Source type groups (known types)
    for _, srcType in ipairs(SOURCE_ORDER) do
        local recipes = result.bySource[srcType]
        if recipes and #recipes > 0 then
            yOff = self:RenderSourceGroup(parent, srcType, recipes, skillLine, yOff)
        end
    end

    -- Catch-all: render any source types not in SOURCE_ORDER
    for srcType, recipes in pairs(result.bySource) do
        if not SOURCE_SET[srcType] and #recipes > 0 then
            yOff = self:RenderSourceGroup(parent, srcType, recipes, skillLine, yOff)
        end
    end

    -- Learned
    if mod.db.showLearned and #result.learned > 0 then
        yOff = self:RenderLearnedGroup(parent, result.learned, skillLine, yOff)
    end

    return yOff
end

--------------------------------------------------------------------------
-- Render: Source group (top-level collapsible)
--------------------------------------------------------------------------
function UI:RenderSourceGroup(parent, srcType, recipes, skillLine, yOff)
    local theme = MUI.Theme
    local sr, sg, sb = theme:SourceColor(srcType)

    local _, collapsed, newY = MUI.RenderCollapsibleHeader(
        self.panel.pool, parent, yOff, {
            height     = 20,
            indent     = 4,
            collKey    = "src_" .. tostring(skillLine) .. "_" .. srcType,
            accentR    = sr, accentG = sg, accentB = sb,
            label      = SOURCE_LABELS[srcType] or srcType,
            labelColor = { sr, sg, sb },
            count      = tostring(#recipes),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY

    if collapsed then return yOff end

    for _, recipe in ipairs(recipes) do
        yOff = self:RenderRecipeRow(parent, recipe, skillLine, yOff, false)
    end

    return yOff
end

--------------------------------------------------------------------------
-- Render: Learned group (per-profession)
--------------------------------------------------------------------------
function UI:RenderLearnedGroup(parent, recipes, skillLine, yOff)
    local theme = MUI.Theme
    local la = theme.colors.learnedAccent

    local _, collapsed, newY = MUI.RenderCollapsibleHeader(
        self.panel.pool, parent, yOff, {
            height     = 20,
            indent     = 4,
            collKey    = "learned_" .. tostring(skillLine),
            accentR    = la[1], accentG = la[2], accentB = la[3],
            label      = "Learned",
            labelColor = { la[1], la[2], la[3] },
            count      = tostring(#recipes),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY

    if collapsed then return yOff end

    for _, recipe in ipairs(recipes) do
        yOff = self:RenderRecipeRow(parent, recipe, nil, yOff, true)
    end

    return yOff
end

--------------------------------------------------------------------------
-- Render: Recipe row (clickable)
--------------------------------------------------------------------------
function UI:RenderRecipeRow(parent, recipe, skillLine, yOff, isLearned)
    local theme = MUI.Theme

    local row = self.panel.pool:Acquire(parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -yOff)
    row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

    -- Hover background
    local rc = theme.colors.rowHover
    local hoverTex = MUI.GetOrCreate(row, "hover", function(p)
        local t = p:CreateTexture(nil, "BACKGROUND", nil, 1)
        return t
    end)
    hoverTex:SetAllPoints()
    hoverTex:SetColorTexture(1, 1, 1, 0)

    -- Status dot (6x6)
    local dot = MUI.GetOrCreate(row, "dot", function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetSize(6, 6)
        return t
    end)
    dot:SetPoint("LEFT", row, "LEFT", PADDING, 0)
    if isLearned then
        local ld = theme.colors.learnedDot
        dot:SetColorTexture(ld[1], ld[2], ld[3], ld[4])
    else
        local sr, sg, sb = theme:SourceColor(recipe.source)
        dot:SetColorTexture(sr, sg, sb, 1)
    end

    -- Recipe name
    local nameFs = MUI.GetOrCreate(row, "name", function(p)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize, "OUTLINE")
        return fs
    end)
    nameFs:SetFont(theme.font, theme.fontSize, "OUTLINE")
    nameFs:SetWordWrap(false)
    nameFs:SetJustifyH("LEFT")
    nameFs:SetPoint("LEFT", row, "LEFT", PADDING + 10, 0)
    nameFs:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    nameFs:SetText(recipe.name)

    if isLearned then
        nameFs:SetTextColor(unpack(theme.colors.textDim))
    else
        nameFs:SetTextColor(unpack(theme.colors.text))
    end

    -- Strikethrough line for learned recipes
    local strike = MUI.GetOrCreate(row, "strike", function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetHeight(1)
        return t
    end)
    if isLearned then
        strike:SetPoint("LEFT", nameFs, "LEFT", 0, 0)
        strike:SetPoint("RIGHT", nameFs, "RIGHT", 0, 0)
        strike:SetColorTexture(theme.colors.textDim[1], theme.colors.textDim[2], theme.colors.textDim[3], 0.5)
        strike:Show()
    else
        strike:Hide()
    end

    -- Spell tooltip on hover + info tooltip below
    row:SetScript("OnEnter", function(r)
        hoverTex:SetColorTexture(rc[1], rc[2], rc[3], rc[4])
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        if GameTooltip.SetSpellByID then
            GameTooltip:SetSpellByID(recipe.id)
        end
        GameTooltip:Show()
        local theme = MUI.Theme
        local sr, sg, sb = theme:SourceColor(recipe.source)
        local label = SOURCE_LABELS[recipe.source] or recipe.source
        MC.ShowItemInfoTooltip(r, recipe, label, sr, sg, sb)
    end)
    row:SetScript("OnLeave", function()
        hoverTex:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
        MC.HideInfoTooltip()
    end)

    -- Click action
    if not isLearned and skillLine then
        row:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then MC.DoItemAction(recipe, skillLine) end
        end)
    end

    return yOff + ROW_HEIGHT
end
