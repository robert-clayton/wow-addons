local lib = LibStub:GetLibrary("MidnightUI-1.0", true)
if not lib then return end

local theme = lib.Theme

--------------------------------------------------------------------------
-- Panel prototype
--------------------------------------------------------------------------
local PanelProto = {}
PanelProto.__index = PanelProto

function lib:CreatePanel(opts)
    local panel = setmetatable({}, PanelProto)
    panel.opts = opts
    panel.db = opts.db
    panel.pool = lib.Pool:New()
    panel:Create()
    return panel
end

--------------------------------------------------------------------------
-- Create main frame
--------------------------------------------------------------------------
function PanelProto:Create()
    local opts = self.opts
    local db = self.db

    local w = db.panelWidth or opts.defaultWidth or 360
    local h = db.panelHeight or opts.defaultHeight or 520

    local f = CreateFrame("Frame", (opts.name or "MidnightUIPanel") .. "Frame", UIParent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    self.frame = f

    self:ApplyBackdrop()
    self:CreateTitleBar()
    self:CreateScrollFrame()
    self:CreateResizeDragger()

    local pos = db.position
    f:ClearAllPoints()
    f:SetPoint(pos.point or "CENTER", UIParent, pos.point or "CENTER", pos.x or 0, pos.y or 0)

    -- Apply scale
    if db.frameScale and db.frameScale ~= 1.0 then
        f:SetScale(db.frameScale)
    end

    f:Hide()

    if db.panelShown then
        f:Show()
        if opts.onRefresh then opts.onRefresh(self) end
        if db.minimized then
            self:ApplyMinimizeState()
        end
    end
end

--------------------------------------------------------------------------
-- Backdrop
--------------------------------------------------------------------------
function PanelProto:ApplyBackdrop()
    local f = self.frame
    local v = self.db.frameAlpha or 1.0
    f:SetBackdrop(theme.backdrop)
    f:SetBackdropColor(theme.colors.bg[1], theme.colors.bg[2], theme.colors.bg[3], theme.colors.bg[4] * v)
    f:SetBackdropBorderColor(theme.colors.border[1], theme.colors.border[2], theme.colors.border[3], v)
    if f.titleBar then
        f.titleBar:SetBackdropColor(theme.colors.titlebar[1], theme.colors.titlebar[2], theme.colors.titlebar[3], v)
        f.titleBar:SetBackdropBorderColor(theme.colors.titleBorder[1], theme.colors.titleBorder[2], theme.colors.titleBorder[3], math.max(v, 0.4))
    end
end

--------------------------------------------------------------------------
-- Minimize state
--------------------------------------------------------------------------
function PanelProto:ApplyMinimizeState()
    local f = self.frame
    if not f then return end
    local db = self.db
    if db.minimized then
        local left = f:GetLeft()
        local top = f:GetTop()
        if left and top then
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
            db.position = { point = "TOPLEFT", x = left, y = top }
        end
        if f.scrollFrame then f.scrollFrame:Hide() end
        if f.scrollTrack then f.scrollTrack:Hide() end
        if f.tabBar then f.tabBar:Hide() end
        if f.dragger then f.dragger:Hide() end
        f:SetHeight(24)
    else
        if f.scrollFrame then f.scrollFrame:Show() end
        if f.scrollTrack then f.scrollTrack:Show() end
        if f.tabBar then f.tabBar:Show() end
        if f.dragger and not db.locked then f.dragger:Show() end
        f:SetHeight(db.panelHeight or self.opts.defaultHeight or 520)
        if self.opts.onRefresh then self.opts.onRefresh(self) end
    end
    if self.UpdateMinimizeVisual then self.UpdateMinimizeVisual() end
end

--------------------------------------------------------------------------
-- Title bar
--------------------------------------------------------------------------
function PanelProto:CreateTitleBar()
    local f = self.frame
    local db = self.db
    local panel = self

    local bar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    bar:SetHeight(24)
    bar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    local v = db.frameAlpha or 1.0
    bar:SetBackdrop(theme.backdrop)
    bar:SetBackdropColor(theme.colors.titlebar[1], theme.colors.titlebar[2], theme.colors.titlebar[3], v)
    bar:SetBackdropBorderColor(theme.colors.titleBorder[1], theme.colors.titleBorder[2], theme.colors.titleBorder[3], math.max(v, 0.4))
    bar:EnableMouse(true)
    bar:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not db.locked then f:StartMoving() end
    end)
    bar:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            f:StopMovingOrSizing()
            local point, _, _, x, y = f:GetPoint()
            db.position = { point = point, x = x, y = y }
        end
    end)

    -- Gold crown bar (2px accent at the very top edge)
    local crown = bar:CreateTexture(nil, "OVERLAY")
    crown:SetHeight(2)
    crown:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, -1)
    crown:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -1, -1)
    crown:SetColorTexture(theme.colors.accent[1], theme.colors.accent[2], theme.colors.accent[3], 0.70)

    -- Icon
    if self.opts.icon then
        local profIcon = bar:CreateTexture(nil, "ARTWORK")
        profIcon:SetSize(14, 14)
        profIcon:SetPoint("LEFT", bar, "LEFT", 8, 0)
        profIcon:SetTexture(self.opts.icon)
        profIcon:SetVertexColor(theme.colors.accent[1], theme.colors.accent[2], theme.colors.accent[3])

        local title = bar:CreateFontString(nil, "OVERLAY")
        title:SetFont(theme.font, theme.fontSize, "OUTLINE")
        title:SetPoint("LEFT", profIcon, "RIGHT", 5, 0)
        title:SetText(self.opts.title or "")
        title:SetTextColor(unpack(theme.colors.title))
    else
        local title = bar:CreateFontString(nil, "OVERLAY")
        title:SetFont(theme.font, theme.fontSize, "OUTLINE")
        title:SetPoint("LEFT", bar, "LEFT", 8, 0)
        title:SetText(self.opts.title or "")
        title:SetTextColor(unpack(theme.colors.title))
    end

    -- Progress counter (warm dim gold)
    local progressText = bar:CreateFontString(nil, "OVERLAY")
    progressText:SetFont(theme.font, theme.fontSize - 1, "OUTLINE")
    progressText:SetTextColor(0.60, 0.50, 0.30)
    self.titleProgressText = progressText

    -- Close button
    local closeBtn = lib.MakeHeaderBtn(bar, "x",
        theme.colors.btnCloseFg,
        theme.colors.btnCloseHoverBg,
        theme.colors.btnCloseHoverBd,
        "Close")
    closeBtn:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    closeBtn:SetScript("OnClick", function() panel:Hide() end)

    -- Minimize button
    local minBtn = lib.MakeHeaderBtn(bar, "-",
        theme.colors.btnTealFg,
        theme.colors.btnTealHoverBg,
        theme.colors.btnTealHoverBd,
        "Minimize")
    minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -3, 0)
    self.UpdateMinimizeVisual = function()
        minBtn._label:SetText(db.minimized and "+" or "-")
    end
    self.UpdateMinimizeVisual()
    minBtn:SetScript("OnClick", function()
        db.minimized = not db.minimized
        panel:ApplyMinimizeState()
    end)

    -- Options button (gear icon)
    local cfgBtn = lib.MakeHeaderIconBtn(bar,
        "Interface\\Buttons\\UI-OptionsButton", 14,
        theme.colors.btnTealFg,
        theme.colors.btnTealHoverBg,
        theme.colors.btnTealHoverBd,
        "Options")
    cfgBtn:SetPoint("RIGHT", minBtn, "LEFT", -3, 0)
    cfgBtn:SetScript("OnClick", function()
        panel:ToggleConfig()
    end)

    -- Position progress text between title and buttons
    progressText:SetPoint("RIGHT", cfgBtn, "LEFT", -8, 0)

    f.titleBar = bar
end

--------------------------------------------------------------------------
-- Scroll frame
--------------------------------------------------------------------------
function PanelProto:CreateScrollFrame()
    local f = self.frame
    local db = self.db

    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:SetPoint("TOPLEFT", f.titleBar, "BOTTOMLEFT", 0, -1)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -9, 4)
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth((db.panelWidth or self.opts.defaultWidth or 360) - 9)
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    local track = scroll:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(5)
    track:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -26)
    track:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 4)
    local tc = theme.colors.scrollTrack
    track:SetColorTexture(tc[1], tc[2], tc[3], tc[4])

    local thumb = scroll:CreateTexture(nil, "ARTWORK")
    thumb:SetWidth(5)
    local stc = theme.colors.scrollThumb
    thumb:SetColorTexture(stc[1], stc[2], stc[3], stc[4])
    thumb:Hide()

    local function UpdateScrollBar()
        local viewH = scroll:GetHeight()
        local contentH = content:GetHeight()
        if contentH <= viewH or viewH <= 0 then thumb:Hide(); return end
        thumb:Show()
        local trackH = math.max(track:GetHeight(), 1)
        local thumbH = math.max(trackH * (viewH / contentH), 14)
        local pct = math.max(0, math.min(scroll:GetVerticalScroll() / (contentH - viewH), 1))
        thumb:SetHeight(thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, -((trackH - thumbH) * pct))
    end

    scroll:SetScript("OnMouseWheel", function(_, delta)
        local cur = scroll:GetVerticalScroll()
        local maxScroll = math.max(content:GetHeight() - scroll:GetHeight(), 0)
        scroll:SetVerticalScroll(math.max(0, math.min(cur - delta * 30, maxScroll)))
        UpdateScrollBar()
    end)
    scroll:SetScript("OnScrollRangeChanged", function() UpdateScrollBar() end)
    scroll:SetScript("OnVerticalScroll", function() UpdateScrollBar() end)

    f.scrollFrame = scroll
    f.scrollChild = content
    f.scrollTrack = track
    self.scrollFrame = scroll
    self.scrollChild = content
end

--------------------------------------------------------------------------
-- Resize dragger
--------------------------------------------------------------------------
function PanelProto:CreateResizeDragger()
    local f = self.frame
    local db = self.db
    local panel = self
    local minW = self.opts.minWidth or 240
    local maxW = self.opts.maxWidth or 600
    local minH = self.opts.minHeight or 120
    local maxH = self.opts.maxHeight or 900

    local dragger = CreateFrame("Frame", nil, f)
    dragger:SetSize(12, 12)
    dragger:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    dragger:SetFrameLevel(f:GetFrameLevel() + 10)
    dragger:EnableMouse(true)

    local dTex = dragger:CreateTexture(nil, "OVERLAY")
    dTex:SetAllPoints()
    dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    dragger:SetScript("OnEnter", function()
        if not db.locked then
            dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        end
    end)
    dragger:SetScript("OnLeave", function()
        dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)

    local dragStartW, dragStartH, dragStartX, dragStartY

    -- OnUpdate is bound only during an active drag (cleared on MouseUp)
    -- so an idle dragger doesn't burn a per-frame callback.
    local function onDragUpdate()
        local cx, cy = GetCursorPosition()
        local scale = f:GetEffectiveScale()
        cx = cx / scale
        cy = cy / scale
        local dx = cx - dragStartX
        local dy = dragStartY - cy
        local newW = math.max(minW, math.min(maxW, dragStartW + dx))
        local newH = math.max(minH, math.min(maxH, dragStartH + dy))
        f:SetWidth(newW)
        f:SetHeight(newH)
    end

    dragger:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not db.locked then
            local left = f:GetLeft()
            local top = f:GetTop()
            if left and top then
                f:ClearAllPoints()
                f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
            end
            dragStartW = f:GetWidth()
            dragStartH = f:GetHeight()
            dragStartX, dragStartY = GetCursorPosition()
            local scale = f:GetEffectiveScale()
            dragStartX = dragStartX / scale
            dragStartY = dragStartY / scale
            dragger._dragging = true
            dragger:SetScript("OnUpdate", onDragUpdate)
        end
    end)
    dragger:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and dragger._dragging then
            dragger._dragging = false
            dragger:SetScript("OnUpdate", nil)
            local newW = math.max(minW, math.min(maxW, math.floor(f:GetWidth())))
            local newH = math.max(minH, math.min(maxH, math.floor(f:GetHeight())))
            db.panelWidth = newW
            db.panelHeight = newH
            f:SetWidth(newW)
            f:SetHeight(newH)
            local point, _, _, x, y = f:GetPoint()
            db.position = { point = point, x = x, y = y }
            if f.scrollChild then
                f.scrollChild:SetWidth(newW - 9)
            end
            if panel.opts.onRefresh then panel.opts.onRefresh(panel) end
        end
    end)

    if db.locked or db.minimized then dragger:Hide() end
    f.dragger = dragger
end

function PanelProto:UpdateDraggerVisibility()
    if not self.frame or not self.frame.dragger then return end
    if self.db.locked or self.db.minimized then
        self.frame.dragger:Hide()
    else
        self.frame.dragger:Show()
    end
end

--------------------------------------------------------------------------
-- Show / Hide / Toggle
--------------------------------------------------------------------------
function PanelProto:Show()
    self.frame:Show()
    self.db.panelShown = true
    if self.opts.onRefresh then self.opts.onRefresh(self) end
    if self.db.minimized then
        self:ApplyMinimizeState()
    end
end

function PanelProto:Hide()
    self.frame:Hide()
    self.db.panelShown = false
    if self.cfgFrame then self.cfgFrame:Hide() end
    if self.opts.onHide then self.opts.onHide(self) end
end

function PanelProto:Toggle()
    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

--------------------------------------------------------------------------
-- Config frame
--------------------------------------------------------------------------
function PanelProto:BuildConfigFrame()
    local panel = self
    local f = CreateFrame("Frame", (self.opts.name or "MidnightUIPanel") .. "ConfigFrame", UIParent, "BackdropTemplate")
    f:SetWidth(220)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop(theme.backdrop)
    local obc = theme.colors.optionsBg
    f:SetBackdropColor(obc[1], obc[2], obc[3], obc[4])
    f:SetBackdropBorderColor(theme.colors.titleBorder[1], theme.colors.titleBorder[2], theme.colors.titleBorder[3], 1)
    f:Hide()

    if self.frame then
        f:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 4, 0)
    else
        f:SetPoint("CENTER")
    end

    -- Title bar
    local bar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    bar:SetHeight(24)
    bar:SetPoint("TOPLEFT"); bar:SetPoint("TOPRIGHT")
    bar:SetBackdrop(theme.backdrop)
    bar:SetBackdropColor(unpack(theme.colors.titlebar))
    bar:SetBackdropBorderColor(unpack(theme.colors.titleBorder))
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() f:StartMoving() end)
    bar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    -- Gold crown bar (matching main panel)
    local crownCfg = bar:CreateTexture(nil, "OVERLAY")
    crownCfg:SetHeight(2)
    crownCfg:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, -1)
    crownCfg:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -1, -1)
    crownCfg:SetColorTexture(theme.colors.accent[1], theme.colors.accent[2], theme.colors.accent[3], 0.70)

    -- Left accent bar
    local acc = bar:CreateTexture(nil, "ARTWORK")
    acc:SetPoint("TOPLEFT"); acc:SetPoint("BOTTOMLEFT")
    acc:SetWidth(3)
    acc:SetColorTexture(unpack(theme.colors.accent))

    -- Title
    local ttl = bar:CreateFontString(nil, "OVERLAY")
    ttl:SetFont(theme.font, theme.fontSize, "OUTLINE")
    ttl:SetPoint("LEFT", 8, 0)
    ttl:SetText("Options")
    ttl:SetTextColor(unpack(theme.colors.title))

    -- Close
    local cls = lib.MakeHeaderBtn(bar, "x",
        theme.colors.btnCloseFg,
        theme.colors.btnCloseHoverBg,
        theme.colors.btnCloseHoverBd,
        "Close")
    cls:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    cls:SetScript("OnClick", function() f:Hide() end)

    -- Body
    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
    body:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
    f.body = body

    return f
end

function PanelProto:ToggleConfig()
    if self.cfgFrame and self.cfgFrame:IsShown() then
        self.cfgFrame:Hide()
        return
    end
    if not self.cfgFrame then
        self.cfgFrame = self:BuildConfigFrame()
    end
    -- Re-dock to main frame
    if self.frame then
        self.cfgFrame:ClearAllPoints()
        self.cfgFrame:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 4, 0)
    end
    if self.pendingConfigDefs then
        self:_PopulateConfigBody(self.pendingConfigDefs)
    end
    self.cfgFrame:Show()
end

function PanelProto:PopulateConfig(defs)
    self.pendingConfigDefs = defs
end

function PanelProto:_PopulateConfigBody(defs)
    if lib._populateConfigBody then
        lib._populateConfigBody(self, defs)
    end
end

--------------------------------------------------------------------------
-- Scroll content helpers
--------------------------------------------------------------------------
function PanelProto:RefreshScrollContent(height)
    if self.scrollChild then
        self.scrollChild:SetHeight(math.max(height, 1))
    end
    -- Re-apply minimize state after refresh
    if self.db.minimized then
        local f = self.frame
        if f.scrollFrame then f.scrollFrame:Hide() end
        if f.scrollTrack then f.scrollTrack:Hide() end
        if f.tabBar then f.tabBar:Hide() end
        if f.dragger then f.dragger:Hide() end
        f:SetHeight(24)
        if self.UpdateMinimizeVisual then self.UpdateMinimizeVisual() end
    end
end

--------------------------------------------------------------------------
-- RenderHeader convenience wrapper
--------------------------------------------------------------------------
function PanelProto:RenderHeader(parent, yOff, opts)
    return lib.RenderCollapsibleHeader(self.pool, parent, yOff, opts, self.db, function()
        if self.opts.onRefresh then self.opts.onRefresh(self) end
    end)
end
