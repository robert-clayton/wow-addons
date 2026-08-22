local _, MC = ...

-- Global search across every tracker.
--
-- The view follows the Options pseudo-tab pattern: MC.SEARCH_KEY rides
-- in MC.activeSelection while a module stays in MC.activeModule, so
-- leaving search returns to whatever tracker the player was reading
-- (see Core.lua ToggleOptions for the same trick). All tab plumbing —
-- SwitchTab guards, RefreshActive guard, SelectSearch itself — lives in
-- Core.lua next to its siblings; this file owns state, index, query,
-- and rendering.
--
-- Indexing rules (deliberate asymmetry, documented per branch):
--   * Mounts, pets, toys, decorations, achievements, recipes index from
--     the RAW manifests. Scanner results are filter-scoped
--     (hideUnavailable / hideTradingPost strip entries during scan), and
--     a global search that silently misses toggled-off items reads as a
--     bug. Collected/icon state is resolved live through small per-module
--     collectors that mirror each scanner's journal lookup.
--   * Rares and treasures index from Scanner.results instead. Their names
--     come from live achievement criteria (GetAchievementCriteriaInfo),
--     not the manifest; reproducing the criteria/pending/NPC-map handling
--     here would fork the most fragile scanner logic for no gain.
--
-- What search respects vs ignores:
--   * Options > Expansions browse toggles apply at INDEX time, for every
--     module alike. Search covers enabled content.
--   * hideUnavailable / hideTradingPost are IGNORED — those curate the
--     tracker pages; search answers "does this exist anywhere".
--   * Faction-gated entries for the other faction never appear.

local MUI = LibStub("MidnightUI-1.0")

MC.SEARCH_KEY = "__search"
MC.Search = {}
local Search = MC.Search

local MAX_RESULTS = 100

-- Floating chrome above the scroll viewport: input row + scope chips.
-- Results start this far down inside the scrollChild so nothing hides
-- under the chrome, which is parented to the window frame (not the
-- scroll child — it must not scroll away with its own results).
local CHROME_PAD    = 6
local INPUT_H       = 26
local CHIPS_GAP     = 4
local CHIP_H        = 18
local RESULTS_GAP   = 8
local CHROME_H      = CHROME_PAD + INPUT_H + CHIPS_GAP + CHIP_H + RESULTS_GAP

--------------------------------------------------------------------------
-- Source metadata
--------------------------------------------------------------------------

-- Per-module label maps on MC, probed rather than assumed: modules grew
-- these independently (MountSourceLabels predates RareSourceLabels), and
-- a missing one falls through to prettified source text. Names verified
-- against each module's UI; RecipeSourceLabels is exported by
-- Modules/Recipes/UI.lua for exactly this shared use.
local LABEL_FIELDS = {
    mounts       = "MountSourceLabels",
    pets         = "PetSourceLabels",
    toys         = "ToySourceLabels",
    decorations  = "DecoSourceLabels",
    rares        = "RareSourceLabels",
    treasures    = "TreasureSourceLabels",
    recipes      = "RecipeSourceLabels",
    achievements = "AchievementSourceLabels",
}

local function prettifySource(src)
    if type(src) ~= "string" or src == "" then return "Unknown" end
    local s = src:gsub("_", " ")
    return s:gsub("^%l", string.upper)
end

-- Returns label, r, g, b for an entry's source type. Reads the RESOLVED
-- rec.source (entry-level, falling back to its group's at index time) —
-- achievement entries carry no source of their own.
function Search:SourceMeta(rec)
    local theme = MUI.Theme
    local src = rec.source or rec.ref.source
    local mapField = LABEL_FIELDS[rec.moduleKey]
    local map = mapField and rawget(MC, mapField)
    local label = (map and map[src]) or prettifySource(src)
    local sr, sg, sb
    if theme and theme.SourceColor then
        sr, sg, sb = theme:SourceColor(src)
    end
    return label, sr, sg, sb
end

local expansionLabels = {}
local function expansionLabel(key)
    return expansionLabels[key] or key
end
local function refreshExpansionLabels()
    wipe(expansionLabels)
    for _, e in ipairs(MC.EXPANSIONS or {}) do
        expansionLabels[e.key] = e.label
    end
end

--------------------------------------------------------------------------
-- Ownership collectors
--
-- One per raw-indexed moduleKey: resolve { collected, icon } for a
-- manifest entry. Each mirrors the API calls its module's Scanner makes;
-- they stay small on purpose, and the decorations/recipes branches reuse
-- their scanners' exposed methods outright.
--------------------------------------------------------------------------

local Collectors = {}

Collectors.mounts = function(ref)
    local collected, icon = false, nil
    if C_MountJournal and C_MountJournal.GetMountInfoByID and ref.mountID and ref.mountID > 0 then
        local ok, name, mountIcon, _, _, _, _, _, _, _, isCollected =
            pcall(C_MountJournal.GetMountInfoByID, ref.mountID)
        if ok then
            collected = isCollected and true or false
            if mountIcon and mountIcon ~= 0 then icon = mountIcon end
        end
    end
    return collected, icon
end

Collectors.pets = function(ref)
    local collected, icon = false, nil
    if C_PetJournal then
        if C_PetJournal.GetNumCollectedInfo and ref.speciesID then
            collected = (C_PetJournal.GetNumCollectedInfo(ref.speciesID) or 0) > 0
        end
        if C_PetJournal.GetPetInfoBySpeciesID and ref.speciesID then
            local ok, _, petIcon = pcall(C_PetJournal.GetPetInfoBySpeciesID, ref.speciesID)
            if ok and petIcon and petIcon ~= 0 and petIcon ~= "" then icon = petIcon end
        end
    end
    return collected, icon
end

Collectors.toys = function(ref)
    local collected, icon = false, nil
    if PlayerHasToy and ref.itemID and ref.itemID > 0 then
        collected = PlayerHasToy(ref.itemID) and true or false
    end
    if C_ToyBox and C_ToyBox.GetToyInfo and ref.itemID and ref.itemID > 0 then
        local ok, _, fileID = pcall(C_ToyBox.GetToyInfo, ref.itemID)
        if ok and fileID and fileID ~= 0 then icon = fileID end
    end
    return collected, icon
end

Collectors.decorations = function(ref, mod)
    -- The scanner exposes exactly the lookups needed (and owns the
    -- catalog-warmup subtleties); delegate rather than re-derive.
    if mod and mod.Scanner then
        local s = mod.Scanner
        if s.CheckCollected then
            local collected = s:CheckCollected(ref.decorID, ref.itemID)
            local icon
            if s.GetIcon then icon = s:GetIcon(ref.decorID, ref.itemID) end
            return collected and true or false, icon
        end
    end
    return false, nil
end

Collectors.achievements = function(ref)
    -- Mirrors Achievements/Scanner getAchievementInfo: icon rides in slot
    -- 10 of GetAchievementInfo; pcall because removed IDs hard-error.
    local getInfo = (C_AchievementInfo and C_AchievementInfo.GetAchievementInfo)
                    or GetAchievementInfo
    if not getInfo or not ref.achievementID then return false, nil end
    local ok, _, _, _, completed, _, _, _, _, _, icon = pcall(getInfo, ref.achievementID)
    if not ok then return false, nil end
    return completed and true or false, icon
end

Collectors.recipes = function(ref, mod)
    if mod and mod.Scanner and mod.Scanner.IsRecipeKnown and ref.id then
        return mod.Scanner:IsRecipeKnown(ref.id) and true or false, nil
    end
    return false, nil
end

-- Rares/treasures arrive pre-resolved from scanner results; no collector.

--------------------------------------------------------------------------
-- Index
--------------------------------------------------------------------------

Search.index = nil      -- array of records
Search.byItemID = nil   -- itemID -> record (first wins; tooltips only need one route in)

local function makeRecord(mod, ref, byItemID, skillLine, fallbackSource)
    local name = ref.name
    if type(name) ~= "string" or name == "" then return nil end
    local zone = ref.zone
    -- Some modules keep the sub-category key on the GROUP, not the entry
    -- (achievements file source under the achievement group); thread it
    -- down so SourceMeta never reads a bare prettify of nil.
    local src = ref.source or fallbackSource
    local hay = strlower(name)
    if zone then hay = hay .. "\1" .. strlower(zone) end
    if src then hay = hay .. "\1" .. strlower(src) end
    local rec = {
        moduleKey = mod.key,
        mod       = mod,
        ref       = ref,
        skillLine = skillLine,
        source    = src,
        hay       = hay,
        name      = name,
    }
    local collector = Collectors[mod.key]
    if collector then
        rec.collected, rec.icon = collector(ref, mod)
    elseif ref.collected ~= nil then
        -- Results-derived entries carry resolved state already.
        rec.collected = ref.collected and true or false
        rec.icon = ref.icon
    end
    if ref.itemID and ref.itemID > 0 and not byItemID[ref.itemID] then
        byItemID[ref.itemID] = rec
    end
    return rec
end

-- Rares/treasures: union of bySource buckets + the collected list gives
-- every entry whose name the scanner resolved this session.
local function addResultsBuckets(mod, index, byItemID, stats)
    local r = mod.Scanner and mod.Scanner.results
    if not r then return end
    local seen = {}
    local function addEntry(entry)
        if type(entry) ~= "table" or not entry.name or seen[entry] then return end
        seen[entry] = true
        local rec = makeRecord(mod, entry, byItemID)
        if rec then
            index[#index + 1] = rec
            stats.n = stats.n + 1
        end
    end
    for _, bucket in pairs(r.bySource or {}) do
        for _, entry in ipairs(bucket) do addEntry(entry) end
    end
    for _, entry in ipairs(r.collected or {}) do addEntry(entry) end
end

-- The whole build runs against locals and commits only on success: a
-- thrower mid-build (an un-pcall'd journal API, a bad ID) must not leave
-- a half-built index behind — the non-nil guard would serve it forever.
local function buildIndex(self, index, byItemID)
    refreshExpansionLabels()

    -- Faction gate mirrors the scanners' inline check.
    local playerFaction = UnitFactionGroup and UnitFactionGroup("player")

    local stats = { n = 0 }

    local function factionOk(ref)
        return not (playerFaction and ref.faction and ref.faction ~= playerFaction)
    end

    -- Raw-manifest pass. Field names match CONTENT_TARGETS in Core.lua;
    -- recipes route through the per-profession tables keyed by
    -- RECIPE_DATA_KEYS. Decorations groups file their entries under
    -- either "decorations" or the generic "items" catch-all, so both are
    -- probed per group.
    local FIELDS = {
        { field = "MountData",      key = "mounts",      lists = { "mounts" } },
        { field = "PetData",        key = "pets",        lists = { "pets" } },
        { field = "ToyData",        key = "toys",        lists = { "toys" } },
        { field = "DecorationData", key = "decorations", lists = { "decorations", "items" } },
        { field = "AchievementData", key = "achievements", lists = { "achievements" } },
    }
    for _, spec in ipairs(FIELDS) do
        local groups = rawget(MC, spec.field)
        local mod = MC.modulesByKey[spec.key]
        if groups and mod then
            for _, group in ipairs(groups) do
                if not group.expansion or MC.IsGroupVisible(group) then
                    for _, listKey in ipairs(spec.lists) do
                        local list = group[listKey]
                        if type(list) == "table" then
                            for _, ref in ipairs(list) do
                                if factionOk(ref) then
                                    local rec = makeRecord(mod, ref, byItemID,
                                        nil, group.source)
                                    if rec then
                                        index[#index + 1] = rec
                                        stats.n = stats.n + 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Recipes: per-profession tables of category groups.
    local recipesMod = MC.modulesByKey["recipes"]
    if recipesMod then
        for _, fieldName in pairs(MC.RECIPE_DATA_KEYS or {}) do
            local groups = rawget(MC, fieldName)
            if groups then
                for _, group in ipairs(groups) do
                    if not group.expansion or MC.IsGroupVisible(group) then
                        local list = group.recipes
                        if type(list) == "table" then
                            for _, ref in ipairs(list) do
                                if factionOk(ref) then
                                    local rec = makeRecord(recipesMod, ref, byItemID,
                                        group.skillLine, group.source)
                                    if rec then
                                        index[#index + 1] = rec
                                        stats.n = stats.n + 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Rares/treasures from live-resolved scanner results.
    addResultsBuckets(MC.modulesByKey["rares"], index, byItemID, stats)
    addResultsBuckets(MC.modulesByKey["treasures"], index, byItemID, stats)

    self._size = stats.n
end

function Search:EnsureIndex()
    if self.index then return end

    local index, byItemID = {}, {}
    local ok, err = pcall(buildIndex, self, index, byItemID)
    if not ok then
        -- Surface through the standard handler but commit nothing; _dirty
        -- stays set so the next trigger retries from scratch.
        if geterrorhandler then geterrorhandler()(err) else error(err) end
        return
    end
    self.index = index
    self.byItemID = byItemID
    self._dirty = false
end

-- Called from MC.OnScanComplete. The rebuild itself is debounced: a login
-- wave fires one of these per module, and rebuilding on each would be
-- pure waste. Settling ~1s after the last invalidation keeps the index
-- fresh for tooltips too, without ever paying for the rebuild inside the
-- tooltip render path.
function Search:Invalidate()
    self.index = nil
    self.byItemID = nil
    self._dirty = true
    self._invSeq = (self._invSeq or 0) + 1
    local seq = self._invSeq
    C_Timer.After(1, function()
        if seq == self._invSeq and self._dirty then
            self:EnsureIndex()
        end
    end)
end

--------------------------------------------------------------------------
-- Query
--------------------------------------------------------------------------

-- Tokenized AND over the prebuilt haystack (name \1 zone \1 source).
-- Linear scan; at ~20k records a keystroke costs well under a millisecond
-- and needs none of the machinery of a real inverted index.
--
-- Disabled modules are filtered here rather than at render time so the
-- "n / m" counter, the per-module buckets, and the visible rows all
-- agree on what matched.
function Search:Execute(text, scopeModule)
    self:EnsureIndex()

    local tokens = {}
    for tok in strlower(strtrim(text or "")):gmatch("%S+") do
        tokens[#tokens + 1] = tok
    end

    local buckets = {}          -- moduleKey -> { rec, ... }
    local shown, total = 0, 0
    if #tokens > 0 then
        for _, rec in ipairs(self.index) do
            if (not scopeModule or rec.moduleKey == scopeModule)
               and MC.IsModuleEnabled(rec.moduleKey) then
                local hit = true
                for _, tok in ipairs(tokens) do
                    if not rec.hay:find(tok, 1, true) then hit = false; break end
                end
                if hit then
                    total = total + 1
                    if shown < MAX_RESULTS then
                        local b = buckets[rec.moduleKey]
                        if not b then b = {}; buckets[rec.moduleKey] = b end
                        b[#b + 1] = rec
                        shown = shown + 1
                    end
                end
            end
        end
    end
    return buckets, shown, total, (#tokens > 0)
end

--------------------------------------------------------------------------
-- View
--------------------------------------------------------------------------

Search.queryText = ""
Search.scope = nil         -- nil = All modules
Search.resultsShown = false

local chips = {}           -- [moduleKeyOrAll] = button

local function chipOnClick(key)
    Search.scope = (key == "__all") and nil or key
    Search:RenderChips()
    Search:RenderResults()
end

local function makeChip(parent, key, label)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(CHIP_H)
    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFont(MUI.Theme.font, MUI.Theme.fontSize - 1, MUI.FontFlags())
    -- Text BEFORE SetWidth: GetStringWidth measures whatever is set, and
    -- an unlabeled FontString measures zero.
    fs:SetText(label)
    fs:SetPoint("CENTER")
    btn:SetFontString(fs)
    btn:SetWidth(math.max(fs:GetStringWidth() + 16, 34))

    local underline = btn:CreateTexture(nil, "ARTWORK")
    underline:SetHeight(2)
    underline:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 6, 0)
    underline:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -6, 0)

    btn._label = fs
    btn._underline = underline
    btn._key = key
    btn:SetScript("OnClick", function() chipOnClick(key) end)
    btn:SetScript("OnEnter", function(s)
        local active = (s._key == "__all" and Search.scope == nil)
                       or s._key == Search.scope
        if not active then fs:SetTextColor(1, 1, 1, 1) end
    end)
    btn:SetScript("OnLeave", function(s)
        Search:PaintChip(s)
    end)
    chips[key] = btn
    return btn
end

function Search:PaintChip(btn)
    local c = MUI.Theme.colors
    local active = (btn._key == "__all" and self.scope == nil)
                   or btn._key == self.scope
    if active then
        local ac = c.accent
        btn._underline:SetColorTexture(ac[1], ac[2], ac[3], 1)
        btn._underline:Show()
        btn._label:SetTextColor(ac[1], ac[2], ac[3])
    else
        btn._underline:Hide()
        local td = c.textDim
        btn._label:SetTextColor(td[1], td[2], td[3])
    end
end

function Search:RenderChips()
    local panel = MC.panel
    if not (panel and self.chrome and self.chrome:IsShown()) then return end

    -- "All" leads; enabled trackers follow in panel order. Chips are
    -- created lazily here (not in EnsureChrome) so a module enabled later
    -- in the session gets its chip on the next view.
    if self.chipsRow and not chips.__all then
        makeChip(self.chipsRow, "__all", "All")
    end
    local prev
    local function place(btn)
        btn:ClearAllPoints()
        if prev then
            btn:SetPoint("LEFT", prev, "RIGHT", 10, 0)
        else
            btn:SetPoint("LEFT", self.chipsRow, "LEFT", 4, 0)
        end
        btn:Show()
        self:PaintChip(btn)
        prev = btn
    end
    place(chips.__all)
    for _, mod in ipairs(MC.modules) do
        local want = MC.IsModuleEnabled(mod.key)
        local btn = chips[mod.key]
        if want and not btn then
            btn = makeChip(self.chipsRow, mod.key, mod.label)
        elseif btn then
            btn:SetShown(want)
        end
        if want then place(btn) end
    end
end

local function onQueryChanged(text)
    -- Debounce via sequence token: each keystroke invalidates the previous
    -- pending run. Cheaper than timer handles and immune to Cancel() API
    -- differences across client builds.
    Search._qseq = (Search._qseq or 0) + 1
    local seq = Search._qseq
    Search.queryText = text
    C_Timer.After(0.15, function()
        if seq == Search._qseq and Search.resultsShown then
            Search:RenderResults()
        end
    end)
end

local function onEscapeFromInput()
    -- Empty-box Escape backs out to the last tracker, mirroring how
    -- ToggleOptions pops back out of Options.
    local back = MC.activeModule
    if not back or not MC.IsModuleEnabled(back) then
        back = MC.FirstEnabledModule()
    end
    if back then MC.SwitchTab(back) end
end

-- Build the floating chrome once per session (a shell switch forces a
-- /reload, so the panel frame never changes under us).
function Search:EnsureChrome()
    if self.chrome then return end
    local panel = MC.panel
    local f = panel.frame
    if not (f and f.titleBar) then return end

    local chrome = CreateFrame("Frame", nil, f)
    chrome:SetFrameLevel(f:GetFrameLevel() + 20)

    -- Opaque backing: results scroll beneath the chrome, and rows bleeding
    -- through around the input's rounded corners read as a rendering bug.
    local backing = chrome:CreateTexture(nil, "BACKGROUND")
    backing:SetAllPoints()
    local bgc = MUI.Theme.colors.bg
    backing:SetColorTexture(bgc[1], bgc[2], bgc[3], 1)
    if MUI.RegisterThemeHook then
        MUI.RegisterThemeHook(function()
            local c = MUI.Theme.colors.bg
            backing:SetColorTexture(c[1], c[2], c[3], 1)
        end)
    end

    local topAnchor = f.tabBar or f.titleBar

    local input = MUI.MakeSearchInput(chrome, {
        height      = INPUT_H,
        placeholder = "Search every collection…",
        onChanged   = onQueryChanged,
        onEscape    = onEscapeFromInput,
        onEnter     = function(text)
            Search:AddRecent(text)
            Search:RenderResults()
        end,
    })
    input:SetPoint("TOPLEFT", topAnchor, "BOTTOMLEFT", 8, -CHROME_PAD)
    input:SetPoint("TOPRIGHT", topAnchor, "BOTTOMRIGHT", -8, -CHROME_PAD)

    local chipsRow = CreateFrame("Frame", nil, chrome)
    chipsRow:SetHeight(CHIP_H)
    chipsRow:SetPoint("TOPLEFT", input, "BOTTOMLEFT", 0, -CHIPS_GAP)
    chipsRow:SetPoint("TOPRIGHT", input, "BOTTOMRIGHT", 0, -CHIPS_GAP)

    self.chrome = chrome
    self.backing = backing
    self.inputFrame = input
    self.chipsRow = chipsRow
end

function Search:ShowView(query, focusInput)
    self:EnsureChrome()
    if not self.chrome then return end

    -- A stale index from before this session's scans would show wrong
    -- collected badges; scans invalidate anyway, but the first-ever open
    -- can land mid-wave.
    if self._dirty or not self.index then
        self.index = nil
        self.byItemID = nil
    end

    self.chrome:Show()
    self:RenderChips()
    self.resultsShown = true

    if query then
        self.queryText = query
        self.inputFrame:SetText(query)
    else
        self.queryText = self.inputFrame:GetText()
    end

    if focusInput then self.inputFrame:Focus() end
    self:RenderResults()
end

function Search:HideView()
    self.resultsShown = false
    if self.inputFrame then self.inputFrame:ClearFocus() end
    if self.chrome then self.chrome:Hide() end
end

function Search:IsVisible()
    return self.resultsShown
end

-- RefreshActive path while search owns the content area (theme switch,
-- rescan finishing, etc). Re-renders without touching focus or text.
function Search:RefreshResults()
    if not self.resultsShown then return end
    self:RenderResults()
end

-- Premium view transitions (fired from _ApplyIndicatorVisibility, which
-- only runs for the premium shell). Compact keeps its title bar so the
-- chrome can stay; the strip hides it outright and would leave the input
-- floating over the 30px strip. Returning to a full/compact view while
-- search is still the selection re-shows what HideView took down.
function Search:OnViewChanged()
    if not MC.panel or not MC.panel.GetViewMode then return end
    local mode = MC.panel:GetViewMode()
    if mode == "strip" then
        if self.resultsShown then self:HideView() end
    elseif MC.IsSearchSelected and MC.IsSearchSelected()
           and self.chrome and not self.resultsShown then
        self:ShowView(nil, false)
    end
end

-- ShowEmptyMessage pins its FontString 20px under the scroll child's top
-- edge — which is exactly where this view's opaque chrome sits, so the
-- message would render invisibly behind it. Re-anchor below the chrome.
local function showMessage(child, yOff, text, color)
    local h = MUI.ShowEmptyMessage(child, text, color)
    local fs = child._children and child._children.emptyText
    if fs then
        fs:ClearAllPoints()
        fs:SetPoint("TOP", child, "TOP", 0, -(yOff + 20))
    end
    return h
end

local function renderRow(child, rec, yOff)
    local info
    if rec.ref.future and MC.GetAvailabilityBadge then
        info = MC.GetAvailabilityBadge(rec.ref)
    else
        info = rec.ref.zone or expansionLabel(rec.ref.expansion)
    end
    return MUI.RenderItemRow(MC.panel.pool, child, yOff, {
        height      = 22,
        indent      = 8,
        leading     = {
            kind = "icon",
            size = 18,
            texture = rec.icon,
            fallback = rec.mod.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
        },
        name        = rec.name,
        info        = info,
        isCollected = rec.collected,
        onEnter = function(r)
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            GameTooltip:AddLine(rec.name, 1, 1, 1)
            if rec.ref.description then
                GameTooltip:AddLine(rec.ref.description, 0.7, 0.7, 0.7, true)
            elseif rec.ref.sourceInfo then
                GameTooltip:AddLine(rec.ref.sourceInfo, 0.7, 0.7, 0.7, true)
            end
            GameTooltip:Show()
            local label, sr, sg, sb = Search:SourceMeta(rec)
            MC.ShowItemInfoTooltip(r, rec.ref, label, sr, sg, sb)
        end,
        onLeave = MC.RowOnLeave,
        onClick = function() MC.DoItemAction(rec.ref, rec.skillLine) end,
    })
end

function Search:RenderResults()
    local panel = MC.panel
    if not (panel and panel.scrollChild and self.resultsShown) then return end

    -- Rows are about to be reused; a tooltip pinned to one would survive
    -- the release and float over the new render.
    MC.HideInfoTooltip()
    if GameTooltip then GameTooltip:Hide() end

    panel.pool:ReleaseAll()
    -- Search renders the same pooled rows as a module page and can match
    -- thousands of items, so it takes the same viewport window.
    MUI.BeginRenderPass(panel.pool, panel.scrollFrame)
    local child = panel.scrollChild
    MUI.HideEmptyMessage(child)

    local text = self.queryText or ""
    local buckets, shown, total, hadQuery = self:Execute(text, self.scope)

    if not hadQuery then
        local yOff = self:RenderIdleState(child)
        panel:RefreshScrollContent(yOff)
        if panel.titleProgressText then panel.titleProgressText:SetText("") end
        return
    end

    -- A module disabled from Options while its chip held the scope would
    -- otherwise strand the player on an empty scope with no chip to click.
    if self.scope and not MC.IsModuleEnabled(self.scope) then
        self.scope = nil
        self:RenderChips()
        buckets, shown, total, hadQuery = self:Execute(text, self.scope)
    end

    local yOff = CHROME_H
    local renderedAny = false

    for _, mod in ipairs(MC.modules) do
        local bucket = buckets[mod.key]
        if bucket and #bucket > 0 then
            renderedAny = true
            local ac = MUI.Theme.colors.accent
            local _, collapsed, newY = MUI.RenderSourceHeader(panel.pool, child, yOff, {
                label       = mod.label,
                icon        = mod.icon,
                accentColor = { ac[1], ac[2], ac[3] },
                count       = #bucket,
                collKey     = "search_" .. mod.key,
            }, self:CollapseDB(), function() self:RefreshResults() end)
            yOff = newY
            if not collapsed then
                for _, rec in ipairs(bucket) do
                    yOff = renderRow(child, rec, yOff)
                end
            end
            yOff = yOff + 6
        end
    end

    if not renderedAny then
        yOff = CHROME_H
        showMessage(child, yOff,
            format("No matches for |cffaaaaaa%s|r.", text))
        yOff = yOff + 60
    elseif shown < total then
        showMessage(child, yOff,
            format("%d more matches — narrow the search.", total - shown))
        yOff = yOff + 60
    else
        MUI.HideEmptyMessage(child)
    end

    panel:RefreshScrollContent(yOff)
    if panel.titleProgressText then
        panel.titleProgressText:SetText(format("%d / %d", shown, total))
    end
end

-- Collapse state for search headers. RenderCollapsibleHeader indexes
-- db.collapsed directly, and top-level MC.db has no such table (module
-- pages pass their own seeded mod.db) — so hand it a wrapper over one
-- persisted account-wide key of our own.
function Search:CollapseDB()
    if not self._collapseDB then
        CollectionistDB.searchCollapsed = CollectionistDB.searchCollapsed or {}
        self._collapseDB = { collapsed = CollectionistDB.searchCollapsed }
    end
    return self._collapseDB
end

-- Empty-query state: recent searches (clickable), plus a one-line hint.
function Search:RenderIdleState(child)
    local yOff = CHROME_H
    local recents = CollectionistDB and CollectionistDB.searchRecents
    if recents and #recents > 0 then
        for i, q in ipairs(recents) do
            if i > 5 then break end
            yOff = MUI.RenderItemRow(MC.panel.pool, child, yOff, {
                height  = 22,
                indent  = 12,
                name    = q,
                info    = "Recent",
                onClick = function()
                    Search.queryText = q
                    Search.inputFrame:SetText(q)
                    Search:RenderResults()
                end,
            })
        end
    else
        showMessage(child, CHROME_H,
            "Type to search every collectible — name, zone, or source.")
        yOff = yOff + 60
    end
    return yOff
end

-- Recent queries, account-wide, newest first, deduped, max 5.
function Search:AddRecent(text)
    text = strtrim(text or "")
    if text == "" or #text < 3 then return end
    local db = CollectionistDB
    if not db then return end
    local recents = db.searchRecents or {}
    local out = { text }
    for _, q in ipairs(recents) do
        if q ~= text and #out < 5 then out[#out + 1] = q end
    end
    db.searchRecents = out
end
