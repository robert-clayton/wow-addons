local _, MC = ...

local MUI = LibStub("MidnightUI-1.0")
local theme = MUI.Theme

MC.TabBar = {}
local TabBar = MC.TabBar

local TAB_HEIGHT = 22
local TAB_PAD    = 2
local TAB_WIDTH  = 88

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
    bg:SetColorTexture(theme.colors.bg[1], theme.colors.bg[2], theme.colors.bg[3], 0.85)

    -- Bottom border (warm gold divider)
    local border = container:CreateTexture(nil, "ARTWORK")
    border:SetHeight(1)
    border:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    border:SetColorTexture(theme.colors.accent[1], theme.colors.accent[2],
                           theme.colors.accent[3], 0.15)

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

    -- Create tab buttons
    local xOff = TAB_PAD
    for _, mod in ipairs(modules) do
        local tab = CreateFrame("Button", nil, container)
        tab:SetSize(TAB_WIDTH, TAB_HEIGHT)
        tab:SetPoint("LEFT", container, "LEFT", xOff, 0)

        -- Active background (warm glow when selected)
        local activeBg = tab:CreateTexture(nil, "BACKGROUND")
        activeBg:SetAllPoints()
        activeBg:SetColorTexture(theme.colors.accent[1], theme.colors.accent[2],
                                 theme.colors.accent[3], 0.08)
        activeBg:Hide()
        tab._activeBg = activeBg

        -- Icon (12x12)
        local icon = tab:CreateTexture(nil, "ARTWORK")
        icon:SetSize(12, 12)
        icon:SetPoint("LEFT", tab, "LEFT", 6, 0)
        icon:SetTexture(mod.icon)
        tab._icon = icon

        -- Label
        local label = tab:CreateFontString(nil, "OVERLAY")
        label:SetFont(theme.font, theme.fontSize - 1, "OUTLINE")
        label:SetPoint("LEFT", icon, "RIGHT", 3, 0)
        label:SetText(mod.label)
        tab._label = label

        -- Active indicator (bottom 2px accent bar)
        local activeBar = tab:CreateTexture(nil, "OVERLAY")
        activeBar:SetHeight(2)
        activeBar:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
        activeBar:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
        activeBar:SetColorTexture(theme.colors.accent[1], theme.colors.accent[2],
                                  theme.colors.accent[3], 1)
        activeBar:Hide()
        tab._activeBar = activeBar

        -- Hover
        local hoverBg = tab:CreateTexture(nil, "BACKGROUND", nil, 1)
        hoverBg:SetAllPoints()
        hoverBg:SetColorTexture(1, 1, 1, 0)
        tab._hoverBg = hoverBg
        tab:SetScript("OnEnter", function()
            if not tab._isActive then
                hoverBg:SetColorTexture(1, 0.85, 0.5, 0.04)
            end
        end)
        tab:SetScript("OnLeave", function()
            hoverBg:SetColorTexture(1, 1, 1, 0)
        end)

        -- Click
        tab:SetScript("OnClick", function()
            onSwitch(mod.key)
        end)

        self.tabs[mod.key] = tab
        xOff = xOff + TAB_WIDTH + TAB_PAD
    end
end

function TabBar:Reflow()
    local xOff = TAB_PAD
    for _, mod in ipairs(MC.modules) do
        local tab = self.tabs[mod.key]
        if tab then
            if MC.IsModuleEnabled(mod.key) then
                tab:ClearAllPoints()
                tab:SetPoint("LEFT", self.container, "LEFT", xOff, 0)
                tab:Show()
                xOff = xOff + TAB_WIDTH + TAB_PAD
            else
                tab:Hide()
            end
        end
    end
end

function TabBar:SetActive(key)
    for k, tab in pairs(self.tabs) do
        if k == key then
            tab._isActive = true
            tab._activeBar:Show()
            tab._activeBg:Show()
            tab._label:SetTextColor(theme.colors.accent[1], theme.colors.accent[2],
                                    theme.colors.accent[3])
            tab._icon:SetVertexColor(theme.colors.accent[1], theme.colors.accent[2],
                                     theme.colors.accent[3])
        else
            tab._isActive = false
            tab._activeBar:Hide()
            tab._activeBg:Hide()
            tab._label:SetTextColor(theme.colors.textDim[1], theme.colors.textDim[2],
                                    theme.colors.textDim[3])
            tab._icon:SetVertexColor(0.45, 0.40, 0.30)
        end
    end
end
