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

    -- Re-skin on theme change like every other widget, otherwise the
    -- popup keeps whatever theme it was created under (SetBackdrop copies
    -- colors at call time and never re-reads them).
    local function applyTheme()
        local t = lib.Theme
        if t and t.backdrop then
            popup:SetBackdrop(t.backdrop)
            popup:SetBackdropColor(t.colors.bg[1], t.colors.bg[2],
                                   t.colors.bg[3], 0.97)
            popup:SetBackdropBorderColor(unpack(t.colors.border))
        end
    end
    applyTheme()
    lib.RegisterThemeHook(applyTheme)
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
        fs:SetFont(theme.font, theme.fontSize - 1, lib.FontFlags())
        fs:SetPoint("LEFT", PAD_X, 0)
        fs:SetTextColor(0.88, 0.88, 0.88)
        row._fs = fs
        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 0.85, 0.5, 0)
        -- Hover tint read live from the theme; the fallback keeps the
        -- legacy warm-gold wash for themes without colors.menuHover.
        row:SetScript("OnEnter", function()
            if row._disabled then return end
            local h = lib.Theme.colors.menuHover or { 1, 0.85, 0.5, 0.10 }
            hl:SetColorTexture(h[1], h[2], h[3], h[4])
        end)
        row:SetScript("OnLeave", function()
            local h = lib.Theme.colors.menuHover or { 1, 0.85, 0.5, 0.10 }
            hl:SetColorTexture(h[1], h[2], h[3], 0)
        end)
        popup._rows[idx] = row
        return row
    end

    -- Show the popup anchored to `anchorFrame`. `anchorRel` is the
    -- anchor's edge ("BOTTOMLEFT"/"BOTTOMRIGHT"); `popupPoint` is the
    -- popup's matching corner ("TOPLEFT"/"TOPRIGHT"). `items` is a
    -- list of { label, selected, onClick } tables.
    function popup:ShowAt(anchorFrame, anchorRel, popupPoint, items)
        local widest = 0
        -- Per-show theming: rows are created once, so font and colors
        -- are re-applied here to track live theme switches. The
        -- fallbacks are the legacy hardcoded palette (|cffffcc66 ==
        -- RGB 1.0/0.8/0.4 exactly), so themes without menu* keys
        -- render identically to the old escape-sequence path.
        local t = lib.Theme
        local mc = t.colors
        local selColor  = mc.menuSelected or { 1, 0.8, 0.4 }
        local textColor = mc.menuText or { 0.88, 0.88, 0.88 }
        -- Disabled rows render dim, take no hover wash, and swallow
        -- clicks without closing the popup.
        local disColor  = mc.menuDisabled or { 0.45, 0.45, 0.45 }
        for i, item in ipairs(items) do
            local row = acquireRow(i)
            row._disabled = item.disabled and true or nil
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, -PAD_Y - (i - 1) * ROW_HEIGHT)
            row._fs:SetFont(t.font, t.fontSize - 1, lib.FontFlags())
            row._fs:SetText(item.label)
            local c = item.disabled and disColor
                or (item.selected and selColor or textColor)
            row._fs:SetTextColor(c[1], c[2], c[3])
            row:SetScript("OnClick", function()
                if item.disabled then return end
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
