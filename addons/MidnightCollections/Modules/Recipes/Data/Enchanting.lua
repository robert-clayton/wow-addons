local _, MC = ...

local LOC = MC.LOC

MC.EnchantingRecipes = {
    {
        name = "Weapon Enchants",
        recipes = {
            { id = 1236067, name = "Enchant Weapon - Berserker's Rage",          source = "trainer",  sourceInfo = "Trainer (Skill 20)",             priority = 1 },
            { id = 1236097, name = "Enchant Weapon - Arcane Mastery",            source = "trainer",  sourceInfo = "Trainer (Skill 40)",             priority = 1 },
            { id = 1236066, name = "Enchant Weapon - Jan'alai's Precision",      source = "trainer",  sourceInfo = "Trainer (Skill 55)",             priority = 1 },
            { id = 1236080, name = "Enchant Weapon - Worldsoul Aegis",           source = "trainer",  sourceInfo = "Trainer (Skill 55)",             priority = 1 },
            { id = 1236095, name = "Enchant Weapon - Acuity of the Ren'dorei",   source = "vendor",   sourceInfo = "Void Researcher Anomander",     priority = 1, waypoint = LOC.Anomander, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1236065, name = "Enchant Weapon - Strength of Halazzi",       source = "vendor",   sourceInfo = "Magovu, Zul'Aman",              priority = 1, waypoint = LOC.Magovu, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1236081, name = "Enchant Weapon - Worldsoul Tenacity",        source = "vendor",   sourceInfo = "Naynar, Harandar",              priority = 1, waypoint = LOC.Naynar, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1236094, name = "Enchant Weapon - Flames of the Sin'dorei",   source = "drop",     sourceInfo = "Degentrius, Magisters' Terrace", priority = 4 },
            { id = 1236079, name = "Enchant Weapon - Worldsoul Cradle",          source = "drop",     sourceInfo = "Chimaerus, The Dreamrift",       priority = 4 },
        },
    },
    {
        name = "Boot Enchants",
        recipes = {
            { id = 1236085, name = "Enchant Boots - Farstrider's Hunt",      source = "vendor",         sourceInfo = "Construct V'anore, Silvermoon City", priority = 1, waypoint = LOC.ConstructVanore, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.RemnantOfAnguish, 500 } } },
            { id = 1236057, name = "Enchant Boots - Lynx's Dexterity",       source = "specialization", sourceInfo = "Amani Augments",                    priority = 3 },
            { id = 1236072, name = "Enchant Boots - Shaladrassil's Roots",   source = "drop",           sourceInfo = "Heavy Trunk (Delves)",              priority = 4 },
        },
    },
    {
        name = "Chest Enchants",
        recipes = {
            { id = 1236068, name = "Enchant Chest - Mark of the Rootwarden",  source = "vendor",         sourceInfo = "Naynar, Harandar",                priority = 1, waypoint = LOC.Naynar, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1236069, name = "Enchant Chest - Mark of the Worldsoul",   source = "specialization", sourceInfo = "Haranir Heightening",             priority = 3 },
            { id = 1236082, name = "Enchant Chest - Mark of the Magister",    source = "drop",           sourceInfo = "Degentrius, Magisters' Terrace",  priority = 4 },
            { id = 1236054, name = "Enchant Chest - Mark of Nalorakk",        source = "drop",           sourceInfo = "Den of Nalorakk (Treasure Chest)", priority = 4 },
        },
    },
    {
        name = "Helm Enchants",
        recipes = {
            { id = 1236083, name = "Enchant Helm - Rune of Avoidance",            source = "trainer",        sourceInfo = "Trainer (Skill 15)",     priority = 1 },
            { id = 1236055, name = "Enchant Helm - Hex of Leeching",              source = "trainer",        sourceInfo = "Trainer (Skill 35)",     priority = 1 },
            { id = 1236070, name = "Enchant Helm - Blessing of Speed",            source = "trainer",        sourceInfo = "Trainer (Skill 50)",     priority = 1 },
            { id = 1236071, name = "Enchant Helm - Empowered Blessing of Speed",  source = "specialization", sourceInfo = "Haranir Heightening",    priority = 3 },
            { id = 1236084, name = "Enchant Helm - Empowered Rune of Avoidance",  source = "drop",           sourceInfo = "Heavy Trunk (Delves)",   priority = 4 },
            { id = 1236056, name = "Enchant Helm - Empowered Hex of Leeching",    source = "drop",           sourceInfo = "Heavy Trunk (Delves)",   priority = 4 },
        },
    },
    {
        name = "Shoulder Enchants",
        recipes = {
            { id = 1236075, name = "Enchant Shoulders - Nature's Grace",          source = "trainer",        sourceInfo = "Trainer (Skill 10)",     priority = 1 },
            { id = 1236061, name = "Enchant Shoulders - Flight of the Eagle",     source = "trainer",        sourceInfo = "Trainer (Skill 30)",     priority = 1 },
            { id = 1236090, name = "Enchant Shoulders - Thalassian Recovery",     source = "trainer",        sourceInfo = "Trainer (Skill 50)",     priority = 1 },
            { id = 1236091, name = "Enchant Shoulders - Silvermoon's Mending",    source = "specialization", sourceInfo = "Thalassian Talents",     priority = 3 },
            { id = 1236076, name = "Enchant Shoulders - Amirdrassil's Grace",     source = "drop",           sourceInfo = "Heavy Trunk (Delves)",   priority = 4 },
            { id = 1236062, name = "Enchant Shoulders - Akil'zon's Swiftness",   source = "drop",           sourceInfo = "Heavy Trunk (Delves)",   priority = 4 },
        },
    },
    {
        name = "Ring Enchants",
        recipes = {
            { id = 1236086, name = "Enchant Ring - Thalassian Haste",         source = "trainer",        sourceInfo = "Trainer (Skill 1)",                priority = 1 },
            { id = 1236087, name = "Enchant Ring - Thalassian Versatility",   source = "trainer",        sourceInfo = "Trainer (Skill 5)",                priority = 1 },
            { id = 1236073, name = "Enchant Ring - Nature's Wrath",           source = "trainer",        sourceInfo = "Trainer (Skill 25)",               priority = 1 },
            { id = 1236058, name = "Enchant Ring - Amani Mastery",            source = "trainer",        sourceInfo = "Trainer (Skill 45)",               priority = 1 },
            { id = 1236089, name = "Enchant Ring - Silvermoon's Tenacity",    source = "vendor",         sourceInfo = "Caeris Fairdawn, Eversong Woods",  priority = 1, waypoint = LOC.CaerisFairdawn, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1236088, name = "Enchant Ring - Silvermoon's Alacrity",    source = "specialization", sourceInfo = "Thalassian Talents",               priority = 3 },
            { id = 1236060, name = "Enchant Ring - Zul'jin's Mastery",        source = "specialization", sourceInfo = "Amani Augments",                   priority = 3 },
            { id = 1236074, name = "Enchant Ring - Nature's Fury",            source = "drop",           sourceInfo = "Heavy Trunk (Delves)",             priority = 4 },
            { id = 1236059, name = "Enchant Ring - Eyes of the Eagle",        source = "drop",           sourceInfo = "Zul'Aman (Treasure Drops)",        priority = 4, dropInfo = { rate = "~0.3%" } },
        },
    },
    {
        name = "Tool Enchants",
        recipes = {
            { id = 1236063, name = "Enchant Tool - Amani Perception",        source = "vendor",         sourceInfo = "Magovu, Zul'Aman",            priority = 1, waypoint = LOC.Magovu, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1236078, name = "Enchant Tool - Haranir Multicrafting",   source = "vendor",         sourceInfo = "Naynar, Harandar",             priority = 1, waypoint = LOC.Naynar, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1236093, name = "Enchant Tool - Ren'dorei Ingenuity",     source = "vendor",         sourceInfo = "Void Researcher Anomander",    priority = 1, waypoint = LOC.Anomander, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1236064, name = "Enchant Tool - Amani Resourcefulness",   source = "specialization", sourceInfo = "Amani Augments",               priority = 3 },
            { id = 1236077, name = "Enchant Tool - Haranir Finesse",         source = "specialization", sourceInfo = "Haranir Heightening",          priority = 3 },
            { id = 1236092, name = "Enchant Tool - Sin'dorei Deftness",      source = "specialization", sourceInfo = "Thalassian Talents",           priority = 3 },
        },
    },
    {
        name = "Oils & Consumables",
        recipes = {
            { id = 1236491, name = "Thalassian Phoenix Oil",     source = "trainer",        sourceInfo = "Trainer (Skill 20)",                  priority = 1 },
            { id = 1236492, name = "Oil of Dawn",                source = "specialization", sourceInfo = "Transitories, Tonics, and Tools",     priority = 3 },
            { id = 1236493, name = "Smuggler's Enchanted Edge",  source = "drop",           sourceInfo = "Lithiel Cinderfury, Murder Row",      priority = 4 },
        },
    },
    {
        name = "Profession Rods",
        recipes = {
            { id = 1236486, name = "Runed Refulgent Copper Rod",   source = "trainer",        sourceInfo = "Trainer (Skill 1)",                      priority = 1 },
            { id = 1236488, name = "Runed Dazzling Thorium Rod",   source = "vendor",         sourceInfo = "Lyna, Silvermoon City",                  priority = 1, waypoint = LOC.Lyna, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 } } },
            { id = 1236487, name = "Runed Brilliant Silver Rod",   source = "specialization", sourceInfo = "Transitories, Tonics, and Tools",        priority = 3 },
        },
    },
    {
        name = "Shattering",
        recipes = {
            { id = 1280401, name = "Dawn Shatter",      source = "trainer",        sourceInfo = "Trainer (Skill 25)",    priority = 1 },
            { id = 1280394, name = "Radiant Shatter",    source = "trainer",        sourceInfo = "Trainer (Skill 50)",    priority = 1 },
            { id = 1235731, name = "Shatter Essence",    source = "specialization", sourceInfo = "Spellbound Shatterer",  priority = 3 },
        },
    },
    {
        name = "Wands",
        recipes = {
            { id = 1236489, name = "Thalassian Spellweaver's Wand", source = "trainer",        sourceInfo = "Trainer (Skill 40)",                                    priority = 1 },
            { id = 1236490, name = "Magister's Grand Focus",        source = "specialization", sourceInfo = "Transitories, Tonics, and Tools - Worthy Wands", priority = 3 },
        },
    },
    {
        name = "Illusions",
        recipes = {
            { id = 1236098, name = "Illusory Adornment - Blooming Light",   source = "trainer", sourceInfo = "Trainer (Skill 25)",                 priority = 1 },
            { id = 1236099, name = "Illusory Adornment - Nature's Embrace", source = "vendor",  sourceInfo = "Construct V'anore, Silvermoon City", priority = 1, waypoint = LOC.ConstructVanore, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.RemnantOfAnguish, 500 } } },
            { id = 1236100, name = "Illusory Adornment - Voidtouched",      source = "drop",    sourceInfo = "Victorious Stormarion Pinnacle Cache", priority = 4, dropInfo = { rate = "~2%" } },
        },
    },
    {
        name = "Gleeful Glamours",
        recipes = {
            { id = 1236461, name = "Gleeful Glamour - Blood Elf",            source = "trainer", sourceInfo = "Trainer (Skill 5)",  priority = 1 },
            { id = 1236475, name = "Gleeful Glamour - Night Elf",            source = "trainer", sourceInfo = "Trainer (Skill 5)",  priority = 1 },
            { id = 1236466, name = "Gleeful Glamour - Dwarf",                source = "trainer", sourceInfo = "Trainer (Skill 10)", priority = 1 },
            { id = 1236594, name = "Gleeful Glamour - Earthen",              source = "trainer", sourceInfo = "Trainer (Skill 10)", priority = 1 },
            { id = 1236481, name = "Gleeful Glamour - Undead",               source = "trainer", sourceInfo = "Trainer (Skill 10)", priority = 1 },
            { id = 1236470, name = "Gleeful Glamour - Human",                source = "trainer", sourceInfo = "Trainer (Skill 15)", priority = 1 },
            { id = 1236477, name = "Gleeful Glamour - Orc",                  source = "trainer", sourceInfo = "Trainer (Skill 15)", priority = 1 },
            { id = 1236465, name = "Gleeful Glamour - Draenei",              source = "trainer", sourceInfo = "Trainer (Skill 20)", priority = 1 },
            { id = 1236479, name = "Gleeful Glamour - Tauren",               source = "trainer", sourceInfo = "Trainer (Skill 20)", priority = 1 },
            { id = 1236476, name = "Gleeful Glamour - Nightborne",           source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1236482, name = "Gleeful Glamour - Void Elf",             source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1236483, name = "Gleeful Glamour - Vulpera",              source = "trainer", sourceInfo = "Trainer (Skill 30)", priority = 1 },
            { id = 1236484, name = "Gleeful Glamour - Worgen",               source = "trainer", sourceInfo = "Trainer (Skill 30)", priority = 1 },
            { id = 1236471, name = "Gleeful Glamour - Kul Tiran",            source = "trainer", sourceInfo = "Trainer (Skill 35)", priority = 1 },
            { id = 1236485, name = "Gleeful Glamour - Zandalari Troll",      source = "trainer", sourceInfo = "Trainer (Skill 35)", priority = 1 },
            { id = 1236469, name = "Gleeful Glamour - Highmountain Tauren",  source = "trainer", sourceInfo = "Trainer (Skill 40)", priority = 1 },
            { id = 1236472, name = "Gleeful Glamour - Lightforged Draenei",  source = "trainer", sourceInfo = "Trainer (Skill 40)", priority = 1 },
            { id = 1236463, name = "Gleeful Glamour - Dark Iron Dwarf",      source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1236478, name = "Gleeful Glamour - Pandaren",             source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1236480, name = "Gleeful Glamour - Troll",                source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1236467, name = "Gleeful Glamour - Gnome",                source = "trainer", sourceInfo = "Trainer (Skill 50)", priority = 1 },
            { id = 1236468, name = "Gleeful Glamour - Goblin",               source = "trainer", sourceInfo = "Trainer (Skill 50)", priority = 1 },
            { id = 1236473, name = "Gleeful Glamour - Mag'har Orc",          source = "trainer", sourceInfo = "Trainer (Skill 55)", priority = 1 },
            { id = 1236474, name = "Gleeful Glamour - Mechagnome",           source = "trainer", sourceInfo = "Trainer (Skill 55)", priority = 1 },
            { id = 1236464, name = "Gleeful Glamour - Haranir",              source = "vendor",  sourceInfo = "Naynar, Harandar",   priority = 1, waypoint = LOC.Naynar, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
        },
    },
    {
        name = "Housing Decor",
        recipes = {
            { id = 1246904, name = "Ensorcelled Broom",                       source = "trainer", sourceInfo = "Trainer (Skill 80)",                priority = 1 },
            { id = 1246905, name = "Font of Gleaming Water",                  source = "trainer", sourceInfo = "Trainer (Skill 80)",                priority = 1 },
            { id = 1246906, name = "Animated Sin'dorei Hammer",               source = "vendor",  sourceInfo = "World Vendor, Eversong Woods",     priority = 1, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 } } },
            { id = 1246902, name = "Animated Sin'dorei Pick",                 source = "vendor",  sourceInfo = "World Vendor, Eversong Woods",     priority = 1, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 } } },
            { id = 1281342, name = "Endless Codex of Blooming Light",         source = "vendor",  sourceInfo = "Caeris Fairdawn, Eversong Woods",  priority = 1, waypoint = LOC.CaerisFairdawn, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1281348, name = "Endless Codex of Nature's Grace",         source = "vendor",  sourceInfo = "Magovu, Zul'Aman",                 priority = 1, waypoint = LOC.Magovu, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1281349, name = "Endless Codex of the Voidtouched",        source = "vendor",  sourceInfo = "Void Researcher Anomander",        priority = 1, waypoint = LOC.Anomander, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1246909, name = "Self-Pouring Thalassian Sunwine",         source = "vendor",  sourceInfo = "Neriv, Eversong Woods",            priority = 1, waypoint = LOC.Neriv, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 } } },
            { id = 1246907, name = "Spellbound Tome of Thalassian Magics",    source = "vendor",  sourceInfo = "Caeris Fairdawn, Eversong Woods",  priority = 1, waypoint = LOC.CaerisFairdawn, cost = { currency = { MC.CURRENCY.EnchantingMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1246908, name = "Rootflame Campfire",                      source = "drop",    sourceInfo = "Master Tailor's Surplus Reagents",  priority = 4, dropInfo = { rate = "~20%" } },
            { id = 1246903, name = "Ren'dorei Postal Repository",            source = "drop",    sourceInfo = "Voidstorm (Treasure Drop)",         priority = 4 },
        },
    },
}
