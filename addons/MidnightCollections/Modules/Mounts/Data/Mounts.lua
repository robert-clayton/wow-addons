local _, MC = ...

MC.MountSourceOrder = {
    "renown", "reputation", "drop", "achievement", "quest",
    "delve", "prey", "dungeon", "raid", "pvp",
    "worldevent", "profession", "vendor", "prepatch",
}
MC.MountSourceLabels = {
    renown = "Renown", reputation = "Reputation", drop = "Rare Drop",
    achievement = "Achievement", quest = "Quest", delve = "Delve",
    prey = "Prey System", dungeon = "Dungeon", raid = "Raid", pvp = "PvP",
    worldevent = "World Event", profession = "Profession",
    vendor = "Vendor", prepatch = "Pre-Patch",
}

local LOC = MC.LOC

-- Mount data organized by source type
-- Fields: mountID, name, source, sourceInfo,
--         waypoint (optional), cost (optional), zone (optional),
--         renown (optional), achievementID (optional), dropInfo (optional),
--         faction (optional)
--
-- mountID values are C_MountJournal mount IDs (from Wowhead /mount/NNNN).
-- These are NOT spell IDs or NPC IDs.
-- Data sourced from Wowhead (wowhead.com), March 2026.

MC.MountData = {
    -------------------------------------------------------------------------
    -- Renown Vendor Mounts (Voidlight Marl, currency 3316)
    -- 4 factions × 2 mounts each
    -------------------------------------------------------------------------
    {
        source = "renown",
        mounts = {
            -- Silvermoon Court (factionID 2710)
            { mountID = 2761, name = "Crimson Silvermoon Hawkstrider", source = "renown", sourceInfo = "Caeris Fairdawn - Renown 17, Silvermoon Court",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 17, factionName = "Silvermoon Court" } },
            { mountID = 2753, name = "Fiery Dragonhawk", source = "renown", sourceInfo = "Caeris Fairdawn - Renown 19, Silvermoon Court",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 8000 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 19, factionName = "Silvermoon Court" } },

            -- Amani Tribe (factionID 2696)
            { mountID = 2776, name = "Amani Blessed Bear", source = "renown", sourceInfo = "Magovu - Renown 17, Amani Tribe",
              waypoint = LOC.Magovu, zone = "Zul'Aman",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 17, factionName = "Amani Tribe" } },
            { mountID = 2694, name = "Amani Windcaller", source = "renown", sourceInfo = "Magovu - Renown 19, Amani Tribe",
              waypoint = LOC.Magovu, zone = "Zul'Aman",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 8000 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 19, factionName = "Amani Tribe" } },

            -- Hara'ti (factionID 2704)
            { mountID = 2614, name = "Fierce Grimlynx", source = "renown", sourceInfo = "Naynar - Renown 16, Hara'ti",
              waypoint = LOC.Naynar, zone = "Harandar",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } }, renown = { factionID = MC.FACTION.Harati, level = 16, factionName = "Hara'ti" } },
            { mountID = 2710, name = "Cerulean Sporeglider", source = "renown", sourceInfo = "Naynar - Renown 19, Hara'ti",
              waypoint = LOC.Naynar, zone = "Harandar",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 8000 } }, renown = { factionID = MC.FACTION.Harati, level = 19, factionName = "Hara'ti" } },

            -- The Singularity (factionID 2699)
            { mountID = 2789, name = "Ravenous Shredclaw", source = "renown", sourceInfo = "Void Researcher Anomander - Renown 17, The Singularity",
              waypoint = LOC.Anomander, zone = "Voidstorm",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } }, renown = { factionID = MC.FACTION.Singularity, level = 17, factionName = "The Singularity" } },
            { mountID = 2828, name = "Voidbound Stormray", source = "renown", sourceInfo = "Void Researcher Anomander - Renown 19, The Singularity",
              waypoint = LOC.Anomander, zone = "Voidstorm",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 8000 } }, renown = { factionID = MC.FACTION.Singularity, level = 19, factionName = "The Singularity" } },

            -- Patch 12.0.5: Ritual Sites renown (Sergeant Vornin)
            { mountID = 2182, name = "Void-Touched Hawkstrider", source = "renown", sourceInfo = "Sergeant Vornin - 4,500 Voidlight Marl, Ritual Sites Renown 8",
              waypoint = LOC.SergeantVornin, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 4500 } },
              renown = { factionID = MC.FACTION.RitualSites, level = 8, factionName = "Ritual Sites" } },
        },
    },

    -------------------------------------------------------------------------
    -- Reputation — Slayer's Duellum (factionID 2770)
    -------------------------------------------------------------------------
    {
        source = "reputation",
        mounts = {
            { mountID = 2792, name = "Frenzied Shredclaw", source = "reputation", sourceInfo = "Thraxadar - Exalted, Slayer's Duellum",
              waypoint = LOC.Thraxadar, zone = "Voidstorm",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } }, renown = { factionID = MC.FACTION.SlayersDuellum, standing = "Exalted", factionName = "Slayer's Duellum" } },
            { mountID = 2791, name = "Prowling Shredclaw", source = "reputation", sourceInfo = "Thraxadar - Exalted, Slayer's Duellum",
              waypoint = LOC.Thraxadar, zone = "Voidstorm",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } }, renown = { factionID = MC.FACTION.SlayersDuellum, standing = "Exalted", factionName = "Slayer's Duellum" } },
            { mountID = 2764, name = "Duskbrute Harrower", source = "reputation", sourceInfo = "Slayer's Duellum Trove (Paragon cache drop)",
              zone = "Voidstorm",
              dropInfo = { mob = "Slayer's Duellum Trove", zone = "Voidstorm" } },
        },
    },

    -------------------------------------------------------------------------
    -- Rare Drops (world rares, by zone)
    -------------------------------------------------------------------------
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
            { mountID = 2775, name = "Escaped Witherbark Pango", source = "drop", sourceInfo = "Rare drop, Zul'Aman",
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
              waypoint = LOC.HonoredWarriorsCache, zone = "Zul'Aman", dropInfo = { mob = "Honored Warrior's Cache", zone = "Zul'Aman" } },
            { mountID = 2786, name = "Hexed Vilefeather Eagle", source = "drop", sourceInfo = "Abandoned Ritual Skull (1,000 Vile Essence)",
              waypoint = LOC.AbandonedRitualSkull, zone = "Zul'Aman", dropInfo = { mob = "Abandoned Ritual Skull", zone = "Zul'Aman" } },
            -- Harandar treasures
            { mountID = 2713, name = "Ruddy Sporeglider", source = "drop", sourceInfo = "Peculiar Cauldron (150 Crystalized Resin Fragments)",
              waypoint = LOC.PeculiarCauldron, zone = "Harandar", dropInfo = { mob = "Peculiar Cauldron", zone = "Harandar" } },
            { mountID = 2747, name = "Untainted Grove Crawler", source = "drop", sourceInfo = "Sporespawned Cache (ring Mycelium Gong)",
              waypoint = LOC.SporespawnedCache, zone = "Harandar", dropInfo = { mob = "Sporespawned Cache", zone = "Harandar" } },
            -- Voidstorm treasures
            { mountID = 2790, name = "Insatiable Shredclaw", source = "drop", sourceInfo = "Final Clutch of Predaxas (lightning maze)",
              waypoint = LOC.FinalClutchPredaxas, zone = "Voidstorm", dropInfo = { mob = "Final Clutch of Predaxas", zone = "Voidstorm" } },
            -- Patch 12.0.5: Ritual Sites (instanced — waypoints are in-instance)
            { mountID = 2116, name = "Witherbark Warbear Mother", source = "drop",
              sourceInfo = "Broken Throne Tier 2+ — get Chubs (pet) first, then bring 5 more Practically Pork to the bone pile, summon Chubs to spawn Angry Amani Warbear, defeat to receive the mount kit",
              waypoint = LOC.AmaniWarbearPile, overworldWaypoint = LOC.BrokenThroneEntrance, zone = "Zul'Aman",
              dropInfo = { mob = "Angry Amani Warbear", zone = "Broken Throne Ritual Site", rate = "Guaranteed" } },
            { mountID = 2183, name = "Void-Corrupted Hex Eagle", source = "drop",
              sourceInfo = "Broken Throne Tier 2+ — pick up the Misplaced Ritual Candle under the nearby tree, place it in the empty skull, then click the candle cluster to summon the elite",
              waypoint = LOC.HexEagleRitual, overworldWaypoint = LOC.BrokenThroneEntrance, zone = "Zul'Aman",
              dropInfo = { mob = "Void-Corrupted Hex Eagle (elite)", zone = "Broken Throne Ritual Site", rate = "Guaranteed" } },
            { mountID = 2181, name = "Void-Touched Snapdragon", source = "drop",
              sourceInfo = "Daggerspine Point Tier 2+ — loot Washed-Up Kelp piles along the coast (1-2 per instance) for a chance to spawn the rare; otherwise spawns slimes",
              waypoint = LOC.DaggerspineKelpPiles, overworldWaypoint = LOC.DaggerspinePointEntrance, zone = "Eversong Woods",
              dropInfo = { mob = "Void-Touched Snapdragon (rare)", zone = "Daggerspine Point Ritual Site", rate = "Very rare" } },
        },
    },

    -------------------------------------------------------------------------
    -- Achievement Mounts
    -------------------------------------------------------------------------
    {
        source = "achievement",
        mounts = {
            { mountID = 2707, name = "Brilliant Petalwing", source = "achievement", sourceInfo = "Light Up the Night",
              achievementID = 62386 },
            { mountID = 2756, name = "Crimson Dragonhawk", source = "achievement", sourceInfo = "Midnight Glyph Hunter",
              achievementID = 61584 },
            { mountID = 2912, name = "Vivacious Chloroceros", source = "achievement", sourceInfo = "Treasures of Harandar",
              achievementID = 61263 },
            { mountID = 2829, name = "Lab-grown Stormray", source = "achievement", sourceInfo = "Staring Into The Void",
              achievementID = 62385 },
            { mountID = 2616, name = "Ivory Grimlynx", source = "achievement", sourceInfo = "Allied Race: Haranir",
              achievementID = 61506 },
            { mountID = 2831, name = "Tenebrous Harrower", source = "achievement", sourceInfo = "Glory of the Midnight Raider",
              achievementID = 61380 },
            { mountID = 2773, name = "Giganto Manis", source = "achievement", sourceInfo = "Glory of the Midnight Delver",
              achievementID = 61906 },
            { mountID = 2842, name = "Arcanovoid Construct", source = "achievement", sourceInfo = "Let Me Solo Him: Nullaeus",
              achievementID = 61799 },
            { mountID = 2733, name = "Calamitous Carrion", source = "achievement", sourceInfo = "Midnight Keystone Master: Season One",
              achievementID = 61256 },
            { mountID = 2734, name = "Convalescent Carrion", source = "achievement", sourceInfo = "Midnight Keystone Legend: Season One",
              achievementID = 61258 },
            { mountID = 2801, name = "Galactic Gladiator's Goredrake", source = "achievement", sourceInfo = "Gladiator: Midnight Season 1",
              achievementID = 61188 },
            { mountID = 2755, name = "Umbral Dragonhawk", source = "achievement", sourceInfo = "Life of the Party",
              achievementID = 62190 },
        },
    },

    -------------------------------------------------------------------------
    -- Quest Mounts
    -------------------------------------------------------------------------
    {
        source = "quest",
        mounts = {
            { mountID = 2785, name = "Relinquished Scarlet Charger", source = "quest", sourceInfo = "Quest: Relinquishing Relics (Silvermoon City)",
              zone = "Silvermoon City" },
            { mountID = 2749, name = "Echo of Aln'sharan", source = "quest", sourceInfo = "Questline: The Legend of Aln'sharan + 500 Mysterious Skyshards",
              zone = "Harandar" },
        },
    },

    -------------------------------------------------------------------------
    -- Delve Mounts
    -------------------------------------------------------------------------
    {
        source = "delve",
        mounts = {
            { mountID = 2841, name = "Elven Arcane Guardian", source = "delve", sourceInfo = "Naleidea Rivergleam - 10,000 Undercoin",
              waypoint = LOC.NaleideaRivergleam, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.Undercoin, 10000 } } },
            { mountID = 2840, name = "Silvermoon's Arcane Defender", source = "delve", sourceInfo = "Telemancer Astrandis - 10 Voidlight Marl, Delver's Journey Renown 5",
              zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 10 } } },
        },
    },

    -------------------------------------------------------------------------
    -- Prey System Mounts (Remnant of Anguish, currency 3392)
    -------------------------------------------------------------------------
    {
        source = "prey",
        mounts = {
            { mountID = 2769, name = "Preyseeker's Hubris", source = "prey", sourceInfo = "Construct V'anore - 2,000 Remnant of Anguish, Rank 5",
              waypoint = LOC.ConstructVanore, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 2000 } } },
            { mountID = 2770, name = "Preyseeker's Wrath", source = "prey", sourceInfo = "Construct V'anore - 2,550 Remnant of Anguish, Rank 10",
              waypoint = LOC.ConstructVanore, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 2550 } } },
            { mountID = 2771, name = "Preyseeker's Nightmare", source = "prey", sourceInfo = "Prey: Nightmare Mode III achievement", achievementID = 42703 },
        },
    },

    -------------------------------------------------------------------------
    -- Dungeon Mounts
    -------------------------------------------------------------------------
    {
        source = "dungeon",
        mounts = {
            { mountID = 2817, name = "Lucent Hawkstrider", source = "dungeon", sourceInfo = "Magisters' Terrace (Mythic) - Degentrius",
              dropInfo = { mob = "Degentrius", zone = "Magisters' Terrace", boss = true, rate = "~1%" } },
            { mountID = 2805, name = "Spectral Hawkstrider", source = "dungeon", sourceInfo = "Windrunner Spire (Mythic) - The Restless Heart",
              dropInfo = { mob = "The Restless Heart", zone = "Windrunner Spire", boss = true, rate = "~1%" } },
        },
    },

    -------------------------------------------------------------------------
    -- Raid Mounts
    -------------------------------------------------------------------------
    {
        source = "raid",
        mounts = {
            { mountID = 2607, name = "Ashes of Belo'ren", source = "raid", sourceInfo = "March on Quel'Danas (Mythic) - Midnight Falls",
              dropInfo = { mob = "Midnight Falls", zone = "March on Quel'Danas", boss = true, rate = "~3 per kill (Mythic, current expansion)" } },
        },
    },

    -------------------------------------------------------------------------
    -- PvP Mounts (filtered by player faction at scan time)
    -------------------------------------------------------------------------
    {
        source = "pvp",
        mounts = {
            { mountID = 2794, name = "Vicious Snaplizard", source = "pvp", sourceInfo = "Galactic Combatant: Midnight Season 1 (Alliance)",
              faction = "Alliance" },
            { mountID = 2793, name = "Vicious Snaplizard", source = "pvp", sourceInfo = "Galactic Combatant: Midnight Season 1 (Horde)",
              faction = "Horde" },
        },
    },

    -------------------------------------------------------------------------
    -- World Event Mounts (Abundance event, Unalloyed Abundance currency;
    -- 12.0.5: Decor Duels, Void Assaults)
    -------------------------------------------------------------------------
    {
        source = "worldevent",
        mounts = {
            { mountID = 2693, name = "Amani Sunfeather", source = "worldevent", sourceInfo = "Chel the Chip - 6,400 Unalloyed Abundance" },
            { mountID = 2772, name = "Blessed Amani Burrower", source = "worldevent", sourceInfo = "Chel the Chip - 6,400 Unalloyed Abundance" },
            -- Patch 12.0.5: Decor Duels
            { mountID = 1763, name = "Magister's Spell Bee", source = "worldevent", sourceInfo = "Gamesmaster Fleurin - 500 Illusionary Coins (Decor Duels)",
              waypoint = LOC.GamesmasterFleurin, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.IllusionaryCoin, 500 } } },
            -- Patch 12.0.5: Void Assaults achievement reward
            { mountID = 2176, name = "Unbound Manawyrm", source = "worldevent",
              sourceInfo = "Sergeant Vornin (Silvermoon Bazaar) - 6,000 Voidlight Marl after earning both Void Response Team (6 Void Assault sub-achievements) and Ritual Site Disruptor",
              waypoint = LOC.SergeantVornin, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 6000 } }, achievementID = 62563 },
        },
    },

    -------------------------------------------------------------------------
    -- Profession Mounts
    -------------------------------------------------------------------------
    {
        source = "profession",
        mounts = {
            { mountID = 654, name = "Nether-Swept Drake", source = "profession", sourceInfo = "Fishing - Nether-Warped Egg (7 day hatch), Voidstorm",
              zone = "Voidstorm" },
            -- Patch 12.0.5: Leatherworking craft
            { mountID = 2188, name = "Void-Corrupted Lynx", source = "profession",
              sourceInfo = "Leatherworking 90 craft — needs Pattern: Rope Lynx Harness + Broken Lynx Leash reagent (both drop from the end-of-run chest at Ritual Sites, guaranteed on Tier 5 first clear)",
              dropInfo = { mob = "End-of-run Ritual Site chest (Tier 5)", zone = "Ritual Sites" } },
        },
    },

    -------------------------------------------------------------------------
    -- Vendor Mounts (Luminous Dust, Mothkeeper Wew'tam)
    -------------------------------------------------------------------------
    {
        source = "vendor",
        mounts = {
            { mountID = 2913, name = "Vivid Chloroceros", source = "vendor", sourceInfo = "Mothkeeper Wew'tam - 10 Luminous Dust (50 moths)" },
            { mountID = 2161, name = "Elder Glowmite", source = "vendor", sourceInfo = "Mothkeeper Wew'tam - 10 Luminous Dust (120 moths, TWW origin)" },
        },
    },

    -------------------------------------------------------------------------
    -- Pre-Patch Mounts
    -------------------------------------------------------------------------
    {
        source = "prepatch",
        mounts = {
            { mountID = 2608, name = "Light-Forged Mechsuit", source = "prepatch", sourceInfo = "Two Minutes to Midnight achievement",
              achievementID = 42300 },
            { mountID = 2220, name = "Retrained Skyrazor", source = "prepatch", sourceInfo = "Materialist Ophinell - 100 Twilight's Blade Insignia (no longer available)" },
        },
    },
}
