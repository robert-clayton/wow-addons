local _, MC = ...

-- Collection Inspector: a popup with a left-side peer list and a right-
-- side comparison view. Clicking a name in the list toggles that peer
-- in/out of the comparison columns.

local MUI = LibStub("MidnightUI-1.0", true)

local FRAME
local activePeers = {}  -- ordered list of Name-Realm keys in comparison

local LIST_WIDTH      = 180
local LIST_ROW_H      = 18
local COLUMN_WIDTH    = 220
local COLUMN_GAP      = 12
local TITLE_BAR_H     = 24
local CONTENT_TOP_PAD = 12
local BOTTOM_PAD      = 14
local SIDE_PAD        = 14
local LIST_GAP        = 12

-- Red at 0%, yellow at 50%, green at 100%.
local function progressColor(pct)
    pct = math.max(0, math.min(1, pct or 0))
    if pct < 0.5 then
        local t = pct * 2
        return 1, t, 0
    end
    local t = (pct - 0.5) * 2
    return 1 - t, 1, 0
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

local function sumCounts(counts)
    if not counts then return 0, 0 end
    local got, total = 0, 0
    for _, c in pairs(counts) do
        got   = got + (c.collected or 0)
        total = total + (c.total or 0)
    end
    return got, total
end

local function getEntry(name)
    if not name then return nil end
    if MC.GetMeRosterEntry then
        local me = MC.GetMeRosterEntry()
        if me and me.name == name then return me end
    end
    return MC.RosterDB and MC.RosterDB[name]
end

-- "You" first, then alphabetical. Used for the left list.
local function buildPeerOrder()
    local list = {}
    if MC.GetMeRosterEntry then
        local me = MC.GetMeRosterEntry()
        if me and me.name then
            list[#list + 1] = { name = me.name, isMe = true, entry = me }
        end
    end
    if MC.RosterDB then
        local names = {}
        for k in pairs(MC.RosterDB) do names[#names + 1] = k end
        table.sort(names, function(a, b) return a:lower() < b:lower() end)
        for _, n in ipairs(names) do
            list[#list + 1] = { name = n, isMe = false, entry = MC.RosterDB[n] }
        end
    end
    return list
end

-- One-shot frame construction.
local function build()
    if FRAME then return FRAME end

    local theme = MUI and MUI.Theme

    local f = CreateFrame("Frame", "MidnightCollectionsPeerPanel", UIParent, "BackdropTemplate")
    f:SetFrameStrata("DIALOG")
    f:SetSize(LIST_WIDTH + LIST_GAP + COLUMN_WIDTH + SIDE_PAD * 2, 360)
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
    f.title:SetText("Collection Inspector")
    if theme then f.title:SetTextColor(unpack(theme.colors.title)) end

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

    --------------------------------------------------------------------
    -- Left scrollable peer list
    --------------------------------------------------------------------
    local list = CreateFrame("ScrollFrame", nil, f)
    list:SetPoint("TOPLEFT", f, "TOPLEFT", SIDE_PAD, -TITLE_BAR_H - CONTENT_TOP_PAD)
    list:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", SIDE_PAD, BOTTOM_PAD)
    list:SetWidth(LIST_WIDTH)
    list:EnableMouseWheel(true)
    f.listScroll = list

    local listChild = CreateFrame("Frame", nil, list)
    listChild:SetWidth(LIST_WIDTH)
    listChild:SetHeight(1)
    list:SetScrollChild(listChild)
    f.listChild = listChild

    list:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local maxScroll = math.max(listChild:GetHeight() - self:GetHeight(), 0)
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 20, maxScroll)))
    end)

    f.listRows = {}

    --------------------------------------------------------------------
    -- Right-side comparison columns
    --------------------------------------------------------------------
    f.columns = {}
    f.columnAnchor = CreateFrame("Frame", nil, f)
    f.columnAnchor:SetPoint("TOPLEFT", f, "TOPLEFT",
        SIDE_PAD + LIST_WIDTH + LIST_GAP, -TITLE_BAR_H - CONTENT_TOP_PAD)
    f.columnAnchor:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT",
        SIDE_PAD + LIST_WIDTH + LIST_GAP, BOTTOM_PAD)
    f.columnAnchor:SetWidth(1)

    -- Empty-comparison hint text (shown when activePeers is empty)
    f.emptyText = f:CreateFontString(nil, "OVERLAY")
    f.emptyText:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 11, "OUTLINE")
    f.emptyText:SetPoint("TOPLEFT", f.columnAnchor, "TOPLEFT", 0, -8)
    f.emptyText:SetWidth(220)
    f.emptyText:SetJustifyH("LEFT")
    f.emptyText:SetText("Click a name on the left to add it to the comparison.")
    if theme then f.emptyText:SetTextColor(unpack(theme.colors.textDim)) end
    f.emptyText:Hide()

    FRAME = f
    return f
end

-- Left-list row factory + render.
local function acquireListRow(f, idx, yOff)
    local theme = MUI and MUI.Theme
    local row = f.listRows[idx]
    if not row then
        row = {}
        row.frame = CreateFrame("Frame", nil, f.listChild)
        row.frame:SetHeight(LIST_ROW_H)
        row.frame:EnableMouse(true)
        row.bg = row.frame:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(1, 1, 1, 0)
        row.dot = row.frame:CreateTexture(nil, "ARTWORK")
        row.dot:SetSize(6, 6)
        row.dot:SetPoint("LEFT", row.frame, "LEFT", 6, 0)
        row.label = row.frame:CreateFontString(nil, "OVERLAY")
        row.label:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 11, "OUTLINE")
        row.label:SetPoint("LEFT", row.dot, "RIGHT", 6, 0)
        row.label:SetPoint("RIGHT", row.frame, "RIGHT", -28, 0)
        row.label:SetJustifyH("LEFT")
        row.check = row.frame:CreateFontString(nil, "OVERLAY")
        row.check:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 11, "OUTLINE")
        row.check:SetPoint("RIGHT", row.frame, "RIGHT", -8, 0)
        f.listRows[idx] = row
    end
    row.frame:ClearAllPoints()
    row.frame:SetPoint("TOPLEFT", f.listChild, "TOPLEFT", 0, yOff)
    row.frame:SetPoint("RIGHT", f.listChild, "RIGHT", 0, 0)
    row.frame:Show()
    return row
end

local function renderListRow(row, item, isSelected)
    local r, g, b = classRGB(item.entry and item.entry.class)
    row.dot:SetColorTexture(r, g, b, 1)
    local label = nameOnly(item.name)
    if item.isMe then label = label .. " |cff888888(You)|r" end
    row.label:SetText(label)
    row.label:SetTextColor(0.85, 0.85, 0.85)
    row.check:SetText(isSelected and "|cff55cc55✓|r" or "")
    row.bg:SetColorTexture(1, 1, 1, isSelected and 0.06 or 0)
    -- Capture row.bg via closure; the frame doesn't carry a `bg` field.
    local bg = row.bg
    row.frame:SetScript("OnEnter", function()
        if not isSelected then bg:SetColorTexture(1, 1, 1, 0.04) end
    end)
    row.frame:SetScript("OnLeave", function()
        if not isSelected then bg:SetColorTexture(1, 1, 1, 0) end
    end)
    row.frame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then MC.ShowPeerPanel(item.name) end
    end)
end

local function refreshList(f)
    local order = buildPeerOrder()
    local yOff = 0
    for i, item in ipairs(order) do
        local row = acquireListRow(f, i, yOff)
        local isSelected = indexOf(activePeers, item.name) ~= nil
        renderListRow(row, item, isSelected)
        yOff = yOff - LIST_ROW_H
    end
    -- Hide leftover rows from a previous render with more peers
    for i = #order + 1, #f.listRows do
        if f.listRows[i] then f.listRows[i].frame:Hide() end
    end
    f.listChild:SetHeight(math.max(-yOff, 1))
end

-- Right-side comparison column factory + render.
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

local function acquireColRow(col, key, yOff)
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
        row.barFill = fill
        col.rows[key] = row
    end
    row.frame:ClearAllPoints()
    row.frame:SetPoint("TOPLEFT", col.frame, "TOPLEFT", 0, yOff)
    row.frame:SetPoint("TOPRIGHT", col.frame, "TOPRIGHT", 0, yOff)
    row.frame:Show()
    return row
end

local function renderColumn(col, entry)
    local r, g, b = classRGB(entry.class)
    col.title:SetText(nameOnly(entry.name) .. (entry.isMe and " |cff888888(You)|r" or ""))
    col.title:SetTextColor(r, g, b)
    local seen = relTime(entry.lastSeen)
    local ver  = entry.version and ("v" .. entry.version) or ""
    local sep  = (seen ~= "" and ver ~= "") and "  ·  " or ""
    col.subtitle:SetText(seen .. sep .. ver)

    for _, row in pairs(col.rows) do row.frame:Hide() end

    local yOff = -36
    for _, key in ipairs(MOD_DISPLAY_ORDER) do
        local c = entry.counts and entry.counts[key]
        if c then
            local row = acquireColRow(col, key, yOff)
            row.label:SetText(MOD_LABELS[key])
            row.label:SetTextColor(0.85, 0.85, 0.85)
            local pct = c.total > 0 and (c.collected / c.total) or 0
            local cr, cg, cb = progressColor(pct)
            row.value:SetTextColor(cr, cg, cb)
            row.value:SetText(format("%d / %d", c.collected, c.total))
            row.barFill:ClearAllPoints()
            row.barFill:SetPoint("BOTTOMLEFT", row.frame, "BOTTOMLEFT", 0, 0)
            row.barFill:SetWidth(math.max(2, COLUMN_WIDTH * pct))
            row.barFill:SetColorTexture(cr, cg, cb)
            yOff = yOff - 22
        end
    end
    return -yOff
end

-- Re-layout based on the current activePeers list.
local function rerender(f)
    refreshList(f)

    -- Hide all columns first; we'll show only the ones we actually render
    for _, col in pairs(f.columns) do
        col.frame:Hide()
        col.title:Hide()
        col.subtitle:Hide()
        for _, row in pairs(col.rows) do row.frame:Hide() end
    end

    local n = #activePeers
    local maxContentH = 0
    if n > 0 then
        f.emptyText:Hide()
        for i = 1, n do
            local entry = getEntry(activePeers[i])
            if entry then
                local col = acquireColumn(f, i)
                col.frame:ClearAllPoints()
                col.frame:SetPoint("TOPLEFT", f.columnAnchor, "TOPLEFT",
                    (i - 1) * (COLUMN_WIDTH + COLUMN_GAP), 0)
                col.frame:SetSize(COLUMN_WIDTH, 1)
                local h = renderColumn(col, entry)
                if h > maxContentH then maxContentH = h end
            end
        end
    else
        f.emptyText:Show()
        maxContentH = 24
    end

    local rightWidth = math.max(COLUMN_WIDTH, n * COLUMN_WIDTH + math.max(0, n - 1) * COLUMN_GAP)
    local totalW = SIDE_PAD + LIST_WIDTH + LIST_GAP + rightWidth + SIDE_PAD
    f:SetWidth(totalW)
    local totalH = TITLE_BAR_H + CONTENT_TOP_PAD + maxContentH + BOTTOM_PAD
    f:SetHeight(math.max(totalH, 200))
end

-- Public API.
function MC.ShowPeerPanel(peerName)
    if peerName then
        if not getEntry(peerName) then return end
        local idx = indexOf(activePeers, peerName)
        if idx then
            table.remove(activePeers, idx)
        else
            table.insert(activePeers, peerName)
        end
    end
    -- Even with empty activePeers we open the popup so the player can see
    -- the peer list and pick someone to compare. The right pane shows a
    -- small hint until they do.
    local f = build()
    rerender(f)
    f:Show()
    f:Raise()
end

function MC.HidePeerPanel()
    wipe(activePeers)
    if FRAME then FRAME:Hide() end
end

-- Allow Comms / receive paths to refresh the list when a new peer
-- broadcast arrives while the popup is open.
function MC.RefreshPeerPanel()
    if FRAME and FRAME:IsShown() then rerender(FRAME) end
end
