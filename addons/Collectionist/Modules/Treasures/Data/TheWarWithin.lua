local ADDON, MC = ...

-- The War Within (11.x) treasure achievements. Criterion order matches
-- CriteriaTree OrderIndex from the final TWW DB2 snapshot (11.2.7.65299),
-- validated against retail 12.1.0.69382 — see
-- research/collectionist/tww/ids/treasures.csv.

MC.RegisterContent("tww", "treasures", {
    { source = "isle_of_dorn", achievementID = 40434, criteriaCount = 12,
      criteriaNames = {
          "Tree's Treasure", "Turtle's Thanks", "Magical Treasure Chest",
          "Mysterious Orb", "Mushroom Cap", "Thak's Treasure",
          "Mosswool Flower", "Kobold Pickaxe", "Jade Pearl",
          "Shimmering Opal Lily", "Infused Cinderbrew", "Web-Wrapped Axe",
      }, name = "Treasures of the Isle of Dorn",
      zoneMapID = MC.MAP.IsleOfDorn, zone = "Isle of Dorn" },
    { source = "ringing_deeps", achievementID = 40724, criteriaCount = 10,
      criteriaNames = {
          "Webbed Knapsack", "Cursed Pickaxe", "Munderut's Forgotten Stash",
          "Discarded Toolbox", "Waterlogged Refuse", "Scary Dark Chest",
          "Kaja'Cola Machine", "Dislodged Blockage",
          "Dusty Prospector's Chest", "Forgotten Treasure",
      }, name = "Treasures of The Ringing Deeps",
      zoneMapID = MC.MAP.RingingDeeps, zone = "The Ringing Deeps" },
    { source = "hallowfall", achievementID = 40848, criteriaCount = 11,
      criteriaNames = {
          "Caesper", "Smuggler's Treasure", "Dark Ritual",
          "Arathi Loremaster", "Illusive Kobyss Lure", "Jewel of the Cliffs",
          "Priory Satchel", "Lost Necklace", "Sky-Captains' Sunken Cache",
          "Illuminated Footlocker", "Spore-covered Coffer",
      }, name = "Treasures of Hallowfall",
      zoneMapID = MC.MAP.Hallowfall, zone = "Hallowfall" },
    { source = "azj_kahet", achievementID = 40828, criteriaCount = 10,
      criteriaNames = {
          "Concealed Contraband", "Memory Cache", "Weaving Supplies",
          "Trapped Trove", "Nest Egg", "Disturbed Soil",
          "Silk-spun Supplies", "Nerubian Offerings", "Niffen Stash",
          "Missing Scout's Pack",
      }, name = "Treasures of Azj-Kahet",
      zoneMapID = MC.MAP.AzjKahet, zone = "Azj-Kahet" },
    -- Single counter criterion: loot 10 Runed Storm Caches (18 known spawn
    -- points around Siren Isle; each needs a Thunderous Runekey and the
    -- "Uncovered Mysteries" quest). No single waypoint is meaningful, so no
    -- coord entry below.
    { source = "siren_isle", achievementID = 41131, criteriaCount = 1,
      criteriaNames = {
          "Runed Storm Caches",
      }, name = "Treasures of the Storm",
      zoneMapID = MC.MAP.SirenIsle, zone = "Siren Isle" },
    { source = "undermine", achievementID = 41217, criteriaCount = 15,
      criteriaNames = {
          "Unexploded Fireworks", "Suspicious Book", "Fireworks Hat",
          "Exploded Plunger", "Blackened Dice", "Lonely Tub",
          "Potent Potable", "Abandoned Toolbox", "Papa's Prized Putter",
          "Unsupervised Takeout", "Particularly Nice Lamp",
          "Uncracked Cold Ones", "Marooned Floatmingo", "Trick Deck of Cards",
          "Crumpled Schematics",
      }, name = "Treasures of Undermine",
      zoneMapID = MC.MAP.Undermine, zone = "Undermine" },
    { source = "karesh", achievementID = 42741, criteriaCount = 27,
      criteriaNames = {
          "Gift of the Brothers", "Ancient Coffer", "Forlorn Wind Chime",
          "Mailroom Distribution", "Ixthar's Favorite Crystal",
          "Wastelander Stash", "Tumbled Package", "Rashaal's Vase",
          "Shattered Crystals", "Skeletal Tail Bones",
          "Crudely Stitched Sack", "Abandoned Lockbox",
          "Lightly-Dented Luggage", "Sand-Worn Coffer",
          "Ethereal Voidforged Container", "Light-Soaked Cleaver",
          "Spear of Fallen Memories", "Efrat's Forgotten Bulwark",
          "Tulwar of the Golden Guard", "Petrified Branch of Janaa",
          "Shadowguard Crusher", "Sufaadi Skiff Lantern",
          "Korgorath's Talon", "Warglaive of the Audacious Hunter",
          "P.O.S.T. Master's Prototype Parcel and Postage Presser",
          "Phaseblade of the Void Marches",
          "Bladed Rifle of Unfettered Momentum",
      }, name = "Treasures of K'aresh",
      zoneMapID = MC.MAP.Karesh, zone = "K'aresh" },
})

----------------------------------------------------------------------------
-- Source keys/labels and per-treasure coords live in tables that
-- Modules/Treasures/Data/Treasures.lua OWNS and assigns fresh — and that
-- file loads AFTER this one (the TOC orders expansion data files
-- chronologically, TWW before the Midnight base file). Merging at file
-- scope would be clobbered, so stage the additions locally and fold them
-- in at ADDON_LOADED, after every file has executed and before the first
-- scan. Each key is guarded so a load-order change (or a base file that
-- learns these keys) stays safe.
----------------------------------------------------------------------------

local TWW_SOURCE_ORDER = {
    "isle_of_dorn", "ringing_deeps", "hallowfall", "azj_kahet",
    "siren_isle", "undermine", "karesh",
}
local TWW_SOURCE_LABELS = {
    isle_of_dorn  = "Isle of Dorn",
    ringing_deeps = "The Ringing Deeps",
    hallowfall    = "Hallowfall",
    azj_kahet     = "Azj-Kahet",
    siren_isle    = "Siren Isle",
    undermine     = "Undermine",
    karesh        = "K'aresh",
}

-- Sub-zone uiMapIDs with no MC.MAP constant (deliberately per-entry only).
local AZJ_KAHET_LOWER  = 2256 -- Azj-Kahet - Lower
local CITY_OF_THREADS  = 2213 -- City of Threads

-- name -> { mapID, x, y, "Label" }
-- Coords sourced from HandyNotes_TheWarWithin (Aug 2026), joined through
-- each node's Achievement criteria ID, deduped to one waypoint per
-- criterion (first listed spawn for multi-spawn treasures).
local TWW_COORDS = {
    -- Isle of Dorn (12)
    ["Tree's Treasure"]            = { MC.MAP.IsleOfDorn, 0.4851, 0.3004, "Tree's Treasure" },
    -- Two-step treasure: feed the Dalaran Sewer Turtle here, then collect
    -- its thanks in Dornogal (58.28, 30.26).
    ["Turtle's Thanks"]            = { MC.MAP.IsleOfDorn, 0.4091, 0.7377, "Turtle's Thanks (start)" },
    ["Magical Treasure Chest"]     = { MC.MAP.IsleOfDorn, 0.4062, 0.5986, "Magical Treasure Chest" },
    ["Mysterious Orb"]             = { MC.MAP.IsleOfDorn, 0.5395, 0.1920, "Mysterious Orb" },
    ["Mushroom Cap"]               = { MC.MAP.IsleOfDorn, 0.5500, 0.6564, "Mushroom Cap" },
    ["Thak's Treasure"]            = { MC.MAP.IsleOfDorn, 0.3807, 0.4358, "Thak's Treasure" },
    ["Mosswool Flower"]            = { MC.MAP.IsleOfDorn, 0.5973, 0.2868, "Mosswool Flower" },
    ["Kobold Pickaxe"]             = { MC.MAP.IsleOfDorn, 0.6257, 0.4327, "Kobold Pickaxe" },
    ["Jade Pearl"]                 = { MC.MAP.IsleOfDorn, 0.7723, 0.2445, "Jade Pearl" },
    ["Shimmering Opal Lily"]       = { MC.MAP.IsleOfDorn, 0.4889, 0.6087, "Shimmering Opal Lily" },
    ["Infused Cinderbrew"]         = { MC.MAP.IsleOfDorn, 0.5622, 0.6094, "Infused Cinderbrew" },
    ["Web-Wrapped Axe"]            = { MC.MAP.IsleOfDorn, 0.5912, 0.2348, "Web-Wrapped Axe" },
    -- The Ringing Deeps (10)
    ["Webbed Knapsack"]            = { MC.MAP.RingingDeeps, 0.6470, 0.3883, "Webbed Knapsack" },
    ["Cursed Pickaxe"]             = { MC.MAP.RingingDeeps, 0.5892, 0.6311, "Cursed Pickaxe" },
    ["Munderut's Forgotten Stash"] = { MC.MAP.RingingDeeps, 0.5123, 0.1385, "Munderut's Forgotten Stash" },
    ["Discarded Toolbox"]          = { MC.MAP.RingingDeeps, 0.4135, 0.1745, "Discarded Toolbox" },
    ["Waterlogged Refuse"]         = { MC.MAP.RingingDeeps, 0.6204, 0.3341, "Waterlogged Refuse" },
    ["Scary Dark Chest"]           = { MC.MAP.RingingDeeps, 0.5477, 0.3027, "Scary Dark Chest" },
    ["Kaja'Cola Machine"]          = { MC.MAP.RingingDeeps, 0.5485, 0.6438, "Kaja'Cola Machine" },
    ["Dislodged Blockage"]         = { MC.MAP.RingingDeeps, 0.4409, 0.4896, "Dislodged Blockage" },
    ["Dusty Prospector's Chest"]   = { MC.MAP.RingingDeeps, 0.4489, 0.3163, "Dusty Prospector's Chest" },
    ["Forgotten Treasure"]         = { MC.MAP.RingingDeeps, 0.4632, 0.5349, "Forgotten Treasure" },
    -- Hallowfall (11)
    ["Caesper"]                    = { MC.MAP.Hallowfall, 0.4179, 0.5827, "Caesper" },
    ["Smuggler's Treasure"]        = { MC.MAP.Hallowfall, 0.5513, 0.5193, "Smuggler's Treasure" },
    ["Dark Ritual"]                = { MC.MAP.Hallowfall, 0.5952, 0.5966, "Dark Ritual" },
    ["Arathi Loremaster"]          = { MC.MAP.Hallowfall, 0.4003, 0.5112, "Arathi Loremaster" },
    -- Four known lure spawns; first listed.
    ["Illusive Kobyss Lure"]       = { MC.MAP.Hallowfall, 0.5536, 0.2720, "Illusive Kobyss Lure" },
    ["Jewel of the Cliffs"]        = { MC.MAP.Hallowfall, 0.5579, 0.6954, "Jewel of the Cliffs" },
    ["Priory Satchel"]             = { MC.MAP.Hallowfall, 0.3023, 0.3875, "Priory Satchel" },
    ["Lost Necklace"]              = { MC.MAP.Hallowfall, 0.5007, 0.1385, "Lost Necklace" },
    ["Sky-Captains' Sunken Cache"] = { MC.MAP.Hallowfall, 0.4594, 0.4513, "Sky-Captains' Sunken Cache" },
    ["Illuminated Footlocker"]     = { MC.MAP.Hallowfall, 0.5838, 0.2715, "Illuminated Footlocker" },
    ["Spore-covered Coffer"]       = { MC.MAP.Hallowfall, 0.7676, 0.5382, "Spore-covered Coffer" },
    -- Azj-Kahet (10; some caches sit on the Lower / City of Threads maps)
    ["Concealed Contraband"]       = { MC.MAP.AzjKahet, 0.3405, 0.6102, "Concealed Contraband" },
    ["Memory Cache"]               = { AZJ_KAHET_LOWER, 0.6272, 0.8795, "Memory Cache" },
    ["Weaving Supplies"]           = { MC.MAP.AzjKahet, 0.7861, 0.3320, "Weaving Supplies" },
    ["Trapped Trove"]              = { CITY_OF_THREADS, 0.6739, 0.7441, "Trapped Trove" },
    ["Nest Egg"]                   = { MC.MAP.AzjKahet, 0.4955, 0.4370, "Nest Egg" },
    ["Disturbed Soil"]             = { MC.MAP.AzjKahet, 0.6745, 0.9072, "Disturbed Soil" },
    ["Silk-spun Supplies"]         = { MC.MAP.AzjKahet, 0.6748, 0.2754, "Silk-spun Supplies" },
    ["Nerubian Offerings"]         = { CITY_OF_THREADS, 0.3164, 0.2077, "Nerubian Offerings" },
    ["Niffen Stash"]               = { MC.MAP.AzjKahet, 0.5452, 0.5081, "Niffen Stash" },
    ["Missing Scout's Pack"]       = { MC.MAP.AzjKahet, 0.3878, 0.3722, "Missing Scout's Pack" },
    -- Undermine (15)
    ["Unexploded Fireworks"]       = { MC.MAP.Undermine, 0.4847, 0.4307, "Unexploded Fireworks" },
    ["Suspicious Book"]            = { MC.MAP.Undermine, 0.4979, 0.6566, "Suspicious Book" },
    ["Fireworks Hat"]              = { MC.MAP.Undermine, 0.5601, 0.5171, "Fireworks Hat" },
    ["Exploded Plunger"]           = { MC.MAP.Undermine, 0.4969, 0.9025, "Exploded Plunger" },
    ["Blackened Dice"]             = { MC.MAP.Undermine, 0.3896, 0.5963, "Blackened Dice" },
    ["Lonely Tub"]                 = { MC.MAP.Undermine, 0.5935, 0.1912, "Lonely Tub" },
    ["Potent Potable"]             = { MC.MAP.Undermine, 0.6965, 0.2164, "Potent Potable" },
    ["Abandoned Toolbox"]          = { MC.MAP.Undermine, 0.4085, 0.2126, "Abandoned Toolbox" },
    ["Papa's Prized Putter"]       = { MC.MAP.Undermine, 0.7467, 0.7988, "Papa's Prized Putter" },
    ["Unsupervised Takeout"]       = { MC.MAP.Undermine, 0.2686, 0.4265, "Unsupervised Takeout" },
    ["Particularly Nice Lamp"]     = { MC.MAP.Undermine, 0.3938, 0.6103, "Particularly Nice Lamp" },
    ["Uncracked Cold Ones"]        = { MC.MAP.Undermine, 0.5340, 0.5272, "Uncracked Cold Ones" },
    ["Marooned Floatmingo"]        = { MC.MAP.Undermine, 0.6381, 0.3220, "Marooned Floatmingo" },
    ["Trick Deck of Cards"]        = { MC.MAP.Undermine, 0.4366, 0.5154, "Trick Deck of Cards" },
    ["Crumpled Schematics"]        = { MC.MAP.Undermine, 0.4230, 0.8231, "Crumpled Schematics" },
    -- K'aresh (27; four are inside Tazavesh)
    ["Gift of the Brothers"]       = { MC.MAP.Karesh, 0.7611, 0.4526, "Gift of the Brothers" },
    ["Ancient Coffer"]             = { MC.MAP.Karesh, 0.6090, 0.3835, "Ancient Coffer" },
    ["Forlorn Wind Chime"]         = { MC.MAP.Karesh, 0.6974, 0.5231, "Forlorn Wind Chime" },
    ["Mailroom Distribution"]      = { MC.MAP.Tazavesh, 0.4776, 0.6265, "Mailroom Distribution" },
    ["Ixthar's Favorite Crystal"]  = { MC.MAP.Karesh, 0.6410, 0.4398, "Ixthar's Favorite Crystal" },
    ["Wastelander Stash"]          = { MC.MAP.Karesh, 0.6054, 0.4213, "Wastelander Stash" },
    ["Tumbled Package"]            = { MC.MAP.Karesh, 0.6534, 0.6362, "Tumbled Package" },
    ["Rashaal's Vase"]             = { MC.MAP.Karesh, 0.7020, 0.4773, "Rashaal's Vase" },
    ["Shattered Crystals"]         = { MC.MAP.Karesh, 0.7506, 0.5534, "Shattered Crystals" },
    ["Skeletal Tail Bones"]        = { MC.MAP.Karesh, 0.7778, 0.2787, "Skeletal Tail Bones" },
    ["Crudely Stitched Sack"]      = { MC.MAP.Karesh, 0.5865, 0.3434, "Crudely Stitched Sack" },
    -- Five known spawns; first listed.
    ["Abandoned Lockbox"]          = { MC.MAP.Karesh, 0.5398, 0.5926, "Abandoned Lockbox" },
    -- Three known spawns; first listed.
    ["Lightly-Dented Luggage"]     = { MC.MAP.Karesh, 0.5370, 0.6405, "Lightly-Dented Luggage" },
    ["Sand-Worn Coffer"]           = { MC.MAP.Karesh, 0.5446, 0.2444, "Sand-Worn Coffer" },
    ["Ethereal Voidforged Container"] = { MC.MAP.Karesh, 0.5209, 0.6833, "Ethereal Voidforged Container" },
    ["Light-Soaked Cleaver"]       = { MC.MAP.Karesh, 0.5250, 0.4677, "Light-Soaked Cleaver" },
    ["Spear of Fallen Memories"]   = { MC.MAP.Tazavesh, 0.2369, 0.4682, "Spear of Fallen Memories" },
    ["Efrat's Forgotten Bulwark"]  = { MC.MAP.Karesh, 0.7799, 0.4894, "Efrat's Forgotten Bulwark" },
    ["Tulwar of the Golden Guard"] = { MC.MAP.Karesh, 0.5105, 0.6509, "Tulwar of the Golden Guard" },
    ["Petrified Branch of Janaa"]  = { MC.MAP.Karesh, 0.7834, 0.6154, "Petrified Branch of Janaa" },
    ["Shadowguard Crusher"]        = { MC.MAP.Karesh, 0.4920, 0.1805, "Shadowguard Crusher" },
    ["Sufaadi Skiff Lantern"]      = { MC.MAP.Karesh, 0.8072, 0.5267, "Sufaadi Skiff Lantern" },
    ["Korgorath's Talon"]          = { MC.MAP.Karesh, 0.6443, 0.4269, "Korgorath's Talon" },
    ["Warglaive of the Audacious Hunter"] = { MC.MAP.Karesh, 0.5843, 0.2259, "Warglaive of the Audacious Hunter" },
    ["P.O.S.T. Master's Prototype Parcel and Postage Presser"] = { MC.MAP.Tazavesh, 0.4747, 0.6998, "P.O.S.T. Master's Prototype Parcel" },
    ["Phaseblade of the Void Marches"] = { MC.MAP.Karesh, 0.5082, 0.3534, "Phaseblade of the Void Marches" },
    ["Bladed Rifle of Unfettered Momentum"] = { MC.MAP.Tazavesh, 0.6516, 0.1472, "Bladed Rifle of Unfettered Momentum" },
}

local function mergeTreasureMetadata()
    MC.TreasureSourceOrder  = MC.TreasureSourceOrder or {}
    MC.TreasureSourceLabels = MC.TreasureSourceLabels or {}
    MC.TreasureCoords       = MC.TreasureCoords or {}
    for _, key in ipairs(TWW_SOURCE_ORDER) do
        if MC.TreasureSourceLabels[key] == nil then
            MC.TreasureSourceOrder[#MC.TreasureSourceOrder + 1] = key
            MC.TreasureSourceLabels[key] = TWW_SOURCE_LABELS[key]
        end
    end
    for name, waypoint in pairs(TWW_COORDS) do
        if MC.TreasureCoords[name] == nil then
            MC.TreasureCoords[name] = waypoint
        end
    end
end

local merger = CreateFrame("Frame")
merger:RegisterEvent("ADDON_LOADED")
merger:SetScript("OnEvent", function(self, _, loadedName)
    if loadedName ~= ADDON then return end
    self:UnregisterEvent("ADDON_LOADED")
    self:SetScript("OnEvent", nil)
    mergeTreasureMetadata()
end)
