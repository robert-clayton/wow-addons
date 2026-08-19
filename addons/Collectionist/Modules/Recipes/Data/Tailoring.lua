local _, MC = ...
local T = MC.SCORE_TIERS

local LOC = MC.LOC

MC.TailoringRecipes = {
    {
        name = "Woven Cloth",
        recipes = {
            { id = 1228939, name = "Bright Linen Bolt",           source = "trainer",        sourceInfo = "Trainer (Skill 1)",                          priority = 1 },
            { id = 1228940, name = "Imbued Bright Linen Bolt",    source = "trainer",        sourceInfo = "Trainer (Skill 25)",                         priority = 1 },
            { id = 1228060, name = "Sunfire Silk Bolt",           source = "specialization", sourceInfo = "Nimble Needlework - Sunfire Silk Weaving",    priority = 3 },
            { id = 1227926, name = "Arcanoweave Bolt",            source = "specialization", sourceInfo = "Nimble Needlework - Arcanoweaving",           priority = 3 },
        },
    },
    {
        name = "Consumables",
        recipes = {
            { id = 1228941, name = "Bright Linen Bandage", source = "trainer", sourceInfo = "Trainer (Skill 1)", priority = 1 },
        },
    },
    {
        name = "Courtly Cloth Armor",
        recipes = {
            { id = 1228954, name = "Courtly Wrists",    source = "trainer", sourceInfo = "Trainer (Skill 5)",  priority = 1 },
            { id = 1228953, name = "Courtly Belt",       source = "trainer", sourceInfo = "Trainer (Skill 10)", priority = 1 },
            { id = 1228952, name = "Courtly Gloves",     source = "trainer", sourceInfo = "Trainer (Skill 15)", priority = 1 },
            { id = 1228957, name = "Courtly Slippers",   source = "trainer", sourceInfo = "Trainer (Skill 15)", priority = 1 },
            { id = 1228958, name = "Courtly Cloak",      source = "trainer", sourceInfo = "Trainer (Skill 15)", priority = 1 },
            { id = 1228956, name = "Courtly Pants",      source = "trainer", sourceInfo = "Trainer (Skill 20)", priority = 1 },
            { id = 1228951, name = "Courtly Helm",       source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1228955, name = "Courtly Robes",      source = "trainer", sourceInfo = "Trainer (Skill 30)", priority = 1 },
            { id = 1228959, name = "Courtly Shoulders",  source = "trainer", sourceInfo = "Trainer (Skill 30)", priority = 1 },
        },
    },
    {
        name = "Martyr's Cloth Armor",
        recipes = {
            { id = 1228945, name = "Martyr's Bindings",        source = "specialization", sourceInfo = "Sin'dorei Finery - Bracers",    priority = 3 },
            { id = 1228944, name = "Martyr's Waistwrap",       source = "specialization", sourceInfo = "Sin'dorei Finery - Belts",      priority = 3 },
            { id = 1228943, name = "Martyr's Gloves",          source = "specialization", sourceInfo = "Sin'dorei Finery - Gloves",     priority = 3 },
            { id = 1228948, name = "Martyr's Slippers",        source = "specialization", sourceInfo = "Sin'dorei Finery - Boots",      priority = 3 },
            { id = 1228950, name = "Adherent's Silken Shroud", source = "specialization", sourceInfo = "Sin'dorei Finery - Cloaks",     priority = 3 },
            { id = 1228947, name = "Martyr's Leggings",        source = "specialization", sourceInfo = "Sin'dorei Finery - Trousers",   priority = 3 },
            { id = 1228942, name = "Martyr's Crown",           source = "specialization", sourceInfo = "Sin'dorei Finery - Hats",       priority = 3 },
            { id = 1228949, name = "Martyr's Mantle",          source = "specialization", sourceInfo = "Sin'dorei Finery - Shoulders",  priority = 3 },
            { id = 1228946, name = "Martyr's Vestments",       source = "specialization", sourceInfo = "Sin'dorei Finery - Robes",      priority = 3 },
        },
    },
    {
        name = "Sunfire Silk Armor",
        recipes = {
            { id = 1228981, name = "Sunfire Bracers", source = "specialization", sourceInfo = "Nimble Needlework - Sunfire Expertise",  priority = 3 },
            { id = 1228982, name = "Sunfire Cloak",   source = "specialization", sourceInfo = "Nimble Needlework - Sunfire Expertise",  priority = 3 },
            { id = 1228983, name = "Sunfire Treads",  source = "specialization", sourceInfo = "Nimble Needlework - Sunfire Expertise",  priority = 3 },
            { id = 1228987, name = "Sunfire Sash",    source = "drop",           sourceInfo = "Restless Heart, Windrunner Spire",       priority = 4 },
        },
    },
    {
        name = "Arcanoweave Armor",
        recipes = {
            { id = 1228984, name = "Arcanoweave Bracers", source = "specialization", sourceInfo = "Nimble Needlework - Arcanoweave Expertise", priority = 3 },
            { id = 1228985, name = "Arcanoweave Cloak",   source = "specialization", sourceInfo = "Nimble Needlework - Arcanoweave Expertise", priority = 3 },
            { id = 1228986, name = "Arcanoweave Treads",  source = "specialization", sourceInfo = "Nimble Needlework - Arcanoweave Expertise", priority = 3 },
            { id = 1228988, name = "Arcanoweave Cord",    source = "drop",           sourceInfo = "Heavy Trunk (Delves)",                      priority = 4, score = T.epic },
        },
    },
    {
        name = "Optional Reagents",
        recipes = {
            { id = 1228960, name = "Sunfire Silk Lining",  source = "drop", sourceInfo = "Heavy Trunk (Delves)",              priority = 4, score = T.epic },
            { id = 1228961, name = "Arcanoweave Lining",   source = "drop", sourceInfo = "Degentrius, Magisters' Terrace",    priority = 4 },
        },
    },
    {
        name = "Spellthreads",
        recipes = {
            { id = 1228976, name = "Bright Linen Spellthread",    source = "trainer", sourceInfo = "Trainer (Skill 35)",                          priority = 1 },
            { id = 1228975, name = "Arcanoweave Spellthread",      source = "vendor",  sourceInfo = "Caeris Fairdawn (Silvermoon Court Renown 5)", priority = 1, waypoint = LOC.CaerisFairdawn, cost = { currency = { MC.CURRENCY.TailoringMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1228974, name = "Sunfire Silk Spellthread",     source = "drop",    sourceInfo = "Fallen-King Salhadaar, The Voidspire",        priority = 4, score = T.epic },
        },
    },
    {
        name = "Bags",
        recipes = {
            { id = 1228977, name = "Imbued Bright Linen Backpack",     source = "trainer", sourceInfo = "Trainer (Skill 35)", priority = 1 },
            { id = 1228978, name = "Bright Linen Reagent Satchel",     source = "trainer", sourceInfo = "Trainer (Skill 35)", priority = 1 },
            { id = 1228980, name = "Sunfire Silk Backpack",            source = "trainer", sourceInfo = "Trainer (Skill 50)", priority = 1 },
            { id = 1228979, name = "Arcanoweave Reagent Rucksack",     source = "trainer", sourceInfo = "Trainer (Skill 50)", priority = 1 },
        },
    },
    {
        name = "Bright Linen Profession Gear",
        recipes = {
            { id = 1228968, name = "Bright Linen Alchemy Apron",              source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1228969, name = "Chef's Bright Linen Cooking Chapeau",     source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1228970, name = "Bright Linen Enchanting Hat",             source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1228971, name = "Bright Linen Fishing Hat",                source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1228972, name = "Bright Linen Herbalism Hat",              source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1228973, name = "Bright Linen Tailoring Robe",             source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
        },
    },
    {
        name = "Elegant Artisan's Profession Gear",
        recipes = {
            { id = 1228962, name = "Elegant Artisan's Alchemy Coveralls", source = "vendor", sourceInfo = "Lyrendal (150 Artisan Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.TailoringMoxie, 150 } } },
            { id = 1228963, name = "Elegant Artisan's Cooking Hat",       source = "vendor", sourceInfo = "Lyrendal (150 Artisan Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.TailoringMoxie, 150 } } },
            { id = 1228964, name = "Elegant Artisan's Enchanting Hat",    source = "vendor", sourceInfo = "Lyrendal (150 Artisan Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.TailoringMoxie, 150 } } },
            { id = 1228965, name = "Elegant Artisan's Fishing Hat",       source = "vendor", sourceInfo = "Lyrendal (150 Artisan Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.TailoringMoxie, 150 } } },
            { id = 1228966, name = "Elegant Artisan's Herbalism Hat",     source = "vendor", sourceInfo = "Lyrendal (150 Artisan Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.TailoringMoxie, 150 } } },
            { id = 1228967, name = "Elegant Artisan's Tailoring Robe",    source = "vendor", sourceInfo = "Lyrendal (150 Artisan Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.TailoringMoxie, 150 } } },
        },
    },
    {
        name = "Thalassian Profession Gear",
        recipes = {
            { id = 1279123, name = "Thalassian Alchemy Coveralls",    source = "vendor", sourceInfo = "Lyrendal (200 Artisan Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.TailoringMoxie, 200 } } },
            { id = 1279124, name = "Thalassian Chef's Chapeau",       source = "vendor", sourceInfo = "Lyrendal (200 Artisan Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.TailoringMoxie, 200 } } },
            { id = 1279125, name = "Thalassian Enchanter's Bonnet",   source = "vendor", sourceInfo = "Lyrendal (200 Artisan Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.TailoringMoxie, 200 } } },
            { id = 1279128, name = "Thalassian Herbalist's Cowl",     source = "vendor", sourceInfo = "Lyrendal (200 Artisan Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.TailoringMoxie, 200 } } },
            { id = 1279129, name = "Thalassian Tailor's Threads",     source = "vendor", sourceInfo = "Lyrendal (200 Artisan Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.TailoringMoxie, 200 } } },
        },
    },
    {
        name = "PvP Competitor's Cloth",
        recipes = {
            { id = 1228989, name = "Thalassian Competitor's Cloth Bands",        source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1228990, name = "Thalassian Competitor's Cloth Cloak",        source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1228991, name = "Thalassian Competitor's Cloth Gloves",       source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1228992, name = "Thalassian Competitor's Cloth Hood",         source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1228993, name = "Thalassian Competitor's Cloth Leggings",     source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1228994, name = "Thalassian Competitor's Cloth Sash",         source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1228995, name = "Thalassian Competitor's Cloth Shoulderpads", source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1228996, name = "Thalassian Competitor's Cloth Treads",       source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1228997, name = "Thalassian Competitor's Cloth Tunic",        source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
        },
    },
    {
        name = "Cosmetic Cloaks",
        recipes = {
            { id = 1280541, name = "Smuggler's Cloak",                 source = "trainer", sourceInfo = "Trainer (Skill 50)", priority = 1 },
            { id = 1280542, name = "Silvermoon Agent's Drape",         source = "trainer", sourceInfo = "Trainer (Skill 50)", priority = 1 },
            { id = 1280543, name = "Scout's Cape",                     source = "trainer", sourceInfo = "Trainer (Skill 50)", priority = 1 },
            { id = 1280544, name = "Farstrider's Embroidered Cover",   source = "trainer", sourceInfo = "Trainer (Skill 50)", priority = 1 },
            { id = 1280545, name = "Blood-Tempered Cape",              source = "trainer", sourceInfo = "Trainer (Skill 50)", priority = 1 },
            { id = 1280546, name = "Spellbreaker's Shroud",            source = "trainer", sourceInfo = "Trainer (Skill 50)", priority = 1 },
        },
    },
    {
        name = "Housing Decor",
        recipes = {
            { id = 1229000, name = "Silvermoon Curtains",                  source = "quest",  sourceInfo = "Quest: Clothes Make the Man (Eversong)", priority = 4 },
            { id = 1229001, name = "Lush Telogrus Carpet",                source = "vendor", sourceInfo = "Anomander (Singularity Renown 5)",       priority = 1, waypoint = LOC.Anomander, cost = { currency = { MC.CURRENCY.TailoringMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1229002, name = "Luxurious Silvermoon Lounge Cushion", source = "drop",   sourceInfo = "Eversong Treasures",                     priority = 4 },
            { id = 1229003, name = "Plush Silvermoon Bed",                source = "vendor", sourceInfo = "Lyrendal (150 Artisan Moxie)",           priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.TailoringMoxie, 150 } } },
            { id = 1246919, name = "Chic Silvermoon Pillow",              source = "vendor", sourceInfo = "Lyrendal (150 Artisan Moxie)",           priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.TailoringMoxie, 150 } } },
            { id = 1246929, name = "Voidstrider Saddlebag",               source = "drop",   sourceInfo = "Victorious Stormarion Cache",             priority = 4, dropInfo = { rate = "~1%" } },
        },
    },
}
