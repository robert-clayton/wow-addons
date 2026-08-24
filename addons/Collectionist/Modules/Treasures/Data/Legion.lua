local addonName, MC = ...

-- Legion treasures and hidden-object collections. Exact 314 ordered criteria rows.
MC.RegisterContent("legion", "treasures", {
    { source = "azsuna", achievementID = 11256, criteriaCount = 49,
      criteriaTreeIDs = { 53747, 53748, 53749, 53750, 53751, 53752, 53753, 53754, 53755, 53756, 53757, 53758, 53759, 53760, 53761, 53762, 53763, 53764, 53765, 53766, 53767, 53768, 53769, 53770, 53771, 53772, 53773, 53774, 53775, 53776, 53777, 53778, 53779, 53780, 53781, 53782, 53783, 53784, 53785, 53786, 53787, 53788, 53789, 53790, 53791, 53792, 53793, 53794, 53795 },
      criteriaNames = { "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" }, name = "Treasures of Azsuna",
      zoneMapID = MC.MAP.Azsuna, zone = "Azsuna" },
    { source = "valsharah", achievementID = 11258, criteriaCount = 68,
      criteriaTreeIDs = { 53805, 53940, 53941, 53942, 53943, 53944, 53945, 53946, 53947, 53948, 53949, 53950, 53951, 53952, 53953, 53954, 53955, 53956, 53957, 53958, 53959, 53960, 53961, 53962, 53963, 53964, 53965, 53966, 53967, 53968, 53969, 53970, 53971, 53972, 53973, 53974, 53975, 53976, 53977, 53978, 53979, 53980, 53981, 53982, 53983, 53984, 53985, 53986, 53987, 53988, 53989, 53990, 53991, 53992, 53993, 53994, 53995, 53996, 53997, 53998, 53999, 54000, 54001, 54002, 54003, 54004, 54005, 54006 },
      criteriaNames = { "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" }, name = "Treasures of Val'sharah",
      zoneMapID = MC.MAP.Valsharah, zone = "Val'sharah" },
    { source = "stormheim", achievementID = 11259, criteriaCount = 72,
      criteriaTreeIDs = { 53807, 54007, 54008, 54009, 54010, 54011, 54012, 54013, 54014, 54015, 54016, 54017, 54018, 54019, 54020, 54021, 54022, 54023, 54024, 54025, 54026, 54027, 54028, 54029, 54030, 54031, 54032, 54033, 54034, 54035, 54036, 54037, 54038, 54039, 54040, 54041, 54042, 54043, 54044, 54045, 54046, 54047, 54048, 54049, 54050, 54051, 54052, 54053, 54054, 54055, 54056, 54057, 54058, 54059, 54060, 54061, 54062, 54063, 54064, 54065, 54066, 54067, 54068, 54069, 54070, 54071, 54072, 54073, 54074, 54075, 54076, 54077 },
      criteriaNames = { "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" }, name = "Treasures of Stormheim",
      zoneMapID = MC.MAP.Stormheim, zone = "Stormheim" },
    { source = "highmountain", achievementID = 11257, criteriaCount = 45,
      criteriaTreeIDs = { 53802, 53803, 54078, 54079, 54080, 54081, 54082, 54083, 54084, 54085, 54086, 54087, 54088, 54089, 54090, 54091, 54092, 54093, 54094, 54095, 54096, 54097, 54098, 54099, 54100, 54101, 54102, 54103, 54104, 54105, 54106, 54107, 54108, 54109, 54110, 54111, 54112, 54113, 54114, 54115, 54116, 54117, 54118, 54119, 62480 },
      criteriaNames = { "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" }, name = "Treasures of Highmountain",
      zoneMapID = MC.MAP.Highmountain, zone = "Highmountain" },
    { source = "suramar", achievementID = 11260, criteriaCount = 58,
      criteriaTreeIDs = { 53809, 54120, 54121, 54122, 54123, 54124, 54125, 54126, 54127, 54128, 54129, 54130, 54131, 54132, 54133, 54134, 54135, 54136, 54137, 54138, 54139, 54140, 54141, 54142, 54143, 54144, 54145, 54146, 54147, 54148, 54149, 54150, 54151, 54152, 54153, 54154, 54155, 54156, 54157, 54158, 54159, 54160, 54161, 54162, 54163, 54164, 54165, 54166, 54167, 54168, 54169, 54170, 54171, 54172, 54173, 54174, 54175, 54176 },
      criteriaNames = { "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" }, name = "Treasures of Suramar",
      zoneMapID = MC.MAP.Suramar, zone = "Suramar" },
    { source = "argus", achievementID = 12074, criteriaCount = 22,
      criteriaTreeIDs = { 61266, 61267, 61268, 61269, 61270, 61271, 61272, 61273, 61274, 61275, 61276, 61528, 61529, 61530, 61531, 61532, 61848, 61849, 61850, 61851, 61852, 61853 },
      criteriaNames = { "Krokul Emergency Cache", "Legion Tower Chest", "Lost Krokul Chest", "Eredar Treasure Cache", "Chest of Ill-Gotten Gains", "Student's Surprising Surplus", "Void-Tinged Chest", "Augari Secret Stash", "Desperate Eredar's Cache", "Shattered House Chest", "Doomseeker's Treasure", "Forgotten Legion Supplies", "Ancient Legion War Cache", "Fel-Bound Chest", "Legion Treasure Hoard", "Timeworn Fel Chest", "Augari-Runed Chest", "Secret Augari Chest", "Augari Goods", "Long-Lost Augari Treasure", "Precious Augari Keepsakes", "Missing Augari Chest" }, name = "Shoot First, Loot Later",
      zoneMapID = MC.MAP.Argus, zone = "Argus" },
})

local SOURCE_KEYS = {
    { "azsuna", "Azsuna" },
    { "valsharah", "Val'sharah" },
    { "stormheim", "Stormheim" },
    { "highmountain", "Highmountain" },
    { "suramar", "Suramar" },
    { "argus", "Argus" },
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
