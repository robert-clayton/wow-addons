local addonName, MC = ...

-- Legion zone rares and special encounters. Exact 185 ordered criteria/entity rows.
MC.RegisterContent("legion", "rares", {
    { source = "azsuna", achievementID = 11261, criteriaCount = 26,
      criteriaTreeIDs = { 53797, 53798, 53799, 53800, 53810, 53811, 53812, 53813, 53814, 53815, 53816, 53817, 53818, 53820, 53821, 53819, 53822, 53823, 53824, 53825, 53826, 53827, 53934, 53935, 53936, 53939 },
      criteriaNPCIDs = { 89650, 89816, 89846, 89850, 89865, 89884, 90057, 90164, 90217, 90244, 90505, 90803, 90901, 91113, 91187, 91100, 91579, 105938, 106990, 107127, 109504, 112637, 107657, 107113, 107269, 89016 },
      criteriaObjectIDs = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false }, name = "Adventurer of Azsuna",
      zoneMapID = MC.MAP.Azsuna, zone = "Azsuna" },
    { source = "valsharah", achievementID = 11262, criteriaCount = 20,
      criteriaTreeIDs = { 53829, 53830, 53831, 53832, 53833, 53834, 53835, 53836, 53837, 53838, 53840, 53841, 53842, 53843, 53844, 53845, 53846, 53847, 53848, 53849 },
      criteriaNPCIDs = { 92117, 92180, 92423, 92965, 93030, 93205, 92334, false, 94414, 94485, 95123, 95221, 95318, 97504, 97517, 98241, 109708, 110562, false, 93679 },
      criteriaObjectIDs = { false, false, false, false, false, false, false, 242350, false, false, false, false, false, false, false, false, false, false, 241128, false }, name = "Adventurer of Val'sharah",
      zoneMapID = MC.MAP.Valsharah, zone = "Val'sharah" },
    { source = "stormheim", achievementID = 11263, criteriaCount = 25,
      criteriaTreeIDs = { 53851, 53852, 53853, 53854, 53855, 53856, 53857, 53858, 53860, 53861, 53862, 53863, 53864, 53865, 53866, 53867, 53868, 53869, 53870, 53871, 53872, 53873, 53874, 53875, 53933 },
      criteriaNPCIDs = { 91529, 91795, 91803, 91874, 91892, 92040, 92152, 92599, 92152, 91803, 92685, 92751, 92763, 93166, 93371, 93401, 94413, 97630, 98188, 98268, 98421, 98503, 107926, 110363, 90139 },
      criteriaObjectIDs = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false }, name = "Adventurer of Stormheim",
      zoneMapID = MC.MAP.Stormheim, zone = "Stormheim" },
    { source = "highmountain", achievementID = 11264, criteriaCount = 22,
      criteriaTreeIDs = { 53898, 53890, 53891, 53886, 53880, 53885, 53878, 53900, 53883, 53884, 53879, 53888, 53889, 53937, 53894, 53896, 53881, 53897, 53892, 53882, 53893, 53895 },
      criteriaNPCIDs = { 101077, false, 97933, 97345, 96590, 97326, 95872, false, 97203, false, 96410, 97449, 97579, 98299, false, false, 96621, 100495, 98024, 97093, 98311, 98890 },
      criteriaObjectIDs = { false, 244628, false, false, false, false, false, 240353, false, 244473, false, false, false, false, 244446, 245479, false, false, false, false, false, false }, name = "Adventurer of Highmountain",
      zoneMapID = MC.MAP.Highmountain, zone = "Highmountain" },
    { source = "suramar", achievementID = 11265, criteriaCount = 32,
      criteriaTreeIDs = { 53902, 53903, 53904, 53905, 53906, 53907, 53908, 53909, 53910, 53911, 53912, 53913, 53914, 53915, 53916, 53917, 53918, 53919, 53920, 53921, 53922, 53923, 53924, 53925, 53926, 53927, 53928, 53929, 53930, 53931, 53932, 53938 },
      criteriaNPCIDs = { 99610, 99792, 100864, 103183, 103214, 103223, 103575, 103841, 105547, 106351, 107846, 109054, 109954, 110024, 110340, 110438, 110577, 110656, 110726, 110824, 110832, 110870, 110944, 111007, 111197, 111329, 111649, 111651, 111653, 112497, 112802, 102303 },
      criteriaObjectIDs = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false }, name = "Adventurer of Suramar",
      zoneMapID = MC.MAP.Suramar, zone = "Suramar" },
    { source = "argus", achievementID = 12078, criteriaCount = 60,
      criteriaTreeIDs = { 61349, 61350, 61351, 61353, 61354, 61355, 61356, 61357, 61358, 61359, 61360, 61361, 61363, 61364, 61365, 61366, 61367, 61368, 61369, 61370, 61371, 61372, 61373, 61374, 61375, 61376, 61377, 61378, 61379, 61380, 61381, 61382, 61383, 61384, 61385, 61386, 61387, 61388, 61389, 61390, 61391, 61392, 61393, 61394, 61395, 61396, 61397, 61398, 61399, 61400, 61401, 61402, 61403, 61404, 61405, 61406, 61407, 61408, 61409, 61410 },
      criteriaNPCIDs = { 127705, 127118, 127376, 122838, 123689, 122999, 122958, 122947, 120393, 127581, 127700, 127703, 127706, 124804, 125388, 125479, 125820, 126199, 126115, 126040, 125824, 126419, 122912, 122911, 124775, 123464, 126815, 126852, 126860, 126862, 126864, 126865, 126866, 126867, 126868, 126869, 126885, 126887, 126889, 126896, 126898, 126899, 124440, 125497, 125498, 126900, 126908, 126910, 126912, 126913, 126338, 127288, 127300, 127291, 126254, 127090, 127084, 127096, 126946, 126208 },
      criteriaObjectIDs = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false }, name = "Commander of Argus",
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
    MC.RareSourceOrder = MC.RareSourceOrder or {}
    MC.RareSourceLabels = MC.RareSourceLabels or {}
    for i, pair in ipairs(SOURCE_KEYS) do table.insert(MC.RareSourceOrder, i, pair[1]); MC.RareSourceLabels[pair[1]] = pair[2] end
end
if MC.RareSourceOrder then merge() else
    local frame = CreateFrame("Frame"); frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, _, name) if name ~= addonName then return end; self:UnregisterEvent("ADDON_LOADED"); self:SetScript("OnEvent", nil); merge() end)
end
