local _, MR = ...

-- NPC waypoint data: { mapID, x, y, "NPC Name" }
-- Midnight uiMapIDs: Silvermoon=2393, Eversong=2395, Zul'Aman=2437, Harandar=2413, Voidstorm=2405
local NPC = {
    Mirvedon       = { 2393, 0.340, 0.812, "Mirvedon, Silvermoon City" },
    Lyrendal       = { 2393, 0.450, 0.554, "Lyrendal, Silvermoon City" },
    CaerisFairdawn = { 2395, 0.435, 0.474, "Caeris Fairdawn, Saltheril's Haven" },
    Magovu         = { 2437, 0.460, 0.659, "Magovu, Zul'Aman" },
    Naynar         = { 2413, 0.510, 0.508, "Naynar, Harandar" },
    Anomander      = { 2405, 0.526, 0.729, "Void Researcher Anomander, Voidstorm" },
}

MR.JewelcraftingRecipes = {
    {
        name = "Peridot Gems",
        recipes = {
            { id = 1230437, name = "Quick Peridot",              source = "trainer",        sourceInfo = "Trainer (Skill 10)",                  priority = 1 },
            { id = 1230439, name = "Deadly Peridot",             source = "trainer",        sourceInfo = "Trainer (Skill 15)",                  priority = 1 },
            { id = 1230440, name = "Masterful Peridot",          source = "trainer",        sourceInfo = "Trainer (Skill 20)",                  priority = 1 },
            { id = 1230441, name = "Versatile Peridot",          source = "trainer",        sourceInfo = "Trainer (Skill 25)",                  priority = 1 },
            { id = 1230442, name = "Flawless Quick Peridot",     source = "trainer",        sourceInfo = "Trainer (Skill 50)",                  priority = 1 },
            { id = 1230443, name = "Flawless Deadly Peridot",    source = "specialization", sourceInfo = "Glamorous Gems - Deadly Peridot",     priority = 3 },
            { id = 1230444, name = "Flawless Masterful Peridot", source = "specialization", sourceInfo = "Glamorous Gems - Masterful Peridot",  priority = 3 },
            { id = 1230445, name = "Flawless Versatile Peridot", source = "specialization", sourceInfo = "Glamorous Gems - Versatile Peridot",  priority = 3 },
            { id = 1230481, name = "Harandar Peridot Prism",     source = "specialization", sourceInfo = "Glamorous Gems",                      priority = 3 },
        },
    },
    {
        name = "Lapis Gems",
        recipes = {
            { id = 1230449, name = "Versatile Lapis",            source = "trainer",        sourceInfo = "Trainer (Skill 10)",              priority = 1 },
            { id = 1230447, name = "Deadly Lapis",               source = "trainer",        sourceInfo = "Trainer (Skill 15)",              priority = 1 },
            { id = 1230448, name = "Masterful Lapis",            source = "trainer",        sourceInfo = "Trainer (Skill 20)",              priority = 1 },
            { id = 1230446, name = "Quick Lapis",                source = "trainer",        sourceInfo = "Trainer (Skill 25)",              priority = 1 },
            { id = 1230453, name = "Flawless Versatile Lapis",   source = "trainer",        sourceInfo = "Trainer (Skill 50)",              priority = 1 },
            { id = 1230450, name = "Flawless Quick Lapis",       source = "specialization", sourceInfo = "Glamorous Gems - Quick Lapis",    priority = 3 },
            { id = 1230451, name = "Flawless Deadly Lapis",      source = "specialization", sourceInfo = "Glamorous Gems - Deadly Lapis",   priority = 3 },
            { id = 1230452, name = "Flawless Masterful Lapis",   source = "specialization", sourceInfo = "Glamorous Gems - Masterful Lapis", priority = 3 },
            { id = 1230482, name = "Amani Lapis Prism",          source = "specialization", sourceInfo = "Glamorous Gems",                   priority = 3 },
        },
    },
    {
        name = "Amethyst Gems",
        recipes = {
            { id = 1230456, name = "Masterful Amethyst",            source = "trainer",        sourceInfo = "Trainer (Skill 10)",                  priority = 1 },
            { id = 1230455, name = "Deadly Amethyst",               source = "trainer",        sourceInfo = "Trainer (Skill 20)",                  priority = 1 },
            { id = 1230454, name = "Quick Amethyst",                source = "trainer",        sourceInfo = "Trainer (Skill 25)",                  priority = 1 },
            { id = 1230457, name = "Versatile Amethyst",            source = "trainer",        sourceInfo = "Trainer (Skill 30)",                  priority = 1 },
            { id = 1230460, name = "Flawless Masterful Amethyst",   source = "trainer",        sourceInfo = "Trainer (Skill 50)",                  priority = 1 },
            { id = 1230458, name = "Flawless Quick Amethyst",       source = "specialization", sourceInfo = "Glamorous Gems - Quick Amethyst",     priority = 3 },
            { id = 1230459, name = "Flawless Deadly Amethyst",      source = "specialization", sourceInfo = "Glamorous Gems - Deadly Amethyst",    priority = 3 },
            { id = 1230461, name = "Flawless Versatile Amethyst",   source = "specialization", sourceInfo = "Glamorous Gems - Versatile Amethyst", priority = 3 },
            { id = 1230483, name = "Tenebrous Amethyst Prism",      source = "specialization", sourceInfo = "Glamorous Gems",                      priority = 3 },
        },
    },
    {
        name = "Garnet Gems",
        recipes = {
            { id = 1230463, name = "Deadly Garnet",              source = "trainer",        sourceInfo = "Trainer (Skill 10)",                 priority = 1 },
            { id = 1230462, name = "Quick Garnet",               source = "trainer",        sourceInfo = "Trainer (Skill 20)",                 priority = 1 },
            { id = 1230464, name = "Masterful Garnet",           source = "trainer",        sourceInfo = "Trainer (Skill 25)",                 priority = 1 },
            { id = 1230465, name = "Versatile Garnet",           source = "trainer",        sourceInfo = "Trainer (Skill 30)",                 priority = 1 },
            { id = 1230467, name = "Flawless Deadly Garnet",     source = "trainer",        sourceInfo = "Trainer (Skill 50)",                 priority = 1 },
            { id = 1230466, name = "Flawless Quick Garnet",      source = "specialization", sourceInfo = "Glamorous Gems - Quick Garnet",      priority = 3 },
            { id = 1230468, name = "Flawless Masterful Garnet",  source = "specialization", sourceInfo = "Glamorous Gems - Masterful Garnet",  priority = 3 },
            { id = 1230469, name = "Flawless Versatile Garnet",  source = "specialization", sourceInfo = "Glamorous Gems - Versatile Garnet",  priority = 3 },
            { id = 1230484, name = "Sanguine Garnet Prism",      source = "specialization", sourceInfo = "Glamorous Gems",                     priority = 3 },
        },
    },
    {
        name = "Meta Gems",
        recipes = {
            { id = 1230470, name = "Powerful Eversong Diamond",       source = "drop", sourceInfo = "Midnight Dungeons", priority = 4, dropInfo = { rate = "~5%" } },
            { id = 1230471, name = "Telluric Eversong Diamond",       source = "drop", sourceInfo = "Midnight Dungeons", priority = 4, dropInfo = { rate = "~5%" } },
            { id = 1230472, name = "Stoic Eversong Diamond",          source = "drop", sourceInfo = "Midnight Dungeons", priority = 4, dropInfo = { rate = "~5%" } },
            { id = 1230473, name = "Indecipherable Eversong Diamond", source = "drop", sourceInfo = "Midnight Dungeons", priority = 4, dropInfo = { rate = "~5%" } },
        },
    },
    {
        name = "PvP Gems",
        recipes = {
            { id = 1230500, name = "Determined Heliotrope", source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = NPC.Mirvedon, cost = { currency = { 1792, 7500 } } },
            { id = 1230501, name = "Cognitive Heliotrope",  source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = NPC.Mirvedon, cost = { currency = { 1792, 7500 } } },
            { id = 1230502, name = "Enduring Heliotrope",   source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = NPC.Mirvedon, cost = { currency = { 1792, 7500 } } },
        },
    },
    {
        name = "Rings",
        recipes = {
            { id = 1230489, name = "Gleaming Copper Band",           source = "trainer",        sourceInfo = "Trainer (Skill 20)",                       priority = 1 },
            { id = 1230479, name = "Loa Worshiper's Band",           source = "vendor",         sourceInfo = "Magovu (1500 Voidlight Marl + 150 Moxie)", priority = 1, waypoint = NPC.Magovu, cost = { currency = { 3262, 150 }, currency2 = { 3316, 1500 } } },
            { id = 1230487, name = "Signet of Azerothian Blessings", source = "vendor",         sourceInfo = "Naynar (150 Moxie)",                       priority = 1, waypoint = NPC.Naynar, cost = { currency = { 3262, 150 }, currency2 = { 3316, 1500 } } },
            { id = 1230503, name = "Thalassian Competitor's Signet", source = "vendor",         sourceInfo = "Mirvedon (7500 Honor)",                    priority = 1, waypoint = NPC.Mirvedon, cost = { currency = { 1792, 7500 } } },
            { id = 1230485, name = "Masterwork Sin'dorei Band",      source = "specialization", sourceInfo = "Alluring Accessories - Regal Rings",       priority = 3 },
        },
    },
    {
        name = "Necklaces",
        recipes = {
            { id = 1230490, name = "Nocturnal Charm",                  source = "trainer",        sourceInfo = "Trainer (Skill 30)",                        priority = 1 },
            { id = 1230504, name = "Thalassian Competitor's Amulet",   source = "vendor",         sourceInfo = "Mirvedon (7500 Honor)",                     priority = 1, waypoint = NPC.Mirvedon, cost = { currency = { 1792, 7500 } } },
            { id = 1230486, name = "Masterwork Sin'dorei Amulet",      source = "specialization", sourceInfo = "Alluring Accessories - Luxurious Lockets",  priority = 3 },
            { id = 1230488, name = "Thalassian Phoenix Torque",        source = "drop",           sourceInfo = "Belo'ren",                                  priority = 4, dropInfo = { rate = "~3%" } },
            { id = 1251983, name = "Voidstone Shielding Array",        source = "drop",           sourceInfo = "Charonus",                                   priority = 4, dropInfo = { rate = "~3%" } },
        },
    },
    {
        name = "Reagents",
        recipes = {
            { id = 1230476, name = "Sunglass Vial",                  source = "trainer", sourceInfo = "Trainer (Skill 5)",  priority = 1 },
            { id = 1230475, name = "Sin'dorei Lens",                 source = "trainer", sourceInfo = "Trainer (Skill 10)", priority = 1 },
            { id = 1230474, name = "Kaleidoscopic Prism",            source = "trainer", sourceInfo = "Trainer (Skill 40)", priority = 1 },
            { id = 1230477, name = "Prismatic Focusing Iris",        source = "drop",    sourceInfo = "Lothraxion, Nexus-Point Xenas", priority = 4, dropInfo = { rate = "~3%" } },
            { id = 1230478, name = "Stabilizing Gemstone Bandolier", source = "drop",    sourceInfo = "Heavy Trunk (Delves)",          priority = 4, dropInfo = { rate = "~3%" } },
        },
    },
    {
        name = "Profession Equipment",
        recipes = {
            { id = 1230492, name = "Silvermoon Loupes",                          source = "trainer", sourceInfo = "Trainer (Skill 1)",             priority = 1 },
            { id = 1230491, name = "Silvermoon Focusing Shard",                  source = "trainer", sourceInfo = "Trainer (Skill 25)",            priority = 1 },
            { id = 1230493, name = "Fantastic Font Focuser",                     source = "trainer", sourceInfo = "Trainer (Skill 35)",            priority = 1 },
            { id = 1230494, name = "Bold Biographer's Bifocals",                 source = "trainer", sourceInfo = "Trainer (Skill 45)",            priority = 1 },
            { id = 1230496, name = "Sin'dorei Jeweler's Loupes",                 source = "vendor",  sourceInfo = "Lyrendal (150 Artisan Moxie)",  priority = 1, waypoint = NPC.Lyrendal, cost = { currency = { 3262, 150 } } },
            { id = 1230495, name = "Sin'dorei Enchanter's Crystal",              source = "vendor",  sourceInfo = "Lyrendal (150 Artisan Moxie)",  priority = 1, waypoint = NPC.Lyrendal, cost = { currency = { 3262, 150 } } },
            { id = 1230497, name = "Improved Right-Handed Magnifying Glass",     source = "vendor",  sourceInfo = "Lyrendal (150 Artisan Moxie)",  priority = 1, waypoint = NPC.Lyrendal, cost = { currency = { 3262, 150 } } },
            { id = 1230498, name = "Sin'dorei Scribe's Spectacles",             source = "vendor",  sourceInfo = "Lyrendal (150 Artisan Moxie)",  priority = 1, waypoint = NPC.Lyrendal, cost = { currency = { 3262, 150 } } },
            { id = 1242461, name = "Mage-Eye Precision Loupes",                  source = "vendor",  sourceInfo = "Lyrendal (150 Artisan Moxie)",  priority = 1, waypoint = NPC.Lyrendal, cost = { currency = { 3262, 150 } } },
            { id = 1242462, name = "Thalassian Scribe's Crystalline Lens",       source = "vendor",  sourceInfo = "Lyrendal (150 Artisan Moxie)",  priority = 1, waypoint = NPC.Lyrendal, cost = { currency = { 3262, 150 } } },
            { id = 1242463, name = "Flawless Text Scrutinizers",                 source = "vendor",  sourceInfo = "Lyrendal (150 Artisan Moxie)",  priority = 1, waypoint = NPC.Lyrendal, cost = { currency = { 3262, 150 } } },
            { id = 1242464, name = "Attuned Thalassian Rune-Prism",              source = "vendor",  sourceInfo = "Lyrendal (150 Artisan Moxie)",  priority = 1, waypoint = NPC.Lyrendal, cost = { currency = { 3262, 150 } } },
        },
    },
    {
        name = "Miscellaneous",
        recipes = {
            { id = 1230499, name = "Monologuer's Chalice", source = "trainer", sourceInfo = "Trainer (Skill 40)", priority = 1 },
        },
    },
    {
        name = "Housing Decor",
        recipes = {
            { id = 1246895, name = "Brilliant Phoenix Harp",        source = "trainer", sourceInfo = "Trainer (Skill 80)",     priority = 1 },
            { id = 1246889, name = "Tenebrous Ren'dorei Armillary", source = "trainer", sourceInfo = "Trainer (Skill 80)",     priority = 1 },
            { id = 1246891, name = "Bejeweled Sin'dorei Lyre",      source = "vendor",  sourceInfo = "Caeris Fairdawn, Eversong Woods", priority = 1, waypoint = NPC.CaerisFairdawn, cost = { currency = { 3262, 150 }, currency2 = { 3316, 1500 } } },
            { id = 1246892, name = "Resplendent Highborne Statue",  source = "drop",    sourceInfo = "Eversong Treasures",     priority = 4, dropInfo = { rate = "~5%" } },
            { id = 1246893, name = "Replica Haranir Mural",         source = "drop",    sourceInfo = "Heavy Trunk (Delves)",   priority = 4, dropInfo = { rate = "~3%" } },
            { id = 1246894, name = "Shining Sin'dorei Hourglass",   source = "drop",    sourceInfo = "Challenger's Cache",     priority = 4, dropInfo = { rate = "~5%" } },
        },
    },
}
