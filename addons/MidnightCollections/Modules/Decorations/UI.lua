local _, MC = ...

local mod = MC.modulesByKey["decorations"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local SECTION_PAD = 8
local ROW_HEIGHT  = 22
local ICON_SIZE   = 24

local SOURCE_SET = {}
for _, s in ipairs(MC.DecoSourceOrder) do SOURCE_SET[s] = true end

function UI:Init(panel, m)
    self.panel = panel
    self.mod = m
end

function UI:GetConfigDefs()
    local db = mod.db
    return {
        { type = "checkbox", label = "Hide Trading Post Decorations",
            get = function() return db.hideTradingPost end,
            set = function(v)
                db.hideTradingPost = v
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
    for _, srcType in ipairs(MC.DecoSourceOrder) do
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
            and "All Midnight decorations collected!"
            or "No uncollected Midnight decorations found."
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
            label      = MC.DecoSourceLabels[srcType] or srcType,
            labelColor = { sr, sg, sb },
            count      = tostring(#entries),
            countColor = theme.colors.countDim,
        }, mod.db, function() self:Refresh() end)
    yOff = newY
    if collapsed then return yOff end

    if srcType == "crafted" then
        local byProf = MUI.GroupByField(entries, "skillLine", 0)
        local profSet = {}
        for _, sl in ipairs(MC.DecoProfOrder) do profSet[sl] = true end
        for _, skillLine in ipairs(MC.DecoProfOrder) do
            local profEntries = byProf[skillLine]
            if profEntries and #profEntries > 0 then
                yOff = self:RenderProfSubGroup(parent, skillLine, profEntries, yOff)
            end
        end
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

function UI:RenderDecoRow(parent, deco, yOff, isCollected)
    local theme = MUI.Theme
    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height      = ROW_HEIGHT,
        indent      = 8,
        leading     = { kind = "icon", size = ICON_SIZE,
                        texture = deco.icon,
                        fallback = "Interface\\Icons\\INV_Misc_Rune_01" },
        name        = deco.name,
        info        = deco.zone,
        isCollected = isCollected,
        onEnter = function(r)
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
            local sr, sg, sb = theme:SourceColor(deco.source)
            local label = MC.DecoSourceLabels[deco.source] or deco.source
            MC.ShowItemInfoTooltip(r, deco, label, sr, sg, sb)
        end,
        onLeave = function()
            GameTooltip:Hide()
            MC.HideInfoTooltip()
        end,
        onClick = function() MC.DoItemAction(deco) end,
    })
end
