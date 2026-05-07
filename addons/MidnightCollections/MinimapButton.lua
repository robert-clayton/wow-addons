local _, MC = ...

MC.MinimapButton = {}
local MB = MC.MinimapButton

function MB:Init()
    if self.initialized then return end
    self.initialized = true

    local LDB = LibStub("LibDataBroker-1.1")
    local LDBIcon = LibStub("LibDBIcon-1.0")

    local dataObj = LDB:NewDataObject("MidnightCollections", {
        type = "launcher",
        text = "Midnight Collections",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        OnClick = function(_, button)
            if button == "LeftButton" then
                if MC.panel then MC.panel:Toggle() end
            elseif button == "RightButton" then
                -- Throttled per-module rescan; only enabled modules
                for _, mod in ipairs(MC.modules) do
                    if MC.IsModuleEnabled(mod.key) and mod.Scanner then
                        MC.ThrottledScan(mod)
                    end
                end
                MB:PrintSummary()
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("|cffffcc00Midnight Collections|r")
            for _, mod in ipairs(MC.modules) do
                if MC.IsModuleEnabled(mod.key) then
                    if mod.opts.tooltipLines then
                        mod.opts.tooltipLines(tt, mod)
                    else
                        local r = mod.Scanner and mod.Scanner.results
                        if r and r.total then
                            tt:AddLine(format("  %s: %d / %d",
                                mod.label, r.collectedCount or 0, r.total), 0.7, 0.7, 0.7)
                        end
                    end
                end
            end
            tt:AddLine(" ")
            tt:AddLine("|cff80ff80Left-click|r to toggle panel", 0.8, 0.8, 0.8)
            tt:AddLine("|cff80ff00Right-click|r to scan & summarize", 0.8, 0.8, 0.8)
        end,
    })

    LDBIcon:Register("MidnightCollections", dataObj, MC.db.minimap)
    self.LDBIcon = LDBIcon
end

function MB:Update()
    if not self.LDBIcon then return end
    if MC.db.minimap and MC.db.minimap.hide then
        self.LDBIcon:Hide("MidnightCollections")
    else
        self.LDBIcon:Show("MidnightCollections")
    end
end

function MB:PrintSummary()
    for _, mod in ipairs(MC.modules) do
        if MC.IsModuleEnabled(mod.key) then
            if mod.opts.printSummary then
                mod.opts.printSummary(mod)
            else
                local r = mod.Scanner and mod.Scanner.results
                if r and r.total then
                    print(format("%s [%s] %d / %d collected (%d remaining)",
                        MC.PREFIX, mod.label, r.collectedCount or 0, r.total, r.uncollectedCount or 0))
                end
            end
        end
    end
end
