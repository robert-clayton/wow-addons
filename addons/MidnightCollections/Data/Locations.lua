local _, MC = ...

-- Waypoint table: { mapID, x, y, "Display Name" }. mapIDs come from MC.MAP.

MC.LOC = {
    -- Vendor NPCs (shared across modules)
    CaerisFairdawn     = { MC.MAP.Eversong, 0.435, 0.474, "Caeris Fairdawn, Saltheril's Haven" },
    Magovu             = { MC.MAP.ZulAman, 0.460, 0.659, "Magovu, Zul'Aman" },
    Naynar             = { MC.MAP.Harandar, 0.510, 0.508, "Naynar, Harandar" },
    Anomander          = { MC.MAP.Voidstorm, 0.526, 0.729, "Void Researcher Anomander, Voidstorm" },
    Thraxadar          = { MC.MAP.Voidstorm, 0.393, 0.811, "Thraxadar, Slayer's Rise" },
    NaleideaRivergleam = { MC.MAP.Silvermoon, 0.526, 0.780, "Naleidea Rivergleam, Silvermoon City" },
    ConstructVanore    = { MC.MAP.Silvermoon, 0.557, 0.657, "Construct V'anore, Silvermoon City" },
    ApprenticeDiell    = { MC.MAP.Eversong, 0.434, 0.474, "Apprentice Diell, Eversong Woods" },
    -- Recipe vendors / trainers
    Lyrendal           = { MC.MAP.Silvermoon, 0.450, 0.554, "Lyrendal, Silvermoon City" },
    Mirvedon           = { MC.MAP.Silvermoon, 0.340, 0.812, "Mirvedon, Silvermoon City" },
    Eriden             = { MC.MAP.Silvermoon, 0.436, 0.514, "Eriden, Silvermoon City" },
    Neriv              = { MC.MAP.Eversong, 0.434, 0.474, "Neriv, Eversong Woods" },
    Camberon           = { MC.MAP.Silvermoon, 0.470, 0.518, "Camberon, Silvermoon City" },
    CamberonsCauldron  = { MC.MAP.Silvermoon, 0.470, 0.520, "Camberon's Cauldron, Silvermoon City" },
    Lyna               = { MC.MAP.Silvermoon, 0.478, 0.534, "Lyna, Silvermoon City" },

    -- 12.0.5 NPCs
    SergeantVornin           = { MC.MAP.Silvermoon, 0.486, 0.506, "Sergeant Vornin, Silvermoon City" },
    GamesmasterFleurin       = { MC.MAP.Silvermoon, 0.316, 0.767, "Gamesmaster Fleurin, Falconwing Square" },
    DisguisedDecorDuelVendor = { MC.MAP.Silvermoon, 0.316, 0.767, "Disguised Decor Duel Vendor, Falconwing Square" },
    TriamDawnsetter          = { MC.MAP.Silvermoon, 0.480, 0.490, "Triam Dawnsetter, Silvermoon City Bazaar" },
    MarenSilverwing          = { MC.MAP.Silvermoon, 0.482, 0.496, "Maren Silverwing, Silvermoon City Bazaar" },
    DepthdiverTunakit        = { MC.MAP.ZulAman, 0.682, 0.200, "Depthdiver Tu'nakit, Zul'Aman" },

    -- Silvermoon City portals to other Midnight zones (used by MC.PORTALS routing)
    SilvermoonHarandarPortal  = { MC.MAP.Silvermoon, 0.367, 0.686, "Portal to Harandar (Gardens of Remembrance)" },
    SilvermoonVoidstormPortal = { MC.MAP.Silvermoon, 0.353, 0.657, "Portal to Voidstorm (above Gardens of Remembrance)" },
    -- Return portals at The Den (Harandar sub-map 2576) and Howling Ridge
    -- (which is part of the Voidstorm map, not a separate sub-zone).
    HarandarSilvermoonPortal  = { MC.MAP.HarandarDen, 0.631, 0.715, "Portal to Silvermoon (The Den)" },
    HarandarVoidstormPortal   = { MC.MAP.HarandarDen, 0.631, 0.715, "Portal to Voidstorm (The Den)" },
    VoidstormSilvermoonPortal = { MC.MAP.Voidstorm, 0.516, 0.703, "Portal to Silvermoon (Howling Ridge)" },
    VoidstormHarandarPortal   = { MC.MAP.Voidstorm, 0.517, 0.704, "Portal to Harandar (Howling Ridge)" },

    -- 12.0.5 Ritual Site Obelisks (overworld entrance).
    DaggerspinePointEntrance = { MC.MAP.Eversong, 0.349, 0.654, "Daggerspine Point Obelisk (Eversong Woods)" },
    BrokenThroneEntrance     = { MC.MAP.ZulAman,  0.297, 0.782, "Broken Throne Obelisk (Zul'Aman)" },

    -- 12.0.5 Ritual Site spawn / interaction points. The mapIDs are
    -- instance-only; these only resolve once the player is inside.
    -- Daggerspine Point (Eversong Woods Ritual Site, mapID 2594)
    SoggyNest          = { MC.MAP.DaggerspinePoint, 0.300, 0.631, "Soggy Nest (Daggerspine Point)" },
    DaggerspineRiverEgg = { MC.MAP.DaggerspinePoint, 0.652, 0.454, "White egg in river (Daggerspine Point)" },
    DaggerspineKelpPiles = { MC.MAP.DaggerspinePoint, 0.660, 0.738, "Washed-Up Kelp pile (one of several, Daggerspine Point)" },
    DaggerspineRustlingBush = { MC.MAP.DaggerspinePoint, 0.664, 0.524, "Rustling Bush (one of several, Daggerspine Point — Tier 4+)" },
    -- Broken Throne (Zul'Aman Ritual Site, mapID 2585)
    LostBearCub        = { MC.MAP.BrokenThrone, 0.558, 0.496, "Lost Bear Cub (Broken Throne)" },
    AmaniWarbearPile   = { MC.MAP.BrokenThrone, 0.557, 0.389, "Angry Amani Warbear bone pile (Broken Throne)" },
    VoidTaintedNest    = { MC.MAP.BrokenThrone, 0.495, 0.779, "Void-Tainted Nest (Broken Throne)" },
    HexEagleRitual     = { MC.MAP.BrokenThrone, 0.506, 0.474, "Hex Eagle ritual circle (Broken Throne)" },

    -- NPCs needing in-game coordinate verification
    -- MothkeeperWewTam    = { 0, 0, 0, "Mothkeeper Wew'tam" },
    -- ChelTheChip         = { 0, 0, 0, "Chel the Chip" },
    -- TelemancerAstrandis = { 0, 0, 0, "Telemancer Astrandis" },
    -- Kuri                = { 0, 0, 0, "Kuri" },

    -- Wild pet spawn centers (from Wowhead spawn maps)
    -- Eversong Woods (mapID 2395)
    AmberTreeflitter   = { MC.MAP.Eversong, 0.508, 0.634, "Amber Treeflitter" },        -- 27 spawns, zone-wide
    VibrantManaling    = { MC.MAP.Eversong, 0.462, 0.546, "Vibrant Manaling" },         -- 27 spawns, zone-wide
    VioletChick        = { MC.MAP.Eversong, 0.500, 0.684, "Violet Chick" },             -- 15 spawns, uncommon
    -- Silvermoon City (mapID 2393)
    SilvermoonBroom    = { MC.MAP.Silvermoon, 0.305, 0.783, "Silvermoon Broom" },         -- 25 spawns, tight patrol loop
    -- Harandar (mapID 2413)
    AzureSporebat      = { MC.MAP.Harandar, 0.618, 0.564, "Azure Sporebat" },           -- 22 spawns, zone-wide
    MudPotadpole       = { MC.MAP.Harandar, 0.703, 0.310, "Mud Potadpole" },            -- 9 spawns, Nordrassil Roots
    RootlingNester     = { MC.MAP.Harandar, 0.535, 0.517, "Rootling Nester" },          -- 10 spawns, scattered
    Silkcrawler        = { MC.MAP.Harandar, 0.466, 0.444, "Silkcrawler" },              -- 31 spawns, zone-wide
    Waddles            = { MC.MAP.Harandar, 0.609, 0.192, "Waddles" },                  -- 9 spawns, waterfall area
    -- Voidstorm (mapID 2405)
    Blistercreepling   = { MC.MAP.Voidstorm, 0.486, 0.765, "Blistercreepling" },         -- 24 spawns, zone-wide
    DevouringRunt      = { MC.MAP.Voidstorm, 0.430, 0.530, "Devouring Runt" },           -- 26 spawns, zone-wide
    RiftbladeFamiliar  = { MC.MAP.Voidstorm, 0.623, 0.733, "Riftblade Familiar" },       -- 8 spawns, near Obscurian Citadel
    Voidcrawler        = { MC.MAP.Voidstorm, 0.434, 0.660, "Voidcrawler" },              -- 27 spawns, zone-wide
    -- Zul'Aman (mapID 2437)
    AkilFledgling      = { MC.MAP.ZulAman, 0.517, 0.783, "Akil Fledgling" },           -- 10 spawns, SE mountain area
    DragonhawkMosswing = { MC.MAP.ZulAman, 0.509, 0.234, "Dragonhawk Mosswing" },      -- 14 spawns, northern islands
    EbonSnapling       = { MC.MAP.ZulAman, 0.392, 0.511, "Ebon Snapling" },            -- 7 spawns in ZA centre
    GloomToad          = { MC.MAP.ZulAman, 0.365, 0.649, "Gloom Toad" },               -- 24 spawns, near water
    Pangolil           = { MC.MAP.ZulAman, 0.440, 0.542, "Pangolil" },                 -- 4 spawns, bridge patrol
    StripedSnakebiter  = { MC.MAP.ZulAman, 0.472, 0.545, "Striped Snakebiter" },       -- 20 spawns, common
    SwampBiter         = { MC.MAP.ZulAman, 0.447, 0.606, "Swamp Biter" },              -- 18 spawns, zone-wide
    -- Isle of Quel'Danas (mapID 2424)
    NetherFamiliar     = { MC.MAP.IsleOfQuelDanas, 0.424, 0.282, "Nether Familiar" },          -- 43 spawns, northern area
    WrathfulWyrm       = { MC.MAP.IsleOfQuelDanas, 0.436, 0.290, "Wrathful Wyrm" },            -- 25 spawns, Sunwell bridge path

    -- Treasure locations
    -- Pet treasures
    BurblingPaintPot   = { MC.MAP.Eversong, 0.487, 0.754, "Burbling Paint Pot, Eversong Woods" },
    RookeryCache       = { MC.MAP.Silvermoon, 0.243, 0.693, "Rookery Cache, Silvermoon City" },
    KemetsCauldron     = { MC.MAP.Harandar, 0.556, 0.394, "Kemet's Simmering Cauldron, Harandar" },
    SealedGourd        = { MC.MAP.Harandar, 0.267, 0.676, "Impenetrably Sealed Gourd, Harandar" },
    AbandonedNest      = { MC.MAP.ZulAman, 0.426, 0.524, "Abandoned Nest, Zul'Aman" },
    QuiveringEgg       = { MC.MAP.Voidstorm, 0.315, 0.445, "Quivering Egg, Voidstorm" },
    HalfDigestedVisc   = { MC.MAP.Voidstorm, 0.380, 0.688, "Half-Digested Viscera, Voidstorm" },
    -- Mount treasures
    HonoredWarriorsCache = { MC.MAP.ZulAman, 0.468, 0.819, "Honored Warrior's Cache, Zul'Aman" },
    AbandonedRitualSkull = { MC.MAP.ZulAman, 0.447, 0.441, "Abandoned Ritual Skull, Zul'Aman" },
    PeculiarCauldron     = { MC.MAP.Harandar, 0.406, 0.280, "Peculiar Cauldron, Harandar" },
    SporespawnedCache    = { MC.MAP.Harandar, 0.467, 0.678, "Sporespawned Cache, Harandar" },
    FinalClutchPredaxas  = { MC.MAP.Voidstorm, 0.489, 0.783, "Final Clutch of Predaxas, Voidstorm" },

    -- Drop mob locations
    DameBloodshed      = { MC.MAP.Eversong, 0.453, 0.387, "Dame Bloodshed, Eversong Woods" },
    StormarionAssault  = { MC.MAP.Voidstorm, 0.264, 0.676, "Stormarion Assault, Voidstorm" },

    -- Quest chain start NPCs
    Neytar             = { MC.MAP.Harandar, 0.696, 0.506, "Ney'tar, Harandar" },                     -- chain start: Drift Them Away (92864)
    ZurasharKassameh   = { MC.MAP.Harandar, 0.542, 0.530, "Zur'ashar Kassameh, Harandar" },          -- chain start: The Listener (90733)
    Chana              = { MC.MAP.ZulAman, 0.454, 0.697, "Chana, Zul'Aman" },                       -- chain start: The Path of Mourning (89565)
    ShiningSpan        = { MC.MAP.Silvermoon, 0.482, 0.066, "Shining Span, Silvermoon" },               -- campaign scenario location
    Ravenia            = { MC.MAP.Voidstorm, 0.520, 0.674, "Ravenia, Voidstorm" },                    -- chain start: Harvest of Darkness (91363)
    VaelithSunplume    = { MC.MAP.Eversong, 0.568, 0.356, "Vaelith Sunplume, Eversong Woods" },      -- chain start: One Adventurous Hatchling (89383)
    Hannan             = { MC.MAP.Harandar, 0.314, 0.648, "Hannan, Harandar" },                      -- chain start: Light Disturbance (92732)
    InstructorAntheol  = { MC.MAP.Eversong, 0.444, 0.454, "Instructor Antheol, Eversong Woods" },    -- chain start: Second Time's a Choice (94388)
}

-- Portal table read by MC.GetSmartWaypoint.
-- MC.PORTALS[fromMap][toMap] = the portal you'd take. After clicking once and
-- using the portal, the next click resolves to the actual NPC/spawn.
-- Eversong, Zul'Aman, and Isle of Quel'Danas all share Silvermoon's portals
-- since they're contiguous with it.

local LOC = MC.LOC
local SilvermoonPortals = {
    [MC.MAP.Harandar]  = LOC.SilvermoonHarandarPortal,
    [MC.MAP.Voidstorm] = LOC.SilvermoonVoidstormPortal,
}

MC.PORTALS = {
    [MC.MAP.Silvermoon]      = SilvermoonPortals,
    [MC.MAP.Eversong]        = SilvermoonPortals,
    [MC.MAP.ZulAman]         = SilvermoonPortals,
    [MC.MAP.IsleOfQuelDanas] = SilvermoonPortals,

    -- Walking-back-to-Silvermoon zones are reached by taking the
    -- "to Silvermoon" portal first.
    [MC.MAP.Harandar] = {
        [MC.MAP.Silvermoon]      = LOC.HarandarSilvermoonPortal,
        [MC.MAP.Voidstorm]       = LOC.HarandarVoidstormPortal,
        [MC.MAP.Eversong]        = LOC.HarandarSilvermoonPortal,
        [MC.MAP.ZulAman]         = LOC.HarandarSilvermoonPortal,
        [MC.MAP.IsleOfQuelDanas] = LOC.HarandarSilvermoonPortal,
    },
    -- The Den is a sub-map of Harandar; same routing applies so portals work
    -- whether the player is standing in the overworld zone or the hub itself.
    [MC.MAP.HarandarDen] = {
        [MC.MAP.Silvermoon]      = LOC.HarandarSilvermoonPortal,
        [MC.MAP.Voidstorm]       = LOC.HarandarVoidstormPortal,
        [MC.MAP.Eversong]        = LOC.HarandarSilvermoonPortal,
        [MC.MAP.ZulAman]         = LOC.HarandarSilvermoonPortal,
        [MC.MAP.IsleOfQuelDanas] = LOC.HarandarSilvermoonPortal,
    },
    [MC.MAP.Voidstorm] = {
        [MC.MAP.Silvermoon]      = LOC.VoidstormSilvermoonPortal,
        [MC.MAP.Harandar]        = LOC.VoidstormHarandarPortal,
        [MC.MAP.Eversong]        = LOC.VoidstormSilvermoonPortal,
        [MC.MAP.ZulAman]         = LOC.VoidstormSilvermoonPortal,
        [MC.MAP.IsleOfQuelDanas] = LOC.VoidstormSilvermoonPortal,
    },
}
