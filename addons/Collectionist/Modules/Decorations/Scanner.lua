local _, MC = ...

local mod = MC.modulesByKey["decorations"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

local DECOR_ENTRY_TYPE = 1 -- Enum.HousingCatalogEntryType.Decor

-- The housing catalog needs to be "warmed" before
-- GetCatalogEntryInfoByRecordID returns populated ownership data —
-- otherwise it hands back empty tables and every decoration scans as
-- not collected. Mirrors HomeDecor's bootstrap pattern.
local catalogReady = false
local catalogRetries = 0
local CATALOG_MAX_RETRIES = 6
-- Held at module scope so the searcher userdata isn't GC'd before its
-- ResultsUpdated callback fires. With a local-only ref, the searcher
-- sometimes dies between RunSearch and the callback, leaving the catalog
-- un-warmed → every decor scans as 0/260.
local catalogSearcher = nil

local function warmCatalog()
    if catalogReady then return end
    catalogRetries = catalogRetries + 1
    if catalogRetries > CATALOG_MAX_RETRIES then return end

    if not (C_HousingCatalog and C_HousingCatalog.CreateCatalogSearcher) then
        C_Timer.After(1, warmCatalog)
        return
    end

    catalogSearcher = C_HousingCatalog.CreateCatalogSearcher()
    local s = catalogSearcher
    if not s then
        C_Timer.After(1, warmCatalog)
        return
    end

    if s.SetOwnedOnly             then s:SetOwnedOnly(false) end
    if s.SetCollected             then s:SetCollected(true)  end
    if s.SetUncollected           then s:SetUncollected(true) end
    if s.SetAutoUpdateOnParamChanges then s:SetAutoUpdateOnParamChanges(false) end

    if s.SetResultsUpdatedCallback then
        s:SetResultsUpdatedCallback(function()
            if catalogReady then return end
            catalogReady = true
            -- Re-run the decoration scan now that ownership lookups
            -- will return real data.
            if Scanner.Scan then
                pcall(Scanner.Scan, Scanner)
                if MC.RefreshActive then MC.RefreshActive() end
                if MC.RefreshPeerIndicator then MC.RefreshPeerIndicator() end
            end
        end)
    end

    if s.RunSearch then s:RunSearch() end

    -- Failsafe: if the callback never fires after 5s, retry the warmup.
    -- Don't reassign `catalogSearcher` if the previous one still has a
    -- pending callback — that would orphan it and re-introduce the GC
    -- race the module-level reference is meant to prevent.
    C_Timer.After(5, function()
        if catalogReady then return end
        if catalogRetries >= CATALOG_MAX_RETRIES then return end
        -- Drop the previous searcher's callback so its eventual fire
        -- is a no-op, then create a fresh one.
        if catalogSearcher and catalogSearcher.SetResultsUpdatedCallback then
            pcall(catalogSearcher.SetResultsUpdatedCallback, catalogSearcher, function() end)
        end
        warmCatalog()
    end)
end

local warmFrame = CreateFrame("Frame")
warmFrame:RegisterEvent("PLAYER_LOGIN")
warmFrame:SetScript("OnEvent", function() C_Timer.After(0, warmCatalog) end)

-- Sum the four ownership counters; any one being > 0 means the player
-- has earned this decor at some point (placed in current/other house,
-- in storage, or destroyed).
local function ownedFromInfo(info)
    if not info then return 0 end
    return (info.numPlaced or 0)
         + (info.quantity or 0)
         + (info.totalNumPlaced or 0)
         + (info.totalNumStored or 0)
end

function Scanner:CheckCollected(decorID, itemID)
    if decorID and decorID > 0 and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByRecordID then
        -- Wrap the API in a closure rather than passing the function
        -- reference directly to pcall — some Blizzard C-API functions
        -- misbehave when their ref is pulled out of the namespace,
        -- returning empty tables instead of populated data.
        local ok, info = pcall(function()
            return C_HousingCatalog.GetCatalogEntryInfoByRecordID(DECOR_ENTRY_TYPE, decorID, true)
        end)
        if ok and info then
            local owned = ownedFromInfo(info)
            return owned > 0, info
        end
    end

    if itemID and itemID > 0 and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
        local ok, info = pcall(function()
            return C_HousingCatalog.GetCatalogEntryInfoByItem(itemID, true)
        end)
        if ok and info then
            local owned = ownedFromInfo(info)
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

    -- See Mounts/Scanner.lua for the rationale on totalAll.
    local result = {
        total              = 0,
        collectedCount     = 0,
        uncollectedCount   = 0,
        totalAll           = 0,
        collectedCountAll  = 0,
        byExpansion        = {},
        score              = 0,
        legacyScore        = 0,
        legacyCount        = 0,
        bySource           = {},
        collected          = {},
    }

    local hideTradingPost = mod.db and mod.db.hideTradingPost
    for _, group in ipairs(MC.DecorationData) do
        local visible = MC.IsGroupVisible(group)
        if not (hideTradingPost and group.source == "tradingpost") then
            for _, deco in ipairs(group.decorations) do
                local isCollected, catalogInfo = self:CheckCollected(deco.decorID, deco.itemID)

                local hideUnavailable = mod.db == nil or mod.db.hideUnavailable ~= false
                if not (deco.unavailable and not isCollected and hideUnavailable) then
                    result.totalAll = result.totalAll + 1
                    if isCollected then
                        result.collectedCountAll = result.collectedCountAll + 1
                        local w = MC.ScoreFor(deco)
                        if deco.unavailable then
                            result.legacyCount = result.legacyCount + 1
                            result.legacyScore = result.legacyScore + w
                        else
                            result.score = result.score + w
                        end
                    end

                    local exp = deco.expansion or group.expansion or "_unknown"
                    local b = result.byExpansion[exp]
                    if not b then
                        b = { total = 0, collected = 0 }
                        result.byExpansion[exp] = b
                    end
                    b.total = b.total + 1
                    if isCollected then b.collected = b.collected + 1 end

                    if visible then
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
                            taskList      = deco.taskList,
                            zone          = deco.zone,
                            renown        = deco.renown,
                            icon          = icon,
                            collected     = isCollected,
                            expansion     = deco.expansion,
                        }
                        result.total = result.total + 1
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
        end
    end

    self.results = result
end
