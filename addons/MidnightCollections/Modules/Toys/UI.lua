local _, MC = ...

local mod = MC.modulesByKey["toys"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local SECTION_PAD = 8
local ROW_HEIGHT  = 20
local ICON_SIZE   = 20

local SOURCE_SET = {}
for _, s in ipairs(MC.ToySourceOrder) do SOURCE_SET[s] = true end

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
    for _, srcType in ipairs(MC.ToySourceOrder) do
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
            and "All Midnight toys collected!"
            or "No uncollected Midnight toys found."
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
            label      = MC.ToySourceLabels[srcType] or srcType,
            labelColor = { sr, sg, sb },
            count      = tostring(#entries),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY
    if collapsed then return yOff end
    for _, toy in ipairs(entries) do
        yOff = self:RenderToyRow(parent, toy, yOff, false)
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
    for _, toy in ipairs(entries) do
        yOff = self:RenderToyRow(parent, toy, yOff, true)
    end
    return yOff
end

function UI:RenderToyRow(parent, toy, yOff, isCollected)
    local theme = MUI.Theme
    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height      = ROW_HEIGHT,
        indent      = 8,
        leading     = { kind = "icon", size = ICON_SIZE,
                        texture = toy.icon,
                        fallback = "Interface\\Icons\\Trade_Archaeology_ChestOfTinyGlassAnimals" },
        name        = toy.name,
        info        = toy.zone,
        isCollected = isCollected,
        onEnter = function(r)
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            if toy.itemID and toy.itemID > 0 then
                GameTooltip:SetItemByID(toy.itemID)
            else
                GameTooltip:AddLine(toy.name, 1, 1, 1)
            end
            GameTooltip:Show()
            local sr, sg, sb = theme:SourceColor(toy.source)
            local label = MC.ToySourceLabels[toy.source] or toy.source
            MC.ShowItemInfoTooltip(r, toy, label, sr, sg, sb)
        end,
        onLeave = function()
            GameTooltip:Hide()
            MC.HideInfoTooltip()
        end,
        onClick = function() MC.DoItemAction(toy) end,
    })
end
