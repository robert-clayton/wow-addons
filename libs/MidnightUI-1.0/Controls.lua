local lib = LibStub:GetLibrary("MidnightUI-1.0", true)
if not lib then return end

-- Shell-independent control primitives for the Premium shell (and,
-- later, anywhere else). Rules shared by every control here:
--   * read lib.Theme inside the paint function — never cache color
--     values at creation
--   * no per-widget theme hooks (the hook registry is append-only);
--     owners repaint via the returned :Repaint()/:SnapToState() methods
--   * Blizzard built-in assets only (WHITE8x8 + FontStrings)

local WHITE8 = "Interface\\Buttons\\WHITE8x8"

-- MakePillToggle: an iOS-style on/off pill.
--   opts = { get, set, width = 36, height = 18 }
-- Returns a Button with :SnapToState() (re-read get(), repaint without
-- animation) and :Refresh() (alias). Knob-slide animation is a Polish-
-- phase item; MVP snaps.
function lib.MakePillToggle(parent, opts)
    opts = opts or {}
    local w = opts.width or 36
    local h = opts.height or 18

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w, h)

    local track = btn:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetTexture(WHITE8)

    local knob = btn:CreateTexture(nil, "ARTWORK")
    knob:SetSize(h - 4, h - 4)
    knob:SetTexture(WHITE8)
    -- Anchored from LEFT in both states so the travel is a pure x-offset
    -- slide (SlideTo only lerps offsets — a LEFT/RIGHT anchor swap would
    -- snap instead).
    local KNOB_OFF = w - (h - 4) - 2

    local function paint(on, instant)
        local c = lib.Theme.colors
        local tr, tg, tb, ta
        if on then
            local ac = c.accent
            tr, tg, tb, ta = ac[1], ac[2], ac[3], 0.75
            knob:SetColorTexture(1, 1, 1, 1)
        else
            local t = c.text
            tr, tg, tb, ta = 0.27, 0.27, 0.27, 0.65
            knob:SetColorTexture(t[1], t[2], t[3], 0.5)
        end
        if instant then
            lib.SetTextureAlpha(track, tr, tg, tb, ta)
        else
            lib.FadeTexture(track, tr, tg, tb, ta)
        end
        local x = on and KNOB_OFF or 2
        if instant then
            lib.StopAnims(knob)
            knob:ClearAllPoints()
            knob:SetPoint("LEFT", btn, "LEFT", x, 0)
        else
            lib.SlideTo(knob, "LEFT", btn, "LEFT", x, 0)
        end
    end

    -- SnapToState repaints without motion (theme switches, rebuilds);
    -- the click path slides.
    function btn:SnapToState()
        paint(opts.get and opts.get() and true or false, true)
    end
    btn.Refresh = btn.SnapToState

    btn:SetScript("OnClick", function()
        if opts.set and opts.get then
            opts.set(not opts.get())
        end
        paint(opts.get and opts.get() and true or false, false)
    end)

    btn:SnapToState()
    return btn
end

-- Window controls (minimize / maximize / restore-down) drawn from
-- WHITE8x8 rather than typed as glyphs: the box characters those
-- controls conventionally use are outside the Latin range the UI font
-- ships, so a text label would render as tofu. Sizing carries the
-- meaning — a big square grows the window, a small one shrinks it.
--   kind: "minimize" | "maximize" | "restore"
-- Re-callable: the same button swaps glyph as the view state changes.
function lib.ApplyWindowGlyph(btn, kind)
    if not btn then return end
    btn._glyphKind = kind
    if btn._label then btn._label:SetText("") end
    btn._glyphs = btn._glyphs or {}
    for _, t in ipairs(btn._glyphs) do t:Hide() end

    local n = 0
    local function part(w, h, point, x, y)
        n = n + 1
        local t = btn._glyphs[n]
        if not t then
            t = btn:CreateTexture(nil, "OVERLAY")
            t:SetTexture(WHITE8)
            btn._glyphs[n] = t
        end
        t:SetSize(w, h)
        t:ClearAllPoints()
        t:SetPoint(point, btn, "CENTER", x, y)
        t:Show()
        return t
    end

    -- Square outline of side `s`, centred with optional offset.
    local function box(s, ox, oy)
        local half = s / 2
        part(s, 1, "CENTER", ox, oy + half)          -- top
        part(s, 1, "CENTER", ox, oy - half)          -- bottom
        part(1, s, "CENTER", ox - half, oy)          -- left
        part(1, s, "CENTER", ox + half, oy)          -- right
    end

    if kind == "minimize" then
        part(10, 1, "CENTER", 0, -3)
    elseif kind == "maximize" then
        box(11, 0, 0)
    elseif kind == "restore" then
        box(8, -1, -1)
    end

    -- Paints every texture the button has ever created, not just this
    -- glyph's: the hook is registered once but the glyph can change, and
    -- the registry is append-only.
    local function paint()
        local c = btn._fgColor or lib.Theme.colors.btnTealFg
        for _, t in ipairs(btn._glyphs) do
            t:SetColorTexture(c[1], c[2], c[3], 1)
        end
    end
    paint()
    if not btn._glyphHooked then
        btn._glyphHooked = true
        lib.RegisterThemeHook(paint)
    end
end

-- Where a nav row's top edge sits relative to the container's, which is
-- the one coordinate the indicator travels in. Most rows anchor to the
-- container's TOP edge and their own y offset is already that number; a
-- row pinned to the container's BOTTOM edge (so it holds its place as
-- rows above it come and go) has to be converted, or the indicator would
-- travel to y = 0 and sit at the top of the list.
--
-- A TOP-anchored row already carries the answer in its own anchor, and
-- reading it back is exact the moment it is written: the sidebar
-- re-anchors its rows and then asks for the selected one's offset inside
-- the same layout pass, so the anchor is the only source guaranteed to
-- describe where the row is about to be rather than where it was. Such a
-- row does not move under a resize either.
--
-- Only the BOTTOM-anchored case needs converting, and the container's
-- height is the one term that moves it. Derive from that height rather
-- than from resolved rects: a resize is applied over many frames (SizeTo
-- lerps SetSize), so a rect sampled during one describes the size being
-- left, not the one being travelled to — the same trap ShellProto's
-- UpdateSpine(targetW) exists to avoid. `containerH` is the height to
-- resolve against; callers that have the authoritative one (OnSizeChanged
-- hands it over) pass it, everyone else gets the live measurement.
-- Live rects stay the fallback for a row anchored to something other than
-- the container, where the height math does not apply.
local function rowTopOffset(container, row, containerH)
    local _, relTo, relPoint, _, y = row:GetPoint()
    if type(relPoint) == "string" and not relPoint:find("BOTTOM") then
        return y or 0
    end
    if relTo and relTo ~= container then
        local rowTop, containerTop = row:GetTop(), container:GetTop()
        if rowTop and containerTop then return rowTop - containerTop end
    end
    local h = containerH or container:GetHeight() or 0
    return (y or 0) - (h - (row:GetHeight() or 0))
end

-- MakeNavIndicator: the sidebar's single accent bar. One shared bar that
-- travels to the selected row reads as one object moving; per-row bars
-- blinking on and off read as two unrelated events. A Frame, not a
-- texture, so the travel can use a native Translation.
--   :MoveTo(row, instant) — slide to a nav row (nil hides the bar)
--   :Repaint()            — re-read the theme accent
-- The bar always anchors TOPLEFT-to-container whichever edge the row
-- itself is pinned to: SlideTo only lerps offsets, so swapping the
-- anchor point per row would snap instead of travelling.
function lib.MakeNavIndicator(container)
    local bar = CreateFrame("Frame", nil, container)
    bar:SetWidth(2)
    bar:SetHeight(32)
    bar:Hide()

    local tex = bar:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture(WHITE8)
    bar._tex = tex

    function bar:Repaint()
        local ac = lib.Theme.colors.accent
        tex:SetColorTexture(ac[1], ac[2], ac[3], 1)
    end

    -- Place the bar with no travel, against a specific container height.
    -- Stops the slide only: a re-seat can land mid fade-in (the bar's
    -- first appearance during a window animation), and StopAnims would
    -- take the fade with it and strand the bar at alpha 0.
    function bar:_Seat(row, containerH)
        local y = rowTopOffset(container, row, containerH)
        lib.StopSlide(self)
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", container, "TOPLEFT", 0, y or 0)
    end

    function bar:MoveTo(row, instant)
        if not row then
            self._row = nil
            lib.StopAnims(self)
            self:Hide()
            return
        end
        self._row = row
        self:SetHeight(row:GetHeight())
        -- First appearance has nowhere to travel from: place it, fade in.
        if not self:IsShown() then
            self:_Seat(row)
            lib.FadeIn(self)
            return
        end
        if instant then
            self:_Seat(row)
        else
            lib.SlideTo(self, "TOPLEFT", container, "TOPLEFT", 0,
                rowTopOffset(container, row) or 0)
        end
    end

    -- A bottom-anchored row's offset is a function of the container's
    -- height, so the bar has to be re-seated every time that height moves
    -- — and the container is the only place that hears about all of them.
    -- A window resize animates SetSize over many frames, so a re-seat
    -- driven from the START of one (ApplyMinimizeState fires its refresh
    -- before SizeTo has moved anything) resolves against the height being
    -- left: restoring from the 30px strip would seat the bar above the
    -- sidebar entirely, and nothing would correct it until an unrelated
    -- layout change. Watching the container catches every intermediate
    -- frame and the final one, and covers the drag-resize path for free.
    -- Top-anchored rows are height-independent, so this is a no-op for
    -- them and never interrupts a travel in progress.
    container:HookScript("OnSizeChanged", function(_, _, h)
        local row = bar._row
        if not row or not bar:IsShown() then return end
        local _, _, relPoint = row:GetPoint()
        if type(relPoint) == "string" and relPoint:find("BOTTOM") then
            bar:_Seat(row, h)
        end
    end)

    bar:Repaint()
    return bar
end

-- MakeNavRow: one sidebar navigation row (the Premium tab analog).
--   opts = { icon, label, onClick, onRightClick, tooltip }
-- tooltip is a string or function(row, GameTooltip).
-- Returns a full-width Button with:
--   :SetActive(bool)    — accent bar + wash + title-colored label
--   :SetEnabled(bool)   — disabled rows desaturate and show a dim dot
--   :SetCounts(c, t)    — right-aligned "c / t" (nil hides the count)
--   :Repaint()          — re-read lib.Theme (owner calls on theme switch)
-- Generic: no consumer references; behavior arrives through opts.
function lib.MakeNavRow(parent, opts)
    opts = opts or {}
    local theme = lib.Theme

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(32)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- No per-row accent bar: the sidebar owns one shared indicator that
    -- travels between rows (lib.MakeNavIndicator).
    local activeWash = row:CreateTexture(nil, "BACKGROUND", nil, 2)
    activeWash:SetAllPoints()
    activeWash:SetTexture(WHITE8)
    activeWash:Hide()

    local hover = row:CreateTexture(nil, "BACKGROUND", nil, 3)
    hover:SetAllPoints()
    lib.SetTextureAlpha(hover, 1, 1, 1, 0)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("LEFT", row, "LEFT", 14, 0)
    if opts.icon then icon:SetTexture(opts.icon) end

    -- Fonts assigned before SetText (SetText requires a font).
    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(theme.font, theme.fontSize, lib.FontFlags())
    label:SetPoint("LEFT", row, "LEFT", 40, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -56, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetText(opts.label or "")

    local count = row:CreateFontString(nil, "OVERLAY")
    count:SetFont(theme.font, theme.fontSize - 1, lib.FontFlags())
    count:SetPoint("RIGHT", row, "RIGHT", -12, 0)

    -- Disabled marker: small and quiet — an 8px square reads as a
    -- rendering bug, a 4px tick reads as "switched off".
    local dot = row:CreateTexture(nil, "ARTWORK")
    dot:SetSize(4, 4)
    dot:SetTexture(WHITE8)
    dot:SetPoint("RIGHT", row, "RIGHT", -14, 0)
    dot:Hide()

    row._active = false
    row._enabled = true

    function row:Repaint()
        local th = lib.Theme
        local c = th.colors
        local ac = c.accent
        lib.SetGradient(activeWash, "HORIZONTAL",
            { ac[1], ac[2], ac[3], 0.10 },
            { ac[1], ac[2], ac[3], 0 })
        label:SetFont(th.font, th.fontSize, lib.FontFlags())
        count:SetFont(th.font, th.fontSize - 1, lib.FontFlags())
        if self._active then
            activeWash:Show()
            label:SetTextColor(c.title[1], c.title[2], c.title[3], c.title[4] or 1)
            icon:SetVertexColor(ac[1], ac[2], ac[3])
        elseif self._enabled then
            activeWash:Hide()
            label:SetTextColor(c.text[1], c.text[2], c.text[3], c.text[4] or 1)
            icon:SetVertexColor(0.9, 0.9, 0.9)
        else
            activeWash:Hide()
            label:SetTextColor(c.textDim[1], c.textDim[2], c.textDim[3])
            icon:SetVertexColor(0.7, 0.7, 0.7)
        end
        if icon.SetDesaturated then icon:SetDesaturated(not self._enabled) end
        if self._enabled then
            dot:Hide()
            if self._c and self._t then
                count:SetText(self._c .. " / " .. self._t)
                count:SetTextColor(lib.CountColor(self._c, self._t))
                count:Show()
            else
                count:Hide()
            end
        else
            count:Hide()
            local td = c.textDim
            dot:SetColorTexture(td[1], td[2], td[3], 0.6)
            dot:Show()
        end
    end

    function row:SetActive(b)
        self._active = b and true or false
        self:Repaint()
    end

    function row:SetEnabled(b)
        self._enabled = b and true or false
        self:Repaint()
    end

    function row:SetCounts(c, t)
        self._c, self._t = c, t
        self:Repaint()
    end

    row:SetScript("OnEnter", function(s)
        local rh = lib.Theme.colors.rowHover
        lib.FadeTexture(hover, rh[1], rh[2], rh[3], rh[4] or 0.05, 0.08)
        local tt = opts.tooltip
        if type(tt) == "string" then
            GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
            GameTooltip:SetText(tt)
            GameTooltip:Show()
        elseif type(tt) == "function" then
            GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
            tt(s, GameTooltip)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function()
        local rh = lib.Theme.colors.rowHover
        lib.FadeTexture(hover, rh[1], rh[2], rh[3], 0, 0.12)
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function(s, btn)
        if btn == "RightButton" then
            if opts.onRightClick then opts.onRightClick(s) end
        else
            if opts.onClick then opts.onClick(s) end
        end
    end)

    row:Repaint()
    return row
end
