local _, MC = ...

local mod = MC.modulesByKey["mounts"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

function Scanner:Scan()
    if not MC.MountData then return end

    -- `total` / `collectedCount` are filter-scoped (what the UI shows).
    -- `totalAll` / `collectedCountAll` ignore the expansion filter so
    -- Sharing broadcasts stay account-wide regardless of what the
    -- player has selected on the panel.
    -- byExpansion[expKey] = { total, collected } feeds the per-expansion
    -- 'e' broadcast and the inspector's filter-aware peer columns.
    --
    -- score / legacyScore / legacyCount feed the Collection Score
    -- system. Items with `unavailable = true` go into the legacy bucket
    -- (count + score tracked separately) and are excluded from the
    -- main score so retired content doesn't lock newer collectors out.
    local result = {
        total              = 0,
        collectedCount     = 0,
        uncollectedCount   = 0,
        totalAll           = 0,
        collectedCountAll  = 0,
        byExpansion        = {},
        score              = 0,
        legacyScore        = 0,
        legacyCount        = 0,
        bySource           = {},
        collected          = {},
    }

    local playerFaction = UnitFactionGroup("player")
    local hasJournal = C_MountJournal and C_MountJournal.GetMountInfoByID
    for _, group in ipairs(MC.MountData) do
        local visible = MC.IsGroupVisible(group)
        for _, mount in ipairs(group.mounts) do
            -- PvP faction filtering: skip mounts not for this player's faction
            if not (mount.faction and mount.faction ~= playerFaction) then
                local isCollected = false
                local icon = nil
                local mountName = mount.name

                if hasJournal and mount.mountID and mount.mountID > 0 then
                    local name, _, mountIcon, _, _, _, _, _, _, _, collected
                        = C_MountJournal.GetMountInfoByID(mount.mountID)
                    if collected ~= nil then isCollected = collected end
                    if mountIcon and mountIcon ~= 0 then icon = mountIcon end
                    if name and name ~= "" then mountName = name end
                end

                -- Hide unavailable items the player doesn't already own
                -- when the toggle is on (default). Users can flip it off to
                -- see what they missed.
                local hideUnavailable = mod.db == nil or mod.db.hideUnavailable ~= false
                if not (mount.unavailable and not isCollected and hideUnavailable) then
                    result.totalAll = result.totalAll + 1
                    if isCollected then
                        result.collectedCountAll = result.collectedCountAll + 1
                        local w = MC.ScoreFor(mount)
                        if mount.unavailable then
                            result.legacyCount = result.legacyCount + 1
                            result.legacyScore = result.legacyScore + w
                        else
                            result.score = result.score + w
                        end
                    end

                    local exp = mount.expansion or group.expansion or "_unknown"
                    local b = result.byExpansion[exp]
                    if not b then
                        b = { total = 0, collected = 0 }
                        result.byExpansion[exp] = b
                    end
                    b.total = b.total + 1
                    if isCollected then b.collected = b.collected + 1 end

                    if visible then
                        local entry = {
                            mountID           = mount.mountID,
                            name              = mountName,
                            source            = mount.source,
                            sourceInfo        = mount.sourceInfo,
                            waypoint           = mount.waypoint,
                            overworldWaypoint = mount.overworldWaypoint,
                            cost              = mount.cost,
                            dropInfo          = mount.dropInfo,
                            achievementID    = mount.achievementID,
                            taskList          = mount.taskList,
                            zone              = mount.zone,
                            renown            = mount.renown,
                            faction           = mount.faction,
                            icon              = icon,
                            collected         = isCollected,
                            expansion         = mount.expansion,
                        }
                        result.total = result.total + 1
                        if isCollected then
                            result.collectedCount = result.collectedCount + 1
                            result.collected[#result.collected + 1] = entry
                        else
                            result.uncollectedCount = result.uncollectedCount + 1
                            local src = mount.source
                            if not result.bySource[src] then result.bySource[src] = {} end
                            result.bySource[src][#result.bySource[src] + 1] = entry
                        end
                    end
                end
            end
        end
    end

    self.results = result
end
