local lib = LibStub:GetLibrary("MidnightUI-1.0", true)
if not lib then return end

local theme = lib.Theme

--------------------------------------------------------------------------
-- File-local widget helpers
--------------------------------------------------------------------------
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
    fs:SetFont(theme.font, 9, "OUTLINE")
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
    lbl:SetFont(theme.font, 10, "OUTLINE")
    lbl:SetText(label)
    lbl:SetTextColor(0.88, 0.88, 0.88)
    lbl:SetPoint("LEFT", fr, "RIGHT", 0, 0)
    return yOff - 22
end

local function OptionsSlider(body, yOff, label, min, max, step, getVal, setVal, fillR, fillG, fillB)
    local lbl = body:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(theme.font, 9, "OUTLINE")
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
    valTxt:SetFont(theme.font, 9, "OUTLINE")
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

--------------------------------------------------------------------------
-- Pooled-widget config builder: each "type+slot" is created once and reused
-- across rebuilds. Frames in WoW cannot be GC'd, so re-creating CheckButtons
-- and Sliders on every settings rebuild is a real frame leak.
--------------------------------------------------------------------------
local function getPool(panel)
    if not panel._cfgPools then
        panel._cfgPools = {
            section  = { items = {}, idx = 0 },
            divider  = { items = {}, idx = 0 },
            checkbox = { items = {}, idx = 0 },
            slider   = { items = {}, idx = 0 },
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
        fs:SetFont(theme.font, 9, "OUTLINE")
        w = { fs = fs }
        pool.items[pool.idx] = w
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
    end
    w.frame:ClearAllPoints()
    w.frame:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    w.frame:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, yOff)
    w.frame:Show()
    return yOff - 6
end

local function acquireCheckbox(panel, body, yOff, label, getVal, setVal, onRefresh)
    local pool = getPool(panel).checkbox
    pool.idx = pool.idx + 1
    local w = pool.items[pool.idx]
    if not w then
        local fr = CreateFrame("CheckButton", nil, body, "UICheckButtonTemplate")
        fr:SetSize(20, 20)
        fr:EnableMouse(true)
        local lbl = fr:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(theme.font, 10, "OUTLINE")
        lbl:SetTextColor(0.88, 0.88, 0.88)
        lbl:SetPoint("LEFT", fr, "RIGHT", 0, 0)
        w = { frame = fr, lbl = lbl }
        pool.items[pool.idx] = w
    end
    w.frame:ClearAllPoints()
    w.frame:SetPoint("TOPLEFT", body, "TOPLEFT", 6, yOff)
    w.lbl:SetText(label)
    w.frame:SetChecked(getVal())
    w.frame:SetScript("OnClick", function(s)
        setVal(s:GetChecked())
        if onRefresh then onRefresh() end
    end)
    w.frame:Show()
    return yOff - 22
end

local function acquireSlider(panel, body, yOff, label, min, max, step, getVal, setVal, fillR, fillG, fillB)
    local pool = getPool(panel).slider
    pool.idx = pool.idx + 1
    local w = pool.items[pool.idx]
    if not w then
        local lbl = body:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(theme.font, 9, "OUTLINE")
        local bg = CreateFrame("Frame", nil, body, "BackdropTemplate")
        bg:SetSize(138, 14)
        bg:SetBackdrop(theme.backdrop)
        local slc = theme.colors.optionsSliderBg
        bg:SetBackdropColor(slc[1], slc[2], slc[3], slc[4])
        bg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        local fill = bg:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("LEFT", bg, "LEFT", 2, 0)
        fill:SetHeight(10)
        local valBox = CreateFrame("Frame", nil, body, "BackdropTemplate")
        valBox:SetPoint("LEFT", bg, "RIGHT", 4, 0)
        valBox:SetSize(44, 14)
        valBox:SetBackdrop(theme.backdrop)
        valBox:SetBackdropColor(0, 0, 0, 0.5)
        valBox:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        local valTxt = valBox:CreateFontString(nil, "OVERLAY")
        valTxt:SetFont(theme.font, 9, "OUTLINE")
        valTxt:SetPoint("CENTER")
        local sl = CreateFrame("Slider", nil, bg)
        sl:SetAllPoints(bg)
        sl:SetOrientation("HORIZONTAL")
        sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        local th = sl:GetThumbTexture()
        if th then th:Hide() end
        w = { lbl = lbl, frame = bg, fill = fill, valBox = valBox, valTxt = valTxt, slider = sl }
        pool.items[pool.idx] = w
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

--------------------------------------------------------------------------
-- PopulateConfig implementation (called by PanelProto:_PopulateConfigBody)
--------------------------------------------------------------------------
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
            yOff = acquireCheckbox(panel, body, yOff, def.label, def.get, def.set, def.onRefresh)
        elseif def.type == "slider" then
            local fc = def.fillColor or { 0.40, 0.40, 0.40 }
            yOff = acquireSlider(panel, body, yOff, def.label, def.min, def.max, def.step,
                def.get, def.set, fc[1], fc[2], fc[3])
        end
    end

    poolHideExtras(panel)

    local totalH = math.abs(yOff) + 8
    body:SetHeight(totalH)
    cfgFrame:SetHeight(24 + 4 + totalH)
end
