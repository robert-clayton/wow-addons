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

    local function paint(on)
        local c = lib.Theme.colors
        knob:ClearAllPoints()
        if on then
            local ac = c.accent
            track:SetColorTexture(ac[1], ac[2], ac[3], 0.75)
            knob:SetColorTexture(1, 1, 1, 1)
            knob:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
        else
            track:SetColorTexture(0.27, 0.27, 0.27, 0.65)
            local t = c.text
            knob:SetColorTexture(t[1], t[2], t[3], 0.5)
            knob:SetPoint("LEFT", btn, "LEFT", 2, 0)
        end
    end

    function btn:SnapToState()
        paint(opts.get and opts.get() and true or false)
    end
    btn.Refresh = btn.SnapToState

    btn:SetScript("OnClick", function()
        if opts.set and opts.get then
            opts.set(not opts.get())
        end
        btn:SnapToState()
    end)

    btn:SnapToState()
    return btn
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

    local activeBar = row:CreateTexture(nil, "ARTWORK")
    activeBar:SetWidth(2)
    activeBar:SetPoint("TOPLEFT")
    activeBar:SetPoint("BOTTOMLEFT")
    activeBar:SetTexture(WHITE8)
    activeBar:Hide()

    local activeWash = row:CreateTexture(nil, "BACKGROUND", nil, 2)
    activeWash:SetAllPoints()
    activeWash:SetTexture(WHITE8)
    activeWash:Hide()

    local hover = row:CreateTexture(nil, "BACKGROUND", nil, 3)
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0)

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

    local dot = row:CreateTexture(nil, "ARTWORK")
    dot:SetSize(8, 8)
    dot:SetTexture(WHITE8)
    dot:SetPoint("RIGHT", row, "RIGHT", -12, 0)
    dot:Hide()

    row._active = false
    row._enabled = true

    function row:Repaint()
        local th = lib.Theme
        local c = th.colors
        local ac = c.accent
        activeBar:SetColorTexture(ac[1], ac[2], ac[3], 1)
        lib.SetGradient(activeWash, "HORIZONTAL",
            { ac[1], ac[2], ac[3], 0.10 },
            { ac[1], ac[2], ac[3], 0 })
        label:SetFont(th.font, th.fontSize, lib.FontFlags())
        count:SetFont(th.font, th.fontSize - 1, lib.FontFlags())
        if self._active then
            activeBar:Show()
            activeWash:Show()
            label:SetTextColor(c.title[1], c.title[2], c.title[3], c.title[4] or 1)
            icon:SetVertexColor(ac[1], ac[2], ac[3])
        elseif self._enabled then
            activeBar:Hide()
            activeWash:Hide()
            label:SetTextColor(c.text[1], c.text[2], c.text[3], c.text[4] or 1)
            icon:SetVertexColor(0.9, 0.9, 0.9)
        else
            activeBar:Hide()
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
        hover:SetColorTexture(rh[1], rh[2], rh[3], rh[4] or 0.05)
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
        hover:SetColorTexture(1, 1, 1, 0)
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
