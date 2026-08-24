local addonName, MC = ...

-- Warlords of Draenor treasures. Exact 368 ordered criteria rows.
MC.RegisterContent("wod", "treasures", {
    { source = "nagrand", achievementID = 9548, criteriaCount = 6,
      criteriaTreeIDs = { 39604, 39605, 39606, 39607, 39608, 39609 },
      criteriaNames = { "Garrosh's Shackles", "Warsong Relics", "Warsong Remains", "Stolen Draenei Tome", "Wolf Pup Remains", "Gnarled Bone" },
      name = "Buried Treasures",
      zoneMapID = MC.MAP.NagrandDraenor, zone = "Nagrand" },
    { source = "draenor", achievementID = 9728, criteriaCount = 310,
      criteriaTreeIDs = { 41841, 41842, 41843, 41844, 41845, 41846, 41847, 41848, 41849, 41850, 41851, 41852, 41853, 41854, 41855, 41856, 41857, 41858, 41859, 41860, 41861, 41862, 41863, 41864, 41865, 41866, 41867, 41868, 41869, 41870, 41871, 41872, 41873, 41874, 41875, 41876, 41877, 41878, 41879, 41880, 41881, 41882, 41883, 41884, 41885, 41886, 41887, 41888, 41889, 41890, 41891, 41892, 41893, 41894, 41895, 41896, 41897, 41898, 41899, 41900, 41901, 41902, 41903, 41904, 41905, 41906, 41907, 41908, 41909, 41910, 41911, 41912, 41913, 41914, 41915, 41916, 41917, 41918, 41919, 41920, 41921, 41922, 41923, 41924, 41925, 41926, 41927, 41928, 41929, 41930, 41931, 41932, 41933, 41934, 41935, 41936, 41937, 41938, 41939, 41940, 41941, 41942, 41943, 41944, 41945, 41946, 41947, 41948, 41949, 41950, 41951, 41952, 41953, 41954, 41955, 41956, 41957, 41958, 41959, 41960, 41961, 41962, 41963, 41964, 41965, 41966, 41967, 41968, 41969, 41970, 41971, 41972, 41973, 41974, 41975, 41976, 41977, 41978, 41979, 41980, 41981, 41982, 41983, 41984, 41985, 41986, 41987, 41988, 41989, 41990, 41991, 41992, 41993, 41994, 41995, 41996, 41997, 41998, 41999, 42000, 42001, 42002, 42003, 42004, 42005, 42006, 42007, 42008, 42009, 42010, 42011, 42012, 42013, 42014, 42015, 42016, 42017, 42018, 42019, 42020, 42021, 42022, 42023, 42024, 42025, 42026, 42027, 42028, 42029, 42030, 42031, 42032, 42033, 42034, 42035, 42036, 42037, 42038, 42039, 42040, 42041, 42042, 42043, 42044, 42045, 42046, 42047, 42048, 42049, 42050, 42051, 42052, 42053, 42054, 42055, 42056, 42057, 42058, 42059, 42060, 42061, 42062, 42063, 42064, 42065, 42066, 42067, 42068, 42069, 42070, 42071, 42072, 42073, 42074, 42075, 42076, 42077, 42078, 42079, 42080, 42081, 42082, 42083, 42084, 42085, 42086, 42087, 42088, 42089, 42090, 42091, 42092, 42093, 42094, 42095, 42096, 42097, 42098, 42099, 42100, 42101, 42102, 42103, 42104, 42105, 42106, 42107, 42108, 42109, 42110, 42111, 42112, 42113, 42114, 42115, 42116, 42117, 42118, 42119, 42120, 42121, 42122, 42123, 42124, 42125, 42126, 42127, 42128, 42129, 42130, 42131, 42132, 42133, 42134, 42135, 42136, 42137, 42138, 42139, 42140, 42141, 42142, 42143, 42144, 42145, 42146, 45756, 45757, 45758, 45759 },
      name = "Grand Treasure Hunter",
      zoneMapID = MC.MAP.Draenor, zone = "Draenor" },
    { source = "tanaan_jungle", achievementID = 10262, criteriaCount = 52,
      criteriaTreeIDs = { 44950, 44949, 44961, 44936, 44971, 44951, 44947, 44966, 44941, 44964, 44948, 44938, 44967, 44959, 44956, 44946, 44968, 44934, 44953, 44939, 44969, 44958, 44970, 44973, 44962, 44942, 44945, 44960, 44937, 44954, 44952, 44972, 44965, 44935, 44955, 44943, 44957, 44940, 44963, 44944, 45020, 45021, 45254, 45255, 45256, 45257, 45258, 45259, 45260, 45261, 45262, 45739 },
      name = "Jungle Treasure Master",
      zoneMapID = MC.MAP.TanaanJungle, zone = "Tanaan Jungle" },
})

local SOURCE_KEYS = {
    { "nagrand", "Nagrand" },
    { "draenor", "Draenor" },
    { "tanaan", "Tanaan Jungle" },
}
local function merge()
    MC.TreasureSourceOrder = MC.TreasureSourceOrder or {}
    MC.TreasureSourceLabels = MC.TreasureSourceLabels or {}
    local have = {}
    for _, key in ipairs(MC.TreasureSourceOrder) do have[key] = true end
    -- The base file already declares every key it owns. Inserting a
    -- second copy put the zone in the order list twice, which draws
    -- its group twice and prints it twice in the /mc summary.
    local at = 0
    for _, pair in ipairs(SOURCE_KEYS) do
        MC.TreasureSourceLabels[pair[1]] = pair[2]
        if not have[pair[1]] then
            at = at + 1
            have[pair[1]] = true
            table.insert(MC.TreasureSourceOrder, at, pair[1])
        end
    end
end
if MC.TreasureSourceOrder then merge() else
    local frame = CreateFrame("Frame"); frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, _, name) if name ~= addonName then return end; self:UnregisterEvent("ADDON_LOADED"); self:SetScript("OnEvent", nil); merge() end)
end
