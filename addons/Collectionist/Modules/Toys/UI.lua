local _, MC = ...

local mod = MC.modulesByKey["toys"]
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
        { type = "checkbox", label = "Hide unavailable toys",
            get = function() return db.hideUnavailable ~= false end,
            set = function(v)
                db.hideUnavailable = v
                if mod.Scanner then MC.ScanNow(mod) end
                MC.RefreshActive()
            end },
        { type = "checkbox", label = "Hide Trading Post Toys",
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
        sourceOrder   = MC.ToySourceOrder,
        renderSourceGroup = function(p, s, e, y) return self:RenderSourceGroup(p, s, e, y) end,
        renderRow     = function(p, t, y, c) return self:RenderToyRow(p, t, y, c) end,
        showCollected = mod.db.showCollected,
        db            = mod.db,
        refreshCb     = self._refresh,
        emptyMessages = {
            allDone  = "All Midnight toys collected!",
            noneLeft = "No uncollected Midnight toys found.",
        },
    })
end

function UI:RenderSourceGroup(parent, srcType, entries, yOff)
    local sr, sg, sb = MUI.Theme:SourceColor(srcType)
    local _, collapsed, newY = MUI.RenderSourceHeader(self.panel.pool, parent, yOff, {
        label       = MC.ToySourceLabels[srcType] or srcType,
        accentColor = { sr, sg, sb },
        count       = #entries,
        collKey     = "src_" .. srcType,
    }, mod.db, self._refresh)
    yOff = newY
    if collapsed then return yOff end
    for _, toy in ipairs(entries) do
        yOff = self:RenderToyRow(parent, toy, yOff, false)
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
        info        = toy.future and MC.GetAvailabilityBadge(toy) or toy.zone,
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
        onLeave = MC.RowOnLeave,
        onClick = function() MC.DoItemAction(toy) end,
    })
end
