local _, MC = ...

local mod = MC.modulesByKey["rares"]
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

-- Drop-source colour for the per-zone accent.
local function zoneColor()
    return MUI.Theme:SourceColor("drop")
end

function UI:Refresh()
    MUI.RenderModulePage(self.panel, {
        results       = mod.Scanner and mod.Scanner.results,
        sourceOrder   = MC.RareSourceOrder,
        renderSourceGroup = function(p, s, e, y) return self:RenderSourceGroup(p, s, e, y) end,
        renderRow     = function(p, r, y, c) return self:RenderRareRow(p, r, y, c) end,
        showCollected = mod.db.showCollected,
        db            = mod.db,
        refreshCb     = self._refresh,
        collectedLabel = "Defeated",
        collectedKey  = "defeated",
        emptyMessages = {
            allDone  = "All Midnight rares defeated!",
            noneLeft = "No remaining rares to track.",
        },
    })
end

function UI:RenderSourceGroup(parent, srcType, entries, yOff)
    local sr, sg, sb = zoneColor()
    local _, collapsed, newY = MUI.RenderSourceHeader(self.panel.pool, parent, yOff, {
        label       = MC.RareSourceLabels[srcType] or srcType,
        accentColor = { sr, sg, sb },
        count       = #entries,
        collKey     = "src_" .. srcType,
    }, mod.db, self._refresh)
    yOff = newY
    if collapsed then return yOff end
    for _, rare in ipairs(entries) do
        yOff = self:RenderRareRow(parent, rare, yOff, false)
    end
    return yOff
end

function UI:RenderRareRow(parent, rare, yOff, isCollected)
    -- Offscreen: bail before the opts table below is constructed. Lua builds
    -- it at the call site, so letting RenderItemRow skip saves the frame but
    -- not the garbage.
    if MUI.RowHidden(self.panel.pool, yOff, ROW_HEIGHT) then return yOff + ROW_HEIGHT end

    local sr, sg, sb = zoneColor()
    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height      = ROW_HEIGHT,
        indent      = 8,
        leading     = { kind = "dot", size = 6, color = { sr, sg, sb } },
        name        = rare.name,
        info        = rare.future and MC.GetAvailabilityBadge(rare)
                   or rare.zone,
        isCollected = isCollected,
        onEnter = function(r)
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            GameTooltip:AddLine(rare.name, 1, 1, 1)
            if rare.npcID then
                GameTooltip:AddLine(format("NPC %d", rare.npcID), 0.6, 0.6, 0.6)
            end
            GameTooltip:Show()
            MC.ShowItemInfoTooltip(r, rare, "Rare", sr, sg, sb)
        end,
        onLeave = MC.RowOnLeave,
        onClick = function() MC.DoItemAction(rare) end,
    })
end
