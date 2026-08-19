local _, MC = ...

local M = MC.MAP
local T = MC.SCORE_TIERS

-- Two-level grouping: top-level category, then sub-category. The UI
-- renders categories as outer collapsibles and sub-categories as inner.

MC.AchievementCategoryOrder = {
    "exploration",
    "quests",
    "collections",
    "features",
}

MC.AchievementCategoryLabels = {
    exploration = "Exploration",
    quests      = "Quests",
    collections = "Collections",
    features    = "Features",
}

-- Per-category sub-category render order. Sub-categories not listed
-- here fall through to alphabetical display.
MC.AchievementSubcategoryOrder = {
    exploration = { "metas", "explore", "vistas", "glyphs", "lore", "paintings", "events", "zone" },
    quests      = { "metas" },
    collections = { "pets", "mounts", "toys" },
    features    = {
        "covenants", "torghast", "dragonriding", "reputation",
        "islands", "war_effort", "heart_of_azeroth",
        "showdowns", "prey", "void_assaults", "ritual_sites",
        "delves", "dungeons", "raid", "housing", "professions", "season",
    },
}

MC.AchievementSourceLabels = {
    metas         = "Metas",
    explore       = "Zone Explorer",
    vistas        = "Highest Peaks (Vistas)",
    glyphs        = "Skyriding Glyphs",
    lore          = "Lore Hunter",
    paintings     = "Ever Painting (Eversong)",
    events        = "World Events",
    zone          = "Zone Specific",
    pets          = "Pets",
    mounts        = "Mounts",
    toys          = "Toys",
    dragonriding  = "Dragonriding",
    covenants     = "Covenant Sanctums",
    torghast      = "Torghast",
    reputation    = "Reputation",
    islands       = "Island Expeditions",
    war_effort    = "War Effort",
    heart_of_azeroth = "Heart of Azeroth",
    prey          = "Prey",
    void_assaults = "Void Assaults",
    ritual_sites  = "Ritual Sites",
    showdowns     = "Void Showdowns",
    delves        = "Delves",
    dungeons      = "Dungeons",
    raid          = "Raids",
    housing       = "Housing",
    professions   = "Professions",
    season        = "Season 2",
}

-- Back-compat: keep flat source order so older callers don't break.
MC.AchievementSourceOrder = {
    "metas", "explore", "vistas", "glyphs", "lore", "paintings",
    "events", "zone", "pets", "mounts", "toys",
    "covenants", "torghast", "dragonriding", "reputation",
    "islands", "war_effort", "heart_of_azeroth",
    "showdowns", "prey", "void_assaults", "ritual_sites",
    "delves", "dungeons", "raid", "housing", "professions", "season",
}

-- Coordinates from HandyNotes_Midnight (verified May 2026). The 8-digit
-- node keys there encode XX.XX × YY.YY as ints; converted to fractions
-- below.

MC.RegisterContent("midnight", "achievements", {
    --------------------------------------------------------------------
    -- Highest Peaks: each zone has its own achievement with 5 vistas.
    -- Use a telescope at each lookout point to get the criterion.
    --------------------------------------------------------------------
    {
        category = "exploration",
        source = "vistas",
        achievements = {
            {
                achievementID = 62288,
                name          = "Highest Peaks: Eversong Woods",
                zone          = "Eversong Woods",
                description   = "Use the telescope at five lookout points across Eversong Woods.",
                taskList = {
                    intro = "Each is a fixed telescope on top of a tower or peak. All reachable on a flying mount.",
                    tasks = {
                        { achievementID = 62288, criteriaID = 111573, label = "Silvermoon City rooftop telescope",
                          waypoint = { M.Silvermoon, 0.2022, 0.7961, "Silvermoon vista" } },
                        { achievementID = 62288, criteriaID = 111574, label = "North Eversong telescope",
                          waypoint = { M.Eversong, 0.4041, 0.1010, "North Eversong vista" } },
                        { achievementID = 62288, criteriaID = 111575, label = "West Eversong telescope",
                          waypoint = { M.Eversong, 0.3741, 0.4789, "West Eversong vista" } },
                        { achievementID = 62288, criteriaID = 111576, label = "East Eversong telescope",
                          waypoint = { M.Eversong, 0.5458, 0.5101, "East Eversong vista" } },
                        { achievementID = 62288, criteriaID = 111577, label = "South Eversong telescope",
                          waypoint = { M.Eversong, 0.5019, 0.8543, "South Eversong vista" } },
                    },
                },
            },
            {
                achievementID = 62289,
                name          = "Highest Peaks: Zul'Aman",
                zone          = "Zul'Aman",
                description   = "Use the telescope at five lookout points across Zul'Aman.",
                taskList = {
                    intro = "Fixed telescopes at five high points around the zone.",
                    tasks = {
                        { achievementID = 62289, criteriaID = 111578, label = "Northwest Zul'Aman telescope",
                          waypoint = { M.ZulAman, 0.2779, 0.7001, "NW Zul'Aman vista" } },
                        { achievementID = 62289, criteriaID = 111579, label = "Central Zul'Aman telescope",
                          waypoint = { M.ZulAman, 0.5301, 0.8202, "Central Zul'Aman vista" } },
                        { achievementID = 62289, criteriaID = 111580, label = "East Zul'Aman telescope",
                          waypoint = { M.ZulAman, 0.5769, 0.2123, "East Zul'Aman vista" } },
                        { achievementID = 62289, criteriaID = 111581, label = "Southwest Zul'Aman telescope",
                          waypoint = { M.ZulAman, 0.2463, 0.5830, "SW Zul'Aman vista" } },
                        { achievementID = 62289, criteriaID = 111582, label = "Central-south Zul'Aman telescope",
                          waypoint = { M.ZulAman, 0.4185, 0.4163, "Central-south Zul'Aman vista" } },
                    },
                },
            },
            {
                achievementID = 62290,
                name          = "Highest Peaks: Harandar",
                zone          = "Harandar",
                description   = "Use the telescope at five lookout points across Harandar.",
                taskList = {
                    intro = "Each is a telescope perched on a peak or spire.",
                    tasks = {
                        { achievementID = 62290, criteriaID = 111583, label = "East Harandar telescope",
                          waypoint = { M.Harandar, 0.6917, 0.4638, "East Harandar vista" } },
                        { achievementID = 62290, criteriaID = 111584, label = "Southeast Harandar telescope",
                          waypoint = { M.Harandar, 0.6816, 0.2597, "SE Harandar vista" } },
                        { achievementID = 62290, criteriaID = 111585, label = "Central Harandar telescope",
                          waypoint = { M.Harandar, 0.4940, 0.7592, "Central Harandar vista" } },
                        { achievementID = 62290, criteriaID = 111586, label = "Far-east Harandar telescope",
                          waypoint = { M.Harandar, 0.6940, 0.6339, "Far-east Harandar vista" } },
                        { achievementID = 62290, criteriaID = 111587, label = "Mid-east Harandar telescope",
                          waypoint = { M.Harandar, 0.5349, 0.5855, "Mid-east Harandar vista" } },
                    },
                },
            },
            {
                achievementID = 62291,
                name          = "Highest Peaks: Voidstorm",
                zone          = "Voidstorm",
                description   = "Use the telescope at five lookout points across Voidstorm.",
                taskList = {
                    intro = "Five fixed telescopes scattered across the zone.",
                    tasks = {
                        { achievementID = 62291, criteriaID = 111588, label = "North Voidstorm telescope",
                          waypoint = { M.Voidstorm, 0.3968, 0.6116, "North Voidstorm vista" } },
                        { achievementID = 62291, criteriaID = 111589, label = "West Voidstorm telescope",
                          waypoint = { M.Voidstorm, 0.3650, 0.4430, "West Voidstorm vista" } },
                        { achievementID = 62291, criteriaID = 111590, label = "East Voidstorm telescope",
                          waypoint = { M.Voidstorm, 0.5546, 0.6717, "East Voidstorm vista" } },
                        { achievementID = 62291, criteriaID = 111591, label = "Central Voidstorm telescope",
                          waypoint = { M.Voidstorm, 0.4176, 0.7022, "Central Voidstorm vista" } },
                        { achievementID = 62291, criteriaID = 111592, label = "South Voidstorm telescope",
                          waypoint = { M.Voidstorm, 0.3781, 0.5497, "South Voidstorm vista" } },
                    },
                },
            },
        },
    },

    --------------------------------------------------------------------
    -- Skyriding Glyphs: floating glowing books at fixed locations.
    -- Need a flying mount (skyriding) to reach most of them.
    --------------------------------------------------------------------
    {
        category = "exploration",
        source = "glyphs",
        achievements = {
            {
                achievementID = 61576,
                name          = "Glyph Hunter: Eversong Woods",
                zone          = "Eversong Woods",
                description   = "Collect every Skyriding Glyph in Eversong Woods.",
                taskList = {
                    intro = "Each glyph is a glowing floating tome. Skyride up and fly through it.",
                    tasks = {
                        { achievementID = 61576, criteriaID = 110335, label = "The Shining Span (Silvermoon)",
                          waypoint = { M.Silvermoon, 0.4832, 0.0667, "The Shining Span" } },
                        { achievementID = 61576, criteriaID = 110336, label = "Brightwing Estate",
                          waypoint = { M.Eversong, 0.6520, 0.3258, "Brightwing Estate" } },
                        { achievementID = 61576, criteriaID = 110337, label = "Silvermoon City",
                          waypoint = { M.Eversong, 0.5892, 0.1954, "Silvermoon City" } },
                        { achievementID = 61576, criteriaID = 110338, label = "Goldenmist Village",
                          waypoint = { M.Eversong, 0.4000, 0.5960, "Goldenmist Village" } },
                        { achievementID = 61576, criteriaID = 110339, label = "Path of Dawn",
                          waypoint = { M.Eversong, 0.4947, 0.4803, "Path of Dawn" } },
                        { achievementID = 61576, criteriaID = 110340, label = "Sunsail Anchorage",
                          waypoint = { M.Eversong, 0.3945, 0.4563, "Sunsail Anchorage" } },
                        { achievementID = 61576, criteriaID = 110341, label = "Dawnstar Spire",
                          waypoint = { M.Eversong, 0.6261, 0.6278, "Dawnstar Spire" } },
                        { achievementID = 61576, criteriaID = 110342, label = "Tranquillien",
                          waypoint = { M.Eversong, 0.5246, 0.6754, "Tranquillien" } },
                        { achievementID = 61576, criteriaID = 110343, label = "Daggerspine Point",
                          waypoint = { M.Eversong, 0.3343, 0.6540, "Daggerspine Point" } },
                        { achievementID = 61576, criteriaID = 110344, label = "Suncrown Tree",
                          waypoint = { M.Eversong, 0.5843, 0.5831, "Suncrown Tree" } },
                        { achievementID = 61576, criteriaID = 110345, label = "Fairbreeze Village",
                          waypoint = { M.Eversong, 0.4320, 0.4636, "Fairbreeze Village" } },
                    },
                },
            },
            {
                achievementID = 61581,
                name          = "Glyph Hunter: Zul'Aman",
                zone          = "Zul'Aman",
                description   = "Collect every Skyriding Glyph in Zul'Aman.",
                taskList = {
                    intro = "Floating glowing tomes. Skyride through each one.",
                    tasks = {
                        { achievementID = 61581, criteriaID = 110353, label = "Revantusk Sedge",
                          waypoint = { M.ZulAman, 0.1917, 0.7064, "Revantusk Sedge" } },
                        { achievementID = 61581, criteriaID = 110354, label = "Temple of Akil'zon",
                          waypoint = { M.ZulAman, 0.5363, 0.8039, "Temple of Akil'zon" } },
                        { achievementID = 61581, criteriaID = 110355, label = "Shadebasin Watch",
                          waypoint = { M.ZulAman, 0.4292, 0.3436, "Shadebasin Watch" } },
                        { achievementID = 61581, criteriaID = 110356, label = "Temple of Jan'alai",
                          waypoint = { M.ZulAman, 0.5148, 0.2357, "Temple of Jan'alai" } },
                        { achievementID = 61581, criteriaID = 110357, label = "Strait of Hexx'alor",
                          waypoint = { M.ZulAman, 0.5320, 0.5448, "Strait of Hexx'alor" } },
                        { achievementID = 61581, criteriaID = 110358, label = "Witherbark Bluffs",
                          waypoint = { M.ZulAman, 0.3955, 0.1977, "Witherbark Bluffs" } },
                        { achievementID = 61581, criteriaID = 110359, label = "Nalorakk's Prowl",
                          waypoint = { M.ZulAman, 0.3041, 0.8478, "Nalorakk's Prowl" } },
                        { achievementID = 61581, criteriaID = 110360, label = "Zeb'Alar Lumberyard",
                          waypoint = { M.ZulAman, 0.2791, 0.2860, "Zeb'Alar Lumberyard" } },
                        { achievementID = 61581, criteriaID = 110361, label = "Amani Pass",
                          waypoint = { M.ZulAman, 0.2482, 0.5483, "Amani Pass" } },
                        { achievementID = 61581, criteriaID = 110362, label = "Solemn Valley",
                          waypoint = { M.ZulAman, 0.4669, 0.8217, "Solemn Valley" } },
                        { achievementID = 61581, criteriaID = 110363, label = "Spiritpaw Burrow",
                          waypoint = { M.ZulAman, 0.4274, 0.8014, "Spiritpaw Burrow" } },
                    },
                },
            },
            {
                achievementID = 61582,
                name          = "Glyph Hunter: Harandar",
                zone          = "Harandar",
                description   = "Collect every Skyriding Glyph in Harandar.",
                taskList = {
                    intro = "Skyride up and pass through each glowing tome.",
                    tasks = {
                        { achievementID = 61582, criteriaID = 110364, label = "Blossoming Terrace",
                          waypoint = { M.Harandar, 0.6024, 0.4436, "Blossoming Terrace" } },
                        { achievementID = 61582, criteriaID = 110365, label = "The Cradle",
                          waypoint = { M.Harandar, 0.4707, 0.5321, "The Cradle" } },
                        { achievementID = 61582, criteriaID = 110366, label = "Roots of Shaladrassil",
                          waypoint = { M.Harandar, 0.2653, 0.6139, "Roots of Shaladrassil" } },
                        { achievementID = 61582, criteriaID = 110367, label = "Roots of Amirdrassil",
                          waypoint = { M.Harandar, 0.6930, 0.4593, "Roots of Amirdrassil" } },
                        { achievementID = 61582, criteriaID = 110368, label = "Blooming Lattice",
                          waypoint = { M.Harandar, 0.5412, 0.3558, "Blooming Lattice" } },
                        { achievementID = 61582, criteriaID = 110369, label = "Roots of Nordrassil",
                          waypoint = { M.Harandar, 0.7301, 0.2599, "Roots of Nordrassil" } },
                        { achievementID = 61582, criteriaID = 110370, label = "Fungara Village",
                          waypoint = { M.Harandar, 0.4454, 0.6280, "Fungara Village" } },
                        { achievementID = 61582, criteriaID = 110371, label = "Rift of Aln",
                          waypoint = { M.Harandar, 0.6186, 0.6750, "Rift of Aln" } },
                        { achievementID = 61582, criteriaID = 112628, label = "Roots of Teldrassil",
                          waypoint = { M.Harandar, 0.3450, 0.2360, "Roots of Teldrassil" } },
                    },
                },
            },
            {
                achievementID = 61583,
                name          = "Glyph Hunter: Voidstorm",
                zone          = "Voidstorm",
                description   = "Collect every Skyriding Glyph in Voidstorm.",
                taskList = {
                    intro = "Glowing tomes hovering above the landscape. Skyride through each one to count it.",
                    tasks = {
                        { achievementID = 61583, criteriaID = 110372, label = "The Voidspire",
                          waypoint = { M.Voidstorm, 0.5135, 0.6271, "The Voidspire" } },
                        { achievementID = 61583, criteriaID = 110373, label = "The Molt",
                          waypoint = { M.Voidstorm, 0.3716, 0.4996, "The Molt" } },
                        { achievementID = 61583, criteriaID = 110374, label = "The Ingress",
                          waypoint = { M.Voidstorm, 0.3567, 0.6109, "The Ingress" } },
                        { achievementID = 61583, criteriaID = 110375, label = "The Bladeburrows",
                          waypoint = { M.Voidstorm, 0.3990, 0.7098, "The Bladeburrows" } },
                        { achievementID = 61583, criteriaID = 110376, label = "Gnawing Reach",
                          waypoint = { M.Voidstorm, 0.5495, 0.4554, "Gnawing Reach" } },
                        { achievementID = 61583, criteriaID = 110377, label = "Hanaar Outpost (Slayer's Rise)",
                          waypoint = { M.SlayersRise, 0.3622, 0.4497, "Hanaar Outpost" } },
                        { achievementID = 61583, criteriaID = 110378, label = "Ethereum Refinery",
                          waypoint = { M.Voidstorm, 0.3891, 0.7611, "Ethereum Refinery" } },
                        { achievementID = 61583, criteriaID = 110379, label = "Master's Perch",
                          waypoint = { M.Voidstorm, 0.4530, 0.5226, "Master's Perch" } },
                        { achievementID = 61583, criteriaID = 110380, label = "Obscurion Citadel",
                          waypoint = { M.Voidstorm, 0.6508, 0.7193, "Obscurion Citadel" } },
                        { achievementID = 61583, criteriaID = 110381, label = "Shadowguard Point",
                          waypoint = { M.Voidstorm, 0.3605, 0.3726, "Shadowguard Point" } },
                        { achievementID = 61583, criteriaID = 110382, label = "The Gorging Pit",
                          waypoint = { M.Voidstorm, 0.4927, 0.8746, "The Gorging Pit" } },
                    },
                },
            },
        },
    },

    --------------------------------------------------------------------
    -- Midnight Lore Hunter: 21 lore objects scattered across all four
    -- zones. One achievement; criteria span every zone. Each is a
    -- single-use interactable on the ground (tablet, mural, runestone,
    -- etc.).
    --------------------------------------------------------------------
    {
        category = "exploration",
        source = "lore",
        achievements = {
            {
                achievementID = 62104,
                name          = "Midnight Lore Hunter",
                zone          = "Midnight (all zones)",
                description   = "Find every lore object in the four Midnight zones.",
                taskList = {
                    intro = "Each lore object is a single-use ground interactable (tablet, mural, runestone, plaque). Reading one gives 250 reputation with that zone's faction.",
                    tasks = {
                        -- Eversong Woods (faction 2710 Silvermoon Court)
                        { achievementID = 62104, criteriaID = 111828, label = "Memorial Plaque (Eversong)",
                          waypoint = { M.Eversong, 0.4795, 0.8820, "Memorial Plaque" } },
                        { achievementID = 62104, criteriaID = 111829, label = "Shrine of Dath'remar (Eversong)",
                          waypoint = { M.Eversong, 0.3760, 0.1378, "Shrine of Dath'remar" } },
                        { achievementID = 62104, criteriaID = 111830, label = "Mirveda's Notes — Dead Scar (Eversong)",
                          waypoint = { M.Eversong, 0.5052, 0.4347, "Mirveda's Notes" } },
                        { achievementID = 62104, criteriaID = 111831, label = "Dar'khan's Notes — Profane Research (Eversong)",
                          waypoint = { M.Eversong, 0.3605, 0.7251, "Dar'khan's Notes" } },
                        { achievementID = 62104, criteriaID = 111832, label = "Hawkstrider Husbandry Manual (Eversong)",
                          waypoint = { M.Eversong, 0.5781, 0.5092, "Hawkstrider Husbandry Manual" } },
                        { achievementID = 62104, criteriaID = 111833, label = "Unfinished Sheet Music (Silvermoon City)",
                          waypoint = { M.Silvermoon, 0.3810, 0.7699, "Unfinished Sheet Music" } },

                        -- Harandar (faction 2704 Hara'ti)
                        { achievementID = 62104, criteriaID = 111823, label = "Tarnished Mural (Harandar)",
                          waypoint = { M.Harandar, 0.5566, 0.5402, "Tarnished Mural" } },
                        { achievementID = 62104, criteriaID = 111824, label = "Ancient Runestone (Harandar)",
                          waypoint = { M.Harandar, 0.3333, 0.6084, "Ancient Runestone" } },
                        { achievementID = 62104, criteriaID = 111825, label = "Derelict Mural (Harandar)",
                          waypoint = { M.Harandar, 0.7244, 0.3809, "Derelict Mural" } },
                        { achievementID = 62104, criteriaID = 111826, label = "Forgotten Mural (Harandar)",
                          waypoint = { M.Harandar, 0.6821, 0.2379, "Forgotten Mural" } },

                        -- Voidstorm (faction 2699 The Singularity)
                        { achievementID = 62104, criteriaID = 111834, label = "Void Armor (Voidstorm)",
                          waypoint = { M.Voidstorm, 0.6342, 0.7822, "Void Armor" } },
                        { achievementID = 62104, criteriaID = 111835, label = "Ancient Tablet (Voidstorm)",
                          waypoint = { M.Voidstorm, 0.5032, 0.8768, "Ancient Tablet" } },
                        { achievementID = 62104, criteriaID = 111836, label = "Abandoned Telescope (Voidstorm)",
                          waypoint = { M.Voidstorm, 0.4048, 0.5863, "Abandoned Telescope" } },
                        { achievementID = 62104, criteriaID = 111837, label = "Tattered Page (Voidstorm)",
                          waypoint = { M.Voidstorm, 0.6038, 0.4550, "Tattered Page" } },
                        { achievementID = 62104, criteriaID = 111838, label = "Shadowgraft Harness (Voidstorm)",
                          waypoint = { M.Voidstorm, 0.2783, 0.5402, "Shadowgraft Harness" } },

                        -- Zul'Aman (faction 2696 Amani Tribe)
                        { achievementID = 62104, criteriaID = 111772, label = "Tablet of Akil'zon (Zul'Aman)",
                          waypoint = { M.ZulAman, 0.5310, 0.8211, "Tablet of Akil'zon" } },
                        { achievementID = 62104, criteriaID = 111773, label = "Tablet of Halazzi (Zul'Aman)",
                          waypoint = { M.ZulAman, 0.3208, 0.3165, "Tablet of Halazzi" } },
                        { achievementID = 62104, criteriaID = 111774, label = "Tablet of Jan'alai (Zul'Aman)",
                          waypoint = { M.ZulAman, 0.5513, 0.1762, "Tablet of Jan'alai" } },
                        { achievementID = 62104, criteriaID = 111775, label = "Tablet of Nalorakk (Zul'Aman)",
                          waypoint = { M.ZulAman, 0.3017, 0.8466, "Tablet of Nalorakk" } },
                        { achievementID = 62104, criteriaID = 111777, label = "Tablet of Kulzi (Zul'Aman)",
                          waypoint = { M.ZulAman, 0.3926, 0.4472, "Tablet of Kulzi" } },
                        { achievementID = 62104, criteriaID = 111778, label = "Tablet of Filo (Zul'Aman)",
                          waypoint = { M.ZulAman, 0.5292, 0.3212, "Tablet of Filo" } },
                    },
                },
            },
        },
    },

    --------------------------------------------------------------------
    -- Ever Painting: 7 paintings to admire across Eversong Woods.
    -- Most are at named landmarks; "Light Consuming" sits on a flying
    -- platform off the ground.
    --------------------------------------------------------------------
    {
        category = "exploration",
        source = "paintings",
        achievements = {
            {
                achievementID = 62185,
                name          = "Ever Painting",
                zone          = "Eversong Woods",
                description   = "Admire all seven paintings scattered around Eversong Woods.",
                taskList = {
                    intro = "Each is a small framed painting at a fixed spot. Right-click it to admire.",
                    tasks = {
                        { achievementID = 62185, criteriaID = 111993, label = "Sway of Red and Gold",
                          waypoint = { M.Eversong, 0.5396, 0.7560, "Sway of Red and Gold" } },
                        { achievementID = 62185, criteriaID = 112030, label = "Lost Lamppost",
                          waypoint = { M.Eversong, 0.4180, 0.5634, "Lost Lamppost" } },
                        { achievementID = 62185, criteriaID = 112031, label = "Anar'alah Belore",
                          waypoint = { M.Eversong, 0.5076, 0.4128, "Anar'alah Belore" } },
                        { achievementID = 62185, criteriaID = 112032, label = "Light Consuming (on flying platform)",
                          waypoint = { M.Eversong, 0.5514, 0.5968, "Light Consuming — flying platform" } },
                        { achievementID = 62185, criteriaID = 112033, label = "Babble and Brook",
                          waypoint = { M.Eversong, 0.4608, 0.6429, "Babble and Brook" } },
                        { achievementID = 62185, criteriaID = 112034, label = "Memories of Ghosts",
                          waypoint = { M.Eversong, 0.3900, 0.7822, "Memories of Ghosts" } },
                        { achievementID = 62185, criteriaID = 112035, label = "Elrendar's Song",
                          waypoint = { M.Eversong, 0.4262, 0.6263, "Elrendar's Song" } },
                    },
                },
            },
        },
    },

    --------------------------------------------------------------------
    -- Meta achievements. Each rolls up several sub-achievements; the
    -- taskList tracks completion of each component. No waypoints —
    -- visit the sub-achievement's row for those.
    --------------------------------------------------------------------
    {
        category = "exploration",
        source = "metas",
        achievements = {
            {
                achievementID = 62386,
                name          = "Light Up the Night",
                zone          = "Midnight (all zones)",
                description   = "Complete each of the four zone metas. Rewards the Brilliant Petalwing mount.",
                score         = T.legendary,  -- top-level grand meta
                taskList = {
                    intro = "One meta per zone. Finish all four and the mount is yours.",
                    tasks = {
                        { achievementID = 62261, label = "Forever Song (Eversong Woods)" },
                        { achievementID = 61453, label = "Making an Amani Out of You (Zul'Aman)" },
                        { achievementID = 62260, label = "That's Aln, Folks! (Harandar)" },
                        { achievementID = 62256, label = "Yelling into the Voidstorm (Voidstorm)" },
                    },
                },
            },
            {
                achievementID = 62057,
                name          = "Midnight: The Highest Peaks",
                zone          = "Midnight (all zones)",
                description   = "Complete the Highest Peaks vista achievement in every Midnight zone.",
                taskList = {
                    intro = "Find every telescope across the four zones.",
                    tasks = {
                        { achievementID = 62288, label = "Highest Peaks: Eversong Woods" },
                        { achievementID = 62289, label = "Highest Peaks: Zul'Aman" },
                        { achievementID = 62290, label = "Highest Peaks: Harandar" },
                        { achievementID = 62291, label = "Highest Peaks: Voidstorm" },
                    },
                },
            },
            {
                achievementID = 61854,
                name          = "The Midnight Explorer",
                zone          = "Midnight (all zones)",
                description   = "Discover every named sub-zone across all four Midnight zones.",
                taskList = {
                    intro = "Complete each zone's Explorer achievement.",
                    tasks = {
                        { achievementID = 61855, label = "Explore Eversong Woods" },
                        { achievementID = 61856, label = "Explore Zul'Aman" },
                        { achievementID = 61520, label = "Explore Harandar" },
                        { achievementID = 61857, label = "Explore Voidstorm" },
                    },
                },
            },
            {
                achievementID = 62261,
                name          = "Forever Song",
                zone          = "Eversong Woods",
                description   = "The Eversong Woods meta. Combines every Eversong sub-achievement below.",
                taskList = {
                    intro = "Complete each row to finish the meta.",
                    tasks = {
                        { achievementID = 61855, label = "Explore Eversong Woods" },
                        { achievementID = 61960, label = "Treasures of Eversong Woods" },
                        { achievementID = 61507, label = "A Bloody Song (Eversong rares)" },
                        { achievementID = 61576, label = "Glyph Hunter: Eversong Woods" },
                        { achievementID = 62288, label = "Highest Peaks: Eversong Woods" },
                        { achievementID = 62185, label = "Ever Painting" },
                    },
                },
            },
            {
                achievementID = 61453,
                name          = "Making an Amani Out of You",
                zone          = "Zul'Aman",
                description   = "The Zul'Aman meta. Finish every Zul'Aman achievement to earn it.",
                taskList = {
                    intro = "Hit each row below.",
                    tasks = {
                        { achievementID = 61856, label = "Explore Zul'Aman" },
                        { achievementID = 62125, label = "Treasures of Zul'Aman" },
                        { achievementID = 62122, label = "Tallest Tree in the Forest (Zul'Aman rares)" },
                        { achievementID = 61581, label = "Glyph Hunter: Zul'Aman" },
                        { achievementID = 62289, label = "Highest Peaks: Zul'Aman" },
                    },
                },
            },
            {
                achievementID = 62260,
                name          = "That's Aln, Folks!",
                zone          = "Harandar",
                description   = "The Harandar meta. Wraps up every Harandar achievement at once.",
                taskList = {
                    intro = "Each Harandar row below contributes.",
                    tasks = {
                        { achievementID = 61520, label = "Explore Harandar" },
                        { achievementID = 61263, label = "Treasures of Harandar" },
                        { achievementID = 61264, label = "Leaf None Behind (Harandar rares)" },
                        { achievementID = 61582, label = "Glyph Hunter: Harandar" },
                        { achievementID = 62290, label = "Highest Peaks: Harandar" },
                        { achievementID = 61574, label = "Legends Never Die" },
                    },
                },
            },
            {
                achievementID = 62256,
                name          = "Yelling into the Voidstorm",
                zone          = "Voidstorm",
                description   = "The Voidstorm meta. Earn it by clearing every Voidstorm achievement.",
                taskList = {
                    intro = "All four Voidstorm rows below contribute.",
                    tasks = {
                        { achievementID = 61857, label = "Explore Voidstorm" },
                        { achievementID = 62126, label = "Treasures of Voidstorm" },
                        { achievementID = 62130, label = "The Ultimate Predator (Voidstorm rares)" },
                        { achievementID = 61583, label = "Glyph Hunter: Voidstorm" },
                        { achievementID = 62291, label = "Highest Peaks: Voidstorm" },
                    },
                },
            },
        },
    },

    --------------------------------------------------------------------
    -- Zone Explorer achievements. Each criterion is a discrete sub-zone
    -- name; walking into it triggers the discovery. Names are pulled
    -- live by the scanner via GetAchievementCriteriaInfo so they match
    -- the in-game text exactly.
    --------------------------------------------------------------------
    {
        category = "exploration",
        source = "explore",
        achievements = {
            {
                achievementID = 61855,
                name          = "Explore Eversong Woods",
                zone          = "Eversong Woods",
                description   = "Discover every named sub-zone in Eversong Woods. Walk into each one — the area name fades onto the screen.",
            },
            {
                achievementID = 61856,
                name          = "Explore Zul'Aman",
                zone          = "Zul'Aman",
                description   = "Discover every named sub-zone in Zul'Aman.",
            },
            {
                achievementID = 61520,
                name          = "Explore Harandar",
                zone          = "Harandar",
                description   = "Discover every named sub-zone in Harandar.",
            },
            {
                achievementID = 61857,
                name          = "Explore Voidstorm",
                zone          = "Voidstorm",
                description   = "Discover every named sub-zone in Voidstorm.",
            },
        },
    },

    --------------------------------------------------------------------
    -- Zone-specific exploration achievements with waypoints.
    --------------------------------------------------------------------
    {
        category = "exploration",
        source = "zone",
        achievements = {
            {
                achievementID = 61961,
                name          = "Runestone Rush",
                zone          = "Eversong Woods",
                description   = "Defend each Eversong runestone from the boss that spawns when you tap it.",
                taskList = {
                    intro = "Click a runestone to summon its boss. Kill the boss and that runestone counts.",
                    tasks = {
                        { achievementID = 61961, criteriaID = 111480, label = "Elrendar River Runestone (Sapmaw the Infestor)",
                          waypoint = { M.Eversong, 0.4740, 0.5860, "Elrendar River Runestone" } },
                        { achievementID = 61961, criteriaID = 111481, label = "Ath'ran Runestone (Commander Viskaj)",
                          waypoint = { M.Eversong, 0.3840, 0.5580, "Ath'ran Runestone" } },
                        { achievementID = 61961, criteriaID = 111482, label = "Dawnstar Spire Runestone (Hal'nok the Trampler)",
                          waypoint = { M.Eversong, 0.6140, 0.6280, "Dawnstar Spire Runestone" } },
                        { achievementID = 61961, criteriaID = 111483, label = "Sanctum of the Moon Runestone (Commander Gravok)",
                          waypoint = { M.Eversong, 0.4100, 0.7380, "Sanctum of the Moon Runestone" } },
                        { achievementID = 61961, criteriaID = 111484, label = "Sunstrider Isle Runestone (Claw of the Void)",
                          waypoint = { M.Eversong, 0.4060, 0.1360, "Sunstrider Isle Runestone" } },
                    },
                },
            },
            -- The following are tracked at the achievement level. They
            -- have richer per-criterion guides we can fill in later from
            -- HandyNotes; for now players see overall progress + the
            -- live achievement description.
            {
                achievementID = 62186,
                name          = "The Party Must Go On",
                zone          = "Eversong Woods",
                description   = "Send invitations to all four factions at Saltheril's Haven, then attend each weekly party.",
                taskList = {
                    intro = "Saltheril's Haven, Eversong Woods (38, 73). One faction per week.",
                    tasks = {
                        { achievementID = 62186, label = "Invite Blood Knights",
                          waypoint = { M.Eversong, 0.3800, 0.7300, "Saltheril's Haven" } },
                        { achievementID = 62186, label = "Invite Magisters",
                          waypoint = { M.Eversong, 0.3800, 0.7300, "Saltheril's Haven" } },
                        { achievementID = 62186, label = "Invite Farstriders",
                          waypoint = { M.Eversong, 0.3800, 0.7300, "Saltheril's Haven" } },
                        { achievementID = 62186, label = "Invite Shades of the Row",
                          waypoint = { M.Eversong, 0.3800, 0.7300, "Saltheril's Haven" } },
                    },
                },
            },
            {
                achievementID = 61574,
                name          = "Legends Never Die",
                zone          = "Harandar",
                description   = "Complete the seven Haranir storyline quests in Harandar. Reward: On'ohia's Call decoration.",
            },
            {
                achievementID = 62121,
                name          = "Sacred Buffet Devotee",
                zone          = "Zul'Aman",
                description   = "Receive every blessing at the Altar of Blessings (Amani'Zar Village).",
                waypoint      = { M.ZulAman, 0.4316, 0.6928, "Altar of Blessings" },
            },
            {
                achievementID = 62133,
                name          = "Thrill of the Chase",
                zone          = "Voidstorm",
                description   = "Complete the Voidstorm hunt event — kill the wandering apex predators.",
            },
            {
                achievementID = 61913,
                name          = "A Singular Problem",
                zone          = "Voidstorm",
                description   = "Complete each phase of the Singularity Renown side quest.",
            },
            {
                achievementID = 61860,
                name          = "From The Cradle to the Grave",
                zone          = "Harandar",
                description   = "Fly upward above The Den until you find The Cradle.",
                waypoint      = { M.Harandar, 0.4930, 0.5436, "The Cradle (fly UP)" },
            },
            {
                achievementID = 61219,
                name          = "No Time to Paws",
                zone          = "Harandar",
                description   = "Complete the Lil' Scoots quest chain in record time.",
            },
            {
                achievementID = 61344,
                name          = "Chronicler of the Haranir",
                zone          = "Harandar",
                description   = "Read all 21 Haranir lore books across 7 storyline-gated series.",
                taskList = {
                    intro = "21 books in 7 series. Each series only spawns its books once you've finished its parent campaign quest. If a parent below shows |cffff5555[ ]|r, that series isn't unlocked yet.",
                    tasks = {
                        -- Series 1: Laments of Wey'nan
                        { questID = 88993, label = "[Parent] Wey'nan's Ward — unlocks Laments of Wey'nan" },
                        { achievementID = 61344, questID = 93470, label = "Laments of Wey'nan: Pt 1 — Finding Hope",
                          waypoint = { M.Harandar, 0.4323, 0.3733, "Laments of Wey'nan 1" } },
                        { achievementID = 61344, questID = 93471, label = "Laments of Wey'nan: Pt 2 — Hunting Purpose",
                          waypoint = { M.Harandar, 0.4153, 0.3585, "Laments of Wey'nan 2" } },
                        { achievementID = 61344, questID = 93472, label = "Laments of Wey'nan: Pt 3 — There Must Be More",
                          waypoint = { M.Harandar, 0.4230, 0.3548, "Laments of Wey'nan 3" } },
                        -- Series 2: Echoes of Our Past
                        { questID = 88994, label = "[Parent] The Cauldron of Echoes — unlocks Echoes of Our Past" },
                        { achievementID = 61344, questID = 93475, label = "Echoes of Our Past: Pt 1 — Fading History",
                          waypoint = { M.Harandar, 0.6000, 0.2089, "Echoes of Our Past 1" } },
                        { achievementID = 61344, questID = 93474, label = "Echoes of Our Past: Pt 2 — Alndust",
                          waypoint = { M.Harandar, 0.5971, 0.1851, "Echoes of Our Past 2" } },
                        { achievementID = 61344, questID = 93473, label = "Echoes of Our Past: Pt 3 — Dangerous Memories",
                          waypoint = { M.Harandar, 0.6115, 0.1596, "Echoes of Our Past 3" } },
                        -- Series 3: Seeker's Trail
                        { questID = 88995, label = "[Parent] Aln'hara's Bloom — unlocks Seeker's Trail" },
                        { achievementID = 61344, questID = 93479, label = "Seeker's Trail: Pt 1 — Call of Aln'hara",
                          waypoint = { M.Harandar, 0.5368, 0.6695, "Seeker's Trail 1" } },
                        { achievementID = 61344, questID = 93478, label = "Seeker's Trail: Pt 2 — Seeking Peace",
                          waypoint = { M.Harandar, 0.5503, 0.6627, "Seeker's Trail 2" } },
                        { achievementID = 61344, questID = 93476, label = "Seeker's Trail: Pt 3 — Unending Mission",
                          waypoint = { M.Harandar, 0.5591, 0.6686, "Seeker's Trail 3" } },
                        -- Series 4: Words of Obayo
                        { questID = 88996, label = "[Parent] The Echoless Flame — unlocks Words of Obayo" },
                        { achievementID = 61344, questID = 93482, label = "Words of Obayo: Pt 1 — The Flame",
                          waypoint = { M.Harandar, 0.6485, 0.3846, "Words of Obayo 1" } },
                        { achievementID = 61344, questID = 93481, label = "Words of Obayo: Pt 2 — The Rift",
                          waypoint = { M.Harandar, 0.6143, 0.3503, "Words of Obayo 2" } },
                        { achievementID = 61344, questID = 93480, label = "Words of Obayo: Pt 3 — The Silence",
                          waypoint = { M.Harandar, 0.6259, 0.3571, "Words of Obayo 3" } },
                        -- Series 5: Tending the Lands
                        { questID = 88997, label = "[Parent] Russula's Outreach — unlocks Tending the Lands" },
                        { achievementID = 61344, questID = 93485, label = "Tending the Lands: Pt 1 — The Conflict",
                          waypoint = { M.Harandar, 0.6343, 0.4008, "Tending the Lands 1" } },
                        { achievementID = 61344, questID = 93484, label = "Tending the Lands: Pt 2 — The Plan",
                          waypoint = { M.Harandar, 0.6107, 0.3896, "Tending the Lands 2" } },
                        { achievementID = 61344, questID = 93483, label = "Tending the Lands: Pt 3 — The Cycle",
                          waypoint = { M.Harandar, 0.6138, 0.3716, "Tending the Lands 3" } },
                        -- Series 6: Ways of the Roots
                        { questID = 88998, label = "[Parent] Root of the World — unlocks Ways of the Roots" },
                        { achievementID = 61344, questID = 93488, label = "Ways of the Roots: Pt 1 — Serving",
                          waypoint = { M.Harandar, 0.4083, 0.3629, "Ways of the Roots 1" } },
                        { achievementID = 61344, questID = 93487, label = "Ways of the Roots: Pt 2 — Growing",
                          waypoint = { M.Harandar, 0.4148, 0.3416, "Ways of the Roots 2" } },
                        { achievementID = 61344, questID = 93486, label = "Ways of the Roots: Pt 3 — Pruning",
                          waypoint = { M.Harandar, 0.4051, 0.3471, "Ways of the Roots 3" } },
                        -- Series 7: Awe'ohna's Path — rotating weekly Lost Legends
                        -- (89268) from Zur'ashar Kassameh in The Den. Relic #7
                        -- only unlocks after relics 1-6 on this character.
                        -- Books spawn only the week relic #7 is the active
                        -- relic. Pts 2 & 3 are inside a cave at their coords.
                        { questID = 89268, label = "[Parent] Lost Legends weekly (relic #7) — Zur'ashar Kassameh, The Den",
                          waypoint = { M.Harandar, 0.5415, 0.5314, "Zur'ashar Kassameh" } },
                        { achievementID = 61344, label = "Awe'ohna's Path: Pt 1 — Questions",
                          waypoint = { M.Harandar, 0.7189, 0.5894, "Awe'ohna's Path 1" } },
                        { achievementID = 61344, label = "Awe'ohna's Path: Pt 2 — Answers (inside cave)",
                          waypoint = { M.Harandar, 0.7352, 0.5820, "Awe'ohna's Path 2 (in cave)" } },
                        { achievementID = 61344, label = "Awe'ohna's Path: Pt 3 — The Cradle (inside cave)",
                          waypoint = { M.Harandar, 0.7346, 0.5746, "Awe'ohna's Path 3 (in cave)" } },
                    },
                },
            },
            {
                achievementID = 61052,
                name          = "Dust 'Em Off",
                zone          = "Harandar",
                description   = "Catch all 120 Glowing Moths across Harandar. Moth tiers unlock at Hara'ti Renown 1, 4, and 9. Talk to Mothkeeper Wew'tam to see which moths you still need.",
                waypoint      = { M.Harandar, 0.4930, 0.5436, "Mothkeeper Wew'tam" },
            },
        },
    },

    --------------------------------------------------------------------
    -- Quest metas. Loremaster covers all Midnight zone storylines.
    --------------------------------------------------------------------
    {
        category = "quests",
        source = "metas",
        achievements = {
            {
                achievementID = 62110,
                name          = "Loremaster of Midnight",
                zone          = "Midnight (all zones)",
                description   = "Complete every storyline campaign across the four Midnight zones.",
                -- Sub-achievement IDs not yet confirmed; once they are,
                -- add them as a taskList of achievementID-only tasks.
            },
        },
    },

    --------------------------------------------------------------------
    -- Cross-zone Abundance event achievement. Same waypoints as the
    -- Dundun's Travel Method toy (Toys module).
    --------------------------------------------------------------------
    {
        category = "exploration",
        source = "events",
        achievements = {
            {
                achievementID = 61943,
                name          = "Abundance: Prosperous Plentitude!",
                zone          = "Midnight (all zones)",
                description   = "Visit the weekly Abundance event in each of the four Midnight zones.",
                taskList = {
                    intro = "Abundance rotates between zones weekly. Visit each location once over the rotation.",
                    tasks = {
                        { achievementID = 61943, criteriaID = 111431, label = "Watha'nan Crypts (Eversong)",
                          waypoint = { M.Eversong, 0.5678, 0.6579, "Watha'nan Crypts" } },
                        { achievementID = 61943, criteriaID = 111432, label = "Loaknit Den (Zul'Aman)",
                          waypoint = { M.ZulAman, 0.3162, 0.2614, "Loaknit Den" } },
                        { achievementID = 61943, criteriaID = 111433, label = "Floaret Grotto (Harandar)",
                          waypoint = { M.Harandar, 0.6614, 0.6169, "Floaret Grotto" } },
                        { achievementID = 61943, criteriaID = 111434, label = "Abundant Voidburrow (Voidstorm)",
                          waypoint = { M.Voidstorm, 0.3882, 0.5331, "Abundant Voidburrow" } },
                    },
                },
            },
        },
    },

    --------------------------------------------------------------------
    -- Collections > Pets. Wild-pet collection scoped to Midnight zones.
    --------------------------------------------------------------------
    {
        category = "collections",
        source = "pets",
        achievements = {
            {
                achievementID = 61091,
                name          = "Midnight Safari",
                zone          = "Midnight (all zones)",
                description   = "Catch all 21 new wild pets across the Midnight zones. The Pets tab tracks each one individually with waypoints.",
            },
            {
                achievementID = 15644,
                name          = "Good Things Come in Small Packages",
                zone          = "Account-wide",
                description   = "Collect 1800 unique pets. Reward: Mister Muskoxeles. Current top of the pet-collection ladder.",
                score         = T.legendary,  -- account-wide ultimate collection tier
            },
        },
    },

    --------------------------------------------------------------------
    -- Collections > Mounts. Glory metas + collector tier.
    --------------------------------------------------------------------
    {
        category = "collections",
        source = "mounts",
        achievements = {
            {
                achievementID = 61568,
                name          = "Glory of the Midnight Hero",
                zone          = "Midnight dungeons",
                description   = "Complete every Midnight dungeon achievement on Mythic. Reward: a Midnight dungeon-hero mount.",
            },
            {
                achievementID = 61380,
                name          = "Glory of the Midnight Raider",
                zone          = "Midnight raids",
                description   = "Complete the curated raid achievements across The Dreamrift, The Voidspire, and March on Quel'Danas. Reward: Tenebrous Harrower mount.",
            },
            {
                achievementID = 62096,
                name          = "Insurmountable Collection",
                zone          = "Account-wide",
                description   = "Collect 600 mounts on a single character. Reward: Anu'shalla, Shadow's Guidance.",
                score         = T.legendary,  -- account-wide ultimate collection tier
            },
        },
    },

    --------------------------------------------------------------------
    -- Collections > Toys. Hidden FoS + Pinterest promo.
    --------------------------------------------------------------------
    {
        category = "collections",
        source = "toys",
        achievements = {
            {
                achievementID = 62388,
                name          = "Illicit Rain: Five Stars",
                zone          = "Eversong Woods",
                description   = "Earn a Five Star Review at the Illicit Rain show. Reward: Feeling Fielder Mk. 7 toy.",
            },
            {
                achievementID = 62400,
                name          = "Craft Your World",
                zone          = "Out-of-game",
                description   = "Connect your WoW account to Pinterest via the official promo page. Reward: Pin-o-Matic Camera toy.",
            },
            {
                achievementID = 15781,
                name          = "The Joy of Toy",
                zone          = "Account-wide",
                description   = "Collect 500 toys. Reward: Murglasses. Current top of the toy-collection ladder.",
                score         = T.legendary,  -- account-wide ultimate collection tier
            },
        },
    },

    --------------------------------------------------------------------
    -- Features > Prey. Voidstorm-style hunt event spanning all zones.
    --------------------------------------------------------------------
    {
        category = "features",
        source = "prey",
        achievements = {
            {
                achievementID = 62351,
                name          = "Preying For Midnight",
                zone          = "Midnight (all zones)",
                description   = "Complete every Prey achievement. Rewards the Preyseeker title.",
                taskList = {
                    intro = "Each Prey hunt achievement below counts toward the title.",
                    tasks = {
                        { achievementID = 62383, label = "Gotta Hunt Them All" },
                        { achievementID = 62139, label = "Midnight Hunter" },
                        { achievementID = 62138, label = "You're Trapped In Here With Me" },
                        { achievementID = 62140, label = "Kitchen Nightmare" },
                        { achievementID = 62141, label = "Look, I'm Just Trying To Fish Here" },
                        { achievementID = 62142, label = "I Didn't Hear No Bell" },
                        { achievementID = 62143, label = "Trapped In The Middle With You" },
                    },
                },
            },
            {
                achievementID = 62383,
                name          = "Gotta Hunt Them All",
                zone          = "Midnight (all zones)",
                description   = "Defeat all 32 named Prey targets across the four Midnight zones. Difficulty doesn't matter.",
            },
            {
                achievementID = 62139,
                name          = "Midnight Hunter",
                zone          = "Midnight (all zones)",
                description   = "Complete a Prey Hunt in each of Eversong, Zul'Aman, Harandar, and Voidstorm.",
            },
            {
                achievementID = 62138,
                name          = "You're Trapped In Here With Me",
                zone          = "Midnight (all zones)",
                description   = "Defeat 100 Prey Ambushes. They spawn unexpectedly while you have a Prey hunt active.",
            },
            {
                achievementID = 62140,
                name          = "Kitchen Nightmare",
                zone          = "Midnight (all zones)",
                description   = "Cook 100 things while a Nightmare Prey hunt is active.",
            },
            {
                achievementID = 62141,
                name          = "Look, I'm Just Trying To Fish Here",
                zone          = "Midnight (all zones)",
                description   = "Catch 100 fish while a Nightmare Prey hunt is active.",
            },
            {
                achievementID = 62142,
                name          = "I Didn't Hear No Bell",
                zone          = "Midnight (all zones)",
                description   = "Deliver 50 Riposte attacks after being ambushed during a Prey hunt.",
            },
            {
                achievementID = 62143,
                name          = "Trapped In The Middle With You",
                zone          = "Midnight (all zones)",
                description   = "Interact with 100 traps during Prey hunts.",
            },
        },
    },

    --------------------------------------------------------------------
    -- Features > Void Assaults. Per-zone strike completion ladders +
    -- the Void Response Team meta which unlocks Unbound Manawyrm.
    --------------------------------------------------------------------
    {
        category = "features",
        source = "void_assaults",
        achievements = {
            {
                achievementID = 62563,
                name          = "Void Response Team",
                zone          = "Eversong + Zul'Aman",
                description   = "Complete the Void Assault meta. Unlocks the Unbound Manawyrm purchase from Sergeant Vornin.",
                taskList = {
                    intro = "Mix of Eversong and Zul'Aman Void Assault tiers, plus the Field Accolade and corrupted-kill counters.",
                    tasks = {
                        { achievementID = 62498, label = "Void Assault: Eversong (1)" },
                        { achievementID = 62508, label = "Void Eradicator: Eversong (25)" },
                        { achievementID = 62513, label = "Outstanding in the Field (100 accolades)" },
                        { achievementID = 62499, label = "Void Assault: Zul'Aman (1)" },
                        { achievementID = 62511, label = "Void Eradicator: Zul'Aman (25)" },
                        { achievementID = 62518, label = "Cosmic Exterminator (100 corrupted)" },
                    },
                },
            },
            { achievementID = 62498, name = "Void Assault: Eversong", zone = "Eversong Woods",
              description = "Complete one Void Strike or Incursion in Eversong." },
            { achievementID = 62507, name = "Void Smasher: Eversong", zone = "Eversong Woods",
              description = "Complete 10 Void Strikes/Incursions in Eversong." },
            { achievementID = 62508, name = "Void Eradicator: Eversong", zone = "Eversong Woods",
              description = "Complete 25 Void Strikes/Incursions in Eversong." },
            { achievementID = 62509, name = "Void Bane: Eversong", zone = "Eversong Woods",
              description = "Complete 50 Void Strikes/Incursions in Eversong." },
            { achievementID = 62499, name = "Void Assault: Zul'Aman", zone = "Zul'Aman",
              description = "Complete one Void Strike or Incursion in Zul'Aman." },
            { achievementID = 62510, name = "Void Smasher: Zul'Aman", zone = "Zul'Aman",
              description = "Complete 10 Void Strikes/Incursions in Zul'Aman." },
            { achievementID = 62511, name = "Void Eradicator: Zul'Aman", zone = "Zul'Aman",
              description = "Complete 25 Void Strikes/Incursions in Zul'Aman." },
            { achievementID = 62512, name = "Void Bane: Zul'Aman", zone = "Zul'Aman",
              description = "Complete 50 Void Strikes/Incursions in Zul'Aman." },
            { achievementID = 62513, name = "Outstanding in the Field", zone = "Eversong + Zul'Aman",
              description = "Earn 100 Field Accolades from Ritual Sites or Void Assaults combined." },
            { achievementID = 62574, name = "Accolade to Rest", zone = "Eversong + Zul'Aman",
              description = "Earn 500 Field Accolades from Ritual Sites or Void Assaults combined." },
            { achievementID = 62518, name = "Cosmic Exterminator", zone = "Eversong + Zul'Aman",
              description = "Defeat 100 corrupted creatures inside Void Strikes. Reward: unlocks Cappy." },
        },
    },

    --------------------------------------------------------------------
    -- Features > Ritual Sites (12.0.5). Two live sites: Broken Throne
    -- (Zul'Aman) and Daggerspine Point (Eversong).
    --------------------------------------------------------------------
    {
        category = "features",
        source = "ritual_sites",
        achievements = {
            {
                achievementID = 62562,
                name          = "Ritual Site Disruptor",
                zone          = "Eversong + Zul'Aman",
                description   = "Complete the Ritual Sites meta.",
                taskList = {
                    intro = "You'll need a Tier 3 clear, Renown 8 with the Ritual Sites faction, and all 8 challenges unlocked.",
                    tasks = {
                        { achievementID = 62452, label = "Ritual Sites 320 (Tier 3)" },
                        { achievementID = 62622, label = "Ritual Renown (rank 8)" },
                        { achievementID = 62621, label = "Challenging Sites (8 challenges unlocked)" },
                    },
                },
            },
            { achievementID = 62452, name = "Ritual Sites 320",
              zone = "Eversong + Zul'Aman",
              description = "Complete a Tier 3 Ritual Site. Tiers go 1 (101 score) up through 5 (505 score)." },
            { achievementID = 62622, name = "Ritual Renown",
              zone = "Eversong + Zul'Aman",
              description = "Reach Renown Rank 8 with the Ritual Sites faction." },
            { achievementID = 62621, name = "Challenging Sites",
              zone = "Eversong + Zul'Aman",
              description = "Unlock all 8 Ritual Site challenges (Tendrils, Magical Alarm Bells, Patrols, Manifestations, Tainted Corpses, Reinforced, Malevolent Boons, Embers)." },
            { achievementID = 62521, name = "Ritual Site: Broken Throne",
              zone = "Zul'Aman",
              description = "Disrupt the Broken Throne Ritual Site once." },
            { achievementID = 62523, name = "Ritual Site Mastery: Broken Throne",
              zone = "Zul'Aman",
              description = "Disrupt Broken Throne at Tier 5 (505 score)." },
            { achievementID = 62524, name = "Ritual Site Challenge: Broken Throne",
              zone = "Zul'Aman",
              description = "Disrupt Broken Throne with at least 8 challenges active." },
            { achievementID = 62525, name = "Ritual Site Extreme: Broken Throne",
              zone = "Zul'Aman",
              description = "Disrupt Broken Throne at Tier 5 with all 8 challenges active." },
            { achievementID = 62522, name = "Ritual Site: Daggerspine Point",
              zone = "Eversong Woods",
              description = "Disrupt the Daggerspine Point Ritual Site once." },
            { achievementID = 62527, name = "Ritual Site Challenge: Daggerspine Point",
              zone = "Eversong Woods",
              description = "Disrupt Daggerspine Point with at least 8 challenges active." },
        },
    },
})
