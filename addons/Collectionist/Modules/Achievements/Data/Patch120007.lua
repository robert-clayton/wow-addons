local _, MC = ...

local M = MC.MAP

-- Patch 12.0.7 (Revelations), released June 16, 2026. This shard
-- intentionally contains only content released after the May 10 data
-- verification of Achievements.lua.
MC.RegisterContent("midnight", "achievements", {
    --------------------------------------------------------------------
    -- Void Showdowns: the rotating off-world zones of Val and Naigtal.
    --------------------------------------------------------------------
    {
        category = "features",
        source = "showdowns",
        achievements = {
            {
                achievementID = 62873,
                name          = "A Trip Around the Stars",
                zone          = "Val",
                description   = "Complete the Val Void Showdown meta. Reward: Voidmancer's Starcarver mount.",
                taskList = {
                    intro = "Finish the introduction and preparation, then complete Val's story, storm, rare, and world-quest achievements.",
                    tasks = {
                        { achievementID = 63383, label = "Into the Stars" },
                        { achievementID = 63384, label = "Prepared for a Showdown" },
                        { achievementID = 63386, label = "Frosty Domanaar Politics" },
                        { achievementID = 62903, label = "Climate Strange: Val" },
                        { achievementID = 62881, label = "Showdown Slugger: Val" },
                        { achievementID = 62880, label = "Showdown Success: Val" },
                    },
                },
            },
            {
                achievementID = 62874,
                name          = "A Trip Through the Stars",
                zone          = "Naigtal",
                description   = "Complete the Naigtal Void Showdown meta. Reward: Netherforged Nullframe mount.",
                taskList = {
                    intro = "Finish the introduction and preparation, then complete Naigtal's story, storm, rare, and world-quest achievements.",
                    tasks = {
                        { achievementID = 63383, label = "Into the Stars" },
                        { achievementID = 63384, label = "Prepared for a Showdown" },
                        { achievementID = 63385, label = "A Hal'hadar Walks into a Swamp" },
                        { achievementID = 62904, label = "Climate Strange: Naigtal" },
                        { achievementID = 62883, label = "Showdown Slugger: Naigtal" },
                        { achievementID = 62882, label = "Showdown Success: Naigtal" },
                    },
                },
            },
            { achievementID = 62899, name = "Absolute Power", zone = "Val + Naigtal",
              description = "Defeat a creature with each of 6 specified Void Showdown affixes." },
            { achievementID = 62898, name = "Cradle of Power", zone = "Val + Naigtal",
              description = "Defeat a creature with each of 6 specified Void Showdown affixes." },
            {
                achievementID = 63264,
                name          = "Heroic Showdowns",
                zone          = "Val + Naigtal",
                description   = "Complete the Heroic World Tier achievements in Val and Naigtal. Reward: Tortured Gorger mount.",
                taskList = {
                    intro = "Enable Heroic World Tier, then finish these six achievements across both rotating zones.",
                    tasks = {
                        { achievementID = 62887, label = "Heroic: Worlds Ahead" },
                        { achievementID = 62901, label = "Heroic: Power Creep" },
                        { achievementID = 62909, label = "Heroic: Pain of Command" },
                        { achievementID = 62917, label = "Heroic Climate Strange: Val" },
                        { achievementID = 62919, label = "Heroic Climate Strange: Naigtal" },
                        { achievementID = 63348, label = "Heroic Slugger" },
                    },
                },
            },
            { achievementID = 63348, name = "Heroic Slugger", zone = "Val + Naigtal",
              description = "Defeat 15 rare creatures in Val or Naigtal on Heroic World Tier." },
            { achievementID = 63323, name = "Heroic Tendencies", zone = "Val + Naigtal",
              description = "Defeat a world boss in Val or Naigtal." },
            { achievementID = 62909, name = "Heroic: Pain of Command", zone = "Val + Naigtal",
              description = "Defeat Imperator Pertinax and Nexus-Captain Leth'ir on Heroic World Tier." },
            { achievementID = 62901, name = "Heroic: Power Creep", zone = "Val + Naigtal",
              description = "Defeat creatures with 10 specified affixes on Heroic World Tier." },
            { achievementID = 62887, name = "Heroic: Worlds Ahead", zone = "Val + Naigtal",
              description = "Complete 15 World Quests in Val or Naigtal on Heroic World Tier." },
            { achievementID = 63383, name = "Into the Stars", zone = "Val + Naigtal",
              description = "Complete the introduction quest lines for both Val and Naigtal." },
            { achievementID = 62905, name = "Pain of Command", zone = "Val + Naigtal",
              description = "Defeat Imperator Pertinax and Nexus-Captain Leth'ir." },
            { achievementID = 62900, name = "Power Beyond Measure", zone = "Val + Naigtal",
              description = "Defeat a creature with each of 6 specified Void Showdown affixes." },
            { achievementID = 62896, name = "Power Creep", zone = "Val + Naigtal",
              description = "Defeat a creature with each of 6 specified Void Showdown affixes." },
            {
                achievementID = 63384,
                name          = "Prepared for a Showdown",
                zone          = "Val + Naigtal",
                description   = "Complete the preparation quests on both Val and Naigtal.",
                taskList = {
                    intro = "Complete all seven preparation objectives spread across the two rotating zones.",
                    tasks = {
                        { achievementID = 63384, criteriaID = 115419, label = "The Road Not Taken Twice" },
                        { achievementID = 63384, criteriaID = 115420, label = "Spatial Reasoning" },
                        { achievementID = 63384, criteriaID = 115421, label = "Bouncy Mushrooms" },
                        { achievementID = 63384, criteriaID = 115422, label = "Aerospores" },
                        { achievementID = 63384, criteriaID = 115423, label = "The Grappler" },
                        { achievementID = 63384, criteriaID = 115424, label = "Preparing for Threats" },
                        { achievementID = 63384, criteriaID = 115435, label = "Exterior Manaforge Translocator" },
                    },
                },
            },
            {
                achievementID = 63385,
                name          = "A Hal'hadar Walks into a Swamp",
                zone          = "Naigtal",
                description   = "Complete the three campaign quest lines on Naigtal.",
                taskList = {
                    intro = "Complete Naigtal's three story chapters.",
                    tasks = {
                        { achievementID = 63385, criteriaID = 115426, label = "Manaforge Reconnaissance" },
                        { achievementID = 63385, criteriaID = 115429, label = "Pilfered Technology" },
                        { achievementID = 63385, criteriaID = 115430, label = "A Cryptic Mystery" },
                    },
                },
            },
            { achievementID = 62904, name = "Climate Strange: Naigtal", zone = "Naigtal",
              description = "Dissipate 5 storms in Naigtal." },
            { achievementID = 62919, name = "Heroic Climate Strange: Naigtal", zone = "Naigtal",
              description = "Dissipate 5 storms in Naigtal on Heroic World Tier." },
            { achievementID = 62883, name = "Showdown Slugger: Naigtal", zone = "Naigtal",
              description = "Defeat 6 rare creatures in Naigtal. The Rares tab tracks every target." },
            { achievementID = 62882, name = "Showdown Success: Naigtal", zone = "Naigtal",
              description = "Complete 8 different World Quests in Naigtal." },
            { achievementID = 62944, name = "Showdown Unlock: Bouncy Mushrooms", zone = "Naigtal",
              description = "Unlock the Very Bouncy Mushrooms traversal feature." },
            { achievementID = 62945, name = "Showdown Unlock: Grapple Skiffs", zone = "Naigtal",
              description = "Unlock the Grappling Hook traversal feature." },
            { achievementID = 62949, name = "Showdown Unlock: Naigtal Spores", zone = "Naigtal",
              description = "Unlock Naigtal Spores." },
            { achievementID = 62903, name = "Climate Strange: Val", zone = "Val",
              description = "Dissipate 5 storms in Val." },
            {
                achievementID = 63386,
                name          = "Frosty Domanaar Politics",
                zone          = "Val",
                description   = "Complete the three campaign quest lines on Val.",
                taskList = {
                    intro = "Complete Val's three story chapters.",
                    tasks = {
                        { achievementID = 63386, criteriaID = 115432, label = "Victory Within Hindsight" },
                        { achievementID = 63386, criteriaID = 115433, label = "A Shot at the Dark" },
                        { achievementID = 63386, criteriaID = 115434, label = "Umbral Title Bout" },
                    },
                },
            },
            { achievementID = 62917, name = "Heroic Climate Strange: Val", zone = "Val",
              description = "Dissipate 5 storms in Val on Heroic World Tier." },
            { achievementID = 62881, name = "Showdown Slugger: Val", zone = "Val",
              description = "Defeat 6 rare creatures in Val. The Rares tab tracks every target." },
            { achievementID = 62880, name = "Showdown Success: Val", zone = "Val",
              description = "Complete 8 different World Quests in Val." },
            { achievementID = 63349, name = "Ultradon Carnage", zone = "Val",
              description = "Kill 100 enemies while controlling the Ultradon Slayer during the Until It Is Done World Quest." },
            { achievementID = 62842, name = "A Celestial Pain", zone = "Val",
              description = "Evade 100 consecutive lightning strikes during Thunder Pains." },
        },
    },

    --------------------------------------------------------------------
    -- Expanded 12.0.7 systems and time-limited events.
    --------------------------------------------------------------------
    {
        category = "features",
        source = "ritual_sites",
        achievements = {
            {
                achievementID = 63182,
                name          = "Advanced Ritual Site Studies",
                zone          = "Eversong + Zul'Aman",
                description   = "Complete Lady Darkglen's six weekly Tier 6 Ritual Site studies.",
                taskList = {
                    intro = "Each weekly study requires two Tier 6 clears with the named challenges active.",
                    tasks = {
                        { achievementID = 63182, criteriaID = 114818, label = "Week 1: Reinforcements" },
                        { achievementID = 63182, criteriaID = 114819, label = "Week 2: Malevolent Boons" },
                        { achievementID = 63182, criteriaID = 114820, label = "Week 3: Embers" },
                        { achievementID = 63182, criteriaID = 114821, label = "Week 4: Reinforcements and Alarm Bells" },
                        { achievementID = 63182, criteriaID = 114822, label = "Week 5: Boons and Patrols" },
                        { achievementID = 63182, criteriaID = 114823, label = "Week 6: Embers and Manifestations" },
                    },
                },
            },
            {
                achievementID = 62941,
                name          = "Pinnacle Ritual Work",
                zone          = "Eversong + Zul'Aman",
                description   = "Complete both Ritual Sites at Tier 6 with all 8 challenges active before Midnight ends. Reward: Ritual Breaker title.",
                taskList = {
                    intro = "Complete one fully challenged Tier 6 run at each site.",
                    tasks = {
                        { achievementID = 62941, criteriaID = 114234, label = "Broken Throne" },
                        { achievementID = 62941, criteriaID = 114235, label = "Daggerspine Point" },
                    },
                },
            },
            { achievementID = 62940, name = "Ritual Sites 612: Practical Ritual Work",
              zone = "Eversong + Zul'Aman", description = "Complete a Tier 6 Ritual Site." },
        },
    },
    {
        category = "features",
        source = "void_assaults",
        achievements = {
            {
                achievementID = 63325,
                name          = "Omnium Folio Studies",
                zone          = "Quel'Thalas",
                description   = "Earn all 5 Motes of Omnial Inquiry for the Omnium Folio. Reward: Sunstrider Omnium Simulacrum decor.",
                taskList = {
                    intro = "Complete the five weekly Omnium Folio research assignments.",
                    tasks = {
                        { achievementID = 63325, criteriaIndex = 1, label = "The Sunstrider Omnium" },
                        { achievementID = 63325, criteriaIndex = 2, label = "Ritualized Arcana" },
                        { achievementID = 63325, criteriaIndex = 3, label = "Leyline Assaults" },
                        { achievementID = 63325, criteriaIndex = 4, label = "Magical Primessence" },
                        { achievementID = 63325, criteriaIndex = 5, label = "Off-World Magic" },
                    },
                },
            },
            { achievementID = 62606, name = "The Sunstrider Omnium", zone = "Silvermoon City",
              description = "Complete The Omnium Reawakens and restore the Sunstrider Omnium." },
        },
    },
    {
        category = "features",
        source = "prey",
        achievements = {
            { achievementID = 63164, name = "Big Prey Hunter (Season 1)", zone = "Midnight (all zones)",
              description = "Complete the Prey Journey before Midnight Season 1 ends." },
        },
    },
    {
        category = "features",
        source = "raid",
        achievements = {
        },
    },
    {
        category = "exploration",
        source = "lore",
        achievements = {
            { achievementID = 61442, name = "Lorewalking: The Loa", zone = "Azeroth",
              description = "Complete the Loa Lorewalking campaign. Reward: Tome of Kings decor." },
        },
    },
    {
        category = "exploration",
        source = "zone",
        achievements = {
            {
                achievementID = 61083,
                name          = "Highly Decorated",
                zone          = "The Arcantina",
                description   = "Retrieve and display all 11 optional relics from the Arcantina quest rotation. Unlocks the Arcantina Weapon Rack decor in 12.0.7.",
                taskList = {
                    intro = "Missed relics remain retrievable after their related quest, but use the character that completed that quest.",
                    tasks = {
                        { achievementID = 61083, criteriaID = 117459, label = "Scarred Spear" },
                        { achievementID = 61083, criteriaID = 108608, label = "Ebon Banner" },
                        { achievementID = 61083, criteriaID = 108609, label = "Corrupted Lantern" },
                        { achievementID = 61083, criteriaID = 108610, label = "Ancient Zandalari Scroll" },
                        { achievementID = 61083, criteriaID = 108611, label = "Evergreen Vine" },
                        { achievementID = 61083, criteriaID = 108612, label = "Pylon Fragment" },
                        { achievementID = 61083, criteriaID = 108613, label = "Weathered Tome" },
                        { achievementID = 61083, criteriaID = 108614, label = "Heavy Anchor" },
                        { achievementID = 61083, criteriaID = 108615, label = "Sandy Tapestry" },
                        { achievementID = 61083, criteriaID = 108616, label = "Dried Roses" },
                        { achievementID = 61083, criteriaID = 108617, label = "Clefthoof Hide" },
                    },
                },
            },
            { achievementID = 63343, name = "Goal!", zone = "Silvermoon City",
              description = "Wear a Tabard of Participation and score 3 times with Kickable Practice Balls. Rewards three faction-football decor items.",
              waypoint = { M.Silvermoon, 0.3940, 0.5940, "Richmond and the practice field" } },
        },
    },
    {
        category = "exploration",
        source = "events",
        achievements = {
            {
                achievementID = 61335,
                name          = "Flame Keeper of Midnight",
                zone          = "Midnight (all zones)",
                description   = "Honor the five Horde Midsummer bonfires across Midnight.",
                taskList = {
                    intro = "Honor one Horde bonfire in each Midnight area during Midsummer.",
                    tasks = {
                        { achievementID = 61335, criteriaID = 109164, label = "Eversong Woods",
                          waypoint = { M.Eversong, 0.4890, 0.6390, "Midsummer bonfire" } },
                        { achievementID = 61335, criteriaID = 109163, label = "Silvermoon City",
                          waypoint = { M.Silvermoon, 0.4860, 0.8080, "Midsummer bonfire" } },
                        { achievementID = 61335, criteriaID = 109165, label = "Zul'Aman",
                          waypoint = { M.ZulAman, 0.5440, 0.1680, "Midsummer bonfire" } },
                        { achievementID = 61335, criteriaID = 109166, label = "Voidstorm",
                          waypoint = { M.Voidstorm, 0.5370, 0.7020, "Midsummer bonfire" } },
                        { achievementID = 61335, criteriaID = 109167, label = "Harandar",
                          waypoint = { M.Harandar, 0.5420, 0.5160, "Midsummer bonfire" } },
                    },
                },
            },
            {
                achievementID = 61336,
                name          = "Flame Warden of Midnight",
                zone          = "Midnight (all zones)",
                description   = "Honor the five Alliance Midsummer bonfires across Midnight.",
                taskList = {
                    intro = "Honor one Alliance bonfire in each Midnight area during Midsummer.",
                    tasks = {
                        { achievementID = 61336, criteriaID = 109164, label = "Eversong Woods",
                          waypoint = { M.Eversong, 0.4890, 0.6390, "Midsummer bonfire" } },
                        { achievementID = 61336, criteriaID = 109163, label = "Silvermoon City",
                          waypoint = { M.Silvermoon, 0.4860, 0.8080, "Midsummer bonfire" } },
                        { achievementID = 61336, criteriaID = 109165, label = "Zul'Aman",
                          waypoint = { M.ZulAman, 0.5440, 0.1680, "Midsummer bonfire" } },
                        { achievementID = 61336, criteriaID = 109166, label = "Voidstorm",
                          waypoint = { M.Voidstorm, 0.5370, 0.7020, "Midsummer bonfire" } },
                        { achievementID = 61336, criteriaID = 109167, label = "Harandar",
                          waypoint = { M.Harandar, 0.5420, 0.5160, "Midsummer bonfire" } },
                    },
                },
            },
            { achievementID = 61463, name = "Master of the Turbulent Timeways V", zone = "Timewalking",
              description = "Gain Mastery of Timeways for 4 weeks during Turbulent Timeways V. Reward: Spawn of Vyranoth mount." },
        },
    },
})
