local _, MC = ...

local mod = MC.modulesByKey["pets"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local ROW_HEIGHT     = 20
local HEADER_HEIGHT  = 24
local SECTION_PAD    = 8
local PADDING        = 6

local SOURCE_COLORS = {
    wild        = { 0.40, 0.90, 0.40 },
    vendor      = { 0.30, 0.60, 1.00 },
    drop        = { 0.90, 0.40, 0.30 },
    quest       = { 0.90, 0.80, 0.20 },
    treasure    = { 0.85, 0.65, 0.30 },
    achievement = { 0.90, 0.70, 0.20 },
    delve       = { 0.55, 0.75, 0.90 },
    profession  = { 0.80, 0.50, 0.90 },
    tradingpost = { 0.90, 0.55, 0.80 },
    event       = { 0.70, 0.70, 0.70 },
}

local SOURCE_SET = {}
for _, s in ipairs(MC.PetSourceOrder) do SOURCE_SET[s] = true end

local function SourceColor(srcType)
    local c = SOURCE_COLORS[srcType]
    if c then return c[1], c[2], c[3] end
    return 0.7, 0.7, 0.7
end

--------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------
function UI:Init(panel, m)
    self.panel = panel
    self.mod = m
end

--------------------------------------------------------------------------
-- Config definitions
--------------------------------------------------------------------------
function UI:GetConfigDefs()
    local db = mod.db
    return {
        { type = "checkbox", label = "Show Collected Pets",
            get = function() return db.showCollected end,
            set = function(v) db.showCollected = v; MC.RefreshActive() end },
        { type = "checkbox", label = "Wild Pet Nearby Alerts",
            get = function() return db.wildAlerts end,
            set = function(v) db.wildAlerts = v end },
        { type = "checkbox", label = "Hide Trading Post Pets",
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

    for _, srcType in ipairs(MC.PetSourceOrder) do
        local entries = r.bySource[srcType]
        if entries and #entries > 0 then
            yOff = self:RenderSourceGroup(child, srcType, entries, yOff)
            yOff = yOff + SECTION_PAD
        end
    end

    for srcType, entries in pairs(r.bySource) do
        if not SOURCE_SET[srcType] and #entries > 0 then
            yOff = self:RenderSourceGroup(child, srcType, entries, yOff)
            yOff = yOff + SECTION_PAD
        end
    end

    if mod.db.showCollected and #r.collected > 0 then
        yOff = self:RenderCollectedGroup(child, r.collected, yOff)
    end

    if self.panel.titleProgressText then
        if r.total > 0 then
            self.panel.titleProgressText:SetText(format("%d / %d", r.collectedCount, r.total))
        else
            self.panel.titleProgressText:SetText("")
        end
    end

    local theme = MUI.Theme
    local emptyText = MUI.GetOrCreate(child, "emptyText", function(p)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize, "OUTLINE")
        return fs
    end)
    if yOff == 0 then
        emptyText:SetPoint("TOP", child, "TOP", 0, -20)
        emptyText:SetText("No uncollected Midnight pets found.")
        emptyText:SetTextColor(0.7, 0.7, 0.7)
        emptyText:Show()
        yOff = 60
    else
        emptyText:Hide()
    end

    self.panel:RefreshScrollContent(yOff)
end

--------------------------------------------------------------------------
-- Render: Source group
--------------------------------------------------------------------------
local ZONE_ORDER = {
    "Eversong Woods", "Silvermoon City", "Harandar", "Voidstorm",
    "Zul'Aman", "Isle of Quel'Danas",
}
local ZONE_SET = {}
for _, z in ipairs(ZONE_ORDER) do ZONE_SET[z] = true end

local function GroupByZone(entries)
    local byZone = {}
    for _, pet in ipairs(entries) do
        local z = pet.zone or "Unknown"
        if not byZone[z] then byZone[z] = {} end
        byZone[z][#byZone[z] + 1] = pet
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
            label      = MC.PetSourceLabels[srcType] or srcType,
            labelColor = { sr, sg, sb },
            count      = tostring(#entries),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY

    if collapsed then return yOff end

    if srcType == "wild" then
        local byZone = GroupByZone(entries)
        for _, zoneName in ipairs(ZONE_ORDER) do
            local pets = byZone[zoneName]
            if pets and #pets > 0 then
                yOff = self:RenderZoneSubGroup(parent, zoneName, pets, yOff, sr, sg, sb)
            end
        end
        for zoneName, pets in pairs(byZone) do
            if not ZONE_SET[zoneName] and #pets > 0 then
                yOff = self:RenderZoneSubGroup(parent, zoneName, pets, yOff, sr, sg, sb)
            end
        end
    else
        for _, pet in ipairs(entries) do
            yOff = self:RenderPetRow(parent, pet, yOff, false)
        end
    end

    return yOff
end

--------------------------------------------------------------------------
-- Render: Zone sub-group
--------------------------------------------------------------------------
function UI:RenderZoneSubGroup(parent, zoneName, pets, yOff, sr, sg, sb)
    local theme = MUI.Theme

    local _, collapsed, newY = MUI.RenderCollapsibleHeader(
        self.panel.pool, parent, yOff, {
            height     = 18,
            indent     = 10,
            collKey    = "zone_" .. zoneName,
            accentR    = sr, accentG = sg, accentB = sb,
            label      = zoneName,
            labelColor = { sr * 0.85, sg * 0.85, sb * 0.85 },
            count      = tostring(#pets),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY

    if collapsed then return yOff end

    for _, pet in ipairs(pets) do
        yOff = self:RenderPetRow(parent, pet, yOff, false)
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

    for _, pet in ipairs(entries) do
        yOff = self:RenderPetRow(parent, pet, yOff, true)
    end

    return yOff
end

--------------------------------------------------------------------------
-- Render: Pet row
--------------------------------------------------------------------------
function UI:RenderPetRow(parent, pet, yOff, isCollected)
    local theme = MUI.Theme

    local row = self.panel.pool:Acquire(parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -yOff)
    row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

    local rc = theme.colors.rowHover
    local hoverTex = MUI.GetOrCreate(row, "hover", function(p)
        local t = p:CreateTexture(nil, "BACKGROUND", nil, 1)
        return t
    end)
    hoverTex:SetAllPoints()
    hoverTex:SetColorTexture(1, 1, 1, 0)

    local petIcon = MUI.GetOrCreate(row, "icon", function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetSize(16, 16)
        return t
    end)
    petIcon:SetPoint("LEFT", row, "LEFT", PADDING, 0)
    if pet.icon then
        petIcon:SetTexture(pet.icon)
    else
        petIcon:SetTexture("Interface\\Icons\\INV_Pet_BabyBlizzardBear")
    end
    if isCollected then
        petIcon:SetDesaturated(true)
        petIcon:SetAlpha(0.5)
    else
        petIcon:SetDesaturated(false)
        petIcon:SetAlpha(1)
    end

    local nameFs = MUI.GetOrCreate(row, "name", function(p)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize, "OUTLINE")
        return fs
    end)
    nameFs:SetFont(theme.font, theme.fontSize, "OUTLINE")
    nameFs:SetJustifyH("LEFT")
    nameFs:SetWordWrap(false)
    nameFs:SetPoint("LEFT", row, "LEFT", PADDING + 20, 0)
    nameFs:SetPoint("RIGHT", row, "RIGHT", -50, 0)
    nameFs:SetText(pet.name)

    if isCollected then
        nameFs:SetTextColor(unpack(theme.colors.textDim))
    else
        nameFs:SetTextColor(unpack(theme.colors.text))
    end

    local typeFs = MUI.GetOrCreate(row, "petType", function(p)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize - 2, "OUTLINE")
        return fs
    end)
    typeFs:SetFont(theme.font, theme.fontSize - 2, "OUTLINE")
    typeFs:SetJustifyH("RIGHT")
    typeFs:SetPoint("RIGHT", row, "RIGHT", -PADDING, 0)
    local typeName = MC.PetTypeNames[pet.petType] or ""
    typeFs:SetText(typeName)
    typeFs:SetTextColor(0.45, 0.45, 0.45)

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

    row:SetScript("OnEnter", function(r)
        hoverTex:SetColorTexture(rc[1], rc[2], rc[3], rc[4])
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        GameTooltip:AddLine(pet.name, 1, 1, 1)
        if pet.icon then
            if C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID then
                local ok, _, _, petType, companionID, tooltipSource, tooltipDescription = pcall(C_PetJournal.GetPetInfoBySpeciesID, pet.speciesID)
                if ok and tooltipDescription then
                    GameTooltip:AddLine(tooltipDescription, 0.7, 0.7, 0.7, true)
                end
                if ok and tooltipSource then
                    GameTooltip:AddLine(tooltipSource, 0.5, 0.8, 0.5, true)
                end
            end
        end
        GameTooltip:Show()
        local sr, sg, sb = SourceColor(pet.source)
        local label = MC.PetSourceLabels[pet.source] or pet.source
        MC.ShowItemInfoTooltip(r, pet, label, sr, sg, sb)
    end)
    row:SetScript("OnLeave", function()
        hoverTex:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
        MC.HideInfoTooltip()
    end)

    if not isCollected then
        row:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then MC.DoItemAction(pet) end
        end)
    end

    return yOff + ROW_HEIGHT
end
