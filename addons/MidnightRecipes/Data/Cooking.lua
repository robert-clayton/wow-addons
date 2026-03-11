local _, MR = ...

-- NPC waypoint data: { mapID, x, y, "NPC Name" }
-- Midnight uiMapIDs: Silvermoon=2393, Eversong=2395, Zul'Aman=2437, Harandar=2413, Voidstorm=2405
MR.CookingRecipes = {
    {
        name = "Starter Meals",
        recipes = {
            { id = 1226199, name = "Mana-Infused Stew",  source = "trainer", sourceInfo = "Trainer (Skill 1)",  priority = 1 },
            { id = 1226200, name = "Spiced Biscuits",     source = "trainer", sourceInfo = "Trainer (Skill 1)",  priority = 1 },
            { id = 1226201, name = "Silvermoon Standard", source = "trainer", sourceInfo = "Trainer (Skill 1)",  priority = 1 },
            { id = 1226202, name = "Forager's Medley",    source = "trainer", sourceInfo = "Trainer (Skill 1)",  priority = 1 },
            { id = 1226203, name = "Quick Sandwich",      source = "trainer", sourceInfo = "Trainer (Skill 1)",  priority = 1 },
            { id = 1226204, name = "Portable Snack",      source = "trainer", sourceInfo = "Trainer (Skill 1)",  priority = 1 },
            { id = 1226198, name = "Bloom Skewers",       source = "trainer", sourceInfo = "Trainer (Skill 10)", priority = 1 },
        },
    },
    {
        name = "Teas",
        recipes = {
            { id = 1226193, name = "Mana Lily Tea",         source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1226194, name = "Argentleaf Tea",        source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1226195, name = "Sanguithorn Tea",       source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1226196, name = "Tranquility Bloom Tea", source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1226197, name = "Azeroot Tea",           source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
        },
    },
    {
        name = "Intermediate Meals",
        recipes = {
            { id = 1226166, name = "Farstrider Rations",            source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1226187, name = "Fried Bloomtail",              source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1226188, name = "Eversong Pudding",             source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1226189, name = "Sunwell Delight",              source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1226190, name = "Felberry Figs",                source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1226191, name = "Hearthflame Supper",           source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1226192, name = "Bloodthistle-wrapped Cutlets", source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1226184, name = "Twilight Angler's Medley",     source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1226185, name = "Spellfire Filet",              source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1226186, name = "Wise Tails",                   source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
        },
    },
    {
        name = "Advanced Meals",
        recipes = {
            { id = 1226176, name = "Buttered Root Crab",     source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1226177, name = "Glitter Skewers",        source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1226178, name = "Null and Void Plate",    source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1226179, name = "Sun-Seared Lumifin",     source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1226180, name = "Void-Kissed Fish Rolls", source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1226181, name = "Warped Wise Wings",      source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1226182, name = "Fel-Kissed Filet",       source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1226183, name = "Arcano Cutlets",         source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1226172, name = "Braised Blood Hunter",   source = "trainer", sourceInfo = "Trainer (Skill 65)", priority = 1 },
            { id = 1226173, name = "Crimson Calamari",       source = "trainer", sourceInfo = "Trainer (Skill 65)", priority = 1 },
            { id = 1226174, name = "Tasty Smoked Tetra",     source = "trainer", sourceInfo = "Trainer (Skill 65)", priority = 1 },
        },
    },
    {
        name = "Master Meals",
        recipes = {
            { id = 1226167, name = "Hearty Food",            source = "trainer", sourceInfo = "Trainer (Skill 35)", priority = 1 },
            { id = 1226170, name = "Champion's Bento",       source = "trainer", sourceInfo = "Trainer (Skill 65)", priority = 1 },
            { id = 1226171, name = "Royal Roast",            source = "trainer", sourceInfo = "Trainer (Skill 65)", priority = 1 },
            { id = 1259654, name = "Impossibly Royal Roast", source = "trainer", sourceInfo = "Trainer (Skill 65)", priority = 1 },
            { id = 1259660, name = "Flora Frenzy",           source = "quest",   sourceInfo = "Quest: Gomphusta (Harandar)", priority = 4 },
        },
    },
    {
        name = "Feasts",
        recipes = {
            { id = 1232247, name = "Hearty Feast",         source = "trainer", sourceInfo = "Trainer (Skill 80)", priority = 1 },
            { id = 1226168, name = "Quel'dorei Medley",    source = "trainer", sourceInfo = "Trainer (Skill 85)", priority = 1 },
            { id = 1226169, name = "Blooming Feast",       source = "trainer", sourceInfo = "Trainer (Skill 85)", priority = 1 },
            { id = 1226175, name = "Harandar Celebration", source = "trainer", sourceInfo = "Trainer (Skill 85)", priority = 1 },
            { id = 1257796, name = "Silvermoon Parade",    source = "trainer", sourceInfo = "Trainer (Skill 85)", priority = 1 },
        },
    },
}
