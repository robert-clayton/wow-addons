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

-- How many of these entries a player could still go and complete. Feeds the
-- minimap summary's per-source "remaining" lines and the premium shell's
-- collection spine.
--
-- navigationOnly entries are excluded. They share the same bySource buckets as
-- real collectibles so they render in the tab list, but they have no completion
-- state at all, so counting them told players they had dozens more treasures
-- left in a zone than actually exist -- "The Coiled Isle: 56 remaining" when 22
-- were trackable. The scanners already keep them out of totalAll and score;
-- this is the one counter they reached.
function MC.CountObtainableEntries(entries)
    local count = 0
    for _, entry in ipairs(entries or {}) do
        if not entry.future and not entry.navigationOnly then count = count + 1 end
    end
    return count
end

function MC.HasObtainableEntries(bySource)
    for _, entries in pairs(bySource or {}) do
        if MC.CountObtainableEntries(entries) > 0 then return true end
    end
    return false
end

-- ---------------------------------------------------------------- sorting
--
-- How rows are ordered inside a source group. Rows are already grouped by
-- source, so "sort by source" would be a no-op; what varies inside a group is
-- the curated order the data shipped in, the name, and the expansion.
--
-- Order here is the cycle order of the title-bar control.
MC.SORT_MODES = {
    { key = "default",  label = "Default",      tip = "The order the data ships in" },
    { key = "name_asc", label = "A-Z",          tip = "Name, A to Z" },
    { key = "name_desc", label = "Z-A",         tip = "Name, Z to A" },
    -- Arrows rather than words: "Expansion Ascending" is too long for a
    -- control that has to hold a fixed width next to four other labels.
    { key = "exp_asc",   label = "Expansion ▲", tip = "Expansion, oldest first" },
    { key = "exp_desc", label = "Expansion ▼", tip = "Expansion, newest first" },
}

MC.SORT_MODE_BY_KEY = {}
for i, m in ipairs(MC.SORT_MODES) do
    m.index = i
    MC.SORT_MODE_BY_KEY[m.key] = m
end

-- Per module, so "A-Z" on a 10,000-row recipe list does not also reorder a
-- curated 40-row rare list where the shipped order is the useful one.
function MC.GetSortMode(moduleKey)
    local db = MC.db
    local key = db and db.sortMode and db.sortMode[moduleKey or MC.activeModule]
    return MC.SORT_MODE_BY_KEY[key] and key or "default"
end

function MC.CycleSortMode(moduleKey)
    moduleKey = moduleKey or MC.activeModule
    if not (MC.db and moduleKey) then return "default" end
    MC.db.sortMode = MC.db.sortMode or {}
    local cur = MC.SORT_MODE_BY_KEY[MC.GetSortMode(moduleKey)]
    local nextMode = MC.SORT_MODES[(cur.index % #MC.SORT_MODES) + 1]
    MC.db.sortMode[moduleKey] = nextMode.key
    return nextMode.key
end

local function expansionOrder(entry)
    local e = entry.expansion and MC.EXPANSION_BY_KEY[entry.expansion]
    return e and e.order or -1
end

-- Sorts a bucket IN PLACE. Position inside a bucket carries no meaning beyond
-- display, so there is nothing to preserve by copying first.
--
-- Every comparator falls through to `name` and then to the entry's original
-- index. table.sort is not stable in Lua, so without a total order two rows
-- that compare equal could swap places between renders -- and with a windowed
-- list that repaints on scroll, that shows up as rows visibly jumping.
function MC.SortEntries(entries, moduleKey)
    if type(entries) ~= "table" or #entries < 2 then return entries end
    local mode = MC.GetSortMode(moduleKey)
    if mode == "default" then return entries end

    local pos = {}
    for i = 1, #entries do pos[entries[i]] = i end

    -- The original index is the final tie-break in every mode. table.sort is
    -- not stable in Lua, and with the row list windowed and repainting on
    -- scroll, two rows that compare equal could otherwise swap places
    -- mid-scroll and read as flicker.
    local function byName(a, b, desc)
        local an, bn = a.name or "", b.name or ""
        if an ~= bn then
            if desc then return an > bn end
            return an < bn
        end
        return pos[a] < pos[b]
    end

    if mode == "name_asc" then
        table.sort(entries, function(a, b) return byName(a, b, false) end)
    elseif mode == "name_desc" then
        table.sort(entries, function(a, b) return byName(a, b, true) end)
    elseif mode == "exp_asc" or mode == "exp_desc" then
        local desc = mode == "exp_desc"
        table.sort(entries, function(a, b)
            local ao, bo = expansionOrder(a), expansionOrder(b)
            if ao ~= bo then
                if desc then return ao > bo end
                return ao < bo
            end
            -- Names inside an expansion always read A-Z, in both directions.
            -- Reversing them under a descending expansion sort is surprising:
            -- the player asked for expansion order, not for reversed names.
            return byName(a, b, false)
        end)
    end
    return entries
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

-- Navigation-only rare/treasure groups let source catalogs contribute useful
-- map locations without inventing a durable completion signal. These entries
-- are deliberately bucketed only for display: they never pass through
-- AccumulateScanEntry, never enter completion totals or score, and never join
-- the collected list/roster bitmap.
--
-- Data shape:
--   { navigationOnly = true, source = "zone_key", zone = "Zone", rares = {
--       { npcID = 123, name = "Rare", waypoint = { mapID, x, y } },
--   } }
-- Use `treasures` plus objectID/itemID for treasure groups.
function MC.BucketNavigationGroups(result, groups, moduleKey, listKey, noun)
    for _, group in ipairs(groups or {}) do
        if group.navigationOnly and MC.IsGroupVisible(group, moduleKey) then
            for _, sourceEntry in ipairs(group[listKey] or {}) do
                local entry = {}
                for key, value in pairs(sourceEntry) do entry[key] = value end
                entry.moduleKey = entry.moduleKey or moduleKey
                entry.expansion = entry.expansion or group.expansion
                entry.source = entry.source or group.source or "navigation"
                entry.sourceInfo = entry.sourceInfo or group.sourceInfo
                entry.zone = entry.zone or group.zone
                entry.availableAfter = entry.availableAfter or group.availableAfter
                entry.navigationOnly = true
                entry.collected = nil
                entry.learned = nil

                local available = MC.IsContentAvailable(entry)
                entry.future = not available
                if not entry.sourceInfo and entry.zone then
                    entry.sourceInfo = (noun or "Location") .. " location in " .. entry.zone
                end

                MC.BucketEntry(result, entry.source, entry)
                if available then
                    result.navigationCount = (result.navigationCount or 0) + 1
                else
                    result.navigationFutureCount =
                        (result.navigationFutureCount or 0) + 1
                end
            end
        end
    end
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
    -- Legion reputations, friendship tracks, and collectible-gating factions.
    HighmountainTribe     = 1828,
    Nightfallen           = 1859,
    Dreamweavers          = 1883,
    Wardens               = 1894,
    CourtOfFarondis       = 1900,
    Valarjar               = 1948,
    ConjurerMargoss       = 1975,
    TalonsVengeance       = 2018,
    ArmiesOfLegionfall    = 2045,
    IlyssiaOfTheWaters    = 2097,
    KeeperRaynae          = 2098,
    AkuleRiverhorn        = 2099,
    Corbyn                = 2100,
    Shaleth               = 2101,
    Impus                 = 2102,
    Chromie               = 2135,
    ArmyOfTheLight        = 2165,
    ArgussianReach        = 2170,
    -- Battle for Azeroth reputations and collectible-gating friendships.
    ZandalariEmpire       = 2103,
    TalanjisExpedition    = 2156,
    Honorbound            = 2157,
    Voldunai              = 2158,
    SeventhLegion         = 2159,
    ProudmooreAdmiralty   = 2160,
    OrderOfEmbers         = 2161,
    StormsWake            = 2162,
    TortollanSeekers      = 2163,
    ChampionsOfAzeroth    = 2164,
    Unshackled            = 2373,
    RustboltResistance    = 2391,
    HoneybackHive         = 2395,
    HoneybackDrone        = 2396,
    HoneybackHivemother   = 2397,
    HoneybackHarvester    = 2398,
    WavebladeAnkoan       = 2400,
    Rajani                = 2415,
    UldumAccord           = 2417,
    -- Shadowlands reputations and covenant feature friendships.
    Ascended             = 2407,
    UndyingArmy          = 2410,
    CourtOfHarvesters    = 2413,
    Venari               = 2432,
    Avowed               = 2439,
    EmberCourt           = 2445,
    Marasmius            = 2463,
    CourtOfNight         = 2464,
    WildHunt             = 2465,
    DeathsAdvance        = 2470,
    ArchivistsCodex      = 2472,
    Enlightened          = 2478,
    -- Dragonflight (df) major factions and collectible-gating friendships.
    MaruukCentaur       = 2503,
    DragonscaleExpedition = 2507,
    ValdrakkenAccord    = 2510,
    IskaaraTuskarr      = 2511,
    Wrathion            = 2517,
    Sabellian           = 2518,
    WinterpeltFurbolg   = 2526,
    ArtisansConsortiumDF = 2544,
    CobaltAssembly      = 2550,
    Soridormi           = 2553,
    LoammNiffen         = 2564,
    GlimmeroggRacer     = 2568,
    DreamWardens        = 2574,
    KegLegsCrew         = 2593,
    AzerothianArchives  = 2615,
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
    -- Older recurring currencies referenced by collectible sources.
    ChampionsSeal          = 241,
    TolBaradCommendation   = 391,
    DarkmoonPrizeTicket    = 515,
    TimewarpedBadges       = 1166,
    -- Legion currencies used by collectible and housing acquisition sources.
    SightlessEye           = 1149,
    ShadowyCoins           = 1154,
    AncientMana            = 1155,
    OrderResources         = 1220,
    Nethershard            = 1226,
    CuriousCoin            = 1275,
    BrawlersGold           = 1299,
    LegionfallWarSupplies  = 1342,
    TrialOfStyleToken      = 1379,
    CoinsOfAir             = 1416,
    VeiledArgunite         = 1508,
    -- Battle for Azeroth currencies.
    WarResources           = 1560,
    SeafarersDubloon       = 1710,
    HonorboundServiceMedal = 1716,
    SeventhLegionMedal     = 1717,
    CorruptedMementos      = 1719,
    PrismaticManapearl     = 1721,
    EchoesOfNyalotha       = 1803,
    -- Shadowlands currencies used by collectible sources.
    Phantasma           = 1728,
    ArgentCommendations = 1754,
    Stygia              = 1767,
    ReservoirAnima      = 1813,
    SinstoneFragments   = 1816,
    InfusedRuby         = 1820,
    CatalogedResearch   = 1931,
    CyphersFirstOnes    = 1979,
    -- Dragonflight and acquisition-source currencies used by DF entries.
    DragonIslesSupplies  = 2003,
    ElementalOverflow    = 2118,
    BloodyTokens         = 2123,
    RidersOfAzerothBadge = 2588,
    ParacausalFlakes     = 2594,
    MysteriousFragment   = 2657,
    DreamInfusion        = 2777,
    -- The War Within (tww) world currencies used by collectible vendors.
    ResonanceCrystals  = 2815,
    Valorstones        = 3008,
    Kej                = 3056,
    ResidualMemories   = 3089,  -- 11.0.7 Siren Isle
    FlameBlessedIron   = 3090,  -- 11.0.7 Siren Isle
    UntetheredCoin     = 3303,  -- 11.2 K'aresh
    TwilightsBladeInsignia = 3319,  -- pre-patch event
    LegionRemixBronze  = 3252,  -- 11.2.5 WoW Remix: Legion (event ended)
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

-- uiMapIDs for tracked zones (Classic onward).
MC.MAP = {
    -- Classic.
    Durotar                   = 1,
    Mulgore                   = 7,
    NorthernBarrens           = 10,
    Kalimdor                  = 12,
    EasternKingdoms           = 13,
    ArathiHighlands           = 14,
    Badlands                  = 15,
    BlastedLands              = 17,
    TirisfalGlades            = 18,
    SilverpineForest          = 21,
    WesternPlaguelands        = 22,
    EasternPlaguelands        = 23,
    HillsbradFoothills        = 25,
    Hinterlands               = 26,
    DunMorogh                 = 27,
    SearingGorge              = 32,
    BurningSteppes            = 36,
    ElwynnForest              = 37,
    DeadwindPass              = 42,
    Duskwood                  = 47,
    LochModan                 = 48,
    RedridgeMountains         = 49,
    NorthernStranglethorn     = 50,
    SwampOfSorrows            = 51,
    Westfall                  = 52,
    Wetlands                  = 56,
    Teldrassil                = 57,
    Darkshore                 = 62,
    Ashenvale                 = 63,
    ThousandNeedles           = 64,
    StonetalonMountains       = 65,
    Desolace                  = 66,
    Feralas                   = 69,
    DustwallowMarsh           = 70,
    Tanaris                   = 71,
    Azshara                   = 76,
    Felwood                   = 77,
    UngoroCrater              = 78,
    Moonglade                 = 80,
    Silithus                  = 81,
    Winterspring              = 83,
    StormwindCity             = 84,
    Orgrimmar                 = 85,
    Ironforge                 = 87,
    ThunderBluff              = 88,
    Darnassus                 = 89,
    Undercity                 = 90,
    AlteracValley             = 91,
    WarsongGulch              = 92,
    ArathiBasin               = 93,
    SouthernBarrens           = 199,
    StranglethornVale         = 224,

    -- The Burning Crusade.
    EversongWoods             = 94,
    Ghostlands                = 95,
    AzuremystIsle             = 97,
    HellfirePeninsula         = 100,
    Outland                   = 101,
    Zangarmarsh               = 102,
    Exodar                    = 103,
    ShadowmoonValleyOutland   = 104,
    BladesEdgeMountains       = 105,
    BloodmystIsle             = 106,
    NagrandOutland            = 107,
    TerokkarForest            = 108,
    Netherstorm               = 109,
    SilvermoonCity            = 110,
    ShattrathCity             = 111,
    -- The TBC-era Sunwell island. Midnight re-uses the name for a different
    -- uiMap (2424, further down), so this one is suffixed: an unsuffixed
    -- IsleOfQuelDanas here was silently shadowed by the Midnight entry and
    -- unreachable. Every current consumer wants the Midnight map.
    IsleOfQuelDanasTBC        = 122,

    -- Wrath of the Lich King.
    Northrend                 = 113,
    BoreanTundra              = 114,
    Dragonblight              = 115,
    GrizzlyHills              = 116,
    HowlingFjord              = 117,
    Icecrown                  = 118,
    SholazarBasin             = 119,
    StormPeaks                = 120,
    ZulDrak                   = 121,
    Wintergrasp               = 123,
    DalaranNorthrend          = 125,
    CrystalsongForest         = 127,
    HrothgarsLanding          = 170,

    -- Cataclysm.
    LostIsles                 = 174,
    Gilneas                   = 179,
    Kezan                     = 194,
    MountHyjal                = 198,
    KelpTharForest            = 201,
    GilneasCity               = 202,
    Vashjir                   = 203,
    AbyssalDepths             = 204,
    ShimmeringExpanse         = 205,
    Deepholm                  = 207,
    TwilightHighlands         = 241,
    TolBarad                  = 244,
    TolBaradPeninsula         = 245,
    Uldum                     = 249,
    MoltenFront               = 338,

    -- Mists of Pandaria.
    Pandaria                  = 424,
    JadeForest                = 371,
    ValleyOfTheFourWinds      = 376,
    KunLaiSummit              = 379,
    TownlongSteppes           = 388,
    ValeOfEternalBlossoms     = 390,
    KrasarangWilds            = 418,
    DreadWastes               = 422,
    VeiledStair               = 433,
    IsleOfThunder             = 504,
    IsleOfGiants              = 507,
    TimelessIsle              = 554,

    -- Warlords of Draenor.
    Draenor                  = 572,
    FrostfireRidge           = 525,
    TanaanJungle             = 534,
    Talador                  = 535,
    ShadowmoonValleyDraenor  = 539,
    SpiresOfArak             = 542,
    Gorgrond                 = 543,
    NagrandDraenor           = 550,
    Ashran                   = 588,
    -- Legion.
    DalaranBrokenIsles = 627,
    Azsuna              = 630,
    Stormheim           = 634,
    Valsharah           = 641,
    BrokenShore         = 646,
    Highmountain        = 650,
    Suramar             = 680,
    Krokuun             = 830,
    Eredath             = 882,
    AntoranWastes       = 885,
    Argus               = 905,
    -- Battle for Azeroth.
    Zuldazar            = 862,
    Nazmir              = 863,
    Voldun              = 864,
    TiragardeSound      = 895,
    Drustvar            = 896,
    StormsongValley     = 942,
    Nazjatar            = 1355,
    Mechagon            = 1462,
    UldumAssault        = 1527,
    ValeAssault         = 1530,
    -- Shadowlands.
    Revendreth          = 1525,
    Bastion             = 1533,
    Maldraxxus          = 1536,
    Maw                 = 1543,
    Shadowlands         = 1550,
    Ardenweald          = 1565,
    Korthia             = 1961,
    ZerethMortis        = 1970,
    -- Dragonflight (df): Dragon Isles zones.
    DragonIsles       = 1978,
    WakingShores      = 2022,
    OhnahranPlains    = 2023,
    AzureSpan         = 2024,
    Thaldraszus       = 2025,
    ForbiddenReachDracthyr = 2118,
    ZaralekCavern     = 2133,
    ForbiddenReach   = 2151,
    EmeraldDream     = 2200,
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
