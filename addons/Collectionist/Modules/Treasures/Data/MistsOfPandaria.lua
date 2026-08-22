local addonName, MC = ...

-- Mists of Pandaria treasures. Exact 98 ordered criteria rows.
MC.RegisterContent("mop", "treasures", {
    { source = "pandaria", achievementID = 7284, criteriaCount = 28,
      criteriaTreeIDs = { 27104, 27105, 27106, 27107, 27109, 27110, 27113, 27114, 27117, 27118, 27120, 27121, 27122, 27123, 27124, 27128, 27132, 27136, 27140, 27141, 27142, 27143, 27144, 27145, 27146, 27147, 27148, 27149 },
      criteriaNames = { "Ancient Pandaren Fishing Pole", "Ancient Pandaren Woodcutter", "Kafa Press", "Jade Infused Blade", "Wodin's Mantid Shanker", "Ancient Pandaren Mining Pick", "Waterspeaker's Staff", "Hammer of Ten Thunders", "Cache of Pilfered Goods", "Staff of the Hidden Master", "Pandaren Fishing Spear", "Equipment Locker", "Banana Infused Rum", "Sprite's Cloth Chest", "Hozen Warrior Spear", "Tablet of Ren Yun", "Stash of Yaungol Weapons", "Yaungol Fire Carrier", "Wind-Reaver's Dagger", "Malik's Stalwart Spear", "Lucid Amulet", "Manipulator's Talisman", "Blade of the Prime", "Swarming Cleaver", "Dissector's Staff", "Bloodseeker's Frenzied Mace", "Swarmkeeper's Crossbow", "Hammer of the Poisoned Mind" },
      name = "Is Another Man's Treasure",
      zoneMapID = MC.MAP.Pandaria, zone = "Pandaria" },
    { source = "pandaria", achievementID = 7997, criteriaCount = 18,
      criteriaTreeIDs = { 31368, 31369, 31370, 31371, 31372, 31373, 31374, 31375, 31376, 31377, 31378, 31379, 31380, 31381, 31382, 31383, 31384, 31385 },
      criteriaNames = { "Ship's Storage", "Ancient Pandaren Tea Pot", "Lucky Pandaren Coin", "Pandaren Ritual Stone", "Virmen Treasure Cache", "Saurok Stone Tablet", "Hozen Treasure Cache", "Stolen Sprite Treasure", "Statue of Xuen", "Lost Adventurer's Belongings", "Rikktik's Tick Remover", "Ancient Mogu Tablet", "Terracotta Head", "Fragment of Dread", "Hardened Sap of Kri'vess", "Amber Encased Moth", "Abandoned Crate of Goods", "Hammer of Folly" },
      name = "Riches of Pandaria",
      zoneMapID = MC.MAP.Pandaria, zone = "Pandaria" },
    { source = "timeless_isle", achievementID = 8726, criteriaCount = 3,
      criteriaTreeIDs = { 34186, 34187, 34188 },
      criteriaNames = { "Gleaming Treasure Chest", "Rope-Bound Treasure Chest", "Mist-Covered Treasure Chest" },
      name = "Extreme Treasure Hunter",
      zoneMapID = MC.MAP.TimelessIsle, zone = "Timeless Isle" },
    { source = "timeless_isle", achievementID = 8727, criteriaCount = 3,
      criteriaTreeIDs = { 34190, 34191, 34192 },
      criteriaNames = { "Sunken Treasure", "Blackguard's Jetsam", "Gleaming Treasure Satchel" },
      name = "Where There's Pirates, There's Booty",
      zoneMapID = MC.MAP.TimelessIsle, zone = "Timeless Isle" },
    { source = "timeless_isle", achievementID = 8729, criteriaCount = 42,
      criteriaTreeIDs = { 34255, 34256, 34257, 34258, 34259, 34260, 34261, 34262, 34263, 34264, 34265, 34266, 34267, 34268, 34269, 34270, 34271, 34272, 34273, 34274, 34275, 34276, 34277, 34278, 34279, 34280, 34281, 34282, 34283, 34284, 34285, 34286, 34287, 34288, 34289, 34290, 34292, 34293, 34294, 34295, 34297, 34298 },
      name = "Treasure, Treasure Everywhere",
      zoneMapID = MC.MAP.TimelessIsle, zone = "Timeless Isle" },
    { source = "timeless_isle", achievementID = 8784, criteriaCount = 4,
      criteriaTreeIDs = { 34393, 34394, 34395, 34396 },
      criteriaNames = { "Cloudstrike Family Helm", "Flameheart Shawl", "Riverspeaker's Trident", "Snowdrift Tiger Talons" },
      name = "Timeless Legends",
      zoneMapID = MC.MAP.TimelessIsle, zone = "Timeless Isle" },
})

local SOURCE_KEYS = {
    { "pandaria", "Pandaria" },
    { "timeless", "Timeless Isle" },
}
local function merge()
    MC.TreasureSourceOrder = MC.TreasureSourceOrder or {}
    MC.TreasureSourceLabels = MC.TreasureSourceLabels or {}
    for i, pair in ipairs(SOURCE_KEYS) do table.insert(MC.TreasureSourceOrder, i, pair[1]); MC.TreasureSourceLabels[pair[1]] = pair[2] end
end
if MC.TreasureSourceOrder then merge() else
    local frame = CreateFrame("Frame"); frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, _, name) if name ~= addonName then return end; self:UnregisterEvent("ADDON_LOADED"); self:SetScript("OnEvent", nil); merge() end)
end
