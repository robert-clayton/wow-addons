local _, MC = ...

-- Wrath of the Lich King-acquisition housing decor. Ownership follows the awarding content, not the Midnight housing row or visual theme.
MC.RegisterContent("wrath", "decorations", {
    { source = "crafted", decorations = {
        { decorID = 11375, itemID = 257040, name = "Dalaran Runic Anvil", source = "crafted", sourceInfo = "3 Dalaran Runic Anvil Accents › Ornamental Crafting: Blacksmithing Profession: Northrend Blacksmithing (60)", skillLine = MC.PROFESSION.Blacksmithing },
        { decorID = 11432, itemID = 257094, name = "Mark of the Mages' Eye", source = "crafted", sourceInfo = "1 Mark of the Mages' Eye Lighting › Small Lights Crafting: Enchanting Profession: Northrend Enchanting (60)", skillLine = MC.PROFESSION.Enchanting },
        { decorID = 11439, itemID = 257101, name = "Stampwhistle's Postal Portal", source = "crafted", sourceInfo = "1 Stampwhistle's Postal Portal Functional › Utility Crafting: Enchanting Profession: Northrend Enchanting (60)", skillLine = MC.PROFESSION.Enchanting },
        { decorID = 11722, itemID = 257693, name = "Snowfall Tribe Scare-Totem", source = "crafted", sourceInfo = "3 Snowfall Tribe Scare-Totem Miscellaneous › Miscellaneous - All Crafting: Leatherworking Profession: Northrend Leatherworking (60)", skillLine = MC.PROFESSION.Leatherworking },
        { decorID = 11891, itemID = 258203, name = "Silver Dalaran Bench", source = "crafted", sourceInfo = "3 Silver Dalaran Bench Furnishings › Seating Crafting: Inscription Profession: Northrend Inscription (60)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 11892, itemID = 258204, name = "Dalaran Post", source = "crafted", sourceInfo = "1 Dalaran Post Miscellaneous › Miscellaneous - All Crafting: Inscription Profession: Northrend Inscription (60)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 11893, itemID = 258205, name = "Wolvar Postbag", source = "crafted", sourceInfo = "1 Wolvar Postbag Functional › Utility Crafting: Leatherworking Profession: Northrend Leatherworking (60)", skillLine = MC.PROFESSION.Leatherworking },
        { decorID = 11894, itemID = 258206, name = "Gilded Dalaran Banner", source = "crafted", sourceInfo = "3 Gilded Dalaran Banner Accents › Wall Hangings Crafting: Tailoring Profession: Northrend Tailoring (60)", skillLine = MC.PROFESSION.Tailoring },
        { decorID = 11895, itemID = 258207, name = "Dalaran Scholar's Bookcase", source = "crafted", sourceInfo = "3 Dalaran Scholar's Bookcase Furnishings › Storage Crafting: Inscription Profession: Northrend Inscription (60)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 11896, itemID = 258208, name = "Kirin Tor Sun Chandelier", source = "crafted", sourceInfo = "3 Kirin Tor Sun Chandelier Lighting › Ceiling Lights Crafting: Jewelcrafting Profession: Northrend Jewelcrafting (60)", skillLine = MC.PROFESSION.Jewelcrafting },
        { decorID = 11897, itemID = 258209, name = "Kirin Tor Crate", source = "crafted", sourceInfo = "1 Kirin Tor Crate Furnishings › Storage Crafting: Inscription Profession: Northrend Inscription (60)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 11898, itemID = 258210, name = "Dalaran Street Sign", source = "crafted", sourceInfo = "1 Dalaran Street Sign Accents › Misc Accents Crafting: Inscription Profession: Northrend Inscription (60)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 11899, itemID = 258211, name = "Kirin Tor Glass Table", source = "crafted", sourceInfo = "3 Kirin Tor Glass Table Furnishings › Tables and Desks Crafting: Jewelcrafting Profession: Northrend Jewelcrafting (60)", skillLine = MC.PROFESSION.Jewelcrafting },
        { decorID = 11900, itemID = 258212, name = "San'layn Blood Orb", source = "crafted", sourceInfo = "3 San'layn Blood Orb Accents › Ornamental Crafting: Alchemy Profession: Northrend Alchemy (60)", skillLine = MC.PROFESSION.Alchemy },
        { decorID = 11901, itemID = 258213, name = "Icecrown Plague Canister", source = "crafted", sourceInfo = "5 Icecrown Plague Canister Furnishings › Storage Crafting: Alchemy Profession: Northrend Alchemy (60)", skillLine = MC.PROFESSION.Alchemy },
        { decorID = 11941, itemID = 258298, name = "Kirin Tor Skyline Banner", source = "crafted", sourceInfo = "3 Kirin Tor Skyline Banner Accents › Wall Hangings Crafting: Tailoring Profession: Northrend Tailoring (60)", skillLine = MC.PROFESSION.Tailoring },
        { decorID = 16012, itemID = 264676, name = "Dalaran Sewer Gate", source = "crafted", sourceInfo = "5 Dalaran Sewer Gate Structural › Doors Crafting: Blacksmithing Profession: Northrend Blacksmithing (60)", skillLine = MC.PROFESSION.Blacksmithing },
        { decorID = 16084, itemID = 264707, name = "Resizable All-Purpose Gear", source = "crafted", sourceInfo = "3 Resizable All-Purpose Gear Accents › Wall Hangings Crafting: Engineering Profession: Northrend Engineering (60)", skillLine = MC.PROFESSION.Engineering },
        { decorID = 16085, itemID = 264708, name = "Home Defense Gadget", source = "crafted", sourceInfo = "1 Home Defense Gadget Accents › Wall Hangings Crafting: Engineering Profession: Northrend Engineering (60)", skillLine = MC.PROFESSION.Engineering },
        { decorID = 16087, itemID = 264710, name = "Dalaran Sun Sconce", source = "crafted", sourceInfo = "1 Dalaran Sun Sconce Lighting › Wall Lights Crafting: Blacksmithing Profession: Northrend Blacksmithing (60)", skillLine = MC.PROFESSION.Blacksmithing },
        { decorID = 16088, itemID = 264711, name = "Joybuzz's Joyful Wall of Trains", source = "crafted", sourceInfo = "5 Joybuzz's Joyful Wall of Trains Accents › Wall Hangings Crafting: Engineering Profession: Northrend Engineering (60)", skillLine = MC.PROFESSION.Engineering },
    } },
    { source = "achievement", decorations = {
        { decorID = 1674, itemID = 244852, name = "Head of the Broodmother", source = "achievement", sourceInfo = "3 Head of the Broodmother Accents › Wall Hangings More Dots! (25 player) Axle (Mudsprocket, Dustwallow Marsh) 250", achievementID = 4405, npcID = 23995 },
        { decorID = 4839, itemID = 248807, name = "Nesingwary Mounted Shoveltusk Head", source = "achievement", sourceInfo = "3 Nesingwary Mounted Shoveltusk Head Accents › Wall Hangings The Snows of Northrend Purser Boulian (Sholazar Basin) 500", zone = "Sholazar Basin", achievementID = 938, npcID = 28038 },
    } },
    { source = "quest", decorations = {
        { decorID = 4448, itemID = 248622, name = "Wooden Outhouse", source = "quest", sourceInfo = "5 Wooden Outhouse Structural › Large Structures Doing Your Duty (Grizzly Hills) Woodsman Drake 500", zone = "Grizzly Hills", questID = 12227, npcID = 27391 },
        { decorID = 11872, itemID = 258145, name = "Eversong Party Platter", source = "quest", sourceInfo = "1 Eversong Party Platter Accents › Food and Drink Cheese for Glowergold (Dalaran)", zone = "Dalaran" },
        { decorID = 11906, itemID = 258220, name = "Murloc Driftwood Hut", source = "quest", sourceInfo = "5 Murloc Driftwood Hut Structural › Large Structures Surrender... Not! (Borean Tundra) Ahlurglgr (Borean Tundra)", zone = "Borean Tundra", questID = 11566, npcID = 25206 },
    } },
    { source = "drop", decorations = {
        { decorID = 18483, itemID = 267007, name = "Eye of Acherus", source = "drop", sourceInfo = "5 Eye of Acherus Accents › Ornamental Encounter: Scourgelord Tyrannus (Pit of Saron)", zone = "Icecrown" },
    } },
})
