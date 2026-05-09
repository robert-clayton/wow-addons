local _, MC = ...

local mod = MC.RegisterModule("achievements", {
    label          = "Achievements",
    icon           = "Interface\\Icons\\Achievement_GuildPerk_HastyHearth",
    order          = 8,
    collectedKey   = "showCollected",
    collectedLabel = "completed",
    defaults       = {
        showCollected = false,
        collapsed     = {},
    },
    -- ACHIEVEMENT_EARNED + CRITERIA_UPDATE catch live progress as the
    -- player picks up glyphs / scopes vistas without a /reload.
    events = { "ACHIEVEMENT_EARNED", "CRITERIA_UPDATE" },
    onEvent = function(m, event)
        MC.ThrottledScan(m)
    end,
    tooltipLines = function(tt, m)
        local r = m.Scanner and m.Scanner.results
        if r and r.total then
            tt:AddLine(format("  Achievements: %d / %d", r.collectedCount, r.total), 0.7, 0.7, 0.7)
        end
    end,
    printSummary = function(m)
        local r = m.Scanner and m.Scanner.results
        if r and r.total then
            print(format("%s [Achievements] %d / %d completed (%d remaining)",
                MC.PREFIX, r.collectedCount, r.total, r.uncollectedCount))
            for _, srcType in ipairs(MC.AchievementSourceOrder) do
                local entries = r.bySource[srcType]
                if entries and #entries > 0 then
                    print(format("  %s: %d remaining", MC.AchievementSourceLabels[srcType], #entries))
                end
            end
        end
    end,
})
