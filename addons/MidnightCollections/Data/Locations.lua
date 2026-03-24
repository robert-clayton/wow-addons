local _, MC = ...

-- All NPC and location waypoint data: { mapID, x, y, "Display Name" }
-- Midnight uiMapIDs: Silvermoon=2393, Eversong=2395, Zul'Aman=2437,
--                    Harandar=2413, Voidstorm=2405, Isle of Quel'Danas=2424

MC.LOC = {
    ---------------------------------------------------------------------------
    -- Vendor NPCs (shared across modules)
    ---------------------------------------------------------------------------
    CaerisFairdawn     = { 2395, 0.435, 0.474, "Caeris Fairdawn, Saltheril's Haven" },
    Magovu             = { 2437, 0.460, 0.659, "Magovu, Zul'Aman" },
    Naynar             = { 2413, 0.510, 0.508, "Naynar, Harandar" },
    Anomander          = { 2405, 0.526, 0.729, "Void Researcher Anomander, Voidstorm" },
    Thraxadar          = { 2405, 0.393, 0.811, "Thraxadar, Slayer's Rise" },
    NaleideaRivergleam = { 2393, 0.526, 0.780, "Naleidea Rivergleam, Silvermoon City" },
    ConstructVanore    = { 2393, 0.557, 0.657, "Construct V'anore, Silvermoon City" },
    ApprenticeDiell    = { 2395, 0.434, 0.474, "Apprentice Diell, Eversong Woods" },
    Lyrendal           = { 2393, 0.450, 0.554, "Lyrendal, Silvermoon City" },
    Mirvedon           = { 2393, 0.340, 0.812, "Mirvedon, Silvermoon City" },
    Eriden             = { 2393, 0.436, 0.514, "Eriden, Silvermoon City" },
    Neriv              = { 2395, 0.434, 0.474, "Neriv, Eversong Woods" },

    -- NPCs needing in-game coordinate verification
    -- MothkeeperWewTam    = { 0, 0, 0, "Mothkeeper Wew'tam" },
    -- ChelTheChip         = { 0, 0, 0, "Chel the Chip" },
    -- TelemancerAstrandis = { 0, 0, 0, "Telemancer Astrandis" },
    -- Kuri                = { 0, 0, 0, "Kuri" },

    ---------------------------------------------------------------------------
    -- Wild pet spawn coordinates (center of spawn area from Wowhead data)
    ---------------------------------------------------------------------------
    -- Eversong Woods (mapID 2395)
    AmberTreeflitter   = { 2395, 0.508, 0.634, "Amber Treeflitter" },        -- 27 spawns, zone-wide
    VibrantManaling    = { 2395, 0.462, 0.546, "Vibrant Manaling" },         -- 27 spawns, zone-wide
    VioletChick        = { 2395, 0.500, 0.684, "Violet Chick" },             -- 15 spawns, uncommon
    -- Silvermoon City (mapID 2393)
    SilvermoonBroom    = { 2393, 0.305, 0.783, "Silvermoon Broom" },         -- 25 spawns, tight patrol loop
    -- Harandar (mapID 2413)
    AzureSporebat      = { 2413, 0.618, 0.564, "Azure Sporebat" },           -- 22 spawns, zone-wide
    MudPotadpole       = { 2413, 0.703, 0.310, "Mud Potadpole" },            -- 9 spawns, Nordrassil Roots
    RootlingNester     = { 2413, 0.535, 0.517, "Rootling Nester" },          -- 10 spawns, scattered
    Silkcrawler        = { 2413, 0.466, 0.444, "Silkcrawler" },              -- 31 spawns, zone-wide
    Waddles            = { 2413, 0.609, 0.192, "Waddles" },                  -- 9 spawns, waterfall area
    -- Voidstorm (mapID 2405)
    Blistercreepling   = { 2405, 0.486, 0.765, "Blistercreepling" },         -- 24 spawns, zone-wide
    DevouringRunt      = { 2405, 0.430, 0.530, "Devouring Runt" },           -- 26 spawns, zone-wide
    RiftbladeFamiliar  = { 2405, 0.623, 0.733, "Riftblade Familiar" },       -- 8 spawns, near Obscurian Citadel
    Voidcrawler        = { 2405, 0.434, 0.660, "Voidcrawler" },              -- 27 spawns, zone-wide
    -- Zul'Aman (mapID 2437)
    AkilFledgling      = { 2437, 0.517, 0.783, "Akil Fledgling" },           -- 10 spawns, SE mountain area
    DragonhawkMosswing = { 2437, 0.509, 0.234, "Dragonhawk Mosswing" },      -- 14 spawns, northern islands
    EbonSnapling       = { 2437, 0.392, 0.511, "Ebon Snapling" },            -- 7 spawns in ZA centre
    GloomToad          = { 2437, 0.365, 0.649, "Gloom Toad" },               -- 24 spawns, near water
    Pangolil           = { 2437, 0.440, 0.542, "Pangolil" },                 -- 4 spawns, bridge patrol
    StripedSnakebiter  = { 2437, 0.472, 0.545, "Striped Snakebiter" },       -- 20 spawns, common
    SwampBiter         = { 2437, 0.447, 0.606, "Swamp Biter" },              -- 18 spawns, zone-wide
    -- Isle of Quel'Danas (mapID 2424)
    NetherFamiliar     = { 2424, 0.424, 0.282, "Nether Familiar" },          -- 43 spawns, northern area
    WrathfulWyrm       = { 2424, 0.436, 0.290, "Wrathful Wyrm" },            -- 25 spawns, Sunwell bridge path

    ---------------------------------------------------------------------------
    -- Treasure locations
    ---------------------------------------------------------------------------
    -- Pet treasures
    BurblingPaintPot   = { 2395, 0.487, 0.754, "Burbling Paint Pot, Eversong Woods" },
    RookeryCache       = { 2393, 0.243, 0.693, "Rookery Cache, Silvermoon City" },
    KemetsCauldron     = { 2413, 0.556, 0.394, "Kemet's Simmering Cauldron, Harandar" },
    SealedGourd        = { 2413, 0.267, 0.676, "Impenetrably Sealed Gourd, Harandar" },
    AbandonedNest      = { 2437, 0.426, 0.524, "Abandoned Nest, Zul'Aman" },
    QuiveringEgg       = { 2405, 0.315, 0.445, "Quivering Egg, Voidstorm" },
    HalfDigestedVisc   = { 2405, 0.380, 0.688, "Half-Digested Viscera, Voidstorm" },
    -- Mount treasures
    HonoredWarriorsCache = { 2437, 0.468, 0.819, "Honored Warrior's Cache, Zul'Aman" },
    AbandonedRitualSkull = { 2437, 0.447, 0.441, "Abandoned Ritual Skull, Zul'Aman" },
    PeculiarCauldron     = { 2413, 0.406, 0.280, "Peculiar Cauldron, Harandar" },
    SporespawnedCache    = { 2413, 0.467, 0.678, "Sporespawned Cache, Harandar" },
    FinalClutchPredaxas  = { 2405, 0.489, 0.783, "Final Clutch of Predaxas, Voidstorm" },

    ---------------------------------------------------------------------------
    -- Drop mob locations
    ---------------------------------------------------------------------------
    DameBloodshed      = { 2395, 0.453, 0.387, "Dame Bloodshed, Eversong Woods" },
    StormarionAssault  = { 2405, 0.264, 0.676, "Stormarion Assault, Voidstorm" },

    ---------------------------------------------------------------------------
    -- Quest chain start NPCs
    ---------------------------------------------------------------------------
    Neytar             = { 2413, 0.696, 0.506, "Ney'tar, Harandar" },                     -- chain start: Drift Them Away (92864)
    ZurasharKassameh   = { 2413, 0.542, 0.530, "Zur'ashar Kassameh, Harandar" },          -- chain start: The Listener (90733)
    Chana              = { 2437, 0.454, 0.697, "Chana, Zul'Aman" },                       -- chain start: The Path of Mourning (89565)
    ShiningSpan        = { 2393, 0.482, 0.066, "Shining Span, Silvermoon" },               -- campaign scenario location
    Ravenia            = { 2405, 0.520, 0.674, "Ravenia, Voidstorm" },                    -- chain start: Harvest of Darkness (91363)
    VaelithSunplume    = { 2395, 0.568, 0.356, "Vaelith Sunplume, Eversong Woods" },      -- chain start: One Adventurous Hatchling (89383)
    Hannan             = { 2413, 0.314, 0.648, "Hannan, Harandar" },                      -- chain start: Light Disturbance (92732)
    InstructorAntheol  = { 2395, 0.444, 0.454, "Instructor Antheol, Eversong Woods" },    -- chain start: Second Time's a Choice (94388)
}
