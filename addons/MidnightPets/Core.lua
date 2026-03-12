local addonName, MP = ...

MP.name = addonName
MP.version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version")
              or GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")
              or "dev"

local function DeepMergeDefaults(target, source)
    for k, v in pairs(source) do
        if target[k] == nil then
            target[k] = type(v) == "table" and CopyTable(v) or v
        elseif type(v) == "table" and type(target[k]) == "table" then
            DeepMergeDefaults(target[k], v)
        end
    end
end

local defaults = {
    minimap     = { minimapPos = 225, hide = false },
    position    = { point = "CENTER", x = 0, y = 0 },
    locked      = false,
    showCollected = false,
    hideTradingPost = false,
    wildAlerts  = true,
    collapsed   = {},
    panelShown  = false,
    minimized   = false,
    frameAlpha  = 1.0,
    frameScale  = 1.0,
    panelWidth  = 360,
    panelHeight = 520,
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PET_JOURNAL_LIST_UPDATE")

local scanPending = false
local function ThrottledScan()
    if scanPending then return end
    scanPending = true
    C_Timer.After(0.5, function()
        scanPending = false
        if MP.Scanner then
            MP.Scanner:Scan()
            if MP.UI and MP.UI.frame and MP.UI.frame:IsShown() then
                MP.UI:Refresh()
            end
        end
    end)
end

--------------------------------------------------------------------------
-- Wild pet proximity alerts (nameplate + mouseover based)
--------------------------------------------------------------------------
-- Build a lookup of wild pet species IDs for fast matching
local wildSpeciesLookup  -- built lazily after data is ready

local function BuildWildSpeciesLookup()
    wildSpeciesLookup = {}
    if not MP.PetData then return end
    for _, group in ipairs(MP.PetData) do
        if group.source == "wild" then
            for _, pet in ipairs(group.pets) do
                wildSpeciesLookup[pet.speciesID] = pet
            end
        end
    end
end

-- Track which species we've already alerted for this session (avoid spam)
local alertedThisSession = {}

local function AlertForPet(speciesID)
    if not MP.db or not MP.db.wildAlerts then return end
    if not wildSpeciesLookup then BuildWildSpeciesLookup() end

    local pet = wildSpeciesLookup[speciesID]
    if not pet then return end
    if alertedThisSession[speciesID] then return end

    -- Check if already collected
    if C_PetJournal and C_PetJournal.GetNumCollectedInfo then
        local ok, nc = pcall(C_PetJournal.GetNumCollectedInfo, speciesID)
        if ok and nc and nc > 0 then return end
    end

    alertedThisSession[speciesID] = true
    -- Chat alert
    local msg = format("|cff40e840[Midnight Pets]|r Uncollected wild pet nearby: |cffffffff%s|r (%s)", pet.name, pet.zone or "")
    print(msg)
    -- Raid warning flash (visible even without raid)
    if RaidNotice_AddMessage then
        RaidNotice_AddMessage(RaidWarningFrame, format("Uncollected pet: %s", pet.name), ChatTypeInfo["RAID_WARNING"])
    end
    -- Play alert sound
    PlaySound(SOUNDKIT.RAID_WARNING or 8959, "Master")
end

local function OnNameplateAdded(unitToken)
    if not MP.db or not MP.db.wildAlerts then return end
    if not UnitIsWildBattlePet or not UnitBattlePetSpeciesID then return end
    if not UnitIsWildBattlePet(unitToken) then return end
    local speciesID = UnitBattlePetSpeciesID(unitToken)
    if speciesID and speciesID > 0 then
        AlertForPet(speciesID)
    end
end

local function OnMouseoverUnit()
    if not MP.db or not MP.db.wildAlerts then return end
    if not UnitIsWildBattlePet or not UnitBattlePetSpeciesID then return end
    if not UnitIsWildBattlePet("mouseover") then return end
    local speciesID = UnitBattlePetSpeciesID("mouseover")
    if speciesID and speciesID > 0 then
        AlertForPet(speciesID)
    end
end

-- Reset alerts when changing zones (so re-entering a zone re-alerts)
local function OnZoneChanged()
    wipe(alertedThisSession)
end

--------------------------------------------------------------------------
-- Event handler
--------------------------------------------------------------------------
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        frame:UnregisterEvent("ADDON_LOADED")
        if not MidnightPetsDB then MidnightPetsDB = {} end
        DeepMergeDefaults(MidnightPetsDB, defaults)
        MP.db = MidnightPetsDB
        MP.Theme = LibStub("MidnightUI-1.0").Theme
        print("|cff80c0ff[Midnight Pets]|r v" .. MP.version .. " loaded. Type /mp to toggle.")

    elseif event == "PLAYER_LOGIN" then
        frame:UnregisterEvent("PLAYER_LOGIN")
        ThrottledScan()
        BuildWildSpeciesLookup()
        if MP.UI then MP.UI:Create() end
        if MP.MinimapButton then MP.MinimapButton:Init() end
        -- Register nameplate + mouseover events for wild pet alerts
        frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
        frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    elseif event == "PET_JOURNAL_LIST_UPDATE" then
        ThrottledScan()

    elseif event == "NAME_PLATE_UNIT_ADDED" then
        OnNameplateAdded(arg1)

    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        OnMouseoverUnit()

    elseif event == "ZONE_CHANGED_NEW_AREA" then
        OnZoneChanged()
    end
end)

--------------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------------
SLASH_MIDNIGHTPETS1 = "/mp"
SLASH_MIDNIGHTPETS2 = "/midnightpets"
SlashCmdList["MIDNIGHTPETS"] = function(msg)
    msg = strlower(strtrim(msg))
    if msg == "scan" then
        if MP.Scanner then
            MP.Scanner:Scan()
            if MP.UI and MP.UI.frame then MP.UI:Refresh() end
            print("|cff80c0ff[Midnight Pets]|r Scan complete.")
        end
    elseif msg == "collected" then
        if MP.db then
            MP.db.showCollected = not MP.db.showCollected
            print("|cff80c0ff[Midnight Pets]|r Show collected: " .. tostring(MP.db.showCollected))
            if MP.UI and MP.UI.frame then MP.UI:Refresh() end
        end
    elseif msg == "help" then
        print("|cff80c0ff[Midnight Pets]|r Available commands:")
        print("  /mp - Toggle panel")
        print("  /mp scan - Force rescan")
        print("  /mp collected - Toggle collected pets display")
        print("  /mp help - Show this help")
    else
        if MP.Scanner then MP.Scanner:Scan() end
        if MP.UI then MP.UI:Toggle() end
    end
end
