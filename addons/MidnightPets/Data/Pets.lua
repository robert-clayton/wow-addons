local _, MP = ...

MP.PET_TYPE_NAMES = {
    [1] = "Humanoid", [2] = "Dragonkin", [3] = "Flying", [4] = "Undead",
    [5] = "Critter", [6] = "Magic", [7] = "Elemental", [8] = "Beast",
    [9] = "Aquatic", [10] = "Mechanical",
}

MP.SOURCE_ORDER = { "wild", "vendor", "drop", "quest", "treasure", "achievement", "delve", "profession", "tradingpost", "event" }
MP.SOURCE_LABELS = {
    wild = "Wild", vendor = "Vendor", drop = "Drop",
    quest = "Quest", treasure = "Treasure", achievement = "Achievement",
    delve = "Delve", profession = "Profession", tradingpost = "Trading Post",
    event = "Event / Promo",
}

-- NPC/location waypoint data: { mapID, x, y, "Display Name" }
-- Midnight uiMapIDs: Silvermoon=2393, Eversong=2395, Zul'Aman=2437,
--                    Harandar=2413, Voidstorm=2405, Isle of Quel'Danas=2424
local LOC = {
    -- Per-pet wild spawn coordinates (center of spawn area from Wowhead data)
    -- Eversong Woods (mapID 2395)
    AmberTreeflitter = { 2395, 0.508, 0.634, "Amber Treeflitter" },       -- 27 spawns, zone-wide
    VibrantManaling  = { 2395, 0.462, 0.546, "Vibrant Manaling" },        -- 27 spawns, zone-wide
    VioletChick      = { 2395, 0.500, 0.684, "Violet Chick" },            -- 15 spawns, uncommon
    -- Silvermoon City (mapID 2393)
    SilvermoonBroom  = { 2393, 0.305, 0.783, "Silvermoon Broom" },        -- 25 spawns, tight patrol loop
    -- Harandar (mapID 2413)
    AzureSporebat    = { 2413, 0.618, 0.564, "Azure Sporebat" },          -- 22 spawns, zone-wide
    MudPotadpole     = { 2413, 0.703, 0.310, "Mud Potadpole" },           -- 9 spawns, Nordrassil Roots
    RootlingNester   = { 2413, 0.535, 0.517, "Rootling Nester" },         -- 10 spawns, scattered
    Silkcrawler      = { 2413, 0.466, 0.444, "Silkcrawler" },             -- 31 spawns, zone-wide
    Waddles          = { 2413, 0.609, 0.192, "Waddles" },                 -- 9 spawns, waterfall area
    -- Voidstorm (mapID 2405)
    Blistercreepling = { 2405, 0.486, 0.765, "Blistercreepling" },        -- 24 spawns, zone-wide
    DevouringRunt    = { 2405, 0.430, 0.530, "Devouring Runt" },          -- 26 spawns, zone-wide
    RiftbladeFamiliar= { 2405, 0.623, 0.733, "Riftblade Familiar" },      -- 8 spawns, near Obscurian Citadel
    Voidcrawler      = { 2405, 0.434, 0.660, "Voidcrawler" },             -- 27 spawns, zone-wide
    -- Zul'Aman (mapID 2437)
    AkilFledgling    = { 2437, 0.517, 0.783, "Akil Fledgling" },          -- 10 spawns, SE mountain area
    DragonhawkMosswing = { 2437, 0.509, 0.234, "Dragonhawk Mosswing" },   -- 14 spawns, northern islands
    EbonSnapling     = { 2437, 0.392, 0.511, "Ebon Snapling" },           -- 7 spawns in ZA centre
    GloomToad        = { 2437, 0.365, 0.649, "Gloom Toad" },              -- 24 spawns, near water
    Pangolil         = { 2437, 0.440, 0.542, "Pangolil" },                -- 4 spawns, bridge patrol
    StripedSnakebiter= { 2437, 0.472, 0.545, "Striped Snakebiter" },      -- 20 spawns, common
    SwampBiter       = { 2437, 0.447, 0.606, "Swamp Biter" },             -- 18 spawns, zone-wide
    -- Isle of Quel'Danas (mapID 2424)
    NetherFamiliar   = { 2424, 0.424, 0.282, "Nether Familiar" },         -- 43 spawns, northern area
    WrathfulWyrm     = { 2424, 0.436, 0.290, "Wrathful Wyrm" },           -- 25 spawns, Sunwell bridge path

    -- Vendor NPCs
    CaerisFairdawn   = { 2395, 0.435, 0.474, "Caeris Fairdawn, Saltheril's Haven" },
    Anomander        = { 2405, 0.526, 0.729, "Void Researcher Anomander, Voidstorm" },
    Thraxadar        = { 2405, 0.393, 0.811, "Thraxadar, Slayer's Rise" },
    Naynar           = { 2413, 0.510, 0.508, "Naynar, Harandar" },
    Magovu           = { 2437, 0.460, 0.659, "Magovu, Zul'Aman" },
    ApprenticeDiell  = { 2395, 0.434, 0.474, "Apprentice Diell, Eversong Woods" },
    ConstructVanore  = { 2393, 0.557, 0.657, "Construct V'anore, Silvermoon City" },
    NaleideaRivergleam = { 2393, 0.526, 0.780, "Naleidea Rivergleam, Silvermoon City" },

    -- Treasure locations
    BurblingPaintPot  = { 2395, 0.487, 0.754, "Burbling Paint Pot, Eversong Woods" },
    RookeryCache      = { 2393, 0.243, 0.693, "Rookery Cache, Silvermoon City" },
    KemetsCauldron    = { 2413, 0.556, 0.394, "Kemet's Simmering Cauldron, Harandar" },
    SealedGourd       = { 2413, 0.275, 0.680, "Impenetrably Sealed Gourd, Harandar" },
    AbandonedNest     = { 2437, 0.426, 0.524, "Abandoned Nest, Zul'Aman" },
    QuiveringEgg      = { 2405, 0.315, 0.445, "Quivering Egg, Voidstorm" },
    HalfDigestedVisc  = { 2405, 0.380, 0.688, "Half-Digested Viscera, Voidstorm" },

    -- Drop locations
    DameBloodshed     = { 2395, 0.453, 0.387, "Dame Bloodshed, Eversong Woods" },
    StormarionAssault = { 2405, 0.260, 0.680, "Stormarion Assault, Voidstorm" },

    -- Quest chain start NPCs
    Neytar            = { 2413, 0.696, 0.506, "Ney'tar, Harandar" },                     -- chain start: Drift Them Away (92864)
    ZurasharKassameh  = { 2413, 0.542, 0.530, "Zur'ashar Kassameh, Harandar" },          -- chain start: The Listener (90733)
    Chana             = { 2437, 0.454, 0.697, "Chana, Zul'Aman" },                       -- chain start: The Path of Mourning (89565)
    ShiningSpan       = { 2393, 0.482, 0.066, "Shining Span, Silvermoon" },               -- campaign scenario location
    Ravenia           = { 2405, 0.520, 0.674, "Ravenia, Voidstorm" },                    -- chain start: Harvest of Darkness (91363)
    VaelithSunplume   = { 2395, 0.568, 0.356, "Vaelith Sunplume, Eversong Woods" },      -- chain start: One Adventurous Hatchling (89383)
    Hannan            = { 2413, 0.314, 0.648, "Hannan, Harandar" },                      -- chain start: Light Disturbance (92732)
    InstructorAntheol = { 2395, 0.444, 0.454, "Instructor Antheol, Eversong Woods" },    -- chain start: Second Time's a Choice (94388)
}

-- Pet data organized by source type
-- Fields: speciesID, name, petType (1-10), source, sourceInfo,
--         waypoint (optional), cost (optional), dropInfo (optional),
--         achievementID (optional), canBattle, zone (optional),
--         npcID (optional - the NPC ID for the pet creature itself)
--
-- Data sourced from Wowhead (wowhead.com), March 2026.
-- IMPORTANT: Most Midnight "wild" pets are companion-only (cannot battle).
-- Only a handful of Midnight pets can actually enter pet battles.
-- canBattle is set accurately based on Wowhead data.

MP.PetData = {
    -------------------------------------------------------------------------
    -- Wild Pets (Companion-only - caught by right-clicking in the world)
    -- 21 achievement pets + 1 bonus (Silvermoon Broom). All cannot battle.
    -- Required for the Midnight Safari achievement (ID 61091).
    -------------------------------------------------------------------------
    {
        source = "wild",
        pets = {
            -- Eversong Woods
            { speciesID = 3277, npcID = 241500, name = "Amber Treeflitter",     petType = 5,  source = "wild", sourceInfo = "Eversong Woods - common spawn",          canBattle = false, waypoint = LOC.AmberTreeflitter, zone = "Eversong Woods" },
            { speciesID = 4890, npcID = 250572, name = "Vibrant Manaling",      petType = 6,  source = "wild", sourceInfo = "Eversong Woods - common spawn",          canBattle = false, waypoint = LOC.VibrantManaling,  zone = "Eversong Woods" },
            { speciesID = 4877, npcID = 249817, name = "Violet Chick",          petType = 5,  source = "wild", sourceInfo = "Eversong Woods - uncommon spawn",        canBattle = false, waypoint = LOC.VioletChick,      zone = "Eversong Woods" },

            -- Silvermoon City (bonus - not in Midnight Safari achievement)
            { speciesID = 4912, npcID = 254885, name = "Silvermoon Broom",      petType = 6,  source = "wild", sourceInfo = "Silvermoon City - rare (2-3+ hr respawn)", canBattle = false, waypoint = LOC.SilvermoonBroom, zone = "Silvermoon City" },

            -- Harandar
            { speciesID = 4882, npcID = 249822, name = "Azure Sporebat",        petType = 3,  source = "wild", sourceInfo = "Harandar - common",                      canBattle = false, waypoint = LOC.AzureSporebat,    zone = "Harandar" },
            { speciesID = 4876, npcID = 249816, name = "Mud Potadpole",         petType = 9,  source = "wild", sourceInfo = "Harandar - rare (3+ hr respawn)",        canBattle = false, waypoint = LOC.MudPotadpole,     zone = "Harandar" },
            { speciesID = 4875, npcID = 249815, name = "Rootling Nester",       petType = 8,  source = "wild", sourceInfo = "Harandar - uncommon",                    canBattle = false, waypoint = LOC.RootlingNester,   zone = "Harandar" },
            { speciesID = 4886, npcID = 249827, name = "Silkcrawler",           petType = 5,  source = "wild", sourceInfo = "Harandar - common",                      canBattle = false, waypoint = LOC.Silkcrawler,      zone = "Harandar" },
            { speciesID = 4497, npcID = 222077, name = "Waddles",               petType = 9,  source = "wild", sourceInfo = "Harandar - isolated area",               canBattle = false, waypoint = LOC.Waddles,          zone = "Harandar" },

            -- Voidstorm
            { speciesID = 4879, npcID = 249819, name = "Blistercreepling",      petType = 8,  source = "wild", sourceInfo = "Voidstorm - common",                    canBattle = false, waypoint = LOC.Blistercreepling, zone = "Voidstorm" },
            { speciesID = 4790, npcID = 240014, name = "Devouring Runt",        petType = 8,  source = "wild", sourceInfo = "Voidstorm - common",                    canBattle = false, waypoint = LOC.DevouringRunt,    zone = "Voidstorm" },
            { speciesID = 4892, npcID = 250680, name = "Riftblade Familiar",    petType = 6,  source = "wild", sourceInfo = "Voidstorm - rare, near Obscurian Citadel", canBattle = false, waypoint = LOC.RiftbladeFamiliar, zone = "Voidstorm" },
            { speciesID = 4795, npcID = 241439, name = "Voidcrawler",           petType = 6,  source = "wild", sourceInfo = "Voidstorm - multiple locations",         canBattle = false, waypoint = LOC.Voidcrawler,      zone = "Voidstorm" },

            -- Zul'Aman
            { speciesID = 4874, npcID = 249812, name = "Akil Fledgling",        petType = 3,  source = "wild", sourceInfo = "Zul'Aman - SE mountain area",           canBattle = false, waypoint = LOC.AkilFledgling,    zone = "Zul'Aman" },
            { speciesID = 4883, npcID = 249824, name = "Dragonhawk Mosswing",   petType = 3,  source = "wild", sourceInfo = "Zul'Aman - northern islands",           canBattle = false, waypoint = LOC.DragonhawkMosswing, zone = "Zul'Aman" },
            { speciesID = 4878, npcID = 249818, name = "Ebon Snapling",         petType = 8,  source = "wild", sourceInfo = "Zul'Aman - centre zone",                canBattle = false, waypoint = LOC.EbonSnapling,     zone = "Zul'Aman" },
            { speciesID = 4885, npcID = 249826, name = "Gloom Toad",            petType = 9,  source = "wild", sourceInfo = "Zul'Aman - near water areas",           canBattle = false, waypoint = LOC.GloomToad,        zone = "Zul'Aman" },
            { speciesID = 4884, npcID = 249825, name = "Pangolil",              petType = 8,  source = "wild", sourceInfo = "Zul'Aman - bridge patrol, rare (4-8+ hr respawn)", canBattle = false, waypoint = LOC.Pangolil, zone = "Zul'Aman" },
            { speciesID = 3364, npcID = 192368, name = "Striped Snakebiter",    petType = 8,  source = "wild", sourceInfo = "Zul'Aman - common",                     canBattle = false, waypoint = LOC.StripedSnakebiter, zone = "Zul'Aman" },
            { speciesID = 4880, npcID = 249820, name = "Swamp Biter",           petType = 8,  source = "wild", sourceInfo = "Zul'Aman - all zones",                  canBattle = false, waypoint = LOC.SwampBiter,       zone = "Zul'Aman" },

            -- Isle of Quel'Danas
            { speciesID = 4889, npcID = 250571, name = "Nether Familiar",       petType = 6,  source = "wild", sourceInfo = "Isle of Quel'Danas - northern area",    canBattle = false, waypoint = LOC.NetherFamiliar,   zone = "Isle of Quel'Danas" },
            { speciesID = 4891, npcID = 250573, name = "Wrathful Wyrm",         petType = 6,  source = "wild", sourceInfo = "Isle of Quel'Danas - rare (3+ hr respawn)", canBattle = false, waypoint = LOC.WrathfulWyrm, zone = "Isle of Quel'Danas" },
        },
    },

    -------------------------------------------------------------------------
    -- Vendor Pets
    -------------------------------------------------------------------------
    {
        source = "vendor",
        pets = {
            -- Renown vendors (Voidlight Marl, currency 3316)
            { speciesID = 4952, npcID = 256271, name = "Blitzcreek",            petType = 8,  source = "vendor", sourceInfo = "Void Researcher Anomander - Renown 14, The Singularity", canBattle = true,  waypoint = LOC.Anomander, zone = "Voidstorm",
              cost = { currency = { 3316, 2500 } }, renown = { factionID = 2699, level = 14, factionName = "The Singularity" } },
            { speciesID = 4928, npcID = 255257, name = "Dragonhawk Munchkin",   petType = 2,  source = "vendor", sourceInfo = "Caeris Fairdawn - Renown 12, Silvermoon Court",          canBattle = true,  waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods",
              cost = { currency = { 3316, 2500 } }, renown = { factionID = 2710, level = 12, factionName = "Silvermoon Court" } },
            { speciesID = 4984, npcID = 257802, name = "Medusa",                petType = 6,  source = "vendor", sourceInfo = "Thraxadar - Revered, Slayer's Duellum",                  canBattle = false, waypoint = LOC.Thraxadar, zone = "Voidstorm",
              cost = { currency = { 3316, 2500 } }, renown = { factionID = 2770, standing = "Revered", factionName = "Slayer's Duellum" } },
            { speciesID = 4929, npcID = 255295, name = "Munchy",                petType = 8,  source = "vendor", sourceInfo = "Naynar - Renown 12, Hara'ti",                            canBattle = true,  waypoint = LOC.Naynar, zone = "Harandar",
              cost = { currency = { 3316, 2500 } }, renown = { factionID = 2704, level = 12, factionName = "Hara'ti" } },
            { speciesID = 4888, npcID = 250583, name = "Naloki",                petType = 5,  source = "vendor", sourceInfo = "Magovu - Renown 12, Amani Tribe",                        canBattle = false, waypoint = LOC.Magovu, zone = "Zul'Aman",
              cost = { currency = { 3316, 2500 } }, renown = { factionID = 2696, level = 12, factionName = "Amani Tribe" } },

            -- Brimming Arcana vendor (currency 3379)
            { speciesID = 4982, npcID = 257857, name = "Flicker",               petType = 8,  source = "vendor", sourceInfo = "Apprentice Diell - Luminary rank, Magisters",             canBattle = false, waypoint = LOC.ApprenticeDiell, zone = "Eversong Woods",
              cost = { currency = { 3379, 200 } } },

            -- Preyseeker's Journey vendors (Remnant of Anguish, currency 3392)
            { speciesID = 4930, npcID = 255522, name = "Lil' Preyseeker",       petType = 6,  source = "vendor", sourceInfo = "Construct V'anore - Preyseeker's Journey Rank 9",         canBattle = true,  waypoint = LOC.ConstructVanore, zone = "Silvermoon City",
              cost = { currency = { 3392, 1200 } } },
            { speciesID = 4976, npcID = 257546, name = "Voldy",                 petType = 7,  source = "vendor", sourceInfo = "Construct V'anore, Silvermoon City",                      canBattle = false, waypoint = LOC.ConstructVanore, zone = "Silvermoon City",
              cost = { currency = { 3392, 800 } } },

            -- Undercoin vendor (currency 2803)
            { speciesID = 4955, npcID = 256272, name = "Kreepah'zoyd",          petType = 8,  source = "vendor", sourceInfo = "Naleidea Rivergleam - 10,000 Undercoin",                  canBattle = false, waypoint = LOC.NaleideaRivergleam, zone = "Silvermoon City",
              cost = { currency = { 2803, 10000 } } },
        },
    },

    -------------------------------------------------------------------------
    -- Drop Pets
    -------------------------------------------------------------------------
    {
        source = "drop",
        pets = {
            { speciesID = 4985, npcID = 258281, name = "Princess Bloodshed",    petType = 8,  source = "drop", sourceInfo = "Dame Bloodshed (rare), Eversong Woods",   canBattle = true,  waypoint = LOC.DameBloodshed, zone = "Eversong Woods",
              dropInfo = { mob = "Dame Bloodshed", npcID = 255348, zone = "Eversong Woods" } },
            { speciesID = 4983, npcID = 257908, name = "Kai",                   petType = 8,  source = "drop", sourceInfo = "Victorious Stormarion Cache, Voidstorm",   canBattle = true,  waypoint = LOC.StormarionAssault, zone = "Voidstorm",
              dropInfo = { mob = "Stormarion Assault event cache", zone = "Voidstorm" } },
            { speciesID = 4981, npcID = 257695, name = "Nova",                  petType = 5,  source = "drop", sourceInfo = "Slayer's Duellum Trove (Paragon cache)",   canBattle = false, zone = "Voidstorm",
              dropInfo = { mob = "Slayer's Duellum Trove", zone = "Voidstorm" } },
        },
    },

    -------------------------------------------------------------------------
    -- Quest Pets
    -------------------------------------------------------------------------
    {
        source = "quest",
        pets = {
            { speciesID = 4947, npcID = 256014, name = "Assistant Botanist Leafy", petType = 7, source = "quest", sourceInfo = "Chain: Drift Them Away — Re-Hydra-ted (92866)",                    canBattle = false, waypoint = LOC.Neytar, zone = "Harandar" },
            { speciesID = 4942, npcID = 255689, name = "Distorted Memory",          petType = 7, source = "quest", sourceInfo = "Chain: The Listener — The Empty Cradle (Storyline 5929)",          canBattle = false, waypoint = LOC.ZurasharKassameh, zone = "Harandar" },
            { speciesID = 4977, npcID = 257616, name = "Emberwing Hatchling",       petType = 3, source = "quest", sourceInfo = "Chain: The Path of Mourning — A Quiet Farewell (89560)",           canBattle = false, waypoint = LOC.Chana, zone = "Zul'Aman" },
            { speciesID = 4909, npcID = 254647, name = "Emerald Hatchling",         petType = 5, source = "quest", sourceInfo = "The Battle of the Bridge (campaign scenario)",                     canBattle = false, waypoint = LOC.ShiningSpan, zone = "Silvermoon City" },
            { speciesID = 4950, npcID = 256107, name = "Fidoficus",                 petType = 8, source = "quest", sourceInfo = "Chain: Harvest of Darkness — Mighty and Superior (91382)",         canBattle = false, waypoint = LOC.Ravenia, zone = "Voidstorm" },
            { speciesID = 4816, npcID = 245043, name = "Hawkstrider Hatchling",     petType = 5, source = "quest", sourceInfo = "Chain: One Adventurous Hatchling — First Step Into Parenthood (89385) — 1 day hatch", canBattle = false, waypoint = LOC.VaelithSunplume, zone = "Eversong Woods" },
            { speciesID = 4946, npcID = 255921, name = "Linda the Lucky",           petType = 9, source = "quest", sourceInfo = "Chain: Light Disturbance — O.K. Bloomer (92739)",                  canBattle = false, waypoint = LOC.Hannan, zone = "Harandar" },
            { speciesID = 4971, npcID = 256759, name = "Luma",                      petType = 8, source = "quest", sourceInfo = "Chain: Second Time's a Choice — Thief at Bark (90544)",            canBattle = false, waypoint = LOC.InstructorAntheol, zone = "Eversong Woods" },
        },
    },

    -------------------------------------------------------------------------
    -- Treasure Pets (found in world treasure objects)
    -------------------------------------------------------------------------
    {
        source = "treasure",
        pets = {
            { speciesID = 4974, npcID = 246696, name = "Dali",                  petType = 9,  source = "treasure", sourceInfo = "Burbling Paint Pot, Eversong Woods (use in water)",                           canBattle = false, waypoint = LOC.BurblingPaintPot, zone = "Eversong Woods" },
            { speciesID = 4967, npcID = 256567, name = "Gortham",               petType = 8,  source = "treasure", sourceInfo = "Netherstorm Structural Cage, Nexus-Point Xenas dungeon (5-player puzzle)",    canBattle = true,  zone = "Nexus-Point Xenas" },
            { speciesID = 4881, npcID = 258803, name = "Nether Siphoner",       petType = 8,  source = "treasure", sourceInfo = "Quivering Egg, Voidstorm (31.5, 44.5)",                                      canBattle = false, waypoint = LOC.QuiveringEgg, zone = "Voidstorm" },
            { speciesID = 4927, npcID = 255119, name = "Percival",              petType = 9,  source = "treasure", sourceInfo = "Kemet's Simmering Cauldron, Harandar (55.6, 39.4)",                           canBattle = false, waypoint = LOC.KemetsCauldron, zone = "Harandar" },
            { speciesID = 4948, npcID = 256059, name = "Perturbed Sporebat",    petType = 3,  source = "treasure", sourceInfo = "Impenetrably Sealed Gourd, Harandar (cave puzzle, 27.5, 68.0)",               canBattle = false, waypoint = LOC.SealedGourd, zone = "Harandar" },
            { speciesID = 4906, npcID = 253399, name = "Scruffbeak",            petType = 5,  source = "treasure", sourceInfo = "Abandoned Nest, Zul'Aman - 72hr egg hatch (42.6, 52.4)",                     canBattle = false, waypoint = LOC.AbandonedNest, zone = "Zul'Aman" },
            { speciesID = 5003, npcID = 259728, name = "Sunwing Hatchling",     petType = 2,  source = "treasure", sourceInfo = "Rookery Cache, Silvermoon City (key + puzzle, 24.3, 69.3)",                   canBattle = false, waypoint = LOC.RookeryCache, zone = "Silvermoon City" },
            { speciesID = 4972, npcID = 256985, name = "Willie",                petType = 8,  source = "treasure", sourceInfo = "Half-Digested Viscera, Voidstorm (38.0, 68.8)",                               canBattle = false, waypoint = LOC.HalfDigestedVisc, zone = "Voidstorm" },
        },
    },

    -------------------------------------------------------------------------
    -- Achievement Pets
    -------------------------------------------------------------------------
    {
        source = "achievement",
        pets = {
            { speciesID = 4910, npcID = 254689, name = "Do, Child of Filo",     petType = 8,  source = "achievement", sourceInfo = "Midnight Safari (collect all 21 wild pets)",   canBattle = true,  achievementID = 61091 },
            { speciesID = 4803, npcID = 242452, name = "Niblet",                petType = 5,  source = "achievement", sourceInfo = "Midnight Dungeon Hero",                        canBattle = false, achievementID = 61567 },
            { speciesID = 5012, npcID = 260899, name = "Sootpaw",              petType = 8,  source = "achievement", sourceInfo = "Treasures of Eversong Woods",                  canBattle = false, achievementID = 61960 },
        },
    },

    -------------------------------------------------------------------------
    -- Delve Pets (End-of-run Nemesis Strongbox + Nullaeus nemesis drop)
    -------------------------------------------------------------------------
    {
        source = "delve",
        pets = {
            -- End-of-run drops from Nemesis Strongbox
            { speciesID = 4959, npcID = 256278, name = "Hexed Bunny",           petType = 8,  source = "delve", sourceInfo = "Delve end-of-run (Nemesis Strongbox)",                            canBattle = false },
            { speciesID = 4957, npcID = 256282, name = "Lost Star",             petType = 6,  source = "delve", sourceInfo = "Delve end-of-run (Nemesis Strongbox)",                            canBattle = false },
            { speciesID = 4961, npcID = 256269, name = "Nibblesworth",          petType = 8,  source = "delve", sourceInfo = "Delve end-of-run (Nemesis Strongbox)",                            canBattle = false },
            { speciesID = 4953, npcID = 256264, name = "Sporbie",               petType = 3,  source = "delve", sourceInfo = "Delve end-of-run (Nemesis Strongbox)",                            canBattle = false },
            { speciesID = 4956, npcID = 256237, name = "Spormilian",            petType = 7,  source = "delve", sourceInfo = "Delve end-of-run (Nemesis Strongbox)",                            canBattle = false },
            { speciesID = 4960, npcID = 256238, name = "Treja'saka",            petType = 8,  source = "delve", sourceInfo = "Delve end-of-run (Nemesis Strongbox)",                            canBattle = false },
            { speciesID = 4954, npcID = 256276, name = "Ziorg'pharon",          petType = 7,  source = "delve", sourceInfo = "Delve end-of-run (Nemesis Strongbox)",                            canBattle = false },

            -- Nullaeus nemesis boss drop
            { speciesID = 4958, npcID = 256265, name = "Ominous Domanus",       petType = 7,  source = "delve", sourceInfo = "Nullaeus (Season 1 Nemesis boss) - ~7% from Nullaeus Cache",     canBattle = false,
              dropInfo = { mob = "Nullaeus", npcID = 252892, rate = "~7%" } },
        },
    },

    -------------------------------------------------------------------------
    -- Profession Pets
    -------------------------------------------------------------------------
    {
        source = "profession",
        pets = {
            { speciesID = 4951, npcID = 256201, name = "Bubbly Snapling",       petType = 8,  source = "profession", sourceInfo = "Fishing - Patient Treasure chest", canBattle = false },
        },
    },

    -------------------------------------------------------------------------
    -- Trading Post Pets (Trader's Tender, rotates monthly)
    -------------------------------------------------------------------------
    {
        source = "tradingpost",
        pets = {
            { speciesID = 4965, npcID = 256565, name = "Chirpy Mandrake",      petType = 7,  source = "tradingpost", sourceInfo = "Trading Post - Trader's Tender (rotating)",  canBattle = false },
            { speciesID = 4963, npcID = 256559, name = "Grumpy Mandrake",      petType = 7,  source = "tradingpost", sourceInfo = "Trading Post - Trader's Tender (rotating)",  canBattle = false },
            { speciesID = 4964, npcID = 256560, name = "Plump Mandrake",       petType = 7,  source = "tradingpost", sourceInfo = "Trading Post - Trader's Tender (rotating)",  canBattle = false },
            { speciesID = 4966, npcID = 256566, name = "Screechy Mandrake",    petType = 7,  source = "tradingpost", sourceInfo = "Trading Post - Trader's Tender (rotating)",  canBattle = false },
        },
    },

    -------------------------------------------------------------------------
    -- Event / Promotional Pets
    -- Not obtainable through normal Midnight content. Included for reference.
    -------------------------------------------------------------------------
    {
        source = "event",
        pets = {
            -- Pre-patch Family Battler achievement rewards (species IDs unconfirmed)
            -- { speciesID = ????, name = "Moon Darter",  petType = ??, source = "event", sourceInfo = "Family Battler of Kalimdor",          canBattle = true },
            -- { speciesID = ????, name = "Byrn",         petType = ??, source = "event", sourceInfo = "Family Battler of Eastern Kingdoms",   canBattle = true },
            -- { speciesID = ????, name = "Webbers",      petType = ??, source = "event", sourceInfo = "Family Battler of Northrend",          canBattle = true },
        },
    },
}
