local _, MC = ...

local mod = MC.modulesByKey["decorations"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local ROW_HEIGHT     = 20
local HEADER_HEIGHT  = 24
local SECTION_PAD    = 8
local PADDING        = 6
local ICON_SIZE      = 20

local SOURCE_COLORS = {
    crafted     = { 0.80, 0.50, 0.90 },
    vendor      = { 0.30, 0.60, 1.00 },
    quest       = { 0.90, 0.80, 0.20 },
    achievement = { 0.90, 0.70, 0.20 },
    drop        = { 0.90, 0.40, 0.30 },
    renown      = { 0.30, 0.60, 1.00 },
    tradingpost = { 0.90, 0.55, 0.80 },
    worldevent  = { 0.70, 0.70, 0.70 },
}

local SOURCE_SET = {}
for _, s in ipairs(MC.DecoSourceOrder) do SOURCE_SET[s] = true end

local function SourceColor(srcType)
    local c = SOURCE_COLORS[srcType]
    if c then return c[1], c[2], c[3] end
    return 0.7, 0.7, 0.7
end


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
        { type = "checkbox", label = "Show Collected Decorations",
            get = function() return db.showCollected end,
            set = function(v) db.showCollected = v; MC.RefreshActive() end },
        { type = "checkbox", label = "Hide Trading Post Decorations",
            get = function() return db.hideTradingPost end,
            set = function(v)
                db.hideTradingPost = v
                if mod.Scanner then mod.Scanner:Scan() end
                MC.RefreshActive()
            end },
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
    local r = mod.Scanner.results

    if not r or not r.total then
        self.panel:RefreshScrollContent(0)
        return
    end

    -- Source type groups
    for _, srcType in ipairs(MC.DecoSourceOrder) do
        local entries = r.bySource[srcType]
        if entries and #entries > 0 then
            yOff = self:RenderSourceGroup(child, srcType, entries, yOff)
            yOff = yOff + SECTION_PAD
        end
    end

    -- Catch-all: render any source types not in SOURCE_ORDER
    for srcType, entries in pairs(r.bySource) do
        if not SOURCE_SET[srcType] and #entries > 0 then
            yOff = self:RenderSourceGroup(child, srcType, entries, yOff)
            yOff = yOff + SECTION_PAD
        end
    end

    -- Collected
    if mod.db.showCollected and #r.collected > 0 then
        yOff = self:RenderCollectedGroup(child, r.collected, yOff)
    end

    -- Update title bar progress counter
    if self.panel.titleProgressText then
        if r.total > 0 then
            self.panel.titleProgressText:SetText(format("%d / %d", r.collectedCount, r.total))
        else
            self.panel.titleProgressText:SetText("")
        end
    end

    -- emptyText: show when no content, hide otherwise
    local theme = MUI.Theme
    local emptyText = MUI.GetOrCreate(child, "emptyText", function(p)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize, "OUTLINE")
        return fs
    end)
    if yOff == 0 then
        emptyText:SetPoint("TOP", child, "TOP", 0, -20)
        emptyText:SetText("No uncollected Midnight decorations found.")
        emptyText:SetTextColor(0.7, 0.7, 0.7)
        emptyText:Show()
        yOff = 60
    else
        emptyText:Hide()
    end

    self.panel:RefreshScrollContent(yOff)
end

--------------------------------------------------------------------------
-- Render: Source group (collapsible)
--------------------------------------------------------------------------
local function GroupByProfession(entries)
    local byProf = {}
    for _, deco in ipairs(entries) do
        local sl = deco.skillLine or 0
        if not byProf[sl] then byProf[sl] = {} end
        byProf[sl][#byProf[sl] + 1] = deco
    end
    return byProf
end

function UI:RenderSourceGroup(parent, srcType, entries, yOff)
    local theme = MUI.Theme
    local sr, sg, sb = SourceColor(srcType)

    local _, collapsed, newY = MUI.RenderCollapsibleHeader(
        self.panel.pool, parent, yOff, {
            height     = 20,
            indent     = 0,
            collKey    = "src_" .. srcType,
            accentR    = sr, accentG = sg, accentB = sb,
            label      = MC.DecoSourceLabels[srcType] or srcType,
            labelColor = { sr, sg, sb },
            count      = tostring(#entries),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY

    if collapsed then return yOff end

    -- Crafted: sub-group by profession
    if srcType == "crafted" then
        local byProf = GroupByProfession(entries)
        for _, skillLine in ipairs(MC.DecoProfOrder) do
            local profEntries = byProf[skillLine]
            if profEntries and #profEntries > 0 then
                yOff = self:RenderProfSubGroup(parent, skillLine, profEntries, yOff)
            end
        end
        -- Catch-all for unknown professions
        local profSet = {}
        for _, sl in ipairs(MC.DecoProfOrder) do profSet[sl] = true end
        for sl, profEntries in pairs(byProf) do
            if not profSet[sl] and #profEntries > 0 then
                yOff = self:RenderProfSubGroup(parent, sl, profEntries, yOff)
            end
        end
    else
        for _, deco in ipairs(entries) do
            yOff = self:RenderDecoRow(parent, deco, yOff, false)
        end
    end

    return yOff
end

--------------------------------------------------------------------------
-- Render: Profession sub-group within crafted (collapsible)
--------------------------------------------------------------------------
function UI:RenderProfSubGroup(parent, skillLine, decos, yOff)
    local theme = MUI.Theme
    local pr, pg, pb = theme:ProfAccentColor(skillLine)
    local profLabel = MC.DecoProfLabels[skillLine] or ("Profession " .. skillLine)

    local _, collapsed, newY = MUI.RenderCollapsibleHeader(
        self.panel.pool, parent, yOff, {
            height     = 18,
            indent     = 10,
            collKey    = "prof_" .. skillLine,
            accentR    = pr, accentG = pg, accentB = pb,
            label      = profLabel,
            labelColor = { pr * 0.85, pg * 0.85, pb * 0.85 },
            count      = tostring(#decos),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY

    if collapsed then return yOff end

    for _, deco in ipairs(decos) do
        yOff = self:RenderDecoRow(parent, deco, yOff, false)
    end

    return yOff
end

--------------------------------------------------------------------------
-- Render: Collected group
--------------------------------------------------------------------------
function UI:RenderCollectedGroup(parent, entries, yOff)
    local theme = MUI.Theme
    local la = theme.colors.learnedAccent

    local _, collapsed, newY = MUI.RenderCollapsibleHeader(
        self.panel.pool, parent, yOff, {
            height     = 20,
            indent     = 0,
            collKey    = "collected",
            accentR    = la[1], accentG = la[2], accentB = la[3],
            label      = "Collected",
            labelColor = { la[1], la[2], la[3] },
            count      = tostring(#entries),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY

    if collapsed then return yOff end

    for _, deco in ipairs(entries) do
        yOff = self:RenderDecoRow(parent, deco, yOff, true)
    end

    return yOff
end

--------------------------------------------------------------------------
-- Render: Decoration row (clickable)
--------------------------------------------------------------------------
function UI:RenderDecoRow(parent, deco, yOff, isCollected)
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

    -- Decoration icon (20x20)
    local decoIcon = MUI.GetOrCreate(row, "icon", function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetSize(ICON_SIZE, ICON_SIZE)
        return t
    end)
    decoIcon:SetPoint("LEFT", row, "LEFT", PADDING, 0)
    if deco.icon then
        decoIcon:SetTexture(deco.icon)
    else
        decoIcon:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
    end
    if isCollected then
        decoIcon:SetDesaturated(true)
        decoIcon:SetAlpha(0.5)
    else
        decoIcon:SetDesaturated(false)
        decoIcon:SetAlpha(1)
    end

    -- Decoration name
    local nameFs = MUI.GetOrCreate(row, "name", function(p)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize, "OUTLINE")
        return fs
    end)
    nameFs:SetFont(theme.font, theme.fontSize, "OUTLINE")
    nameFs:SetJustifyH("LEFT")
    nameFs:SetWordWrap(false)
    nameFs:SetPoint("LEFT", row, "LEFT", PADDING + 24, 0)
    nameFs:SetPoint("RIGHT", row, "RIGHT", -50, 0)
    nameFs:SetText(deco.name)

    if isCollected then
        nameFs:SetTextColor(unpack(theme.colors.textDim))
    else
        nameFs:SetTextColor(unpack(theme.colors.text))
    end

    -- Source info / zone label (right side, dim)
    local infoFs = MUI.GetOrCreate(row, "info", function(p)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize - 2, "OUTLINE")
        return fs
    end)
    infoFs:SetFont(theme.font, theme.fontSize - 2, "OUTLINE")
    infoFs:SetJustifyH("RIGHT")
    infoFs:SetPoint("RIGHT", row, "RIGHT", -PADDING, 0)
    local infoText = deco.zone or ""
    infoFs:SetText(infoText)
    infoFs:SetTextColor(0.45, 0.45, 0.45)

    -- Strikethrough line for collected decorations
    local strike = MUI.GetOrCreate(row, "strike", function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetHeight(1)
        return t
    end)
    if isCollected then
        strike:SetPoint("LEFT", nameFs, "LEFT", 0, 0)
        strike:SetPoint("RIGHT", nameFs, "RIGHT", 0, 0)
        strike:SetColorTexture(theme.colors.textDim[1], theme.colors.textDim[2], theme.colors.textDim[3], 0.5)
        strike:Show()
    else
        strike:Hide()
    end

    -- Tooltip on hover: primary = item tooltip (crafted) or name tooltip, secondary = info tooltip
    row:SetScript("OnEnter", function(r)
        hoverTex:SetColorTexture(rc[1], rc[2], rc[3], rc[4])
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        if deco.itemID and deco.itemID > 0 then
            GameTooltip:SetItemByID(deco.itemID)
        else
            GameTooltip:AddLine(deco.name, 1, 1, 1)
            if deco.sourceInfo then
                GameTooltip:AddLine(deco.sourceInfo, 0.7, 0.7, 0.7, true)
            end
        end
        GameTooltip:Show()
        local sr, sg, sb = SourceColor(deco.source)
        local label = MC.DecoSourceLabels[deco.source] or deco.source
        MC.ShowItemInfoTooltip(r, deco, label, sr, sg, sb)
    end)
    row:SetScript("OnLeave", function()
        hoverTex:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
        MC.HideInfoTooltip()
    end)

    -- Click action
    if not isCollected then
        row:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then MC.DoItemAction(deco) end
        end)
    end

    return yOff + ROW_HEIGHT
end
