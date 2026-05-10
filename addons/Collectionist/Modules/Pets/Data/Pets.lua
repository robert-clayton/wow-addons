local _, MC = ...

MC.PetTypeNames = {
    [1] = "Humanoid", [2] = "Dragonkin", [3] = "Flying", [4] = "Undead",
    [5] = "Critter", [6] = "Magic", [7] = "Elemental", [8] = "Beast",
    [9] = "Aquatic", [10] = "Mechanical",
}

MC.PetSourceOrder = { "wild", "vendor", "drop", "quest", "treasure", "achievement", "delve", "profession", "tradingpost", "event" }
MC.PetSourceLabels = {
    wild = "Wild", vendor = "Vendor", drop = "Drop",
    quest = "Quest", treasure = "Treasure", achievement = "Achievement",
    delve = "Delve", profession = "Profession", tradingpost = "Trading Post",
    event = "Event / Promo",
}

local LOC = MC.LOC
local M = MC.MAP

-- Pet entry shape: { speciesID, name, petType (1-10), source, sourceInfo,
--   [waypoint], [overworldWaypoint], [cost], [dropInfo], [achievementID],
--   [taskList], canBattle, [zone], [npcID] }
-- Note: most Midnight "wild" pets are companion-only and can't enter pet
-- battles, even though they live in the wild-pet group.

-- Midnight Safari (achievement 61091) — earns Do, Child of Filo. 21 wild
-- pets, one per task; gated on speciesID (per-pet collection state) so the
-- ✓/✗ flips immediately when the player captures a pet, before the safari
-- meta-achievement itself ticks.
local SAFARI_TASKS = {
    intro = "Capture all 21 Midnight wild pets to earn Do, Child of Filo.",
    tasks = {
        { speciesID = 3277, label = "Amber Treeflitter (Eversong)",      waypoint = LOC.AmberTreeflitter },
        { speciesID = 4890, label = "Vibrant Manaling (Eversong)",       waypoint = LOC.VibrantManaling },
        { speciesID = 4877, label = "Violet Chick (Eversong)",           waypoint = LOC.VioletChick },
        { speciesID = 4882, label = "Azure Sporebat (Harandar)",         waypoint = LOC.AzureSporebat },
        { speciesID = 4876, label = "Mud Potadpole (Harandar)",          waypoint = LOC.MudPotadpole },
        { speciesID = 4875, label = "Rootling Nester (Harandar)",        waypoint = LOC.RootlingNester },
        { speciesID = 4886, label = "Silkcrawler (Harandar)",            waypoint = LOC.Silkcrawler },
        { speciesID = 4497, label = "Waddles (Harandar)",                waypoint = LOC.Waddles },
        { speciesID = 4879, label = "Blistercreepling (Voidstorm)",      waypoint = LOC.Blistercreepling },
        { speciesID = 4790, label = "Devouring Runt (Voidstorm)",        waypoint = LOC.DevouringRunt },
        { speciesID = 4892, label = "Riftblade Familiar (Voidstorm)",    waypoint = LOC.RiftbladeFamiliar },
        { speciesID = 4795, label = "Voidcrawler (Voidstorm)",           waypoint = LOC.Voidcrawler },
        { speciesID = 4874, label = "Akil Fledgling (Zul'Aman)",         waypoint = LOC.AkilFledgling },
        { speciesID = 4883, label = "Dragonhawk Mosswing (Zul'Aman)",    waypoint = LOC.DragonhawkMosswing },
        { speciesID = 4878, label = "Ebon Snapling (Zul'Aman)",          waypoint = LOC.EbonSnapling },
        { speciesID = 4885, label = "Gloom Toad (Zul'Aman)",             waypoint = LOC.GloomToad },
        { speciesID = 4884, label = "Pangolil (Zul'Aman)",               waypoint = LOC.Pangolil },
        { speciesID = 3364, label = "Striped Snakebiter (Zul'Aman)",     waypoint = LOC.StripedSnakebiter },
        { speciesID = 4880, label = "Swamp Biter (Zul'Aman)",            waypoint = LOC.SwampBiter },
        { speciesID = 4889, label = "Nether Familiar (Quel'Danas)",      waypoint = LOC.NetherFamiliar },
        { speciesID = 4891, label = "Wrathful Wyrm (Quel'Danas)",        waypoint = LOC.WrathfulWyrm },
    },
}

-- Family Battler chains. Each parent achievement aggregates 10 family-of-X
-- sub-achievements (one per pet family), not individual trainers. Trainers
-- live one level deeper inside each sub-achievement, so we surface progress
-- at the family level here. Criterion order is alphabetical, verified in-game
-- against achievement 61051 (May 2026); EK and Northrend assumed to share the
-- same alphabetical pattern.
local FAMILY_BATTLER_KALIMDOR_TASKS = {
    intro = "Defeat all 10 Kalimdor pet families (parent achievement 61051).",
    tasks = {
        { achievementID = 61051, criteriaIndex = 1,  label = "Aquatic Battler of Kalimdor" },
        { achievementID = 61051, criteriaIndex = 2,  label = "Beast Battler of Kalimdor" },
        { achievementID = 61051, criteriaIndex = 3,  label = "Critter Battler of Kalimdor" },
        { achievementID = 61051, criteriaIndex = 4,  label = "Dragonkin Battler of Kalimdor" },
        { achievementID = 61051, criteriaIndex = 5,  label = "Elemental Battler of Kalimdor" },
        { achievementID = 61051, criteriaIndex = 6,  label = "Flying Battler of Kalimdor" },
        { achievementID = 61051, criteriaIndex = 7,  label = "Humanoid Battler of Kalimdor" },
        { achievementID = 61051, criteriaIndex = 8,  label = "Magic Battler of Kalimdor" },
        { achievementID = 61051, criteriaIndex = 9,  label = "Mechanical Battler of Kalimdor" },
        { achievementID = 61051, criteriaIndex = 10, label = "Undead Battler of Kalimdor" },
    },
}

local FAMILY_BATTLER_EK_TASKS = {
    intro = "Defeat all 10 Eastern Kingdoms pet families (parent achievement 61040).",
    tasks = {
        { achievementID = 61040, criteriaIndex = 1,  label = "Aquatic Battler of Eastern Kingdoms" },
        { achievementID = 61040, criteriaIndex = 2,  label = "Beast Battler of Eastern Kingdoms" },
        { achievementID = 61040, criteriaIndex = 3,  label = "Critter Battler of Eastern Kingdoms" },
        { achievementID = 61040, criteriaIndex = 4,  label = "Dragonkin Battler of Eastern Kingdoms" },
        { achievementID = 61040, criteriaIndex = 5,  label = "Elemental Battler of Eastern Kingdoms" },
        { achievementID = 61040, criteriaIndex = 6,  label = "Flying Battler of Eastern Kingdoms" },
        { achievementID = 61040, criteriaIndex = 7,  label = "Humanoid Battler of Eastern Kingdoms" },
        { achievementID = 61040, criteriaIndex = 8,  label = "Magic Battler of Eastern Kingdoms" },
        { achievementID = 61040, criteriaIndex = 9,  label = "Mechanical Battler of Eastern Kingdoms" },
        { achievementID = 61040, criteriaIndex = 10, label = "Undead Battler of Eastern Kingdoms" },
    },
}

local FAMILY_BATTLER_NORTHREND_TASKS = {
    intro = "Defeat all 10 Northrend pet families (parent achievement 60956).",
    tasks = {
        { achievementID = 60956, criteriaIndex = 1,  label = "Aquatic Battler of Northrend" },
        { achievementID = 60956, criteriaIndex = 2,  label = "Beast Battler of Northrend" },
        { achievementID = 60956, criteriaIndex = 3,  label = "Critter Battler of Northrend" },
        { achievementID = 60956, criteriaIndex = 4,  label = "Dragonkin Battler of Northrend" },
        { achievementID = 60956, criteriaIndex = 5,  label = "Elemental Battler of Northrend" },
        { achievementID = 60956, criteriaIndex = 6,  label = "Flying Battler of Northrend" },
        { achievementID = 60956, criteriaIndex = 7,  label = "Humanoid Battler of Northrend" },
        { achievementID = 60956, criteriaIndex = 8,  label = "Magic Battler of Northrend" },
        { achievementID = 60956, criteriaIndex = 9,  label = "Mechanical Battler of Northrend" },
        { achievementID = 60956, criteriaIndex = 10, label = "Undead Battler of Northrend" },
    },
}

-- Treasures of Eversong Woods (achievement 61960) — earns the Sootpaw pet.
-- Inlining the coords here rather than referencing MC.TreasureCoords because
-- the Pets data file loads before the Treasures data file in the .toc.
local SOOTPAW_TASKS = {
    intro = "Loot all 9 Eversong treasures to earn the Sootpaw pet.",
    tasks = {
        { questID = 93967, label = "Rookery Cache",
          waypoint = { M.Silvermoon, 0.2434, 0.6928, "Rookery Cache" } },
        { questID = 93456, label = "Triple-Locked Safebox",
          waypoint = { M.Eversong,   0.3889, 0.7606, "Triple-Locked Safebox" } },
        { questID = 93544, label = "Gift of the Phoenix",
          waypoint = { M.Eversong,   0.4096, 0.1945, "Gift of the Phoenix" } },
        { questID = 94747, label = "Forgotten Ink and Quill",
          waypoint = { M.Eversong,   0.4327, 0.6949, "Forgotten Ink and Quill" } },
        { questID = 93908, label = "Gilded Armillary Sphere",
          waypoint = { M.Eversong,   0.4461, 0.4554, "Gilded Armillary Sphere" } },
        { questID = 93455, label = "Antique Nobleman's Signet Ring",
          waypoint = { M.Eversong,   0.5234, 0.4543, "Antique Nobleman's Signet Ring" } },
        { questID = 93457, label = "Farstrider's Lost Quiver",
          waypoint = { M.Eversong,   0.6068, 0.6729, "Farstrider's Lost Quiver" } },
        { questID = 86645, label = "Stone Vat of Wine",
          waypoint = { M.Eversong,   0.4043, 0.6089, "Stone Vat of Wine" } },
        { questID = 91358, label = "Burbling Paint Pot",
          waypoint = { M.Eversong,   0.4873, 0.7544, "Burbling Paint Pot" } },
    },
}

MC.RegisterContent("midnight", "pets", {
    -- Wild Pets (Companion-only - caught by right-clicking in the world)
    -- 21 achievement pets + 1 bonus (Silvermoon Broom). All cannot battle.
    -- Required for the Midnight Safari achievement (ID 61091).
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

    -- Vendor Pets
    {
        source = "vendor",
        pets = {
            -- Renown vendors (Voidlight Marl, currency 3316)
            { speciesID = 4952, npcID = 256271, name = "Blitzcreek",            petType = 8,  source = "vendor", sourceInfo = "Void Researcher Anomander - Renown 14, The Singularity", canBattle = true,  waypoint = LOC.Anomander, zone = "Voidstorm",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.Singularity, level = 14, factionName = "The Singularity" } },
            { speciesID = 4928, npcID = 255257, name = "Dragonhawk Munchkin",   petType = 2,  source = "vendor", sourceInfo = "Caeris Fairdawn - Renown 12, Silvermoon Court",          canBattle = true,  waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 12, factionName = "Silvermoon Court" } },
            { speciesID = 4984, npcID = 257802, name = "Medusa",                petType = 6,  source = "vendor", sourceInfo = "Thraxadar - Revered, Slayer's Duellum",                  canBattle = false, waypoint = LOC.Thraxadar, zone = "Voidstorm",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.SlayersDuellum, standing = "Revered", factionName = "Slayer's Duellum" } },
            { speciesID = 4929, npcID = 255295, name = "Munchy",                petType = 8,  source = "vendor", sourceInfo = "Naynar - Renown 12, Hara'ti",                            canBattle = true,  waypoint = LOC.Naynar, zone = "Harandar",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.Harati, level = 12, factionName = "Hara'ti" } },
            { speciesID = 4888, npcID = 250583, name = "Naloki",                petType = 5,  source = "vendor", sourceInfo = "Magovu - Renown 12, Amani Tribe",                        canBattle = false, waypoint = LOC.Magovu, zone = "Zul'Aman",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 12, factionName = "Amani Tribe" } },

            -- Brimming Arcana vendor (currency 3379)
            { speciesID = 4982, npcID = 257857, name = "Flicker",               petType = 8,  source = "vendor", sourceInfo = "Apprentice Diell - Luminary rank, Magisters",             canBattle = false, waypoint = LOC.ApprenticeDiell, zone = "Eversong Woods",
              cost = { currency = { MC.CURRENCY.BrimmingArcana, 200 } } },

            -- Preyseeker's Journey vendors (Remnant of Anguish, currency 3392)
            { speciesID = 4930, npcID = 255522, name = "Lil' Preyseeker",       petType = 6,  source = "vendor", sourceInfo = "Construct V'anore - Preyseeker's Journey Rank 9",         canBattle = true,  waypoint = LOC.ConstructVanore, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 1200 } } },
            { speciesID = 4976, npcID = 257546, name = "Voldy",                 petType = 7,  source = "vendor", sourceInfo = "Construct V'anore, Silvermoon City",                      canBattle = false, waypoint = LOC.ConstructVanore, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 800 } } },

            -- Undercoin vendor (currency 2803)
            { speciesID = 4955, npcID = 256272, name = "Kreepah'zoyd",          petType = 8,  source = "vendor", sourceInfo = "Naleidea Rivergleam - 10,000 Undercoin",                  canBattle = false, waypoint = LOC.NaleideaRivergleam, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.Undercoin, 10000 } } },

            -- Patch 12.0.5: Sergeant Vornin (Voidlight Marl, currency 3316)
            { speciesID = 5039, npcID = 262787, name = "Cappy",                    petType = 8, source = "vendor", sourceInfo = "Sergeant Vornin - 1,800 Voidlight Marl (after Cosmic Exterminator)",
              canBattle = true, waypoint = LOC.SergeantVornin, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 1800 } }, achievementID = 62518 },
            { speciesID = 5036, npcID = 262422, name = "Rescued Dragonhawk Chick", petType = 2, source = "vendor",
              sourceInfo = "Sergeant Vornin - 1,800 Voidlight Marl, Ritual Sites Renown 6 (item: Void-Touched Dragonhawk Egg)",
              canBattle = true, waypoint = LOC.SergeantVornin, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 1800 } },
              renown = { factionID = MC.FACTION.RitualSites, level = 6, factionName = "Ritual Sites" } },
            { speciesID = 5037, npcID = 262427, name = "Void-Infused Mindbreaker Fry", petType = 6, source = "vendor",
              sourceInfo = "Sergeant Vornin - 1,800 Voidlight Marl, Ritual Sites Renown 6",
              canBattle = true, waypoint = LOC.SergeantVornin, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 1800 } },
              renown = { factionID = MC.FACTION.RitualSites, level = 6, factionName = "Ritual Sites" } },
            -- Patch 12.0.5: Depthdiver Tu'nakit (Angler Pearls, currency 3373)
            { speciesID = 5065, npcID = 264933, name = "Ka'bubb",                  petType = 3, source = "vendor", sourceInfo = "Depthdiver Tu'nakit - 2,400 Angler Pearls (Abyss Anglers)",
              canBattle = false, waypoint = LOC.DepthdiverTunakit, zone = "Zul'Aman",
              cost = { currency = { MC.CURRENCY.AnglerPearls, 2400 } } },
        },
    },

    -- Drop Pets
    {
        source = "drop",
        pets = {
            { speciesID = 4985, npcID = 258281, name = "Princess Bloodshed",    petType = 8,  source = "drop", sourceInfo = "Dame Bloodshed (rare), Eversong Woods",   canBattle = true,  waypoint = LOC.DameBloodshed, zone = "Eversong Woods",
              dropInfo = { mob = "Dame Bloodshed", npcID = 255348, zone = "Eversong Woods" } },
            { speciesID = 4983, npcID = 257908, name = "Kai",                   petType = 8,  source = "drop", sourceInfo = "Victorious Stormarion Cache, Voidstorm",   canBattle = true,  waypoint = LOC.StormarionAssault, zone = "Voidstorm",
              dropInfo = { mob = "Stormarion Assault event cache", zone = "Voidstorm" } },
            { speciesID = 4981, npcID = 257695, name = "Nova",                  petType = 5,  source = "drop", sourceInfo = "Slayer's Duellum Trove (Paragon cache)",   canBattle = false, zone = "Voidstorm",
              dropInfo = { mob = "Slayer's Duellum Trove", zone = "Voidstorm" } },

            -- Patch 12.0.5: Void Assault Wriggling Field Pouch drops
            { speciesID = 5040, npcID = 262788, name = "Curious Lynx Kitten",  petType = 8,  source = "drop", sourceInfo = "Wriggling Field Pouch (Void Assault, Eversong Woods)", canBattle = true, zone = "Eversong Woods",
              dropInfo = { mob = "Wriggling Field Pouch", zone = "Eversong Woods" } },
            { speciesID = 5038, npcID = 262786, name = "Wriggling Capybara",   petType = 8,  source = "drop", sourceInfo = "Wriggling Field Pouch (Void Assault, Zul'Aman)",        canBattle = true, zone = "Zul'Aman",
              dropInfo = { mob = "Wriggling Field Pouch", zone = "Zul'Aman" } },
            { speciesID = 5020, npcID = 262066, name = "Overloaded Manaling",  petType = 6,  source = "drop", sourceInfo = "Mana-Gorged Greatwyrm (rare elite, Void Assault)",     canBattle = true, zone = "Eversong Woods",
              dropInfo = { mob = "Mana-Gorged Greatwyrm", zone = "Eversong Woods" } },
        },
    },

    -- Quest Pets
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

    -- Treasure Pets (found in world treasure objects)
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

            -- Patch 12.0.5: Ritual Site treasures (instanced — coords are in-instance)
            { speciesID = 5021, npcID = 262089, name = "Void-Corrupted Snapdragon", petType = 9, source = "treasure",
              sourceInfo = "Loot Soggy Lynx Toy from kelp mobs at Daggerspine Point, then use it at Soggy Nest to spawn the Void-Corrupted Snapdragon NPC and click it",
              canBattle = true, waypoint = LOC.SoggyNest, overworldWaypoint = LOC.DaggerspinePointEntrance, zone = "Eversong Woods" },
            { speciesID = 5022, npcID = 262090, name = "Void-Touched Chick", petType = 5, source = "treasure",
              sourceInfo = "Swim to the white egg in the river at Daggerspine Point and loot it directly (no prerequisite)",
              canBattle = true, waypoint = LOC.DaggerspineRiverEgg, overworldWaypoint = LOC.DaggerspinePointEntrance, zone = "Eversong Woods" },
            { speciesID = 5023, npcID = 262092, name = "Void-Touched Lynx Kitten", petType = 8, source = "treasure",
              sourceInfo = "Daggerspine Point Tier 4+ — Rustling Bush spawns at one of 8 locations with no sparkle or glint, so you have to walk each spot. Each interact has ~10% chance, expect several attempts.",
              canBattle = true, overworldWaypoint = LOC.DaggerspinePointEntrance, zone = "Eversong Woods",
              dropInfo = { rate = "~10% per bush" },
              waypoint = {
                  { MC.MAP.DaggerspinePoint, 0.6640, 0.5246, "Rustling Bush" },
                  { MC.MAP.DaggerspinePoint, 0.5500, 0.7930, "Rustling Bush" },
                  { MC.MAP.DaggerspinePoint, 0.3510, 0.4450, "Rustling Bush" },
                  { MC.MAP.DaggerspinePoint, 0.6846, 0.3762, "Rustling Bush" },
                  { MC.MAP.DaggerspinePoint, 0.6358, 0.6558, "Rustling Bush" },
                  { MC.MAP.DaggerspinePoint, 0.4203, 0.8003, "Rustling Bush" },
                  { MC.MAP.DaggerspinePoint, 0.4176, 0.4969, "Rustling Bush" },
                  { MC.MAP.DaggerspinePoint, 0.4331, 0.5799, "Rustling Bush" },
              } },
            { speciesID = 5019, npcID = 261684, name = "Chubs", petType = 8, source = "treasure",
              sourceInfo = "Broken Throne Tier 2+ — find the stealthed Lost Bear Cub and feed Practically Pork (drops from beasts) or Sin'dorei Swarmer (fishing)",
              canBattle = true, waypoint = LOC.LostBearCub, overworldWaypoint = LOC.BrokenThroneEntrance, zone = "Zul'Aman" },
            { speciesID = 5017, npcID = 261676, name = "Void-Scarred Eaglet", petType = 2, source = "treasure",
              sourceInfo = "Earn the Void-Corrupted Hex Eagle mount first; mount it to follow the Void-Tainted Feather trail and ride the wind gale up to loot the Void-Tainted Nest",
              canBattle = true, waypoint = LOC.VoidTaintedNest, overworldWaypoint = LOC.BrokenThroneEntrance, zone = "Zul'Aman" },
        },
    },

    -- Achievement Pets
    {
        source = "achievement",
        pets = {
            { speciesID = 4910, npcID = 254689, name = "Do, Child of Filo",     petType = 8,  source = "achievement", sourceInfo = "Midnight Safari (collect all 21 wild pets)",   canBattle = true,  achievementID = 61091, taskList = SAFARI_TASKS },
            { speciesID = 4803, npcID = 242452, name = "Niblet",                petType = 5,  source = "achievement", sourceInfo = "Midnight Dungeon Hero",                        canBattle = false, achievementID = 61567 },
            { speciesID = 5012, npcID = 260899, name = "Sootpaw",              petType = 8,  source = "achievement", sourceInfo = "Treasures of Eversong Woods",                  canBattle = false, achievementID = 61960, taskList = SOOTPAW_TASKS },
        },
    },

    -- Delve Pets (End-of-run Nemesis Strongbox + Nullaeus nemesis drop)
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
            { speciesID = 4958, npcID = 256265, name = "Ominous Dominus",       petType = 7,  source = "delve", sourceInfo = "Nullaeus (Season 1 Nemesis boss) - ~7% from Nullaeus Cache",     canBattle = false,
              dropInfo = { mob = "Nullaeus", npcID = 252892, rate = "~7%" } },
        },
    },

    -- Profession Pets
    {
        source = "profession",
        pets = {
            { speciesID = 4951, npcID = 256201, name = "Bubbly Snapling",       petType = 8,  source = "profession", sourceInfo = "Fishing - Patient Treasure chest", canBattle = false },
        },
    },

    -- Trading Post Pets (Trader's Tender, rotates monthly)
    {
        source = "tradingpost",
        pets = {
            { speciesID = 4965, npcID = 256565, name = "Chirpy Mandrake",      petType = 7,  source = "tradingpost", sourceInfo = "Trading Post - Trader's Tender (rotating)",  canBattle = true },
            { speciesID = 4963, npcID = 256559, name = "Grumpy Mandrake",      petType = 7,  source = "tradingpost", sourceInfo = "Trading Post - Trader's Tender (rotating)",  canBattle = true },
            { speciesID = 4964, npcID = 256560, name = "Plump Mandrake",       petType = 7,  source = "tradingpost", sourceInfo = "Trading Post - Trader's Tender (rotating)",  canBattle = true },
            { speciesID = 4966, npcID = 256566, name = "Screechy Mandrake",    petType = 7,  source = "tradingpost", sourceInfo = "Trading Post - Trader's Tender (rotating)",  canBattle = true },
        },
    },

    -- Event / Promotional Pets
    -- Not obtainable through normal Midnight content. Included for reference.
    {
        source = "event",
        pets = {
            -- Pre-patch Family Battler achievement rewards
            { speciesID = 4913, name = "Moon Darter",  petType = 2, source = "event", sourceInfo = "Family Battler of Kalimdor",          canBattle = false, achievementID = 61051, taskList = FAMILY_BATTLER_KALIMDOR_TASKS },
            { speciesID = 3519, name = "Byrn",         petType = 7, source = "event", sourceInfo = "Family Battler of Eastern Kingdoms", canBattle = false, achievementID = 61040, taskList = FAMILY_BATTLER_EK_TASKS },
            { speciesID = 4475, name = "Webbers",      petType = 4, source = "event", sourceInfo = "Family Battler of Northrend",         canBattle = true,  achievementID = 60956, taskList = FAMILY_BATTLER_NORTHREND_TASKS },

            -- Patch 12.0.5: Blizzard Gear Store promotion (Apr 13 – May 15, 2026)
            { speciesID = 4968, npcID = 256663, name = "Lil' Staropod", petType = 6, source = "event", sourceInfo = "Blizzard Gear Store: Lil' Staropod collection (Apr 13 – May 15, 2026)", canBattle = true },
        },
    },
})
