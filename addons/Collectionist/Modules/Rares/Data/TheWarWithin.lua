local addonName, MC = ...
local T = MC.SCORE_TIERS

-- The War Within (tww) zone-rare achievements: the four launch zones plus
-- Siren Isle (11.0.7), Undermine (11.1), and K'aresh (11.2).
--
-- Criteria/NPC IDs: research/collectionist/tww/ids/rares.csv (order_path
-- sorted numerically). 40435/40837/41046/41216/42761 use kill-creature
-- criteria (type 0, assetID == npcID); 40840/40851 use quest-complete
-- criteria (type 27, assetID is a QUEST id), so the positional
-- criteriaNPCIDs arrays below are the only npcID source for those two.
-- Coords sourced from HandyNotes_TheWarWithin (Aug 2026).
--
-- LOAD ORDER NOTE: this file precedes Rares.lua in the TOC, and Rares.lua
-- assigns MC.RareSourceOrder / MC.RareSourceLabels / MC.RareNPCs /
-- MC.RareCoords / MC.RareScoreOverrides wholesale (it predates
-- multi-expansion data). Writing into those tables here would be clobbered,
-- so this file stages its additions and merges them on ADDON_LOADED, which
-- fires after every TOC file has executed and before the first (post-login,
-- deferred) scan. RegisterContent appends and is safe at load time.

MC.RegisterContent("tww", "rares", {
    { source = "isle_of_dorn", achievementID = 40435, criteriaCount = 22,
      criteriaNPCIDs = {
          213115, 217534, 219262, 219263, 219264, 219265, 219267, 219268,
          219266, 219269, 219270, 219278, 219271, 219279, 221128, 219281,
          219284, 222378, 222380, 221126, 220883, 220890,
      }, name = "Adventurer of the Isle of Dorn",
      zoneMapID = MC.MAP.IsleOfDorn, zone = "Isle of Dorn" },
    { source = "ringing_deeps", achievementID = 40837, criteriaCount = 18,
      criteriaNPCIDs = {
          220276, 220275, 220274, 220273, 220272, 220271, 220270, 220269,
          220268, 220267, 220266, 220265, 220287, 220286, 220285, 221217,
          221199, 218393,
      }, name = "Adventurer of The Ringing Deeps",
      zoneMapID = MC.MAP.RingingDeeps, zone = "The Ringing Deeps" },
    { source = "hallowfall", achievementID = 40851, criteriaCount = 25,
      criteriaNPCIDs = {
          218458, 218426, 218452, 221551, 221767, 218444, 215805, 221534,
          221648, 221668, 221708, 207802, 221690, 221786, 221753, 206203,
          206514, 206184, 214757, 207803, 221179, 206977, 207826, 207780,
          220771,
      }, name = "Adventurer of Hallowfall",
      zoneMapID = MC.MAP.Hallowfall, zone = "Hallowfall" },
    -- Criterion 1 ("Rhak'ik & Khak'ik") is a single criterion covering a
    -- shared spawn with two NPC ids (216032 and 221032); 216032 is the
    -- primary/tracked id, 221032 gets a waypoint entry below for safety.
    { source = "azj_kahet", achievementID = 40840, criteriaCount = 19,
      criteriaNPCIDs = {
          216031, 216032, 214151, 216041, 216037, 216038, 216039, 221327,
          216034, 216042, 216043, 216044, 216045, 216048, 216049, 216050,
          216051, 222624, 216052,
      }, name = "Adventurer of Azj-Kahet",
      zoneMapID = MC.MAP.AzjKahet, zone = "Azj-Kahet" },
    { source = "siren_isle", achievementID = 41046, criteriaCount = 16,
      criteriaNPCIDs = {
          229982, 228201, 229992, 228154, 227550, 228601, 228155, 228159,
          231090, 228151, 229852, 229853, 228583, 228580, 227545, 230137,
      }, name = "Clean Up on Isle Siren",
      zoneMapID = MC.MAP.SirenIsle, zone = "Siren Isle" },
    { source = "undermine", achievementID = 41216, criteriaCount = 21,
      criteriaNPCIDs = {
          230931, 230934, 230940, 230947, 230946, 230951, 230979, 230995,
          231012, 231017, 231288, 230746, 230793, 230800, 230828, 230840,
          234480, 234499, 233471, 233472, 231310,
      }, name = "Adventurer of Undermine",
      zoneMapID = MC.MAP.Undermine, zone = "Undermine" },
    { source = "karesh", achievementID = 42761, criteriaCount = 19,
      criteriaNPCIDs = {
          232098, 241956, 238540, 245998, 232128, 232077, 245997, 231981,
          232108, 232127, 232182, 232189, 232006, 232129, 232193, 234845,
          232111, 232195, 232199,
      }, name = "Remnants of a Shattered World",
      zoneMapID = MC.MAP.Karesh, zone = "K'aresh" },
})

-- Source keys in campaign order; merged into the head of MC.RareSourceOrder
-- so the shared list stays chronological (TWW zones before Midnight zones).
local SOURCE_KEYS = {
    { "isle_of_dorn",  "Isle of Dorn" },
    { "ringing_deeps", "The Ringing Deeps" },
    { "hallowfall",    "Hallowfall" },
    { "azj_kahet",     "Azj-Kahet" },
    { "siren_isle",    "Siren Isle" },
    { "undermine",     "Undermine" },
    { "karesh",        "K'aresh" },
}

-- npcID -> { mapID, x, y, "Name" }, HandyNotes_TheWarWithin coords.
-- Sub-maps without an MC.MAP constant use literal ids (commented inline).
local added = {
    -- Isle of Dorn (22)
    [213115] = { MC.MAP.IsleOfDorn, 0.3565, 0.7489, "Rustul Titancap" },
    [217534] = { MC.MAP.IsleOfDorn, 0.6277, 0.6842, "Sandres the Relicbearer" },
    [219262] = { MC.MAP.IsleOfDorn, 0.5877, 0.6068, "Springbubble" },
    [219263] = { MC.MAP.IsleOfDorn, 0.5683, 0.3477, "Warphorn" },
    [219264] = { MC.MAP.IsleOfDorn, 0.4107, 0.7616, "Bloodmaw" },
    -- Cave interior spawn; entrances near 45.9,60.0 / 46.2,62.1 / 47.7,61.7.
    [219265] = { MC.MAP.IsleOfDorn, 0.4794, 0.6014, "Emperor Pitfang" },
    [219267] = { MC.MAP.IsleOfDorn, 0.5087, 0.6975, "Plaguehart" },
    [219268] = { MC.MAP.IsleOfDorn, 0.5352, 0.7998, "Gar'loc" },
    [219266] = { MC.MAP.IsleOfDorn, 0.2578, 0.4503, "Escaped Cutthroat" },
    [219269] = { MC.MAP.IsleOfDorn, 0.5689, 0.1601, "Tempest Lord Incarnus" },
    [219270] = { MC.MAP.IsleOfDorn, 0.4821, 0.2701, "Kronolith, Might of the Mountain" },
    [219278] = { MC.MAP.IsleOfDorn, 0.7442, 0.2804, "Shallowshell the Clacker" },
    [219271] = { MC.MAP.IsleOfDorn, 0.5712, 0.2241, "Twice-Stinger the Wretched" },
    [219279] = { MC.MAP.IsleOfDorn, 0.6398, 0.4054, "Flamekeeper Graz" },
    [221128] = { MC.MAP.IsleOfDorn, 0.5576, 0.2753, "Clawbreaker K'zithix" },
    [219281] = { MC.MAP.IsleOfDorn, 0.2333, 0.5817, "Alunira" },
    -- Zovex/Kereke/Rotfist rotate through one shared spawn point
    -- (HandyNotes' "Violet Hold Prisoner" node); identical coords intended.
    [219284] = { MC.MAP.IsleOfDorn, 0.3090, 0.5239, "Zovex" },
    [222378] = { MC.MAP.IsleOfDorn, 0.3090, 0.5239, "Kereke" },
    [222380] = { MC.MAP.IsleOfDorn, 0.3090, 0.5239, "Rotfist" },
    [221126] = { MC.MAP.IsleOfDorn, 0.7291, 0.3794, "Tephratennae" },
    [220883] = { MC.MAP.IsleOfDorn, 0.6985, 0.3850, "Sweetspark the Oozeful" },
    [220890] = { MC.MAP.IsleOfDorn, 0.7300, 0.4009, "Matriarch Charfuria" },
    -- The Ringing Deeps (18)
    [220276] = { MC.MAP.RingingDeeps, 0.6207, 0.2975, "Candleflyer Captain" },
    [220275] = { MC.MAP.RingingDeeps, 0.3861, 0.3508, "King Splash" },
    [220274] = { MC.MAP.RingingDeeps, 0.4539, 0.6618, "Aquellion" },
    [220273] = { MC.MAP.RingingDeeps, 0.5285, 0.5473, "Rampaging Blight" },
    [220272] = { MC.MAP.RingingDeeps, 0.6247, 0.6887, "Deathbound Husk" }, -- small cave
    [220271] = { MC.MAP.RingingDeeps, 0.4346, 0.1217, "Terror of the Forge" },
    [220270] = { MC.MAP.RingingDeeps, 0.4787, 0.2657, "Zilthara" },
    [220269] = { MC.MAP.RingingDeeps, 0.4683, 0.4631, "Cragmund" },
    [220268] = { MC.MAP.RingingDeeps, 0.6749, 0.4630, "Trungal" }, -- cave approach
    [220267] = { MC.MAP.RingingDeeps, 0.3721, 0.1692, "Charmonger" },
    [220266] = { MC.MAP.RingingDeeps, 0.5374, 0.3813, "Coalesced Monstrosity" },
    [220265] = { MC.MAP.RingingDeeps, 0.4843, 0.1991, "Automaxor" },
    [220287] = { MC.MAP.RingingDeeps, 0.4290, 0.4697, "Kelpmire" },
    [220286] = { MC.MAP.RingingDeeps, 0.4884, 0.0880, "Deepflayer Broodmother" }, -- patrols; patrol start
    [220285] = { MC.MAP.RingingDeeps, 0.5672, 0.7668, "Lurker of the Deeps" }, -- underwater approach
    [221217] = { MC.MAP.RingingDeeps, 0.6205, 0.4622, "Spore-infused Shalewing" },
    [221199] = { MC.MAP.RingingDeeps, 0.6119, 0.4950, "Hungerer of the Deeps" },
    [218393] = { MC.MAP.RingingDeeps, 0.6288, 0.5265, "Disturbed Earthgorger" },
    -- Hallowfall (25)
    [218458] = { MC.MAP.Hallowfall, 0.7211, 0.6435, "Deepfiend Azellix" },
    [218426] = { MC.MAP.Hallowfall, 0.5704, 0.6433, "Ixlorb the Spinner" },
    [218452] = { MC.MAP.Hallowfall, 0.5213, 0.2681, "Murkshade" },
    [221551] = { MC.MAP.Hallowfall, 0.3690, 0.5469, "Grimslice" },
    [221767] = { MC.MAP.Hallowfall, 0.3680, 0.7187, "Funglour" },
    [218444] = { MC.MAP.Hallowfall, 0.5648, 0.6899, "The Taskmaker" },
    [215805] = { MC.MAP.Hallowfall, 0.7340, 0.5259, "Sloshmuck" },
    [221534] = { MC.MAP.Hallowfall, 0.2300, 0.5922, "Lytfang the Lost" },
    [221648] = { MC.MAP.Hallowfall, 0.4401, 0.1637, "The Perchfather" },
    [221668] = { MC.MAP.Hallowfall, 0.3312, 0.2687, "Horror of the Shallows" },
    [221708] = { MC.MAP.Hallowfall, 0.3594, 0.3547, "Sir Alastair Purefire" },
    -- No fixed spawn: rotates among several locations on a 3-hour cycle;
    -- this is HandyNotes' single representative marker.
    [207802] = { MC.MAP.Hallowfall, 0.2500, 0.4500, "Beledar's Spawn" },
    [221690] = { MC.MAP.Hallowfall, 0.4360, 0.2994, "Strength of Beledar" },
    [221786] = { MC.MAP.Hallowfall, 0.5730, 0.4857, "Pride of Beledar" },
    [221753] = { MC.MAP.Hallowfall, 0.4474, 0.4241, "Deathtide" },
    [206203] = { MC.MAP.Hallowfall, 0.6345, 0.2854, "Moth'ethk" },
    [206514] = { MC.MAP.Hallowfall, 0.6505, 0.2965, "Crazed Cabbage Smacker" },
    [206184] = { MC.MAP.Hallowfall, 0.6364, 0.3205, "Deathpetal" },
    [214757] = { MC.MAP.Hallowfall, 0.6755, 0.2316, "Croakit" },
    [207803] = { MC.MAP.Hallowfall, 0.6643, 0.2411, "Toadstomper" },
    [221179] = { MC.MAP.Hallowfall, 0.6393, 0.1977, "Duskshadow" },
    [206977] = { MC.MAP.Hallowfall, 0.6161, 0.3277, "Parasidious" },
    [207826] = { MC.MAP.Hallowfall, 0.6194, 0.3197, "Ravageant" },
    [207780] = { MC.MAP.Hallowfall, 0.6201, 0.1683, "Finclaw Bloodtide" },
    [220771] = { MC.MAP.Hallowfall, 0.6198, 0.1331, "Murkspike" }, -- patrols; point on route
    -- Azj-Kahet (19 criteria, 20 npc entries: Rhak'ik & Khak'ik dual-id).
    -- Sub-maps not in MC.MAP: 2256 Azj-Kahet Lower, 2213 City of Threads,
    -- 2216 City of Threads Lower (per HandyNotes map declarations).
    [216031] = { MC.MAP.AzjKahet, 0.4638, 0.3875, "Abyssal Devourer" },
    [216032] = { MC.MAP.AzjKahet, 0.4386, 0.3678, "Rhak'ik & Khak'ik" },
    [221032] = { MC.MAP.AzjKahet, 0.4386, 0.3678, "Rhak'ik & Khak'ik" },
    [214151] = { MC.MAP.AzjKahet, 0.3792, 0.4284, "Ahg'zagall" },
    [216041] = { MC.MAP.AzjKahet, 0.6123, 0.2730, "Webspeaker Grik'ik" }, -- in building
    [216037] = { MC.MAP.AzjKahet, 0.3469, 0.4110, "Vilewing" },
    [216038] = { 2213, 0.3075, 0.5599, "The Groundskeeper" },       -- City of Threads
    [216039] = { 2216, 0.6752, 0.5826, "Xishorr" },                 -- City of Threads Lower
    [221327] = { MC.MAP.AzjKahet, 0.6315, 0.2530, "Kaheti Silk Hauler" },
    [216034] = { MC.MAP.AzjKahet, 0.7658, 0.5780, "The XT-Minecrusher 8700" }, -- small cave
    [216042] = { MC.MAP.AzjKahet, 0.7072, 0.2147, "Cha'tak" }, -- waterfall cave
    [216043] = { MC.MAP.AzjKahet, 0.6998, 0.6923, "Monstrous Lasharoth" },
    [216044] = { MC.MAP.AzjKahet, 0.6649, 0.6197, "Maddened Siegebomber" },
    [216045] = { MC.MAP.AzjKahet, 0.5803, 0.6210, "Enduring Gutterface" },
    [216048] = { 2256, 0.6743, 0.8318, "Jix'ak the Crazed" },       -- Azj-Kahet Lower
    [216049] = { 2256, 0.6191, 0.8962, "The Oozekhan" },            -- Azj-Kahet Lower, small cave
    [216050] = { 2256, 0.6519, 0.8283, "Harvester Qixt" },          -- Azj-Kahet Lower
    [216051] = { MC.MAP.AzjKahet, 0.6459, 0.0352, "Umbraclaw Matra" },
    [222624] = { MC.MAP.AzjKahet, 0.6456, 0.0668, "Deepcrawler Tx'kesh" },
    [216052] = { MC.MAP.AzjKahet, 0.6240, 0.0703, "Skirmisher Sa'zryk" },
    -- Siren Isle (16). 2375 = The Forgotten Vault sub-map (HandyNotes).
    [229982] = { MC.MAP.SirenIsle, 0.2620, 0.6546, "Nerathor" },    -- cave; entrance 0.3175/0.6503
    [228201] = { MC.MAP.SirenIsle, 0.5772, 0.6612, "Gravesludge" }, -- cave; entrance 0.6147/0.7357
    [229992] = { MC.MAP.SirenIsle, 0.3711, 0.5497, "Stalagnarok" }, -- cave; entrance 0.4278/0.5666
    [228154] = { MC.MAP.SirenIsle, 0.3614, 0.7261, "Bloodbrine" },
    [227550] = { 2375, 0.2807, 0.2475, "Shardsong" },               -- The Forgotten Vault
    [228601] = { MC.MAP.SirenIsle, 0.5328, 0.3383, "Ghostmaker" },
    [228155] = { MC.MAP.SirenIsle, 0.3415, 0.1392, "Grimgull" },
    [228159] = { 2375, 0.6646, 0.5635, "Gunnlod the Sea-Drinker" }, -- The Forgotten Vault
    [231090] = { MC.MAP.SirenIsle, 0.6739, 0.1919, "Snacker" },
    [228151] = { MC.MAP.SirenIsle, 0.4678, 0.7812, "Wreckwater" },
    [229852] = { MC.MAP.SirenIsle, 0.6175, 0.8953, "Coralweaver Calliso" },
    [229853] = { MC.MAP.SirenIsle, 0.5606, 0.8410, "Siris the Sea Scorpion" },
    [228583] = { MC.MAP.SirenIsle, 0.6612, 0.8495, "Chef Chum Platter" },
    [228580] = { MC.MAP.SirenIsle, 0.6069, 0.8921, "Plank-Master Bluebelly" },
    [227545] = { MC.MAP.SirenIsle, 0.3245, 0.7405, "Ikir the Flotsurge" },
    [230137] = { MC.MAP.SirenIsle, 0.6394, 0.8729, "Asbjorn the Bloodsoaked" },
    -- Undermine (21)
    [230931] = { MC.MAP.Undermine, 0.6850, 0.8078, "Scrap Beak" },
    [230934] = { MC.MAP.Undermine, 0.2524, 0.3675, "Ratspit" },
    [230940] = { MC.MAP.Undermine, 0.3768, 0.4448, "Tally Doublespeak" },
    -- Slimesby and V.V. Goosworth alternate at one shared spawn point;
    -- identical coords intended (HandyNotes models them as one node).
    [230947] = { MC.MAP.Undermine, 0.3687, 0.7815, "Slimesby" },
    [230946] = { MC.MAP.Undermine, 0.3687, 0.7815, "V.V. Goosworth" },
    [230951] = { MC.MAP.Undermine, 0.5401, 0.5023, "Thwack" },
    [230979] = { MC.MAP.Undermine, 0.4192, 0.2563, "S.A.L." },
    [230995] = { MC.MAP.Undermine, 0.4691, 0.5565, "Nitro" },
    [231012] = { MC.MAP.Undermine, 0.4222, 0.7735, "Candy Stickemup" },
    [231017] = { MC.MAP.Undermine, 0.6733, 0.3353, "Grimewick" },
    [231288] = { MC.MAP.Undermine, 0.4135, 0.4357, "Swigs Farsight" },
    [230746] = { MC.MAP.Undermine, 0.2651, 0.6830, "Ephemeral Agent Lathyd" },
    [230793] = { MC.MAP.Undermine, 0.6335, 0.4975, "The Junk-Wall" },
    [230800] = { MC.MAP.Undermine, 0.5235, 0.4107, "Slugger the Smart" },
    [230828] = { MC.MAP.Undermine, 0.5848, 0.8643, "Chief Foreman Gutso" },
    [230840] = { MC.MAP.Undermine, 0.6058, 0.0989, "Flyboy Snooty" },
    [234480] = { MC.MAP.Undermine, 0.4000, 0.2232, "M.A.G.N.O." },
    [234499] = { MC.MAP.Undermine, 0.3202, 0.7652, "Giovante" },
    [233471] = { MC.MAP.Undermine, 0.5720, 0.7860, "Scrapchewer" },
    [233472] = { MC.MAP.Undermine, 0.6416, 0.2556, "Volstrike the Charged" },
    [231310] = { MC.MAP.Undermine, 0.4020, 0.9190, "Darkfuse Precipitant" },
    -- K'aresh (19; three on the Tazavesh sub-map)
    [232098] = { MC.MAP.Tazavesh, 0.7294, 0.8327, "\"Chowdar\"" },
    [241956] = { MC.MAP.Tazavesh, 0.3505, 0.3647, "Arcana-Monger So'zer" },
    [238540] = { MC.MAP.Tazavesh, 0.7113, 0.5712, "Grubber" },
    [245998] = { MC.MAP.Karesh, 0.7523, 0.3098, "Heka'tamos" },
    [232128] = { MC.MAP.Karesh, 0.6382, 0.4363, "Ixthar the Unblinking" },
    [232077] = { MC.MAP.Karesh, 0.6631, 0.4258, "Korgorath the Ravager" },
    [245997] = { MC.MAP.Karesh, 0.5405, 0.5884, "Malek'ta" },
    [231981] = { MC.MAP.Karesh, 0.5445, 0.5445, "Maw of the Sands" },
    [232108] = { MC.MAP.Karesh, 0.5620, 0.5058, "Morgil the Netherspawn" }, -- patrols
    [232127] = { MC.MAP.Karesh, 0.5278, 0.2081, "Orith the Dreadful" },
    [232182] = { MC.MAP.Karesh, 0.4578, 0.2425, "Prototype MK-V" }, -- patrols
    [232189] = { MC.MAP.Karesh, 0.5053, 0.6469, "Revenant of the Wasteland" },
    [232006] = { MC.MAP.Karesh, 0.7220, 0.5557, "Sha'ryth the Cursed" }, -- patrols
    [232129] = { MC.MAP.Karesh, 0.5417, 0.4911, "Shadowhowl" },
    [232193] = { MC.MAP.Karesh, 0.7675, 0.4219, "Stalker of the Wastes" },
    [234845] = { MC.MAP.Karesh, 0.7404, 0.3254, "Sthaarbs" },
    [232111] = { MC.MAP.Karesh, 0.5270, 0.5660, "The Nightreaver" }, -- patrols
    [232195] = { MC.MAP.Karesh, 0.7014, 0.4983, "Urmag" },
    [232199] = { MC.MAP.Karesh, 0.6514, 0.4998, "Xarran the Binder" },
}

-- Per-rare score overrides above the zone default (short = 5), mirroring
-- the Midnight file's practice for hidden-prerequisite/long-cycle spawns.
-- Mechanics documented in the HandyNotes_TheWarWithin plugin notes.
local scoreOverrides = {
    -- Rotating spawn on a 3-hour cycle keyed to the daily reset.
    [207802] = T.medium, -- Beledar's Spawn
    -- Require summoning steps (lures / element collection) before spawning.
    [238540] = T.medium, -- Grubber
    [241956] = T.medium, -- Arcana-Monger So'zer
    [245997] = T.medium, -- Malek'ta
    [245998] = T.medium, -- Heka'tamos
}

local function merge()
    MC.RareSourceOrder = MC.RareSourceOrder or {}
    MC.RareSourceLabels = MC.RareSourceLabels or {}
    local have = {}
    for _, key in ipairs(MC.RareSourceOrder) do have[key] = true end
    -- The base file already declares every key it owns; a second copy puts
    -- the zone in the order list twice.
    local at = 0
    for _, sk in ipairs(SOURCE_KEYS) do
        MC.RareSourceLabels[sk[1]] = sk[2]
        if not have[sk[1]] then
            at = at + 1
            have[sk[1]] = true
            table.insert(MC.RareSourceOrder, at, sk[1])
        end
    end
    MC.RareNPCs = MC.RareNPCs or {}
    for npcID, waypoint in pairs(added) do
        MC.RareNPCs[npcID] = waypoint
        if MC.RareCoords then MC.RareCoords[waypoint[4]] = waypoint end
    end
    MC.RareScoreOverrides = MC.RareScoreOverrides or {}
    for npcID, tier in pairs(scoreOverrides) do
        MC.RareScoreOverrides[npcID] = tier
    end
end

if MC.RareNPCs then
    -- Loaded after the base Rares.lua (e.g. a future TOC reorder): the
    -- shared tables exist, merge immediately like the Patch files do.
    merge()
else
    -- Planned TOC position (before Rares.lua): defer until ADDON_LOADED.
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, _, loadedName)
        if loadedName ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")
        self:SetScript("OnEvent", nil)
        merge()
    end)
end
