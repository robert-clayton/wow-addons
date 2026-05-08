local MAJOR, MINOR = "MidnightUI-1.0", 20260506
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

-- Reusing the same Theme table across lib reloads so consumers that cached
-- `local theme = lib.Theme` don't end up pointing at a stale copy.
lib.Theme = lib.Theme or {}
local _ThemeRebuild = {
    font = STANDARD_TEXT_FONT,
    fontSize = 11,

    colors = {
        -- Midnight Gilded: deep velvet darkness with Sin'dorei gold
        bg           = { 0.035, 0.028, 0.045, 0.96 },
        border       = { 0.18, 0.14, 0.08, 1 },
        titlebar     = { 0.06, 0.04, 0.03, 1 },
        titleBorder  = { 0.50, 0.36, 0.12, 0.85 },
        accent       = { 0.85, 0.60, 0.15, 1 },
        title        = { 0.92, 0.87, 0.78, 1 },
        text         = { 0.86, 0.82, 0.74, 1 },
        textDim      = { 0.40, 0.36, 0.28, 1 },
        textComplete = { 0.85, 0.62, 0.15, 1 },
        learned      = { 0.35, 0.55, 0.30, 0.60 },
        progress     = { 0.82, 0.58, 0.12, 1 },
        progressBg   = { 0.06, 0.05, 0.03, 1 },
        hoverBg      = { 1, 0.85, 0.5, 0.05 },
        headerBg     = { 0.04, 0.03, 0.02, 0.60 },
        -- Header button colors
        btnBg        = { 0.08, 0.06, 0.04, 0.85 },
        btnBorder    = { 0.40, 0.30, 0.14, 0.9 },
        btnCloseFg   = { 0.80, 0.28, 0.22 },
        btnCloseHoverBg = { 0.35, 0.06, 0.04 },
        btnCloseHoverBd = { 0.90, 0.28, 0.22 },
        btnTealFg    = { 0.85, 0.62, 0.18 },
        btnTealHoverBg  = { 0.20, 0.15, 0.04 },
        btnTealHoverBd  = { 0.85, 0.60, 0.15 },
        -- Profession accent colors
        profAccent = {
            [171] = { 0.30, 0.80, 0.30 },  -- Alchemy
            [333] = { 0.55, 0.30, 0.90 },  -- Enchanting
            [202] = { 0.35, 0.62, 1.00 },  -- Engineering
            [197] = { 0.90, 0.70, 0.22 },  -- Tailoring
            [185] = { 0.82, 0.42, 0.22 },  -- Cooking
            [164] = { 0.72, 0.52, 0.30 },  -- Blacksmithing
            [165] = { 0.60, 0.78, 0.38 },  -- Leatherworking
            [755] = { 0.82, 0.32, 0.62 },  -- Jewelcrafting
            [773] = { 0.42, 0.72, 0.90 },  -- Inscription
        },
        -- Header elements
        headerHover    = { 1, 0.85, 0.5, 0.06 },
        headerDivider  = { 0.85, 0.62, 0.15, 0.10 },
        arrowColor     = { 0.55, 0.45, 0.25 },
        countDim       = { 0.55, 0.48, 0.35 },
        learnedAccent  = { 0.35, 0.55, 0.30, 1 },
        learnedDot     = { 0.30, 0.50, 0.25, 0.6 },
        -- Count colors
        countComplete  = { 0.85, 0.62, 0.15 },
        countPartial   = { 0.92, 0.55, 0.15 },
        countNone      = { 0.50, 0.45, 0.36 },
        -- Scrollbar
        scrollTrack    = { 0.04, 0.03, 0.02, 0.4 },
        scrollThumb    = { 0.72, 0.52, 0.15, 0.65 },
        -- Options panel
        optionsBg      = { 0.04, 0.03, 0.02, 0.98 },
        optionsDivider = { 0.85, 0.62, 0.15, 0.10 },
        optionsSliderBg = { 0.02, 0.02, 0.01, 0.5 },
        -- Row hover
        rowHover       = { 1, 0.85, 0.5, 0.05 },
        -- Tooltip
        ttTitle     = { 0.92, 0.87, 0.78 },
        ttLabel     = { 0.62, 0.56, 0.46 },
        ttValue     = { 0.80, 0.76, 0.66 },
        ttDropMob   = { 1, 0.80, 0.45 },
        ttDropRate  = { 1, 0.90, 0.42 },
        ttBoss      = { 1, 0.48, 0.28 },
        ttSpec      = { 0.80, 0.50, 0.88 },
        ttHintGreen = { 0.55, 0.78, 0.42 },
        ttHintBlue  = { 0.60, 0.72, 0.95 },
        ttCostBad   = { 1, 0.30, 0.25 },
        -- Chat prefix color (warm gold)
        chat           = { 0.85, 0.65, 0.22 },
        -- Source colors (covers Recipes, Mounts, Pets, Decorations sources)
        source = {
            -- Recipes
            trainer        = { 0.35, 0.78, 0.30 },
            discovery      = { 0.90, 0.68, 0.20 },
            specialization = { 0.78, 0.50, 0.88 },
            -- Shared
            vendor         = { 0.35, 0.62, 0.98 },
            drop           = { 0.90, 0.38, 0.28 },
            quest          = { 0.90, 0.78, 0.20 },
            achievement    = { 0.90, 0.70, 0.20 },
            -- Mounts
            renown         = { 0.30, 0.60, 1.00 },
            reputation     = { 0.20, 0.50, 0.90 },
            delve          = { 0.55, 0.75, 0.90 },
            prey           = { 0.80, 0.30, 0.50 },
            dungeon        = { 0.70, 0.50, 0.90 },
            raid           = { 0.90, 0.40, 0.60 },
            pvp            = { 0.85, 0.30, 0.30 },
            worldevent     = { 0.70, 0.70, 0.70 },
            profession     = { 0.80, 0.50, 0.90 },
            prepatch       = { 0.60, 0.60, 0.60 },
            -- Pets
            wild           = { 0.40, 0.90, 0.40 },
            treasure       = { 0.85, 0.65, 0.30 },
            tradingpost    = { 0.90, 0.55, 0.80 },
            event          = { 0.70, 0.70, 0.70 },
            -- Decorations
            crafted        = { 0.80, 0.50, 0.90 },
        },
        -- Dim "secondary" text on rows
        infoText        = { 0.45, 0.45, 0.45 },
    },

    backdrop = {
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    },

    backdropSlim = {
        bgFile   = "Interface\\Buttons\\WHITE8x8",
    },
}
for k, v in pairs(_ThemeRebuild) do lib.Theme[k] = v end

function lib.ChatPrefix(name)
    local c = lib.Theme.colors.chat
    return format("|cff%02x%02x%02x[%s]|r",
        c[1] * 255, c[2] * 255, c[3] * 255, name)
end

function lib.Theme:ProfAccentColor(skillLine)
    local c = self.colors.profAccent[skillLine]
    if c then return c[1], c[2], c[3] end
    return self.colors.accent[1], self.colors.accent[2], self.colors.accent[3]
end

function lib.Theme:SourceColor(sourceType)
    local c = self.colors.source[sourceType]
    if c then return c[1], c[2], c[3] end
    return 0.7, 0.7, 0.7
end

function lib.Theme:CreateStyledFrame(parent, w, h, frameless)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(w, h)
    if frameless then
        f:SetBackdrop(self.backdropSlim)
        f:SetBackdropColor(self.colors.bg[1], self.colors.bg[2], self.colors.bg[3], self.colors.bg[4] * 0.5)
    else
        f:SetBackdrop(self.backdrop)
        f:SetBackdropColor(unpack(self.colors.bg))
        f:SetBackdropBorderColor(unpack(self.colors.border))
    end
    return f
end

-- Pool class
lib.Pool = {}
lib.Pool.__index = lib.Pool

function lib.Pool:New()
    return setmetatable({ inactive = {}, active = {} }, self)
end

-- Static row script handlers. Bound once at frame creation; they read whatever
-- callbacks the consumer stashed on the frame for the current refresh. This
-- avoids allocating a fresh closure per row per refresh (~1800 closures per
-- full refresh on a fully-expanded view) and lets ReleaseAll skip SetScript
-- entirely.
local function _staticOnEnter(self)
    if self._onEnter then self._onEnter(self) end
end
local function _staticOnLeave(self)
    if self._onLeave then self._onLeave(self) end
end
local function _staticOnMouseUp(self, button)
    if self._onMouseUp then self._onMouseUp(self, button) end
end

function lib.Pool:Acquire(parent)
    local frame = tremove(self.inactive)
    if not frame then
        frame = CreateFrame("Frame", nil, parent)
        frame:EnableMouse(true)
    else
        frame:SetParent(parent)
        frame:ClearAllPoints()
        if frame._children then
            for _, child in pairs(frame._children) do
                if child.Hide then child:Hide() end
            end
        end
    end
    -- Always (re)bind the static dispatchers. Some consumers — notably
    -- RenderCollapsibleHeader — call SetScript directly with their own
    -- closures, and that binding survives a release/reacquire cycle. If
    -- we don't re-bind here, a frame that previously hosted a recipe
    -- header would still fire the recipe refresh callback when reused
    -- as a Roster row, and clicks would visit the wrong module.
    frame:SetScript("OnEnter", _staticOnEnter)
    frame:SetScript("OnLeave", _staticOnLeave)
    frame:SetScript("OnMouseUp", _staticOnMouseUp)
    -- Clear stale callbacks; the consumer re-stashes them this refresh.
    frame._onEnter, frame._onLeave, frame._onMouseUp = nil, nil, nil
    frame:Show()
    self.active[#self.active + 1] = frame
    return frame
end

function lib.Pool:ReleaseAll()
    for i = #self.active, 1, -1 do
        local frame = self.active[i]
        frame:Hide()
        frame:ClearAllPoints()
        frame._onEnter, frame._onLeave, frame._onMouseUp = nil, nil, nil
        self.inactive[#self.inactive + 1] = frame
        self.active[i] = nil
    end
end

-- GetOrCreate: caches children keyed by parent
function lib.GetOrCreate(parent, key, createFn)
    if not parent._children then parent._children = {} end
    if not parent._children[key] then
        parent._children[key] = createFn(parent)
    else
        local child = parent._children[key]
        if child.ClearAllPoints then child:ClearAllPoints() end
    end
    local child = parent._children[key]
    child:Show()
    return child
end

-- CountColor (green if done, orange if partial, grey if 0)
function lib.CountColor(done, total)
    local colors = lib.Theme.colors
    if done >= total then
        return colors.countComplete[1], colors.countComplete[2], colors.countComplete[3]
    elseif done > 0 then
        return colors.countPartial[1], colors.countPartial[2], colors.countPartial[3]
    else
        return colors.countNone[1], colors.countNone[2], colors.countNone[3]
    end
end

-- FormatGold
function lib.FormatGold(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = gold .. "|cffffd700g|r" end
    if silver > 0 then parts[#parts + 1] = silver .. "|cffc7c7cfs|r" end
    if cop > 0 or #parts == 0 then parts[#parts + 1] = cop .. "|cffeda55fc|r" end
    return table.concat(parts, " ")
end

-- MakeHeaderBtn (text label button)
function lib.MakeHeaderBtn(parent, label, fgColor, hoverBg, hoverBd, tooltip)
    local theme = lib.Theme
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(16, 16)
    btn:SetBackdrop(theme.backdrop)
    btn:SetBackdropColor(unpack(theme.colors.btnBg))
    btn:SetBackdropBorderColor(unpack(theme.colors.btnBorder))
    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(theme.font, 11, "OUTLINE")
    lbl:SetPoint("CENTER", 0, 1)
    lbl:SetText(label)
    lbl:SetTextColor(unpack(fgColor))
    btn._label = lbl
    btn._fgColor = fgColor
    btn:SetScript("OnEnter", function(s)
        btn:SetBackdropColor(unpack(hoverBg))
        btn:SetBackdropBorderColor(unpack(hoverBd))
        lbl:SetTextColor(1, 1, 1)
        if tooltip then
            GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tooltip)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(unpack(theme.colors.btnBg))
        btn:SetBackdropBorderColor(unpack(theme.colors.btnBorder))
        lbl:SetTextColor(unpack(fgColor))
        GameTooltip:Hide()
    end)
    return btn
end

-- MakeHeaderIconBtn (texture icon button)
function lib.MakeHeaderIconBtn(parent, texPath, iconSize, fgColor, hoverBg, hoverBd, tooltip)
    local theme = lib.Theme
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(16, 16)
    btn:SetBackdrop(theme.backdrop)
    btn:SetBackdropColor(unpack(theme.colors.btnBg))
    btn:SetBackdropBorderColor(unpack(theme.colors.btnBorder))
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(iconSize, iconSize)
    icon:SetPoint("CENTER")
    icon:SetTexture(texPath)
    icon:SetVertexColor(unpack(fgColor))
    btn._icon = icon
    btn._fgColor = fgColor
    btn:SetScript("OnEnter", function(s)
        btn:SetBackdropColor(unpack(hoverBg))
        btn:SetBackdropBorderColor(unpack(hoverBd))
        icon:SetVertexColor(1, 1, 1)
        if tooltip then
            GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tooltip)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(unpack(theme.colors.btnBg))
        btn:SetBackdropBorderColor(unpack(theme.colors.btnBorder))
        icon:SetVertexColor(unpack(btn._fgColor))
        GameTooltip:Hide()
    end)
    return btn
end

-- Render a collapsible group header.
--   opts: { height, indent, collKey, accentR/G/B, label, labelColor, count,
--           countColor, [icon], [fontSize], [countFontSize] }
--   db.collapsed[collKey] holds the collapsed state; refreshCb fires on toggle.
function lib.RenderCollapsibleHeader(pool, parent, yOff, opts, db, refreshCb)
    local theme = lib.Theme
    local collapsed = db.collapsed[opts.collKey] == true

    local header = pool:Acquire(parent)
    header:SetHeight(opts.height)
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", opts.indent, -yOff)
    header:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

    -- Header background
    local headerBg = lib.GetOrCreate(header, "bg", function(p)
        local t = p:CreateTexture(nil, "BACKGROUND")
        return t
    end)
    headerBg:SetAllPoints()
    local hbg = theme.colors.headerBg
    headerBg:SetColorTexture(hbg[1], hbg[2], hbg[3], hbg[4] * (db.frameAlpha or 1))

    -- 3px left accent bar
    local accentBar = lib.GetOrCreate(header, "accent", function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetWidth(3)
        return t
    end)
    accentBar:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 0)
    accentBar:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    accentBar:SetColorTexture(opts.accentR, opts.accentG, opts.accentB, 1)

    -- Hover overlay
    local hoverTex = lib.GetOrCreate(header, "hover", function(p)
        local t = p:CreateTexture(nil, "BACKGROUND", nil, 1)
        return t
    end)
    hoverTex:SetAllPoints()
    hoverTex:SetColorTexture(1, 1, 1, 0)

    -- Optional icon
    local textAnchor = header
    local textAnchorPt = "LEFT"
    local textOfsX = 6
    if opts.icon then
        local icon = lib.GetOrCreate(header, "icon", function(p)
            local t = p:CreateTexture(nil, "ARTWORK")
            t:SetSize(20, 20)
            return t
        end)
        icon:SetPoint("LEFT", header, "LEFT", 6, 0)
        icon:SetTexture(opts.icon)
        textAnchor = icon
        textAnchorPt = "RIGHT"
        textOfsX = 6
    end

    -- Label text
    local fs = opts.fontSize or (theme.fontSize - 1)
    local nameFs = lib.GetOrCreate(header, "text", function(p)
        local f = p:CreateFontString(nil, "OVERLAY")
        f:SetFont(theme.font, fs, "OUTLINE")
        return f
    end)
    nameFs:SetFont(theme.font, fs, "OUTLINE")
    nameFs:SetPoint("LEFT", textAnchor, textAnchorPt, textOfsX, 0)
    nameFs:SetText(opts.label)
    nameFs:SetTextColor(opts.labelColor[1], opts.labelColor[2], opts.labelColor[3], opts.labelColor[4] or 1)

    -- Count (right-aligned)
    local cfs = opts.countFontSize or (theme.fontSize - 2)
    local countFs = lib.GetOrCreate(header, "count", function(p)
        local f = p:CreateFontString(nil, "OVERLAY")
        f:SetFont(theme.font, cfs, "OUTLINE")
        return f
    end)
    countFs:SetFont(theme.font, cfs, "OUTLINE")
    countFs:SetPoint("RIGHT", header, "RIGHT", -20, 0)
    countFs:SetText(opts.count)
    countFs:SetTextColor(opts.countColor[1], opts.countColor[2], opts.countColor[3])

    -- Arrow icon (8x8)
    local ac = theme.colors.arrowColor
    local arrow = lib.GetOrCreate(header, "arrow", function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetSize(8, 8)
        return t
    end)
    arrow:SetPoint("RIGHT", header, "RIGHT", -6, 0)
    if collapsed then
        arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    else
        arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    end
    arrow:SetVertexColor(ac[1], ac[2], ac[3])

    -- 1px divider
    local dc = theme.colors.headerDivider
    local divider = lib.GetOrCreate(header, "divider", function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetHeight(1)
        return t
    end)
    divider:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    divider:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    divider:SetColorTexture(dc[1], dc[2], dc[3], dc[4])

    local hc = theme.colors.headerHover
    header:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            local wasCollapsed = db.collapsed[opts.collKey] == true
            db.collapsed[opts.collKey] = not wasCollapsed
            refreshCb()
        end
    end)
    header:SetScript("OnEnter", function() hoverTex:SetColorTexture(hc[1], hc[2], hc[3], hc[4]) end)
    header:SetScript("OnLeave", function() hoverTex:SetColorTexture(1, 1, 1, 0) end)

    return header, collapsed, yOff + opts.height + 2
end

-- Static row dispatchers. RenderItemRow stashes the per-refresh callbacks
-- and the hover-tint texture on the row; these read them off the row at
-- event time so we never allocate per-row closures during a refresh.
local function _rowOnEnter(self)
    local h, c = self._hoverTex, self._hoverColor
    if h and c then h:SetColorTexture(c[1], c[2], c[3], c[4]) end
    if self._userOnEnter then self._userOnEnter(self) end
end
local function _rowOnLeave(self)
    if self._hoverTex then self._hoverTex:SetColorTexture(1, 1, 1, 0) end
    if self._userOnLeave then self._userOnLeave(self) end
end
local function _rowOnMouseUp(self, button)
    if button == "LeftButton" and self._userOnClick then self._userOnClick() end
end

-- Shared row scaffold used by every module's UI.
--   opts = { height, indent, padding,
--            leading = { kind = "icon"|"dot", size, texture, color, fallback },
--            name, info, isCollected,
--            onEnter, onLeave, onClick }
-- Returns the new yOff.
function lib.RenderItemRow(pool, parent, yOff, opts)
    local pad = opts.padding or 6
    local indent = opts.indent or 8
    local height = opts.height or 22

    local row = pool:Acquire(parent)
    row:SetHeight(height)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", indent, -yOff)
    row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

    -- Hover background
    local rc = lib.Theme.colors.rowHover
    local hoverTex = lib.GetOrCreate(row, "hover", function(p)
        return p:CreateTexture(nil, "BACKGROUND", nil, 1)
    end)
    hoverTex:SetAllPoints()
    hoverTex:SetColorTexture(1, 1, 1, 0)

    -- Leading element (icon or color dot)
    local nameOffset = pad
    local leading = opts.leading
    if leading then
        if leading.kind == "icon" then
            local sz = leading.size or 20
            local iconTex = lib.GetOrCreate(row, "icon", function(p)
                local t = p:CreateTexture(nil, "ARTWORK")
                return t
            end)
            iconTex:SetSize(sz, sz)
            iconTex:SetPoint("LEFT", row, "LEFT", pad, 0)
            iconTex:SetTexture(leading.texture or leading.fallback or "Interface\\Icons\\INV_Misc_QuestionMark")
            if opts.isCollected then
                iconTex:SetDesaturated(true)
                iconTex:SetAlpha(0.5)
            else
                iconTex:SetDesaturated(false)
                iconTex:SetAlpha(1)
            end
            -- Hide the dot if it was previously rendered on this pooled row
            local oldDot = row._children and row._children.dot
            if oldDot then oldDot:Hide() end
            nameOffset = pad + sz + 4
        elseif leading.kind == "dot" then
            local sz = leading.size or 6
            local dot = lib.GetOrCreate(row, "dot", function(p)
                local t = p:CreateTexture(nil, "ARTWORK")
                return t
            end)
            dot:SetSize(sz, sz)
            dot:SetPoint("LEFT", row, "LEFT", pad, 0)
            local color = leading.color or { 0.7, 0.7, 0.7 }
            dot:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
            local oldIcon = row._children and row._children.icon
            if oldIcon then oldIcon:Hide() end
            nameOffset = pad + sz + 6
        end
    end

    -- Name
    local theme = lib.Theme
    local nameFs = lib.GetOrCreate(row, "name", function(p)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize, "OUTLINE")
        return fs
    end)
    nameFs:SetFont(theme.font, theme.fontSize, "OUTLINE")
    nameFs:SetJustifyH("LEFT")
    nameFs:SetWordWrap(false)
    nameFs:SetPoint("LEFT", row, "LEFT", nameOffset, 0)
    nameFs:SetPoint("RIGHT", row, "RIGHT", opts.info and -50 or 0, 0)
    nameFs:SetText(opts.name or "")
    if opts.isCollected then
        nameFs:SetTextColor(unpack(theme.colors.textDim))
    else
        nameFs:SetTextColor(unpack(theme.colors.text))
    end

    -- Info (right side, dim)
    if opts.info and opts.info ~= "" then
        local infoFs = lib.GetOrCreate(row, "info", function(p)
            local fs = p:CreateFontString(nil, "OVERLAY")
            fs:SetFont(theme.font, theme.fontSize - 2, "OUTLINE")
            return fs
        end)
        infoFs:SetFont(theme.font, theme.fontSize - 2, "OUTLINE")
        infoFs:SetJustifyH("RIGHT")
        infoFs:ClearAllPoints()
        infoFs:SetPoint("RIGHT", row, "RIGHT", -pad, 0)
        infoFs:SetText(opts.info)
        infoFs:SetTextColor(unpack(theme.colors.infoText))
    elseif row._children and row._children.info then
        row._children.info:Hide()
    end

    -- Strikethrough
    local strike = lib.GetOrCreate(row, "strike", function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetHeight(1)
        return t
    end)
    if opts.isCollected then
        strike:ClearAllPoints()
        strike:SetPoint("LEFT", nameFs, "LEFT", 0, 0)
        strike:SetPoint("RIGHT", nameFs, "RIGHT", 0, 0)
        local td = theme.colors.textDim
        strike:SetColorTexture(td[1], td[2], td[3], 0.5)
        strike:Show()
    else
        strike:Hide()
    end

    -- Stash callbacks on the row so the static OnEnter/OnLeave/OnMouseUp
    -- handlers in Pool:Acquire can dispatch without allocating closures.
    row._hoverTex     = hoverTex
    row._hoverColor   = rc
    row._userOnEnter  = opts.onEnter
    row._userOnLeave  = opts.onLeave
    row._userOnClick  = opts.onClick
    row._onEnter = _rowOnEnter
    row._onLeave = _rowOnLeave
    -- Always wire OnMouseUp so collected rows still respond to shift-click
    -- (Wowhead) and ctrl-click (info dump). DoItemAction decides what to do.
    row._onMouseUp = opts.onClick and _rowOnMouseUp or nil

    return yOff + height
end

-- Zone display order used by the zone sub-grouping in Mounts/Pets.
lib.MidnightZoneOrder = {
    "Eversong Woods", "Silvermoon City", "Harandar", "Voidstorm",
    "Zul'Aman", "Isle of Quel'Danas",
}
local _zoneSet = {}
for _, z in ipairs(lib.MidnightZoneOrder) do _zoneSet[z] = true end
lib.MidnightZoneSet = _zoneSet

function lib.GroupByField(entries, field, fallback)
    local groups = {}
    for _, item in ipairs(entries) do
        local k = item[field] or fallback or "Unknown"
        if not groups[k] then groups[k] = {} end
        groups[k][#groups[k] + 1] = item
    end
    return groups
end

-- Empty-state placeholder. Pooled per-parent under the key "emptyText".
function lib.ShowEmptyMessage(parent, text, color)
    local theme = lib.Theme
    local fs = lib.GetOrCreate(parent, "emptyText", function(p)
        local f = p:CreateFontString(nil, "OVERLAY")
        f:SetFont(theme.font, theme.fontSize, "OUTLINE")
        return f
    end)
    fs:ClearAllPoints()
    fs:SetPoint("TOP", parent, "TOP", 0, -20)
    fs:SetText(text)
    local c = color or theme.colors.countDim
    fs:SetTextColor(c[1], c[2], c[3])
    fs:Show()
    return 60
end

function lib.HideEmptyMessage(parent)
    if parent._children and parent._children.emptyText then
        parent._children.emptyText:Hide()
    end
end
