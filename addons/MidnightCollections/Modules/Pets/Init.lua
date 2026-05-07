local _, MC = ...

--------------------------------------------------------------------------
-- Wild pet proximity alerts
--------------------------------------------------------------------------
local wildSpeciesLookup
local alertedThisSession = {}

local function BuildWildSpeciesLookup()
    wildSpeciesLookup = {}
    if not MC.PetData then return end
    for _, group in ipairs(MC.PetData) do
        if group.source == "wild" then
            for _, pet in ipairs(group.pets) do
                wildSpeciesLookup[pet.speciesID] = pet
            end
        end
    end
end

local function AlertForPet(speciesID, db)
    if not db or not db.wildAlerts then return end
    if not wildSpeciesLookup then BuildWildSpeciesLookup() end

    local pet = wildSpeciesLookup[speciesID]
    if not pet then return end
    if alertedThisSession[speciesID] then return end

    -- Check if already collected
    if C_PetJournal and C_PetJournal.GetNumCollectedInfo then
        local nc = C_PetJournal.GetNumCollectedInfo(speciesID)
        if nc and nc > 0 then return end
    end

    alertedThisSession[speciesID] = true
    print(format("%s Uncollected wild pet nearby: |cffffffff%s|r (%s)",
        MC.PREFIX, pet.name, pet.zone or ""))
    if RaidNotice_AddMessage then
        RaidNotice_AddMessage(RaidWarningFrame, format("Uncollected pet: %s", pet.name), ChatTypeInfo["RAID_WARNING"])
    end
    PlaySound(SOUNDKIT.RAID_WARNING or 8959, "Master")
end

local function OnNameplateAdded(unitToken, db)
    if not db or not db.wildAlerts then return end
    if not UnitIsWildBattlePet or not UnitBattlePetSpeciesID then return end
    if not UnitIsWildBattlePet(unitToken) then return end
    local speciesID = UnitBattlePetSpeciesID(unitToken)
    if speciesID and speciesID > 0 then
        AlertForPet(speciesID, db)
    end
end

local function OnMouseoverUnit(db)
    if not db or not db.wildAlerts then return end
    if not UnitIsWildBattlePet or not UnitBattlePetSpeciesID then return end
    if not UnitIsWildBattlePet("mouseover") then return end
    local speciesID = UnitBattlePetSpeciesID("mouseover")
    if speciesID and speciesID > 0 then
        AlertForPet(speciesID, db)
    end
end

-- Public: clear "already alerted" cache. Called when wildAlerts toggles back on
-- so the user can re-discover pets they already saw this session.
function MC.ClearPetAlertCache()
    wipe(alertedThisSession)
end

--------------------------------------------------------------------------
-- Module registration
--------------------------------------------------------------------------
local mod = MC.RegisterModule("pets", {
    label          = "Pets",
    icon           = "Interface\\Icons\\INV_Pet_BabyBlizzardBear",
    order          = 2,
    collectedKey   = "showCollected",
    collectedLabel = "collected",
    defaults       = {
        showCollected   = false,
        hideTradingPost = false,
        wildAlerts      = true,
        collapsed       = {},
    },
    events = { "NEW_PET_ADDED", "PET_JOURNAL_LIST_UPDATE", "BAG_UPDATE_DELAYED",
               "NAME_PLATE_UNIT_ADDED", "UPDATE_MOUSEOVER_UNIT", "ZONE_CHANGED_NEW_AREA" },
    onLogin = function(m)
        BuildWildSpeciesLookup()
    end,
    onEvent = function(m, event, arg1)
        if event == "NEW_PET_ADDED" or event == "PET_JOURNAL_LIST_UPDATE" then
            MC.ThrottledScan(m)
        elseif event == "BAG_UPDATE_DELAYED" then
            -- 3s throttle: BAG_UPDATE_DELAYED storms during raid/loot showers
            MC.ThrottledScan(m, 3)
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            if m.db and m.db.wildAlerts then OnNameplateAdded(arg1, m.db) end
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            if m.db and m.db.wildAlerts then OnMouseoverUnit(m.db) end
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            wipe(alertedThisSession)
        end
    end,
    tooltipLines = function(tt, m)
        local r = m.Scanner and m.Scanner.results
        if r and r.total then
            tt:AddLine(format("  Pets: %d / %d", r.collectedCount, r.total), 0.7, 0.7, 0.7)
        end
    end,
    printSummary = function(m)
        local r = m.Scanner and m.Scanner.results
        if r and r.total then
            print(format("%s [Pets] %d / %d collected (%d remaining)",
                MC.PREFIX, r.collectedCount, r.total, r.uncollectedCount))
            for _, srcType in ipairs(MC.PetSourceOrder) do
                local entries = r.bySource[srcType]
                if entries and #entries > 0 then
                    print(format("  %s: %d uncollected", MC.PetSourceLabels[srcType], #entries))
                end
            end
        end
    end,
})
