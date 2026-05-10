local lib = LibStub:GetLibrary("MidnightUI-1.0", true)
if not lib then return end

local theme = lib.Theme

-- Reusable dropdown popup. Returns a frame that can be shown next to
-- any anchor frame with a list of selectable items. Replaces the
-- removed-from-retail UIDropDownMenu / EasyMenu pattern with a simple
-- custom popup that handles its own click-outside dismissal.
--
-- Usage:
--     local popup = MUI.MakeDropdown()
--     anchorBtn:SetScript("OnClick", function()
--         if popup:IsShown() then popup:Hide(); return end
--         popup:ShowAt(anchorBtn, "BOTTOMLEFT", "TOPLEFT", {
--             { label = "Option A", selected = true,
--               onClick = function() ... end },
--             { label = "Option B",
--               onClick = function() ... end },
--         })
--     end)
--
-- Each item is { label, selected (bool), onClick }. The selected item
-- renders in a highlighted color so the active choice is obvious. The
-- popup auto-dismisses on click outside or on row click.

local ROW_HEIGHT = 18
local PAD_X      = 8
local PAD_Y      = 6

function lib.MakeDropdown()
    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("DIALOG")
    popup:SetClampedToScreen(true)
    popup:Hide()

    if theme and theme.backdrop then
        popup:SetBackdrop(theme.backdrop)
        popup:SetBackdropColor(theme.colors.bg[1], theme.colors.bg[2],
                               theme.colors.bg[3], 0.97)
        popup:SetBackdropBorderColor(unpack(theme.colors.border))
    end
    popup._rows = {}

    -- Click-outside dismissal: a full-screen invisible frame one level
    -- below the popup absorbs the click and hides everything.
    popup:SetScript("OnShow", function(self)
        if not self._closer then
            self._closer = CreateFrame("Frame", nil, UIParent)
            self._closer:SetAllPoints(UIParent)
            self._closer:SetFrameStrata("DIALOG")
            self._closer:EnableMouse(true)
            self._closer:SetScript("OnMouseDown", function() self:Hide() end)
        end
        self._closer:SetFrameLevel(self:GetFrameLevel() - 1)
        self._closer:Show()
    end)
    popup:SetScript("OnHide", function(self)
        if self._closer then self._closer:Hide() end
    end)

    local function acquireRow(idx)
        local row = popup._rows[idx]
        if row then return row end
        row = CreateFrame("Button", nil, popup)
        row:SetHeight(ROW_HEIGHT)
        row:EnableMouse(true)
        local fs = row:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize - 1, "OUTLINE")
        fs:SetPoint("LEFT", PAD_X, 0)
        fs:SetTextColor(0.88, 0.88, 0.88)
        row._fs = fs
        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 0.85, 0.5, 0)
        row:SetScript("OnEnter", function() hl:SetColorTexture(1, 0.85, 0.5, 0.10) end)
        row:SetScript("OnLeave", function() hl:SetColorTexture(1, 0.85, 0.5, 0) end)
        popup._rows[idx] = row
        return row
    end

    -- Show the popup anchored to `anchorFrame`. `anchorRel` is the
    -- anchor's edge ("BOTTOMLEFT"/"BOTTOMRIGHT"); `popupPoint` is the
    -- popup's matching corner ("TOPLEFT"/"TOPRIGHT"). `items` is a
    -- list of { label, selected, onClick } tables.
    function popup:ShowAt(anchorFrame, anchorRel, popupPoint, items)
        local widest = 0
        for i, item in ipairs(items) do
            local row = acquireRow(i)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, -PAD_Y - (i - 1) * ROW_HEIGHT)
            row._fs:SetText(item.selected
                and ("|cffffcc66" .. item.label .. "|r")
                or item.label)
            row:SetScript("OnClick", function()
                if item.onClick then item.onClick() end
                popup:Hide()
            end)
            row:Show()
            local w = row._fs:GetStringWidth() + PAD_X * 2
            if w > widest then widest = w end
        end
        for i = #items + 1, #popup._rows do popup._rows[i]:Hide() end
        for _, row in ipairs(popup._rows) do row:SetWidth(widest) end

        popup:SetSize(widest, PAD_Y * 2 + #items * ROW_HEIGHT)
        popup:ClearAllPoints()
        popup:SetPoint(popupPoint or "TOPLEFT",
                       anchorFrame,
                       anchorRel or "BOTTOMLEFT",
                       0, -2)
        popup:Show()
        -- Both this popup and any DIALOG-strata anchor frame share the
        -- DIALOG strata; without an explicit raise the popup can render
        -- under the anchor's children.
        popup:Raise()
    end

    return popup
end
