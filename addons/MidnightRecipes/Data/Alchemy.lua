local _, MR = ...

-- NPC waypoint data: { mapID, x, y, "NPC Name" }
-- Midnight uiMapIDs: Silvermoon=2393, Eversong=2395, Zul'Aman=2437, Harandar=2413, Voidstorm=2405
local NPC = {
    Camberon          = { 2393, 0.470, 0.518, "Camberon, Silvermoon City" },
    Mirvedon          = { 2393, 0.340, 0.812, "Mirvedon, Silvermoon City" },
    Lyrendal          = { 2393, 0.450, 0.554, "Lyrendal, Silvermoon City" },
    Magovu            = { 2437, 0.460, 0.659, "Magovu, Zul'Aman" },
    Naynar            = { 2413, 0.510, 0.508, "Naynar, Harandar" },
    Anomander         = { 2405, 0.526, 0.729, "Void Researcher Anomander, Voidstorm" },
    CamberonsCauldron = { 2393, 0.470, 0.520, "Camberon's Cauldron, Silvermoon City" },
}

MR.AlchemyRecipes = {
    {
        name = "Potions",
        recipes = {
            { id = 1230866, name = "Silvermoon Health Potion",     source = "trainer",        sourceInfo = "Camberon (Skill 1)",              priority = 1, waypoint = NPC.Camberon },
            { id = 1230886, name = "Enlightenment Tonic",          source = "trainer",        sourceInfo = "Camberon (Skill 5)",              priority = 1, waypoint = NPC.Camberon },
            { id = 1230854, name = "Entropic Extract",             source = "trainer",        sourceInfo = "Camberon (Skill 5)",              priority = 1, waypoint = NPC.Camberon },
            { id = 1230855, name = "Composite Flora",              source = "trainer",        sourceInfo = "Camberon (Skill 10)",             priority = 1, waypoint = NPC.Camberon },
            { id = 1230868, name = "Refreshing Serum",             source = "trainer",        sourceInfo = "Camberon (Skill 15)",             priority = 1, waypoint = NPC.Camberon },
            { id = 1230864, name = "Amani Extract",                source = "vendor",         sourceInfo = "Magovu, Zul'Aman",               priority = 1, waypoint = NPC.Magovu, cost = { currency = { 3256, 150 }, currency2 = { 3316, 1500 } } },
            { id = 1230859, name = "Potion of Recklessness",       source = "vendor",         sourceInfo = "Void Researcher Anomander",       priority = 1, waypoint = NPC.Anomander, cost = { currency = { 3256, 150 }, currency2 = { 3316, 1500 } } },
            { id = 1230869, name = "Light's Potential",             source = "discovery",      sourceInfo = "Camberon's Cauldron",             priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230863, name = "Potion of Zealotry",           source = "discovery",      sourceInfo = "Camberon's Cauldron",             priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230865, name = "Lightfused Mana Potion",       source = "discovery",      sourceInfo = "Camberon's Cauldron",             priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230860, name = "Draught of Rampant Abandon",   source = "discovery",      sourceInfo = "Camberon's Cauldron",             priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230862, name = "Potion of Devoured Dreams",    source = "discovery",      sourceInfo = "Camberon's Cauldron",             priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230858, name = "Light's Preservation",         source = "specialization", sourceInfo = "Potion Prowess - Path of Light",  priority = 3 },
            { id = 1230867, name = "Void-Shrouded Tincture",       source = "specialization", sourceInfo = "Potion Prowess - Path of Void",   priority = 3 },
        },
    },
    {
        name = "Flasks & Phials",
        recipes = {
            { id = 1230873, name = "Haranir Phial of Perception",          source = "vendor",         sourceInfo = "Naynar, Harandar",               priority = 1, waypoint = NPC.Naynar, cost = { currency = { 3256, 150 }, currency2 = { 3316, 1500 } } },
            { id = 1230883, name = "Vicious Thalassian Flask of Honor",    source = "vendor",         sourceInfo = "Mirvedon (7500 Honor)",          priority = 1, waypoint = NPC.Mirvedon, cost = { currency = { 1792, 7500 } } },
            { id = 1230877, name = "Flask of the Blood Knights",           source = "discovery",      sourceInfo = "Camberon's Cauldron",            priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230876, name = "Flask of the Magisters",              source = "discovery",      sourceInfo = "Camberon's Cauldron",            priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230878, name = "Flask of the Shattered Sun",          source = "discovery",      sourceInfo = "Camberon's Cauldron",            priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230872, name = "Haranir Phial of Ingenuity",          source = "discovery",      sourceInfo = "Camberon's Cauldron",            priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230875, name = "Flask of Thalassian Resistance",      source = "specialization", sourceInfo = "Fluent in Flasks",               priority = 3 },
            { id = 1230870, name = "Haranir Phial of Finesse",           source = "specialization", sourceInfo = "Fluent in Flasks - Haranir Secrets", priority = 3 },
            { id = 1230874, name = "Cauldron of Sin'dorei Flasks",        source = "specialization", sourceInfo = "Fluent in Flasks (30 pts)",      priority = 3 },
        },
    },
    {
        name = "Transmutations",
        recipes = {
            { id = 1230887, name = "Transmute: Mote of Wild Magic",    source = "trainer",        sourceInfo = "Camberon (Skill 5)",                    priority = 1, waypoint = NPC.Camberon },
            { id = 1230889, name = "Transmute: Mote of Primal Energy", source = "discovery",      sourceInfo = "Camberon's Cauldron",                   priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230890, name = "Transmute: Mote of Light",         source = "discovery",      sourceInfo = "Camberon's Cauldron",                   priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230888, name = "Transmute: Mote of Pure Void",     source = "discovery",      sourceInfo = "Camberon's Cauldron",                   priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230892, name = "Bouquet of Herbs",                 source = "discovery",      sourceInfo = "Camberon's Cauldron",                   priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230893, name = "School of Gems",                   source = "discovery",      sourceInfo = "Camberon's Cauldron",                   priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230891, name = "Box of Rocks",                     source = "specialization", sourceInfo = "Transmutation Authority",                priority = 3 },
            { id = 1230856, name = "Wondrous Synergist",               source = "specialization", sourceInfo = "Transmutation Authority - Synthesis Synergy", priority = 3 },
        },
    },
    {
        name = "Alchemist Stones",
        recipes = {
            { id = 1230861, name = "Primal Philosopher's Stone",   source = "discovery",      sourceInfo = "Camberon's Cauldron",            priority = 2, waypoint = NPC.CamberonsCauldron },
            { id = 1230885, name = "Magister's Alchemist Stone",   source = "specialization", sourceInfo = "Transmutation Authority (30 pts)", priority = 3 },
        },
    },
    {
        name = "Cauldrons",
        recipes = {
            { id = 1230857, name = "Voidlight Potion Cauldron", source = "specialization", sourceInfo = "Potion Prowess (30 pts)", priority = 3 },
        },
    },
    {
        name = "Housing Decor",
        recipes = {
            { id = 1233137, name = "Haranir Preserving Agents",    source = "vendor", sourceInfo = "Lyrendal, Silvermoon City", priority = 1, waypoint = NPC.Lyrendal, cost = { currency = { 3256, 150 } } },
            { id = 1233133, name = "Rootbound Vat",                source = "vendor", sourceInfo = "Naynar, Harandar",          priority = 1, waypoint = NPC.Naynar, cost = { currency = { 3256, 150 }, currency2 = { 3316, 1500 } } },
            { id = 1233135, name = "Sunsmoke Censer",              source = "vendor", sourceInfo = "Lyrendal, Silvermoon City", priority = 1, waypoint = NPC.Lyrendal, cost = { currency = { 3256, 150 } } },
            { id = 1233132, name = "Entropic Illuminant",          source = "drop",   sourceInfo = "Mysterious Domanaar Vessel", priority = 4, dropInfo = { rate = "~0.2%" } },
            { id = 1233136, name = "Riftstone",                    source = "drop",   sourceInfo = "Heavy Trunk (Delves)",      priority = 4 },
            { id = 1233138, name = "Silvermoon Spire Fountain",    source = "drop",   sourceInfo = "Nemesis Strongbox",         priority = 4, dropInfo = { rate = "~0.1%" } },
        },
    },
}
