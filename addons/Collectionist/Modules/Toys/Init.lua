local _, MC = ...

local mod = MC.RegisterModule("toys", {
    label          = "Toys",
    icon           = "Interface\\Icons\\Trade_Archaeology_ChestOfTinyGlassAnimals",
    order          = 4,
    collectedKey   = "showCollected",
    collectedLabel = "collected",
    defaults       = {
        showCollected   = false,
        hideUnavailable = true,
        hideTradingPost = false,
        collapsed       = {},
    },
    -- NEW_TOY_ADDED fires on collect; TOYS_UPDATED catches filter / journal
    -- updates we'd otherwise miss. Both go through ThrottledScan.
    events = { "NEW_TOY_ADDED", "TOYS_UPDATED" },
    onEvent = function(m, event)
        if event == "NEW_TOY_ADDED" or event == "TOYS_UPDATED" then
            MC.ThrottledScan(m)
        end
    end,
    tooltipLines = function(tt, m)
        local r = m.Scanner and m.Scanner.results
        if r and r.totalAll then
            tt:AddLine(format("  Toys: %d / %d", r.collectedCountAll or 0, r.totalAll), 0.7, 0.7, 0.7)
        end
    end,
    printSummary = MC.MakeSourceSummary("collected", MC.ToySourceOrder, MC.ToySourceLabels),
})
