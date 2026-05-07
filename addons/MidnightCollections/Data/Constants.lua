local _, MC = ...

-- Major faction IDs. Used by C_MajorFactions.GetMajorFactionData.
MC.FACTION = {
    AmaniTribe      = 2696,
    Singularity     = 2699,
    Harati          = 2704,
    SilvermoonCourt = 2710,
    SlayersDuellum  = 2770,
    RitualSites     = 2792,  -- 12.0.5
}

-- Currency IDs. Used by C_CurrencyInfo.GetCurrencyInfo and cost = { ... } blocks.
MC.CURRENCY = {
    Honor              = 1792,
    Undercoin          = 2803,
    ResonanceCrystals  = 3008,  -- pre-patch
    -- Per-profession Artisan's Moxie variants
    AlchemyMoxie       = 3256,
    BlacksmithingMoxie = 3257,
    EnchantingMoxie    = 3258,
    EngineeringMoxie   = 3259,
    InscriptionMoxie   = 3261,
    JewelcraftingMoxie = 3262,
    LeatherworkingMoxie= 3263,
    TailoringMoxie     = 3266,
    -- Midnight world currencies
    VoidlightMarl      = 3316,
    AnglerPearls       = 3373,  -- 12.0.5 Abyss Anglers
    BrimmingArcana     = 3379,
    RemnantOfAnguish   = 3392,
    IllusionaryCoin    = 3393,  -- 12.0.5 Decor Duels
}

-- Profession skill line IDs.
MC.PROFESSION = {
    Alchemy        = 171,
    Blacksmithing  = 164,
    Cooking        = 185,
    Enchanting     = 333,
    Engineering    = 202,
    Inscription    = 773,
    Jewelcrafting  = 755,
    Leatherworking = 165,
    Tailoring      = 197,
}

-- Display order (alphabetical) for the Recipes tab.
MC.PROFESSION_ORDER = {
    MC.PROFESSION.Alchemy,
    MC.PROFESSION.Blacksmithing,
    MC.PROFESSION.Cooking,
    MC.PROFESSION.Enchanting,
    MC.PROFESSION.Engineering,
    MC.PROFESSION.Inscription,
    MC.PROFESSION.Jewelcrafting,
    MC.PROFESSION.Leatherworking,
    MC.PROFESSION.Tailoring,
}

MC.PROFESSION_LABELS = {
    [MC.PROFESSION.Alchemy]        = "Alchemy",
    [MC.PROFESSION.Blacksmithing]  = "Blacksmithing",
    [MC.PROFESSION.Cooking]        = "Cooking",
    [MC.PROFESSION.Enchanting]     = "Enchanting",
    [MC.PROFESSION.Engineering]    = "Engineering",
    [MC.PROFESSION.Inscription]    = "Inscription",
    [MC.PROFESSION.Jewelcrafting]  = "Jewelcrafting",
    [MC.PROFESSION.Leatherworking] = "Leatherworking",
    [MC.PROFESSION.Tailoring]      = "Tailoring",
}

-- uiMapIDs for Midnight zones.
MC.MAP = {
    Silvermoon       = 2393,
    Eversong         = 2395,
    Voidstorm        = 2405,
    Harandar         = 2413,
    IsleOfQuelDanas  = 2424,
    ZulAman          = 2437,
    -- 12.0.5 Ritual Sites are instanced and have their own mapIDs.
    BrokenThrone     = 2585,
    DaggerspinePoint = 2594,
}

-- MC.PORTALS is defined at the bottom of Data/Locations.lua (it needs MC.LOC).
