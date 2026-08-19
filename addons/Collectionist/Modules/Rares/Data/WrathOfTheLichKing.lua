local addonName, MC = ...

-- Wrath of the Lich King zone rares. Exact 23 ordered criteria/entity rows.
MC.RegisterContent("wrath", "rares", {
    { source = "northrend", achievementID = 2257, criteriaCount = 23,
      criteriaTreeIDs = { 8950, 8951, 8952, 8965, 8961, 8953, 8946, 8943, 8944, 8945, 8962, 8964, 8947, 8948, 8954, 8963, 8955, 8956, 8949, 8957, 8958, 8959, 8960 },
      criteriaNPCIDs = { 32517, 32501, 32495, 32357, 32358, 32361, 32377, 32386, 32398, 32400, 32409, 32417, 32422, 32429, 32438, 32447, 32471, 32475, 32481, 32485, 32630, 32500, 32487 }, name = "Frostbitten",
      zoneMapID = MC.MAP.Northrend, zone = "Northrend" },
})

local SOURCE_KEYS = {
    { "n", "o" },
    { "N", "o" },
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
