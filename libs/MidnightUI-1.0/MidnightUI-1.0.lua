local MAJOR, MINOR = "MidnightUI-1.0", 20260820

-- No pre-gate hook wipe here: /reload resets all Lua state, so hooks
-- can never accumulate across reloads — but a second addon embedding
-- this lib WOULD hit a pre-gate wipe and destroy the first consumer's
-- live theme hooks (NewLibrary then returns nil and nothing re-registers
-- them). Same-MINOR duplicate loads simply return below; upgrades keep
-- hooks via the `or {}` init on lib._themeHooks.
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

-- Theme registry. One flavor ("default"): flat near-black, 1px grey
-- hairlines, one saturated teal accent, un-outlined text. The registry
-- and switch machinery survive so a future look can slot in.
--
-- Consumers cache `local theme = lib.Theme`. We keep the same table
-- identity across switches by mutating sub-tables in place — see
-- _ApplyTheme below.
lib.Themes = lib.Themes or {}

-- The one and only theme (EllesmereUI-inspired origins; approximated
-- with built-in assets — no external addon's file is referenced). Flat
-- near-black shell, 1px grey hairlines, one saturated teal accent,
-- un-outlined text. The theme MACHINERY (lib.Theme live table, SetTheme,
-- RegisterThemeHook) stays: it is how every widget reads its palette.
lib.Themes.default = {
    name = "Collectionist",
    -- Barlow (SIL OFL), shipped in the lib's Media folder — a grotesque
    -- with real character at UI sizes, replacing the ARIALN stand-in.
    -- Path assumes the lib is embedded under Collectionist (its only
    -- consumer); a missing file degrades to the previously set font.
    font = "Interface\\AddOns\\Collectionist\\Libs\\MidnightUI-1.0\\Media\\Barlow-Regular.ttf",
    fontBold = "Interface\\AddOns\\Collectionist\\Libs\\MidnightUI-1.0\\Media\\Barlow-SemiBold.ttf",
    fontSize = 12,

    colors = {
        -- Flat near-black "hairline" UI, one saturated teal #0CD29D accent
        bg           = { 0.067, 0.067, 0.067, 0.97 },  -- #111111 shell
        border       = { 0.20, 0.20, 0.20, 1 },        -- 1px grey hairline
        titlebar     = { 0.03, 0.03, 0.03, 1 },        -- near-black title strip
        titleBorder  = { 0.20, 0.20, 0.20, 1 },        -- matches panel border
        accent       = { 0.047, 0.824, 0.616, 1 },     -- #0CD29D teal
        title        = { 1, 1, 1, 1 },
        text         = { 1, 1, 1, 0.92 },
        textDim      = { 0.56, 0.56, 0.56, 1 },        -- white a0.53 composited on bg
        textComplete = { 0.047, 0.824, 0.616, 1 },
        learned      = { 0.047, 0.824, 0.616, 0.55 },
        progress     = { 0.038, 0.659, 0.493, 0.95 },  -- accent x0.8
        progressBg   = { 0.02, 0.02, 0.02, 1 },
        hoverBg      = { 1, 1, 1, 0.10 },              -- flat white-wash hover
        headerBg     = { 0, 0, 0, 0.35 },              -- black alpha wash
        btnBg        = { 0.02, 0.02, 0.02, 1 },
        btnBorder    = { 0.25, 0.25, 0.25, 1 },
        btnCloseFg   = { 0.90, 0.90, 0.90 },           -- white X; lib hover forces 1,1,1
        btnCloseHoverBg = { 0.13, 0.13, 0.13 },        -- = white a0.10 over titlebar
        btnCloseHoverBd = { 0.35, 0.35, 0.35 },
        btnTealFg    = { 0.62, 0.62, 0.62 },
        btnTealHoverBg  = { 0.13, 0.13, 0.13 },
        btnTealHoverBd  = { 0.35, 0.35, 0.35 },
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
        headerHover    = { 1, 1, 1, 0.06 },
        headerDivider  = { 1, 1, 1, 0.08 },            -- row sep derives x0.6
        arrowColor     = { 0.62, 0.62, 0.62 },
        countDim       = { 0.56, 0.56, 0.56 },
        learnedAccent  = { 0.047, 0.824, 0.616, 1 },   -- "Collected" header = the accent
        learnedDot     = { 0.047, 0.824, 0.616, 0.6 },
        countComplete  = { 0.047, 0.824, 0.616 },
        countPartial   = { 0.90, 0.90, 0.90 },
        countNone      = { 0.48, 0.48, 0.48 },
        scrollTrack    = { 0, 0, 0, 0 },               -- track invisible
        scrollThumb    = { 1, 1, 1, 0.30 },            -- white strip
        optionsBg      = { 0.05, 0.07, 0.09, 0.98 },   -- blue-slate panel variant
        optionsDivider = { 1, 1, 1, 0.06 },
        optionsSliderBg = { 0.02, 0.02, 0.02, 0.6 },
        rowHover       = { 1, 1, 1, 0.05 },
        -- Semantic tooltip colors kept identical to simple/modern (they
        -- are info-semantics, not chrome).
        ttTitle     = { 1, 1, 1 },
        ttLabel     = { 0.58, 0.58, 0.60 },
        ttValue     = { 0.88, 0.88, 0.88 },
        ttDropMob   = { 1, 0.80, 0.45 },
        ttDropRate  = { 1, 0.90, 0.42 },
        ttBoss      = { 1, 0.48, 0.28 },
        ttSpec      = { 0.80, 0.50, 0.88 },
        ttHintGreen = { 0.55, 0.78, 0.42 },
        ttHintBlue  = { 0.60, 0.72, 0.95 },
        ttCostBad   = { 1, 0.30, 0.25 },
        chat           = { 0.047, 0.824, 0.616 },
        source = {
            trainer        = { 0.35, 0.78, 0.30 },
            discovery      = { 0.90, 0.68, 0.20 },
            specialization = { 0.78, 0.50, 0.88 },
            vendor         = { 0.35, 0.62, 0.98 },
            drop           = { 0.90, 0.38, 0.28 },
            quest          = { 0.90, 0.78, 0.20 },
            achievement    = { 0.90, 0.70, 0.20 },
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
            wild           = { 0.40, 0.90, 0.40 },
            treasure       = { 0.85, 0.65, 0.30 },
            tradingpost    = { 0.90, 0.55, 0.80 },
            event          = { 0.70, 0.70, 0.70 },
            crafted        = { 0.80, 0.50, 0.90 },
            -- Random world drops: no fixed vendor, boss or zone to point at.
            worlddrop      = { 0.72, 0.62, 0.45 },
            -- Exists in the client but was never released, or has since been
            -- pulled. Muted, because there is nothing to go and do.
            unavailable    = { 0.52, 0.50, 0.55 },
            -- Not a source type: the marker for "we haven't catalogued this
            -- yet". Deliberately dimmer and less saturated than the 0.7 grey
            -- SourceColor falls back to, so the group reads as pending rather
            -- than as one more ordinary category.
            unknown        = { 0.45, 0.47, 0.52 },
        },
        infoText        = { 0.48, 0.48, 0.48 },
        indicatorText      = { 0.62, 0.62, 0.62 },
        indicatorTextHover = { 1.00, 1.00, 1.00 },
        tooltipSubtext     = { 0.70, 0.70, 0.70 },
        scoreAccent        = { 0.047, 0.824, 0.616 },
        scoreAccentHover   = { 0.55, 1.00, 0.85 },
        menuText     = { 0.88, 0.88, 0.88 },
        menuHover    = { 1, 1, 1, 0.05 },
        menuSelected = { 0.047, 0.824, 0.616 },
        titleCounter = { 0.62, 0.62, 0.62 },
    },

    backdrop = {   -- 1px hairline; same shape as simple's
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    },
    backdropSlim = {
        bgFile   = "Interface\\Buttons\\WHITE8x8",
    },
    -- See the simple theme's note: small frames always take a 1px edge.
    btnBackdrop = {
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    },

    titleBarTopStripe   = false,  -- title strip stays black, no top accent
    titleBarBotStripe   = true,   -- 1px accent hairline under the title strip
    titleBarGradient    = false,  -- flat; no bevel/gradient chrome
    buttonEmboss        = false,
    progressHighlight   = false,  -- flat bars
    panelEdgeFile       = false,
    indicatorHoverUnderline = true,  -- 1px accent underline on hover
    tabActiveGradient   = false,  -- flat accent tint on the active tab
    rowSeparator        = true,   -- hairline language
    -- nineSliceFamily deliberately absent: plain 1px edge, border inset 0.
    fontOutline            = "",    -- un-outlined text (the typography signature)
    titleBarBotStripeAlpha = 0.90,  -- crisp full-strength teal hairline
}

-- Font outline flag shared by every widget FontString. Themes may set
-- `fontOutline` ("" = none, "OUTLINE", "THICKOUTLINE"); a theme without
-- the key falls back to the legacy "OUTLINE" so pre-existing themes
-- render unchanged.
function lib.FontFlags()
    return lib.Theme.fontOutline or "OUTLINE"
end

-- Display-weight face for titles/wordmarks. Themes without a fontBold
-- (modern/simple) fall back to their body face.
function lib.FontBold()
    return lib.Theme.fontBold or lib.Theme.font
end

-- Theme hook registry. Frames that paint static visuals at creation
-- time register a refresh callback so SetTheme can re-apply.
lib._themeHooks = lib._themeHooks or {}

function lib.RegisterThemeHook(fn)
    lib._themeHooks[#lib._themeHooks + 1] = fn
end

function lib.FireThemeHooks()
    for _, fn in ipairs(lib._themeHooks) do
        local ok, err = pcall(fn)
        if not ok then
            -- A hook that errors must not block the rest. Print to chat
            -- for diagnosis without taking the others down.
            print("|cffff8080[MidnightUI]|r theme hook error: " .. tostring(err))
        end
    end
end

-- The canonical Theme reference. Kept stable across SetTheme calls so
-- consumers that captured it as an upvalue still see live values.
lib.Theme = lib.Theme or {}

-- Recursive in-place merge: copies values from src into dst, replacing
-- sub-tables key-by-key so cached references to dst.subtable stay valid.
local function _wipeStaleKeys(dst, src)
    -- Remove keys in dst that aren't present in the new theme.
    -- Skip function values (methods like SourceColor/ProfAccentColor
    -- are attached to lib.Theme after load and must survive SetTheme).
    for k, v in pairs(dst) do
        if src[k] == nil and type(v) ~= "function" then
            dst[k] = nil
        end
    end
end

local function _deepMergeInto(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            -- For arrays of primitives (color tables {r,g,b[,a]}), wipe
            -- and copy. For nested maps (colors.source, profAccent),
            -- recurse so existing sub-table identities survive, and
            -- also wipe stale keys at this level so removing a source
            -- type or profession from one theme doesn't bleed across.
            if v[1] ~= nil and type(v[1]) ~= "table" then
                for i = 1, #dst[k] do dst[k][i] = nil end
                for i = 1, #v do dst[k][i] = v[i] end
                for kk, vv in pairs(v) do
                    if type(kk) ~= "number" then dst[k][kk] = vv end
                end
            else
                _wipeStaleKeys(dst[k], v)
                _deepMergeInto(dst[k], v)
            end
        else
            dst[k] = v
        end
    end
end

function lib.SetTheme(name)
    local target = lib.Themes[name]
    if not target then return false end
    _wipeStaleKeys(lib.Theme, target)
    if lib.Theme.colors then _wipeStaleKeys(lib.Theme.colors, target.colors) end
    if lib.Theme.backdrop and target.backdrop then
        _wipeStaleKeys(lib.Theme.backdrop, target.backdrop)
    end
    if lib.Theme.backdropSlim and target.backdropSlim then
        _wipeStaleKeys(lib.Theme.backdropSlim, target.backdropSlim)
    end
    if lib.Theme.btnBackdrop and target.btnBackdrop then
        _wipeStaleKeys(lib.Theme.btnBackdrop, target.btnBackdrop)
    end
    _deepMergeInto(lib.Theme, target)
    lib._activeThemeName = name
    lib.FireThemeHooks()
    return true
end

function lib.GetActiveThemeName()
    return lib._activeThemeName
end

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

-- Initial palette load. Done AFTER every method has been attached to
-- lib.Theme so the first SetTheme's _wipeStaleKeys can see them and
-- skip them.
lib.SetTheme("default")

-- Pool: per-parent reuse of generic mouseable Frames.
--   pool = lib.Pool:New()
--   row = pool:Acquire(parent)   -- returns a fresh-or-recycled Frame, parented + Shown
--   pool:ReleaseAll()            -- hides all active frames, returns them to the inactive list
-- Designed for per-refresh churn in module UIs: every Refresh() does
-- pool:ReleaseAll() at the start, then Acquire() per row. Frames carry
-- a static OnEnter/OnLeave/OnMouseUp dispatcher; consumers stash
-- per-refresh callbacks on the frame (row._onEnter etc.) instead of
-- allocating a fresh closure per row.
--
-- GetOrCreate: caches lazily-created children on a parent under a
-- string key. Use it for sub-textures / sub-fontstrings inside a pooled
-- frame so they persist across release/reacquire instead of being
-- recreated on every refresh.
lib.Pool = {}
lib.Pool.__index = lib.Pool

-- Every pool ever created, so a memory report can enumerate them without
-- knowing who owns them. A pool is never discarded (the panel and shell that
-- own them live for the session), so this registry retains nothing that was
-- not already retained.
lib._pools = lib._pools or {}

function lib.Pool:New()
    local pool = setmetatable({ inactive = {}, active = {} }, self)
    lib._pools[#lib._pools + 1] = pool
    return pool
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
        -- Also hide _decor textures (row separators, etc.). They are
        -- kept out of _children so a single consumer can persist them
        -- across renders, but on reuse by a *different* consumer (e.g. a
        -- header recycled from an item row) they must be cleared or the
        -- decoration leaks. Every _decor user re-shows what it needs.
        if frame._decor then
            for _, tex in pairs(frame._decor) do
                if tex.Hide then tex:Hide() end
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
        -- RenderItemRow also stashes the CONSUMER's callbacks and hover state,
        -- and clearing only the three dispatchers left those behind. A frame
        -- resting in the inactive list kept three closures alive, and through
        -- their upvalues the scan entry it last displayed -- so the pool held a
        -- parallel copy of the catalog that no rescan could ever free.
        frame._userOnEnter, frame._userOnLeave, frame._userOnClick = nil, nil, nil
        frame._hoverTex, frame._hoverColor = nil, nil
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

-- Cross-version gradient helper. Retail's SetGradient takes Color
-- objects; legacy SetGradientAlpha takes raw rgba. Falls back to a flat
-- color when neither path is available.
function lib.SetGradient(tex, orientation, a, b)
    if tex.SetGradient and CreateColor then
        local ok = pcall(tex.SetGradient, tex, orientation,
            CreateColor(a[1], a[2], a[3], a[4] or 1),
            CreateColor(b[1], b[2], b[3], b[4] or 1))
        if ok then return end
    end
    tex:SetColorTexture(a[1], a[2], a[3], a[4] or 1)
end
local _setGradient = lib.SetGradient

-- Per-frame decoration texture cache. Keeps these out of `_children`
-- which the pool's :Acquire hides on recycle; lets decoration helpers
-- (ApplyThemedBackdrop, ApplyButtonEmboss, row separator, etc.) be
-- called on pool-managed frames without losing the decoration on
-- recycle.
local function _decorTex(frame, key, layer, sublayer)
    frame._decor = frame._decor or {}
    if not frame._decor[key] then
        frame._decor[key] = frame:CreateTexture(nil, layer or "OVERLAY", nil, sublayer)
    end
    return frame._decor[key]
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

-- MakeHeaderBtn (text label button). `opts` is an optional table:
--   opts.width, opts.height — defaults to { 16, 16 }
function lib.MakeHeaderBtn(parent, label, fgColor, hoverBg, hoverBd, tooltip, opts)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize((opts and opts.width) or 16, (opts and opts.height) or 16)
    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(lib.Theme.font, 11, lib.FontFlags())
    lbl:SetPoint("CENTER", 0, 1)
    lbl:SetText(label)
    btn:SetFontString(lbl)
    btn._label = lbl
    btn._fgColor = fgColor

    -- All visual state lives in this closure so theme switches re-skin
    -- the button without recreating it. The color tables (fgColor,
    -- hoverBg, hoverBd, theme.colors.btnBg/btnBorder) are theme-managed
    -- so a SetTheme that mutates them in place reflects automatically;
    -- this hook re-runs SetBackdrop and the emboss decoration.
    local function applyTheme()
        local theme = lib.Theme
        btn:SetBackdrop(theme.btnBackdrop)
        btn:SetBackdropColor(unpack(theme.colors.btnBg))
        btn:SetBackdropBorderColor(unpack(theme.colors.btnBorder))
        lbl:SetFont(theme.font, 11, lib.FontFlags())
        lbl:SetTextColor(unpack(fgColor))
        lib.ApplyButtonEmboss(btn)
    end
    applyTheme()
    lib.RegisterThemeHook(applyTheme)

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
        btn:SetBackdropColor(unpack(lib.Theme.colors.btnBg))
        btn:SetBackdropBorderColor(unpack(lib.Theme.colors.btnBorder))
        lbl:SetTextColor(unpack(fgColor))
        GameTooltip:Hide()
    end)
    return btn
end

-- MakeHeaderIconBtn (texture icon button)
function lib.MakeHeaderIconBtn(parent, texPath, iconSize, fgColor, hoverBg, hoverBd, tooltip)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(16, 16)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(iconSize, iconSize)
    icon:SetPoint("CENTER")
    icon:SetTexture(texPath)
    btn._icon = icon
    btn._fgColor = fgColor

    local function applyTheme()
        local theme = lib.Theme
        btn:SetBackdrop(theme.btnBackdrop)
        btn:SetBackdropColor(unpack(theme.colors.btnBg))
        btn:SetBackdropBorderColor(unpack(theme.colors.btnBorder))
        icon:SetVertexColor(unpack(fgColor))
        lib.ApplyButtonEmboss(btn)
    end
    applyTheme()
    lib.RegisterThemeHook(applyTheme)

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
        btn:SetBackdropColor(unpack(lib.Theme.colors.btnBg))
        btn:SetBackdropBorderColor(unpack(lib.Theme.colors.btnBorder))
        icon:SetVertexColor(unpack(btn._fgColor))
        GameTooltip:Hide()
    end)
    return btn
end

-- ---------------------------------------------------------------- windowing
--
-- Row lists are windowed: a render pass walks every entry to compute layout,
-- but only builds frames for the ones near the viewport. Groups default to
-- EXPANDED, so opening Recipes asked for 10,318 frames in one pass and the
-- client visibly stalled.
--
-- The important property is that only *painting* is skipped. Every renderer
-- still advances yOff by its own height, so the content height, the scroll
-- range and the thumb are identical to what a full build produces -- the list
-- does not grow as you scroll into it.
--
-- Overscan keeps a screen of built rows above and below the viewport, so a
-- normal scroll never outruns the repaint.
local OVERSCAN = 600

-- Called once at the top of a render pass. Without it the window is nil and
-- every renderer builds unconditionally, which is exactly the old behaviour --
-- so any consumer that has not opted in keeps working.
function lib.BeginRenderPass(pool, scrollFrame)
    if not pool then return end
    pool._winTop, pool._winBot = nil, nil
    if not scrollFrame then return end
    local viewH = scrollFrame:GetHeight()
    -- Fail CLOSED. A scroll frame that has not been laid out yet reports zero
    -- height, and leaving the window nil means nothing is offscreen -- so the
    -- whole tab builds real frames, and WoW never frees a frame once created.
    -- One screen's worth is the safe assumption; the next scroll or refresh
    -- repaints with the real measurement.
    if not viewH or viewH <= 0 then viewH = 800 end
    local off = scrollFrame:GetVerticalScroll() or 0
    pool._winTop = off - OVERSCAN
    pool._winBot = off + viewH + OVERSCAN
    pool._winAt  = off
end

local function offscreen(pool, yOff, height)
    local top = pool and pool._winTop
    if not top then return false end
    return (yOff + (height or 0)) < top or yOff > pool._winBot
end
lib.IsOffscreen = offscreen

-- Callers MUST ask this before building a row, not rely on RenderItemRow to
-- skip. Lua evaluates a table constructor at the CALL SITE, before the callee
-- runs, so `RenderItemRow(pool, parent, y, { ... })` has already allocated the
-- opts table, its colour and leading sub-tables, and the onEnter/onLeave
-- closures by the time RenderItemRow could decide to skip. Windowing bounded
-- the frames and left the allocation untouched: a Recipes render pass still
-- cost ~9 MB of garbage with 63 rows painted, and the pass re-runs on scroll.
--
-- Guarding at the top of the caller's row function skips the constructor and
-- every per-row computation above it.
function lib.RowHidden(pool, yOff, height)
    return offscreen(pool, yOff, height)
end

-- Render a collapsible group header.
--   opts: { height, indent, collKey, accentR/G/B, label, labelColor, count,
--           countColor, [icon], [fontSize], [countFontSize] }
--   db.collapsed[collKey] holds the collapsed state; refreshCb fires on toggle.
function lib.RenderCollapsibleHeader(pool, parent, yOff, opts, db, refreshCb)
    local theme = lib.Theme
    local collapsed = db.collapsed[opts.collKey] == true

    -- Skipping a header must still report `collapsed`: callers decide whether
    -- to walk the children from it, and an offscreen collapsed group would
    -- otherwise lay out its entire contents and push everything below it down.
    if offscreen(pool, yOff, opts.height) then
        return nil, collapsed, yOff + opts.height + 2
    end

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
        f:SetFont(theme.font, fs, lib.FontFlags())
        return f
    end)
    nameFs:SetFont(theme.font, fs, lib.FontFlags())
    nameFs:SetPoint("LEFT", textAnchor, textAnchorPt, textOfsX, 0)
    nameFs:SetText(opts.label)
    nameFs:SetTextColor(opts.labelColor[1], opts.labelColor[2], opts.labelColor[3], opts.labelColor[4] or 1)

    -- Count (right-aligned)
    local cfs = opts.countFontSize or (theme.fontSize - 2)
    local countFs = lib.GetOrCreate(header, "count", function(p)
        local f = p:CreateFontString(nil, "OVERLAY")
        f:SetFont(theme.font, cfs, lib.FontFlags())
        return f
    end)
    countFs:SetFont(theme.font, cfs, lib.FontFlags())
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

    -- The whole point of the window: 10,290 of the Recipes tab's 10,318 rows
    -- return here without touching the frame pool.
    if offscreen(pool, yOff, height) then return yOff + height end

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
        fs:SetFont(theme.font, theme.fontSize, lib.FontFlags())
        return fs
    end)
    nameFs:SetFont(theme.font, theme.fontSize, lib.FontFlags())
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
            fs:SetFont(theme.font, theme.fontSize - 2, lib.FontFlags())
            return fs
        end)
        infoFs:SetFont(theme.font, theme.fontSize - 2, lib.FontFlags())
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

    -- Row separator: 1px hairline at the bottom edge, visible only
    -- when the active theme requests it (modern). Uses _decor so it
    -- survives the pool's _children hide-walk on Acquire.
    local sep = _decorTex(row, "rowSeparator", "ARTWORK")
    sep:ClearAllPoints()
    sep:SetHeight(1)
    sep:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", pad, 0)
    sep:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -pad, 0)
    if theme.rowSeparator then
        local d = theme.colors.headerDivider
        sep:SetColorTexture(d[1], d[2], d[3], (d[4] or 0.10) * 0.6)
        sep:Show()
    else
        sep:Hide()
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
        f:SetFont(theme.font, theme.fontSize, lib.FontFlags())
        return f
    end)
    -- Reset pass (create+reset pattern): a cached FontString keeps the
    -- font it was created with, so re-apply for live theme switches.
    fs:SetFont(theme.font, theme.fontSize, lib.FontFlags())
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

--------------------------------------------------------------------
-- Skin protocol: helpers consumers call to paint themed backdrops,
-- title bars, buttons, etc. Each manages its decoration textures via
-- GetOrCreate so repeat calls are idempotent (necessary for live theme
-- switches).
--------------------------------------------------------------------


-- Atlas-presence probe. C_Texture.GetAtlasInfo lands in 10.0+
-- (Dragonflight); returns a struct for valid atlases, nil otherwise.
local function _hasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

-- Probe-once cache of which Blizzard atlas families are available for
-- the modern theme's NineSlice border. The TWW base UI uses
-- "UI-Frame-Bronze"; older clients may not have it. The family must
-- expose at minimum -CornerTopLeft / -CornerTopRight / -CornerBottomLeft
-- / -CornerBottomRight + _<family>-Edge{Top,Bottom,Left,Right} tilers.
local _atlasFamilyCache = nil
local function _resolveAtlasFamily(preferred)
    if _atlasFamilyCache ~= nil then return _atlasFamilyCache end
    local candidates = { preferred, "UI-Frame-Bronze", "UI-Frame-Gold", "UI-Frame-Genericmetal" }
    for _, fam in ipairs(candidates) do
        if fam and _hasAtlas(fam .. "-CornerTopLeft") then
            _atlasFamilyCache = fam
            return fam
        end
    end
    _atlasFamilyCache = false
    return false
end

-- 9-slice border composed of 4 corner atlas pieces + 4 tiling edge
-- atlases. Idempotent: textures are re-acquired from the frame's
-- _decor cache. Pass nil/false `atlasFamily` to hide all pieces.
-- Returns the resolved family (or false if none available).
function lib.ApplyNineSliceBorder(frame, atlasFamily)
    local tl = _decorTex(frame, "nsTL", "OVERLAY", 7)
    local tr = _decorTex(frame, "nsTR", "OVERLAY", 7)
    local bl = _decorTex(frame, "nsBL", "OVERLAY", 7)
    local br = _decorTex(frame, "nsBR", "OVERLAY", 7)
    local et = _decorTex(frame, "nsET", "OVERLAY", 6)
    local eb = _decorTex(frame, "nsEB", "OVERLAY", 6)
    local el = _decorTex(frame, "nsEL", "OVERLAY", 6)
    local er = _decorTex(frame, "nsER", "OVERLAY", 6)

    local resolved = atlasFamily and _resolveAtlasFamily(atlasFamily) or false
    if not resolved then
        for _, t in ipairs({ tl, tr, bl, br, et, eb, el, er }) do t:Hide() end
        return false
    end

    -- Corners: atlas sized naturally (useAtlasSize = true).
    tl:SetAtlas(resolved .. "-CornerTopLeft", true)
    tl:ClearAllPoints(); tl:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0); tl:Show()

    tr:SetAtlas(resolved .. "-CornerTopRight", true)
    tr:ClearAllPoints(); tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0); tr:Show()

    bl:SetAtlas(resolved .. "-CornerBottomLeft", true)
    bl:ClearAllPoints(); bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0); bl:Show()

    br:SetAtlas(resolved .. "-CornerBottomRight", true)
    br:ClearAllPoints(); br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0); br:Show()

    -- Edges: underscore-prefixed atlas variants are the tiling versions
    -- in Blizzard's atlas naming convention.
    et:SetAtlas("_" .. resolved .. "-EdgeTop", false)
    et:ClearAllPoints()
    et:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0)
    et:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 0)
    et:SetHeight(tl:GetHeight())
    et:SetHorizTile(true)
    et:Show()

    eb:SetAtlas("_" .. resolved .. "-EdgeBottom", false)
    eb:ClearAllPoints()
    eb:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, 0)
    eb:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)
    eb:SetHeight(bl:GetHeight())
    eb:SetHorizTile(true)
    eb:Show()

    el:SetAtlas("_" .. resolved .. "-EdgeLeft", false)
    el:ClearAllPoints()
    el:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0)
    el:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", 0, 0)
    el:SetWidth(tl:GetWidth())
    el:SetVertTile(true)
    el:Show()

    er:SetAtlas("_" .. resolved .. "-EdgeRight", false)
    er:ClearAllPoints()
    er:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 0, 0)
    er:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)
    er:SetWidth(tr:GetWidth())
    er:SetVertTile(true)
    er:Show()

    return resolved
end

-- Inset (in px) that NineSlice corner textures consume off the
-- frame's inner content area. Consumers anchor inside this margin so
-- corner atlases don't occlude the title text / first row / etc.
-- Returns 0 when no NineSlice is active; otherwise reports the actual
-- corner atlas height from C_Texture.GetAtlasInfo.
function lib.GetBorderInset()
    local fam = lib.Theme.nineSliceFamily
    if not fam then return 0 end
    if not _resolveAtlasFamily(fam) then return 0 end
    local resolved = _atlasFamilyCache
    if not resolved then return 0 end
    local info = C_Texture and C_Texture.GetAtlasInfo
        and C_Texture.GetAtlasInfo(resolved .. "-CornerTopLeft")
    return (info and info.height) or 8
end

-- Apply a themed backdrop to a frame.
--   opts.kind        — "panel" | "titlebar" | "options" (palette pick)
--   opts.alpha       — multiplier on bg alpha (default 1)
--   opts.borderAlpha — explicit border alpha (default opts.alpha)
-- Frames using "titlebar" get extra decoration based on theme flags
-- (top stripe, bottom stripe, gradient).
function lib.ApplyThemedBackdrop(frame, opts)
    opts = opts or {}
    local kind = opts.kind or "panel"
    local theme = lib.Theme
    local v = opts.alpha or 1.0
    local bv = opts.borderAlpha or v

    frame:SetBackdrop(theme.backdrop)
    local bgKey = (kind == "options" and "optionsBg") or (kind == "titlebar" and "titlebar") or "bg"
    local borderKey = (kind == "titlebar" and "titleBorder") or "border"
    local bg = theme.colors[bgKey]
    local bd = theme.colors[borderKey]
    local bgA = (bg[4] or 1) * v
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bgA)
    local minBorder = (kind == "titlebar") and 0.4 or 0
    frame:SetBackdropBorderColor(bd[1], bd[2], bd[3], math.max(bv, minBorder))

    -- NineSlice atlas border for "panel" / "options" frames (not
    -- titlebars — too small for a 9-slice). Themes that opt in via
    -- nineSliceFamily get bronze atlas corners + tiling edges; if the
    -- atlas doesn't resolve, the backdrop's own edge stays visible.
    if kind == "panel" or kind == "options" then
        local applied = theme.nineSliceFamily
            and lib.ApplyNineSliceBorder(frame, theme.nineSliceFamily)
            or lib.ApplyNineSliceBorder(frame, nil)
        if applied then
            -- Hide the SetBackdrop edge so atlas + line edge don't
            -- compete; the atlas border becomes the only visible edge.
            frame:SetBackdropBorderColor(0, 0, 0, 0)
        end
    end

    if kind == "titlebar" then
        local topStripe = _decorTex(frame, "titleTopStripe", "OVERLAY")
        topStripe:ClearAllPoints()
        topStripe:SetHeight(2)
        topStripe:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        topStripe:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
        if theme.titleBarTopStripe then
            local ac = theme.colors.accent
            topStripe:SetColorTexture(ac[1], ac[2], ac[3], 0.70)
            topStripe:Show()
        else
            topStripe:Hide()
        end

        local botStripe = _decorTex(frame, "titleBotStripe", "ARTWORK")
        botStripe:ClearAllPoints()
        botStripe:SetHeight(1)
        botStripe:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 0)
        botStripe:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 0)
        if theme.titleBarBotStripe then
            local ac = theme.colors.accent
            -- Per-theme stripe strength; 0.45 is the pre-key legacy value.
            botStripe:SetColorTexture(ac[1], ac[2], ac[3], theme.titleBarBotStripeAlpha or 0.45)
            botStripe:Show()
        else
            botStripe:Hide()
        end

        -- Gradient overlay: subtle top-to-bottom warmth.
        local gradient = _decorTex(frame, "titleGradient", "BACKGROUND", 2)
        gradient:ClearAllPoints()
        gradient:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        gradient:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        if theme.titleBarGradient then
            local ac = theme.colors.accent
            _setGradient(gradient, "VERTICAL",
                { 0, 0, 0, 0 },
                { ac[1], ac[2], ac[3], 0.12 })
            gradient:Show()
        else
            gradient:Hide()
        end
    end
end

-- Button emboss: 1px lighter line on top, 1px darker line on bottom.
-- Gives the button a slight raised look. No-op when the theme doesn't
-- request it; existing decoration textures are hidden in that case.
function lib.ApplyButtonEmboss(btn)
    local theme = lib.Theme
    local top = _decorTex(btn, "embossTop", "OVERLAY")
    top:ClearAllPoints()
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    top:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -1, -1)

    local bot = _decorTex(btn, "embossBot", "ARTWORK")
    bot:ClearAllPoints()
    bot:SetHeight(1)
    bot:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 1, 0)
    bot:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 0)

    if theme.buttonEmboss then
        top:SetColorTexture(1, 1, 1, 0.10)
        bot:SetColorTexture(0, 0, 0, 0.45)
        top:Show()
        bot:Show()
    else
        top:Hide()
        bot:Hide()
    end
end

-- Progress fill highlight: 1px highlight line along the top edge of a
-- fill texture, giving it a slight 3D appearance.
-- Pass a per-bar GetOrCreate key (bars share one scroll-content parent,
-- so the key must be unique per bar) and the highlight joins the parent's
-- _children cache — the same hide-walks that hide the bar then hide it
-- too. Without a key it is cached on the fill texture itself (legacy
-- callers), where nothing auto-hides it.
function lib.ApplyProgressHighlight(fillTex, key)
    local theme = lib.Theme
    local hl
    if key then
        hl = lib.GetOrCreate(fillTex:GetParent(), key, function(p)
            return p:CreateTexture(nil, "OVERLAY")
        end)
    else
        hl = fillTex._progressHighlight
        if not hl then
            hl = fillTex:GetParent():CreateTexture(nil, "OVERLAY")
            fillTex._progressHighlight = hl
        end
    end
    hl:ClearAllPoints()
    hl:SetHeight(1)
    hl:SetPoint("TOPLEFT", fillTex, "TOPLEFT", 0, 0)
    hl:SetPoint("TOPRIGHT", fillTex, "TOPRIGHT", 0, 0)
    if theme.progressHighlight then
        hl:SetColorTexture(1, 1, 1, 0.22)
        hl:Show()
    else
        hl:Hide()
    end
end

-- Source-group header. Thin wrapper over RenderCollapsibleHeader using
-- the conventions every module shares (countColor = countDim,
-- labelColor defaults to the accent).
--
--   opts.label         — header text
--   opts.accentColor   — { r, g, b }; required
--   opts.count         — numeric; tostring'd
--   opts.collKey       — collapse-state key; required
--   opts.height        — default 20
--   opts.indent        — default 0
--   opts.labelColor    — { r, g, b[, a] }; defaults to accentColor
--   opts.icon, opts.fontSize, opts.countFontSize — pass-through
function lib.RenderSourceHeader(pool, parent, yOff, opts, db, refreshCb)
    local theme = lib.Theme
    local a = opts.accentColor
    return lib.RenderCollapsibleHeader(pool, parent, yOff, {
        height        = opts.height or 20,
        indent        = opts.indent or 0,
        collKey       = opts.collKey,
        accentR       = a[1], accentG = a[2], accentB = a[3],
        label         = opts.label,
        labelColor    = opts.labelColor or { a[1], a[2], a[3] },
        count         = tostring(opts.count),
        countColor    = theme.colors.countDim,
        icon          = opts.icon,
        fontSize      = opts.fontSize,
        countFontSize = opts.countFontSize,
    }, db, refreshCb)
end

-- "Collected/Learned/Looted/Defeated/Completed" group: green-accent
-- header followed by `opts.entries` iterated through `opts.renderRow`.
-- Returns the new yOff.
--
--   opts.entries    — array of items
--   opts.renderRow  — function(parent, item, yOff, isCollected) -> newYOff
--   opts.label      — default "Collected"
--   opts.collKey    — default "collected"
--   opts.height     — default 20
--   opts.indent     — default 0
function lib.RenderCollectedSection(pool, parent, yOff, opts, db, refreshCb)
    local theme = lib.Theme
    local la = theme.colors.learnedAccent
    local _, collapsed, newY = lib.RenderCollapsibleHeader(pool, parent, yOff, {
        height     = opts.height or 20,
        indent     = opts.indent or 0,
        collKey    = opts.collKey or "collected",
        accentR    = la[1], accentG = la[2], accentB = la[3],
        label      = opts.label or "Collected",
        labelColor = { la[1], la[2], la[3] },
        count      = tostring(#opts.entries),
        countColor = theme.colors.countDim,
    }, db, refreshCb)
    yOff = newY
    if collapsed then return yOff end
    for _, item in ipairs(opts.entries) do
        yOff = opts.renderRow(parent, item, yOff, true)
    end
    return yOff
end

-- Module-page orchestration: pool-reset → iterate-sources →
-- collected-group → progress-text → empty-message → scroll-resize.
-- Used by every "by source" module (Mounts, Pets, Toys, Decorations,
-- Rares, Treasures). Modules with bespoke shapes (Recipes per-prof,
-- Achievements per-category) drive their own loop.
--
--   opts.results             — Scanner.results { total, collectedCount, bySource, collected }
--   opts.sourceOrder         — array of source keys in render order
--   opts.renderSourceGroup   — function(parent, srcType, entries, yOff) -> newYOff
--   opts.renderRow           — function(parent, item, yOff, isCollected) -> newYOff
--                              (used by the default collected-group renderer)
--   opts.renderCollectedGroup— function(parent, entries, yOff) -> newYOff (optional override)
--   opts.collectedLabel      — default "Collected"
--   opts.collectedKey        — default "collected"
--   opts.showCollected       — boolean; default true
--   opts.sectionPad          — default 8
--   opts.emptyMessages       — { allDone, noneLeft }
--   opts.progressText        — function(r) -> string (default "X / Y")
--   opts.db, opts.refreshCb  — passed to the default collected-section header
-- Consumers set lib.defaultSortEntries once (Collectionist points it at
-- MC.SortEntries) rather than threading a sorter through every module's opts.
-- The library stays ignorant of what the ordering means.
function lib.RenderModulePage(panel, opts)
    if not panel or not panel.scrollChild then return end
    local sortEntries = opts.sortEntries or lib.defaultSortEntries
    panel.pool:ReleaseAll()
    lib.BeginRenderPass(panel.pool, panel.scrollFrame)

    local r = opts.results
    if not r or not r.total then
        panel:RefreshScrollContent(0)
        return
    end

    local child = panel.scrollChild
    local PAD = opts.sectionPad or 8
    local yOff = 0

    local seen = {}
    for _, srcType in ipairs(opts.sourceOrder or {}) do
        seen[srcType] = true
        local entries = r.bySource and r.bySource[srcType]
        if entries and #entries > 0 then
            if sortEntries then sortEntries(entries) end
            yOff = opts.renderSourceGroup(child, srcType, entries, yOff)
            yOff = yOff + PAD
        end
    end
    if r.bySource then
        for srcType, entries in pairs(r.bySource) do
            if not seen[srcType] and #entries > 0 then
                if sortEntries then sortEntries(entries) end
                yOff = opts.renderSourceGroup(child, srcType, entries, yOff)
                yOff = yOff + PAD
            end
        end
    end

    if opts.showCollected ~= false and r.collected and #r.collected > 0 then
        if sortEntries then sortEntries(r.collected) end
        if opts.renderCollectedGroup then
            yOff = opts.renderCollectedGroup(child, r.collected, yOff)
        elseif opts.renderRow then
            yOff = lib.RenderCollectedSection(panel.pool, child, yOff, {
                entries   = r.collected,
                renderRow = opts.renderRow,
                label     = opts.collectedLabel,
                collKey   = opts.collectedKey,
            }, opts.db, opts.refreshCb)
        end
    end

    if panel.titleProgressText then
        local txt
        if opts.progressText then
            txt = opts.progressText(r)
        elseif r.total > 0 then
            txt = format("%d / %d", r.collectedCount or 0, r.total)
        else
            txt = ""
        end
        panel.titleProgressText:SetText(txt)
    end

    if yOff == 0 then
        local complete = r.collectedCount == r.total and r.total > 0
        local msgs = opts.emptyMessages or {}
        local msg = (complete and msgs.allDone) or msgs.noneLeft or "Nothing to track."
        local color = complete and lib.Theme.colors.textComplete or nil
        yOff = lib.ShowEmptyMessage(child, msg, color)
    else
        lib.HideEmptyMessage(child)
    end

    panel:RefreshScrollContent(yOff)
end

-- MakeIndicatorBtn: a borderless text button used in the panel title
-- bar (filter / score / peer count). Auto-sizes to its label and swaps
-- text color on hover. Optional tooltip is either a static string or a
-- callback that populates GameTooltip with custom content.
--
--   opts.label       — initial text (default "")
--   opts.fontSize    — defaults to theme.fontSize - 1
--   opts.fgColor     — table {r,g,b}; default theme.colors.indicatorText
--   opts.hoverColor  — table {r,g,b}; default theme.colors.indicatorTextHover
--   opts.tooltip     — string OR function(self, GameTooltip)
--   opts.height      — default 16
--   opts.padding     — extra width around label; default 14
--   opts.onClick     — click handler (button arg passed through)
--
-- Returns the button. The button gains a `:SetLabel(text)` method that
-- updates the text and re-fits the button width.
function lib.MakeIndicatorBtn(parent, opts)
    opts = opts or {}
    local fg = opts.fgColor or lib.Theme.colors.indicatorText
    local hv = opts.hoverColor or lib.Theme.colors.indicatorTextHover
    local pad = opts.padding or 14
    local userFontSize = opts.fontSize

    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(opts.height or 16)
    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetPoint("CENTER")
    btn:SetFontString(fs)

    local function applyTheme()
        local theme = lib.Theme
        fs:SetFont(theme.font, userFontSize or (theme.fontSize - 1), lib.FontFlags())
        fs:SetTextColor(fg[1], fg[2], fg[3])
    end
    applyTheme()
    lib.RegisterThemeHook(applyTheme)

    -- opts.fixedWidth pins the button so its label can change without the
    -- neighbours shifting. A control that cycles through labels of different
    -- lengths otherwise nudges everything anchored to it on every click.
    function btn:SetLabel(text)
        fs:SetText(text or "")
        btn:SetWidth(opts.fixedWidth or (fs:GetStringWidth() + pad))
    end
    btn:SetLabel(opts.label or "")

    -- Underline texture, shown on hover when the theme requests it
    -- (modern). Pre-created so OnEnter is just :Show().
    local underline = _decorTex(btn, "indicatorUnderline", "OVERLAY")
    underline:SetHeight(1)
    underline:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 2, 1)
    underline:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 1)
    underline:Hide()

    btn:SetScript("OnEnter", function(s)
        fs:SetTextColor(hv[1], hv[2], hv[3])
        if lib.Theme.indicatorHoverUnderline then
            local ac = lib.Theme.colors.accent
            underline:SetColorTexture(ac[1], ac[2], ac[3], 0.85)
            underline:Show()
        end
        local tt = opts.tooltip
        if type(tt) == "string" then
            GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tt)
            GameTooltip:Show()
        elseif type(tt) == "function" then
            GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
            tt(s, GameTooltip)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function()
        fs:SetTextColor(fg[1], fg[2], fg[3])
        underline:Hide()
        GameTooltip:Hide()
    end)
    if opts.onClick then
        btn:SetScript("OnClick", opts.onClick)
    end
    return btn
end

-- MakeCheckbox: a one-shot Blizzard-template checkbox with a themed
-- label to the right. Not pooled — for fixed-position UI like the
-- onboarding popup. Returns the CheckButton; the label font string is
-- accessible as `btn._label`.
--
--   opts.label    — text to the right of the box (default "")
--   opts.fontSize — defaults to 11
--   opts.size     — checkbox size (default 22)
--   opts.checked  — initial state
--   opts.onClick  — function(checked) callback
function lib.MakeCheckbox(parent, opts)
    opts = opts or {}
    local userFontSize = opts.fontSize
    local sz = opts.size or 22
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(sz, sz)
    local fs = cb:CreateFontString(nil, "OVERLAY")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb._label = fs

    -- applyTheme MUST run before SetText below; SetText requires a
    -- font to already be assigned.
    local function applyTheme()
        local theme = lib.Theme
        fs:SetFont(theme.font, userFontSize or 11, "")
        fs:SetTextColor(unpack(theme.colors.text))
    end
    applyTheme()
    lib.RegisterThemeHook(applyTheme)
    fs:SetText(opts.label or "")

    if opts.checked ~= nil then cb:SetChecked(opts.checked and true or false) end
    if opts.onClick then
        cb:SetScript("OnClick", function(s) opts.onClick(s:GetChecked() and true or false) end)
    end
    return cb
end
