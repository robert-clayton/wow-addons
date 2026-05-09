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
    events = { "ACHIEVEMENT_EARNED", "CRITERIA_UPDATE", "QUEST_TURNED_IN" },
    onEvent = function(m, event)
        MC.ThrottledScan(m)
    end,
    tooltipLines = function(tt, m)
        local r = m.Scanner and m.Scanner.results
        if r and r.total then
            tt:AddLine(format("  Treasures: %d / %d", r.collectedCount, r.total), 0.7, 0.7, 0.7)
        end
    end,
    printSummary = function(m)
        local r = m.Scanner and m.Scanner.results
        if r and r.total then
            print(format("%s [Treasures] %d / %d looted (%d remaining)",
                MC.PREFIX, r.collectedCount, r.total, r.uncollectedCount))
            for _, srcType in ipairs(MC.TreasureSourceOrder) do
                local entries = r.bySource[srcType]
                if entries and #entries > 0 then
                    print(format("  %s: %d remaining", MC.TreasureSourceLabels[srcType], #entries))
                end
            end
        end
    end,
})
