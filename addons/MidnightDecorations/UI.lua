local _, MD = ...

MD.UI = {}
local UI = MD.UI

local MUI = LibStub("MidnightUI-1.0")
local PREFIX = MUI.ChatPrefix("Midnight Decorations")

local ROW_HEIGHT     = 20
local HEADER_HEIGHT  = 24
local SECTION_PAD    = 8
local PADDING        = 6
local ICON_SIZE      = 20

local SOURCE_COLORS = {
    crafted     = { 0.80, 0.50, 0.90 },
    vendor      = { 0.30, 0.60, 1.00 },
    quest       = { 0.90, 0.80, 0.20 },
    achievement = { 0.90, 0.70, 0.20 },
    drop        = { 0.90, 0.40, 0.30 },
    renown      = { 0.30, 0.60, 1.00 },
    tradingpost = { 0.90, 0.55, 0.80 },
    worldevent  = { 0.70, 0.70, 0.70 },
}

local SOURCE_SET = {}
for _, s in ipairs(MD.SOURCE_ORDER) do SOURCE_SET[s] = true end

local function SourceColor(srcType)
    local c = SOURCE_COLORS[srcType]
    if c then return c[1], c[2], c[3] end
    return 0.7, 0.7, 0.7
end

--------------------------------------------------------------------------
-- Info tooltip (secondary, shows source details)
--------------------------------------------------------------------------
local infoTooltip

local function GetInfoTooltip()
    if not infoTooltip then
        infoTooltip = CreateFrame("GameTooltip", "MidnightDecorationsInfoTooltip", UIParent, "GameTooltipTemplate")
        infoTooltip:SetFrameStrata("TOOLTIP")
    end
    return infoTooltip
end

local function ShowInfoTooltip(owner, deco)
    local tt = GetInfoTooltip()
    tt:SetOwner(owner, "ANCHOR_PRESERVE")
    tt:ClearAllPoints()
    tt:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 2, 0)

    local theme = MUI.Theme
    local sr, sg, sb = SourceColor(deco.source)
    local label = MD.SOURCE_LABELS[deco.source] or deco.source

    local c = theme.colors
    tt:AddLine("Midnight Decorations", c.ttTitle[1], c.ttTitle[2], c.ttTitle[3])
    tt:AddDoubleLine("Source:", label, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], sr, sg, sb)

    if deco.sourceInfo then
        tt:AddLine(deco.sourceInfo, 1, 1, 1)
    end

    -- Profession label for crafted items
    if deco.skillLine and MD.PROF_LABELS[deco.skillLine] then
        local pr, pg, pb = theme:ProfAccentColor(deco.skillLine)
        tt:AddDoubleLine("Profession:", MD.PROF_LABELS[deco.skillLine], c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], pr, pg, pb)
    end

    -- Location from waypoint
    if deco.waypoint then
        local wp = deco.waypoint
        if wp[1] and wp[1] > 0 then
            local mapInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(wp[1])
            local mapName = mapInfo and mapInfo.name or ("Map " .. wp[1])
            tt:AddDoubleLine("Zone:", mapName, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttValue[1], c.ttValue[2], c.ttValue[3])
            if wp[2] and wp[3] then
                tt:AddDoubleLine("Coords:", format("%.1f, %.1f", wp[2] * 100, wp[3] * 100), c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttValue[1], c.ttValue[2], c.ttValue[3])
            end
        end
    elseif deco.zone then
        tt:AddDoubleLine("Zone:", deco.zone, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttValue[1], c.ttValue[2], c.ttValue[3])
    end

    -- Renown / reputation requirement
    if deco.renown then
        local req = deco.renown
        local metReq = false
        local reqLabel = ""
        if req.factionID and req.level then
            local current = "?"
            if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
                local ok, data = pcall(C_MajorFactions.GetMajorFactionData, req.factionID)
                if ok and data and data.renownLevel then
                    current = tostring(data.renownLevel)
                    metReq = data.renownLevel >= req.level
                end
            end
            local name = req.factionName or ("Faction " .. req.factionID)
            reqLabel = format("%s Renown %s/%d", name, current, req.level)
        elseif req.factionID and req.standing then
            local current = "?"
            if C_Reputation and C_Reputation.GetFactionDataByID then
                local ok, data = pcall(C_Reputation.GetFactionDataByID, req.factionID)
                if ok and data and data.reaction then
                    local standings = { "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted" }
                    current = standings[data.reaction] or tostring(data.reaction)
                    local standingOrder = { Hated = 1, Hostile = 2, Unfriendly = 3, Neutral = 4, Friendly = 5, Honored = 6, Revered = 7, Exalted = 8 }
                    metReq = data.reaction >= (standingOrder[req.standing] or 0)
                end
            end
            local name = req.factionName or ("Faction " .. req.factionID)
            reqLabel = format("%s %s (%s)", name, current, req.standing)
        end
        local rr, rg, rb = c.ttCostBad[1], c.ttCostBad[2], c.ttCostBad[3]
        if metReq then rr, rg, rb = 0.5, 0.8, 0.5 end
        tt:AddLine(reqLabel, rr, rg, rb)
    end

    -- Vendor cost
    if deco.cost then
        if deco.cost.gold then
            local playerGold = GetMoney and GetMoney() or 0
            local gr, gg, gb = 1, 1, 1
            if playerGold < deco.cost.gold then gr, gg, gb = c.ttCostBad[1], c.ttCostBad[2], c.ttCostBad[3] end
            tt:AddDoubleLine("Cost:", MUI.FormatGold(deco.cost.gold), c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], gr, gg, gb)
        end
        local parts = {}
        for _, key in ipairs({"currency", "currency2"}) do
            local cur = deco.cost[key]
            if cur then
                local currID, amount = cur[1], cur[2]
                local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currID)
                local icon = info and info.iconFileID
                local name = info and info.name or ("Currency " .. currID)
                local owned = info and info.quantity or 0
                local color = owned >= amount and "" or "|cffff4d4d"
                local costLabel = icon and (amount .. " |T" .. icon .. ":0|t") or (amount .. " " .. name)
                parts[#parts + 1] = color .. costLabel .. "|r"
            end
        end
        if #parts > 0 then
            tt:AddDoubleLine("Cost:", table.concat(parts, "  "), c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], 1, 1, 1)
        end
    end

    -- Drop info
    if deco.dropInfo then
        local di = deco.dropInfo
        if di.mob then
            tt:AddDoubleLine("Drops from:", di.mob, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttDropMob[1], c.ttDropMob[2], c.ttDropMob[3])
        end
        if di.zone then
            tt:AddDoubleLine("Zone:", di.zone, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttValue[1], c.ttValue[2], c.ttValue[3])
        end
        if di.rate then
            tt:AddDoubleLine("Drop rate:", di.rate, c.ttLabel[1], c.ttLabel[2], c.ttLabel[3], c.ttDropRate[1], c.ttDropRate[2], c.ttDropRate[3])
        end
        if di.boss then
            tt:AddLine("Boss drop", c.ttBoss[1], c.ttBoss[2], c.ttBoss[3])
        end
    end

    -- Click hints
    tt:AddLine(" ")
    local src = deco.source
    if deco.waypoint then
        tt:AddLine("Click to set TomTom waypoint", c.ttHintGreen[1], c.ttHintGreen[2], c.ttHintGreen[3])
    elseif src == "achievement" and deco.achievementID and deco.achievementID > 0 then
        tt:AddLine("Click to open achievement", c.ttHintGreen[1], c.ttHintGreen[2], c.ttHintGreen[3])
    elseif src == "crafted" and deco.skillLine then
        tt:AddLine("Click to open profession", c.ttHintGreen[1], c.ttHintGreen[2], c.ttHintGreen[3])
    end
    tt:AddLine("Shift-click to copy Wowhead URL", c.ttHintBlue[1], c.ttHintBlue[2], c.ttHintBlue[3])

    tt:Show()
end

local function HideInfoTooltip()
    if infoTooltip then infoTooltip:Hide() end
end

--------------------------------------------------------------------------
-- Click actions per source type
--------------------------------------------------------------------------
StaticPopupDialogs["MIDNIGHTDECORATIONS_WOWHEAD"] = {
    text = "Copy Wowhead URL:",
    button1 = CLOSE,
    hasEditBox = true,
    editBoxWidth = 280,
    OnShow = function(self, data)
        local editBox = self.editBox
        editBox:SetText(data)
        editBox:HighlightText()
        editBox:SetFocus()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function OpenWowhead(deco)
    local url
    if deco.decorID and deco.decorID > 0 then
        url = "https://www.wowhead.com/decor=" .. deco.decorID
    elseif deco.itemID and deco.itemID > 0 then
        url = "https://www.wowhead.com/item=" .. deco.itemID
    end
    if url then
        StaticPopup_Show("MIDNIGHTDECORATIONS_WOWHEAD", nil, nil, url)
    end
end

local function DoDecoAction(deco)
    if IsShiftKeyDown() then
        OpenWowhead(deco)
        return
    end
    local src = deco.source
    if deco.waypoint then
        local wp = deco.waypoint
        if wp[1] and wp[1] > 0 then
            if TomTom then
                local title = wp[4] or deco.sourceInfo or deco.name
                TomTom:AddWaypoint(wp[1], wp[2], wp[3], { title = title })
                print(format("%s Waypoint set: %s", PREFIX, title))
            else
                print(PREFIX .. " TomTom addon required for waypoints.")
            end
        end
    elseif src == "achievement" and deco.achievementID and deco.achievementID > 0 then
        if InCombatLockdown() then
            print(PREFIX .. " Cannot open achievements during combat.")
            return
        end
        local ok = pcall(function()
            OpenAchievementFrame(deco.achievementID)
        end)
        if not ok then
            print(PREFIX .. " Could not open achievement frame.")
        end
    elseif src == "crafted" and deco.skillLine then
        if InCombatLockdown() then
            print(PREFIX .. " Cannot open professions during combat.")
            return
        end
        if C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill then
            local ok = pcall(C_TradeSkillUI.OpenTradeSkill, deco.skillLine)
            if not ok then
                print(PREFIX .. " Could not open profession frame.")
            end
        end
    end
end

--------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------
function UI:Toggle()
    if not self.panel then self:Create() end
    self.panel:Toggle()
end

function UI:Show()
    if not self.panel then self:Create() end
    self.panel:Show()
end

function UI:Hide()
    if self.panel then self.panel:Hide() end
end

--------------------------------------------------------------------------
-- Frame creation (thin wrapper around MUI panel)
--------------------------------------------------------------------------
function UI:Create()
    if self.panel then return end

    local panel = MUI:CreatePanel({
        name          = "MidnightDecorations",
        title         = "Midnight Decorations",
        icon          = "Interface\\Icons\\INV_Misc_Rune_01",
        db            = MD.db,
        defaultWidth  = 360,
        defaultHeight = 520,
        minWidth      = 240,
        maxWidth      = 600,
        minHeight     = 120,
        maxHeight     = 900,
        onRefresh     = function() UI:Refresh() end,
    })

    self.panel = panel
    self.frame = panel.frame

    self.panel:PopulateConfig({
        { type = "section", label = "DISPLAY" },
        { type = "checkbox", label = "Lock Frame",
            get = function() return MD.db.locked end,
            set = function(v)
                MD.db.locked = v
                if self.frame then self.frame:SetMovable(not v) end
                self.panel:UpdateDraggerVisibility()
            end },
        { type = "checkbox", label = "Show Collected Decorations",
            get = function() return MD.db.showCollected end,
            set = function(v)
                MD.db.showCollected = v
                self:Refresh()
            end },
        { type = "checkbox", label = "Hide Trading Post Decorations",
            get = function() return MD.db.hideTradingPost end,
            set = function(v)
                MD.db.hideTradingPost = v
                if MD.Scanner then MD.Scanner:Scan() end
                self:Refresh()
            end },
        { type = "checkbox", label = "Hide Minimap Icon",
            get = function()
                return MD.db.minimap and MD.db.minimap.hide or false
            end,
            set = function(v)
                if MD.db.minimap then MD.db.minimap.hide = v end
                if MD.MinimapButton and MD.MinimapButton.Update then
                    MD.MinimapButton:Update()
                end
            end },
        { type = "divider" },
        { type = "section", label = "APPEARANCE" },
        { type = "slider", label = "Background Opacity", min = 0.1, max = 1.0, step = 0.05,
            get = function() return MD.db.frameAlpha or 1.0 end,
            set = function(v)
                MD.db.frameAlpha = v
                self.panel:ApplyBackdrop()
                self:Refresh()
            end,
            fillColor = { 0.40, 0.40, 0.40 } },
        { type = "slider", label = "Frame Scale", min = 0.5, max = 2.0, step = 0.05,
            get = function() return MD.db.frameScale or 1.0 end,
            set = function(v)
                MD.db.frameScale = v
                if self.frame then self.frame:SetScale(v) end
            end,
            fillColor = { 0.16, 0.78, 0.75 } },
    })
end

--------------------------------------------------------------------------
-- ToggleConfig
--------------------------------------------------------------------------
function UI:ToggleConfig()
    if not self.panel then return end
    self.panel:ToggleConfig()
end

--------------------------------------------------------------------------
-- Refresh
--------------------------------------------------------------------------
function UI:Refresh()
    if not self.panel or not self.panel.scrollChild then return end
    if not MD.Scanner then return end

    self.panel.pool:ReleaseAll()

    local child = self.panel.scrollChild
    local yOff = 0
    local r = MD.Scanner.results

    if not r or not r.total then
        self.panel:RefreshScrollContent(0)
        return
    end

    -- Source type groups
    for _, srcType in ipairs(MD.SOURCE_ORDER) do
        local entries = r.bySource[srcType]
        if entries and #entries > 0 then
            yOff = self:RenderSourceGroup(child, srcType, entries, yOff)
            yOff = yOff + SECTION_PAD
        end
    end

    -- Catch-all: render any source types not in SOURCE_ORDER
    for srcType, entries in pairs(r.bySource) do
        if not SOURCE_SET[srcType] and #entries > 0 then
            yOff = self:RenderSourceGroup(child, srcType, entries, yOff)
            yOff = yOff + SECTION_PAD
        end
    end

    -- Collected
    if MD.db.showCollected and #r.collected > 0 then
        yOff = self:RenderCollectedGroup(child, r.collected, yOff)
    end

    -- Update title bar progress counter
    if self.panel.titleProgressText then
        if r.total > 0 then
            self.panel.titleProgressText:SetText(format("%d / %d", r.collectedCount, r.total))
        else
            self.panel.titleProgressText:SetText("")
        end
    end

    -- emptyText: show when no content, hide otherwise
    local theme = MUI.Theme
    local emptyText = MUI.GetOrCreate(child, "emptyText", function(p)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize, "OUTLINE")
        return fs
    end)
    if yOff == 0 then
        emptyText:SetPoint("TOP", child, "TOP", 0, -20)
        emptyText:SetText("No uncollected Midnight decorations found.")
        emptyText:SetTextColor(0.7, 0.7, 0.7)
        emptyText:Show()
        yOff = 60
    else
        emptyText:Hide()
    end

    self.panel:RefreshScrollContent(yOff)
end

--------------------------------------------------------------------------
-- Render: Source group (collapsible)
--------------------------------------------------------------------------
local function GroupByProfession(entries)
    local byProf = {}
    for _, deco in ipairs(entries) do
        local sl = deco.skillLine or 0
        if not byProf[sl] then byProf[sl] = {} end
        byProf[sl][#byProf[sl] + 1] = deco
    end
    return byProf
end

function UI:RenderSourceGroup(parent, srcType, entries, yOff)
    local theme = MUI.Theme
    local sr, sg, sb = SourceColor(srcType)

    local _, collapsed, newY = self.panel:RenderHeader(parent, yOff, {
        height     = 20,
        indent     = 0,
        collKey    = "src_" .. srcType,
        accentR    = sr, accentG = sg, accentB = sb,
        label      = MD.SOURCE_LABELS[srcType] or srcType,
        labelColor = { sr, sg, sb },
        count      = tostring(#entries),
        countColor = theme.colors.countDim,
    })
    yOff = newY

    if collapsed then return yOff end

    -- Crafted: sub-group by profession
    if srcType == "crafted" then
        local byProf = GroupByProfession(entries)
        for _, skillLine in ipairs(MD.PROF_ORDER) do
            local profEntries = byProf[skillLine]
            if profEntries and #profEntries > 0 then
                yOff = self:RenderProfSubGroup(parent, skillLine, profEntries, yOff)
            end
        end
        -- Catch-all for unknown professions
        local profSet = {}
        for _, sl in ipairs(MD.PROF_ORDER) do profSet[sl] = true end
        for sl, profEntries in pairs(byProf) do
            if not profSet[sl] and #profEntries > 0 then
                yOff = self:RenderProfSubGroup(parent, sl, profEntries, yOff)
            end
        end
    else
        for _, deco in ipairs(entries) do
            yOff = self:RenderDecoRow(parent, deco, yOff, false)
        end
    end

    return yOff
end

--------------------------------------------------------------------------
-- Render: Profession sub-group within crafted (collapsible)
--------------------------------------------------------------------------
function UI:RenderProfSubGroup(parent, skillLine, decos, yOff)
    local theme = MUI.Theme
    local pr, pg, pb = theme:ProfAccentColor(skillLine)
    local profLabel = MD.PROF_LABELS[skillLine] or ("Profession " .. skillLine)

    local _, collapsed, newY = self.panel:RenderHeader(parent, yOff, {
        height     = 18,
        indent     = 10,
        collKey    = "prof_" .. skillLine,
        accentR    = pr, accentG = pg, accentB = pb,
        label      = profLabel,
        labelColor = { pr * 0.85, pg * 0.85, pb * 0.85 },
        count      = tostring(#decos),
        countColor = theme.colors.countDim,
    })
    yOff = newY

    if collapsed then return yOff end

    for _, deco in ipairs(decos) do
        yOff = self:RenderDecoRow(parent, deco, yOff, false)
    end

    return yOff
end

--------------------------------------------------------------------------
-- Render: Collected group
--------------------------------------------------------------------------
function UI:RenderCollectedGroup(parent, entries, yOff)
    local theme = MUI.Theme
    local la = theme.colors.learnedAccent

    local _, collapsed, newY = self.panel:RenderHeader(parent, yOff, {
        height     = 20,
        indent     = 0,
        collKey    = "collected",
        accentR    = la[1], accentG = la[2], accentB = la[3],
        label      = "Collected",
        labelColor = { la[1], la[2], la[3] },
        count      = tostring(#entries),
        countColor = theme.colors.countDim,
    })
    yOff = newY

    if collapsed then return yOff end

    for _, deco in ipairs(entries) do
        yOff = self:RenderDecoRow(parent, deco, yOff, true)
    end

    return yOff
end

--------------------------------------------------------------------------
-- Render: Decoration row (clickable)
--------------------------------------------------------------------------
function UI:RenderDecoRow(parent, deco, yOff, isCollected)
    local theme = MUI.Theme

    local row = self.panel.pool:Acquire(parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -yOff)
    row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

    -- Hover background
    local rc = theme.colors.rowHover
    local hoverTex = MUI.GetOrCreate(row, "hover", function(p)
        local t = p:CreateTexture(nil, "BACKGROUND", nil, 1)
        return t
    end)
    hoverTex:SetAllPoints()
    hoverTex:SetColorTexture(1, 1, 1, 0)

    -- Decoration icon (20x20)
    local decoIcon = MUI.GetOrCreate(row, "icon", function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetSize(ICON_SIZE, ICON_SIZE)
        return t
    end)
    decoIcon:SetPoint("LEFT", row, "LEFT", PADDING, 0)
    if deco.icon then
        decoIcon:SetTexture(deco.icon)
    else
        decoIcon:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
    end
    if isCollected then
        decoIcon:SetDesaturated(true)
        decoIcon:SetAlpha(0.5)
    else
        decoIcon:SetDesaturated(false)
        decoIcon:SetAlpha(1)
    end

    -- Decoration name
    local nameFs = MUI.GetOrCreate(row, "name", function(p)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize, "OUTLINE")
        return fs
    end)
    nameFs:SetFont(theme.font, theme.fontSize, "OUTLINE")
    nameFs:SetJustifyH("LEFT")
    nameFs:SetWordWrap(false)
    nameFs:SetPoint("LEFT", row, "LEFT", PADDING + 24, 0)
    nameFs:SetPoint("RIGHT", row, "RIGHT", -50, 0)
    nameFs:SetText(deco.name)

    if isCollected then
        nameFs:SetTextColor(unpack(theme.colors.textDim))
    else
        nameFs:SetTextColor(unpack(theme.colors.text))
    end

    -- Source info / zone label (right side, dim)
    local infoFs = MUI.GetOrCreate(row, "info", function(p)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme.font, theme.fontSize - 2, "OUTLINE")
        return fs
    end)
    infoFs:SetFont(theme.font, theme.fontSize - 2, "OUTLINE")
    infoFs:SetJustifyH("RIGHT")
    infoFs:SetPoint("RIGHT", row, "RIGHT", -PADDING, 0)
    local infoText = deco.zone or ""
    infoFs:SetText(infoText)
    infoFs:SetTextColor(0.45, 0.45, 0.45)

    -- Strikethrough line for collected decorations
    local strike = MUI.GetOrCreate(row, "strike", function(p)
        local t = p:CreateTexture(nil, "ARTWORK")
        t:SetHeight(1)
        return t
    end)
    if isCollected then
        strike:SetPoint("LEFT", nameFs, "LEFT", 0, 0)
        strike:SetPoint("RIGHT", nameFs, "RIGHT", 0, 0)
        strike:SetColorTexture(theme.colors.textDim[1], theme.colors.textDim[2], theme.colors.textDim[3], 0.5)
        strike:Show()
    else
        strike:Hide()
    end

    -- Tooltip on hover: primary = item tooltip (crafted) or name tooltip, secondary = info tooltip
    row:SetScript("OnEnter", function(r)
        hoverTex:SetColorTexture(rc[1], rc[2], rc[3], rc[4])
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        if deco.itemID and deco.itemID > 0 then
            GameTooltip:SetItemByID(deco.itemID)
        else
            GameTooltip:AddLine(deco.name, 1, 1, 1)
            if deco.sourceInfo then
                GameTooltip:AddLine(deco.sourceInfo, 0.7, 0.7, 0.7, true)
            end
        end
        GameTooltip:Show()
        ShowInfoTooltip(r, deco)
    end)
    row:SetScript("OnLeave", function()
        hoverTex:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
        HideInfoTooltip()
    end)

    -- Click action
    if not isCollected then
        row:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then DoDecoAction(deco) end
        end)
    end

    return yOff + ROW_HEIGHT
end
