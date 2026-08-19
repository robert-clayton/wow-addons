local _, MC = ...

local mod = MC.RegisterModule("mounts", {
    label          = "Mounts",
    icon           = "Interface\\Icons\\Ability_Mount_RidingHorse",
    order          = 1,
    collectedKey   = "showCollected",
    collectedLabel = "collected",
    defaults       = {
        showCollected   = false,
        hideUnavailable = true,
        collapsed       = {},
    },
    events = { "NEW_MOUNT_ADDED", "COMPANION_LEARNED", "PLAYER_ENTERING_WORLD" },
    onEvent = function(m, event)
        if event == "NEW_MOUNT_ADDED" or event == "COMPANION_LEARNED"
            or event == "PLAYER_ENTERING_WORLD" then
            MC.ThrottledScan(m)
        end
    end,
    tooltipLines = function(tt, m)
        local r = m.Scanner and m.Scanner.results
        if r and r.totalAll then
            tt:AddLine(format("  Mounts: %d / %d", r.collectedCountAll or 0, r.totalAll), 0.7, 0.7, 0.7)
        end
    end,
    printSummary = MC.MakeSourceSummary("collected", MC.MountSourceOrder, MC.MountSourceLabels),
})
