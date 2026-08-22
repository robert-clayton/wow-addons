local addonName, MC = ...

-- Dragonflight zone rares. Exact 197 ordered criteria/NPC rows.
MC.RegisterContent("df", "rares", {
    { source = "waking_shores", achievementID = 16676, criteriaCount = 33,
      criteriaTreeIDs = { 139711, 139712, 139713, 139714, 139715, 139716, 139717, 139718, 139719, 139720, 139721, 139722, 139723, 139724, 139725, 139726, 139729, 146454, 139727, 139728, 139730, 139731, 139732, 139733, 139734, 139735, 139736, 139737, 139738, 139739, 141026, 141027, 141043 },
      criteriaNPCIDs = { 196056, 193256, 187945, 193181, 199645, 192738, 193217, 193148, 193135, 193228, 193118, 193120, 193132, 186827, 193152, 193154, 192362, 192362, 193134, 193198, 186859, 190985, 189822, 193266, 186783, 187598, 187886, 190986, 190991, 193232, 187306, 193271, 193175 }, name = "Adventurer of The Waking Shores",
      zoneMapID = MC.MAP.WakingShores, zone = "Waking Shores" },
    { source = "ohnahran_plains", achievementID = 16677, criteriaCount = 35,
      criteriaTreeIDs = { 139741, 139742, 139743, 139744, 139745, 139746, 139747, 139748, 139749, 139750, 139751, 139752, 139753, 139754, 139755, 139756, 139757, 139758, 139759, 139760, 139761, 139762, 139763, 139764, 139765, 139766, 139767, 139768, 139769, 139770, 139771, 139772, 139773, 139774, 139775 },
      criteriaNPCIDs = { 193165, 193136, 193142, 193188, 193209, 197009, 189652, 196010, 193173, 193227, 193123, 193212, 193235, 193170, 192045, 192020, 193140, 193215, 187559, 187219, 187781, 188095, 188124, 188451, 191842, 191950, 195204, 192364, 192453, 192557, 195186, 195223, 195409, 196334, 196350 }, name = "Adventurer of the Ohn'ahran Plains",
      zoneMapID = MC.MAP.OhnahranPlains, zone = "Ohn'ahran Plains" },
    { source = "azure_span", achievementID = 16678, criteriaCount = 32,
      criteriaTreeIDs = { 139777, 139778, 139779, 139780, 139781, 139782, 139783, 139784, 139785, 139786, 139787, 139788, 139789, 139790, 139791, 139792, 139794, 139795, 139796, 139797, 139798, 139799, 139800, 139802, 139803, 139805, 139806, 139807, 139808, 139809, 139810, 139811 },
      criteriaNPCIDs = { 193632, 193157, 194270, 198004, 191356, 193201, 194392, 193698, 194210, 193116, 193225, 193259, 190244, 193149, 193251, 193269, 193196, 193691, 193706, 193708, 193710, 193735, 193634, 197557, 193178, 193238, 197344, 197353, 197354, 197356, 197371, 197411 }, name = "Adventurer of The Azure Span",
      zoneMapID = MC.MAP.AzureSpan, zone = "The Azure Span" },
    { source = "thaldraszus", achievementID = 16679, criteriaCount = 22,
      criteriaTreeIDs = { 139820, 139821, 139822, 139823, 139824, 139825, 139826, 139827, 139828, 139829, 139830, 139831, 139832, 139833, 139834, 139835, 139836, 139837, 139838, 139839, 139840, 139841 },
      criteriaNPCIDs = { 193143, 193126, 193128, 193130, 193125, 193688, 193246, 193210, 193258, 193146, 193234, 193240, 193220, 193176, 193666, 193161, 183984, 193663, 191305, 193658, 193241, 193664 }, name = "Adventurer of Thaldraszus",
      zoneMapID = MC.MAP.Thaldraszus, zone = "Thaldraszus" },
    { source = "forbidden_reach", achievementID = 17524, criteriaCount = 30,
      criteriaTreeIDs = { 143673, 143674, 143675, 143676, 143677, 143678, 143679, 143680, 143681, 143682, 143683, 143684, 143685, 143686, 143687, 143688, 143689, 143690, 143691, 143692, 143693, 143694, 143695, 143696, 143697, 143698, 143699, 143700, 143701, 144278 },
      criteriaNPCIDs = { 200584, 200537, 200579, 200600, 200610, 200681, 200717, 200721, 200885, 200904, 201181, 201013, 200960, 200956, 200978, 200911, 200619, 200620, 200621, 200622, 200722, 200725, 200730, 200737, 200738, 200739, 200740, 200742, 200743, 203353 }, name = "Adventurer of the Forbidden Reach",
      zoneMapID = MC.MAP.ForbiddenReach, zone = "The Forbidden Reach" },
    { source = "zaralek_cavern", achievementID = 17783, criteriaCount = 21,
      criteriaTreeIDs = { 144860, 144861, 144862, 144863, 144864, 144865, 144866, 144867, 144869, 144870, 144871, 144872, 144873, 144874, 144877, 144878, 144880, 144881, 144882, 144883, 144884 },
      criteriaNPCIDs = { 203515, 203468, 203621, 204093, 203664, 203660, 203592, 203477, 203627, 203646, 203625, 203466, 203618, 203462, 200111, 203521, 203643, 203480, 203662, 203593, 201029 }, name = "Adventurer of Zaralek Cavern",
      zoneMapID = MC.MAP.ZaralekCavern, zone = "Zaralek Cavern" },
    { source = "emerald_dream", achievementID = 19316, criteriaCount = 24,
      criteriaTreeIDs = { 151262, 151263, 151264, 151265, 151266, 151267, 151268, 151269, 151270, 151271, 151272, 151273, 151274, 151275, 151276, 151277, 151278, 151279, 151280, 151281, 151282, 151283, 151284, 153296 },
      criteriaNPCIDs = { 209113, 209893, 209898, 209936, 209929, 209902, 209365, 209620, 209909, 209913, 209911, 209919, 210111, 210045, 210046, 210047, 210050, 210051, 208658, 210064, 210070, 210075, 210161, 210508 }, name = "Adventurer of the Emerald Dream",
      zoneMapID = MC.MAP.EmeraldDream, zone = "Emerald Dream" },
})

local SOURCE_KEYS = {
    { "waking_shores", "Waking Shores" },
    { "ohnahran_plains", "Ohn'ahran Plains" },
    { "azure_span", "The Azure Span" },
    { "thaldraszus", "Thaldraszus" },
    { "forbidden_reach", "The Forbidden Reach" },
    { "zaralek_cavern", "Zaralek Cavern" },
    { "emerald_dream", "Emerald Dream" },
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
