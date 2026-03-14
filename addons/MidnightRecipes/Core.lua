local addonName, MR = ...

MR.name = addonName
MR.version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version")
              or GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")
              or "dev"
MR.professions = {}

-- Crafting profession skillLine IDs (gathering professions excluded)
local CRAFT_SKILLS = {
    [171] = true,   -- Alchemy
    [164] = true,   -- Blacksmithing
    [185] = true,   -- Cooking
    [333] = true,   -- Enchanting
    [202] = true,   -- Engineering
    [773] = true,   -- Inscription
    [755] = true,   -- Jewelcrafting
    [165] = true,   -- Leatherworking
    [197] = true,   -- Tailoring
}

MR.PROF_ORDER = { 171, 164, 185, 333, 202, 773, 755, 165, 197 }

local MUI = LibStub("MidnightUI-1.0")
local PREFIX = MUI.ChatPrefix("Midnight Recipes")

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
    showLearned = false,
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

local optionalEvents = { "TRADE_SKILL_LIST_UPDATE", "SPELLS_CHANGED", "SKILL_LINES_CHANGED" }
for _, ev in ipairs(optionalEvents) do
    local ok, err = pcall(frame.RegisterEvent, frame, ev)
    if not ok then
        print("|cffff4040[MR] Failed to register event: " .. ev .. " - " .. tostring(err) .. "|r")
    end
end

local scanPending = false
local function ThrottledScan()
    if scanPending then return end
    scanPending = true
    C_Timer.After(0.5, function()
        scanPending = false
        if MR.Scanner then
            MR.Scanner:Scan()
            if MR.UI and MR.UI.frame and MR.UI.frame:IsShown() then
                MR.UI:Refresh()
            end
        end
    end)
end

local function DetectProfessions()
    wipe(MR.professions)
    local prof1, prof2, _arch, _fish, cooking = GetProfessions()
    local indices = {}
    if prof1 then indices[#indices + 1] = prof1 end
    if prof2 then indices[#indices + 1] = prof2 end
    if cooking then indices[#indices + 1] = cooking end

    for _, profIndex in ipairs(indices) do
        local name, icon, skillLevel, maxLevel, _, _, skillLine = GetProfessionInfo(profIndex)
        if name and CRAFT_SKILLS[skillLine] then
            MR.professions[skillLine] = {
                name       = name,
                icon       = icon,
                profIndex  = profIndex,
                skillLine  = skillLine,
                skillLevel = skillLevel or 0,
                maxLevel   = maxLevel or 0,
            }
        end
    end
end

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        frame:UnregisterEvent("ADDON_LOADED")
        if not MidnightRecipesDB then MidnightRecipesDB = {} end
        DeepMergeDefaults(MidnightRecipesDB, defaults)
        MR.db = MidnightRecipesDB
        MR.Theme = MUI.Theme
        print(PREFIX .. " v" .. MR.version .. " loaded. Type /mr to toggle.")

    elseif event == "PLAYER_LOGIN" then
        frame:UnregisterEvent("PLAYER_LOGIN")
        DetectProfessions()
        ThrottledScan()
        if MR.UI then MR.UI:Create() end
        if MR.MinimapButton then MR.MinimapButton:Init() end

    elseif event == "SKILL_LINES_CHANGED" then
        DetectProfessions()
        ThrottledScan()

    elseif event == "TRADE_SKILL_LIST_UPDATE" or event == "SPELLS_CHANGED" then
        ThrottledScan()
    end
end)

SLASH_MIDNIGHTRECIPES1 = "/mr"
SLASH_MIDNIGHTRECIPES2 = "/midnightrecipes"
SlashCmdList["MIDNIGHTRECIPES"] = function(msg)
    msg = strlower(strtrim(msg))
    if msg == "scan" then
        if MR.Scanner then
            MR.Scanner:Scan()
            if MR.UI and MR.UI.frame then MR.UI:Refresh() end
            print(PREFIX .. " Scan complete.")
        end
    elseif msg == "learned" then
        if MR.db then
            MR.db.showLearned = not MR.db.showLearned
            print(PREFIX .. " Show learned: " .. tostring(MR.db.showLearned))
            if MR.UI and MR.UI.frame then MR.UI:Refresh() end
        end
    elseif msg == "help" then
        print(PREFIX .. " Available commands:")
        print("  /mr - Toggle panel")
        print("  /mr scan - Force rescan")
        print("  /mr learned - Toggle learned recipes display")
        print("  /mr help - Show this help")
    else
        if MR.UI then MR.UI:Toggle() end
    end
end
