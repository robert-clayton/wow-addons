local _, MC = ...
local T = MC.SCORE_TIERS

-- Patch 12.0.7: Revelations.  The Amani Hex Bear is intentionally absent:
-- it appeared in the journal in this build, but still has no obtainable
-- source.  Add it when Blizzard enables a source rather than showing players
-- a permanently unactionable row.

local SPOREGLIDER_TASKS = {
    intro = "Collect four Delicious Sporesnacks from Rotmire, then combine them.",
    tasks = {
        { itemID = 269245, itemCount = 4, label = "Collect 4 Delicious Sporesnacks (Rotmire)" },
    },
}

MC.RegisterContent("midnight", "mounts", {
    {
        source = "showdowns",
        mounts = {
            { mountID = 2990, itemID = 274650, name = "Netherforged Nullframe",
              source = "showdowns", sourceInfo = "Kifaan - 15 Voidlight Marl after A Trip Through the Stars",
              waypoint = MC.LOC.Kifaan, zone = "Naigtal / Val",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 15 } }, achievementID = 62874, score = T.epic },
            { mountID = 2988, itemID = 274649, name = "Voidmancer's Starcarver",
              source = "showdowns", sourceInfo = "Kifaan - 15 Voidlight Marl after A Trip Around the Stars",
              waypoint = MC.LOC.Kifaan, zone = "Naigtal / Val",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 15 } }, achievementID = 62873, score = T.epic },
            { mountID = 3033, itemID = 275664, name = "Tortured Gorger",
              source = "showdowns", sourceInfo = "Kifaan - 15 Voidlight Marl after Heroic Showdowns",
              waypoint = MC.LOC.Kifaan, zone = "Naigtal / Val",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 15 } }, achievementID = 63264, score = T.legendary },
        },
    },
    {
        source = "raid",
        mounts = {
            { mountID = 2950, itemID = 269240, name = "Luminous Sporeglider",
              source = "raid", sourceInfo = "Combine 4 Delicious Sporesnacks from Rotmire in Sporefall",
              zone = "Sporefall", taskList = SPOREGLIDER_TASKS, score = T.epic },
        },
    },
    {
        source = "achievement",
        mounts = {
            { mountID = 2806, itemID = 258884, name = "Spawn of Vyranoth",
              source = "achievement", sourceInfo = "Master of the Turbulent Timeways V",
              achievementID = 61463, score = T.epic },
        },
    },
    {
        source = "quest",
        mounts = {
            { mountID = 2611, itemID = 246731, name = "Dusk Grimlynx",
              source = "quest", sourceInfo = "History Lesson - Legacy of the Amani storyline",
              zone = "Harandar", score = T.medium },
        },
    },
    {
        source = "worldevent",
        mounts = {
            { mountID = 3036, itemID = 275464, name = "Sun Festival's Painted Roc",
              source = "worldevent", sourceInfo = "First daily Warband attempt from Ahune's Satchel of Chilled Goods; failed attempts increase the chance",
              dropInfo = { mob = "Ahune", zone = "Midsummer Fire Festival", boss = true, rate = "Increasing daily Warband chance" }, score = T.epic },
            { mountID = 1470, itemID = 192778, name = "Liquid Hot Magma Slug",
              source = "worldevent", sourceInfo = "Xydan - 5,000 Timewarped Badges during Dragonflight Timewalking",
              cost = { currency = { MC.CURRENCY.TimewarpedBadges, 5000 } }, score = T.long },
            { mountID = 1710, itemID = 210140, name = "Black-Furred Bakar",
              source = "worldevent", sourceInfo = "Xydan - 5,000 Timewarped Badges during Dragonflight Timewalking",
              cost = { currency = { MC.CURRENCY.TimewarpedBadges, 5000 } }, score = T.long },
        },
    },
})
