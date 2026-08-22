local _, MC = ...

MC.TreasureSourceOrder = {
    "eversong", "zulaman", "harandar", "voidstorm", "eversong_woods",
    "isle_of_queldanas", "coiled_isle", "azj_kahet", "dornogal",
    "hallowfall", "isle_of_dorn", "karesh", "siren_isle", "ringing_deeps",
    "undermine", "emerald_dream", "ohnahran_plains", "thaldraszus",
    "azure_span", "forbidden_reach", "waking_shores", "zaralek_cavern",
    "ardenweald", "bastion", "korthia", "maldraxxus", "revendreth", "maw",
    "zereth_mortis", "drustvar", "mechagon", "nazjatar", "nazmir",
    "stormsong_valley", "tiragarde_sound", "uldum", "voldun", "zuldazar",
    "antoran_wastes", "argus", "azsuna", "eredath", "highmountain",
    "krokuun", "stormheim", "suramar", "valsharah", "draenor",
    "frostfire_ridge", "gorgrond", "nagrand", "nagrand_draenor",
    "shadowmoon_valley_draenor", "spires_of_arak", "talador",
    "tanaan_jungle",
    "kun_lai_summit", "pandaria", "jade_forest", "timeless_isle",
    "valley_of_the_four_winds"
}
MC.TreasureSourceLabels = {
    eversong  = "Eversong Woods",
    zulaman   = "Zul'Aman",
    harandar  = "Harandar",
    voidstorm = "Voidstorm",
    eversong_woods            = "Eversong Woods",
    isle_of_queldanas         = "Isle of Quel'Danas",
    coiled_isle               = "The Coiled Isle",
    azj_kahet                 = "Azj-Kahet",
    dornogal                  = "Dornogal",
    hallowfall                = "Hallowfall",
    isle_of_dorn              = "Isle of Dorn",
    karesh                    = "K'aresh",
    siren_isle                = "Siren Isle",
    ringing_deeps             = "The Ringing Deeps",
    undermine                 = "Undermine",
    emerald_dream             = "Emerald Dream",
    ohnahran_plains           = "Ohn'ahran Plains",
    thaldraszus               = "Thaldraszus",
    azure_span                = "The Azure Span",
    forbidden_reach           = "The Forbidden Reach",
    waking_shores             = "The Waking Shores",
    zaralek_cavern            = "Zaralek Cavern",
    ardenweald                = "Ardenweald",
    bastion                   = "Bastion",
    korthia                   = "Korthia",
    maldraxxus                = "Maldraxxus",
    revendreth                = "Revendreth",
    maw                       = "The Maw",
    zereth_mortis             = "Zereth Mortis",
    drustvar                  = "Drustvar",
    mechagon                  = "Mechagon Island",
    nazjatar                  = "Nazjatar",
    nazmir                    = "Nazmir",
    stormsong_valley          = "Stormsong Valley",
    tiragarde_sound           = "Tiragarde Sound",
    uldum                     = "Uldum",
    voldun                    = "Vol'dun",
    zuldazar                  = "Zuldazar",
    antoran_wastes            = "Antoran Wastes",
    argus                     = "Argus",
    azsuna                    = "Azsuna",
    eredath                   = "Eredath",
    highmountain              = "Highmountain",
    krokuun                   = "Krokuun",
    stormheim                 = "Stormheim",
    suramar                   = "Suramar",
    valsharah                 = "Val'sharah",
    draenor                   = "Draenor",
    frostfire_ridge           = "Frostfire Ridge",
    gorgrond                  = "Gorgrond",
    tanaan_jungle             = "Tanaan Jungle",
    nagrand                   = "Nagrand",
    nagrand_draenor           = "Nagrand",
    shadowmoon_valley_draenor = "Shadowmoon Valley",
    spires_of_arak            = "Spires of Arak",
    talador                   = "Talador",
    kun_lai_summit            = "Kun-Lai Summit",
    pandaria                  = "Pandaria",
    jade_forest               = "The Jade Forest",
    timeless_isle             = "Timeless Isle",
    valley_of_the_four_winds  = "Valley of the Four Winds",
}

MC.RegisterContent("midnight", "treasures", {
    { source = "eversong", achievementID = 61960, criteriaCount = 9,
      criteriaNames = {
          "Rookery Cache", "Triple-Locked Safebox", "Gift of the Phoenix",
          "Forgotten Ink and Quill", "Gilded Armillary Sphere",
          "Antique Nobleman's Signet Ring", "Farstrider's Lost Quiver",
          "Stone Vat of Wine", "Burbling Paint Pot",
      }, name = "Treasures of Eversong Woods",
      zoneMapID = MC.MAP.Eversong, zone = "Eversong Woods" },
    { source = "zulaman", achievementID = 62125, criteriaCount = 7,
      criteriaNames = {
          "Honored Warrior's Cache", "Sealed Twilight Blade Bounty", "Bait and Tackle",
          "Burrow Bounty", "Mrruk's Mangy Trove", "Secret Formula", "Abandoned Nest",
      }, name = "Treasures of Zul'Aman",
      zoneMapID = MC.MAP.ZulAman, zone = "Zul'Aman" },
    { source = "harandar", achievementID = 61263, criteriaCount = 9,
      criteriaNames = {
          "Failed Shroom Jumper's Satchel", "Burning Branch of the World Tree",
          "Sporelord's Fight Prize", "Reliquary's Lost Paintbrush",
          "Kemet's Simmering Cauldron", "Gift of the Cycle",
          "Impenetrably Sealed Gourd", "Sporespawned Cache", "Peculiar Cauldron",
      }, name = "Treasures of Harandar",
      zoneMapID = MC.MAP.Harandar, zone = "Harandar" },
    { source = "voidstorm", achievementID = 62126, criteriaCount = 13,
      criteriaNames = {
          "Final Clutch of Predaxas", "Void-Shielded Tomb", "Bloody Sack",
          "Malignant Chest", "Stellar Stash", "Forgotten Researcher's Cache",
          "Scout's Pack", "Embedded Spear", "Quivering Egg", "Exaliburn",
          "Discarded Energy Pike", "Faindel's Quiver", "Half-Digested Viscera",
      }, name = "Treasures of Voidstorm",
      zoneMapID = MC.MAP.Voidstorm, zone = "Voidstorm" },
})

-- name -> { mapID, x, y, "Name" }
-- Coords sourced from HandyNotes_Midnight (May 2026), deduped to one waypoint
-- per criterion; multi-node entries (e.g. Forgotten Researcher's Cache has
-- both an entrance and an inner chest) keep the parent-zone entrance.
MC.TreasureCoords = {
    -- Eversong Woods (9)
    ["Rookery Cache"]                     = { MC.MAP.Silvermoon, 0.2434, 0.6928, "Rookery Cache" },
    ["Triple-Locked Safebox"]             = { MC.MAP.Eversong,   0.3889, 0.7606, "Triple-Locked Safebox" },
    ["Gift of the Phoenix"]               = { MC.MAP.Eversong,   0.4096, 0.1945, "Gift of the Phoenix" },
    ["Forgotten Ink and Quill"]           = { MC.MAP.Eversong,   0.4327, 0.6949, "Forgotten Ink and Quill" },
    ["Gilded Armillary Sphere"]           = { MC.MAP.Eversong,   0.4461, 0.4554, "Gilded Armillary Sphere" },
    ["Antique Nobleman's Signet Ring"]    = { MC.MAP.Eversong,   0.5234, 0.4543, "Antique Nobleman's Signet Ring" },
    ["Farstrider's Lost Quiver"]          = { MC.MAP.Eversong,   0.6068, 0.6729, "Farstrider's Lost Quiver" },
    ["Stone Vat of Wine"]                 = { MC.MAP.Eversong,   0.4043, 0.6089, "Stone Vat of Wine" },
    ["Burbling Paint Pot"]                = { MC.MAP.Eversong,   0.4873, 0.7544, "Burbling Paint Pot" },
    -- Zul'Aman (7)
    ["Honored Warrior's Cache"]           = { MC.MAP.ZulAman, 0.4683, 0.8186, "Honored Warrior's Cache" },
    ["Sealed Twilight Blade Bounty"]      = { MC.MAP.ZulAman, 0.2189, 0.7738, "Sealed Twilight Blade Bounty" },
    ["Bait and Tackle"]                   = { MC.MAP.ZulAman, 0.2084, 0.6654, "Bait and Tackle" },
    ["Burrow Bounty"]                     = { MC.MAP.ZulAman, 0.4199, 0.4779, "Burrow Bounty" },
    ["Mrruk's Mangy Trove"]               = { MC.MAP.ZulAman, 0.5232, 0.6599, "Mrruk's Mangy Trove" },
    ["Secret Formula"]                    = { MC.MAP.ZulAman, 0.4048, 0.3595, "Secret Formula" },
    ["Abandoned Nest"]                    = { MC.MAP.ZulAman, 0.4264, 0.5243, "Abandoned Nest" },
    -- Harandar (9; Gift of the Cycle is in The Den sub-map)
    ["Failed Shroom Jumper's Satchel"]    = { MC.MAP.Harandar,    0.7168, 0.3100, "Failed Shroom Jumper's Satchel" },
    ["Burning Branch of the World Tree"]  = { MC.MAP.Harandar,    0.4706, 0.5025, "Burning Branch of the World Tree" },
    ["Sporelord's Fight Prize"]           = { MC.MAP.Harandar,    0.7365, 0.6535, "Sporelord's Fight Prize" },
    ["Reliquary's Lost Paintbrush"]       = { MC.MAP.Harandar,    0.6290, 0.5124, "Reliquary's Lost Paintbrush" },
    ["Kemet's Simmering Cauldron"]        = { MC.MAP.Harandar,    0.5569, 0.3943, "Kemet's Simmering Cauldron" },
    ["Gift of the Cycle"]                 = { MC.MAP.HarandarDen, 0.4723, 0.5078, "Gift of the Cycle" },
    ["Impenetrably Sealed Gourd"]         = { MC.MAP.Harandar,    0.2673, 0.6759, "Impenetrably Sealed Gourd" },
    ["Sporespawned Cache"]                = { MC.MAP.Harandar,    0.4665, 0.6778, "Sporespawned Cache" },
    ["Peculiar Cauldron"]                 = { MC.MAP.Harandar,    0.4064, 0.2802, "Peculiar Cauldron" },
    -- Voidstorm (13; Stellar Stash and Scout's Pack are in Slayer's Rise)
    ["Final Clutch of Predaxas"]          = { MC.MAP.Voidstorm,   0.4994, 0.7936, "Final Clutch of Predaxas" },
    ["Void-Shielded Tomb"]                = { MC.MAP.Voidstorm,   0.2576, 0.6728, "Void-Shielded Tomb" },
    ["Bloody Sack"]                       = { MC.MAP.Voidstorm,   0.6453, 0.7547, "Bloody Sack" },
    ["Malignant Chest"]                   = { MC.MAP.Voidstorm,   0.5336, 0.4266, "Malignant Chest" },
    ["Stellar Stash"]                     = { MC.MAP.SlayersRise, 0.5313, 0.3228, "Stellar Stash" },
    ["Forgotten Researcher's Cache"]      = { MC.MAP.Voidstorm,   0.4793, 0.7851, "Forgotten Researcher's Cache (entrance)" },
    ["Scout's Pack"]                      = { MC.MAP.SlayersRise, 0.4905, 0.2012, "Scout's Pack" },
    ["Embedded Spear"]                    = { MC.MAP.Voidstorm,   0.5537, 0.7542, "Embedded Spear" },
    ["Quivering Egg"]                     = { MC.MAP.Voidstorm,   0.3150, 0.4451, "Quivering Egg" },
    ["Exaliburn"]                         = { MC.MAP.Voidstorm,   0.2833, 0.7290, "Exaliburn" },
    ["Discarded Energy Pike"]             = { MC.MAP.Voidstorm,   0.3577, 0.4141, "Discarded Energy Pike" },
    ["Faindel's Quiver"]                  = { MC.MAP.Voidstorm,   0.4301, 0.8194, "Faindel's Quiver" },
    ["Half-Digested Viscera"]             = { MC.MAP.Voidstorm,   0.3769, 0.6976, "Half-Digested Viscera" },
}

-- Aliases for spelling drift between HandyNotes and the achievement criterion.
-- Add new entries as players spot treasures with `waypoint: none` in ctrl-click.
local NAME_ALIASES = {
    -- HandyNotes typo: missing 'e'
    ["Impenatrably Sealed Gourd"] = "Impenetrably Sealed Gourd",
    -- Live criterion name dropped the suffix in 12.1; metadata keys keep it
    ["Stone Vat"] = "Stone Vat of Wine",
}
for criterion, handyName in pairs(NAME_ALIASES) do
    MC.TreasureCoords[criterion] = MC.TreasureCoords[handyName]
end

-- Per-treasure step-by-step notes. Most treasures are just "click the chest at
-- the marker" and don't need a note; only the ones with a puzzle, key, or
-- prerequisite are listed here. Verified May 2026 against current community
-- guides (method.gg, Wowhead, Warcraft Wiki).
MC.TreasureNotes = {
    ["Rookery Cache"] =
        "On the flying platform. Requires the Rookery Cache Key, dropped by the Mischievous Chick after feeding it Tasty Meat (bought from Farstrider Aerieminder).",
    ["Triple-Locked Safebox"] =
        "Take the Burning Torch next to the chest to gain a buff that reveals three Safebox Keys hidden around Windrunner Village. Loot all three, then unlock the chest.",
    ["Gift of the Phoenix"] =
        "Interact with the Sunstrider Vessel to spawn Phoenix Hatchlings, stand in 5 Phoenix Cinder circles they leave behind, then return the vessel to spawn the chest.",
    ["Stone Vat of Wine"] =
        "On the flying platform. Gather 10x Bunch of Ripe Grapes from the vineyards, drop them in the vat, jump inside to stomp, then add a Packet of Instant Yeast (vendored from Sheri).",
    ["Bloody Sack"] =
        "Pick up Dripping Meat from the ground around the Forgotten Oubliette and throw it in until the Bloody Sack appears.",
    ["Exaliburn"] =
        "Drink the nearby Potion of Unquestionable Strength, then pull out the Exaliburn.",
    -- Malignant Chest moved to MC.TreasureSteps below — has live ✓/✗ per node.
    ["Void-Shielded Tomb"] =
        "Drink the Potion of Dissociation on the nearby table, then race to the opposite building, grab the Key of Fused Darkness, and use it on the tomb before the buff expires.",
    ["Sporespawned Cache"] =
        "Pick up the Fungal Mallet in Fungara Village to gain a buff, then ring the Mycelium Gong to spawn the chest beside it.",
    ["Impenetrably Sealed Gourd"] =
        "Collect the Mysterious Red Fluid and Mysterious Purple Fluid from the cave, combine them at the Durable Vase to brew Fizzing Fluid, then use it on the gourd.",
    ["Peculiar Cauldron"] =
        "Requires 150x Crystalized Resin Fragment. Farm them from Flame-Hardened Sap of Teldrassil objects (purple outline) that spawn in the stream next to the cauldron — each loots 2-7 fragments. Drinking an Inky Black Potion makes the outlines easier to spot. The saps stop spawning at 149/150, so drop one fragment temporarily to finish farming.",
}

-- Step-by-step task lists. Like TreasureNotes but with per-task quest IDs so
-- the tooltip can render ✓/✗ progress and the row click routes waypoints to
-- the incomplete steps. Use this when a treasure is gated on a quest chain
-- (multi-quest prerequisites). For simple text-only notes, use TreasureNotes.
MC.TreasureSteps = {
    ["Gift of the Cycle"] = {
        intro = "Bring a found item to each of the three altars in Harandar. Click drops a waypoint at both the item pickup and the altar for any incomplete step.",
        tasks = {
            { questID = 93130, label = "Altar of Innocence (A Tattered Ball)",
              pickupWaypoint = { MC.MAP.Harandar, 0.5110, 0.5049, "A Tattered Ball" },
              waypoint       = { MC.MAP.Harandar, 0.5115, 0.4755, "Altar of Innocence" } },
            { questID = 93145, label = "Altar of Vigor (Lost Hunting Knife)",
              pickupWaypoint = { MC.MAP.Harandar, 0.4514, 0.5412, "Lost Hunting Knife" },
              waypoint       = { MC.MAP.Harandar, 0.4718, 0.5314, "Altar of Vigor" } },
            { questID = 93146, label = "Altar of Wisdom (A Rolled-Up Pillow)",
              pickupWaypoint = { MC.MAP.Harandar, 0.5139, 0.5600, "A Rolled-Up Pillow" },
              waypoint       = { MC.MAP.Harandar, 0.5115, 0.5856, "Altar of Wisdom" } },
        },
    },
    ["Sealed Twilight Blade Bounty"] = {
        intro = "Empower 4 sealing orbs around the bounty before opening the chest.",
        tasks = {
            { questID = 93918, label = "Sealing Orb (NW)",
              waypoint = { MC.MAP.ZulAman, 0.2402, 0.7566, "Sealing Orb (NW)" } },
            { questID = 93919, label = "Sealing Orb (NE)",
              waypoint = { MC.MAP.ZulAman, 0.2609, 0.7401, "Sealing Orb (NE)" } },
            { questID = 93916, label = "Sealing Orb (SE)",
              waypoint = { MC.MAP.ZulAman, 0.2609, 0.8074, "Sealing Orb (SE)" } },
            { questID = 93917, label = "Sealing Orb (SW)",
              waypoint = { MC.MAP.ZulAman, 0.2395, 0.7895, "Sealing Orb (SW)" } },
        },
    },
    ["Malignant Chest"] = {
        intro = "Activate every Malignant Node in the cave (only one is active at a time) until the chest spawns.",
        tasks = {
            { questID = 93812, label = "Malignant Node 1",
              waypoint = { MC.MAP.Voidstorm, 0.5348, 0.4323, "Malignant Node 1" } },
            { questID = 93813, label = "Malignant Node 2",
              waypoint = { MC.MAP.Voidstorm, 0.5292, 0.4332, "Malignant Node 2" } },
            { questID = 93814, label = "Malignant Node 3",
              waypoint = { MC.MAP.Voidstorm, 0.5353, 0.4391, "Malignant Node 3" } },
            { questID = 93815, label = "Malignant Node 4",
              waypoint = { MC.MAP.Voidstorm, 0.5323, 0.4268, "Malignant Node 4" } },
        },
    },
    ["Honored Warrior's Cache"] = {
        intro = "Loot all 4 totem items from the Loa's Chosen mobs at each shrine.",
        tasks = {
            { itemID = 259220, label = "Dragonhawk Feather (Jan'alai's Chosen)",
              waypoint = { MC.MAP.ZulAman, 0.5477, 0.2240, "Jan'alai's Chosen" } },
            { itemID = 259223, label = "Lynx Claw (Halazzi's Chosen)",
              waypoint = { MC.MAP.ZulAman, 0.3454, 0.3348, "Halazzi's Chosen" } },
            { itemID = 259221, label = "Eagle Talon (Akil'zon's Chosen)",
              waypoint = { MC.MAP.ZulAman, 0.5157, 0.8491, "Akil'zon's Chosen" } },
            { itemID = 259219, label = "Bear Tooth (Nalorakk's Chosen)",
              waypoint = { MC.MAP.ZulAman, 0.3269, 0.8349, "Nalorakk's Chosen" } },
        },
    },
}
-- Mirror the alias so the typo'd name resolves the same note.
MC.TreasureNotes["Impenatrably Sealed Gourd"] = MC.TreasureNotes["Impenetrably Sealed Gourd"]
