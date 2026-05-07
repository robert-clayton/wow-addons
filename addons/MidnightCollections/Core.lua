local addonName, MC = ...

MC.name = addonName
MC.version = (C_AddOns and C_AddOns.GetAddOnMetadata
                and C_AddOns.GetAddOnMetadata(addonName, "Version")) or "dev"

local MUI = LibStub("MidnightUI-1.0", true)
if not MUI then
    error(addonName .. ": failed to load MidnightUI-1.0 library")
end
local PREFIX = MUI.ChatPrefix("Midnight Collections")
MC.PREFIX = PREFIX

-- Bumped when SavedVariables shape changes; MigrateDB reads it.
local DB_VERSION = 1

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
-- Account-wide defaults
--------------------------------------------------------------------------
local coreDefaults = {
    dbVersion        = DB_VERSION,
    minimap          = { minimapPos = 225, hide = false },
    position         = { point = "CENTER", x = 0, y = 0 },
    locked           = false,
    panelShown       = false,
    minimized        = false,
    frameAlpha       = 1.0,
    frameScale       = 1.0,
    panelWidth       = 380,
    panelHeight      = 560,
    disabledModules  = {},
}

-- Per-character. Alts tend to care about different tabs.
local charDefaults = {
    activeTab        = "mounts",
}

--------------------------------------------------------------------------
-- Module enabled check
--------------------------------------------------------------------------
function MC.IsModuleEnabled(key)
    return not MC.db.disabledModules[key]
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
            if mod.Scanner then
                mod.Scanner:Scan()
                if MC.activeModule == key and mod.UI then
                    MC.RefreshActive()
                end
            end
        end
    end

    -- Active tab disabled? Fall back to the first enabled module, or
    -- show a placeholder if everything is off.
    if not enabled and MC.activeModule == key then
        local first = MC.FirstEnabledModule()
        if first then
            MC.SwitchTab(first)
        else
            MC.activeModule = nil
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
    OnShow = function(self, data)
        local editBox = self.editBox
        editBox:SetText(data)
        editBox:HighlightText()
        editBox:SetFocus()
    end,
    EditBoxOnEscapePressed = function(self)
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
        infoTooltip = CreateFrame("GameTooltip", "MidnightCollectionsInfoTooltip", UIParent, "GameTooltipTemplate")
        infoTooltip:SetFrameStrata("TOOLTIP")
    end
    return infoTooltip
end

function MC.HideInfoTooltip()
    if infoTooltip then infoTooltip:Hide() end
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
    -- Anchor to the row, not GameTooltip. If we anchored to GameTooltip
    -- and another addon hid it, this one would float off-screen.
    tt:SetPoint("TOPLEFT", owner, "TOPRIGHT", 8, 0)

    tt:AddLine("Midnight Collections", C.ttTitle[1], C.ttTitle[2], C.ttTitle[3])
    tt:AddDoubleLine("Source:", sourceLabel or item.source or "Unknown",
        C.ttLabel[1], C.ttLabel[2], C.ttLabel[3],
        sr or 0.7, sg or 0.7, sb or 0.7)

    if item.sourceInfo then
        tt:AddLine(item.sourceInfo, 1, 1, 1, true)
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
        local wp = resolvedWp
        if wp[1] and wp[1] > 0 then
            local mapInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(wp[1])
            local mapName = mapInfo and mapInfo.name or ("Map " .. wp[1])
            tt:AddDoubleLine("Zone:", mapName, C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], C.ttValue[1], C.ttValue[2], C.ttValue[3])
            if wp[2] and wp[3] then
                tt:AddDoubleLine("Coords:", format("%.1f, %.1f", wp[2] * 100, wp[3] * 100), C.ttLabel[1], C.ttLabel[2], C.ttLabel[3], C.ttValue[1], C.ttValue[2], C.ttValue[3])
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

    -- Currency / gold cost. Red if you can't afford it.
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
    if resolvedWp then
        tt:AddLine("Click to set waypoint", C.ttHintGreen[1], C.ttHintGreen[2], C.ttHintGreen[3])
    elseif item.achievementID and item.achievementID > 0 then
        tt:AddLine("Click to open achievement", C.ttHintGreen[1], C.ttHintGreen[2], C.ttHintGreen[3])
    elseif item.skillLine or item.specInfo then
        tt:AddLine("Click to open profession", C.ttHintGreen[1], C.ttHintGreen[2], C.ttHintGreen[3])
    end
    tt:AddLine("Shift-click to copy Wowhead URL", C.ttHintBlue[1], C.ttHintBlue[2], C.ttHintBlue[3])

    tt:Show()
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
    end
    if url then
        StaticPopup_Show("MIDNIGHTCOLLECTIONS_WOWHEAD", nil, nil, url)
    end
end

--------------------------------------------------------------------------
-- Pick the right waypoint for where the player is right now.
-- Inside the instance? Precise spawn coords.
-- In the target zone? Direct waypoint.
-- In a hub with a portal to the target zone? Route to that portal first.
-- Otherwise just send them to wherever they should end up; TomTom queues it.
--------------------------------------------------------------------------
function MC.GetSmartWaypoint(item)
    local wp  = item.waypoint
    local owp = item.overworldWaypoint
    if not wp and not owp then return nil end

    local currentMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")

    if wp and currentMap == wp[1] then return wp end

    -- Target zone: instanced content uses owp[1], everything else wp[1].
    local targetZone = (owp and owp[1]) or (wp and wp[1])

    if currentMap == targetZone then return owp or wp end

    if MC.PORTALS and currentMap and targetZone then
        local portalsFromHere = MC.PORTALS[currentMap]
        if portalsFromHere and portalsFromHere[targetZone] then
            return portalsFromHere[targetZone]
        end
    end

    return owp or wp
end

--------------------------------------------------------------------------
-- TomTom if available, Blizzard's user map pin if not.
--------------------------------------------------------------------------
local _warnedNoWaypointProvider = false
function MC.AddWaypoint(mapID, x, y, title)
    if not (mapID and x and y) or mapID <= 0 then return false end
    title = title or "Midnight Collections waypoint"
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
function MC.DoItemAction(item, skillLine)
    if IsShiftKeyDown() then
        MC.OpenItemWowhead(item)
        return
    end
    local wp = MC.GetSmartWaypoint(item)
    if wp then
        MC.AddWaypoint(wp[1], wp[2], wp[3], wp[4] or item.sourceInfo or item.name)
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
function MC.ThrottledScan(mod, delay)
    if mod._scanPending then return end
    mod._scanPending = true
    C_Timer.After(delay or 0.5, function()
        mod._scanPending = false
        -- Module might have been disabled while we were waiting.
        if not MC.IsModuleEnabled(mod.key) then return end
        if mod.Scanner then
            local ok, err = pcall(mod.Scanner.Scan, mod.Scanner)
            if not ok then
                print(format("%s Scan error in %s: %s", PREFIX, mod.key, tostring(err)))
                return
            end
            if MC.activeModule == mod.key and mod.UI and MC.panel
                and MC.panel.frame and MC.panel.frame:IsShown() then
                mod.UI:Refresh()
            end
        end
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
frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
frame:RegisterEvent("UNIT_FACTION")
MC.eventFrame = frame

frame:SetScript("OnEvent", function(_, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == addonName then
        frame:UnregisterEvent("ADDON_LOADED")

        if not MidnightCollectionsDB then MidnightCollectionsDB = {} end
        if not MidnightCollectionsCharDB then MidnightCollectionsCharDB = {} end
        MigrateDB(MidnightCollectionsDB)
        -- activeTab used to be account-wide; move it to the char DB once.
        if MidnightCollectionsDB.activeTab and not MidnightCollectionsCharDB.activeTab then
            MidnightCollectionsCharDB.activeTab = MidnightCollectionsDB.activeTab
            MidnightCollectionsDB.activeTab = nil
        end
        MC.DeepMergeDefaults(MidnightCollectionsDB, coreDefaults)
        MC.DeepMergeDefaults(MidnightCollectionsCharDB, charDefaults)
        MC.db = MidnightCollectionsDB
        MC.cdb = MidnightCollectionsCharDB

        -- Each module gets its own sub-table for settings and collapsed state.
        for _, mod in ipairs(MC.modules) do
            local moduleDefaults = mod.opts.defaults or {}
            if not moduleDefaults.collapsed then
                moduleDefaults.collapsed = {}
            end
            if not MC.db[mod.key] then MC.db[mod.key] = {} end
            MC.DeepMergeDefaults(MC.db[mod.key], moduleDefaults)
            mod.db = MC.db[mod.key]
        end

        MC.Theme = MUI.Theme
        print(PREFIX .. " v" .. MC.version .. " loaded. Type /mc to toggle.")

    elseif event == "PLAYER_LOGIN" then
        frame:UnregisterEvent("PLAYER_LOGIN")

        for _, mod in ipairs(MC.modules) do
            if MC.IsModuleEnabled(mod.key) and mod.opts.events then
                for _, ev in ipairs(mod.opts.events) do
                    pcall(frame.RegisterEvent, frame, ev)
                end
            end
        end
        MC._RebuildEventMap()

        for _, mod in ipairs(MC.modules) do
            if MC.IsModuleEnabled(mod.key) and mod.opts.onLogin then
                mod.opts.onLogin(mod)
            end
        end
        -- C_PetJournal/C_MountJournal aren't fully populated at PLAYER_LOGIN,
        -- so the first scan is deferred a couple of seconds.
        C_Timer.After(2, function()
            for _, mod in ipairs(MC.modules) do
                if MC.IsModuleEnabled(mod.key) and mod.Scanner then
                    pcall(mod.Scanner.Scan, mod.Scanner)
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

    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        MC.InvalidateCurrencyCache()

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
            if MC.IsModuleEnabled(mod.key) and mod.opts.onEvent then
                mod.opts.onEvent(mod, event, ...)
            end
        end
    end
end)

--------------------------------------------------------------------------
-- Panel creation
--------------------------------------------------------------------------
function MC.CreatePanel()
    if MC.panel then return end

    local panel = MUI:CreatePanel({
        name          = "MidnightCollections",
        title         = "Midnight Collections",
        icon          = "Interface\\Icons\\INV_Misc_Book_09",
        db            = MC.db,
        defaultWidth  = 380,
        defaultHeight = 560,
        minWidth      = 280,
        maxWidth      = 700,
        minHeight     = 140,
        maxHeight     = 900,
        onRefresh     = function() MC.RefreshActive() end,
    })

    MC.panel = panel

    if MC.TabBar then
        MC.TabBar:Create(panel, MC.modules, function(key) MC.SwitchTab(key) end)
    end
    MC.BuildConfig()
end

--------------------------------------------------------------------------
-- Tab switching
--------------------------------------------------------------------------
function MC.SwitchTab(key)
    local mod = MC.modulesByKey[key]
    if not mod or not MC.IsModuleEnabled(key) then return end

    MC.activeModule = key
    if MC.cdb then MC.cdb.activeTab = key end

    -- Tooltip and row frames are about to be reused by the new tab.
    MC.HideInfoTooltip()
    if GameTooltip then GameTooltip:Hide() end

    if MC.TabBar then MC.TabBar:SetActive(key) end

    if mod.UI and not mod.UI._initialized then
        mod.UI:Init(MC.panel, mod)
        mod.UI._initialized = true
    end

    -- Hide stale GetOrCreate children left behind by the previous tab
    -- (progress bars, emptyText, etc).
    if MC.panel and MC.panel.scrollChild and MC.panel.scrollChild._children then
        for _, child in pairs(MC.panel.scrollChild._children) do
            if child.Hide then child:Hide() end
        end
    end

    if MC.panel and MC.panel.scrollFrame then
        MC.panel.scrollFrame:SetVerticalScroll(0)
    end

    MC.RefreshActive()
end

-- Refresh hides the tooltip first, otherwise it can stay pinned to a row
-- that's about to be released back to the pool.
function MC.RefreshActive()
    if not MC.panel or not MC.panel.scrollChild then return end
    local mod = MC.modulesByKey[MC.activeModule]
    if not mod or not mod.UI then return end
    MC.HideInfoTooltip()
    if GameTooltip then GameTooltip:Hide() end
    mod.UI:Refresh()
end

--------------------------------------------------------------------------
-- Build the unified options panel from each module's config defs.
--------------------------------------------------------------------------
function MC.BuildConfig()
    if not MC.panel then return end

    local defs = {}

    defs[#defs + 1] = { type = "section", label = "MODULES" }
    for _, mod in ipairs(MC.modules) do
        local key = mod.key
        defs[#defs + 1] = { type = "checkbox", label = mod.label,
            get = function() return MC.IsModuleEnabled(key) end,
            set = function(v) MC.SetModuleEnabled(key, v) end }
    end

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

    -- Inject the "Show Collected" checkbox automatically from each module's
    -- collectedKey/collectedLabel; modules only have to declare extras.
    for _, mod in ipairs(MC.modules) do
        if MC.IsModuleEnabled(mod.key) and mod.UI then
            defs[#defs + 1] = { type = "divider" }
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

    defs[#defs + 1] = { type = "divider" }
    defs[#defs + 1] = { type = "section", label = "APPEARANCE" }
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

    MC.panel:PopulateConfig(defs)
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
    print("  /mc scan - rescan enabled modules")
    print("  /mc collected [module] - toggle collected/learned display")
    print("  /mc reset - reset panel position + size")
    print("  /mc version - show addon version")
    print("  /mc help - show this help")
end

SlashCmdList["MIDNIGHTCOLLECTIONS"] = function(msg)
    msg = strlower(strtrim(msg or "", " \t\r\n"))

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
            if MC.IsModuleEnabled(mod.key) and mod.Scanner then
                pcall(mod.Scanner.Scan, mod.Scanner)
            end
        end
        MC.RefreshActive()
        print(PREFIX .. " Enabled modules scanned.")
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
        if MC.db.position then
            MC.db.position.point = "CENTER"
            MC.db.position.x = 0
            MC.db.position.y = 0
        end
        MC.db.panelWidth = 380
        MC.db.panelHeight = 560
        MC.db.frameAlpha = 1.0
        MC.db.frameScale = 1.0
        if MC.panel and MC.panel.frame then
            MC.panel.frame:ClearAllPoints()
            MC.panel.frame:SetPoint("CENTER")
            MC.panel.frame:SetSize(MC.db.panelWidth, MC.db.panelHeight)
            MC.panel.frame:SetScale(1.0)
        end
        print(PREFIX .. " Panel reset.")
    elseif cmd == "version" then
        print(format("%s Midnight Collections v%s", PREFIX, MC.version))
    elseif cmd == "help" then
        PrintHelp()
    else
        print(format("%s Unknown command '%s'. Type /mc help.", PREFIX, cmd))
    end
end
