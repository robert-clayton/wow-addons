local _, MC = ...

--------------------------------------------------------------------------
-- Pinned-targets overlay ("Targets"). Shell-independent: a small
-- always-on-screen quest-tracker-style list of specific uncollected
-- rows the player alt-clicked in any module list. Left-click routes the
-- row's waypoint through MC.DoItemAction (the same smart-waypoint /
-- pending-task routing as the list rows, TomTom optional); right-click
-- unpins; drag moves (position saved). Shown only while pins exist and
-- the overlay isn't hidden via /mc targets.
--
-- Pins persist per character in MC.db.targets (CollectionistCharDB;
-- Core's CHAR_ONLY_KEYS keeps them out of the account seed snapshot).
-- Cap 10 — the oldest pin is evicted with a chat line. On every scan
-- completion, pins whose entries turned collected/learned auto-unpin
-- with one quiet celebration line.
--
-- No frame exists until the first Refresh with pins present, so a
-- character with nothing pinned pays zero UI cost (and the classic
-- default stays byte-identical). All visuals read lib.Theme at paint
-- time; exactly ONE theme hook is registered, at frame creation.
--------------------------------------------------------------------------

local MAX_PINS = 10
local WIDTH    = 220
local HEADER_H = 18
local ROW_H    = 22
local PAD      = 4

local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local WHITE8 = "Interface\\Buttons\\WHITE8x8"

MC.Targets = MC.Targets or {}
local Targets = MC.Targets
-- Runtime (not saved): key -> live scanner entry, refreshed each scan,
-- so clicks get full DoItemAction semantics (task-list routing etc).
-- The persisted wp/owp snapshot is the fallback before the first scan.
Targets._live = Targets._live or {}

--------------------------------------------------------------------------
-- Pin identity: "<module>:<idTag>:<id>". Mirrors the Bitmap canonical-
-- ID precedence, then the Wowhead chain. moduleOverride lets the scan
-- hook derive keys for entries that lack moduleKey (recipes).
--------------------------------------------------------------------------
local GENERIC_ID_FIELDS = {
    "mountID", "speciesID", "decorID", "itemID",
    "id", "objectID", "npcID", "achievementID",
}

local function keyFor(item, moduleOverride)
    if not item then return nil end
    local module = moduleOverride or item.moduleKey or MC.activeModule
    if not module then return nil end
    if module == "mounts" and item.mountID then
        return module .. ":mountID:" .. item.mountID
    elseif module == "pets" and item.speciesID then
        return module .. ":speciesID:" .. item.speciesID
    elseif module == "decorations" and item.decorID then
        return module .. ":decorID:" .. item.decorID
    elseif module == "toys" and item.itemID then
        return module .. ":itemID:" .. item.itemID
    elseif module == "rares" or module == "treasures" then
        if item.achievementID and item.criteriaIndex then
            return module .. ":crit:" .. item.achievementID .. "." .. item.criteriaIndex
        elseif item.npcID then
            return module .. ":npcID:" .. item.npcID
        elseif item.objectID then
            return module .. ":objectID:" .. item.objectID
        elseif item.itemID then
            return module .. ":itemID:" .. item.itemID
        end
    elseif module == "recipes" and item.id then
        return module .. ":id:" .. item.id
    elseif module == "achievements" and item.achievementID then
        return module .. ":achievementID:" .. item.achievementID
    end
    -- Generic fallback: first stable ID, tagged with its field name.
    for _, field in ipairs(GENERIC_ID_FIELDS) do
        if item[field] then
            return module .. ":" .. field .. ":" .. item[field]
        end
    end
    return nil
end

local function ensureDB()
    if not MC.db then return nil end
    local t = MC.db.targets
    if not t then
        t = { pins = {}, hidden = false }
        MC.db.targets = t
    end
    t.pins = t.pins or {}
    return t
end

local function getPins()
    local t = MC.db and MC.db.targets
    return t and t.pins or nil, t
end

--------------------------------------------------------------------------
-- Public pin API (Core's DoItemAction alt-click branch and the row
-- tooltip hint call these; both call sites nil-guard, so Core stays
-- loadable without this file).
--------------------------------------------------------------------------
function MC.IsTargetPinned(item)
    local pins = getPins()
    if not pins then return false end
    local key = keyFor(item)
    if not key then return false end
    for _, pin in ipairs(pins) do
        if pin.key == key then return true end
    end
    return false
end

function MC.ToggleTargetPin(item, skillLine)
    local db = ensureDB()
    if not db then return end
    local prefix = MC.PREFIX or ""
    local key = keyFor(item)
    if not key then
        print(prefix .. " Can't pin this entry (no stable ID).")
        return
    end
    for i, pin in ipairs(db.pins) do
        if pin.key == key then
            table.remove(db.pins, i)
            Targets._live[key] = nil
            print(format("%s Unpinned from Targets: %s", prefix, pin.name or "?"))
            Targets:Refresh()
            return
        end
    end
    if item.collected or item.learned then
        print(prefix .. " Already collected — nothing to track.")
        return
    end
    if #db.pins >= MAX_PINS then
        local evicted = table.remove(db.pins, 1)
        if evicted then
            Targets._live[evicted.key] = nil
            print(format("%s Target cap (%d) reached — unpinned oldest: %s",
                prefix, MAX_PINS, evicted.name or "?"))
        end
    end
    db.pins[#db.pins + 1] = {
        key     = key,
        module  = item.moduleKey or MC.activeModule,
        name    = item.name,
        icon    = item.icon,
        addedAt = time(),
        zone    = item.zone,
        wp      = item.waypoint and CopyTable(item.waypoint) or nil,
        owp     = item.overworldWaypoint and CopyTable(item.overworldWaypoint) or nil,
        -- Recipes: keeps DoItemAction's open-profession fallback alive
        -- for overlay clicks before the first scan of a session.
        skillLine = item.skillLine or skillLine,
    }
    Targets._live[key] = item
    print(format("%s Pinned to Targets: %s", prefix, item.name or "?"))
    Targets:Refresh()
end

function Targets:Unpin(key)
    local pins = getPins()
    if not pins then return end
    for i, pin in ipairs(pins) do
        if pin.key == key then
            table.remove(pins, i)
            self._live[key] = nil
            print(format("%s Unpinned from Targets: %s",
                MC.PREFIX or "", pin.name or "?"))
            self:Refresh()
            return
        end
    end
end

--------------------------------------------------------------------------
-- Overlay frame (lazy).
--------------------------------------------------------------------------

-- Rebuild a clickable entry from a pin when no live scanner entry is
-- cached this session. The key carries the stable ID, so restoring the
-- field keeps achievement-open / Wowhead fallbacks working too.
local function entryFromPin(pin)
    local entry = {
        name              = pin.name,
        waypoint          = pin.wp,
        overworldWaypoint = pin.owp,
        zone              = pin.zone,
        moduleKey         = pin.module,
    }
    local _, tag, id = string.match(pin.key or "", "^([^:]+):([^:]+):(.+)$")
    if tag == "crit" then
        local aid, idx = string.match(id or "", "^(%d+)%.(%d+)$")
        entry.achievementID = tonumber(aid)
        entry.criteriaIndex = tonumber(idx)
    elseif tag then
        entry[tag] = tonumber(id) or id
    end
    return entry
end

function Targets:_RowClick(row, button)
    local pin = row._pin
    if not pin then return end
    if button == "RightButton" then
        self:Unpin(pin.key)
        return
    end
    if button ~= "LeftButton" then return end
    local entry = self._live[pin.key] or entryFromPin(pin)
    if MC.DoItemAction then MC.DoItemAction(entry, pin.skillLine) end
end

function Targets:_EnsureFrame()
    if self.frame then return self.frame end
    local lib = LibStub and LibStub("MidnightUI-1.0", true)
    if not lib then return nil end
    self.lib = lib

    local f = CreateFrame("Frame", "CollectionistTargets", UIParent, "BackdropTemplate")
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetWidth(WIDTH)
    f:Hide()
    self.frame = f

    -- Whole-frame drag; position persists only after real cursor
    -- movement (the Shell drag-handler pattern), so a plain click can't
    -- clobber the saved point.
    local downX, downY, didDrag
    f:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            downX, downY = GetCursorPosition()
            didDrag = false
            f:StartMoving()
        end
    end)
    f:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            f:StopMovingOrSizing()
            if downX and downY then
                local cx, cy = GetCursorPosition()
                local dx, dy = (cx or downX) - downX, (cy or downY) - downY
                if (dx * dx + dy * dy) > 16 then didDrag = true end
            end
            if didDrag then
                local db = ensureDB()
                if db then
                    local point, _, relativePoint, x, y = f:GetPoint()
                    db.position = { point = point, relativePoint = relativePoint, x = x, y = y }
                end
            end
        end
    end)

    -- Header strip.
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + 2, -4)
    title:SetText("TARGETS")
    f.title = title

    local count = f:CreateFontString(nil, "OVERLAY")
    count:SetPoint("TOPRIGHT", f, "TOPRIGHT", -(PAD + 2), -4)
    f.count = count

    local headerLine = f:CreateTexture(nil, "ARTWORK")
    headerLine:SetHeight(1)
    headerLine:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -HEADER_H)
    headerLine:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -HEADER_H)
    f.headerLine = headerLine

    -- Fixed row frames — no pool needed at a cap of 10.
    f.rows = {}
    for i = 1, MAX_PINS do
        local row = CreateFrame("Frame", nil, f)
        row:SetHeight(ROW_H)
        row:SetPoint("TOPLEFT", f, "TOPLEFT", PAD,
            -(HEADER_H + 2 + (i - 1) * ROW_H))
        row:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
        row:EnableMouse(true)
        row:Hide()

        local hover = row:CreateTexture(nil, "BACKGROUND")
        hover:SetAllPoints()
        hover:SetTexture(WHITE8)
        hover:SetColorTexture(1, 1, 1, 0)
        row.hover = hover

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.icon = icon

        local name = row:CreateFontString(nil, "OVERLAY")
        name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        name:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        row.name = name

        row:SetScript("OnEnter", function(r)
            local hc = r._hoverColor
            if hc then r.hover:SetColorTexture(hc[1], hc[2], hc[3], hc[4] or 0.05) end
            local pin = r._pin
            if pin and GameTooltip then
                GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
                GameTooltip:SetText(pin.name or "?")
                GameTooltip:AddLine("Click: set waypoint  \194\183  Right-click: unpin",
                    0.7, 0.7, 0.7)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(r)
            r.hover:SetColorTexture(1, 1, 1, 0)
            if GameTooltip then GameTooltip:Hide() end
        end)
        row:SetScript("OnMouseUp", function(r, button)
            Targets:_RowClick(r, button)
        end)
        f.rows[i] = row
    end

    self:Repaint()
    -- The overlay's ONE theme hook.
    lib.RegisterThemeHook(function() Targets:Repaint() end)
    return f
end

-- All colors read from lib.Theme.colors at paint time; no new theme
-- keys. Re-run by the theme hook on every live switch.
function Targets:Repaint()
    local f = self.frame
    local lib = self.lib
    if not (f and lib) then return end
    local theme = lib.Theme
    local c = theme.colors

    f:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    f:SetBackdropColor(c.bg[1], c.bg[2], c.bg[3], (c.bg[4] or 1) * 0.9)
    f:SetBackdropBorderColor(c.border[1], c.border[2], c.border[3], 1)

    f.title:SetFont(lib.FontBold(), theme.fontSize - 1, lib.FontFlags())
    f.title:SetTextColor(c.title[1], c.title[2], c.title[3], c.title[4] or 1)
    f.count:SetFont(theme.font, theme.fontSize - 2, lib.FontFlags())
    f.count:SetTextColor(c.textDim[1], c.textDim[2], c.textDim[3])
    f.headerLine:SetColorTexture(c.accent[1], c.accent[2], c.accent[3], 0.9)

    for _, row in ipairs(f.rows) do
        row.name:SetFont(theme.font, theme.fontSize, lib.FontFlags())
        row.name:SetTextColor(c.text[1], c.text[2], c.text[3], c.text[4] or 1)
        row._hoverColor = c.rowHover
    end
end

-- Re-layout during combat defers to a one-shot PLAYER_REGEN_ENABLED
-- watcher (the Shell ApplyMinimizeState pattern).
function Targets:_QueueCombatRefresh()
    if self._combatQueued then return end
    self._combatQueued = true
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent", function(w)
        w:UnregisterAllEvents()
        Targets._combatQueued = false
        Targets:Refresh()
    end)
end

function Targets:Refresh()
    local pins, t = getPins()
    local n = pins and #pins or 0
    if not self.frame then
        -- Lazy: no frame until the first refresh with pins present.
        if n == 0 then return end
        if not self:_EnsureFrame() then return end
    end
    local f = self.frame
    local MUI = LibStub and LibStub("MidnightUI-1.0", true)
    if n == 0 or (t and t.hidden) then
        if MUI then MUI.FadeOut(f) else f:Hide() end
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        self:_QueueCombatRefresh()
        return
    end

    local pos = (t and t.position) or {}
    f:ClearAllPoints()
    f:SetPoint(pos.point or "CENTER", UIParent,
        pos.relativePoint or pos.point or "CENTER",
        pos.x or 300, pos.y or 0)

    for i, row in ipairs(f.rows) do
        local pin = pins[i]
        row._pin = pin
        if pin then
            row.icon:SetTexture(pin.icon or FALLBACK_ICON)
            row.name:SetText(pin.name or "?")
            row:Show()
        else
            row:Hide()
        end
    end
    f.count:SetText(tostring(n))
    local h = HEADER_H + 2 + n * ROW_H + PAD
    -- Already open: grow/shrink into the new pin count. Opening: land at
    -- the right height, then fade in.
    if f:IsShown() and MUI then
        MUI.SizeTo(f, f:GetWidth(), h)
    else
        f:SetHeight(h)
    end
    if MUI then MUI.FadeIn(f) else f:Show() end
end

function Targets:Toggle()
    local db = ensureDB()
    if not db then
        print((MC.PREFIX or "") .. " Targets not ready yet.")
        return
    end
    local prefix = MC.PREFIX or ""
    db.hidden = not db.hidden
    print(format("%s Targets overlay %s.", prefix,
        db.hidden and "hidden" or "shown"))
    if not db.hidden and #db.pins == 0 then
        print(prefix .. " No targets pinned yet — Alt-click a list row to pin one.")
    end
    self:Refresh()
end

--------------------------------------------------------------------------
-- Scan hook (called from MC.OnScanComplete). For pins belonging to the
-- scanned module: a positive collected/learned match unpins with one
-- quiet celebration line; uncollected matches refresh the live entry
-- cache and the persisted snapshot. Entries merely absent from the
-- results (expansion filter, hideUnavailable) are never auto-unpinned.
--------------------------------------------------------------------------
function Targets:OnScanComplete(mod)
    local pins = getPins()
    if not pins or #pins == 0 then return end
    local modKey = mod and mod.key
    if modKey then
        local mine, any = {}, false
        for _, pin in ipairs(pins) do
            if pin.module == modKey then
                mine[pin.key] = pin
                any = true
            end
        end
        local r = any and mod.Scanner and mod.Scanner.results
        if type(r) == "table" then
            local collectedKeys = {}
            local function markEntry(entry, isCollected)
                local k = keyFor(entry, modKey)
                local pin = k and mine[k]
                if not pin then return end
                if isCollected then
                    collectedKeys[k] = true
                else
                    self._live[k] = entry
                    pin.name = entry.name or pin.name
                    pin.icon = entry.icon or pin.icon
                    pin.zone = entry.zone or pin.zone
                    if entry.waypoint then pin.wp = CopyTable(entry.waypoint) end
                    if entry.overworldWaypoint then
                        pin.owp = CopyTable(entry.overworldWaypoint)
                    end
                end
            end
            if modKey == "recipes" then
                -- Per-skillLine sub-tables ({ learned, bySource, ... });
                -- _offProfession has only .score and is skipped.
                for _, sub in pairs(r) do
                    if type(sub) == "table" and sub.learned then
                        for _, entry in ipairs(sub.learned) do
                            markEntry(entry, true)
                        end
                        for _, entries in pairs(sub.bySource or {}) do
                            for _, entry in ipairs(entries) do
                                markEntry(entry, entry.learned and true or false)
                            end
                        end
                    end
                end
            else
                for _, entry in ipairs(r.collected or {}) do
                    markEntry(entry, true)
                end
                for _, entries in pairs(r.bySource or {}) do
                    for _, entry in ipairs(entries) do
                        markEntry(entry, entry.collected and true or false)
                    end
                end
            end
            if next(collectedKeys) then
                local names = {}
                for i = #pins, 1, -1 do
                    local pin = pins[i]
                    if collectedKeys[pin.key] then
                        names[#names + 1] = pin.name or "?"
                        table.remove(pins, i)
                        self._live[pin.key] = nil
                    end
                end
                if #names > 0 then
                    print(format("%s |cff55cc55Collected!|r %s — removed from Targets.",
                        MC.PREFIX or "", table.concat(names, ", ")))
                end
            end
        end
    end
    -- Always refresh while pins exist: the first completing scan of the
    -- session builds and shows the overlay.
    self:Refresh()
end
