local _, MC = ...

-- Only events that actually change the player's *known* decor list.
-- HOUSING_STORAGE_UPDATED / _ENTRY_UPDATED / HOUSE_DECOR_ADDED_TO_CHEST
-- fire on every chest-stack change, which retriggers a full 260-entry rescan
-- with hundreds of C_HousingCatalog calls — they don't add information.
local HOUSING_EVENTS = {
    "HOUSING_DECOR_KNOWN_CHANGED",
    "NEW_HOUSING_ITEM_ACQUIRED",
    "BAG_UPDATE_DELAYED",
}

local mod = MC.RegisterModule("decorations", {
    label          = "Decorations",
    icon           = "Interface\\Icons\\INV_Misc_Rune_01",
    order          = 3,
    collectedKey   = "showCollected",
    collectedLabel = "collected",
    defaults       = {
        showCollected   = false,
        hideTradingPost = false,
        collapsed       = {},
    },
    events = HOUSING_EVENTS,
    onEvent = function(m, event)
        if event == "BAG_UPDATE_DELAYED" then
            -- 3s throttle: chatty during raid/loot
            MC.ThrottledScan(m, 3)
        else
            MC.ThrottledScan(m)
        end
    end,
    tooltipLines = function(tt, m)
        local r = m.Scanner and m.Scanner.results
        if r and r.totalAll then
            tt:AddLine(format("  Decorations: %d / %d", r.collectedCountAll or 0, r.totalAll), 0.7, 0.7, 0.7)
        end
    end,
    printSummary = MC.MakeSourceSummary("collected", MC.DecoSourceOrder, MC.DecoSourceLabels),
})
