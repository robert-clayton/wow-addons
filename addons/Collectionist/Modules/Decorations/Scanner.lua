local _, MC = ...
local T = MC.SCORE_TIERS

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
            if MC.ScanNow then MC.ScanNow(mod) end
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
         + (info.remainingRedeemable or 0)
end

function Scanner:CheckCollected(decorID, itemID)
    if decorID and decorID > 0 and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByRecordID then
        -- Wrap the API in a closure rather than passing the function
        -- reference directly to pcall — some Blizzard C-API functions
        -- misbehave when their ref is pulled out of the namespace,
        -- returning empty tables instead of populated data.
        local ok, info = pcall(function()
            return C_HousingCatalog.GetCatalogEntryInfoByRecordID(DECOR_ENTRY_TYPE, decorID)
        end)
        if ok and info then
            local owned = ownedFromInfo(info)
            return owned > 0, info
        end
    end

    if itemID and itemID > 0 and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
        local ok, info = pcall(function()
            return C_HousingCatalog.GetCatalogEntryInfoByItem(itemID)
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
        local ok, _, _, _, _, itemIcon = pcall(GetItemInfoInstant, itemID)
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
        legacyCount        = 0,
        bySource           = {},
        collected          = {},
    }

    local hideTradingPost = mod.db and mod.db.hideTradingPost
    for _, group in ipairs(MC.DecorationData) do
        -- The trading-post toggle only affects what's shown; account-wide
        -- tallies below run for every group so broadcasts don't depend on
        -- per-character display settings. (CheckCollected now also runs
        -- for hidden trading-post groups — minor cost, non-default only.)
        local groupVisible = MC.IsGroupVisible(group)
                             and not (hideTradingPost and group.source == "tradingpost")
        for _, deco in ipairs(group.decorations) do
            local isCollected, catalogInfo = self:CheckCollected(deco.decorID, deco.itemID)

            -- Account-wide tallies use a fixed rule — unavailable and
            -- uncollected items are excluded, everything else counts —
            -- independent of display toggles. Decorations are bulk catalog
            -- items — most are found just by browsing the housing UI, so
            -- they score trivial flat; a per-entry `score` override wins.
            local w = deco.score or T.trivial
            local exp = deco.expansion or group.expansion or "_unknown"
            local available = MC.IsContentAvailable(deco)
            MC.AccumulateScanEntry(result, isCollected, w, exp,
                deco.unavailable, available)

            local hideUnavailable = mod.db == nil or mod.db.hideUnavailable ~= false
            if not (deco.unavailable and not isCollected and hideUnavailable) then
                if groupVisible then
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
                        moduleKey     = "decorations",
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
                        availableAfter = deco.availableAfter,
                        future         = not available,
                    }
                    if available then
                        result.total = result.total + 1
                        if isCollected then
                            result.collectedCount = result.collectedCount + 1
                            result.collected[#result.collected + 1] = entry
                        else
                            result.uncollectedCount = result.uncollectedCount + 1
                        end
                    end
                    if not (available and isCollected) then
                        MC.BucketEntry(result, deco.source, entry)
                    end
                end
            end
        end
    end

    self.results = result
end
