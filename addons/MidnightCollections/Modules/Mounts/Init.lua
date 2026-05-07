local _, MC = ...

local mod = MC.RegisterModule("mounts", {
    label          = "Mounts",
    icon           = "Interface\\Icons\\Ability_Mount_RidingHorse",
    order          = 1,
    collectedKey   = "showCollected",
    collectedLabel = "collected",
    defaults       = {
        showCollected = false,
        collapsed     = {},
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
        if r and r.total then
            tt:AddLine(format("  Mounts: %d / %d", r.collectedCount, r.total), 0.7, 0.7, 0.7)
        end
    end,
    printSummary = function(m)
        local r = m.Scanner and m.Scanner.results
        if r and r.total then
            print(format("%s [Mounts] %d / %d collected (%d remaining)",
                MC.PREFIX, r.collectedCount, r.total, r.uncollectedCount))
            for _, srcType in ipairs(MC.MountSourceOrder) do
                local entries = r.bySource[srcType]
                if entries and #entries > 0 then
                    print(format("  %s: %d uncollected", MC.MountSourceLabels[srcType], #entries))
                end
            end
        end
    end,
})
