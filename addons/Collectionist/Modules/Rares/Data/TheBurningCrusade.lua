local addonName, MC = ...

-- The Burning Crusade zone rares. Exact 20 ordered criteria/entity rows.
MC.RegisterContent("tbc", "rares", {
    { source = "outland", achievementID = 1312, criteriaCount = 20,
      criteriaTreeIDs = { 7953, 7954, 7963, 7972, 7967, 7955, 7970, 7964, 7956, 7968, 7957, 7969, 7958, 7965, 7959, 7960, 7966, 7961, 7971, 7962 },
      criteriaNPCIDs = { 18695, 18682, 18697, 18681, 18694, 18689, 18686, 18698, 18678, 17144, 18692, 18696, 18680, 18677, 18690, 20932, 18685, 18693, 18683, 18679 }, name = "Bloody Rare",
      zoneMapID = MC.MAP.Outland, zone = "Outland" },
})

local SOURCE_KEYS = {
    { "o", "u" },
    { "O", "u" },
}
local function merge()
    MC.RareSourceOrder = MC.RareSourceOrder or {}
    MC.RareSourceLabels = MC.RareSourceLabels or {}
    local have = {}
    for _, key in ipairs(MC.RareSourceOrder) do have[key] = true end
    -- The base file already declares every key it owns. Inserting a
    -- second copy put the zone in the order list twice, which draws
    -- its group twice and prints it twice in the /mc summary.
    local at = 0
    for _, pair in ipairs(SOURCE_KEYS) do
        MC.RareSourceLabels[pair[1]] = pair[2]
        if not have[pair[1]] then
            at = at + 1
            have[pair[1]] = true
            table.insert(MC.RareSourceOrder, at, pair[1])
        end
    end
end
if MC.RareSourceOrder then merge() else
    local frame = CreateFrame("Frame"); frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, _, name) if name ~= addonName then return end; self:UnregisterEvent("ADDON_LOADED"); self:SetScript("OnEvent", nil); merge() end)
end
