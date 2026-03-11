local MAJOR, MINOR = "MidnightUI-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

--------------------------------------------------------------------------
-- Theme
--------------------------------------------------------------------------
lib.Theme = {
    font = STANDARD_TEXT_FONT,
    fontSize = 11,

    colors = {
        bg           = { 0.02, 0.03, 0.07, 0.96 },
        border       = { 0.15, 0.15, 0.20, 1 },
        titlebar     = { 0.04, 0.10, 0.20, 1 },
        titleBorder  = { 0.10, 0.28, 0.35, 1 },
        accent       = { 0.16, 0.78, 0.75, 1 },
        title        = { 0.85, 0.85, 0.85, 1 },
        text         = { 0.85, 0.85, 0.85, 1 },
        textDim      = { 0.38, 0.38, 0.38, 1 },
        textComplete = { 0.00, 1.00, 0.59, 1 },
        learned      = { 0.30, 0.60, 0.30, 0.60 },
        progress     = { 0.16, 0.78, 0.75, 1 },
        progressBg   = { 0.08, 0.08, 0.10, 1 },
        hoverBg      = { 1, 1, 1, 0.04 },
        headerBg     = { 0, 0, 0, 0.55 },
        -- Header button colors
        btnBg        = { 0.06, 0.12, 0.22, 0.85 },
        btnBorder    = { 0.15, 0.35, 0.40, 0.9 },
        btnCloseFg   = { 0.75, 0.28, 0.28 },
        btnCloseHoverBg = { 0.35, 0.06, 0.06 },
        btnCloseHoverBd = { 0.90, 0.25, 0.25 },
        btnTealFg    = { 0.25, 0.80, 0.68 },
        btnTealHoverBg  = { 0.06, 0.22, 0.28 },
        btnTealHoverBd  = { 0.20, 0.80, 0.65 },
        -- Profession accent colors
        profAccent = {
            [171] = { 0.30, 0.80, 0.30 },  -- Alchemy
            [333] = { 0.50, 0.30, 0.90 },  -- Enchanting
            [202] = { 0.30, 0.60, 1.00 },  -- Engineering
            [197] = { 0.90, 0.70, 0.20 },  -- Tailoring
            [185] = { 0.80, 0.40, 0.20 },  -- Cooking
            [164] = { 0.70, 0.50, 0.30 },  -- Blacksmithing
            [165] = { 0.60, 0.80, 0.40 },  -- Leatherworking
            [755] = { 0.80, 0.30, 0.60 },  -- Jewelcrafting
            [773] = { 0.40, 0.70, 0.90 },  -- Inscription
        },
        -- Header elements
        headerHover    = { 1, 1, 1, 0.05 },
        headerDivider  = { 1, 1, 1, 0.06 },
        arrowColor     = { 0.45, 0.45, 0.45 },
        countDim       = { 0.50, 0.50, 0.50 },
        learnedAccent  = { 0.30, 0.60, 0.30, 1 },
        learnedDot     = { 0.25, 0.55, 0.25, 0.6 },
        -- Count colors
        countComplete  = { 0.00, 1.00, 0.59 },
        countPartial   = { 1, 0.47, 0 },
        countNone      = { 0.6, 0.6, 0.6 },
        -- Scrollbar
        scrollTrack    = { 0, 0, 0, 0.3 },
        scrollThumb    = { 0.25, 0.65, 0.65, 0.75 },
        -- Options panel
        optionsBg      = { 0.03, 0.06, 0.12, 0.98 },
        optionsDivider = { 1, 1, 1, 0.07 },
        optionsSliderBg = { 0, 0, 0, 0.5 },
        -- Recipe row
        rowHover       = { 1, 1, 1, 0.04 },
        -- Tooltip
        ttTitle     = { 0.85, 0.85, 0.85 },
        ttLabel     = { 0.7, 0.7, 0.7 },
        ttValue     = { 0.8, 0.8, 0.8 },
        ttDropMob   = { 1, 0.8, 0.5 },
        ttDropRate  = { 1, 1, 0.5 },
        ttBoss      = { 1, 0.5, 0.3 },
        ttSpec      = { 0.8, 0.5, 0.9 },
        ttHintGreen = { 0.5, 0.8, 0.5 },
        ttHintBlue  = { 0.6, 0.7, 1.0 },
        ttCostBad   = { 1, 0.30, 0.30 },
        -- Source colors
        source = {
            trainer        = { 0.30, 0.80, 0.30 },
            vendor         = { 0.30, 0.60, 1.00 },
            discovery      = { 0.90, 0.70, 0.20 },
            specialization = { 0.80, 0.50, 0.90 },
            drop           = { 0.90, 0.40, 0.30 },
            quest          = { 0.90, 0.80, 0.20 },
        },
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

--------------------------------------------------------------------------
-- Pool class
--------------------------------------------------------------------------
lib.Pool = {}
lib.Pool.__index = lib.Pool

function lib.Pool:New()
    return setmetatable({ inactive = {}, active = {} }, self)
end

function lib.Pool:Acquire(parent)
    local frame = tremove(self.inactive)
    if not frame then
        frame = CreateFrame("Frame", nil, parent)
        frame:EnableMouse(true)
    else
        frame:SetParent(parent)
        frame:ClearAllPoints()
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
        frame:SetScript("OnMouseUp", nil)
        if frame._children then
            for _, child in pairs(frame._children) do
                if child.Hide then child:Hide() end
            end
        end
    end
    frame:Show()
    self.active[#self.active + 1] = frame
    return frame
end

function lib.Pool:ReleaseAll()
    for i = #self.active, 1, -1 do
        local frame = self.active[i]
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
        frame:SetScript("OnMouseUp", nil)
        self.inactive[#self.inactive + 1] = frame
        self.active[i] = nil
    end
end

--------------------------------------------------------------------------
-- GetOrCreate: caches children keyed by parent
--------------------------------------------------------------------------
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

--------------------------------------------------------------------------
-- CountColor (green if done, orange if partial, grey if 0)
--------------------------------------------------------------------------
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

--------------------------------------------------------------------------
-- FormatGold
--------------------------------------------------------------------------
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

--------------------------------------------------------------------------
-- MakeHeaderBtn (text label button)
--------------------------------------------------------------------------
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

--------------------------------------------------------------------------
-- MakeHeaderIconBtn (texture icon button)
--------------------------------------------------------------------------
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

--------------------------------------------------------------------------
-- RenderCollapsibleHeader (parameterized)
--------------------------------------------------------------------------
function lib.RenderCollapsibleHeader(pool, parent, yOff, opts, db, refreshCb)
    -- pool: lib.Pool instance
    -- opts: { height, indent, collKey, accentR, accentG, accentB,
    --         label, labelColor, count, countColor, icon, fontSize, countFontSize }
    -- db: addon saved variables (reads db.collapsed[collKey], db.frameAlpha)
    -- refreshCb: function() called on collapse toggle
    local theme = lib.Theme
    local collapsed = db.collapsed[opts.collKey] ~= false

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
    headerBg:SetColorTexture(0, 0, 0, 0.55 * (db.frameAlpha or 1))

    -- 2px left accent bar
    local accentBar = lib.GetOrCreate(header, "accent", function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetWidth(2)
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
            local wasCollapsed = db.collapsed[opts.collKey] ~= false
            db.collapsed[opts.collKey] = not wasCollapsed
            refreshCb()
        end
    end)
    header:SetScript("OnEnter", function() hoverTex:SetColorTexture(hc[1], hc[2], hc[3], hc[4]) end)
    header:SetScript("OnLeave", function() hoverTex:SetColorTexture(1, 1, 1, 0) end)

    return header, collapsed, yOff + opts.height + 2
end
