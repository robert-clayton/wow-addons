local lib = LibStub:GetLibrary("MidnightUI-1.0", true)
if not lib then return end

local theme = lib.Theme

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
local function getPool(panel)
    if not panel._cfgPools then
        panel._cfgPools = {
            section  = { items = {}, idx = 0 },
            divider  = { items = {}, idx = 0 },
            checkbox = { items = {}, idx = 0 },
            slider   = { items = {}, idx = 0 },
            dropdown = { items = {}, idx = 0 },
        }
    end
    return panel._cfgPools
end

local function poolReset(panel)
    for _, pool in pairs(getPool(panel)) do
        pool.idx = 0
        for _, w in ipairs(pool.items) do
            if w.frame then w.frame:Hide() end
            if w.fs then w.fs:Hide() end
        end
    end
end

local function poolHideExtras(panel)
    for _, pool in pairs(getPool(panel)) do
        for i = pool.idx + 1, #pool.items do
            local w = pool.items[i]
            if w.frame then w.frame:Hide() end
            if w.fs then w.fs:Hide() end
        end
    end
end

-- Acquire-or-create handlers per widget type
local function acquireSection(panel, body, yOff, text)
    local pool = getPool(panel).section
    pool.idx = pool.idx + 1
    local w = pool.items[pool.idx]
    if not w then
        local fs = body:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, 9, lib.FontFlags())
        w = { fs = fs }
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

local function acquireDivider(panel, body, yOff)
    local pool = getPool(panel).divider
    pool.idx = pool.idx + 1
    local w = pool.items[pool.idx]
    if not w then
        local fr = CreateFrame("Frame", nil, body, "BackdropTemplate")
        fr:SetHeight(1)
        fr:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        local dc = theme.colors.optionsDivider
        fr:SetBackdropColor(dc[1], dc[2], dc[3], dc[4])
        w = { frame = fr }
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

local function acquireCheckbox(panel, body, yOff, def)
    local pool = getPool(panel).checkbox
    pool.idx = pool.idx + 1
    local w = pool.items[pool.idx]
    if not w then
        local fr = CreateFrame("CheckButton", nil, body, "UICheckButtonTemplate")
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
        w = { frame = fr, lbl = lbl, upBtn = upBtn, dnBtn = dnBtn }
        pool.items[pool.idx] = w
        if lib.RegisterThemeHook then
            lib.RegisterThemeHook(function()
                lbl:SetFont(theme.font, 10, lib.FontFlags())
            end)
        end
    end
    w.frame:ClearAllPoints()
    w.frame:SetPoint("TOPLEFT", body, "TOPLEFT", 6, yOff)
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
    local r = def.reorder
    if r then
        w.dnBtn:ClearAllPoints()
        w.dnBtn:SetPoint("RIGHT", body, "RIGHT", -8, 0)
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

    -- Anchor label LEFT to checkbox and RIGHT to body so it fills the
    -- column width at draw time. body:GetWidth() returns 0 here because
    -- BuildConfig runs before cfgFrame:Show(), so SetWidth() would clamp
    -- to the floor and wrap after a few chars.
    local rightReserve = r and 50 or 6
    w.lbl:ClearAllPoints()
    w.lbl:SetPoint("TOPLEFT", w.frame, "TOPRIGHT", 4, -2)
    w.lbl:SetPoint("RIGHT", body, "RIGHT", -rightReserve, 0)
    w.lbl:SetWidth(0)  -- clear any prior fixed width so the L+R anchors win
    w.lbl:SetText(def.label)

    w.frame:Show()

    -- Row height grows with the wrapped label so two-line labels don't
    -- overlap the next widget. GetStringHeight returns the wrapped
    -- height once SetText has run against the resolved anchor width.
    local lh = w.lbl:GetStringHeight() or 12
    return yOff - math.max(22, lh + 8)
end

local function acquireSlider(panel, body, yOff, label, min, max, step, getVal, setVal, fillR, fillG, fillB)
    local pool = getPool(panel).slider
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
        w = { lbl = lbl, frame = bg, fill = fill, valBox = valBox, valTxt = valTxt, slider = sl }
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
local function acquireDropdown(panel, body, yOff, def)
    local pool = getPool(panel).dropdown
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

        w = { lbl = lbl, frame = btn, valFs = valFs, arrow = arrow, popup = popup }
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

-- PopulateConfig implementation (called by PanelProto:_PopulateConfigBody)
lib._populateConfigBody = function(panel, defs)
    local cfgFrame = panel.cfgFrame
    if not cfgFrame or not cfgFrame.body then return end
    local body = cfgFrame.body

    poolReset(panel)
    local yOff = 0

    for _, def in ipairs(defs) do
        if def.type == "section" then
            yOff = acquireSection(panel, body, yOff, def.label)
            yOff = yOff - 2
        elseif def.type == "divider" then
            yOff = acquireDivider(panel, body, yOff)
        elseif def.type == "checkbox" then
            yOff = acquireCheckbox(panel, body, yOff, def)
        elseif def.type == "slider" then
            local fc = def.fillColor or { 0.40, 0.40, 0.40 }
            yOff = acquireSlider(panel, body, yOff, def.label, def.min, def.max, def.step,
                def.get, def.set, fc[1], fc[2], fc[3])
        elseif def.type == "dropdown" then
            yOff = acquireDropdown(panel, body, yOff, def)
        end
    end

    poolHideExtras(panel)

    local totalH = math.abs(yOff) + 8
    body:SetHeight(totalH)
    cfgFrame:SetHeight(24 + 4 + totalH)
end
