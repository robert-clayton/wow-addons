local _, MD = ...

local MUI = LibStub("MidnightUI-1.0")
local PREFIX = MUI.ChatPrefix("Midnight Decorations")

MD.MinimapButton = {}
local MB = MD.MinimapButton

function MB:Init()
    if self.initialized then return end
    self.initialized = true

    local LDB = LibStub("LibDataBroker-1.1")
    local LDBIcon = LibStub("LibDBIcon-1.0")

    local dataObj = LDB:NewDataObject("MidnightDecorations", {
        type = "launcher",
        text = "Midnight Decorations",
        icon = "Interface\\Icons\\INV_Misc_Rune_01",
        OnClick = function(_, button)
            if button == "LeftButton" then
                if MD.UI then MD.UI:Toggle() end
            elseif button == "RightButton" then
                if MD.Scanner then
                    MD.Scanner:Scan()
                    if MD.UI and MD.UI.frame then MD.UI:Refresh() end
                    local r = MD.Scanner.results
                    if r and r.total then
                        print(format("%s %d / %d collected (%d remaining)",
                            PREFIX, r.collectedCount, r.total, r.uncollectedCount))
                        for _, srcType in ipairs(MD.SOURCE_ORDER) do
                            local entries = r.bySource[srcType]
                            if entries and #entries > 0 then
                                print(format("  %s: %d uncollected", MD.SOURCE_LABELS[srcType], #entries))
                            end
                        end
                    end
                end
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("|cffffcc00Midnight Decorations|r")
            local r = MD.Scanner and MD.Scanner.results
            if r and r.total then
                tt:AddLine(format("Collected: %d / %d", r.collectedCount, r.total), 1, 1, 1)
                for _, srcType in ipairs(MD.SOURCE_ORDER) do
                    local entries = r.bySource[srcType]
                    if entries and #entries > 0 then
                        tt:AddLine(format("  %s: %d remaining", MD.SOURCE_LABELS[srcType], #entries), 0.7, 0.7, 0.7)
                    end
                end
            end
            tt:AddLine(" ")
            tt:AddLine("|cff80ff80Left-click|r to toggle panel", 0.8, 0.8, 0.8)
            tt:AddLine("|cff80ff00Right-click|r to scan & summarize", 0.8, 0.8, 0.8)
        end,
    })

    LDBIcon:Register("MidnightDecorations", dataObj, MD.db.minimap)
    self.LDBIcon = LDBIcon
end

function MB:Update()
    if not self.LDBIcon then return end
    if MD.db.minimap and MD.db.minimap.hide then
        self.LDBIcon:Hide("MidnightDecorations")
    else
        self.LDBIcon:Show("MidnightDecorations")
    end
end
