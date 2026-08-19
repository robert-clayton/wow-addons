local _, MC = ...

local MUI = LibStub("MidnightUI-1.0")

local NAV_ROW_H = 32

-- Per-module taglines for the Premium page header subtitle.
-- No tagline repeats its module's name — the page title directly above
-- already says it.
local TAGLINES = {
    mounts       = "Still out there to hunt down",
    pets         = "Waiting to be caught",
    decorations  = "Missing from your housing stock",
    toys         = "Not in your toybox yet",
    recipes      = "Your professions haven't learned these",
    rares        = "Still on the hit list",
    treasures    = "Left to uncover",
    achievements = "Within reach",
}

-- Canonical counts derivation, mirroring Roster's BuildLocalCounts
-- (Modules/Roster/Init.lua): recipes sum per-skill-line sub-tables;
-- everything else prefers the account-wide totals. Returns
-- collected, total — or nil when the module has no results yet.
local function ModuleCounts(mod)
    local r = mod.Scanner and mod.Scanner.results
    if not r then return nil end
    if mod.key == "recipes" then
        local c, t = 0, 0
        for _, sub in pairs(r) do
            if type(sub) == "table" and sub.total then
                c = c + (sub.learnedCount or 0)
                t = t + sub.total
            end
        end
        if t > 0 then return c, t end
        return nil
    end
    local total = r.totalAll or r.total
    if not total or total == 0 then return nil end
    return (r.collectedCountAll or r.collectedCount or 0), total
end

--------------------------------------------------------------------------
-- PremiumNav duck-types MC.TabBar's Create/SetActive/Reflow surface —
-- Core calls all three through MC.TabBar once the premium constructor
-- branch swaps it in. Create builds MakeNavRows into panel.navContainer
-- and must NOT touch panel.frame.scrollFrame (that re-anchor surgery in
-- TabBar.lua is classic-only).
--------------------------------------------------------------------------
MC.PremiumNav = {}
local Nav = MC.PremiumNav

function Nav:Create(panel, modules, onSwitch)
    self.panel = panel
    self.onSwitch = onSwitch
    self.rows = {}

    for _, mod in ipairs(modules) do
        local key = mod.key
        local modRef = mod
        local row = MUI.MakeNavRow(panel.navContainer, {
            icon  = mod.icon,
            label = mod.label,
            onClick = function()
                -- Disabled modules ignore left-click (the tooltip says
                -- how to re-enable).
                if MC.IsModuleEnabled(key) then
                    onSwitch(key)
                end
            end,
            onRightClick = function()
                -- Runtime-dynamic already — no reload. SetModuleEnabled
                -- calls MC.TabBar:Reflow(), which re-derives row states.
                MC.SetModuleEnabled(key, not MC.IsModuleEnabled(key))
            end,
            tooltip = function(_, tt)
                tt:SetText(modRef.label)
                local c, t = ModuleCounts(modRef)
                if c then
                    tt:AddLine(format("%d / %d collected", c, t), 0.9, 0.9, 0.9)
                end
                if MC.IsModuleEnabled(key) then
                    tt:AddLine("Right-click to enable/disable", 0.7, 0.7, 0.7)
                else
                    tt:AddLine("Module disabled — right-click to enable", 0.7, 0.7, 0.7)
                end
            end,
        })
        row:SetHeight(NAV_ROW_H)
        self.rows[key] = row
    end

    -- One theme hook for the whole nav; rows repaint through Reflow.
    MUI.RegisterThemeHook(function() Nav:Reflow() end)

    self:Reflow()
end

function Nav:SetActive(key)
    if not self.rows then return end
    self.activeKey = key
    for k, row in pairs(self.rows) do
        row:SetActive(k == key)
    end
    if self.panel and self.panel.SetPageHeader then
        local mod = MC.modulesByKey and MC.modulesByKey[key]
        local tagline = TAGLINES[key] or (mod and mod.label) or ""
        local scope = MC.GetExpansionFilterLabel and MC.GetExpansionFilterLabel()
        local subtitle = (scope and scope ~= "") and (tagline .. "  \194\183  " .. scope) or tagline
        self.panel:SetPageHeader((mod and mod.label) or key, subtitle)
    end
end

-- Re-anchors rows in the CURRENT MC.modules order — module reorder
-- (options up/down arrows) notifies solely through this method — and
-- re-derives enabled/count/active state per row. Rows past the
-- container bottom clip (accepted).
function Nav:Reflow()
    if not self.rows or not self.panel then return end
    local container = self.panel.navContainer
    if not container then return end
    local y = 0
    for _, mod in ipairs(MC.modules) do
        local row = self.rows[mod.key]
        if row then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -y)
            row:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -y)
            y = y + NAV_ROW_H
            row._enabled = MC.IsModuleEnabled(mod.key)
            row._active = (mod.key == self.activeKey)
            row._c, row._t = ModuleCounts(mod)
            row:Repaint()
        end
    end
end

-- Fired from MC.OnScanComplete after every module scan. PremiumNav
-- loads in the classic style too, where Create never ran — early-return
-- when rows are nil.
function Nav:RefreshCounts()
    if not self.rows then return end
    for _, mod in ipairs(MC.modules) do
        local row = self.rows[mod.key]
        if row then
            row:SetCounts(ModuleCounts(mod))
        end
    end
    -- Fresh scan results move the spine's lit segments too.
    if self.panel and self.panel.UpdateSpine then self.panel:UpdateSpine() end
end
