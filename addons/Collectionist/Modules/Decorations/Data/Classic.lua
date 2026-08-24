local _, MC = ...

-- Classic-acquisition housing decor. Ownership follows the awarding content, not the Midnight housing row or visual theme.
MC.RegisterContent("vanilla", "decorations", {
    { source = "crafted", decorations = {
        { decorID = 854, itemID = 245502, name = "Brill Coffin", source = "crafted", sourceInfo = "3 Brill Coffin Furnishings › Storage Crafting: Inscription Profession: Classic Inscription (240)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 922, itemID = 245503, name = "Brill Coffin Lid", source = "crafted", sourceInfo = "3 Brill Coffin Lid Furnishings › Storage Crafting: Inscription Profession: Classic Inscription (240)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 1119, itemID = 242948, name = "Loch Modan Bearskin Rug", source = "crafted", sourceInfo = "5 Loch Modan Bearskin Rug Accents › Floor Crafting: Leatherworking Profession: Classic Leatherworking (240)", skillLine = MC.PROFESSION.Leatherworking },
        { decorID = 1282, itemID = 243336, name = "Elder Rise Rug", source = "crafted", sourceInfo = "3 Elder Rise Rug Accents › Floor Crafting: Tailoring Profession: Classic Tailoring (240)", skillLine = MC.PROFESSION.Tailoring },
        { decorID = 2001, itemID = 246111, name = "Shadowforge Sconce", source = "crafted", sourceInfo = "1 Shadowforge Sconce Lighting › Wall Lights Crafting: Blacksmithing Profession: Classic Blacksmithing (240)", skillLine = MC.PROFESSION.Blacksmithing },
        { decorID = 2227, itemID = 246410, name = "Dark Iron Table Saw", source = "crafted", sourceInfo = "3 Dark Iron Table Saw Furnishings › Tables and Desks Crafting: Engineering Profession: Classic Engineering (240)", skillLine = MC.PROFESSION.Engineering },
        { decorID = 2230, itemID = 246413, name = "Blackrock Lamppost", source = "crafted", sourceInfo = "3 Blackrock Lamppost Lighting › Large Lights Crafting: Jewelcrafting Profession: Classic Jewelcrafting (240)", skillLine = MC.PROFESSION.Jewelcrafting },
        { decorID = 2237, itemID = 246420, name = "Kharanos Bookcase", source = "crafted", sourceInfo = "5 Kharanos Bookcase Furnishings › Storage Crafting: Inscription Profession: Classic Inscription (240)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 2240, itemID = 246423, name = "Wooden Ironforge Table", source = "crafted", sourceInfo = "3 Wooden Ironforge Table Furnishings › Tables and Desks Crafting: Inscription Profession: Classic Inscription (240)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 2331, itemID = 246488, name = "Ironforge Chandelier", source = "crafted", sourceInfo = "1 Ironforge Chandelier Lighting › Ceiling Lights Crafting: Jewelcrafting Profession: Classic Jewelcrafting (240)", skillLine = MC.PROFESSION.Jewelcrafting },
        { decorID = 2332, itemID = 246489, name = "Steel Ironforge Emblem", source = "crafted", sourceInfo = "3 Steel Ironforge Emblem Accents › Wall Hangings Crafting: Blacksmithing Profession: Classic Blacksmithing (240)", skillLine = MC.PROFESSION.Blacksmithing },
        { decorID = 2452, itemID = 246685, name = "Dwarven District Banner", source = "crafted", sourceInfo = "5 Dwarven District Banner Accents › Wall Hangings Crafting: Tailoring Profession: Classic Tailoring (240)", skillLine = MC.PROFESSION.Tailoring },
        { decorID = 2465, itemID = 246700, name = "Gnomish Steam-Powered Bed", source = "crafted", sourceInfo = "1 Gnomish Steam-Powered Bed Furnishings › Beds Crafting: Engineering Profession: Classic Engineering (240)", skillLine = MC.PROFESSION.Engineering },
        { decorID = 9266, itemID = 253250, name = "Tirisfal Hollow Campfire", source = "crafted", sourceInfo = "1 Tirisfal Hollow Campfire Lighting › Misc Lighting Crafting: Enchanting Profession: Classic Enchanting (240)", skillLine = MC.PROFESSION.Enchanting },
        { decorID = 11376, itemID = 257041, name = "Stoppered Black Potion", source = "crafted", sourceInfo = "1 Stoppered Black Potion Accents › Ornamental Crafting: Alchemy Profession: Classic Alchemy (240)", skillLine = MC.PROFESSION.Alchemy },
        { decorID = 11438, itemID = 257100, name = "Apothecary's Worktable", source = "crafted", sourceInfo = "3 Apothecary's Worktable Furnishings › Tables and Desks Crafting: Alchemy Profession: Classic Alchemy (240)", skillLine = MC.PROFESSION.Alchemy },
        { decorID = 11755, itemID = 257725, name = "Camp Narache Rug", source = "crafted", sourceInfo = "1 Camp Narache Rug Accents › Floor Crafting: Leatherworking Profession: Classic Leatherworking (240)", skillLine = MC.PROFESSION.Leatherworking },
        { decorID = 11935, itemID = 258289, name = "Thunder Bluff Totem", source = "crafted", sourceInfo = "1 Thunder Bluff Totem Structural › Misc Structural Crafting: Inscription Profession: Classic Inscription (240)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 14816, itemID = 263027, name = "Darkmaster's Mystical Brazier", source = "crafted", sourceInfo = "3 Darkmaster's Mystical Brazier Lighting › Large Lights Crafting: Enchanting Profession: Classic Enchanting (240)", skillLine = MC.PROFESSION.Enchanting },
    } },
    { source = "achievement", decorations = {
        { decorID = 3893, itemID = 247756, name = "Challenger's Dueling Flag", source = "achievement", sourceInfo = "3 Challenger's Dueling Flag Accents › Ornamental Duel-icious Joruh (Orgrimmar) 1000 Honor +1 more source", achievementID = 1157, npcID = 254606, waypoint = { { 84, 0.7780, 0.6570, "Challenger's Dueling Flag" }, { 85, 0.3880, 0.7200, "Challenger's Dueling Flag" } } },
    } },
    { source = "quest", decorations = {
        { decorID = 11274, itemID = 256673, name = "Stormwind Forge", source = "quest", sourceInfo = "5 Stormwind Forge Structural › Misc Structural A Binding Contract Captain Lancy Revshon (Stormwind City) 950", zone = "Stormwind City", questID = 7604, npcID = 49877, waypoint = { 84, 0.6760, 0.7280, "Stormwind Forge" } },
    } },
    { source = "drop", decorations = {
        { decorID = 2246, itemID = 246429, name = "Dark Iron Chandelier", source = "drop", sourceInfo = "1 Dark Iron Chandelier Lighting › Ceiling Lights Encounter: Emperor Dagran Thaurissan (Blackrock Depths)", zone = "Blackrock Mountain", waypoint = { 35, 0.3906, 0.1812, "Dark Iron Chandelier" } },
    } },
})
