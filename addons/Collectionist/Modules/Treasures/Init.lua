local _, MC = ...

local mod = MC.RegisterModule("treasures", {
    label          = "Treasures",
    icon           = "Interface\\Icons\\INV_Misc_Map_01",
    order          = 7,
    collectedKey   = "showCollected",
    collectedLabel = "looted",
    defaults       = {
        showCollected = false,
        collapsed     = {},
    },
    -- QUEST_TURNED_IN catches Gift of the Cycle's altar prerequisite quests
    -- so the tooltip ✓/✗ marks update without needing a /reload.
    events = { "RECEIVED_ACHIEVEMENT_LIST", "ACHIEVEMENT_EARNED", "CRITERIA_UPDATE", "QUEST_TURNED_IN" },
    onEvent = function(m, event)
        MC.ThrottledScan(m)
    end,
    tooltipLines = function(tt, m)
        local r = m.Scanner and m.Scanner.results
        if r and r.totalAll then
            tt:AddLine(format("  Treasures: %d / %d", r.collectedCountAll or 0, r.totalAll), 0.7, 0.7, 0.7)
        end
    end,
    printSummary = MC.MakeSourceSummary("looted", MC.TreasureSourceOrder, MC.TreasureSourceLabels),
})
