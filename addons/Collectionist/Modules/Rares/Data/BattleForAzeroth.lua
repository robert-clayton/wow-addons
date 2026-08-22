local addonName, MC = ...

-- Battle for Azeroth zone rares and special encounters. Exact 254 ordered criteria/entity rows.
MC.RegisterContent("bfa", "rares", {
    { source = "tiragarde_sound", achievementID = 12939, criteriaCount = 32,
      criteriaTreeIDs = { 69152, 69153, 69154, 69155, 69156, 69157, 69158, 69159, 69160, 69161, 69162, 69163, 69164, 69165, 69166, 69167, 69168, 69169, 69170, 69171, 69172, 69173, 69174, 69175, 69176, 69177, 69178, 69179, 69180, 69181, 69182, 69183 },
      criteriaNPCIDs = { 132182, 129181, 132068, 132086, 139145, 130508, 132088, 139152, 132211, 132127, 139233, 131520, 134106, 139290, 137183, 131252, 139205, 131262, 132179, 139278, 127290, 139287, 139285, 132280, 139135, 139280, 133356, 139289, 131389, 139235, 132076, 131984 },
      criteriaObjectIDs = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false }, name = "Adventurer of Tiragarde Sound",
      zoneMapID = MC.MAP.TiragardeSound, zone = "Tiragarde Sound" },
    { source = "stormsong_valley", achievementID = 12940, criteriaCount = 35,
      criteriaTreeIDs = { 69076, 69078, 69079, 69080, 69081, 69082, 69083, 69084, 69085, 69086, 69087, 69088, 69098, 69099, 69100, 69101, 69102, 69103, 69104, 69105, 69106, 69107, 69135, 69148, 69149, 69150, 69184, 69185, 69186, 69187, 69188, 69189, 69190, 69192, 69191 },
      criteriaNPCIDs = { 141175, 140997, 138938, 139328, 136189, 134884, 139319, 137025, 132007, 142088, 141029, 131404, 141286, 139298, 141059, 139385, 140938, 139968, 136183, 134897, 135939, false, 141226, 141088, 141039, 130897, 129803, 141143, 130079, 138963, 141239, 139988, 139980, 140925, 141043 },
      criteriaObjectIDs = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, 286952, false, false, false, false, false, false, false, false, false, false, false, false, false }, name = "Adventurer of Stormsong Valley",
      zoneMapID = MC.MAP.StormsongValley, zone = "Stormsong Valley" },
    { source = "drustvar", achievementID = 12941, criteriaCount = 33,
      criteriaTreeIDs = { 69040, 69041, 69042, 69043, 69045, 69046, 69047, 69048, 69049, 69051, 69052, 69053, 69054, 69055, 69056, 69057, 69058, 69059, 69060, 69061, 69062, 69063, 69064, 69065, 69066, 69067, 69068, 69069, 69070, 69071, 69072, 69073, 69074 },
      criteriaNPCIDs = { 124548, 125453, 127333, 127651, 126621, 127844, 127877, false, 129904, 128707, 128973, false, 127129, 129835, 129805, 129950, 129995, 130138, 130143, 132319, 134213, 134706, 134754, 135796, 137529, 137824, 137825, 138618, 138675, 138863, 138871, 139321, 139322 },
      criteriaObjectIDs = { false, false, false, false, false, false, false, 277333, false, false, false, 277897, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false }, name = "Adventurer of Drustvar",
      zoneMapID = MC.MAP.Drustvar, zone = "Drustvar" },
    { source = "nazmir", achievementID = 12942, criteriaCount = 32,
      criteriaTreeIDs = { 68700, 68701, 68702, 68703, 68704, 68705, 68706, 68707, 68708, 68709, 68710, 68711, 68712, 68713, 68714, 68715, 68716, 68717, 68718, 68719, 68720, 68721, 68722, 68723, 68725, 68726, 68727, 68728, 68729, 68730, 68731, 68732 },
      criteriaNPCIDs = { 125250, 134298, 134293, 126635, 128965, 129005, 134296, 126187, 125232, 127001, 121242, 128426, 128974, 124399, 133373, 133527, 124397, 125214, 134295, 126142, 127820, 127873, 126460, 126056, false, 126926, 126907, 133531, 129657, 133812, 133539, 128935 },
      criteriaObjectIDs = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, 282666, false, false, false, false, false, false, false }, name = "Adventurer of Nazmir",
      zoneMapID = MC.MAP.Nazmir, zone = "Nazmir" },
    { source = "voldun", achievementID = 12943, criteriaCount = 28,
      criteriaTreeIDs = { 68907, 68908, 68909, 68910, 68911, 68912, 68913, 68914, 68915, 68916, 68917, 68918, 68919, 68920, 68921, 68922, 68923, 68924, 68925, 68926, 68927, 68928, 68929, 68930, 68931, 68932, 68933, 68934 },
      criteriaNPCIDs = { 135852, 130439, 128553, 128497, 129476, 136393, 136346, 124722, 136335, 128674, 130443, 129283, 136341, 128686, 137681, 128951, 136340, 127776, 136336, 136338, 134571, 134745, 136304, 130401, 129180, 134638, 134625, 129411 },
      criteriaObjectIDs = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false }, name = "Adventurer of Vol'dun",
      zoneMapID = MC.MAP.Voldun, zone = "Vol'dun" },
    { source = "zuldazar", achievementID = 12944, criteriaCount = 23,
      criteriaTreeIDs = { 69199, 69200, 69201, 69202, 69215, 69216, 69217, 69218, 69219, 69220, 69221, 69222, 69223, 69204, 69205, 69207, 69208, 69209, 69210, 69211, 69212, 69213, 69214 },
      criteriaNPCIDs = { 129961, 129954, 136428, 136413, 131476, 131233, 129343, 128699, 127939, 126637, 120899, 124185, 122004, 134760, 134738, 134048, 133842, 134782, 133190, 133155, 132244, 131718, 131687 },
      criteriaObjectIDs = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false }, name = "Adventurer of Zuldazar",
      zoneMapID = MC.MAP.Zuldazar, zone = "Zuldazar" },
    { source = "mechagon", achievementID = 13470, criteriaCount = 36,
      criteriaTreeIDs = { 79764, 79765, 79766, 79769, 79770, 79771, 79772, 79773, 79774, 79775, 79776, 79777, 79778, 79779, 79781, 79782, 79783, 79784, 79785, 79787, 79788, 79803, 79804, 79816, 79811, 79812, 79813, 79814, 79815, 79817, 80320, 80321, 80390, 80392, 80418, 80842 },
      criteriaNPCIDs = { 151124, 151625, 151672, 151684, 151702, 150575, 151934, 152007, 151884, 151202, 151569, 151296, 152001, 151308, 151940, 150937, 153000, 152182, 151933, 152569, 150342, 153206, 153205, 152764, 153200, 152113, 153226, 153228, 151627, false, 154153, 154225, 154701, 154739, 155060, 155583 },
      criteriaObjectIDs = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, 322020, false, false, false, false, false, false }, name = "Rest In Pistons",
      zoneMapID = MC.MAP.Mechagon, zone = "Mechagon" },
    { source = "nazjatar", achievementID = 13691, criteriaCount = 35,
      criteriaTreeIDs = { 80613, 80614, 80615, 80618, 80619, 80621, 80622, 80623, 80624, 80625, 80626, 80627, 80628, 80629, 80630, 80631, 80632, 80633, 80634, 80635, 80637, 80638, 80639, 80640, 80641, 80642, 80643, 80644, 80645, 80647, 80648, 80649, 80650, 80651, 80652 },
      criteriaNPCIDs = { 152415, 152416, 152794, 152361, 152712, 152464, 152556, 152756, 152291, 152414, 152555, 152553, 152448, 152567, 152323, 144644, 152465, 152397, 152681, 152682, 151870, 152795, 152548, 152545, 152542, 152552, 153658, 152359, 152290, 153898, 153928, 154148, 152360, 152568, 151719 },
      criteriaObjectIDs = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false }, name = "I Thought You Said They'd Be Rare?",
      zoneMapID = MC.MAP.Nazjatar, zone = "Nazjatar" },
})

local SOURCE_KEYS = {
    { "tiragarde", "Tiragarde Sound" },
    { "stormsong", "Stormsong Valley" },
    { "drustvar", "Drustvar" },
    { "nazmir", "Nazmir" },
    { "voldun", "Vol'dun" },
    { "zuldazar", "Zuldazar" },
    { "mechagon", "Mechagon" },
    { "nazjatar", "Nazjatar" },
}
local function merge()
    MC.RareSourceOrder = MC.RareSourceOrder or {}
    MC.RareSourceLabels = MC.RareSourceLabels or {}
    for i, pair in ipairs(SOURCE_KEYS) do table.insert(MC.RareSourceOrder, i, pair[1]); MC.RareSourceLabels[pair[1]] = pair[2] end
end
if MC.RareSourceOrder then merge() else
    local frame = CreateFrame("Frame"); frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, _, name) if name ~= addonName then return end; self:UnregisterEvent("ADDON_LOADED"); self:SetScript("OnEvent", nil); merge() end)
end
