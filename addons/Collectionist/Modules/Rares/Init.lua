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
    events = { "RECEIVED_ACHIEVEMENT_LIST", "ACHIEVEMENT_EARNED", "CRITERIA_UPDATE" },
    onEvent = function(m, event)
        if event == "RECEIVED_ACHIEVEMENT_LIST"
           or event == "ACHIEVEMENT_EARNED" or event == "CRITERIA_UPDATE" then
            MC.ThrottledScan(m, MC.LAZY_SCAN_EVENTS[event])
        end
    end,
    tooltipLines = function(tt, m)
        local r = m.Scanner and m.Scanner.results
        if r and r.totalAll then
            tt:AddLine(format("  Rares: %d / %d", r.collectedCountAll or 0, r.totalAll), 0.7, 0.7, 0.7)
        end
    end,
    printSummary = MC.MakeSourceSummary("defeated", MC.RareSourceOrder, MC.RareSourceLabels),
})
