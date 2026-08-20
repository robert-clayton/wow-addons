local _, MC = ...

local mod = MC.modulesByKey["toys"]
mod.Scanner = {}
local Scanner = mod.Scanner

Scanner.results = {}

function Scanner:Scan()
    if not MC.ToyData then return end

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

    local hasToyAPI  = PlayerHasToy ~= nil
    local hasInfoAPI = C_ToyBox and C_ToyBox.GetToyInfo

    local hideTradingPost = mod.db and mod.db.hideTradingPost
    for _, group in ipairs(MC.ToyData) do
        -- The trading-post toggle only affects what's shown; the account-wide
        -- tallies below run for every group so broadcasts don't depend on
        -- per-character display settings.
        local visible = MC.IsGroupVisible(group)
                        and not (hideTradingPost and group.source == "tradingpost")
        for _, toy in ipairs(group.toys) do
            local isCollected = false
            if hasToyAPI and toy.itemID and toy.itemID > 0 then
                isCollected = PlayerHasToy(toy.itemID) and true or false
            end

            local exp = toy.expansion or group.expansion or "_unknown"
            local available = MC.IsContentAvailable(toy)
            MC.AccumulateScanEntry(result, isCollected, MC.ScoreFor(toy), exp,
                toy.unavailable, available)

            local hideUnavailable = mod.db == nil or mod.db.hideUnavailable ~= false
            if not (toy.unavailable and not isCollected and hideUnavailable) then
                if visible then
                    -- Live name + icon from C_ToyBox (the data file is the
                    -- canonical name; live API just refines if Wowhead and
                    -- the client disagree).
                    local icon, toyName = nil, toy.name
                    if hasInfoAPI and toy.itemID and toy.itemID > 0 then
                        local _, name, fileID = C_ToyBox.GetToyInfo(toy.itemID)
                        if name and name ~= "" then toyName = name end
                        if fileID and fileID ~= 0 then icon = fileID end
                    end

                    local entry = {
                        moduleKey         = "toys",
                        itemID            = toy.itemID,
                        name              = toyName,
                        source            = toy.source,
                        sourceInfo        = toy.sourceInfo,
                        waypoint          = toy.waypoint,
                        overworldWaypoint = toy.overworldWaypoint,
                        cost              = toy.cost,
                        dropInfo          = toy.dropInfo,
                        achievementID     = toy.achievementID,
                        taskList          = toy.taskList,
                        zone              = toy.zone,
                        renown            = toy.renown,
                        icon              = icon,
                        collected         = isCollected,
                        expansion         = toy.expansion,
                        availableAfter    = toy.availableAfter,
                        future            = not available,
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
                        MC.BucketEntry(result, toy.source, entry)
                    end
                end
            end
        end
    end

    self.results = result
end
