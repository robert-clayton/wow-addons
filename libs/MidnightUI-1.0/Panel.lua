local lib = LibStub:GetLibrary("MidnightUI-1.0", true)
if not lib then return end

local theme = lib.Theme

-- Panel prototype
local PanelProto = {}
PanelProto.__index = PanelProto

-- Saved sizes can predate a raised minimum (or lowered maximum); bring
-- them back inside the configured envelope. Defaults match the resize
-- dragger's.
local function ClampPanelSize(opts, w, h)
    w = math.max(opts.minWidth or 240, math.min(opts.maxWidth or 600, w))
    h = math.max(opts.minHeight or 120, math.min(opts.maxHeight or 900, h))
    return w, h
end

function lib:CreatePanel(opts)
    local panel = setmetatable({}, PanelProto)
    panel.opts = opts
    panel.db = opts.db
    panel.pool = lib.Pool:New()
    panel:Create()
    return panel
end

-- Create main frame
function PanelProto:Create()
    local opts = self.opts
    local db = self.db

    local w = db.panelWidth or opts.defaultWidth or 360
    local h = db.panelHeight or opts.defaultHeight or 520
    w, h = ClampPanelSize(opts, w, h)
    -- Write back so every later read of the saved size (un-minimize,
    -- scroll content width) sees the clamped value. Only when a value was
    -- saved: an untouched nil keeps tracking future default changes.
    if db.panelWidth then db.panelWidth = w end
    if db.panelHeight then db.panelHeight = h end

    local f = CreateFrame("Frame", (opts.name or "MidnightUIPanel") .. "Frame", UIParent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    self.frame = f

    self:CreateTitleBar()
    self:CreateScrollFrame()
    self:CreateResizeDragger()
    self:ApplyBackdrop()
    -- Re-skin on live theme switch.
    lib.RegisterThemeHook(function() self:ApplyBackdrop() end)

    local pos = db.position
    f:ClearAllPoints()
    -- relativePoint defaults to point for backwards compat with old saves
    -- that didn't store it (CENTER->CENTER and TOPLEFT->TOPLEFT both work).
    local relPoint = pos.relativePoint or pos.point or "CENTER"
    f:SetPoint(pos.point or "CENTER", UIParent, relPoint, pos.x or 0, pos.y or 0)

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

-- Backdrop. Delegates to the lib's skin protocol so theme decorations
-- (top stripe, gradient, etc.) get applied consistently.
function PanelProto:ApplyBackdrop()
    local f = self.frame
    local v = self.db.frameAlpha or 1.0
    lib.ApplyThemedBackdrop(f, { kind = "panel", alpha = v, borderAlpha = v })

    -- Modern theme's NineSlice corners sit at the panel's TOPLEFT/etc.
    -- and would occlude title-bar text + the first/last row. Re-anchor
    -- the title bar inside the corner inset, and shrink the scroll
    -- area's bottom and right edges by the same amount. Simple theme's
    -- inset is 0, so anchors stay at the panel's edges.
    local inset = lib.GetBorderInset()
    if f.titleBar then
        f.titleBar:ClearAllPoints()
        f.titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", inset, -inset)
        f.titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -inset, -inset)
        lib.ApplyThemedBackdrop(f.titleBar, { kind = "titlebar", alpha = v })
    end
    if f.scrollFrame then
        local bottom = 4 + inset
        local right = 9 + inset
        f.scrollFrame:ClearAllPoints()
        if f.tabBar then
            f.scrollFrame:SetPoint("TOPLEFT", f.tabBar, "BOTTOMLEFT", 0, -1)
        else
            f.scrollFrame:SetPoint("TOPLEFT", f.titleBar, "BOTTOMLEFT", 0, -1)
        end
        f.scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -right, bottom)
    end
    if f.scrollTrack then
        f.scrollTrack:ClearAllPoints()
        local titleH = (f.titleBar and f.titleBar:GetHeight()) or 24
        local topOfsY = -(inset + titleH + 2 + ((f.tabBar and f.tabBar:GetHeight() + 2) or 0))
        f.scrollTrack:SetPoint("TOPRIGHT", f, "TOPRIGHT", -(3 + inset), topOfsY)
        f.scrollTrack:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(3 + inset), 4 + inset)
    end
    if f.dragger then
        f.dragger:ClearAllPoints()
        f.dragger:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(1 + inset), 1 + inset)
    end
    -- Refresh title text fonts + colors (snapshot at creation). SetFont
    -- with unchanged values is a no-op, so themes sharing the default
    -- font render exactly as before; themes with their own font/outline
    -- re-skin live.
    if f.titleBar and f.titleBar._titleFontStrings then
        local title = lib.Theme.colors.title
        for _, fs in ipairs(f.titleBar._titleFontStrings) do
            fs:SetFont(lib.Theme.font, lib.Theme.fontSize, lib.FontFlags())
            fs:SetTextColor(title[1], title[2], title[3], title[4] or 1)
        end
    end
    if self.titleProgressText then
        self.titleProgressText:SetFont(lib.Theme.font, lib.Theme.fontSize - 1, lib.FontFlags())
        -- Themes may pin the counter color via colors.titleCounter;
        -- absent, keep the legacy warm derivation off textDim.
        local pc = lib.Theme.colors.titleCounter
        if pc then
            self.titleProgressText:SetTextColor(pc[1], pc[2], pc[3])
        else
            local td = lib.Theme.colors.textDim
            self.titleProgressText:SetTextColor(td[1] + 0.20, td[2] + 0.14, td[3] + 0.02)
        end
    end
    -- Refresh icon vertex color (uses accent).
    if f.titleBar and f.titleBar._titleIcon then
        local ac = lib.Theme.colors.accent
        f.titleBar._titleIcon:SetVertexColor(ac[1], ac[2], ac[3])
    end
end

-- Minimize state
function PanelProto:ApplyMinimizeState()
    local f = self.frame
    if not f then return end
    -- Resizing/anchoring during combat can taint UIParent. Queue and apply
    -- the moment combat ends.
    if InCombatLockdown() then
        if not self._minimizeQueued then
            self._minimizeQueued = true
            local watcher = CreateFrame("Frame")
            watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
            watcher:SetScript("OnEvent", function(w)
                w:UnregisterAllEvents()
                self._minimizeQueued = false
                self:ApplyMinimizeState()
            end)
        end
        return
    end
    local db = self.db
    if db.minimized then
        local left = f:GetLeft()
        local top = f:GetTop()
        if left and top then
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
            db.position = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = left, y = top }
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

-- Title bar
function PanelProto:CreateTitleBar()
    local f = self.frame
    local db = self.db
    local panel = self

    local bar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    bar:SetHeight(24)
    bar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    -- Backdrop colors + decoration applied by ApplyBackdrop at the
    -- end of :Create() (and again on every theme switch).
    bar:EnableMouse(true)
    -- Drag tracking: a release that follows real cursor movement should not
    -- count as a click for the manual double-click detector below, otherwise
    -- a quick drag-and-release toggles minimize unintentionally.
    local downX, downY, didDrag
    bar:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            downX, downY = GetCursorPosition()
            didDrag = false
            if not db.locked then f:StartMoving() end
        end
    end)
    -- Manual double-click detection. WoW's `Frame` doesn't expose
    -- OnDoubleClick (only `Button` does), so we time successive clicks.
    local lastClick = 0
    bar:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            f:StopMovingOrSizing()
            if downX and downY then
                local cx, cy = GetCursorPosition()
                local dx, dy = (cx or downX) - downX, (cy or downY) - downY
                if (dx * dx + dy * dy) > 16 then didDrag = true end
            end
            -- Only persist the position if the user actually dragged. A static
            -- click can otherwise clobber relativePoint with whatever the frame
            -- happens to be anchored to right now.
            if didDrag and not db.locked then
                local point, _, relativePoint, x, y = f:GetPoint()
                db.position = { point = point, relativePoint = relativePoint, x = x, y = y }
            end

            if not didDrag then
                local now = GetTime()
                if now - lastClick < 0.4 then
                    -- Combat-safe: ApplyMinimizeState defers when locked down.
                    db.minimized = not db.minimized
                    panel:ApplyMinimizeState()
                    lastClick = 0  -- prevent triple-click from toggling twice
                else
                    lastClick = now
                end
            end
        end
    end)

    -- Top accent stripe + optional bottom stripe + gradient are now
    -- managed by ApplyThemedBackdrop based on the active theme.

    -- Track title font strings + the icon so ApplyBackdrop can refresh
    -- their colors on theme switch.
    bar._titleFontStrings = {}

    -- Icon
    if self.opts.icon then
        local profIcon = bar:CreateTexture(nil, "ARTWORK")
        profIcon:SetSize(14, 14)
        profIcon:SetPoint("LEFT", bar, "LEFT", 8, 0)
        profIcon:SetTexture(self.opts.icon)
        profIcon:SetVertexColor(theme.colors.accent[1], theme.colors.accent[2], theme.colors.accent[3])
        bar._titleIcon = profIcon

        local title = bar:CreateFontString(nil, "OVERLAY")
        title:SetFont(theme.font, theme.fontSize, lib.FontFlags())
        title:SetPoint("LEFT", profIcon, "RIGHT", 5, 0)
        title:SetText(self.opts.title or "")
        title:SetTextColor(unpack(theme.colors.title))
        bar._titleFontStrings[#bar._titleFontStrings + 1] = title
    else
        local title = bar:CreateFontString(nil, "OVERLAY")
        title:SetFont(theme.font, theme.fontSize, lib.FontFlags())
        title:SetPoint("LEFT", bar, "LEFT", 8, 0)
        title:SetText(self.opts.title or "")
        title:SetTextColor(unpack(theme.colors.title))
        bar._titleFontStrings[#bar._titleFontStrings + 1] = title
    end

    -- Progress counter (warm dim gold; color refreshed in ApplyBackdrop)
    local progressText = bar:CreateFontString(nil, "OVERLAY")
    progressText:SetFont(theme.font, theme.fontSize - 1, lib.FontFlags())
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

-- Scroll frame
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

    local thumb = scroll:CreateTexture(nil, "ARTWORK")
    thumb:SetWidth(5)
    thumb:Hide()

    local function applyScrollTheme()
        local tc = lib.Theme.colors.scrollTrack
        track:SetColorTexture(tc[1], tc[2], tc[3], tc[4])
        local stc = lib.Theme.colors.scrollThumb
        thumb:SetColorTexture(stc[1], stc[2], stc[3], stc[4])
    end
    applyScrollTheme()
    lib.RegisterThemeHook(applyScrollTheme)

    local syncScrollHit
    local function UpdateScrollBar()
        local viewH = scroll:GetHeight()
        local contentH = content:GetHeight()
        if contentH <= viewH or viewH <= 0 then
            thumb:Hide()
            if syncScrollHit then syncScrollHit() end
            if self._MaybeRepaintWindow then self:_MaybeRepaintWindow() end
            return
        end
        thumb:Show()
        local trackH = math.max(track:GetHeight(), 1)
        local thumbH = math.max(trackH * (viewH / contentH), 14)
        local pct = math.max(0, math.min(scroll:GetVerticalScroll() / (contentH - viewH), 1))
        thumb:SetHeight(thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, -((trackH - thumbH) * pct))
        if syncScrollHit then syncScrollHit() end
        if self._MaybeRepaintWindow then self:_MaybeRepaintWindow() end
    end

    -- Textures cannot take mouse input; overlay frames that can.
    syncScrollHit = lib.AttachScrollDrag and lib.AttachScrollDrag(scroll, content, thumb, track, UpdateScrollBar)

    scroll:SetScript("OnMouseWheel", function(_, delta)
        local cur = scroll:GetVerticalScroll()
        local maxScroll = math.max(content:GetHeight() - scroll:GetHeight(), 0)
        scroll:SetVerticalScroll(math.max(0, math.min(cur - delta * 30, maxScroll)))
        UpdateScrollBar()
    end)
    scroll:SetScript("OnScrollRangeChanged", function() UpdateScrollBar() end)
    scroll:SetScript("OnVerticalScroll", function()
        UpdateScrollBar()
        if self._MaybeRepaintWindow then self:_MaybeRepaintWindow() end
    end)

    f.scrollFrame = scroll
    f.scrollChild = content
    f.scrollTrack = track
    self.scrollFrame = scroll
    self.scrollChild = content
end

-- Resize dragger
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
            -- Defensive against the rare case the user releases the resize
            -- handle the same instant a combat-flag flips on. SetWidth/Height
            -- on non-secure frames is technically allowed in combat, but the
            -- onRefresh below will rebuild rows and we don't want to rebuild
            -- mid-combat — defer it.
            local newW, newH = ClampPanelSize(panel.opts,
                math.floor(f:GetWidth()), math.floor(f:GetHeight()))
            db.panelWidth = newW
            db.panelHeight = newH
            f:SetWidth(newW)
            f:SetHeight(newH)
            local point, _, relativePoint, x, y = f:GetPoint()
            db.position = { point = point, relativePoint = relativePoint, x = x, y = y }
            if f.scrollChild then
                f.scrollChild:SetWidth(newW - 9)
            end
            if panel.opts.onRefresh then
                if InCombatLockdown() then
                    local watcher = CreateFrame("Frame")
                    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
                    watcher:SetScript("OnEvent", function(w)
                        w:UnregisterAllEvents()
                        panel.opts.onRefresh(panel)
                    end)
                else
                    panel.opts.onRefresh(panel)
                end
            end
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

-- Show / Hide / Toggle
function PanelProto:Show()
    lib.FadeIn(self.frame)
    self.db.panelShown = true
    if self.opts.onRefresh then self.opts.onRefresh(self) end
    if self.db.minimized then
        self:ApplyMinimizeState()
    end
end

function PanelProto:Hide()
    -- State commits now; the frame hides when the fade finishes.
    self.db.panelShown = false
    lib.FadeOut(self.frame)
    if self.cfgFrame then lib.PopOut(self.cfgFrame) end
    if self.opts.onHide then self.opts.onHide(self) end
end

function PanelProto:Toggle()
    -- A frame mid-fade-out is still shown but on its way out; toggling
    -- then means "bring it back", not "close it again".
    local closing = self.frame._muiFadeOut and self.frame._muiFadeOut:IsPlaying()
    if self.frame:IsShown() and not closing then
        self:Hide()
    else
        self:Show()
    end
end

-- Config frame. The options surface is the shared settings window, so
-- both shells present identical options.
function PanelProto:BuildConfigFrame()
    if not lib.BuildSettingsWindow then
        print("|cffff8888[MidnightUI]|r Settings.lua did not load. Restart the "
            .. "game client fully — a /reload does not pick up newly added "
            .. "addon files.")
        return nil
    end
    return lib.BuildSettingsWindow(self, {
        name     = self.opts.name or "MidnightUIPanel",
        title    = "Options",
        subtitle = self.opts.title or "",
        db       = self.db,
    })
end

function PanelProto:ToggleConfig()
    if self.cfgFrame and self.cfgFrame:IsShown() then
        lib.PopOut(self.cfgFrame)
        return
    end
    if not self.cfgFrame then
        self.cfgFrame = self:BuildConfigFrame()
    end
    -- Free-floating window with its own saved position: no re-docking.
    if self.pendingConfigDefs then
        self:_PopulateConfigBody(self.pendingConfigDefs)
    end
    lib.PopIn(self.cfgFrame)
end

function PanelProto:PopulateConfig(defs)
    self.pendingConfigDefs = defs
    -- If the config panel is already open, re-render immediately so live
    -- updates (module reorder, module enable/disable) reflect right away
    -- without the user having to close and reopen the panel.
    if self.cfgFrame and self.cfgFrame:IsShown() then
        self:_PopulateConfigBody(defs)
    end
end

function PanelProto:_PopulateConfigBody(defs)
    if lib._populateConfigBody then
        lib._populateConfigBody(self, defs)
    end
end

-- Scroll content helpers
-- Repaint the windowed row list once the viewport has moved far enough that
-- unbuilt rows could be showing. Mirrors ShellProto:_MaybeRepaintWindow; the
-- two protos do not share a base.
function PanelProto:_MaybeRepaintWindow()
    local pool = self.pool
    if not (pool and pool._winTop and self.scrollFrame) then return end
    local off = self.scrollFrame:GetVerticalScroll() or 0
    if math.abs(off - (pool._winAt or 0)) < 300 then return end
    -- Distance alone is not enough of a brake. Dragging the scroll thumb runs
    -- onDrag as an OnUpdate, so UpdateScrollBar -- and therefore this -- is
    -- reached every frame, and a fast drag clears 300px many times a second.
    -- A render pass walks every row in the list even when it paints almost
    -- none of them, so cap the rate as well as the distance.
    local now = GetTime and GetTime() or 0
    if now > 0 and (now - (self._repaintAt or 0)) < 0.06 then return end
    self._repaintAt = now
    if self._repainting then return end
    self._repainting = true
    if self.opts and self.opts.onRefresh then self.opts.onRefresh(self) end
    self._repainting = false
end

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

-- RenderHeader convenience wrapper
function PanelProto:RenderHeader(parent, yOff, opts)
    return lib.RenderCollapsibleHeader(self.pool, parent, yOff, opts, self.db, function()
        if self.opts.onRefresh then self.opts.onRefresh(self) end
    end)
end
