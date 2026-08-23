local addonName, MC = ...

-- Expose the namespace as a global so /run scripts and other addons can
-- reach it. Using the addon's full name avoids colliding with anything else.
_G.Collectionist = MC

MC.name = addonName
MC.version = (C_AddOns and C_AddOns.GetAddOnMetadata
                and C_AddOns.GetAddOnMetadata(addonName, "Version")) or "dev"

local MUI = LibStub("MidnightUI-1.0", true)
if not MUI then
    error(addonName .. ": failed to load MidnightUI-1.0 library")
end
local PREFIX = MUI.ChatPrefix("Collectionist")
MC.PREFIX = PREFIX

-- Bumped when SavedVariables shape changes; MigrateDB reads it.
local DB_VERSION = 1

-- Cross-fade for switching what the content area shows.
MC.TAB_FADE = 0.3
-- Marker we set on the per-character DB the first time the v1->v2 flip runs
-- (per-character primary, account-wide DB demoted to "last-logged-out snapshot"
-- used to seed brand-new alts).
local CHAR_DB_VERSION = 2

--------------------------------------------------------------------------
-- Deep-merge defaults into a saved DB without overwriting existing values.
--------------------------------------------------------------------------
function MC.DeepMergeDefaults(target, source)
    for k, v in pairs(source) do
        if target[k] == nil then
            target[k] = type(v) == "table" and CopyTable(v) or v
        elseif type(v) == "table" and type(target[k]) == "table" then
            MC.DeepMergeDefaults(target[k], v)
        end
    end
end

--------------------------------------------------------------------------
-- Module registry
--------------------------------------------------------------------------
MC.modules = {}
MC.modulesByKey = {}
MC.activeModule = nil

--------------------------------------------------------------------------
-- What the content area is showing. One selection, two kinds: a module
-- key, or MC.OPTIONS_KEY for the Options view (premium shell only — the
-- classic panel keeps its settings window). MC.SwitchTab takes either and
-- runs the same cross-fade for both.
--
-- MC.activeModule keeps naming the last TRACKER shown even while Options
-- is up, so the expansion filter, the score tooltip and `/mc collected`
-- all still have a module to talk about; MC.IsOptionsSelected() is what
-- the render paths branch on. The sentinel is namespaced so it can never
-- collide with a module key.
--------------------------------------------------------------------------
MC.OPTIONS_KEY = "__options"
MC.activeSelection = nil

function MC.IsOptionsSelected()
    return MC.activeSelection == MC.OPTIONS_KEY
end

function MC.RegisterModule(key, opts)
    local mod = {
        key   = key,
        label = opts.label,
        icon  = opts.icon,
        order = opts.order or (#MC.modules + 1),
        opts  = opts,
        db    = nil,
        Scanner = nil,
        UI      = nil,
    }
    MC.modules[#MC.modules + 1] = mod
    MC.modulesByKey[key] = mod
    table.sort(MC.modules, function(a, b) return a.order < b.order end)
    return mod
end

--------------------------------------------------------------------------
-- Content registration. Each expansion's data file calls into this so
-- the per-module lists (MC.MountData, MC.PetData, etc.) build up
-- additively. Each top-level group gets `expansion` stamped on it so
-- scanners and the UI filter can route entries by expansion.
--
-- Per-module content destination is determined by the moduleKey:
--   mounts       -> MC.MountData
--   pets         -> MC.PetData
--   toys         -> MC.ToyData
--   decorations  -> MC.DecorationData
--   rares        -> MC.RareData
--   treasures    -> MC.TreasureData
--   achievements -> MC.AchievementData
--
-- Recipes route differently: profession recipe data lives in the
-- per-skillline tables (MC.AlchemyRecipes etc.), so a "recipes" group
-- carries a `skillLine` and a `recipes` list and is appended to the
-- matching per-profession table as a new category. Because the base
-- per-profession files (Modules/Recipes/Data/Alchemy.lua etc.) assign
-- MC.<Prof>Recipes wholesale, expansion recipe data files MUST be
-- listed in the TOC after them or the appended groups are clobbered.
--------------------------------------------------------------------------
MC._registeredExpansions = {}

local CONTENT_TARGETS = {
    mounts       = "MountData",
    pets         = "PetData",
    toys         = "ToyData",
    decorations  = "DecorationData",
    rares        = "RareData",
    treasures    = "TreasureData",
    achievements = "AchievementData",
}

-- skillLine -> per-profession recipe table name on MC. Shared with
-- Modules/Recipes/Scanner.lua so the routing and the scan stay in sync.
MC.RECIPE_DATA_KEYS = {
    [171] = "AlchemyRecipes",
    [164] = "BlacksmithingRecipes",
    [185] = "CookingRecipes",
    [333] = "EnchantingRecipes",
    [202] = "EngineeringRecipes",
    [773] = "InscriptionRecipes",
    [755] = "JewelcraftingRecipes",
    [165] = "LeatherworkingRecipes",
    [197] = "TailoringRecipes",
}

local function markContentRegistered(expansionKey, moduleKey)
    MC._registeredExpansions[expansionKey] = true
    MC._registeredExpansionsByModule = MC._registeredExpansionsByModule or {}
    MC._registeredExpansionsByModule[moduleKey] = MC._registeredExpansionsByModule[moduleKey] or {}
    MC._registeredExpansionsByModule[moduleKey][expansionKey] = true
    -- Invalidate the latest-expansion cache so the next read picks up
    -- newly-registered expansions.
    MC._latestExpansionKey = nil
    MC._latestExpansionByModule = nil
end

-- Recipes branch of RegisterContent. Each group is one category
-- appended to the matching per-profession table:
--   { skillLine = 171, name = "The War Within", recipes = { ... } }
-- Entry fields match the existing per-profession Data files (id, name,
-- source, sourceInfo, priority, waypoint, cost, dropInfo, score, ...).
local function StampRecipeGroup(expansionKey, group)
    group.expansion = group.expansion or expansionKey
    group.moduleKey = group.moduleKey or "recipes"
    for _, recipe in ipairs(group.recipes) do
        recipe.expansion = recipe.expansion or expansionKey
        recipe.moduleKey = recipe.moduleKey or "recipes"
        recipe.availableAfter = recipe.availableAfter or group.availableAfter
    end
end

local function RegisterRecipeContent(expansionKey, groups)
    local registeredAny = false
    for _, group in ipairs(groups) do
        local targetField = MC.RECIPE_DATA_KEYS[group.skillLine]
        if not targetField then
            print(format("|cffff8888[Collectionist]|r RegisterContent: recipes group '%s' has unknown skillLine '%s'",
                tostring(group.name), tostring(group.skillLine)))
        elseif type(group.recipes) ~= "table" then
            print(format("|cffff8888[Collectionist]|r RegisterContent: recipes group '%s' has no recipes list",
                tostring(group.name)))
        else
            StampRecipeGroup(expansionKey, group)
            if not MC[targetField] then MC[targetField] = {} end
            local target = MC[targetField]
            target[#target + 1] = group
            registeredAny = true
        end
    end
    if registeredAny then
        markContentRegistered(expansionKey, "recipes")
    end
end

-- Adopt a profession table that was assigned directly by a legacy data file.
-- This stamps its existing categories without appending or copying them, then
-- registers the expansion so Current/single-expansion filters can resolve it.
-- New expansion files should continue using RegisterContent instead.
function MC.RegisterExistingRecipeContent(expansionKey, skillLine)
    local targetField = MC.RECIPE_DATA_KEYS[skillLine]
    local target = targetField and MC[targetField]
    if not expansionKey or type(target) ~= "table" then return false end

    local registeredAny = false
    for _, group in ipairs(target) do
        if type(group.recipes) == "table" then
            StampRecipeGroup(expansionKey, group)
            registeredAny = true
        end
    end
    if registeredAny then
        markContentRegistered(expansionKey, "recipes")
    end
    return registeredAny
end

function MC.RegisterContent(expansionKey, moduleKey, groups)
    if not (expansionKey and moduleKey and groups) then return end
    if moduleKey == "recipes" then
        return RegisterRecipeContent(expansionKey, groups)
    end
    local targetField = CONTENT_TARGETS[moduleKey]
    if not targetField then
        print(format("|cffff8888[Collectionist]|r RegisterContent: unknown module '%s'",
            tostring(moduleKey)))
        return
    end
    -- Append to MC.<X>Data. Multiple files registering the same
    -- (module, expansion) combo is allowed — useful when an expansion's
    -- data grows large enough to warrant splitting into per-source
    -- files. /reload resets Lua state so MC[targetField] starts empty
    -- on each session; no idempotency guard needed.
    if not MC[targetField] then MC[targetField] = {} end
    local target = MC[targetField]

    for _, group in ipairs(groups) do
        -- Stamp expansion on the group itself and on each entry within.
        -- Entries inherit at scan time via group.expansion; per-entry
        -- stamping is belt-and-suspenders for code paths that read the
        -- entry directly (Inspector, Sharing).
        group.expansion = group.expansion or expansionKey
        group.moduleKey = group.moduleKey or moduleKey
        -- Inner-list keys: matches CONTENT_TARGETS module keys plus
        -- "items" (a generic catch-all used by some Decorations groups).
        for _, listKey in ipairs({ "mounts", "pets", "toys", "decorations",
                                   "rares", "treasures", "achievements",
                                   "items" }) do
            local list = group[listKey]
            if type(list) == "table" then
                for _, entry in ipairs(list) do
                    entry.expansion = entry.expansion or expansionKey
                    entry.moduleKey = entry.moduleKey or moduleKey
                    entry.availableAfter = entry.availableAfter or group.availableAfter
                    if group.navigationOnly and entry.navigationOnly == nil then
                        entry.navigationOnly = true
                    end
                end
            end
        end
        target[#target + 1] = group
    end

    markContentRegistered(expansionKey, moduleKey)
end

--------------------------------------------------------------------------
-- Expansion filter. Scanners call MC.IsGroupVisible(group) to decide
-- whether to include a content group in the scan. The filter has
-- three modes:
--   "current" — show only the latest expansion that has data
--   "single"  — show only the expansion named in db.expansionFilter.single
--   "all"     — show every expansion's data
-- Default is "current" so existing players see no behavior change.
--------------------------------------------------------------------------
-- Survives only as the Collection Inspector's starting scope for peer
-- columns; the browse tabs no longer filter. Defaults to "all" now that
-- Options decides what is shown.
function MC.GetExpansionFilter()
    if not MC.db then return { mode = "all" } end
    if not MC.db.expansionFilter then
        MC.db.expansionFilter = { mode = "all" }
    end
    return MC.db.expansionFilter
end

-- Visibility is now a single question: is this expansion switched on in
-- Options > Expansions. The title-bar filter that used to scope the list
-- to one expansion (or the current one) is gone — two controls deciding
-- what a tab shows was one too many.
function MC.IsGroupVisible(group)
    if not group then return true end
    -- Groups without an expansion stamp are pre-1.7.0 entries — show
    -- them so legacy data doesn't silently disappear.
    if not group.expansion then return true end
    return MC.IsExpansionEnabled(group.expansion)
end

-- Longer-form scope label for chat summaries, so filter-scoped output
-- (e.g. the minimap right-click source breakdowns) can say which slice
-- of the collection it covers.
function MC.GetFilterScopeLabel()
    -- No per-tab filter any more: the scope is whatever Options has
    -- switched on. Named counts read better than a bare "enabled".
    local on = {}
    for _, e in ipairs(MC.EXPANSIONS or {}) do
        if MC._registeredExpansions and MC._registeredExpansions[e.key]
           and MC.IsExpansionEnabled(e.key) then
            on[#on + 1] = e.label
        end
    end
    if #on == 0 then return "no expansions" end
    if #on == 1 then return on[1] end
    return format("%d expansions", #on)
end

--------------------------------------------------------------------------
-- Module reorder. The user can rearrange modules via up/down arrows in
-- the options panel; the chosen order persists per-character in
-- MC.db.moduleOrder. ApplyModuleOrder rebuilds the runtime list and
-- triggers the tab bar to reflow.
--
-- The default uses each module's registration `order` value, so newly
-- registered modules slot in based on their declared order until the
-- user reorders them.
--------------------------------------------------------------------------
function MC.ApplyModuleOrder()
    if not MC.modules then return end
    local override = MC.db and MC.db.moduleOrder
    table.sort(MC.modules, function(a, b)
        local oa = override and override[a.key] or a.order
        local ob = override and override[b.key] or b.order
        if oa == ob then return a.key < b.key end
        return oa < ob
    end)
    if MC.TabBar and MC.TabBar.Reflow then MC.TabBar:Reflow() end
end

function MC.MoveModule(key, direction)
    if not (MC.db and MC.modules) then return end
    -- Find current visible index in MC.modules
    local idx
    for i, m in ipairs(MC.modules) do
        if m.key == key then idx = i; break end
    end
    if not idx then return end
    local target = idx + direction
    if target < 1 or target > #MC.modules then return end
    -- Swap by giving the two modules each other's effective order.
    MC.db.moduleOrder = MC.db.moduleOrder or {}
    -- Capture the current effective ordering (1..N) into the override so
    -- subsequent swaps can use it consistently regardless of registration
    -- order vs prior overrides.
    for i, m in ipairs(MC.modules) do
        MC.db.moduleOrder[m.key] = i
    end
    -- Now swap the two
    local a = MC.modules[idx].key
    local b = MC.modules[target].key
    MC.db.moduleOrder[a], MC.db.moduleOrder[b] = MC.db.moduleOrder[b], MC.db.moduleOrder[a]
    MC.ApplyModuleOrder()
    if MC.BuildConfig then MC.BuildConfig() end
end

--------------------------------------------------------------------------
-- All settings live in the per-character DB (CollectionistCharDB) as
-- of v2. The account-wide DB (CollectionistDB) is now a "last logged-out
-- snapshot" written on PLAYER_LOGOUT and consumed once when a brand-new alt
-- first enters the game (so they inherit the most recent character's prefs
-- instead of starting from defaults).
--------------------------------------------------------------------------
-- Account-wide ledgers that live only in CollectionistDB. They must
-- survive the PLAYER_LOGOUT snapshot (which otherwise rebuilds the
-- account DB from the per-character DB) and must never be seeded into
-- a CharDB — a per-character copy would overwrite the live ledger with
-- stale data at that character's next logout.
local ACCOUNT_ONLY_KEYS = {
    recipesLearned = true,
    -- Search recents are written straight to CollectionistDB; without
    -- this flag the logout snapshot's clear loop would erase them every
    -- session and the copy loop could never restore them.
    searchRecents = true,
}

-- Strictly per-character state that must never ride the PLAYER_LOGOUT
-- snapshot into the account-wide seed pool (a brand-new alt must not
-- inherit another character's pinned Targets).
local CHAR_ONLY_KEYS = {
    targets = true,
}

local charDefaults = {
    dbVersion        = DB_VERSION,
    minimap          = { minimapPos = 225, hide = false },
    position         = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 },
    locked           = false,
    panelShown       = false,
    minimized        = false,
    frameAlpha       = 1.0,
    frameScale       = 1.0,
    panelWidth       = 520,
    panelHeight      = 560,
    disabledModules  = {},
    animations       = true,
    -- Game-wide item-tooltip status (Tooltips.lua). Off means the line
    -- never appends; the tri-state in Tooltips.lua caches until toggled.
    tooltipStatusDisabled = false,
    -- Expansions hidden from the browse lists. Purely a display filter:
    -- totals, Collection Score, Legacies, and sharing keep counting a
    -- disabled expansion's content.
    disabledExpansions = {},
    activeTab        = "mounts",
}

--------------------------------------------------------------------------
-- Module enabled check
--------------------------------------------------------------------------
function MC.IsModuleEnabled(key)
    return not MC.db.disabledModules[key]
end

--------------------------------------------------------------------------
-- Expansion browse toggle. Disabling an expansion hides its rows from
-- the tab lists ("what to get next" browsing) without touching totals,
-- Collection Score, Legacies, or sharing — accumulation is unaffected.
--------------------------------------------------------------------------
function MC.IsExpansionEnabled(key)
    if not key then return true end
    return not (MC.db and MC.db.disabledExpansions
                and MC.db.disabledExpansions[key])
end

function MC.SetExpansionEnabled(key, enabled)
    if not (MC.db and key) then return end
    MC.db.disabledExpansions = MC.db.disabledExpansions or {}
    if enabled then
        MC.db.disabledExpansions[key] = nil
    else
        MC.db.disabledExpansions[key] = true
    end
    -- GetLatestExpansion resolves against enabled expansions, so drop
    -- the memos and let it re-derive.
    MC._latestExpansionKey = nil
    MC._latestExpansionByModule = nil
    -- Visibility is baked into scanner results, so re-scan.
    if MC.modules and MC.ThrottledScan then
        for _, m in ipairs(MC.modules) do
            if m.Scanner and m.Scanner.Scan then
                MC.ThrottledScan(m, 0)
            end
        end
    end
    if MC.RefreshActive then MC.RefreshActive() end
    if MC.RefreshExpansionFilterButton then MC.RefreshExpansionFilterButton() end
end

--------------------------------------------------------------------------
-- Theme. One look now; the selector is gone and UI style (classic /
-- premium shells) is the appearance axis. Saved theme names from older
-- versions ("modern"/"simple"/"ellesmere") are deliberately ignored.
-- The accessors stay so a future second look can slot back in.
--------------------------------------------------------------------------
function MC.GetTheme()
    return "default"
end

function MC.SetTheme(name)
    if not (MUI and MUI.Themes and MUI.Themes[name]) then return end
    MUI.SetTheme(name)
end

function MC.FirstEnabledModule()
    for _, mod in ipairs(MC.modules) do
        if MC.IsModuleEnabled(mod.key) then return mod.key end
    end
end

function MC.SetModuleEnabled(key, enabled)
    if enabled then
        MC.db.disabledModules[key] = nil
    else
        MC.db.disabledModules[key] = true
    end
    if MC.TabBar then MC.TabBar:Reflow() end

    if enabled then
        local mod = MC.modulesByKey[key]
        if mod then
            if mod.opts.events and MC.eventFrame then
                for _, ev in ipairs(mod.opts.events) do
                    pcall(MC.eventFrame.RegisterEvent, MC.eventFrame, ev)
                end
                MC._RebuildEventMap()
            end
            if mod.Scanner then MC.ScanNow(mod) end
        end
    end

    -- Active tab disabled? Fall back to the first enabled module, or
    -- show a placeholder if everything is off.
    if not enabled and MC.activeModule == key then
        local first = MC.FirstEnabledModule()
        if MC.IsOptionsSelected() then
            -- The toggle came from the Options page itself, which owns
            -- the content area. Re-point the "last tracker" so leaving
            -- Options lands on something enabled, but do not yank the
            -- user off the page they are still using.
            MC.activeModule = first
            if first and MC.cdb then MC.cdb.activeTab = first end
        elseif first then
            MC.SwitchTab(first)
        else
            MC.activeModule = nil
            MC.activeSelection = nil
            if MC.panel and MC.panel.scrollChild and MC.panel.scrollChild._children then
                for _, child in pairs(MC.panel.scrollChild._children) do
                    if child.Hide then child:Hide() end
                end
            end
            MC._ShowAllDisabledPlaceholder()
        end
    end

    -- Deferred so we don't mutate defs mid-iteration if the toggle came
    -- from clicking a checkbox in the config panel.
    C_Timer.After(0, MC.BuildConfig)
end

function MC._ShowAllDisabledPlaceholder()
    if not MC.panel or not MC.panel.scrollChild then return end
    local theme = MUI.Theme
    local fs = MUI.GetOrCreate(MC.panel.scrollChild, "allDisabledText", function(p)
        local t = p:CreateFontString(nil, "OVERLAY")
        t:SetFont(theme.font, theme.fontSize, "OUTLINE")
        return t
    end)
    fs:ClearAllPoints()
    fs:SetPoint("TOP", MC.panel.scrollChild, "TOP", 0, -20)
    fs:SetText("All modules disabled. Enable one in options.")
    fs:SetTextColor(0.7, 0.7, 0.7)
    fs:Show()
    if MC.panel.titleProgressText then MC.panel.titleProgressText:SetText("") end
end

--------------------------------------------------------------------------
-- Shift-click popup that lets the user copy a Wowhead URL
--------------------------------------------------------------------------
StaticPopupDialogs["MIDNIGHTCOLLECTIONS_WOWHEAD"] = {
    text = "Copy Wowhead URL:",
    button1 = CLOSE,
    hasEditBox = true,
    editBoxWidth = 280,
    -- StaticPopup_Show stashes the data argument on the dialog frame as
    -- self.data, regardless of whether OnShow gets it as a second argument
    -- (Blizzard has changed that signature between versions).
    OnShow = function(self, data)
        local url = data or self.data or ""
        local editBox = self.editBox or self.EditBox
        if editBox then
            editBox:SetText(url)
            editBox:HighlightText()
            editBox:SetFocus()
        end
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    EditBoxOnEnterPressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

--------------------------------------------------------------------------
-- Single shared info tooltip — created once and reused by every row hover
--------------------------------------------------------------------------
local infoTooltip

function MC.GetInfoTooltip()
    if not infoTooltip then
        infoTooltip = CreateFrame("GameTooltip", "CollectionistInfoTooltip", UIParent, "GameTooltipTemplate")
        infoTooltip:SetFrameStrata("TOOLTIP")
        infoTooltip:SetClampedToScreen(true)
    end
    return infoTooltip
end

function MC.HideInfoTooltip()
    if infoTooltip then infoTooltip:Hide() end
end

-- Default OnLeave handler for module item rows. Hides the WoW tooltip
-- and the module info tooltip together. Reused via reference (not a
-- closure) so module rows don't allocate one per refresh.
function MC.RowOnLeave()
    GameTooltip:Hide()
    MC.HideInfoTooltip()
end

--------------------------------------------------------------------------
-- Currency info cache. C_CurrencyInfo.GetCurrencyInfo gets called on every
-- tooltip hover, and currency data only changes on CURRENCY_DISPLAY_UPDATE.
--------------------------------------------------------------------------
local currencyCache = {}
function MC.InvalidateCurrencyCache() wipe(currencyCache) end

local function GetCachedCurrencyInfo(currID)
    local hit = currencyCache[currID]
    if hit ~= nil then return hit or nil end
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, currID)
    info = ok and info or false
    currencyCache[currID] = info
    return info or nil
end

-- Item cost metadata uses the same hover-time caching strategy as currencies.
-- Item names can be unavailable until the client cache receives them, so the
-- GET_ITEM_INFO_RECEIVED handler below evicts that specific entry for retry.
local itemInfoCache = {}
function MC.InvalidateItemInfoCache(itemID)
    if itemID then
        itemInfoCache[itemID] = nil
    else
        wipe(itemInfoCache)
    end
end

local function GetCachedItemCostInfo(itemID)
    local hit = itemInfoCache[itemID]
    if hit ~= nil then return hit end

    local name, icon
    if C_Item then
        if C_Item.GetItemNameByID then
            local ok, value = pcall(C_Item.GetItemNameByID, itemID)
            if ok then name = value end
        end
        if C_Item.GetItemIconByID then
            local ok, value = pcall(C_Item.GetItemIconByID, itemID)
            if ok then icon = value end
        end
    end
    -- Keep the legacy API fallback for clients where one or both C_Item
    -- helpers are absent. GetItemInfo's texture is its tenth return value.
    if (not name or not icon) and GetItemInfo then
        local values = { pcall(GetItemInfo, itemID) }
        if values[1] then
            name = name or values[2]
            icon = icon or values[11]
        end
    end

    hit = {
        name = name or ("Item " .. itemID),
        icon = icon,
    }
    itemInfoCache[itemID] = hit
    return hit
end

local function GetOwnedItemCount(itemID)
    local getCount = C_Item and C_Item.GetItemCount or GetItemCount
    if not getCount then return 0 end
    -- Include bank, reagent bank, and Warband bank so the affordability hint
    -- reflects every stack a vendor transaction can reasonably draw from.
    local ok, count = pcall(getCount, itemID, true, false, true, true)
    return ok and (count or 0) or 0
end

-- Standing names <-> reaction index, file-scoped so they're not rebuilt per hover.
local STANDING_ORDER = {
    Hated = 1, Hostile = 2, Unfriendly = 3, Neutral = 4,
    Friendly = 5, Honored = 6, Revered = 7, Exalted = 8,
}
local STANDINGS = { "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted" }

--------------------------------------------------------------------------
-- The big info tooltip (renown, cost, drop info, click hints)
--------------------------------------------------------------------------
local theme = MUI.Theme
local C = theme.colors

function MC.ShowItemInfoTooltip(owner, item, sourceLabel, sr, sg, sb)
    local tt = MC.GetInfoTooltip()
    tt:SetOwner(owner, "ANCHOR_NONE")
    tt:ClearAllPoints()
    -- Default anchor: to the right of the row, top-aligned. Overlap with
    -- GameTooltip is corrected after Show() once both tooltips have a
    -- rendered geometry to compare.
    tt:SetPoint("TOPLEFT", owner, "TOPRIGHT", 8, 0)

    tt:AddLine("Collectionist", C.ttTitle[1], C.ttTitle[2], C.ttTitle[3])
    tt:AddDoubleLine("Source:", sourceLabel or item.source or "Unknown",
        C.ttLabel[1], C.ttLabel[2], C.ttLabel[3],
        sr or 0.7, sg or 0.7, sb or 0.7)

    if item.sourceInfo then
        tt:AddLine(item.sourceInfo, 1, 1, 1, true)
    end

    if item.navigationOnly then
        tt:AddLine("Location only — excluded from completion totals and saved ownership.",
            0.72, 0.72, 0.72, true)
    end

    if item.availableAfter and MC.IsContentAvailable
       and not MC.IsContentAvailable(item) then
        local label = MC.GetAvailabilityLabel and MC.GetAvailabilityLabel(item)
            or "a future update"
        tt:AddLine(" ")
        tt:AddDoubleLine("Available:", label,
            C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], 1.0, 0.72, 0.25)
    end

    -- Step-by-step guide. Used today by treasures that have a puzzle/key
    -- prerequisite; any item type can populate `steps` to show a how-to block.
    if item.steps then
        tt:AddLine(" ")
        tt:AddLine("How to:", C.ttLabel[1], C.ttLabel[2], C.ttLabel[3])
        tt:AddLine(item.steps, C.ttValue[1], C.ttValue[2], C.ttValue[3], true)
    end

    -- Task list with live ✓/✗ progress. A task entry can carry a questID
    -- (checked via C_QuestLog) or an achievementID (checked via the achievement
    -- API). DoItemAction routes waypoints to the incomplete steps when the row
    -- is clicked; tasks may also carry a pickupWaypoint that drops a marker at
    -- the item-pickup spot in addition to the destination waypoint.
    if item.taskList and item.taskList.tasks then
        tt:AddLine(" ")
        if item.taskList.intro then
            tt:AddLine(item.taskList.intro, C.ttValue[1], C.ttValue[2], C.ttValue[3], true)
        end
        for _, task in ipairs(item.taskList.tasks) do
            local done = MC.IsTaskCompleted(task)
            local mark = done and "|cff55cc55[X]|r" or "|cffff5555[ ]|r"
            local r, g, b = 0.85, 0.85, 0.85
            if done then r, g, b = 0.55, 0.78, 0.55 end
            tt:AddLine(mark .. " " .. task.label, r, g, b)
        end
    end

    -- Pets only
    if item.petType then
        local typeName = MC.PetTypeNames and MC.PetTypeNames[item.petType] or ("Type " .. (item.petType or "?"))
        tt:AddDoubleLine("Pet type:", typeName, C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], C.ttValue[1], C.ttValue[2], C.ttValue[3])
    end
    if item.canBattle ~= nil then
        local battleStr = item.canBattle and "Yes" or "No"
        local br, bg, bb = 0.5, 0.8, 0.5
        if not item.canBattle then br, bg, bb = 0.8, 0.5, 0.5 end
        tt:AddDoubleLine("Can battle:", battleStr, C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], br, bg, bb)
    end

    -- Crafted decorations
    if item.skillLine and MC.DecoProfLabels and MC.DecoProfLabels[item.skillLine] then
        local pr, pg, pb = theme:ProfAccentColor(item.skillLine)
        tt:AddDoubleLine("Profession:", MC.DecoProfLabels[item.skillLine], C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], pr, pg, pb)
    end

    -- Use GetSmartWaypoint so the displayed coords match wherever the
    -- player would actually be routed if they clicked.
    local resolvedWp = MC.GetSmartWaypoint(item)
    if resolvedWp then
        local isList = MC._isWaypointList(resolvedWp)
        local first = isList and resolvedWp[1] or resolvedWp
        if first[1] and first[1] > 0 then
            local mapInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(first[1])
            local mapName = mapInfo and mapInfo.name or ("Map " .. first[1])
            tt:AddDoubleLine("Zone:", mapName, C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], C.ttValue[1], C.ttValue[2], C.ttValue[3])
            if isList then
                tt:AddDoubleLine("Spawns:", #resolvedWp .. " possible locations",
                    C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], C.ttValue[1], C.ttValue[2], C.ttValue[3])
            elseif first[2] and first[3] then
                tt:AddDoubleLine("Coords:", format("%.1f, %.1f", first[2] * 100, first[3] * 100), C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], C.ttValue[1], C.ttValue[2], C.ttValue[3])
            end
        end
    elseif item.zone then
        tt:AddDoubleLine("Zone:", item.zone, C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], C.ttValue[1], C.ttValue[2], C.ttValue[3])
    end

    -- Renown / rep requirement (red until met, green when met)
    if item.renown then
        local req = item.renown
        local metReq = false
        local reqLabel = ""
        if req.factionID and req.level then
            local current = "?"
            if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
                local ok, data = pcall(C_MajorFactions.GetMajorFactionData, req.factionID)
                if ok and data and data.renownLevel then
                    current = tostring(data.renownLevel)
                    metReq = data.renownLevel >= req.level
                end
            end
            local name = req.factionName or ("Faction " .. req.factionID)
            reqLabel = format("%s Renown %s/%d", name, current, req.level)
        elseif req.factionID and req.standing then
            local current = "?"
            if C_Reputation and C_Reputation.GetFactionDataByID then
                local ok, data = pcall(C_Reputation.GetFactionDataByID, req.factionID)
                if ok and data and data.reaction then
                    current = STANDINGS[data.reaction] or tostring(data.reaction)
                    metReq = data.reaction >= (STANDING_ORDER[req.standing] or 0)
                end
            end
            local name = req.factionName or ("Faction " .. req.factionID)
            reqLabel = format("%s %s (%s)", name, current, req.standing)
        end
        if reqLabel ~= "" then
            local rr, rg, rb = C.ttCostBad[1], C.ttCostBad[2], C.ttCostBad[3]
            if metReq then rr, rg, rb = 0.5, 0.8, 0.5 end
            tt:AddLine(reqLabel, rr, rg, rb)
        end
    end

    -- Currency, item, and gold costs. Red if you can't afford them.
    if item.cost then
        if item.cost.gold then
            local playerGold = GetMoney and GetMoney() or 0
            local gr, gg, gb = 1, 1, 1
            if playerGold < item.cost.gold then gr, gg, gb = C.ttCostBad[1], C.ttCostBad[2], C.ttCostBad[3] end
            tt:AddDoubleLine("Cost:", MUI.FormatGold(item.cost.gold), C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], gr, gg, gb)
        end
        local parts = {}
        for _, key in ipairs({"currency", "currency2"}) do
            local cur = item.cost[key]
            if cur then
                local currID, amount = cur[1], cur[2]
                local info = GetCachedCurrencyInfo(currID)
                local icon = info and info.iconFileID
                local name = info and info.name or ("Currency " .. currID)
                local owned = (info and info.quantity) or 0
                local color = owned >= amount and "" or "|cffff4d4d"
                local costLabel = icon and (amount .. " |T" .. icon .. ":0|t") or (amount .. " " .. name)
                parts[#parts + 1] = color .. costLabel .. "|r"
            end
        end
        for _, key in ipairs({"item", "item2"}) do
            local itemCost = item.cost[key]
            if itemCost then
                local itemID, amount = itemCost[1], itemCost[2]
                local info = GetCachedItemCostInfo(itemID)
                local owned = GetOwnedItemCount(itemID)
                local color = owned >= amount and "" or "|cffff4d4d"
                local icon = info.icon and ("|T" .. info.icon .. ":0|t ") or ""
                local costLabel = amount .. " " .. icon .. info.name
                parts[#parts + 1] = color .. costLabel .. "|r"
            end
        end
        if #parts > 0 then
            tt:AddDoubleLine("Cost:", table.concat(parts, "  "), C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], 1, 1, 1)
        end
    end

    if item.dropInfo then
        local di = item.dropInfo
        if di.mob then
            tt:AddDoubleLine("Drops from:", di.mob, C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], C.ttDropMob[1], C.ttDropMob[2], C.ttDropMob[3])
        end
        if di.zone then
            tt:AddDoubleLine("Zone:", di.zone, C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], C.ttValue[1], C.ttValue[2], C.ttValue[3])
        end
        if di.rate then
            tt:AddDoubleLine("Drop rate:", di.rate, C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], C.ttDropRate[1], C.ttDropRate[2], C.ttDropRate[3])
        end
        if di.boss then
            tt:AddLine("Boss drop", C.ttBoss[1], C.ttBoss[2], C.ttBoss[3])
        end
    end

    -- Recipes only
    if item.specInfo then
        local si = item.specInfo
        if si.tree then
            tt:AddDoubleLine("Spec tree:", si.tree, C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], C.ttSpec[1], C.ttSpec[2], C.ttSpec[3])
        end
        if si.node then
            tt:AddDoubleLine("Node:", si.node, C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], C.ttSpec[1], C.ttSpec[2], C.ttSpec[3])
        end
        if si.points then
            tt:AddDoubleLine("Points:", tostring(si.points), C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], 1, 1, 1)
        end
    end

    tt:AddLine(" ")
    -- Pending tasks take priority: clicking the row routes to the prereq
    -- waypoints rather than the treasure itself until they're all done. A
    -- task counts as routable if it has either a destination waypoint or a
    -- pickupWaypoint (item-collection spot).
    local pendingTasks = 0
    if item.taskList and item.taskList.tasks then
        for _, task in ipairs(item.taskList.tasks) do
            if not MC.IsTaskCompleted(task) and (task.waypoint or task.pickupWaypoint) then
                pendingTasks = pendingTasks + 1
            end
        end
    end
    if pendingTasks > 0 then
        tt:AddLine(format("Click to mark %d pending step%s",
            pendingTasks, pendingTasks == 1 and "" or "s"),
            C.ttHintGreen[1], C.ttHintGreen[2], C.ttHintGreen[3])
    elseif resolvedWp then
        local hint = "Click to set waypoint"
        if MC._isWaypointList(resolvedWp) then
            hint = format("Click to set %d waypoints", #resolvedWp)
        end
        tt:AddLine(hint, C.ttHintGreen[1], C.ttHintGreen[2], C.ttHintGreen[3])
    elseif item.achievementID and item.achievementID > 0 then
        tt:AddLine("Click to open achievement", C.ttHintGreen[1], C.ttHintGreen[2], C.ttHintGreen[3])
    elseif item.skillLine or item.specInfo then
        tt:AddLine("Click to open profession", C.ttHintGreen[1], C.ttHintGreen[2], C.ttHintGreen[3])
    end
    tt:AddLine("Shift-click to copy Wowhead URL", C.ttHintBlue[1], C.ttHintBlue[2], C.ttHintBlue[3])
    tt:AddLine("Ctrl-click to print entry info", C.ttHintBlue[1], C.ttHintBlue[2], C.ttHintBlue[3])
    if MC.IsTargetPinned then
        -- Collected rows can't be pinned; only show the hint when it can
        -- act (or a stale pin still needs the unpin path).
        if MC.IsTargetPinned(item) then
            tt:AddLine("Alt-click to unpin from Targets",
                C.ttHintBlue[1], C.ttHintBlue[2], C.ttHintBlue[3])
        elseif not (item.collected or item.learned) then
            tt:AddLine("Alt-click to pin to Targets",
                C.ttHintBlue[1], C.ttHintBlue[2], C.ttHintBlue[3])
        end
    end

    -- Roster (v2): show which guildies/BNet friends already own this item.
    if MC.Bitmap and MC.Bitmap.OwnersOf then
        local modKey, canonicalID
        if item.moduleKey == "mounts" and item.mountID then
            modKey, canonicalID = "mounts", item.mountID
        elseif item.moduleKey == "pets" and item.speciesID then
            modKey, canonicalID = "pets", item.speciesID
        elseif item.moduleKey == "decorations" and item.decorID then
            modKey, canonicalID = "decorations", item.decorID
        elseif item.moduleKey == "toys" and item.itemID then
            modKey, canonicalID = "toys", item.itemID
        elseif (item.moduleKey == "rares" or item.moduleKey == "treasures")
               and item.criteriaIndex and item.achievementID
               and MC.Bitmap.CriterionID then
            modKey = item.moduleKey
            canonicalID = MC.Bitmap:CriterionID(item.achievementID, item.criteriaIndex)
        end
        if modKey and canonicalID then
            local owners = MC.Bitmap:OwnersOf(modKey, canonicalID)
            if #owners > 0 then
                tt:AddLine(" ")
                local shown = math.min(#owners, 5)
                local names = {}
                for i = 1, shown do
                    -- Strip "-Realm" for display brevity
                    names[i] = (owners[i]:match("^([^%-]+)") or owners[i])
                end
                local label = table.concat(names, ", ")
                if #owners > shown then
                    label = label .. format(" (+%d more)", #owners - shown)
                end
                tt:AddDoubleLine("Owned by:", label,
                    C.ttLabel[1], C.ttLabel[2], C.ttLabel[3],
                    C.ttValue[1], C.ttValue[2], C.ttValue[3], true)
            end
        end
    end

    tt:Show()

    -- Overlap correction: if GameTooltip is hosting our row and its rendered
    -- bottom sits inside our top edge (panel near screen top + WoW auto-clamp
    -- pushed GameTooltip down into our space), shift our tooltip below it.
    local gt = GameTooltip
    if gt and gt.IsShown and gt:IsShown() and gt:GetOwner() == owner then
        local gtBottom = gt:GetBottom()
        local ttTop    = tt:GetTop()
        if gtBottom and ttTop and gtBottom < ttTop then
            tt:ClearAllPoints()
            tt:SetPoint("TOPLEFT", gt, "BOTTOMLEFT", 0, -4)
        end
    end
end

--------------------------------------------------------------------------
-- Shift-click handler that opens the Wowhead URL popup.
-- Combat-guarded because StaticPopup_Show can taint UIParent.
--------------------------------------------------------------------------
function MC.OpenItemWowhead(item)
    if InCombatLockdown() then
        print(PREFIX .. " Cannot open URL popup during combat.")
        return
    end
    local url
    if item.mountID then
        url = "https://www.wowhead.com/mount/" .. tonumber(item.mountID)
    elseif item.speciesID then
        url = "https://www.wowhead.com/battle-pet/" .. tonumber(item.speciesID)
    elseif item.decorID and item.decorID > 0 then
        url = "https://www.wowhead.com/decor=" .. tonumber(item.decorID)
    elseif item.itemID and item.itemID > 0 then
        url = "https://www.wowhead.com/item=" .. tonumber(item.itemID)
    elseif item.id then
        url = "https://www.wowhead.com/spell=" .. tonumber(item.id)
    elseif item.objectID and item.objectID > 0 then
        url = "https://www.wowhead.com/object=" .. tonumber(item.objectID)
    elseif item.questID and item.questID > 0 then
        -- Navigation-only treasures identify by quest completion flag rather
        -- than an object, so this is the only link they can offer. Ordered
        -- after objectID so a row carrying both still prefers the object.
        url = "https://www.wowhead.com/quest=" .. tonumber(item.questID)
    elseif item.npcID then
        url = "https://www.wowhead.com/npc=" .. tonumber(item.npcID)
    elseif item.achievementID then
        url = "https://www.wowhead.com/achievement=" .. tonumber(item.achievementID)
    end
    if url then
        StaticPopup_Show("MIDNIGHTCOLLECTIONS_WOWHEAD", nil, nil, url)
    else
        print(PREFIX .. " No Wowhead link available for this entry.")
    end
end

--------------------------------------------------------------------------
-- A waypoint is either a single tuple { mapID, x, y, name } or a list of
-- those tuples for items with multiple spawn points (e.g. 8 Rustling Bushes).
-- Detect by checking if the first element is itself a table; an empty list
-- counts as "no waypoint" so we don't crash on wp[1] later.
--------------------------------------------------------------------------
local function isWaypointList(wp)
    return wp ~= nil and type(wp[1]) == "table"
end

local function waypointMapID(wp)
    if not wp then return nil end
    if isWaypointList(wp) then
        local first = wp[1]
        return first and first[1] or nil
    end
    return wp[1]
end

--------------------------------------------------------------------------
-- Pick the right waypoint for where the player is right now.
-- Inside the instance? Precise spawn coords (might be a list of spawns).
-- In the target zone? Direct waypoint.
-- In a hub with a portal to the target zone? Route to that portal first.
-- Otherwise just send them to wherever they should end up; TomTom queues it.
--------------------------------------------------------------------------
-- Roll a sub-map (The Den, Slayer's Rise, etc.) up to its parent zone.
local function effectiveMap(m)
    if not m then return nil end
    return (MC.MAP_PARENT and MC.MAP_PARENT[m]) or m
end

-- For a multi-spawn waypoint list, pick the entry whose effective map matches
-- effCurrent (preferred) or any portal-reachable target. Returns the matching
-- single tuple, or nil if no entry is in-zone.
local function pickInZoneEntry(list, currentMap, effCurrent)
    if not list then return nil end
    for _, w in ipairs(list) do
        local m = w[1]
        if m == currentMap or effectiveMap(m) == effCurrent then
            return w
        end
    end
    return nil
end

function MC.GetSmartWaypoint(item)
    local wp  = item.waypoint
    local owp = item.overworldWaypoint
    if not wp and not owp then return nil end

    local currentMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local effCurrent = effectiveMap(currentMap)

    -- If wp is a list and the player is already in one of its zones, prefer
    -- that exact spawn rather than dropping all of them.
    if wp and isWaypointList(wp) then
        local match = pickInZoneEntry(wp, currentMap, effCurrent)
        if match then return match end
    elseif wp and currentMap == waypointMapID(wp) then
        return wp
    end

    -- Target zone: instanced content uses owp[1], everything else wp's mapID.
    local owpMap = owp and (isWaypointList(owp) and owp[1] and owp[1][1] or owp[1]) or nil
    local targetZone = owpMap or waypointMapID(wp)
    local effTarget  = effectiveMap(targetZone)

    -- Already in the target zone (or a sub-map of it)?
    if currentMap == targetZone or (effCurrent and effCurrent == effTarget) then
        return owp or wp
    end

    -- Portal lookup: try the raw map first, then the rolled-up parent so a
    -- player in The Den can still find Harandar's portals, and so a target
    -- in Slayer's Rise looks up Voidstorm's portal. For multi-zone waypoint
    -- lists, try every entry's effective target.
    if MC.PORTALS then
        local targets
        if wp and isWaypointList(wp) then
            targets = {}
            for _, w in ipairs(wp) do
                targets[#targets + 1] = effectiveMap(w[1])
            end
        else
            targets = { effTarget }
        end
        for _, fromMap in ipairs({ currentMap, effCurrent }) do
            if fromMap and MC.PORTALS[fromMap] then
                for _, t in ipairs(targets) do
                    if t then
                        local p = MC.PORTALS[fromMap][t]
                        if p then return p end
                    end
                end
            end
        end
    end

    return owp or wp
end

MC._isWaypointList = isWaypointList

--------------------------------------------------------------------------
-- Task completion check. A task entry can carry one of:
--   questID                       — C_QuestLog.IsQuestFlaggedCompleted
--   achievementID                 — GetAchievementInfo (4th return = completed)
--   achievementID + criteriaID    — GetAchievementCriteriaInfoByID (preferred;
--                                    survives criterion reorderings between
--                                    patches that would shift criteriaIndex)
--   achievementID + criteriaIndex — GetAchievementCriteriaInfo (3rd = completed;
--                                    takes precedence when Blizzard reuses one
--                                    criteriaID for multiple visible rows)
--   speciesID                     — C_PetJournal.GetNumCollectedInfo > 0
--   itemID [+ itemCount]          — PlayerHasToy / GetItemCount >= itemCount
--                                    (default itemCount = 1; PlayerHasToy is
--                                    only consulted when itemCount == 1)
-- Returns false for unknown shapes so the task always renders as pending.
--------------------------------------------------------------------------
function MC.IsTaskCompleted(task)
    if not task then return false end
    if task.questID then
        if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
            return C_QuestLog.IsQuestFlaggedCompleted(task.questID) and true or false
        end
        return false
    end
    if task.achievementID and task.criteriaIndex then
        local getCrit = (C_AchievementInfo and C_AchievementInfo.GetAchievementCriteriaInfo)
                          or GetAchievementCriteriaInfo
        if getCrit then
            local ok, _, _, completed = pcall(getCrit, task.achievementID, task.criteriaIndex)
            return ok and (completed and true or false) or false
        end
        return false
    end
    if task.achievementID and task.criteriaID then
        -- Look up by stable criteria ID (preferred — surviving criterion
        -- reorderings between patches). Only available via the C_API.
        local getById = (C_AchievementInfo and C_AchievementInfo.GetAchievementCriteriaInfoByID)
                          or GetAchievementCriteriaInfoByID
        if getById then
            local ok, _, _, completed = pcall(getById, task.achievementID, task.criteriaID)
            return ok and (completed and true or false) or false
        end
        return false
    end
    if task.achievementID then
        local getInfo = (C_AchievementInfo and C_AchievementInfo.GetAchievementInfo)
                          or GetAchievementInfo
        if getInfo then
            local ok, _, _, _, completed = pcall(getInfo, task.achievementID)
            return ok and (completed and true or false) or false
        end
        return false
    end
    if task.speciesID then
        if C_PetJournal and C_PetJournal.GetNumCollectedInfo then
            local ok, n = pcall(C_PetJournal.GetNumCollectedInfo, task.speciesID)
            return ok and (n or 0) > 0 or false
        end
        return false
    end
    if task.itemID then
        local needed = task.itemCount or 1
        -- PlayerHasToy is a binary "is this toy collected?" — only meaningful
        -- when itemCount is the default 1 and the item is a toy.
        if needed <= 1 and PlayerHasToy and PlayerHasToy(task.itemID) then
            return true
        end
        local n = 0
        if C_Item and C_Item.GetItemCount then
            local ok, count = pcall(C_Item.GetItemCount, task.itemID)
            n = (ok and count) or 0
        elseif GetItemCount then
            n = GetItemCount(task.itemID) or 0
        end
        return n >= needed
    end
    return false
end

--------------------------------------------------------------------------
-- TomTom if available, Blizzard's user map pin if not.
--------------------------------------------------------------------------
local _warnedNoWaypointProvider = false
function MC.AddWaypoint(mapID, x, y, title)
    if not (mapID and x and y) or mapID <= 0 then return false end
    title = title or "Collectionist waypoint"
    if TomTom and TomTom.AddWaypoint then
        TomTom:AddWaypoint(mapID, x, y, { title = title })
        print(format("%s Waypoint set: %s", PREFIX, title))
        return true
    end
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint then
        local pt = UiMapPoint.CreateFromCoordinates(mapID, x, y)
        local ok = pcall(C_Map.SetUserWaypoint, pt)
        if ok then
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
            end
            print(format("%s Map pin set: %s", PREFIX, title))
            return true
        end
    end
    if not _warnedNoWaypointProvider then
        _warnedNoWaypointProvider = true
        print(PREFIX .. " Install TomTom for waypoint support.")
    end
    return false
end

--------------------------------------------------------------------------
-- Row click handler. Shift-click for Wowhead, plain click sets a waypoint
-- (or opens the achievement / profession if there's no waypoint).
--------------------------------------------------------------------------
-- Print a verbose dump of an entry's IDs, source, cost, drop, etc. to chat.
-- Used by the ctrl-click row handler so the player can copy/paste a row's
-- raw data without dealing with /run's 255-character cap.
function MC.PrintItemInfo(item)
    print(format("%s --- %s ---", PREFIX, item.name or "?"))
    if item.mountID   then print(format("  mountID: %d   /way wowhead.com/mount/%d",   item.mountID, item.mountID)) end
    if item.speciesID then print(format("  speciesID: %d  wowhead.com/battle-pet/%d",  item.speciesID, item.speciesID)) end
    if item.decorID   then print(format("  decorID: %d   wowhead.com/decor=%d",        item.decorID, item.decorID)) end
    if item.itemID    then print(format("  itemID: %d    wowhead.com/item=%d",         item.itemID, item.itemID)) end
    if item.id        then print(format("  spellID: %d   wowhead.com/spell=%d",        item.id, item.id)) end
    if item.objectID  then print(format("  objectID: %d  wowhead.com/object=%d",       item.objectID, item.objectID)) end
    if item.npcID     then print(format("  npcID: %d     wowhead.com/npc=%d",          item.npcID, item.npcID)) end
    if item.criteriaIndex then print("  criteriaIndex: " .. tostring(item.criteriaIndex)) end
    if item.source     then print("  source: " .. tostring(item.source)) end
    if item.sourceInfo then print("  info: " .. tostring(item.sourceInfo)) end
    if item.zone       then print("  zone: " .. tostring(item.zone)) end
    if item.waypoint then
        local wp = item.waypoint
        if type(wp[1]) == "table" then
            print(format("  waypoint: %d locations (first map=%s, %.2f, %.2f)",
                #wp, tostring(wp[1][1]), wp[1][2] or 0, wp[1][3] or 0))
        else
            print(format("  waypoint: map=%s, %.2f, %.2f", tostring(wp[1]), wp[2] or 0, wp[3] or 0))
        end
    else
        print("  waypoint: none")
    end
    if item.renown then
        local r = item.renown
        print(format("  renown: faction=%s level=%s standing=%s",
            tostring(r.factionID), tostring(r.level), tostring(r.standing)))
    end
    if item.cost then
        if item.cost.gold then print("  gold: " .. tostring(item.cost.gold)) end
        for _, k in ipairs({"currency", "currency2"}) do
            local c = item.cost[k]
            if c then print(format("  %s: id=%d amount=%d", k, c[1], c[2])) end
        end
    end
    if item.dropInfo then
        local d = item.dropInfo
        print(format("  drop: mob=%s zone=%s rate=%s boss=%s",
            tostring(d.mob), tostring(d.zone), tostring(d.rate), tostring(d.boss)))
    end
    if item.achievementID then print("  achievementID: " .. tostring(item.achievementID)) end
    if item.collected ~= nil then print("  collected: " .. tostring(item.collected)) end
end

function MC.DoItemAction(item, skillLine)
    if IsShiftKeyDown() then
        MC.OpenItemWowhead(item)
        return
    end
    if IsControlKeyDown() then
        MC.PrintItemInfo(item)
        return
    end
    -- Alt-click: pin/unpin the row in the Targets overlay (shift and
    -- ctrl are taken by Wowhead / info dump above). Guarded so Core
    -- stays loadable without Targets.lua (tests load Core standalone).
    if IsAltKeyDown() then
        -- skillLine rides along so a recipes pin can reopen its
        -- profession before the first scan of a session.
        if MC.ToggleTargetPin then MC.ToggleTargetPin(item, skillLine) end
        return
    end

    -- Task-list aware: if any prerequisite is incomplete, route to those
    -- waypoints first. Once all tasks are done, fall through to the regular
    -- waypoint behavior so the player can navigate to the item itself. Each
    -- incomplete task contributes its pickupWaypoint AND its waypoint (if it
    -- has both), so the player gets a marker at the item pickup AND the
    -- destination/turn-in for every step.
    if item.taskList and item.taskList.tasks then
        local pending = {}
        for _, task in ipairs(item.taskList.tasks) do
            if not MC.IsTaskCompleted(task) then
                if task.pickupWaypoint then
                    pending[#pending + 1] = task.pickupWaypoint
                end
                if task.waypoint then
                    pending[#pending + 1] = task.waypoint
                end
            end
        end
        if #pending > 0 then
            if TomTom and TomTom.AddWaypoint then
                for _, w in ipairs(pending) do
                    TomTom:AddWaypoint(w[1], w[2], w[3], { title = w[4] or item.name })
                end
                print(format("%s Set %d waypoint%s for %s prerequisites.",
                    PREFIX, #pending, #pending == 1 and "" or "s", item.name))
            else
                local first = pending[1]
                MC.AddWaypoint(first[1], first[2], first[3],
                    format("%s (1 of %d markers)", first[4] or item.name, #pending))
                if #pending > 1 then
                    print(format("%s Install TomTom to mark all %d markers at once.",
                        PREFIX, #pending))
                end
            end
            return
        end
    end

    local wp = MC.GetSmartWaypoint(item)
    if wp then
        if MC._isWaypointList(wp) then
            -- Multi-spawn: drop a TomTom marker at each. The Blizzard map-pin
            -- fallback only holds one at a time, so we warn and pin the first.
            if TomTom and TomTom.AddWaypoint then
                for _, w in ipairs(wp) do
                    TomTom:AddWaypoint(w[1], w[2], w[3], { title = w[4] or item.name })
                end
                print(format("%s Set %d waypoints for %s.", PREFIX, #wp, item.name))
            else
                local first = wp[1]
                MC.AddWaypoint(first[1], first[2], first[3],
                    format("%s (1 of %d spawns)", item.name, #wp))
                print(format("%s Install TomTom to mark all %d spawns at once.",
                    PREFIX, #wp))
            end
        else
            MC.AddWaypoint(wp[1], wp[2], wp[3], wp[4] or item.sourceInfo or item.name)
        end
    elseif item.achievementID and item.achievementID > 0 then
        if InCombatLockdown() then
            print(PREFIX .. " Cannot open achievements during combat.")
            return
        end
        if not AchievementFrame then
            AchievementFrame_LoadUI()
        end
        if AchievementFrame_SelectAchievement then
            ShowUIPanel(AchievementFrame)
            AchievementFrame_SelectAchievement(item.achievementID)
        else
            print(PREFIX .. " Could not open achievement frame.")
        end
    elseif skillLine or item.skillLine then
        local sl = skillLine or item.skillLine
        if InCombatLockdown() then
            print(PREFIX .. " Cannot open professions during combat.")
            return
        end
        if C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill then
            local ok = pcall(C_TradeSkillUI.OpenTradeSkill, sl)
            if not ok then
                print(PREFIX .. " Could not open profession frame.")
            end
        end
    end
end

--------------------------------------------------------------------------
-- Coalesces a flurry of events into one scan. Pets and Decorations pass
-- a longer delay for BAG_UPDATE_DELAYED, which fires constantly during loot.
--------------------------------------------------------------------------
function MC.OnScanComplete(mod)
    if MC.RefreshScoreIndicator then MC.RefreshScoreIndicator() end
    if MC.PremiumNav and MC.PremiumNav.RefreshCounts then MC.PremiumNav:RefreshCounts() end
    if MC.Targets and MC.Targets.OnScanComplete then MC.Targets:OnScanComplete(mod) end
    if MC.RosterDebouncedBroadcast then MC.RosterDebouncedBroadcast() end
    if MC.RefreshPeerPanel then MC.RefreshPeerPanel() end
    -- Search marks its index dirty here and pays for the rebuild on the
    -- next open/query; a login wave fires one of these per module.
    if MC.Search and MC.Search.Invalidate then MC.Search:Invalidate() end
    -- Not while Options owns the content area: the module's rows would
    -- render straight over the settings page.
    if MC.activeModule == mod.key and mod.UI and MC.panel
       and MC.panel.frame and MC.panel.frame:IsShown()
       and not MC.IsOptionsSelected() then
        mod.UI:Refresh()
    end
end

-- Bounded retry for scans that defer or commit a partial snapshot. While
-- Blizzard data is still streaming the retries pick the missing rows up
-- within seconds; if the shortfall never resolves (removed achievement,
-- hotfixed criteria) the module settles after ~2 minutes and its partial
-- snapshot becomes the accepted steady state.
local SCAN_RETRY_MAX = 12
local SCAN_RETRY_BACKOFF = { 2, 5 } -- then 10s per attempt

function MC._ScheduleScanRetry(mod)
    if mod._retryPending then return end
    local tries = mod._scanRetries or 0
    if tries >= SCAN_RETRY_MAX then
        -- Settle: stop holding roster broadcasts for rows that are
        -- evidently gone rather than still streaming.
        local r = mod.Scanner and mod.Scanner.results
        if type(r) == "table" and r._partial then
            r._partial = nil
            r._degraded = true
        end
        return
    end
    mod._scanRetries = tries + 1
    mod._retryPending = true
    C_Timer.After(SCAN_RETRY_BACKOFF[mod._scanRetries] or 10, function()
        mod._retryPending = false
        MC.ScanNow(mod)
    end)
end

function MC.ScanNow(mod)
    if not (mod and mod.Scanner and mod.Scanner.Scan) then return false end
    local ok, completed = pcall(mod.Scanner.Scan, mod.Scanner)
    if not ok then
        print(format("%s Scan error in %s: %s", PREFIX, mod.key, tostring(completed)))
        return false
    end
    -- A scanner may explicitly defer by returning false while its Blizzard
    -- data source is still streaming. Keep the last committed snapshot and
    -- retry on a bounded backoff in case no readiness event ever fires.
    if completed == false then
        MC._ScheduleScanRetry(mod)
        return false
    end
    local r = mod.Scanner.results
    if type(r) == "table" and (r._partial or 0) > 0 then
        MC._ScheduleScanRetry(mod)
    else
        mod._scanRetries = 0
    end
    MC.OnScanComplete(mod)
    return true
end

-- Re-scan exactly when the next time-gated content phase opens. This keeps
-- long-running sessions accurate even if no collection journal event fires
-- at the unlock instant.
function MC.ScheduleContentReleaseScan()
    if not (MC.CONTENT_RELEASE and C_Timer and C_Timer.After
            and MC.GetCurrentTimestamp) then return end
    local now = MC.GetCurrentTimestamp()
    local nextUnlock
    for _, release in pairs(MC.CONTENT_RELEASE) do
        local unlock = MC.ResolveContentRelease and MC.ResolveContentRelease(release)
            or release
        if type(unlock) == "number" and unlock > now
           and (not nextUnlock or unlock < nextUnlock) then
            nextUnlock = unlock
        end
    end
    if not nextUnlock or MC._scheduledContentRelease == nextUnlock then return end
    MC._scheduledContentRelease = nextUnlock
    C_Timer.After(math.max(1, nextUnlock - now + 1), function()
        MC._scheduledContentRelease = nil
        for _, candidate in ipairs(MC.modules or {}) do
            if candidate.Scanner then MC.ScanNow(candidate) end
        end
        if MC.activeModule then MC.RefreshActive() end
        MC.ScheduleContentReleaseScan()
    end)
end

function MC.ThrottledScan(mod, delay)
    if mod._scanPending then return end
    mod._scanPending = true
    C_Timer.After(delay or 0.5, function()
        mod._scanPending = false
        -- Disabled modules remain hidden but continue supplying fresh score
        -- and sharing snapshots.
        MC.ScanNow(mod)
    end)
end

--------------------------------------------------------------------------
-- event -> { module, module, ... } so chatty events (BAG_UPDATE_DELAYED,
-- NAME_PLATE_UNIT_ADDED, etc) don't iterate every registered module.
--------------------------------------------------------------------------
MC._eventHandlers = {}

function MC._RebuildEventMap()
    wipe(MC._eventHandlers)
    for _, mod in ipairs(MC.modules) do
        if mod.opts.events then
            for _, ev in ipairs(mod.opts.events) do
                if not MC._eventHandlers[ev] then
                    MC._eventHandlers[ev] = {}
                end
                MC._eventHandlers[ev][#MC._eventHandlers[ev] + 1] = mod
            end
        end
    end
end

--------------------------------------------------------------------------
-- Schema migrations
--------------------------------------------------------------------------
local function MigrateDB(db)
    -- v0 -> v1: pull in saved vars from the four standalone addons that
    -- were merged into this one.
    if not db.dbVersion then
        local function importLegacy(legacyName, modKey)
            local legacy = _G[legacyName]
            if type(legacy) == "table" and not db[modKey] then
                db[modKey] = legacy
                print(format("%s Imported legacy %s settings.", PREFIX, modKey))
            end
        end
        importLegacy("MidnightRecipesDB",     "recipes")
        importLegacy("MidnightPetsDB",        "pets")
        importLegacy("MidnightMountsDB",      "mounts")
        importLegacy("MidnightDecorationsDB", "decorations")
        db.dbVersion = 1
    end
    -- Future schema bumps go here.
end

-- (Position recovery is now handled by SetClampedToScreen on the panel frame.
-- The earlier ValidatePosition routine was clobbering valid positions when
-- UIParent wasn't sized at ADDON_LOADED time.)

--------------------------------------------------------------------------
-- Event frame
--------------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
frame:RegisterEvent("UNIT_FACTION")
MC.eventFrame = frame

frame:SetScript("OnEvent", function(_, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == addonName then
        frame:UnregisterEvent("ADDON_LOADED")

        if not CollectionistDB then CollectionistDB = {} end
        if not CollectionistCharDB then CollectionistCharDB = {} end
        if not CollectionistRosterDB then CollectionistRosterDB = {} end

        -- v0 -> v1: pull in saved vars from the four standalone addons that
        -- were merged into this one. Targets the account-wide DB because that's
        -- where the legacy import lands.
        MigrateDB(CollectionistDB)

        -- v1 -> v2: per-character flip. CharDB becomes the runtime primary;
        -- the account-wide DB is now just a passive snapshot. This branch only
        -- runs on a CharDB that hasn't been seeded yet — it copies whatever's
        -- in the account-wide DB into CharDB so the char inherits the most
        -- recent settings (their own old prefs on first v2 run; another alt's
        -- last snapshot for brand-new characters).
        if (CollectionistCharDB.charDbVersion or 0) < CHAR_DB_VERSION then
            MC.DeepMergeDefaults(CollectionistCharDB, CollectionistDB)
            CollectionistCharDB.charDbVersion = CHAR_DB_VERSION
        end

        -- One-time fix from v0: activeTab briefly lived in account-wide DB.
        if CollectionistDB.activeTab and not CollectionistCharDB.activeTab then
            CollectionistCharDB.activeTab = CollectionistDB.activeTab
            CollectionistDB.activeTab = nil
        end

        -- Defaults merge for any new keys added since this character was last
        -- seeded. Operates on CharDB (the primary) only.
        MC.DeepMergeDefaults(CollectionistCharDB, charDefaults)

        -- Account-only ledgers must never live in a CharDB. The v1->v2 seed
        -- above copies the whole account DB, and older versions may have
        -- leaked copies via crash-skipped logouts — scrub unconditionally
        -- so a stale per-character copy can never shadow the live ledger.
        for k in pairs(ACCOUNT_ONLY_KEYS) do
            CollectionistCharDB[k] = nil
        end

        -- Runtime aliases. MC.db is the per-char primary; everything reads
        -- from here. MC.snapshotDB is the account-wide seed pool, written on
        -- PLAYER_LOGOUT. MC.cdb is kept as a back-compat alias.
        MC.db         = CollectionistCharDB
        MC.cdb        = CollectionistCharDB
        MC.snapshotDB = CollectionistDB
        MC.RosterDB   = CollectionistRosterDB

        -- Roster is no longer a module — it runs alongside the rest of
        -- the addon as a standalone feature. Init it now so its settings
        -- table (MC.db.roster + MC.db.rosterEnabled) is ready before any
        -- other code reads them.
        if MC.RosterInit then MC.RosterInit() end

        -- Each module gets its own sub-table for settings and collapsed state.
        -- Copy the registration defaults so we don't mutate mod.opts.defaults
        -- in place — DeepMergeDefaults shallow-copies sub-tables and we don't
        -- want the saved DB and the registration default to share refs.
        for _, mod in ipairs(MC.modules) do
            local moduleDefaults = mod.opts.defaults and CopyTable(mod.opts.defaults) or {}
            if not moduleDefaults.collapsed then
                moduleDefaults.collapsed = {}
            end
            if not MC.db[mod.key] then MC.db[mod.key] = {} end
            MC.DeepMergeDefaults(MC.db[mod.key], moduleDefaults)
            mod.db = MC.db[mod.key]
        end

        MC.Theme = MUI.Theme
        -- Apply the saved theme now, before any frames are built. The
        -- lib's hook list is empty at this point so the call is just a
        -- palette swap; CreatePanel later reads the active palette.
        MC.SetTheme(MC.GetTheme())
        -- Motion preference, applied before any frame animates.
        MUI.animEnabled = (MC.db.animations ~= false)
        print(PREFIX .. " v" .. MC.version .. " loaded. Type /mc to toggle.")

    elseif event == "PLAYER_LOGIN" then
        frame:UnregisterEvent("PLAYER_LOGIN")

        -- Apply the user's saved module order before anything else uses
        -- the MC.modules array (TabBar:Create, event registration, etc).
        if MC.ApplyModuleOrder then MC.ApplyModuleOrder() end
        MC.ScheduleContentReleaseScan()

        for _, mod in ipairs(MC.modules) do
            if mod.opts.events then
                for _, ev in ipairs(mod.opts.events) do
                    pcall(frame.RegisterEvent, frame, ev)
                end
            end
        end
        MC._RebuildEventMap()

        -- Run onLogin for every module, not just enabled ones. Some modules
        -- have init logic (Recipes' DetectProfessions, Pets' wild-species
        -- lookup) that the Scanner needs even when the module is disabled,
        -- so the Me row in Roster + the broadcast payload have its counts
        -- available.
        for _, mod in ipairs(MC.modules) do
            if mod.opts.onLogin then
                mod.opts.onLogin(mod)
            end
        end

        -- Roster runs outside the module system; it has its own
        -- post-login init (cleanup + broadcast) gated on rosterEnabled.
        if MC.RosterPostLogin then MC.RosterPostLogin() end
        -- C_PetJournal/C_MountJournal aren't fully populated at PLAYER_LOGIN,
        -- so the first scan is deferred a couple of seconds. Scan every
        -- module regardless of enabled state — disabling a module hides its
        -- tab but its counts should still be available for the Me row in
        -- Roster + the Roster broadcast payload. Disabled trackers remain
        -- hidden, but their lightweight event scans continue to keep those
        -- account-wide values current.
        C_Timer.After(2, function()
            for _, mod in ipairs(MC.modules) do
                if mod.Scanner then
                    MC.ScanNow(mod)
                end
            end
            if MC.activeModule then MC.RefreshActive() end
        end)

        MC.CreatePanel()
        if MC.MinimapButton then MC.MinimapButton:Init() end

        local tabKey = MC.cdb.activeTab
        if not MC.modulesByKey[tabKey] or not MC.IsModuleEnabled(tabKey) then
            tabKey = MC.FirstEnabledModule()
        end
        if tabKey then
            MC.SwitchTab(tabKey)
        else
            MC._ShowAllDisabledPlaceholder()
        end

        -- One-time onboarding popup at first launch on a new addon-version
        -- milestone. The onboarding module no-ops if the user has already
        -- accepted the current milestone.
        if MC.MaybeShowOnboarding then MC.MaybeShowOnboarding() end

        -- First login after an update: show what changed. No-ops on a fresh
        -- install (nothing to compare against, and Onboarding covers that
        -- case) and when the stored version already matches.
        if MC.WhatsNew then MC.WhatsNew:CheckOnLogin() end

    elseif event == "PLAYER_LOGOUT" then
        -- Snapshot the per-character DB into the account-wide DB so the next
        -- alt to log in for the first time inherits these settings as their
        -- seed. /reload also fires PLAYER_LOGOUT, so this stays current.
        -- ACCOUNT_ONLY_KEYS are skipped in both directions: the clear loop
        -- must not erase live account ledgers, and the copy loop must not
        -- let a stale per-character copy of one roll them back.
        if MC.db and MC.snapshotDB then
            for k in pairs(MC.snapshotDB) do
                if not ACCOUNT_ONLY_KEYS[k] then MC.snapshotDB[k] = nil end
            end
            for k, v in pairs(MC.db) do
                if not ACCOUNT_ONLY_KEYS[k] and not CHAR_ONLY_KEYS[k] then
                    MC.snapshotDB[k] = type(v) == "table" and CopyTable(v) or v
                end
            end
        end

    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        MC.InvalidateCurrencyCache()

    elseif event == "GET_ITEM_INFO_RECEIVED" then
        MC.InvalidateItemInfoCache(arg1)

    elseif event == "UNIT_FACTION" and arg1 == "player" then
        -- Player swapped factions; PvP-filtered mount list needs a rescan.
        local mounts = MC.modulesByKey["mounts"]
        if mounts and MC.IsModuleEnabled("mounts") then
            MC.ThrottledScan(mounts)
        end

    else
        local handlers = MC._eventHandlers[event]
        if not handlers then return end
        for _, mod in ipairs(handlers) do
            if mod.opts.onEvent then
                mod.opts.onEvent(mod, event, ...)
            end
        end
    end
end)

--------------------------------------------------------------------------
-- Panel creation
--------------------------------------------------------------------------
-- Two independent reasons to take indicators off the header:
--
--   view      premium compact/strip states condense the title bar; the
--             BUTTON chain (filter/score/peer) would overlap the page
--             title at compact widths, so those hide. The progress
--             counter is exempt: both condensed views are built around
--             it — the strip is icon + wordmark + counter + restore, and
--             the compact header is title + counter + spine — and each
--             re-anchors it rather than dropping it. Hiding it here
--             would also stick, because nothing on the way back into
--             those views shows it again.
--   options   the Options view owns the content area. The expansion
--             filter and the progress counter describe a tracker list and
--             have nothing to say about a settings page; Collection Score
--             and the peer count are account-wide and stay.
--
-- MC._indicatorsHidden keeps its original meaning — the VIEW-driven "the
-- whole chain is gone" flag, which RefreshPeerIndicator consults when it
-- self-shows from an event. Premium only: under classic nothing here ever
-- runs, so the peer indicator's roster-driven visibility is untouched.
local function setIndicatorShown(btn, hidden)
    if not btn then return end
    if hidden then btn:Hide() else btn:Show() end
end

function MC._ApplyIndicatorVisibility()
    if not MC._premiumShell then return end
    -- The shell calls onViewChanged from inside its own constructor (restoring
    -- a saved compact/minimized view), which reaches here before MC.panel has
    -- been assigned -- the constructor has not returned yet. Every indicator
    -- this function touches is created after that point, so there is nothing
    -- to apply; without the guard a single unguarded MC.panel deref in this
    -- path aborts CreatePanel and the addon comes up with no nav, no header
    -- and no content.
    if not MC.panel then return end
    local viewHidden = MC._viewIndicatorsHidden and true or false
    MC._indicatorsHidden = viewHidden

    -- The filter is module-scoped, so it goes with the view state OR with
    -- Options.
    setIndicatorShown(MC.expansionFilterBtn, viewHidden or MC.IsOptionsSelected())
    setIndicatorShown(MC.scoreIndicator, viewHidden)
    setIndicatorShown(MC.peerIndicator, viewHidden)
    -- Sort orders a tracker list, so it hides with the view chrome AND on
    -- Options/search, which have no source groups to order. Hiding here is
    -- the chrome half; RefreshSortIndicator owns the per-tab half.
    setIndicatorShown(MC.sortIndicator, viewHidden)
    if not viewHidden and MC.RefreshSortIndicator then MC.RefreshSortIndicator() end
    -- Search rides the chain's compact/strip hiding but, being an action
    -- rather than a readout, stays available on the Options page.
    setIndicatorShown(MC.searchIndicator, viewHidden)
    setIndicatorShown(MC.goalsIndicator, viewHidden)
    -- The counter hides for Options, since it counts a tracker list.
    -- Exception: the strip is built around it (icon, wordmark, counter,
    -- restore) and would collapse to a gap without it. Its value is the
    -- last tracker's and stays accurate while Options is up, so the
    -- strip keeps showing it. It is a FontString, and the
    -- score/peer/filter chain hangs off it — hiding a region does not
    -- break anchors that reference it, so the rest keeps its place.
    local stripView = MC.panel and MC.panel.GetViewMode
        and MC.panel:GetViewMode() == "strip"
    setIndicatorShown(MC.panel and MC.panel.titleProgressText,
        MC.IsOptionsSelected() and not stripView)

    -- Peer visibility also depends on rosterEnabled; re-derive it on
    -- return to full rather than blanket-showing.
    if not viewHidden and MC.RefreshPeerIndicator then MC.RefreshPeerIndicator() end

    -- Search's floating chrome anchors off the title bar, which compact/
    -- strip hide outright — take the chrome down with it, and bring it
    -- back when a full view returns while search is still the selection.
    if MC.Search and MC.Search.OnViewChanged then MC.Search:OnViewChanged() end
end

function MC.CreatePanel()
    if MC.panel then return end

    -- Live theme switch: re-render the active tab so row colors,
    -- header accents, and other per-Refresh visuals pick up the new
    -- palette. The lib's own hooks handle panel chrome (backdrop,
    -- title bar, tabs, indicator buttons).
    MUI.RegisterThemeHook(function()
        if MC.RefreshActive then MC.RefreshActive() end
    end)

    local panel
    if MC.GetUIStyle and MC.GetUIStyle() == "premium"
       and MUI.CreatePremiumShell and MC.MakePremiumDB then
        -- Set before construction: the shell fires onViewChanged from its
        -- own constructor, and the indicator applier is premium-only.
        MC._premiumShell = true
        panel = MUI:CreatePremiumShell({
            name          = "CollectionistPremium",
            title         = "Collectionist",
            icon          = "Interface\\Icons\\INV_Misc_Book_09",
            version       = MC.version,
            db            = MC.MakePremiumDB(),
            defaultWidth  = 980,
            defaultHeight = 680,
            -- Floor for the header to hold the page title on the left
            -- and, on the right, three window controls plus the whole
            -- indicator chain (filter, peers, score, counter).
            minWidth      = 820,
            maxWidth      = 1400,
            minHeight     = 520,
            maxHeight     = 1000,
            onRefresh     = function(shell)
                -- Resizes and view-state applies move the nav container's
                -- bottom edge, and with it the bottom-anchored Options
                -- row. The indicator re-seats itself off the container's
                -- OnSizeChanged (lib.MakeNavIndicator) — that is the path
                -- that sees the END of an animated resize, which this one
                -- cannot: ApplyMinimizeState calls onRefresh before
                -- lib.SizeTo has moved anything. This stays as the row
                -- re-anchor for the same event. onRefresh also fires for
                -- every section expand/collapse, where the sidebar has
                -- not moved at all; a full Reflow there would re-anchor
                -- all eight rows and re-derive every module's counts for
                -- nothing, so gate on the one measurement that changes.
                local nav = shell and shell.navContainer
                local h = nav and nav:GetHeight() or 0
                if h ~= MC._navContainerHeight then
                    MC._navContainerHeight = h
                    if MC.PremiumNav and MC.PremiumNav.Reflow then
                        MC.PremiumNav:Reflow()
                    end
                end
                MC.RefreshActive()
            end,
            -- Footer behaviors: the lib shell is consumer-agnostic, so
            -- the /mc-scan body and the Inspector hook arrive as opts.
            onScan        = function()
                for _, mod in ipairs(MC.modules) do
                    if mod.Scanner then MC.ScanNow(mod) end
                end
            end,
            onInspector   = function()
                if MC.ShowPeerPanel then MC.ShowPeerPanel() end
            end,
            inspectorVisible = function()
                return (MC.db and MC.db.rosterEnabled) and true or false
            end,
            -- View-state changes (full/compact/strip). The initial fire
            -- can happen before the indicator chain exists; the handler
            -- nil-guards each button and CreatePanel re-applies after
            -- the chain is built.
            -- Compact drops the sidebar, so the page title becomes the page
            -- picker. The lib owns the affordance; the list of pages is ours.
            onTitleClick  = function(_, anchor) MC.ShowPagePicker(anchor) end,
            onViewChanged = function(_, mode)
                MC._viewIndicatorsHidden = (mode ~= "full")
                MC._ApplyIndicatorVisibility()
            end,
            -- The footer's Options button selects the Options row in the
            -- sidebar rather than opening a second window. It still
            -- toggles, as it did when it owned a window: pressing it
            -- while Options is showing goes back to the tracker the
            -- player came from, which is the only way to dismiss Options
            -- without picking a specific tab.
            onOptions     = function() MC.ToggleOptions() end,
            -- Collection spine data: per-source {collected, total} for
            -- the active tab, filter-scoped like the 17/90 counter (both
            -- read the same visible result sets). Recipes' per-skillLine
            -- results don't fit the source shape — nil hides the spine.
            spineData = function()
                -- Options is not a tracker list: nothing for the spine to
                -- describe, so the header falls back to its plain accent
                -- hairline rather than showing the last module's data.
                if MC.IsOptionsSelected() then return nil end
                local mod = MC.modulesByKey[MC.activeModule]
                local r = mod and mod.Scanner and mod.Scanner.results
                if not r or not r.bySource or mod.key == "recipes" then return nil end
                local per, order = {}, {}
                local function bucket(src)
                    if not per[src] then
                        per[src] = { key = src, collected = 0, total = 0 }
                        order[#order + 1] = src
                    end
                    return per[src]
                end
                for _, e in ipairs(r.collected or {}) do
                    if e.source then
                        local b = bucket(e.source)
                        b.collected = b.collected + 1
                        b.total = b.total + 1
                    end
                end
                for src, entries in pairs(r.bySource) do
                    local n = MC.CountObtainableEntries(entries)
                    if n > 0 then bucket(src).total = bucket(src).total + n end
                end
                -- Alphabetical: stable across rescans (pairs order isn't).
                table.sort(order)
                local out = {}
                for _, src in ipairs(order) do out[#out + 1] = per[src] end
                return out
            end,
        })
        -- PremiumNav duck-types TabBar's Create/SetActive/Reflow.
        MC.TabBar = MC.PremiumNav or MC.TabBar
    else
        panel = MUI:CreatePanel({
            name          = "Collectionist",
            title         = "Collectionist",
            icon          = "Interface\\Icons\\INV_Misc_Book_09",
            db            = MC.db,
            defaultWidth  = 520,
            defaultHeight = 560,
            minWidth      = 520,
            maxWidth      = 700,
            minHeight     = 140,
            maxHeight     = 900,
            onRefresh     = function() MC.RefreshActive() end,
        })
    end

    -- One binding instead of a sortEntries option on six module pages; the
    -- library stays ignorant of what the ordering means.
    MUI.defaultSortEntries = MC.SortEntries
    MC.panel = panel

    if MC.TabBar then
        MC.TabBar:Create(panel, MC.modules, function(key) MC.SwitchTab(key) end)
    end
    -- TabBar:Create re-anchors the scroll frame to its own hard-coded
    -- insets, so re-run ApplyBackdrop to re-apply NineSlice insets on
    -- top.
    panel:ApplyBackdrop()
    MC.BuildConfig()

    -- Title-bar indicator chain (right→left): progressText, scoreBtn,
    -- peerBtn. Anchored once at the end so each one can reference its
    -- right-hand neighbor.
    local bar = panel.frame and panel.frame.titleBar
    if bar then
        local theme = MC.Theme
        local sub = theme.colors.tooltipSubtext

        -- Expansion filter
        -- The expansion filter button used to live here. Options >
        -- Expansions is now the only control over what a tab shows;
        -- RefreshExpansionFilterButton stays as a no-op so the call
        -- sites scattered through the scan/refresh paths keep working.
        function MC.RefreshExpansionFilterButton() end

        -- Collection Score
        local scoreBtn = MUI.MakeIndicatorBtn(bar, {
            fgColor    = theme.colors.scoreAccent,
            hoverColor = theme.colors.scoreAccentHover,
            tooltip = function(_, tt)
                if not MC.GetLocalScore then return end
                local total, legacy, byMod = MC.GetLocalScore()
                tt:SetText("Collection Score")
                tt:AddDoubleLine("Total", tostring(total),
                    1, 1, 1, theme.colors.scoreAccent[1], theme.colors.scoreAccent[2], theme.colors.scoreAccent[3])
                if MC.modules then
                    for _, m in ipairs(MC.modules) do
                        local b = byMod[m.key]
                        if b and b.score > 0 then
                            tt:AddDoubleLine("  " .. (m.label or m.key),
                                tostring(b.score),
                                0.85, 0.85, 0.85,
                                theme.colors.scoreAccent[1], theme.colors.scoreAccent[2], theme.colors.scoreAccent[3])
                        end
                    end
                end
                if legacy > 0 then
                    tt:AddLine(" ")
                    tt:AddDoubleLine("Legacies", tostring(legacy),
                        0.7, 0.7, 0.85, 0.7, 0.7, 0.85)
                end
            end,
        })
        MC.scoreIndicator = scoreBtn

        function MC.RefreshScoreIndicator()
            local btn = MC.scoreIndicator
            if not btn or not MC.GetLocalScore then return end
            local total, legacy = MC.GetLocalScore()
            if legacy > 0 then
                btn:SetLabel(format("CS %d  ·  %dL", total, legacy))
            else
                btn:SetLabel(format("CS %d", total))
            end
        end
        MC.RefreshScoreIndicator()

        -- Peer count
        local peerBtn = MUI.MakeIndicatorBtn(bar, {
            tooltip = "Open Collection Inspector",
            onClick = function()
                if MC.ShowPeerPanel then MC.ShowPeerPanel() end
            end,
        })
        MC.peerIndicator = peerBtn

        -- Row order. A labelled indicator rather than an icon: the current
        -- mode has to be readable at a glance, or cycling through three
        -- states with no visible label is a guessing game.
        local sortBtn = MUI.MakeIndicatorBtn(bar, {
            -- Pinned width. The label cycles between "Default" and
            -- "Expansion h88", and an auto-sized button would shove
            -- the peers/score chain sideways on every click.
            fixedWidth = 86,
            tooltip = function(_, tt)
                tt:SetText("Sort rows")
                for _, m in ipairs(MC.SORT_MODES) do
                    local active = m.key == MC.GetSortMode()
                    tt:AddDoubleLine(m.label, m.tip,
                        active and 1 or 0.6, active and 1 or 0.6, active and 1 or 0.6,
                        0.7, 0.7, 0.7)
                end
                tt:AddLine(" ")
                tt:AddLine("Click to cycle. Remembered per tab.", 0.6, 0.6, 0.6)
            end,
            onClick = function()
                MC.CycleSortMode()
                MC.RefreshSortIndicator()
                MC.RefreshActive()
            end,
        })
        MC.sortIndicator = sortBtn

        function MC.RefreshSortIndicator()
            local btn = MC.sortIndicator
            if not btn then return end
            -- Options and search have no per-source row groups to order.
            local applies = not (MC.IsOptionsSelected and MC.IsOptionsSelected())
                and not (MC.IsSearchSelected and MC.IsSearchSelected())
                and not (MC.IsGoalsSelected and MC.IsGoalsSelected())
            if not applies then btn:Hide() return end
            btn:Show()
            local mode = MC.SORT_MODE_BY_KEY[MC.GetSortMode()]
            btn:SetLabel(mode and mode.label or "Default")
        end
        MC.RefreshSortIndicator()

        -- Anchor chain right→left from progressText (or bar's right edge).
        local rightAnchor, rightPoint, rightOfsX = bar, "RIGHT", -68
        if panel.titleProgressText then
            rightAnchor, rightPoint, rightOfsX = panel.titleProgressText, "LEFT", -10
        end
        scoreBtn:SetPoint("RIGHT", rightAnchor, rightPoint, rightOfsX, 0)
        peerBtn:SetPoint("RIGHT", scoreBtn, "LEFT", -10, 0)
        sortBtn:SetPoint("RIGHT", peerBtn, "LEFT", -10, 0)

        -- Search. A view action rather than an indicator, so it stays up
        -- on the Options page (unlike score/peer) and only follows the
        -- chain down into compact/strip.
        local searchBtn = MUI.MakeHeaderIconBtn(bar,
            "Interface\\Common\\UI-Searchbox-Icon", 13,
            theme.colors.btnTealFg,
            theme.colors.btnTealHoverBg,
            theme.colors.btnTealHoverBd,
            "Search  (/mc find)")
        searchBtn:SetPoint("RIGHT", sortBtn, "LEFT", -10, 0)
        -- SelectSearch already handles the already-open case by refocusing
        -- the input; no duplicate guard here.
        searchBtn:SetScript("OnClick", function() MC.SelectSearch() end)
        MC.searchIndicator = searchBtn

        -- Closest to done. Sits with search as a view action rather than a
        -- readout, so it survives the Options page the same way.
        local goalsBtn = MUI.MakeHeaderIconBtn(bar,
            "Interface\\Common\\ReputationStar", 13,
            theme.colors.btnTealFg,
            theme.colors.btnTealHoverBg,
            theme.colors.btnTealHoverBd,
            "Closest to done")
        goalsBtn:SetPoint("RIGHT", searchBtn, "LEFT", -10, 0)
        goalsBtn:SetScript("OnClick", function() MC.SelectGoals() end)
        MC.goalsIndicator = goalsBtn

        MC.RefreshPeerIndicator()

        -- The premium shell may already be in the compact/strip state
        -- (saved from last session); its initial onViewChanged fired
        -- before this chain existed, so re-apply visibility now.
        if panel.GetViewMode and panel:GetViewMode() ~= "full" then
            MC._viewIndicatorsHidden = true
            MC._ApplyIndicatorVisibility()
        end
    end
end

-- Updates the title-bar peer-count text. Called whenever a new peer is
-- received, the user toggles Roster on/off, or the Roster is cleared.
function MC.RefreshPeerIndicator()
    local btn = MC.peerIndicator
    if not btn then return end
    -- Premium compact/strip: the whole indicator chain is hidden. This
    -- is the only indicator that self-Shows from events, so it must
    -- respect the flag itself. Never set under the classic shell.
    if MC._indicatorsHidden then
        btn:Hide()
        return
    end
    if not (MC.db and MC.db.rosterEnabled) then
        btn:Hide()
        return
    end
    local count = 0
    if MC.RosterDB then
        -- Skip reserved meta keys like _bnetCache so the indicator
        -- reflects the actual peer count. Records without counts are
        -- partial (a stray 's'/'e'/'b' arrived before the peer's 'u'
        -- update) — don't count them until they're renderable.
        for k, v in pairs(MC.RosterDB) do
            if type(k) == "string" and k:sub(1, 1) ~= "_"
               and type(v) == "table" and v.counts then
                count = count + 1
            end
        end
    end
    btn:GetFontString():SetText(format("%d peer%s", count, count == 1 and "" or "s"))
    btn:SetWidth(btn:GetFontString():GetStringWidth() + 10)
    btn:Show()
end

--------------------------------------------------------------------------
-- Tab switching
--------------------------------------------------------------------------
-- The Options category rail sits beside the scroll child rather than
-- inside it (it must not scroll), so the cross-fade has to reach it
-- separately. nil for tracker views and before the first options render.
local function ConfigRail()
    local p = MC.panel
    return p and p.GetConfigContentRail and p:GetConfigContentRail() or nil
end

-- One cross-fade, shared by every selection — tracker or Options: the
-- outgoing content is gone the instant the row is clicked, and the
-- incoming one fades up. Alpha is dropped before the rebuild so the
-- rebuild itself is never seen, then raised from zero — a plain FadeIn
-- would no-op at full alpha.
local function TransitionContent(rebuild)
    -- Tooltip and row frames are about to be reused by the new view.
    MC.HideInfoTooltip()
    if GameTooltip then GameTooltip:Hide() end

    -- Hide stale GetOrCreate children left behind by the previous view
    -- (progress bars, emptyText, etc).
    if MC.panel and MC.panel.scrollChild and MC.panel.scrollChild._children then
        for _, child in pairs(MC.panel.scrollChild._children) do
            if child.Hide then child:Hide() end
        end
    end

    if MC.panel and MC.panel.scrollFrame then
        MC.panel.scrollFrame:SetVerticalScroll(0)
    end

    local child = MC.panel and MC.panel.scrollChild
    if child then child:SetAlpha(0) end
    local outgoingRail = ConfigRail()
    if outgoingRail then outgoingRail:SetAlpha(0) end

    rebuild()

    if child then MUI.FadeIn(child, MC.TAB_FADE) end
    -- Only fade a rail the rebuild actually left on screen: FadeIn shows
    -- what it fades, which would resurrect the rail over a tracker list.
    local rail = ConfigRail()
    if rail then
        if rail:IsShown() then
            rail:SetAlpha(0)
            MUI.FadeIn(rail, MC.TAB_FADE)
        else
            rail:SetAlpha(1)
        end
    end
end

-- Accepts a module key or MC.OPTIONS_KEY. The sidebar hands whichever the
-- clicked row carries straight through, so both kinds land here.
function MC.SwitchTab(key)
    if key == MC.OPTIONS_KEY then return MC.SelectOptions() end

    local mod = MC.modulesByKey[key]
    if not mod or not MC.IsModuleEnabled(key) then return end

    local wasOptions = MC.IsOptionsSelected()
    local wasSearch = MC.IsSearchSelected()
    MC.activeSelection = key
    MC.activeModule = key
    if MC.cdb then MC.cdb.activeTab = key end

    -- Leaving search takes its floating chrome (input + scope chips) down;
    -- it is parented to the window frame, so nothing else hides it.
    if wasSearch and MC.Search and MC.Search.HideView then MC.Search:HideView() end

    if MC.TabBar then MC.TabBar:SetActive(key) end
    if MC.RefreshExpansionFilterButton then MC.RefreshExpansionFilterButton() end
    if wasOptions then MC._ApplyIndicatorVisibility() end

    if mod.UI and not mod.UI._initialized then
        mod.UI:Init(MC.panel, mod)
        mod.UI._initialized = true
    end

    TransitionContent(function()
        -- Leaving Options: its pooled widgets share the scroll child with
        -- the tracker list that is about to render, so take them off it
        -- before the module draws.
        if wasOptions and MC.panel.ClearConfigContent then
            MC.panel:ClearConfigContent()
        end
        MC.RefreshActive()
    end)
end

-- Options as a view of the main window. Premium only: the classic panel
-- has no sidebar to select it from, so it keeps the settings window.
function MC.SelectOptions()
    if not MC.panel then return end
    if not MC.panel.RenderConfigInContent then
        -- Classic shell (or a lib too old to render options in place).
        if MC.panel.ToggleConfig then MC.panel:ToggleConfig() end
        return
    end
    -- Already the selection: re-clicking the row (or the footer button
    -- landing here) would release every pooled widget and cross-fade the
    -- page back in over itself, which reads as a flicker for no change.
    -- RefreshActive is the path for redrawing a page that is already up.
    if MC.IsOptionsSelected() then return end

    MC.activeSelection = MC.OPTIONS_KEY

    -- Search → Options: same chrome teardown SwitchTab does on its way to
    -- a tracker.
    if MC.Search and MC.Search.HideView then MC.Search:HideView() end

    if MC.TabBar and MC.TabBar.SetActive then
        MC.TabBar:SetActive(MC.OPTIONS_KEY)
    end
    -- The expansion filter and the progress counter describe a tracker
    -- list; neither has anything to say about Options.
    MC._ApplyIndicatorVisibility()

    TransitionContent(function()
        -- The tracker rows are pooled on the shell, not on the module, so
        -- nothing releases them unless we do — they would sit under the
        -- options page otherwise.
        if MC.panel.pool then MC.panel.pool:ReleaseAll() end
        MC.BuildConfig()
    end)
end

-- The footer button's behavior: in, then back out. Under classic this is
-- still the settings window's own open/close (SelectOptions forwards to
-- ToggleConfig). Under premium, "out" means the tracker that was last
-- selected — MC.activeModule is untouched while Options is showing — or
-- the first enabled one if that module was disabled from the page the
-- player is standing on.
function MC.ToggleOptions()
    if not MC.IsOptionsSelected() then return MC.SelectOptions() end
    local back = MC.activeModule
    if not back or not MC.IsModuleEnabled(back) then
        back = MC.FirstEnabledModule()
    end
    -- Everything disabled: there is nothing to go back to, so Options
    -- stays up rather than leaving an empty content area behind.
    if back then MC.SwitchTab(back) end
end

--------------------------------------------------------------------------
-- Search view. State/index/render live in Search.lua; this is the tab
-- plumbing, kept beside its siblings (SwitchTab / SelectOptions) because
-- it needs TransitionContent, which is file-local to Core.
--
-- activeSelection carries SEARCH_KEY while activeModule stays put, so
-- backing out of search reopens the last tracker — the same contract
-- Options uses.
--------------------------------------------------------------------------

function MC.IsSearchSelected()
    return MC.activeSelection == MC.SEARCH_KEY
end

function MC.SelectSearch(query)
    if not MC.panel then return end
    -- Re-clicking the header magnifier while search is up just refocuses
    -- the input rather than flickering the page through another fade.
    if MC.IsSearchSelected() then
        if MC.Search and MC.Search.inputFrame then MC.Search.inputFrame:Focus() end
        return
    end

    local wasOptions = MC.IsOptionsSelected()
    MC.activeSelection = MC.SEARCH_KEY

    -- Deactivate the sidebar rows and re-seat the page header, mirroring
    -- SwitchTab: PremiumNav's SetActive hides the travelling indicator for
    -- an unknown key and titles the page "Search". Classic TabBar merely
    -- deactivates its tabs.
    if MC.TabBar and MC.TabBar.SetActive then
        MC.TabBar:SetActive(MC.SEARCH_KEY)
    end

    if wasOptions then MC._ApplyIndicatorVisibility() end

    TransitionContent(function()
        -- Leaving Options: its pooled widgets share the scroll child with
        -- the results about to render (same teardown SwitchTab does).
        if wasOptions and MC.panel.ClearConfigContent then
            MC.panel:ClearConfigContent()
        elseif not wasOptions then
            if MC.panel.pool then MC.panel.pool:ReleaseAll() end
        end
        if MC.Search and MC.Search.ShowView then
            MC.Search:ShowView(query, true)
        end
    end)
end

-- The compact view has no sidebar, so switching page there means clicking the
-- title. Lists the same things the sidebar does, in the same order, plus the
-- two views that live in the header rather than the rail.
function MC.ShowPagePicker(anchorFrame)
    if not (MC.panel and anchorFrame) then return end
    MC._pagePicker = MC._pagePicker or MUI.MakeDropdown()

    local items = {}
    for _, m in ipairs(MC.modules or {}) do
        if not (MC.IsModuleEnabled and MC.IsModuleEnabled(m.key) == false) then
            local key = m.key
            items[#items + 1] = {
                label = m.label or key,
                selected = (MC.activeSelection == nil or MC.activeSelection == key)
                    and MC.activeModule == key
                    and not MC.IsOptionsSelected() and not MC.IsSearchSelected()
                    and not MC.IsGoalsSelected(),
                onClick = function() MC.SwitchTab(key) end,
            }
        end
    end

    items[#items + 1] = {
        label = "Closest to Done",
        selected = MC.IsGoalsSelected(),
        onClick = function() if not MC.IsGoalsSelected() then MC.SelectGoals() end end,
    }
    items[#items + 1] = {
        label = "Search",
        selected = MC.IsSearchSelected(),
        onClick = function() MC.SelectSearch() end,
    }
    items[#items + 1] = {
        label = "Options",
        selected = MC.IsOptionsSelected(),
        onClick = function() if MC.SelectOptions then MC.SelectOptions() end end,
    }

    MC._pagePicker:ShowAt(anchorFrame, "BOTTOMLEFT", "TOPLEFT", items)
end

function MC.SelectGoals()
    if not MC.panel then return end
    -- Clicking the icon again backs out to the tracker underneath. Goals is a
    -- detour, not a destination, and there was otherwise no way out of it
    -- except picking a tab from the sidebar.
    if MC.IsGoalsSelected() then
        if MC.activeModule then MC.SwitchTab(MC.activeModule) end
        return
    end
    local wasOptions = MC.IsOptionsSelected()
    MC.activeSelection = MC.GOALS_KEY

    if MC.TabBar and MC.TabBar.SetActive then
        MC.TabBar:SetActive(MC.GOALS_KEY)
    end
    if wasOptions then MC._ApplyIndicatorVisibility() end
    -- Search owns floating chrome above the scroll viewport; leaving it for
    -- another view has to take that chrome down or it hangs over the goals.
    if MC.Search and MC.Search.HideView then MC.Search:HideView() end
    MC._ApplyIndicatorVisibility()

    TransitionContent(function()
        if wasOptions and MC.panel.ClearConfigContent then
            MC.panel:ClearConfigContent()
        elseif MC.panel.pool then
            MC.panel.pool:ReleaseAll()
        end
        if MC.Goals then MC.Goals:Render() end
    end)
end

-- Re-render the options page on the next frame, once, however many
-- callers ask for it.
--
-- Off the current call stack on purpose: RefreshActive is what an option
-- setter calls to redraw the list behind it ("Show <collected>" from a
-- checkbox's OnClick, Background Opacity from a slider's OnMouseUp), and
-- with Options in the content area that redraw is the options page
-- itself. Rendering it synchronously would poolReset — hide — the very
-- widget whose handler is still running, then re-acquire and re-show it
-- underneath itself. The settings window never had that shape: it only
-- ever re-rendered a page nothing was standing on. Same reason
-- SetModuleEnabled defers its own BuildConfig.
function MC.QueueConfigRebuild()
    if MC._configRebuildQueued then return end
    MC._configRebuildQueued = true
    C_Timer.After(0, function()
        MC._configRebuildQueued = false
        -- The player can leave Options inside that frame; SwitchTab has
        -- already rendered the tracker by then and must not be painted
        -- over.
        if MC.IsOptionsSelected() then MC.BuildConfig() end
    end)
end

-- Refresh hides the tooltip first, otherwise it can stay pinned to a row
-- that's about to be released back to the pool.
function MC.RefreshActive()
    if not MC.panel or not MC.panel.scrollChild then return end
    -- Every "the content area is stale" path funnels through here —
    -- scans, theme switches, resizes, filter changes. While Options owns
    -- the content area it is the thing that has to be redrawn; letting a
    -- module render would paint a tracker list over it.
    if MC.IsOptionsSelected() then
        MC.QueueConfigRebuild()
        if MC.RefreshScoreIndicator then MC.RefreshScoreIndicator() end
        return
    end
    -- While search owns the content area, a stale-path refresh re-runs the
    -- current query (fresh collected badges after a rescan) instead of
    -- painting a tracker list over the results.
    if MC.IsSearchSelected() then
        if MC.Search and MC.Search.RefreshResults then MC.Search:RefreshResults() end
        if MC.RefreshScoreIndicator then MC.RefreshScoreIndicator() end
        return
    end
    -- Goals rank live scanner output, so a rescan has to redraw them too.
    if MC.IsGoalsSelected() then
        if MC.Goals then MC.Goals:Render() end
        if MC.RefreshScoreIndicator then MC.RefreshScoreIndicator() end
        return
    end
    local mod = MC.modulesByKey[MC.activeModule]
    if not mod or not mod.UI then return end
    MC.HideInfoTooltip()
    if GameTooltip then GameTooltip:Hide() end
    mod.UI:Refresh()
    -- Score depends on every scanner; refresh it whenever any tab
    -- redraws so the title-bar number tracks the latest scan.
    if MC.RefreshScoreIndicator then MC.RefreshScoreIndicator() end
    -- Sort is remembered per tab, so the label follows the active one.
    if MC.RefreshSortIndicator then MC.RefreshSortIndicator() end
end

--------------------------------------------------------------------------
-- Build the unified options panel from each module's config defs.
--
-- The def list is split into pages by `{ type = "page" }` markers; the
-- renderer shows one page at a time and drives the category rail down
-- the left of the settings window from the markers' labels. Five pages:
-- General (actions, display, sharing), Modules (enable + reorder),
-- Expansions (browse toggles), Trackers (per-module options), and
-- Appearance. Every get/set below is unchanged from the single-scroll
-- layout — only the grouping moved.
--------------------------------------------------------------------------
function MC.BuildConfig()
    if not MC.panel then return end

    local defs = {}

    defs[#defs + 1] = { type = "page", label = "General" }
    defs[#defs + 1] = { type = "section", label = "ACTIONS" }
    -- The Scan action used to be a shell footer button; it lives here now
    -- so both shells reach it the same way. Same body as `/mc scan`
    -- minus the chat confirmation.
    defs[#defs + 1] = {
        type    = "button",
        label   = "Rescan every collection module",
        text    = "Scan",
        tooltip = "Rescan all collection modules",
        onClick = function()
            for _, mod in ipairs(MC.modules) do
                if mod.Scanner then MC.ScanNow(mod) end
            end
        end,
    }

    defs[#defs + 1] = { type = "divider" }
    defs[#defs + 1] = { type = "section", label = "DISPLAY" }
    defs[#defs + 1] = { type = "checkbox", label = "Lock Frame",
        get = function() return MC.db.locked end,
        set = function(v)
            MC.db.locked = v
            if MC.panel.frame then MC.panel.frame:SetMovable(not v) end
            MC.panel:UpdateDraggerVisibility()
        end }
    defs[#defs + 1] = { type = "checkbox", label = "Hide Minimap Icon",
        get = function() return MC.db.minimap and MC.db.minimap.hide or false end,
        set = function(v)
            if MC.db.minimap then MC.db.minimap.hide = v end
            if MC.MinimapButton and MC.MinimapButton.Update then MC.MinimapButton:Update() end
        end }
    defs[#defs + 1] = { type = "checkbox", label = "Animations",
        get = function() return MC.db.animations ~= false end,
        set = function(v)
            MC.db.animations = v and true or false
            MUI.animEnabled = v and true or false
        end }
    -- Stored account-wide next to lastSeenVersion, not in MC.db, so turning
    -- it off on one character turns it off everywhere.
    defs[#defs + 1] = { type = "checkbox", label = "Show What's New after updating",
        get = function() return not (CollectionistDB and CollectionistDB.whatsNewDisabled) end,
        set = function(v)
            if CollectionistDB then CollectionistDB.whatsNewDisabled = not v end
        end }
    defs[#defs + 1] = { type = "checkbox", label = "Collection status on item tooltips",
        get = function() return not (MC.db.tooltipStatusDisabled) end,
        set = function(v)
            MC.db.tooltipStatusDisabled = not v
            if MC.TooltipsSetEnabled then MC.TooltipsSetEnabled(v) end
        end }
    defs[#defs + 1] = { type = "divider" }
    defs[#defs + 1] = { type = "section", label = "SHARING" }
    defs[#defs + 1] = { type = "checkbox",
        label = "Enable Sharing",
        get = function() return MC.db.rosterEnabled and true or false end,
        set = function(v)
            if MC.SetRosterEnabled then
                MC.SetRosterEnabled(v, v)
            else
                MC.db.rosterEnabled = v and true or false
            end
        end }

    defs[#defs + 1] = { type = "page", label = "Modules" }
    defs[#defs + 1] = { type = "section", label = "MODULES" }
    local modCount = #MC.modules
    for i, mod in ipairs(MC.modules) do
        local key = mod.key
        defs[#defs + 1] = {
            type    = "checkbox",
            label   = mod.label,
            get     = function() return MC.IsModuleEnabled(key) end,
            set     = function(v) MC.SetModuleEnabled(key, v) end,
            -- Up/down arrows let the user reorder modules. The buttons
            -- swap this module with its neighbor and then BuildConfig
            -- re-runs so the visible position updates immediately.
            reorder = {
                isFirst = (i == 1),
                isLast  = (i == modCount),
                onUp    = function() MC.MoveModule(key, -1) end,
                onDown  = function() MC.MoveModule(key,  1) end,
            },
        }
    end

    -- Browse toggles per expansion with registered content. Unchecking
    -- hides that expansion from the tab lists only — totals, Collection
    -- Score, and sharing still count it.
    defs[#defs + 1] = { type = "page", label = "Expansions" }
    defs[#defs + 1] = { type = "section", label = "BROWSE EXPANSIONS" }
    for _, e in ipairs(MC.EXPANSIONS or {}) do
        if MC._registeredExpansions and MC._registeredExpansions[e.key] then
            local expKey = e.key
            defs[#defs + 1] = {
                type  = "checkbox",
                label = e.label,
                get   = function() return MC.IsExpansionEnabled(expKey) end,
                set   = function(v) MC.SetExpansionEnabled(expKey, v) end,
            }
        else
            -- Skeleton row for expansions without content: greyed,
            -- checked, inert — flips live once a data file registers.
            defs[#defs + 1] = {
                type     = "checkbox",
                label    = e.label .. " (coming soon)",
                disabled = true,
                get      = function() return true end,
                set      = function() end,
            }
        end
    end

    -- Inject the "Show Collected" checkbox automatically from each module's
    -- collectedKey/collectedLabel; modules only have to declare extras.
    -- Each module's header is a sub-header inside the Trackers page.
    defs[#defs + 1] = { type = "page", label = "Trackers" }
    local firstTracker = true
    for _, mod in ipairs(MC.modules) do
        if MC.IsModuleEnabled(mod.key) and mod.UI then
            if firstTracker then
                firstTracker = false
            else
                defs[#defs + 1] = { type = "divider" }
            end
            defs[#defs + 1] = { type = "section", label = strupper(mod.label) }
            local key   = mod.opts.collectedKey or "showCollected"
            local label = mod.opts.collectedLabel or "collected"
            defs[#defs + 1] = {
                type = "checkbox",
                label = "Show " .. label:gsub("^%l", string.upper),
                get = function() return mod.db[key] end,
                set = function(v) mod.db[key] = v; MC.RefreshActive() end,
            }
            if mod.UI.GetConfigDefs then
                for _, def in ipairs(mod.UI:GetConfigDefs()) do
                    defs[#defs + 1] = def
                end
            end
        end
    end

    defs[#defs + 1] = { type = "page", label = "Appearance" }
    defs[#defs + 1] = { type = "section", label = "APPEARANCE" }
    defs[#defs + 1] = { type = "dropdown", label = "UI Style",
        options = {
            { label = "Simple (compact)", value = "classic" },
            { label = "Premium", value = "premium" },
        },
        get = function() return MC.GetUIStyle and MC.GetUIStyle() or "classic" end,
        set = function(v) if MC.SetUIStyle then MC.SetUIStyle(v) end end }
    defs[#defs + 1] = { type = "slider", label = "Background Opacity", min = 0.1, max = 1.0, step = 0.05,
        get = function() return MC.db.frameAlpha or 1.0 end,
        set = function(v)
            MC.db.frameAlpha = v
            MC.panel:ApplyBackdrop()
            MC.RefreshActive()
        end,
        fillColor = { 0.40, 0.40, 0.40 } }
    defs[#defs + 1] = { type = "slider", label = "Frame Scale", min = 0.5, max = 2.0, step = 0.05,
        get = function() return MC.db.frameScale or 1.0 end,
        set = function(v)
            MC.db.frameScale = v
            if MC.panel.frame then MC.panel.frame:SetScale(v) end
        end,
        fillColor = { 0.16, 0.78, 0.75 } }

    -- Options-as-a-view renders the same defs into the main content area;
    -- the settings window path is unchanged for everyone else.
    if MC.IsOptionsSelected() and MC.panel.RenderConfigInContent then
        MC.panel:RenderConfigInContent(defs)
    else
        MC.panel:PopulateConfig(defs)
    end
end

--------------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------------
SLASH_MIDNIGHTCOLLECTIONS1 = "/mc"
SLASH_MIDNIGHTCOLLECTIONS2 = "/midnightcollections"

local function PrintHelp()
    print(PREFIX .. " Commands:")
    print("  /mc - toggle panel")
    local keys = {}
    for _, mod in ipairs(MC.modules) do keys[#keys + 1] = mod.key end
    print("  /mc <module> - switch tab (" .. table.concat(keys, ", ") .. ")")
    print("  /mc scan - rescan all collection modules")
    print("  /mc collected [module] - toggle collected/learned display")
    print("  /mc reset - reset panel position + size")
    print("  /mc sharing on|off|announce|sync|prune|clear|status - optional sharing")
    print("  /mc score - show your Collection Score breakdown")
    print("  /mc whatsnew - what changed in this version")
    print("  /mc style classic|premium - switch UI shell (reload required)")
    print("  /mc targets - toggle the pinned-targets overlay")
    print("  /mc find <text> - global search (also: just /mc <anything>)")
    print("  /mc goals       - what you are closest to finishing")
    print("  /mc version - show addon version")
    print("  /mc help - show this help")
end

SlashCmdList["MIDNIGHTCOLLECTIONS"] = function(msg)
    -- Queries keep their original case (recents display it verbatim);
    -- command matching below runs on the lowercased copy.
    local rawQuery = strtrim(msg or "", " \t\r\n")
    msg = strlower(rawQuery)

    if msg == "" then
        if MC.panel then MC.panel:Toggle() end
        return
    end

    local cmd, arg = strsplit(" ", msg, 2)

    if MC.modulesByKey[cmd] then
        if not MC.IsModuleEnabled(cmd) then
            print(format("%s Module '%s' is disabled.", PREFIX, cmd))
            return
        end
        MC.SwitchTab(cmd)
        if MC.panel then MC.panel:Show() end
        return
    end

    if cmd == "scan" then
        for _, mod in ipairs(MC.modules) do
            if mod.Scanner then MC.ScanNow(mod) end
        end
        print(PREFIX .. " All collection modules scanned.")
    elseif cmd == "collected" or cmd == "learned" then
        local target = (arg and MC.modulesByKey[arg]) and arg or MC.activeModule
        local mod = MC.modulesByKey[target]
        if not mod or not mod.db then
            print(format("%s No module to toggle. Try '/mc collected pets'.", PREFIX))
            return
        end
        local key = mod.opts.collectedKey or "showCollected"
        mod.db[key] = not mod.db[key]
        print(format("%s [%s] Show %s: %s",
            PREFIX, mod.label, mod.opts.collectedLabel or "collected", tostring(mod.db[key])))
        if MC.activeModule == target then MC.RefreshActive() end
    elseif cmd == "reset" then
        if InCombatLockdown() then
            print(PREFIX .. " Cannot reset panel during combat.")
            return
        end
        -- Replace the whole position table so a stale relativePoint from a
        -- previous drag doesn't survive the reset and put us off-screen.
        if MC.panel and MC.panel._ContentWidth then
            -- Gate on the actual shell type, not the saved style: if the
            -- premium shell failed to build (stale embedded lib), the
            -- classic branch below must handle the classic panel.
            -- Premium geometry lives in MC.db.premium; the shell's db
            -- proxy reads it dynamically, so wholesale replacement is
            -- safe.
            MC.db.premium = {
                position   = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 },
                panelWidth = 980, panelHeight = 680, minimized = false,
            }
            MC.db.frameAlpha = 1.0
            MC.db.frameScale = 1.0
            if MC.panel and MC.panel.frame then
                MC.panel.frame:ClearAllPoints()
                MC.panel.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                MC.panel.frame:SetSize(980, 680)
                MC.panel.frame:SetScale(1.0)
                -- Re-set the scroll child width first (bar fills read
                -- parent:GetWidth()), then un-hide the regions a
                -- minimized strip had collapsed — this order keeps the
                -- onRefresh inside ApplyMinimizeState from rendering one
                -- frame at the stale width.
                if MC.panel.scrollChild then
                    MC.panel.scrollChild:SetWidth(MC.panel:_ContentWidth())
                end
                if MC.panel.ApplyMinimizeState then MC.panel:ApplyMinimizeState() end
                if MC.panel.ApplyBackdrop then MC.panel:ApplyBackdrop() end
                MC.RefreshActive()
            end
        else
            MC.db.position = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 }
            MC.db.panelWidth = 520
            MC.db.panelHeight = 560
            MC.db.frameAlpha = 1.0
            MC.db.frameScale = 1.0
            if MC.panel and MC.panel.frame then
                MC.panel.frame:ClearAllPoints()
                MC.panel.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                MC.panel.frame:SetSize(MC.db.panelWidth, MC.db.panelHeight)
                MC.panel.frame:SetScale(1.0)
            end
        end
        print(PREFIX .. " Panel reset.")
    elseif cmd == "version" then
        print(format("%s Collectionist v%s", PREFIX, MC.version))
    elseif cmd == "whatsnew" or cmd == "changelog" then
        if MC.WhatsNew then
            -- Explicit request: show the notes for this version even when the
            -- player has already dismissed them.
            MC.WhatsNew:Show(MC.WhatsNew.PreviousVersionFloor())
        else
            print(PREFIX .. " What's New is unavailable — restart the client fully.")
        end
    elseif cmd == "score" then
        if not MC.GetLocalScore then
            print(PREFIX .. " Score system not available.")
        else
            local total, legacy, byMod = MC.GetLocalScore()
            print(format("%s Collection Score: |cffffcc66%d|r", PREFIX, total))
            for _, m in ipairs(MC.modules) do
                local b = byMod[m.key]
                if b and b.score > 0 then
                    print(format("    %s: %d", m.label or m.key, b.score))
                end
            end
            if legacy > 0 then
                print(format("  Legacies: %d (collected items no longer obtainable)", legacy))
            end
        end
    elseif cmd == "filter" then
        -- Retired: Options > Expansions decides what the tabs show.
        print(PREFIX .. " The expansion filter moved into Options > Expansions.")
    elseif cmd == "sharing" or cmd == "roster" then
        if MC.RosterSlashHandler then
            MC.RosterSlashHandler(arg)
        else
            print(PREFIX .. " Sharing not loaded.")
        end
    elseif cmd == "theme" then
        -- Retired: one look now. /mc style picks the shell.
        print(PREFIX .. " Themes have been retired — try /mc style classic|premium.")
    elseif cmd == "style" then
        local a = (arg or ""):lower()
        if a == "" or a == "status" then
            print(format("%s UI style: %s", PREFIX, MC.GetUIStyle and MC.GetUIStyle() or "classic"))
            print("    available: classic, premium (takes effect after /reload)")
        elseif (a == "classic" or a == "premium") and MC.SetUIStyle then
            MC.SetUIStyle(a)
        else
            print(PREFIX .. " /mc style classic|premium")
        end
    elseif cmd == "targets" then
        if MC.Targets then
            MC.Targets:Toggle()
        else
            print(PREFIX .. " Targets not loaded.")
        end
    elseif cmd == "find" or cmd == "search" then
        -- /mc find <query> — open the panel on the search view with the
        -- rest of the line as the query. No query: just open the view.
        if MC.panel and not MC.panel.frame:IsShown() then MC.panel:Show() end
        if rawQuery ~= cmd then
            local query = strtrim(rawQuery:sub(#cmd + 1))
            if MC.Search and MC.Search.AddRecent then MC.Search:AddRecent(query) end
            MC.SelectSearch(query)
        elseif MC.SelectSearch then
            MC.SelectSearch()
        end
    elseif cmd == "goals" or cmd == "next" then
        -- /mc goals — what you are closest to finishing.
        if MC.panel and not MC.panel.frame:IsShown() then MC.panel:Show() end
        if MC.SelectGoals then MC.SelectGoals() end
    elseif cmd == "help" then
        PrintHelp()
    else
        -- Anything unrecognized is a query. "/mc storm song" reads better
        -- than an error for the thing people will actually type, at the
        -- cost of typos ("/mc sharng on") silently becoming searches.
        if MC.SelectSearch then
            if MC.panel and not MC.panel.frame:IsShown() then MC.panel:Show() end
            MC.SelectSearch(rawQuery)
        else
            print(format("%s Unknown command '%s'. Type /mc help.", PREFIX, cmd))
        end
    end
end
