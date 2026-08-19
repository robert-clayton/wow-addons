local function fail(message)
    error(message, 2)
end

local function equal(actual, expected, message)
    if actual ~= expected then
        fail(string.format("%s (expected %s, got %s)", message, tostring(expected), tostring(actual)))
    end
end

local function truthy(value, message)
    if not value then fail(message) end
end

local function loadAddon(path, namespace)
    local chunk, err = loadfile(path)
    if not chunk then fail(err) end
    return chunk("Collectionist", namespace)
end

format = string.format
time = os.time
wipe = function(t) for k in pairs(t) do t[k] = nil end end
strsplit = function(delimiter, value, limit)
    local parts, start = {}, 1
    value = value or ""
    while not limit or #parts < limit - 1 do
        local first, last = string.find(value, delimiter, start, true)
        if not first then break end
        parts[#parts + 1] = string.sub(value, start, first - 1)
        start = last + 1
    end
    parts[#parts + 1] = string.sub(value, start)
    return unpack(parts)
end
CopyTable = function(source)
    local copy = {}
    for k, v in pairs(source) do
        copy[k] = type(v) == "table" and CopyTable(v) or v
    end
    return copy
end

local function newFrameFactory()
    local frames = {}
    local function createFrame()
        local frame = { scripts = {}, events = {}, shown = true }
        function frame:SetScript(name, fn) self.scripts[name] = fn end
        function frame:RegisterEvent(name) self.events[name] = true end
        function frame:UnregisterEvent(name) self.events[name] = nil end
        function frame:Show() self.shown = true end
        function frame:Hide() self.shown = false end
        function frame:IsShown() return self.shown end
        frames[#frames + 1] = frame
        return frame
    end
    return createFrame, frames
end

-- Item-priced costs render both item slots, use inventory affordability,
-- cache item metadata, and retry it after GET_ITEM_INFO_RECEIVED.
do
    local createFrame = newFrameFactory()
    CreateFrame = createFrame
    SlashCmdList = {}
    StaticPopupDialogs = {}
    local color = { 1, 1, 1 }
    local colors = {
        ttTitle = color, ttLabel = color, ttValue = color, ttCostBad = color,
        ttDropMob = color, ttDropRate = color, ttBoss = color, ttSpec = color,
        ttHintGreen = color, ttHintBlue = color,
    }
    local mui = {
        Theme = { colors = colors },
        Themes = { modern = true, simple = true },
        ChatPrefix = function() return "[Collectionist]" end,
        FormatGold = function(amount) return tostring(amount) end,
    }
    LibStub = function(name)
        if name == "MidnightUI-1.0" then return mui end
    end
    GameTooltip = {
        IsShown = function() return false end,
        Hide = function() end,
    }
    local itemNames = { [111] = "First Token", [222] = "Second Token" }
    C_Item = {
        GetItemNameByID = function(itemID) return itemNames[itemID] end,
        GetItemIconByID = function(itemID) return itemID * 10 end,
        GetItemCount = function(itemID) return itemID == 111 and 2 or 1 end,
    }

    local MC = {}
    loadAddon("addons/Collectionist/Core.lua", MC)
    local tooltip = { doubleLines = {} }
    function tooltip:SetOwner() end
    function tooltip:ClearAllPoints() end
    function tooltip:SetPoint() end
    function tooltip:AddLine() end
    function tooltip:AddDoubleLine(left, right)
        self.doubleLines[#self.doubleLines + 1] = { left, right }
    end
    function tooltip:Show() end
    MC.GetInfoTooltip = function() return tooltip end

    MC.ShowItemInfoTooltip({}, {
        source = "vendor",
        cost = { item = { 111, 2 }, item2 = { 222, 3 } },
    })
    local renderedCost
    for _, line in ipairs(tooltip.doubleLines) do
        if line[1] == "Cost:" then renderedCost = line[2] end
    end
    truthy(renderedCost and renderedCost:find("2 |T1110:0|t First Token", 1, true),
        "primary item cost tooltip")
    truthy(renderedCost and renderedCost:find("|cffff4d4d3 |T2220:0|t Second Token|r", 1, true),
        "secondary item cost affordability")

    itemNames[111] = "Refreshed Token"
    tooltip.doubleLines = {}
    MC.ShowItemInfoTooltip({}, { source = "vendor", cost = { item = { 111, 2 } } })
    local cached = tooltip.doubleLines[#tooltip.doubleLines][2]
    truthy(cached:find("First Token", 1, true), "item metadata should be cached")
    MC.eventFrame.scripts.OnEvent(MC.eventFrame, "GET_ITEM_INFO_RECEIVED", 111)
    tooltip.doubleLines = {}
    MC.ShowItemInfoTooltip({}, { source = "vendor", cost = { item = { 111, 2 } } })
    local refreshed = tooltip.doubleLines[#tooltip.doubleLines][2]
    truthy(refreshed:find("Refreshed Token", 1, true),
        "item metadata should retry after cache notification")
end

-- Stable legacy denominator and score separation.
do
    local MC = {}
    loadAddon("addons/Collectionist/Data/Constants.lua", MC)
    local result = {
        totalAll = 0, collectedCountAll = 0, score = 0,
        legacyCount = 0, byExpansion = {},
    }
    MC.AccumulateScanEntry(result, false, 100, "midnight", true)
    MC.AccumulateScanEntry(result, true, 100, "midnight", true)
    equal(result.totalAll, 2, "legacy items must always be in the denominator")
    equal(result.collectedCountAll, 1, "collected legacy count")
    equal(result.legacyCount, 1, "legacy ownership is tracked separately")
    equal(result.score, 0, "legacy items do not add score")
end

-- Future content remains discoverable without entering obtainable totals or
-- score until its release instant.
do
    local MC = {}
    GetCurrentRegion = function() return 1 end
    local serverNow = 1787065199
    -- The synchronized server clock must win even when the local OS clock is
    -- already past the release instant.
    GetServerTime = function() return serverNow end
    time = function() return 1787069999 end
    loadAddon("addons/Collectionist/Data/Constants.lua", MC)

    local future = { availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 }
    equal(MC.IsContentAvailable(future), false, "future content before unlock")
    equal(MC.GetAvailabilityLabel(future), "August 18, 2026", "future release label")
    equal(MC.GetAvailabilityBadge(future), "Aug 18", "future release badge")

    local result = {
        totalAll = 0, collectedCountAll = 0, score = 0,
        legacyCount = 0, byExpansion = {},
    }
    equal(MC.AccumulateScanEntry(result, false, 50, "midnight", false, false),
        false, "future accumulation should report exclusion")
    equal(result.totalAll, 0, "future content excluded from denominator")
    equal(result.score, 0, "future content excluded from score")
    equal(result.futureCount, 1, "future content tracked for planning")

    serverNow = MC.ResolveContentRelease(MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2)
    equal(MC.IsContentAvailable(future), true, "content unlock instant")
    equal(MC.AccumulateScanEntry(result, true, 50, "midnight", false, true),
        true, "released content should enter totals")
    equal(result.totalAll, 1, "released content denominator")
    equal(result.score, 50, "released content score")
    GetCurrentRegion = function() return 3 end
    equal(MC.ResolveContentRelease(MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2),
        1787112000, "European regional unlock")
    equal(MC.GetAvailabilityLabel(future), "August 19, 2026",
        "European release label")
    equal(MC.GetAvailabilityBadge(future), "Aug 19", "European release badge")
    GetServerTime = function() return nil end
    time = function() return 12345 end
    equal(MC.GetCurrentTimestamp(), 12345,
        "local clock fallback when the server clock is unavailable")
    GetCurrentRegion, GetServerTime = nil, nil
    time = os.time
end


-- Scanner integration keeps a future collectible in its source list for
-- planning while excluding it from both visible and account-wide progress.
do
    GetCurrentRegion = function() return 1 end
    local now = 1787065199
    GetServerTime = function() return now end
    time = function() return now end
    local MC = { modulesByKey = { pets = { db = {} } } }
    loadAddon("addons/Collectionist/Data/Constants.lua", MC)
    MC.IsGroupVisible = function() return true end
    MC.PetData = {
        { source = "prey", expansion = "midnight", pets = {
            { speciesID = 1, name = "Future Pet", source = "prey",
              expansion = "midnight",
              availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
        } },
    }
    C_PetJournal = {
        GetNumCollectedInfo = function() return 0 end,
        GetPetInfoBySpeciesID = function() return nil, nil, 8 end,
    }
    loadAddon("addons/Collectionist/Modules/Pets/Scanner.lua", MC)
    local scanner = MC.modulesByKey.pets.Scanner
    scanner:Scan()
    equal(scanner.results.totalAll, 0, "future pet account denominator")
    equal(scanner.results.total, 0, "future pet visible denominator")
    equal(#scanner.results.bySource.prey, 1, "future pet remains visible")
    equal(scanner.results.bySource.prey[1].future, true, "future pet row badge state")

    now = MC.ResolveContentRelease(MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2)
    scanner:Scan()
    equal(scanner.results.totalAll, 1, "released pet account denominator")
    equal(scanner.results.total, 1, "released pet visible denominator")
    equal(scanner.results.uncollectedCount, 1, "released pet remaining count")
    GetCurrentRegion, GetServerTime, C_PetJournal = nil, nil, nil
    time = os.time
end

-- Current expansion is resolved independently for each module.
do
    local MC = {
        _registeredExpansions = { tww = true, midnight = true },
        _registeredExpansionsByModule = {
            mounts = { midnight = true },
            pets = { tww = true },
        },
    }
    loadAddon("addons/Collectionist/Data/Expansions.lua", MC)
    equal(MC.GetLatestExpansion("mounts"), "midnight", "mount current expansion")
    equal(MC.GetLatestExpansion("pets"), "tww", "pet current expansion")
    equal(MC.GetLatestExpansion(), "midnight", "global latest expansion")
end

-- Communication queues survive encounters and report actual send success.
do
    CreateFrame = newFrameFactory()
    IsInGuild = function() return true end
    IsInGroup = function() return false end
    UnitAffectingCombat = function() return false end
    BNConnected = function() return false end
    local sent = 0
    C_ChatInfo = {
        RegisterAddonMessagePrefix = function() return true end,
        SendAddonMessage = function() sent = sent + 1; return nil end,
    }
    local MC = {}
    loadAddon("addons/Collectionist/Modules/Roster/Comms.lua", MC)
    local callbackResult
    MC.Comms.encounterPause = true
    truthy(MC.Comms:Send("u", "snapshot", "GUILD", nil,
        function(ok) callbackResult = ok end), "encounter send should queue")
    MC.Comms.frame.scripts.OnUpdate(MC.Comms.frame, 2)
    equal(#MC.Comms.queue, 1, "encounter must retain queued messages")
    equal(sent, 0, "encounter pump must be paused")
    MC.Comms.encounterPause = false
    MC.Comms.frame.scripts.OnUpdate(MC.Comms.frame, 2)
    equal(sent, 1, "queued message should send after encounter")
    equal(callbackResult, true, "successful API send callback")
end

-- Interleaved bitmap generations from one sender can never combine into a
-- valid snapshot: a newer generation supersedes the old partial transfer.
do
    local createFrame, frames = newFrameFactory()
    CreateFrame = createFrame
    IsInGuild = function() return true end
    IsInGroup = function() return false end
    UnitAffectingCombat = function() return false end
    BNConnected = function() return false end
    GetServerTime = function() return 1000 end
    GetTimePreciseSec = function() return 1.25 end
    C_ChatInfo = {
        RegisterAddonMessagePrefix = function() return true end,
        SendAddonMessage = function() return nil end,
    }

    local MC = {}
    loadAddon("addons/Collectionist/Modules/Roster/Comms.lua", MC)
    local received = {}
    MC.Comms:RegisterPrefix("GUILD", "b", function(payload)
        received[#received + 1] = payload
    end)

    local fingerprint = "layout-fingerprint"
    local oldPayload = string.rep("A", 900)
    local newPayload = string.rep("B", 900)
    truthy(MC.Comms:SendBitmap(fingerprint, oldPayload, "GUILD"),
        "old bitmap should queue")
    local oldChunks = {}
    for _, message in ipairs(MC.Comms.queue) do
        truthy(#message.body <= 250, "old bitmap chunk wire budget")
        oldChunks[#oldChunks + 1] = message.body
    end
    truthy(#oldChunks > 1, "large bitmap should be chunked")

    MC.Comms.queue = {}
    truthy(MC.Comms:SendBitmap(fingerprint, newPayload, "GUILD"),
        "new bitmap should queue")
    local newChunks = {}
    for _, message in ipairs(MC.Comms.queue) do
        truthy(#message.body <= 250, "new bitmap chunk wire budget")
        newChunks[#newChunks + 1] = message.body
    end
    equal(#newChunks, #oldChunks, "same-size bitmap chunk count")

    local listener = frames[2]
    local function receive(body)
        listener.scripts.OnEvent(listener, "CHAT_MSG_ADDON",
            "MC", body, "GUILD", "Peer-Realm")
    end
    receive(oldChunks[1])
    receive(newChunks[1])
    for i = 2, #oldChunks do receive(oldChunks[i]) end
    equal(#received, 0, "superseded chunks must not complete")
    for i = 2, #newChunks do receive(newChunks[i]) end
    equal(#received, 1, "new bitmap generation should complete once")
    equal(received[1], fingerprint .. "|" .. newPayload,
        "only the new generation may dispatch")
    GetServerTime, GetTimePreciseSec = nil, nil
end

-- ScanNow preserves the last result when a scanner explicitly defers, and a
-- future-content unlock schedules a rescan even in a long-running session.
do
    local createFrame = newFrameFactory()
    CreateFrame = createFrame
    SlashCmdList = {}
    StaticPopupDialogs = {}
    GameTooltip = { IsShown = function() return false end, Hide = function() end }
    local color = { 1, 1, 1 }
    local mui = {
        Theme = { colors = {
            ttTitle = color, ttLabel = color, ttValue = color, ttCostBad = color,
            ttDropMob = color, ttDropRate = color, ttBoss = color, ttSpec = color,
            ttHintGreen = color, ttHintBlue = color,
        } },
        Themes = { modern = true, simple = true },
        ChatPrefix = function() return "[Collectionist]" end,
        FormatGold = function(amount) return tostring(amount) end,
    }
    LibStub = function(name) if name == "MidnightUI-1.0" then return mui end end
    C_Item = {}

    local scheduled
    C_Timer = { After = function(delay, fn) scheduled = { delay, fn } end }
    local serverNow = 100
    GetServerTime = function() return serverNow end
    time = function() return 1000 end
    local MC = {}
    loadAddon("addons/Collectionist/Core.lua", MC)
    MC.GetCurrentTimestamp = function() return GetServerTime() end

    local completed = 0
    MC.OnScanComplete = function() completed = completed + 1 end
    local deferred = { key = "deferred", Scanner = { Scan = function() return false end } }
    equal(MC.ScanNow(deferred), false, "explicit scan deferral")
    equal(completed, 0, "deferred scan must not publish completion")
    deferred.Scanner.Scan = function() return true end
    equal(MC.ScanNow(deferred), true, "completed scan")
    equal(completed, 1, "completed scan notification")

    MC.CONTENT_RELEASE = { TEST_PHASE = 110 }
    MC.modules = { deferred }
    MC.ScheduleContentReleaseScan()
    truthy(scheduled, "future release should schedule a timer")
    equal(scheduled[1], 11, "release rescan delay")
    serverNow = 111
    scheduled[2]()
    equal(completed, 2, "release timer should rescan modules")
    GetServerTime = nil
    time = os.time
end

-- Achievement and Housing API adapters use the current return slots and
-- signatures, and never overwrite a valid achievement snapshot while its
-- cache is unavailable.
do
    local MC = { modulesByKey = { achievements = {} } }
    loadAddon("addons/Collectionist/Data/Constants.lua", MC)
    MC.AchievementData = {
        { source = "season", category = "features", expansion = "midnight",
          achievements = { { achievementID = 42, name = "Fallback" } } },
    }
    MC.IsGroupVisible = function() return true end
    MC.IsTaskCompleted = function() return false end
    CanShowAchievementUI = function() return true end
    C_AchievementInfo = {
        GetAchievementInfo = function()
            return 42, "Live Name", 10, true, 1, 1, 2026,
                "Description", 12345, 987654
        end,
    }
    loadAddon("addons/Collectionist/Modules/Achievements/Scanner.lua", MC)
    truthy(MC.modulesByKey.achievements.Scanner:Scan(), "achievement scan ready")
    equal(MC.modulesByKey.achievements.Scanner.results.collected[1].icon,
        987654, "achievement icon return slot")
    local committed = MC.modulesByKey.achievements.Scanner.results
    C_AchievementInfo.GetAchievementInfo = function() return nil end
    equal(MC.modulesByKey.achievements.Scanner:Scan(), false,
        "achievement scan should defer on empty cache")
    equal(MC.modulesByKey.achievements.Scanner.results, committed,
        "deferred achievement scan preserves prior results")

    local createFrame = newFrameFactory()
    CreateFrame = createFrame
    C_Timer = { After = function() end }
    local recordArgs, itemArgs
    C_HousingCatalog = {
        GetCatalogEntryInfoByRecordID = function(...)
            recordArgs = select("#", ...)
            return { remainingRedeemable = 1 }
        end,
        GetCatalogEntryInfoByItem = function(...)
            itemArgs = select("#", ...)
            return { remainingRedeemable = 1 }
        end,
    }
    C_HousingDecor = {}
    GetItemInfoInstant = function()
        return 10, "type", "subtype", "INVTYPE", 24680
    end
    local decorMC = { modulesByKey = { decorations = {} } }
    loadAddon("addons/Collectionist/Data/Constants.lua", decorMC)
    decorMC.IsGroupVisible = function() return true end
    loadAddon("addons/Collectionist/Modules/Decorations/Scanner.lua", decorMC)
    local decorScanner = decorMC.modulesByKey.decorations.Scanner
    local owned = decorScanner:CheckCollected(77, nil)
    equal(owned, true, "redeemable decor counts as owned")
    equal(recordArgs, 2, "record lookup current signature")
    owned = decorScanner:CheckCollected(nil, 88)
    equal(owned, true, "item lookup redeemable decor")
    equal(itemArgs, 1, "item lookup current signature")
    equal(decorScanner:GetIcon(nil, 88), 24680, "instant item icon return slot")
end

-- Rare and treasure scanners also retain their committed snapshots until all
-- advertised achievement criteria are available.
do
    CanShowAchievementUI = function() return true end
    local criteriaCount = 1
    GetAchievementNumCriteria = function() return criteriaCount end
    GetAchievementCriteriaInfo = function(_, index)
        return "Criterion " .. index, 0, index == 1, 0, 1, nil, 0, 9000 + index
    end

    local rareMC = { modulesByKey = { rares = {} } }
    loadAddon("addons/Collectionist/Data/Constants.lua", rareMC)
    rareMC.IsGroupVisible = function() return true end
    rareMC.RareData = {
        { achievementID = 10, criteriaCount = 2, source = "coiled_isle",
          zone = "Test", expansion = "midnight", criteriaNPCIDs = { 1, 2 } },
    }
    rareMC.RareNPCs = { [1] = { 1, 0.1, 0.1 }, [2] = { 1, 0.2, 0.2 } }
    loadAddon("addons/Collectionist/Modules/Rares/Scanner.lua", rareMC)
    local rareScanner = rareMC.modulesByKey.rares.Scanner
    local rarePrior = { sentinel = "rare" }
    rareScanner.results = rarePrior
    equal(rareScanner:Scan(), false, "partial rare criteria should defer")
    equal(rareScanner.results, rarePrior, "rare defer preserves prior snapshot")
    criteriaCount = 2
    equal(rareScanner:Scan(), true, "complete rare criteria scan")
    equal(rareScanner.results.totalAll, 2, "rare criteria denominator")

    criteriaCount = 1
    local treasureMC = { modulesByKey = { treasures = {} } }
    loadAddon("addons/Collectionist/Data/Constants.lua", treasureMC)
    treasureMC.IsGroupVisible = function() return true end
    treasureMC.TreasureData = {
        { achievementID = 20, criteriaCount = 2, source = "coiled_isle",
          zone = "Test", expansion = "midnight", criteriaNames = { "One", "Two" } },
    }
    treasureMC.TreasureCoords = {
        One = { 1, 0.1, 0.1 }, Two = { 1, 0.2, 0.2 },
    }
    loadAddon("addons/Collectionist/Modules/Treasures/Scanner.lua", treasureMC)
    local treasureScanner = treasureMC.modulesByKey.treasures.Scanner
    local treasurePrior = { sentinel = "treasure" }
    treasureScanner.results = treasurePrior
    equal(treasureScanner:Scan(), false, "partial treasure criteria should defer")
    equal(treasureScanner.results, treasurePrior,
        "treasure defer preserves prior snapshot")
    criteriaCount = 2
    equal(treasureScanner:Scan(), true, "complete treasure criteria scan")
    equal(treasureScanner.results.totalAll, 2, "treasure criteria denominator")
end

-- Rare and treasure bitmap IDs are locale-independent criteria keys, and
-- partial achievement caches never emit a bitmap.
do
    CreateFrame = newFrameFactory()
    local criteriaCounts = { [10] = 2, [20] = 1 }
    GetAchievementNumCriteria = function(id) return criteriaCounts[id] or 0 end
    GetAchievementCriteriaInfo = function(id, idx)
        local complete = (id == 10 and idx == 1) or id == 20
        return "localized-name-" .. id .. "-" .. idx, 0, complete
    end
    local MC = {
        MountData = {}, PetData = {}, ToyData = {}, DecorationData = {},
        RareData = { { achievementID = 10, criteriaCount = 2 } },
        TreasureData = { { achievementID = 20, criteriaCount = 1 } },
        modulesByKey = {},
    }
    loadAddon("addons/Collectionist/Modules/Roster/Bitmap.lua", MC)
    MC.Bitmap:Init()
    equal(MC.Bitmap.ids.rares[1], "10:1", "rare criterion key")
    equal(MC.Bitmap.ids.treasures[1], "20:1", "treasure criterion key")

    criteriaCounts[10] = 1
    MC.Bitmap._criteriaReady = false
    equal(MC.Bitmap:Build(), nil, "partial criteria cache must defer bitmap")

    criteriaCounts[10] = 2
    MC.Bitmap._criteriaReady = false
    local encoded = MC.Bitmap:Build()
    truthy(encoded and encoded ~= "", "complete criteria cache should build bitmap")
    local decoded = MC.Bitmap:Decode(encoded)
    equal(decoded.rares["10:1"], true, "completed rare bit")
    equal(decoded.rares["10:2"], nil, "incomplete rare bit")
    equal(decoded.treasures["20:1"], true, "completed treasure bit")
end

-- Shipped criterion metadata must cover every stable rare/treasure bit and
-- resolve to a waypoint on non-English clients.
do
    local MC = {
        SCORE_TIERS = { trivial = 1, short = 5, medium = 10, long = 25 },
        MAP = setmetatable({}, { __index = function(_, key) return key end }),
    }
    function MC.RegisterContent(expansionKey, moduleKey, groups)
        if moduleKey == "rares" then MC.RareData = groups end
        if moduleKey == "treasures" then MC.TreasureData = groups end
    end
    loadAddon("addons/Collectionist/Modules/Rares/Data/Rares.lua", MC)
    loadAddon("addons/Collectionist/Modules/Treasures/Data/Treasures.lua", MC)

    for _, achievement in ipairs(MC.RareData) do
        equal(#achievement.criteriaNPCIDs, achievement.criteriaCount,
            "rare criterion NPC map length")
        for _, npcID in ipairs(achievement.criteriaNPCIDs) do
            truthy(MC.RareNPCs[npcID], "rare criterion NPC must have coordinates: " .. npcID)
        end
    end
    for _, achievement in ipairs(MC.TreasureData) do
        equal(#achievement.criteriaNames, achievement.criteriaCount,
            "treasure criterion metadata length")
        for _, metadataName in ipairs(achievement.criteriaNames) do
            truthy(MC.TreasureCoords[metadataName],
                "treasure criterion must have coordinates: " .. metadataName)
        end
    end
end

-- Fresh installs default to no sharing; an existing onboarding consent flag
-- preserves the feature across upgrades.
do
    local function rosterNamespace(db, accountDB)
        CollectionistDB = accountDB
        C_Timer = { After = function() end }
        UnitClass = function() return "Warrior", "WARRIOR" end
        UnitName = function() return "Tester" end
        GetRealmName = function() return "Realm" end
        local MC = {
            db = db,
            modules = {},
            RosterDB = {},
            Comms = {
                handlers = {},
                RegisterPrefix = function(self, channel, sub, fn)
                    self.handlers[channel .. ":" .. sub] = fn
                end,
            },
        }
        loadAddon("addons/Collectionist/Modules/Roster/Init.lua", MC)
        MC.RosterInit()
        return MC
    end

    local fresh = rosterNamespace({ disabledModules = {} }, {})
    equal(fresh.db.rosterEnabled, false, "fresh install sharing consent")
    local existing = rosterNamespace({ disabledModules = {}, _onboardingShown = true },
        { _onboardingShown = true })
    equal(existing.db.rosterEnabled, true, "existing consent migration")
end

-- Snapshot hashes advance after successful delivery and suppress unchanged
-- count/score messages on the next scan.
do
    CollectionistDB = { _onboardingShown = true }
    C_Timer = { After = function() end }
    UnitClass = function() return "Warrior", "WARRIOR" end
    UnitName = function() return "Tester" end
    GetRealmName = function() return "Realm" end
    local sends = 0
    local comms = {
        handlers = {},
        RegisterPrefix = function(self, channel, sub, fn)
            self.handlers[channel .. ":" .. sub] = fn
        end,
        Send = function(_, _, _, _, _, callback)
            sends = sends + 1
            if callback then callback(true) end
            return true
        end,
    }
    local MC = {
        db = { disabledModules = {}, _onboardingShown = true, rosterEnabled = true },
        RosterDB = {},
        Comms = comms,
        version = "test",
        modules = {
            {
                key = "mounts",
                Scanner = { results = {
                    totalAll = 2, collectedCountAll = 1,
                    score = 5, legacyCount = 0,
                } },
            },
        },
    }
    loadAddon("addons/Collectionist/Modules/Roster/Init.lua", MC)
    MC.RosterInit()
    truthy(MC.RosterBroadcastIfChanged("GUILD"), "first snapshot should queue")
    equal(sends, 2, "count and score streams should send")
    equal(MC.RosterBroadcastIfChanged("GUILD"), false, "unchanged snapshot should dedupe")
    equal(sends, 2, "unchanged snapshot must not re-send")
end

-- Patch 12.0.7 and 12.1 content is additive, complete, and collision-free
-- with the checked-in Midnight catalogs it extends.
do
    local MC = {}
    loadAddon("addons/Collectionist/Data/Constants.lua", MC)
    loadAddon("addons/Collectionist/Data/Locations.lua", MC)

    function MC.RegisterContent(_, moduleKey, groups)
        local targets = {
            mounts = "MountData",
            pets = "PetData",
            toys = "ToyData",
            rares = "RareData",
            treasures = "TreasureData",
            decorations = "DecorationData",
            achievements = "AchievementData",
        }
        local key = targets[moduleKey]
        truthy(key, "unknown content module in fixture: " .. tostring(moduleKey))
        MC[key] = MC[key] or {}
        for _, group in ipairs(groups) do
            group.expansion = group.expansion or expansionKey
            group.moduleKey = group.moduleKey or moduleKey
            local list = group[({
                mounts = "mounts", pets = "pets", toys = "toys",
                decorations = "decorations", achievements = "achievements",
            })[moduleKey]]
            for _, entry in ipairs(list or {}) do
                entry.expansion = entry.expansion or expansionKey
                entry.moduleKey = entry.moduleKey or moduleKey
                entry.availableAfter = entry.availableAfter or group.availableAfter
            end
            MC[key][#MC[key] + 1] = group
        end
    end

    local baseFiles = {
        "addons/Collectionist/Modules/Mounts/Data/Mounts.lua",
        "addons/Collectionist/Modules/Pets/Data/Pets.lua",
        "addons/Collectionist/Modules/Toys/Data/Toys.lua",
        "addons/Collectionist/Modules/Rares/Data/Rares.lua",
        "addons/Collectionist/Modules/Treasures/Data/Treasures.lua",
        "addons/Collectionist/Modules/Decorations/Data/Decorations.lua",
        "addons/Collectionist/Modules/Achievements/Data/Achievements.lua",
    }
    local patchFiles = {
        "addons/Collectionist/Modules/Mounts/Data/Patch120007.lua",
        "addons/Collectionist/Modules/Pets/Data/Patch120007.lua",
        "addons/Collectionist/Modules/Toys/Data/Patch120007.lua",
        "addons/Collectionist/Modules/Rares/Data/Patch120007.lua",
        "addons/Collectionist/Modules/Decorations/Data/Patch120007.lua",
        "addons/Collectionist/Modules/Achievements/Data/Patch120007.lua",
    }
    local patch120100Files = {
        "addons/Collectionist/Modules/Mounts/Data/Patch120100.lua",
        "addons/Collectionist/Modules/Pets/Data/Patch120100.lua",
        "addons/Collectionist/Modules/Toys/Data/Patch120100.lua",
        "addons/Collectionist/Modules/Rares/Data/Patch120100.lua",
        "addons/Collectionist/Modules/Treasures/Data/Patch120100.lua",
        "addons/Collectionist/Modules/Decorations/Data/Patch120100.lua",
        "addons/Collectionist/Modules/Achievements/Data/Patch120100.lua",
    }

    local fields = {
        mounts = "mounts",
        pets = "pets",
        toys = "toys",
        rares = "rares",
        treasures = "treasures",
        decorations = "decorations",
        achievements = "achievements",
    }
    local dataFields = {
        mounts = "MountData",
        pets = "PetData",
        toys = "ToyData",
        rares = "RareData",
        treasures = "TreasureData",
        decorations = "DecorationData",
        achievements = "AchievementData",
    }
    local function entries(moduleKey)
        local result = {}
        for _, group in ipairs(MC[dataFields[moduleKey]] or {}) do
            local list = group[fields[moduleKey]]
            if list then
                for _, entry in ipairs(list) do result[#result + 1] = entry end
            elseif (moduleKey == "rares" or moduleKey == "treasures") and group.achievementID then
                result[#result + 1] = group
            end
        end
        return result
    end
    local function assertUnique(moduleKey, idField)
        local seen = {}
        for _, entry in ipairs(entries(moduleKey)) do
            local id = entry[idField]
            truthy(id, moduleKey .. " entry missing " .. idField)
            truthy(not seen[id], string.format("duplicate %s %s in %s", idField, id, moduleKey))
            seen[id] = true
        end
    end
    local function assertIDs(moduleKey, idField, expected, label)
        local present = {}
        for _, entry in ipairs(entries(moduleKey)) do present[entry[idField]] = true end
        for _, id in ipairs(expected) do
            truthy(present[id], string.format("missing %s %s: %s", label, idField, id))
        end
    end
    local function findEntry(moduleKey, idField, expectedID)
        for _, entry in ipairs(entries(moduleKey)) do
            if entry[idField] == expectedID then return entry end
        end
    end

    for _, path in ipairs(baseFiles) do loadAddon(path, MC) end
    local baseCounts = {}
    for moduleKey in pairs(fields) do baseCounts[moduleKey] = #entries(moduleKey) end
    for _, path in ipairs(patchFiles) do loadAddon(path, MC) end
    local patch120007Counts = {}
    for moduleKey in pairs(fields) do patch120007Counts[moduleKey] = #entries(moduleKey) end

    equal(MC.CURRENCY.VoidlightMarl, 3316, "Voidlight Marl currency")
    equal(MC.CURRENCY.TimewarpedBadges, 1166, "Timewarped Badge currency")
    equal(MC.MAP.Val, 2599, "Val map")
    equal(MC.MAP.Naigtal, 2600, "Naigtal map")
    equal(MC.MAP.NaigtalCrypt, 2646, "Naigtal Crypt map")
    equal(MC.MAP_PARENT[MC.MAP.NaigtalCrypt], MC.MAP.Naigtal, "Naigtal Crypt parent")
    truthy(MC.LOC.Kifaan and #MC.LOC.Kifaan == 2, "Kifaan rotation waypoints")
    truthy(MC.LOC.Zuronar and #MC.LOC.Zuronar == 2, "Zuronar rotation waypoints")

    equal(#entries("mounts") - baseCounts.mounts, 9, "12.0.7 mount count")
    assertIDs("mounts", "mountID",
        { 2990, 2988, 3033, 2950, 2806, 2611, 3036, 1470, 1710 }, "12.0.7 mount")
    local duskGrimlynx = findEntry("mounts", "mountID", 2611)
    equal(duskGrimlynx.itemID, 246731, "Dusk Grimlynx item ID")
    truthy(duskGrimlynx.sourceInfo:find("History Lesson", 1, true),
        "Dusk Grimlynx quest source")
    equal(#entries("pets") - baseCounts.pets, 7, "12.0.7 pet count")
    assertIDs("pets", "speciesID",
        { 4898, 5073, 5074, 4965, 5041, 5007, 4949 }, "12.0.7 pet")
    equal(#entries("toys") - baseCounts.toys, 7, "12.0.7 toy count")
    assertIDs("toys", "itemID",
        { 276371, 264313, 264367, 267323, 259335, 259899, 260170 }, "12.0.7 toy")
    equal(#entries("rares") - baseCounts.rares, 2, "12.0.7 rare achievement count")
    assertIDs("rares", "achievementID", { 62881, 62883 }, "12.0.7 rare")

    local sleepyCount = 0
    for _, pet in ipairs(entries("pets")) do
        if pet.speciesID == 4965 then sleepyCount = sleepyCount + 1 end
    end
    equal(sleepyCount, 1, "Sleepy Mandrake must occur once across base and patch data")

    local patchRareCount, patchRareCoords = 0, 0
    for _, rare in ipairs(entries("rares")) do
        if rare.achievementID == 62881 or rare.achievementID == 62883 then
            patchRareCount = patchRareCount + 1
            equal(rare.criteriaCount, 10, "Showdown rare criterion count")
            equal(#rare.criteriaNPCIDs, 10, "Showdown rare NPC metadata count")
            patchRareCoords = patchRareCoords + #rare.criteriaNPCIDs
            for _, npcID in ipairs(rare.criteriaNPCIDs) do
                truthy(MC.RareNPCs[npcID], "missing Showdown rare coordinate: " .. npcID)
            end
        end
    end
    equal(patchRareCount, 2, "Showdown rare achievement records")
    equal(patchRareCoords, 20, "Showdown rare coordinate count")

    equal(#entries("decorations") - baseCounts.decorations, 117, "12.0.7 decoration count")
    local neighborhood, special = 0, 0
    for _, decor in ipairs(entries("decorations")) do
        if decor.sourceInfo == "Neighborhood decor vendor (Patch 12.0.7)" then
            neighborhood = neighborhood + 1
        end
    end
    equal(neighborhood, 102, "12.0.7 neighborhood vendor decoration count")
    special = (#entries("decorations") - baseCounts.decorations) - neighborhood
    equal(special, 15, "12.0.7 special decoration count")
    assertIDs("decorations", "decorID", {
        25664, 25665, 25564, 25566, 18802, 25565,
        25307, 20679, 24194, 24193, 23706, 2606,
        21857, 18897, 16813,
    }, "12.0.7 special decoration")

    -- The achievement module deliberately includes 14 non-Showdown patch
    -- events in addition to the 30 rotating-world achievements.
    local achievementAdded = #entries("achievements") - baseCounts.achievements
    local showdownCount = 0
    for _, group in ipairs(MC.AchievementData) do
        if group.source == "showdowns" then
            showdownCount = showdownCount + #(group.achievements or {})
        end
    end
    equal(achievementAdded, 44, "12.0.7 achievement count")
    equal(showdownCount, 30, "12.0.7 Showdown achievement count")
    equal(findEntry("achievements", "achievementID", 62413), nil,
        "phantom achievement 62413 must not be registered")
    assertIDs("achievements", "achievementID", {
        62873, 62874, 62899, 62898, 63264, 63348, 63323, 62909,
        62901, 62887, 63383, 62905, 62900, 62896, 63384, 63385,
        62904, 62919, 62883, 62882, 62944, 62945, 62949, 62903,
        63386, 62917, 62881, 62880, 63349, 62842,
    }, "12.0.7 Showdown achievement")

    -- Patch 12.1: Curse of Ula'tek. Record the post-12.0.7 baselines so
    -- every assertion below measures this shard only.
    local achievementGroupBaseline = #MC.AchievementData
    for _, path in ipairs(patch120100Files) do loadAddon(path, MC) end

    equal(MC.CURRENCY.CommunityCoupons, 3363, "Community Coupon currency")
    equal(MC.CURRENCY.CorrosiveCoin, 3448, "Corrosive Coin currency")
    equal(MC.CURRENCY.CoiledFilament, 3546, "Coiled Filament currency")
    equal(MC.FACTION.ZuljarrasForces, 2772, "Zul'jarra's Forces faction")
    equal(MC.FACTION.CaptainTokka, 2773, "Captain Tokka faction")
    equal(MC.MAP.CoiledIsle, 2512, "Coiled Isle map")
    equal(MC.MAP.VaultsOfAtalUtek, 2509, "Vaults of Atal'Utek map")
    equal(MC.MAP.VaultsDepths, 2613, "Vaults interior map")
    equal(MC.MAP_PARENT[MC.MAP.VaultsDepths], MC.MAP.VaultsOfAtalUtek,
        "Vaults interior parent")
    equal(MC.MAP_PARENT[MC.MAP.VaultsOfAtalUtek], MC.MAP.CoiledIsle,
        "Vaults overworld parent")
    truthy(MC.LOC.Jansari and MC.LOC.SecondMateSluggs and MC.LOC.SkullOfErinye and MC.LOC.Dugal,
        "Patch 12.1 vendor locations")
    truthy(MC.LOC.ConstructAlia, "Construct Ali'a vendor location")

    equal(#entries("mounts") - patch120007Counts.mounts, 23, "12.1 mount count")
    assertIDs("mounts", "mountID", {
        3060, 3054, 3019, 2980, 3061, 3051, 3023, 3053, 3062, 3029, 3063,
        3064, 3043, 2839, 3032, 3031, 3058, 3021, 3030, 2821, 3002, 3003, 3020,
    }, "12.1 mount")
    local arcaneGolem = findEntry("mounts", "mountID", 2839)
    equal(arcaneGolem.itemID, 262496, "Delver's Arcane Golem item ID")
    equal(arcaneGolem.waypoint[1], 2635, "Delver's Arcane Golem map")
    equal(arcaneGolem.waypoint[2], 0.6043, "Delver's Arcane Golem x")
    equal(arcaneGolem.waypoint[3], 0.6811, "Delver's Arcane Golem y")
    equal(arcaneGolem.availableAfter, nil,
        "ordinary 12.1 delve chest must not be Season 2 gated")

    equal(#entries("pets") - patch120007Counts.pets, 24, "12.1 pet count")
    assertIDs("pets", "speciesID", {
        5035, 5031, 5029, 5030, 5032, 5028, 5033, 5034, 5071, 5072, 5070,
        5093, 5078, 5076, 5137, 5092, 5125, 5011, 5134, 5133, 5131, 5132,
        5130, 5129,
    }, "12.1 pet")

    equal(#entries("toys") - patch120007Counts.toys, 14, "12.1 toy count")
    assertIDs("toys", "itemID", {
        276925, 280419, 280201, 275988, 279054, 274921, 279021,
        277954, 268504, 279052, 276189, 276229, 276258, 267472,
    }, "12.1 toy")

    equal(#entries("rares") - patch120007Counts.rares, 2,
        "12.1 rare achievement count")
    assertIDs("rares", "achievementID", { 63358, 63390 }, "12.1 rare")
    local coiledRareCriteria = 0
    for _, rare in ipairs(entries("rares")) do
        if rare.achievementID == 63358 or rare.achievementID == 63390 then
            equal(#rare.criteriaNPCIDs, rare.criteriaCount,
                "12.1 rare criterion NPC metadata")
            coiledRareCriteria = coiledRareCriteria + rare.criteriaCount
        end
    end
    equal(coiledRareCriteria, 17, "12.1 rare criterion count")
    local turnTheSurge = findEntry("rares", "achievementID", 63390)
    local expectedSurgeOrder = { 255088, 257863, 258254, 255927, 255087 }
    for index, npcID in ipairs(expectedSurgeOrder) do
        equal(turnTheSurge.criteriaNPCIDs[index], npcID,
            "Turn the Surge criterion order " .. index)
    end
    truthy(MC.RareNPCs[263456] and MC.RareNPCs[263456][1] == MC.MAP.VaultsDepths,
        "Szarith must use the Vaults interior map")

    equal(#entries("treasures") - patch120007Counts.treasures, 1,
        "12.1 treasure achievement count")
    assertIDs("treasures", "achievementID", { 63359 }, "12.1 treasure")
    local coiledTreasure
    for _, treasure in ipairs(entries("treasures")) do
        if treasure.achievementID == 63359 then coiledTreasure = treasure end
    end
    truthy(coiledTreasure, "Coiled Isle treasure metadata")
    equal(coiledTreasure.criteriaCount, 22, "Coiled Isle treasure criterion count")
    equal(#coiledTreasure.criteriaNames, 22, "Coiled Isle treasure metadata count")
    for _, name in ipairs(coiledTreasure.criteriaNames) do
        truthy(MC.TreasureCoords[name], "missing Coiled Isle treasure coordinate: " .. name)
    end

    equal(#entries("decorations") - patch120007Counts.decorations, 145,
        "12.1 decoration count")
    assertIDs("decorations", "decorID", {
        15283, 5130, 21833, 27041, 26484, 27042, 26377, 26203, 21616, 26481,
        21725, 15290, 25121, 25106, 25102, 25103, 25122, 25105, 25101,
        26704, 25765, 26705, 25895, 26940, 26706, 26707, 26877, 27973,
        25896, 26876, 26703, 27045,
    }, "12.1 representative decoration")

    local vendorWaypointCounts = {
        ["Second Mate Sluggs"] = { expected = 6, waypoint = MC.LOC.SecondMateSluggs, found = 0 },
        ["Jan'sari"] = { expected = 15, waypoint = MC.LOC.Jansari, found = 0 },
        ["Skull of Er'inye"] = { expected = 18, waypoint = MC.LOC.SkullOfErinye, found = 0 },
        ["Construct Ali'a"] = { expected = 14, waypoint = MC.LOC.ConstructAlia, found = 0 },
    }
    for _, decor in ipairs(entries("decorations")) do
        for vendor, expectation in pairs(vendorWaypointCounts) do
            if decor.sourceInfo and decor.sourceInfo:find(vendor, 1, true) then
                expectation.found = expectation.found + 1
                equal(decor.waypoint, expectation.waypoint,
                    vendor .. " decoration waypoint")
            end
        end
    end
    for vendor, expectation in pairs(vendorWaypointCounts) do
        equal(expectation.found, expectation.expected,
            vendor .. " decoration count")
    end

    equal(#entries("achievements") - patch120007Counts.achievements, 167,
        "12.1 achievement count")
    local patchAchievementSources = {}
    local patchAchievementTasks = 0
    for groupIndex = achievementGroupBaseline + 1, #MC.AchievementData do
        local group = MC.AchievementData[groupIndex]
        patchAchievementSources[group.source] =
            (patchAchievementSources[group.source] or 0) + #(group.achievements or {})
        for _, achievement in ipairs(group.achievements or {}) do
            patchAchievementTasks = patchAchievementTasks +
                #((achievement.taskList and achievement.taskList.tasks) or {})
        end
    end
    local expectedAchievementSources = {
        season = 44, raid = 37, zone = 23, delves = 18, glyphs = 12,
        prey = 11, professions = 7, dungeons = 4, housing = 3, metas = 3,
        events = 2, explore = 1, lore = 1, pets = 1,
    }
    for source, expected in pairs(expectedAchievementSources) do
        equal(patchAchievementSources[source], expected,
            "12.1 achievement source count: " .. source)
    end
    equal(patchAchievementTasks, 142, "12.1 achievement task count")

    local rewardDescriptions = {
        [63630] = "Venomous Coiler mount",
        [63333] = "Apophic Soul Crusher mount",
        [63254] = "Crimson Venomfang mount",
        [62447] = "Breath of Blight mount",
    }
    for achievementID, reward in pairs(rewardDescriptions) do
        local achievement = findEntry("achievements", "achievementID", achievementID)
        truthy(achievement.description:find(reward, 1, true),
            "achievement reward text " .. achievementID)
    end
    local uLatekMeta = findEntry("achievements", "achievementID", 63639)
    truthy(not uLatekMeta.description:find("Reward:", 1, true),
        "Ula'tek Uncoiled must not claim a reward")
    local venomousGlory = findEntry("achievements", "achievementID", 63254)
    equal(venomousGlory.name, "Glory of the Venomous Raider",
        "Venomous raid meta name")

    local futureCounts = {}
    local futureTotal = 0
    for moduleKey in pairs(fields) do
        for _, entry in ipairs(entries(moduleKey)) do
            if entry.availableAfter then
                equal(entry.availableAfter, MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2,
                    moduleKey .. " unexpected release gate")
                futureCounts[moduleKey] = (futureCounts[moduleKey] or 0) + 1
                futureTotal = futureTotal + 1
            end
        end
    end
    equal(futureCounts.mounts, 9, "Season 2 mount gate count")
    equal(futureCounts.pets, 2, "Season 2 pet gate count")
    equal(futureCounts.toys or 0, 0, "Season 2 toy gate count")
    equal(futureCounts.decorations, 14, "Season 2 decoration gate count")
    equal(futureCounts.achievements, 83, "Season 2 achievement gate count")
    equal(futureTotal, 108, "all Season 2 gated catalog rows")

    local function assertAvailability(moduleKey, idField, ids, expected, label)
        for _, id in ipairs(ids) do
            local entry = findEntry(moduleKey, idField, id)
            truthy(entry, label .. " missing row " .. id)
            equal(entry.availableAfter, expected, label .. " availability " .. id)
        end
    end

    -- Blizzard's revised schedule starts Mythic 0, Prey Normal/Hard, all
    -- ordinary delve tiers, Nemesis ?, and Tidebound Grotto World difficulty
    -- on patch week. Keep Nightmare/Curse, Nemesis ??, raid, M+, PvP, and the
    -- Grotto's Normal/Heroic/Mythic difficulties behind the next reset.
    assertAvailability("toys", "itemID", { 275988, 276229, 276258 }, nil,
        "patch-week toy")
    assertAvailability("pets", "speciesID", { 5078, 5076 }, nil,
        "patch-week pet")
    assertAvailability("mounts", "mountID", { 3043, 3032, 3058 }, nil,
        "patch-week mount")
    assertAvailability("decorations", "decorID", {
        25286, 25289, 25274, 25284, 7834, 1136, 25288, 25287, 25279, 7832,
        26487,
    }, nil, "patch-week decoration")
    assertAvailability("achievements", "achievementID", {
        62410, 62411, 62412, 62414, 62416,
        63611, 63416, 63642, 63643, 63644,
        63326, 62889, 62890, 62891, 62892, 62893, 62894, 62895, 62897,
        63433, 63434, 63435, 63683, 62284,
    }, nil, "patch-week achievement")

    assertAvailability("mounts", "mountID", { 3031 },
        MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2, "Nightmare/Curse mount")
    assertAvailability("decorations", "decorID", { 22145, 22146, 24891, 22148 },
        MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2, "Nightmare/Curse decoration")
    assertAvailability("achievements", "achievementID", {
        62871, 62872, 63473,
        63415, 63451, 63452, 63453, 63454, 63457,
        63332, 63333,
        63681, 63682, 63686, 63687, 63688,
    }, MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2, "August 18 achievement")

    equal(findEntry("achievements", "achievementID", 63679).availableAfter, nil,
        "Altar challenge is available at patch launch")
    equal(findEntry("achievements", "achievementID", 62282).availableAfter, nil,
        "normal Altar achievement is available at patch launch")
    equal(findEntry("achievements", "achievementID", 62283).availableAfter, nil,
        "heroic Altar achievement is available at patch launch")
    equal(findEntry("achievements", "achievementID", 62284).availableAfter, nil,
        "mythic Altar achievement is available at patch launch")
    equal(findEntry("pets", "speciesID", 5129).availableAfter, nil,
        "Slitherfang is available from the launch achievement")
    equal(findEntry("decorations", "decorID", 25293).availableAfter, nil,
        "Altar boss decor is available at patch launch")

    -- Cross-catalog schema checks keep newly-added groups visible and make
    -- malformed costs/waypoints fail in CI instead of at hover or click time.
    local sourceConfigs = {
        mounts = { MC.MountSourceLabels, MC.MountSourceOrder },
        pets = { MC.PetSourceLabels, MC.PetSourceOrder },
        toys = { MC.ToySourceLabels, MC.ToySourceOrder },
        rares = { MC.RareSourceLabels, MC.RareSourceOrder },
        treasures = { MC.TreasureSourceLabels, MC.TreasureSourceOrder },
        decorations = { MC.DecoSourceLabels, MC.DecoSourceOrder },
        achievements = { MC.AchievementSourceLabels, MC.AchievementSourceOrder },
    }
    for moduleKey, config in pairs(sourceConfigs) do
        local ordered = {}
        for _, source in ipairs(config[2] or {}) do ordered[source] = true end
        for _, group in ipairs(MC[dataFields[moduleKey]] or {}) do
            truthy(group.source, moduleKey .. " group missing source")
            truthy(config[1] and config[1][group.source],
                moduleKey .. " source missing UI label: " .. tostring(group.source))
            truthy(ordered[group.source],
                moduleKey .. " source missing UI order: " .. tostring(group.source))
        end
    end

    local function validateWaypoint(waypoint, label)
        if not waypoint then return end
        if type(waypoint[1]) == "table" then
            for index, child in ipairs(waypoint) do
                validateWaypoint(child, label .. "[" .. index .. "]")
            end
            return
        end
        truthy(type(waypoint[1]) == "number" and waypoint[1] > 0,
            label .. " invalid map")
        truthy(type(waypoint[2]) == "number" and waypoint[2] >= 0 and waypoint[2] <= 1,
            label .. " invalid x coordinate")
        truthy(type(waypoint[3]) == "number" and waypoint[3] >= 0 and waypoint[3] <= 1,
            label .. " invalid y coordinate")
    end
    local function validateCost(cost, label)
        if not cost then return end
        if cost.gold ~= nil then
            truthy(type(cost.gold) == "number" and cost.gold > 0,
                label .. " invalid gold cost")
        end
        for _, key in ipairs({ "currency", "currency2", "item", "item2" }) do
            local value = cost[key]
            if value then
                truthy(type(value) == "table" and type(value[1]) == "number" and value[1] > 0,
                    label .. " invalid " .. key .. " ID")
                truthy(type(value[2]) == "number" and value[2] > 0,
                    label .. " invalid " .. key .. " amount")
            end
        end
    end
    for moduleKey in pairs(fields) do
        for _, entry in ipairs(entries(moduleKey)) do
            local label = moduleKey .. " " .. tostring(entry.name or entry.achievementID or "entry")
            validateCost(entry.cost, label)
            validateWaypoint(entry.waypoint, label .. " waypoint")
            validateWaypoint(entry.overworldWaypoint, label .. " overworld waypoint")
            for taskIndex, task in ipairs((entry.taskList and entry.taskList.tasks) or {}) do
                validateWaypoint(task.waypoint, label .. " task " .. taskIndex)
                validateWaypoint(task.pickupWaypoint, label .. " pickup " .. taskIndex)
            end
        end
    end

    assertUnique("mounts", "mountID")
    assertUnique("pets", "speciesID")
    assertUnique("toys", "itemID")
    assertUnique("rares", "achievementID")
    assertUnique("treasures", "achievementID")
    assertUnique("decorations", "decorID")
    assertUnique("achievements", "achievementID")
end

-- Every shipped profession recipe has a stable unique spell ID and a schema
-- the scanner/UI can consume. This closes the previous catalog-test gap.
do
    local MC = {}
    loadAddon("addons/Collectionist/Data/Constants.lua", MC)
    loadAddon("addons/Collectionist/Data/Locations.lua", MC)
    local recipeFiles = {
        { "addons/Collectionist/Modules/Recipes/Data/Alchemy.lua", "AlchemyRecipes" },
        { "addons/Collectionist/Modules/Recipes/Data/Blacksmithing.lua", "BlacksmithingRecipes" },
        { "addons/Collectionist/Modules/Recipes/Data/Cooking.lua", "CookingRecipes" },
        { "addons/Collectionist/Modules/Recipes/Data/Enchanting.lua", "EnchantingRecipes" },
        { "addons/Collectionist/Modules/Recipes/Data/Engineering.lua", "EngineeringRecipes" },
        { "addons/Collectionist/Modules/Recipes/Data/Inscription.lua", "InscriptionRecipes" },
        { "addons/Collectionist/Modules/Recipes/Data/Jewelcrafting.lua", "JewelcraftingRecipes" },
        { "addons/Collectionist/Modules/Recipes/Data/Leatherworking.lua", "LeatherworkingRecipes" },
        { "addons/Collectionist/Modules/Recipes/Data/Tailoring.lua", "TailoringRecipes" },
    }
    local validSources = {
        trainer = true, vendor = true, discovery = true,
        specialization = true, drop = true, quest = true,
    }
    local seen, total = {}, 0
    local function validateRecipeWaypoint(waypoint, label)
        if not waypoint then return end
        truthy(type(waypoint[1]) == "number" and waypoint[1] > 0,
            label .. " invalid map")
        truthy(type(waypoint[2]) == "number" and waypoint[2] >= 0 and waypoint[2] <= 1,
            label .. " invalid x")
        truthy(type(waypoint[3]) == "number" and waypoint[3] >= 0 and waypoint[3] <= 1,
            label .. " invalid y")
    end
    for _, fixture in ipairs(recipeFiles) do
        loadAddon(fixture[1], MC)
        local categories = MC[fixture[2]]
        truthy(type(categories) == "table" and #categories > 0,
            fixture[2] .. " categories")
        for _, category in ipairs(categories) do
            truthy(type(category.name) == "string" and category.name ~= "",
                fixture[2] .. " category name")
            truthy(type(category.recipes) == "table" and #category.recipes > 0,
                fixture[2] .. " empty category " .. category.name)
            for _, recipe in ipairs(category.recipes) do
                total = total + 1
                truthy(type(recipe.id) == "number" and recipe.id > 0,
                    fixture[2] .. " invalid recipe ID")
                truthy(not seen[recipe.id],
                    "duplicate recipe spell ID " .. recipe.id)
                seen[recipe.id] = true
                truthy(type(recipe.name) == "string" and recipe.name ~= "",
                    "recipe name " .. recipe.id)
                truthy(validSources[recipe.source],
                    "unsupported recipe source " .. tostring(recipe.source))
                truthy(type(recipe.priority) == "number"
                    and recipe.priority >= 1 and recipe.priority <= 4,
                    "invalid recipe priority " .. recipe.id)
                validateRecipeWaypoint(recipe.waypoint, "recipe " .. recipe.id)
            end
        end
    end
    truthy(total > 500, "recipe fixture should cover the full catalog")
end

print("Collectionist tests passed")
