local _, MC = ...

local mod = MC.RegisterModule("rares", {
    label          = "Rares",
    -- Crossed-blades icon evokes "hunt and slay rares" without using the same
    -- visual vocabulary as the achievement journal (which uses a wreath).
    icon           = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    order          = 6,
    collectedKey   = "showCollected",
    collectedLabel = "defeated",
    defaults       = {
        showCollected = false,
        collapsed     = {},
    },
    events = { "ACHIEVEMENT_EARNED", "CRITERIA_UPDATE" },
    onEvent = function(m, event)
        if event == "ACHIEVEMENT_EARNED" or event == "CRITERIA_UPDATE" then
            MC.ThrottledScan(m)
        end
    end,
    tooltipLines = function(tt, m)
        local r = m.Scanner and m.Scanner.results
        if r and r.total then
            tt:AddLine(format("  Rares: %d / %d", r.collectedCount, r.total), 0.7, 0.7, 0.7)
        end
    end,
    printSummary = function(m)
        local r = m.Scanner and m.Scanner.results
        if r and r.total then
            print(format("%s [Rares] %d / %d defeated (%d remaining)",
                MC.PREFIX, r.collectedCount, r.total, r.uncollectedCount))
            for _, srcType in ipairs(MC.RareSourceOrder) do
                local entries = r.bySource[srcType]
                if entries and #entries > 0 then
                    print(format("  %s: %d remaining", MC.RareSourceLabels[srcType], #entries))
                end
            end
        end
    end,
})
