local _, MC = ...

local mod = MC.modulesByKey["mounts"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local SECTION_PAD = 8
local ROW_HEIGHT  = 22
local ICON_SIZE   = 24

local SOURCE_SET = {}
for _, s in ipairs(MC.MountSourceOrder) do SOURCE_SET[s] = true end

function UI:Init(panel, m)
    self.panel = panel
    self.mod = m
end

function UI:GetConfigDefs()
    -- Show Collected toggle is auto-injected by Core.BuildConfig
    return {}
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
    for _, srcType in ipairs(MC.MountSourceOrder) do
        local entries = r.bySource[srcType]
        if entries and #entries > 0 then
            yOff = self:RenderSourceGroup(child, srcType, entries, yOff)
            yOff = yOff + SECTION_PAD
        end
    end
    -- Catch-all for unknown source types
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
        local msg = r.collectedCount == r.total and r.total > 0
            and "All Midnight mounts collected!"
            or "No uncollected Midnight mounts found."
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
            label      = MC.MountSourceLabels[srcType] or srcType,
            labelColor = { sr, sg, sb },
            count      = tostring(#entries),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY
    if collapsed then return yOff end

    if srcType == "drop" then
        local byZone = MUI.GroupByField(entries, "zone", "Unknown")
        for _, zoneName in ipairs(MUI.MidnightZoneOrder) do
            local mounts = byZone[zoneName]
            if mounts and #mounts > 0 then
                yOff = self:RenderZoneSubGroup(parent, zoneName, mounts, yOff, sr, sg, sb)
            end
        end
        for zoneName, mounts in pairs(byZone) do
            if not MUI.MidnightZoneSet[zoneName] and #mounts > 0 then
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

function UI:RenderMountRow(parent, mount, yOff, isCollected)
    local theme = MUI.Theme
    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height      = ROW_HEIGHT,
        indent      = 8,
        leading     = { kind = "icon", size = ICON_SIZE,
                        texture = mount.icon,
                        fallback = "Interface\\Icons\\Ability_Mount_RidingHorse" },
        name        = mount.name,
        info        = mount.zone,
        isCollected = isCollected,
        onEnter = function(r)
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            GameTooltip:AddLine(mount.name, 1, 1, 1)
            if mount.mountID and mount.mountID > 0 and C_MountJournal and C_MountJournal.GetMountInfoExtraByID then
                local _, description, source = C_MountJournal.GetMountInfoExtraByID(mount.mountID)
                if description then GameTooltip:AddLine(description, 0.7, 0.7, 0.7, true) end
                if source then GameTooltip:AddLine(source, 0.5, 0.8, 0.5, true) end
            end
            GameTooltip:Show()
            local sr, sg, sb = theme:SourceColor(mount.source)
            local label = MC.MountSourceLabels[mount.source] or mount.source
            MC.ShowItemInfoTooltip(r, mount, label, sr, sg, sb)
        end,
        onLeave = function()
            GameTooltip:Hide()
            MC.HideInfoTooltip()
        end,
        onClick = function() MC.DoItemAction(mount) end,
    })
end
