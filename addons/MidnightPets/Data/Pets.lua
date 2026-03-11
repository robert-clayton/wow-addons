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
--                    Harandar=2413, Voidstorm=2405, Isle of Quel'Danas=2441
-- NOTE: Isle of Quel'Danas mapID needs in-game verification.
local LOC = {
    -- Wild pet zones (approximate central coords for each zone)
    Eversong         = { 2395, 0.460, 0.370, "Eversong Woods" },
    SilvermoonCity   = { 2393, 0.300, 0.780, "Silvermoon City" },
    ZulAman          = { 2437, 0.470, 0.540, "Zul'Aman" },
    Harandar         = { 2413, 0.480, 0.520, "Harandar" },
    Voidstorm        = { 2405, 0.550, 0.650, "Voidstorm" },
    IsleOfQuelDanas  = { 2441, 0.500, 0.500, "Isle of Quel'Danas" }, -- mapID unverified

    -- Vendor NPCs
    CaerisFairdawn   = { 2395, 0.435, 0.474, "Caeris Fairdawn, Saltheril's Haven" },
    Anomander        = { 2405, 0.526, 0.729, "Void Researcher Anomander, Voidstorm" },
    Thraxadar        = { 2405, 0.393, 0.811, "Thraxadar, Slayer's Rise" },
    Naynar           = { 2413, 0.510, 0.508, "Naynar, Harandar" },
    Magovu           = { 2437, 0.460, 0.659, "Magovu, Zul'Aman" },
    ApprenticeDiell  = { 2395, 0.434, 0.474, "Apprentice Diell, Eversong Woods" },
    ConstructVanore  = { 2393, 0.557, 0.657, "Construct V'anore, Silvermoon City" },
    NaleideaRivergleam = { 2393, 0.500, 0.500, "Naleidea Rivergleam, Silvermoon City" }, -- coords need verification

    -- Treasure locations
    BurblingPaintPot  = { 2395, 0.487, 0.754, "Burbling Paint Pot, Eversong Woods" },
    RookeryCache      = { 2393, 0.243, 0.693, "Rookery Cache, Silvermoon City" },
    KemetsCauldron    = { 2413, 0.556, 0.394, "Kemet's Simmering Cauldron, Harandar" },
    SealedGourd       = { 2413, 0.275, 0.680, "Impenetrably Sealed Gourd, Harandar" },
    AbandonedNest     = { 2437, 0.426, 0.524, "Abandoned Nest, Zul'Aman" },
    QuiveringEgg      = { 2405, 0.315, 0.445, "Quivering Egg, Voidstorm" },
    HalfDigestedVisc  = { 2405, 0.380, 0.688, "Half-Digested Viscera, Voidstorm" },

    -- Drop locations
    DameBloodshed     = { 2395, 0.500, 0.500, "Dame Bloodshed, Eversong Woods" },       -- coords need verification (roaming rare)
    StormarionAssault = { 2405, 0.500, 0.500, "Stormarion Assault, Voidstorm" },          -- coords need verification
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
    -- Wild Pets (Companion-only — caught by right-clicking in the world)
    -- 21 achievement pets + 1 bonus (Silvermoon Broom). All cannot battle.
    -- Required for the Midnight Safari achievement (ID 61091).
    -------------------------------------------------------------------------
    {
        source = "wild",
        pets = {
            -- Eversong Woods
            { speciesID = 3277, npcID = 241500, name = "Amber Treeflitter",     petType = 5,  source = "wild", sourceInfo = "Eversong Woods — common spawn",          canBattle = false, waypoint = LOC.Eversong,        zone = "Eversong Woods" },
            { speciesID = 4890, npcID = 250572, name = "Vibrant Manaling",      petType = 6,  source = "wild", sourceInfo = "Eversong Woods — common spawn",          canBattle = false, waypoint = LOC.Eversong,        zone = "Eversong Woods" },
            { speciesID = 4877, npcID = 249817, name = "Violet Chick",          petType = 5,  source = "wild", sourceInfo = "Eversong Woods — uncommon spawn",        canBattle = false, waypoint = LOC.Eversong,        zone = "Eversong Woods" },

            -- Silvermoon City (bonus — not in Midnight Safari achievement)
            { speciesID = 4912, npcID = 254885, name = "Silvermoon Broom",      petType = 6,  source = "wild", sourceInfo = "Silvermoon City — rare (2-3+ hr respawn)", canBattle = false, waypoint = LOC.SilvermoonCity, zone = "Silvermoon City" },

            -- Harandar
            { speciesID = 4882, npcID = 249822, name = "Azure Sporebat",        petType = 3,  source = "wild", sourceInfo = "Harandar — common",                      canBattle = false, waypoint = LOC.Harandar,        zone = "Harandar" },
            { speciesID = 4876, npcID = 249816, name = "Mud Potadpole",         petType = 9,  source = "wild", sourceInfo = "Harandar — rare (3+ hr respawn)",        canBattle = false, waypoint = LOC.Harandar,        zone = "Harandar" },
            { speciesID = 4875, npcID = 249815, name = "Rootling Nester",       petType = 8,  source = "wild", sourceInfo = "Harandar — uncommon",                    canBattle = false, waypoint = LOC.Harandar,        zone = "Harandar" },
            { speciesID = 4886, npcID = 249827, name = "Silkcrawler",           petType = 5,  source = "wild", sourceInfo = "Harandar — common",                      canBattle = false, waypoint = LOC.Harandar,        zone = "Harandar" },
            { speciesID = 4497, npcID = 222077, name = "Waddles",               petType = 9,  source = "wild", sourceInfo = "Harandar — isolated area",               canBattle = false, waypoint = LOC.Harandar,        zone = "Harandar" },

            -- Voidstorm
            { speciesID = 4879, npcID = 249819, name = "Blistercreepling",      petType = 8,  source = "wild", sourceInfo = "Voidstorm — common",                    canBattle = false, waypoint = LOC.Voidstorm,       zone = "Voidstorm" },
            { speciesID = 4790, npcID = 240014, name = "Devouring Runt",        petType = 8,  source = "wild", sourceInfo = "Voidstorm — common",                    canBattle = false, waypoint = LOC.Voidstorm,       zone = "Voidstorm" },
            { speciesID = 4892, npcID = 250680, name = "Riftblade Familiar",    petType = 6,  source = "wild", sourceInfo = "Voidstorm — rare, near Obscurian Citadel", canBattle = false, waypoint = LOC.Voidstorm,    zone = "Voidstorm" },
            { speciesID = 4795, npcID = 241439, name = "Voidcrawler",           petType = 6,  source = "wild", sourceInfo = "Voidstorm — multiple locations",         canBattle = false, waypoint = LOC.Voidstorm,       zone = "Voidstorm" },

            -- Zul'Aman
            { speciesID = 4874, npcID = 249812, name = "Akil Fledgling",        petType = 3,  source = "wild", sourceInfo = "Zul'Aman — SE mountain area",           canBattle = false, waypoint = LOC.ZulAman,         zone = "Zul'Aman" },
            { speciesID = 4883, npcID = 249824, name = "Dragonhawk Mosswing",   petType = 3,  source = "wild", sourceInfo = "Zul'Aman — northern islands",           canBattle = false, waypoint = LOC.ZulAman,         zone = "Zul'Aman" },
            { speciesID = 4878, npcID = 249818, name = "Ebon Snapling",         petType = 8,  source = "wild", sourceInfo = "Zul'Aman — centre zone",                canBattle = false, waypoint = LOC.ZulAman,         zone = "Zul'Aman" },
            { speciesID = 4885, npcID = 249826, name = "Gloom Toad",            petType = 9,  source = "wild", sourceInfo = "Zul'Aman — near water areas",           canBattle = false, waypoint = LOC.ZulAman,         zone = "Zul'Aman" },
            { speciesID = 4884, npcID = 249825, name = "Pangolil",              petType = 8,  source = "wild", sourceInfo = "Zul'Aman — bridge patrol, rare (4-8+ hr respawn)", canBattle = false, waypoint = LOC.ZulAman, zone = "Zul'Aman" },
            { speciesID = 3364, npcID = 192368, name = "Striped Snakebiter",    petType = 8,  source = "wild", sourceInfo = "Zul'Aman — common",                     canBattle = false, waypoint = LOC.ZulAman,         zone = "Zul'Aman" },
            { speciesID = 4880, npcID = 249820, name = "Swamp Biter",           petType = 8,  source = "wild", sourceInfo = "Zul'Aman — all zones",                  canBattle = false, waypoint = LOC.ZulAman,         zone = "Zul'Aman" },

            -- Isle of Quel'Danas
            { speciesID = 4889, npcID = 250571, name = "Nether Familiar",       petType = 6,  source = "wild", sourceInfo = "Isle of Quel'Danas — northern area",    canBattle = false, waypoint = LOC.IsleOfQuelDanas, zone = "Isle of Quel'Danas" },
            { speciesID = 4891, npcID = 250573, name = "Wrathful Wyrm",         petType = 6,  source = "wild", sourceInfo = "Isle of Quel'Danas — rare (3+ hr respawn)", canBattle = false, waypoint = LOC.IsleOfQuelDanas, zone = "Isle of Quel'Danas" },
        },
    },

    -------------------------------------------------------------------------
    -- Vendor Pets
    -------------------------------------------------------------------------
    {
        source = "vendor",
        pets = {
            -- Renown vendors (Voidlight Marl, currency 3316)
            { speciesID = 4952, npcID = 256271, name = "Blitzcreek",            petType = 8,  source = "vendor", sourceInfo = "Void Researcher Anomander — Renown 14, The Singularity", canBattle = true,  waypoint = LOC.Anomander, zone = "Voidstorm",
              cost = { currency = { 3316, 2500 } } },
            { speciesID = 4928, npcID = 255257, name = "Dragonhawk Munchkin",   petType = 2,  source = "vendor", sourceInfo = "Caeris Fairdawn — Renown 12, Silvermoon Court",          canBattle = true,  waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods",
              cost = { currency = { 3316, 2500 } } },
            { speciesID = 4984, npcID = 257802, name = "Medusa",                petType = 6,  source = "vendor", sourceInfo = "Thraxadar — Revered, Slayer's Duellum",                  canBattle = false, waypoint = LOC.Thraxadar, zone = "Voidstorm",
              cost = { currency = { 3316, 2500 } } },
            { speciesID = 4929, npcID = 255295, name = "Munchy",                petType = 8,  source = "vendor", sourceInfo = "Naynar — Renown 12, Hara'ti",                            canBattle = true,  waypoint = LOC.Naynar, zone = "Harandar",
              cost = { currency = { 3316, 2500 } } },
            { speciesID = 4888, npcID = 250583, name = "Naloki",                petType = 5,  source = "vendor", sourceInfo = "Magovu — Renown 12, Amani Tribe",                        canBattle = false, waypoint = LOC.Magovu, zone = "Zul'Aman",
              cost = { currency = { 3316, 2500 } } },

            -- Brimming Arcana vendor (currency 3379)
            { speciesID = 4982, npcID = 257857, name = "Flicker",               petType = 8,  source = "vendor", sourceInfo = "Apprentice Diell — Luminary rank, Magisters",             canBattle = false, waypoint = LOC.ApprenticeDiell, zone = "Eversong Woods",
              cost = { currency = { 3379, 200 } } },

            -- Preyseeker's Journey vendors (Remnant of Anguish, currency 3392)
            { speciesID = 4930, npcID = 255522, name = "Lil' Preyseeker",       petType = 6,  source = "vendor", sourceInfo = "Construct V'anore — Preyseeker's Journey Rank 9",         canBattle = true,  waypoint = LOC.ConstructVanore, zone = "Silvermoon City",
              cost = { currency = { 3392, 1200 } } },
            { speciesID = 4976, npcID = 257546, name = "Voldy",                 petType = 7,  source = "vendor", sourceInfo = "Construct V'anore, Silvermoon City",                      canBattle = false, waypoint = LOC.ConstructVanore, zone = "Silvermoon City",
              cost = { currency = { 3392, 800 } } },

            -- Undercoin vendor (currency 2803)
            { speciesID = 4955, npcID = 256272, name = "Kreepah'zoyd",          petType = 8,  source = "vendor", sourceInfo = "Naleidea Rivergleam — 10,000 Undercoin",                  canBattle = false, waypoint = LOC.NaleideaRivergleam, zone = "Silvermoon City",
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
            { speciesID = 4947, npcID = 256014, name = "Assistant Botanist Leafy", petType = 7, source = "quest", sourceInfo = "Re-Hydra-ted (Quest 92866), Harandar",                          canBattle = false, zone = "Harandar" },
            { speciesID = 4942, npcID = 255689, name = "Distorted Memory",          petType = 7, source = "quest", sourceInfo = "The Empty Cradle (Storyline 5929), Voidstorm",                   canBattle = false, zone = "Voidstorm" },
            { speciesID = 4977, npcID = 257616, name = "Emberwing Hatchling",       petType = 3, source = "quest", sourceInfo = "A Quiet Farewell (Quest 89560), Zul'Aman",                      canBattle = false, zone = "Zul'Aman" },
            { speciesID = 4909, npcID = 254647, name = "Emerald Hatchling",         petType = 5, source = "quest", sourceInfo = "The Battle of the Bridge (World Quest), Silvermoon City",        canBattle = false, zone = "Silvermoon City" },
            { speciesID = 4950, npcID = 256107, name = "Fidoficus",                 petType = 8, source = "quest", sourceInfo = "Mighty and Superior (Quest 91382)",                              canBattle = false, zone = "Voidstorm" },
            { speciesID = 4816, npcID = 245043, name = "Hawkstrider Hatchling",     petType = 5, source = "quest", sourceInfo = "First Step Into Parenthood (Quest 89385) — hatches after 1 day", canBattle = false, zone = "Eversong Woods" },
            { speciesID = 4946, npcID = 255921, name = "Linda the Lucky",           petType = 9, source = "quest", sourceInfo = "O.K. Bloomer (Quest 92739), Harandar",                          canBattle = false, zone = "Harandar" },
            { speciesID = 4971, npcID = 256759, name = "Luma",                      petType = 8, source = "quest", sourceInfo = "Thief at Bark (Quest 90544), Eversong Woods",                   canBattle = false, zone = "Eversong Woods" },
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
            { speciesID = 4906, npcID = 253399, name = "Scruffbeak",            petType = 5,  source = "treasure", sourceInfo = "Abandoned Nest, Zul'Aman — 72hr egg hatch (42.6, 52.4)",                     canBattle = false, waypoint = LOC.AbandonedNest, zone = "Zul'Aman" },
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
            { speciesID = 4958, npcID = 256265, name = "Ominous Domanus",       petType = 7,  source = "delve", sourceInfo = "Nullaeus (Season 1 Nemesis boss) — ~7% from Nullaeus Cache",     canBattle = false,
              dropInfo = { mob = "Nullaeus", npcID = 252892, rate = "~7%" } },
        },
    },

    -------------------------------------------------------------------------
    -- Profession Pets
    -------------------------------------------------------------------------
    {
        source = "profession",
        pets = {
            { speciesID = 4951, npcID = 256201, name = "Bubbly Snapling",       petType = 8,  source = "profession", sourceInfo = "Fishing — Patient Treasure chest", canBattle = false },
        },
    },

    -------------------------------------------------------------------------
    -- Trading Post Pets (Trader's Tender, rotates monthly)
    -------------------------------------------------------------------------
    {
        source = "tradingpost",
        pets = {
            { speciesID = 4965, npcID = 256565, name = "Chirpy Mandrake",      petType = 7,  source = "tradingpost", sourceInfo = "Trading Post — Trader's Tender (rotating)",  canBattle = false },
            { speciesID = 4963, npcID = 256559, name = "Grumpy Mandrake",      petType = 7,  source = "tradingpost", sourceInfo = "Trading Post — Trader's Tender (rotating)",  canBattle = false },
            { speciesID = 4964, npcID = 256560, name = "Plump Mandrake",       petType = 7,  source = "tradingpost", sourceInfo = "Trading Post — Trader's Tender (rotating)",  canBattle = false },
            { speciesID = 4966, npcID = 256566, name = "Screechy Mandrake",    petType = 7,  source = "tradingpost", sourceInfo = "Trading Post — Trader's Tender (rotating)",  canBattle = false },
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
