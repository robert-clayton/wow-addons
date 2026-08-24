local _, MC = ...

local mod = MC.modulesByKey["mounts"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local ROW_HEIGHT = 22
local ICON_SIZE  = 24

function UI:Init(panel, m)
    self.panel = panel
    self.mod = m
    self._refresh = function() self:Refresh() end
end

function UI:GetConfigDefs()
    local db = mod.db
    return {
        { type = "checkbox", label = "Hide unavailable mounts",
            get = function() return db.hideUnavailable ~= false end,
            set = function(v)
                db.hideUnavailable = v
                if mod.Scanner then MC.ScanNow(mod) end
                MC.RefreshActive()
            end },
        { type = "checkbox", label = "Hide Trading Post Mounts",
            get = function() return db.hideTradingPost end,
            set = function(v)
                db.hideTradingPost = v
                if mod.Scanner then MC.ScanNow(mod) end
                MC.RefreshActive()
            end },
    }
end

function UI:Refresh()
    MUI.RenderModulePage(self.panel, {
        results       = mod.Scanner and mod.Scanner.results,
        sourceOrder   = MC.MountSourceOrder,
        renderSourceGroup = function(p, s, e, y) return self:RenderSourceGroup(p, s, e, y) end,
        renderRow     = function(p, m, y, c) return self:RenderMountRow(p, m, y, c) end,
        showCollected = mod.db.showCollected,
        db            = mod.db,
        refreshCb     = self._refresh,
        emptyMessages = {
            allDone  = "All Midnight mounts collected!",
            noneLeft = "No uncollected Midnight mounts found.",
        },
    })
end

function UI:RenderSourceGroup(parent, srcType, entries, yOff)
    local sr, sg, sb = MUI.Theme:SourceColor(srcType)
    local _, collapsed, newY = MUI.RenderSourceHeader(self.panel.pool, parent, yOff, {
        label       = MC.MountSourceLabels[srcType] or srcType,
        accentColor = { sr, sg, sb },
        count       = #entries,
        collKey     = "src_" .. srcType,
    }, mod.db, self._refresh)
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
    local _, collapsed, newY = MUI.RenderSourceHeader(self.panel.pool, parent, yOff, {
        label       = zoneName,
        accentColor = { sr, sg, sb },
        labelColor  = { sr * 0.85, sg * 0.85, sb * 0.85 },
        count       = #mounts,
        collKey     = "zone_" .. zoneName,
        height      = 18,
        indent      = 10,
    }, mod.db, self._refresh)
    yOff = newY
    if collapsed then return yOff end
    for _, mount in ipairs(mounts) do
        yOff = self:RenderMountRow(parent, mount, yOff, false)
    end
    return yOff
end

function UI:RenderMountRow(parent, mount, yOff, isCollected)
    -- Offscreen: bail before the opts table below is constructed. Lua builds
    -- it at the call site, so letting RenderItemRow skip saves the frame but
    -- not the garbage.
    if MUI.RowHidden(self.panel.pool, yOff, ROW_HEIGHT) then return yOff + ROW_HEIGHT end

    local theme = MUI.Theme
    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height      = ROW_HEIGHT,
        indent      = 8,
        leading     = { kind = "icon", size = ICON_SIZE,
                        texture = mount.icon,
                        fallback = "Interface\\Icons\\Ability_Mount_RidingHorse" },
        name        = mount.name,
        info        = mount.future and MC.GetAvailabilityBadge(mount) or mount.zone,
        isCollected = isCollected,
        onEnter = function(r)
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            GameTooltip:AddLine(mount.name, 1, 1, 1)
            if mount.mountID and mount.mountID > 0 and C_MountJournal and C_MountJournal.GetMountInfoExtraByID then
                local _, description, source = C_MountJournal.GetMountInfoExtraByID(mount.mountID)
                if description then GameTooltip:AddLine(description, 0.7, 0.7, 0.7, true) end
                if source then
                    GameTooltip:AddLine(MC.SanitizeGameText(source),
                        0.5, 0.8, 0.5, true)
                end
            end
            GameTooltip:Show()
            local sr, sg, sb = theme:SourceColor(mount.source)
            local label = MC.MountSourceLabels[mount.source] or mount.source
            MC.ShowItemInfoTooltip(r, mount, label, sr, sg, sb)
        end,
        onLeave = MC.RowOnLeave,
        onClick = function() MC.DoItemAction(mount) end,
    })
end
