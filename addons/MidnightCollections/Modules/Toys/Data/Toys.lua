local _, MC = ...

MC.ToySourceOrder = {
    "renown", "achievement", "quest", "treasure", "drop",
    "dungeon", "raid", "vendor", "profession", "worldevent",
}
MC.ToySourceLabels = {
    renown      = "Renown",
    achievement = "Achievement",
    quest       = "Quest",
    treasure    = "Treasure",
    drop        = "Rare Drop",
    dungeon     = "Dungeon",
    raid        = "Raid",
    vendor      = "Vendor",
    profession  = "Profession",
    worldevent  = "World Event",
}

local LOC = MC.LOC

-- Toy entry shape: { itemID, name, source, sourceInfo,
--   [waypoint], [overworldWaypoint], [cost], [zone], [renown],
--   [achievementID], [dropInfo] }
-- itemID is the same number you'd pass to PlayerHasToy / C_ToyBox.GetToyInfo.

MC.ToyData = {
    -- Renown vendor toys (Voidlight Marl)
    {
        source = "renown",
        toys = {
            { itemID = 259240, name = "Sin'dorei Wine", source = "renown",
              sourceInfo = "Caeris Fairdawn - Renown 13, Silvermoon Court",
              waypoint = LOC.CaerisFairdawn, zone = "Eversong Woods",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 4000 } },
              renown = { factionID = MC.FACTION.SilvermoonCourt, level = 13, factionName = "Silvermoon Court" } },
            { itemID = 250974, name = "Akil'zon's Updraft", source = "renown",
              sourceInfo = "Magovu - Renown 13, Amani Tribe",
              waypoint = LOC.Magovu, zone = "Zul'Aman",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 4000 } },
              renown = { factionID = MC.FACTION.AmaniTribe, level = 13, factionName = "Amani Tribe" } },
            { itemID = 256552, name = "Verdant Rutaani Seed", source = "renown",
              sourceInfo = "Naynar - Renown 13, Hara'ti",
              waypoint = LOC.Naynar, zone = "Harandar",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 4000 } },
              renown = { factionID = MC.FACTION.Harati, level = 13, factionName = "Hara'ti" } },
            { itemID = 263244, name = "Enigmatic Fountain", source = "renown",
              sourceInfo = "Void Researcher Anomander - Renown 16, The Singularity",
              waypoint = LOC.Anomander, zone = "Voidstorm",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 4000 } },
              renown = { factionID = MC.FACTION.Singularity, level = 16, factionName = "The Singularity" } },
        },
    },

    -- Achievement toys (zone treasure meta-achievements + hidden FoS)
    {
        source = "achievement",
        toys = {
            { itemID = 268717, name = "Pango Plating", source = "achievement",
              sourceInfo = "Treasures of Zul'Aman", zone = "Zul'Aman",
              achievementID = 62125 },
            { itemID = 264695, name = "Interdimensional Parcel Signal", source = "achievement",
              sourceInfo = "Treasures of Voidstorm", zone = "Voidstorm",
              achievementID = 62126 },
            { itemID = 263975, name = "Feeling Fielder Mk. 7", source = "achievement",
              sourceInfo = "Hidden Feat of Strength: Illicit Rain — Five Stars" },
            { itemID = 268695, name = "Pin-o-Matic Camera", source = "achievement",
              sourceInfo = "Pinterest x WoW promotion (Feat of Strength)" },
            -- Pre-patch Family Battler chain (added in Midnight pre-patch)
            { itemID = 251491, name = "Magical Pet Clicker", source = "achievement",
              sourceInfo = "Old World Family Battler chain (Midnight pre-patch)",
              achievementID = 61094 },
            { itemID = 266370, name = "Dundun's Abundant Travel Method", source = "achievement",
              sourceInfo = "Achievement: Abundance: Azeroth Runs on Dundun (teleports to current Abundant location)",
              achievementID = 42283 },
            { itemID = 272339, name = "Umbral Champion's Illustrious Banner", source = "achievement",
              sourceInfo = "WoW Esports / AWC participation OR Time Trial Keystones (Midnight Season 1)" },
        },
    },

    -- Quest toys (campaign rewards)
    {
        source = "quest",
        toys = {
            { itemID = 253629, name = "Personal Key to the Arcantina", source = "quest",
              sourceInfo = "End of the Arator's Journey campaign chapter",
              zone = "Silvermoon City" },
            { itemID = 264413, name = "Dominating Victory", source = "quest",
              sourceInfo = "Quest: Nulling Nullaeus (Torment's Rise nemesis delve)" },
            { itemID = 263871, name = "Holy Pet Leash", source = "quest",
              sourceInfo = "Quest: Pet Wranglin' (capture a wild pet in any Midnight zone)",
              zone = "Silvermoon City" },
            { itemID = 257736, name = "Lightcalled Hearthstone", source = "quest",
              sourceInfo = "March on Quel'Danas storyline quest reward",
              zone = "Isle of Quel'Danas" },
            { itemID = 267456, name = "Lil' Scoots' Pillow", source = "quest",
              sourceInfo = "Quest: Scoot Along Now (return Lil' Scoots to Ranger Telenus)",
              zone = "Eversong Woods" },
            { itemID = 263198, name = "Valdekar's Special", source = "quest",
              sourceInfo = "Quest: Lost in Light",
              zone = "Eversong Woods" },
            { itemID = 260427, name = "Nahuut's Second-Favorite Chew Toy", source = "quest",
              sourceInfo = "Quest: Leave Your Mark (A Goblin in Harandar storyline)",
              zone = "Harandar" },
            { itemID = 264183, name = "Kelum'ko's Generous Aromatic Gift", source = "quest",
              sourceInfo = "Quest: Unlikely Friends (Zul'Aman Sojourner storyline)",
              zone = "Zul'Aman" },
        },
    },

    -- Zone treasure toys (single chest / interaction loot, not meta-rewards)
    {
        source = "treasure",
        toys = {
            { itemID = 258963, name = "Shroom Jumper's Parachute", source = "treasure",
              sourceInfo = "Failed Shroom Jumper's Satchel (cliff in NE Harandar)",
              zone = "Harandar",
              dropInfo = { mob = "Failed Shroom Jumper's Satchel", zone = "Harandar" } },
            { itemID = 259084, name = "Gift of the Cycle", source = "treasure",
              sourceInfo = "Bottom of the pool in The Den, Harandar",
              zone = "Harandar" },
            { itemID = 267139, name = "Hungry Black Hole", source = "treasure",
              sourceInfo = "Bloody Sack, Obscurion Citadel (Voidstorm)",
              zone = "Voidstorm",
              dropInfo = { mob = "Bloody Sack", zone = "Voidstorm" } },
            { itemID = 250319, name = "Researcher's Shadowgraft", source = "treasure",
              sourceInfo = "Forgotten Researcher's Cache (Lair of Predaxas, Voidstorm)",
              zone = "Voidstorm",
              dropInfo = { mob = "Forgotten Researcher's Cache", zone = "Voidstorm" } },
        },
    },

    -- Drop toys (transformations — chest / rare drops)
    {
        source = "drop",
        toys = {
            { itemID = 252265, name = "Hexed Potatoad Mucus", source = "drop",
              sourceInfo = "One of the one-time Sturdy Chests in the Atal'Aman delve (Atal'Aman Discoveries achievement)",
              zone = "Zul'Aman",
              dropInfo = { mob = "Sturdy Chest", zone = "Atal'Aman delve", rate = "Guaranteed (one-time)" } },
            { itemID = 251903, name = "Potatoad Egg", source = "drop",
              sourceInfo = "Use Hexed Potatoad Mucus first, then interact with Gravid Potatoad in Blinding Vale while transformed",
              dropInfo = { mob = "Gravid Potatoad", zone = "The Blinding Vale", rate = "Guaranteed" } },
            { itemID = 264805, name = "Brann-O-Vision 3000", source = "drop",
              sourceInfo = "Sturdy Chest (delve loot)",
              dropInfo = { mob = "Sturdy Chest", zone = "Delves" } },
        },
    },

    -- Dungeon / Raid drops
    {
        source = "dungeon",
        toys = {
            { itemID = 268728, name = "Saptor Salve", source = "dungeon",
              sourceInfo = "Ziekket (Mythic), The Blinding Vale",
              dropInfo = { mob = "Ziekket", zone = "The Blinding Vale", boss = true } },
        },
    },
    {
        source = "raid",
        toys = {
            { itemID = 264672, name = "Cosmic Ritual Stone", source = "raid",
              sourceInfo = "Fallen-King Salhadaar, The Voidspire",
              dropInfo = { mob = "Fallen-King Salhadaar", zone = "The Voidspire", boss = true } },
        },
    },

    -- Vendor toys (Decor Duels — Illusionary Coin; Abyss Anglers — Angler Pearls;
    -- Delves — Voidlight Marl)
    {
        source = "vendor",
        toys = {
            -- Decor Duels (Gamesmaster Fleurin, Falconwing Square)
            { itemID = 268456, name = "Animated Bench", source = "vendor",
              sourceInfo = "Gamesmaster Fleurin - 200 Illusionary Coins (Decor Duels)",
              waypoint = LOC.GamesmasterFleurin, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.IllusionaryCoin, 200 } } },
            { itemID = 268455, name = "Enchanted Hourglass", source = "vendor",
              sourceInfo = "Gamesmaster Fleurin - 200 Illusionary Coins (Decor Duels)",
              waypoint = LOC.GamesmasterFleurin, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.IllusionaryCoin, 200 } } },
            { itemID = 239018, name = "Winner's Podium", source = "vendor",
              sourceInfo = "Gamesmaster Fleurin - 200 Illusionary Coins (Decor Duels)",
              waypoint = LOC.GamesmasterFleurin, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.IllusionaryCoin, 200 } } },
            -- Abyss Anglers (Depthdiver Tu'nakit)
            { itemID = 265749, name = "Idol of the Depths", source = "vendor",
              sourceInfo = "Depthdiver Tu'nakit - 1500 Angler Pearls (after meta-achievement)",
              waypoint = LOC.DepthdiverTunakit, zone = "Zul'Aman",
              cost = { currency = { MC.CURRENCY.AnglerPearls, 1500 } },
              achievementID = 62217 },
            -- Delves (Telemancer Astrandis / Naleidea Rivergleam)
            { itemID = 264414, name = "Midnight Delver's Flare Gun", source = "vendor",
              sourceInfo = "Telemancer Astrandis - 10 Voidlight Marl, Delver's Journey Rank 7",
              zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 10 } } },
            { itemID = 265100, name = "Corewarden's Hearthstone", source = "vendor",
              sourceInfo = "Naleidea Rivergleam - 10 Voidlight Marl, Delver's Journey Rank 10",
              waypoint = LOC.NaleideaRivergleam, zone = "Silvermoon City",
              cost = { currency = { MC.CURRENCY.VoidlightMarl, 10 } } },
            -- Twilight Ascension (pre-patch event, Resonance Crystals 3008)
            { itemID = 249468, name = "Twilight's Blade Top Secret Strategy Training Guide", source = "vendor",
              sourceInfo = "Materialist Ophinell - 30 Resonance Crystals (pre-patch event)",
              cost = { currency = { MC.CURRENCY.ResonanceCrystals, 30 } } },
        },
    },

    -- Profession-crafted toys
    {
        source = "profession",
        toys = {
            { itemID = 248485, name = "Wormhole Generator: Quel'Thalas", source = "profession",
              sourceInfo = "Engineering craft (teleports to a random Midnight location, 30min CD)" },
        },
    },

    -- World event toys (seasonal events with Midnight-era additions)
    {
        source = "worldevent",
        toys = {
            { itemID = 272287, name = "Nap Mat", source = "worldevent",
              sourceInfo = "Children's Week 2026 vendor reward (Well-loved Figurine token)" },
        },
    },
}
