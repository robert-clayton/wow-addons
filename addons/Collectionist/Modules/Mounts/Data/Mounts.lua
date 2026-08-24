local _, MC = ...

local M = MC.MAP
local T = MC.SCORE_TIERS

-- Shared Ritual Sites gate. Several Ritual-Sites collectibles require both
-- meta-achievements (Void Response Team + Ritual Site Disruptor) regardless
-- of renown rank. Define once and reference from every entry that shares it.
MC.RitualSitesGate = {
    intro = "Two Ritual Sites meta-achievements gate this collectible.",
    tasks = {
        { achievementID = 62563, label = "Void Response Team" },
        { achievementID = 62562, label = "Ritual Site Disruptor" },
    },
}

-- Glory of the Midnight Raider (achievementID 61380) — earns Tenebrous
-- Harrower mount. 10 sub-achievements across The Voidspire / March on
-- Quel'Danas / The Dreamrift raids. Verified May 2026 against Wowhead.
local GLORY_RAIDER_TASKS = {
    intro = "Earn all 10 Midnight raid feat-of-strength achievements.",
    tasks = {
        { achievementID = 62352, label = "Nothing to See Here (Voidspire)" },
        { achievementID = 62058, label = "Hungry Hungry Hatchlings (Voidspire)" },
        { achievementID = 61911, label = "Ready, Set, Snap! (Voidspire)" },
        { achievementID = 61346, label = "We Will, In Fact, See It Again (Voidspire)" },
        { achievementID = 61381, label = "Eggsistential Crisis (March on Quel'Danas)" },
        { achievementID = 62106, label = "The Only Winning Move Is Not To Play (Voidspire)" },
        { achievementID = 61514, label = "It's Treason Then (Voidspire)" },
        { achievementID = 61936, label = "Aura Farming (Voidspire)" },
        { achievementID = 61454, label = "Falling Between The Quacks (Dreamrift)" },
        { achievementID = 62406, label = "All the Things She Said (Midnight Falls)" },
    },
}

-- Glory of the Midnight Delver (achievementID 61906) — earns Giganto Manis.
-- 4 sub-achievements that are themselves often metas (Loremaster, Treasure,
-- Curio, Nemesis). Nemesis is time-gated to the current delve season.
local GLORY_DELVER_TASKS = {
    intro = "Earn all 4 Midnight delve metas (Nemesis is season-gated).",
    tasks = {
        { achievementID = 61741, label = "Delve Loremaster: Midnight (10 story arcs)" },
        { achievementID = 61723, label = "Curio Fanatic: Midnight (Valeera rank 4 curios)" },
        { achievementID = 61901, label = "Leave No Treasure Unfound (Sturdy Chests in all 10 delves)" },
        { achievementID = 61797, label = "My Shady Nemesis (defeat Nullaeus before next season)" },
    },
}

-- Echo of Aln'sharan questline (mountID 2749) — Kuri in Har'kuai, Harandar.
-- 5 quests + a 500 Mysterious Skyshards inventory check (item 255826,
-- Warbound, NOT a tracked currency). Coords from method.gg (May 2026).
local ALN_SHARAN_TASKS = {
    intro = "Complete Kuri's questline and collect 500 Mysterious Skyshards.",
    tasks = {
        { questID = 90467, label = "Tales of the Sky",
          waypoint = { M.Harandar, 0.6779, 0.2746, "Kuri (Har'kuai)" } },
        { questID = 90468, label = "Ugh, Chores!",
          waypoint = { M.Harandar, 0.6779, 0.2746, "Kuri (Har'kuai)" } },
        { questID = 90469, label = "Carry On, Wayward Kuri",
          waypoint = { M.Harandar, 0.6779, 0.2746, "Kuri (Har'kuai)" } },
        { questID = 90470, label = "Skyglass Scavenging",
          waypoint = { M.Harandar, 0.6779, 0.2746, "Kuri -> Dreth'amar Cavern" } },
        { questID = 90474, label = "The Legend of Aln'sharan",
          waypoint = { M.Harandar, 0.6614, 0.2548, "Kuri (return ritual)" } },
        { itemID = 255826, itemCount = 500, label = "Collect 500 Mysterious Skyshards",
          waypoint = { M.Harandar, 0.6614, 0.2548, "Kuri (final turn-in)" } },
    },
}

-- Treasures of Harandar (achievement 61263) — earns Vivacious Chloroceros.
-- Inlining the coords because Mounts loads before the Treasures data file.
local VIVACIOUS_CHLOROCEROS_TASKS = {
    intro = "Loot all 9 Harandar treasures to earn the Vivacious Chloroceros mount.",
    tasks = {
        { questID = 92424, label = "Failed Shroom Jumper's Satchel",
          waypoint = { M.Harandar,    0.7168, 0.3100, "Failed Shroom Jumper's Satchel" } },
        { questID = 92426, label = "Burning Branch of the World Tree",
          waypoint = { M.Harandar,    0.4706, 0.5025, "Burning Branch of the World Tree" } },
        { questID = 92427, label = "Sporelord's Fight Prize",
          waypoint = { M.Harandar,    0.7365, 0.6535, "Sporelord's Fight Prize" } },
        { questID = 92431, label = "Reliquary's Lost Paintbrush",
          waypoint = { M.Harandar,    0.6290, 0.5124, "Reliquary's Lost Paintbrush" } },
        { questID = 92436, label = "Kemet's Simmering Cauldron",
          waypoint = { M.Harandar,    0.5569, 0.3943, "Kemet's Simmering Cauldron" } },
        { questID = 93144, label = "Gift of the Cycle",
          waypoint = { M.HarandarDen, 0.4723, 0.5078, "Gift of the Cycle (The Den)" } },
        { questID = 93508, label = "Impenetrably Sealed Gourd",
          waypoint = { M.Harandar,    0.2673, 0.6759, "Impenetrably Sealed Gourd" } },
        { questID = 93650, label = "Sporespawned Cache",
          waypoint = { M.Harandar,    0.4665, 0.6778, "Sporespawned Cache" } },
        { questID = 93587, label = "Peculiar Cauldron",
          waypoint = { M.Harandar,    0.4064, 0.2802, "Peculiar Cauldron" } },
    },
}

MC.MountSourceOrder = {
    "renown", "reputation", "drop", "achievement", "quest",
    "delve", "prey", "ritual_sites", "void_assaults",
    "showdowns",
    "dungeon", "raid", "pvp",
    "worldevent", "profession", "vendor", "tradingpost", "prepatch",
}
MC.MountSourceLabels = {
    renown = "Renown", reputation = "Reputation", drop = "Rare Drop",
    achievement = "Achievement", quest = "Quest", delve = "Delve",
    prey = "Prey", ritual_sites = "Ritual Sites", void_assaults = "Void Assaults",
    showdowns = "Void Showdowns",
    dungeon = "Dungeon", raid = "Raid", pvp = "PvP",
    worldevent = "World Event", profession = "Profession",
    vendor = "Vendor", tradingpost = "Trading Post", prepatch = "Pre-Patch",
    treasure = "Treasure",
}

local LOC = MC.LOC

-- Mount entry shape: { mountID, name, source, sourceInfo,
--   [waypoint], [overworldWaypoint], [cost], [zone], [renown],
--   [achievementID], [dropInfo], [faction] }
-- mountID is the C_MountJournal id (Wowhead /mount/NNNN), not spell or NPC id.

MC.RegisterContent("midnight", "mounts", {
    -- Renown Vendor Mounts (Voidlight Marl, currency 3316)
    -- 4 factions × 2 mounts each
    {
        source = "renown",
        mounts = {
            -- Silvermoon Court (factionID 2710)
            { mountID = 2761, name = "Crimson Silvermoon Hawkstrider", source = "renown", sourceInfo = "Caeris Fairdawn",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 17, factionName = "Silvermoon Court" }, score = T.long },
            { mountID = 2753, name = "Fiery Dragonhawk", source = "renown", sourceInfo = "Caeris Fairdawn",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 8000 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 19, factionName = "Silvermoon Court" }, score = T.long },

            -- Amani Tribe (factionID 2696)
            { mountID = 2776, name = "Amani Blessed Bear", source = "renown", sourceInfo = "Magovu",
              waypoint = LOC.Magovu, zone = "Zul'Aman",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 17, factionName = "Amani Tribe" }, score = T.long },
            { mountID = 2694, name = "Amani Windcaller", source = "renown", sourceInfo = "Magovu",
              waypoint = LOC.Magovu, zone = "Zul'Aman",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 8000 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 19, factionName = "Amani Tribe" }, score = T.long },

            -- Hara'ti (factionID 2704)
            { mountID = 2614, name = "Fierce Grimlynx", source = "renown", sourceInfo = "Naynar",
              waypoint = LOC.Naynar, zone = "Harandar",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } }, renown = { factionID = MC.FACTION.Harati, level = 16, factionName = "Hara'ti" }, score = T.long },
            { mountID = 2710, name = "Cerulean Sporeglider", source = "renown", sourceInfo = "Naynar",
              waypoint = LOC.Naynar, zone = "Harandar",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 8000 } }, renown = { factionID = MC.FACTION.Harati, level = 19, factionName = "Hara'ti" }, score = T.long },

            -- The Singularity (factionID 2699)
            { mountID = 2789, name = "Ravenous Shredclaw", source = "renown", sourceInfo = "Void Researcher Anomander",
              waypoint = LOC.Anomander, zone = "Voidstorm",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } }, renown = { factionID = MC.FACTION.Singularity, level = 17, factionName = "The Singularity" }, score = T.long },
            { mountID = 2828, name = "Voidbound Stormray", source = "renown", sourceInfo = "Void Researcher Anomander",
              waypoint = LOC.Anomander, zone = "Voidstorm",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 8000 } }, renown = { factionID = MC.FACTION.Singularity, level = 19, factionName = "The Singularity" }, score = T.long },

            -- Patch 12.0.5: Ritual Sites renown (Sergeant Vornin)
            { mountID = 2935, name = "Void-Touched Hawkstrider", source = "renown", sourceInfo = "Sergeant Vornin - 4,500 Voidlight Marl",
              waypoint = LOC.SergeantVornin, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 4500 } },
              renown = { factionID = MC.FACTION.RitualSites, level = 8, factionName = "Ritual Sites" } },
        },
    },

    -- Reputation — Slayer's Duellum (factionID 2770)
    {
        source = "reputation",
        mounts = {
            { mountID = 2792, name = "Frenzied Shredclaw", source = "reputation", sourceInfo = "Thraxadar - Exalted, Slayer's Duellum",
              waypoint = LOC.Thraxadar, zone = "Voidstorm",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } }, renown = { factionID = MC.FACTION.SlayersDuellum, standing = "Exalted", factionName = "Slayer's Duellum" }, score = T.medium },
            { mountID = 2791, name = "Prowling Shredclaw", source = "reputation", sourceInfo = "Thraxadar - Exalted, Slayer's Duellum",
              waypoint = LOC.Thraxadar, zone = "Voidstorm",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } }, renown = { factionID = MC.FACTION.SlayersDuellum, standing = "Exalted", factionName = "Slayer's Duellum" }, score = T.medium },
            { mountID = 2764, name = "Duskbrute Harrower", source = "reputation", sourceInfo = "Slayer's Duellum Trove (Paragon cache drop)",
              zone = "Voidstorm",
              dropInfo = { mob = "Slayer's Duellum Trove", zone = "Voidstorm" }, waypoint = { 2444, 0.3930, 0.8100, "Duskbrute Harrower" } },
        },
    },

    -- Rare Drops (world rares, by zone)
    {
        source = "drop",
        mounts = {
            -- Eversong Woods
            { mountID = 2762, name = "Cerulean Hawkstrider", source = "drop", sourceInfo = "Rare drop, Eversong Woods",
              zone = "Eversong Woods", dropInfo = { mob = "Zone rares", zone = "Eversong Woods", rate = "~1%" } },
            { mountID = 2758, name = "Cobalt Dragonhawk", source = "drop", sourceInfo = "Rare drop, Eversong Woods",
              zone = "Eversong Woods", dropInfo = { mob = "Zone rares", zone = "Eversong Woods", rate = "~1%" } },
            -- Zul'Aman
            { mountID = 2760, name = "Amani Sharptalon", source = "drop", sourceInfo = "Rare drop, Zul'Aman",
              zone = "Zul'Aman", dropInfo = { mob = "Zone rares", zone = "Zul'Aman", rate = "~1%" } },
            { mountID = 2775, name = "Witherbark Pango", source = "drop", sourceInfo = "Rare drop, Zul'Aman",
              zone = "Zul'Aman", dropInfo = { mob = "Zone rares", zone = "Zul'Aman", rate = "~1%" } },
            -- Harandar
            { mountID = 2615, name = "Rootstalker Grimlynx", source = "drop", sourceInfo = "Rare drop, Harandar",
              zone = "Harandar", dropInfo = { mob = "Zone rares", zone = "Harandar", rate = "~1%" } },
            { mountID = 2708, name = "Vibrant Petalwing", source = "drop", sourceInfo = "Rare drop, Harandar",
              zone = "Harandar", dropInfo = { mob = "Zone rares", zone = "Harandar", rate = "~1%" } },
            -- Voidstorm
            { mountID = 2751, name = "Augmented Stormray", source = "drop", sourceInfo = "Rare drop, Voidstorm",
              zone = "Voidstorm", dropInfo = { mob = "Zone rares", zone = "Voidstorm", rate = "~1%" } },
            { mountID = 2827, name = "Sanguine Harrower", source = "drop", sourceInfo = "Rare drop, Voidstorm",
              zone = "Voidstorm", dropInfo = { mob = "Zone rares", zone = "Voidstorm", rate = "~1%" } },
            -- Zul'Aman treasures
            { mountID = 2778, name = "Ancestral War Bear", source = "drop", sourceInfo = "Honored Warrior's Cache (4 Loa's Chosen trophies)",
              waypoint = LOC.HonoredWarriorsCache, zone = "Zul'Aman", dropInfo = { mob = "Honored Warrior's Cache", zone = "Zul'Aman" }, score = T.medium },
            { mountID = 2786, name = "Hexed Vilefeather Eagle", source = "drop", sourceInfo = "Abandoned Ritual Skull (1,000 Vile Essence)",
              waypoint = LOC.AbandonedRitualSkull, zone = "Zul'Aman", dropInfo = { mob = "Abandoned Ritual Skull", zone = "Zul'Aman" } },
            -- Harandar treasures
            { mountID = 2713, name = "Ruddy Sporeglider", source = "drop", sourceInfo = "Peculiar Cauldron (150 Crystalized Resin Fragments)",
              waypoint = LOC.PeculiarCauldron, zone = "Harandar", dropInfo = { mob = "Peculiar Cauldron", zone = "Harandar" }, score = T.medium },
            { mountID = 2747, name = "Untainted Grove Crawler", source = "drop", sourceInfo = "Sporespawned Cache (ring Mycelium Gong)",
              waypoint = LOC.SporespawnedCache, zone = "Harandar", dropInfo = { mob = "Sporespawned Cache", zone = "Harandar" }, score = T.trivial },
            -- Voidstorm treasures
            { mountID = 2790, name = "Insatiable Shredclaw", source = "drop", sourceInfo = "Final Clutch of Predaxas (lightning maze)",
              waypoint = LOC.FinalClutchPredaxas, zone = "Voidstorm", dropInfo = { mob = "Final Clutch of Predaxas", zone = "Voidstorm" }, score = T.short },
        },
    },

    -- Patch 12.0.5: Ritual Site instanced drops (Broken Throne / Daggerspine
    -- Point). Waypoints land in-instance; overworldWaypoint takes you to the
    -- portal entrance.
    {
        source = "ritual_sites",
        mounts = {
            { mountID = 2779, name = "Witherbark Warbear Mother", source = "ritual_sites",
              sourceInfo = "Broken Throne Tier 2+ — get Chubs (pet) first, then bring 5 more Practically Pork to the bone pile, summon Chubs to spawn Angry Amani Warbear, defeat to receive the mount kit",
              waypoint = LOC.AmaniWarbearPile, overworldWaypoint = LOC.BrokenThroneEntrance, zone = "Zul'Aman",
              dropInfo = { mob = "Angry Amani Warbear", zone = "Broken Throne Ritual Site", rate = "Guaranteed" } },
            { mountID = 2961, name = "Void-Corrupted Hex Eagle", source = "ritual_sites",
              sourceInfo = "Broken Throne Tier 2+ — pick up the Misplaced Ritual Candle under the nearby tree, place it in the empty skull, then click the candle cluster to summon the elite",
              waypoint = LOC.HexEagleRitual, overworldWaypoint = LOC.BrokenThroneEntrance, zone = "Zul'Aman",
              dropInfo = { mob = "Void-Corrupted Hex Eagle (elite)", zone = "Broken Throne Ritual Site", rate = "Guaranteed" }, score = T.medium },
            { mountID = 2964, name = "Void-Touched Snapdragon", source = "ritual_sites",
              sourceInfo = "Daggerspine Point Tier 2+ — loot Washed-Up Kelp piles along the coast (1-2 per instance) for a chance to spawn the rare; otherwise spawns slimes",
              waypoint = LOC.DaggerspineKelpPiles, overworldWaypoint = LOC.DaggerspinePointEntrance, zone = "Eversong Woods",
              dropInfo = { mob = "Void-Touched Snapdragon (rare)", zone = "Daggerspine Point Ritual Site", rate = "Very rare" }, score = T.epic },
        },
    },

    -- Achievement Mounts
    {
        source = "achievement",
        mounts = {
            { mountID = 2707, name = "Brilliant Petalwing", source = "achievement", sourceInfo = "Light Up the Night",
              achievementID = 62386 },
            { mountID = 2756, name = "Crimson Dragonhawk", source = "achievement", sourceInfo = "Midnight Glyph Hunter",
              achievementID = 61584 },
            { mountID = 2912, name = "Vivacious Chloroceros", source = "achievement", sourceInfo = "Treasures of Harandar", zone = "Harandar",
              achievementID = 61263, taskList = VIVACIOUS_CHLOROCEROS_TASKS, waypoint = { 2413, 0.5240, 0.8020, "Vivacious Chloroceros" } },
            { mountID = 2829, name = "Lab-Grown Stormray", source = "achievement", sourceInfo = "Staring Into The Void", zone = "Voidstorm",
              achievementID = 62385 },
            { mountID = 2616, name = "Ivory Grimlynx", source = "achievement", sourceInfo = "Allied Race: Haranir", zone = "Harandar",
              achievementID = 61506, score = T.short },
            { mountID = 2831, name = "Tenebrous Harrower", source = "achievement", sourceInfo = "Glory of the Midnight Raider",
              achievementID = 61380, taskList = GLORY_RAIDER_TASKS, score = T.epic },
            { mountID = 2773, name = "Giganto Manis", source = "achievement", sourceInfo = "Glory of the Midnight Delver",
              achievementID = 61906, taskList = GLORY_DELVER_TASKS, score = T.epic },
            { mountID = 2842, name = "Arcanovoid Construct", source = "achievement", sourceInfo = "Let Me Solo Him: Nullaeus", zone = "Torment's Rise",
              achievementID = 61799, score = T.epic },
            { mountID = 2733, name = "Calamitous Carrion", source = "achievement", sourceInfo = "Midnight Keystone Master: Season One",
              achievementID = 61256, score = T.epic },
            { mountID = 2734, name = "Convalescent Carrion", source = "achievement", sourceInfo = "Midnight Keystone Legend: Season One",
              achievementID = 61258, score = T.legendary },
            { mountID = 2801, name = "Galactic Gladiator's Goredrake", source = "achievement", sourceInfo = "Gladiator: Midnight Season 1",
              achievementID = 61188, score = T.legendary },
            { mountID = 2755, name = "Umbral Dragonhawk", source = "achievement", sourceInfo = "Life of the Party", zone = "Eversong Woods",
              achievementID = 62190, score = T.medium },
        },
    },

    -- Quest Mounts
    {
        source = "quest",
        mounts = {
            { mountID = 2785, name = "Relinquished Scarlet Charger", source = "quest", sourceInfo = "Quest: Relinquishing Relics (Silvermoon City)",
              zone = "Silvermoon City", waypoint = { 2424, 0.5260, 0.5590, "Relinquished Scarlet Charger" } },
            { mountID = 2749, name = "Echo of Aln'sharan", source = "quest", sourceInfo = "Questline: The Legend of Aln'sharan + 500 Mysterious Skyshards",
              zone = "Harandar", taskList = ALN_SHARAN_TASKS, score = T.legendary, waypoint = { 2413, 0.6620, 0.2550, "Echo of Aln'sharan" } },
        },
    },

    -- Delve Mounts
    {
        source = "delve",
        mounts = {
            { mountID = 2841, name = "Elven Arcane Guardian", source = "delve", sourceInfo = "Naleidea Rivergleam - 10,000 Undercoin",
              waypoint = LOC.NaleideaRivergleam, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.Undercoin, 10000 } } },
            { mountID = 2840, name = "Silvermoon's Arcane Defender", source = "delve", sourceInfo = "Telemancer Astrandis - 10 Voidlight Marl",
              waypoint = LOC.TelemancerAstrandis, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 10 } }, score = T.epic,
              renown = { factionID = MC.FACTION.DelversJourney, level = 5,
                         factionName = "Delver's Journey" } },
        },
    },

    -- Prey System Mounts (Remnant of Anguish, currency 3392)
    {
        source = "prey",
        mounts = {
            { mountID = 2769, name = "Preyseeker's Hubris", source = "prey", sourceInfo = "Construct V'anore - 2,000 Remnant of Anguish",
              waypoint = LOC.ConstructVanore, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 2000 } },
              renown = { factionID = MC.FACTION.PreyhuntersJourney, level = 5,
                         factionName = "Preyhunter's Journey" } },
            { mountID = 2770, name = "Preyseeker's Wrath", source = "prey", sourceInfo = "Construct V'anore - 2,550 Remnant of Anguish",
              waypoint = LOC.ConstructVanore, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 2550 } }, score = T.epic,
              renown = { factionID = MC.FACTION.PreyhuntersJourney, level = 10,
                         factionName = "Preyhunter's Journey" } },
            { mountID = 2771, name = "Preyseeker's Nightmare", source = "prey", sourceInfo = "Prey: Nightmare Mode III achievement", achievementID = 42703, score = T.epic },
        },
    },

    -- Dungeon Mounts
    {
        source = "dungeon",
        mounts = {
            { mountID = 2817, name = "Lucent Hawkstrider", source = "dungeon", sourceInfo = "Magisters' Terrace (Mythic) - Degentrius",
              dropInfo = { mob = "Degentrius", zone = "Magisters' Terrace", boss = true, rate = "~1%" }, waypoint = { 2424, 0.6300, 0.1510, "Lucent Hawkstrider" } },
            { mountID = 2805, name = "Spectral Hawkstrider", source = "dungeon", sourceInfo = "Windrunner Spire (Mythic) - The Restless Heart",
              dropInfo = { mob = "The Restless Heart", zone = "Windrunner Spire", boss = true, rate = "~1%" }, waypoint = { 2395, 0.3550, 0.7880, "Spectral Hawkstrider" } },
        },
    },

    -- Raid Mounts
    {
        source = "raid",
        mounts = {
            { mountID = 2607, name = "Ashes of Belo'ren", source = "raid", sourceInfo = "March on Quel'Danas (Mythic) - Midnight Falls",
              dropInfo = { mob = "Midnight Falls", zone = "March on Quel'Danas", boss = true, rate = "~3 per kill (Mythic, current expansion)" }, score = T.legendary, waypoint = { 2424, 0.5260, 0.8600, "Ashes of Belo'ren" } },
        },
    },

    -- PvP Mounts (filtered by player faction at scan time)
    {
        source = "pvp",
        mounts = {
            { mountID = 2794, name = "Vicious Snaplizard", source = "pvp", sourceInfo = "Galactic Combatant: Midnight Season 1 (Alliance)",
              faction = "Alliance" },
            { mountID = 2793, name = "Vicious Snaplizard", source = "pvp", sourceInfo = "Galactic Combatant: Midnight Season 1 (Horde)",
              faction = "Horde" },
        },
    },

    -- World Event Mounts (Abundance event, Unalloyed Abundance currency;
    -- 12.0.5: Decor Duels, Void Assaults)
    {
        source = "worldevent",
        mounts = {
            -- Chel the Chip rotates between 4 Abundance event locations weekly;
            -- multi-waypoint drops a marker at all four so you can hit whichever is active.
            { mountID = 2693, name = "Amani Sunfeather", source = "worldevent", sourceInfo = "Chel the Chip - 6,400 Unalloyed Abundance",
              waypoint = {
                  { MC.MAP.Eversong,  0.5678, 0.6579, "Chel the Chip (Watha'nan Crypts)" },
                  { MC.MAP.ZulAman,   0.3162, 0.2614, "Chel the Chip (Loaknit Den)" },
                  { MC.MAP.Harandar,  0.6614, 0.6169, "Chel the Chip (Floaret Grotto)" },
                  { MC.MAP.Voidstorm, 0.3882, 0.5331, "Chel the Chip (Abundant Voidburrow)" },
              } },
            { mountID = 2772, name = "Blessed Amani Burrower", source = "worldevent", sourceInfo = "Chel the Chip - 6,400 Unalloyed Abundance",
              waypoint = {
                  { MC.MAP.Eversong,  0.5678, 0.6579, "Chel the Chip (Watha'nan Crypts)" },
                  { MC.MAP.ZulAman,   0.3162, 0.2614, "Chel the Chip (Loaknit Den)" },
                  { MC.MAP.Harandar,  0.6614, 0.6169, "Chel the Chip (Floaret Grotto)" },
                  { MC.MAP.Voidstorm, 0.3882, 0.5331, "Chel the Chip (Abundant Voidburrow)" },
              } },
            -- Patch 12.0.5: Decor Duels
            { mountID = 2933, name = "Magister's Spell Bee", source = "worldevent", sourceInfo = "Gamesmaster Fleurin - 500 Illusionary Coins (Decor Duels)",
              waypoint = LOC.GamesmasterFleurin, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.IllusionaryCoin, 500 } } },
            { mountID = 2767, itemID = 257180, name = "Contained Stormarion Defender", source = "worldevent",
              sourceInfo = "Stormarion Assault event", zone = "Voidstorm" },
        },
    },

    -- Patch 12.0.5: Void Assaults / Incursions in Eversong + Zul'Aman.
    -- Currently a single mount (the meta reward); more may be added in
    -- future patches.
    {
        source = "void_assaults",
        mounts = {
            { mountID = 2915, name = "Unbound Manawyrm", source = "void_assaults",
              sourceInfo = "Sergeant Vornin (Silvermoon Bazaar) - 6,000 Voidlight Marl after earning both Void Response Team and Ritual Site Disruptor",
              waypoint = LOC.SergeantVornin, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } },
              achievementID = 62563,
              taskList = MC.RitualSitesGate, score = T.epic },
        },
    },

    -- Profession Mounts
    {
        source = "profession",
        mounts = {
            { mountID = 16, name = "Nether-Swept Drake", source = "profession", sourceInfo = "Fishing - Nether-Warped Egg (7 day hatch), Voidstorm",
              zone = "Voidstorm", waypoint = { 2405, 0.5110, 0.6930, "Nether-Swept Drake" } },
            -- Patch 12.0.5: Leatherworking craft
            { mountID = 2965, name = "Void-Corrupted Lynx", source = "profession",
              sourceInfo = "Leatherworking 90 craft — needs Pattern: Rope Lynx Harness + Broken Lynx Leash reagent (both drop from the end-of-run chest at Ritual Sites, guaranteed on Tier 5 first clear)",
              dropInfo = { mob = "End-of-run Ritual Site chest (Tier 5)", zone = "Ritual Sites" } },
        },
    },

    -- Vendor Mounts (Luminous Dust, Mothkeeper Wew'tam)
    {
        source = "vendor",
        mounts = {
            { mountID = 2913, name = "Vivid Chloroceros", source = "vendor", sourceInfo = "Mothkeeper Wew'tam - 10 Luminous Dust (50 moths)",
              waypoint = LOC.MothkeeperWewTam, zone = "Harandar" },
            { mountID = 2161, name = "Elder Glowmite", source = "vendor", sourceInfo = "Mothkeeper Wew'tam - 10 Luminous Dust (120 moths, TWW origin)",
              waypoint = LOC.MothkeeperWewTam, zone = "Harandar" },
        },
    },

    -- Pre-Patch Mounts
    {
        source = "prepatch",
        mounts = {
            { mountID = 2608, name = "Light-Forged Mechsuit", source = "prepatch", sourceInfo = "Two Minutes to Midnight achievement (Twilight Ascension pre-patch event, no longer earnable)",
              achievementID = 42300, unavailable = true },
            { mountID = 2220, name = "Retrained Skyrazor", source = "prepatch", sourceInfo = "Materialist Ophinell - 100 Twilight's Blade Insignia (no longer available)", zone = "Twilight Highlands",
              unavailable = true, waypoint = { 241, 0.4980, 0.8130, "Retrained Skyrazor" } },
        },
    },
})
