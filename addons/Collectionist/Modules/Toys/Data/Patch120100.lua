local _, MC = ...
local T = MC.SCORE_TIERS

local COILED_ISLE = MC.MAP.CoiledIsle

MC.RegisterContent("midnight", "toys", {
    {
        source = "renown",
        toys = {
            { itemID = 276925, name = "Idol of Ula'tek", source = "renown",
              sourceInfo = "Jan'sari the Watchful",
              waypoint = { COILED_ISLE, 0.588, 0.450, "Jan'sari the Watchful" }, zone = "The Coiled Isle",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 4000 } },
              renown = { factionID = MC.FACTION.ZuljarrasForces, level = 13, factionName = "Zul'Jarra's Forces" }, score = T.medium },
        },
    },
    {
        source = "achievement",
        toys = {
            { itemID = 280419, name = "Cursed Badge of the Soulcoilers", source = "achievement",
              sourceInfo = "Student of Hissstory", zone = "The Coiled Isle",
              achievementID = 63662, score = T.medium, waypoint = { 2512, 0.6790, 0.8150, "Cursed Badge of the Soulcoilers" } },
            { itemID = 275825, name = "Ula'tek's Sssacrificial Rain", source = "achievement",
              sourceInfo = "Tour of Duty: The Coiled Isle - earn 1,000 honor on the Coiled Isle in War Mode",
              zone = "The Coiled Isle", achievementID = 63167, score = T.medium },
        },
    },
    {
        source = "quest",
        toys = {
            { itemID = 280201, name = "Book of Storytime", source = "quest",
              sourceInfo = "Quest: Strong Heart", waypoint = { MC.MAP.ZulAman, 0.453, 0.487, "Strong Heart" },
              zone = "Zul'Aman" },
            { itemID = 275988, name = "Corrosive Victory", source = "quest",
              sourceInfo = "Quest: Fangs for the Memories", waypoint = { MC.MAP.Silvermoon, 0.525, 0.783, "Valeera Sanguinar" },
              zone = "Silvermoon City" },
        },
    },
    {
        source = "treasure",
        toys = {
            { itemID = 279054, name = "Idol of Blue Water and Blue Sky", source = "treasure",
              sourceInfo = "Abandoned Amani Privateer's Cache", waypoint = { COILED_ISLE, 0.719, 0.667, "Abandoned Amani Privateer's Cache" },
              zone = "The Coiled Isle", cost = { item = { 265602, 1 } } },
            { itemID = 274921, name = "Pearl of Jubilation", source = "treasure",
              sourceInfo = "Brine-Crusted Chest", waypoint = { COILED_ISLE, 0.706, 0.766, "Brine-Crusted Chest" },
              zone = "The Coiled Isle", cost = { item = { 271881, 1 } } },
            { itemID = 279021, name = "Forgotten Memento", source = "treasure",
              sourceInfo = "Grave of Someone Forgotten", waypoint = { COILED_ISLE, 0.673, 0.485, "Grave of Someone Forgotten" },
              zone = "The Coiled Isle" },
            { itemID = 277954, name = "Jaktu's Cursed Blade", source = "treasure",
              sourceInfo = "Jaktu's Cursed Blade", waypoint = { COILED_ISLE, 0.604, 0.594, "Jaktu's Cursed Blade" },
              zone = "The Coiled Isle" },
            { itemID = 268504, name = "Malfunctioning Staff", source = "treasure",
              sourceInfo = "Malfunctioning Staff", waypoint = { COILED_ISLE, 0.754, 0.573, "Malfunctioning Staff" },
              zone = "The Coiled Isle" },
            { itemID = 279052, name = "Ancient Amani Mask", source = "treasure",
              sourceInfo = "Sunken Diver's Chest", waypoint = { COILED_ISLE, 0.654, 0.056, "Sunken Diver's Chest" },
              zone = "The Coiled Isle", cost = { item = { 271423, 1 } } },
        },
    },
    {
        source = "drop",
        toys = {
            { itemID = 276207, name = "Preyhunter's Masquerade", source = "drop",
              sourceInfo = "Ral'kala during Prey: A Ghostly Nightmare (Season 2)", zone = "Prey",
              dropInfo = { mob = "Ral'kala", zone = "Prey: A Ghostly Nightmare", boss = true },
              availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2, score = T.long },
        },
    },
    {
        source = "vendor",
        toys = {
            { itemID = 276189, name = "Effigy of Dundun", source = "vendor",
              sourceInfo = "Naleidea Rivergleam - 10 Voidlight Marl", waypoint = MC.LOC.NaleideaRivergleam,
              zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.VoidlightMarl, 10 } } },
            { itemID = 276229, name = "Preyhunter's Trophy Stand", source = "vendor",
              sourceInfo = "Construct V'anore - Prey Season 2 reward track level 4", waypoint = MC.LOC.ConstructVanore,
              zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 800 } },
              score = T.medium },
            { itemID = 276258, name = "Companion Command Crystal", source = "vendor",
              sourceInfo = "Construct V'anore - Prey Season 2 reward track level 4", waypoint = MC.LOC.ConstructVanore,
              zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 600 } },
              score = T.medium },
            { itemID = 274817, name = "Gold Starfish", source = "vendor",
              sourceInfo = "Navigator Otoola - 10 Pristine Polygon and 750 Voidlight Marl (starfish are fished on the Coiled Isle)",
              waypoint = MC.LOC.NavigatorOtoola, zone = "The Coiled Isle",
              cost = { item = { 274595, 10 }, currency = { MC.CURRENCY.VoidlightMarl, 750 } }, score = T.short },
            { itemID = 278557, name = "Otoola's Recognition", source = "vendor",
              sourceInfo = "Navigator Otoola - 10 Pristine Polygon and 750 Voidlight Marl (starfish are fished on the Coiled Isle)",
              waypoint = MC.LOC.NavigatorOtoola, zone = "The Coiled Isle",
              cost = { item = { 274595, 10 }, currency = { MC.CURRENCY.VoidlightMarl, 750 } }, score = T.short },
        },
    },
    {
        source = "profession",
        toys = {
            { itemID = 275683, name = "G-00", source = "profession",
              sourceInfo = "Midnight Engineering (50) craft - Schematic: G-00 from Thalassian Recipe in a Bottle, fished on the Coiled Isle",
              zone = "The Coiled Isle" },
        },
    },
    {
        source = "worldevent",
        toys = {
            { itemID = 267472, name = "Gnomatic Projector", source = "worldevent",
              sourceInfo = "The Great Gnomeregan Run", zone = "New Tinkertown", faction = "Alliance", score = T.medium, waypoint = { 469, 0.3630, 0.3650, "Gnomatic Projector" } },
        },
    },
})
