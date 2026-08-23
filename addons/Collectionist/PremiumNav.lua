local _, MC = ...

local MUI = LibStub("MidnightUI-1.0")

local NAV_ROW_H = 32
-- The Options row sits apart from the trackers: a gap, and a hairline
-- across it, so it still reads as part of the same list.
local OPT_GAP    = 14
-- Clear of the container's bottom edge (which is already GAP above the
-- window's), so the row doesn't sit flush against the frame border.
local OPT_INSET  = 4
local OPT_ICON   = "Interface\\Icons\\INV_Misc_Gear_01"
local TGT_ICON   = "Interface\\Icons\\INV_Misc_Map_01"

-- Tracker pages carry no subtitle: the list under the title already
-- says what it is, and the line was pure decoration.

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

-- "pinned / cap", not "collected / total": the cap is the number that
-- matters, since reaching it evicts the oldest pin.
local function TargetCounts()
    local pins = MC.db and MC.db.targets and MC.db.targets.pins
    local n = pins and #pins or 0
    if n == 0 then return nil end
    return n, MC.TARGET_CAP or 10
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

    -- Options: one more row in the same list, pinned to the BOTTOM of the
    -- nav container rather than laid out after the last module. Modules
    -- are enabled, disabled and reordered at runtime and Reflow re-anchors
    -- every one of them; anchoring Options to the container's bottom edge
    -- keeps it where the player left it through all of that, and off
    -- Reflow's list entirely. (The travelling indicator converts the
    -- bottom anchor for itself — see lib.MakeNavIndicator.)
    local optRow = MUI.MakeNavRow(panel.navContainer, {
        icon    = OPT_ICON,
        label   = "Options",
        onClick = function() onSwitch(MC.OPTIONS_KEY) end,
        tooltip = function(_, tt)
            tt:SetText("Options")
            tt:AddLine("Modules, expansions, trackers and appearance.",
                0.7, 0.7, 0.7, true)
        end,
    })
    optRow:SetHeight(NAV_ROW_H)
    optRow:SetPoint("BOTTOMLEFT", panel.navContainer, "BOTTOMLEFT", 0, OPT_INSET)
    optRow:SetPoint("BOTTOMRIGHT", panel.navContainer, "BOTTOMRIGHT", 0, OPT_INSET)
    self.rows[MC.OPTIONS_KEY] = optRow
    self.optionsRow = optRow

    -- Targets: the working set, not a catalog. It joins Options in the
    -- bottom-anchored group (both sit below the hairline, off Reflow's
    -- list) and paints in targetAccent so the difference in kind is
    -- visible before you read the label.
    if MC.TARGETS_KEY then
        local tgtRow = MUI.MakeNavRow(panel.navContainer, {
            icon      = TGT_ICON,
            label     = "Targets",
            accentKey = "targetAccent",
            onClick   = function() onSwitch(MC.TARGETS_KEY) end,
            tooltip   = function(_, tt)
                tt:SetText("Targets")
                tt:AddLine("What you are working on right now.",
                    0.7, 0.7, 0.7, true)
                tt:AddLine("Alt-click any uncollected row to pin it.",
                    0.7, 0.7, 0.7, true)
            end,
        })
        tgtRow:SetHeight(NAV_ROW_H)
        tgtRow:SetPoint("BOTTOMLEFT", optRow, "TOPLEFT", 0, 0)
        tgtRow:SetPoint("BOTTOMRIGHT", optRow, "TOPRIGHT", 0, 0)
        self.rows[MC.TARGETS_KEY] = tgtRow
        self.targetsRow = tgtRow
    end

    -- The hairline that separates it from the trackers. Inset from both
    -- edges so it reads as a divider inside the list, not as chrome.
    local sep = panel.navContainer:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    local groupTop = self.targetsRow or optRow
    sep:SetPoint("BOTTOMLEFT", groupTop, "TOPLEFT", 12, OPT_GAP / 2)
    sep:SetPoint("BOTTOMRIGHT", groupTop, "TOPRIGHT", -12, OPT_GAP / 2)
    self.optionsSep = sep

    -- The single accent bar that travels between rows. Created last so it
    -- draws above every row at the same frame level.
    self.indicator = MUI.MakeNavIndicator(panel.navContainer)

    -- One theme hook for the whole nav; rows repaint through Reflow.
    MUI.RegisterThemeHook(function()
        if Nav.indicator then Nav.indicator:Repaint() end
        Nav:Reflow()
    end)

    self:Reflow()
end

function Nav:SetActive(key)
    if not self.rows then return end
    self.activeKey = key
    for k, row in pairs(self.rows) do
        row:SetActive(k == key)
    end
    -- Tab switch: the bar travels to the newly selected row — Options
    -- included, from either direction.
    if self.indicator then self.indicator:MoveTo(self.rows[key], false) end
    if self.panel and self.panel.SetPageHeader then
        if key == MC.OPTIONS_KEY then
            -- No expansion scope here: Options is not a filtered list.
            self.panel:SetPageHeader("Options",
                "How Collectionist tracks, and how it looks")
        elseif MC.TARGETS_KEY and key == MC.TARGETS_KEY then
            self.panel:SetPageHeader("Targets",
                "What you are working on right now")
        elseif key == MC.SEARCH_KEY then
            self.panel:SetPageHeader("Search",
                "Every collectible, by name, zone, or source")
        else
            local mod = MC.modulesByKey and MC.modulesByKey[key]
            self.panel:SetPageHeader((mod and mod.label) or key, nil)
        end
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
    -- Options keeps its own bottom anchor through every reorder; only its
    -- active state and palette need re-deriving here.
    local optRow = self.rows[MC.OPTIONS_KEY]
    if optRow then
        optRow._active = (self.activeKey == MC.OPTIONS_KEY)
        optRow:Repaint()
    end
    local tgtRow = MC.TARGETS_KEY and self.rows[MC.TARGETS_KEY]
    if tgtRow then
        tgtRow._active = (self.activeKey == MC.TARGETS_KEY)
        tgtRow._c, tgtRow._t = TargetCounts()
        tgtRow:Repaint()
    end
    if self.optionsSep then
        local dv = MUI.Theme.colors.optionsDivider
        self.optionsSep:SetColorTexture(dv[1], dv[2], dv[3], dv[4] or 0.06)
    end
    -- Reflow is a layout change (reorder, enable/disable, theme switch,
    -- window resize), not a selection change: the bar re-seats without
    -- travelling. The resize case matters for Options specifically — its
    -- row moves with the container's bottom edge.
    if self.indicator then
        self.indicator:MoveTo(self.activeKey and self.rows[self.activeKey], true)
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
    local tgtRow = MC.TARGETS_KEY and self.rows[MC.TARGETS_KEY]
    if tgtRow then tgtRow:SetCounts(TargetCounts()) end
    -- Fresh scan results move the spine's lit segments too.
    if self.panel and self.panel.UpdateSpine then self.panel:UpdateSpine() end
end
