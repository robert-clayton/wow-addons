local _, MC = ...
local T = MC.SCORE_TIERS

local SILENTO_TASKS = {
    intro = "Complete the normal world-quest meta in both rotating Showdown worlds.",
    tasks = {
        { achievementID = 62880, label = "Showdown Success: Val" },
        { achievementID = 62882, label = "Showdown Success: Naigtal" },
    },
}

local SLEEPY_MANDRAKE_TASKS = {
    intro = "Bring Sleepy Mandrake all five Redcap varieties found around Naigtal.",
    tasks = {
        { questID = 97091, label = "Feed the first Redcap",  waypoint = { MC.MAP.Naigtal, 0.682, 0.516, "Sleepy Mandrake" } },
        { questID = 97092, label = "Feed the second Redcap", waypoint = { MC.MAP.Naigtal, 0.682, 0.516, "Sleepy Mandrake" } },
        { questID = 97093, label = "Feed the third Redcap",  waypoint = { MC.MAP.Naigtal, 0.682, 0.516, "Sleepy Mandrake" } },
        { questID = 97094, label = "Feed the fourth Redcap", waypoint = { MC.MAP.Naigtal, 0.682, 0.516, "Sleepy Mandrake" } },
        { questID = 97095, label = "Feed the fifth Redcap",  waypoint = { MC.MAP.Naigtal, 0.682, 0.516, "Sleepy Mandrake" } },
    },
}

MC.RegisterContent("midnight", "pets", {
    {
        source = "vendor",
        pets = {
            { speciesID = 4898, itemID = 252195, npcID = 251820, name = "Fishstick Keith",
              petType = 9, source = "vendor", sourceInfo = "Kifaan - 50 Sin'dorei Swarmers after Climate Strange: Val",
              canBattle = true, waypoint = MC.LOC.Kifaan, zone = "Val",
              cost = { item = { 238365, 50 } }, achievementID = 62903, score = T.medium },
            { speciesID = 5073, itemID = 275662, npcID = 266577, name = "Frosticus Maximus",
              petType = 8, source = "vendor", sourceInfo = "Kifaan - 15 Voidlight Marl after Ultradon Carnage",
              canBattle = true, waypoint = MC.LOC.Kifaan, zone = "Val",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 15 } }, achievementID = 63349, score = T.medium },
            { speciesID = 5074, itemID = 275663, npcID = 266580, name = "Silento",
              petType = 7, source = "vendor", sourceInfo = "Kifaan - 15 Voidlight Marl after Showdown Success in Val and Naigtal",
              canBattle = true, waypoint = MC.LOC.Kifaan, zone = "Naigtal / Val",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 15 } }, achievementID = 62880,
              taskList = SILENTO_TASKS, score = T.long },
        },
    },
    {
        source = "quest",
        pets = {
            { speciesID = 4965, itemID = 262768, npcID = 256565, name = "Sleepy Mandrake",
              petType = 7, source = "quest", sourceInfo = "Feed five different Redcaps to the Sleepy Mandrake in Naigtal",
              canBattle = true, waypoint = { MC.MAP.Naigtal, 0.682, 0.516, "Sleepy Mandrake" }, zone = "Naigtal",
              taskList = SLEEPY_MANDRAKE_TASKS, score = T.medium },
            { speciesID = 5041, itemID = 271185, npcID = 262985, name = "Emberlyn",
              petType = 2, source = "quest", sourceInfo = "Quest: Like Dragonhawks to a Flame",
              canBattle = false, waypoint = { MC.MAP.ZulAman, 0.551, 0.184, "Like Dragonhawks to a Flame" }, zone = "Zul'Aman" },
            { speciesID = 5007, itemID = 268557, npcID = 260149, name = "Akiki",
              petType = 8, source = "quest", sourceInfo = "Quest: Dead End (Zul'jan campaign chapter)",
              canBattle = false, waypoint = { MC.MAP.ZulAman, 0.444, 0.667, "Dead End" }, zone = "Zul'Aman", score = T.medium },
        },
    },
    {
        source = "event",
        pets = {
            { speciesID = 4949, itemID = 260885, npcID = 256080, name = "Shadowflame Remnant",
              petType = 7, source = "event", sourceInfo = "Xydan - 2,200 Timewarped Badges during Dragonflight Timewalking", zone = "Valdrakken",
              canBattle = true, cost = { currency = { MC.CURRENCY.TimewarpedBadges, 2200 } }, score = T.medium },
        },
    },
})
