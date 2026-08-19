local addonName, MC = ...

-- Shadowlands zone treasures. Exact 103 ordered criteria rows.
MC.RegisterContent("shadowlands", "treasures", {
    { source = "bastion", achievementID = 14311, criteriaCount = 15,
      criteriaTreeIDs = { 88404, 88405, 88406, 88407, 88408, 88409, 88410, 88411, 88412, 88413, 88415, 88416, 88417, 88418, 88419 },
      criteriaNames = { "Scroll of Aeons", "Vesper of Virtues", "Purifying Draught", "Lost Disciple's Notes", "Larion Tamer's Harness", "Stolen Equipment", "Abandoned Stockpile", "Experimental Construct Part", "Windsmith's Tools", "Memorial Offerings", "Gift of Agthia", "Gift of Vesiphone", "Gift of Chyrus", "Gift of Thenios", "Gift of Devos" }, name = "Treasures of Bastion",
      zoneMapID = MC.MAP.Bastion, zone = "Bastion" },
    { source = "maldraxxus", achievementID = 14312, criteriaCount = 13,
      criteriaTreeIDs = { 88420, 88421, 88422, 88423, 88424, 88425, 88427, 88428, 88429, 88430, 88431, 88432, 88433 },
      criteriaNames = { "Ornate Bone Shield", "Kyrian Keepsake", "Halis's Lunch Pail", "Vat of Conspicuous Slime", "Stolen Jar", "Necro Tome", "Forgotten Mementos", "Chest of Eyes", "Misplaced Supplies", "Glutharn's Stash", "Runespeaker's Trove", "Plaguefallen Chest", "Ritualist's Cache" }, name = "Treasures of Maldraxxus",
      zoneMapID = MC.MAP.Maldraxxus, zone = "Maldraxxus" },
    { source = "ardenweald", achievementID = 14313, criteriaCount = 15,
      criteriaTreeIDs = { 88389, 88390, 88391, 88392, 88393, 88394, 88395, 88396, 88397, 88398, 88399, 88400, 88401, 88402, 88403 },
      criteriaNames = { "Aerto's Body", "Lost Satchel", "Veilwing Egg", "Swollen Anima Seed", "Faerie Trove", "Harmonic Chest", "Hearty Dragon Plume", "Playful Vulpin Befriended", "Cache of the Moon", "Desiccated Moth", "Dreamsong Heart", "Enchanted Dreamcatcher", "Elusive Faerie Cache", "Cache of the Night", "Darkreach Supplies" }, name = "Treasures of Ardenweald",
      zoneMapID = MC.MAP.Ardenweald, zone = "Ardenweald" },
    { source = "revendreth", achievementID = 14314, criteriaCount = 16,
      criteriaTreeIDs = { 88434, 88435, 88436, 88437, 88438, 88439, 88440, 88442, 89855, 89856, 89857, 89858, 89859, 89860, 89861, 90051 },
      criteriaNames = { "Lost Quill", "Stylish Parasol", "The Count", "Rapier of the Fearless", "Vrytha's Dredglaive", "Makeshift Muckpool", "Taskmaster's Trove", "Forbidden Chamber", "Smuggled Cache", "Chest of Envious Dreams", "Filcher's Prize", "Wayfarer's Abandoned Spoils", "Remlate's Hidden Cache", "Fleeing Soul's Bundle", "Gilded Plum Chest", "Abandoned Curios" }, name = "Treasures of Revendreth",
      zoneMapID = MC.MAP.Revendreth, zone = "Revendreth" },
    { source = "korthia", achievementID = 15099, criteriaCount = 10,
      criteriaTreeIDs = { 91891, 91892, 91893, 91894, 91895, 91896, 91897, 91898, 91899, 91900 },
      criteriaNames = { "Glittering Nest Material", "Forgotten Feather", "Lost Memento", "Dislodged Nest", "Anima Laden Egg", "Displaced Relic", "Helsworn Chest", "Jeweled Heart", "Infested Vestige", "Offering Box" }, name = "Treasures of Korthia",
      zoneMapID = MC.MAP.Korthia, zone = "Korthia" },
    { source = "zereth_mortis", achievementID = 15331, criteriaCount = 27,
      criteriaTreeIDs = { 94299, 94501, 94502, 94503, 94504, 94505, 94506, 94507, 94571, 94572, 94573, 94614, 94633, 94634, 94637, 94642, 94643, 94644, 94645, 94646, 94647, 94648, 94649, 94650, 94651, 94652, 94653 },
      criteriaNames = { "Library Vault", "Submerged Chest", "Damaged Jiro Stash", "Template Archive", "Forgotten Proto-Vault", "Symphonic Vault", "Mawsworn Cache", "Stolen Relic", "Fallen Vault", "Gnawed Valise", "Domination Cache", "Filched Artifact", "Architect's Reserve", "Crushed Supply Crate", "Overgrown Protofruit", "Mistaken Ovoid", "Drowned Broker Supplies", "Offering to the First Ones", "Protomineral Extractor", "Pilfered Curio", "Stolen Scroll", "Grateful Boon", "Protoflora Harvester", "Syntactic Vault", "Ripened Protopear", "Undulating Foliage", "Bushel of Progenitor Produce" }, name = "Treasures of Zereth Mortis",
      zoneMapID = MC.MAP.ZerethMortis, zone = "Zereth Mortis" },
    { source = "zereth_mortis", achievementID = 15502, criteriaCount = 7,
      criteriaTreeIDs = { 95143, 95144, 95145, 95146, 95147, 95148, 95149 },
      criteriaNames = { "Lumpy Sand Pile", "Glinting Sand Pile", "Shifting Sand Pile", "Humming Sand Pile", "Misshapen Sand Pile", "Sparkling Sand Pile", "Ticking Sand Pile" }, name = "Sand, Sand Everywhere!",
      zoneMapID = MC.MAP.ZerethMortis, zone = "Zereth Mortis" },
})

local SOURCE_KEYS = {
    { "bastion", "Bastion" },
    { "maldraxxus", "Maldraxxus" },
    { "ardenweald", "Ardenweald" },
    { "revendreth", "Revendreth" },
    { "korthia", "Korthia" },
    { "zereth_mortis", "Zereth Mortis" },
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
