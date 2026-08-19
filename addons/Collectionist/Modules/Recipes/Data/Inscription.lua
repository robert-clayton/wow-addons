local _, MC = ...
local T = MC.SCORE_TIERS

local LOC = MC.LOC

MC.InscriptionRecipes = {
    {
        name = "Inks & Reagents",
        recipes = {
            { id = 1230017, name = "Munsell Ink",      source = "trainer", sourceInfo = "Trainer (Skill 15)", priority = 1 },
            { id = 1230016, name = "Sienna Ink",       source = "trainer", sourceInfo = "Trainer (Skill 10)", priority = 1 },
            { id = 1230019, name = "Soul Cipher",      source = "trainer", sourceInfo = "Trainer (Skill 20)", priority = 1 },
            { id = 1230018, name = "Codified Azeroot", source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
        },
    },
    {
        name = "Profession Equipment",
        recipes = {
            { id = 1230020, name = "Hobbyist Rolling Pin",              source = "trainer",        sourceInfo = "Trainer (Skill 25)",                    priority = 1 },
            { id = 1230021, name = "Hobbyist Alchemist's Mixing Rod",   source = "trainer",        sourceInfo = "Trainer (Skill 25)",                    priority = 1 },
            { id = 1230022, name = "Hobbyist Scribe's Quill",           source = "trainer",        sourceInfo = "Trainer (Skill 25)",                    priority = 1 },
            { id = 1230023, name = "Sin'dorei Rolling Pin",             source = "specialization", sourceInfo = "Blueprints",                            priority = 3 },
            { id = 1230024, name = "Sin'dorei Alchemist's Mixing Rod",  source = "specialization", sourceInfo = "Blueprints",                            priority = 3 },
            { id = 1230025, name = "Sin'dorei Quill",                   source = "specialization", sourceInfo = "Blueprints (Market Research)",           priority = 3 },
            { id = 1264550, name = "Gilded Alchemist's Mixing Rod",     source = "vendor",         sourceInfo = "Lyrendal (150 Artisan Scribe's Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1264551, name = "Gilded Sin'dorei Rolling Pin",      source = "vendor",         sourceInfo = "Lyrendal (150 Artisan Scribe's Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1264552, name = "Gilded Sin'dorei Quill",            source = "vendor",         sourceInfo = "Lyrendal (150 Artisan Scribe's Moxie)", priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
        },
    },
    {
        name = "Treatises",
        recipes = {
            { id = 1230032, name = "Thalassian Treatise on Inscription",     source = "specialization", sourceInfo = "Calm Hands",                  priority = 3 },
            { id = 1230026, name = "Thalassian Treatise on Blacksmithing",   source = "discovery",      sourceInfo = "Crafting Thalassian Treatises", priority = 2 },
            { id = 1230027, name = "Thalassian Treatise on Mining",          source = "discovery",      sourceInfo = "Crafting Thalassian Treatises", priority = 2 },
            { id = 1230028, name = "Thalassian Treatise on Herbalism",       source = "discovery",      sourceInfo = "Crafting Thalassian Treatises", priority = 2 },
            { id = 1230029, name = "Thalassian Treatise on Jewelcrafting",   source = "discovery",      sourceInfo = "Crafting Thalassian Treatises", priority = 2 },
            { id = 1230030, name = "Thalassian Treatise on Enchanting",      source = "discovery",      sourceInfo = "Crafting Thalassian Treatises", priority = 2 },
            { id = 1230031, name = "Thalassian Treatise on Leatherworking",  source = "discovery",      sourceInfo = "Crafting Thalassian Treatises", priority = 2 },
            { id = 1230033, name = "Thalassian Treatise on Tailoring",       source = "discovery",      sourceInfo = "Crafting Thalassian Treatises", priority = 2 },
            { id = 1230034, name = "Thalassian Treatise on Alchemy",         source = "discovery",      sourceInfo = "Crafting Thalassian Treatises", priority = 2 },
            { id = 1230035, name = "Thalassian Treatise on Skinning",        source = "discovery",      sourceInfo = "Crafting Thalassian Treatises", priority = 2 },
            { id = 1230036, name = "Thalassian Treatise on Engineering",     source = "discovery",      sourceInfo = "Crafting Thalassian Treatises", priority = 2 },
        },
    },
    {
        name = "Combat Missives",
        recipes = {
            { id = 1230042, name = "Thalassian Missive of the Aurora",      source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1230041, name = "Thalassian Missive of the Feverflare",  source = "trainer", sourceInfo = "Trainer (Skill 25)", priority = 1 },
            { id = 1230040, name = "Thalassian Missive of the Fireflash",   source = "trainer", sourceInfo = "Trainer (Skill 35)", priority = 1 },
            { id = 1230039, name = "Thalassian Missive of the Harmonious",  source = "trainer", sourceInfo = "Trainer (Skill 35)", priority = 1 },
            { id = 1230037, name = "Thalassian Missive of the Quickblade",  source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
            { id = 1230038, name = "Thalassian Missive of the Peerless",    source = "trainer", sourceInfo = "Trainer (Skill 45)", priority = 1 },
        },
    },
    {
        name = "Profession Missives",
        recipes = {
            { id = 1230043, name = "Thalassian Missive of Deftness",        source = "vendor", sourceInfo = "Lyrendal (Skill 50)",                    priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1230044, name = "Thalassian Missive of Perception",      source = "vendor", sourceInfo = "Lyrendal (150 Artisan Scribe's Moxie)",  priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1230045, name = "Thalassian Missive of Finesse",         source = "vendor", sourceInfo = "Lyrendal (Skill 50)",                    priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1230046, name = "Thalassian Missive of Crafting Speed",  source = "vendor", sourceInfo = "Lyrendal (Skill 50)",                    priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1230047, name = "Thalassian Missive of Multicraft",      source = "vendor", sourceInfo = "Lyrendal (Skill 50)",                    priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1230048, name = "Thalassian Missive of Resourcefulness", source = "vendor", sourceInfo = "Lyrendal (Skill 50)",                    priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1230049, name = "Thalassian Missive of Ingenuity",       source = "vendor", sourceInfo = "Lyrendal (Skill 50)",                    priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
        },
    },
    {
        name = "Vantus Runes",
        recipes = {
            { id = 1230050, name = "Vantus Rune: Radiant", source = "trainer", sourceInfo = "Trainer (Skill 50)", priority = 1 },
        },
    },
    {
        name = "Contracts",
        recipes = {
            { id = 1230052, name = "Contract: The Amani Tribe",      source = "vendor", sourceInfo = "Magovu (Amani Renown 5)",        priority = 1, waypoint = LOC.Magovu, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1230054, name = "Contract: The Singularity",      source = "vendor", sourceInfo = "Anomander (Singularity Renown 5)", priority = 1, waypoint = LOC.Anomander, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1241690, name = "Contract: The Silvermoon Court",  source = "vendor", sourceInfo = "Caeris Fairdawn (Court Renown 5)", priority = 1, waypoint = LOC.CaerisFairdawn, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1241985, name = "Contract: The Hara'ti",          source = "vendor", sourceInfo = "Naynar (Hara'ti Renown 5)",       priority = 1, waypoint = LOC.Naynar, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
        },
    },
    {
        name = "Weapons",
        recipes = {
            { id = 1230055, name = "Faunatender's Baton",  source = "trainer",        sourceInfo = "Trainer (Skill 20)", priority = 1 },
            { id = 1230056, name = "Floratender's Crutch", source = "trainer",        sourceInfo = "Trainer (Skill 20)", priority = 1 },
            { id = 1230057, name = "Rootwarden's Lamp",    source = "trainer",        sourceInfo = "Trainer (Skill 20)", priority = 1 },
            { id = 1230058, name = "Faunatender's Trust",  source = "trainer",        sourceInfo = "Trainer (Skill 35)", priority = 1 },
            { id = 1230059, name = "Aln'hara Pikestaff",   source = "specialization", sourceInfo = "Blueprints",         priority = 3 },
            { id = 1230060, name = "Aln'hara Cane",        source = "specialization", sourceInfo = "Blueprints",         priority = 3 },
            { id = 1230061, name = "Aln'hara Lantern",     source = "specialization", sourceInfo = "Blueprints",         priority = 3 },
            { id = 1230062, name = "Aln'hara Sprigshot",   source = "specialization", sourceInfo = "Blueprints",         priority = 3 },
        },
    },
    {
        name = "PvP Gear",
        recipes = {
            { id = 1230064, name = "Thalassian Competitor's Lamp",                    source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1230065, name = "Thalassian Competitor's Staff",                   source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1230066, name = "Thalassian Competitor's Pillar",                  source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1230067, name = "Thalassian Competitor's Emblem",                  source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1230068, name = "Thalassian Competitor's Insignia of Alacrity",    source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1230069, name = "Thalassian Competitor's Medallion",               source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
            { id = 1260760, name = "Thalassian Competitor's Bow",                    source = "vendor", sourceInfo = "Mirvedon (7500 Honor)", priority = 1, waypoint = LOC.Mirvedon, cost = { currency = { MC.CURRENCY.Honor, 7500 } } },
        },
    },
    {
        name = "Darkmoon Cards & Sigils",
        recipes = {
            { id = 1230070, name = "Darkmoon Dominion: Blood",  source = "specialization", sourceInfo = "Darkmoon Curiosity",          priority = 3, score = T.medium },
            { id = 1230071, name = "Darkmoon Dominion: Rot",    source = "specialization", sourceInfo = "Darkmoon Curiosity",          priority = 3, score = T.medium },
            { id = 1230072, name = "Darkmoon Dominion: Hunt",   source = "specialization", sourceInfo = "Darkmoon Curiosity",          priority = 3, score = T.medium },
            { id = 1230073, name = "Darkmoon Dominion: Void",   source = "specialization", sourceInfo = "Darkmoon Curiosity",          priority = 3, score = T.medium },
            { id = 1230074, name = "Darkmoon Sigil: Blood",     source = "specialization", sourceInfo = "Darkmoon Curiosity",          priority = 3 },
            { id = 1230075, name = "Darkmoon Sigil: Rot",       source = "specialization", sourceInfo = "Darkmoon Curiosity",          priority = 3 },
            { id = 1230076, name = "Darkmoon Sigil: Hunt",      source = "specialization", sourceInfo = "Darkmoon Curiosity",          priority = 3 },
            { id = 1230077, name = "Darkmoon Sigil: Void",      source = "specialization", sourceInfo = "Darkmoon Curiosity",          priority = 3 },
            { id = 1230078, name = "Transcribe: Void",          source = "specialization", sourceInfo = "Darkmoon Curiosity - Void",   priority = 3 },
            { id = 1230079, name = "Inscribe: Void",            source = "specialization", sourceInfo = "Darkmoon Curiosity - Void",   priority = 3 },
            { id = 1230080, name = "Transcribe: Rot",           source = "specialization", sourceInfo = "Darkmoon Curiosity - Rot",    priority = 3 },
            { id = 1230081, name = "Inscribe: Rot",             source = "specialization", sourceInfo = "Darkmoon Curiosity - Rot",    priority = 3 },
            { id = 1230082, name = "Transcribe: Hunt",          source = "specialization", sourceInfo = "Darkmoon Curiosity - Hunt",   priority = 3 },
            { id = 1230083, name = "Inscribe: Hunt",            source = "specialization", sourceInfo = "Darkmoon Curiosity - Hunt",   priority = 3 },
            { id = 1230084, name = "Transcribe: Blood",         source = "specialization", sourceInfo = "Darkmoon Curiosity - Blood",  priority = 3 },
            { id = 1230085, name = "Inscribe: Blood",           source = "specialization", sourceInfo = "Darkmoon Curiosity - Blood",  priority = 3 },
        },
    },
    {
        name = "Housing Decor",
        recipes = {
            { id = 1248619, name = "Sturdy Ren'dorei Cask",          source = "vendor", sourceInfo = "Construct V'anore, Silvermoon City",      priority = 1, waypoint = LOC.ConstructVanore, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 }, currency2 = { MC.CURRENCY.RemnantOfAnguish, 500 } } },
            { id = 1248621, name = "Floating Void-Touched Tome",     source = "vendor", sourceInfo = "Anomander, Voidstorm",                   priority = 1, waypoint = LOC.Anomander, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1248622, name = "Homely Sin'dorei Shelf",         source = "vendor", sourceInfo = "Lyrendal (150 Artisan Scribe's Moxie)",   priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1248623, name = "Lively Songwriter's Quill",      source = "vendor", sourceInfo = "Lyrendal, Silvermoon City",               priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1248624, name = "Opened Sin'dorei Scroll",        source = "vendor", sourceInfo = "Lyrendal (150 Artisan Scribe's Moxie)",   priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1248625, name = "Gilded Eversong Book",           source = "vendor", sourceInfo = "Lyrendal, Silvermoon City",               priority = 1, waypoint = LOC.Lyrendal, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1248626, name = "Sin'dorei Phoenix Quill",        source = "vendor", sourceInfo = "Ranger Allorn, Saltheril's Haven (Eversong)", priority = 1, waypoint = LOC.RangerAllorn, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1248627, name = "Homely Wall Shelves",            source = "vendor", sourceInfo = "Lyrendal (150 Artisan Scribe's Moxie)",      priority = 1, waypoint = LOC.Lyrendal,     cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 } } },
            { id = 1248628, name = "Wild Hanging Scroll",            source = "vendor", sourceInfo = "Construct V'anore, Silvermoon City",      priority = 1, waypoint = LOC.ConstructVanore, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 }, currency2 = { MC.CURRENCY.RemnantOfAnguish, 500 } } },
            { id = 1248630, name = "Harandar Signpost",              source = "vendor", sourceInfo = "Naynar (150 Artisan Scribe's Moxie)",     priority = 1, waypoint = LOC.Naynar, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1248631, name = "Magnificent Towering Bookcase",  source = "vendor", sourceInfo = "Naynar (150 Artisan Scribe's Moxie)",     priority = 1, waypoint = LOC.Naynar, cost = { currency = { MC.CURRENCY.InscriptionMoxie, 150 }, currency2 = { MC.CURRENCY.VoidlightMarl, 1500 } } },
            { id = 1248620, name = "Restful Bronze Bench",           source = "drop",   sourceInfo = "Victorious Stormarion Pinnacle Cache",     priority = 4, dropInfo = { rate = "~1%" } },
        },
    },
}
