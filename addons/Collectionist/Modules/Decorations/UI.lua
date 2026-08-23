local _, MC = ...

local mod = MC.modulesByKey["decorations"]
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
        { type = "checkbox", label = "Hide Trading Post Decorations",
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
        sourceOrder   = MC.DecoSourceOrder,
        renderSourceGroup = function(p, s, e, y) return self:RenderSourceGroup(p, s, e, y) end,
        renderRow     = function(p, d, y, c) return self:RenderDecoRow(p, d, y, c) end,
        showCollected = mod.db.showCollected,
        db            = mod.db,
        refreshCb     = self._refresh,
        emptyMessages = {
            allDone  = "All Midnight decorations collected!",
            noneLeft = "No uncollected Midnight decorations found.",
        },
    })
end

function UI:RenderSourceGroup(parent, srcType, entries, yOff)
    local sr, sg, sb = MUI.Theme:SourceColor(srcType)
    local _, collapsed, newY = MUI.RenderSourceHeader(self.panel.pool, parent, yOff, {
        label       = MC.DecoSourceLabels[srcType] or srcType,
        accentColor = { sr, sg, sb },
        count       = #entries,
        collKey     = "src_" .. srcType,
    }, mod.db, self._refresh)
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
    local pr, pg, pb = MUI.Theme:ProfAccentColor(skillLine)
    local profLabel = MC.DecoProfLabels[skillLine] or ("Profession " .. skillLine)
    local _, collapsed, newY = MUI.RenderSourceHeader(self.panel.pool, parent, yOff, {
        label       = profLabel,
        accentColor = { pr, pg, pb },
        labelColor  = { pr * 0.85, pg * 0.85, pb * 0.85 },
        count       = #decos,
        collKey     = "prof_" .. skillLine,
        height      = 18,
        indent      = 10,
    }, mod.db, self._refresh)
    yOff = newY
    if collapsed then return yOff end
    for _, deco in ipairs(decos) do
        yOff = self:RenderDecoRow(parent, deco, yOff, false)
    end
    return yOff
end

function UI:RenderDecoRow(parent, deco, yOff, isCollected)
    -- Offscreen: bail before the opts table below is constructed. Lua builds
    -- it at the call site, so letting RenderItemRow skip saves the frame but
    -- not the garbage.
    if MUI.RowHidden(self.panel.pool, yOff, ROW_HEIGHT) then return yOff + ROW_HEIGHT end

    local theme = MUI.Theme
    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height      = ROW_HEIGHT,
        indent      = 8,
        leading     = { kind = "icon", size = ICON_SIZE,
                        texture = deco.icon,
                        fallback = "Interface\\Icons\\INV_Misc_Rune_01" },
        name        = deco.name,
        info        = deco.future and MC.GetAvailabilityBadge(deco) or deco.zone,
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
        onLeave = MC.RowOnLeave,
        onClick = function() MC.DoItemAction(deco) end,
    })
end
