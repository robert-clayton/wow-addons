local _, MM = ...

MM.Scanner = {}
local Scanner = MM.Scanner

Scanner.results = {}

function Scanner:Scan()
    wipe(self.results)

    local result = {
        total          = 0,
        collectedCount = 0,
        uncollectedCount = 0,
        bySource       = {},
        collected      = {},
    }

    local playerFaction = UnitFactionGroup("player")

    if not MM.MountData then return end
    for _, group in ipairs(MM.MountData) do
        for _, mount in ipairs(group.mounts) do
            -- PvP faction filtering: skip mounts not for this player's faction
            if mount.faction and mount.faction ~= playerFaction then
                -- skip entirely
            else
                result.total = result.total + 1

                local isCollected = false
                local icon = nil
                local mountName = mount.name

                -- Collection check via C_MountJournal
                if mount.mountID and mount.mountID > 0 and C_MountJournal and C_MountJournal.GetMountInfoByID then
                    local ok, name, spellID, mountIcon, _, _, _, _, _, _, collected
                        = pcall(C_MountJournal.GetMountInfoByID, mount.mountID)
                    if ok then
                        if collected ~= nil then isCollected = collected end
                        if mountIcon and mountIcon ~= 0 then icon = mountIcon end
                        if name and name ~= "" then mountName = name end
                    end
                end

                local entry = {
                    mountID       = mount.mountID,
                    name          = mountName,
                    source        = mount.source,
                    sourceInfo    = mount.sourceInfo,
                    waypoint      = mount.waypoint,
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
