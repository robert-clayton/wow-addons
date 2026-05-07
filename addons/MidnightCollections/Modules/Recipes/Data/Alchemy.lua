local _, MC = ...

local LOC = MC.LOC

MC.AlchemyRecipes = {
    {
        name = "Potions",
        recipes = {
            { id = 1230866, name = "Silvermoon Health Potion",     source = "trainer",        sourceInfo = "Camberon (Skill 1)",              priority = 1, waypoint = LOC.Camberon },
            { id = 1230886, name = "Enlightenment Tonic",          source = "trainer",        sourceInfo = "Camberon (Skill 5)",              priority = 1, waypoint = LOC.Camberon },
            { id = 1230854, name = "Entropic Extract",             source = "trainer",        sourceInfo = "Camberon (Skill 5)",              priority = 1, waypoint = LOC.Camberon },
            { id = 1230855, name = "Composite Flora",              source = "trainer",        sourceInfo = "Camberon (Skill 10)",             priority = 1, waypoint = LOC.Camberon },
            { id = 1230868, name = "Refreshing Serum",             source = "trainer",        sourceInfo = "Camberon (Skill 15)",             priority = 1, waypoint = LOC.Camberon },
            { id = 1230864, name = "Amani Extract",                source = "vendor",         sourceInfo = "Magovu, Zul'Aman",               priority = 1, waypoint = LOC.Magovu, cost = { currency = { MC.CURRENCY.AlchemyMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1230859, name = "Potion of Recklessness",       source = "vendor",         sourceInfo = "Void Researcher Anomander",       priority = 1, waypoint = LOC.Anomander, cost = { currency = { MC.CURRENCY.AlchemyMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1230869, name = "Light's Potential",             source = "discovery",      sourceInfo = "Camberon's Cauldron",             priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230863, name = "Potion of Zealotry",           source = "discovery",      sourceInfo = "Camberon's Cauldron",             priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230865, name = "Lightfused Mana Potion",       source = "discovery",      sourceInfo = "Camberon's Cauldron",             priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230860, name = "Draught of Rampant Abandon",   source = "discovery",      sourceInfo = "Camberon's Cauldron",             priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230862, name = "Potion of Devoured Dreams",    source = "discovery",      sourceInfo = "Camberon's Cauldron",             priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230858, name = "Light's Preservation",         source = "specialization", sourceInfo = "Potion Prowess - Path of Light",  priority = 3 },
            { id = 1230867, name = "Void-Shrouded Tincture",       source = "specialization", sourceInfo = "Potion Prowess - Path of Void",   priority = 3 },
        },
    },
    {
        name = "Flasks & Phials",
        recipes = {
            { id = 1230873, name = "Haranir Phial of Perception",          source = "vendor",         sourceInfo = "Naynar, Harandar",               priority = 1, waypoint = LOC.Naynar, cost = { currency = { MC.CURRENCY.AlchemyMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1230883, name = "Vicious Thalassian Flask of Honor",    source = "vendor",         sourceInfo = "Mirvedon (7500 Honor)",          priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1230877, name = "Flask of the Blood Knights",           source = "discovery",      sourceInfo = "Camberon's Cauldron",            priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230876, name = "Flask of the Magisters",              source = "discovery",      sourceInfo = "Camberon's Cauldron",            priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230878, name = "Flask of the Shattered Sun",          source = "discovery",      sourceInfo = "Camberon's Cauldron",            priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230872, name = "Haranir Phial of Ingenuity",          source = "discovery",      sourceInfo = "Camberon's Cauldron",            priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230875, name = "Flask of Thalassian Resistance",      source = "specialization", sourceInfo = "Fluent in Flasks",               priority = 3 },
            { id = 1230870, name = "Haranir Phial of Finesse",           source = "specialization", sourceInfo = "Fluent in Flasks - Haranir Secrets", priority = 3 },
            { id = 1230874, name = "Cauldron of Sin'dorei Flasks",        source = "specialization", sourceInfo = "Fluent in Flasks (30 pts)",      priority = 3 },
        },
    },
    {
        name = "Transmutations",
        recipes = {
            { id = 1230887, name = "Transmute: Mote of Wild Magic",    source = "trainer",        sourceInfo = "Camberon (Skill 5)",                    priority = 1, waypoint = LOC.Camberon },
            { id = 1230889, name = "Transmute: Mote of Primal Energy", source = "discovery",      sourceInfo = "Camberon's Cauldron",                   priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230890, name = "Transmute: Mote of Light",         source = "discovery",      sourceInfo = "Camberon's Cauldron",                   priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230888, name = "Transmute: Mote of Pure Void",     source = "discovery",      sourceInfo = "Camberon's Cauldron",                   priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230892, name = "Bouquet of Herbs",                 source = "discovery",      sourceInfo = "Camberon's Cauldron",                   priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230893, name = "School of Gems",                   source = "discovery",      sourceInfo = "Camberon's Cauldron",                   priority = 2, waypoint = LOC.CamberonsCauldron },
            { id = 1230891, name = "Box of Rocks",                     source = "specialization", sourceInfo = "Transmutation Authority",                priority = 3 },
            { id = 1230856, name = "Wondrous Synergist",               source = "specialization", sourceInfo = "Transmutation Authority - Synthesis Synergy", priority = 3 },
        },
    },
    {
        name = "Alchemist Stones",
        recipes = {
            { id = 1230861, name = "Primal Philosopher's Stone",   source = "discovery",      sourceInfo = "Camberon's Cauldron",            priority = 2, waypoint = LOC.CamberonsCauldron },
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
            { id = 1233137, name = "Haranir Preserving Agents",    source = "vendor", sourceInfo = "Lyrendal, Silvermoon City", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.AlchemyMoxie, 150 } } },
            { id = 1233133, name = "Rootbound Vat",                source = "vendor", sourceInfo = "Naynar, Harandar",          priority = 1, waypoint = LOC.Naynar, cost = { currency = { MC.CURRENCY.AlchemyMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1233135, name = "Sunsmoke Censer",              source = "vendor", sourceInfo = "Lyrendal, Silvermoon City", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.AlchemyMoxie, 150 } } },
            { id = 1233132, name = "Entropic Illuminant",          source = "drop",   sourceInfo = "Mysterious Domanaar Vessel", priority = 4, dropInfo = { rate = "~0.2%" } },
            { id = 1233136, name = "Riftstone",                    source = "drop",   sourceInfo = "Heavy Trunk (Delves)",      priority = 4 },
            { id = 1233138, name = "Silvermoon Spire Fountain",    source = "drop",   sourceInfo = "Nemesis Strongbox",         priority = 4, dropInfo = { rate = "~0.1%" } },
        },
    },
}
