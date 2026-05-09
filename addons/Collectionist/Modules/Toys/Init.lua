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
        if r and r.total then
            tt:AddLine(format("  Toys: %d / %d", r.collectedCount, r.total), 0.7, 0.7, 0.7)
        end
    end,
    printSummary = function(m)
        local r = m.Scanner and m.Scanner.results
        if r and r.total then
            print(format("%s [Toys] %d / %d collected (%d remaining)",
                MC.PREFIX, r.collectedCount, r.total, r.uncollectedCount))
            for _, srcType in ipairs(MC.ToySourceOrder) do
                local entries = r.bySource[srcType]
                if entries and #entries > 0 then
                    print(format("  %s: %d uncollected", MC.ToySourceLabels[srcType], #entries))
                end
            end
        end
    end,
})
