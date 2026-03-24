local _, MC = ...

local mod = MC.modulesByKey["mounts"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local ROW_HEIGHT     = 22
local HEADER_HEIGHT  = 24
local SECTION_PAD    = 8
local PADDING        = 6
local ICON_SIZE      = 24

local SOURCE_COLORS = {
    renown      = { 0.30, 0.60, 1.00 },
    reputation  = { 0.20, 0.50, 0.90 },
    drop        = { 0.90, 0.40, 0.30 },
    achievement = { 0.90, 0.70, 0.20 },
    quest       = { 0.90, 0.80, 0.20 },
    delve       = { 0.55, 0.75, 0.90 },
    prey        = { 0.80, 0.30, 0.50 },
    dungeon     = { 0.70, 0.50, 0.90 },
    raid        = { 0.90, 0.40, 0.60 },
    pvp         = { 0.85, 0.30, 0.30 },
    worldevent  = { 0.70, 0.70, 0.70 },
    profession  = { 0.80, 0.50, 0.90 },
    vendor      = { 0.40, 0.80, 0.40 },
    prepatch    = { 0.60, 0.60, 0.60 },
}

local SOURCE_SET = {}
for _, s in ipairs(MC.MountSourceOrder) do SOURCE_SET[s] = true end

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
        { type = "checkbox", label = "Show Collected Mounts",
            get = function() return db.showCollected end,
            set = function(v) db.showCollected = v; MC.RefreshActive() end },
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
    for _, srcType in ipairs(MC.MountSourceOrder) do
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
        emptyText:SetText("No uncollected Midnight mounts found.")
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
local ZONE_ORDER = {
    "Eversong Woods", "Silvermoon City", "Harandar", "Voidstorm",
    "Zul'Aman", "Isle of Quel'Danas",
}
local ZONE_SET = {}
for _, z in ipairs(ZONE_ORDER) do ZONE_SET[z] = true end

local function GroupByZone(entries)
    local byZone = {}
    for _, mount in ipairs(entries) do
        local z = mount.zone or "Unknown"
        if not byZone[z] then byZone[z] = {} end
        byZone[z][#byZone[z] + 1] = mount
    end
    return byZone
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
            label      = MC.MountSourceLabels[srcType] or srcType,
            labelColor = { sr, sg, sb },
            count      = tostring(#entries),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY

    if collapsed then return yOff end

    -- Rare drops: sub-group by zone
    if srcType == "drop" then
        local byZone = GroupByZone(entries)
        for _, zoneName in ipairs(ZONE_ORDER) do
            local mounts = byZone[zoneName]
            if mounts and #mounts > 0 then
                yOff = self:RenderZoneSubGroup(parent, zoneName, mounts, yOff, sr, sg, sb)
            end
        end
        for zoneName, mounts in pairs(byZone) do
            if not ZONE_SET[zoneName] and #mounts > 0 then
                yOff = self:RenderZoneSubGroup(parent, zoneName, mounts, yOff, sr, sg, sb)
            end
        end
    else
        for _, mount in ipairs(entries) do
            yOff = self:RenderMountRow(parent, mount, yOff, false)
        end
    end

    return yOff
end

--------------------------------------------------------------------------
-- Render: Zone sub-group
--------------------------------------------------------------------------
function UI:RenderZoneSubGroup(parent, zoneName, mounts, yOff, sr, sg, sb)
    local theme = MUI.Theme

    local _, collapsed, newY = MUI.RenderCollapsibleHeader(
        self.panel.pool, parent, yOff, {
            height     = 18,
            indent     = 10,
            collKey    = "zone_" .. zoneName,
            accentR    = sr, accentG = sg, accentB = sb,
            label      = zoneName,
            labelColor = { sr * 0.85, sg * 0.85, sb * 0.85 },
            count      = tostring(#mounts),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY

    if collapsed then return yOff end

    for _, mount in ipairs(mounts) do
        yOff = self:RenderMountRow(parent, mount, yOff, false)
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

    for _, mount in ipairs(entries) do
        yOff = self:RenderMountRow(parent, mount, yOff, true)
    end

    return yOff
end

--------------------------------------------------------------------------
-- Render: Mount row
--------------------------------------------------------------------------
function UI:RenderMountRow(parent, mount, yOff, isCollected)
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

    -- Mount icon (24x24)
    local mountIcon = MUI.GetOrCreate(row, "icon", function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetSize(ICON_SIZE, ICON_SIZE)
        return t
    end)
    mountIcon:SetPoint("LEFT", row, "LEFT", PADDING, 0)
    if mount.icon then
        mountIcon:SetTexture(mount.icon)
    else
        mountIcon:SetTexture("Interface\\Icons\\Ability_Mount_RidingHorse")
    end
    if isCollected then
        mountIcon:SetDesaturated(true)
        mountIcon:SetAlpha(0.5)
    else
        mountIcon:SetDesaturated(false)
        mountIcon:SetAlpha(1)
    end

    -- Mount name
    local nameFs = MUI.GetOrCreate(row, "name", function(p)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize, "OUTLINE")
        return fs
    end)
    nameFs:SetFont(theme.font, theme.fontSize, "OUTLINE")
    nameFs:SetJustifyH("LEFT")
    nameFs:SetWordWrap(false)
    nameFs:SetPoint("LEFT", row, "LEFT", PADDING + 28, 0)
    nameFs:SetPoint("RIGHT", row, "RIGHT", -50, 0)
    nameFs:SetText(mount.name)

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
    local infoText = mount.zone or ""
    infoFs:SetText(infoText)
    infoFs:SetTextColor(0.45, 0.45, 0.45)

    -- Strikethrough line for collected mounts
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

    -- Tooltip on hover
    row:SetScript("OnEnter", function(r)
        hoverTex:SetColorTexture(rc[1], rc[2], rc[3], rc[4])
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        GameTooltip:AddLine(mount.name, 1, 1, 1)
        if mount.mountID and mount.mountID > 0 and C_MountJournal and C_MountJournal.GetMountInfoExtraByID then
            local ok, _, description, source = pcall(C_MountJournal.GetMountInfoExtraByID, mount.mountID)
            if ok and description then
                GameTooltip:AddLine(description, 0.7, 0.7, 0.7, true)
            end
            if ok and source then
                GameTooltip:AddLine(source, 0.5, 0.8, 0.5, true)
            end
        end
        GameTooltip:Show()
        local sr, sg, sb = SourceColor(mount.source)
        local label = MC.MountSourceLabels[mount.source] or mount.source
        MC.ShowItemInfoTooltip(r, mount, label, sr, sg, sb)
    end)
    row:SetScript("OnLeave", function()
        hoverTex:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
        MC.HideInfoTooltip()
    end)

    -- Click action
    if not isCollected then
        row:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then MC.DoItemAction(mount) end
        end)
    end

    return yOff + ROW_HEIGHT
end
