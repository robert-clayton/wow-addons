local addonName, MC = ...

-- Warlords of Draenor zone rares. Exact 72 ordered criteria/entity rows.
MC.RegisterContent("wod", "rares", {
    { source = "gorgrond", achievementID = 9400, criteriaCount = 8,
      criteriaTreeIDs = { 38468, 38469, 38470, 38471, 38472, 38473, 38474, 38475 },
      criteriaNPCIDs = { 75207, 77093, 81528, 81529, 81537, 81540, 81548, 80785 }, name = "Gorgrond Monster Hunter",
      zoneMapID = MC.MAP.Gorgrond, zone = "Gorgrond" },
    { source = "tanaan_jungle", achievementID = 10061, criteriaCount = 4,
      criteriaTreeIDs = { 44087, 44088, 44089, 44090 },
      criteriaNPCIDs = { 95044, 95053, 95054, 95056 }, name = "Hellbane",
      zoneMapID = MC.MAP.TanaanJungle, zone = "Tanaan Jungle" },
    { source = "tanaan_jungle", achievementID = 10070, criteriaCount = 60,
      criteriaTreeIDs = { 44242, 44243, 44244, 44245, 44246, 44247, 44248, 44249, 44250, 44251, 44252, 44253, 44254, 44255, 44256, 44257, 44258, 44259, 44260, 44261, 44262, 44263, 44264, 44265, 44266, 44267, 44268, 44269, 44270, 44271, 44272, 44273, 44274, 44275, 44276, 44277, 44278, 44279, 44280, 44281, 44282, 44283, 44284, 44285, 44286, 44287, 44288, 44289, 44290, 44296, 44988, 44989, 44990, 44991, 44992, 44993, 44994, 44995, 44996, 44997 },
      criteriaNPCIDs = { 91374, 91093, 91087, 91098, 90429, 90438, 90437, 90434, 90442, 90519, 90024, 92451, 90782, 92274, 91695, 92887, 93002, 91232, 91243, 93057, 93001, 92977, 90884, 90885, 90887, 90888, 90936, 92197, 92429, 92495, 92508, 92517, 92465, 92574, 92552, 92606, 92627, 92636, 92694, 92941, 93028, 93076, 93125, 93168, 92766, 92817, 92819, 92657, 93279, 91727, 91871, 90122, 90094, 93236, 92647, 91009, 92408, 92411, 93264, 89675 }, name = "Jungle Stalker",
      zoneMapID = MC.MAP.TanaanJungle, zone = "Tanaan Jungle" },
})

local SOURCE_KEYS = {
    { "gorgrond", "Gorgrond" },
    { "tanaan", "Tanaan Jungle" },
}
local function merge()
    MC.RareSourceOrder = MC.RareSourceOrder or {}
    MC.RareSourceLabels = MC.RareSourceLabels or {}
    for i, pair in ipairs(SOURCE_KEYS) do table.insert(MC.RareSourceOrder, i, pair[1]); MC.RareSourceLabels[pair[1]] = pair[2] end
end
if MC.RareSourceOrder then merge() else
    local frame = CreateFrame("Frame"); frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, _, name) if name ~= addonName then return end; self:UnregisterEvent("ADDON_LOADED"); self:SetScript("OnEvent", nil); merge() end)
end
