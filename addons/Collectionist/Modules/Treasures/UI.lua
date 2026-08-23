local _, MC = ...

local mod = MC.modulesByKey["treasures"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local ROW_HEIGHT = 18

function UI:Init(panel, m)
    self.panel = panel
    self.mod = m
    self._refresh = function() self:Refresh() end
end

function UI:GetConfigDefs()
    return {}
end

-- Treasure-themed accent (warm gold)
local function zoneColor()
    return 0.90, 0.78, 0.20
end

function UI:Refresh()
    MUI.RenderModulePage(self.panel, {
        results       = mod.Scanner and mod.Scanner.results,
        sourceOrder   = MC.TreasureSourceOrder,
        renderSourceGroup = function(p, s, e, y) return self:RenderSourceGroup(p, s, e, y) end,
        renderRow     = function(p, t, y, c) return self:RenderTreasureRow(p, t, y, c) end,
        showCollected = mod.db.showCollected,
        db            = mod.db,
        refreshCb     = self._refresh,
        collectedLabel = "Looted",
        collectedKey  = "looted",
        emptyMessages = {
            allDone  = "All Midnight treasures looted!",
            noneLeft = "No remaining treasures to track.",
        },
    })
end

function UI:RenderSourceGroup(parent, srcType, entries, yOff)
    local sr, sg, sb = zoneColor()
    local _, collapsed, newY = MUI.RenderSourceHeader(self.panel.pool, parent, yOff, {
        label       = MC.TreasureSourceLabels[srcType] or srcType,
        accentColor = { sr, sg, sb },
        count       = #entries,
        collKey     = "src_" .. srcType,
    }, mod.db, self._refresh)
    yOff = newY
    if collapsed then return yOff end
    for _, t in ipairs(entries) do
        yOff = self:RenderTreasureRow(parent, t, yOff, false)
    end
    return yOff
end

function UI:RenderTreasureRow(parent, t, yOff, isCollected)
    -- Offscreen: bail before the opts table below is constructed. Lua builds
    -- it at the call site, so letting RenderItemRow skip saves the frame but
    -- not the garbage.
    if MUI.RowHidden(self.panel.pool, yOff, ROW_HEIGHT) then return yOff + ROW_HEIGHT end

    local sr, sg, sb = zoneColor()
    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height      = ROW_HEIGHT,
        indent      = 8,
        leading     = { kind = "dot", size = 6, color = { sr, sg, sb } },
        name        = t.name,
        info        = t.future and MC.GetAvailabilityBadge(t)
                   or (t.navigationOnly and ("Location only - " .. (t.zone or "map")))
                   or t.zone,
        isCollected = isCollected,
        onEnter = function(r)
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            GameTooltip:AddLine(t.name, 1, 1, 1)
            GameTooltip:Show()
            MC.ShowItemInfoTooltip(r, t, "Treasure", sr, sg, sb)
        end,
        onLeave = MC.RowOnLeave,
        onClick = function() MC.DoItemAction(t) end,
    })
end
