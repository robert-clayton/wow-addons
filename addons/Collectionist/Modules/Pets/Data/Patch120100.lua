local _, MC = ...
local T = MC.SCORE_TIERS

local COILED_ISLE = MC.MAP.CoiledIsle
local VAULTS_OF_ATAL_UTEK = MC.MAP.VaultsOfAtalUtek

-- 12.1 Family Battler chains (continue the pre-patch series in Pets.lua).
-- Criterion order verified against CriteriaTree OrderIndex: the 10 family
-- sub-achievements are alphabetical.
local FAMILY_BATTLER_OUTLAND_TASKS = {
    intro = "Defeat all 10 Outland pet families.",
    tasks = {
        { achievementID = 62460, criteriaIndex = 1,  label = "Aquatic Battler of Outland" },
        { achievementID = 62460, criteriaIndex = 2,  label = "Beast Battler of Outland" },
        { achievementID = 62460, criteriaIndex = 3,  label = "Critter Battler of Outland" },
        { achievementID = 62460, criteriaIndex = 4,  label = "Dragonkin Battler of Outland" },
        { achievementID = 62460, criteriaIndex = 5,  label = "Elemental Battler of Outland" },
        { achievementID = 62460, criteriaIndex = 6,  label = "Flying Battler of Outland" },
        { achievementID = 62460, criteriaIndex = 7,  label = "Humanoid Battler of Outland" },
        { achievementID = 62460, criteriaIndex = 8,  label = "Magic Battler of Outland" },
        { achievementID = 62460, criteriaIndex = 9,  label = "Mechanical Battler of Outland" },
        { achievementID = 62460, criteriaIndex = 10, label = "Undead Battler of Outland" },
    },
}

local FAMILY_BATTLER_CATACLYSM_TASKS = {
    intro = "Defeat all 10 Cataclysm pet families.",
    tasks = {
        { achievementID = 62461, criteriaIndex = 1,  label = "Aquatic Battler of Cataclysm" },
        { achievementID = 62461, criteriaIndex = 2,  label = "Beast Battler of Cataclysm" },
        { achievementID = 62461, criteriaIndex = 3,  label = "Critter Battler of Cataclysm" },
        { achievementID = 62461, criteriaIndex = 4,  label = "Dragonkin Battler of Cataclysm" },
        { achievementID = 62461, criteriaIndex = 5,  label = "Elemental Battler of Cataclysm" },
        { achievementID = 62461, criteriaIndex = 6,  label = "Flying Battler of Cataclysm" },
        { achievementID = 62461, criteriaIndex = 7,  label = "Humanoid Battler of Cataclysm" },
        { achievementID = 62461, criteriaIndex = 8,  label = "Magic Battler of Cataclysm" },
        { achievementID = 62461, criteriaIndex = 9,  label = "Mechanical Battler of Cataclysm" },
        { achievementID = 62461, criteriaIndex = 10, label = "Undead Battler of Cataclysm" },
    },
}

MC.RegisterContent("midnight", "pets", {
    {
        source = "wild",
        pets = {
            { speciesID = 5035, itemID = 270248, npcID = 262248, name = "Autumn Snapling",
              petType = 8, source = "wild", sourceInfo = "One-click capture on the Coiled Isle",
              canBattle = false, waypoint = { COILED_ISLE, 0.663, 0.626, "Autumn Snapling" }, zone = "The Coiled Isle" },
            { speciesID = 5031, itemID = 270254, npcID = 262247, name = "Caustic Writhling",
              petType = 8, source = "wild", sourceInfo = "One-click capture in the Vaults of Atal'Utek",
              canBattle = false, waypoint = { VAULTS_OF_ATAL_UTEK, 0.381, 0.307, "Caustic Writhling" }, zone = "Vaults of Atal'Utek" },
            { speciesID = 5029, itemID = 270249, npcID = 262226, name = "Cursed Spawn",
              petType = 8, source = "wild", sourceInfo = "One-click capture on the Coiled Isle",
              canBattle = false, waypoint = { COILED_ISLE, 0.441, 0.466, "Cursed Spawn" }, zone = "The Coiled Isle" },
            { speciesID = 5030, itemID = 270253, npcID = 262246, name = "Jaundiced Slitherer",
              petType = 8, source = "wild", sourceInfo = "One-click capture on the Coiled Isle",
              canBattle = false, waypoint = { COILED_ISLE, 0.499, 0.558, "Jaundiced Slitherer" }, zone = "The Coiled Isle" },
            { speciesID = 5032, itemID = 270252, npcID = 262245, name = "Nightfur Kapara",
              petType = 5, source = "wild", sourceInfo = "One-click capture on the Coiled Isle",
              canBattle = false, waypoint = { COILED_ISLE, 0.620, 0.819, "Nightfur Kapara" }, zone = "The Coiled Isle" },
            { speciesID = 5028, itemID = 270214, npcID = 262222, name = "Poisoned Parasite",
              petType = 8, source = "wild", sourceInfo = "One-click capture on the Coiled Isle",
              canBattle = false, waypoint = { COILED_ISLE, 0.7183, 0.6484, "Poisoned Parasite" }, zone = "The Coiled Isle" },
            { speciesID = 5033, itemID = 270251, npcID = 262244, name = "Sleek Snakebiter",
              petType = 5, source = "wild", sourceInfo = "One-click capture on the Coiled Isle",
              canBattle = false, waypoint = { COILED_ISLE, 0.654, 0.498, "Sleek Snakebiter" }, zone = "The Coiled Isle" },
            { speciesID = 5034, itemID = 270250, npcID = 262243, name = "Steady Croakfrog",
              petType = 9, source = "wild", sourceInfo = "One-click capture on the Coiled Isle",
              canBattle = false, waypoint = { COILED_ISLE, 0.7237, 0.5502, "Steady Croakfrog" }, zone = "The Coiled Isle" },
        },
    },
    {
        source = "vendor",
        pets = {
            { speciesID = 5071, itemID = 275631, npcID = 266464, name = "Corrosive Writhling",
              petType = 8, source = "vendor", sourceInfo = "Skull of Er'inye - 5,000 Corrosive Coin",
              canBattle = false, waypoint = { VAULTS_OF_ATAL_UTEK, 0.512, 0.624, "Skull of Er'inye" }, zone = "Vaults of Atal'Utek",
              cost = { currency = { 3448, 5000 } }, score = T.medium },
            { speciesID = 5072, itemID = 275632, npcID = 266469, name = "Volatile Venomfang",
              petType = 8, source = "vendor", sourceInfo = "Skull of Er'inye - 5,000 Corrosive Coin",
              canBattle = false, waypoint = { VAULTS_OF_ATAL_UTEK, 0.512, 0.624, "Skull of Er'inye" }, zone = "Vaults of Atal'Utek",
              cost = { currency = { 3448, 5000 } }, score = T.medium },
            { speciesID = 5070, itemID = 275020, npcID = 265786, name = "Venom Elemental",
              petType = 7, source = "vendor", sourceInfo = "Second Mate Sluggs, 100 gold",
              canBattle = false, waypoint = { COILED_ISLE, 0.516, 0.498, "Second Mate Sluggs" }, zone = "The Coiled Isle",
              cost = { gold = 1000000 },
              renown = { factionID = MC.FACTION.CaptainTokka, level = 4,
                         factionName = "Captain Tokka" } },
            { speciesID = 5093, itemID = 276248, npcID = 267805, name = "Snek'zali",
              petType = 8, source = "vendor", sourceInfo = "Jan'sari the Watchful",
              canBattle = false, waypoint = { COILED_ISLE, 0.588, 0.450, "Jan'sari the Watchful" }, zone = "The Coiled Isle",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } },
              renown = { factionID = MC.FACTION.ZuljarrasForces, level = 12, factionName = "Zul'Jarra's Forces" }, score = T.medium },
            { speciesID = 5078, itemID = 275704, npcID = 266835, name = "Preyhunter's Riftbreaker",
              petType = 10, source = "vendor", sourceInfo = "Construct V'anore",
              canBattle = true, waypoint = MC.LOC.ConstructVanore, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 1200 } },
              score = T.long,
              renown = { factionID = MC.FACTION.PreyhuntersJourney, level = 8,
                         factionName = "Preyhunter's Journey" } },
            { speciesID = 5076, itemID = 275702, npcID = 266833, name = "Preyhunter's Prismguard",
              petType = 10, source = "vendor", sourceInfo = "Construct V'anore",
              canBattle = true, waypoint = MC.LOC.ConstructVanore, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 1200 } },
              score = T.long,
              renown = { factionID = MC.FACTION.PreyhuntersJourney, level = 8,
                         factionName = "Preyhunter's Journey" } },
        },
    },
    {
        source = "drop",
        pets = {
            { speciesID = 5137, itemID = 280540, name = "Lil' Mon",
              petType = 8, source = "drop", sourceInfo = "Big Mon",
              canBattle = false, zone = "The Coiled Isle",
              dropInfo = { mob = "Big Mon", zone = "The Coiled Isle" }, waypoint = { 2512, 0.6980, 0.6350, "Lil' Mon" } },
            { speciesID = 5092, itemID = 276234, name = "Vibrant Venomfang",
              petType = 8, source = "drop", sourceInfo = "Wriggling Venom-Soaked Satchel",
              canBattle = false, zone = "The Coiled Isle",
              dropInfo = { mob = "Wriggling Venom-Soaked Satchel", zone = "The Coiled Isle" } },
            { speciesID = 5125, itemID = 280305, name = "Soulcoil Remnant",
              petType = 6, source = "drop", sourceInfo = "Nek'zali the Soulcoiler, The Venomous Abyss",
              canBattle = false, zone = "The Venomous Abyss",
              dropInfo = { mob = "Nek'zali the Soulcoiler", zone = "The Venomous Abyss", boss = true },
              availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2, score = T.long },
            { speciesID = 5126, itemID = 278572, npcID = 269712, name = "Pale Hexscale",
              petType = 8, source = "drop", sourceInfo = "Ral'kala during Prey: A Ghostly Nightmare (Season 2)",
              canBattle = true, zone = "Prey",
              dropInfo = { mob = "Ral'kala", zone = "Prey: A Ghostly Nightmare", boss = true },
              availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2, score = T.long },
        },
    },
    {
        source = "quest",
        pets = {
            { speciesID = 5011, itemID = 268644, npcID = 260792, name = "Zan",
              petType = 8, source = "quest", sourceInfo = "Quest: A Little Kindness",
              canBattle = false, waypoint = { COILED_ISLE, 0.609, 0.326, "A Little Kindness" }, zone = "The Coiled Isle" },
            -- Journal name is Three-Eyed Fish; the summon item tooltip says
            -- "Blorp". Quest-giver coords unpublished, so no waypoint yet.
            { speciesID = 3526, itemID = 279483, npcID = 269295, name = "Three-Eyed Fish",
              petType = 9, source = "quest", sourceInfo = "Quest: Tipping the Scaled (Venom Trawler)",
              canBattle = true, zone = "The Coiled Isle", score = T.medium,
              renown = { factionID = MC.FACTION.CaptainTokka, level = 4,
                         factionName = "Captain Tokka" } },
        },
    },
    {
        source = "treasure",
        pets = {
            { speciesID = 5134, itemID = 280189, name = "Cauldron Concoction",
              petType = 6, source = "treasure", sourceInfo = "Discovery: Ofi's Offerings",
              canBattle = false, zone = "The Coiled Isle" },
            { speciesID = 5133, itemID = 280178, name = "Poison Dart Frog",
              petType = 8, source = "treasure", sourceInfo = "Unfortunate Scout's Satchel",
              canBattle = false, zone = "The Coiled Isle",
              dropInfo = { mob = "Unfortunate Scout's Satchel", zone = "The Coiled Isle" }, waypoint = { 2512, 0.2150, 0.6430, "Poison Dart Frog" } },
            -- Hotfix-added Aug 2026 secret (pet the Silvermoon raccoon for the
            -- Stubby Whistle). Blizzard confirmed the secret is not active
            -- yet; drop `unavailable` once it is.
            { speciesID = 5164, itemID = 282417, npcID = 273775, name = "J'imothy",
              petType = 5, source = "treasure",
              sourceInfo = "Discovery: Silvermoon City secret (not yet activated by Blizzard)",
              canBattle = false, zone = "Silvermoon City", unavailable = true },
        },
    },
    {
        source = "achievement",
        pets = {
            { speciesID = 5131, itemID = 279921, npcID = 270857, name = "Ki'clak",
              petType = 9, source = "achievement", sourceInfo = "A Stack of Snacks",
              canBattle = false, waypoint = { COILED_ISLE, 0.693, 0.523, "Ki'clak" }, zone = "The Coiled Isle",
              achievementID = 63633, score = T.medium },
            { speciesID = 5132, itemID = 280138, npcID = 271086, name = "Zesty",
              petType = 8, source = "achievement", sourceInfo = "The Coiled Isle Safari",
              canBattle = false, zone = "The Coiled Isle", achievementID = 62492, score = T.medium, waypoint = { 2512, 0.6790, 0.8150, "Zesty" } },
            { speciesID = 5130, itemID = 279387, npcID = 270425, name = "Ula'took",
              petType = 8, source = "achievement", sourceInfo = "No Egg Scramble - The Venomous Abyss",
              canBattle = false, zone = "The Venomous Abyss", achievementID = 63609,
              availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2, score = T.long },
            { speciesID = 5129, itemID = 279197, name = "Slitherfang",
              petType = 8, source = "achievement", sourceInfo = "In Case Of Emergency - Altar of Fangs",
              canBattle = false, zone = "Altar of Fangs", achievementID = 63679,
              score = T.medium },
        },
    },
    -- Family Battler rewards. Earned by completing the achievement, so they
    -- file under "achievement" like every other achievement pet -- not under
    -- Event / Promo, which reads as "you cannot get this any more".
    {
        source = "achievement",
        pets = {
            { speciesID = 5026, itemID = 270191, npcID = 262210, name = "Lil'Kruul",
              petType = 1, source = "achievement",
              sourceInfo = "|cFFFFD200Achievement: |rFamily Battler of Outland",
              canBattle = true, achievementID = 62460, taskList = FAMILY_BATTLER_OUTLAND_TASKS, score = T.long },
            { speciesID = 5027, itemID = 270211, npcID = 262220, name = "Furiostraza",
              petType = 2, source = "achievement",
              sourceInfo = "|cFFFFD200Achievement: |rFamily Battler of Cataclysm",
              canBattle = true, achievementID = 62461, taskList = FAMILY_BATTLER_CATACLYSM_TASKS, score = T.long },
        },
    },
})
