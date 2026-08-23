local _, MC = ...
local T = MC.SCORE_TIERS

-- Patch 12.1: Curse of Ula'tek.  Season 2 entries are included up front so
-- players can plan for them; the UI calls out their regional unlock.

local TOKJARA_TASKS = {
    intro = "Reach Zul'jarra's Forces Renown 10, then complete Du'gal's six-day quest chain.",
    tasks = {
        { questID = 96267, label = "Day 1: Ancestral Gems", waypoint = MC.LOC.Dugal },
        { questID = 96276, label = "Day 2: Dark Charms", waypoint = MC.LOC.Dugal },
        { questID = 96273, label = "Day 3: A Balance Paid in Blood", waypoint = MC.LOC.Dugal },
        { questID = 96275, label = "Day 4: Wading In", waypoint = MC.LOC.Dugal },
        { questID = 96271, label = "Day 5: Cursed Existence", waypoint = MC.LOC.Dugal },
        { questID = 96305, label = "Day 6: The Innocent Essence", waypoint = MC.LOC.Dugal },
    },
}

MC.RegisterContent("midnight", "mounts", {
    {
        source = "renown",
        mounts = {
            { mountID = 3060, itemID = 276802, name = "Indigo Coiled Horror", source = "renown",
              sourceInfo = "Jan'sari the Watchful - 6,000 Voidlight Marl",
              waypoint = MC.LOC.Jansari, zone = "The Coiled Isle",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } },
              renown = { factionID = MC.FACTION.ZuljarrasForces, level = 17, factionName = "Zul'jarra's Forces" }, score = T.long },
            { mountID = 3054, itemID = 276551, name = "Violet-Backed Skyfang", source = "renown",
              sourceInfo = "Jan'sari the Watchful - 8,000 Voidlight Marl",
              waypoint = MC.LOC.Jansari, zone = "The Coiled Isle",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 8000 } },
              renown = { factionID = MC.FACTION.ZuljarrasForces, level = 19, factionName = "Zul'jarra's Forces" }, score = T.long },
            { mountID = 3019, itemID = 275653, name = "Sea-Dwelling Isle Serpent", source = "renown",
              sourceInfo = "Second Mate Sluggs - Bloodsworn Crew with Captain Tokka and 2,500 Coiled Filament",
              waypoint = MC.LOC.SecondMateSluggs, zone = "The Coiled Isle",
              cost = { currency = { MC.CURRENCY.CoiledFilament, 2500 } }, score = T.long },
        },
    },
    {
        source = "quest",
        mounts = {
            { mountID = 2980, itemID = 273838, name = "Spirit of Tok'jara", source = "quest",
              sourceInfo = "The Innocent Essence - six-day quest chain unlocked at Zul'jarra's Forces Renown 10",
              waypoint = MC.LOC.Dugal, zone = "Vaults of Atal'Utek", taskList = TOKJARA_TASKS, score = T.long },
        },
    },
    {
        source = "drop",
        mounts = {
            { mountID = 3061, itemID = 276803, name = "Ruby Writhe", source = "drop",
              sourceInfo = "Rare drop from Coiled Isle rares", zone = "The Coiled Isle",
              dropInfo = { mob = "Coiled Isle rares", zone = "The Coiled Isle", rate = "Rare" }, score = T.long },
            { mountID = 3051, itemID = 276549, name = "Topaz Skyfang", source = "drop",
              sourceInfo = "Rare drop from Coiled Isle rares", zone = "The Coiled Isle",
              dropInfo = { mob = "Coiled Isle rares", zone = "The Coiled Isle", rate = "Rare" }, score = T.long },
        },
    },
    {
        source = "achievement",
        mounts = {
            { mountID = 3023, itemID = 275656, name = "Auriferous Venomfang", source = "achievement",
              sourceInfo = "Treasures of the Coiled Isle", achievementID = 63359, zone = "The Coiled Isle", score = T.epic },
            { mountID = 3053, itemID = 276553, name = "Emerald Skyfang", source = "achievement",
              sourceInfo = "Pro Poison Patroller - complete 250 patrols in the Vaults", achievementID = 63653,
              zone = "Vaults of Atal'Utek", score = T.epic },
            { mountID = 3062, itemID = 276801, name = "Venomous Coiler", source = "achievement",
              sourceInfo = "Assault the Vault", achievementID = 63630, zone = "Vaults of Atal'Utek", score = T.epic },
            { mountID = 3029, itemID = 275657, name = "Apophic Soul Crusher", source = "achievement",
              sourceInfo = "Let Me Solo Him: Azta'rec", achievementID = 63333, zone = "Delves",
              availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2, score = T.epic },
            { mountID = 3063, itemID = 276881, name = "Breath of Blight", source = "achievement",
              sourceInfo = "Midnight Keystone Master: Season 2 (available at the regional Season 2 reset)", achievementID = 62447,
              availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2, score = T.epic },
            { mountID = 3064, itemID = 276882, name = "Breath of Ruin", source = "achievement",
              sourceInfo = "Midnight Keystone Legend: Season 2 (available at the regional Season 2 reset)", achievementID = 62449,
              availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2, score = T.legendary },
            { mountID = 3069, itemID = 277192, name = "Umbral Ashes", source = "achievement",
              sourceInfo = "Umbral Champion: Midnight Season 1 - top 1% Mythic+ rating at the Season 1 close (no longer earnable)",
              achievementID = 63104, unavailable = true, score = T.legendary },
        },
    },
    {
        source = "delve",
        mounts = {
            { mountID = 3043, itemID = 276162, name = "Corroded Soul Crusher", source = "delve",
              sourceInfo = "Telemancer Astrandis - 10 Voidlight Marl",
              waypoint = MC.LOC.TelemancerAstrandis, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 10 } },
              renown = { factionID = MC.FACTION.DelversJourney, level = 5,
                         factionName = "Delver's Journey" },
              score = T.long },
            { mountID = 2839, itemID = 262496, name = "Delver's Arcane Golem", source = "delve",
              sourceInfo = "Sturdy Chest in Gnarldor Isle", zone = "Gnarldor Isle",
              waypoint = { 2635, 0.6043, 0.6811, "Sturdy Chest" },
              dropInfo = { mob = "Sturdy Chest", zone = "Gnarldor Isle" }, score = T.long },
        },
    },
    {
        source = "prey",
        mounts = {
            { mountID = 3032, itemID = 275660, name = "Preyhunter's Fury", source = "prey",
              sourceInfo = "Construct V'anore - 2,250 Remnants of Anguish (Season 2)",
              waypoint = MC.LOC.ConstructVanore, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 2250 } },
              renown = { factionID = MC.FACTION.PreyhuntersJourney, level = 10,
                         factionName = "Preyhunter's Journey" }, score = T.long },
            { mountID = 3031, itemID = 275659, name = "Hexflame Reaver", source = "prey",
              sourceInfo = "Ral'kala during Prey: A Ghostly Nightmare (Season 2)",
              zone = "Prey", dropInfo = { mob = "Ral'kala", zone = "Prey: A Ghostly Nightmare" },
              availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2, score = T.epic },
        },
    },
    {
        source = "dungeon",
        mounts = {
            { mountID = 3058, itemID = 276804, name = "The Writhing Brood", source = "dungeon",
              sourceInfo = "Zul'jan, Altar of Fangs (Mythic or Mythic+)", zone = "Altar of Fangs",
              dropInfo = { mob = "Zul'jan", zone = "Altar of Fangs", boss = true, rate = "Rare" }, score = T.epic },
        },
    },
    {
        source = "raid",
        availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2,
        mounts = {
            { mountID = 3021, itemID = 275652, name = "Crimson Venomfang", source = "raid",
              sourceInfo = "Glory of the Venomous Raider (Season 2 raid)",
              achievementID = 63254, zone = "The Venomous Abyss", score = T.epic },
            { mountID = 3030, itemID = 275658, name = "Primeval Skyfriend", source = "raid",
              sourceInfo = "Mythic Ula'tek (Season 2 raid)", zone = "The Venomous Abyss",
              dropInfo = { mob = "Ula'tek", zone = "The Venomous Abyss", boss = true, rate = "Mythic" }, score = T.legendary },
        },
    },
    {
        source = "pvp",
        availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2,
        mounts = {
            { mountID = 2821, itemID = 275302, name = "Venomous Gladiator's Goredrake", source = "pvp",
              sourceInfo = "Gladiator: Midnight Season 2", achievementID = 62930, score = T.legendary },
            { mountID = 3002, itemID = 275433, name = "Vicious Lightbloom Boar", source = "pvp",
              sourceInfo = "Horde Rated PvP Season 2 reward", faction = "Horde", score = T.epic },
            { mountID = 3003, itemID = 275432, name = "Vicious Lightbloom Boar", source = "pvp",
              sourceInfo = "Alliance Rated PvP Season 2 reward", faction = "Alliance", score = T.epic },
        },
    },
    {
        source = "vendor",
        mounts = {
            { mountID = 3020, itemID = 275654, name = "Caustic Venomfang", source = "vendor",
              sourceInfo = "Skull of Er'inye - 10,000 Corrosive Coin",
              waypoint = MC.LOC.SkullOfErinye, zone = "Vaults of Atal'Utek",
              cost = { currency = { MC.CURRENCY.CorrosiveCoin, 10000 } }, score = T.long },
        },
    },
})
