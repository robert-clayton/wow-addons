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
    events = { "RECEIVED_ACHIEVEMENT_LIST", "ACHIEVEMENT_EARNED", "CRITERIA_UPDATE" },
    onEvent = function(m, event)
        MC.ThrottledScan(m)
    end,
    tooltipLines = function(tt, m)
        local r = m.Scanner and m.Scanner.results
        if r and r.totalAll then
            tt:AddLine(format("  Achievements: %d / %d", r.collectedCountAll or 0, r.totalAll), 0.7, 0.7, 0.7)
        end
    end,
    printSummary = MC.MakeSourceSummary("completed", MC.AchievementSourceOrder, MC.AchievementSourceLabels),
})
