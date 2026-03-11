local _, MP = ...

MP.MinimapButton = {}
local MB = MP.MinimapButton

function MB:Init()
    if self.initialized then return end
    self.initialized = true

    local LDB = LibStub("LibDataBroker-1.1")
    local LDBIcon = LibStub("LibDBIcon-1.0")

    local dataObj = LDB:NewDataObject("MidnightPets", {
        type = "launcher",
        text = "Midnight Pets",
        icon = "Interface\\Icons\\INV_Pet_BabyBlizzardBear",
        OnClick = function(_, button)
            if button == "LeftButton" then
                if MP.UI then MP.UI:Toggle() end
            elseif button == "RightButton" then
                if MP.Scanner then
                    MP.Scanner:Scan()
                    if MP.UI and MP.UI.frame then MP.UI:Refresh() end
                    local r = MP.Scanner.results
                    if r and r.total then
                        print(format("|cff80c0ff[Midnight Pets]|r %d / %d collected (%d remaining)",
                            r.collectedCount, r.total, r.uncollectedCount))
                        for _, srcType in ipairs(MP.SOURCE_ORDER) do
                            local entries = r.bySource[srcType]
                            if entries and #entries > 0 then
                                print(format("  %s: %d uncollected", MP.SOURCE_LABELS[srcType], #entries))
                            end
                        end
                    end
                end
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("|cffffcc00Midnight Pets|r")
            local r = MP.Scanner and MP.Scanner.results
            if r and r.total then
                tt:AddLine(format("Collected: %d / %d", r.collectedCount, r.total), 1, 1, 1)
                for _, srcType in ipairs(MP.SOURCE_ORDER) do
                    local entries = r.bySource[srcType]
                    if entries and #entries > 0 then
                        tt:AddLine(format("  %s: %d remaining", MP.SOURCE_LABELS[srcType], #entries), 0.7, 0.7, 0.7)
                    end
                end
            end
            tt:AddLine(" ")
            tt:AddLine("|cff80ff80Left-click|r to toggle panel", 0.8, 0.8, 0.8)
            tt:AddLine("|cff80ff00Right-click|r to scan & summarize", 0.8, 0.8, 0.8)
        end,
    })

    LDBIcon:Register("MidnightPets", dataObj, MP.db.minimap)
    self.LDBIcon = LDBIcon
end

function MB:Update()
    if not self.LDBIcon then return end
    if MP.db.minimap and MP.db.minimap.hide then
        self.LDBIcon:Hide("MidnightPets")
    else
        self.LDBIcon:Show("MidnightPets")
    end
end
