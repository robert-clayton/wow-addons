local addonName, MC = ...

MC.name = addonName
MC.version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version")
              or GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")
              or "dev"

local MUI = LibStub("MidnightUI-1.0")
local PREFIX = MUI.ChatPrefix("Midnight Collections")
MC.PREFIX = PREFIX

--------------------------------------------------------------------------
-- Deep merge (single shared copy)
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
-- Core defaults (panel-level settings)
--------------------------------------------------------------------------
local coreDefaults = {
    minimap          = { minimapPos = 225, hide = false },
    position         = { point = "CENTER", x = 0, y = 0 },
    locked           = false,
    panelShown       = false,
    minimized        = false,
    frameAlpha       = 1.0,
    frameScale       = 1.0,
    panelWidth       = 380,
    panelHeight      = 560,
    activeTab        = "mounts",
    disabledModules  = {},
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
    MC.db.disabledModules[key] = (not enabled) or nil
    if MC.TabBar then MC.TabBar:Reflow() end
    if enabled then
        local mod = MC.modulesByKey[key]
        if mod and mod.Scanner then mod.Scanner:Scan() end
    end
    -- If the active tab was just disabled, switch to the first enabled one
    if not enabled and MC.activeModule == key then
        local first = MC.FirstEnabledModule()
        if first then MC.SwitchTab(first) end
    end
    MC.BuildConfig()
end

--------------------------------------------------------------------------
-- Shared Wowhead URL popup
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
-- Shared info tooltip
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
-- Shared info tooltip builder
--------------------------------------------------------------------------
function MC.ShowItemInfoTooltip(owner, item, sourceLabel, sr, sg, sb)
    local tt = MC.GetInfoTooltip()
    tt:SetOwner(owner, "ANCHOR_PRESERVE")
    tt:ClearAllPoints()
    tt:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 2, 0)

    local MUI = LibStub("MidnightUI-1.0")
    local theme = MUI.Theme
    local c = theme.colors

    tt:AddLine("Midnight Collections", c.ttTitle[1], c.ttTitle[2], c.ttTitle[3])
    tt:AddDoubleLine("Source:", sourceLabel or item.source, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], sr or 0.7, sg or 0.7, sb or 0.7)

    if item.sourceInfo then
        tt:AddLine(item.sourceInfo, 1, 1, 1)
    end

    -- Pet type + battle capability (Pets only)
    if item.petType then
        local typeName = MC.PetTypeNames and MC.PetTypeNames[item.petType] or ("Type " .. (item.petType or "?"))
        tt:AddDoubleLine("Pet type:", typeName, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttValue[1], c.ttValue[2], c.ttValue[3])
    end
    if item.canBattle ~= nil then
        local battleStr = item.canBattle and "Yes" or "No"
        local br, bg, bb = 0.5, 0.8, 0.5
        if not item.canBattle then br, bg, bb = 0.8, 0.5, 0.5 end
        tt:AddDoubleLine("Can battle:", battleStr, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], br, bg, bb)
    end

    -- Profession label (Decorations crafted items)
    if item.skillLine and MC.DecoProfLabels and MC.DecoProfLabels[item.skillLine] then
        local pr, pg, pb = theme:ProfAccentColor(item.skillLine)
        tt:AddDoubleLine("Profession:", MC.DecoProfLabels[item.skillLine], c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], pr, pg, pb)
    end

    -- Location from waypoint / zone fallback
    if item.waypoint then
        local wp = item.waypoint
        if wp[1] and wp[1] > 0 then
            local mapInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(wp[1])
            local mapName = mapInfo and mapInfo.name or ("Map " .. wp[1])
            tt:AddDoubleLine("Zone:", mapName, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttValue[1], c.ttValue[2], c.ttValue[3])
            if wp[2] and wp[3] then
                tt:AddDoubleLine("Coords:", format("%.1f, %.1f", wp[2] * 100, wp[3] * 100), c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttValue[1], c.ttValue[2], c.ttValue[3])
            end
        end
    elseif item.zone then
        tt:AddDoubleLine("Zone:", item.zone, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttValue[1], c.ttValue[2], c.ttValue[3])
    end

    -- Renown / reputation requirement
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
                    local standings = { "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted" }
                    current = standings[data.reaction] or tostring(data.reaction)
                    local standingOrder = { Hated = 1, Hostile = 2, Unfriendly = 3, Neutral = 4, Friendly = 5, Honored = 6, Revered = 7, Exalted = 8 }
                    metReq = data.reaction >= (standingOrder[req.standing] or 0)
                end
            end
            local name = req.factionName or ("Faction " .. req.factionID)
            reqLabel = format("%s %s (%s)", name, current, req.standing)
        end
        local rr, rg, rb = c.ttCostBad[1], c.ttCostBad[2], c.ttCostBad[3]
        if metReq then rr, rg, rb = 0.5, 0.8, 0.5 end
        tt:AddLine(reqLabel, rr, rg, rb)
    end

    -- Vendor cost (gold + currency)
    if item.cost then
        if item.cost.gold then
            local playerGold = GetMoney and GetMoney() or 0
            local gr, gg, gb = 1, 1, 1
            if playerGold < item.cost.gold then gr, gg, gb = c.ttCostBad[1], c.ttCostBad[2], c.ttCostBad[3] end
            tt:AddDoubleLine("Cost:", MUI.FormatGold(item.cost.gold), c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], gr, gg, gb)
        end
        local parts = {}
        for _, key in ipairs({"currency", "currency2"}) do
            local cur = item.cost[key]
            if cur then
                local currID, amount = cur[1], cur[2]
                local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currID)
                local icon = info and info.iconFileID
                local name = info and info.name or ("Currency " .. currID)
                local owned = info and info.quantity or 0
                local color = owned >= amount and "" or "|cffff4d4d"
                local costLabel = icon and (amount .. " |T" .. icon .. ":0|t") or (amount .. " " .. name)
                parts[#parts + 1] = color .. costLabel .. "|r"
            end
        end
        if #parts > 0 then
            tt:AddDoubleLine("Cost:", table.concat(parts, "  "), c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], 1, 1, 1)
        end
    end

    -- Drop info
    if item.dropInfo then
        local di = item.dropInfo
        if di.mob then
            tt:AddDoubleLine("Drops from:", di.mob, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttDropMob[1], c.ttDropMob[2], c.ttDropMob[3])
        end
        if di.zone then
            tt:AddDoubleLine("Zone:", di.zone, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttValue[1], c.ttValue[2], c.ttValue[3])
        end
        if di.rate then
            tt:AddDoubleLine("Drop rate:", di.rate, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttDropRate[1], c.ttDropRate[2], c.ttDropRate[3])
        end
        if di.boss then
            tt:AddLine("Boss drop", c.ttBoss[1], c.ttBoss[2], c.ttBoss[3])
        end
    end

    -- Specialization info (Recipes only)
    if item.specInfo then
        local si = item.specInfo
        if si.tree then
            tt:AddDoubleLine("Spec tree:", si.tree, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttSpec[1], c.ttSpec[2], c.ttSpec[3])
        end
        if si.node then
            tt:AddDoubleLine("Node:", si.node, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttSpec[1], c.ttSpec[2], c.ttSpec[3])
        end
        if si.points then
            tt:AddDoubleLine("Points:", tostring(si.points), c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], 1, 1, 1)
        end
    end

    -- Click hints
    tt:AddLine(" ")
    if item.waypoint then
        tt:AddLine("Click to set TomTom waypoint", c.ttHintGreen[1], c.ttHintGreen[2], c.ttHintGreen[3])
    elseif item.achievementID and item.achievementID > 0 then
        tt:AddLine("Click to open achievement", c.ttHintGreen[1], c.ttHintGreen[2], c.ttHintGreen[3])
    elseif item.skillLine or item.specInfo then
        tt:AddLine("Click to open profession", c.ttHintGreen[1], c.ttHintGreen[2], c.ttHintGreen[3])
    end
    tt:AddLine("Shift-click to copy Wowhead URL", c.ttHintBlue[1], c.ttHintBlue[2], c.ttHintBlue[3])

    tt:Show()
end

--------------------------------------------------------------------------
-- Shared Wowhead URL opener
--------------------------------------------------------------------------
function MC.OpenItemWowhead(item)
    local url
    if item.mountID then
        url = "https://www.wowhead.com/mount/" .. item.mountID
    elseif item.speciesID then
        url = "https://www.wowhead.com/battle-pet/" .. item.speciesID
    elseif item.decorID and item.decorID > 0 then
        url = "https://www.wowhead.com/decor=" .. item.decorID
    elseif item.itemID and item.itemID > 0 then
        url = "https://www.wowhead.com/item=" .. item.itemID
    elseif item.id then
        url = "https://www.wowhead.com/spell=" .. item.id
    end
    if url then
        StaticPopup_Show("MIDNIGHTCOLLECTIONS_WOWHEAD", nil, nil, url)
    end
end

--------------------------------------------------------------------------
-- Shared click action handler
--------------------------------------------------------------------------
function MC.DoItemAction(item, skillLine)
    if IsShiftKeyDown() then
        MC.OpenItemWowhead(item)
        return
    end
    local src = item.source
    if item.waypoint then
        local wp = item.waypoint
        if wp[1] and wp[1] > 0 then
            if TomTom then
                local title = wp[4] or item.sourceInfo or item.name
                TomTom:AddWaypoint(wp[1], wp[2], wp[3], { title = title })
                print(format("%s Waypoint set: %s", PREFIX, title))
            else
                print(PREFIX .. " TomTom addon required for waypoints.")
            end
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
-- ThrottledScan (per-module)
--------------------------------------------------------------------------
function MC.ThrottledScan(mod)
    if mod._scanPending then return end
    mod._scanPending = true
    C_Timer.After(0.5, function()
        mod._scanPending = false
        if mod.Scanner then
            mod.Scanner:Scan()
            if MC.activeModule == mod.key and mod.UI and MC.panel
                and MC.panel.frame and MC.panel.frame:IsShown() then
                mod.UI:Refresh()
            end
        end
    end)
end

--------------------------------------------------------------------------
-- Event frame
--------------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
MC.eventFrame = frame

frame:SetScript("OnEvent", function(_, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == addonName then
        frame:UnregisterEvent("ADDON_LOADED")

        if not MidnightCollectionsDB then MidnightCollectionsDB = {} end
        MC.DeepMergeDefaults(MidnightCollectionsDB, coreDefaults)
        MC.db = MidnightCollectionsDB

        -- Init per-module sub-tables
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

        -- Register per-module events (pcall-wrapped)
        for _, mod in ipairs(MC.modules) do
            if mod.opts.events then
                for _, ev in ipairs(mod.opts.events) do
                    pcall(frame.RegisterEvent, frame, ev)
                end
            end
        end

        -- Call each module's onLogin + initial scan
        for _, mod in ipairs(MC.modules) do
            if mod.opts.onLogin then
                mod.opts.onLogin(mod)
            end
            if mod.Scanner then mod.Scanner:Scan() end
        end

        -- Create the unified panel
        MC.CreatePanel()

        -- Init minimap button
        if MC.MinimapButton then MC.MinimapButton:Init() end

        -- Activate saved tab (or first enabled module)
        local tabKey = MC.db.activeTab
        if not MC.modulesByKey[tabKey] or not MC.IsModuleEnabled(tabKey) then
            tabKey = MC.FirstEnabledModule()
        end
        if tabKey then MC.SwitchTab(tabKey) end

    else
        -- Dispatch to modules (skip disabled)
        for _, mod in ipairs(MC.modules) do
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

    -- Create tab bar between title bar and scroll area
    if MC.TabBar then
        MC.TabBar:Create(panel, MC.modules, function(key) MC.SwitchTab(key) end)
    end

    -- Build aggregated config
    MC.BuildConfig()
end

--------------------------------------------------------------------------
-- Tab switching
--------------------------------------------------------------------------
function MC.SwitchTab(key)
    local mod = MC.modulesByKey[key]
    if not mod or not MC.IsModuleEnabled(key) then return end

    MC.activeModule = key
    MC.db.activeTab = key

    if MC.TabBar then MC.TabBar:SetActive(key) end

    -- Ensure module UI is initialized
    if mod.UI and not mod.UI._initialized then
        mod.UI:Init(MC.panel, mod)
        mod.UI._initialized = true
    end

    -- Hide stale GetOrCreate children (progress bars, emptyText, etc.)
    if MC.panel and MC.panel.scrollChild and MC.panel.scrollChild._children then
        for _, child in pairs(MC.panel.scrollChild._children) do
            if child.Hide then child:Hide() end
        end
    end

    -- Reset scroll position to top
    if MC.panel and MC.panel.scrollFrame then
        MC.panel.scrollFrame:SetVerticalScroll(0)
    end

    MC.RefreshActive()
end

--------------------------------------------------------------------------
-- Refresh active module
--------------------------------------------------------------------------
function MC.RefreshActive()
    if not MC.panel or not MC.panel.scrollChild then return end
    local mod = MC.modulesByKey[MC.activeModule]
    if not mod or not mod.UI then return end
    mod.UI:Refresh()
end

--------------------------------------------------------------------------
-- Config panel (aggregated)
--------------------------------------------------------------------------
function MC.BuildConfig()
    if not MC.panel then return end

    local defs = {}

    -- Module toggles
    defs[#defs + 1] = { type = "section", label = "MODULES" }
    for _, mod in ipairs(MC.modules) do
        local key = mod.key
        defs[#defs + 1] = { type = "checkbox", label = mod.label,
            get = function() return MC.IsModuleEnabled(key) end,
            set = function(v) MC.SetModuleEnabled(key, v) end }
    end

    -- Global settings
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

    -- Per-module settings (only enabled modules)
    for _, mod in ipairs(MC.modules) do
        if MC.IsModuleEnabled(mod.key) and mod.UI and mod.UI.GetConfigDefs then
            defs[#defs + 1] = { type = "divider" }
            defs[#defs + 1] = { type = "section", label = strupper(mod.label) }
            for _, def in ipairs(mod.UI:GetConfigDefs()) do
                defs[#defs + 1] = def
            end
        end
    end

    -- Appearance
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
SlashCmdList["MIDNIGHTCOLLECTIONS"] = function(msg)
    msg = strlower(strtrim(msg))

    -- /mc <module> → switch tab + show
    if MC.modulesByKey[msg] then
        MC.SwitchTab(msg)
        if MC.panel then MC.panel:Show() end
        return
    end

    if msg == "scan" then
        for _, mod in ipairs(MC.modules) do
            if mod.Scanner then mod.Scanner:Scan() end
        end
        MC.RefreshActive()
        print(MC.PREFIX .. " All modules scanned.")
    elseif msg == "collected" or msg == "learned" then
        local mod = MC.modulesByKey[MC.activeModule]
        if mod and mod.db then
            local key = mod.opts.collectedKey or "showCollected"
            mod.db[key] = not mod.db[key]
            print(MC.PREFIX .. format(" [%s] Show %s: %s",
                mod.label, mod.opts.collectedLabel or "collected", tostring(mod.db[key])))
            MC.RefreshActive()
        end
    elseif msg == "help" then
        print(MC.PREFIX .. " Available commands:")
        print("  /mc - Toggle panel")
        print("  /mc <module> - Switch to module (recipes, pets, mounts, decorations)")
        print("  /mc scan - Force rescan all modules")
        print("  /mc collected - Toggle collected display for active module")
        print("  /mc help - Show this help")
    else
        if MC.panel then MC.panel:Toggle() end
    end
end
