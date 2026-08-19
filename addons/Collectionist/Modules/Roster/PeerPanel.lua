local _, MC = ...

-- Collection Inspector: a left-side peer list and a right-side comparison
-- view. Clicking a name in the list toggles that peer in/out of the
-- comparison columns.
--
-- The chrome is not ours: header (title + subtitle + close), drag, saved
-- position, Escape-to-close, footer button strip, scrolling body and the
-- PopIn/PopOut open/close motion all come from lib.CreateWindow — the
-- same factory the Options window is built on, so the two read as one
-- family. What stays local is the two-pane body (a vertical peer list
-- beside a horizontally scrolling strip of comparison columns) and the
-- add/remove column choreography, neither of which the factory models.

local MUI = LibStub("MidnightUI-1.0", true)

local WIN       -- window object from MUI.CreateWindow
local FRAME     -- WIN.frame; most of this file only needs the frame
local rerender  -- forward declaration: assigned below at file scope. The
                -- inspector-filter dropdown's onClick closures reference
                -- this and would otherwise resolve to a nil global at
                -- click time.
local activePeers = {}  -- ordered list of Name-Realm keys in comparison

-- Bumped by every rerender. The add/remove choreography is a chain of
-- callbacks; a pass that gets superseded mid-flight must not land its
-- (now stale) window size on top of the newer pass's.
local renderToken = 0

-- Inspector's own expansion filter. Initialized from the panel's
-- filter once per open session. Mutating this here doesn't
-- affect the panel filter (so the user can browse peer comparisons
-- in a different scope without losing their main view).
--
-- When the filter is "single", peer columns display the matching
-- expansion's slice from `entry.countsByExpansion` (broadcast as 'e'
-- messages). Falls back to account-wide `entry.counts` if the peer
-- didn't broadcast that expansion's slice (e.g. they're on an older
-- version, or they have no data for that expansion).
local inspectorFilter = nil

local function copyFilter(f)
    return { mode = f.mode or "current", single = f.single }
end

local function inspectorFilterLabel()
    if not inspectorFilter then return "" end
    if inspectorFilter.mode == "all" then return "All" end
    if inspectorFilter.mode == "current" then return "Current" end
    local key = inspectorFilter.single
    local e = MC.EXPANSION_BY_KEY and MC.EXPANSION_BY_KEY[key]
    return e and e.label or (key or "?")
end

local LIST_WIDTH   = 180
local LIST_ROW_H   = 18
local COLUMN_WIDTH = 220
local COLUMN_GAP   = 12
local LIST_GAP     = 16

-- Window geometry. WIN_PAD and SCROLL_GUTTER mirror the factory's body
-- inset and scrollbar channel; they are needed here to compute the window
-- width that leaves room for both panes, and to seed the pane widths
-- before the first layout pass — after that the scroll frame's own
-- OnSizeChanged is the authority (see layoutPanes). WINDOW_H is fixed:
-- the window grows sideways with the column count, never downwards.
local WIN_PAD       = 16
local SCROLL_GUTTER = 6
local WINDOW_H      = 400
local FIXED_W       = LIST_WIDTH + LIST_GAP + WIN_PAD * 2 + SCROLL_GUTTER

-- Column content height: renderColumn starts at -36 then drops -22 per
-- module row (8 modules incl. achievements), plus a Collection Score
-- row (+22, with a 4px gap above). Stays constant across peer counts
-- (columns are side-by-side, not stacked), so the window only grows in
-- width.
local COLUMN_CONTENT_H = 36 + 8 * 22 + 26

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

local MOD_DISPLAY_ORDER = { "mounts", "pets", "toys", "decorations", "recipes", "rares", "treasures", "achievements" }
local MOD_LABELS = {
    mounts       = "Mounts",
    pets         = "Pets",
    toys         = "Toys",
    decorations  = "Decorations",
    recipes      = "Recipes",
    rares        = "Rares",
    treasures    = "Treasures",
    achievements = "Achievements",
}

local function themeFont()
    local t = MUI and MUI.Theme
    return (t and t.font) or STANDARD_TEXT_FONT
end

local function fontFlags()
    return (MUI and MUI.FontFlags and MUI.FontFlags()) or "OUTLINE"
end

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

local function getEntry(name)
    if not name then return nil end
    if MC.GetMeRosterEntry then
        local me = MC.GetMeRosterEntry()
        if me and me.name == name then return me end
    end
    return MC.RosterDB and MC.RosterDB[name]
end

-- "You" first, then alphabetical. Used for the left list. Alts that
-- share a BNet account get collapsed to a single row showing the most-
-- recently-seen character; characters with no known BNet ID stay as
-- separate rows.
local function buildPeerOrder()
    local list = {}
    if MC.GetMeRosterEntry then
        local me = MC.GetMeRosterEntry()
        if me and me.name then
            list[#list + 1] = { name = me.name, isMe = true, entry = me }
        end
    end
    if not MC.RosterDB then return list end

    local cache = MC.RosterDB._bnetCache or {}
    local seenBnet = {}     -- bnetID -> { name = ..., entry = ..., altCount = N }
    local soloRecords = {}  -- { name, entry } for non-deduped peers

    for k, rec in pairs(MC.RosterDB) do
        -- rec.counts required: peers known only from a stray 's'/'e'/'b'
        -- message (their 'u' update was dropped) stay stored but aren't
        -- listed until real counts arrive — no phantom columns.
        if type(k) == "string" and k:sub(1, 1) ~= "_"
           and type(rec) == "table" and rec.counts and k:find("-", 1, true) then
            local bnetID = cache[k]
            if bnetID then
                local existing = seenBnet[bnetID]
                if not existing then
                    seenBnet[bnetID] = { name = k, entry = rec, altCount = 1 }
                else
                    existing.altCount = existing.altCount + 1
                    -- Most-recently-seen char wins display slot.
                    if (rec.lastSeen or 0) > (existing.entry.lastSeen or 0) then
                        existing.name  = k
                        existing.entry = rec
                    end
                end
            else
                soloRecords[#soloRecords + 1] = { name = k, entry = rec }
            end
        end
    end

    local rest = {}
    for _, g in pairs(seenBnet) do
        rest[#rest + 1] = { name = g.name, isMe = false, entry = g.entry, altCount = g.altCount }
    end
    for _, r in ipairs(soloRecords) do
        rest[#rest + 1] = { name = r.name, isMe = false, entry = r.entry, altCount = 1 }
    end
    table.sort(rest, function(a, b) return a.name:lower() < b.name:lower() end)
    for _, r in ipairs(rest) do list[#list + 1] = r end

    return list
end

-- Header line under the title: how many peers we know about, and how
-- many of them are currently in the comparison.
local function subtitleFor(peerCount)
    if peerCount == 0 then return "No peers tracked yet" end
    local s = peerCount .. (peerCount == 1 and " peer tracked" or " peers tracked")
    local n = #activePeers
    if n > 0 then s = s .. "  ·  " .. n .. " in comparison" end
    return s
end

--------------------------------------------------------------------------
-- One-shot window construction.
--------------------------------------------------------------------------
local function build()
    if FRAME then return FRAME end
    if not (MUI and MUI.CreateWindow) then
        print("|cffff8888[Collectionist]|r Window.lua did not load. Restart the "
            .. "game client fully — a /reload does not pick up newly added "
            .. "addon files.")
        return nil
    end

    local theme = MUI.Theme

    -- Global frame name kept as-is: it is what UISpecialFrames and any
    -- external reference already know this window by.
    local win = MUI.CreateWindow({
        name         = "CollectionistPeerPanel",
        title        = "Collection Inspector",
        subtitle     = subtitleFor(0),
        width        = FIXED_W + COLUMN_WIDTH,
        height       = WINDOW_H,
        db           = MC.db or {},
        posKey       = "inspectorPosition",
        scroll       = true,
        pad          = WIN_PAD,
        onClose      = function()
            -- One exit path for the header x, the footer Close, and
            -- Escape: leaving resets the session, so the next open
            -- starts from an empty comparison and re-syncs the filter
            -- from the main panel.
            wipe(activePeers)
            inspectorFilter = nil
        end,
    })
    WIN = win

    local f = win.frame
    local body = win.body
    FRAME = f

    ----------------------------------------------------------------------
    -- Header-side control: the inspector-local expansion filter. A CHILD
    -- of win.header — the header is a full-cover mouse-enabled drag
    -- surface, so a sibling at the same frame level never sees the click.
    ----------------------------------------------------------------------
    local filterBtn = MUI.MakeHeaderBtn(win.header, "Midnight",
        theme.colors.btnCloseFg,
        theme.colors.btnCloseHoverBg,
        theme.colors.btnCloseHoverBd,
        "Inspector expansion filter",
        { width = 100, height = 20 })
    if win.closeBtn then
        filterBtn:SetPoint("RIGHT", win.closeBtn, "LEFT", -6, 0)
    else
        filterBtn:SetPoint("RIGHT", win.header, "RIGHT", -10, 0)
    end

    local popup = MUI.MakeDropdown()
    local function buildItems()
        if not inspectorFilter then return {} end
        local items = {
            { label = "Current (per module)",
              selected = inspectorFilter.mode == "current",
              onClick = function()
                  inspectorFilter.mode = "current"
                  if FRAME and FRAME.RefreshFilterButton then FRAME:RefreshFilterButton() end
                  if FRAME and FRAME:IsShown() then rerender(FRAME) end
              end },
            { label = "All Expansions",
              selected = inspectorFilter.mode == "all",
              onClick = function()
                  inspectorFilter.mode = "all"
                  if FRAME and FRAME.RefreshFilterButton then FRAME:RefreshFilterButton() end
                  if FRAME and FRAME:IsShown() then rerender(FRAME) end
              end },
        }
        for _, e in ipairs(MC.EXPANSIONS or {}) do
            if not (MC._registeredExpansions and MC._registeredExpansions[e.key]) then
                -- Skeleton row: listed but greyed until content ships.
                items[#items + 1] = { label = e.label, disabled = true }
            elseif MC.IsExpansionEnabled(e.key) then
                local key = e.key
                items[#items + 1] = {
                    label = e.label,
                    selected = inspectorFilter.mode == "single" and inspectorFilter.single == key,
                    onClick = function()
                        inspectorFilter.mode = "single"
                        inspectorFilter.single = key
                        if FRAME and FRAME.RefreshFilterButton then FRAME:RefreshFilterButton() end
                        if FRAME and FRAME:IsShown() then rerender(FRAME) end
                    end,
                }
            end
        end
        return items
    end
    filterBtn:SetScript("OnClick", function()
        if popup:IsShown() then popup:Hide(); return end
        popup:ShowAt(filterBtn, "BOTTOMRIGHT", "TOPRIGHT", buildItems())
    end)

    -- Re-applies the active filter's label to the button. Called on every
    -- open (so the label tracks the panel filter) and after a selection.
    function f:RefreshFilterButton()
        local fs = filterBtn:GetFontString()
        if fs then fs:SetText(inspectorFilterLabel()) end
    end

    ----------------------------------------------------------------------
    -- Footer actions.
    ----------------------------------------------------------------------
    win:AddFooterButton("Close", { primary = true, tooltip = "Close the Inspector" },
        function() win:Close() end)

    win:AddFooterButton("Sync", { tooltip = "Ask guild peers to re-broadcast their collections" },
        function()
            -- RosterRequestSync returns false for both "sharing is off"
            -- and "no guild to ask", so the failure line covers both.
            local ok = MC.RosterRequestSync and MC.RosterRequestSync(true)
            print((MC.PREFIX or "") .. (ok
                and " Asked guild peers to re-broadcast their collections."
                or  " Nothing to sync — roster sharing is off, or you're not in a guild."))
        end)

    win:AddFooterButton("Clear", { side = "LEFT", tooltip = "Clear all peer history" },
        function() StaticPopup_Show("MIDNIGHTCOLLECTIONS_CLEAR_PEERS") end)

    ----------------------------------------------------------------------
    -- Body pane 1: the peer list. Rows are plain children of the factory's
    -- scroll child, so the window's own scrollbar carries a long roster —
    -- no nested vertical scroll frame of our own.
    ----------------------------------------------------------------------
    f.listRows = {}

    -- 1px hairline between the two panes.
    local divider = body:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", body, "TOPLEFT", LIST_WIDTH + LIST_GAP / 2, 0)
    divider:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", LIST_WIDTH + LIST_GAP / 2, 0)

    ----------------------------------------------------------------------
    -- Body pane 2: horizontally scrollable comparison columns.
    ----------------------------------------------------------------------
    f.columns = {}
    local comparison = CreateFrame("ScrollFrame", nil, body)
    comparison:SetPoint("TOPLEFT", body, "TOPLEFT", LIST_WIDTH + LIST_GAP, 0)
    comparison:SetHeight(COLUMN_CONTENT_H)
    comparison:EnableMouseWheel(true)
    f.comparisonScroll = comparison

    f.columnAnchor = CreateFrame("Frame", nil, comparison)
    f.columnAnchor:SetSize(COLUMN_WIDTH, COLUMN_CONTENT_H)
    comparison:SetScrollChild(f.columnAnchor)

    -- Wheel over the columns pans them sideways, but only while there is
    -- somewhere to pan; with everything already visible the event is
    -- handed to the window's vertical scroll so the roster still moves.
    comparison:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(f.columnAnchor:GetWidth() - self:GetWidth(), 0)
        if maxScroll <= 0 then
            local outer = win.scrollFrame
            local handler = outer and outer:GetScript("OnMouseWheel")
            if handler then handler(outer, delta) end
            return
        end
        local nextScroll = self:GetHorizontalScroll() - delta * (COLUMN_WIDTH / 2)
        self:SetHorizontalScroll(math.max(0, math.min(nextScroll, maxScroll)))
    end)

    -- Empty-comparison hint (shown when activePeers is empty).
    f.emptyText = f.columnAnchor:CreateFontString(nil, "OVERLAY")
    f.emptyText:SetFont(themeFont(), 11, fontFlags())
    f.emptyText:SetPoint("TOPLEFT", f.columnAnchor, "TOPLEFT", 0, -8)
    f.emptyText:SetWidth(220)
    f.emptyText:SetJustifyH("LEFT")
    f.emptyText:SetText("Click a name on the left to add it to the comparison.")
    f.emptyText:Hide()

    ----------------------------------------------------------------------
    -- Pane widths track the window live. The factory only re-derives the
    -- body width when a resize finishes; hooking the scroll frame instead
    -- means the panes follow every frame of the grow/shrink animation
    -- (and the scroll frame's width IS the body width the factory sets,
    -- so nothing is duplicated but the seed below).
    ----------------------------------------------------------------------
    local function layoutPanes(width)
        if not width or width <= 0 then return end
        body:SetWidth(width)
        comparison:SetWidth(math.max(width - LIST_WIDTH - LIST_GAP, COLUMN_WIDTH))
    end
    win.scrollFrame:HookScript("OnSizeChanged", function(_, w) layoutPanes(w) end)
    layoutPanes(f:GetWidth() - WIN_PAD * 2 - SCROLL_GUTTER)

    ----------------------------------------------------------------------
    -- Theme. The window paints its own chrome; this covers what we drew.
    ----------------------------------------------------------------------
    local function applyLocalTheme()
        local th = MUI and MUI.Theme
        if not th then return end
        local dv = th.colors.optionsDivider
        divider:SetColorTexture(dv[1], dv[2], dv[3], dv[4] or 0.06)
        f.emptyText:SetFont(th.font, 11, fontFlags())
        f.emptyText:SetTextColor(unpack(th.colors.textDim))
        -- List rows and columns paint from theme colors as they render,
        -- so a live theme switch needs a re-render, not a repaint.
        if FRAME and FRAME:IsShown() then rerender(FRAME) end
    end
    applyLocalTheme()
    if MUI.RegisterThemeHook then MUI.RegisterThemeHook(applyLocalTheme) end

    return f
end

--------------------------------------------------------------------------
-- Left-list row factory + render.
--------------------------------------------------------------------------
local function acquireListRow(f, idx, yOff)
    local row = f.listRows[idx]
    if not row then
        row = {}
        row.frame = CreateFrame("Frame", nil, f.body)
        row.frame:SetHeight(LIST_ROW_H)
        row.frame:EnableMouse(true)
        row.bg = row.frame:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(1, 1, 1, 0)
        row.dot = row.frame:CreateTexture(nil, "ARTWORK")
        row.dot:SetSize(6, 6)
        row.dot:SetPoint("LEFT", row.frame, "LEFT", 6, 0)
        row.label = row.frame:CreateFontString(nil, "OVERLAY")
        row.label:SetPoint("LEFT", row.dot, "RIGHT", 6, 0)
        row.label:SetPoint("RIGHT", row.frame, "RIGHT", -28, 0)
        row.label:SetJustifyH("LEFT")
        row.check = row.frame:CreateFontString(nil, "OVERLAY")
        row.check:SetPoint("RIGHT", row.frame, "RIGHT", -8, 0)
        f.listRows[idx] = row
    end
    -- Fonts re-applied per render (not just at creation) so a live theme
    -- switch re-faces the list. SetFont must precede SetText anyway.
    row.label:SetFont(themeFont(), 11, fontFlags())
    row.check:SetFont(themeFont(), 11, fontFlags())
    row.frame:ClearAllPoints()
    row.frame:SetPoint("TOPLEFT", f.body, "TOPLEFT", 0, yOff)
    row.frame:SetWidth(LIST_WIDTH)
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
    -- Inline texture, not a font glyph — sidesteps the missing-glyph
    -- tofu when the panel font doesn't cover U+2713.
    row.check:SetText(isSelected and "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t" or "")
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

-- Returns the number of peers listed and the pixel height they occupy.
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
    return #order, -yOff
end

--------------------------------------------------------------------------
-- Right-side comparison column factory + render. Columns are keyed by
-- peer name (not slot index) so each peer has a stable visual identity
-- across reorders — required for fade-in/out without flicker.
--------------------------------------------------------------------------
local function acquireColumn(f, peerName)
    local theme = MUI and MUI.Theme
    local col = f.columns[peerName]
    if not col then
        col = {}
        -- Columns must be descendants of the ScrollFrame's scroll child;
        -- anchoring an outer child to it moves the frame but bypasses
        -- the comparison viewport's clipping.
        col.frame = CreateFrame("Frame", nil, f.columnAnchor)
        col.title = col.frame:CreateFontString(nil, "OVERLAY")
        col.title:SetPoint("TOPLEFT", col.frame, "TOPLEFT", 0, 0)
        col.title:SetJustifyH("LEFT")
        col.subtitle = col.frame:CreateFontString(nil, "OVERLAY")
        col.subtitle:SetPoint("TOPLEFT", col.title, "BOTTOMLEFT", 0, -2)
        col.subtitle:SetJustifyH("LEFT")
        col.rows = {}
        f.columns[peerName] = col
    end
    col.title:SetFont(themeFont(), 12, fontFlags())
    col.subtitle:SetFont(themeFont(), 9, fontFlags())
    if theme then col.subtitle:SetTextColor(unpack(theme.colors.textDim)) end
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
        row.label:SetPoint("LEFT", row.frame, "LEFT", 0, 0)
        row.value = row.frame:CreateFontString(nil, "OVERLAY")
        row.value:SetPoint("RIGHT", row.frame, "RIGHT", 0, 0)
        row.value:SetJustifyH("RIGHT")
        local bg = row.frame:CreateTexture(nil, "ARTWORK")
        bg:SetHeight(2)
        bg:SetPoint("BOTTOMLEFT", row.frame, "BOTTOMLEFT", 0, 0)
        bg:SetPoint("BOTTOMRIGHT", row.frame, "BOTTOMRIGHT", 0, 0)
        row.barBg = bg
        local fill = row.frame:CreateTexture(nil, "OVERLAY")
        fill:SetHeight(2)
        fill:SetPoint("BOTTOMLEFT", row.frame, "BOTTOMLEFT", 0, 0)
        row.barFill = fill
        col.rows[key] = row
    end
    row.label:SetFont(themeFont(), 11, fontFlags())
    row.value:SetFont(themeFont(), 11, fontFlags())
    if theme then row.barBg:SetColorTexture(unpack(theme.colors.progressBg)) end
    row.frame:ClearAllPoints()
    row.frame:SetPoint("TOPLEFT", col.frame, "TOPLEFT", 0, yOff)
    row.frame:SetPoint("TOPRIGHT", col.frame, "TOPRIGHT", 0, yOff)
    row.frame:Show()
    return row
end

-- Picks which {collected, total} to display for a given module on a
-- given peer entry, respecting the inspector filter:
--   filter "all"              → account-wide (entry.counts)
--   filter "current"          → latest expansion's slice, like single
--   filter "single"+expKey    → entry.countsByExpansion[expKey] if the
--                               peer broadcast it; otherwise fall back
--                               to account-wide so older peers (and
--                               peers without that expansion's data)
--                               still render something useful
local function pickCounts(entry, modKey)
    if inspectorFilter and inspectorFilter.mode ~= "all" then
        local exp = inspectorFilter.mode == "single" and inspectorFilter.single
                    or (MC.GetLatestExpansion and MC.GetLatestExpansion(modKey))
        local byExp = exp and entry.countsByExpansion and entry.countsByExpansion[exp]
        if byExp and byExp[modKey] then return byExp[modKey] end
    end
    return entry.counts and entry.counts[modKey]
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
        local c = pickCounts(entry, key)
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

    -- Collection Score row at the bottom of each column. Shows the
    -- peer's broadcast totalScore, plus legacy count if non-zero.
    -- For "You", the inspector pulls from MC.GetLocalScore so the
    -- value tracks the live local state even between broadcasts.
    local total, legacy
    if entry.isMe and MC.GetLocalScore then
        total, legacy = MC.GetLocalScore()
    else
        total = entry.totalScore or 0
        legacy = entry.totalLegacyCount or 0
    end
    if total > 0 or legacy > 0 then
        local row = acquireColRow(col, "_score", yOff - 4)
        row.label:SetText("Collection Score")
        row.label:SetTextColor(0.95, 0.85, 0.45)
        row.value:SetTextColor(0.95, 0.85, 0.45)
        if legacy > 0 then
            row.value:SetText(format("%d  ·  %dL", total, legacy))
        else
            row.value:SetText(tostring(total))
        end
        -- No progress bar on the score row.
        row.barFill:SetWidth(0)
        yOff = yOff - 22 - 4
    end
    return -yOff
end

--------------------------------------------------------------------------
-- Resize. The window object owns the combat deferral, the body-width
-- re-derive and the scrollbar refresh, but SetWindowSize has no slot for
-- a completion callback and the column choreography needs one — so the
-- motion comes from lib.SizeTo and SetWindowSize is called on landing to
-- do the bookkeeping (the SetSize it performs is a no-op by then).
--------------------------------------------------------------------------
local function applySize(w, h, instant, after)
    local f = FRAME
    if instant then
        -- Hidden window: no motion to see, and no stale driver allowed
        -- to keep writing a previous target over this one.
        MUI.StopAnims(f)
        WIN:SetWindowSize(w, h)
        if after then after() end
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        -- Resizing is unsafe in combat; SetWindowSize owns the
        -- PLAYER_REGEN_ENABLED queue, so hand it over and carry on.
        -- The scroll frame clips, so columns rendered now stay inside.
        WIN:SetWindowSize(w, h)
        if after then after() end
        return
    end
    MUI.SizeTo(f, w, h, nil, function()
        WIN:SetWindowSize(w, h)
        if after then after() end
    end)
end

--------------------------------------------------------------------------
-- Re-layout based on the current activePeers list. Animations are
-- sequenced so content never overflows the window:
--   ADD:    width grows, then the new column fades in (kept invisible
--           while it would sit outside the in-progress bounds).
--   REMOVE: column fades out, then the window shrinks (so nothing is
--           visible past the new edge).
--------------------------------------------------------------------------
function rerender(f)  -- forward-declared at top of file
    -- A hidden window has no motion worth watching, and its animation
    -- groups would not advance anyway: snap everything into place so the
    -- PopIn that follows shows the finished layout.
    local instant = not f:IsShown()

    renderToken = renderToken + 1
    local token = renderToken

    local peerCount, listHeight = refreshList(f)
    WIN:SetTitle("Collection Inspector", subtitleFor(peerCount))

    local activeSet = {}
    for _, name in ipairs(activePeers) do activeSet[name] = true end

    local n = #activePeers
    local rightWidth = math.max(COLUMN_WIDTH, n * COLUMN_WIDTH + math.max(0, n - 1) * COLUMN_GAP)
    local screenWidth = (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 1280
    local visibleRightWidth = math.min(rightWidth,
        math.max(COLUMN_WIDTH, screenWidth * 0.9 - FIXED_W))
    local totalW = FIXED_W + visibleRightWidth

    f.columnAnchor:SetWidth(rightWidth)
    f.body:SetHeight(math.max(listHeight, COLUMN_CONTENT_H, 1))
    WIN:UpdateScrollBar()
    if f.comparisonScroll then
        local maxScroll = math.max(rightWidth - f.comparisonScroll:GetWidth(), 0)
        f.comparisonScroll:SetHorizontalScroll(
            math.min(f.comparisonScroll:GetHorizontalScroll(), maxScroll))
    end

    -- Identify columns that need to fade out (peer removed).
    local removing = {}
    for peerName, col in pairs(f.columns) do
        if not activeSet[peerName] and col.frame:IsShown() then
            removing[#removing + 1] = col
        end
    end

    local function hideColumn(col)
        col.frame:Hide()
        col.title:Hide()
        col.subtitle:Hide()
        for _, row in pairs(col.rows) do row.frame:Hide() end
    end

    -- Step 3: render active columns and fade in any new ones. Runs after
    -- the resize finishes, so new columns appear inside the final bounds.
    local function renderAndFadeIn()
        if token ~= renderToken then return end
        if n == 0 then
            f.emptyText:Show()
            return
        end
        f.emptyText:Hide()
        for i, peerName in ipairs(activePeers) do
            local entry = getEntry(peerName)
            if entry then
                local existing = f.columns[peerName]
                local existed = existing and existing.frame:IsShown()
                local col = acquireColumn(f, peerName)
                col.frame:ClearAllPoints()
                col.frame:SetPoint("TOPLEFT", f.columnAnchor, "TOPLEFT",
                    (i - 1) * (COLUMN_WIDTH + COLUMN_GAP), 0)
                col.frame:SetSize(COLUMN_WIDTH, COLUMN_CONTENT_H)
                renderColumn(col, entry)
                if instant or existed then
                    -- FadeIn on an already-visible frame is a no-op, but
                    -- a column re-added mid-fade-out needs its alpha put
                    -- back explicitly; StopAnims kills the outgoing group
                    -- so its OnFinished can never hide it after the fact.
                    MUI.StopAnims(col.frame)
                    col.frame:SetAlpha(1)
                else
                    col.frame:Hide()
                    MUI.FadeIn(col.frame, 0.18)
                end
            end
        end
    end

    -- Step 2: animate the window to its target size, then run step 3.
    local function animateSize()
        if token ~= renderToken then return end
        applySize(totalW, WINDOW_H, instant, renderAndFadeIn)
    end

    -- Step 1: fade out any removed columns. Once they're all invisible,
    -- run step 2. With no removals we skip straight to size + render.
    if #removing == 0 then
        animateSize()
    elseif instant then
        for _, col in ipairs(removing) do
            -- A fade left over from a pass that was interrupted by the
            -- window closing would otherwise keep ticking on a frame we
            -- are about to hide outright.
            MUI.StopAnims(col.frame)
            col.frame:SetAlpha(1)
            hideColumn(col)
        end
        animateSize()
    else
        local pending = #removing
        for _, col in ipairs(removing) do
            local fadingCol = col
            -- FadeOut hides the frame and restores alpha 1 on landing, so
            -- a later plain Show() is never invisible.
            MUI.FadeOut(fadingCol.frame, 0.15, function()
                hideColumn(fadingCol)
                pending = pending - 1
                if pending == 0 then animateSize() end
            end)
        end
    end
end

--------------------------------------------------------------------------
-- Public API.
--------------------------------------------------------------------------
function MC.ShowPeerPanel(peerName)
    if peerName then
        if not getEntry(peerName) then return end
        local idx = indexOf(activePeers, peerName)
        if idx then
            table.remove(activePeers, idx)
        else
            -- If another alt of the same BNet account is already
            -- showing, replace it rather than adding a duplicate
            -- column for the same person.
            local cache = MC.RosterDB and MC.RosterDB._bnetCache
            local newBnet = cache and cache[peerName]
            if newBnet then
                for i, existingName in ipairs(activePeers) do
                    if cache[existingName] == newBnet then
                        activePeers[i] = peerName
                        idx = i
                        break
                    end
                end
            end
            if not idx then
                table.insert(activePeers, peerName)
            end
        end
    end
    -- Initialize only once per open session. Toggling a peer while the
    -- Inspector is already visible must not reset its local filter.
    if not inspectorFilter and MC.GetExpansionFilter then
        inspectorFilter = copyFilter(MC.GetExpansionFilter())
    end
    -- Even with empty activePeers we open the window so the player can see
    -- the peer list and pick someone to compare. The right pane shows a
    -- small hint until they do.
    local f = build()
    if not f then return end
    if f.RefreshFilterButton then f:RefreshFilterButton() end
    -- Layout first, open second: while hidden the rerender is instant, so
    -- the window pops in already at its final size.
    rerender(f)
    WIN:Open()
    f:Raise()
end

function MC.HidePeerPanel()
    -- Explicit wipe as well as the window's onClose: Close() on a window
    -- that is already hidden returns without firing OnHide.
    wipe(activePeers)
    inspectorFilter = nil  -- next open re-syncs from the panel filter
    if WIN then WIN:Close() end
end

-- Allow Comms / receive paths to refresh the list when a new peer
-- broadcast arrives while the window is open.
function MC.RefreshPeerPanel()
    if FRAME and FRAME:IsShown() then rerender(FRAME) end
end

-- Confirmation dialog for the inspector's Clear button.
StaticPopupDialogs["MIDNIGHTCOLLECTIONS_CLEAR_PEERS"] = {
    text         = "Clear all tracked peers? This wipes everyone's last-known counts. They'll repopulate as guildies broadcast again.",
    button1      = "Clear",
    button2      = "Cancel",
    OnAccept     = function()
        -- Wipe the comparison list FIRST so the refresh triggered
        -- inside RosterClearHistory sees an empty active set and skips
        -- a redundant column animation pass.
        wipe(activePeers)
        if MC.RosterClearHistory then MC.RosterClearHistory() end
        if FRAME and FRAME:IsShown() then rerender(FRAME) end
    end,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
