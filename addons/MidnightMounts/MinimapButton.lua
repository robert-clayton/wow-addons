local _, MM = ...

local MUI = LibStub("MidnightUI-1.0")
local PREFIX = MUI.ChatPrefix("Midnight Mounts")

MM.MinimapButton = {}
local MB = MM.MinimapButton

function MB:Init()
    if self.initialized then return end
    self.initialized = true

    local LDB = LibStub("LibDataBroker-1.1")
    local LDBIcon = LibStub("LibDBIcon-1.0")

    local dataObj = LDB:NewDataObject("MidnightMounts", {
        type = "launcher",
        text = "Midnight Mounts",
        icon = "Interface\\Icons\\Ability_Mount_RidingHorse",
        OnClick = function(_, button)
            if button == "LeftButton" then
                if MM.UI then MM.UI:Toggle() end
            elseif button == "RightButton" then
                if MM.Scanner then
                    MM.Scanner:Scan()
                    if MM.UI and MM.UI.frame then MM.UI:Refresh() end
                    local r = MM.Scanner.results
                    if r and r.total then
                        print(format("%s %d / %d collected (%d remaining)",
                            PREFIX, r.collectedCount, r.total, r.uncollectedCount))
                        for _, srcType in ipairs(MM.SOURCE_ORDER) do
                            local entries = r.bySource[srcType]
                            if entries and #entries > 0 then
                                print(format("  %s: %d uncollected", MM.SOURCE_LABELS[srcType], #entries))
                            end
                        end
                    end
                end
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("|cffffcc00Midnight Mounts|r")
            local r = MM.Scanner and MM.Scanner.results
            if r and r.total then
                tt:AddLine(format("Collected: %d / %d", r.collectedCount, r.total), 1, 1, 1)
                for _, srcType in ipairs(MM.SOURCE_ORDER) do
                    local entries = r.bySource[srcType]
                    if entries and #entries > 0 then
                        tt:AddLine(format("  %s: %d remaining", MM.SOURCE_LABELS[srcType], #entries), 0.7, 0.7, 0.7)
                    end
                end
            end
            tt:AddLine(" ")
            tt:AddLine("|cff80ff80Left-click|r to toggle panel", 0.8, 0.8, 0.8)
            tt:AddLine("|cff80ff00Right-click|r to scan & summarize", 0.8, 0.8, 0.8)
        end,
    })

    LDBIcon:Register("MidnightMounts", dataObj, MM.db.minimap)
    self.LDBIcon = LDBIcon
end

function MB:Update()
    if not self.LDBIcon then return end
    if MM.db.minimap and MM.db.minimap.hide then
        self.LDBIcon:Hide("MidnightMounts")
    else
        self.LDBIcon:Show("MidnightMounts")
    end
end
