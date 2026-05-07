local _, MC = ...

local mod = MC.modulesByKey["mounts"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

function Scanner:Scan()
    if not MC.MountData then return end

    local result = {
        total            = 0,
        collectedCount   = 0,
        uncollectedCount = 0,
        bySource         = {},
        collected        = {},
    }

    local playerFaction = UnitFactionGroup("player")
    local hasJournal = C_MountJournal and C_MountJournal.GetMountInfoByID
    for _, group in ipairs(MC.MountData) do
        for _, mount in ipairs(group.mounts) do
            -- PvP faction filtering: skip mounts not for this player's faction
            if not (mount.faction and mount.faction ~= playerFaction) then
                result.total = result.total + 1

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

                local entry = {
                    mountID       = mount.mountID,
                    name          = mountName,
                    source        = mount.source,
                    sourceInfo    = mount.sourceInfo,
                    waypoint         = mount.waypoint,
                    overworldWaypoint = mount.overworldWaypoint,
                    cost          = mount.cost,
                    dropInfo      = mount.dropInfo,
                    achievementID = mount.achievementID,
                    zone          = mount.zone,
                    renown        = mount.renown,
                    faction       = mount.faction,
                    icon          = icon,
                    collected     = isCollected,
                }

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

    self.results = result
end
