local _, MC = ...

--------------------------------------------------------------------------
-- Peer detail popup. Clicking a Roster row toggles that peer in/out of
-- the popup. Multiple peers are rendered as side-by-side columns for
-- direct comparison. Empty selection -> popup hides itself.
--------------------------------------------------------------------------

local MUI = LibStub("MidnightUI-1.0", true)

local FRAME
local activePeers = {}  -- ordered list of Name-Realm keys currently shown

local COLUMN_WIDTH    = 220
local COLUMN_GAP      = 12
local TITLE_BAR_H     = 24
local CONTENT_TOP_PAD = 12
local BOTTOM_PAD      = 14
local SIDE_PAD        = 14

-- Progress-bar fill colour: full red at 0% -> yellow at 50% -> full
-- green at 100%, with a smooth lerp between stops.
local function progressColor(pct)
    pct = math.max(0, math.min(1, pct or 0))
    local r, g, b
    if pct < 0.5 then
        local t = pct * 2  -- 0..1 across the first half
        r, g, b = 1, t, 0
    else
        local t = (pct - 0.5) * 2  -- 0..1 across the second half
        r, g, b = 1 - t, 1, 0
    end
    return r, g, b
end

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

local function relTime(ts)
    if not ts then return "" end
    local dt = time() - ts
    if dt < 60     then return dt .. "s ago" end
    if dt < 3600   then return math.floor(dt / 60)    .. "m ago" end
    if dt < 86400  then return math.floor(dt / 3600)  .. "h ago" end
    return math.floor(dt / 86400) .. "d ago"
end

local function indexOf(t, v)
    for i, x in ipairs(t) do if x == v then return i end end
end

-- Special-case "me" so the local player can be added to the popup.
local function getEntry(name)
    if not name then return nil end
    if MC.GetMeRosterEntry then
        local me = MC.GetMeRosterEntry()
        if me and me.name == name then return me end
    end
    return MC.RosterDB and MC.RosterDB[name]
end

--------------------------------------------------------------------------
-- Frame construction (one-shot).
--------------------------------------------------------------------------
local function build()
    if FRAME then return FRAME end

    local theme = MUI and MUI.Theme

    local f = CreateFrame("Frame", "MidnightCollectionsPeerPanel", UIParent, "BackdropTemplate")
    f:SetFrameStrata("DIALOG")
    f:SetSize(COLUMN_WIDTH + SIDE_PAD * 2, 320)
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
    bar:SetHeight(TITLE_BAR_H)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    if theme and theme.backdrop then
        bar:SetBackdrop(theme.backdrop)
        bar:SetBackdropColor(unpack(theme.colors.titlebar))
        bar:SetBackdropBorderColor(unpack(theme.colors.titleBorder))
    end
    f.titleBar = bar

    f.title = bar:CreateFontString(nil, "OVERLAY")
    f.title:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 12, "OUTLINE")
    f.title:SetPoint("LEFT", 10, 0)

    if MUI and MUI.MakeHeaderBtn then
        local close = MUI.MakeHeaderBtn(bar, "x",
            theme.colors.btnCloseFg,
            theme.colors.btnCloseHoverBg,
            theme.colors.btnCloseHoverBd,
            "Close")
        close:SetPoint("RIGHT", -4, 0)
        close:SetScript("OnClick", function()
            wipe(activePeers)
            f:Hide()
        end)
    end

    tinsert(UISpecialFrames, "MidnightCollectionsPeerPanel")

    f.columns = {}

    FRAME = f
    return f
end

--------------------------------------------------------------------------
-- Per-column factory + render.
--------------------------------------------------------------------------
local function acquireColumn(f, idx)
    local theme = MUI and MUI.Theme
    local col = f.columns[idx]
    if not col then
        col = {}
        col.frame = CreateFrame("Frame", nil, f)
        col.title = col.frame:CreateFontString(nil, "OVERLAY")
        col.title:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 12, "OUTLINE")
        col.title:SetPoint("TOPLEFT", col.frame, "TOPLEFT", 0, 0)
        col.title:SetJustifyH("LEFT")
        col.subtitle = col.frame:CreateFontString(nil, "OVERLAY")
        col.subtitle:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 9, "OUTLINE")
        col.subtitle:SetPoint("TOPLEFT", col.title, "BOTTOMLEFT", 0, -2)
        col.subtitle:SetJustifyH("LEFT")
        if theme then col.subtitle:SetTextColor(unpack(theme.colors.textDim)) end
        col.rows = {}
        f.columns[idx] = col
    end
    col.frame:Show()
    col.title:Show()
    col.subtitle:Show()
    return col
end

local function acquireRow(col, key, yOff)
    local theme = MUI and MUI.Theme
    local row = col.rows[key]
    if not row then
        row = {}
        row.frame = CreateFrame("Frame", nil, col.frame)
        row.frame:SetHeight(20)
        row.label = row.frame:CreateFontString(nil, "OVERLAY")
        row.label:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 11, "OUTLINE")
        row.label:SetPoint("LEFT", row.frame, "LEFT", 0, 0)
        row.value = row.frame:CreateFontString(nil, "OVERLAY")
        row.value:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 11, "OUTLINE")
        row.value:SetPoint("RIGHT", row.frame, "RIGHT", 0, 0)
        row.value:SetJustifyH("RIGHT")
        local bg = row.frame:CreateTexture(nil, "ARTWORK")
        bg:SetHeight(2)
        bg:SetPoint("BOTTOMLEFT", row.frame, "BOTTOMLEFT", 0, 0)
        bg:SetPoint("BOTTOMRIGHT", row.frame, "BOTTOMRIGHT", 0, 0)
        if theme then bg:SetColorTexture(unpack(theme.colors.progressBg)) end
        row.barBg = bg
        local fill = row.frame:CreateTexture(nil, "OVERLAY")
        fill:SetHeight(2)
        fill:SetPoint("BOTTOMLEFT", row.frame, "BOTTOMLEFT", 0, 0)
        -- Initial colour is set per-render via progressColor based on
        -- the current pct; nothing to do at create time.
        row.barFill = fill
        col.rows[key] = row
    end
    row.frame:ClearAllPoints()
    row.frame:SetPoint("TOPLEFT", col.frame, "TOPLEFT", 0, yOff)
    row.frame:SetPoint("TOPRIGHT", col.frame, "TOPRIGHT", 0, yOff)
    row.frame:Show()
    row.label:Show()
    row.value:Show()
    row.barBg:Show()
    return row
end

local function hideAllRows(col)
    for _, row in pairs(col.rows) do row.frame:Hide() end
end

local function renderColumn(col, entry)
    local theme = MUI.Theme
    local r, g, b = classRGB(entry.class)
    col.title:SetText(nameOnly(entry.name) .. (entry.isMe and " |cff888888(You)|r" or ""))
    col.title:SetTextColor(r, g, b)
    local seen = relTime(entry.lastSeen)
    local ver  = entry.version and ("v" .. entry.version) or ""
    local sep  = (seen ~= "" and ver ~= "") and "  ·  " or ""
    col.subtitle:SetText(seen .. sep .. ver)

    hideAllRows(col)
    local yOff = -36
    for _, key in ipairs(MOD_DISPLAY_ORDER) do
        local c = entry.counts and entry.counts[key]
        if c then
            local row = acquireRow(col, key, yOff)
            row.label:SetText(MOD_LABELS[key])
            row.label:SetTextColor(0.85, 0.85, 0.85)
            local cr, cg, cb = MUI.CountColor(c.collected, c.total)
            row.value:SetTextColor(cr, cg, cb)
            row.value:SetText(format("%d / %d", c.collected, c.total))
            local pct = c.total > 0 and (c.collected / c.total) or 0
            local rowW = COLUMN_WIDTH - 8
            row.barFill:SetWidth(math.max(2, rowW * pct))
            row.barFill:SetColorTexture(progressColor(pct))
            yOff = yOff - 22
        end
    end
    return -yOff
end

--------------------------------------------------------------------------
-- Re-render the popup based on the current activePeers list.
--------------------------------------------------------------------------
local function rerender(f)
    -- Hide all columns first; we'll show only the ones we render.
    for _, col in ipairs(f.columns) do
        col.frame:Hide()
        col.title:Hide()
        col.subtitle:Hide()
        for _, row in pairs(col.rows) do row.frame:Hide() end
    end

    local n = #activePeers
    if n == 0 then return end

    local maxContentH = 0
    for i = 1, n do
        local entry = getEntry(activePeers[i])
        if entry then
            local col = acquireColumn(f, i)
            col.frame:ClearAllPoints()
            col.frame:SetPoint("TOPLEFT", f, "TOPLEFT",
                SIDE_PAD + (i - 1) * (COLUMN_WIDTH + COLUMN_GAP),
                -TITLE_BAR_H - CONTENT_TOP_PAD)
            col.frame:SetSize(COLUMN_WIDTH, 1)
            local h = renderColumn(col, entry)
            if h > maxContentH then maxContentH = h end
        end
    end

    -- Resize the frame
    local totalW = SIDE_PAD * 2 + n * COLUMN_WIDTH + math.max(0, n - 1) * COLUMN_GAP
    f:SetWidth(totalW)
    local totalH = TITLE_BAR_H + CONTENT_TOP_PAD + maxContentH + BOTTOM_PAD
    f:SetHeight(math.max(totalH, 160))

    f.title:SetText("Collection Inspector")
    if MUI and MUI.Theme then
        f.title:SetTextColor(unpack(MUI.Theme.colors.title))
    end
end

--------------------------------------------------------------------------
-- Public API: toggle a peer in/out of the comparison popup.
--------------------------------------------------------------------------
function MC.ShowPeerPanel(peerName)
    if not peerName then return end
    if not getEntry(peerName) then return end

    local idx = indexOf(activePeers, peerName)
    if idx then
        table.remove(activePeers, idx)
    else
        table.insert(activePeers, peerName)
    end

    if #activePeers == 0 then
        if FRAME then FRAME:Hide() end
        return
    end

    local f = build()
    rerender(f)
    f:Show()
    f:Raise()
end

function MC.HidePeerPanel()
    wipe(activePeers)
    if FRAME then FRAME:Hide() end
end
