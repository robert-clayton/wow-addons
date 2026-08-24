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
              dropInfo = { mob = "Rotmire", zone = "Sporefall", boss = true }, score = T.long, waypoint = { 2413, 0.7350, 0.6640, "Madcap Redcap" } },
            { itemID = 264367, name = "Mycomancer's Hearthspore", source = "raid",
              sourceInfo = "Rotmire, Sporefall", zone = "Sporefall",
              dropInfo = { mob = "Rotmire", zone = "Sporefall", boss = true }, score = T.long, waypoint = { 2413, 0.7350, 0.6640, "Mycomancer's Hearthspore" } },
        },
    },
    {
        source = "worldevent",
        toys = {
            { itemID = 267323, name = "Troll Scroll of Rainbow Roll", source = "worldevent",
              sourceInfo = "Complete the Horde-only Darkspear Dash from the Echo Isles to Silvermoon City", zone = "Echo Isles",
              faction = "Horde", score = T.medium, waypoint = { 463, 0.4670, 0.4740, "Troll Scroll of Rainbow Roll" } },
            { itemID = 259335, name = "Photo Finisher", source = "worldevent",
              sourceInfo = "Xydan - 1,000 Timewarped Badges during Dragonflight Timewalking", zone = "Valdrakken",
              cost = { currency = { MC.CURRENCY.TimewarpedBadges, 1000 } }, waypoint = { 2112, 0.8150, 0.4720, "Photo Finisher" } },
            { itemID = 259899, name = "Ashen Horn of the Fallen Keeper", source = "worldevent",
              sourceInfo = "Xydan - 750 Timewarped Badges during Dragonflight Timewalking", zone = "Valdrakken",
              cost = { currency = { MC.CURRENCY.TimewarpedBadges, 750 } }, waypoint = { 2112, 0.8150, 0.4720, "Ashen Horn of the Fallen Keeper" } },
            { itemID = 260170, name = "Oathstone Fragment", source = "worldevent",
              sourceInfo = "Xydan - 500 Timewarped Badges during Dragonflight Timewalking", zone = "Valdrakken",
              cost = { currency = { MC.CURRENCY.TimewarpedBadges, 500 } }, waypoint = { 2112, 0.8150, 0.4720, "Oathstone Fragment" } },
        },
    },
})
