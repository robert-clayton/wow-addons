local lib = LibStub:GetLibrary("MidnightUI-1.0", true)
if not lib then return end

-- Settings window. Shared by both shells: PanelProto and ShellProto both
-- build their cfgFrame from here, so the options surface is identical
-- whichever shell is active.
--
-- Replaces the old side-dock, which grew to fit its content — with a
-- dozen expansions and eight modules that ran past the bottom of the
-- screen with no way to reach the end. This is a fixed window with a
-- scrolling body: the content grows, the window doesn't.
--
-- The consumer contract is unchanged: the window exposes `.body` for
-- lib._populateConfigBody to render into, and `_scrolls` tells that
-- renderer to size the scroll child rather than the window.

local WIDTH      = 480
local HEIGHT     = 620
local HEADER_H   = 46
local FOOTER_H   = 48
local PAD        = 16
local WHITE8     = "Interface\\Buttons\\WHITE8x8"

-- opts: { name, title, subtitle, db } — db persists `optionsPosition`.
function lib.BuildSettingsWindow(owner, opts)
    opts = opts or {}
    local db = opts.db or owner.db or {}
    local frameName = (opts.name or "MidnightUISettings") .. "Window"

    local f = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    f:SetSize(WIDTH, HEIGHT)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:Hide()
    f._scrolls = true

    local pos = db.optionsPosition
    if pos and pos.point then
        f:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point,
            pos.x or 0, pos.y or 0)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    -- Esc closes, like every other WoW window. Blizzard calls Hide()
    -- directly, so the fade is skipped on that path — OnHide restores
    -- the alpha an interrupted fade would otherwise have left behind.
    if frameName and UISpecialFrames then
        tinsert(UISpecialFrames, frameName)
    end
    f:SetScript("OnHide", function(self) self:SetAlpha(1) end)

    --------------------------------------------------------------------
    -- Header
    --------------------------------------------------------------------
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(HEADER_H)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local point, _, relativePoint, x, y = f:GetPoint()
        db.optionsPosition = { point = point, relativePoint = relativePoint,
            x = x, y = y }
    end)
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
    title:SetPoint("LEFT", header, "LEFT", PAD, 6)
    title:SetJustifyH("LEFT")
    title:SetText(opts.title or "Options")

    local subtitle = header:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(lib.Theme.font, lib.Theme.fontSize - 1, lib.FontFlags())
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText(opts.subtitle or "")

    --------------------------------------------------------------------
    -- Scrolling body. The renderer anchors widgets to body's edges, so
    -- the scroll child carries a real width.
    --------------------------------------------------------------------
    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -(HEADER_H + 8))
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(PAD + 6), FOOTER_H + 4)
    scroll:EnableMouseWheel(true)

    local body = CreateFrame("Frame", nil, scroll)
    body:SetWidth(WIDTH - 2 * PAD - 6)
    body:SetHeight(1)
    scroll:SetScrollChild(body)
    f.body = body
    f.scrollFrame = scroll

    local track = f:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(4)
    track:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -(HEADER_H + 8))
    track:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, FOOTER_H + 4)

    local thumb = f:CreateTexture(nil, "ARTWORK")
    thumb:SetWidth(4)
    thumb:SetTexture(WHITE8)
    thumb:Hide()

    local function UpdateScrollBar()
        local viewH = scroll:GetHeight()
        local contentH = body:GetHeight()
        if contentH <= viewH or viewH <= 0 then thumb:Hide(); return end
        thumb:Show()
        local trackH = math.max(track:GetHeight(), 1)
        local thumbH = math.max(trackH * (viewH / contentH), 20)
        local pct = math.max(0, math.min(scroll:GetVerticalScroll() / (contentH - viewH), 1))
        thumb:SetHeight(thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, -((trackH - thumbH) * pct))
    end
    f.UpdateScrollBar = UpdateScrollBar

    scroll:SetScript("OnMouseWheel", function(_, delta)
        local maxScroll = math.max(body:GetHeight() - scroll:GetHeight(), 0)
        scroll:SetVerticalScroll(
            math.max(0, math.min(scroll:GetVerticalScroll() - delta * 40, maxScroll)))
        UpdateScrollBar()
    end)
    scroll:SetScript("OnScrollRangeChanged", UpdateScrollBar)
    scroll:SetScript("OnVerticalScroll", UpdateScrollBar)

    --------------------------------------------------------------------
    -- Footer
    --------------------------------------------------------------------
    local footer = CreateFrame("Frame", nil, f)
    footer:SetHeight(FOOTER_H)
    footer:SetPoint("BOTTOMLEFT")
    footer:SetPoint("BOTTOMRIGHT")
    f.footer = footer

    local footerFill = footer:CreateTexture(nil, "BACKGROUND")
    footerFill:SetAllPoints()
    footerFill:SetTexture(WHITE8)

    local footerLine = footer:CreateTexture(nil, "ARTWORK")
    footerLine:SetHeight(1)
    footerLine:SetPoint("TOPLEFT")
    footerLine:SetPoint("TOPRIGHT")
    footerLine:SetTexture(WHITE8)

    local colors = lib.Theme.colors
    local doneBtn = lib.MakeHeaderBtn(footer, "Done",
        colors.accent, colors.btnTealHoverBg, colors.accent,
        "Close options", { width = 88, height = 30 })
    doneBtn:SetPoint("RIGHT", footer, "RIGHT", -PAD, 0)
    doneBtn:SetScript("OnClick", function() lib.PopOut(f) end)
    f.doneBtn = doneBtn

    local doneFill = doneBtn:CreateTexture(nil, "BACKGROUND")
    doneFill:SetPoint("TOPLEFT", 1, -1)
    doneFill:SetPoint("BOTTOMRIGHT", -1, 1)
    doneFill:SetTexture(WHITE8)
    doneBtn._fill = doneFill

    local closeBtn = lib.MakeHeaderBtn(header, "x",
        colors.btnCloseFg, colors.btnCloseHoverBg, colors.btnCloseHoverBd,
        "Close", { width = 20, height = 20 })
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -10, 0)
    closeBtn:SetScript("OnClick", function() lib.PopOut(f) end)

    --------------------------------------------------------------------
    -- Theme
    --------------------------------------------------------------------
    local function applyTheme()
        local th = lib.Theme
        local c = th.colors
        lib.ApplyThemedBackdrop(f, { kind = "options",
            alpha = c.optionsBg[4] or 1, borderAlpha = 1 })
        local tb = c.titlebar
        headerFill:SetColorTexture(tb[1], tb[2], tb[3], tb[4] or 1)
        footerFill:SetColorTexture(tb[1], tb[2], tb[3], tb[4] or 1)
        local ac = c.accent
        hairline:SetColorTexture(ac[1], ac[2], ac[3],
            th.titleBarBotStripeAlpha or 0.9)
        local dv = c.optionsDivider
        footerLine:SetColorTexture(dv[1], dv[2], dv[3], dv[4] or 0.06)
        title:SetFont(lib.FontBold(), th.fontSize + 6, lib.FontFlags())
        title:SetTextColor(c.title[1], c.title[2], c.title[3], c.title[4] or 1)
        subtitle:SetFont(th.font, th.fontSize - 1, lib.FontFlags())
        subtitle:SetTextColor(c.textDim[1], c.textDim[2], c.textDim[3])
        local tc = c.scrollTrack
        track:SetColorTexture(tc[1], tc[2], tc[3], tc[4])
        local st = c.scrollThumb
        thumb:SetColorTexture(st[1], st[2], st[3], st[4])
        doneFill:SetColorTexture(ac[1], ac[2], ac[3], 0.12)
    end
    applyTheme()
    lib.RegisterThemeHook(applyTheme)

    return f
end
