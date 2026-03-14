local _, MR = ...

local MUI = LibStub("MidnightUI-1.0")
local PREFIX = MUI.ChatPrefix("Midnight Recipes")

MR.MinimapButton = {}
local MB = MR.MinimapButton

function MB:Init()
    if self.initialized then return end
    self.initialized = true

    local LDB = LibStub("LibDataBroker-1.1")
    local LDBIcon = LibStub("LibDBIcon-1.0")

    local dataObj = LDB:NewDataObject("MidnightRecipes", {
        type = "launcher",
        text = "Midnight Recipes",
        icon = "Interface\\Icons\\INV_Scroll_05",
        OnClick = function(_, button)
            if button == "LeftButton" then
                if MR.UI then MR.UI:Toggle() end
            elseif button == "RightButton" then
                if MR.Scanner then
                    MR.Scanner:Scan()
                    if MR.UI and MR.UI.frame then MR.UI:Refresh() end
                    -- Print summary in deterministic order
                    for _, skillLine in ipairs(MR.PROF_ORDER) do
                        local result = MR.Scanner.results[skillLine]
                        local prof = MR.professions[skillLine]
                        if result and prof then
                            print(format("%s %s: %d / %d learned (%d remaining)",
                                PREFIX, prof.name, result.learnedCount, result.total, result.unlearnedCount))
                        end
                    end
                end
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("|cffffcc00Midnight Recipes|r")
            local results = MR.Scanner and MR.Scanner.results or {}
            for _, skillLine in ipairs(MR.PROF_ORDER) do
                local result = results[skillLine]
                local prof = MR.professions[skillLine]
                if result and prof then
                    tt:AddLine(format("%s: %d / %d", prof.name, result.learnedCount, result.total), 1, 1, 1)
                end
            end
            tt:AddLine(" ")
            tt:AddLine("|cff80ff80Left-click|r to toggle panel", 0.8, 0.8, 0.8)
            tt:AddLine("|cff80ff00Right-click|r to scan & summarize", 0.8, 0.8, 0.8)
        end,
    })

    LDBIcon:Register("MidnightRecipes", dataObj, MR.db.minimap)
    self.LDBIcon = LDBIcon
end

function MB:Update()
    if not self.LDBIcon then return end
    if MR.db.minimap and MR.db.minimap.hide then
        self.LDBIcon:Hide("MidnightRecipes")
    else
        self.LDBIcon:Show("MidnightRecipes")
    end
end
