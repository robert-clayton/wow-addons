local _, MC = ...

-- Current DB2 collectible gaps confirmed by source audit.
-- Generated from the exact 95-row include set.

MC.RegisterContent("vanilla", "pets", {
    { source = "drop", pets = {
        { speciesID = 57, npcID = 7547, name = "Azure Whelpling", petType = 2, source = "drop", sourceInfo = "|cFFFFD200Drop: |rWorld Drop|n|cFFFFD200Zone: |rWinterspring", zone = "Winterspring" },
        { speciesID = 232, npcID = 35396, name = "Darting Hatchling", petType = 8, source = "drop", sourceInfo = "|cFFFFD200Drop: |rDart's Nest|n|cFFFFD200Zone: |rDustwallow Marsh", zone = "Dustwallow Marsh", waypoint = { 70, 0.4650, 0.1720, "Darting Hatchling" } },
        { speciesID = 235, npcID = 35387, name = "Leaping Hatchling", petType = 8, source = "drop", sourceInfo = "|cFFFFD200Drop: |rTakk's Nest|n|cFFFFD200Zone: |rThe Barrens", zone = "Northern Barrens", waypoint = { 10, 0.6100, 0.1980, "Leaping Hatchling" } },
        { speciesID = 237, npcID = 35397, name = "Ravasaur Hatchling", petType = 8, source = "drop", sourceInfo = "|cFFFFD200Drop: |rRavasaur Matriarch's Nest|n|cFFFFD200Zone: |rUn'goro Crater", zone = "Un'Goro Crater", waypoint = { 78, 0.6200, 0.7360, "Ravasaur Hatchling" } },
        { speciesID = 286, npcID = 50586, name = "Mr. Grubbs", petType = 8, source = "drop", sourceInfo = "|cFFFFD200World Drop:|r Eastern Plaguelands (requires Fiona's Lucky Charm)", zone = "Eastern Plaguelands" },
    } },
    { source = "quest", pets = {
        { speciesID = 220, npcID = 34278, name = "Withers", petType = 7, source = "quest", sourceInfo = "|cFFFFD200Quest: |rRemembrance of Auberdine|n|cFFFFD200Zone: |rDarkshore", zone = "Darkshore", waypoint = { { 62, 0.5010, 0.1950, "Withers" }, { 62, 0.5720, 0.3380, "Withers" } } },
        { speciesID = 287, npcID = 51632, name = "Tiny Flamefly", petType = 3, source = "quest", sourceInfo = "|cFFFFD200Quest:|r SEVEN! YUP!, Not Fireflies, Flameflies|n|cFFFFD200Zone:|r Burning Steppes|n", waypoint = { { 36, 0.5490, 0.2250, "Tiny Flamefly" }, { 36, 0.7180, 0.6790, "Tiny Flamefly" } } },
        { speciesID = 291, npcID = 51090, name = "Singing Sunflower", petType = 7, source = "quest", sourceInfo = "|cFFFFD200Quest:|r Lawn of the Dead|n|cFFFFD200Zone:|r Hillsbrad Foothills|n", zone = "Hillsbrad Foothills", waypoint = { 25, 0.3350, 0.4930, "Singing Sunflower" } },
        { speciesID = 301, npcID = 52226, name = "Panther Cub", petType = 8, source = "quest", sourceInfo = "|cFFFFD200Quest:|r Some Good Will Come|n|cFFFFD200Zone:|r Northern Stranglethorn|n|n", zone = "Northern Stranglethorn", waypoint = { 50, 0.7610, 0.6670, "Panther Cub" } },
        { speciesID = 307, npcID = 52894, name = "Lashtail Hatchling", petType = 8, source = "quest", sourceInfo = "|cFFFFD200Quest: |rAn Old Friend|n|cFFFFD200Zone: |rZul'Gurub" },
        { speciesID = 331, npcID = 54539, name = "Alliance Balloon", petType = 3, source = "quest", sourceInfo = "|cFFFFD200Quest:|r Blown Away|n|cFFFFD200Zone:|r Stormwind", zone = "Stormwind City", waypoint = { 84, 0.5890, 0.5270, "Alliance Balloon" } },
        { speciesID = 332, npcID = 54541, name = "Horde Balloon", petType = 3, source = "quest", sourceInfo = "|cFFFFD200Quest:|r Blown Away|n|cFFFFD200Zone:|r Orgrimmar|n", zone = "Orgrimmar", waypoint = { 85, 0.4810, 0.4680, "Horde Balloon" } },
    } },
    { source = "vendor", pets = {
        { speciesID = 629, npcID = 63097, name = "Shore Crawler", petType = 9, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rMatty|n|cFFFFD200Zone: |rOrgrimmar", zone = "Orgrimmar", waypoint = { 85, 0.5260, 0.5930, "Shore Crawler" } },
        { speciesID = 630, npcID = 63098, name = "Gilnean Raven", petType = 3, source = "vendor", sourceInfo = "|cFFFFD200Vendor:|r Will Larsons|n|cFFFFD200Zone:|r Darkshore", zone = "Stormwind City", waypoint = { 84, 0.6940, 0.2440, "Gilnean Raven" } },
        { speciesID = 1237, npcID = 71159, name = "Gahz'rooki", petType = 9, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rRavika|n|cFFFFD200Zone: |rDurotar|n|cFFFFD200Cost: |r1|TINTERFACE\\ICONS\\inv_drink_31_embalmingfluid:0|t|n|n|cFFFFD200Vendor: |rTenuki|n|cFFFFD200Zone: |rDurotar|n|cFFFFD200Cost: |r1|TINTERFACE\\ICONS\\inv_drink_31_embalmingfluid:0|t", zone = "Northern Barrens" },
    } },
})

MC.RegisterContent("tbc", "pets", {
    { source = "drop", pets = {
        { speciesID = 187, npcID = 28513, name = "Vampiric Batling", petType = 4, source = "drop", sourceInfo = "|cFFFFD200Drop: |rPrince Tenris Mirkblood|n|cFFFFD200Zone: |rKarazhan", unavailable = true },
    } },
})

MC.RegisterContent("wrath", "pets", {
    { source = "achievement", pets = {
        { speciesID = 160, npcID = 23274, name = "Stinker", petType = 5, source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rShop Smart, Shop Pet...Smart|n|cFFFFD200Category: |rPet Battles" },
        { speciesID = 202, npcID = 32841, name = "Baby Blizzard Bear", petType = 8, source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rWoW's 4th Anniversary|n|cFFFFD200Category: |rFeats of Strength", zone = "Tanaris", unavailable = true, waypoint = { 71, 0.6290, 0.5110, "Baby Blizzard Bear" } },
        { speciesID = 203, npcID = 32939, name = "Little Fawn", petType = 5, source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rLil' Game Hunter|n|cFFFFD200Category: |rPet Battles" },
        { speciesID = 243, npcID = 36607, name = "Onyxian Whelpling", petType = 2, source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rWoW's 5th Anniversary|n|cFFFFD200Category: |rFeats of Strength", zone = "Tanaris", unavailable = true, waypoint = { 71, 0.6290, 0.5110, "Onyxian Whelpling" } },
        { speciesID = 250, npcID = 37865, name = "Perky Pug", petType = 5, source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rLooking For Multitudes|n|cFFFFD200Category: |rDungeons & Raids" },
    } },
    { source = "drop", pets = {
        { speciesID = 194, npcID = 32589, name = "Tickbird Hatchling", petType = 3, source = "drop", sourceInfo = "|cFFFFD200Drop: |rMysterious Egg", zone = "Sholazar Basin" },
        { speciesID = 195, npcID = 32590, name = "White Tickbird Hatchling", petType = 3, source = "drop", sourceInfo = "|cFFFFD200Drop: |rMysterious Egg", zone = "Sholazar Basin" },
        { speciesID = 196, npcID = 32592, name = "Proto-Drake Whelp", petType = 2, source = "drop", sourceInfo = "|cFFFFD200Drop: |rMysterious Egg", zone = "Sholazar Basin" },
        { speciesID = 197, npcID = 32591, name = "Cobra Hatchling", petType = 8, source = "drop", sourceInfo = "|cFFFFD200Drop: |rMysterious Egg", zone = "Sholazar Basin" },
    } },
    { source = "event", pets = {
        { speciesID = 166, npcID = 24753, name = "Pint-Sized Pink Pachyderm", petType = 5, source = "event", sourceInfo = "|cFFFFD200World Event:|r Brewfest|n|cFFFFD200Vendor: |rBelbi Quikswitch|n|cFFFFD200Zone: |rDun Morogh|n|cFFFFD200Cost: |r100|TINTERFACE\\ICONS\\INV_Misc_Coin_01:0|t|n|n|cFFFFD200Vendor: |rBliz Fixwidget|n|cFFFFD200Zone: |rDurotar|n|cFFFFD200Cost: |r100|TINTERFACE\\ICONS\\INV_Misc_Coin_01:0|t", waypoint = { { 1, 0.4040, 0.1710, "Pint-Sized Pink Pachyderm" }, { 27, 0.5620, 0.3650, "Pint-Sized Pink Pachyderm" } } },
        { speciesID = 200, npcID = 32791, name = "Spring Rabbit", petType = 5, source = "event", sourceInfo = "|cFFFFD200World Event:|r Noblegarden|n|cFFFFD200Vendor: |rNoblegarden Merchant|n|cFFFFD200Cost: |r100|TINTERFACE\\ICONS\\Achievement_Noblegarden_Chocolate_Egg:0|t", waypoint = { { 1, 0.5191, 0.4187, "Spring Rabbit" }, { 27, 0.5411, 0.5081, "Spring Rabbit" } } },
        { speciesID = 201, npcID = 32818, name = "Plump Turkey", petType = 3, source = "event", sourceInfo = "|cFFFFD200World Event:|r Pilgrim's Bounty" },
        { speciesID = 225, npcID = 33530, name = "Curious Oracle Hatchling", petType = 1, source = "event", sourceInfo = "|cFFFFD200World Event:|r Children's Week", zone = "Dalaran", waypoint = { 125, 0.4937, 0.6326, "Curious Oracle Hatchling" } },
        { speciesID = 226, npcID = 33529, name = "Curious Wolvar Pup", petType = 1, source = "event", sourceInfo = "|cFFFFD200World Event:|r Children's Week", waypoint = { { 84, 0.5800, 0.5680, "Curious Wolvar Pup" }, { 85, 0.5800, 0.5680, "Curious Wolvar Pup" }, { 125, 0.4937, 0.6326, "Curious Wolvar Pup" }, { 2339, 0.5580, 0.2640, "Curious Wolvar Pup" } } },
        { speciesID = 251, npcID = 38374, name = "Toxic Wasteling", petType = 6, source = "event", sourceInfo = "|cFFFFD200World Event:|r Love is in the Air" },
        { speciesID = 253, npcID = 40198, name = "Frigid Frostling", petType = 7, source = "event", sourceInfo = "|cFFFFD200World Event:|r Midsummer Fire Festival" },
    } },
    { source = "profession", pets = {
        { speciesID = 211, npcID = 33226, name = "Strand Crawler", petType = 9, source = "profession", sourceInfo = "|cFFFFD200Profession: |rFishing|n|cFFFFD200Zone: |rNorthrend, Stormwind, Orgrimmar" },
    } },
    { source = "vendor", pets = {
        { speciesID = 198, npcID = 32595, name = "Pengu", petType = 9, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rSairuk|n|cFFFFD200Zone: |rDragonblight|n|cFFFFD200Faction: |rThe Kalu'ak - Exalted|n|cFFFFD200Cost: |r12|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t|n|n|cFFFFD200Vendor: |rTanaika|n|cFFFFD200Zone: |rHowling Fjord|n|cFFFFD200Faction: |rThe Kalu'ak - Exalted|n|cFFFFD200Cost: |r12|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t", zone = "Dragonblight", waypoint = { 115, 0.4860, 0.7560, "Pengu" } },
        { speciesID = 236, npcID = 35399, name = "Obsidian Hatchling", petType = 8, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rBreanni|n|cFFFFD200Zone: |rCrystalsong Forest|n|cFFFFD200Cost: |r50|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t", zone = "Dalaran", waypoint = { 125, 0.5870, 0.3920, "Obsidian Hatchling" } },
        { speciesID = 254, npcID = 40295, name = "Blue Clockwork Rocket Bot", petType = 10, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rWorld Vendors|n|cFFFFD200Cost: |r50|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t", waypoint = { { 84, 0.5660, 0.6760, "Blue Clockwork Rocket Bot" }, { 85, 0.5780, 0.5100, "Blue Clockwork Rocket Bot" }, { 125, 0.4480, 0.4630, "Blue Clockwork Rocket Bot" }, { 535, 0.4520, 0.3880, "Blue Clockwork Rocket Bot" } } },
    } },
})

MC.RegisterContent("cata", "pets", {
    { source = "achievement", pets = {
        { speciesID = 255, npcID = 40624, name = "Celestial Dragon", petType = 2, source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rLittlest Pet Shop|n|cFFFFD200Category: |rPet Battles" },
        { speciesID = 323, npcID = 54227, name = "Nuts", petType = 5, source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rPetting Zoo|n|cFFFFD200Category: |rPet Battles" },
        { speciesID = 325, npcID = 54374, name = "Brilliant Kaliri", petType = 3, source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rMenagerie|n|cFFFFD200Category: |rPet Battles" },
    } },
    { source = "event", pets = {
        { speciesID = 289, npcID = 51635, name = "Scooter the Snail", petType = 5, source = "event", sourceInfo = "|cFFFFD200World Event:|r Children's Week", waypoint = { { 84, 0.5631, 0.5399, "Scooter the Snail" }, { 84, 0.5800, 0.5680, "Scooter the Snail" }, { 85, 0.5793, 0.5763, "Scooter the Snail" }, { 85, 0.5800, 0.5680, "Scooter the Snail" }, { 2339, 0.5580, 0.2640, "Scooter the Snail" } } },
        { speciesID = 308, npcID = 53048, name = "Legs", petType = 6, source = "event", sourceInfo = "|cFFFFD200World Event:|r Children's Week", waypoint = { { 84, 0.5800, 0.5680, "Legs" }, { 85, 0.5800, 0.5680, "Legs" }, { 111, 0.7508, 0.4787, "Legs" }, { 2339, 0.5580, 0.2640, "Legs" } } },
        { speciesID = 319, npcID = 53884, name = "Feline Familiar", petType = 8, source = "event", sourceInfo = "|cFFFFD200World Event:|r Hallow's End|n|cFFFFD200Vendor: |rWoim|n|cFFFFD200Zone: |rTirisfal Glades|n|cFFFFD200Cost: |r150|TINTERFACE\\ICONS\\achievement_halloween_candy_01:0|t|n|n|cFFFFD200Vendor: |rPippi|n|cFFFFD200Zone: |rStormwind City|n|cFFFFD200Cost: |r150|TINTERFACE\\ICONS\\achievement_halloween_candy_01:0|t", waypoint = { { 18, 0.6230, 0.6640, "Feline Familiar" }, { 37, 0.3190, 0.5020, "Feline Familiar" } } },
        { speciesID = 321, npcID = 54128, name = "Creepy Crate", petType = 4, source = "event", sourceInfo = "|cFFFFD200World Event:|r Hallow's End" },
        { speciesID = 337, npcID = 55215, name = "Lumpy", petType = 7, source = "event", sourceInfo = "|cFFFFD200World Event:|r Feast of Winter Veil" },
        { speciesID = 341, npcID = 55571, name = "Lunar Lantern", petType = 6, source = "event", sourceInfo = "|cFFFFD200World Event:|r Lunar Festival|n|cFFFFD200Vendor: |rValadar Starsong|n|cFFFFD200Zone: |rMoonglade|n|cFFFFD200Cost: |r50|TINTERFACE\\ICONS\\INV_Misc_ElvenCoins:0|t", zone = "Moonglade", waypoint = { 80, 0.5360, 0.3530, "Lunar Lantern" } },
        { speciesID = 342, npcID = 55574, name = "Festival Lantern", petType = 6, source = "event", sourceInfo = "|cFFFFD200World Event:|r Lunar Festival|n|cFFFFD200Vendor: |rValadar Starsong|n|cFFFFD200Zone: |rMoonglade|n|cFFFFD200Cost: |r50|TINTERFACE\\ICONS\\INV_Misc_ElvenCoins:0|t", zone = "Moonglade", waypoint = { 80, 0.5360, 0.3530, "Festival Lantern" } },
    } },
    { source = "profession", pets = {
        { speciesID = 340, npcID = 55386, name = "Sea Pony", petType = 9, source = "profession", sourceInfo = "|cFFFFD200Profession: |rFishing|n|cFFFFD200Zone: |rDarkmoon Island" },
    } },
    { source = "vendor", pets = {
        { speciesID = 270, npcID = 47944, name = "Dark Phoenix Hatchling", petType = 7, source = "vendor", sourceInfo = "|cFFFFD200Vendor:|r Guild Vendor|n|cFFFFD200Zone:|r Stormwind, Orgrimmar|n|cFFFFD200Cost: |r300|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t|n" },
        { speciesID = 272, npcID = 48242, name = "Armadillo Pup", petType = 5, source = "vendor", sourceInfo = "|cFFFFD200Vendor:|r Guild Vendor|n|cFFFFD200Zone:|r Stormwind, Orgrimmar|n|cFFFFD200Cost: |r300|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t|n" },
        { speciesID = 280, npcID = 49586, name = "Guild Page", petType = 1, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rGuild Vendor|n|cFFFFD200Zone:|r Stormwind, Orgrimmar|n|cFFFFD200Cost: |r300|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t|n|cFFFFD200Cooldown: |r8 hrs" },
        { speciesID = 281, npcID = 49588, name = "Guild Page", petType = 1, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rGuild Vendor|n|cFFFFD200Zone:|r Stormwind, Orgrimmar|n|cFFFFD200Cost: |r300|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t|n|cFFFFD200Cooldown: |r8 hrs" },
        { speciesID = 282, npcID = 49587, name = "Guild Herald", petType = 1, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rGuild Vendor|n|cFFFFD200Zone:|r Stormwind, Orgrimmar|n|cFFFFD200Cost: |r500|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t|n|cFFFFD200Cooldown: |r4 hrs" },
        { speciesID = 283, npcID = 49590, name = "Guild Herald", petType = 1, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rGuild Vendor|n|cFFFFD200Zone:|r Stormwind, Orgrimmar|n|cFFFFD200Cost: |r500|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t|n|cFFFFD200Cooldown: |r4 hrs" },
        { speciesID = 318, npcID = 53661, name = "Crimson Lasher", petType = 7, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rAyla Shadowstorm|n|cFFFFD200Zone: |rMolten Front|n|cFFFFD200Cost: |r1500|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t", zone = "Molten Front", waypoint = { 338, 0.4410, 0.8635, "Crimson Lasher" } },
        { speciesID = 320, npcID = 54027, name = "Lil' Tarecgosa", petType = 2, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rGuild Vendor|n|cFFFFD200Zone:|r Stormwind, Orgrimmar|n|cFFFFD200Cost: |r1500|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t|n" },
        { speciesID = 330, npcID = 54491, name = "Darkmoon Monkey", petType = 8, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rLhara|n|cFFFFD200Zone: |rDarkmoon Island|n|cFFFFD200Cost: |r90|TINTERFACE\\ICONS\\inv_misc_ticket_darkmoon_01:0|t |n", zone = "Darkmoon Island", waypoint = { 407, 0.4800, 0.6950, "Darkmoon Monkey" } },
        { speciesID = 335, npcID = 54487, name = "Darkmoon Turtle", petType = 9, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rLhara|n|cFFFFD200Zone: |rDarkmoon Island|n|cFFFFD200Cost: |r90|TINTERFACE\\ICONS\\inv_misc_ticket_darkmoon_01:0|t ", zone = "Darkmoon Island", waypoint = { 407, 0.4800, 0.6950, "Darkmoon Turtle" } },
        { speciesID = 336, npcID = 55187, name = "Darkmoon Balloon", petType = 3, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rLhara|n|cFFFFD200Zone: |rDarkmoon Island|n|cFFFFD200Cost: |r90|TINTERFACE\\ICONS\\inv_misc_ticket_darkmoon_01:0|t |n", zone = "Darkmoon Island", waypoint = { { 407, 0.4770, 0.6470, "Darkmoon Balloon" }, { 407, 0.4800, 0.6950, "Darkmoon Balloon" }, { 407, 0.4930, 0.7840, "Darkmoon Balloon" } } },
        { speciesID = 338, npcID = 55356, name = "Darkmoon Tonk", petType = 10, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rLhara|n|cFFFFD200Zone: |rDarkmoon Island|n|cFFFFD200Cost: |r90|TINTERFACE\\ICONS\\inv_misc_ticket_darkmoon_01:0|t ", zone = "Darkmoon Island", waypoint = { 407, 0.4800, 0.6950, "Darkmoon Tonk" } },
        { speciesID = 339, npcID = 55367, name = "Darkmoon Zeppelin", petType = 10, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rLhara|n|cFFFFD200Zone: |rDarkmoon Island|n|cFFFFD200Cost: |r90|TINTERFACE\\ICONS\\inv_misc_ticket_darkmoon_01:0|t ", zone = "Darkmoon Island", waypoint = { 407, 0.4800, 0.6950, "Darkmoon Zeppelin" } },
        { speciesID = 343, npcID = 56031, name = "Darkmoon Cub", petType = 8, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rLhara|n|cFFFFD200Zone: |rDarkmoon Island|n|cFFFFD200Cost: |r90|TINTERFACE\\ICONS\\inv_misc_ticket_darkmoon_01:0|t |n", zone = "Darkmoon Island", waypoint = { 407, 0.4800, 0.6950, "Darkmoon Cub" } },
        { speciesID = 344, npcID = 56082, name = "Green Balloon", petType = 3, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rCarl Goodup|n|cFFFFD200Zone: |rDarkmoon Island|n|cFFFFD200Cost: |r10|TINTERFACE\\MONEYFRAME\\UI-SILVERICON.BLP:0|t" },
        { speciesID = 345, npcID = 56083, name = "Yellow Balloon", petType = 3, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rCarl Goodup|n|cFFFFD200Zone: |rDarkmoon Island|n|cFFFFD200Cost: |r10|TINTERFACE\\MONEYFRAME\\UI-SILVERICON.BLP:0|t" },
        { speciesID = 4508, npcID = 222593, name = "Emerald Sporbit", petType = 6, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rMaterialist Ophinell|n|cFFFFD200Zone: |rTwilight Highlands|n|cFFFFD200Cost: |r30|Hcurrency:3319|h|TInterface\\ICONS\\INV12_Twilight_ Blade_Cultist_Insignia.BLP:0|t|h", zone = "Twilight Highlands", waypoint = { 241, 0.4980, 0.8130, "Emerald Sporbit" } },
    } },
})

MC.RegisterContent("mop", "pets", {
    { source = "achievement", pets = {
        { speciesID = 821, npcID = 63621, name = "Feral Vermling", petType = 1, source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rGoing to Need More Leashes|n|cFFFFD200Category: |rCollect" },
        { speciesID = 855, npcID = 66491, name = "Venus", petType = 7, source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rThat's a Lot of Pet Food|n|cFFFFD200Category: |rCollect" },
        { speciesID = 856, npcID = 66450, name = "Jade Tentacle", petType = 7, source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rTime To Open a Pet Store|n|cFFFFD200Category: |rPet Battles" },
        { speciesID = 1184, npcID = 69849, name = "Stunted Direhorn", petType = 8, source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rBrutal Pet Brawler|n|cFFFFD200Category: |rBattle" },
    } },
    { source = "drop", pets = {
        { speciesID = 381, npcID = 61086, name = "Porcupette", petType = 5, source = "drop", sourceInfo = "|cFFFFD200Drop:|r Sack of Pet Supplies|n" },
        { speciesID = 848, npcID = 59358, name = "Darkmoon Rabbit", petType = 5, source = "drop", sourceInfo = "|cFFFFD200Drop: |rDarkmoon Rabbit|n|cFFFFD200Zone: |rDarkmoon Island", zone = "Darkmoon Island", waypoint = { 407, 0.7569, 0.7817, "Darkmoon Rabbit" } },
        { speciesID = 1063, npcID = 67332, name = "Darkmoon Eye", petType = 6, source = "drop", sourceInfo = "|cFFFFD200Drop:|r Darkmoon Pet Supplies|n" },
        { speciesID = 1276, npcID = 72160, name = "Moon Moon", petType = 8, source = "drop", sourceInfo = "|cFFFFD200Drop: |rMoonfang|n|cFFFFD200Zone: |rDarkmoon Island", zone = "Darkmoon Island", waypoint = { 407, 0.3965, 0.4407, "Moon Moon" } },
        { speciesID = 1320, npcID = 73011, name = "Lil' Bling", petType = 10, source = "drop", sourceInfo = "|cFFFFD200Drop:|r Blingtron Gift Package|n" },
        { speciesID = 1322, npcID = 73352, name = "Blackfuse Bombling", petType = 10, source = "drop", sourceInfo = "|cFFFFD200Drop:|r Siegecrafter Blackfuse|n|cFFFFD200Raid:|r Siege of Orgrimmar", zone = "Vale of Eternal Blossoms", waypoint = { 390, 0.7230, 0.4430, "Blackfuse Bombling" } },
        { speciesID = 1331, npcID = 73350, name = "Droplet of Y'Shaarj", petType = 7, source = "drop", sourceInfo = "|cFFFFD200Drop:|r Sha of Pride|n|cFFFFD200Raid:|r Siege of Orgrimmar|n|cFFFFD200Difficulty:|r Flexible, Normal or Heroic", zone = "Vale of Eternal Blossoms", waypoint = { 390, 0.7230, 0.4430, "Droplet of Y'Shaarj" } },
    } },
    { source = "event", pets = {
        { speciesID = 1351, npcID = 34770, name = "Macabre Marionette", petType = 4, source = "event", sourceInfo = "|cFFFFD200World Event:|r Day of the Dead", waypoint = { { 1, 0.4740, 0.1760, "Macabre Marionette" }, { 18, 0.6230, 0.6830, "Macabre Marionette" }, { 27, 0.6160, 0.3740, "Macabre Marionette" }, { 84, 0.4760, 0.2660, "Macabre Marionette" }, { 88, 0.5680, 0.1760, "Macabre Marionette" }, { 89, 0.6860, 0.4060, "Macabre Marionette" } } },
    } },
    { source = "profession", pets = {
        { speciesID = 115, npcID = 86445, name = "Land Shark", petType = 9, source = "profession", sourceInfo = "|cFFFFD200Profession:|r Fishing|n|cFFFFD200Vendor:|r Nat Pagle|n|cFFFFD200Zone:|r Garrison, Fishing Shack|n|cFFFFD200Cost:|r 50|Tinterface\\icons\\inv_misc_coin_19.blp:0|t" },
        { speciesID = 1040, npcID = 67233, name = "Imperial Silkworm", petType = 5, source = "profession", sourceInfo = "|cFFFFD200Profession:|r Mists of Pandaria Tailoring (Imperial Silk)|n" },
    } },
    { source = "quest", pets = {
        { speciesID = 1349, npcID = 73741, name = "Rotten Little Helper", petType = 1, source = "quest", sourceInfo = "|cFFFFD200World Event:|r Feast of Winter Veil|n" },
    } },
    { source = "vendor", pets = {
        { speciesID = 1061, npcID = 67319, name = "Darkmoon Hatchling", petType = 5, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rLhara|n|cFFFFD200Zone: |rDarkmoon Island|n|cFFFFD200Cost: |r90|TINTERFACE\\ICONS\\inv_misc_ticket_darkmoon_01:0|t", zone = "Darkmoon Island", waypoint = { 407, 0.4800, 0.6950, "Darkmoon Hatchling" } },
        { speciesID = 1142, npcID = 68601, name = "Clock'em", petType = 10, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rQuackenbush|n|cFFFFD200Zone: |rDeeprun Tram|n|cFFFFD200Cost: |r500|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t|n|cFFFFD200Reputation: |rBizmo's Brawlpub, Rank 3|n|n|cFFFFD200Vendor: |rPaul North|n|cFFFFD200Zone: |rBrawl'gar Arena|n|cFFFFD200Cost: |r500|TINTERFACE\\MONEYFRAME\\UI-GOLDICON.BLP:0|t|n|cFFFFD200Reputation: |rBrawl'gar Arena, Rank 3", waypoint = { { 500, 0.5430, 0.2520, "Clock'em" }, { 503, 0.5080, 0.2940, "Clock'em" } } },
        { speciesID = 1303, npcID = 72462, name = "Chi-Chi, Hatchling of Chi-Ji", petType = 3, source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rMaster Li|n|cFFFFD200Zone: |rTimeless Isle|n|cFFFFD200Cost: |r3|TINTERFACE\\ICONS\\INV_MISC_TRINKETPANDA_07:0|t", zone = "Timeless Isle", waypoint = { 554, 0.3470, 0.5960, "Chi-Chi, Hatchling of Chi-Ji" } },
    } },
    { source = "wild", pets = {
        { speciesID = 820, npcID = 64232, name = "Singing Cricket", petType = 5, source = "wild", sourceInfo = "|cFFFFD200Achievement: |rPro Pet Mob|n|cFFFFD200Category: |rPet Battle" },
    } },
})

MC.RegisterContent("wod", "pets", {
    { source = "achievement", pets = {
        { speciesID = 1384, npcID = 76873, name = "Hogs", petType = 1, source = "achievement", sourceInfo = "|cFFFFD200Achievement:|r That's Whack!|n|cFFFFD200Category:|r Darkmoon Faire" },
    } },
})

MC.RegisterContent("legion", "pets", {
    { source = "achievement", pets = {
        { speciesID = 666, npcID = 63724, name = "Micronax", petType = 10, source = "achievement", sourceInfo = "|cFFFFD200Achievement:|r Glory of the Tomb Raider|n" },
        { speciesID = 2003, npcID = 117343, name = "Hearthy", petType = 7, source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rMaster of Minions|n|cFFFFD200Category: |rCollect" },
    } },
    { source = "drop", pets = {
        { speciesID = 382, npcID = 61087, name = "Sun Darter Hatchling", petType = 2, source = "drop", sourceInfo = "|cFFFFD200Drop:|r Oddly-Colored Egg|n", zone = "Winterspring", waypoint = { 83, 0.5090, 0.0230, "Sun Darter Hatchling" } },
    } },
})

MC.RegisterContent("tww", "pets", {
    { source = "achievement", pets = {
        { speciesID = 3518, npcID = 204237, name = "Lettuce", petType = 3, source = "achievement", sourceInfo = "|cFFFFD200Achievement:|r Undermine Safari|n" },
    } },
    { source = "wild", pets = {
        { speciesID = 3361, npcID = 192363, name = "Diamond Crab", petType = 9, source = "wild", sourceInfo = "|cFFFFD200Pet Battle:|r Isle of Dorn|n", zone = "Isle of Dorn" },
        { speciesID = 3525, npcID = 204271, name = "Abyssal Lurker", petType = 9, source = "wild", sourceInfo = "|cFFFFD200Pet Battle:|r Hallowfall|n", zone = "Hallowfall" },
        { speciesID = 3543, npcID = 204341, name = "Ravenous Shalewing", petType = 7, source = "wild", sourceInfo = "|cFFFFD200Pet Battle: |rIsle of Dorn" },
        { speciesID = 3544, npcID = 204342, name = "Shalewing Devourer", petType = 7, source = "wild", sourceInfo = "|cFFFFD200Pet Battle: |rIsle of Dorn" },
        { speciesID = 3547, npcID = 204354, name = "Jade Cragviper", petType = 8, source = "wild", sourceInfo = "|cFFFFD200Pet Battle:|r The Ringing Deeps|n", zone = "The Ringing Deeps" },
        { speciesID = 3550, npcID = 204361, name = "Undermoth", petType = 3, source = "wild", sourceInfo = "|cFFFFD200Pet Battle:|r Azj-Kahet|n", zone = "Azj-Kahet" },
    } },
})

MC.RegisterContent("midnight", "pets", {
    { source = "quest", pets = {
        { speciesID = 4945, npcID = 255832, name = "Aud'rei III", petType = 7, source = "quest", sourceInfo = "|cFFFFD200Quest:|r Re-Hydra-ted|n" },
    } },
})
