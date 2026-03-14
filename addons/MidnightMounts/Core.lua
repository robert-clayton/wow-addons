local addonName, MM = ...

MM.name = addonName
MM.version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version")
              or GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")
              or "dev"

local MUI = LibStub("MidnightUI-1.0")
local PREFIX = MUI.ChatPrefix("Midnight Mounts")

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
frame:RegisterEvent("NEW_MOUNT_ADDED")

local scanPending = false
local function ThrottledScan()
    if scanPending then return end
    scanPending = true
    C_Timer.After(0.5, function()
        scanPending = false
        if MM.Scanner then
            MM.Scanner:Scan()
            if MM.UI and MM.UI.frame and MM.UI.frame:IsShown() then
                MM.UI:Refresh()
            end
        end
    end)
end

--------------------------------------------------------------------------
-- Event handler
--------------------------------------------------------------------------
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        frame:UnregisterEvent("ADDON_LOADED")
        if not MidnightMountsDB then MidnightMountsDB = {} end
        DeepMergeDefaults(MidnightMountsDB, defaults)
        MM.db = MidnightMountsDB
        MM.Theme = MUI.Theme
        print(PREFIX .. " v" .. MM.version .. " loaded. Type /mm to toggle.")

    elseif event == "PLAYER_LOGIN" then
        frame:UnregisterEvent("PLAYER_LOGIN")
        ThrottledScan()
        if MM.UI then MM.UI:Create() end
        if MM.MinimapButton then MM.MinimapButton:Init() end

    elseif event == "NEW_MOUNT_ADDED" then
        ThrottledScan()
    end
end)

--------------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------------
SLASH_MIDNIGHTMOUNTS1 = "/mm"
SLASH_MIDNIGHTMOUNTS2 = "/midnightmounts"
SlashCmdList["MIDNIGHTMOUNTS"] = function(msg)
    msg = strlower(strtrim(msg))
    if msg == "scan" then
        if MM.Scanner then
            MM.Scanner:Scan()
            if MM.UI and MM.UI.frame then MM.UI:Refresh() end
            print(PREFIX .. " Scan complete.")
        end
    elseif msg == "collected" then
        if MM.db then
            MM.db.showCollected = not MM.db.showCollected
            print(PREFIX .. " Show collected: " .. tostring(MM.db.showCollected))
            if MM.UI and MM.UI.frame then MM.UI:Refresh() end
        end
    elseif msg == "help" then
        print(PREFIX .. " Available commands:")
        print("  /mm - Toggle panel")
        print("  /mm scan - Force rescan")
        print("  /mm collected - Toggle collected mounts display")
        print("  /mm help - Show this help")
    else
        if MM.Scanner then MM.Scanner:Scan() end
        if MM.UI then MM.UI:Toggle() end
    end
end
