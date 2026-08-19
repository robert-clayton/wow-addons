local _, MC = ...

-- Collection Inspector: a popup with a left-side peer list and a right-
-- side comparison view. Clicking a name in the list toggles that peer
-- in/out of the comparison columns.

local MUI = LibStub("MidnightUI-1.0", true)

local FRAME
local rerender  -- forward declaration: assigned below at file scope. The
                -- inspector-filter dropdown's onClick closures reference
                -- this and would otherwise resolve to a nil global at
                -- click time.
local activePeers = {}  -- ordered list of Name-Realm keys in comparison

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

local LIST_WIDTH      = 180
local LIST_ROW_H      = 18
local COLUMN_WIDTH    = 220
local COLUMN_GAP      = 12
local TITLE_BAR_H     = 24
local CONTENT_TOP_PAD = 12
local BOTTOM_PAD      = 14
local SIDE_PAD        = 14
local LIST_GAP        = 12

-- Column content height: renderColumn starts at -36 then drops -22 per
-- module row (8 modules incl. achievements), plus a Collection Score
-- row (+22, with a 4px gap above). Stays constant across peer counts
-- (columns are side-by-side, not stacked), so the panel only grows in
-- width.
local COLUMN_CONTENT_H = 36 + 8 * 22 + 26
local DEFAULT_PANEL_H  = TITLE_BAR_H + CONTENT_TOP_PAD + COLUMN_CONTENT_H + BOTTOM_PAD

-- Smooth width/height transitions via OnUpdate lerp. Ease-out cubic so
-- the resize decelerates into place. Fires onComplete once finished.
local function startSizeAnim(f, targetW, targetH, duration, onComplete)
    duration = duration or 0.18
    local fromW, fromH = f:GetWidth(), f:GetHeight()
    -- Honor the Animations preference (MidnightUI-1.0's shared flag).
    if MUI and MUI.animEnabled == false then
        f:SetScript("OnUpdate", nil)
        f:SetSize(targetW, targetH)
        if onComplete then onComplete() end
        return
    end
    if math.abs(fromW - targetW) < 0.5 and math.abs(fromH - targetH) < 0.5 then
        f:SetScript("OnUpdate", nil)
        f:SetSize(targetW, targetH)
        if onComplete then onComplete() end
        return
    end
    f._animElapsed = 0
    f:SetScript("OnUpdate", function(self, dt)
        self._animElapsed = (self._animElapsed or 0) + dt
        local t = math.min(self._animElapsed / duration, 1)
        local e = 1 - (1 - t) ^ 3
        self:SetSize(fromW + (targetW - fromW) * e, fromH + (targetH - fromH) * e)
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            if onComplete then onComplete() end
        end
    end)
end

-- Linear alpha lerp via OnUpdate. Fires onComplete when done, used to
-- hide columns once their fade-out finishes.
local function startFadeAnim(frame, targetAlpha, duration, onComplete)
    duration = duration or 0.15
    local fromAlpha = frame:GetAlpha()
    if MUI and MUI.animEnabled == false then
        frame:SetScript("OnUpdate", nil)
        frame:SetAlpha(targetAlpha)
        if onComplete then onComplete() end
        return
    end
    if math.abs(fromAlpha - targetAlpha) < 0.01 then
        frame:SetScript("OnUpdate", nil)
        frame:SetAlpha(targetAlpha)
        if onComplete then onComplete() end
        return
    end
    frame._fadeElapsed = 0
    frame:SetScript("OnUpdate", function(self, dt)
        self._fadeElapsed = (self._fadeElapsed or 0) + dt
        local t = math.min(self._fadeElapsed / duration, 1)
        self:SetAlpha(fromAlpha + (targetAlpha - fromAlpha) * t)
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            if onComplete then onComplete() end
        end
    end)
end

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

-- One-shot frame construction.
local function build()
    if FRAME then return FRAME end

    local theme = MUI and MUI.Theme

    local f = CreateFrame("Frame", "CollectionistPeerPanel", UIParent, "BackdropTemplate")
    f:SetFrameStrata("DIALOG")
    f:SetSize(LIST_WIDTH + LIST_GAP + COLUMN_WIDTH + SIDE_PAD * 2, DEFAULT_PANEL_H)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    -- Clip children to the panel's current bounds so columns extending
    -- past the edge during a width-shrink lerp don't visually overflow.
    if f.SetClipsChildren then f:SetClipsChildren(true) end
    f:Hide()

    -- Title bar
    local bar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    bar:SetHeight(TITLE_BAR_H)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    f.titleBar = bar

    f.title = bar:CreateFontString(nil, "OVERLAY")
    -- SetText requires a font to already be assigned; theme hook
    -- re-applies later on theme switch.
    f.title:SetFont((MUI and MUI.Theme and MUI.Theme.font) or STANDARD_TEXT_FONT, 12, "OUTLINE")
    f.title:SetPoint("LEFT", 10, 0)
    f.title:SetText("Collection Inspector")

    local function applyFrameTheme()
        local th = MUI and MUI.Theme
        if not th then return end
        MUI.ApplyThemedBackdrop(f, { kind = "panel", alpha = 0.97 })
        MUI.ApplyThemedBackdrop(bar, { kind = "titlebar", alpha = 1 })
        f.title:SetFont(th.font, 12, "OUTLINE")
        f.title:SetTextColor(unpack(th.colors.title))
    end
    applyFrameTheme()
    if MUI and MUI.RegisterThemeHook then
        MUI.RegisterThemeHook(applyFrameTheme)
        -- Column contents also paint via theme colors at build time, so
        -- a re-render is needed when the user switches themes.
        MUI.RegisterThemeHook(function()
            if FRAME and FRAME:IsShown() then rerender(FRAME) end
        end)
    end

    if MUI and MUI.MakeHeaderBtn then
        local close = MUI.MakeHeaderBtn(bar, "x",
            theme.colors.btnCloseFg,
            theme.colors.btnCloseHoverBg,
            theme.colors.btnCloseHoverBd,
            "Close")
        close:SetPoint("RIGHT", -4, 0)
        close:SetScript("OnClick", function()
            wipe(activePeers)
            inspectorFilter = nil
            f:Hide()
        end)

        -- Clear peer history button. Confirms before wiping so a stray
        -- click doesn't nuke the list. Wider than the default 16px to
        -- fit the word.
        local clear = MUI.MakeHeaderBtn(bar, "Clear",
            theme.colors.btnCloseFg,
            theme.colors.btnCloseHoverBg,
            theme.colors.btnCloseHoverBd,
            "Clear all peer history")
        clear:SetSize(48, 16)
        clear:SetPoint("RIGHT", close, "LEFT", -4, 0)
        clear:SetScript("OnClick", function()
            StaticPopup_Show("MIDNIGHTCOLLECTIONS_CLEAR_PEERS")
        end)

        -- Inspector-local expansion filter. Defaults to the panel's
        -- filter at open time; changing it doesn't affect the panel.
        local filterBtn = MUI.MakeHeaderBtn(bar, "Midnight",
            theme.colors.btnCloseFg,
            theme.colors.btnCloseHoverBg,
            theme.colors.btnCloseHoverBd,
            "Inspector expansion filter")
        filterBtn:SetSize(80, 16)
        filterBtn:SetPoint("RIGHT", clear, "LEFT", -4, 0)

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

        -- Re-applies the active filter's label to the button. Called
        -- on every open (so the label tracks the panel filter) and
        -- after every selection.
        function f:RefreshFilterButton()
            local fs = filterBtn:GetFontString()
            if fs then fs:SetText(inspectorFilterLabel()) end
        end
    end

    tinsert(UISpecialFrames, "CollectionistPeerPanel")

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
    -- Right-side horizontally scrollable comparison columns
    --------------------------------------------------------------------
    f.columns = {}
    local comparison = CreateFrame("ScrollFrame", nil, f)
    comparison:SetPoint("TOPLEFT", f, "TOPLEFT",
        SIDE_PAD + LIST_WIDTH + LIST_GAP, -TITLE_BAR_H - CONTENT_TOP_PAD)
    comparison:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -SIDE_PAD, BOTTOM_PAD)
    comparison:EnableMouseWheel(true)
    f.comparisonScroll = comparison

    f.columnAnchor = CreateFrame("Frame", nil, comparison)
    f.columnAnchor:SetSize(COLUMN_WIDTH, COLUMN_CONTENT_H)
    comparison:SetScrollChild(f.columnAnchor)
    comparison:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(f.columnAnchor:GetWidth() - self:GetWidth(), 0)
        local nextScroll = self:GetHorizontalScroll() - delta * (COLUMN_WIDTH / 2)
        self:SetHorizontalScroll(math.max(0, math.min(nextScroll, maxScroll)))
    end)

    -- Empty-comparison hint text (shown when activePeers is empty)
    f.emptyText = f.columnAnchor:CreateFontString(nil, "OVERLAY")
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

-- Right-side comparison column factory + render. Columns are keyed by
-- peer name (not slot index) so each peer has a stable visual identity
-- across reorders — required for fade-in/out without flicker.
local function acquireColumn(f, peerName)
    local theme = MUI and MUI.Theme
    local col = f.columns[peerName]
    if not col then
        col = {}
        -- Columns must be descendants of the ScrollFrame's scroll child;
        -- anchoring an outer-panel child to it moves the frame but bypasses
        -- the comparison viewport's clipping.
        col.frame = CreateFrame("Frame", nil, f.columnAnchor)
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
        f.columns[peerName] = col
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

-- Re-layout based on the current activePeers list. Animations are
-- sequenced so content never overflows the panel:
--   ADD:    size grows, then new column fades in (kept at alpha 0
--           while outside the in-progress bounds).
--   REMOVE: column fades to alpha 0 (becomes invisible), then panel
--           shrinks (so nothing is visible past the new edge).
function rerender(f)  -- forward-declared at top of file
    refreshList(f)

    local activeSet = {}
    for _, name in ipairs(activePeers) do activeSet[name] = true end

    local n = #activePeers
    local rightWidth = math.max(COLUMN_WIDTH, n * COLUMN_WIDTH + math.max(0, n - 1) * COLUMN_GAP)
    local fixedWidth = SIDE_PAD + LIST_WIDTH + LIST_GAP + SIDE_PAD
    local screenWidth = (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 1280
    local visibleRightWidth = math.min(rightWidth,
        math.max(COLUMN_WIDTH, screenWidth * 0.9 - fixedWidth))
    local totalW = fixedWidth + visibleRightWidth
    local totalH = DEFAULT_PANEL_H
    f.columnAnchor:SetWidth(rightWidth)
    if f.comparisonScroll then
        local maxScroll = math.max(rightWidth - visibleRightWidth, 0)
        f.comparisonScroll:SetHorizontalScroll(
            math.min(f.comparisonScroll:GetHorizontalScroll(), maxScroll))
    end

    -- Identify columns that need to fade out (peer removed).
    local removing = {}
    for peerName, col in pairs(f.columns) do
        if not activeSet[peerName] and col.frame:IsShown() and col.frame:GetAlpha() > 0.01 then
            removing[#removing + 1] = col
        end
    end

    -- Step 3: render active columns and fade in any new ones. Runs
    -- after size finishes, so new columns appear inside the panel's
    -- final bounds.
    local function renderAndFadeIn()
        if n > 0 then
            f.emptyText:Hide()
            for i, peerName in ipairs(activePeers) do
                local entry = getEntry(peerName)
                if entry then
                    local existed = f.columns[peerName]
                            and f.columns[peerName].frame:IsShown()
                            and f.columns[peerName].frame:GetAlpha() > 0.01
                    local col = acquireColumn(f, peerName)
                    col.frame:ClearAllPoints()
                    col.frame:SetPoint("TOPLEFT", f.columnAnchor, "TOPLEFT",
                        (i - 1) * (COLUMN_WIDTH + COLUMN_GAP), 0)
                    col.frame:SetSize(COLUMN_WIDTH, 1)
                    renderColumn(col, entry)
                    -- Cancel any in-flight fade on this column. If the
                    -- column was mid-fade-out from a prior remove and the
                    -- user re-added the peer, the stale OnUpdate would
                    -- continue ticking and Hide() it after we re-show.
                    col.frame:SetScript("OnUpdate", nil)
                    col.frame._fadeElapsed = nil
                    if not existed then
                        col.frame:SetAlpha(0)
                        startFadeAnim(col.frame, 1, 0.18)
                    else
                        col.frame:SetAlpha(1)
                    end
                end
            end
        else
            f.emptyText:Show()
        end
    end

    -- Step 2: animate the panel to its target size, then run step 3.
    local function animateSize()
        startSizeAnim(f, totalW, totalH, 0.18, renderAndFadeIn)
    end

    -- Step 1: fade out any removed columns. Once they're all invisible,
    -- run step 2. With no removals we skip straight to size+render.
    if #removing == 0 then
        animateSize()
    else
        local pending = #removing
        for _, col in ipairs(removing) do
            local fadingCol = col
            startFadeAnim(col.frame, 0, 0.15, function()
                fadingCol.frame:Hide()
                fadingCol.title:Hide()
                fadingCol.subtitle:Hide()
                for _, row in pairs(fadingCol.rows) do row.frame:Hide() end
                pending = pending - 1
                if pending == 0 then animateSize() end
            end)
        end
    end
end

-- Public API.
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
    -- Even with empty activePeers we open the popup so the player can see
    -- the peer list and pick someone to compare. The right pane shows a
    -- small hint until they do.
    local f = build()
    if f.RefreshFilterButton then f:RefreshFilterButton() end
    rerender(f)
    f:Show()
    f:Raise()
end

function MC.HidePeerPanel()
    wipe(activePeers)
    inspectorFilter = nil  -- next open re-syncs from the panel filter
    if FRAME then FRAME:Hide() end
end

-- Allow Comms / receive paths to refresh the list when a new peer
-- broadcast arrives while the popup is open.
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
