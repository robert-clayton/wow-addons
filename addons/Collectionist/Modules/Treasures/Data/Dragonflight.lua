local addonName, MC = ...

-- Dragonflight zone treasures. Exact 57 ordered criteria rows.
MC.RegisterContent("df", "treasures", {
    { source = "waking_shores", achievementID = 16297, criteriaCount = 8,
      criteriaTreeIDs = { 137551, 137552, 137553, 137554, 137555, 137556, 138567, 138619 },
      criteriaNames = { "Golden Dragon Goblet", "Bubble Drifter", "Ruby Gem Cluster", "Yennu's Kite", "Dead Man's Chestplate", "Torn Riding Pack", "Misty Treasure Chest", "Onyx Gem Cluster" }, name = "Treasures of The Waking Shores",
      zoneMapID = MC.MAP.WakingShores, zone = "Waking Shores" },
    { source = "ohnahran_plains", achievementID = 16299, criteriaCount = 6,
      criteriaTreeIDs = { 137560, 137561, 137562, 137563, 137564, 137565 },
      criteriaNames = { "Nokhud Warspear", "Slightly Chewed Duck Egg", "Emerald Gem Cluster", "Cracked Centaur Horn", "Gold Swog Coin", "Yennu's Boat" }, name = "Treasures of the Ohn'ahran Plains",
      zoneMapID = MC.MAP.OhnahranPlains, zone = "Ohn'ahran Plains" },
    { source = "azure_span", achievementID = 16300, criteriaCount = 6,
      criteriaTreeIDs = { 137699, 137700, 137701, 137702, 137703, 137704 },
      criteriaNames = { "Forgotten Jewel Box", "Gnoll Fiend Flail", "Sapphire Gem Cluster", "Lost Compass", "Rubber Fish", "Pepper Hammer" }, name = "Treasures of The Azure Span",
      zoneMapID = MC.MAP.AzureSpan, zone = "The Azure Span" },
    { source = "thaldraszus", achievementID = 16301, criteriaCount = 6,
      criteriaTreeIDs = { 137706, 137707, 137708, 137709, 137710, 137711 },
      criteriaNames = { "Cracked Hourglass", "Sandy Wooden Duck", "Amber Gem Cluster", "Elegant Canvas Brush", "Surveyor's Magnifying Glass", "Acorn Harvester" }, name = "Treasures of Thaldraszus",
      zoneMapID = MC.MAP.Thaldraszus, zone = "Thaldraszus" },
    { source = "forbidden_reach", achievementID = 17526, criteriaCount = 12,
      criteriaTreeIDs = { 143733, 143734, 143735, 143736, 143737, 143738, 143739, 143740, 143741, 143742, 143743, 143744 },
      criteriaNames = { "Forbidden Hoard", "Avian Trove", "Obsidian Coffer", "Spellsworn Reserves", "Bone Pile", "Farscale Cache", "Irontide Stash", "Storm-Eater Cairn", "Stonescaled Cairn", "Blazing Cairn", "Frozenheart Cairn", "Morqut Provisions" }, name = "Treasures of the Forbidden Reach",
      zoneMapID = MC.MAP.ForbiddenReach, zone = "The Forbidden Reach" },
    { source = "zaralek_cavern", achievementID = 17786, criteriaCount = 9,
      criteriaTreeIDs = { 144893, 144894, 144895, 144896, 144897, 144898, 144899, 144900, 144902 },
      criteriaNames = { "Ancient Zaqali Chest", "Blazing Shadowflame Chest", "Bloody Body", "Charred Egg", "Chest of the Flights", "Crystal-Encased Chest", "Long-Lost Cache", "Old Trunk", "Well-Chewed Chest" }, name = "Treasures of Zaralek Cavern",
      zoneMapID = MC.MAP.ZaralekCavern, zone = "Zaralek Cavern" },
    { source = "emerald_dream", achievementID = 19317, criteriaCount = 10,
      criteriaTreeIDs = { 151286, 151287, 151288, 151290, 151294, 151295, 151289, 151291, 151292, 151293 },
      criteriaNames = { "Triflesnatch's Roving Trove", "Hidden Moonkin Stash", "Crystalline Glowblossom", "Pineshrew Cache", "Magical Bloom", "Odd Burl", "Reliquary of Ursol", "Reliquary of Aviana", "Reliquary of Ashamane", "Reliquary of Goldrinn" }, name = "Treasures of the Emerald Dream",
      zoneMapID = MC.MAP.EmeraldDream, zone = "Emerald Dream" },
})

local SOURCE_KEYS = {
    { "waking_shores", "Waking Shores" },
    { "ohnahran_plains", "Ohn'ahran Plains" },
    { "azure_span", "The Azure Span" },
    { "thaldraszus", "Thaldraszus" },
    { "forbidden_reach", "The Forbidden Reach" },
    { "zaralek_cavern", "Zaralek Cavern" },
    { "emerald_dream", "Emerald Dream" },
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
