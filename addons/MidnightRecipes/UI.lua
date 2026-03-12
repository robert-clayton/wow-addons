local _, MR = ...

MR.UI = {}
local UI = MR.UI

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
-- Info tooltip (secondary, shows source details)
--------------------------------------------------------------------------
local infoTooltip

local function GetInfoTooltip()
    if not infoTooltip then
        infoTooltip = CreateFrame("GameTooltip", "MidnightRecipesInfoTooltip", UIParent, "GameTooltipTemplate")
        infoTooltip:SetFrameStrata("TOOLTIP")
    end
    return infoTooltip
end

local function ShowInfoTooltip(owner, recipe)
    local tt = GetInfoTooltip()
    tt:SetOwner(owner, "ANCHOR_PRESERVE")
    tt:ClearAllPoints()
    tt:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 2, 0)

    local theme = MUI.Theme
    local sr, sg, sb = theme:SourceColor(recipe.source)
    local label = SOURCE_LABELS[recipe.source] or recipe.source

    local c = theme.colors
    tt:AddLine("Midnight Recipes", c.ttTitle[1], c.ttTitle[2], c.ttTitle[3])
    tt:AddDoubleLine("Source:", label, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], sr, sg, sb)

    if recipe.sourceInfo then
        tt:AddLine(recipe.sourceInfo, 1, 1, 1)
    end

    -- Location from waypoint
    if recipe.waypoint then
        local wp = recipe.waypoint
        if wp[1] and wp[1] > 0 then
            local mapInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(wp[1])
            local mapName = mapInfo and mapInfo.name or ("Map " .. wp[1])
            tt:AddDoubleLine("Zone:", mapName, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttValue[1], c.ttValue[2], c.ttValue[3])
            if wp[2] and wp[3] then
                tt:AddDoubleLine("Coords:", format("%.1f, %.1f", wp[2] * 100, wp[3] * 100), c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttValue[1], c.ttValue[2], c.ttValue[3])
            end
        end
    end

    -- Vendor cost (gold, and/or one or two currencies)
    if recipe.cost then
        if recipe.cost.gold then
            local playerGold = GetMoney and GetMoney() or 0
            local gr, gg, gb = 1, 1, 1
            if playerGold < recipe.cost.gold then gr, gg, gb = c.ttCostBad[1], c.ttCostBad[2], c.ttCostBad[3] end
            tt:AddDoubleLine("Cost:", MUI.FormatGold(recipe.cost.gold), c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], gr, gg, gb)
        end
        local parts = {}
        for _, key in ipairs({"currency", "currency2"}) do
            local cur = recipe.cost[key]
            if cur then
                local currID, amount = cur[1], cur[2]
                local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currID)
                local icon = info and info.iconFileID
                local name = info and info.name or ("Currency " .. currID)
                local owned = info and info.quantity or 0
                local color = owned >= amount and "" or "|cffff4d4d"
                local costLabel = icon and (amount .. " |T" .. icon .. ":0|t") or (amount .. " " .. name)
                parts[#parts + 1] = color .. costLabel .. "|r"
            end
        end
        if #parts > 0 then
            tt:AddDoubleLine("Cost:", table.concat(parts, "  "), c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], 1, 1, 1)
        end
    end

    -- Drop info
    if recipe.dropInfo then
        local di = recipe.dropInfo
        if di.mob then
            tt:AddDoubleLine("Drops from:", di.mob, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttDropMob[1], c.ttDropMob[2], c.ttDropMob[3])
        end
        if di.zone then
            tt:AddDoubleLine("Zone:", di.zone, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttValue[1], c.ttValue[2], c.ttValue[3])
        end
        if di.rate then
            tt:AddDoubleLine("Drop rate:", di.rate, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttDropRate[1], c.ttDropRate[2], c.ttDropRate[3])
        end
        if di.boss then
            tt:AddLine("Boss drop", c.ttBoss[1], c.ttBoss[2], c.ttBoss[3])
        end
    end

    -- Specialization info
    if recipe.specInfo then
        local si = recipe.specInfo
        if si.tree then
            tt:AddDoubleLine("Spec tree:", si.tree, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttSpec[1], c.ttSpec[2], c.ttSpec[3])
        end
        if si.node then
            tt:AddDoubleLine("Node:", si.node, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttSpec[1], c.ttSpec[2], c.ttSpec[3])
        end
        if si.points then
            tt:AddDoubleLine("Points:", tostring(si.points), c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], 1, 1, 1)
        end
    end

    -- Click hints
    tt:AddLine(" ")
    local src = recipe.source
    if (src == "trainer" or src == "vendor" or src == "discovery") and recipe.waypoint then
        tt:AddLine("Click to set TomTom waypoint", c.ttHintGreen[1], c.ttHintGreen[2], c.ttHintGreen[3])
    elseif src == "specialization" then
        tt:AddLine("Click to open profession window", c.ttHintGreen[1], c.ttHintGreen[2], c.ttHintGreen[3])
    end
    tt:AddLine("Shift-click to copy Wowhead URL", c.ttHintBlue[1], c.ttHintBlue[2], c.ttHintBlue[3])

    tt:Show()
end

local function HideInfoTooltip()
    if infoTooltip then infoTooltip:Hide() end
end

--------------------------------------------------------------------------
-- Click actions per source type
--------------------------------------------------------------------------
StaticPopupDialogs["MIDNIGHTRECIPES_WOWHEAD"] = {
    text = "Copy Wowhead URL:",
    button1 = CLOSE,
    hasEditBox = true,
    editBoxWidth = 280,
    OnShow = function(self, data)
        local editBox = self.editBox
        editBox:SetText(data)
        editBox:HighlightText()
        editBox:SetFocus()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function OpenWowhead(spellID)
    local url = "https://www.wowhead.com/spell=" .. spellID
    StaticPopup_Show("MIDNIGHTRECIPES_WOWHEAD", nil, nil, url)
end

local function DoRecipeAction(recipe, skillLine)
    if IsShiftKeyDown() then
        OpenWowhead(recipe.id)
        return
    end
    local src = recipe.source
    if (src == "trainer" or src == "vendor" or src == "discovery") and recipe.waypoint then
        local wp = recipe.waypoint
        if wp[1] and wp[1] > 0 then
            if TomTom then
                local title = wp[4] or recipe.sourceInfo or recipe.name
                TomTom:AddWaypoint(wp[1], wp[2], wp[3], { title = title })
                print(format("|cff80c0ff[Midnight Recipes]|r Waypoint set: %s", title))
            else
                print("|cff80c0ff[Midnight Recipes]|r TomTom addon required for waypoints.")
            end
        end
    elseif src == "specialization" then
        if InCombatLockdown() then
            print("|cff80c0ff[Midnight Recipes]|r Cannot open profession window during combat.")
            return
        end
        local ok = pcall(function()
            C_TradeSkillUI.OpenTradeSkill(skillLine)
        end)
        if not ok then
            print("|cff80c0ff[Midnight Recipes]|r Could not open profession window.")
        end
    end
end

--------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------
function UI:Toggle()
    if not self.panel then self:Create() end
    self.panel:Toggle()
end

function UI:Show()
    if not self.panel then self:Create() end
    self.panel:Show()
end

function UI:Hide()
    if self.panel then self.panel:Hide() end
end

--------------------------------------------------------------------------
-- Frame creation (thin wrapper around MUI panel)
--------------------------------------------------------------------------
function UI:Create()
    if self.panel then return end

    local panel = MUI:CreatePanel({
        name          = "MidnightRecipes",
        title         = "Midnight Recipes",
        icon          = "Interface\\Icons\\INV_Scroll_03",
        db            = MR.db,
        defaultWidth  = 360,
        defaultHeight = 520,
        minWidth      = 240,
        maxWidth      = 600,
        minHeight     = 120,
        maxHeight     = 900,
        onRefresh     = function() UI:Refresh() end,
    })

    self.panel = panel
    self.frame = panel.frame

    self.panel:PopulateConfig({
        { type = "section", label = "DISPLAY" },
        { type = "checkbox", label = "Lock Frame",
            get = function() return MR.db.locked end,
            set = function(v)
                MR.db.locked = v
                if self.frame then self.frame:SetMovable(not v) end
                self.panel:UpdateDraggerVisibility()
            end },
        { type = "checkbox", label = "Show Learned Recipes",
            get = function() return MR.db.showLearned end,
            set = function(v)
                MR.db.showLearned = v
                self:Refresh()
            end },
        { type = "checkbox", label = "Hide Minimap Icon",
            get = function()
                return MR.db.minimap and MR.db.minimap.hide or false
            end,
            set = function(v)
                if MR.db.minimap then MR.db.minimap.hide = v end
                if MR.MinimapButton and MR.MinimapButton.Update then
                    MR.MinimapButton:Update()
                end
            end },
        { type = "divider" },
        { type = "section", label = "APPEARANCE" },
        { type = "slider", label = "Background Opacity", min = 0.1, max = 1.0, step = 0.05,
            get = function() return MR.db.frameAlpha or 1.0 end,
            set = function(v)
                MR.db.frameAlpha = v
                self.panel:ApplyBackdrop()
                self:Refresh()
            end,
            fillColor = { 0.40, 0.40, 0.40 } },
        { type = "slider", label = "Frame Scale", min = 0.5, max = 2.0, step = 0.05,
            get = function() return MR.db.frameScale or 1.0 end,
            set = function(v)
                MR.db.frameScale = v
                if self.frame then self.frame:SetScale(v) end
            end,
            fillColor = { 0.16, 0.78, 0.75 } },
    })
end

--------------------------------------------------------------------------
-- ToggleConfig
--------------------------------------------------------------------------
function UI:ToggleConfig()
    if not self.panel then return end
    self.panel:ToggleConfig()
end

--------------------------------------------------------------------------
-- Refresh
--------------------------------------------------------------------------
function UI:Refresh()
    if not self.panel or not self.panel.scrollChild then return end
    if not MR.Scanner then return end

    self.panel.pool:ReleaseAll()

    local child = self.panel.scrollChild
    local yOff = 0
    local totalLearned, totalRecipes = 0, 0

    for _, skillLine in ipairs(MR.PROF_ORDER) do
        local result = MR.Scanner.results[skillLine]
        local profInfo = MR.professions[skillLine]
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

    local _, collapsed, newY = self.panel:RenderHeader(parent, yOff, {
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
    })
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
    if MR.db.showLearned and #result.learned > 0 then
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

    local _, collapsed, newY = self.panel:RenderHeader(parent, yOff, {
        height     = 20,
        indent     = 4,
        collKey    = "src_" .. tostring(skillLine) .. "_" .. srcType,
        accentR    = sr, accentG = sg, accentB = sb,
        label      = SOURCE_LABELS[srcType] or srcType,
        labelColor = { sr, sg, sb },
        count      = tostring(#recipes),
        countColor = theme.colors.countDim,
    })
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

    local _, collapsed, newY = self.panel:RenderHeader(parent, yOff, {
        height     = 20,
        indent     = 4,
        collKey    = "learned_" .. tostring(skillLine),
        accentR    = la[1], accentG = la[2], accentB = la[3],
        label      = "Learned",
        labelColor = { la[1], la[2], la[3] },
        count      = tostring(#recipes),
        countColor = theme.colors.countDim,
    })
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
        ShowInfoTooltip(r, recipe)
    end)
    row:SetScript("OnLeave", function()
        hoverTex:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
        HideInfoTooltip()
    end)

    -- Click action
    if not isLearned and skillLine then
        row:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then DoRecipeAction(recipe, skillLine) end
        end)
    end

    return yOff + ROW_HEIGHT
end
