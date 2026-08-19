local _, MC = ...
local T = MC.SCORE_TIERS

MC.DecoSourceOrder = {
    "crafted", "renown", "vendor", "quest", "achievement",
    "drop", "worldevent",
}
MC.DecoSourceLabels = {
    crafted     = "Crafted",
    renown      = "Renown",
    vendor      = "Vendor",
    quest       = "Quest",
    achievement = "Achievement",
    drop        = "Drop",
    worldevent  = "World Event",
}

-- Crafted decorations are grouped by profession. Cooking is omitted (no decor crafts).
MC.DecoProfOrder = {
    MC.PROFESSION.Alchemy,
    MC.PROFESSION.Blacksmithing,
    MC.PROFESSION.Enchanting,
    MC.PROFESSION.Engineering,
    MC.PROFESSION.Inscription,
    MC.PROFESSION.Jewelcrafting,
    MC.PROFESSION.Leatherworking,
    MC.PROFESSION.Tailoring,
}
MC.DecoProfLabels = MC.PROFESSION_LABELS

local LOC = MC.LOC
local M = MC.MAP

--------------------------------------------------------------------------
-- Shared task lists for meta-achievement decorations. Coords inlined here
-- (rather than referenced from MC.RareNPCs) because the Rares data file
-- loads after Decorations in the .toc.
--------------------------------------------------------------------------

-- Tallest Tree in the Forest (62122) — Zul'Aman rare-kill meta. 15 rares.
-- Rewards Colossal Amani Stone Visage. Quest IDs verified May 2026 against
-- Wowhead achievement criteria.
local TALLEST_TREE_TASKS = {
    intro = "Defeat all 15 Zul'Aman rares to earn the Colossal Amani Stone Visage.",
    tasks = {
        { questID = 89569, label = "Necrohexxer Raz'ka",     waypoint = { M.ZulAman, 0.3441, 0.3305, "Necrohexxer Raz'ka" } },
        { questID = 89571, label = "Skullcrusher Harak",     waypoint = { M.ZulAman, 0.5185, 0.7291, "Skullcrusher Harak" } },
        { questID = 91174, label = "Mrrlokk",                waypoint = { M.ZulAman, 0.5087, 0.6514, "Mrrlokk" } },
        { questID = 89578, label = "Spinefrill",             waypoint = { M.ZulAman, 0.3048, 0.4456, "Spinefrill" } },
        { questID = 89580, label = "Tiny Vermin",            waypoint = { M.ZulAman, 0.4777, 0.3422, "Tiny Vermin" } },
        { questID = 89583, label = "The Devouring Invader",  waypoint = { M.ZulAman, 0.3959, 0.2097, "The Devouring Invader" } },
        { questID = 89573, label = "Depthborn Eelamental",   waypoint = { M.ZulAman, 0.4768, 0.2056, "Depthborn Eelamental" } },
        { questID = 91073, label = "Asha the Empowered",     waypoint = { M.ZulAman, 0.4529, 0.4170, "Asha the Empowered" } },
        { questID = 89570, label = "The Snapping Scourge",   waypoint = { M.ZulAman, 0.5180, 0.1862, "The Snapping Scourge" } },
        { questID = 89575, label = "Lightwood Borer",        waypoint = { M.ZulAman, 0.2895, 0.2444, "Lightwood Borer" } },
        { questID = 91634, label = "Poacher Rav'ik",         waypoint = { M.ZulAman, 0.3899, 0.4997, "Poacher Rav'ik" } },
        { questID = 89579, label = "Oophaga",                waypoint = { M.ZulAman, 0.4629, 0.5113, "Oophaga" } },
        { questID = 89581, label = "Voidtouched Crustacean", waypoint = { M.ZulAman, 0.2130, 0.7055, "Voidtouched Crustacean" } },
        { questID = 89572, label = "Elder Oaktalon",         waypoint = { M.ZulAman, 0.3371, 0.8897, "Elder Oaktalon" } },
        { questID = 91072, label = "The Decaying Diamondback", waypoint = { M.ZulAman, 0.4639, 0.4339, "The Decaying Diamondback" } },
    },
}

-- The Ultimate Predator (62130) — Voidstorm rare-kill meta. 14 rares,
-- confirmed against HandyNotes_Midnight criteria links. Rewards Opened
-- Domanaar Storage Crate. Rakshur and Eruundi are on the SlayersRise
-- sub-map; MC.MAP_PARENT[2444]=2405 handles portal routing from Silvermoon.
local ULTIMATE_PREDATOR_TASKS = {
    intro = "Defeat all Voidstorm rares to earn the Opened Domanaar Storage Crate.",
    tasks = {
        { questID = 90805, label = "Sundereth the Caller",     waypoint = { M.Voidstorm,   0.2951, 0.5008, "Sundereth the Caller" } },
        { questID = 91048, label = "Tremora",                  waypoint = { M.Voidstorm,   0.3616, 0.8355, "Tremora" } },
        { questID = 93946, label = "Bane of the Vilebloods",   waypoint = { M.Voidstorm,   0.4705, 0.8063, "Bane of the Vilebloods" } },
        { questID = 93947, label = "Lotus Darkblossom",        waypoint = { M.Voidstorm,   0.3789, 0.7177, "Lotus Darkblossom" } },
        { questID = 93895, label = "Ravengerus",               waypoint = { M.Voidstorm,   0.4881, 0.5326, "Ravengerus" } },
        { questID = 93884, label = "Bilemaw the Gluttonous",   waypoint = { M.Voidstorm,   0.3549, 0.5023, "Bilemaw the Gluttonous" } },
        { questID = 91051, label = "Nightbrood",               waypoint = { M.Voidstorm,   0.4017, 0.4130, "Nightbrood" } },
        { questID = 91050, label = "Territorial Voidscythe",   waypoint = { M.Voidstorm,   0.3405, 0.8198, "Territorial Voidscythe" } },
        { questID = 93966, label = "Screammaxa the Matriarch", waypoint = { M.Voidstorm,   0.4366, 0.5154, "Screammaxa the Matriarch" } },
        { questID = 93944, label = "Aeonelle Blackstar",       waypoint = { M.Voidstorm,   0.3923, 0.6392, "Aeonelle Blackstar" } },
        { questID = 93934, label = "Queen o' War",             waypoint = { M.Voidstorm,   0.5572, 0.7945, "Queen o' War" } },
        { questID = 93953, label = "Rakshur the Bonegrinder",  waypoint = { M.SlayersRise, 0.4633, 0.4094, "Rakshur the Bonegrinder" } },
        { questID = 91047, label = "Eruundi",                  waypoint = { M.SlayersRise, 0.4088, 0.8899, "Eruundi" } },
        { questID = 93896, label = "Far'thana the Mad",        waypoint = { M.Voidstorm,   0.5394, 0.6272, "Far'thana the Mad" } },
    },
}

-- Ever Painting (62185) — 7 paintings from Hesta Forlath in Eversong Woods.
-- Keyed by stable criteriaID; the old positional indices matched an
-- alphabetical listing, not Blizzard's criterion order. Coords absent —
-- player can use the existing Decorations vendor waypoint to reach Hesta.
local EVER_PAINTING_TASKS = {
    intro = "Buy all 7 Eversong paintings from Hesta Forlath.",
    tasks = {
        { achievementID = 62185, criteriaID = 111993, label = "Sway of Red and Gold" },
        { achievementID = 62185, criteriaID = 112031, label = "Anar'alah Belore" },
        { achievementID = 62185, criteriaID = 112033, label = "Babble and Brook" },
        { achievementID = 62185, criteriaID = 112035, label = "Elrendar's Song" },
        { achievementID = 62185, criteriaID = 112030, label = "Lost Lamppost" },
        { achievementID = 62185, criteriaID = 112032, label = "Light Consuming" },
        { achievementID = 62185, criteriaID = 112034, label = "Memories of Ghosts" },
    },
}

-- Legends Never Die (61574) — 7 Haranir storyline quests. Rewards On'ohia's
-- Call. Quest IDs interleave two storyline pairs but Wowhead order works.
local LEGENDS_NEVER_DIE_TASKS = {
    intro = "Complete all 7 Haranir Legends quests to earn On'ohia's Call.",
    tasks = {
        { questID = 88993, label = "Wey'nan's Ward" },
        { questID = 88995, label = "Aln'hara's Bloom" },
        { questID = 88997, label = "Russula's Outreach" },
        { questID = 88999, label = "Sky's Hope" },
        { questID = 88994, label = "The Cauldron of Echoes" },
        { questID = 88996, label = "The Echoless Flame" },
        { questID = 88998, label = "Root of the World" },
    },
}

-- Decoration entry shape: { decorID, [itemID], name, source, sourceInfo,
--   [skillLine], [waypoint], [cost], [zone], [renown], [achievementID],
--   [taskList], [dropInfo] }
-- decorID is the housing catalog record id (Wowhead /decor=NNNN).
-- itemID is only present on crafted entries; the scanner falls back to it
-- via C_HousingCatalog.GetCatalogEntryInfoByItem when decorID lookup fails.

MC.RegisterContent("midnight", "decorations", {
    -- Crafted — Alchemy (skillLine 171)
    {
        source = "crafted",
        decorations = {
            { decorID = 14559, itemID = 262356, name = "Haranir Preserving Agents", source = "crafted", sourceInfo = "Alchemy craft", skillLine = MC.PROFESSION.Alchemy },
            { decorID = 1247, itemID = 253506, name = "Rootbound Vat", source = "crafted", sourceInfo = "Alchemy craft", skillLine = MC.PROFESSION.Alchemy },
            { decorID = 11138, itemID = 256356, name = "Sunsmoke Censer", source = "crafted", sourceInfo = "Alchemy craft", skillLine = MC.PROFESSION.Alchemy },
            { decorID = 14558, itemID = 262355, name = "Entropic Illuminant", source = "crafted", sourceInfo = "Alchemy craft", skillLine = MC.PROFESSION.Alchemy },
            { decorID = 14557, itemID = 262354, name = "Riftstone", source = "crafted", sourceInfo = "Alchemy craft", skillLine = MC.PROFESSION.Alchemy },
            { decorID = 11501, itemID = 257420, name = "Silvermoon Spire Fountain", source = "crafted", sourceInfo = "Alchemy craft", skillLine = MC.PROFESSION.Alchemy },
        },
    },

    -- Crafted — Blacksmithing (skillLine 164)
    {
        source = "crafted",
        decorations = {
            { decorID = 14581, itemID = 262451, name = "Gilded Silvermoon Anvil", source = "crafted", sourceInfo = "Blacksmithing craft", skillLine = MC.PROFESSION.Blacksmithing },
            { decorID = 14587, itemID = 262457, name = "Gilded Silvermoon Hanger", source = "crafted", sourceInfo = "Blacksmithing craft", skillLine = MC.PROFESSION.Blacksmithing },
            { decorID = 14590, itemID = 262460, name = "Ren'dorei Anvil", source = "crafted", sourceInfo = "Blacksmithing craft", skillLine = MC.PROFESSION.Blacksmithing },
            { decorID = 14582, itemID = 262452, name = "Masterwork Crafting Hammer", source = "crafted", sourceInfo = "Blacksmithing craft", skillLine = MC.PROFESSION.Blacksmithing },
            { decorID = 14586, itemID = 262456, name = "Ornamental Silvermoon Hanger", source = "crafted", sourceInfo = "Blacksmithing craft", skillLine = MC.PROFESSION.Blacksmithing },
        },
    },

    -- Crafted — Enchanting (skillLine 333)
    {
        source = "crafted",
        decorations = {
            { decorID = 14580, itemID = 262450, name = "Ensorcelled Broom", source = "crafted", sourceInfo = "Enchanting craft", skillLine = MC.PROFESSION.Enchanting },
            { decorID = 14585, itemID = 262455, name = "Font of Gleaming Water", source = "crafted", sourceInfo = "Enchanting craft", skillLine = MC.PROFESSION.Enchanting },
            { decorID = 14589, itemID = 262459, name = "Animated Sin'dorei Hammer", source = "crafted", sourceInfo = "Enchanting craft", skillLine = MC.PROFESSION.Enchanting },
            { decorID = 14588, itemID = 262458, name = "Animated Sin'dorei Pick", source = "crafted", sourceInfo = "Enchanting craft", skillLine = MC.PROFESSION.Enchanting },
            { decorID = 19229, itemID = 268038, name = "Endless Codex of Blooming Light", source = "crafted", sourceInfo = "Enchanting craft", skillLine = MC.PROFESSION.Enchanting },
            { decorID = 19231, itemID = 268039, name = "Endless Codex of Nature's Grace", source = "crafted", sourceInfo = "Enchanting craft", skillLine = MC.PROFESSION.Enchanting },
            { decorID = 19234, itemID = 268041, name = "Endless Codex of the Voidtouched", source = "crafted", sourceInfo = "Enchanting craft", skillLine = MC.PROFESSION.Enchanting },
            { decorID = 2460, itemID = 246693, name = "Self-Pouring Thalassian Sunwine", source = "crafted", sourceInfo = "Enchanting craft", skillLine = MC.PROFESSION.Enchanting },
            { decorID = 14600, itemID = 262470, name = "Spellbound Tome of Thalassian Magics", source = "crafted", sourceInfo = "Enchanting craft", skillLine = MC.PROFESSION.Enchanting },
            { decorID = 14616, itemID = 262590, name = "Rootflame Campfire", source = "crafted", sourceInfo = "Enchanting craft", skillLine = MC.PROFESSION.Enchanting },
            { decorID = 14598, itemID = 262468, name = "Ren'dorei Postal Repository", source = "crafted", sourceInfo = "Enchanting craft", skillLine = MC.PROFESSION.Enchanting },
        },
    },

    -- Crafted — Engineering (skillLine 202)
    {
        source = "crafted",
        decorations = {
            { decorID = 14643, itemID = 262618, name = "Ren'dorei Void Projector", source = "crafted", sourceInfo = "Engineering craft", skillLine = MC.PROFESSION.Engineering },
            { decorID = 14835, itemID = 263049, name = "Ren'dorei Lightpost", source = "crafted", sourceInfo = "Engineering craft", skillLine = MC.PROFESSION.Engineering },
            { decorID = 2301, itemID = 246460, name = "Ambient Aethercharged Crystal", source = "crafted", sourceInfo = "Engineering craft", skillLine = MC.PROFESSION.Engineering },
            { decorID = 14595, itemID = 262465, name = "Ren'dorei Stargazer", source = "crafted", sourceInfo = "Engineering craft", skillLine = MC.PROFESSION.Engineering },
            { decorID = 14730, itemID = 262789, name = "Small Telogrus Lamp", source = "crafted", sourceInfo = "Engineering craft", skillLine = MC.PROFESSION.Engineering },
            { decorID = 14642, itemID = 262617, name = "Ren'dorei Crafting Framework", source = "crafted", sourceInfo = "Engineering craft", skillLine = MC.PROFESSION.Engineering },
            { decorID = 14627, itemID = 262602, name = "Ren'dorei Warp Orb", source = "crafted", sourceInfo = "Engineering craft", skillLine = MC.PROFESSION.Engineering },
        },
    },

    -- Crafted — Inscription (skillLine 773)
    {
        source = "crafted",
        decorations = {
            { decorID = 14637, itemID = 262612, name = "Sturdy Ren'dorei Cask", source = "crafted", sourceInfo = "Inscription craft", skillLine = MC.PROFESSION.Inscription },
            { decorID = 14594, itemID = 262464, name = "Floating Void-Touched Tome", source = "crafted", sourceInfo = "Inscription craft", skillLine = MC.PROFESSION.Inscription },
            { decorID = 14620, itemID = 262594, name = "Homely Sin'dorei Shelf", source = "crafted", sourceInfo = "Inscription craft", skillLine = MC.PROFESSION.Inscription },
            -- Lively Songwriter's Quill omitted here (listed under treasure drops with decorID 14641)
            { decorID = 14623, itemID = 262598, name = "Opened Sin'dorei Scroll", source = "crafted", sourceInfo = "Inscription craft", skillLine = MC.PROFESSION.Inscription },
            { decorID = 14622, itemID = 262597, name = "Gilded Eversong Book", source = "crafted", sourceInfo = "Inscription craft", skillLine = MC.PROFESSION.Inscription },
            { decorID = 14640, itemID = 262615, name = "Sin'dorei Phoenix Quill", source = "crafted", sourceInfo = "Inscription craft", skillLine = MC.PROFESSION.Inscription },
            { decorID = 14621, itemID = 262595, name = "Homely Wall Shelves", source = "crafted", sourceInfo = "Inscription craft", skillLine = MC.PROFESSION.Inscription },
            { decorID = 14626, itemID = 262601, name = "Wild Hanging Scroll", source = "crafted", sourceInfo = "Inscription craft", skillLine = MC.PROFESSION.Inscription },
            { decorID = 1328, itemID = 253508, name = "Harandar Signpost", source = "crafted", sourceInfo = "Inscription craft", skillLine = MC.PROFESSION.Inscription },
            { decorID = 14820, itemID = 263034, name = "Magnificent Towering Bookcase", source = "crafted", sourceInfo = "Inscription craft", skillLine = MC.PROFESSION.Inscription },
            { decorID = 14731, itemID = 262790, name = "Restful Bronze Bench", source = "crafted", sourceInfo = "Inscription craft", skillLine = MC.PROFESSION.Inscription },
        },
    },

    -- Crafted — Jewelcrafting (skillLine 755)
    {
        source = "crafted",
        decorations = {
            { decorID = 14599, itemID = 262469, name = "Brilliant Phoenix Harp", source = "crafted", sourceInfo = "Jewelcrafting craft", skillLine = MC.PROFESSION.Jewelcrafting },
            { decorID = 14591, itemID = 262461, name = "Tenebrous Ren'dorei Armillary", source = "crafted", sourceInfo = "Jewelcrafting craft", skillLine = MC.PROFESSION.Jewelcrafting },
            { decorID = 14601, itemID = 262471, name = "Bejeweled Sin'dorei Lyre", source = "crafted", sourceInfo = "Jewelcrafting craft", skillLine = MC.PROFESSION.Jewelcrafting },
            { decorID = 5133, itemID = 248965, name = "Resplendent Highborne Statue", source = "crafted", sourceInfo = "Jewelcrafting craft", skillLine = MC.PROFESSION.Jewelcrafting },
            { decorID = 14638, itemID = 262613, name = "Replica Haranir Mural", source = "crafted", sourceInfo = "Jewelcrafting craft", skillLine = MC.PROFESSION.Jewelcrafting },
            { decorID = 14584, itemID = 262454, name = "Shining Sin'dorei Hourglass", source = "crafted", sourceInfo = "Jewelcrafting craft", skillLine = MC.PROFESSION.Jewelcrafting },
        },
    },

    -- Crafted — Leatherworking (skillLine 165)
    {
        source = "crafted",
        decorations = {
            { decorID = 14579, itemID = 262449, name = "Embossed Sin'dorei Fur Rug", source = "crafted", sourceInfo = "Leatherworking craft", skillLine = MC.PROFESSION.Leatherworking },
            { decorID = 1142, itemID = 253457, name = "Leather-Bound Haranir Wall Shelf", source = "crafted", sourceInfo = "Leatherworking craft", skillLine = MC.PROFESSION.Leatherworking },
            { decorID = 17515, itemID = 265791, name = "Haranir Canopy Bed", source = "crafted", sourceInfo = "Leatherworking craft", skillLine = MC.PROFESSION.Leatherworking },
            { decorID = 14625, itemID = 262600, name = "Stitched Haranir Rug", source = "crafted", sourceInfo = "Leatherworking craft", skillLine = MC.PROFESSION.Leatherworking },
            { decorID = 1157, itemID = 243090, name = "Sturdy Haranir Chair", source = "crafted", sourceInfo = "Leatherworking craft", skillLine = MC.PROFESSION.Leatherworking },
            { decorID = 15479, itemID = 264244, name = "Plush Haranir Leather Pillow", source = "crafted", sourceInfo = "Leatherworking craft", skillLine = MC.PROFESSION.Leatherworking },
        },
    },

    -- Crafted — Tailoring (skillLine 197)
    {
        source = "crafted",
        decorations = {
            { decorID = 14624, itemID = 262599, name = "Silvermoon Curtains", source = "crafted", sourceInfo = "Tailoring craft", skillLine = MC.PROFESSION.Tailoring },
            { decorID = 14555, itemID = 262352, name = "Lush Telogrus Carpet", source = "crafted", sourceInfo = "Tailoring craft", skillLine = MC.PROFESSION.Tailoring },
            { decorID = 14617, itemID = 262591, name = "Luxurious Silvermoon Lounge Cushion", source = "crafted", sourceInfo = "Tailoring craft", skillLine = MC.PROFESSION.Tailoring },
            { decorID = 14618, itemID = 262592, name = "Plush Silvermoon Bed", source = "crafted", sourceInfo = "Tailoring craft", skillLine = MC.PROFESSION.Tailoring },
            { decorID = 14619, itemID = 262593, name = "Chic Silvermoon Pillow", source = "crafted", sourceInfo = "Tailoring craft", skillLine = MC.PROFESSION.Tailoring },
            { decorID = 14636, itemID = 262611, name = "Voidstrider Saddlebag", source = "crafted", sourceInfo = "Tailoring craft", skillLine = MC.PROFESSION.Tailoring },
        },
    },

    -- Renown — Silvermoon Court (Caeris Fairdawn, factionID 2710)
    -- Currency: Voidlight Marl (3316)
    {
        source = "renown",
        decorations = {
            { decorID = 14985, name = "Gilded Sky-Blue Drapery", source = "renown", sourceInfo = "Caeris Fairdawn - 750 Voidlight Marl, Renown 3",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 3, factionName = "Silvermoon Court" } },
            { decorID = 14971, name = "Crimson Silvermoon Runner", source = "renown", sourceInfo = "Caeris Fairdawn - 750 Voidlight Marl, Renown 3",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 3, factionName = "Silvermoon Court" } },
            { decorID = 14972, name = "Plum Eversong Rug", source = "renown", sourceInfo = "Caeris Fairdawn - 750 Voidlight Marl, Renown 3",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 3, factionName = "Silvermoon Court" } },
            { decorID = 15059, name = "Grand Lightwood Table", source = "renown", sourceInfo = "Caeris Fairdawn - 2500 Voidlight Marl, Renown 7",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 7, factionName = "Silvermoon Court" } },
            { decorID = 15060, name = "Ornate Lightwood Table", source = "renown", sourceInfo = "Caeris Fairdawn - 750 Voidlight Marl, Renown 7",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 7, factionName = "Silvermoon Court" } },
            { decorID = 10944, name = "Silvermoon Gemmed Chair", source = "renown", sourceInfo = "Caeris Fairdawn - Renown 7",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", renown = { factionID = MC.FACTION.SilvermoonCourt, level = 7, factionName = "Silvermoon Court" } },
            { decorID = 11503, name = "Gilded Sunfury Chair", source = "renown", sourceInfo = "Caeris Fairdawn - Renown 7",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", renown = { factionID = MC.FACTION.SilvermoonCourt, level = 7, factionName = "Silvermoon Court" } },
            { decorID = 15063, name = "Floating Spire Shelf", source = "renown", sourceInfo = "Caeris Fairdawn - 750 Voidlight Marl, Renown 11",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 11, factionName = "Silvermoon Court" } },
            { decorID = 15065, name = "Turning Silvermoon Archives", source = "renown", sourceInfo = "Caeris Fairdawn - 2500 Voidlight Marl, Renown 11",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 11, factionName = "Silvermoon Court" } },
            { decorID = 1901, name = "Floating Azure Lantern", source = "renown", sourceInfo = "Caeris Fairdawn - 750 Voidlight Marl, Renown 15",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 15, factionName = "Silvermoon Court" } },
            { decorID = 15499, name = "Gilded Vigil Post", source = "renown", sourceInfo = "Caeris Fairdawn - 750 Voidlight Marl, Renown 15",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 15, factionName = "Silvermoon Court" } },
            { decorID = 11502, name = "Bejeweled Silvermoon Chandelier", source = "renown", sourceInfo = "Caeris Fairdawn - Renown 15",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", renown = { factionID = MC.FACTION.SilvermoonCourt, level = 15, factionName = "Silvermoon Court" } },
            { decorID = 15500, name = "Sanctified Flame Lantern", source = "renown", sourceInfo = "Caeris Fairdawn - 750 Voidlight Marl, Renown 15",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 15, factionName = "Silvermoon Court" } },
            { decorID = 5564, name = "Reverent Sin'dorei Statue", source = "renown", sourceInfo = "Caeris Fairdawn - 2500 Voidlight Marl, Renown 18",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 18, factionName = "Silvermoon Court" } },
            { decorID = 1896, name = "Silvermoon Sanctum Focus", source = "renown", sourceInfo = "Caeris Fairdawn - 2500 Voidlight Marl, Renown 18",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods", cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.SilvermoonCourt, level = 18, factionName = "Silvermoon Court" } },
        },
    },

    -- Renown — Amani Tribe (Magovu, factionID 2696)
    -- Currency: Voidlight Marl (3316)
    {
        source = "renown",
        decorations = {
            { decorID = 15158, name = "Simple Amani Basket", source = "renown", sourceInfo = "Magovu - 750 Voidlight Marl, Renown 3",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 3, factionName = "Amani Tribe" } },
            { decorID = 15160, name = "Rope-Bound Amani Basket", source = "renown", sourceInfo = "Magovu - 750 Voidlight Marl, Renown 3",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 3, factionName = "Amani Tribe" } },
            { decorID = 15596, name = "Carved Idol of Akil'zon, Loa of Victory", source = "renown", sourceInfo = "Magovu - 750 Voidlight Marl, Renown 7",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 7, factionName = "Amani Tribe" } },
            { decorID = 11333, name = "Carved Idol of Jan'alai, Loa of Fire", source = "renown", sourceInfo = "Magovu - 750 Voidlight Marl, Renown 7",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 7, factionName = "Amani Tribe" } },
            { decorID = 11327, name = "Carved Idol of Nalorakk, Loa of War", source = "renown", sourceInfo = "Magovu - 750 Voidlight Marl, Renown 7",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 7, factionName = "Amani Tribe" } },
            { decorID = 11936, name = "Carved Idol of Halazzi, Loa of the Hunt", source = "renown", sourceInfo = "Magovu - 750 Voidlight Marl, Renown 7",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 7, factionName = "Amani Tribe" } },
            { decorID = 12154, name = "Burning Amani Pinecone", source = "renown", sourceInfo = "Magovu - 750 Voidlight Marl, Renown 11",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 11, factionName = "Amani Tribe" } },
            { decorID = 15571, name = "Amani Incense Burner", source = "renown", sourceInfo = "Magovu - 750 Voidlight Marl, Renown 11",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 11, factionName = "Amani Tribe" } },
            { decorID = 11334, name = "Boiling Amani Cauldron", source = "renown", sourceInfo = "Magovu - 750 Voidlight Marl, Renown 15",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 15, factionName = "Amani Tribe" } },
            { decorID = 11326, name = "Empty Amani Cauldron", source = "renown", sourceInfo = "Magovu - 750 Voidlight Marl, Renown 15",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 15, factionName = "Amani Tribe" } },
            { decorID = 11324, name = "Hash'ey Heartbroth Cauldron", source = "renown", sourceInfo = "Magovu - 750 Voidlight Marl, Renown 15",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 15, factionName = "Amani Tribe" } },
            { decorID = 14204, name = "Visage of Akil'zon, Loa of Victory", source = "renown", sourceInfo = "Magovu - 2500 Voidlight Marl, Renown 18",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 18, factionName = "Amani Tribe" } },
            { decorID = 14351, name = "Visage of Halazzi, Loa of the Hunt", source = "renown", sourceInfo = "Magovu - 2500 Voidlight Marl, Renown 18",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 18, factionName = "Amani Tribe" } },
            { decorID = 14352, name = "Visage of Jan'alai, Loa of Fire", source = "renown", sourceInfo = "Magovu - 2500 Voidlight Marl, Renown 18",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 18, factionName = "Amani Tribe" } },
            { decorID = 14350, name = "Visage of Nalorakk, Loa of War", source = "renown", sourceInfo = "Magovu - 2500 Voidlight Marl, Renown 18",
              waypoint = LOC.Magovu, zone = "Zul'Aman", cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.AmaniTribe, level = 18, factionName = "Amani Tribe" } },
        },
    },

    -- Renown — Hara'ti (Naynar, factionID 2704)
    -- Currency: Voidlight Marl (3316)
    {
        source = "renown",
        decorations = {
            { decorID = 2219, name = "Hollowed Harandar Gourds", source = "renown", sourceInfo = "Naynar - 750 Voidlight Marl, Renown 3",
              waypoint = LOC.Naynar, zone = "Harandar", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Harati, level = 3, factionName = "Hara'ti" } },
            { decorID = 2225, name = "Haranir Herb Rack", source = "renown", sourceInfo = "Naynar - 750 Voidlight Marl, Renown 3",
              waypoint = LOC.Naynar, zone = "Harandar", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Harati, level = 3, factionName = "Hara'ti" } },
            { decorID = 14615, name = "Simple Haranir Table", source = "renown", sourceInfo = "Naynar - Renown 5",
              waypoint = LOC.Naynar, zone = "Harandar", renown = { factionID = MC.FACTION.Harati, level = 5, factionName = "Hara'ti" } },
            { decorID = 2588, name = "Sealed Fungal Jar", source = "renown", sourceInfo = "Naynar - 750 Voidlight Marl, Renown 7",
              waypoint = LOC.Naynar, zone = "Harandar", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Harati, level = 7, factionName = "Hara'ti" } },
            { decorID = 5651, name = "Fungarian Barrel", source = "renown", sourceInfo = "Naynar - 750 Voidlight Marl, Renown 7",
              waypoint = LOC.Naynar, zone = "Harandar", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Harati, level = 7, factionName = "Hara'ti" } },
            { decorID = 8916, name = "Fungarian Sack", source = "renown", sourceInfo = "Naynar - 750 Voidlight Marl, Renown 7",
              waypoint = LOC.Naynar, zone = "Harandar", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Harati, level = 7, factionName = "Hara'ti" } },
            { decorID = 14825, name = "Harandar Flowering Lamp", source = "renown", sourceInfo = "Naynar - 750 Voidlight Marl, Renown 12",
              waypoint = LOC.Naynar, zone = "Harandar", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Harati, level = 12, factionName = "Hara'ti" } },
            { decorID = 14967, name = "Harandar Glowvine Lamppost", source = "renown", sourceInfo = "Naynar - 750 Voidlight Marl, Renown 12",
              waypoint = LOC.Naynar, zone = "Harandar", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Harati, level = 12, factionName = "Hara'ti" } },
            { decorID = 14965, name = "Harandar Glowvine Sconce", source = "renown", sourceInfo = "Naynar - 750 Voidlight Marl, Renown 12",
              waypoint = LOC.Naynar, zone = "Harandar", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Harati, level = 12, factionName = "Hara'ti" } },
            { decorID = 15502, name = "Rutaani Birdfeeder", source = "renown", sourceInfo = "Naynar - 750 Voidlight Marl, Renown 15",
              waypoint = LOC.Naynar, zone = "Harandar", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Harati, level = 15, factionName = "Hara'ti" } },
            { decorID = 15503, name = "Rutaani Birdbath", source = "renown", sourceInfo = "Naynar - 750 Voidlight Marl, Renown 15",
              waypoint = LOC.Naynar, zone = "Harandar", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Harati, level = 15, factionName = "Hara'ti" } },
            { decorID = 15504, name = "Rutaani Bird Perch", source = "renown", sourceInfo = "Naynar - 750 Voidlight Marl, Renown 15",
              waypoint = LOC.Naynar, zone = "Harandar", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Harati, level = 15, factionName = "Hara'ti" } },
            { decorID = 14808, name = "Haranir Pennant", source = "renown", sourceInfo = "Naynar - 750 Voidlight Marl, Renown 18",
              waypoint = LOC.Naynar, zone = "Harandar", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Harati, level = 18, factionName = "Hara'ti" } },
        },
    },

    -- Renown — The Singularity (Anomander, factionID 2699)
    -- Currency: Voidlight Marl (3316)
    {
        source = "renown",
        decorations = {
            { decorID = 14632, name = "Void Elf Throne", source = "renown", sourceInfo = "Anomander - 750 Voidlight Marl, Renown 3",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Singularity, level = 3, factionName = "The Singularity" } },
            { decorID = 5132, name = "Cosmic Void Table", source = "renown", sourceInfo = "Anomander - 750 Voidlight Marl, Renown 3",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Singularity, level = 3, factionName = "The Singularity" } },
            { decorID = 15769, name = "Void Elf Barrel", source = "renown", sourceInfo = "Anomander - 750 Voidlight Marl, Renown 3",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Singularity, level = 3, factionName = "The Singularity" } },
            { decorID = 14603, name = "Cosmic Chalice", source = "renown", sourceInfo = "Anomander - 750 Voidlight Marl, Renown 5",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Singularity, level = 5, factionName = "The Singularity" } },
            { decorID = 15260, name = "Sturdy Void Elf Trunk", source = "renown", sourceInfo = "Anomander - 750 Voidlight Marl, Renown 5",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Singularity, level = 5, factionName = "The Singularity" } },
            { decorID = 14592, name = "Dark Void Inkwell", source = "renown", sourceInfo = "Anomander - 750 Voidlight Marl, Renown 8",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Singularity, level = 8, factionName = "The Singularity" } },
            { decorID = 14596, name = "Void Elf Table", source = "renown", sourceInfo = "Anomander - 750 Voidlight Marl, Renown 8",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Singularity, level = 8, factionName = "The Singularity" } },
            { decorID = 15584, name = "Cosmic Void Orb", source = "renown", sourceInfo = "Anomander - 750 Voidlight Marl, Renown 8",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Singularity, level = 8, factionName = "The Singularity" } },
            { decorID = 15597, name = "Ornate Void Elf Banner", source = "renown", sourceInfo = "Anomander - 750 Voidlight Marl, Renown 12",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Singularity, level = 12, factionName = "The Singularity" } },
            { decorID = 14634, name = "Void Elf Floating Lantern", source = "renown", sourceInfo = "Anomander - 750 Voidlight Marl, Renown 12",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Singularity, level = 12, factionName = "The Singularity" } },
            { decorID = 14593, name = "Cosmic Void Ashwell", source = "renown", sourceInfo = "Anomander - 750 Voidlight Marl, Renown 12",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Singularity, level = 12, factionName = "The Singularity" } },
            { decorID = 15581, name = "Cosmic Void Crate", source = "renown", sourceInfo = "Anomander - 750 Voidlight Marl, Renown 18",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Singularity, level = 18, factionName = "The Singularity" } },
            { decorID = 15578, name = "Cosmic Void Summoning Crystal", source = "renown", sourceInfo = "Anomander - 750 Voidlight Marl, Renown 18",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } }, renown = { factionID = MC.FACTION.Singularity, level = 18, factionName = "The Singularity" } },
            { decorID = 15575, name = "Cosmic Void Training Dummy", source = "renown", sourceInfo = "Anomander - 2500 Voidlight Marl, Renown 18",
              waypoint = LOC.Anomander, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } }, renown = { factionID = MC.FACTION.Singularity, level = 18, factionName = "The Singularity" } },
        },
    },

    -- Vendor — Miscellaneous (Delves, Prey, Slayer's Duellum, Paintings)
    {
        source = "vendor",
        decorations = {
            -- Delves (Naleidea Rivergleam, Undercoin 2803)
            { decorID = 2503, name = "Hanging Mana Brazier", source = "vendor", sourceInfo = "Naleidea Rivergleam - 500 Undercoin",
              waypoint = LOC.NaleideaRivergleam, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.Undercoin, 500 } } },
            { decorID = 7780, name = "Silvermoon Privacy Screen", source = "vendor", sourceInfo = "Naleidea Rivergleam - 500 Undercoin",
              waypoint = LOC.NaleideaRivergleam, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.Undercoin, 500 } } },
            -- Delves (Telemancer Astrandis, Voidlight Marl 3316)
            { decorID = 15401, name = "Twilight Tabernacle", source = "vendor", sourceInfo = "Telemancer Astrandis - 500 Voidlight Marl, Rank 1",
              waypoint = LOC.TelemancerAstrandis, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.VoidlightMarl, 500 } } },
            { decorID = 15399, name = "Fungal Chest", source = "vendor", sourceInfo = "Telemancer Astrandis - 500 Voidlight Marl, Rank 2",
              waypoint = LOC.TelemancerAstrandis, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.VoidlightMarl, 500 } } },
            { decorID = 15460, name = "Amani Strongbox", source = "vendor", sourceInfo = "Telemancer Astrandis - 500 Voidlight Marl, Rank 3",
              waypoint = LOC.TelemancerAstrandis, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.VoidlightMarl, 500 } } },
            { decorID = 15455, name = "Ancient Kaldorei Coffer", source = "vendor", sourceInfo = "Telemancer Astrandis - 500 Voidlight Marl, Rank 4",
              waypoint = LOC.TelemancerAstrandis, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.VoidlightMarl, 500 } } },
            { decorID = 15413, name = "Root-Wrapped Reliquary", source = "vendor", sourceInfo = "Telemancer Astrandis - 500 Voidlight Marl, Rank 7",
              waypoint = LOC.TelemancerAstrandis, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.VoidlightMarl, 500 } } },
            { decorID = 15412, name = "Corewarden's Spoils", source = "vendor", sourceInfo = "Telemancer Astrandis - 500 Voidlight Marl, Rank 8",
              waypoint = LOC.TelemancerAstrandis, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.VoidlightMarl, 500 } } },
            { decorID = 15400, name = "Delver's Bountiful Coffer", source = "vendor", sourceInfo = "Telemancer Astrandis - 500 Voidlight Marl, Rank 10",
              waypoint = LOC.TelemancerAstrandis, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.VoidlightMarl, 500 } } },
            -- Prey (Construct V'anore, Remnant of Anguish 3392)
            { decorID = 17519, name = "Preyseeker's Ornate Plinth", source = "vendor", sourceInfo = "Construct V'anore - 1200 Remnant of Anguish",
              waypoint = LOC.ConstructVanore, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 1200 } } },
            { decorID = 17518, name = "Preyseeker's Plinth", source = "vendor", sourceInfo = "Construct V'anore - 800 Remnant of Anguish",
              waypoint = LOC.ConstructVanore, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.RemnantOfAnguish, 800 } } },
            -- Slayer's Duellum (Thraxadar)
            { decorID = 15585, name = "Galactic Commander's Orb", source = "vendor", sourceInfo = "Thraxadar - 750 Voidlight Marl",
              waypoint = LOC.Thraxadar, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } } },
            { decorID = 3922, name = "Galactic Void-Scarred Banner", source = "vendor", sourceInfo = "Thraxadar - 2500 Voidlight Marl",
              waypoint = LOC.Thraxadar, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 2500 } } },
            { decorID = 15488, name = "Galactic Void-Scarred Barricade", source = "vendor", sourceInfo = "Thraxadar - 750 Voidlight Marl",
              waypoint = LOC.Thraxadar, zone = "Voidstorm", cost = { currency = { MC.CURRENCY.VoidlightMarl, 750 } } },
            -- Paintings (Hesta Forlath, gold)
            { decorID = 9489, name = "'Autumnal Eversong' Unframed Painting", source = "vendor", sourceInfo = "Hesta Forlath - 1,500 gold",
              waypoint = LOC.HestaForlath, zone = "Silvermoon City", cost = { gold = 15000000 } },
            { decorID = 9483, name = "'Brunch and a Book' Unframed Painting", source = "vendor", sourceInfo = "Hesta Forlath - 1,500 gold",
              waypoint = LOC.HestaForlath, zone = "Silvermoon City", cost = { gold = 15000000 } },
            { decorID = 9487, name = "'Isolation' Unframed Painting", source = "vendor", sourceInfo = "Hesta Forlath - 1,500 gold",
              waypoint = LOC.HestaForlath, zone = "Silvermoon City", cost = { gold = 15000000 } },
            { decorID = 9490, name = "'Reclamation' Unframed Painting", source = "vendor", sourceInfo = "Hesta Forlath - 1,500 gold",
              waypoint = LOC.HestaForlath, zone = "Silvermoon City", cost = { gold = 15000000 } },
            { decorID = 9486, name = "'River's Protectors' Unframed Painting", source = "vendor", sourceInfo = "Hesta Forlath - 1,500 gold",
              waypoint = LOC.HestaForlath, zone = "Silvermoon City", cost = { gold = 15000000 } },
            { decorID = 9488, name = "'The Fallen Protectors' Unframed Painting", source = "vendor", sourceInfo = "Hesta Forlath - 1,500 gold",
              waypoint = LOC.HestaForlath, zone = "Silvermoon City", cost = { gold = 15000000 } },
            { decorID = 9629, name = "'The Light Blooms' Unframed Painting", source = "vendor", sourceInfo = "Hesta Forlath - 1,500 gold",
              waypoint = LOC.HestaForlath, zone = "Silvermoon City", cost = { gold = 15000000 } },
            { decorID = 9628, name = "Fresh Canvas", source = "vendor", sourceInfo = "Hesta Forlath - 1,500 gold",
              waypoint = LOC.HestaForlath, zone = "Silvermoon City", cost = { gold = 15000000 } },
        },
    },

    -- Quest — Midnight Zones
    {
        source = "quest",
        decorations = {
            -- Eversong Woods
            { decorID = 1160, name = "Diamond Honor Stone", source = "quest", sourceInfo = "Quest: The Heart of Tranquillien", zone = "Eversong Woods" },
            { decorID = 14635, name = "Swirling Ritual Pedestal", source = "quest", sourceInfo = "Quest: Two Tons of Metal and Holy Fire", zone = "Eversong Woods" },
            { decorID = 1442, name = "Silvermoon Sundial", source = "quest", sourceInfo = "Quest: Fractured", zone = "Eversong Woods" },
            { decorID = 1159, name = "Sin'dorei Honor Stone", source = "quest", sourceInfo = "Quest: The Heart of Tranquillien", zone = "Eversong Woods" },
            { decorID = 15483, name = "Sin'dorei Storage Jar", source = "quest", sourceInfo = "Quest: Fairbreeze Favors", zone = "Eversong Woods" },
            { decorID = 15062, name = "Silvermoon Curio Shelves", source = "quest", sourceInfo = "Quest: Paved in Ash", zone = "Eversong Woods" },
            { decorID = 15895, name = "Ren'dorei Spired Tent", source = "quest", sourceInfo = "Quest: Nothing Stands Forever", zone = "Eversong Woods" },
            { decorID = 1908, name = "Ornate Silvermoon Candelabra", source = "quest", sourceInfo = "Quest: Lightbloom Looming", zone = "Eversong Woods" },
            { decorID = 1489, name = "Majestic Lightwood Table", source = "quest", sourceInfo = "Quest: The First to Know", zone = "Eversong Woods" },
            -- Zul'Aman
            { decorID = 15490, name = "Amani Trophy Frame", source = "quest", sourceInfo = "Quest: Gnarldin Bashing", zone = "Zul'Aman" },
            { decorID = 15572, name = "Amani War Drum", source = "quest", sourceInfo = "Quest: Amani Clarion Call", zone = "Zul'Aman" },
            { decorID = 11328, name = "Banner of the Amani Tribe", source = "quest", sourceInfo = "Quest: Reports Returned", zone = "Zul'Aman" },
            { decorID = 10858, name = "Zul'Aman Ancestral Fountain", source = "quest", sourceInfo = "Quest: De Legend of de Hash'ey", zone = "Zul'Aman" },
            { decorID = 15492, name = "Zul'Aman Armament Rest", source = "quest", sourceInfo = "Quest: The Amani Stand Strong", zone = "Zul'Aman" },
            { decorID = 16092, name = "Zul'Aman Flame Cradle", source = "quest", sourceInfo = "Quest: Embers to a Flame", zone = "Zul'Aman" },
            { decorID = 15743, name = "Skyweave Amani Tapestry", source = "quest", sourceInfo = "Quest: Den of Nalorakk: A Taste of Vengeance", zone = "Zul'Aman" },
            { decorID = 1148, name = "Ritual-Cursed Sarcophagus", source = "quest", sourceInfo = "Quest: Rescue from the Shadows", zone = "Zul'Aman" },
            { decorID = 15744, name = "Greenvine Amani Tapestry", source = "quest", sourceInfo = "Quest: Den of Nalorakk: A Taste of Vengeance", zone = "Zul'Aman" },
            { decorID = 15745, name = "Earthhide Amani Tapestry", source = "quest", sourceInfo = "Quest: Den of Nalorakk: A Taste of Vengeance", zone = "Zul'Aman" },
            -- Harandar
            { decorID = 17886, name = "Altar of the Shul'ka", source = "quest", sourceInfo = "Quest: The Foundation of Aln", zone = "Harandar" },
            { decorID = 15497, name = "Haranir Whistling Arrow", source = "quest", sourceInfo = "Quest: The Echoless Flame", zone = "Harandar" },
            { decorID = 14639, name = "Harandar Runestone", source = "quest", sourceInfo = "Quest: The Traveling Flowers", zone = "Harandar" },
            { decorID = 14968, name = "Harandar Glowvine Lantern", source = "quest", sourceInfo = "Quest: Aln'hara's Bloom", zone = "Harandar" },
            { decorID = 14799, name = "Harandar Anvil", source = "quest", sourceInfo = "Quest: Russula's Outreach", zone = "Harandar" },
            { decorID = 15463, name = "Harandar Charcuterie Board", source = "quest", sourceInfo = "Quest: Root Dash Delivery", zone = "Harandar" },
            { decorID = 8993, name = "Fungal Pergola", source = "quest", sourceInfo = "Quest: Herding Manifestations", zone = "Harandar" },
            { decorID = 15155, name = "Bubbling Haranir Cauldron", source = "quest", sourceInfo = "Quest: The Traveling Flowers", zone = "Harandar" },
            { decorID = 10327, name = "Root-Woven Door", source = "quest", sourceInfo = "Quest: Can We Heal This?", zone = "Harandar" },
            { decorID = 10778, name = "Root-Woven Window", source = "quest", sourceInfo = "Quest: Light Finds a Way", zone = "Harandar" },
            { decorID = 14827, name = "Replica Root of the World", source = "quest", sourceInfo = "Quest: Root of the World", zone = "Harandar" },
            { decorID = 1080, name = "Replica Sky's Hope", source = "quest", sourceInfo = "Quest: Sky's Hope", zone = "Harandar" },
            { decorID = 14823, name = "Replica Wey'nan's Ward", source = "quest", sourceInfo = "Quest: Wey'nan's Ward", zone = "Harandar" },
            { decorID = 1726, name = "Sturdy Haranir Handcart", source = "quest", sourceInfo = "Quest: Halting Harm in Har'mara", zone = "Harandar" },
            { decorID = 2224, name = "Stoppered Spring Water Gourd", source = "quest", sourceInfo = "Quest: Descent into the Rift", zone = "Harandar" },
            { decorID = 1147, name = "Rutaani Sporepod", source = "quest", sourceInfo = "Quest: Into the Lightbloom", zone = "Harandar" },
            { decorID = 2605, name = "Rustic Harandar Planter", source = "quest", sourceInfo = "Quest: Light Finds a Way", zone = "Harandar" },
            { decorID = 2232, name = "Ruddy Haranir Pigment Bowl", source = "quest", sourceInfo = "Quest: Echoes and Memories", zone = "Harandar" },
            { decorID = 14809, name = "Ward of the Shul'ka", source = "quest", sourceInfo = "Quest: From This Point Forward", zone = "Harandar" },
            -- Voidstorm
            { decorID = 15579, name = "Cosmic Barrel", source = "quest", sourceInfo = "Quest: Third, Blow It Up", zone = "Voidstorm" },
            { decorID = 14602, name = "Cosmic Kettle", source = "quest", sourceInfo = "Quest: A Strange, Different World", zone = "Voidstorm" },
            { decorID = 15894, name = "Cosmic Traveler's Satchel", source = "quest", sourceInfo = "Quest: The Harvest", zone = "Voidstorm" },
            { decorID = 14631, name = "Smoldering Energy Forge", source = "quest", sourceInfo = "Quest: Nexus-Point Xenas: Eclipse", zone = "Voidstorm" },
            { decorID = 15768, name = "Sturdy Void Elf Barricade", source = "quest", sourceInfo = "Quest: A Matter of Strife and Death", zone = "Voidstorm" },
            { decorID = 15071, name = "Sturdy Void Elf Crate", source = "quest", sourceInfo = "Quest: Work Disruption", zone = "Voidstorm" },
            { decorID = 14554, name = "Ornate Cosmic Rug", source = "quest", sourceInfo = "Quest: Face the Tide", zone = "Voidstorm" },
            { decorID = 18617, name = "Ornate Cosmic Table", source = "quest", sourceInfo = "Quest: All Become Prey", zone = "Voidstorm" },
            { decorID = 15891, name = "Open Sturdy Void Elf Trunk", source = "quest", sourceInfo = "Quest: First, The Shells", zone = "Voidstorm" },
            { decorID = 18800, name = "Open Void Elf Bedroll", source = "quest", sourceInfo = "Quest: Just In Case...", zone = "Voidstorm" },
        },
    },

    -- Achievement — Exploration, Profession Signs, Questing
    {
        source = "achievement",
        decorations = {
            -- Exploration: Highest Peaks
            { decorID = 10542, name = "'Eversong Lantern' Painting", source = "achievement", sourceInfo = "Eversong Woods: The Highest Peaks", achievementID = 62288, score = T.short },
            { decorID = 11325, name = "Amani Spearhunter's Spit", source = "achievement", sourceInfo = "Zul'Aman: The Highest Peaks", achievementID = 62289, score = T.short },
            { decorID = 17516, name = "Fungarian Vine Fence", source = "achievement", sourceInfo = "Harandar: The Highest Peaks", achievementID = 62290, score = T.short },
            { decorID = 15890, name = "Void Elf Weapon Rack", source = "achievement", sourceInfo = "Voidstorm: The Highest Peaks", achievementID = 62291, score = T.short },
            -- Exploration: Other
            { decorID = 11470, name = "Silvermoon Energy Focus", source = "achievement", sourceInfo = "A Bloody Song", achievementID = 61507 },
            { decorID = 15573, name = "Colossal Amani Stone Visage", source = "achievement", sourceInfo = "Tallest Tree in the Forest", achievementID = 62122, taskList = TALLEST_TREE_TASKS, score = T.short },
            { decorID = 15501, name = "Lightbloom Moss Mound", source = "achievement", sourceInfo = "Leaf None Behind", achievementID = 61264 },
            { decorID = 15757, name = "Opened Domanaar Storage Crate", source = "achievement", sourceInfo = "The Ultimate Predator", achievementID = 62130, taskList = ULTIMATE_PREDATOR_TASKS, score = T.short },
            { decorID = 1446, name = "Silvermoon Painter's Cushion", source = "achievement", sourceInfo = "Ever Painting", achievementID = 62185, taskList = EVER_PAINTING_TASKS, score = T.short },
            -- Questing
            { decorID = 15494, name = "On'ohia's Call", source = "achievement", sourceInfo = "Legends Never Die", achievementID = 61574, taskList = LEGENDS_NEVER_DIE_TASKS, score = T.short },
            -- Zone Events
            { decorID = 8872, name = "Eversong Feast Platter", source = "achievement", sourceInfo = "The Party Must Go On", achievementID = 62186 },
            { decorID = 8874, name = "Eversong Dessert Platter", source = "achievement", sourceInfo = "The Party Must Go On", achievementID = 62186 },
            -- Profession Shop Signs
            { decorID = 15402, name = "Midnight Alchemist's Shop Sign", source = "achievement", sourceInfo = "Alchemizing at Midnight", achievementID = 42788 },
            { decorID = 15403, name = "Midnight Blacksmith's Shop Sign", source = "achievement", sourceInfo = "Blacksmithing at Midnight", achievementID = 42792 },
            { decorID = 15404, name = "Midnight Cook's Shop Sign", source = "achievement", sourceInfo = "Cooking at Midnight", achievementID = 42795 },
            { decorID = 15405, name = "Midnight Enchanter's Shop Sign", source = "achievement", sourceInfo = "Enchanting at Midnight", achievementID = 42787 },
            { decorID = 15406, name = "Midnight Engineer's Shop Sign", source = "achievement", sourceInfo = "Engineering at Midnight", achievementID = 42798 },
            { decorID = 15407, name = "Midnight Fisher's Shop Sign", source = "achievement", sourceInfo = "Fishing at Midnight", achievementID = 42797 },
            { decorID = 15408, name = "Midnight Herbalist's Shop Sign", source = "achievement", sourceInfo = "Herbalism at Midnight", achievementID = 42793 },
            { decorID = 15410, name = "Midnight Jewelcrafter's Shop Sign", source = "achievement", sourceInfo = "Jewelcrafting at Midnight", achievementID = 42789 },
            { decorID = 15411, name = "Midnight Leatherworker's Shop Sign", source = "achievement", sourceInfo = "Leatherworking at Midnight", achievementID = 42786 },
            { decorID = 15457, name = "Midnight Miner's Shop Sign", source = "achievement", sourceInfo = "Mining at Midnight", achievementID = 42791 },
            { decorID = 15409, name = "Midnight Scribe's Shop Sign", source = "achievement", sourceInfo = "Inscribing at Midnight", achievementID = 42796 },
            { decorID = 15458, name = "Midnight Skinner's Shop Sign", source = "achievement", sourceInfo = "Skinning at Midnight", achievementID = 42790 },
            { decorID = 15459, name = "Midnight Tailor's Shop Sign", source = "achievement", sourceInfo = "Tailoring at Midnight", achievementID = 42794 },
            -- Feat of Strength
            { decorID = 14467, name = "Miniature Replica Dark Portal", source = "achievement", sourceInfo = "It's Nearly Midnight", achievementID = 62387, score = T.trivial },
        },
    },

    -- Drop — Delves, Dungeons, Raids, Treasures
    {
        source = "drop",
        decorations = {
            -- Delve chest rewards
            { decorID = 15567, name = "Amani Dining Table", source = "drop", sourceInfo = "Delve chest rewards", zone = "Delves" },
            { decorID = 15568, name = "Amani Hanging Brazier", source = "drop", sourceInfo = "Delve chest rewards", zone = "Delves" },
            { decorID = 18485, name = "Amani Training Dummy", source = "drop", sourceInfo = "Delve chest rewards", zone = "Delves" },
            { decorID = 15493, name = "Blossoming Forge", source = "drop", sourceInfo = "Delve chest rewards", zone = "Delves" },
            { decorID = 15582, name = "Cosmic Void Cache", source = "drop", sourceInfo = "Delve chest rewards", zone = "Delves" },
            { decorID = 8889, name = "Fungarian Banner", source = "drop", sourceInfo = "Delve chest rewards", zone = "Delves" },
            { decorID = 14822, name = "Hanging Dawnflower", source = "drop", sourceInfo = "Delve chest rewards", zone = "Delves" },
            { decorID = 14828, name = "Rootlight Lamppost", source = "drop", sourceInfo = "Delve chest rewards", zone = "Delves" },
            { decorID = 15064, name = "Sin'dorei Spinning Library", source = "drop", sourceInfo = "Delve chest rewards", zone = "Delves" },
            -- Dungeon drops
            { decorID = 16094, name = "Amani Warding Hex", source = "drop", sourceInfo = "Rak'tul, Maisara Caverns",
              dropInfo = { mob = "Rak'tul", zone = "Maisara Caverns", boss = true, rate = "100%" } },
            { decorID = 15576, name = "Domanaar Control Console", source = "drop", sourceInfo = "Lothraxion, Nexus-Point Xenas",
              dropInfo = { mob = "Lothraxion", zone = "Nexus-Point Xenas", boss = true, rate = "100%" } },
            { decorID = 15069, name = "Illicit Long Table", source = "drop", sourceInfo = "Lithiel Cinderfury, Murder Row",
              dropInfo = { mob = "Lithiel Cinderfury", zone = "Murder Row", boss = true, rate = "100%" } },
            { decorID = 15061, name = "Magister's Bookshelf", source = "drop", sourceInfo = "Degentrius, Magisters' Terrace",
              dropInfo = { mob = "Degentrius", zone = "Magisters' Terrace", boss = true, rate = "100%" } },
            { decorID = 11284, name = "Silvermoon Training Dummy", source = "drop", sourceInfo = "Restless Heart, Windrunner Spire",
              dropInfo = { mob = "The Restless Heart", zone = "Windrunner Spire", boss = true, rate = "100%" } },
            { decorID = 1137, name = "Veilroot Fountain", source = "drop", sourceInfo = "Ziekket, The Blinding Vale",
              dropInfo = { mob = "Ziekket", zone = "The Blinding Vale", boss = true, rate = "100%" } },
            { decorID = 15574, name = "Voidlight Brazier", source = "drop", sourceInfo = "Charonus, Voidscar Arena",
              dropInfo = { mob = "Charonus", zone = "Voidscar Arena", boss = true, rate = "100%" } },
            { decorID = 15570, name = "Amani Ritual Altar", source = "drop", sourceInfo = "Nalorakk, Den of Nalorakk",
              dropInfo = { mob = "Nalorakk", zone = "Den of Nalorakk", boss = true, rate = "100%" } },
            -- Raid drops: The Voidspire
            { decorID = 15758, name = "Banded Domanaar Storage Crate", source = "drop", sourceInfo = "Fallen-King Salhadaar, The Voidspire",
              dropInfo = { mob = "Fallen-King Salhadaar", zone = "The Voidspire", boss = true, rate = "100%" }, score = T.short },
            { decorID = 15761, name = "Imperator's Torment Crystal", source = "drop", sourceInfo = "Imperator Averzian, The Voidspire",
              dropInfo = { mob = "Imperator Averzian", zone = "The Voidspire", boss = true, rate = "100%" }, score = T.short },
            { decorID = 14806, name = "Tattered Vanguard Banner", source = "drop", sourceInfo = "War Chaplain Senn, The Voidspire",
              dropInfo = { mob = "War Chaplain Senn", zone = "The Voidspire", boss = true, rate = "100%" }, score = T.short },
            { decorID = 15755, name = "Voidbound Holding Cell", source = "drop", sourceInfo = "Vaelgor, The Voidspire",
              dropInfo = { mob = "Vaelgor", zone = "The Voidspire", boss = true, rate = "100%" }, score = T.short },
            { decorID = 15762, name = "Voltaic Trigore Egg", source = "drop", sourceInfo = "Vorasius, The Voidspire",
              dropInfo = { mob = "Vorasius", zone = "The Voidspire", boss = true, rate = "100%" }, score = T.short },
            -- Raid trophies: The Voidspire (Argent=Normal 5, Aureate=Heroic 10, Gleaming=Mythic 25)
            { decorID = 19252, name = "Voidspire Vanquisher's Argent Trophy", source = "drop", sourceInfo = "Alleria Windrunner (Normal)", zone = "The Voidspire", score = T.short },
            { decorID = 17630, name = "Voidspire Vanquisher's Aureate Trophy", source = "drop", sourceInfo = "Alleria Windrunner (Heroic)", zone = "The Voidspire", score = T.medium },
            { decorID = 18398, name = "Voidspire Vanquisher's Gleaming Trophy", source = "drop", sourceInfo = "Alleria Windrunner (Mythic)", zone = "The Voidspire", score = T.long },
            -- Raid trophies: The Dreamrift
            { decorID = 19197, name = "Dreamrift Vanquisher's Argent Trophy", source = "drop", sourceInfo = "Chimaerus (Normal)", zone = "The Dreamrift", score = T.short },
            { decorID = 17629, name = "Dreamrift Vanquisher's Aureate Trophy", source = "drop", sourceInfo = "Chimaerus (Heroic)", zone = "The Dreamrift", score = T.medium },
            { decorID = 18397, name = "Dreamrift Vanquisher's Gleaming Trophy", source = "drop", sourceInfo = "Chimaerus (Mythic)", zone = "The Dreamrift", score = T.long },
            { decorID = 15481, name = "Eerie Iridescent Riftshroom", source = "drop", sourceInfo = "Chimaerus, The Dreamrift",
              dropInfo = { mob = "Chimaerus", zone = "The Dreamrift", boss = true, rate = "100%" }, score = T.short },
            -- Raid trophies: March on Quel'Danas
            { decorID = 19198, name = "March on Quel'Danas Vanquisher's Argent Trophy", source = "drop", sourceInfo = "L'ura (Normal)", zone = "March on Quel'Danas", score = T.short },
            { decorID = 17628, name = "March on Quel'Danas Vanquisher's Aureate Trophy", source = "drop", sourceInfo = "L'ura (Heroic)", zone = "March on Quel'Danas", score = T.medium },
            { decorID = 18396, name = "March on Quel'Danas Vanquisher's Gleaming Trophy", source = "drop", sourceInfo = "L'ura (Mythic)", zone = "March on Quel'Danas", score = T.long },
            { decorID = 15467, name = "Blessed Phoenix Egg", source = "drop", sourceInfo = "Void Ember, March on Quel'Danas",
              dropInfo = { mob = "Void Ember", zone = "March on Quel'Danas", boss = true, rate = "100%" }, score = T.short },
            { decorID = 15756, name = "Chaotic Void Maw", source = "drop", sourceInfo = "L'ura, March on Quel'Danas",
              dropInfo = { mob = "L'ura", zone = "March on Quel'Danas", boss = true, rate = "100%" }, score = T.short },
            -- Treasures
            { decorID = 14977, name = "Gilded Eversong Cup", source = "drop", sourceInfo = "Gift of the Phoenix treasure", zone = "Eversong Woods" },
            { decorID = 8875, name = "Goldenmist Grapes", source = "drop", sourceInfo = "Stone Vat treasure", zone = "Eversong Woods" },
            { decorID = 14641, name = "Lively Songwriter's Quill", source = "drop", sourceInfo = "Forgotten Ink and Quill treasure", zone = "Eversong Woods" },
            { decorID = 1173, name = "Gemmed Eversong Lantern", source = "drop", sourceInfo = "Triple-Locked Safebox treasure", zone = "Eversong Woods" },
            { decorID = 1195, name = "Silvermoon Library Bookcase", source = "drop", sourceInfo = "Incomplete Book of Sonnets treasure", zone = "Eversong Woods" },
            { decorID = 2233, name = "Waterlogged Haranir Pigment Bowl", source = "drop", sourceInfo = "Reliquary's Lost Paint Supplies treasure", zone = "Harandar" },
            { decorID = 14597, name = "Void Elf Round Table", source = "drop", sourceInfo = "Stellar Stash treasure", zone = "Voidstorm" },
            { decorID = 15746, name = "Void Elf Torch", source = "drop", sourceInfo = "Malignant Chest treasure", zone = "Voidstorm" },
        },
    },

    -- World Event — Pre-Patch: Twilight Ascension
    {
        source = "worldevent",
        decorations = {
            { decorID = 714, name = "Silvermoon Wooden Chair", source = "worldevent", sourceInfo = "Dethelin - 3000 Twilight's Blade Insignia",
              cost = { currency = { MC.CURRENCY.TwilightsBladeInsignia, 3000 } } },
            { decorID = 1236, name = "Enchanted Blood Elven Candelabra", source = "worldevent", sourceInfo = "Dethelin - 3000 Twilight's Blade Insignia",
              cost = { currency = { MC.CURRENCY.TwilightsBladeInsignia, 3000 } } },
            { decorID = 1227, name = "Sin'dorei Winged Chaise", source = "worldevent", sourceInfo = "Dethelin - 5000 Twilight's Blade Insignia",
              cost = { currency = { MC.CURRENCY.TwilightsBladeInsignia, 5000 } } },
        },
    },

    -- World Event — Abundance (Chel the Chip)
    -- Chel rotates between 4 Abundance locations weekly; multi-waypoint
    -- drops a marker at all four (mirrors the Amani Sunfeather mount).
    (function()
        local CHEL_WAYPOINTS = {
            { MC.MAP.Eversong,  0.5678, 0.6579, "Chel the Chip (Watha'nan Crypts)" },
            { MC.MAP.ZulAman,   0.3162, 0.2614, "Chel the Chip (Loaknit Den)" },
            { MC.MAP.Harandar,  0.6614, 0.6169, "Chel the Chip (Floaret Grotto)" },
            { MC.MAP.Voidstorm, 0.3882, 0.5331, "Chel the Chip (Abundant Voidburrow)" },
        }
        return {
            source = "worldevent",
            decorations = {
                { decorID = 11323, name = "Amani Crafter's Tool Rack", source = "worldevent", sourceInfo = "Chel the Chip - 3200 Unalloyed Abundance", waypoint = CHEL_WAYPOINTS },
                { decorID = 15851, name = "Amani Slate Bench",          source = "worldevent", sourceInfo = "Chel the Chip - 3200 Unalloyed Abundance", waypoint = CHEL_WAYPOINTS },
                { decorID = 15484, name = "Woodblock Stool",            source = "worldevent", sourceInfo = "Chel the Chip - 1600 Unalloyed Abundance", waypoint = CHEL_WAYPOINTS },
                { decorID = 15489, name = "Three-Tier Zul'Aman Shelf",  source = "worldevent", sourceInfo = "Chel the Chip - 3200 Unalloyed Abundance", waypoint = CHEL_WAYPOINTS },
            },
        }
    end)(),
})
