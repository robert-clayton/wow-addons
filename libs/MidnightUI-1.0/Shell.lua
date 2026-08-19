local lib = LibStub:GetLibrary("MidnightUI-1.0", true)
if not lib then return end

-- Premium application-style shell: sidebar (brand + nav) on the left,
-- page header on top, one shared scroll region, footer button bar.
-- Mirrors PanelProto's consumer contract exactly — a shell object is a
-- drop-in `panel` for module renderers:
--   frame (+ frame.titleBar), scrollFrame, scrollChild, pool, db, opts,
--   titleProgressText, navContainer, searchInput,
--   Show/Hide/Toggle, RefreshScrollContent, ApplyBackdrop,
--   SetPageHeader, PopulateConfig/ToggleConfig,
--   ApplyMinimizeState/UpdateMinimizeVisual, UpdateDraggerVisibility.
-- Behavioral hooks arrive through opts so the lib stays consumer-
-- agnostic: onRefresh, onHide, onScan, onInspector, inspectorVisible.

local SIDEBAR_W   = 220
local BRAND_H     = 64
local NAV_TOP     = 88
local HEADER_H    = 96
local FOOTER_H    = 56
local CONTENT_PAD = 24
local GAP         = 8
local MINI_W      = SIDEBAR_W + 240
local MINI_H      = 48

local WHITE8 = "Interface\\Buttons\\WHITE8x8"

-- Flat 1px-hairline skin, used under every theme. Deliberately NOT
-- ApplyThemedBackdrop: the modern theme's NineSlice / tooltip-border
-- edge would overlap the flush-anchored sidebar, header and footer
-- chrome. Flat is the Premium identity; the palette still comes from
-- the live theme colors.
local PREMIUM_BACKDROP = {
    bgFile   = WHITE8,
    edgeFile = WHITE8,
    edgeSize = 1,
}

local ShellProto = {}
ShellProto.__index = ShellProto

-- Saved sizes can predate a raised minimum (or lowered maximum); bring
-- them back inside the configured envelope.
local function ClampSize(opts, w, h)
    w = math.max(opts.minWidth or 760, math.min(opts.maxWidth or 1400, w))
    h = math.max(opts.minHeight or 520, math.min(opts.maxHeight or 1000, h))
    return w, h
end

function lib:CreatePremiumShell(opts)
    local shell = setmetatable({}, ShellProto)
    shell.opts = opts
    shell.db = opts.db
    shell.pool = lib.Pool:New()
    shell:Create()
    return shell
end

-- Width available to the scroll child at the current saved frame width.
-- Set before the constructor returns and re-set before every onRefresh
-- that follows a resize (module renderers read parent:GetWidth() for
-- bar fills at first Refresh).
function ShellProto:_ContentWidth()
    local w = self.db.panelWidth or self.opts.defaultWidth or 980
    return math.max(w - SIDEBAR_W - 2 * CONTENT_PAD - 6, 100)
end

function ShellProto:Create()
    local opts = self.opts
    local db = self.db
    local shell = self

    local w = db.panelWidth or opts.defaultWidth or 980
    local h = db.panelHeight or opts.defaultHeight or 680
    w, h = ClampSize(opts, w, h)
    -- Write back so later reads of the saved size see the clamped value;
    -- an untouched nil keeps tracking future default changes.
    if db.panelWidth then db.panelWidth = w end
    if db.panelHeight then db.panelHeight = h end

    local f = CreateFrame("Frame", (opts.name or "MidnightUIShell") .. "Frame",
        UIParent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    self.frame = f

    self:_CreateSidebar()
    self:_CreateHeader()
    self:_CreateContent()
    self:_CreateFooter()
    self:_CreateResizeDragger()
    self:ApplyBackdrop()
    -- The shell's one theme hook: repaint all chrome on live switch.
    lib.RegisterThemeHook(function() shell:ApplyBackdrop() end)

    local pos = db.position
    f:ClearAllPoints()
    local relPoint = pos.relativePoint or pos.point or "CENTER"
    f:SetPoint(pos.point or "CENTER", UIParent, relPoint, pos.x or 0, pos.y or 0)

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

-- Drag handling shared by the brand block and the header. Position is
-- only persisted after real cursor movement so a static click can't
-- clobber relativePoint.
function ShellProto:_MakeDragHandler(region)
    local f = self.frame
    local db = self.db
    local downX, downY, didDrag
    region:EnableMouse(true)
    region:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            downX, downY = GetCursorPosition()
            didDrag = false
            if not db.locked then f:StartMoving() end
        end
    end)
    region:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            f:StopMovingOrSizing()
            if downX and downY then
                local cx, cy = GetCursorPosition()
                local dx, dy = (cx or downX) - downX, (cy or downY) - downY
                if (dx * dx + dy * dy) > 16 then didDrag = true end
            end
            if didDrag and not db.locked then
                local point, _, relativePoint, x, y = f:GetPoint()
                db.position = { point = point, relativePoint = relativePoint, x = x, y = y }
            end
        end
    end)
end

function ShellProto:_CreateSidebar()
    local f = self.frame
    local opts = self.opts
    local theme = lib.Theme

    local sb = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    sb:SetPoint("TOPLEFT")
    sb:SetPoint("BOTTOMLEFT")
    sb:SetWidth(SIDEBAR_W)
    sb:SetTexture(WHITE8)
    f.sidebarBg = sb

    local line = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    line:SetPoint("TOPLEFT", f, "TOPLEFT", SIDEBAR_W, 0)
    line:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", SIDEBAR_W, 0)
    line:SetWidth(1)
    line:SetTexture(WHITE8)
    f.sidebarLine = line

    -- Brand block; also a drag handle.
    local brand = CreateFrame("Frame", nil, f)
    brand:SetSize(SIDEBAR_W, BRAND_H)
    brand:SetPoint("TOPLEFT")
    f.brand = brand
    self:_MakeDragHandler(brand)

    local iconEdge = brand:CreateTexture(nil, "ARTWORK", nil, 1)
    iconEdge:SetSize(30, 30)
    iconEdge:SetPoint("TOPLEFT", brand, "TOPLEFT", 15, -17)
    iconEdge:SetTexture(WHITE8)
    brand.iconEdge = iconEdge

    local icon = brand:CreateTexture(nil, "ARTWORK", nil, 2)
    icon:SetSize(28, 28)
    icon:SetPoint("CENTER", iconEdge, "CENTER", 0, 0)
    if opts.icon then icon:SetTexture(opts.icon) end
    brand.icon = icon

    local wordmark = brand:CreateFontString(nil, "OVERLAY")
    wordmark:SetFont(lib.FontBold(), theme.fontSize + 4, lib.FontFlags())
    wordmark:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -1)
    wordmark:SetText(string.upper(opts.title or ""))
    brand.wordmark = wordmark

    local version = brand:CreateFontString(nil, "OVERLAY")
    version:SetFont(theme.font, 9, lib.FontFlags())
    version:SetPoint("TOPLEFT", wordmark, "BOTTOMLEFT", 0, -3)
    version:SetText(opts.version and ("v" .. opts.version) or "")
    brand.version = version

    -- Search input: present but hidden in the MVP (Phase 2 wires
    -- lib.MakeSearchInput + the row filter here).
    local search = CreateFrame("Frame", nil, f, "BackdropTemplate")
    search:SetSize(SIDEBAR_W - 32, 26)
    search:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -72)
    search:Hide()
    self.searchInput = search
    f.searchInput = search

    -- Nav rows live here; the consumer (PremiumNav) fills and anchors
    -- them. Overflow past the container clips.
    local nav = CreateFrame("Frame", nil, f)
    nav:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -NAV_TOP)
    nav:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", SIDEBAR_W, GAP)
    if nav.SetClipsChildren then nav:SetClipsChildren(true) end
    self.navContainer = nav
    f.navContainer = nav
end

function ShellProto:_CreateHeader()
    local f = self.frame
    local theme = lib.Theme

    -- `frame.titleBar` is the contract with Core's indicator chain: the
    -- filter/score/peer buttons are created on it and anchored off
    -- titleProgressText (single-line indicator row).
    local bar = CreateFrame("Frame", nil, f)
    bar:SetHeight(HEADER_H)
    bar:SetPoint("TOPLEFT", f, "TOPLEFT", SIDEBAR_W, 0)
    bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.titleBar = bar
    self:_MakeDragHandler(bar)

    local hairline = bar:CreateTexture(nil, "ARTWORK")
    hairline:SetHeight(1)
    hairline:SetPoint("BOTTOMLEFT")
    hairline:SetPoint("BOTTOMRIGHT")
    hairline:SetTexture(WHITE8)
    bar.hairline = hairline

    -- Collection spine segments (see UpdateSpine): pooled texture pairs
    -- along the header's bottom edge.
    bar.spineSegs = {}

    local title = bar:CreateFontString(nil, "OVERLAY")
    title:SetFont(lib.FontBold(), theme.fontSize + 9, lib.FontFlags())
    title:SetPoint("TOPLEFT", bar, "TOPLEFT", CONTENT_PAD, -14)
    bar.pageTitle = title

    local subtitle = bar:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(theme.font, theme.fontSize, lib.FontFlags())
    subtitle:SetPoint("TOPLEFT", bar, "TOPLEFT", CONTENT_PAD + 1, -44)
    subtitle:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -(CONTENT_PAD + 140), -44)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWordWrap(false)
    bar.pageSubtitle = subtitle

    -- Progress counter. Parented to the window (not the header) so the
    -- minimized strip keeps showing it; normally anchored into the
    -- header's bottom indicator strip.
    local progress = f:CreateFontString(nil, "OVERLAY")
    progress:SetFont(lib.FontBold(), theme.fontSize + 5, lib.FontFlags())
    self.titleProgressText = progress
    self:_AnchorProgressText(false)
end

function ShellProto:_AnchorProgressText(minimized)
    local f = self.frame
    local p = self.titleProgressText
    if not p then return end
    p:ClearAllPoints()
    if minimized and f.restoreBtn then
        p:SetPoint("RIGHT", f.restoreBtn, "LEFT", -10, 0)
    else
        p:SetPoint("RIGHT", f.titleBar, "BOTTOMRIGHT", -CONTENT_PAD, 16)
    end
end

function ShellProto:_CreateContent()
    local f = self.frame

    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", SIDEBAR_W + CONTENT_PAD, -(HEADER_H + GAP))
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(CONTENT_PAD + 6), FOOTER_H + GAP)
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(self:_ContentWidth())
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    -- 4px thumb on an (often invisible) track at the window's right edge.
    local track = scroll:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(4)
    track:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -(HEADER_H + GAP))
    track:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, FOOTER_H + GAP)
    track:SetTexture(WHITE8)

    local thumb = scroll:CreateTexture(nil, "ARTWORK")
    thumb:SetWidth(4)
    thumb:SetTexture(WHITE8)
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
        scroll:SetVerticalScroll(math.max(0, math.min(cur - delta * 60, maxScroll)))
        UpdateScrollBar()
    end)
    scroll:SetScript("OnScrollRangeChanged", function() UpdateScrollBar() end)
    scroll:SetScript("OnVerticalScroll", function() UpdateScrollBar() end)

    f.scrollFrame = scroll
    f.scrollChild = content
    f.scrollTrack = track
    f.scrollThumb = thumb
    self.scrollFrame = scroll
    self.scrollChild = content
end

function ShellProto:_CreateFooter()
    local f = self.frame
    local db = self.db
    local shell = self
    local opts = self.opts
    local colors = lib.Theme.colors

    local footer = CreateFrame("Frame", nil, f)
    footer:SetHeight(FOOTER_H)
    footer:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", SIDEBAR_W, 0)
    footer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.footer = footer

    local fill = footer:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints()
    fill:SetTexture(WHITE8)
    footer.fill = fill

    local hairline = footer:CreateTexture(nil, "ARTWORK")
    hairline:SetHeight(1)
    hairline:SetPoint("TOPLEFT")
    hairline:SetPoint("TOPRIGHT")
    hairline:SetTexture(WHITE8)
    footer.hairline = hairline

    local BTN = { width = 88, height = 30 }

    -- Right side (right → left). Scan is the one primary action in the
    -- footer (accent text over an accent-tinted fill); Close merely
    -- dismisses and stays quiet.
    local closeBtn = lib.MakeHeaderBtn(footer, "Close",
        colors.btnTealFg, colors.btnTealHoverBg, colors.btnTealHoverBd,
        "Close", BTN)
    closeBtn:SetPoint("RIGHT", footer, "RIGHT", -CONTENT_PAD, 0)
    closeBtn:SetScript("OnClick", function() shell:Hide() end)
    footer.closeBtn = closeBtn

    local scanBtn = lib.MakeHeaderBtn(footer, "Scan",
        colors.accent, colors.btnTealHoverBg, colors.accent,
        "Rescan all collection modules", BTN)
    scanBtn:SetPoint("RIGHT", closeBtn, "LEFT", -12, 0)
    scanBtn:SetScript("OnClick", function()
        if opts.onScan then opts.onScan(shell) end
    end)
    -- Persistent accent-tinted fill; repainted in ApplyBackdrop (the
    -- backdrop bg renders beneath regular textures, so this overlays it
    -- and hover backdrop changes still read through the 12% wash).
    local scanFill = scanBtn:CreateTexture(nil, "BACKGROUND")
    scanFill:SetPoint("TOPLEFT", 1, -1)
    scanFill:SetPoint("BOTTOMRIGHT", -1, 1)
    scanFill:SetTexture(WHITE8)
    scanBtn._fill = scanFill
    footer.scanBtn = scanBtn

    -- Left side (left → right).
    local optBtn = lib.MakeHeaderBtn(footer, "Options",
        colors.btnTealFg, colors.btnTealHoverBg, colors.btnTealHoverBd,
        "Options", BTN)
    optBtn:SetPoint("LEFT", footer, "LEFT", CONTENT_PAD, 0)
    optBtn:SetScript("OnClick", function() shell:ToggleConfig() end)
    footer.optionsBtn = optBtn

    local inspBtn = lib.MakeHeaderBtn(footer, "Inspector",
        colors.btnTealFg, colors.btnTealHoverBg, colors.btnTealHoverBd,
        "Open Collection Inspector", BTN)
    inspBtn:SetPoint("LEFT", optBtn, "RIGHT", 12, 0)
    inspBtn:SetScript("OnClick", function()
        if opts.onInspector then opts.onInspector(shell) end
    end)
    footer.inspectorBtn = inspBtn

    local minBtn = lib.MakeHeaderBtn(footer, "-",
        colors.btnTealFg, colors.btnTealHoverBg, colors.btnTealHoverBd,
        "Minimize", { width = 30, height = 30 })
    minBtn:SetPoint("LEFT", inspBtn, "RIGHT", 12, 0)
    minBtn:SetScript("OnClick", function()
        db.minimized = not db.minimized
        shell:ApplyMinimizeState()
    end)
    footer.minBtn = minBtn

    -- Restore button for the minimized brand strip (the footer — and
    -- its minimize button — is hidden while minimized).
    local restoreBtn = lib.MakeHeaderBtn(f, "+",
        colors.btnTealFg, colors.btnTealHoverBg, colors.btnTealHoverBd,
        "Restore", { width = 30, height = 30 })
    restoreBtn:SetPoint("RIGHT", f, "RIGHT", -12, 0)
    restoreBtn:Hide()
    restoreBtn:SetScript("OnClick", function()
        db.minimized = false
        shell:ApplyMinimizeState()
    end)
    f.restoreBtn = restoreBtn

    self.UpdateMinimizeVisual = function()
        minBtn._label:SetText(db.minimized and "+" or "-")
        if db.minimized then restoreBtn:Show() else restoreBtn:Hide() end
    end
    self.UpdateMinimizeVisual()
end

function ShellProto:_CreateResizeDragger()
    local f = self.frame
    local db = self.db
    local shell = self

    local dragger = CreateFrame("Frame", nil, f)
    dragger:SetSize(16, 16)
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

    local function onDragUpdate()
        local cx, cy = GetCursorPosition()
        local scale = f:GetEffectiveScale()
        cx = cx / scale
        cy = cy / scale
        local dx = cx - dragStartX
        local dy = dragStartY - cy
        local newW, newH = ClampSize(shell.opts, dragStartW + dx, dragStartH + dy)
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
            local newW, newH = ClampSize(shell.opts,
                math.floor(f:GetWidth()), math.floor(f:GetHeight()))
            db.panelWidth = newW
            db.panelHeight = newH
            f:SetWidth(newW)
            f:SetHeight(newH)
            local point, _, relativePoint, x, y = f:GetPoint()
            db.position = { point = point, relativePoint = relativePoint, x = x, y = y }
            -- Re-set the scroll child width before the refresh so bar
            -- fills computed off parent:GetWidth() see the new size, and
            -- re-lay the spine segments at the new header width.
            if shell.scrollChild then
                shell.scrollChild:SetWidth(shell:_ContentWidth())
            end
            shell:UpdateSpine()
            if shell.opts.onRefresh then
                if InCombatLockdown() then
                    local watcher = CreateFrame("Frame")
                    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
                    watcher:SetScript("OnEvent", function(w)
                        w:UnregisterAllEvents()
                        shell.opts.onRefresh(shell)
                    end)
                else
                    shell.opts.onRefresh(shell)
                end
            end
        end
    end)

    if db.locked or db.minimized then dragger:Hide() end
    f.dragger = dragger
end

function ShellProto:UpdateDraggerVisibility()
    if not self.frame or not self.frame.dragger then return end
    if self.db.locked or self.db.minimized then
        self.frame.dragger:Hide()
    else
        self.frame.dragger:Show()
    end
end

-- Repaint every piece of chrome from the live theme. Called at
-- creation, on every live theme switch, and by the opacity slider.
function ShellProto:ApplyBackdrop()
    local f = self.frame
    local theme = lib.Theme
    local c = theme.colors
    local v = self.db.frameAlpha or 1.0

    f:SetBackdrop(PREMIUM_BACKDROP)
    local bg = c.bg
    f:SetBackdropColor(bg[1], bg[2], bg[3], (bg[4] or 1) * v)
    local bd = c.border
    f:SetBackdropBorderColor(bd[1], bd[2], bd[3], math.max(v, 0.4))

    local tb = c.titlebar
    f.sidebarBg:SetColorTexture(tb[1], tb[2], tb[3], (tb[4] or 1) * v)
    local dv = c.optionsDivider
    f.sidebarLine:SetColorTexture(dv[1], dv[2], dv[3], dv[4] or 0.06)

    local brand = f.brand
    brand.iconEdge:SetColorTexture(bd[1], bd[2], bd[3], 1)
    brand.wordmark:SetFont(lib.FontBold(), theme.fontSize + 4, lib.FontFlags())
    brand.wordmark:SetTextColor(c.title[1], c.title[2], c.title[3], c.title[4] or 1)
    brand.version:SetFont(theme.font, 9, lib.FontFlags())
    brand.version:SetTextColor(c.textDim[1], c.textDim[2], c.textDim[3])

    local bar = f.titleBar
    bar.pageTitle:SetFont(lib.FontBold(), theme.fontSize + 9, lib.FontFlags())
    bar.pageTitle:SetTextColor(c.title[1], c.title[2], c.title[3], c.title[4] or 1)
    bar.pageSubtitle:SetFont(theme.font, theme.fontSize, lib.FontFlags())
    bar.pageSubtitle:SetTextColor(c.textDim[1], c.textDim[2], c.textDim[3])
    -- Hairline color is owned by UpdateSpine (accent when the spine has
    -- no data, receded divider when it does).
    self:UpdateSpine()

    if self.titleProgressText then
        self.titleProgressText:SetFont(lib.FontBold(), theme.fontSize + 5, lib.FontFlags())
        local sa = c.scoreAccent
        self.titleProgressText:SetTextColor(sa[1], sa[2], sa[3])
    end

    if f.footer.scanBtn and f.footer.scanBtn._fill then
        local ac = c.accent
        f.footer.scanBtn._fill:SetColorTexture(ac[1], ac[2], ac[3], 0.12)
    end

    local tc = c.scrollTrack
    f.scrollTrack:SetColorTexture(tc[1], tc[2], tc[3], tc[4])
    local st = c.scrollThumb
    f.scrollThumb:SetColorTexture(st[1], st[2], st[3], st[4])

    local hb = c.headerBg
    f.footer.fill:SetColorTexture(hb[1], hb[2], hb[3], (hb[4] or 1) * v)
    f.footer.hairline:SetColorTexture(dv[1], dv[2], dv[3], dv[4] or 0.06)

    -- Inspector button visibility is consumer-driven; re-evaluated here
    -- (staleness until the next ApplyBackdrop is accepted).
    local showInsp = true
    if self.opts.inspectorVisible then
        showInsp = self.opts.inspectorVisible() and true or false
    end
    local insp = f.footer.inspectorBtn
    local minBtn = f.footer.minBtn
    if showInsp then insp:Show() else insp:Hide() end
    minBtn:ClearAllPoints()
    if showInsp then
        minBtn:SetPoint("LEFT", insp, "RIGHT", 12, 0)
    else
        minBtn:SetPoint("LEFT", f.footer.optionsBtn, "RIGHT", 12, 0)
    end
end

-- Collapse to a brand strip: icon + wordmark + progress counter +
-- restore button. Everything else (including the resize dragger —
-- a stray drag on the strip must not write bogus geometry) hides.
function ShellProto:_ApplyMinimizedVisuals()
    local f = self.frame
    f.titleBar:Hide()
    f.scrollFrame:Hide()
    f.footer:Hide()
    f.navContainer:Hide()
    f.sidebarBg:Hide()
    f.sidebarLine:Hide()
    if f.searchInput then f.searchInput:Hide() end
    f.brand.version:Hide()
    if f.dragger then f.dragger:Hide() end
    f:SetSize(MINI_W, MINI_H)
    self:_AnchorProgressText(true)
    if self.UpdateMinimizeVisual then self.UpdateMinimizeVisual() end
end

function ShellProto:ApplyMinimizeState()
    local f = self.frame
    if not f then return end
    -- Resizing/anchoring during combat can taint UIParent. Queue and
    -- apply the moment combat ends.
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
        self:_ApplyMinimizedVisuals()
    else
        f.titleBar:Show()
        f.scrollFrame:Show()
        f.footer:Show()
        f.navContainer:Show()
        f.sidebarBg:Show()
        f.sidebarLine:Show()
        f.brand.version:Show()
        -- searchInput stays hidden in the MVP.
        local w, h = ClampSize(self.opts,
            db.panelWidth or self.opts.defaultWidth or 980,
            db.panelHeight or self.opts.defaultHeight or 680)
        f:SetSize(w, h)
        if f.dragger and not db.locked then f.dragger:Show() end
        self:_AnchorProgressText(false)
        self:UpdateSpine()
        if self.UpdateMinimizeVisual then self.UpdateMinimizeVisual() end
        if self.opts.onRefresh then self.opts.onRefresh(self) end
    end
end

function ShellProto:Show()
    self.frame:Show()
    self.db.panelShown = true
    if self.opts.onRefresh then self.opts.onRefresh(self) end
    if self.db.minimized then
        self:ApplyMinimizeState()
    end
end

function ShellProto:Hide()
    self.frame:Hide()
    self.db.panelShown = false
    -- The config dock is parented to UIParent and only anchored to the
    -- window; hide it explicitly or it outlives Close.
    if self.cfgFrame then self.cfgFrame:Hide() end
    if self.opts.onHide then self.opts.onHide(self) end
end

function ShellProto:Toggle()
    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function ShellProto:SetPageHeader(title, subtitle)
    local bar = self.frame and self.frame.titleBar
    if not bar then return end
    bar.pageTitle:SetText(title or "")
    bar.pageSubtitle:SetText(subtitle or "")
    self:UpdateSpine()
end

-- The shell's signature element: a segmented "collection spine" along
-- the header's bottom edge. One segment per source category of the
-- active page, width proportional to that category's share of the
-- collection; the lit run inside each segment is the share already
-- collected. Structure as information — the accent line IS the data.
-- Falls back to the plain accent hairline when the consumer supplies no
-- spine data (module deferred, recipes, classic consumers).
function ShellProto:UpdateSpine()
    local bar = self.frame and self.frame.titleBar
    if not bar or not bar.spineSegs then return end
    local c = lib.Theme.colors
    local segs = bar.spineSegs
    local ok, data = true, nil
    if self.opts.spineData then ok, data = pcall(self.opts.spineData) end
    if not ok then data = nil end
    local n = data and #data or 0
    local grand = 0
    if data then
        for _, d in ipairs(data) do grand = grand + (d.total or 0) end
    end
    local barW = bar:GetWidth() or 0
    if n == 0 or grand == 0 or barW < 200 then
        for _, seg in ipairs(segs) do seg.base:Hide(); seg.lit:Hide() end
        local ac = c.accent
        bar.hairline:SetColorTexture(ac[1], ac[2], ac[3],
            lib.Theme.titleBarBotStripeAlpha or 0.9)
        return
    end
    -- Spine active: the hairline recedes to a divider under it.
    local dv = c.optionsDivider
    bar.hairline:SetColorTexture(dv[1], dv[2], dv[3], dv[4] or 0.06)
    local GAP_W = 2
    local usable = barW - 2 * CONTENT_PAD - GAP_W * (n - 1)
    local x = CONTENT_PAD
    for i, d in ipairs(data) do
        local seg = segs[i]
        if not seg then
            seg = {
                base = bar:CreateTexture(nil, "ARTWORK", nil, 1),
                lit  = bar:CreateTexture(nil, "ARTWORK", nil, 2),
            }
            seg.base:SetTexture(WHITE8); seg.base:SetHeight(3)
            seg.lit:SetTexture(WHITE8);  seg.lit:SetHeight(3)
            segs[i] = seg
        end
        local segW = math.max(usable * ((d.total or 0) / grand), 2)
        local sc = (c.source and d.key and c.source[d.key]) or c.accent
        seg.base:ClearAllPoints()
        seg.base:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", x, 0)
        seg.base:SetWidth(segW)
        seg.base:SetColorTexture(sc[1], sc[2], sc[3], 0.22)
        seg.base:Show()
        local litW = segW * math.min((d.collected or 0) / math.max(d.total or 1, 1), 1)
        if litW >= 1 then
            seg.lit:ClearAllPoints()
            seg.lit:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", x, 0)
            seg.lit:SetWidth(litW)
            seg.lit:SetColorTexture(sc[1], sc[2], sc[3], 0.95)
            seg.lit:Show()
        else
            seg.lit:Hide()
        end
        x = x + segW + GAP_W
    end
    for i = n + 1, #segs do segs[i].base:Hide(); segs[i].lit:Hide() end
end

-- Config side-dock (MVP): delegates to the shared pooled options
-- renderer. Anchored TOPLEFT-only — _populateConfigBody drives the
-- dock's height via SetHeight.
function ShellProto:BuildConfigFrame()
    local theme = lib.Theme
    local f = CreateFrame("Frame", (self.opts.name or "MidnightUIShell") .. "ConfigFrame",
        UIParent, "BackdropTemplate")
    f:SetWidth(260)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:Hide()
    f:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 8, 0)

    local bar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    bar:SetHeight(24)
    bar:SetPoint("TOPLEFT"); bar:SetPoint("TOPRIGHT")
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() f:StartMoving() end)
    bar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    local acc = bar:CreateTexture(nil, "ARTWORK")
    acc:SetPoint("TOPLEFT"); acc:SetPoint("BOTTOMLEFT")
    acc:SetWidth(3)

    local ttl = bar:CreateFontString(nil, "OVERLAY")
    ttl:SetFont(theme.font, theme.fontSize, lib.FontFlags())
    ttl:SetPoint("LEFT", 8, 0)
    ttl:SetText("Options")

    local function applyCfgTheme()
        local th = lib.Theme
        lib.ApplyThemedBackdrop(f, { kind = "options", alpha = th.colors.optionsBg[4] or 1, borderAlpha = 1 })
        lib.ApplyThemedBackdrop(bar, { kind = "titlebar", alpha = 1 })
        acc:SetColorTexture(unpack(th.colors.accent))
        ttl:SetFont(th.font, th.fontSize, lib.FontFlags())
        ttl:SetTextColor(unpack(th.colors.title))
    end
    applyCfgTheme()
    lib.RegisterThemeHook(applyCfgTheme)

    local cls = lib.MakeHeaderBtn(bar, "x",
        theme.colors.btnCloseFg,
        theme.colors.btnCloseHoverBg,
        theme.colors.btnCloseHoverBd,
        "Close")
    cls:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    cls:SetScript("OnClick", function() f:Hide() end)

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
    body:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
    f.body = body

    return f
end

function ShellProto:ToggleConfig()
    if self.cfgFrame and self.cfgFrame:IsShown() then
        self.cfgFrame:Hide()
        return
    end
    if not self.cfgFrame then
        self.cfgFrame = self:BuildConfigFrame()
    end
    if self.frame then
        self.cfgFrame:ClearAllPoints()
        self.cfgFrame:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 8, 0)
    end
    if self.pendingConfigDefs then
        self:_PopulateConfigBody(self.pendingConfigDefs)
    end
    self.cfgFrame:Show()
end

function ShellProto:PopulateConfig(defs)
    self.pendingConfigDefs = defs
    if self.cfgFrame and self.cfgFrame:IsShown() then
        self:_PopulateConfigBody(defs)
    end
end

function ShellProto:_PopulateConfigBody(defs)
    if lib._populateConfigBody then
        lib._populateConfigBody(self, defs)
    end
end

function ShellProto:RefreshScrollContent(height)
    if self.scrollChild then
        self.scrollChild:SetHeight(math.max(height, 1))
    end
    -- Re-assert the minimized strip after refresh (a refresh restores
    -- neither size nor hidden regions on its own).
    if self.db.minimized then
        self:_ApplyMinimizedVisuals()
    end
end

-- RenderHeader convenience wrapper (parity with PanelProto).
function ShellProto:RenderHeader(parent, yOff, opts)
    return lib.RenderCollapsibleHeader(self.pool, parent, yOff, opts, self.db, function()
        if self.opts.onRefresh then self.opts.onRefresh(self) end
    end)
end
