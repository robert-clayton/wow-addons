local lib = LibStub:GetLibrary("MidnightUI-1.0", true)
if not lib then return end

local theme = lib.Theme

local WHITE8 = "Interface\\Buttons\\WHITE8x8"

-- Paged options layout.
--   RAIL_W      width of the category rail down the left of the options
--               surface (the settings window, or a shell's content area)
--   RAIL_GUTTER gap between the rail and the first content column
--   RAIL_ROW_H  one rail row
--   COL_GAP     half-gutter between the two content columns
local RAIL_W      = 130
local RAIL_GUTTER = 14
local RAIL_ROW_H  = 28
local COL_GAP     = 8

-- Narrow-surface fallbacks, used only by a target that reports its own
-- width (see `width` in the target contract). The settings window is a
-- fixed 680 and never reports one, so it always gets the full rail and
-- two columns — exactly what it rendered before these existed.
--   RAIL_NARROW  below this surface width the rail is a bad deal: 144px
--                of a compact shell's ~290 leaves two columns of ~65
--   RAIL_MIN_W   the rail still has to hold "Appearance" on one line
--   COL_MIN_W    below this per column, one full-width column reads
--                better than two cramped ones
local RAIL_NARROW = 420
local RAIL_MIN_W  = 84
local COL_MIN_W   = 150

-- File-local widget helpers
local function OptionsDivider(body, yOff)
    local fr = CreateFrame("Frame", nil, body, "BackdropTemplate")
    fr:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    fr:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, yOff)
    fr:SetHeight(1)
    fr:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    local dc = theme.colors.optionsDivider
    fr:SetBackdropColor(dc[1], dc[2], dc[3], dc[4])
    return yOff - 6
end

local function OptionsSectionLabel(body, yOff, text)
    local fs = body:CreateFontString(nil, "OVERLAY")
    fs:SetFont(theme.font, 9, lib.FontFlags())
    fs:SetText("|cff888888" .. text .. "|r")
    fs:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    return yOff - 14
end

local function OptionsCheckbox(body, yOff, label, getVal, setVal, onRefresh)
    local fr = CreateFrame("CheckButton", nil, body, "UICheckButtonTemplate")
    fr:SetSize(20, 20)
    fr:SetPoint("TOPLEFT", body, "TOPLEFT", 6, yOff)
    fr:SetChecked(getVal())
    fr:EnableMouse(true)
    fr:SetScript("OnClick", function(s)
        setVal(s:GetChecked())
        if onRefresh then onRefresh() end
    end)
    local lbl = fr:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(theme.font, 10, lib.FontFlags())
    lbl:SetText(label)
    lbl:SetTextColor(0.88, 0.88, 0.88)
    lbl:SetPoint("LEFT", fr, "RIGHT", 0, 0)
    return yOff - 22
end

local function OptionsSlider(body, yOff, label, min, max, step, getVal, setVal, fillR, fillG, fillB)
    local lbl = body:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(theme.font, 9, lib.FontFlags())
    lbl:SetText("|cff888888" .. label .. "|r")
    lbl:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    yOff = yOff - 14
    local bg = CreateFrame("Frame", nil, body, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    bg:SetSize(138, 14)
    bg:SetBackdrop(theme.backdrop)
    local slc = theme.colors.optionsSliderBg
    bg:SetBackdropColor(slc[1], slc[2], slc[3], slc[4])
    bg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    local fill = bg:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", bg, "LEFT", 2, 0)
    fill:SetHeight(10)
    fill:SetColorTexture(fillR, fillG, fillB, 0.85)
    local valBox = CreateFrame("Frame", nil, body, "BackdropTemplate")
    valBox:SetPoint("LEFT", bg, "RIGHT", 4, 0)
    valBox:SetSize(44, 14)
    valBox:SetBackdrop(theme.backdrop)
    valBox:SetBackdropColor(0, 0, 0, 0.5)
    valBox:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    local valTxt = valBox:CreateFontString(nil, "OVERLAY")
    valTxt:SetFont(theme.font, 9, lib.FontFlags())
    valTxt:SetPoint("CENTER")
    local function UpdateVis(v)
        local pct = (v - min) / (max - min)
        fill:SetWidth(math.max(2, (bg:GetWidth() - 4) * pct))
        valTxt:SetText(string.format("%.2f", v):gsub("%.?0+$", ""))
    end
    local sl = CreateFrame("Slider", nil, bg)
    sl:SetAllPoints(bg)
    sl:SetMinMaxValues(min, max)
    sl:SetValueStep(step)
    sl:SetObeyStepOnDrag(true)
    sl:SetOrientation("HORIZONTAL")
    sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local th = sl:GetThumbTexture()
    if th then th:Hide() end
    sl:SetValue(getVal())
    UpdateVis(getVal())
    sl:SetScript("OnValueChanged", function(_, v) UpdateVis(v) end)
    sl:SetScript("OnMouseUp", function(s) setVal(s:GetValue()) end)
    return yOff - 18
end

-- WoW frames can't be GC'd. Pool each widget type by index so toggling a
-- setting 50 times in a session doesn't leak 50 sets of CheckButtons.
--
-- `store` is the render TARGET's own state table, not the panel: the same
-- defs can render into the settings window or into a shell's main content
-- area, and a widget created under one parent can never be re-anchored
-- into the other. One pool set per target keeps them disjoint — see the
-- target builders at the bottom of this file.
local function getPool(store)
    if not store._cfgPools then
        store._cfgPools = {
            section  = { items = {}, idx = 0 },
            divider  = { items = {}, idx = 0 },
            checkbox = { items = {}, idx = 0 },
            slider   = { items = {}, idx = 0 },
            dropdown = { items = {}, idx = 0 },
            button   = { items = {}, idx = 0 },
            railrow  = { items = {}, idx = 0 },
        }
    end
    return store._cfgPools
end

-- Every pool item lists the regions it owns at the top level in `_hide`.
-- Hiding only `frame`/`fs` used to be enough because every widget type
-- rendered on every pass; with pages a whole type can go unused, and a
-- slider's caption / value box (siblings of the track, not children)
-- would have stayed on screen after switching to a page without sliders.
local function hideWidget(w)
    for _, r in ipairs(w._hide) do r:Hide() end
end

local function poolReset(store)
    for _, pool in pairs(getPool(store)) do
        pool.idx = 0
        for _, w in ipairs(pool.items) do hideWidget(w) end
    end
end

local function poolHideExtras(store)
    for _, pool in pairs(getPool(store)) do
        for i = pool.idx + 1, #pool.items do
            hideWidget(pool.items[i])
        end
    end
end

-- Acquire-or-create handlers per widget type
local function acquireSection(store, body, yOff, text)
    local pool = getPool(store).section
    pool.idx = pool.idx + 1
    local w = pool.items[pool.idx]
    if not w then
        local fs = body:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, 9, lib.FontFlags())
        w = { fs = fs, _hide = { fs } }
        pool.items[pool.idx] = w
        if lib.RegisterThemeHook then
            lib.RegisterThemeHook(function()
                fs:SetFont(theme.font, 9, lib.FontFlags())
            end)
        end
    end
    w.fs:ClearAllPoints()
    w.fs:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    w.fs:SetText("|cff888888" .. text .. "|r")
    w.fs:Show()
    return yOff - 14
end

local function acquireDivider(store, body, yOff)
    local pool = getPool(store).divider
    pool.idx = pool.idx + 1
    local w = pool.items[pool.idx]
    if not w then
        local fr = CreateFrame("Frame", nil, body, "BackdropTemplate")
        fr:SetHeight(1)
        fr:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        local dc = theme.colors.optionsDivider
        fr:SetBackdropColor(dc[1], dc[2], dc[3], dc[4])
        w = { frame = fr, _hide = { fr } }
        pool.items[pool.idx] = w
        if lib.RegisterThemeHook then
            lib.RegisterThemeHook(function()
                local dc2 = theme.colors.optionsDivider
                fr:SetBackdropColor(dc2[1], dc2[2], dc2[3], dc2[4])
            end)
        end
    end
    w.frame:ClearAllPoints()
    w.frame:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    w.frame:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, yOff)
    w.frame:Show()
    return yOff - 6
end

-- `parent` is the stable creation parent (the content frame); `col` is
-- the frame the row anchors into — the content frame for a full-width
-- row, or one of the two half-width column frames. Returns the row
-- HEIGHT (positive), because a two-column row advances by the taller of
-- its two halves, not by whatever the last one rendered.
local function acquireCheckbox(store, parent, col, yOff, def)
    local pool = getPool(store).checkbox
    pool.idx = pool.idx + 1
    local w = pool.items[pool.idx]
    if not w then
        local fr = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        fr:SetSize(20, 20)
        fr:EnableMouse(true)
        local lbl = fr:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(theme.font, 10, lib.FontFlags())
        lbl:SetTextColor(0.88, 0.88, 0.88)
        -- Anchor both LEFT and RIGHT so long labels wrap inside the
        -- options column instead of running off the right edge. Top
        -- alignment keeps the first line lined up with the checkbox.
        lbl:SetPoint("TOPLEFT", fr, "TOPRIGHT", 4, -2)
        lbl:SetWordWrap(true)
        lbl:SetJustifyH("LEFT")
        lbl:SetJustifyV("TOP")
        local upBtn = CreateFrame("Button", nil, fr, "UIPanelButtonTemplate")
        upBtn:SetSize(20, 16)
        upBtn:SetText("^")
        upBtn:Hide()
        local dnBtn = CreateFrame("Button", nil, fr, "UIPanelButtonTemplate")
        dnBtn:SetSize(20, 16)
        dnBtn:SetText("v")
        dnBtn:Hide()
        w = { frame = fr, lbl = lbl, upBtn = upBtn, dnBtn = dnBtn, _hide = { fr } }
        pool.items[pool.idx] = w
        if lib.RegisterThemeHook then
            lib.RegisterThemeHook(function()
                lbl:SetFont(theme.font, 10, lib.FontFlags())
            end)
        end
    end
    w.frame:ClearAllPoints()
    w.frame:SetPoint("TOPLEFT", col, "TOPLEFT", 6, yOff)
    w.frame:SetChecked(def.get())
    -- Disabled defs render dim and inert (pooled widgets must reset
    -- both ways). A disabled CheckButton never fires OnClick.
    w.frame:SetEnabled(not def.disabled)
    if def.disabled then
        w.lbl:SetTextColor(0.45, 0.45, 0.45)
    else
        w.lbl:SetTextColor(0.88, 0.88, 0.88)
    end
    w.frame:SetScript("OnClick", function(s)
        def.set(s:GetChecked())
        if def.onRefresh then def.onRefresh() end
    end)

    -- Reorder buttons appear at the right edge when the def carries a
    -- `reorder` table. The label width must leave room for them.
    -- Reorder rows are always laid out full width, so `col` is the
    -- content frame here.
    local r = def.reorder
    if r then
        w.dnBtn:ClearAllPoints()
        w.dnBtn:SetPoint("RIGHT", col, "RIGHT", -8, 0)
        w.dnBtn:SetPoint("TOP", w.frame, "TOP", 0, -1)
        w.dnBtn:SetScript("OnClick", function() if r.onDown then r.onDown() end end)
        if r.isLast then w.dnBtn:Disable() else w.dnBtn:Enable() end
        w.dnBtn:Show()

        w.upBtn:ClearAllPoints()
        w.upBtn:SetPoint("RIGHT", w.dnBtn, "LEFT", -2, 0)
        w.upBtn:SetScript("OnClick", function() if r.onUp then r.onUp() end end)
        if r.isFirst then w.upBtn:Disable() else w.upBtn:Enable() end
        w.upBtn:Show()
    else
        w.upBtn:Hide()
        w.dnBtn:Hide()
    end

    -- Anchor label LEFT to checkbox and RIGHT to the column so it fills
    -- the column width at draw time. col:GetWidth() returns 0 here
    -- because BuildConfig runs before cfgFrame:Show(), so SetWidth()
    -- would clamp to the floor and wrap after a few chars. The same
    -- technique carries over per column: the two column frames are
    -- anchored halves of the content frame, so their edges resolve at
    -- draw time exactly like the body's did.
    local rightReserve = r and 50 or 6
    w.lbl:ClearAllPoints()
    w.lbl:SetPoint("TOPLEFT", w.frame, "TOPRIGHT", 4, -2)
    w.lbl:SetPoint("RIGHT", col, "RIGHT", -rightReserve, 0)
    w.lbl:SetWidth(0)  -- clear any prior fixed width so the L+R anchors win
    w.lbl:SetText(def.label)

    w.frame:Show()

    -- Row height grows with the wrapped label so two-line labels don't
    -- overlap the next widget. GetStringHeight returns the wrapped
    -- height once SetText has run against the resolved anchor width.
    local lh = w.lbl:GetStringHeight() or 12
    return math.max(22, lh + 8)
end

local function acquireSlider(store, body, yOff, label, min, max, step, getVal, setVal, fillR, fillG, fillB)
    local pool = getPool(store).slider
    pool.idx = pool.idx + 1
    local w = pool.items[pool.idx]
    if not w then
        local lbl = body:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(theme.font, 9, lib.FontFlags())
        local bg = CreateFrame("Frame", nil, body, "BackdropTemplate")
        bg:SetSize(138, 14)
        bg:SetBackdrop(theme.btnBackdrop)
        local slc = theme.colors.optionsSliderBg
        bg:SetBackdropColor(slc[1], slc[2], slc[3], slc[4])
        bg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        local fill = bg:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("LEFT", bg, "LEFT", 2, 0)
        fill:SetHeight(10)
        local valBox = CreateFrame("Frame", nil, body, "BackdropTemplate")
        valBox:SetPoint("LEFT", bg, "RIGHT", 4, 0)
        valBox:SetSize(44, 14)
        valBox:SetBackdrop(theme.btnBackdrop)
        valBox:SetBackdropColor(0, 0, 0, 0.5)
        valBox:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        local valTxt = valBox:CreateFontString(nil, "OVERLAY")
        valTxt:SetFont(theme.font, 9, lib.FontFlags())
        valTxt:SetPoint("CENTER")
        local sl = CreateFrame("Slider", nil, bg)
        sl:SetAllPoints(bg)
        sl:SetOrientation("HORIZONTAL")
        sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        local th = sl:GetThumbTexture()
        if th then th:Hide() end
        w = { lbl = lbl, frame = bg, fill = fill, valBox = valBox, valTxt = valTxt,
            slider = sl, _hide = { lbl, bg, valBox } }
        pool.items[pool.idx] = w
        if lib.RegisterThemeHook then
            lib.RegisterThemeHook(function()
                lbl:SetFont(theme.font, 9, lib.FontFlags())
                valTxt:SetFont(theme.font, 9, lib.FontFlags())
                local slc = theme.colors.optionsSliderBg
                bg:SetBackdropColor(slc[1], slc[2], slc[3], slc[4])
            end)
        end
    end
    w.lbl:ClearAllPoints()
    w.lbl:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    w.lbl:SetText("|cff888888" .. label .. "|r")
    w.lbl:Show()
    yOff = yOff - 14
    w.frame:ClearAllPoints()
    w.frame:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    w.fill:SetColorTexture(fillR, fillG, fillB, 0.85)
    w.valBox:Show()
    w.valTxt:Show()
    w.slider:SetMinMaxValues(min, max)
    w.slider:SetValueStep(step)
    w.slider:SetObeyStepOnDrag(true)
    local function UpdateVis(v)
        local pct = (v - min) / (max - min)
        w.fill:SetWidth(math.max(2, (w.frame:GetWidth() - 4) * pct))
        w.valTxt:SetText(string.format("%.2f", v):gsub("%.?0+$", ""))
    end
    w.slider:SetValue(getVal())
    UpdateVis(getVal())
    w.slider:SetScript("OnValueChanged", function(_, v) UpdateVis(v) end)
    w.slider:SetScript("OnMouseUp", function(s) setVal(s:GetValue()) end)
    w.frame:Show()
    return yOff - 18
end

-- Single-select dropdown. `def.options` is `{ { label, value }, ... }`;
-- `def.get()` returns the current value; `def.set(v)` applies it.
-- Clicking the button opens MUI.MakeDropdown popup with the options.
local function acquireDropdown(store, body, yOff, def)
    local pool = getPool(store).dropdown
    pool.idx = pool.idx + 1
    local w = pool.items[pool.idx]
    if not w then
        local lbl = body:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(theme.font, 9, lib.FontFlags())

        local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
        btn:SetHeight(20)
        btn:SetBackdrop(theme.btnBackdrop)
        btn:SetBackdropColor(unpack(theme.colors.btnBg))
        btn:SetBackdropBorderColor(unpack(theme.colors.btnBorder))

        local valFs = btn:CreateFontString(nil, "OVERLAY")
        valFs:SetFont(theme.font, 10, lib.FontFlags())
        valFs:SetPoint("LEFT", btn, "LEFT", 6, 0)
        valFs:SetPoint("RIGHT", btn, "RIGHT", -18, 0)
        valFs:SetJustifyH("LEFT")
        valFs:SetTextColor(unpack(theme.colors.text))

        local arrow = btn:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(8, 8)
        arrow:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
        arrow:SetVertexColor(theme.colors.arrowColor[1], theme.colors.arrowColor[2], theme.colors.arrowColor[3])

        local popup = lib.MakeDropdown()

        btn:SetScript("OnEnter", function()
            local h = theme.colors.btnTealHoverBg
            btn:SetBackdropColor(h[1], h[2], h[3], h[4] or 1)
        end)
        btn:SetScript("OnLeave", function()
            btn:SetBackdropColor(unpack(theme.colors.btnBg))
        end)

        w = { lbl = lbl, frame = btn, valFs = valFs, arrow = arrow, popup = popup,
            _hide = { lbl, btn, popup } }
        pool.items[pool.idx] = w

        -- One-time theme hook: re-apply backdrop and font/colors on
        -- theme switch. (Pool items persist across config rebuilds, so
        -- registering here doesn't accumulate per-BuildConfig.)
        if lib.RegisterThemeHook then
            lib.RegisterThemeHook(function()
                btn:SetBackdrop(theme.btnBackdrop)
                btn:SetBackdropColor(unpack(theme.colors.btnBg))
                btn:SetBackdropBorderColor(unpack(theme.colors.btnBorder))
                lbl:SetFont(theme.font, 9, lib.FontFlags())
                valFs:SetFont(theme.font, 10, lib.FontFlags())
                valFs:SetTextColor(unpack(theme.colors.text))
                arrow:SetVertexColor(theme.colors.arrowColor[1], theme.colors.arrowColor[2], theme.colors.arrowColor[3])
            end)
        end
    end

    w.lbl:ClearAllPoints()
    w.lbl:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    w.lbl:SetText("|cff888888" .. (def.label or "") .. "|r")
    w.lbl:Show()
    yOff = yOff - 14

    w.frame:ClearAllPoints()
    w.frame:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    w.frame:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, yOff)

    -- Display the option label whose value matches def.get().
    local curVal = def.get()
    local curLabel = tostring(curVal)
    for _, opt in ipairs(def.options or {}) do
        if opt.value == curVal then curLabel = opt.label; break end
    end
    w.valFs:SetText(curLabel)

    -- Rebuild the click handler each refresh so it sees the latest
    -- def.options / def.get / def.set / def.onRefresh.
    w.frame:SetScript("OnClick", function()
        if w.popup:IsShown() then w.popup:Hide(); return end
        local items = {}
        for _, opt in ipairs(def.options or {}) do
            items[#items + 1] = {
                label = opt.label,
                selected = opt.value == def.get(),
                onClick = function()
                    def.set(opt.value)
                    if def.onRefresh then def.onRefresh() end
                end,
            }
        end
        w.popup:ShowAt(w.frame, "BOTTOMLEFT", "TOPLEFT", items)
    end)

    w.frame:Show()
    return yOff - 24
end

-- Action row: a caption on the left, a clickable button on the right.
--   def = { type = "button", label, text, tooltip, width, height,
--           disabled, onClick }
-- `label` is the explanatory caption, `text` the button face (default
-- "Run"). The button is lib.MakeHeaderBtn with the accent treatment the
-- window's primary footer button uses.
local function acquireButton(store, body, yOff, def)
    local pool = getPool(store).button
    pool.idx = pool.idx + 1
    local w = pool.items[pool.idx]
    if not w then
        local lbl = body:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(theme.font, 10, lib.FontFlags())
        lbl:SetJustifyH("LEFT")
        lbl:SetJustifyV("TOP")
        lbl:SetWordWrap(true)

        local c = theme.colors
        -- Tooltip is nil at creation: pooled buttons outlive any one def,
        -- and MakeHeaderBtn captures its tooltip string in a closure.
        -- The base OnEnter still paints hover; this wrapper adds the
        -- current def's tooltip on top. Base OnLeave already hides it.
        local btn = lib.MakeHeaderBtn(body, "", c.accent, c.btnTealHoverBg,
            c.accent, nil, { width = 88, height = 24 })
        local baseEnter = btn:GetScript("OnEnter")

        local fill = btn:CreateTexture(nil, "BACKGROUND")
        fill:SetPoint("TOPLEFT", 1, -1)
        fill:SetPoint("BOTTOMRIGHT", -1, 1)
        fill:SetTexture(WHITE8)
        local ac = c.accent
        fill:SetColorTexture(ac[1], ac[2], ac[3], 0.12)

        w = { lbl = lbl, frame = btn, fill = fill, _hide = { lbl, btn } }
        pool.items[pool.idx] = w

        btn:SetScript("OnEnter", function(s)
            if baseEnter then baseEnter(s) end
            if w._tooltip then
                GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
                GameTooltip:SetText(w._tooltip)
                GameTooltip:Show()
            end
        end)

        if lib.RegisterThemeHook then
            lib.RegisterThemeHook(function()
                lbl:SetFont(theme.font, 10, lib.FontFlags())
                local a = theme.colors.accent
                fill:SetColorTexture(a[1], a[2], a[3], 0.12)
            end)
        end
    end

    local h = def.height or 24
    w.frame:ClearAllPoints()
    w.frame:SetSize(def.width or 88, h)
    w.frame:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, yOff)
    if w.frame._label then w.frame._label:SetText(def.text or "Run") end
    w._tooltip = def.tooltip
    w.frame:SetEnabled(not def.disabled)
    w.frame:SetScript("OnClick", function()
        if def.onClick then def.onClick() end
        if def.onRefresh then def.onRefresh() end
    end)
    w.frame:Show()

    w.lbl:ClearAllPoints()
    w.lbl:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff - 5)
    w.lbl:SetPoint("RIGHT", w.frame, "LEFT", -8, 0)
    w.lbl:SetWidth(0)
    w.lbl:SetTextColor(0.88, 0.88, 0.88)
    w.lbl:SetText(def.label or "")
    w.lbl:Show()

    local lh = w.lbl:GetStringHeight() or 12
    return yOff - math.max(h + 6, lh + 10)
end

--------------------------------------------------------------------------
-- Category rail
--------------------------------------------------------------------------

-- One rail row. Deliberately not lib.MakeNavRow: that row reserves 40px
-- for an icon and a right-hand count column, neither of which a 130px
-- category rail has room for. Same visual language though — shared
-- accent indicator, hover wash, title-colored active label.
local function acquireRailRow(store, rail, index, label, active, onClick)
    local pool = getPool(store).railrow
    pool.idx = pool.idx + 1
    local w = pool.items[pool.idx]
    if not w then
        local row = CreateFrame("Button", nil, rail)
        row:SetHeight(RAIL_ROW_H)
        row:RegisterForClicks("LeftButtonUp")

        local wash = row:CreateTexture(nil, "BACKGROUND", nil, 2)
        wash:SetAllPoints()
        wash:SetTexture(WHITE8)
        wash:Hide()

        -- Seeded through SetTextureAlpha: SetColorTexture's alpha cannot
        -- be read back, so a bare seed would make the first fade start
        -- from opaque.
        local hover = row:CreateTexture(nil, "BACKGROUND", nil, 3)
        hover:SetAllPoints()
        lib.SetTextureAlpha(hover, 1, 1, 1, 0)

        local bar = row:CreateTexture(nil, "ARTWORK")
        bar:SetWidth(2)
        bar:SetPoint("TOPLEFT")
        bar:SetPoint("BOTTOMLEFT")
        bar:SetTexture(WHITE8)
        bar:Hide()

        -- Font before SetText.
        local fs = row:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize - 1, lib.FontFlags())
        fs:SetPoint("LEFT", row, "LEFT", 12, 0)
        fs:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(false)

        w = { frame = row, fs = fs, wash = wash, hover = hover, bar = bar,
            _hide = { row } }
        pool.items[pool.idx] = w

        local function paint()
            local c = theme.colors
            local ac = c.accent
            lib.SetGradient(wash, "HORIZONTAL",
                { ac[1], ac[2], ac[3], 0.12 }, { ac[1], ac[2], ac[3], 0 })
            bar:SetColorTexture(ac[1], ac[2], ac[3], 1)
            fs:SetFont(theme.font, theme.fontSize - 1, lib.FontFlags())
            if w._active then
                fs:SetTextColor(c.title[1], c.title[2], c.title[3], c.title[4] or 1)
            else
                fs:SetTextColor(c.textDim[1], c.textDim[2], c.textDim[3])
            end
        end
        w.paint = paint
        if lib.RegisterThemeHook then lib.RegisterThemeHook(paint) end

        row:SetScript("OnEnter", function()
            local rh = theme.colors.rowHover
            lib.FadeTexture(hover, rh[1], rh[2], rh[3], rh[4] or 0.05, 0.08)
        end)
        row:SetScript("OnLeave", function()
            local rh = theme.colors.rowHover
            lib.FadeTexture(hover, rh[1], rh[2], rh[3], 0, 0.12)
        end)
    end

    w._active = active
    w.frame:ClearAllPoints()
    w.frame:SetPoint("TOPLEFT", rail, "TOPLEFT", 0, -(index - 1) * (RAIL_ROW_H + 2))
    w.frame:SetPoint("TOPRIGHT", rail, "TOPRIGHT", 0, -(index - 1) * (RAIL_ROW_H + 2))
    w.fs:SetText(label)
    if active then w.wash:Show() else w.wash:Hide() end
    if active then w.bar:Show() else w.bar:Hide() end
    w.paint()
    w.frame:SetScript("OnClick", onClick)
    w.frame:Show()
    return w
end

-- The rail never lives in the scrolling body: it must stay put while the
-- page scrolls. WHERE it hangs is the target's business — between the
-- settings window's header and footer, or down the left edge of a shell's
-- main content area — so the anchors arrive as target.railTop /
-- target.railBottom, each { relativeFrame, relativePoint, x, y }.
local function ensureRail(target)
    local store = target.store
    if store._cfgRail then return store._cfgRail end
    local rail = CreateFrame("Frame", nil, target.railParent)
    rail:SetWidth(RAIL_W)
    local t, b = target.railTop, target.railBottom
    rail:SetPoint("TOPLEFT", t[1], t[2], t[3], t[4])
    rail:SetPoint("BOTTOMLEFT", b[1], b[2], b[3], b[4])
    -- The scroll frame spans the full body width; lifting the rail above
    -- it keeps both the draw order and the hit testing unambiguous.
    if target.railAbove then
        rail:SetFrameLevel(target.railAbove:GetFrameLevel() + 5)
    end

    local edge = rail:CreateTexture(nil, "ARTWORK")
    edge:SetWidth(1)
    edge:SetPoint("TOPRIGHT", rail, "TOPRIGHT", RAIL_GUTTER / 2, 0)
    edge:SetPoint("BOTTOMRIGHT", rail, "BOTTOMRIGHT", RAIL_GUTTER / 2, 0)
    edge:SetTexture(WHITE8)
    local function paint()
        local dc = theme.colors.optionsDivider
        edge:SetColorTexture(dc[1], dc[2], dc[3], dc[4] or 0.06)
    end
    paint()
    if lib.RegisterThemeHook then lib.RegisterThemeHook(paint) end

    store._cfgRail = rail
    return rail
end

-- Content frame + the two column halves. The content frame is the stable
-- creation parent for every pooled widget, and it is what gets indented
-- when the rail is showing — so the rail never has to move the window's
-- scroll frame around. The column frames are anchored halves of it, so
-- a widget anchored into a column resolves its width at draw time just
-- like it used to against the body.
local function ensureContent(store, body)
    local content = store._cfgContent
    if not content then
        content = CreateFrame("Frame", nil, body)
        content:SetHeight(1)
        store._cfgContent = content

        local colL = CreateFrame("Frame", nil, content)
        colL:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        colL:SetPoint("BOTTOMRIGHT", content, "BOTTOM", -COL_GAP, 0)
        store._cfgColL = colL

        local colR = CreateFrame("Frame", nil, content)
        colR:SetPoint("TOPLEFT", content, "TOP", COL_GAP, 0)
        colR:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
        store._cfgColR = colR
    end
    -- A target can be cleared (_clearConfigBody hides the whole subtree);
    -- rendering into it again has to bring it back.
    content:Show()
    return content, store._cfgColL, store._cfgColR
end

-- Split a def list at `page` markers. Defs ahead of the first marker
-- form an implicit first page, so a caller that emits no markers at all
-- still renders everything as one unlabeled page.
local function splitPages(defs)
    local pages, cur = {}, nil
    for _, def in ipairs(defs) do
        if def.type == "page" then
            cur = { label = def.label or ("Page " .. (#pages + 1)), defs = {} }
            pages[#pages + 1] = cur
        else
            if not cur then
                cur = { label = "General", defs = {} }
                pages[#pages + 1] = cur
            end
            cur.defs[#cur.defs + 1] = def
        end
    end
    if #pages == 0 then pages[1] = { label = "General", defs = {} } end
    return pages
end

-- A run of consecutive plain checkboxes (no `reorder` table) lays out two
-- per row. Anything else — a reorder row, slider, dropdown, button,
-- section, divider — is full width and ends the run.
local function isPlainCheckbox(def)
    return def and def.type == "checkbox" and not def.reorder
end

--------------------------------------------------------------------------
-- Render targets
--
-- A target says WHERE a def list renders. Everything the renderer needs
-- that differs between the settings window and a shell's main content
-- area lives here, so the layout pass below is target-agnostic:
--   store        this target's own state (pools, content/column frames,
--                rail, current page, last defs) — one table per target,
--                which is what keeps the two sets of pooled widgets from
--                ever being re-anchored into each other's parent
--   body         the frame widgets anchor into (a scroll child)
--   scrollFrame  scrolled by the rail (page change resets it to the top)
--   railParent   creation parent for the category rail
--   railTop/railBottom  { relativeFrame, relativePoint, x, y }
--   width        optional function returning the surface's usable width.
--                A target that can be resized narrow supplies it and gets
--                the narrow fallbacks (thinner rail, single column); one
--                that omits it renders at full width unconditionally.
--                Authoritative numbers only — body:GetWidth() is 0 until
--                the surface has been shown once.
--   finish(totalH)      commit the measured height
--------------------------------------------------------------------------

-- The settings window: the original — and still the only — target under
-- the classic shell. Rendering state stays on the panel exactly where it
-- has always been, so a panel that only ever opens the window behaves
-- identically to before targets existed.
local function windowTarget(panel)
    local cfgFrame = panel.cfgFrame
    if not cfgFrame or not cfgFrame.body then return nil end
    local target = panel._cfgWindowTarget
    if target and target.frame == cfgFrame then return target end
    target = {
        frame       = cfgFrame,
        store       = panel,
        body        = cfgFrame.body,
        scrollFrame = cfgFrame.scrollFrame,
        railParent  = cfgFrame,
        railAbove   = cfgFrame.scrollFrame,
        railTop     = cfgFrame.header
            and { cfgFrame.header, "BOTTOMLEFT", 16, -8 }
            or  { cfgFrame, "TOPLEFT", 16, -54 },
        railBottom  = cfgFrame.footer
            and { cfgFrame.footer, "TOPLEFT", 16, 8 }
            or  { cfgFrame, "BOTTOMLEFT", 16, 16 },
        finish = function(totalH)
            -- A scrolling settings window is a fixed size: the body is
            -- its scroll child, so only the scroll range changes. The
            -- legacy side-dock grew to fit instead.
            if cfgFrame._scrolls then
                -- Switching from a long page to a short one leaves the
                -- old scroll offset past the new end, which reads as an
                -- empty window.
                local sf = cfgFrame.scrollFrame
                if sf then
                    local maxScroll = math.max(totalH - sf:GetHeight(), 0)
                    if sf:GetVerticalScroll() > maxScroll then
                        sf:SetVerticalScroll(maxScroll)
                    end
                end
                if cfgFrame.UpdateScrollBar then cfgFrame.UpdateScrollBar() end
            else
                cfgFrame:SetHeight(24 + 4 + totalH)
            end
        end,
    }
    panel._cfgWindowTarget = target
    return target
end

-- Hide everything a target has on screen without discarding it: the
-- pooled widgets, the content subtree, and the rail. Used when the
-- surface the target renders into is about to show something else (the
-- premium content area going back to a tracker list).
lib._clearConfigBody = function(target)
    if not target or not target.store then return end
    local store = target.store
    if store._cfgPools then poolReset(store) end
    if store._cfgContent then store._cfgContent:Hide() end
    if store._cfgRail then store._cfgRail:Hide() end
end

-- PopulateConfig implementation (called by PanelProto:_PopulateConfigBody
-- and ShellProto:RenderConfigInContent). `target` defaults to the
-- settings window.
lib._populateConfigBody = function(panel, defs, target)
    target = target or windowTarget(panel)
    if not target or not target.body then return end
    if not defs then return end
    local store = target.store
    local body = target.body

    store._cfgDefs = defs
    local pages = splitPages(defs)
    local paged = #pages > 1

    local pageIdx = store._cfgPage or 1
    if pageIdx < 1 or pageIdx > #pages then pageIdx = 1 end
    store._cfgPage = pageIdx

    poolReset(store)

    local content, colL, colR = ensureContent(store, body)

    -- Layout width. A target that reports one can be dragged narrow
    -- (the shell's content area follows the window), so the rail is
    -- re-measured on every render rather than fixed at creation, and the
    -- two-column grid gives way to one column before the columns get too
    -- thin to read.
    local availW = target.width and target.width() or nil
    local railW = RAIL_W
    if availW and availW < RAIL_NARROW then
        railW = math.max(RAIL_MIN_W, math.min(RAIL_W, math.floor(availW * 0.30)))
    end
    local indent = paged and (railW + RAIL_GUTTER) or 0
    local twoCol = (not availW) or ((availW - indent) >= 2 * COL_MIN_W)

    content:ClearAllPoints()
    content:SetPoint("TOPLEFT", body, "TOPLEFT", indent, 0)
    content:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, 0)

    -- Rail. Built on first paged render and reused; hidden outright when
    -- the def list carries no page markers.
    if paged then
        local rail = ensureRail(target)
        rail:SetWidth(railW)
        rail:Show()
        for i, page in ipairs(pages) do
            local idx = i
            acquireRailRow(store, rail, i, page.label, i == pageIdx, function()
                if store._cfgPage == idx then return end
                store._cfgPage = idx
                if target.scrollFrame then
                    target.scrollFrame:SetVerticalScroll(0)
                end
                lib._populateConfigBody(panel, store._cfgDefs, target)
            end)
        end
    elseif store._cfgRail then
        store._cfgRail:Hide()
    end

    local pageDefs = pages[pageIdx].defs
    local yOff = 0
    local i, n = 1, #pageDefs
    while i <= n do
        local def = pageDefs[i]
        if def.type == "section" then
            yOff = acquireSection(store, content, yOff, def.label)
            yOff = yOff - 2
        elseif def.type == "divider" then
            yOff = acquireDivider(store, content, yOff)
        elseif def.type == "checkbox" then
            if twoCol and isPlainCheckbox(def) and isPlainCheckbox(pageDefs[i + 1]) then
                local hL = acquireCheckbox(store, content, colL, yOff, def)
                local hR = acquireCheckbox(store, content, colR, yOff, pageDefs[i + 1])
                yOff = yOff - math.max(hL, hR)
                i = i + 1
            else
                -- Reorder rows keep the full width (their arrows sit at
                -- the right edge); a lone plain checkbox stays in the
                -- left column so the grid does not jump — unless there is
                -- no grid, where half-width would just waste the room.
                local col = (def.reorder or not twoCol) and content or colL
                yOff = yOff - acquireCheckbox(store, content, col, yOff, def)
            end
        elseif def.type == "slider" then
            local fc = def.fillColor or { 0.40, 0.40, 0.40 }
            yOff = acquireSlider(store, content, yOff, def.label, def.min, def.max, def.step,
                def.get, def.set, fc[1], fc[2], fc[3])
        elseif def.type == "dropdown" then
            yOff = acquireDropdown(store, content, yOff, def)
        elseif def.type == "button" then
            yOff = acquireButton(store, content, yOff, def)
        end
        i = i + 1
    end

    poolHideExtras(store)

    local totalH = math.abs(yOff) + 8
    body:SetHeight(totalH)
    -- The content frame is anchored top-only, so give it the same height:
    -- the column frames hang off its BOTTOM edge, and a stale height
    -- would leave them measuring the previous page.
    content:SetHeight(totalH)
    if target.finish then target.finish(totalH) end
end

--------------------------------------------------------------------------
-- MakeSearchInput: a themed single-line search box.
--
--   opts = {
--       placeholder   — dim prompt shown while empty (default "Search…")
--       width/height  — frame size (height default 26)
--       onChanged(text) — every keystroke (also fires on Clear())
--       onEscape()    — Escape with an EMPTY box (a non-empty one clears
--                       first, which is what a search box should do)
--       onEnter(text) — Enter commits
--       maxLetters    — default 64
--   }
--
-- Returns a Frame exposing:
--   :GetText() :SetText(t) :Clear() :Focus() :ClearFocus()
--
-- Not pooled: the search view owns exactly one for its lifetime and
-- re-parents nothing. One theme hook at creation covers repaints; there
-- is no per-render acquisition to accumulate hooks over.
--------------------------------------------------------------------------
function lib.MakeSearchInput(parent, opts)
    opts = opts or {}
    local h = opts.height or 26

    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetHeight(h)
    frame:SetBackdrop(theme.btnBackdrop)

    local magnifier = frame:CreateTexture(nil, "ARTWORK")
    magnifier:SetSize(13, 13)
    magnifier:SetPoint("LEFT", frame, "LEFT", 8, 0)
    magnifier:SetTexture("Interface\\Common\\UI-Searchbox-Icon")

    -- Font before SetText (house rule).
    local edit = CreateFrame("EditBox", nil, frame)
    edit:SetFont(theme.font, theme.fontSize, lib.FontFlags())
    edit:SetTextInsets(24, 22, 0, 0)
    edit:SetAllPoints()
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(opts.maxLetters or 64)

    local placeholder = frame:CreateFontString(nil, "OVERLAY")
    placeholder:SetFont(theme.font, theme.fontSize, lib.FontFlags())
    placeholder:SetPoint("LEFT", frame, "LEFT", 25, 0)
    placeholder:SetPoint("RIGHT", frame, "RIGHT", -24, 0)
    placeholder:SetJustifyH("LEFT")
    placeholder:SetWordWrap(false)
    placeholder:SetText(opts.placeholder or "Search…")

    -- Clear affordance: a text "x" rather than a texture asset, matching
    -- the close-button treatment used across this UI's chrome.
    local clearBtn = CreateFrame("Button", nil, frame)
    clearBtn:SetSize(16, 16)
    clearBtn:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    local clearFs = clearBtn:CreateFontString(nil, "OVERLAY")
    clearFs:SetFont(theme.font, theme.fontSize - 1, lib.FontFlags())
    clearFs:SetPoint("CENTER", 0, 1)
    clearFs:SetText("x")
    clearBtn:SetFontString(clearFs)
    clearBtn:Hide()

    local function paintFocus(focused)
        local c = theme.colors
        frame:SetBackdropColor(unpack(c.btnBg))
        if focused then
            local ac = c.accent
            frame:SetBackdropBorderColor(ac[1], ac[2], ac[3], 0.9)
        else
            frame:SetBackdropBorderColor(unpack(c.btnBorder))
        end
        local tc = focused and c.text or c.textDim
        edit:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1)
        local dc = c.textDim
        magnifier:SetVertexColor(dc[1], dc[2], dc[3])
        placeholder:SetTextColor(dc[1], dc[2], dc[3])
    end

    local function refresh()
        local text = edit:GetText() or ""
        local has = text ~= ""
        placeholder:SetShown(not has)
        clearBtn:SetShown(has)
        if opts.onChanged then opts.onChanged(text) end
    end

    edit:SetScript("OnTextChanged", refresh)  -- not OnTextChanged(true): no history compare needed
    edit:SetScript("OnEditFocusGained", function() paintFocus(true) end)
    edit:SetScript("OnEditFocusLost", function() paintFocus(false) end)
    edit:SetScript("OnEscapePressed", function(self)
        if self:GetText() ~= "" then
            self:SetText("")
            refresh()
        else
            self:ClearFocus()
            if opts.onEscape then opts.onEscape() end
        end
    end)
    edit:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if opts.onEnter then opts.onEnter(self:GetText() or "") end
    end)

    clearBtn:SetScript("OnClick", function()
        -- SetText alone: OnTextChanged fires refresh(), which updates
        -- placeholder/clear visibility and notifies onChanged once.
        edit:SetText("")
        edit:SetFocus()
    end)
    clearBtn:SetScript("OnEnter", function()
        clearFs:SetTextColor(1, 1, 1, 1)
    end)
    clearBtn:SetScript("OnLeave", function()
        local dc = theme.colors.textDim
        clearFs:SetTextColor(dc[1], dc[2], dc[3])
    end)

    if lib.RegisterThemeHook then
        lib.RegisterThemeHook(function()
            frame:SetBackdrop(theme.btnBackdrop)
            paintFocus(edit:HasFocus())
            local dc = theme.colors.textDim
            clearFs:SetTextColor(dc[1], dc[2], dc[3])
        end)
    end

    paintFocus(false)

    function frame:GetText() return edit:GetText() or "" end
    -- SetText/Clear deliberately do NOT call refresh() themselves:
    -- programmatic SetText fires OnTextChanged, which refreshes and
    -- notifies exactly once.
    function frame:SetText(t)
        edit:SetText(t or "")
    end
    function frame:Clear()
        edit:SetText("")
    end
    function frame:Focus()
        edit:SetFocus()
        edit:SetCursorPosition(#edit:GetText())
    end
    function frame:ClearFocus()
        edit:ClearFocus()
    end

    return frame
end
