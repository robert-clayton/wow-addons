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
--   RenderConfigInContent/ClearConfigContent/IsConfigInContent,
--   ApplyMinimizeState/UpdateMinimizeVisual, UpdateDraggerVisibility,
--   GetViewMode ("full" | "compact" | "strip").
-- View states: full (sidebar + header + footer), compact (db.compact —
-- a narrow leave-it-up list view: condensed 52px header, no sidebar or
-- footer, its own saved geometry in db.compactWidth/compactHeight),
-- strip (db.minimized — the 48px brand strip; checked first when both
-- flags are set, and restore clears both). All three states share
-- db.position. Nil db.compact keys mean legacy saves and resolve to
-- the full state.
-- Window controls (minimize-to-strip, size toggle, close) live in the
-- page header's top-right corner as ONE shared set (f.minBtn /
-- f.sizeBtn / f.winCloseBtn) used by both the full and the compact
-- header — the two views only differ in header height, so a second set
-- would be the same buttons drawn twice. They are children of
-- frame.titleBar (a full-cover drag surface; a sibling would lose the
-- click) and so hide with it in the strip state, where f.restoreBtn
-- takes over. The footer is action-only: Options and Inspector.
-- Behavioral hooks arrive through opts so the lib stays consumer-
-- agnostic: onRefresh, onHide, onInspector, inspectorVisible,
-- onViewChanged(shell, mode) — fired after every non-combat state
-- apply — and onOptions, which claims the footer's Options button for a
-- consumer that renders options as a view of its own (see
-- RenderConfigInContent) instead of the settings window. opts.onScan is
-- still accepted for consumers that surface a rescan action of their own
-- (it now lives in Options); the shell no longer renders a Scan button.

local SIDEBAR_W   = 220
local BRAND_H     = 64
local NAV_TOP     = 88
-- Title and the indicator chain share one line, so the header needs
-- room for two rows (title, subtitle) rather than three.
local HEADER_H    = 76
local FOOTER_H    = 56
local CONTENT_PAD = 24
local GAP         = 8
-- Strip: a slim one-line pill, not a second title bar.
local MINI_W      = 280
local MINI_H      = 30
-- Compact state: condensed header height and tighter content padding.
local COMPACT_HEADER_H = 52
local COMPACT_PAD      = 12

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

-- Compact envelope. Lib-owned defaults; consumers may override via
-- opts.compactMinWidth / compactMaxWidth / compactMinHeight /
-- compactMaxHeight.
local function ClampCompact(opts, w, h)
    w = math.max(opts.compactMinWidth or 320, math.min(opts.compactMaxWidth or 520, w))
    h = math.max(opts.compactMinHeight or 320, math.min(opts.compactMaxHeight or 900, h))
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
    if self.db.compact and not self.db.minimized then
        local w = self.db.compactWidth or 380
        return math.max(w - 2 * COMPACT_PAD - 6, 100)
    end
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
        -- Restoring a saved session: land in the saved view directly
        -- rather than animating a collapse the player didn't ask for.
        self._initializing = true
        f:Show()
        if opts.onRefresh then opts.onRefresh(self) end
        if db.minimized or db.compact then
            self:ApplyMinimizeState()
        end
        self._initializing = nil
    end
end

-- Drag handling shared by the brand block and the header. Position is
-- only persisted after real cursor movement so a static click can't
-- clobber relativePoint. onClick, when given, fires for a press that
-- never moved — a drag surface can double as a button.
function ShellProto:_MakeDragHandler(region, onClick)
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
            elseif not didDrag and onClick then
                onClick()
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

    -- Strip bar: the minimized state's own slim row (the 64px brand
    -- block is far too heavy for a 30px strip). Hidden outside strip.
    local strip = CreateFrame("Frame", nil, f)
    strip:SetAllPoints(f)
    strip:Hide()
    f.stripBar = strip
    -- Drag to move, click to expand. The restore button is the obvious
    -- affordance; this makes the whole pill work, and means a collapsed
    -- window can always be recovered.
    self:_MakeDragHandler(strip, function()
        if not self.db.minimized then return end
        self:_Restore()
    end)

    local sIcon = strip:CreateTexture(nil, "ARTWORK")
    sIcon:SetSize(14, 14)
    sIcon:SetPoint("LEFT", strip, "LEFT", 10, 0)
    if opts.icon then sIcon:SetTexture(opts.icon) end
    strip.icon = sIcon

    local sText = strip:CreateFontString(nil, "OVERLAY")
    sText:SetFont(lib.FontBold(), 10, lib.FontFlags())
    sText:SetPoint("LEFT", sIcon, "RIGHT", 8, 0)
    sText:SetText(string.upper(opts.title or ""))
    strip.text = sText

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
    subtitle:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -CONTENT_PAD, -44)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWordWrap(false)
    bar.pageSubtitle = subtitle

    -- Progress counter, and through it the whole indicator chain (Core
    -- anchors the filter / peers / score buttons leftward off this
    -- string). Parented to the window rather than the header so the
    -- minimized strip can keep showing it.
    local progress = f:CreateFontString(nil, "OVERLAY")
    progress:SetFont(lib.FontBold(), theme.fontSize + 5, lib.FontFlags())
    self.titleProgressText = progress

    -- Window controls, in the corner every desktop window puts them and
    -- in the same order: size button rightmost, minimize to its left.
    -- ONE pair serves both the full and the compact header — the compact
    -- view used to carry a duplicate pair because the controls lived in
    -- the (compact-hidden) footer; now that they are header-owned, the
    -- two views share the buttons and only the header height differs.
    -- Children of `bar`, which is a full-cover drag surface: a sibling
    -- at the same frame level would never receive the click.
    -- Not hidden at creation — full is the default view and only the
    -- strip state (which hides `bar` outright) takes them away.
    local shell = self
    local db = self.db
    local colors = theme.colors
    -- Right-to-left: close, size, minimize — the order every desktop
    -- window uses, with close outermost.
    local winCloseBtn = lib.MakeHeaderBtn(bar, "x",
        colors.btnCloseFg, colors.btnCloseHoverBg, colors.btnCloseHoverBd,
        "Close", { width = 20, height = 20 })
    winCloseBtn:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -8, -8)
    winCloseBtn:SetScript("OnClick", function() shell:Hide() end)
    f.winCloseBtn = winCloseBtn

    local sizeBtn = lib.MakeHeaderBtn(bar, "",
        colors.btnTealFg, colors.btnTealHoverBg, colors.btnTealHoverBd,
        "Compact view", { width = 20, height = 20 })
    sizeBtn:SetPoint("RIGHT", winCloseBtn, "LEFT", -6, 0)
    -- The size button always shows what it will do next.
    lib.ApplyWindowGlyph(sizeBtn, db.compact and "maximize" or "restore")
    sizeBtn:SetScript("OnClick", function()
        db.compact = not db.compact
        shell:ApplyMinimizeState()
    end)
    -- The creation-time tooltip is captured by value; hook a second
    -- handler so the text tracks the state the glyph is showing.
    sizeBtn:HookScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
        GameTooltip:SetText(db.compact and "Full view" or "Compact view")
        GameTooltip:Show()
    end)
    f.sizeBtn = sizeBtn

    local minBtn = lib.MakeHeaderBtn(bar, "",
        colors.btnTealFg, colors.btnTealHoverBg, colors.btnTealHoverBd,
        "Minimize", { width = 20, height = 20 })
    minBtn:SetPoint("RIGHT", sizeBtn, "LEFT", -6, 0)
    lib.ApplyWindowGlyph(minBtn, "minimize")
    minBtn:SetScript("OnClick", function()
        shell:_Minimize()
    end)
    f.minBtn = minBtn

    self:_AnchorProgressText(false)
end

-- mode: "strip" (or legacy true), "compact", anything else = full.
-- Also owns the counter's font: the slim strip needs body-size text,
-- the full/compact headers the larger display cut.
function ShellProto:_AnchorProgressText(mode)
    local f = self.frame
    local p = self.titleProgressText
    if not p then return end
    local strip = (mode == "strip" or mode == true)
    p:SetFont(lib.FontBold(), lib.Theme.fontSize + (strip and 0 or 5), lib.FontFlags())
    p:ClearAllPoints()
    if strip and f.restoreBtn then
        p:SetPoint("RIGHT", f.restoreBtn, "LEFT", -8, 0)
    elseif not strip and f.minBtn then
        -- Left of the window controls (minBtn is the leftmost of the
        -- pair) so the indicator chain Core hangs off this string can
        -- never run under them. The full header adds a -8 nudge: the
        -- controls sit at the header's very top (centre -18) while the
        -- indicator row keeps sharing the page title's optical centre
        -- at -26, exactly where it sat before they moved up here. The
        -- compact header is one line, so there it stays on the buttons'
        -- own centre line.
        p:SetPoint("RIGHT", f.minBtn, "LEFT", -10, (mode == "compact") and 0 or -8)
    else
        p:SetPoint("RIGHT", f.titleBar, "TOPRIGHT", -CONTENT_PAD, -26)
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

    -- Actions only. Dismissal moved to the header's X alongside the
    -- other window controls, so the footer carries nothing but the two
    -- surfaces it opens.
    local optBtn = lib.MakeHeaderBtn(footer, "Options",
        colors.btnTealFg, colors.btnTealHoverBg, colors.btnTealHoverBd,
        "Options", BTN)
    optBtn:SetPoint("LEFT", footer, "LEFT", CONTENT_PAD, 0)
    -- Consumers that render options as a view of their own (an Options
    -- entry in the sidebar) take the click through opts.onOptions; with
    -- no hook the button falls back to the free-floating settings window.
    optBtn:SetScript("OnClick", function()
        if opts.onOptions then
            opts.onOptions(shell)
        else
            shell:ToggleConfig()
        end
    end)
    footer.optionsBtn = optBtn

    local inspBtn = lib.MakeHeaderBtn(footer, "Inspector",
        colors.btnTealFg, colors.btnTealHoverBg, colors.btnTealHoverBd,
        "Open Collection Inspector", BTN)
    inspBtn:SetPoint("LEFT", optBtn, "RIGHT", 12, 0)
    inspBtn:SetScript("OnClick", function()
        if opts.onInspector then opts.onInspector(shell) end
    end)
    footer.inspectorBtn = inspBtn

    -- Restore button for the minimized strip (the header — and its
    -- window controls — is hidden while minimized).
    --
    -- Parented to the strip bar, not the window: the strip bar is a
    -- full-cover drag surface with the mouse enabled, so a sibling at
    -- the same frame level would compete with it for the click and the
    -- strip could not be expanded. A child sits above its parent, which
    -- is how the header's window controls work on the title bar.
    local restoreBtn = lib.MakeHeaderBtn(f.stripBar or f, "+",
        colors.btnTealFg, colors.btnTealHoverBg, colors.btnTealHoverBd,
        "Restore", { width = 20, height = 20 })
    restoreBtn:SetPoint("RIGHT", f, "RIGHT", -6, 0)
    restoreBtn:Hide()
    lib.ApplyWindowGlyph(restoreBtn, "maximize")
    restoreBtn:SetScript("OnClick", function() shell:_Restore() end)
    f.restoreBtn = restoreBtn

    self.UpdateMinimizeVisual = function()
        -- The size button always shows what it will do next. It lives in
        -- the header now (created before the footer), so reach it through
        -- the frame rather than a local.
        if f.sizeBtn then
            lib.ApplyWindowGlyph(f.sizeBtn, db.compact and "maximize" or "restore")
        end
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
        local newW, newH = shell:_CurrentClamp(dragStartW + dx, dragStartH + dy)
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
            local newW, newH = shell:_CurrentClamp(
                math.floor(f:GetWidth()), math.floor(f:GetHeight()))
            if db.compact and not db.minimized then
                db.compactWidth = newW
                db.compactHeight = newH
            else
                db.panelWidth = newW
                db.panelHeight = newH
            end
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

-- Clamp against the envelope of the CURRENT view state (compact sizes
-- must not be forced into the full 760x520 minimum and vice versa).
function ShellProto:_CurrentClamp(w, h)
    if self.db.compact and not self.db.minimized then
        return ClampCompact(self.opts, w, h)
    end
    return ClampSize(self.opts, w, h)
end

function ShellProto:UpdateDraggerVisibility()
    if not self.frame or not self.frame.dragger then return end
    if self.db.locked or self.db.minimized then
        self.frame.dragger:Hide()
    else
        self.frame.dragger:Show()
    end
end

-- Page-title font by view state: the compact header condenses the
-- title. State-aware (not applier-owned) so a live theme switch during
-- compact cannot resurrect the full-size font.
function ShellProto:_ApplyTitleFont()
    local bar = self.frame and self.frame.titleBar
    if not bar then return end
    local delta = (self.db.compact and not self.db.minimized) and 4 or 9
    bar.pageTitle:SetFont(lib.FontBold(), lib.Theme.fontSize + delta, lib.FontFlags())
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
    self:_ApplyTitleFont()
    bar.pageTitle:SetTextColor(c.title[1], c.title[2], c.title[3], c.title[4] or 1)
    bar.pageSubtitle:SetFont(theme.font, theme.fontSize, lib.FontFlags())
    bar.pageSubtitle:SetTextColor(c.textDim[1], c.textDim[2], c.textDim[3])
    -- Hairline color is owned by UpdateSpine (accent when the spine has
    -- no data, receded divider when it does).
    self:UpdateSpine()

    if self.titleProgressText then
        -- Size is mode-aware: the slim strip uses body-size text.
        self:_AnchorProgressText(self:GetViewMode())
        local sa = c.scoreAccent
        self.titleProgressText:SetTextColor(sa[1], sa[2], sa[3])
    end

    if f.stripBar then
        f.stripBar.text:SetFont(lib.FontBold(), 10, lib.FontFlags())
        f.stripBar.text:SetTextColor(c.title[1], c.title[2], c.title[3], c.title[4] or 1)
    end

    local tc = c.scrollTrack
    f.scrollTrack:SetColorTexture(tc[1], tc[2], tc[3], tc[4])
    local st = c.scrollThumb
    f.scrollThumb:SetColorTexture(st[1], st[2], st[3], st[4])

    local hb = c.headerBg
    f.footer.fill:SetColorTexture(hb[1], hb[2], hb[3], (hb[4] or 1) * v)
    f.footer.hairline:SetColorTexture(dv[1], dv[2], dv[3], dv[4] or 0.06)

    -- Inspector button visibility is consumer-driven; re-evaluated here
    -- (staleness until the next ApplyBackdrop is accepted). Nothing is
    -- anchored to it any more — it is the last button in the left run —
    -- so hiding it leaves no gap to close.
    local showInsp = true
    if self.opts.inspectorVisible then
        showInsp = self.opts.inspectorVisible() and true or false
    end
    if showInsp then
        f.footer.inspectorBtn:Show()
    else
        f.footer.inspectorBtn:Hide()
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
    -- The slim strip bar replaces the 64px brand block entirely.
    f.brand:Hide()
    if f.stripBar then f.stripBar:Show() end
    if f.dragger then f.dragger:Hide() end
    self:_SizeTo(MINI_W, MINI_H)
    self:_AnchorProgressText("strip")
    if self.UpdateMinimizeVisual then self.UpdateMinimizeVisual() end
end

-- Compact: a narrow leave-it-up window. No sidebar/footer, condensed
-- 52px header (title + progress + spine along its bottom edge), the
-- active module's list at the compact width. Idempotent — re-asserted
-- by RefreshScrollContent after every content refresh.
function ShellProto:_ApplyCompactVisuals()
    local f = self.frame
    local db = self.db
    f.navContainer:Hide()
    f.sidebarBg:Hide()
    f.sidebarLine:Hide()
    if f.searchInput then f.searchInput:Hide() end
    f.brand:Hide()
    if f.stripBar then f.stripBar:Hide() end
    f.footer:Hide()

    local bar = f.titleBar
    bar:Show()
    bar:SetHeight(COMPACT_HEADER_H)
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    bar.pageSubtitle:Hide()
    bar.pageTitle:ClearAllPoints()
    bar.pageTitle:SetPoint("TOPLEFT", bar, "TOPLEFT", COMPACT_PAD, -8)
    self:_ApplyTitleFont()
    -- The window controls ride the header, so they need no per-view
    -- re-anchor: TOPRIGHT -8,-8 is the same corner in both header
    -- heights. Show() is defensive — only the strip hides them, and it
    -- does so by hiding their parent.
    if f.sizeBtn then f.sizeBtn:Show() end
    if f.minBtn then f.minBtn:Show() end

    f.scrollFrame:Show()
    f.scrollFrame:ClearAllPoints()
    f.scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT",
        COMPACT_PAD, -(COMPACT_HEADER_H + GAP))
    f.scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT",
        -(COMPACT_PAD + 6), GAP)
    f.scrollTrack:ClearAllPoints()
    f.scrollTrack:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -(COMPACT_HEADER_H + GAP))
    f.scrollTrack:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, GAP)

    local w, h = ClampCompact(self.opts,
        db.compactWidth or 380, db.compactHeight or 560)
    self:_SizeTo(w, h)
    if f.dragger and not db.locked then f.dragger:Show() end
    self:_AnchorProgressText("compact")
    self:UpdateSpine()
    if self.UpdateMinimizeVisual then self.UpdateMinimizeVisual() end
end

-- Full: the application window. Extracted from the old un-minimize
-- branch; must explicitly re-anchor the title bar / scroll region back
-- to the full-state anchors because compact moves them.
function ShellProto:_ApplyFullVisuals()
    local f = self.frame
    local db = self.db

    local bar = f.titleBar
    bar:Show()
    bar:SetHeight(HEADER_H)
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", f, "TOPLEFT", SIDEBAR_W, 0)
    bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    bar.pageSubtitle:Show()
    bar.pageTitle:ClearAllPoints()
    bar.pageTitle:SetPoint("TOPLEFT", bar, "TOPLEFT", CONTENT_PAD, -14)
    self:_ApplyTitleFont()
    -- Same shared pair as compact, same corner (see _ApplyCompactVisuals).
    if f.sizeBtn then f.sizeBtn:Show() end
    if f.minBtn then f.minBtn:Show() end

    f.scrollFrame:Show()
    f.scrollFrame:ClearAllPoints()
    f.scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT",
        SIDEBAR_W + CONTENT_PAD, -(HEADER_H + GAP))
    f.scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT",
        -(CONTENT_PAD + 6), FOOTER_H + GAP)
    f.scrollTrack:ClearAllPoints()
    f.scrollTrack:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -(HEADER_H + GAP))
    f.scrollTrack:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, FOOTER_H + GAP)

    f.footer:Show()
    f.navContainer:Show()
    f.sidebarBg:Show()
    f.sidebarLine:Show()
    f.brand:Show()
    f.brand.version:Show()
    if f.stripBar then f.stripBar:Hide() end
    -- searchInput stays hidden in the MVP.
    local w, h = ClampSize(self.opts,
        db.panelWidth or self.opts.defaultWidth or 980,
        db.panelHeight or self.opts.defaultHeight or 680)
    self:_SizeTo(w, h)
    if f.dragger and not db.locked then f.dragger:Show() end
    self:_AnchorProgressText("full")
    self:UpdateSpine()
    if self.UpdateMinimizeVisual then self.UpdateMinimizeVisual() end
end

-- View transitions animate the window between state geometries. The
-- chrome for the new state is applied immediately and every region is
-- anchored to the frame edges, so the content is revealed (or clipped)
-- as the window travels. Construction and the idempotent re-asserts in
-- RefreshScrollContent land instantly — SizeTo short-circuits when it is
-- already there, and _initializing covers the login collapse.
function ShellProto:_SizeTo(w, h)
    if self._initializing then
        self.frame:SetSize(w, h)
        self:UpdateSpine(w)
        return
    end
    -- The spine's segments carry absolute widths, so lay them out for
    -- the size we are travelling TO — measuring the header mid-animation
    -- would freeze them at the width we are leaving, and they would
    -- overhang the window once it arrived. Re-run on completion as well,
    -- in case the animation was interrupted or clamped.
    self:UpdateSpine(w)
    lib.SizeTo(self.frame, w, h, nil, function() self:UpdateSpine() end)
end

-- Collapse to the strip from whichever view is current, remembering
-- which one so expanding returns there rather than always to full.
function ShellProto:_Minimize()
    self.db.prevCompact = self.db.compact and true or false
    self.db.minimized = true
    self:ApplyMinimizeState()
end

function ShellProto:_Restore()
    self.db.minimized = false
    self.db.compact = self.db.prevCompact and true or false
    self:ApplyMinimizeState()
end

-- "full" | "compact" | "strip". Strip wins when both flags are set
-- (strip entered from compact); restore clears both.
function ShellProto:GetViewMode()
    if self.db.minimized then return "strip" end
    if self.db.compact then return "compact" end
    return "full"
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
    -- Convert the anchor to TOPLEFT before any resize so the window's
    -- top-left corner stays put across every state transition.
    -- db.position stays the single shared position for all three states.
    local left = f:GetLeft()
    local top = f:GetTop()
    if left and top then
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        db.position = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = left, y = top }
    end
    local mode = self:GetViewMode()
    if mode == "strip" then
        self:_ApplyMinimizedVisuals()
    else
        if mode == "compact" then
            self:_ApplyCompactVisuals()
        else
            self:_ApplyFullVisuals()
        end
        -- Width before refresh: bar fills read parent:GetWidth() at
        -- first Refresh (same ordering as the resize dragger).
        if self.scrollChild then
            self.scrollChild:SetWidth(self:_ContentWidth())
        end
        if self.opts.onRefresh then self.opts.onRefresh(self) end
    end
    if self.opts.onViewChanged then self.opts.onViewChanged(self, mode) end
end

function ShellProto:Show()
    lib.FadeIn(self.frame)
    self.db.panelShown = true
    if self.opts.onRefresh then self.opts.onRefresh(self) end
    if self.db.minimized or self.db.compact then
        self:ApplyMinimizeState()
    end
end

function ShellProto:Hide()
    -- State commits now; the frame hides when the fade finishes. Toggle
    -- reads IsShown, so a second click mid-fade re-enters Show and the
    -- fade-in cancels the fade-out (FadeIn stops the opposing group).
    self.db.panelShown = false
    lib.FadeOut(self.frame)
    -- The config dock is parented to UIParent and only anchored to the
    -- window; hide it explicitly or it outlives Close.
    if self.cfgFrame then lib.PopOut(self.cfgFrame) end
    if self.opts.onHide then self.opts.onHide(self) end
end

function ShellProto:Toggle()
    -- A frame mid-fade-out is still shown but on its way out; toggling
    -- then means "bring it back", not "close it again".
    local closing = self.frame._muiFadeOut and self.frame._muiFadeOut:IsPlaying()
    if self.frame:IsShown() and not closing then
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
function ShellProto:UpdateSpine(targetFrameW)
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
    -- targetFrameW: lay out for a size the window is animating toward
    -- rather than the one it currently has. The header spans the whole
    -- frame in compact and everything right of the sidebar in full.
    local barW = bar:GetWidth() or 0
    if targetFrameW then
        barW = self.db.compact and targetFrameW or (targetFrameW - SIDEBAR_W)
    end
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
    local pad = (self.db.compact and not self.db.minimized)
        and COMPACT_PAD or CONTENT_PAD
    local usable = barW - 2 * pad - GAP_W * (n - 1)
    local x = pad
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

-- Options live in the shared settings window (Settings.lua) so both
-- shells present an identical surface. It renders through the same
-- pooled config renderer via `.body`.
function ShellProto:BuildConfigFrame()
    if not lib.BuildSettingsWindow then
        print("|cffff8888[MidnightUI]|r Settings.lua did not load. Restart the "
            .. "game client fully — a /reload does not pick up newly added "
            .. "addon files.")
        return nil
    end
    return lib.BuildSettingsWindow(self, {
        name     = self.opts.name or "MidnightUIShell",
        title    = "Options",
        subtitle = (self.opts.title or "")
            .. (self.opts.version and (" v" .. self.opts.version) or ""),
        db       = self.db,
    })
end

function ShellProto:ToggleConfig()
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

function ShellProto:PopulateConfig(defs)
    self.pendingConfigDefs = defs
    if self._cfgInContent then
        self:RenderConfigInContent(defs)
    elseif self.cfgFrame and self.cfgFrame:IsShown() then
        self:_PopulateConfigBody(defs)
    end
end

function ShellProto:_PopulateConfigBody(defs)
    if lib._populateConfigBody then
        lib._populateConfigBody(self, defs)
    end
end

--------------------------------------------------------------------------
-- Options as a view, not a window.
--
-- The same pooled renderer draws the same defs into the main content
-- area, so a consumer can list Options alongside its own pages instead of
-- popping a second window. The two surfaces are independent render
-- targets: separate widget pools, separate content frames, separate rail,
-- separate current page — nothing a window render created can end up
-- anchored inside the content area, or the reverse.
--
-- The category rail is parented to the scroll FRAME rather than the
-- scroll child (it must not scroll with the page) and rather than the
-- window (hiding the scroll frame for the strip view has to take the
-- rail with it).
--------------------------------------------------------------------------
function ShellProto:_ContentConfigTarget()
    local target = self._cfgContentTarget
    if not target then
        local shell = self
        local scroll = self.scrollFrame
        target = {
            store       = {},
            body        = self.scrollChild,
            scrollFrame = scroll,
            railParent  = scroll,
            railAbove   = scroll,
            railTop     = { scroll, "TOPLEFT", 0, 0 },
            railBottom  = { scroll, "BOTTOMLEFT", 0, 0 },
            -- The content area is as wide as the window the player last
            -- dragged it to, and the compact view is narrower still. The
            -- renderer thins its rail and drops to one column off this
            -- number; _ContentWidth is the same authority the scroll
            -- child is sized from, so it is right before a first draw
            -- too (where GetWidth would still read 0).
            width       = function() return shell:_ContentWidth() end,
            finish      = function(totalH)
                -- Same guard the window uses: a shorter page must not
                -- leave the view scrolled past its own end.
                local maxScroll = math.max(totalH - scroll:GetHeight(), 0)
                if scroll:GetVerticalScroll() > maxScroll then
                    scroll:SetVerticalScroll(maxScroll)
                end
                shell:RefreshScrollContent(totalH)
            end,
        }
        self._cfgContentTarget = target
    end
    return target
end

function ShellProto:RenderConfigInContent(defs)
    if not lib._populateConfigBody then return end
    self._cfgInContent = true
    -- Recorded for the same reason PopulateConfig records it: if this
    -- shell ever also opened the settings window, ToggleConfig replays
    -- pendingConfigDefs, and a stale list would render there.
    self.pendingConfigDefs = defs
    lib._populateConfigBody(self, defs, self:_ContentConfigTarget())
end

-- Take the options surface back off the content area. The consumer calls
-- this before rendering one of its own pages there; without it the
-- pooled option widgets — children of the same scroll child — would
-- survive underneath the incoming list.
function ShellProto:ClearConfigContent()
    if not self._cfgInContent then return end
    self._cfgInContent = nil
    if lib._clearConfigBody then
        lib._clearConfigBody(self:_ContentConfigTarget())
    end
end

function ShellProto:IsConfigInContent()
    return self._cfgInContent and true or false
end

-- The rail is deliberately NOT a child of the scroll child, so a consumer
-- cross-fading the content area has to include it by hand. nil until the
-- first paged render.
function ShellProto:GetConfigContentRail()
    local target = self._cfgContentTarget
    return target and target.store and target.store._cfgRail or nil
end

function ShellProto:RefreshScrollContent(height)
    if self.scrollChild then
        self.scrollChild:SetHeight(math.max(height, 1))
    end
    -- Re-assert the minimized strip / compact chrome after refresh (a
    -- refresh restores neither size nor hidden regions on its own; the
    -- appliers are idempotent and cheap).
    if self.db.minimized then
        self:_ApplyMinimizedVisuals()
    elseif self.db.compact then
        self:_ApplyCompactVisuals()
    end
end

-- RenderHeader convenience wrapper (parity with PanelProto).
function ShellProto:RenderHeader(parent, yOff, opts)
    return lib.RenderCollapsibleHeader(self.pool, parent, yOff, opts, self.db, function()
        if self.opts.onRefresh then self.opts.onRefresh(self) end
    end)
end
