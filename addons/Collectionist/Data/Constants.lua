local _, MC = ...

-- Time-gated content stays visible for planning, but scanners exclude it
-- from obtainable totals and Collection Score until the regional unlock.
-- Region IDs follow GetCurrentRegion: US/OCE 1, KR 2, EU 3, TW 4, CN 5.
MC.CONTENT_RELEASE = {
    MIDNIGHT_SEASON_2 = {
        default = 1787065200, -- Americas: 2026-08-18 15:00 UTC
        [1] = 1787065200,
        [2] = 1787187600,    -- Korea:   2026-08-20 01:00 UTC
        [3] = 1787112000,    -- Europe:  2026-08-19 04:00 UTC
        [4] = 1787187600,    -- Taiwan:  2026-08-20 01:00 UTC
        [5] = 1787187600,    -- China:   Thursday regional reset
        [50] = 0,            -- PTR / test realms already expose test content
        [57] = 0,
        labels = {
            default = "August 18, 2026",
            [1] = "August 18, 2026",
            [2] = "August 20, 2026",
            [3] = "August 19, 2026",
            [4] = "August 20, 2026",
            [5] = "August 20, 2026",
            [50] = "Available on test realms",
            [57] = "Available on test realms",
        },
        badges = {
            default = "Aug 18",
            [1] = "Aug 18",
            [2] = "Aug 20",
            [3] = "Aug 19",
            [4] = "Aug 20",
            [5] = "Aug 20",
            [50] = "PTR",
            [57] = "PTR",
        },
    },
}

function MC.GetPlayerRegion()
    if C_BattleNet and C_BattleNet.GetGameAccountInfoByGUID and UnitGUID then
        local ok, account = pcall(C_BattleNet.GetGameAccountInfoByGUID, UnitGUID("player"))
        if ok and account and account.regionID then return account.regionID end
    end
    if GetCurrentRegion then
        local ok, region = pcall(GetCurrentRegion)
        if ok and region then return region end
    end
    return 1
end

function MC.ResolveContentRelease(release)
    if type(release) == "number" then return release end
    if type(release) ~= "table" then return nil end
    return release[MC.GetPlayerRegion()] or release.default
end

function MC.GetCurrentTimestamp()
    if GetServerTime then
        local ok, timestamp = pcall(GetServerTime)
        if ok and type(timestamp) == "number" and timestamp > 0 then
            return timestamp
        end
    end
    if time then
        local ok, timestamp = pcall(time)
        if ok and type(timestamp) == "number" then return timestamp end
    end
    return 0
end

function MC.IsContentAvailable(entry, now)
    local unlock = MC.ResolveContentRelease(entry and entry.availableAfter)
    return not unlock or (now or MC.GetCurrentTimestamp()) >= unlock
end

function MC.GetAvailabilityLabel(entry)
    local release = entry and entry.availableAfter
    if not release then return nil end
    if type(release) == "table" and release.labels then
        return release.labels[MC.GetPlayerRegion()] or release.labels.default
    end
    return "a future update"
end

function MC.GetAvailabilityBadge(entry)
    local release = entry and entry.availableAfter
    if not release then return nil end
    if type(release) == "table" and release.badges then
        return release.badges[MC.GetPlayerRegion()] or release.badges.default
    end
    return "Soon"
end

function MC.CountObtainableEntries(entries)
    local count = 0
    for _, entry in ipairs(entries or {}) do
        if not entry.future then count = count + 1 end
    end
    return count
end

function MC.HasObtainableEntries(bySource)
    for _, entries in pairs(bySource or {}) do
        if MC.CountObtainableEntries(entries) > 0 then return true end
    end
    return false
end

-- Insert a scan entry into the per-source (and, when given, per-category)
-- buckets, creating sub-tables on demand. Shared by every module scanner.
function MC.BucketEntry(result, source, entry, category)
    if category then
        if not result.byCategory[category] then
            result.byCategory[category] = {}
        end
        if not result.byCategory[category][source] then
            result.byCategory[category][source] = {}
        end
        local bucket = result.byCategory[category][source]
        bucket[#bucket + 1] = entry
    end
    if not result.bySource[source] then result.bySource[source] = {} end
    local bucket = result.bySource[source]
    bucket[#bucket + 1] = entry
end

-- Factory for the minimap-summary printer each module registers as
-- opts.printSummary. Every module's summary differs only in its verb and
-- source tables; the bracket label comes from the module itself.
function MC.MakeSourceSummary(verb, orderTable, labelsTable)
    local headerNoun = (verb == "collected") and "Uncollected" or "Remaining"
    local perSource  = (verb == "collected") and "uncollected" or "remaining"
    return function(m)
        local r = m.Scanner and m.Scanner.results
        if not (r and r.totalAll) then return end
        print(format("%s [%s] %d / %d %s (%d remaining)",
            MC.PREFIX, m.label, r.collectedCountAll or 0, r.totalAll,
            verb, r.totalAll - (r.collectedCountAll or 0)))
        -- bySource is filter-scoped (it feeds the tab's waypoint
        -- lists), so say which slice the breakdown covers.
        if MC.HasObtainableEntries(r.bySource) then
            print(format("  %s by source (%s):", headerNoun, MC.GetFilterScopeLabel()))
        end
        for _, srcType in ipairs(orderTable) do
            local count = MC.CountObtainableEntries(r.bySource[srcType])
            if count > 0 then
                print(format("  %s: %d %s", labelsTable[srcType] or srcType, count, perSource))
            end
        end
    end
end

-- Major faction IDs. Used by C_MajorFactions.GetMajorFactionData.
MC.FACTION = {
    -- The War Within (tww) renown factions.
    CouncilOfDornogal   = 2590,
    AssemblyOfTheDeeps  = 2594,
    HallowfallArathi    = 2570,
    SeveredThreads      = 2600,
    CartelsOfUndermine  = 2653,  -- 11.1 Undermine
    GallagioLoyaltyClub = 2685,  -- 11.1 raid renown
    FlamesRadiance      = 2688,  -- 11.1.5
    KareshTrust         = 2658,  -- 11.2 K'aresh
    ManaforgeVandals    = 2736,  -- 11.2 raid renown
    -- Midnight factions.
    AmaniTribe      = 2696,
    Singularity     = 2699,
    Harati          = 2704,
    SilvermoonCourt = 2710,
    SlayersDuellum  = 2770,
    RitualSites     = 2792,  -- 12.0.5
    ZuljarrasForces = 2772,  -- 12.1 Coiled Isle renown
    CaptainTokka    = 2773,  -- 12.1 Cursed Fishing friendship
}

-- Currency IDs. Used by C_CurrencyInfo.GetCurrencyInfo and cost = { ... } blocks.
MC.CURRENCY = {
    Honor              = 1792,
    Undercoin          = 2803,
    -- The War Within (tww) world currencies used by collectible vendors.
    ResonanceCrystals  = 2815,
    Valorstones        = 3008,
    Kej                = 3056,
    ResidualMemories   = 3089,  -- 11.0.7 Siren Isle
    FlameBlessedIron   = 3090,  -- 11.0.7 Siren Isle
    UntetheredCoin     = 3303,  -- 11.2 K'aresh
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
    TimewarpedBadges   = 1166,
    CommunityCoupons   = 3363,
    CorrosiveCoin      = 3448,
    CoiledFilament     = 3546,
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

-- uiMapIDs for tracked zones (The War Within + Midnight).
MC.MAP = {
    -- The War Within (tww): Khaz Algar zones.
    KhazAlgar        = 2274,  -- continent map
    IsleOfDorn       = 2248,
    Dornogal         = 2339,  -- capital; sub-map of Isle of Dorn
    RingingDeeps     = 2214,
    Hallowfall       = 2215,
    AzjKahet         = 2255,
    SirenIsle        = 2369,  -- 11.0.7
    Undermine        = 2346,  -- 11.1
    Karesh           = 2371,  -- 11.2 K'aresh
    Tazavesh         = 2472,  -- 11.2 hub city; sub-map of K'aresh
    -- Midnight zones.
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
    -- Patch 12.0.7 Showdown worlds.
    Val              = 2599,
    Naigtal          = 2600,
    NaigtalCrypt     = 2646,
    -- Patch 12.1: Curse of Ula'tek.
    CoiledIsle       = 2512,
    VaultsOfAtalUtek = 2509,
    VaultsDepths     = 2613,
}

-- Sub-map -> parent overworld map. The smart-waypoint resolver rolls
-- sub-maps up to their parent for portal routing and "are we already
-- in the target zone?" checks. Without this, clicking a SlayersRise
-- rare from Silvermoon falls past portal lookup and ports you straight
-- to a coord that's only valid once you're in Voidstorm.
MC.MAP_PARENT = {
    -- The War Within (tww). MC.PORTALS has no Khaz Algar routing, so for
    -- TWW these only affect the "already in the target zone?" rollup;
    -- waypoints otherwise resolve directly (every zone is flyable).
    [2339] = 2248,  -- Dornogal           -> Isle of Dorn
    [2346] = 2214,  -- Undermine          -> The Ringing Deeps
    [2472] = 2371,  -- Tazavesh           -> K'aresh
    -- Midnight.
    [2576] = 2413,  -- The Den            -> Harandar
    [2444] = 2405,  -- Slayer's Rise      -> Voidstorm
    [2585] = 2437,  -- Broken Throne      -> Zul'Aman
    [2594] = 2395,  -- Daggerspine Point  -> Eversong Woods
    [2646] = 2600,  -- Naigtal Crypt      -> Naigtal
    [2617] = 2599,  -- Val interiors      -> Val
    [2618] = 2599,
    [2619] = 2599,
    [2620] = 2599,
    [2621] = 2599,
    [2509] = 2512,  -- Vaults of Atal'Utek -> Coiled Isle
    [2613] = 2509,  -- Vaults interiors     -> Vaults of Atal'Utek
    [2636] = 2509,
    [2637] = 2509,
    [2638] = 2509,
    [2639] = 2512,  -- Coiled Isle interiors -> Coiled Isle
    [2640] = 2512,
    [2641] = 2512,
    [2642] = 2512,
    [2644] = 2512,
}

-- MC.PORTALS is defined at the bottom of Data/Locations.lua (it needs MC.LOC).

----------------------------------------------------------------------
-- Collection Score weights. Each collected item contributes its
-- weight to the player's CS, computed in each module's Scanner.
--
-- Per-item override: set `score = N` on the entry in the data file.
-- Otherwise the source-default below applies; otherwise SCORE_DEFAULT.
--
-- Tiers:
--   1   Trivial    — walk-up loot, easy vendor purchases
--   5   Short      — single rare, multi-step treasure, raid drop, quest reward
--   10  Medium     — vistas/glyphs/lore achievement criteria, heroic raid trophy
--   25  Long       — dungeon, reputation, prey, ritual sites, mythic raid trophy
--   50  Epic       — raid mount, pvp mount, prepatch, meta achievement
--   100 Legendary  — grand metas, ultra-rare, multi-year aspirational
----------------------------------------------------------------------
MC.SCORE_TIERS = {
    trivial    = 1,    -- walk-up loot, vendor purchase
    short      = 5,    -- single rare, multi-step treasure, raid drop, quest reward
    medium     = 10,   -- vistas/glyphs/lore/etc. achievement criteria, heroic raid trophy
    long       = 25,   -- dungeon, reputation, prey, ritual_sites, mythic raid trophy
    epic       = 50,   -- raid mount, pvp mount, prepatch, meta achievement
    legendary  = 100,  -- grand metas, multi-year aspirational
}
local T = MC.SCORE_TIERS

MC.DEFAULT_SCORE_BY_SOURCE = {
    vendor          = T.trivial,

    renown          = T.short,
    quest           = T.short,
    worldevent      = T.short,
    profession      = T.short,
    delve           = T.short,
    -- Per-zone source keys used by Treasures and Rares modules. A single
    -- rare kill or treasure pickup is closer to a quest/renown reward
    -- than to a multi-week rep grind.
    eversong        = T.short,
    zulaman         = T.short,
    harandar        = T.short,
    voidstorm       = T.short,
    val             = T.short,
    naigtal         = T.short,
    coiled_isle     = T.short,

    -- Achievement criteria (vistas, glyphs, lore, paintings) — quick
    -- clicks once you know the location.
    explore         = T.medium,
    vistas          = T.medium,
    glyphs          = T.medium,
    lore            = T.medium,
    paintings       = T.medium,
    events          = T.medium,
    zone            = T.medium,
    pets            = T.medium,
    mounts          = T.medium,
    toys            = T.medium,

    drop            = T.long,
    achievement     = T.long,
    prey            = T.long,
    ritual_sites    = T.long,
    showdowns       = T.long,
    void_assaults   = T.long,
    dungeon         = T.long,
    delves          = T.long,
    dungeons        = T.long,
    housing         = T.medium,
    professions     = T.medium,
    reputation      = T.long,

    raid            = T.epic,
    pvp             = T.epic,
    prepatch        = T.epic,
    metas           = T.epic,
    season          = T.epic,
}

MC.SCORE_DEFAULT = T.short

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

-- Fold one scanned entry into a scanner's account-wide tallies. Shared by
-- every module's Scan() so the totalAll / collectedCountAll / score /
-- legacyCount / byExpansion bookkeeping lives in one place. Callers
-- resolve the item's weight, expansion key, legacy (unavailable) flag,
-- and current release state first. Future content remains renderable but
-- does not enter completion denominators or Collection Score.
function MC.AccumulateScanEntry(result, collected, weight, expansion, legacy, available)
    if available == false then
        result.futureCount = (result.futureCount or 0) + 1
        return false
    end
    result.totalAll = result.totalAll + 1
    if collected then
        result.collectedCountAll = result.collectedCountAll + 1
        if legacy then
            result.legacyCount = result.legacyCount + 1
        else
            result.score = result.score + (weight or 0)
        end
    end
    expansion = expansion or "_unknown"
    local b = result.byExpansion[expansion]
    if not b then
        b = { total = 0, collected = 0 }
        result.byExpansion[expansion] = b
    end
    b.total = b.total + 1
    if collected then b.collected = b.collected + 1 end
    return true
end
