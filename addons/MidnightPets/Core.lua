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
        if MP.UI then MP.UI:Create() end
        if MP.MinimapButton then MP.MinimapButton:Init() end

    elseif event == "PET_JOURNAL_LIST_UPDATE" then
        ThrottledScan()
    end
end)

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
