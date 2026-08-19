local _, MC = ...

-- Patch 12.1: Curse of Ula'tek.
table.insert(MC.TreasureSourceOrder, "coiled_isle")
MC.TreasureSourceLabels.coiled_isle = "The Coiled Isle"

MC.RegisterContent("midnight", "treasures", {
    { source = "coiled_isle", achievementID = 63359, criteriaCount = 22,
      -- Criterion order is the live achievement order.  The scanner keys
      -- waypoint and puzzle metadata by position so localized clients work.
      criteriaNames = {
          "Amani Privateer's Cache", "Fangbound Sack", "Sunken Diver's Chest",
          "Grave of Someone Forgotten", "Profane Ritual Spoils", "Brine-Crusted Chest",
          "Possessed Vase", "Malfunctioning Staff", "Tarnished Amani Glaive",
          "Jaktu's Cursed Blade", "Lost Spirit", "Cracked Skull",
          "Damaged Loa Trinket", "Venomjade Necklace", "Ornate Bottle",
          "Stinking Vessel", "Waterlogged Basket", "Smoldering Incense",
          "Crumbling Urn", "Forgotten Mask", "Vul'zahn's Smuggled Treasure",
          "Zul'jan's Stash",
      }, name = "Treasures of the Coiled Isle",
      zoneMapID = MC.MAP.CoiledIsle, zone = "The Coiled Isle" },
})

local coords = {
    ["Amani Privateer's Cache"]       = { MC.MAP.CoiledIsle, 0.719, 0.667, "Amani Privateer's Cache" },
    ["Fangbound Sack"]                = { MC.MAP.CoiledIsle, 0.459, 0.663, "Fangbound Sack" },
    ["Sunken Diver's Chest"]          = { MC.MAP.CoiledIsle, 0.654, 0.056, "Sunken Diver's Chest" },
    ["Grave of Someone Forgotten"]   = { MC.MAP.CoiledIsle, 0.673, 0.485, "Grave of Someone Forgotten" },
    ["Profane Ritual Spoils"]         = { MC.MAP.CoiledIsle, 0.437, 0.674, "Profane Ritual Spoils" },
    ["Brine-Crusted Chest"]           = { MC.MAP.CoiledIsle, 0.706, 0.766, "Brine-Crusted Chest" },
    ["Possessed Vase"]                = { MC.MAP.CoiledIsle, 0.314, 0.835, "Possessed Vase" },
    ["Malfunctioning Staff"]          = { MC.MAP.CoiledIsle, 0.754, 0.573, "Malfunctioning Staff" },
    ["Tarnished Amani Glaive"]       = { MC.MAP.CoiledIsle, 0.552, 0.380, "Tarnished Amani Glaive" },
    ["Jaktu's Cursed Blade"]          = { MC.MAP.CoiledIsle, 0.604, 0.594, "Jaktu's Cursed Blade" },
    ["Lost Spirit"]                   = { MC.MAP.CoiledIsle, 0.681, 0.659, "Lost Spirit" },
    ["Cracked Skull"]                 = { MC.MAP.CoiledIsle, 0.581, 0.435, "Cracked Skull" },
    ["Damaged Loa Trinket"]           = { MC.MAP.CoiledIsle, 0.469, 0.296, "Damaged Loa Trinket" },
    ["Venomjade Necklace"]            = { MC.MAP.CoiledIsle, 0.647, 0.366, "Venomjade Necklace" },
    ["Ornate Bottle"]                 = { MC.MAP.CoiledIsle, 0.670, 0.280, "Ornate Bottle" },
    ["Stinking Vessel"]               = { MC.MAP.CoiledIsle, 0.531, 0.431, "Stinking Vessel" },
    ["Waterlogged Basket"]            = { MC.MAP.CoiledIsle, 0.495, 0.320, "Waterlogged Basket" },
    ["Smoldering Incense"]            = { MC.MAP.CoiledIsle, 0.295, 0.672, "Smoldering Incense" },
    ["Crumbling Urn"]                 = { MC.MAP.CoiledIsle, 0.735, 0.565, "Crumbling Urn" },
    ["Forgotten Mask"]                = { MC.MAP.CoiledIsle, 0.649, 0.789, "Forgotten Mask" },
    ["Vul'zahn's Smuggled Treasure"] = { MC.MAP.CoiledIsle, 0.582, 0.457, "Vul'zahn's Smuggled Treasure" },
    ["Zul'jan's Stash"]               = { MC.MAP.CoiledIsle, 0.440, 0.265, "Zul'jan's Stash" },
}
for name, waypoint in pairs(coords) do MC.TreasureCoords[name] = waypoint end

MC.TreasureNotes["Amani Privateer's Cache"] =
    "Fish a Grisly Morsel from a Grisly Cod Pool, feed the Hungry Dolphin, then stay submerged while it finds both key halves. Combine the halves and open the cache."
MC.TreasureNotes["Sunken Diver's Chest"] =
    "Defeat Ss'akrithos during three separate Mlurkrr Massacre Curse Surges. Combine the three Diver's Key Fragments and use the key on the chest."
MC.TreasureNotes["Brine-Crusted Chest"] =
    "Loot a Luminescent Pearl from a Bubbling Clam south of the cave, trade it to Nacretta, then use the dropped key on the chest."
MC.TreasureNotes["Grave of Someone Forgotten"] =
    "Speak with the Forgotten Soldier and the three nearby spirits, buy Spirit Sprouts, die near the grave, eat them as a ghost, wait for the buff, resurrect, then return to the grave."
MC.TreasureNotes["Lost Spirit"] =
    "Pick up the Forgotten Trinket beside the Altar of Wrath and return it to the Lost Spirit."
MC.TreasureNotes["Vul'zahn's Smuggled Treasure"] =
    "Speak to Vul'zahn, the Witherbark Cook, and Apothecary Dezi in sequence to prepare the stew; give it to Vul'zahn for the chest key."
