local _, MC = ...

local HOUSING_EVENTS = {
    "HOUSING_STORAGE_UPDATED",
    "HOUSING_STORAGE_ENTRY_UPDATED",
    "NEW_HOUSING_ITEM_ACQUIRED",
    "HOUSE_DECOR_ADDED_TO_CHEST",
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
        -- All housing/bag events trigger a rescan
        for _, ev in ipairs(HOUSING_EVENTS) do
            if event == ev then
                MC.ThrottledScan(m)
                return
            end
        end
    end,
    tooltipLines = function(tt, m)
        local r = m.Scanner and m.Scanner.results
        if r and r.total then
            tt:AddLine(format("  Decorations: %d / %d", r.collectedCount, r.total), 0.7, 0.7, 0.7)
        end
    end,
    printSummary = function(m)
        local r = m.Scanner and m.Scanner.results
        if r and r.total then
            print(format("%s [Decorations] %d / %d collected (%d remaining)",
                MC.PREFIX, r.collectedCount, r.total, r.uncollectedCount))
            for _, srcType in ipairs(MC.DecoSourceOrder) do
                local entries = r.bySource[srcType]
                if entries and #entries > 0 then
                    print(format("  %s: %d uncollected", MC.DecoSourceLabels[srcType], #entries))
                end
            end
        end
    end,
})
