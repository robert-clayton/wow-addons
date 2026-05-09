local _, MC = ...

local mod = MC.modulesByKey["rares"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local SECTION_PAD = 8
local ROW_HEIGHT  = 18

local SOURCE_SET = {}
for _, s in ipairs(MC.RareSourceOrder) do SOURCE_SET[s] = true end

function UI:Init(panel, m)
    self.panel = panel
    self.mod = m
end

function UI:GetConfigDefs()
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
    for _, srcType in ipairs(MC.RareSourceOrder) do
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
            and "All Midnight rares defeated!"
            or "No remaining rares to track."
        local color = (r.collectedCount == r.total and r.total > 0)
            and MUI.Theme.colors.textComplete or nil
        yOff = MUI.ShowEmptyMessage(child, msg, color)
    else
        MUI.HideEmptyMessage(child)
    end

    self.panel:RefreshScrollContent(yOff)
end

-- Drop-source colour for the per-zone accent.
local function zoneColor()
    return MUI.Theme:SourceColor("drop")
end

function UI:RenderSourceGroup(parent, srcType, entries, yOff)
    local theme = MUI.Theme
    local sr, sg, sb = zoneColor()
    local _, collapsed, newY = MUI.RenderCollapsibleHeader(
        self.panel.pool, parent, yOff, {
            height     = 20,
            indent     = 0,
            collKey    = "src_" .. srcType,
            accentR    = sr, accentG = sg, accentB = sb,
            label      = MC.RareSourceLabels[srcType] or srcType,
            labelColor = { sr, sg, sb },
            count      = tostring(#entries),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY
    if collapsed then return yOff end
    for _, rare in ipairs(entries) do
        yOff = self:RenderRareRow(parent, rare, yOff, false)
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
            collKey    = "defeated",
            accentR    = la[1], accentG = la[2], accentB = la[3],
            label      = "Defeated",
            labelColor = { la[1], la[2], la[3] },
            count      = tostring(#entries),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY
    if collapsed then return yOff end
    for _, rare in ipairs(entries) do
        yOff = self:RenderRareRow(parent, rare, yOff, true)
    end
    return yOff
end

function UI:RenderRareRow(parent, rare, yOff, isCollected)
    local sr, sg, sb = zoneColor()
    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height      = ROW_HEIGHT,
        indent      = 8,
        leading     = { kind = "dot", size = 6, color = { sr, sg, sb } },
        name        = rare.name,
        info        = rare.zone,
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
        onLeave = function()
            GameTooltip:Hide()
            MC.HideInfoTooltip()
        end,
        onClick = function() MC.DoItemAction(rare) end,
    })
end
