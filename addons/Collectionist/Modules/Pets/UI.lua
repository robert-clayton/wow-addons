local _, MC = ...

local mod = MC.modulesByKey["pets"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local ROW_HEIGHT = 22
local ICON_SIZE  = 24

function UI:Init(panel, m)
    self.panel = panel
    self.mod = m
    self._refresh = function() self:Refresh() end
end

function UI:GetConfigDefs()
    local db = mod.db
    return {
        { type = "checkbox", label = "Uncollected Pet Hover Alert",
            get = function() return db.wildAlerts end,
            set = function(v)
                db.wildAlerts = v
                if v and MC.ClearPetAlertCache then MC.ClearPetAlertCache() end
            end },
        { type = "checkbox", label = "Hide Trading Post Pets",
            get = function() return db.hideTradingPost end,
            set = function(v)
                db.hideTradingPost = v
                if mod.Scanner then MC.ScanNow(mod) end
                MC.RefreshActive()
            end },
        { type = "checkbox", label = "Hide unavailable pets",
            get = function() return db.hideUnavailable ~= false end,
            set = function(v)
                db.hideUnavailable = v
                if mod.Scanner then MC.ScanNow(mod) end
                MC.RefreshActive()
            end },
    }
end

function UI:Refresh()
    MUI.RenderModulePage(self.panel, {
        results       = mod.Scanner and mod.Scanner.results,
        sourceOrder   = MC.PetSourceOrder,
        renderSourceGroup = function(p, s, e, y) return self:RenderSourceGroup(p, s, e, y) end,
        renderRow     = function(p, pet, y, c) return self:RenderPetRow(p, pet, y, c) end,
        showCollected = mod.db.showCollected,
        db            = mod.db,
        refreshCb     = self._refresh,
        emptyMessages = {
            allDone  = "All Midnight pets collected!",
            noneLeft = "No uncollected Midnight pets found.",
        },
    })
end

function UI:RenderSourceGroup(parent, srcType, entries, yOff)
    local sr, sg, sb = MUI.Theme:SourceColor(srcType)
    local _, collapsed, newY = MUI.RenderSourceHeader(self.panel.pool, parent, yOff, {
        label       = MC.PetSourceLabels[srcType] or srcType,
        accentColor = { sr, sg, sb },
        count       = #entries,
        collKey     = "src_" .. srcType,
    }, mod.db, self._refresh)
    yOff = newY
    if collapsed then return yOff end

    if srcType == "wild" then
        local byZone = MUI.GroupByField(entries, "zone", "Unknown")
        for _, zoneName in ipairs(MUI.MidnightZoneOrder) do
            local pets = byZone[zoneName]
            if pets and #pets > 0 then
                yOff = self:RenderZoneSubGroup(parent, zoneName, pets, yOff, sr, sg, sb)
            end
        end
        for zoneName, pets in pairs(byZone) do
            if not MUI.MidnightZoneSet[zoneName] and #pets > 0 then
                yOff = self:RenderZoneSubGroup(parent, zoneName, pets, yOff, sr, sg, sb)
            end
        end
    else
        for _, pet in ipairs(entries) do
            yOff = self:RenderPetRow(parent, pet, yOff, false)
        end
    end
    return yOff
end

function UI:RenderZoneSubGroup(parent, zoneName, pets, yOff, sr, sg, sb)
    local _, collapsed, newY = MUI.RenderSourceHeader(self.panel.pool, parent, yOff, {
        label       = zoneName,
        accentColor = { sr, sg, sb },
        labelColor  = { sr * 0.85, sg * 0.85, sb * 0.85 },
        count       = #pets,
        collKey     = "zone_" .. zoneName,
        height      = 18,
        indent      = 10,
    }, mod.db, self._refresh)
    yOff = newY
    if collapsed then return yOff end
    for _, pet in ipairs(pets) do
        yOff = self:RenderPetRow(parent, pet, yOff, false)
    end
    return yOff
end

function UI:RenderPetRow(parent, pet, yOff, isCollected)
    -- Offscreen: bail before the opts table below is constructed. Lua builds
    -- it at the call site, so letting RenderItemRow skip saves the frame but
    -- not the garbage.
    if MUI.RowHidden(self.panel.pool, yOff, ROW_HEIGHT) then return yOff + ROW_HEIGHT end

    local theme = MUI.Theme
    local typeName = MC.PetTypeNames[pet.petType] or ""
    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height      = ROW_HEIGHT,
        indent      = 8,
        leading     = { kind = "icon", size = ICON_SIZE,
                        texture = pet.icon,
                        fallback = "Interface\\Icons\\INV_Pet_BabyBlizzardBear" },
        name        = pet.name,
        info        = pet.future and MC.GetAvailabilityBadge(pet) or typeName,
        isCollected = isCollected,
        onEnter = function(r)
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            GameTooltip:AddLine(pet.name, 1, 1, 1)
            if pet.speciesID and C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID then
                local _, _, _, _, tooltipSource, tooltipDescription =
                    C_PetJournal.GetPetInfoBySpeciesID(pet.speciesID)
                if tooltipDescription then GameTooltip:AddLine(tooltipDescription, 0.7, 0.7, 0.7, true) end
                if tooltipSource then
                    -- Blizzard embeds currency-icon escapes in this string
                    -- and some carry a bare filename the client cannot
                    -- resolve, which then prints as its own path.
                    GameTooltip:AddLine(MC.SanitizeGameText(tooltipSource),
                        0.5, 0.8, 0.5, true)
                end
            end
            GameTooltip:Show()
            local sr, sg, sb = theme:SourceColor(pet.source)
            local label = MC.PetSourceLabels[pet.source] or pet.source
            MC.ShowItemInfoTooltip(r, pet, label, sr, sg, sb)
        end,
        onLeave = MC.RowOnLeave,
        onClick = function() MC.DoItemAction(pet) end,
    })
end
