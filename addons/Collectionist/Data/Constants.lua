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
    TwilightsBladeInsignia = 3319,  -- pre-patch event
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
    -- Sub-zone hubs with their own mapIDs (portal rooms live here).
    HarandarDen      = 2576,
    SlayersRise      = 2444,  -- Voidstorm sub-map
}

-- Sub-map -> parent overworld map. The smart-waypoint resolver rolls
-- sub-maps up to their parent for portal routing and "are we already
-- in the target zone?" checks. Without this, clicking a SlayersRise
-- rare from Silvermoon falls past portal lookup and ports you straight
-- to a coord that's only valid once you're in Voidstorm.
MC.MAP_PARENT = {
    [2576] = 2413,  -- The Den            -> Harandar
    [2444] = 2405,  -- Slayer's Rise      -> Voidstorm
    [2585] = 2437,  -- Broken Throne      -> Zul'Aman
    [2594] = 2395,  -- Daggerspine Point  -> Eversong Woods
}

-- MC.PORTALS is defined at the bottom of Data/Locations.lua (it needs MC.LOC).

----------------------------------------------------------------------
-- Collection Score weights. Each collected item contributes its
-- weight to the player's CS, computed in each module's Scanner.
--
-- Per-item override: set `score = N` on the entry in the data file.
-- Otherwise the source-default below applies; otherwise SCORE_DEFAULT.
--
-- Tiers (see plan):
--   1   Trivial       — easy vendor purchases
--   5   Standard      — renown, normal raid drops, easy quest rewards
--   25  Long          — exalted-rep grinds, ~5% drops, weekly-locked
--   100 Epic          — <1% drops, mythic-only, hard solo achievements
--   500 Legendary     — ultra-rare, retired-but-collected, multi-year
----------------------------------------------------------------------
MC.SCORE_TIERS = {
    trivial    = 1,
    standard   = 5,
    long       = 25,
    epic       = 100,
    legendary  = 500,
}

MC.DEFAULT_SCORE_BY_SOURCE = {
    -- Trivial
    vendor          = 1,
    -- Standard
    renown          = 5,
    quest           = 5,
    worldevent      = 5,
    profession      = 5,
    delve           = 5,
    -- Long
    drop            = 25,
    achievement     = 25,
    prey            = 25,
    ritual_sites    = 25,
    void_assaults   = 25,
    dungeon         = 25,
    reputation      = 25,
    -- Per-zone source keys used by Treasures and Rares modules.
    eversong        = 25,
    zulaman         = 25,
    harandar        = 25,
    voidstorm       = 25,
    -- Epic
    raid            = 100,
    pvp             = 100,
    prepatch        = 100,
    -- Achievement-tab source keys (most are Long; metas overridden per-item).
    metas           = 100,
    explore         = 25,
    vistas          = 25,
    glyphs          = 25,
    lore            = 25,
    paintings       = 25,
    events          = 25,
    zone            = 25,
    pets            = 25,
    mounts          = 25,
    toys            = 25,
}

MC.SCORE_DEFAULT = 5

-- Returns the integer weight for a collectible entry. Per-item override
-- (`entry.score`) wins; otherwise the source default; otherwise the
-- catch-all default.
function MC.ScoreFor(entry)
    if not entry then return MC.SCORE_DEFAULT end
    if entry.score then return entry.score end
    local d = MC.DEFAULT_SCORE_BY_SOURCE[entry.source]
    if d then return d end
    return MC.SCORE_DEFAULT
end
