local addonName, MC = ...

-- Mists of Pandaria zone rares. Exact 104 ordered criteria/entity rows.
MC.RegisterContent("mop", "rares", {
    { source = "pandaria", achievementID = 7439, criteriaCount = 56,
      criteriaTreeIDs = { 27397, 27398, 27399, 27400, 27401, 27402, 27403, 27404, 27405, 27406, 27407, 27408, 27409, 27410, 27411, 27412, 27413, 27414, 27415, 27416, 27417, 27418, 27419, 27420, 27421, 27422, 27423, 27424, 27425, 27426, 27427, 27428, 27429, 27430, 27431, 27432, 27433, 27434, 27435, 27436, 27437, 27438, 29389, 29390, 29391, 29392, 29393, 29394, 29395, 27439, 27440, 27441, 27442, 27443, 27444, 27445 },
      criteriaNPCIDs = { 50823, 50828, 50830, 50831, 50832, 50836, 50840, 50750, 50766, 50768, 50769, 50772, 50776, 50780, 50363, 50364, 50388, 50733, 50734, 50739, 50749, 50338, 50339, 50340, 50341, 50344, 50347, 50349, 50350, 50351, 50352, 50354, 50355, 50356, 50359, 50808, 50811, 50816, 50817, 50820, 50821, 50822, 50782, 50783, 50787, 50789, 50791, 50805, 50806, 51078, 51059, 50331, 50332, 50333, 50334, 50336 }, name = "Glorious!",
      zoneMapID = MC.MAP.Pandaria, zone = "Pandaria" },
    { source = "isleofthunder", achievementID = 7932, criteriaCount = 6,
      criteriaTreeIDs = { 31184, 31185, 31187, 31188, 31190, 31191 },
      criteriaNPCIDs = { 68321, 68318, 68320, 68317, 68322, 68319 }, name = "I'm In Your Base, Killing Your Dudes",
      zoneMapID = MC.MAP.IsleOfThunder, zone = "Isle of Thunder" },
    { source = "isleofthunder", achievementID = 8103, criteriaCount = 10,
      criteriaTreeIDs = { 31966, 31967, 31968, 31969, 31970, 31971, 31972, 31973, 31974, 31975 },
      criteriaNPCIDs = { 50358, 69664, 69996, 69997, 69998, 69999, 70000, 70001, 70002, 70003 }, name = "Champions of Lei Shen",
      zoneMapID = MC.MAP.IsleOfThunder, zone = "Isle of Thunder" },
    { source = "timeless", achievementID = 8714, criteriaCount = 32,
      criteriaTreeIDs = { 34117, 34118, 34119, 34120, 34121, 34122, 34123, 34124, 34125, 34126, 34127, 34128, 34129, 34136, 34132, 34133, 34135, 34139, 34409, 34130, 34142, 34144, 34146, 34131, 34143, 34145, 34134, 34138, 34140, 34137, 34387, 34388 },
      criteriaNPCIDs = { 73158, 73160, 73161, 72909, 72245, 71919, 72193, 72045, 71864, 73854, 72048, 72769, 73277, 72775, 73282, 72808, 73166, 73163, 73704, 73157, 73170, 73169, 73171, 73175, 73173, 73172, 73167, 72970, 73279, 73281, 73174, 73666 }, name = "Timeless Champion",
      zoneMapID = MC.MAP.TimelessIsle, zone = "Timeless Isle" },
})

local SOURCE_KEYS = {
    { "pandaria", "Pandaria" },
    { "isleofthunder", "Isle of Thunder" },
    { "timeless", "Timeless Isle" },
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
