local _, MC = ...
local LOC = MC.LOC

-- Decorations released with Patch 12.1.  All entries keep their catalog ID
-- alongside the item ID so housing scans can fall back to item lookup while
-- the live catalog cache is still warming.
MC.RegisterContent("midnight", "decorations", {
    -- The Coiled Isle -- achievement rewards and campaign quests.
    {
        source = "achievement",
        decorations = {
            { decorID = 15283, itemID = 263873, name = "Amani Forge", source = "achievement", sourceInfo = "Coiled to Strike (Patch 12.1)", achievementID = 63358 },
            { decorID = 5130, itemID = 248962, name = "Mysterious Voodoo Mask", source = "achievement", sourceInfo = "Mysterious Mix Master (Patch 12.1)", achievementID = 63432 },
        },
    },
    {
        source = "quest",
        decorations = {
            { decorID = 21833, itemID = 271851, name = "Oozing Vilescar Barricade", source = "quest", sourceInfo = "The Coiled Isle quest reward (Patch 12.1)", zone = "The Coiled Isle" },
            { decorID = 27041, itemID = 279452, name = "\"Summoning of Ula'tek\" Mural", source = "quest", sourceInfo = "The Coiled Isle quest reward (Patch 12.1)", zone = "The Coiled Isle" },
            { decorID = 26484, itemID = 279285, name = "Lost Tortollan Scroll", source = "quest", sourceInfo = "The Coiled Isle quest reward (Patch 12.1)", zone = "The Coiled Isle" },
            { decorID = 27042, itemID = 279508, name = "\"The Hunger Awakens\" Mural", source = "quest", sourceInfo = "The Coiled Isle quest reward (Patch 12.1)", zone = "The Coiled Isle" },
            { decorID = 26377, itemID = 279292, name = "Zul'Aman Pine Tree", source = "quest", sourceInfo = "The Coiled Isle quest reward (Patch 12.1)", zone = "The Coiled Isle" },
            { decorID = 26203, itemID = 278691, name = "Twilight Brazier", source = "quest", sourceInfo = "The Coiled Isle quest reward (Patch 12.1)", zone = "The Coiled Isle" },
            { decorID = 21616, itemID = 271176, name = "Feathered Ula'tek Talisman", source = "quest", sourceInfo = "The Coiled Isle quest reward (Patch 12.1)", zone = "The Coiled Isle" },
            { decorID = 26481, itemID = 280218, name = "Tortollan Scholar Satchel", source = "quest", sourceInfo = "The Coiled Isle quest reward (Patch 12.1)", zone = "The Coiled Isle" },
            { decorID = 21725, itemID = 271609, name = "Destroyed Clutch of Ula'tek", source = "quest", sourceInfo = "The Coiled Isle quest reward (Patch 12.1)", zone = "The Coiled Isle" },
        },
    },
    {
        source = "drop",
        decorations = {
            { decorID = 26376, itemID = 281582, name = "Atal'Utek Ivy", source = "drop", sourceInfo = "The Coiled Isle treasure (Patch 12.1)", zone = "The Coiled Isle" },
            { decorID = 1428, itemID = 244345, name = "Forgotten Amani Urn", source = "drop", sourceInfo = "The Coiled Isle treasure (Patch 12.1)", zone = "The Coiled Isle" },
            { decorID = 21615, itemID = 271175, name = "Venomjade Necklace", source = "drop", sourceInfo = "The Coiled Isle treasure (Patch 12.1)", zone = "The Coiled Isle" },
        },
    },

    -- Firetender Zab'ni. Most stock is also awarded by the quests,
    -- treasures, and achievements above; Pungent Atal-Utek Shroom is the
    -- vendor-only catalog unlock after completing Stinking Vessel.
    {
        source = "vendor",
        decorations = {
            { decorID = 26375, itemID = 281580, name = "Pungent Atal'Utek Shroom", source = "vendor", sourceInfo = "Firetender Zab'ni - 250 Voidlight Marl; requires Stinking Vessel", zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } } },
        },
    },

    -- Captain Tokka friendship vendor.
    {
        source = "vendor",
        decorations = {
            { decorID = 25299, itemID = 277923, name = "Aged Tortollan Scroll Case", source = "vendor", sourceInfo = "Second Mate Sluggs - 150 Voidlight Marl, Captain Tokka Rank 2", waypoint = LOC.SecondMateSluggs, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } } },
            { decorID = 25336, itemID = 277927, name = "Yellowed Kelp Pile", source = "vendor", sourceInfo = "Second Mate Sluggs - 250 Voidlight Marl, Captain Tokka Rank 2", waypoint = LOC.SecondMateSluggs, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } } },
            { decorID = 26197, itemID = 277931, name = "Hanging Yellowed Kelp", source = "vendor", sourceInfo = "Second Mate Sluggs - 250 Voidlight Marl, Captain Tokka Rank 3", waypoint = LOC.SecondMateSluggs, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } } },
            { decorID = 25300, itemID = 277925, name = "Blue Tortollan Signpost", source = "vendor", sourceInfo = "Second Mate Sluggs - 250 Voidlight Marl, Captain Tokka Rank 4", waypoint = LOC.SecondMateSluggs, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } } },
            { decorID = 26196, itemID = 277929, name = "Rustic Fishing Rack", source = "vendor", sourceInfo = "Second Mate Sluggs - 500 Voidlight Marl, Captain Tokka Rank 4", waypoint = LOC.SecondMateSluggs, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 500 } } },
            { decorID = 25297, itemID = 277921, name = "Traditional Tortollan Tent", source = "vendor", sourceInfo = "Second Mate Sluggs - 500 Voidlight Marl, Captain Tokka Rank 5", waypoint = LOC.SecondMateSluggs, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 500 } } },
        },
    },

    -- Zul'Jarra's Forces renown quartermaster.
    {
        source = "renown",
        decorations = {
            { decorID = 15156, itemID = 263316, name = "Amani Storage Crate", source = "renown", sourceInfo = "Jan'sari the Watchful - 150 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 3, factionName = "Zul'Jarra's Forces" } },
            { decorID = 5648, itemID = 249765, name = "Amani Supply Sack", source = "renown", sourceInfo = "Jan'sari the Watchful - 150 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 3, factionName = "Zul'Jarra's Forces" } },
            { decorID = 15569, itemID = 264331, name = "Amani Wayfarer's Torch", source = "renown", sourceInfo = "Jan'sari the Watchful - 150 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 3, factionName = "Zul'Jarra's Forces" } },
            { decorID = 21325, itemID = 269779, name = "Fanged Scaleskin Pouch", source = "renown", sourceInfo = "Jan'sari the Watchful - 150 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 7, factionName = "Zul'Jarra's Forces" } },
            { decorID = 21324, itemID = 269778, name = "Stitched Blisterfang Bag", source = "renown", sourceInfo = "Jan'sari the Watchful - 150 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 7, factionName = "Zul'Jarra's Forces" } },
            { decorID = 26097, itemID = 277280, name = "Vilescar Weapon Rack", source = "renown", sourceInfo = "Jan'sari the Watchful - 250 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 7, factionName = "Zul'Jarra's Forces" } },
            { decorID = 23876, itemID = 277275, name = "Charmed Blisterfang Urn", source = "renown", sourceInfo = "Jan'sari the Watchful - 150 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 11, factionName = "Zul'Jarra's Forces" } },
            { decorID = 23875, itemID = 277273, name = "Cracked Vilescar Urn", source = "renown", sourceInfo = "Jan'sari the Watchful - 150 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 11, factionName = "Zul'Jarra's Forces" } },
            { decorID = 23874, itemID = 277271, name = "Wrapped Scaleskin Urn", source = "renown", sourceInfo = "Jan'sari the Watchful - 150 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 11, factionName = "Zul'Jarra's Forces" } },
            { decorID = 25295, itemID = 276459, name = "Amani Ritual Candles", source = "renown", sourceInfo = "Jan'sari the Watchful - 150 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 15, factionName = "Zul'Jarra's Forces" } },
            { decorID = 15506, itemID = 264271, name = "Amani Ritual Totem", source = "renown", sourceInfo = "Jan'sari the Watchful - 250 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 15, factionName = "Zul'Jarra's Forces" } },
            { decorID = 25294, itemID = 276457, name = "Amani Worship Candle", source = "renown", sourceInfo = "Jan'sari the Watchful - 150 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 15, factionName = "Zul'Jarra's Forces" } },
            { decorID = 21617, itemID = 271177, name = "Opened Serpentine Reliquary", source = "renown", sourceInfo = "Jan'sari the Watchful - 250 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 18, factionName = "Zul'Jarra's Forces" } },
            { decorID = 23873, itemID = 277323, name = "Sealed Serpentine Reliquary", source = "renown", sourceInfo = "Jan'sari the Watchful - 250 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 18, factionName = "Zul'Jarra's Forces" } },
            { decorID = 18900, itemID = 267377, name = "Ula'tek Ritual Monolith", source = "renown", sourceInfo = "Jan'sari the Watchful - 250 Voidlight Marl", waypoint = LOC.Jansari, zone = "The Coiled Isle", cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } }, renown = { factionID = MC.FACTION.ZuljarrasForces, level = 18, factionName = "Zul'Jarra's Forces" } },
        },
    },

    -- Skull of Er'inye, Vaults of Atal'Utek.
    {
        source = "vendor",
        decorations = {
            { decorID = 25292, itemID = 279922, name = "Altar of Corrosion", source = "vendor", sourceInfo = "Skull of Er'inye - 2,500 Corrosive Coins; Fully Corroded", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 2500 } }, achievementID = 63636 },
            { decorID = 23871, itemID = 275628, name = "Cauldron of Ula'tek", source = "vendor", sourceInfo = "Skull of Er'inye - 1,000 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 1000 } } },
            { decorID = 21653, itemID = 271358, name = "Clutch of Ula'tek", source = "vendor", sourceInfo = "Skull of Er'inye - 1,000 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 1000 } } },
            { decorID = 26204, itemID = 281620, name = "Corrosive Cache", source = "vendor", sourceInfo = "Skull of Er'inye - 2,500 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 2500 } } },
            { decorID = 21720, itemID = 271604, name = "Egg of Ula'tek", source = "vendor", sourceInfo = "Skull of Er'inye - 750 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 750 } } },
            { decorID = 21102, itemID = 269637, name = "Serpent-Caller Spike", source = "vendor", sourceInfo = "Skull of Er'inye - 1,000 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 1000 } } },
            { decorID = 17799, itemID = 266169, name = "Soulcoiler Canopy", source = "vendor", sourceInfo = "Skull of Er'inye - 1,000 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 1000 } } },
            { decorID = 24519, itemID = 279919, name = "Soulcoiler Jaw", source = "vendor", sourceInfo = "Skull of Er'inye - 2,500 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 2500 } } },
            { decorID = 23881, itemID = 275578, name = "Soulcoiler Sconce", source = "vendor", sourceInfo = "Skull of Er'inye - 750 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 750 } } },
            { decorID = 24512, itemID = 279917, name = "Soulcoiler Skull", source = "vendor", sourceInfo = "Skull of Er'inye - 2,500 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 2500 } } },
            { decorID = 1150, itemID = 253473, name = "Unearthed Amani Sarcophagus Base", source = "vendor", sourceInfo = "Skull of Er'inye - 1,000 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 1000 } } },
            { decorID = 1140, itemID = 253455, name = "Unearthed Amani Sarcophagus Lid", source = "vendor", sourceInfo = "Skull of Er'inye - 750 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 750 } } },
            { decorID = 18901, itemID = 267378, name = "Venom Scholar's Focus", source = "vendor", sourceInfo = "Skull of Er'inye - 750 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 750 } } },
            { decorID = 21953, itemID = 272362, name = "Venombound Ropes", source = "vendor", sourceInfo = "Skull of Er'inye - 1,000 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 1000 } } },
            { decorID = 25139, itemID = 280764, name = "Venomous Defender's Barricade", source = "vendor", sourceInfo = "Skull of Er'inye - 1,000 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 1000 } } },
            { decorID = 25138, itemID = 281577, name = "Venomous Globule", source = "vendor", sourceInfo = "Skull of Er'inye - 750 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 750 } } },
            { decorID = 21832, itemID = 271850, name = "Venomous Tendril", source = "vendor", sourceInfo = "Skull of Er'inye - 750 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 750 } } },
            { decorID = 25137, itemID = 281573, name = "Venomous Thread", source = "vendor", sourceInfo = "Skull of Er'inye - 750 Corrosive Coins", waypoint = LOC.SkullOfErinye, zone = "Vaults of Atal'Utek", cost = { currency = { MC.CURRENCY.CorrosiveCoin, 750 } } },
        },
    },

    -- Delve vendors.
    {
        source = "vendor",
        decorations = {
            { decorID = 25296, itemID = 275853, name = "Zul'Aman Burning Pinecone", source = "vendor", sourceInfo = "Naleidea Rivergleam - 500 Undercoin (Patch 12.1)", waypoint = LOC.NaleideaRivergleam, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.Undercoin, 500 } } },
            { decorID = 24765, itemID = 275857, name = "Zul'Aman Creeping Pangoroot", source = "vendor", sourceInfo = "Naleidea Rivergleam - 500 Undercoin (Patch 12.1)", waypoint = LOC.NaleideaRivergleam, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.Undercoin, 500 } } },
            { decorID = 18798, itemID = 267207, name = "Amani Territorial Totem", source = "vendor", sourceInfo = "Reno Jackson - 250 Voidlight Marl (Patch 12.1)", zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } } },
            { decorID = 16808, itemID = 265386, name = "Fortified Amani Awning", source = "vendor", sourceInfo = "Reno Jackson - 250 Voidlight Marl (Patch 12.1)", zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } } },
            { decorID = 21951, itemID = 272360, name = "Ula'tek Ritual Stone", source = "vendor", sourceInfo = "Reno Jackson - 250 Voidlight Marl (Patch 12.1)", zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } } },
            { decorID = 16316, itemID = 265033, name = "Zul'Aman Brazier Post", source = "vendor", sourceInfo = "Reno Jackson - 250 Voidlight Marl (Patch 12.1)", zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } } },
        },
    },

    -- Prey season two additions from Construct Ali'a.
    {
        source = "vendor",
        decorations = {
            { decorID = 25286, itemID = 278123, name = "Sturdy Silvermoon Crate Lid", source = "vendor", sourceInfo = "Construct Ali'a - 100 Remnant of Anguish (Patch 12.1)", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 100 } } },
            { decorID = 25289, itemID = 278126, name = "Mysterious Sin'dorei Candlestick", source = "vendor", sourceInfo = "Construct Ali'a - 100 Remnant of Anguish (Patch 12.1)", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 100 } } },
            { decorID = 25274, itemID = 278130, name = "Gilded Silvermoon Compass", source = "vendor", sourceInfo = "Construct Ali'a - 100 Remnant of Anguish (Patch 12.1)", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 100 } } },
            { decorID = 25284, itemID = 278134, name = "Sturdy Silvermoon Crate", source = "vendor", sourceInfo = "Construct Ali'a - 100 Remnant of Anguish (Patch 12.1)", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 100 } } },
            { decorID = 7834, itemID = 250870, name = "Crimson Crystal Fragment", source = "vendor", sourceInfo = "Construct Ali'a - 200 Remnant of Anguish (Patch 12.1)", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 200 } } },
            { decorID = 1136, itemID = 253449, name = "Bound Silvermoon Drapes", source = "vendor", sourceInfo = "Construct Ali'a - 200 Remnant of Anguish (Patch 12.1)", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 200 } } },
            { decorID = 25288, itemID = 278145, name = "Stonecarved Sin'dorei Jar", source = "vendor", sourceInfo = "Construct Ali'a - 200 Remnant of Anguish (Patch 12.1)", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 200 } } },
            { decorID = 25287, itemID = 278148, name = "Adorned Sin'dorei Satchel", source = "vendor", sourceInfo = "Construct Ali'a - 100 Remnant of Anguish (Patch 12.1)", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 100 } } },
            { decorID = 25279, itemID = 278151, name = "Blood Knight's Decorative Shield", source = "vendor", sourceInfo = "Construct Ali'a - 350 Remnant of Anguish (Patch 12.1)", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 350 } } },
            { decorID = 7832, itemID = 250868, name = "Crimson Crystal Column", source = "vendor", sourceInfo = "Construct Ali'a - 350 Remnant of Anguish (Patch 12.1)", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 350 } } },
            { decorID = 22145, itemID = 278369, name = "Preyhunter's Scaled Effigy", source = "vendor", sourceInfo = "Construct Ali'a - 600 Remnant of Anguish; Scales for Days", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 600 } }, achievementID = 63451, availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { decorID = 22146, itemID = 278372, name = "Preyhunter's Fanged Effigy", source = "vendor", sourceInfo = "Construct Ali'a - 600 Remnant of Anguish; Fangs for the Memories", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 600 } }, achievementID = 63452, availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { decorID = 24891, itemID = 278380, name = "Preyhunter's Terror Bust", source = "vendor", sourceInfo = "Construct Ali'a - 400 Remnant of Anguish; One, Two, Ral'kala's Coming for You", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 400 } }, achievementID = 63453, availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { decorID = 22148, itemID = 278376, name = "Preyhunter's Terror Effigy", source = "vendor", sourceInfo = "Construct Ali'a - 600 Remnant of Anguish; Nine, Ten, Never Sleep Again", waypoint = LOC.ConstructAlia, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 600 } }, achievementID = 63454, availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
        },
    },

    -- Neighborhood construction and pet-decor vendors.
    {
        source = "vendor",
        decorations = {
            { decorID = 1283, itemID = 243337, name = "Bound-Left Silvermoon Drapes", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.1)" },
            { decorID = 1284, itemID = 243338, name = "Bound-Right Silvermoon Drapes", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.1)" },
            { decorID = 23556, itemID = 280148, name = "Large Triangular Wooden Tile", source = "vendor", sourceInfo = "Neighborhood construction vendor (Patch 12.1)" },
            { decorID = 23554, itemID = 280144, name = "Large Wooden Floor Tile", source = "vendor", sourceInfo = "Neighborhood construction vendor (Patch 12.1)" },
            { decorID = 23708, itemID = 280160, name = "Large Wooden Wall Tile", source = "vendor", sourceInfo = "Neighborhood construction vendor (Patch 12.1)" },
            { decorID = 23558, itemID = 280152, name = "Short Round Wooden Column", source = "vendor", sourceInfo = "Neighborhood construction vendor (Patch 12.1)" },
            { decorID = 23559, itemID = 280154, name = "Short Square Wooden Column", source = "vendor", sourceInfo = "Neighborhood construction vendor (Patch 12.1)" },
            { decorID = 23555, itemID = 280146, name = "Small Triangular Wooden Tile", source = "vendor", sourceInfo = "Neighborhood construction vendor (Patch 12.1)" },
            { decorID = 23553, itemID = 280142, name = "Small Wooden Floor Tile", source = "vendor", sourceInfo = "Neighborhood construction vendor (Patch 12.1)" },
            { decorID = 23707, itemID = 280158, name = "Small Wooden Wall Tile", source = "vendor", sourceInfo = "Neighborhood construction vendor (Patch 12.1)" },
            { decorID = 23710, itemID = 280164, name = "Spiral Wooden Stairs", source = "vendor", sourceInfo = "Neighborhood construction vendor (Patch 12.1)" },
            { decorID = 23557, itemID = 280150, name = "Tall Round Wooden Column", source = "vendor", sourceInfo = "Neighborhood construction vendor (Patch 12.1)" },
            { decorID = 23560, itemID = 280156, name = "Tall Square Wooden Column", source = "vendor", sourceInfo = "Neighborhood construction vendor (Patch 12.1)" },
            { decorID = 23709, itemID = 280162, name = "Wide Wooden Staircase", source = "vendor", sourceInfo = "Neighborhood construction vendor (Patch 12.1)" },
            { decorID = 15290, itemID = 263880, name = "Cherished Pet's Rug", source = "vendor", sourceInfo = "Neighborhood pet decor vendor (Patch 12.1)" },
            { decorID = 25121, itemID = 277121, name = "Cozy Bird Nest", source = "vendor", sourceInfo = "Neighborhood pet decor vendor (Patch 12.1)" },
            { decorID = 25106, itemID = 277160, name = "Cozy Lightbloom Lilypad", source = "vendor", sourceInfo = "Neighborhood pet decor vendor (Patch 12.1)" },
            { decorID = 25102, itemID = 277144, name = "Crossroads Pet Cage", source = "vendor", sourceInfo = "Neighborhood pet decor vendor (Patch 12.1)" },
            { decorID = 25103, itemID = 277149, name = "Crude Pet Cage", source = "vendor", sourceInfo = "Neighborhood pet decor vendor (Patch 12.1)" },
            { decorID = 25122, itemID = 277163, name = "Loyal Companion's Plinth", source = "vendor", sourceInfo = "Neighborhood pet decor vendor (Patch 12.1)" },
            { decorID = 25105, itemID = 277138, name = "Silvermoon Dragonhawk Incubator", source = "vendor", sourceInfo = "Neighborhood pet decor vendor (Patch 12.1)" },
            { decorID = 25101, itemID = 277142, name = "Westfall Pet Cage", source = "vendor", sourceInfo = "Neighborhood pet decor vendor (Patch 12.1)" },
        },
    },

    -- Community Coupon vendors: Westfall collection and Amani Endeavor.
    {
        source = "vendor",
        decorations = {
            { decorID = 26704, itemID = 280631, name = "Demont Orchard Juicer", source = "vendor", sourceInfo = "Westfall decor vendor - 20 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 20 } } },
            { decorID = 25765, itemID = 280625, name = "Framed Moonbrook Quilt", source = "vendor", sourceInfo = "Westfall decor vendor - 10 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 10 } } },
            { decorID = 26705, itemID = 280642, name = "Furlbrow Farm Pumpkin Trio", source = "vendor", sourceInfo = "Westfall decor vendor - 10 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 10 } } },
            { decorID = 25895, itemID = 280627, name = "Jansen Farm Floral Basket", source = "vendor", sourceInfo = "Westfall decor vendor - 10 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 10 } } },
            { decorID = 26940, itemID = 280635, name = "Maxwell Stables Saddle", source = "vendor", sourceInfo = "Westfall decor vendor - 20 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 20 } } },
            { decorID = 26706, itemID = 280644, name = "Molsen Farm Corn Row", source = "vendor", sourceInfo = "Westfall decor vendor - 20 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 20 } } },
            { decorID = 26707, itemID = 280646, name = "Old Moonbrook Creeping Ivy", source = "vendor", sourceInfo = "Westfall decor vendor - 10 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 10 } } },
            { decorID = 26877, itemID = 280654, name = "Old Moonbrook Daylight Window", source = "vendor", sourceInfo = "Westfall decor vendor - 20 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 20 } } },
            { decorID = 27973, itemID = 282347, name = "Old Moonbrook Nighttime Window", source = "vendor", sourceInfo = "Westfall decor vendor - 20 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 20 } } },
            { decorID = 25896, itemID = 280639, name = "Saldean Autumnal Woven Rug", source = "vendor", sourceInfo = "Westfall decor vendor - 10 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 10 } } },
            { decorID = 26876, itemID = 280652, name = "Sentinel Hill Picnic Table", source = "vendor", sourceInfo = "Westfall decor vendor - 30 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 30 } } },
            { decorID = 26703, itemID = 280629, name = "Sentinel Hill Rocking Chair", source = "vendor", sourceInfo = "Westfall decor vendor - 20 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 20 } } },
            { decorID = 27045, itemID = 280637, name = "Torquewrench Tractor", source = "vendor", sourceInfo = "Westfall decor vendor - 30 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 30 } } },
            { decorID = 26708, itemID = 280650, name = "Westfall Farmer's Shed", source = "vendor", sourceInfo = "Westfall decor vendor - 30 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 30 } } },
            { decorID = 26875, itemID = 280633, name = "Westfall Harvest Lamp", source = "vendor", sourceInfo = "Westfall decor vendor - 10 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 10 } } },
            { decorID = 15265, itemID = 263708, name = "Amani Anvil", source = "vendor", sourceInfo = "Amani Endeavor - 15 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 15 } } },
            { decorID = 22920, itemID = 274527, name = "Amani Building Peg", source = "vendor", sourceInfo = "Amani Endeavor - 2 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 2 } } },
            { decorID = 22916, itemID = 274518, name = "Amani Decorative Plinth", source = "vendor", sourceInfo = "Amani Endeavor - 20 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 20 } } },
            { decorID = 22917, itemID = 274521, name = "Amani Road Marker", source = "vendor", sourceInfo = "Amani Endeavor - 15 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 15 } } },
            { decorID = 10859, itemID = 255649, name = "Amani Water Well", source = "vendor", sourceInfo = "Amani Endeavor - 15 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 15 } } },
            { decorID = 15157, itemID = 263317, name = "Amani Wicker Crate", source = "vendor", sourceInfo = "Amani Endeavor - 10 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 10 } } },
            { decorID = 22921, itemID = 274529, name = "Forest Troll Fence", source = "vendor", sourceInfo = "Amani Endeavor - 15 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 15 } } },
            { decorID = 22922, itemID = 274531, name = "Forest Troll Fencepost", source = "vendor", sourceInfo = "Amani Endeavor - 10 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 10 } } },
            { decorID = 22927, itemID = 274505, name = "Shrine of Akil'zon, Loa of Victory", source = "vendor", sourceInfo = "Amani Endeavor - 30 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 30 } } },
            { decorID = 23188, itemID = 274539, name = "Shrine of Halazzi, Loa of the Hunt", source = "vendor", sourceInfo = "Amani Endeavor - 30 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 30 } } },
            { decorID = 22926, itemID = 274537, name = "Shrine of Jan'alai, Loa of Fire", source = "vendor", sourceInfo = "Amani Endeavor - 30 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 30 } } },
            { decorID = 22925, itemID = 274535, name = "Shrine of Nalorakk, Loa of War", source = "vendor", sourceInfo = "Amani Endeavor - 30 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 30 } } },
            { decorID = 22919, itemID = 274525, name = "Steamy Romance Tablet", source = "vendor", sourceInfo = "Amani Endeavor - 10 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 10 } } },
            { decorID = 22924, itemID = 274533, name = "Witch Doctor's Punch Bowl", source = "vendor", sourceInfo = "Amani Endeavor - 15 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 15 } } },
            { decorID = 22918, itemID = 274523, name = "Woven Forest Troll Rug", source = "vendor", sourceInfo = "Amani Endeavor - 15 Community Coupons", cost = { currency = { MC.CURRENCY.CommunityCoupons, 15 } } },
        },
    },

    -- Weekly Cursed Keepsake housing quest.
    {
        source = "quest",
        decorations = {
            { decorID = 18960, itemID = 267435, name = "Purified Kaldorei Candle", source = "quest", sourceInfo = "Cursed Keepsake weekly quest (Patch 12.1)" },
            { decorID = 20332, itemID = 268943, name = "Purified Elven Glowlamp", source = "quest", sourceInfo = "Cursed Keepsake weekly quest (Patch 12.1)" },
            { decorID = 18796, itemID = 267205, name = "Purified Folk Candle", source = "quest", sourceInfo = "Cursed Keepsake weekly quest (Patch 12.1)" },
            { decorID = 15286, itemID = 263876, name = "Purified Folk Mirror", source = "quest", sourceInfo = "Cursed Keepsake weekly quest (Patch 12.1)" },
            { decorID = 18880, itemID = 267355, name = "Purified Elven Mirror", source = "quest", sourceInfo = "Cursed Keepsake weekly quest (Patch 12.1)" },
            { decorID = 21873, itemID = 272129, name = "Purified Tauren Pot", source = "quest", sourceInfo = "Cursed Keepsake weekly quest (Patch 12.1)" },
            { decorID = 11285, itemID = 256684, name = "Purified Troll Amulet", source = "quest", sourceInfo = "Cursed Keepsake weekly quest (Patch 12.1)" },
        },
    },

    -- Patch 12.1 dungeons, world boss, and The Venomous Abyss raid.
    {
        source = "drop",
        decorations = {
            { decorID = 25293, itemID = 279211, name = "Pillar of the Fanged Altar", source = "drop", sourceInfo = "Zul'jan, Altar of Fangs", zone = "Altar of Fangs" },
            { decorID = 26487, itemID = 279112, name = "Clumped Asteroidea", source = "drop", sourceInfo = "Nymrissa Wavecaller, The Tidebound Grotto", zone = "The Tidebound Grotto" },
            { decorID = 26205, itemID = 279115, name = "Soulcoiler's Ritual Candle", source = "drop", sourceInfo = "Nekzali, The Venomous Abyss", zone = "The Venomous Abyss", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { decorID = 16093, itemID = 264716, name = "Hexed Tomb Brazier", source = "drop", sourceInfo = "The Entombed, The Venomous Abyss", zone = "The Venomous Abyss", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { decorID = 26374, itemID = 279118, name = "Lost Explorers' Mailbox", source = "drop", sourceInfo = "The Lost Explorers, The Venomous Abyss", zone = "The Venomous Abyss", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { decorID = 1426, itemID = 244343, name = "Vessel of the Howling Ossuary", source = "drop", sourceInfo = "Sszorak, The Venomous Abyss", zone = "The Venomous Abyss", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { decorID = 25813, itemID = 279122, name = "Venom-Fanged Font", source = "drop", sourceInfo = "The Twin Fangs, The Venomous Abyss", zone = "The Venomous Abyss", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { decorID = 25812, itemID = 279131, name = "Pillar of the Coiled Isle", source = "drop", sourceInfo = "The Coiled Altar, The Venomous Abyss", zone = "The Venomous Abyss", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { decorID = 27043, itemID = 279500, name = "\"Rage of the Shackled\" Mural", source = "drop", sourceInfo = "Ula'tek, The Venomous Abyss", zone = "The Venomous Abyss", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { decorID = 25133, itemID = 279127, name = "The Venomous Abyss Argent Trophy", source = "drop", sourceInfo = "Ula'tek (Normal), The Venomous Abyss", zone = "The Venomous Abyss", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { decorID = 25131, itemID = 279125, name = "The Venomous Abyss Aureate Trophy", source = "drop", sourceInfo = "Ula'tek (Heroic), The Venomous Abyss", zone = "The Venomous Abyss", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { decorID = 25132, itemID = 279129, name = "The Venomous Abyss Gleaming Trophy", source = "drop", sourceInfo = "Ula'tek (Mythic), The Venomous Abyss", zone = "The Venomous Abyss", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
        },
    },
})
