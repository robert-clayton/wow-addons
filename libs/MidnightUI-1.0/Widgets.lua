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
-- PopulateConfig implementation (called by PanelProto:_PopulateConfigBody)
--------------------------------------------------------------------------
lib._populateConfigBody = function(panel, defs)
    local cfgFrame = panel.cfgFrame
    if not cfgFrame or not cfgFrame.body then return end

    -- Clear previous children
    local body = cfgFrame.body
    local kids = { body:GetChildren() }
    for _, k in ipairs(kids) do k:Hide() end
    local regions = { body:GetRegions() }
    for _, r in ipairs(regions) do r:Hide() end

    local yOff = 0

    for _, def in ipairs(defs) do
        if def.type == "section" then
            yOff = OptionsSectionLabel(body, yOff, def.label)
            yOff = yOff - 2
        elseif def.type == "divider" then
            yOff = OptionsDivider(body, yOff)
        elseif def.type == "checkbox" then
            yOff = OptionsCheckbox(body, yOff, def.label, def.get, def.set, def.onRefresh)
        elseif def.type == "slider" then
            local fc = def.fillColor or { 0.40, 0.40, 0.40 }
            yOff = OptionsSlider(body, yOff, def.label, def.min, def.max, def.step,
                def.get, def.set, fc[1], fc[2], fc[3])
        end
    end

    -- Set body/frame height
    local totalH = math.abs(yOff) + 8
    body:SetHeight(totalH)
    cfgFrame:SetHeight(24 + 4 + totalH)
end
