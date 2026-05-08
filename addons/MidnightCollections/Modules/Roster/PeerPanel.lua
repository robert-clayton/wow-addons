local _, MC = ...

--------------------------------------------------------------------------
-- Peer detail popup. Clicking a guildie/friend in the Roster opens this
-- in a separate sticky frame rather than overriding the main MC panel.
-- Single shared frame; subsequent clicks repopulate it.
--------------------------------------------------------------------------

local MUI = LibStub("MidnightUI-1.0", true)

local FRAME

local MOD_DISPLAY_ORDER = { "mounts", "pets", "toys", "decorations", "recipes", "rares", "treasures" }
local MOD_LABELS = {
    mounts      = "Mounts",
    pets        = "Pets",
    toys        = "Toys",
    decorations = "Decorations",
    recipes     = "Recipes",
    rares       = "Rares",
    treasures   = "Treasures",
}

local function classRGB(token)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if c then return c.r, c.g, c.b end
    return 0.7, 0.7, 0.7
end

local function nameOnly(fullName)
    return (fullName or ""):match("^([^%-]+)") or fullName or "?"
end

local function realmOnly(fullName)
    return (fullName or ""):match("^[^%-]+%-(.+)$") or ""
end

local function relTime(ts)
    if not ts then return "" end
    local dt = time() - ts
    if dt < 60     then return dt .. "s ago" end
    if dt < 3600   then return math.floor(dt / 60)    .. "m ago" end
    if dt < 86400  then return math.floor(dt / 3600)  .. "h ago" end
    return math.floor(dt / 86400) .. "d ago"
end

--------------------------------------------------------------------------
-- Build the frame on first show, reuse afterward.
--------------------------------------------------------------------------
local function build()
    if FRAME then return FRAME end

    local theme = MUI and MUI.Theme

    local f = CreateFrame("Frame", "MidnightCollectionsPeerPanel", UIParent, "BackdropTemplate")
    f:SetFrameStrata("DIALOG")
    f:SetSize(320, 320)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()

    if theme and theme.backdrop then
        f:SetBackdrop(theme.backdrop)
        f:SetBackdropColor(theme.colors.bg[1], theme.colors.bg[2], theme.colors.bg[3], 0.97)
        f:SetBackdropBorderColor(unpack(theme.colors.border))
    end

    -- Title bar
    local bar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    bar:SetHeight(24)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    if theme and theme.backdrop then
        bar:SetBackdrop(theme.backdrop)
        bar:SetBackdropColor(unpack(theme.colors.titlebar))
        bar:SetBackdropBorderColor(unpack(theme.colors.titleBorder))
    end

    f.title = bar:CreateFontString(nil, "OVERLAY")
    f.title:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 13, "OUTLINE")
    f.title:SetPoint("LEFT", 10, 0)

    f.subtitle = bar:CreateFontString(nil, "OVERLAY")
    f.subtitle:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 10, "OUTLINE")
    f.subtitle:SetPoint("LEFT", f.title, "RIGHT", 8, -1)
    if theme then f.subtitle:SetTextColor(unpack(theme.colors.textDim)) end

    -- Close button (uses the existing MUI helper to match the panel style)
    if MUI and MUI.MakeHeaderBtn then
        local close = MUI.MakeHeaderBtn(bar, "x",
            theme.colors.btnCloseFg,
            theme.colors.btnCloseHoverBg,
            theme.colors.btnCloseHoverBd,
            "Close")
        close:SetPoint("RIGHT", -4, 0)
        close:SetScript("OnClick", function() f:Hide() end)
    end

    -- ESC closes the popup
    tinsert(UISpecialFrames, "MidnightCollectionsPeerPanel")

    -- Module rows are created lazily into f.rows[modKey]
    f.rows = {}

    -- Footer
    f.footer = f:CreateFontString(nil, "OVERLAY")
    f.footer:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 10, "")
    f.footer:SetPoint("BOTTOMLEFT", 14, 12)
    f.footer:SetPoint("BOTTOMRIGHT", -14, 12)
    f.footer:SetJustifyH("LEFT")
    if theme then f.footer:SetTextColor(unpack(theme.colors.textDim)) end

    FRAME = f
    return f
end

--------------------------------------------------------------------------
-- Lazy-create or reuse a row for a given module key.
--------------------------------------------------------------------------
local function acquireRow(f, key, yOff)
    local theme = MUI and MUI.Theme
    local row = f.rows[key]
    if not row then
        row = {}
        row.frame = CreateFrame("Frame", nil, f)
        row.frame:SetHeight(20)
        row.label = row.frame:CreateFontString(nil, "OVERLAY")
        row.label:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 11, "OUTLINE")
        row.label:SetPoint("LEFT", row.frame, "LEFT", 0, 0)
        row.value = row.frame:CreateFontString(nil, "OVERLAY")
        row.value:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 11, "OUTLINE")
        row.value:SetPoint("RIGHT", row.frame, "RIGHT", 0, 0)
        row.value:SetJustifyH("RIGHT")
        -- Thin progress bar background
        local bg = row.frame:CreateTexture(nil, "ARTWORK")
        bg:SetHeight(2)
        bg:SetPoint("BOTTOMLEFT", row.frame, "BOTTOMLEFT", 0, 0)
        bg:SetPoint("BOTTOMRIGHT", row.frame, "BOTTOMRIGHT", 0, 0)
        if theme then bg:SetColorTexture(unpack(theme.colors.progressBg)) end
        row.barBg = bg
        local fill = row.frame:CreateTexture(nil, "OVERLAY")
        fill:SetHeight(2)
        fill:SetPoint("BOTTOMLEFT", row.frame, "BOTTOMLEFT", 0, 0)
        if theme then fill:SetColorTexture(unpack(theme.colors.progress)) end
        row.barFill = fill
        f.rows[key] = row
    end
    row.frame:ClearAllPoints()
    row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 14, yOff)
    row.frame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, yOff)
    row.frame:Show()
    row.label:Show()
    row.value:Show()
    row.barBg:Show()
    return row
end

local function hideRow(f, key)
    local row = f.rows[key]
    if not row then return end
    row.frame:Hide()
end

--------------------------------------------------------------------------
-- Show: takes a peer-name key from MC.RosterDB and renders the popup.
--------------------------------------------------------------------------
function MC.ShowPeerPanel(peerName)
    if not peerName then return end
    if not (MC.RosterDB and MC.RosterDB[peerName]) then return end
    local entry = MC.RosterDB[peerName]
    local f = build()

    local r, g, b = classRGB(entry.class)
    f.title:SetText(nameOnly(peerName))
    f.title:SetTextColor(r, g, b)
    local realm = realmOnly(peerName)
    f.subtitle:SetText(realm ~= "" and ("- " .. realm) or "")

    -- Render per-module rows
    local yOff = -36
    for _, key in ipairs(MOD_DISPLAY_ORDER) do
        local c = entry.counts and entry.counts[key]
        if c then
            local row = acquireRow(f, key, yOff)
            row.label:SetText(MOD_LABELS[key])
            local cr, cg, cb = MUI.CountColor(c.collected, c.total)
            row.label:SetTextColor(0.85, 0.85, 0.85)
            row.value:SetTextColor(cr, cg, cb)
            row.value:SetText(format("%d / %d", c.collected, c.total))
            local pct = c.total > 0 and (c.collected / c.total) or 0
            local rowW = f:GetWidth() - 28
            row.barFill:SetWidth(math.max(2, rowW * pct))
            yOff = yOff - 22
        else
            hideRow(f, key)
        end
    end
    -- Hide any rows for keys that aren't in this peer's data
    for key in pairs(f.rows) do
        local hasIt = false
        for _, k in ipairs(MOD_DISPLAY_ORDER) do
            if k == key and entry.counts and entry.counts[key] then
                hasIt = true
                break
            end
        end
        if not hasIt then hideRow(f, key) end
    end

    -- Resize the frame to fit content + footer
    local contentH = math.abs(yOff) + 32
    f:SetHeight(math.max(contentH, 160))

    -- Footer: last seen + version
    local seen = relTime(entry.lastSeen)
    local ver  = entry.version and ("v" .. entry.version) or ""
    local sep  = (seen ~= "" and ver ~= "") and "  ·  " or ""
    f.footer:SetText("Last seen: " .. seen .. sep .. ver)

    f:Show()
    f:Raise()
end

--------------------------------------------------------------------------
-- Convenience: hide/refresh hooks for reuse.
--------------------------------------------------------------------------
function MC.HidePeerPanel()
    if FRAME then FRAME:Hide() end
end
