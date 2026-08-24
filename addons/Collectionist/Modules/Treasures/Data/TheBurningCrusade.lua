local addonName, MC = ...

-- The Burning Crusade treasures. Exact 0 ordered criteria rows.
MC.RegisterContent("tbc", "treasures", {
})

local SOURCE_KEYS = {
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
