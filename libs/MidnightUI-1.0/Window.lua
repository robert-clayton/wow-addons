local lib = LibStub:GetLibrary("MidnightUI-1.0", true)
if not lib then return end

-- Standalone window factory.
--
-- The chrome every free-floating window in this UI shares: a draggable
-- header carrying title + subtitle and a close button, an optional
-- scrolling body, an optional footer strip for action buttons, a saved
-- position, Escape-to-close, PopIn/PopOut open/close motion, and one
-- theme hook that repaints the lot.
--
-- Settings.lua was the first window to grow all of that; the Collection
-- Inspector needs the same shell, so it lives here instead of being
-- copied. lib.BuildSettingsWindow is now a thin caller of this factory
-- and its external contract is unchanged (see Settings.lua).
--
-- House rules honored here (each one is a bug we already shipped once):
--   * FontStrings get their font BEFORE SetText, or the string is lost.
--   * The header is a full-width mouse-enabled drag surface, so the
--     close button is a CHILD of the header, not a sibling — a sibling
--     at the same frame level never receives the click.
--   * Textures painted here are never faded, so a plain SetColorTexture
--     is safe; anything that WILL be faded must be seeded through
--     lib.SetTextureAlpha (SetColorTexture's alpha cannot be read back).
--   * Resizes go through SetWindowSize, which defers out of combat.
--   * Motion goes through lib.PopIn / lib.PopOut, which already respect
--     lib.animEnabled.

local WIDTH    = 480
local HEIGHT   = 620
local HEADER_H = 46
local FOOTER_H = 48
local PAD      = 16
local BTN_GAP  = 8
local WHITE8   = "Interface\\Buttons\\WHITE8x8"

-- Esc-to-close is a global list; a window rebuilt under the same name
-- must not stack duplicate entries.
local function registerSpecialFrame(frameName)
    if not frameName or not UISpecialFrames then return end
    for i = 1, #UISpecialFrames do
        if UISpecialFrames[i] == frameName then return end
    end
    tinsert(UISpecialFrames, frameName)
end

-- lib.CreateWindow(opts) -> window object
--
-- opts:
--   name          global frame name (nil = anonymous). Also seeds posKey
--                 and enables Escape-to-close.
--   title         header title text            (default "")
--   subtitle      header sub-line text         (default "")
--   width/height  frame size                   (default 480 x 620)
--   db            table the saved position is written to (default {})
--   posKey        field in db holding the position
--                 (default "<name>Position" — two windows must never
--                 share one key or they fight over the same anchor)
--   scroll        false for a plain (non-scrolling) body (default true)
--   footerHeight  0 for no footer strip        (default 48)
--   headerHeight  default 46
--   pad           body inset                   (default 16)
--   strata        frame strata                 (default "HIGH")
--   backdropKind  ApplyThemedBackdrop kind     (default "options")
--   closeButton   false to omit the header "x" (default true)
--   onClose       called after the window hides
--
-- The returned object exposes:
--   .frame .body .header .footer .scrollFrame .buttons
--   :SetTitle(title, subtitle)
--   :AddFooterButton(label, opts, onClick) -> Button
--   :Open() :Close([onComplete]) :Toggle() :IsShown()
--   :UpdateScrollBar()
--   :SetWindowSize(w, h[, animate])
--   :Repaint()
--
-- The same handles are mirrored onto .frame (frame.body, frame.header,
-- frame.footer, frame.scrollFrame, frame.UpdateScrollBar, frame._scrolls,
-- frame._window) so a caller holding only the frame has everything the
-- config renderer needs.
function lib.CreateWindow(opts)
    opts = opts or {}
    local db         = opts.db or {}
    local frameName  = opts.name
    local posKey     = opts.posKey or ((frameName or "MidnightUIWindow") .. "Position")
    local width      = opts.width or WIDTH
    local height     = opts.height or HEIGHT
    local headerH    = opts.headerHeight or HEADER_H
    local footerH    = opts.footerHeight or FOOTER_H
    local pad        = opts.pad or PAD
    local scrolls    = opts.scroll ~= false
    local wantsClose = opts.closeButton ~= false

    -- Gap between the body's bottom edge and the frame bottom: the
    -- footer strip plus 4px, or a plain pad when there is no footer.
    local bottomGap = footerH > 0 and (footerH + 4) or pad

    local win = { buttons = {} }

    local f = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    f:SetSize(width, height)
    f:SetFrameStrata(opts.strata or "HIGH")
    f:SetClampedToScreen(opts.clampToScreen ~= false)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:Hide()
    win.frame = f
    f._window = win

    local pos = db[posKey]
    if pos and pos.point then
        f:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point,
            pos.x or 0, pos.y or 0)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    -- Esc closes, like every other WoW window. Blizzard calls Hide()
    -- directly, so the fade is skipped on that path — OnHide restores
    -- the alpha an interrupted fade would otherwise have left behind.
    registerSpecialFrame(frameName)
    f:SetScript("OnHide", function(self)
        self:SetAlpha(1)
        if opts.onClose then opts.onClose(win) end
    end)

    --------------------------------------------------------------------
    -- Header
    --------------------------------------------------------------------
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(headerH)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local point, _, relativePoint, x, y = f:GetPoint()
        db[posKey] = { point = point, relativePoint = relativePoint,
            x = x, y = y }
    end)
    win.header = header
    f.header = header

    local headerFill = header:CreateTexture(nil, "BACKGROUND")
    headerFill:SetAllPoints()
    headerFill:SetTexture(WHITE8)

    local hairline = header:CreateTexture(nil, "ARTWORK")
    hairline:SetHeight(1)
    hairline:SetPoint("BOTTOMLEFT")
    hairline:SetPoint("BOTTOMRIGHT")
    hairline:SetTexture(WHITE8)

    -- Font before SetText: a FontString with no font set drops the
    -- string instead of storing it for later.
    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont(lib.FontBold(), lib.Theme.fontSize + 6, lib.FontFlags())
    title:SetPoint("LEFT", header, "LEFT", pad, 6)
    title:SetJustifyH("LEFT")
    title:SetText(opts.title or "")

    local subtitle = header:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(lib.Theme.font, lib.Theme.fontSize - 1, lib.FontFlags())
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText(opts.subtitle or "")
    win.titleFS, win.subtitleFS = title, subtitle

    --------------------------------------------------------------------
    -- Body. Scrolling by default: the content grows, the window doesn't.
    -- A renderer anchors widgets to the body's edges, so the body always
    -- carries a real width.
    --------------------------------------------------------------------
    local body, scroll, track, thumb
    local function bodyWidth()
        return f:GetWidth() - 2 * pad - (scrolls and 6 or 0)
    end

    if scrolls then
        scroll = CreateFrame("ScrollFrame", nil, f)
        scroll:SetPoint("TOPLEFT", f, "TOPLEFT", pad, -(headerH + 8))
        scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(pad + 6), bottomGap)
        scroll:EnableMouseWheel(true)

        body = CreateFrame("Frame", nil, scroll)
        body:SetWidth(bodyWidth())
        body:SetHeight(1)
        scroll:SetScrollChild(body)

        track = f:CreateTexture(nil, "BACKGROUND")
        track:SetWidth(4)
        track:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -(headerH + 8))
        track:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, bottomGap)

        thumb = f:CreateTexture(nil, "ARTWORK")
        thumb:SetWidth(4)
        thumb:SetTexture(WHITE8)
        thumb:Hide()
    else
        body = CreateFrame("Frame", nil, f)
        body:SetPoint("TOPLEFT", f, "TOPLEFT", pad, -(headerH + 8))
        body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -pad, bottomGap)
    end
    win.body = body
    win.scrollFrame = scroll
    f.body = body
    f.scrollFrame = scroll
    f._scrolls = scrolls or nil

    -- Plain function, not a method: lib._populateConfigBody calls it as
    -- `cfgFrame.UpdateScrollBar()` with no self.
    local UpdateScrollBar
    if scrolls then
        local syncScrollHit
        UpdateScrollBar = function()
            local viewH = scroll:GetHeight()
            local contentH = body:GetHeight()
            if contentH <= viewH or viewH <= 0 then
                thumb:Hide()
                if syncScrollHit then syncScrollHit() end
                return
            end
            thumb:Show()
            local trackH = math.max(track:GetHeight(), 1)
            local thumbH = math.max(trackH * (viewH / contentH), 20)
            local pct = math.max(0, math.min(scroll:GetVerticalScroll() / (contentH - viewH), 1))
            thumb:SetHeight(thumbH)
            thumb:ClearAllPoints()
            thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, -((trackH - thumbH) * pct))
            if syncScrollHit then syncScrollHit() end
        end

        -- Textures cannot take mouse input; overlay frames that can.
        syncScrollHit = lib.AttachScrollDrag and lib.AttachScrollDrag(scroll, body, thumb, track, UpdateScrollBar)

        scroll:SetScript("OnMouseWheel", function(_, delta)
            local maxScroll = math.max(body:GetHeight() - scroll:GetHeight(), 0)
            scroll:SetVerticalScroll(
                math.max(0, math.min(scroll:GetVerticalScroll() - delta * 40, maxScroll)))
            UpdateScrollBar()
        end)
        scroll:SetScript("OnScrollRangeChanged", UpdateScrollBar)
        scroll:SetScript("OnVerticalScroll", UpdateScrollBar)
    else
        UpdateScrollBar = function() end
    end
    f.UpdateScrollBar = UpdateScrollBar

    --------------------------------------------------------------------
    -- Footer
    --------------------------------------------------------------------
    local footer, footerFill, footerLine
    if footerH > 0 then
        footer = CreateFrame("Frame", nil, f)
        footer:SetHeight(footerH)
        footer:SetPoint("BOTTOMLEFT")
        footer:SetPoint("BOTTOMRIGHT")

        footerFill = footer:CreateTexture(nil, "BACKGROUND")
        footerFill:SetAllPoints()
        footerFill:SetTexture(WHITE8)

        footerLine = footer:CreateTexture(nil, "ARTWORK")
        footerLine:SetHeight(1)
        footerLine:SetPoint("TOPLEFT")
        footerLine:SetPoint("TOPRIGHT")
        footerLine:SetTexture(WHITE8)
    end
    win.footer = footer
    f.footer = footer

    --------------------------------------------------------------------
    -- Theme. One hook per window; it walks the button list so buttons
    -- added after creation still repaint (the hook registry is
    -- append-only, so per-button hooks would accumulate).
    --------------------------------------------------------------------
    local function applyTheme()
        local th = lib.Theme
        local c = th.colors
        lib.ApplyThemedBackdrop(f, { kind = opts.backdropKind or "options",
            alpha = c.optionsBg[4] or 1, borderAlpha = 1 })
        local tb = c.titlebar
        headerFill:SetColorTexture(tb[1], tb[2], tb[3], tb[4] or 1)
        local ac = c.accent
        hairline:SetColorTexture(ac[1], ac[2], ac[3],
            th.titleBarBotStripeAlpha or 0.9)
        title:SetFont(lib.FontBold(), th.fontSize + 6, lib.FontFlags())
        title:SetTextColor(c.title[1], c.title[2], c.title[3], c.title[4] or 1)
        subtitle:SetFont(th.font, th.fontSize - 1, lib.FontFlags())
        subtitle:SetTextColor(c.textDim[1], c.textDim[2], c.textDim[3])
        if footerFill then
            footerFill:SetColorTexture(tb[1], tb[2], tb[3], tb[4] or 1)
            local dv = c.optionsDivider
            footerLine:SetColorTexture(dv[1], dv[2], dv[3], dv[4] or 0.06)
        end
        if track then
            local tc = c.scrollTrack
            track:SetColorTexture(tc[1], tc[2], tc[3], tc[4])
            local st = c.scrollThumb
            thumb:SetColorTexture(st[1], st[2], st[3], st[4])
        end
        for _, btn in ipairs(win.buttons) do
            if btn._fill then
                btn._fill:SetColorTexture(ac[1], ac[2], ac[3], 0.12)
            end
        end
    end
    function win:Repaint() applyTheme() end
    applyTheme()
    lib.RegisterThemeHook(applyTheme)

    --------------------------------------------------------------------
    -- API
    --------------------------------------------------------------------
    function win:SetTitle(t, sub)
        title:SetText(t or "")
        subtitle:SetText(sub or "")
    end

    function win:UpdateScrollBar()
        UpdateScrollBar()
    end

    function win:IsShown()
        return f:IsShown()
    end

    function win:Open()
        lib.PopIn(f)
        UpdateScrollBar()
    end

    function win:Close(onComplete)
        lib.PopOut(f, nil, onComplete)
    end

    function win:Toggle()
        -- A frame mid-fade-out is still shown but on its way out;
        -- toggling then means "bring it back", not "close it again".
        local closing = f._muiFadeOut and f._muiFadeOut:IsPlaying()
        if f:IsShown() and not closing then self:Close() else self:Open() end
    end

    -- Footer buttons stack inward from the right edge by default
    -- (bopts.side == "LEFT" stacks from the left instead).
    --   bopts = { width, height, tooltip, primary, side,
    --             fgColor, hoverBg, hoverBd }
    -- `primary` paints the accent fill the Options window's Done button
    -- uses; the fill is repainted by this window's theme hook.
    function win:AddFooterButton(label, bopts, onClick)
        if not footer then return nil end
        bopts = bopts or {}
        local c = lib.Theme.colors
        local fg     = bopts.fgColor or (bopts.primary and c.accent or c.btnTealFg)
        local hovBg  = bopts.hoverBg or c.btnTealHoverBg
        local hovBd  = bopts.hoverBd or (bopts.primary and c.accent or c.btnTealHoverBd)

        local btn = lib.MakeHeaderBtn(footer, label, fg, hovBg, hovBd,
            bopts.tooltip, { width = bopts.width or 88, height = bopts.height or 30 })

        local side = bopts.side == "LEFT" and "LEFT" or "RIGHT"
        local prev
        for i = #self.buttons, 1, -1 do
            if self.buttons[i]._side == side then prev = self.buttons[i]; break end
        end
        if prev then
            if side == "RIGHT" then
                btn:SetPoint("RIGHT", prev, "LEFT", -BTN_GAP, 0)
            else
                btn:SetPoint("LEFT", prev, "RIGHT", BTN_GAP, 0)
            end
        else
            btn:SetPoint(side, footer, side, side == "RIGHT" and -pad or pad, 0)
        end
        btn._side = side

        if bopts.primary then
            local fill = btn:CreateTexture(nil, "BACKGROUND")
            fill:SetPoint("TOPLEFT", 1, -1)
            fill:SetPoint("BOTTOMRIGHT", -1, 1)
            fill:SetTexture(WHITE8)
            local ac = lib.Theme.colors.accent
            fill:SetColorTexture(ac[1], ac[2], ac[3], 0.12)
            btn._fill = fill
        end

        if onClick then btn:SetScript("OnClick", onClick) end
        self.buttons[#self.buttons + 1] = btn
        return btn
    end

    -- Resize. Any anchor/size change must sit out combat: the deferral
    -- pattern matches Shell.lua's ApplyMinimizeState.
    function win:SetWindowSize(w, h, animate)
        if InCombatLockdown and InCombatLockdown() then
            -- The pending target lives on the window, not in the
            -- watcher's closure: callers resize repeatedly during
            -- combat (the Inspector re-renders per peer added), and the
            -- state that matters is the last one asked for, not the
            -- first one that happened to arm the watcher.
            self._pendingSize = { w = w, h = h, animate = animate }
            if not self._resizeQueued then
                self._resizeQueued = true
                local watcher = CreateFrame("Frame")
                watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
                watcher:SetScript("OnEvent", function(wf)
                    wf:UnregisterAllEvents()
                    self._resizeQueued = nil
                    local p = self._pendingSize
                    self._pendingSize = nil
                    if p then self:SetWindowSize(p.w, p.h, p.animate) end
                end)
            end
            return
        end
        self._pendingSize = nil
        local function done()
            if body and scrolls then body:SetWidth(bodyWidth()) end
            UpdateScrollBar()
        end
        if animate then
            lib.SizeTo(f, w, h, nil, done)
        else
            f:SetSize(w, h)
            done()
        end
    end

    -- Header close button. A CHILD of the header: the header is a
    -- full-cover mouse-enabled drag surface, and a sibling button at the
    -- same frame level would never see the click.
    if wantsClose then
        local colors = lib.Theme.colors
        local closeBtn = lib.MakeHeaderBtn(header, "x",
            colors.btnCloseFg, colors.btnCloseHoverBg, colors.btnCloseHoverBd,
            "Close", { width = 20, height = 20 })
        closeBtn:SetPoint("RIGHT", header, "RIGHT", -10, 0)
        closeBtn:SetScript("OnClick", function() win:Close() end)
        win.closeBtn = closeBtn
        f.closeBtn = closeBtn
    end

    return win
end
