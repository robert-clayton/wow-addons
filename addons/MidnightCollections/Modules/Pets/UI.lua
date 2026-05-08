local _, MC = ...

local mod = MC.modulesByKey["pets"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local SECTION_PAD = 8
local ROW_HEIGHT  = 22
local ICON_SIZE   = 24

local SOURCE_SET = {}
for _, s in ipairs(MC.PetSourceOrder) do SOURCE_SET[s] = true end

function UI:Init(panel, m)
    self.panel = panel
    self.mod = m
end

function UI:GetConfigDefs()
    local db = mod.db
    return {
        { type = "checkbox", label = "Wild Pet Nearby Alerts",
            get = function() return db.wildAlerts end,
            set = function(v)
                db.wildAlerts = v
                if v and MC.ClearPetAlertCache then MC.ClearPetAlertCache() end
            end },
        { type = "checkbox", label = "Hide Trading Post Pets",
            get = function() return db.hideTradingPost end,
            set = function(v)
                db.hideTradingPost = v
                if mod.Scanner then mod.Scanner:Scan() end
                MC.RefreshActive()
            end },
        { type = "checkbox", label = "Hide unavailable pets",
            get = function() return db.hideUnavailable ~= false end,
            set = function(v)
                db.hideUnavailable = v
                if mod.Scanner then mod.Scanner:Scan() end
                MC.RefreshActive()
            end },
    }
end

function UI:Refresh()
    if not self.panel or not self.panel.scrollChild then return end
    if not mod.Scanner then return end

    self.panel.pool:ReleaseAll()

    local child = self.panel.scrollChild
    local r = mod.Scanner.results
    if not r or not r.total then
        self.panel:RefreshScrollContent(0)
        return
    end

    local yOff = 0
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
        self.panel.titleProgressText:SetText(
            r.total > 0 and format("%d / %d", r.collectedCount, r.total) or "")
    end

    if yOff == 0 then
        local msg = (r.collectedCount == r.total and r.total > 0)
            and "All Midnight pets collected!"
            or "No uncollected Midnight pets found."
        local color = (r.collectedCount == r.total and r.total > 0)
            and MUI.Theme.colors.textComplete or nil
        yOff = MUI.ShowEmptyMessage(child, msg, color)
    else
        MUI.HideEmptyMessage(child)
    end

    self.panel:RefreshScrollContent(yOff)
end

function UI:RenderSourceGroup(parent, srcType, entries, yOff)
    local theme = MUI.Theme
    local sr, sg, sb = theme:SourceColor(srcType)
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
        local byZone = MUI.GroupByField(entries, "zone", "Unknown")
        for _, zoneName in ipairs(MUI.MidnightZoneOrder) do
            local pets = byZone[zoneName]
            if pets and #pets > 0 then
                yOff = self:RenderZoneSubGroup(parent, zoneName, pets, yOff, sr, sg, sb)
            end
        end
        for zoneName, pets in pairs(byZone) do
            if not MUI.MidnightZoneSet[zoneName] and #pets > 0 then
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

function UI:RenderPetRow(parent, pet, yOff, isCollected)
    local theme = MUI.Theme
    local typeName = MC.PetTypeNames[pet.petType] or ""
    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height      = ROW_HEIGHT,
        indent      = 8,
        leading     = { kind = "icon", size = ICON_SIZE,
                        texture = pet.icon,
                        fallback = "Interface\\Icons\\INV_Pet_BabyBlizzardBear" },
        name        = pet.name,
        info        = typeName,
        isCollected = isCollected,
        onEnter = function(r)
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            GameTooltip:AddLine(pet.name, 1, 1, 1)
            if pet.speciesID and C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID then
                local _, _, _, _, tooltipSource, tooltipDescription =
                    C_PetJournal.GetPetInfoBySpeciesID(pet.speciesID)
                if tooltipDescription then GameTooltip:AddLine(tooltipDescription, 0.7, 0.7, 0.7, true) end
                if tooltipSource then GameTooltip:AddLine(tooltipSource, 0.5, 0.8, 0.5, true) end
            end
            GameTooltip:Show()
            local sr, sg, sb = theme:SourceColor(pet.source)
            local label = MC.PetSourceLabels[pet.source] or pet.source
            MC.ShowItemInfoTooltip(r, pet, label, sr, sg, sb)
        end,
        onLeave = function()
            GameTooltip:Hide()
            MC.HideInfoTooltip()
        end,
        onClick = function() MC.DoItemAction(pet) end,
    })
end
