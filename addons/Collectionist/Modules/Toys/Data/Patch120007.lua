local _, MC = ...
local T = MC.SCORE_TIERS

MC.RegisterContent("midnight", "toys", {
    {
        source = "quest",
        toys = {
            { itemID = 276371, name = "Lightveil Recall Beacon", source = "quest",
              sourceInfo = "Quest: Ten Forward (Naigtal introductory story)",
              waypoint = { MC.MAP.Naigtal, 0.708, 0.622, "Ten Forward" }, zone = "Naigtal" },
        },
    },
    {
        source = "raid",
        toys = {
            { itemID = 264313, name = "Madcap Redcap", source = "raid",
              sourceInfo = "Rotmire, Sporefall", zone = "Sporefall",
              dropInfo = { mob = "Rotmire", zone = "Sporefall", boss = true }, score = T.long },
            { itemID = 264367, name = "Mycomancer's Hearthspore", source = "raid",
              sourceInfo = "Rotmire, Sporefall", zone = "Sporefall",
              dropInfo = { mob = "Rotmire", zone = "Sporefall", boss = true }, score = T.long },
        },
    },
    {
        source = "worldevent",
        toys = {
            { itemID = 267323, name = "Troll Scroll of Rainbow Roll", source = "worldevent",
              sourceInfo = "Complete the Horde-only Darkspear Dash from the Echo Isles to Silvermoon City", zone = "Echo Isles",
              faction = "Horde", score = T.medium },
            { itemID = 259335, name = "Photo Finisher", source = "worldevent",
              sourceInfo = "Xydan - 1,000 Timewarped Badges during Dragonflight Timewalking", zone = "Valdrakken",
              cost = { currency = { MC.CURRENCY.TimewarpedBadges, 1000 } } },
            { itemID = 259899, name = "Ashen Horn of the Fallen Keeper", source = "worldevent",
              sourceInfo = "Xydan - 750 Timewarped Badges during Dragonflight Timewalking", zone = "Valdrakken",
              cost = { currency = { MC.CURRENCY.TimewarpedBadges, 750 } } },
            { itemID = 260170, name = "Oathstone Fragment", source = "worldevent",
              sourceInfo = "Xydan - 500 Timewarped Badges during Dragonflight Timewalking", zone = "Valdrakken",
              cost = { currency = { MC.CURRENCY.TimewarpedBadges, 500 } } },
        },
    },
})
