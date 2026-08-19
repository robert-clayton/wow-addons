local _, MC = ...

-- The Burning Crusade-acquisition housing decor. Ownership follows the awarding content, not the Midnight housing row or visual theme.
MC.RegisterContent("tbc", "decorations", {
    { source = "crafted", decorations = {
        { decorID = 11370, itemID = 257035, name = "Bronze Banner of the Exiled", source = "crafted", sourceInfo = "3 Bronze Banner of the Exiled Accents › Ornamental Crafting: Blacksmithing Profession: Outland Blacksmithing (60)", skillLine = MC.PROFESSION.Blacksmithing },
        { decorID = 11371, itemID = 257036, name = "Draenei Smith's Anvil", source = "crafted", sourceInfo = "3 Draenei Smith's Anvil Furnishings › Tables and Desks Crafting: Blacksmithing Profession: Outland Blacksmithing (60)", skillLine = MC.PROFESSION.Blacksmithing },
        { decorID = 11372, itemID = 257037, name = "Draenei Holo-Dais", source = "crafted", sourceInfo = "1 Draenei Holo-Dais Accents › Ornamental Crafting: Enchanting Profession: Outland Enchanting (60)", skillLine = MC.PROFESSION.Enchanting },
        { decorID = 11373, itemID = 257038, name = "Draenei Holo-Path", source = "crafted", sourceInfo = "1 Draenei Holo-Path Accents › Ornamental Crafting: Enchanting Profession: Outland Enchanting (60)", skillLine = MC.PROFESSION.Enchanting },
        { decorID = 11374, itemID = 257039, name = "Draenei Crystal Forge", source = "crafted", sourceInfo = "3 Draenei Crystal Forge Accents › Misc Accents Crafting: Blacksmithing Profession: Outland Blacksmithing (60)", skillLine = MC.PROFESSION.Blacksmithing },
        { decorID = 11431, itemID = 257093, name = "Aldor Stellar Console", source = "crafted", sourceInfo = "3 Aldor Stellar Console Miscellaneous › Miscellaneous - All Crafting: Enchanting Profession: Outland Enchanting (60)", skillLine = MC.PROFESSION.Enchanting },
        { decorID = 11878, itemID = 258190, name = "Outland Mag'har Banner", source = "crafted", sourceInfo = "3 Outland Mag'har Banner Accents › Wall Hangings Crafting: Leatherworking Profession: Outland Leatherworking (60)", skillLine = MC.PROFESSION.Leatherworking },
        { decorID = 11879, itemID = 258191, name = "Arakkoa Decoy Scarecrow", source = "crafted", sourceInfo = "3 Arakkoa Decoy Scarecrow Miscellaneous › Miscellaneous - All Crafting: Leatherworking Profession: Outland Leatherworking (60)", skillLine = MC.PROFESSION.Leatherworking },
        { decorID = 11880, itemID = 258192, name = "Talon King's Totem", source = "crafted", sourceInfo = "3 Talon King's Totem Miscellaneous › Miscellaneous - All Crafting: Inscription Profession: Outland Inscription (60)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 11881, itemID = 258193, name = "Draenei Holo-Projector Pedestal", source = "crafted", sourceInfo = "5 Draenei Holo-Projector Pedestal Miscellaneous › Miscellaneous - All Crafting: Engineering Profession: Outland Engineering (60)", skillLine = MC.PROFESSION.Engineering },
        { decorID = 11882, itemID = 258194, name = "Tempest Keep Cryo-Pod", source = "crafted", sourceInfo = "5 Tempest Keep Cryo-Pod Miscellaneous › Miscellaneous - All Crafting: Engineering Profession: Outland Engineering (60)", skillLine = MC.PROFESSION.Engineering },
        { decorID = 11883, itemID = 258195, name = "Draenei Weaver's Loom", source = "crafted", sourceInfo = "3 Draenei Weaver's Loom Furnishings › Misc Furnishings Crafting: Tailoring Profession: Outland Tailoring (60)", skillLine = MC.PROFESSION.Tailoring },
        { decorID = 11884, itemID = 258196, name = "Draenei Transmitter", source = "crafted", sourceInfo = "1 Draenei Transmitter Miscellaneous › Miscellaneous - All Crafting: Engineering Profession: Outland Engineering (60)", skillLine = MC.PROFESSION.Engineering },
        { decorID = 11885, itemID = 258197, name = "Crystal Signpost", source = "crafted", sourceInfo = "3 Crystal Signpost Miscellaneous › Miscellaneous - All Crafting: Inscription Profession: Outland Inscription (60)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 11886, itemID = 258198, name = "Gilded Draenei Round Table", source = "crafted", sourceInfo = "3 Gilded Draenei Round Table Furnishings › Tables and Desks Crafting: Inscription Profession: Outland Inscription (60)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 11887, itemID = 258199, name = "Aldor Bookcase", source = "crafted", sourceInfo = "3 Aldor Bookcase Furnishings › Storage Crafting: Inscription Profession: Outland Inscription (60)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 11888, itemID = 258200, name = "Shattrath Sconce", source = "crafted", sourceInfo = "1 Shattrath Sconce Lighting › Wall Lights Crafting: Jewelcrafting Profession: Outland Jewelcrafting (60)", skillLine = MC.PROFESSION.Jewelcrafting },
        { decorID = 11889, itemID = 258201, name = "Shattrath Lamppost", source = "crafted", sourceInfo = "3 Shattrath Lamppost Lighting › Large Lights Crafting: Jewelcrafting Profession: Outland Jewelcrafting (60)", skillLine = MC.PROFESSION.Jewelcrafting },
        { decorID = 11890, itemID = 258202, name = "Grand Drape of the Exiles", source = "crafted", sourceInfo = "5 Grand Drape of the Exiles Accents › Wall Hangings Crafting: Tailoring Profession: Outland Tailoring (60)", skillLine = MC.PROFESSION.Tailoring },
        { decorID = 11903, itemID = 258215, name = "Halaa Bench", source = "crafted", sourceInfo = "3 Halaa Bench Furnishings › Seating Crafting: Inscription Profession: Outland Inscription (60)", skillLine = MC.PROFESSION.Inscription },
        { decorID = 14553, itemID = 262347, name = "Draenei Crystal Chandelier", source = "crafted", sourceInfo = "1 Draenei Crystal Chandelier Lighting › Ceiling Lights Crafting: Jewelcrafting Profession: Outland Jewelcrafting (60)", skillLine = MC.PROFESSION.Jewelcrafting },
        { decorID = 16082, itemID = 264705, name = "Glazed Sin'dorei Vial", source = "crafted", sourceInfo = "1 Glazed Sin'dorei Vial Accents › Ornamental Crafting: Alchemy Profession: Outland Alchemy (60)", skillLine = MC.PROFESSION.Alchemy },
        { decorID = 16083, itemID = 264706, name = "Shadow Council Torch", source = "crafted", sourceInfo = "3 Shadow Council Torch Lighting › Large Lights Crafting: Alchemy Profession: Outland Alchemy (60)", skillLine = MC.PROFESSION.Alchemy },
        { decorID = 16086, itemID = 264709, name = "Stranglekelp Sack", source = "crafted", sourceInfo = "1 Stranglekelp Sack Nature › Misc Nature Crafting: Alchemy Profession: Outland Alchemy (60)", skillLine = MC.PROFESSION.Alchemy },
        { decorID = 16219, itemID = 264899, name = "Arakkoan Alchemist's Concoction", source = "crafted", sourceInfo = "1 Arakkoan Alchemist's Concoction Accents › Ornamental Crafting: Alchemy Profession: Outland Alchemy (60)", skillLine = MC.PROFESSION.Alchemy },
        { decorID = 16220, itemID = 264900, name = "Arakkoan Alchemist's Bottle", source = "crafted", sourceInfo = "1 Arakkoan Alchemist's Bottle Accents › Ornamental Crafting: Alchemy Profession: Outland Alchemy (60)", skillLine = MC.PROFESSION.Alchemy },
    } },
    { source = "achievement", decorations = {
        { decorID = 3898, itemID = 247761, name = "Uncontested Battlefield Banner", source = "achievement", sourceInfo = "3 Uncontested Battlefield Banner Accents › Ornamental Storm Capper Joruh (Orgrimmar) 400 Honor +1 more source", achievementID = 212, npcID = 254606 },
        { decorID = 3899, itemID = 247762, name = "Netherstorm Battlefield Flag", source = "achievement", sourceInfo = "3 Netherstorm Battlefield Flag Accents › Ornamental Stormtrooper Joruh (Orgrimmar) 300 Honor +1 more source", achievementID = 213, npcID = 254606 },
    } },
    { source = "drop", decorations = {
        { decorID = 15570, itemID = 264332, name = "Amani Ritual Altar", source = "drop", sourceInfo = "3 Amani Ritual Altar Furnishings › Tables and Desks Encounter: Nalorakk" },
    } },
})
