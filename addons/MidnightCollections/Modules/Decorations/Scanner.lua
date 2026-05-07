local _, MC = ...

local mod = MC.modulesByKey["decorations"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

local DECOR_ENTRY_TYPE = 1 -- Enum.HousingCatalogEntryType.Decor

function Scanner:CheckCollected(decorID, itemID)
    if decorID and decorID > 0 and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByRecordID then
        local ok, info = pcall(C_HousingCatalog.GetCatalogEntryInfoByRecordID,
            DECOR_ENTRY_TYPE, decorID, true)
        if ok and info then
            local owned = (info.numPlaced or 0) + (info.quantity or 0)
            return owned > 0, info
        end
    end

    if itemID and itemID > 0 and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
        local ok, info = pcall(C_HousingCatalog.GetCatalogEntryInfoByItem, itemID, true)
        if ok and info then
            local owned = (info.numPlaced or 0) + (info.quantity or 0)
            return owned > 0, info
        end
    end

    return false, nil
end

function Scanner:GetIcon(decorID, itemID)
    if decorID and decorID > 0 and C_HousingDecor and C_HousingDecor.GetDecorIcon then
        local ok, icon = pcall(C_HousingDecor.GetDecorIcon, decorID)
        if ok and icon and icon ~= 0 then return icon end
    end

    if itemID and itemID > 0 and GetItemInfoInstant then
        local ok, _, _, _, itemIcon = pcall(GetItemInfoInstant, itemID)
        if ok and itemIcon and itemIcon ~= 0 then return itemIcon end
    end

    return nil
end

function Scanner:GetName(decorID, itemID, fallbackName)
    if decorID and decorID > 0 and C_HousingDecor and C_HousingDecor.GetDecorName then
        local ok, name = pcall(C_HousingDecor.GetDecorName, decorID)
        if ok and name and name ~= "" then return name end
    end

    if itemID and itemID > 0 and C_Item and C_Item.GetItemNameByID then
        local ok, name = pcall(C_Item.GetItemNameByID, itemID)
        if ok and name and name ~= "" then return name end
    end

    return fallbackName
end

function Scanner:Scan()
    if not MC.DecorationData then return end

    local result = {
        total            = 0,
        collectedCount   = 0,
        uncollectedCount = 0,
        bySource         = {},
        collected        = {},
    }

    local hideTradingPost = mod.db and mod.db.hideTradingPost
    for _, group in ipairs(MC.DecorationData) do
        if not (hideTradingPost and group.source == "tradingpost") then
            for _, deco in ipairs(group.decorations) do
                result.total = result.total + 1

                local isCollected, catalogInfo = self:CheckCollected(deco.decorID, deco.itemID)
                local icon = self:GetIcon(deco.decorID, deco.itemID)
                local decoName = self:GetName(deco.decorID, deco.itemID, deco.name)

                if catalogInfo then
                    if catalogInfo.iconTexture and catalogInfo.iconTexture ~= 0 then
                        icon = icon or catalogInfo.iconTexture
                    end
                    if catalogInfo.name and catalogInfo.name ~= "" then
                        decoName = catalogInfo.name
                    end
                end

                local entry = {
                    decorID       = deco.decorID,
                    itemID        = deco.itemID,
                    name          = decoName,
                    source        = deco.source,
                    sourceInfo    = deco.sourceInfo,
                    skillLine     = deco.skillLine,
                    waypoint      = deco.waypoint,
                    cost          = deco.cost,
                    dropInfo      = deco.dropInfo,
                    achievementID = deco.achievementID,
                    zone          = deco.zone,
                    renown        = deco.renown,
                    icon          = icon,
                    collected     = isCollected,
                }

                if isCollected then
                    result.collectedCount = result.collectedCount + 1
                    result.collected[#result.collected + 1] = entry
                else
                    result.uncollectedCount = result.uncollectedCount + 1
                    local src = deco.source
                    if not result.bySource[src] then result.bySource[src] = {} end
                    result.bySource[src][#result.bySource[src] + 1] = entry
                end
            end
        end
    end

    self.results = result
end
