local _, MC = ...

local MUI = LibStub("MidnightUI-1.0")
local theme = MUI.Theme

MC.TabBar = {}
local TabBar = MC.TabBar

local TAB_HEIGHT  = 22
local TAB_PAD     = 2
local TAB_MAX     = 88   -- maximum width per tab when there's room
local TAB_MIN     = 32   -- below this we drop labels and show icon-only
local ICON_SIZE   = 12
local LABEL_INSET = 6  + ICON_SIZE + 3  -- left padding + icon + spacing before label

function TabBar:Create(panel, modules, onSwitch)
    self.panel = panel
    self.onSwitch = onSwitch
    self.tabs = {}

    -- Container frame between titlebar and scroll area
    local container = CreateFrame("Frame", nil, panel.frame)
    container:SetHeight(TAB_HEIGHT)
    container:SetPoint("TOPLEFT", panel.frame.titleBar, "BOTTOMLEFT", 0, -1)
    container:SetPoint("TOPRIGHT", panel.frame.titleBar, "BOTTOMRIGHT", 0, -1)
    self.container = container
    panel.frame.tabBar = container

    -- Background
    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()

    -- Bottom border (warm gold divider)
    local border = container:CreateTexture(nil, "ARTWORK")
    border:SetHeight(1)
    border:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)

    local function applyContainerTheme()
        local th = MUI.Theme
        bg:SetColorTexture(th.colors.bg[1], th.colors.bg[2], th.colors.bg[3], 0.85)
        border:SetColorTexture(th.colors.accent[1], th.colors.accent[2],
                               th.colors.accent[3], 0.15)
    end
    applyContainerTheme()
    MUI.RegisterThemeHook(applyContainerTheme)

    -- Re-anchor scroll frame below tab bar
    if panel.frame.scrollFrame then
        panel.frame.scrollFrame:ClearAllPoints()
        panel.frame.scrollFrame:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, -1)
        panel.frame.scrollFrame:SetPoint("BOTTOMRIGHT", panel.frame, "BOTTOMRIGHT", -9, 4)
    end

    -- Re-anchor scroll track to account for tab bar height
    if panel.frame.scrollTrack then
        panel.frame.scrollTrack:ClearAllPoints()
        local titleH = panel.frame.titleBar and panel.frame.titleBar:GetHeight() or 24
        panel.frame.scrollTrack:SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", -3, -(titleH + 2 + TAB_HEIGHT + 2))
        panel.frame.scrollTrack:SetPoint("BOTTOMRIGHT", panel.frame, "BOTTOMRIGHT", -3, 4)
    end

    -- Create tab buttons (sized in :Reflow which runs after this)
    for _, mod in ipairs(modules) do
        local tab = CreateFrame("Button", nil, container)
        tab:SetHeight(TAB_HEIGHT)

        -- Active background (warm glow when selected). White base so
        -- the theme gradient (applyTabsTheme) has content to modulate —
        -- SetGradient alone renders nothing on an empty texture.
        local activeBg = tab:CreateTexture(nil, "BACKGROUND")
        activeBg:SetColorTexture(1, 1, 1, 1)
        activeBg:SetAllPoints()
        activeBg:Hide()
        tab._activeBg = activeBg

        -- Icon
        local icon = tab:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetTexture(mod.icon)
        tab._icon = icon

        -- Label. Font is set here (and again by applyTabsTheme on theme
        -- switch) — SetText requires a font to already be assigned.
        local label = tab:CreateFontString(nil, "OVERLAY")
        label:SetFont(theme.font, theme.fontSize - 1, "OUTLINE")
        label:SetWordWrap(false)
        label:SetText(mod.label)
        tab._label = label
        tab._labelText = mod.label

        -- Active indicator (bottom 2px accent bar)
        local activeBar = tab:CreateTexture(nil, "OVERLAY")
        activeBar:SetHeight(2)
        activeBar:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
        activeBar:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
        activeBar:Hide()
        tab._activeBar = activeBar

        -- Hover
        local hoverBg = tab:CreateTexture(nil, "BACKGROUND", nil, 1)
        hoverBg:SetAllPoints()
        hoverBg:SetColorTexture(1, 1, 1, 0)
        tab._hoverBg = hoverBg
        tab:SetScript("OnEnter", function(self)
            if not self._isActive then
                local ac = MUI.Theme.colors.accent
                hoverBg:SetColorTexture(ac[1], ac[2], ac[3], 0.06)
            end
            -- When in icon-only mode, show the label as a tooltip
            if self._iconOnly then
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                GameTooltip:SetText(self._labelText)
                GameTooltip:Show()
            end
        end)
        tab:SetScript("OnLeave", function(self)
            hoverBg:SetColorTexture(1, 1, 1, 0)
            GameTooltip:Hide()
        end)

        -- Click
        tab:SetScript("OnClick", function()
            onSwitch(mod.key)
        end)

        self.tabs[mod.key] = tab
    end

    -- Per-tab theme refresh on live palette change. Handles both
    -- active and inactive states (driven by tab._isActive) so the
    -- currently-selected tab doesn't briefly de-highlight when the
    -- user switches themes.
    local function applyTabsTheme()
        local th = MUI.Theme
        local ac = th.colors.accent
        for _, tab in pairs(self.tabs) do
            -- Active background: vertical gradient (modern) vs flat
            -- accent tint (simple).
            if th.tabActiveGradient then
                MUI.SetGradient(tab._activeBg, "VERTICAL",
                    { ac[1], ac[2], ac[3], 0.02 },
                    { ac[1], ac[2], ac[3], 0.18 })
            else
                -- Flat via the same gradient API: retail SetGradient
                -- state persists on the texture, so a plain
                -- SetColorTexture here would leave the modern theme's
                -- fade ghosting through after a live theme switch.
                MUI.SetGradient(tab._activeBg, "VERTICAL",
                    { ac[1], ac[2], ac[3], 0.08 },
                    { ac[1], ac[2], ac[3], 0.08 })
            end
            tab._activeBar:SetColorTexture(ac[1], ac[2], ac[3], 1)
            tab._label:SetFont(th.font, th.fontSize - 1, "OUTLINE")
            if not tab._isActive then
                tab._label:SetTextColor(th.colors.textDim[1], th.colors.textDim[2],
                                        th.colors.textDim[3])
                tab._icon:SetVertexColor(th.colors.textDim[1] + 0.05, th.colors.textDim[2] + 0.04, th.colors.textDim[3] + 0.02)
            else
                tab._label:SetTextColor(ac[1], ac[2], ac[3])
                tab._icon:SetVertexColor(ac[1], ac[2], ac[3])
            end
        end
    end
    applyTabsTheme()
    MUI.RegisterThemeHook(applyTabsTheme)

    -- Reflow whenever the container resizes (panel drag-resize)
    container:SetScript("OnSizeChanged", function() self:Reflow() end)

    self:Reflow()
end

-- Size enabled tabs to fill the container. Below a threshold the labels
-- get dropped and tabs become icon-only with a hover tooltip.
function TabBar:Reflow()
    if not self.container then return end
    local containerW = self.container:GetWidth()
    if not containerW or containerW <= 0 then return end

    -- Count enabled modules
    local enabled = {}
    for _, mod in ipairs(MC.modules) do
        if MC.IsModuleEnabled(mod.key) then
            enabled[#enabled + 1] = mod
        end
    end
    local n = #enabled
    if n == 0 then
        for _, tab in pairs(self.tabs) do tab:Hide() end
        return
    end

    -- Compute per-tab width: shrink uniformly to fit, capped at TAB_MAX
    local totalPad = TAB_PAD * (n + 1)
    local perTab = math.floor((containerW - totalPad) / n)
    if perTab > TAB_MAX then perTab = TAB_MAX end
    if perTab < 16 then perTab = 16 end

    -- Below this width the label can't fit next to the icon — switch to icon-only
    local iconOnly = perTab < (LABEL_INSET + 30)

    local xOff = TAB_PAD
    for _, mod in ipairs(MC.modules) do
        local tab = self.tabs[mod.key]
        if tab then
            if MC.IsModuleEnabled(mod.key) then
                tab:SetWidth(perTab)
                tab:ClearAllPoints()
                tab:SetPoint("LEFT", self.container, "LEFT", xOff, 0)

                -- Re-anchor icon + label based on mode
                tab._icon:ClearAllPoints()
                tab._label:ClearAllPoints()
                if iconOnly then
                    tab._icon:SetPoint("CENTER", tab, "CENTER", 0, 0)
                    tab._label:Hide()
                    tab._iconOnly = true
                else
                    tab._icon:SetPoint("LEFT", tab, "LEFT", 6, 0)
                    tab._label:SetPoint("LEFT", tab._icon, "RIGHT", 3, 0)
                    tab._label:SetPoint("RIGHT", tab, "RIGHT", -4, 0)
                    tab._label:SetJustifyH("LEFT")
                    tab._label:Show()
                    tab._iconOnly = false
                end

                tab:Show()
                xOff = xOff + perTab + TAB_PAD
            else
                tab:Hide()
            end
        end
    end
end

function TabBar:SetActive(key)
    local th = MUI.Theme
    for k, tab in pairs(self.tabs) do
        if k == key then
            tab._isActive = true
            tab._activeBar:Show()
            tab._activeBg:Show()
            tab._label:SetTextColor(th.colors.accent[1], th.colors.accent[2],
                                    th.colors.accent[3])
            tab._icon:SetVertexColor(th.colors.accent[1], th.colors.accent[2],
                                     th.colors.accent[3])
        else
            tab._isActive = false
            tab._activeBar:Hide()
            tab._activeBg:Hide()
            tab._label:SetTextColor(th.colors.textDim[1], th.colors.textDim[2],
                                    th.colors.textDim[3])
            tab._icon:SetVertexColor(th.colors.textDim[1] + 0.05, th.colors.textDim[2] + 0.04, th.colors.textDim[3] + 0.02)
        end
    end
end
