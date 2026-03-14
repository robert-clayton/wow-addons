local addonName, MD = ...

MD.name = addonName
MD.version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version")
              or GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")
              or "dev"

local MUI = LibStub("MidnightUI-1.0")
local PREFIX = MUI.ChatPrefix("Midnight Decorations")

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
    minimap         = { minimapPos = 225, hide = false },
    position        = { point = "CENTER", x = 0, y = 0 },
    locked          = false,
    showCollected   = false,
    hideTradingPost = false,
    collapsed       = {},
    panelShown      = false,
    minimized       = false,
    frameAlpha      = 1.0,
    frameScale      = 1.0,
    panelWidth      = 360,
    panelHeight     = 520,
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

local scanPending = false
local function ThrottledScan()
    if scanPending then return end
    scanPending = true
    C_Timer.After(0.5, function()
        scanPending = false
        if MD.Scanner then
            MD.Scanner:Scan()
            if MD.UI and MD.UI.frame and MD.UI.frame:IsShown() then
                MD.UI:Refresh()
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
        if not MidnightDecorationsDB then MidnightDecorationsDB = {} end
        DeepMergeDefaults(MidnightDecorationsDB, defaults)
        MD.db = MidnightDecorationsDB
        MD.Theme = MUI.Theme
        print(PREFIX .. " v" .. MD.version .. " loaded. Type /md to toggle.")

    elseif event == "PLAYER_LOGIN" then
        frame:UnregisterEvent("PLAYER_LOGIN")
        -- Register housing events (may not exist pre-12.0)
        for _, ev in ipairs({
            "HOUSING_STORAGE_UPDATED",
            "HOUSING_STORAGE_ENTRY_UPDATED",
            "NEW_HOUSING_ITEM_ACQUIRED",
            "HOUSE_DECOR_ADDED_TO_CHEST",
            "BAG_UPDATE_DELAYED",
        }) do
            pcall(frame.RegisterEvent, frame, ev)
        end
        ThrottledScan()
        if MD.UI then MD.UI:Create() end
        if MD.MinimapButton then MD.MinimapButton:Init() end

    else
        -- Housing or bag events
        ThrottledScan()
    end
end)

--------------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------------
SLASH_MIDNIGHTDECORATIONS1 = "/md"
SLASH_MIDNIGHTDECORATIONS2 = "/midnightdecorations"
SlashCmdList["MIDNIGHTDECORATIONS"] = function(msg)
    msg = strlower(strtrim(msg))
    if msg == "scan" then
        if MD.Scanner then
            MD.Scanner:Scan()
            if MD.UI and MD.UI.frame then MD.UI:Refresh() end
            print(PREFIX .. " Scan complete.")
        end
    elseif msg == "collected" then
        if MD.db then
            MD.db.showCollected = not MD.db.showCollected
            print(PREFIX .. " Show collected: " .. tostring(MD.db.showCollected))
            if MD.UI and MD.UI.frame then MD.UI:Refresh() end
        end
    elseif msg == "help" then
        print(PREFIX .. " Available commands:")
        print("  /md - Toggle panel")
        print("  /md scan - Force rescan")
        print("  /md collected - Toggle collected decorations display")
        print("  /md help - Show this help")
    else
        if MD.Scanner then MD.Scanner:Scan() end
        if MD.UI then MD.UI:Toggle() end
    end
end
