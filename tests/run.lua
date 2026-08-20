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
        Themes = { default = true },
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

-- Shadowlands, Dragonflight, and TWW content are additive, collision-free,
-- and use the same expansion visibility/account-score contract as Midnight.
do
    local createFrame = newFrameFactory()
    CreateFrame = createFrame
    SlashCmdList = {}
    StaticPopupDialogs = {}

    local MC = {}
    loadAddon("addons/Collectionist/Core.lua", MC)
    loadAddon("addons/Collectionist/Data/Constants.lua", MC)
    loadAddon("addons/Collectionist/Data/Locations.lua", MC)
    loadAddon("addons/Collectionist/Data/Expansions.lua", MC)

    local recipeBaseFiles = {
        "Alchemy.lua", "Blacksmithing.lua", "Cooking.lua",
        "Enchanting.lua", "Engineering.lua", "Inscription.lua",
        "Jewelcrafting.lua", "Leatherworking.lua", "Tailoring.lua",
    }
    for _, name in ipairs(recipeBaseFiles) do
        loadAddon("addons/Collectionist/Modules/Recipes/Data/" .. name, MC)
    end
    loadAddon("addons/Collectionist/Modules/Recipes/Data/Ownership.lua", MC)
    loadAddon("addons/Collectionist/Modules/Recipes/Data/Classic.lua", MC)
    loadAddon("addons/Collectionist/Modules/Recipes/Data/TheBurningCrusade.lua", MC)
    loadAddon("addons/Collectionist/Modules/Recipes/Data/WrathOfTheLichKing.lua", MC)
    loadAddon("addons/Collectionist/Modules/Recipes/Data/Cataclysm.lua", MC)
    loadAddon("addons/Collectionist/Modules/Recipes/Data/MistsOfPandaria.lua", MC)
    loadAddon("addons/Collectionist/Modules/Recipes/Data/WarlordsOfDraenor.lua", MC)
    loadAddon("addons/Collectionist/Modules/Recipes/Data/Legion.lua", MC)
    loadAddon("addons/Collectionist/Modules/Recipes/Data/BattleForAzeroth.lua", MC)
    loadAddon("addons/Collectionist/Modules/Recipes/Data/Shadowlands.lua", MC)
    loadAddon("addons/Collectionist/Modules/Recipes/Data/Dragonflight.lua", MC)
    loadAddon("addons/Collectionist/Modules/Recipes/Data/TheWarWithin.lua", MC)

    equal(MC.GetLatestExpansion("recipes"), "midnight",
        "recipe Current expansion after TWW registration")

    local recipeSeen, recipeExpansion = {}, {}
    local classicRecipes, tbcRecipes, wrathRecipes, cataRecipes, mopRecipes, wodRecipes, legionRecipes, bfaRecipes, slRecipes, dfRecipes, twwRecipes, midnightRecipes = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    for _, dataKey in pairs(MC.RECIPE_DATA_KEYS) do
        for _, category in ipairs(MC[dataKey]) do
            truthy(category.expansion == "vanilla" or category.expansion == "tbc" or category.expansion == "wrath" or category.expansion == "cata" or category.expansion == "mop" or category.expansion == "wod" or category.expansion == "legion"
                or category.expansion == "bfa"
                or category.expansion == "shadowlands"
                or category.expansion == "df" or category.expansion == "tww"
                or category.expansion == "midnight",
                "recipe category expansion stamp")
            for _, recipe in ipairs(category.recipes) do
                truthy(not recipeSeen[recipe.id],
                    "duplicate cross-expansion recipe spell ID " .. recipe.id)
                recipeSeen[recipe.id] = true
                recipeExpansion[recipe.id] = recipe.expansion
                equal(recipe.expansion, category.expansion,
                    "recipe/category expansion agreement " .. recipe.id)
                if recipe.expansion == "vanilla" then
                    classicRecipes = classicRecipes + 1
                elseif recipe.expansion == "tbc" then
                    tbcRecipes = tbcRecipes + 1
                elseif recipe.expansion == "wrath" then
                    wrathRecipes = wrathRecipes + 1
                elseif recipe.expansion == "cata" then
                    cataRecipes = cataRecipes + 1
                elseif recipe.expansion == "mop" then
                    mopRecipes = mopRecipes + 1
                elseif recipe.expansion == "wod" then
                    wodRecipes = wodRecipes + 1
                elseif recipe.expansion == "legion" then
                    legionRecipes = legionRecipes + 1
                elseif recipe.expansion == "bfa" then
                    bfaRecipes = bfaRecipes + 1
                elseif recipe.expansion == "shadowlands" then
                    slRecipes = slRecipes + 1
                elseif recipe.expansion == "df" then
                    dfRecipes = dfRecipes + 1
                elseif recipe.expansion == "tww" then
                    twwRecipes = twwRecipes + 1
                else
                    midnightRecipes = midnightRecipes + 1
                end
            end
        end
    end
    equal(classicRecipes, 1223, "Classic recipe count")
    equal(tbcRecipes, 755, "TBC recipe count")
    equal(wrathRecipes, 860, "Wrath recipe count")
    equal(cataRecipes, 690, "Cataclysm recipe count")
    equal(mopRecipes, 978, "Pandaria recipe count")
    equal(wodRecipes, 337, "Warlords recipe count")
    equal(legionRecipes, 773, "Legion recipe count")
    equal(bfaRecipes, 1253, "BFA recipe count")
    equal(slRecipes, 634, "Shadowlands recipe count")
    equal(dfRecipes, 1004, "Dragonflight recipe count")
    equal(twwRecipes, 696, "TWW recipe count")
    truthy(midnightRecipes > 500, "Midnight recipe catalog retained")

    -- Acquisition-data burndown. DB2 carries no source column for recipes, so
    -- most of the catalog ships as source="unknown" pending enrichment from
    -- ATT ancestry. Pinning the count makes progress visible and stops a
    -- generator change from silently re-introducing unsourced rows: enrichment
    -- should only ever ratchet this DOWN. Update it deliberately, per pass.
    local unsourcedRecipes, sourcelessRecipes = 0, 0
    for _, dataKey in pairs(MC.RECIPE_DATA_KEYS) do
        for _, category in ipairs(MC[dataKey]) do
            for _, recipe in ipairs(category.recipes) do
                if recipe.source == nil then
                    sourcelessRecipes = sourcelessRecipes + 1
                elseif recipe.source == "unknown" then
                    unsourcedRecipes = unsourcedRecipes + 1
                end
            end
        end
    end
    equal(sourcelessRecipes, 0, "every recipe carries a source string")
    equal(unsourcedRecipes, 9, "recipe acquisition burndown (enrichment lowers this)")
    for _, recipeID in ipairs({
        402118, 402123, 402124, 402125, 402126, 402128, 402129, 402130,
        402131, 402133, 402134, 402135, 402136, 402137, 402138, 402139,
        402140, 402141, 402142, 402143, 402144, 402146, 402147, 402148,
        402150, 402151, 402152, 402155, 402156, 402615, 405205,
    }) do
        equal(recipeExpansion[recipeID], "df",
            "Ancient Zul'Gurub recipe acquisition expansion " .. recipeID)
    end

    -- Visibility follows Options > Expansions alone: the per-tab
    -- expansion filter is gone.
    MC.db = { disabledExpansions = {} }
    for _, dataKey in pairs(MC.RECIPE_DATA_KEYS) do
        for _, category in ipairs(MC[dataKey]) do
            equal(MC.IsGroupVisible(category, "recipes"), true,
                "every enabled expansion is visible")
        end
    end
    MC.db.disabledExpansions = { tww = true }
    for _, dataKey in pairs(MC.RECIPE_DATA_KEYS) do
        for _, category in ipairs(MC[dataKey]) do
            equal(MC.IsGroupVisible(category, "recipes"), category.expansion ~= "tww",
                "a disabled expansion hides only its own categories")
        end
    end
    MC.db.disabledExpansions = {}

    local ALL_EXP_KEYS = { "vanilla", "tbc", "wrath", "cata", "mop", "wod",
        "legion", "bfa", "shadowlands", "df", "tww", "midnight" }
    local function onlyExpansion(key)
        MC.db.disabledExpansions = {}
        for _, k in ipairs(ALL_EXP_KEYS) do
            if k ~= key then MC.db.disabledExpansions[k] = true end
        end
    end

    local oldDB, oldIsPlayerSpell = CollectionistDB, IsPlayerSpell
    CollectionistDB = { recipesLearned = {} }
    IsPlayerSpell = function(spellID)
        return spellID == 425137 or spellID == 1230866
    end
    MC.modulesByKey.recipes = { db = {}, professions = { [171] = {} } }
    loadAddon("addons/Collectionist/Modules/Recipes/Scanner.lua", MC)
    local scanner = MC.modulesByKey.recipes.Scanner

    onlyExpansion("vanilla")
    scanner:Scan()
    local classicResult = scanner.results[171]
    equal(classicResult.total, 114, "Classic-only Alchemy visible count")
    equal(classicResult.learnedCount, 0, "Classic-only Alchemy learned count")
    equal(classicResult.learnedCountAll, 2, "account Alchemy learned count from Classic view")

    onlyExpansion("tbc")
    scanner:Scan()
    local tbcResult = scanner.results[171]
    equal(tbcResult.total, 75, "TBC-only Alchemy visible count")
    equal(tbcResult.learnedCount, 0, "TBC-only Alchemy learned count")
    equal(tbcResult.learnedCountAll, 2, "account Alchemy learned count from TBC view")

    onlyExpansion("wrath")
    scanner:Scan()
    local wrathResult = scanner.results[171]
    equal(wrathResult.total, 69, "Wrath-only Alchemy visible count")
    equal(wrathResult.learnedCount, 0, "Wrath-only Alchemy learned count")
    equal(wrathResult.learnedCountAll, 2, "account Alchemy learned count from Wrath view")

    onlyExpansion("cata")
    scanner:Scan()
    local cataResult = scanner.results[171]
    equal(cataResult.total, 47, "Cataclysm-only Alchemy visible count")
    equal(cataResult.learnedCount, 0, "Cataclysm-only Alchemy learned count")
    equal(cataResult.learnedCountAll, 2, "account Alchemy learned count from Cataclysm view")

    onlyExpansion("mop")
    scanner:Scan()
    local mopResult = scanner.results[171]
    equal(mopResult.total, 37, "Pandaria-only Alchemy visible count")
    equal(mopResult.learnedCount, 0, "Pandaria-only Alchemy learned count")
    equal(mopResult.learnedCountAll, 2, "account Alchemy learned count from Pandaria view")

    onlyExpansion("wod")
    scanner:Scan()
    local wodResult = scanner.results[171]
    equal(wodResult.total, 53, "Warlords-only Alchemy visible count")
    equal(wodResult.learnedCount, 0, "Warlords-only Alchemy learned count")
    equal(wodResult.learnedCountAll, 2, "account Alchemy learned count from Warlords view")

    onlyExpansion("legion")
    scanner:Scan()
    local legionResult = scanner.results[171]
    equal(legionResult.total, 85, "Legion-only Alchemy visible count")
    equal(legionResult.learnedCount, 0, "Legion-only Alchemy learned count")
    equal(legionResult.learnedCountAll, 2, "account Alchemy learned count from Legion view")

    onlyExpansion("bfa")
    scanner:Scan()
    local bfaResult = scanner.results[171]
    equal(bfaResult.total, 150, "BFA-only Alchemy visible count")
    equal(bfaResult.learnedCount, 0, "BFA-only Alchemy learned count")
    equal(bfaResult.learnedCountAll, 2, "account Alchemy learned count from BFA view")

    onlyExpansion("shadowlands")
    scanner:Scan()
    local slResult = scanner.results[171]
    equal(slResult.total, 66, "Shadowlands-only Alchemy visible count")
    equal(slResult.learnedCount, 0, "Shadowlands-only Alchemy learned count")
    equal(slResult.learnedCountAll, 2, "account Alchemy learned count from Shadowlands view")

    onlyExpansion("df")
    scanner:Scan()
    local dfResult = scanner.results[171]
    equal(dfResult.total, 68, "Dragonflight-only Alchemy visible count")
    equal(dfResult.learnedCount, 0, "Dragonflight-only Alchemy learned count")
    equal(dfResult.learnedCountAll, 2, "account Alchemy learned count from DF view")

    onlyExpansion("tww")
    scanner:Scan()
    local twwResult = scanner.results[171]
    equal(twwResult.total, 53, "TWW-only Alchemy visible count")
    equal(twwResult.learnedCount, 1, "TWW-only Alchemy learned count")
    equal(twwResult.learnedCountAll, 2, "account Alchemy learned count")
    local accountTotal, accountScore = twwResult.totalAll, twwResult.score

    onlyExpansion("midnight")
    scanner:Scan()
    local midnightResult = scanner.results[171]
    truthy(midnightResult.total > 0 and midnightResult.total ~= twwResult.total,
        "Midnight-only Alchemy visible count")
    equal(midnightResult.learnedCount, 1, "Midnight-only Alchemy learned count")
    equal(midnightResult.totalAll, accountTotal,
        "recipe account denominator ignores browse filter")
    equal(midnightResult.learnedCountAll, 2,
        "recipe account ownership ignores browse filter")
    equal(midnightResult.score, accountScore,
        "recipe account score ignores browse filter")

    MC.db.disabledExpansions = { tww = true }
    scanner:Scan()
    equal(scanner.results[171].score, accountScore,
        "recipe account score ignores expansion browse toggle")

    local oldUnitClass, oldUnitName, oldGetRealmName =
        UnitClass, UnitName, GetRealmName
    UnitClass = function() return "Mage", "MAGE" end
    UnitName = function() return "Crafter" end
    GetRealmName = function() return "Test Realm" end
    MC.modules = { { key = "recipes", Scanner = scanner } }
    loadAddon("addons/Collectionist/Modules/Roster/Init.lua", MC)
    local me = MC.GetMeRosterEntry()
    equal(me.counts.recipes.total, accountTotal,
        "shared recipe denominator ignores browse filter")
    equal(me.counts.recipes.collected, 2,
        "shared recipe ownership ignores browse filter")
    UnitClass, UnitName, GetRealmName =
        oldUnitClass, oldUnitName, oldGetRealmName
    CollectionistDB, IsPlayerSpell = oldDB, oldIsPlayerSpell

    local classicUnavailableIDs = { mounts = {}, pets = {}, toys = {} }
    local tbcUnavailableIDs = { mounts = {}, pets = {}, toys = {} }
    for _, id in ipairs({ 169, 199, 201, 207, 223, 241 }) do
        tbcUnavailableIDs.mounts[id] = true
    end
    tbcUnavailableIDs.pets[187] = true
    local wrathUnavailableIDs = { mounts = {}, pets = {}, toys = {} }
    for _, id in ipairs({ 263, 266, 313, 317, 340, 342, 343, 344, 345, 358 }) do
        wrathUnavailableIDs.mounts[id] = true
    end
    for _, id in ipairs({ 202, 243 }) do
        wrathUnavailableIDs.pets[id] = true
    end
    local cataUnavailableIDs = { mounts = {}, pets = {}, toys = {} }
    for _, id in ipairs({ 424, 428, 467 }) do
        cataUnavailableIDs.mounts[id] = true
    end
    for _, id in ipairs({ 46709, 54653, 54651 }) do
        cataUnavailableIDs.toys[id] = true
    end
    local mopUnavailableIDs = { mounts = {}, pets = {}, toys = {} }
    for _, id in ipairs({ 503, 518, 519, 520, 541, 550, 558, 562, 563, 564 }) do
        mopUnavailableIDs.mounts[id] = true
    end
    for _, id in ipairs({ 462, 484, 485 }) do
        mopUnavailableIDs.mounts[id] = true
    end
    local wodUnavailableIDs = { mounts = {}, pets = {}, toys = {} }
    for _, id in ipairs({ 606, 651, 654, 759, 760, 761, 764 }) do
        wodUnavailableIDs.mounts[id] = true
    end
    local legionUnavailableIDs = { mounts = {}, pets = {}, toys = {} }
    for _, id in ipairs({ 848, 849, 850, 851, 852, 853, 878, 948, 978 }) do
        legionUnavailableIDs.mounts[id] = true
    end
    for _, id in ipairs({ 1889, 2022 }) do
        legionUnavailableIDs.pets[id] = true
    end
    local bfaUnavailableIDs = { mounts = {}, pets = {}, toys = {} }
    for _, id in ipairs({ 1030, 1031, 1032, 1035, 1220, 1265, 1326 }) do
        bfaUnavailableIDs.mounts[id] = true
    end
    local dfUnavailableIDs = { mounts = {}, pets = {}, toys = {} }
    local slUnavailableIDs = { mounts = {}, pets = {}, toys = {} }
    for _, id in ipairs({ 1363, 1405, 1419, 1480, 1520, 1544, 1552, 1572, 1576, 1599 }) do
        slUnavailableIDs.mounts[id] = true
    end
    slUnavailableIDs.pets[3046] = true
    for _, id in ipairs({
        482, 994, 1259, 1660, 1681, 1725, 1739, 1801, 1822, 1831, 1959,
        2055, 2060, 2063, 2064, 2065, 2067, 2068, 2069, 2070, 2071, 2072,
        2073, 2074, 2075, 2076, 2077, 2078, 2080, 2081, 2083, 2084, 2085,
        2086, 2087, 2088, 2089, 2090, 2091, 2118, 2142, 2143,
    }) do dfUnavailableIDs.mounts[id] = true end
    for _, id in ipairs({ 4265, 4425, 4426, 4435, 4579, 4580 }) do
        dfUnavailableIDs.pets[id] = true
    end
    for _, id in ipairs({ 206267, 206008, 206343, 210497, 211869, 211946, 212337, 170197 }) do
        dfUnavailableIDs.toys[id] = true
    end

    local dataFixtures = {
        mounts = {
            field = "MountData", list = "mounts", id = "mountID", classicCount = 85, tbcCount = 68, wrathCount = 94, cataCount = 48, mopCount = 93, wodCount = 69, legionCount = 125, bfaCount = 140, slCount = 181, dfCount = 161, twwCount = 186,
            files = {
                "Modules/Mounts/Data/Classic.lua",
                "Modules/Mounts/Data/TheBurningCrusade.lua",
                "Modules/Mounts/Data/WrathOfTheLichKing.lua",
                "Modules/Mounts/Data/Cataclysm.lua",
                "Modules/Mounts/Data/MistsOfPandaria.lua",
                "Modules/Mounts/Data/WarlordsOfDraenor.lua",
                "Modules/Mounts/Data/Legion.lua",
                "Modules/Mounts/Data/BattleForAzeroth.lua",
                "Modules/Mounts/Data/Shadowlands.lua",
                "Modules/Mounts/Data/Dragonflight.lua", "Modules/Mounts/Data/TheWarWithin.lua",
                "Modules/Mounts/Data/DB2Gaps.lua",
                "Modules/Mounts/Data/Mounts.lua",
                "Modules/Mounts/Data/Patch120007.lua", "Modules/Mounts/Data/Patch120100.lua",
            },
        },
        pets = {
            field = "PetData", list = "pets", id = "speciesID", classicCount = 204, tbcCount = 70, wrathCount = 81, cataCount = 82, mopCount = 173, wodCount = 117, legionCount = 158, bfaCount = 300, slCount = 237, dfCount = 217, twwCount = 208,
            files = {
                "Modules/Pets/Data/Classic.lua",
                "Modules/Pets/Data/TheBurningCrusade.lua",
                "Modules/Pets/Data/WrathOfTheLichKing.lua",
                "Modules/Pets/Data/Cataclysm.lua",
                "Modules/Pets/Data/MistsOfPandaria.lua",
                "Modules/Pets/Data/WarlordsOfDraenor.lua",
                "Modules/Pets/Data/Legion.lua",
                "Modules/Pets/Data/BattleForAzeroth.lua",
                "Modules/Pets/Data/Shadowlands.lua",
                "Modules/Pets/Data/Dragonflight.lua", "Modules/Pets/Data/TheWarWithin.lua",
                "Modules/Pets/Data/WildPets.lua",
                "Modules/Pets/Data/DB2Gaps.lua",
                "Modules/Pets/Data/Pets.lua",
                "Modules/Pets/Data/Patch120007.lua", "Modules/Pets/Data/Patch120100.lua",
            },
        },
        toys = {
            field = "ToyData", list = "toys", id = "itemID", classicCount = 14, tbcCount = 22, wrathCount = 36, cataCount = 43, mopCount = 79, wodCount = 128, legionCount = 158, bfaCount = 136, slCount = 115, dfCount = 173, twwCount = 99,
            files = {
                "Modules/Toys/Data/Classic.lua",
                "Modules/Toys/Data/TheBurningCrusade.lua",
                "Modules/Toys/Data/WrathOfTheLichKing.lua",
                "Modules/Toys/Data/Cataclysm.lua",
                "Modules/Toys/Data/MistsOfPandaria.lua",
                "Modules/Toys/Data/WarlordsOfDraenor.lua",
                "Modules/Toys/Data/Legion.lua",
                "Modules/Toys/Data/BattleForAzeroth.lua",
                "Modules/Toys/Data/Shadowlands.lua",
                "Modules/Toys/Data/Dragonflight.lua", "Modules/Toys/Data/TheWarWithin.lua",
                "Modules/Toys/Data/DB2Gaps.lua",
                "Modules/Toys/Data/Toys.lua",
                "Modules/Toys/Data/Patch120007.lua", "Modules/Toys/Data/Patch120100.lua",
            },
        },
        decorations = {
            field = "DecorationData", list = "decorations", id = "decorID", classicCount = 22, tbcCount = 29, wrathCount = 27, cataCount = 46, mopCount = 41, wodCount = 80, legionCount = 211, bfaCount = 136, slCount = 26, dfCount = 76, twwCount = 108,
            files = {
                "Modules/Decorations/Data/Classic.lua",
                "Modules/Decorations/Data/TheBurningCrusade.lua",
                "Modules/Decorations/Data/WrathOfTheLichKing.lua",
                "Modules/Decorations/Data/Cataclysm.lua",
                "Modules/Decorations/Data/MistsOfPandaria.lua",
                "Modules/Decorations/Data/WarlordsOfDraenor.lua",
                "Modules/Decorations/Data/Legion.lua",
                "Modules/Decorations/Data/BattleForAzeroth.lua",
                "Modules/Decorations/Data/Shadowlands.lua",
                "Modules/Decorations/Data/Dragonflight.lua", "Modules/Decorations/Data/TheWarWithin.lua",
                "Modules/Decorations/Data/Decorations.lua",
                "Modules/Decorations/Data/Patch120007.lua", "Modules/Decorations/Data/Patch120100.lua",
            },
        },
        achievements = {
            field = "AchievementData", list = "achievements", id = "achievementID", classicCount = 203, tbcCount = 101, wrathCount = 390, cataCount = 235, mopCount = 413, wodCount = 410, legionCount = 308, bfaCount = 475, slCount = 433, dfCount = 606, twwCount = 441,
            files = {
                "Modules/Achievements/Data/Classic.lua",
                "Modules/Achievements/Data/TheBurningCrusade.lua",
                "Modules/Achievements/Data/WrathOfTheLichKing.lua",
                "Modules/Achievements/Data/Cataclysm.lua",
                "Modules/Achievements/Data/MistsOfPandaria.lua",
                "Modules/Achievements/Data/WarlordsOfDraenor.lua",
                "Modules/Achievements/Data/Legion.lua",
                "Modules/Achievements/Data/BattleForAzeroth.lua",
                "Modules/Achievements/Data/Shadowlands.lua",
                "Modules/Achievements/Data/Dragonflight.lua", "Modules/Achievements/Data/TheWarWithin.lua",
                "Modules/Achievements/Data/HandyNotes.lua",
                "Modules/Achievements/Data/Achievements.lua",
                "Modules/Achievements/Data/Patch120007.lua", "Modules/Achievements/Data/Patch120100.lua",
            },
        },
        rares = {
            field = "RareData", id = "achievementID", classicCount = 0, tbcCount = 1, wrathCount = 1, cataCount = 0, mopCount = 4, wodCount = 3, legionCount = 6, bfaCount = 8, slCount = 10, dfCount = 7, twwCount = 7,
            files = {
                "Modules/Rares/Data/Classic.lua",
                "Modules/Rares/Data/TheBurningCrusade.lua",
                "Modules/Rares/Data/WrathOfTheLichKing.lua",
                "Modules/Rares/Data/Cataclysm.lua",
                "Modules/Rares/Data/MistsOfPandaria.lua",
                "Modules/Rares/Data/WarlordsOfDraenor.lua",
                "Modules/Rares/Data/Legion.lua",
                "Modules/Rares/Data/BattleForAzeroth.lua",
                "Modules/Rares/Data/Shadowlands.lua",
                "Modules/Rares/Data/Dragonflight.lua", "Modules/Rares/Data/TheWarWithin.lua",
                "Modules/Rares/Data/Rares.lua",
                "Modules/Rares/Data/Patch120007.lua", "Modules/Rares/Data/Patch120100.lua",
            },
        },
        treasures = {
            field = "TreasureData", id = "achievementID", classicCount = 0, tbcCount = 0, wrathCount = 0, cataCount = 0, mopCount = 6, wodCount = 3, legionCount = 6, bfaCount = 8, slCount = 7, dfCount = 7, twwCount = 7,
            files = {
                "Modules/Treasures/Data/Classic.lua",
                "Modules/Treasures/Data/TheBurningCrusade.lua",
                "Modules/Treasures/Data/WrathOfTheLichKing.lua",
                "Modules/Treasures/Data/Cataclysm.lua",
                "Modules/Treasures/Data/MistsOfPandaria.lua",
                "Modules/Treasures/Data/WarlordsOfDraenor.lua",
                "Modules/Treasures/Data/Legion.lua",
                "Modules/Treasures/Data/BattleForAzeroth.lua",
                "Modules/Treasures/Data/Shadowlands.lua",
                "Modules/Treasures/Data/Dragonflight.lua", "Modules/Treasures/Data/TheWarWithin.lua",
                "Modules/Treasures/Data/Treasures.lua",
                "Modules/Treasures/Data/Patch120100.lua",
            },
        },
    }

    for moduleKey, fixture in pairs(dataFixtures) do
        for _, relative in ipairs(fixture.files) do
            loadAddon("addons/Collectionist/" .. relative, MC)
        end
        local seen, classicCount, tbcCount, wrathCount, cataCount, mopCount, wodCount, legionCount, bfaCount, slCount, dfCount, twwCount = {}, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        local classicCriteriaCount, tbcCriteriaCount, wrathCriteriaCount, cataCriteriaCount, mopCriteriaCount, wodCriteriaCount, legionCriteriaCount, bfaCriteriaCount, slCriteriaCount, dfCriteriaCount, criteriaCount = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        local endedClassicMounts, endedClassicPets, endedClassicToys = 0, 0, 0
        local endedTbcMounts, endedTbcPets, endedTbcToys = 0, 0, 0
        local endedWrathMounts, endedWrathPets, endedWrathToys = 0, 0, 0
        local endedCataMounts, endedCataPets, endedCataToys = 0, 0, 0
        local endedMopMounts, endedMopPets, endedMopToys = 0, 0, 0
        local endedWodMounts, endedWodPets, endedWodToys = 0, 0, 0
        local endedLegionMounts, endedLegionPets, endedLegionToys = 0, 0, 0
        local endedShadowlandsMounts, endedShadowlandsPets, endedShadowlandsToys = 0, 0, 0
        local endedBfaMounts, endedBfaPets, endedBfaToys = 0, 0, 0
        local mopRemixMounts, endedDragonflightMounts = 0, 0
        local endedDragonflightPets, endedDragonflightToys = 0, 0
        local slDecorationSources, slCraftedDecorations = {}, 0
        local slAchievementSources, slAchievementTasks = {}, 0
        local bfaDecorationSources, bfaCraftedDecorations = {}, 0
        local bfaAchievementSources, bfaAchievementTasks = {}, 0
        local bfaRareObjects = 0
        local classicDecorationSources, classicCraftedDecorations = {}, 0
        local classicAchievementSources, classicAchievementTasks = {}, 0
        local tbcDecorationSources, tbcCraftedDecorations = {}, 0
        local tbcAchievementSources, tbcAchievementTasks = {}, 0
        local wrathDecorationSources, wrathCraftedDecorations = {}, 0
        local wrathAchievementSources, wrathAchievementTasks = {}, 0
        local cataDecorationSources, cataCraftedDecorations = {}, 0
        local cataAchievementSources, cataAchievementTasks = {}, 0
        local mopDecorationSources, mopCraftedDecorations = {}, 0
        local mopAchievementSources, mopAchievementTasks = {}, 0
        local wodDecorationSources, wodCraftedDecorations = {}, 0
        local wodAchievementSources, wodAchievementTasks = {}, 0
        local legionDecorationSources, legionCraftedDecorations = {}, 0
        local legionAchievementSources, legionAchievementTasks = {}, 0
        local legionRareObjects = 0
        local dfDecorationSources, dfCraftedDecorations = {}, 0
        local dfAchievementSources, dfAchievementTasks = {}, 0
        local legionRemixMounts, remixVendorMounts, remixClassMounts = 0, 0, 0
        local twwDecorationSources, twwCookingDecorations = {}, 0
        local twwAchievementSources, twwAchievementTasks = {}, 0
        for _, group in ipairs(MC[fixture.field]) do
            local rows = fixture.list and group[fixture.list] or { group }
            for _, entry in ipairs(rows) do
                local id = entry[fixture.id]
                truthy(id, moduleKey .. " fixture missing primary ID")
                truthy(not seen[id],
                    "duplicate cross-expansion " .. moduleKey .. " ID " .. id)
                seen[id] = true
                if entry.expansion == "vanilla" then
                    classicCount = classicCount + 1
                    local unavailableIDs = classicUnavailableIDs[moduleKey]
                    if unavailableIDs then
                        equal(entry.unavailable and true or false,
                            unavailableIDs[id] and true or false,
                            "Classic unavailable classification " .. moduleKey .. " " .. id)
                    end
                    if entry.sourceInfo then
                        truthy(entry.sourceInfo ~= "",
                            "Classic source coverage " .. moduleKey .. " " .. id)
                    end
                    if moduleKey == "mounts" and entry.unavailable then
                        endedClassicMounts = endedClassicMounts + 1
                    elseif moduleKey == "pets" and entry.unavailable then
                        endedClassicPets = endedClassicPets + 1
                    elseif moduleKey == "toys" and entry.unavailable then
                        endedClassicToys = endedClassicToys + 1
                    end
                    if moduleKey == "decorations" then
                        classicDecorationSources[entry.source] =
                            (classicDecorationSources[entry.source] or 0) + 1
                        if entry.source == "crafted" then
                            truthy(entry.skillLine,
                                "Classic crafted decoration profession " .. id)
                            classicCraftedDecorations = classicCraftedDecorations + 1
                        end
                    elseif moduleKey == "achievements" then
                        local source = entry.source or group.source
                        truthy(source, "Classic achievement source " .. id)
                        classicAchievementSources[source] =
                            (classicAchievementSources[source] or 0) + 1
                        if entry.taskList and entry.taskList.tasks then
                            for _, task in ipairs(entry.taskList.tasks) do
                                equal(task.achievementID, id,
                                    "Classic achievement task parent " .. id)
                                truthy(task.criteriaID,
                                    "Classic achievement task criteria ID " .. id)
                                classicAchievementTasks = classicAchievementTasks + 1
                            end
                        end
                    elseif moduleKey == "rares" then
                        classicCriteriaCount = classicCriteriaCount + entry.criteriaCount
                    elseif moduleKey == "treasures" then
                        classicCriteriaCount = classicCriteriaCount + entry.criteriaCount
                    end
                elseif entry.expansion == "tbc" then
                    tbcCount = tbcCount + 1
                    local unavailableIDs = tbcUnavailableIDs[moduleKey]
                    if unavailableIDs then
                        equal(entry.unavailable and true or false,
                            unavailableIDs[id] and true or false,
                            "TBC unavailable classification " .. moduleKey .. " " .. id)
                    end
                    if entry.sourceInfo then
                        truthy(entry.sourceInfo ~= "",
                            "TBC source coverage " .. moduleKey .. " " .. id)
                    end
                    if moduleKey == "mounts" and entry.unavailable then
                        endedTbcMounts = endedTbcMounts + 1
                    elseif moduleKey == "pets" and entry.unavailable then
                        endedTbcPets = endedTbcPets + 1
                    elseif moduleKey == "toys" and entry.unavailable then
                        endedTbcToys = endedTbcToys + 1
                    end
                    if moduleKey == "decorations" then
                        tbcDecorationSources[entry.source] =
                            (tbcDecorationSources[entry.source] or 0) + 1
                        if entry.source == "crafted" then
                            truthy(entry.skillLine,
                                "TBC crafted decoration profession " .. id)
                            tbcCraftedDecorations = tbcCraftedDecorations + 1
                        end
                    elseif moduleKey == "achievements" then
                        local source = entry.source or group.source
                        truthy(source, "TBC achievement source " .. id)
                        tbcAchievementSources[source] =
                            (tbcAchievementSources[source] or 0) + 1
                        if entry.taskList and entry.taskList.tasks then
                            for _, task in ipairs(entry.taskList.tasks) do
                                equal(task.achievementID, id,
                                    "TBC achievement task parent " .. id)
                                truthy(task.criteriaID,
                                    "TBC achievement task criteria ID " .. id)
                                tbcAchievementTasks = tbcAchievementTasks + 1
                            end
                        end
                    elseif moduleKey == "rares" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "TBC rare criteria-tree metadata " .. id)
                        equal(#entry.criteriaNPCIDs, entry.criteriaCount,
                            "TBC rare NPC metadata " .. id)
                        tbcCriteriaCount = tbcCriteriaCount + entry.criteriaCount
                    elseif moduleKey == "treasures" then
                        tbcCriteriaCount = tbcCriteriaCount + entry.criteriaCount
                    end
                elseif entry.expansion == "wrath" then
                    wrathCount = wrathCount + 1
                    local unavailableIDs = wrathUnavailableIDs[moduleKey]
                    if unavailableIDs then
                        equal(entry.unavailable and true or false,
                            unavailableIDs[id] and true or false,
                            "Wrath unavailable classification " .. moduleKey .. " " .. id)
                    end
                    if entry.sourceInfo then
                        truthy(entry.sourceInfo ~= "",
                            "Wrath source coverage " .. moduleKey .. " " .. id)
                    end
                    if moduleKey == "mounts" and entry.unavailable then
                        endedWrathMounts = endedWrathMounts + 1
                    elseif moduleKey == "pets" and entry.unavailable then
                        endedWrathPets = endedWrathPets + 1
                    elseif moduleKey == "toys" and entry.unavailable then
                        endedWrathToys = endedWrathToys + 1
                    end
                    if moduleKey == "decorations" then
                        wrathDecorationSources[entry.source] =
                            (wrathDecorationSources[entry.source] or 0) + 1
                        if entry.source == "crafted" then
                            truthy(entry.skillLine,
                                "Wrath crafted decoration profession " .. id)
                            wrathCraftedDecorations = wrathCraftedDecorations + 1
                        end
                    elseif moduleKey == "achievements" then
                        local source = entry.source or group.source
                        truthy(source, "Wrath achievement source " .. id)
                        wrathAchievementSources[source] =
                            (wrathAchievementSources[source] or 0) + 1
                        if entry.taskList and entry.taskList.tasks then
                            for _, task in ipairs(entry.taskList.tasks) do
                                equal(task.achievementID, id,
                                    "Wrath achievement task parent " .. id)
                                truthy(task.criteriaID,
                                    "Wrath achievement task criteria ID " .. id)
                                wrathAchievementTasks = wrathAchievementTasks + 1
                            end
                        end
                    elseif moduleKey == "rares" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "Wrath rare criteria-tree metadata " .. id)
                        equal(#entry.criteriaNPCIDs, entry.criteriaCount,
                            "Wrath rare NPC metadata " .. id)
                        wrathCriteriaCount = wrathCriteriaCount + entry.criteriaCount
                    elseif moduleKey == "treasures" then
                        wrathCriteriaCount = wrathCriteriaCount + entry.criteriaCount
                    end
                elseif entry.expansion == "cata" then
                    cataCount = cataCount + 1
                    local unavailableIDs = cataUnavailableIDs[moduleKey]
                    if unavailableIDs then
                        equal(entry.unavailable and true or false,
                            unavailableIDs[id] and true or false,
                            "Cataclysm unavailable classification " .. moduleKey .. " " .. id)
                    end
                    if entry.sourceInfo then
                        truthy(entry.sourceInfo ~= "",
                            "Cataclysm source coverage " .. moduleKey .. " " .. id)
                    end
                    if moduleKey == "mounts" and entry.unavailable then
                        endedCataMounts = endedCataMounts + 1
                    elseif moduleKey == "pets" and entry.unavailable then
                        endedCataPets = endedCataPets + 1
                    elseif moduleKey == "toys" and entry.unavailable then
                        endedCataToys = endedCataToys + 1
                    end
                    if moduleKey == "decorations" then
                        cataDecorationSources[entry.source] =
                            (cataDecorationSources[entry.source] or 0) + 1
                        if entry.source == "crafted" then
                            truthy(entry.skillLine,
                                "Cataclysm crafted decoration profession " .. id)
                            cataCraftedDecorations = cataCraftedDecorations + 1
                        end
                    elseif moduleKey == "achievements" then
                        local source = entry.source or group.source
                        truthy(source, "Cataclysm achievement source " .. id)
                        cataAchievementSources[source] =
                            (cataAchievementSources[source] or 0) + 1
                        if entry.taskList and entry.taskList.tasks then
                            for _, task in ipairs(entry.taskList.tasks) do
                                equal(task.achievementID, id,
                                    "Cataclysm achievement task parent " .. id)
                                truthy(task.criteriaID,
                                    "Cataclysm achievement task criteria ID " .. id)
                                cataAchievementTasks = cataAchievementTasks + 1
                            end
                        end
                    elseif moduleKey == "rares" then
                        cataCriteriaCount = cataCriteriaCount + entry.criteriaCount
                    elseif moduleKey == "treasures" then
                        cataCriteriaCount = cataCriteriaCount + entry.criteriaCount
                    end
                elseif entry.expansion == "mop" then
                    mopCount = mopCount + 1
                    local unavailableIDs = mopUnavailableIDs[moduleKey]
                    if unavailableIDs then
                        equal(entry.unavailable and true or false,
                            unavailableIDs[id] and true or false,
                            "Pandaria unavailable classification " .. moduleKey .. " " .. id)
                    end
                    if entry.sourceInfo then
                        truthy(entry.sourceInfo ~= "",
                            "Pandaria source coverage " .. moduleKey .. " " .. id)
                    end
                    if moduleKey == "mounts" and entry.unavailable then
                        endedMopMounts = endedMopMounts + 1
                    elseif moduleKey == "pets" and entry.unavailable then
                        endedMopPets = endedMopPets + 1
                    elseif moduleKey == "toys" and entry.unavailable then
                        endedMopToys = endedMopToys + 1
                    end
                    if moduleKey == "decorations" then
                        mopDecorationSources[entry.source] =
                            (mopDecorationSources[entry.source] or 0) + 1
                        if entry.source == "crafted" then
                            truthy(entry.skillLine,
                                "Pandaria crafted decoration profession " .. id)
                            mopCraftedDecorations = mopCraftedDecorations + 1
                        end
                    elseif moduleKey == "achievements" then
                        local source = entry.source or group.source
                        truthy(source, "Pandaria achievement source " .. id)
                        mopAchievementSources[source] =
                            (mopAchievementSources[source] or 0) + 1
                        if entry.taskList and entry.taskList.tasks then
                            for _, task in ipairs(entry.taskList.tasks) do
                                equal(task.achievementID, id,
                                    "Pandaria achievement task parent " .. id)
                                truthy(task.criteriaID,
                                    "Pandaria achievement task criteria ID " .. id)
                                mopAchievementTasks = mopAchievementTasks + 1
                            end
                        end
                    elseif moduleKey == "rares" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "Pandaria rare criteria-tree metadata " .. id)
                        equal(#entry.criteriaNPCIDs, entry.criteriaCount,
                            "Pandaria rare NPC metadata " .. id)
                        mopCriteriaCount = mopCriteriaCount + entry.criteriaCount
                    elseif moduleKey == "treasures" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "Pandaria treasure criteria-tree metadata " .. id)
                        if entry.criteriaNames then
                            equal(#entry.criteriaNames, entry.criteriaCount,
                                "Pandaria treasure criteria metadata " .. id)
                        end
                        mopCriteriaCount = mopCriteriaCount + entry.criteriaCount
                    end
                elseif entry.expansion == "wod" then
                    wodCount = wodCount + 1
                    local unavailableIDs = wodUnavailableIDs[moduleKey]
                    if unavailableIDs then
                        equal(entry.unavailable and true or false,
                            unavailableIDs[id] and true or false,
                            "Warlords unavailable classification " .. moduleKey .. " " .. id)
                    end
                    if entry.sourceInfo then
                        truthy(entry.sourceInfo ~= "",
                            "Warlords source coverage " .. moduleKey .. " " .. id)
                    end
                    if moduleKey == "mounts" and entry.unavailable then
                        endedWodMounts = endedWodMounts + 1
                    elseif moduleKey == "pets" and entry.unavailable then
                        endedWodPets = endedWodPets + 1
                    elseif moduleKey == "toys" and entry.unavailable then
                        endedWodToys = endedWodToys + 1
                    end
                    if moduleKey == "decorations" then
                        wodDecorationSources[entry.source] =
                            (wodDecorationSources[entry.source] or 0) + 1
                        if entry.source == "crafted" then
                            truthy(entry.skillLine,
                                "Warlords crafted decoration profession " .. id)
                            wodCraftedDecorations = wodCraftedDecorations + 1
                        end
                    elseif moduleKey == "achievements" then
                        local source = entry.source or group.source
                        truthy(source, "Warlords achievement source " .. id)
                        wodAchievementSources[source] =
                            (wodAchievementSources[source] or 0) + 1
                        if entry.taskList and entry.taskList.tasks then
                            for _, task in ipairs(entry.taskList.tasks) do
                                equal(task.achievementID, id,
                                    "Warlords achievement task parent " .. id)
                                truthy(task.criteriaID,
                                    "Warlords achievement task criteria ID " .. id)
                                wodAchievementTasks = wodAchievementTasks + 1
                            end
                        end
                    elseif moduleKey == "rares" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "Warlords rare criteria-tree metadata " .. id)
                        equal(#entry.criteriaNPCIDs, entry.criteriaCount,
                            "Warlords rare NPC metadata " .. id)
                        wodCriteriaCount = wodCriteriaCount + entry.criteriaCount
                    elseif moduleKey == "treasures" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "Warlords treasure criteria-tree metadata " .. id)
                        if entry.criteriaNames then
                            equal(#entry.criteriaNames, entry.criteriaCount,
                                "Warlords treasure criteria metadata " .. id)
                        end
                        wodCriteriaCount = wodCriteriaCount + entry.criteriaCount
                    end
                elseif entry.expansion == "legion" then
                    legionCount = legionCount + 1
                    local unavailableIDs = legionUnavailableIDs[moduleKey]
                    if unavailableIDs then
                        equal(entry.unavailable and true or false,
                            unavailableIDs[id] and true or false,
                            "Legion unavailable classification " .. moduleKey .. " " .. id)
                    end
                    if entry.sourceInfo then
                        truthy(entry.sourceInfo ~= "",
                            "Legion source coverage " .. moduleKey .. " " .. id)
                    end
                    if moduleKey == "mounts" and entry.unavailable then
                        endedLegionMounts = endedLegionMounts + 1
                    elseif moduleKey == "pets" and entry.unavailable then
                        endedLegionPets = endedLegionPets + 1
                    elseif moduleKey == "toys" and entry.unavailable then
                        endedLegionToys = endedLegionToys + 1
                    end
                    if moduleKey == "decorations" then
                        legionDecorationSources[entry.source] =
                            (legionDecorationSources[entry.source] or 0) + 1
                        if entry.source == "crafted" then
                            truthy(entry.skillLine,
                                "Legion crafted decoration profession " .. id)
                            legionCraftedDecorations = legionCraftedDecorations + 1
                        end
                    elseif moduleKey == "achievements" then
                        local source = entry.source or group.source
                        truthy(source, "Legion achievement source " .. id)
                        legionAchievementSources[source] =
                            (legionAchievementSources[source] or 0) + 1
                        if entry.taskList and entry.taskList.tasks then
                            for _, task in ipairs(entry.taskList.tasks) do
                                equal(task.achievementID, id,
                                    "Legion achievement task parent " .. id)
                                truthy(task.criteriaID,
                                    "Legion achievement task criteria ID " .. id)
                                legionAchievementTasks = legionAchievementTasks + 1
                            end
                        end
                    elseif moduleKey == "rares" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "Legion rare criteria-tree metadata " .. id)
                        equal(#entry.criteriaNPCIDs, entry.criteriaCount,
                            "Legion rare NPC metadata " .. id)
                        equal(#entry.criteriaObjectIDs, entry.criteriaCount,
                            "Legion rare object metadata " .. id)
                        for _, objectID in ipairs(entry.criteriaObjectIDs) do
                            if objectID then legionRareObjects = legionRareObjects + 1 end
                        end
                        legionCriteriaCount = legionCriteriaCount + entry.criteriaCount
                    elseif moduleKey == "treasures" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "Legion treasure criteria-tree metadata " .. id)
                        equal(#entry.criteriaNames, entry.criteriaCount,
                            "Legion treasure criteria metadata " .. id)
                        legionCriteriaCount = legionCriteriaCount + entry.criteriaCount
                    end
                elseif entry.expansion == "bfa" then
                    bfaCount = bfaCount + 1
                    local unavailableIDs = bfaUnavailableIDs[moduleKey]
                    if unavailableIDs then
                        equal(entry.unavailable and true or false,
                            unavailableIDs[id] and true or false,
                            "BFA unavailable classification " .. moduleKey .. " " .. id)
                    end
                    if entry.sourceInfo then
                        truthy(entry.sourceInfo ~= "",
                            "BFA source coverage " .. moduleKey .. " " .. id)
                    end
                    if moduleKey == "mounts" and entry.unavailable then
                        endedBfaMounts = endedBfaMounts + 1
                    elseif moduleKey == "pets" and entry.unavailable then
                        endedBfaPets = endedBfaPets + 1
                    elseif moduleKey == "toys" and entry.unavailable then
                        endedBfaToys = endedBfaToys + 1
                    end
                    if moduleKey == "decorations" then
                        bfaDecorationSources[entry.source] =
                            (bfaDecorationSources[entry.source] or 0) + 1
                        if entry.source == "crafted" then
                            truthy(entry.skillLine,
                                "BFA crafted decoration profession " .. id)
                            bfaCraftedDecorations = bfaCraftedDecorations + 1
                        end
                    elseif moduleKey == "achievements" then
                        local source = entry.source or group.source
                        truthy(source, "BFA achievement source " .. id)
                        bfaAchievementSources[source] =
                            (bfaAchievementSources[source] or 0) + 1
                        if entry.taskList and entry.taskList.tasks then
                            for _, task in ipairs(entry.taskList.tasks) do
                                equal(task.achievementID, id,
                                    "BFA achievement task parent " .. id)
                                truthy(task.criteriaID,
                                    "BFA achievement task criteria ID " .. id)
                                bfaAchievementTasks = bfaAchievementTasks + 1
                            end
                        end
                    elseif moduleKey == "rares" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "BFA rare criteria-tree metadata " .. id)
                        equal(#entry.criteriaNPCIDs, entry.criteriaCount,
                            "BFA rare NPC metadata " .. id)
                        equal(#entry.criteriaObjectIDs, entry.criteriaCount,
                            "BFA rare object metadata " .. id)
                        for _, objectID in ipairs(entry.criteriaObjectIDs) do
                            if objectID then bfaRareObjects = bfaRareObjects + 1 end
                        end
                        bfaCriteriaCount = bfaCriteriaCount + entry.criteriaCount
                    elseif moduleKey == "treasures" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "BFA treasure criteria-tree metadata " .. id)
                        equal(#entry.criteriaNames, entry.criteriaCount,
                            "BFA treasure criteria metadata " .. id)
                        bfaCriteriaCount = bfaCriteriaCount + entry.criteriaCount
                    end
                elseif entry.expansion == "shadowlands" then
                    slCount = slCount + 1
                    local unavailableIDs = slUnavailableIDs[moduleKey]
                    if unavailableIDs then
                        equal(entry.unavailable and true or false,
                            unavailableIDs[id] and true or false,
                            "Shadowlands unavailable classification " .. moduleKey .. " " .. id)
                    end
                    if entry.sourceInfo then
                        truthy(entry.sourceInfo ~= "",
                            "Shadowlands source coverage " .. moduleKey .. " " .. id)
                    end
                    if moduleKey == "mounts" and entry.unavailable then
                        endedShadowlandsMounts = endedShadowlandsMounts + 1
                    elseif moduleKey == "pets" and entry.unavailable then
                        endedShadowlandsPets = endedShadowlandsPets + 1
                    elseif moduleKey == "toys" and entry.unavailable then
                        endedShadowlandsToys = endedShadowlandsToys + 1
                    end
                    if moduleKey == "decorations" then
                        slDecorationSources[entry.source] =
                            (slDecorationSources[entry.source] or 0) + 1
                        if entry.source == "crafted" then
                            truthy(entry.skillLine,
                                "Shadowlands crafted decoration profession " .. id)
                            slCraftedDecorations = slCraftedDecorations + 1
                        end
                    elseif moduleKey == "achievements" then
                        local source = entry.source or group.source
                        truthy(source, "Shadowlands achievement source " .. id)
                        slAchievementSources[source] =
                            (slAchievementSources[source] or 0) + 1
                        if entry.taskList and entry.taskList.tasks then
                            for _, task in ipairs(entry.taskList.tasks) do
                                equal(task.achievementID, id,
                                    "Shadowlands achievement task parent " .. id)
                                truthy(task.criteriaID,
                                    "Shadowlands achievement task criteria ID " .. id)
                                slAchievementTasks = slAchievementTasks + 1
                            end
                        end
                    elseif moduleKey == "rares" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "Shadowlands rare criteria-tree metadata " .. id)
                        equal(#entry.criteriaNPCIDs, entry.criteriaCount,
                            "Shadowlands rare NPC metadata " .. id)
                        slCriteriaCount = slCriteriaCount + entry.criteriaCount
                    elseif moduleKey == "treasures" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "Shadowlands treasure criteria-tree metadata " .. id)
                        equal(#entry.criteriaNames, entry.criteriaCount,
                            "Shadowlands treasure criteria metadata " .. id)
                        slCriteriaCount = slCriteriaCount + entry.criteriaCount
                    end
                elseif entry.expansion == "df" then
                    dfCount = dfCount + 1
                    local unavailableIDs = dfUnavailableIDs[moduleKey]
                    if unavailableIDs then
                        equal(entry.unavailable and true or false,
                            unavailableIDs[id] and true or false,
                            "Dragonflight unavailable classification " .. moduleKey .. " " .. id)
                    end
                    if entry.sourceInfo then
                        truthy(not entry.sourceInfo:find("Source details unavailable", 1, true),
                            "Dragonflight source coverage " .. moduleKey .. " " .. id)
                    end
                    if moduleKey == "mounts" and entry.unavailable then
                        endedDragonflightMounts = endedDragonflightMounts + 1
                    elseif moduleKey == "pets" and entry.unavailable then
                        endedDragonflightPets = endedDragonflightPets + 1
                    elseif moduleKey == "toys" and entry.unavailable then
                        endedDragonflightToys = endedDragonflightToys + 1
                    end
                    if moduleKey == "mounts" and entry.sourceInfo
                        and entry.sourceInfo:find("Remix", 1, true) then
                        mopRemixMounts = mopRemixMounts + 1
                        truthy(entry.unavailable,
                            "ended Mists of Pandaria Remix mount unavailable flag " .. id)
                    elseif moduleKey == "decorations" then
                        dfDecorationSources[entry.source] =
                            (dfDecorationSources[entry.source] or 0) + 1
                        if entry.source == "crafted" then
                            truthy(entry.skillLine,
                                "Dragonflight crafted decoration profession " .. id)
                            dfCraftedDecorations = dfCraftedDecorations + 1
                        end
                    elseif moduleKey == "achievements" then
                        local source = entry.source or group.source
                        truthy(source, "Dragonflight achievement source " .. id)
                        dfAchievementSources[source] =
                            (dfAchievementSources[source] or 0) + 1
                        if entry.taskList and entry.taskList.tasks then
                            for _, task in ipairs(entry.taskList.tasks) do
                                equal(task.achievementID, id,
                                    "Dragonflight achievement task parent " .. id)
                                truthy(task.criteriaID,
                                    "Dragonflight achievement task criteria ID " .. id)
                                dfAchievementTasks = dfAchievementTasks + 1
                            end
                        end
                    elseif moduleKey == "rares" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "Dragonflight rare criteria-tree metadata " .. id)
                        equal(#entry.criteriaNPCIDs, entry.criteriaCount,
                            "Dragonflight rare criteria metadata " .. id)
                        dfCriteriaCount = dfCriteriaCount + entry.criteriaCount
                    elseif moduleKey == "treasures" then
                        equal(#entry.criteriaTreeIDs, entry.criteriaCount,
                            "Dragonflight treasure criteria-tree metadata " .. id)
                        equal(#entry.criteriaNames, entry.criteriaCount,
                            "Dragonflight treasure criteria metadata " .. id)
                        dfCriteriaCount = dfCriteriaCount + entry.criteriaCount
                    end
                elseif entry.expansion == "tww" then
                    twwCount = twwCount + 1
                    if moduleKey == "mounts" and entry.sourceInfo
                        and entry.sourceInfo:find("WoW Remix: Legion", 1, true) then
                        legionRemixMounts = legionRemixMounts + 1
                        truthy(entry.unavailable,
                            "ended Legion Remix mount unavailable flag " .. id)
                        truthy(entry.cost and entry.cost.currency,
                            "Legion Remix mount currency cost " .. id)
                        equal(entry.cost.currency[1], MC.CURRENCY.LegionRemixBronze,
                            "Legion Remix Bronze currency " .. id)
                        if entry.cost.currency[2] == 10000 then
                            remixVendorMounts = remixVendorMounts + 1
                            truthy(entry.sourceInfo:find("Hemet Nesingwary XVII", 1, true),
                                "Legion Remix vendor source " .. id)
                        elseif entry.cost.currency[2] == 20000 then
                            remixClassMounts = remixClassMounts + 1
                            truthy(entry.sourceInfo:find("Grandmaster Jakkus", 1, true),
                                "Legion Remix class source " .. id)
                        else
                            error("unexpected Legion Remix mount cost " .. id)
                        end
                    elseif moduleKey == "decorations" then
                        twwDecorationSources[entry.source] =
                            (twwDecorationSources[entry.source] or 0) + 1
                        if entry.source == "crafted" then
                            truthy(entry.skillLine,
                                "TWW crafted decoration profession " .. id)
                            if entry.skillLine == MC.PROFESSION.Cooking then
                                twwCookingDecorations = twwCookingDecorations + 1
                            end
                        end
                    elseif moduleKey == "achievements" then
                        local source = entry.source or group.source
                        truthy(source, "TWW achievement source " .. id)
                        twwAchievementSources[source] =
                            (twwAchievementSources[source] or 0) + 1
                        if entry.taskList and entry.taskList.tasks then
                            for _, task in ipairs(entry.taskList.tasks) do
                                equal(task.achievementID, id,
                                    "TWW achievement task parent " .. id)
                                truthy(task.criteriaID,
                                    "TWW achievement task criteria ID " .. id)
                                twwAchievementTasks = twwAchievementTasks + 1
                            end
                        end
                    elseif moduleKey == "rares" then
                        equal(#entry.criteriaNPCIDs, entry.criteriaCount,
                            "TWW rare criteria metadata " .. id)
                        criteriaCount = criteriaCount + entry.criteriaCount
                    elseif moduleKey == "treasures" then
                        equal(#entry.criteriaNames, entry.criteriaCount,
                            "TWW treasure criteria metadata " .. id)
                        criteriaCount = criteriaCount + entry.criteriaCount
                    end
                end
            end
        end
        equal(classicCount, fixture.classicCount, moduleKey .. " Classic count")
        equal(tbcCount, fixture.tbcCount, moduleKey .. " TBC count")
        equal(wrathCount, fixture.wrathCount, moduleKey .. " Wrath count")
        equal(cataCount, fixture.cataCount, moduleKey .. " Cataclysm count")
        equal(mopCount, fixture.mopCount, moduleKey .. " Pandaria count")
        equal(wodCount, fixture.wodCount, moduleKey .. " Warlords count")
        equal(legionCount, fixture.legionCount, moduleKey .. " Legion count")
        equal(bfaCount, fixture.bfaCount, moduleKey .. " BFA count")
        equal(slCount, fixture.slCount, moduleKey .. " Shadowlands count")
        equal(dfCount, fixture.dfCount, moduleKey .. " Dragonflight count")
        equal(twwCount, fixture.twwCount, moduleKey .. " TWW count")
        if moduleKey == "mounts" then
            equal(endedClassicMounts, 0, "unavailable Classic mount count")
            equal(endedTbcMounts, 6, "unavailable TBC mount count")
            equal(endedWrathMounts, 10, "unavailable Wrath mount count")
            equal(endedCataMounts, 3, "unavailable Cataclysm mount count")
            equal(endedMopMounts, 13, "unavailable Pandaria mount count")
            equal(endedWodMounts, 7, "unavailable Warlords mount count")
            equal(endedLegionMounts, 9, "unavailable Legion mount count")
            equal(endedBfaMounts, 7, "unavailable BFA mount count")
            equal(endedShadowlandsMounts, 10, "unavailable Shadowlands mount count")
            equal(endedDragonflightMounts, 42, "unavailable Dragonflight mount count")
            equal(mopRemixMounts, 29, "Dragonflight Mists of Pandaria Remix mount count")
            equal(legionRemixMounts, 44, "TWW Legion Remix mount count")
            equal(remixVendorMounts, 33, "TWW Legion Remix vendor mount count")
            equal(remixClassMounts, 11, "TWW Legion Remix class mount count")
        elseif moduleKey == "pets" then
            equal(endedClassicPets, 0, "unavailable Classic pet count")
            equal(endedTbcPets, 1, "unavailable TBC pet count")
            equal(endedWrathPets, 2, "unavailable Wrath pet count")
            equal(endedCataPets, 0, "unavailable Cataclysm pet count")
            equal(endedMopPets, 0, "unavailable Pandaria pet count")
            equal(endedWodPets, 0, "unavailable Warlords pet count")
            equal(endedLegionPets, 2, "unavailable Legion pet count")
            equal(endedBfaPets, 0, "unavailable BFA pet count")
            equal(endedShadowlandsPets, 1, "unavailable Shadowlands pet count")
            equal(endedDragonflightPets, 6, "unavailable Dragonflight pet count")
        elseif moduleKey == "toys" then
            equal(endedClassicToys, 0, "unavailable Classic toy count")
            equal(endedTbcToys, 0, "unavailable TBC toy count")
            equal(endedWrathToys, 0, "unavailable Wrath toy count")
            equal(endedCataToys, 3, "unavailable Cataclysm toy count")
            equal(endedMopToys, 0, "unavailable Pandaria toy count")
            equal(endedWodToys, 0, "unavailable Warlords toy count")
            equal(endedLegionToys, 0, "unavailable Legion toy count")
            equal(endedBfaToys, 0, "unavailable BFA toy count")
            equal(endedShadowlandsToys, 0, "unavailable Shadowlands toy count")
            equal(endedDragonflightToys, 8, "unavailable Dragonflight toy count")
        elseif moduleKey == "decorations" then
            equal(classicDecorationSources.crafted, 19, "Classic crafted decoration count")
            equal(classicDecorationSources.achievement, 1, "Classic achievement decoration count")
            equal(classicDecorationSources.quest, 1, "Classic quest decoration count")
            equal(classicDecorationSources.drop, 1, "Classic drop decoration count")
            equal(classicCraftedDecorations, 19, "Classic crafted decoration profession count")
            equal(tbcDecorationSources.crafted, 26, "TBC crafted decoration count")
            equal(tbcDecorationSources.achievement, 2, "TBC achievement decoration count")
            equal(tbcDecorationSources.drop, 1, "TBC drop decoration count")
            equal(tbcCraftedDecorations, 26, "TBC crafted decoration profession count")
            equal(wrathDecorationSources.crafted, 21, "Wrath crafted decoration count")
            equal(wrathDecorationSources.quest, 3, "Wrath quest decoration count")
            equal(wrathDecorationSources.achievement, 2, "Wrath achievement decoration count")
            equal(wrathDecorationSources.drop, 1, "Wrath drop decoration count")
            equal(wrathCraftedDecorations, 21, "Wrath crafted decoration profession count")
            equal(cataDecorationSources.crafted, 20, "Cataclysm crafted decoration count")
            equal(cataDecorationSources.quest, 20, "Cataclysm quest decoration count")
            equal(cataDecorationSources.achievement, 2, "Cataclysm achievement decoration count")
            equal(cataDecorationSources.vendor, 2, "Cataclysm vendor decoration count")
            equal(cataDecorationSources.drop, 2, "Cataclysm drop decoration count")
            equal(cataCraftedDecorations, 20, "Cataclysm crafted decoration profession count")
            equal(mopDecorationSources.crafted, 21, "Pandaria crafted decoration count")
            equal(mopDecorationSources.vendor, 11, "Pandaria vendor decoration count")
            equal(mopDecorationSources.quest, 5, "Pandaria quest decoration count")
            equal(mopDecorationSources.achievement, 2, "Pandaria achievement decoration count")
            equal(mopDecorationSources.drop, 2, "Pandaria drop decoration count")
            equal(mopCraftedDecorations, 21, "Pandaria crafted decoration profession count")
            equal(wodDecorationSources.crafted, 21, "Warlords crafted decoration count")
            equal(wodDecorationSources.vendor, 26, "Warlords vendor decoration count")
            equal(wodDecorationSources.quest, 27, "Warlords quest decoration count")
            equal(wodDecorationSources.achievement, 1, "Warlords achievement decoration count")
            equal(wodDecorationSources.drop, 5, "Warlords drop decoration count")
            equal(wodCraftedDecorations, 21, "Warlords crafted decoration profession count")
            equal(legionDecorationSources.crafted, 23, "Legion crafted decoration count")
            equal(legionDecorationSources.vendor, 75, "Legion vendor decoration count")
            equal(legionDecorationSources.quest, 34, "Legion quest decoration count")
            equal(legionDecorationSources.achievement, 71, "Legion achievement decoration count")
            equal(legionDecorationSources.drop, 8, "Legion drop decoration count")
            equal(legionCraftedDecorations, 23, "Legion crafted decoration profession count")
            equal(bfaDecorationSources.crafted, 28, "BFA crafted decoration count")
            equal(bfaDecorationSources.vendor, 44, "BFA vendor decoration count")
            equal(bfaDecorationSources.quest, 28, "BFA quest decoration count")
            equal(bfaDecorationSources.achievement, 21, "BFA achievement decoration count")
            equal(bfaDecorationSources.drop, 15, "BFA drop decoration count")
            equal(bfaCraftedDecorations, 28, "BFA crafted decoration profession count")
            equal(slDecorationSources.crafted, 23, "Shadowlands crafted decoration count")
            equal(slDecorationSources.vendor, 1, "Shadowlands vendor decoration count")
            equal(slDecorationSources.achievement, 1, "Shadowlands achievement decoration count")
            equal(slDecorationSources.quest, 1, "Shadowlands quest decoration count")
            equal(slCraftedDecorations, 23, "Shadowlands crafted decoration profession count")
            equal(dfDecorationSources.crafted, 25, "Dragonflight crafted decoration count")
            equal(dfDecorationSources.vendor, 26, "Dragonflight vendor decoration count")
            equal(dfDecorationSources.quest, 12, "Dragonflight quest decoration count")
            equal(dfDecorationSources.achievement, 10, "Dragonflight achievement decoration count")
            equal(dfDecorationSources.drop, 3, "Dragonflight drop decoration count")
            equal(dfCraftedDecorations, 25, "Dragonflight crafted decoration profession count")
            equal(twwDecorationSources.crafted, 24, "TWW crafted decoration count")
            equal(twwDecorationSources.vendor, 41, "TWW vendor decoration count")
            equal(twwDecorationSources.quest, 22, "TWW quest decoration count")
            equal(twwDecorationSources.achievement, 15, "TWW achievement decoration count")
            equal(twwDecorationSources.drop, 6, "TWW drop decoration count")
            equal(twwCookingDecorations, 4, "TWW Cooking decoration count")
        elseif moduleKey == "achievements" then
            equal(classicAchievementSources.zone, 42, "Classic exploration achievement count")
            equal(classicAchievementSources.alterac, 19, "Classic Alterac Valley achievement count")
            equal(classicAchievementSources.arathi, 16, "Classic Arathi Basin achievement count")
            equal(classicAchievementSources.warsong, 19, "Classic Warsong Gulch achievement count")
            equal(classicAchievementSources.dungeons, 24, "Classic dungeon achievement count")
            equal(classicAchievementSources.raid, 25, "Classic raid achievement count")
            equal(classicAchievementSources.metas, 51, "Classic quest/meta achievement count")
            equal(classicAchievementSources.reputation, 4, "Classic reputation achievement count")
            equal(classicAchievementTasks, 1149, "Classic attached achievement criteria count")
            equal(tbcAchievementSources.zone, 14, "TBC exploration achievement count")
            equal(tbcAchievementSources.eye_of_storm, 13, "TBC Eye of the Storm achievement count")
            equal(tbcAchievementSources.dungeons, 40, "TBC dungeon and raid achievement count")
            equal(tbcAchievementSources.metas, 16, "TBC quest/meta achievement count")
            equal(tbcAchievementSources.reputation, 16, "TBC reputation achievement count")
            equal(tbcAchievementTasks, 651, "TBC attached achievement criteria count")
            equal(wrathAchievementSources.zone, 16, "Wrath exploration achievement count")
            equal(wrathAchievementSources.dungeons, 80, "Wrath dungeon achievement count")
            equal(wrathAchievementSources.metas, 21, "Wrath quest/meta achievement count")
            equal(wrathAchievementSources.reputation, 14, "Wrath reputation achievement count")
            equal(wrathAchievementSources.wintergrasp, 19, "Wrath Wintergrasp achievement count")
            equal(wrathAchievementSources.raid, 203, "Wrath raid achievement count")
            equal(wrathAchievementSources.tournament, 35, "Wrath Argent Tournament achievement count")
            equal(wrathAchievementTasks, 1207, "Wrath attached achievement criteria count")
            equal(cataAchievementSources.dungeons, 62, "Cataclysm dungeon achievement count")
            equal(cataAchievementSources.raid, 62, "Cataclysm raid achievement count")
            equal(cataAchievementSources.zone, 9, "Cataclysm exploration achievement count")
            equal(cataAchievementSources.metas, 43, "Cataclysm quest/meta achievement count")
            equal(cataAchievementSources.reputation, 9, "Cataclysm reputation achievement count")
            equal(cataAchievementSources.gilneas, 15, "Cataclysm Battle for Gilneas achievement count")
            equal(cataAchievementSources.twinpeaks, 20, "Cataclysm Twin Peaks achievement count")
            equal(cataAchievementSources.tolbarad, 14, "Cataclysm Tol Barad achievement count")
            equal(cataAchievementTasks, 500, "Cataclysm attached achievement criteria count")
            equal(mopAchievementSources.dungeons, 44, "Pandaria dungeon achievement count")
            equal(mopAchievementSources.raid, 106, "Pandaria raid achievement count")
            equal(mopAchievementSources.metas, 64, "Pandaria quest/meta achievement count")
            equal(mopAchievementSources.zone, 52, "Pandaria exploration achievement count")
            equal(mopAchievementSources.reputation, 20, "Pandaria reputation achievement count")
            equal(mopAchievementSources.silvershard, 11, "Pandaria Silvershard achievement count")
            equal(mopAchievementSources.kotmogu, 10, "Pandaria Kotmogu achievement count")
            equal(mopAchievementSources.deepwind, 10, "Pandaria Deepwind achievement count")
            equal(mopAchievementSources.proving, 19, "Pandaria Proving Grounds achievement count")
            equal(mopAchievementSources.scenarios, 69, "Pandaria scenario achievement count")
            equal(mopAchievementSources.timeless, 6, "Pandaria Timeless Isle achievement count")
            equal(mopAchievementTasks, 1002, "Pandaria attached achievement criteria count")
            equal(wodAchievementSources.metas, 77, "Warlords quest/meta achievement count")
            equal(wodAchievementSources.dungeons, 49, "Warlords dungeon achievement count")
            equal(wodAchievementSources.raid, 75, "Warlords raid achievement count")
            equal(wodAchievementSources.reputation, 13, "Warlords reputation achievement count")
            equal(wodAchievementSources.zone, 25, "Warlords exploration achievement count")
            equal(wodAchievementSources.garrison, 15, "Warlords garrison achievement count")
            equal(wodAchievementSources.buildings, 51, "Warlords garrison-building achievement count")
            equal(wodAchievementSources.followers, 13, "Warlords follower achievement count")
            equal(wodAchievementSources.missions, 15, "Warlords mission achievement count")
            equal(wodAchievementSources.ashran, 21, "Warlords Ashran achievement count")
            equal(wodAchievementSources.monuments, 7, "Warlords monument achievement count")
            equal(wodAchievementSources.invasions, 18, "Warlords invasion achievement count")
            equal(wodAchievementSources.shipyard, 27, "Warlords shipyard achievement count")
            equal(wodAchievementTasks, 981, "Warlords attached achievement criteria count")
            equal(legionAchievementSources.metas, 44, "Legion quest/meta achievement count")
            equal(legionAchievementSources.dungeons, 76, "Legion dungeon achievement count")
            equal(legionAchievementSources.raid, 100, "Legion raid achievement count")
            equal(legionAchievementSources.artifacts, 22, "Legion artifact achievement count")
            equal(legionAchievementSources.zone, 36, "Legion exploration achievement count")
            equal(legionAchievementSources.reputation, 11, "Legion reputation achievement count")
            equal(legionAchievementSources.class_hall, 5, "Legion class-hall achievement count")
            equal(legionAchievementSources.missions, 12, "Legion mission achievement count")
            equal(legionAchievementTasks, 642, "Legion attached achievement criteria count")
            equal(bfaAchievementSources.metas, 77, "BFA quest/meta achievement count")
            equal(bfaAchievementSources.dungeons, 59, "BFA dungeon achievement count")
            equal(bfaAchievementSources.raid, 97, "BFA raid achievement count")
            equal(bfaAchievementSources.zone, 96, "BFA exploration achievement count")
            equal(bfaAchievementSources.reputation, 16, "BFA reputation achievement count")
            equal(bfaAchievementSources.islands, 64, "BFA island achievement count")
            equal(bfaAchievementSources.war_effort, 37, "BFA war-effort achievement count")
            equal(bfaAchievementSources.heart_of_azeroth, 10, "BFA Heart of Azeroth achievement count")
            equal(bfaAchievementTasks, 1310, "BFA attached achievement criteria count")
            equal(slAchievementSources.metas, 48, "Shadowlands quest/meta achievement count")
            equal(slAchievementSources.dungeons, 57, "Shadowlands dungeon achievement count")
            equal(slAchievementSources.zone, 74, "Shadowlands exploration achievement count")
            equal(slAchievementSources.raid, 93, "Shadowlands raid achievement count")
            equal(slAchievementSources.reputation, 9, "Shadowlands reputation achievement count")
            equal(slAchievementSources.torghast, 63, "Shadowlands Torghast achievement count")
            equal(slAchievementSources.covenants, 75, "Shadowlands covenant achievement count")
            equal(slAchievementTasks, 1676, "Shadowlands attached achievement criteria count")
            equal(dfAchievementSources.metas, 53, "Dragonflight quest/meta achievement count")
            equal(dfAchievementSources.dragonriding, 167, "Dragonflight dragonriding achievement count")
            equal(dfAchievementSources.zone, 154, "Dragonflight exploration achievement count")
            equal(dfAchievementSources.reputation, 50, "Dragonflight reputation achievement count")
            equal(dfAchievementSources.dungeons, 59, "Dragonflight dungeon achievement count")
            equal(dfAchievementSources.raid, 72, "Dragonflight raid achievement count")
            equal(dfAchievementSources.mounts, 21, "Dragonflight collection achievement count")
            equal(dfAchievementTasks, 2879, "Dragonflight attached achievement criteria count")
            equal(twwAchievementSources.zone, 163, "TWW general achievement count")
            equal(twwAchievementSources.delves, 113, "TWW delve achievement count")
            equal(twwAchievementSources.dungeons, 34, "TWW dungeon achievement count")
            equal(twwAchievementSources.raid, 73, "TWW raid achievement count")
            equal(twwAchievementTasks, 1485, "TWW attached achievement criteria count")
        end
        if moduleKey == "rares" then
            equal(classicCriteriaCount, 0, "Classic rare criteria count")
            equal(tbcCriteriaCount, 20, "TBC rare criteria count")
            equal(wrathCriteriaCount, 23, "Wrath rare criteria count")
            equal(cataCriteriaCount, 0, "Cataclysm rare criteria count")
            equal(mopCriteriaCount, 104, "Pandaria rare criteria count")
            equal(wodCriteriaCount, 72, "Warlords rare criteria count")
            equal(legionCriteriaCount, 185, "Legion rare criteria count")
            equal(legionRareObjects, 7, "Legion rare object-provider count")
            equal(bfaCriteriaCount, 256, "BFA rare criteria count")
            equal(bfaRareObjects, 5, "BFA rare object-provider count")
            equal(slCriteriaCount, 211, "Shadowlands rare criteria count")
            equal(dfCriteriaCount, 197, "Dragonflight rare criteria count")
            equal(criteriaCount, 140, "TWW rare criteria count")
        end
        if moduleKey == "treasures" then
            equal(classicCriteriaCount, 0, "Classic treasure criteria count")
            equal(tbcCriteriaCount, 0, "TBC treasure criteria count")
            equal(wrathCriteriaCount, 0, "Wrath treasure criteria count")
            equal(cataCriteriaCount, 0, "Cataclysm treasure criteria count")
            equal(mopCriteriaCount, 98, "Pandaria treasure criteria count")
            equal(wodCriteriaCount, 368, "Warlords treasure criteria count")
            equal(legionCriteriaCount, 314, "Legion treasure criteria count")
            equal(bfaCriteriaCount, 98, "BFA treasure criteria count")
            equal(slCriteriaCount, 103, "Shadowlands treasure criteria count")
            equal(dfCriteriaCount, 57, "Dragonflight treasure criteria count")
            equal(criteriaCount, 86, "TWW treasure criteria count")
        end
    end

    local function findCatalogEntry(dataField, listField, idField, expectedID)
        for _, group in ipairs(MC[dataField] or {}) do
            for _, entry in ipairs(group[listField] or {}) do
                if entry[idField] == expectedID then return entry end
            end
        end
    end

    local acquisitionChecks = {
        { "MountData", "mounts", "mountID", 293, "shadowlands" },
        { "MountData", "mounts", "mountID", 2767, "midnight" },
        { "PetData", "pets", "speciesID", 199, "wrath" },
        { "PetData", "pets", "speciesID", 238, "wrath" },
        { "PetData", "pets", "speciesID", 306, "cata" },
        { "PetData", "pets", "speciesID", 3215, "shadowlands" },
        { "PetData", "pets", "speciesID", 3362, "tww" },
        { "DecorationData", "decorations", "decorID", 14824, "midnight" },
        { "DecorationData", "decorations", "decorID", 15478, "midnight" },
        { "DecorationData", "decorations", "decorID", 15480, "midnight" },
    }
    for _, check in ipairs(acquisitionChecks) do
        local entry = findCatalogEntry(check[1], check[2], check[3], check[4])
        truthy(entry, "missing acquisition-era collectible " .. check[4])
        equal(entry.expansion, check[5], "acquisition expansion " .. check[4])
    end

    -- HandyNotes_WarWithin mislabeled these six pet items as toys. The
    -- species/item pairs are collectible pets and must never enter ToyData.
    local underminePetMislabels = {
        [232850] = 4649, [232846] = 4648, [232849] = 4650,
        [232840] = 4661, [232841] = 4644, [232842] = 4638,
    }
    for itemID, speciesID in pairs(underminePetMislabels) do
        local pet = findCatalogEntry("PetData", "pets", "speciesID", speciesID)
        truthy(pet, "missing Undermine pet species " .. speciesID)
        equal(pet.itemID, itemID, "Undermine pet item mapping " .. speciesID)
        equal(findCatalogEntry("ToyData", "toys", "itemID", itemID), nil,
            "Undermine pet item must not be a toy " .. itemID)
    end
    equal(findCatalogEntry("ToyData", "toys", "itemID", 131809), nil,
        "Gleaming Roc Feather is a component, not a toy")
    truthy(findCatalogEntry("ToyData", "toys", "itemID", 131811),
        "Rocfeather Skyhorn Kite is the actual toy")

    -- Current collection DB2 still exposes shells for these records, but
    -- source adjudication proves they are obsolete/internal or never shipped.
    for _, mountID in ipairs({ 7, 12, 43, 123, 145 }) do
        equal(findCatalogEntry("MountData", "mounts", "mountID", mountID), nil,
            "obsolete mount-spell record must stay excluded " .. mountID)
    end
    for _, speciesID in ipairs({ 1757, 1758 }) do
        equal(findCatalogEntry("PetData", "pets", "speciesID", speciesID), nil,
            "internal pet record must stay excluded " .. speciesID)
    end
    for _, itemID in ipairs({ 88587, 110586, 166851 }) do
        equal(findCatalogEntry("ToyData", "toys", "itemID", itemID), nil,
            "never-implemented toy record must stay excluded " .. itemID)
    end
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
        Themes = { default = true },
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
    C_AchievementInfo.GetAchievementInfo = function() return nil end
    equal(MC.modulesByKey.achievements.Scanner:Scan(), true,
        "achievement scan commits while its cache is streaming")
    local partial = MC.modulesByKey.achievements.Scanner.results
    equal(partial._partial, 1, "streaming achievement row marked partial")
    equal(partial.totalAll, 0, "streaming achievement row stays out of totals")

    MC.modulesByKey.achievements.Scanner._warnedInvalid = true
    C_AchievementInfo.GetAchievementInfo = function() error("removed ID") end
    equal(MC.modulesByKey.achievements.Scanner:Scan(), true,
        "achievement scan commits past an invalid ID")
    equal(MC.modulesByKey.achievements.Scanner.results._invalid, 1,
        "invalid achievement row counted")
    equal(MC.modulesByKey.achievements.Scanner.results._partial, nil,
        "invalid achievement rows do not hold the scan partial")

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

-- Rare and treasure scanners commit partial snapshots while criteria are
-- still streaming — marked _partial for the bounded retry — and scan the
-- live criteria count rather than aborting on a shipped-count mismatch.
do
    CanShowAchievementUI = function() return true end
    local criteriaCount = 1
    GetAchievementNumCriteria = function(achievementID)
        if not achievementID then error("navigation-only row queried as achievement") end
        return criteriaCount
    end
    GetAchievementCriteriaInfo = function(achievementID, index)
        if not achievementID then error("navigation-only row queried as achievement") end
        return "Criterion " .. index, 0, index == 1, 0, 1, nil, 0, 9000 + index
    end

    local rareMC = { modulesByKey = { rares = {} } }
    loadAddon("addons/Collectionist/Data/Constants.lua", rareMC)
    rareMC.IsGroupVisible = function() return true end
    rareMC.RareData = {
        { achievementID = 10, criteriaCount = 2, source = "coiled_isle",
          zone = "Test", expansion = "midnight", criteriaNPCIDs = { 1, 2 } },
        { navigationOnly = true, source = "navigation", zone = "Test",
          expansion = "midnight", rares = {
              { npcID = 333, name = "Untracked Rare",
                waypoint = { 1, 0.3, 0.4 } },
          } },
    }
    rareMC.RareNPCs = { [1] = { 1, 0.1, 0.1 }, [2] = { 1, 0.2, 0.2 } }
    loadAddon("addons/Collectionist/Modules/Rares/Scanner.lua", rareMC)
    local rareScanner = rareMC.modulesByKey.rares.Scanner
    equal(rareScanner:Scan(), true, "short rare criteria still commits")
    equal(rareScanner.results._partial, 1, "missing rare criteria marked partial")
    equal(rareScanner.results.totalAll, 1, "only live rare criteria counted")
    criteriaCount = 2
    equal(rareScanner:Scan(), true, "complete rare criteria scan")
    equal(rareScanner.results.totalAll, 2, "rare criteria denominator")
    equal(rareScanner.results.total, 2,
        "navigation-only rare stays out of visible completion denominator")
    equal(rareScanner.results.navigationCount, 1,
        "navigation-only rare display count")
    local rareNavigation = rareScanner.results.bySource.navigation[1]
    equal(rareNavigation.npcID, 333, "navigation-only rare entity")
    equal(rareNavigation.navigationOnly, true, "navigation-only rare marker")
    equal(rareNavigation.collected, nil,
        "navigation-only rare has no completion state")
    equal(rareScanner.results._partial, nil, "complete rare scan is not partial")
    rareMC.RareData[1].criteriaNPCIDs = { 1, false }
    rareMC.RareData[1].criteriaObjectIDs = { false, 777 }
    equal(rareScanner:Scan(), true, "mixed rare NPC/object criteria scan")
    local objectEncounter = rareScanner.results.bySource.coiled_isle[1]
    equal(objectEncounter.objectID, 777, "rare object-provider metadata")
    equal(objectEncounter.npcID, nil,
        "rare object criterion must not treat completion quest as NPC")

    criteriaCount = 1
    local treasureMC = { modulesByKey = { treasures = {} } }
    loadAddon("addons/Collectionist/Data/Constants.lua", treasureMC)
    treasureMC.IsGroupVisible = function() return true end
    treasureMC.TreasureData = {
        { achievementID = 20, criteriaCount = 2, source = "coiled_isle",
          zone = "Test", expansion = "midnight", criteriaNames = { "One", "Two" } },
        { navigationOnly = true, source = "navigation", zone = "Test",
          expansion = "midnight", treasures = {
              { objectID = 444, name = "Untracked Treasure",
                waypoint = { 1, 0.4, 0.5 } },
          } },
    }
    treasureMC.TreasureCoords = {
        One = { 1, 0.1, 0.1 }, Two = { 1, 0.2, 0.2 },
    }
    loadAddon("addons/Collectionist/Modules/Treasures/Scanner.lua", treasureMC)
    local treasureScanner = treasureMC.modulesByKey.treasures.Scanner
    equal(treasureScanner:Scan(), true, "short treasure criteria still commits")
    equal(treasureScanner.results._partial, 1,
        "missing treasure criteria marked partial")
    equal(treasureScanner.results.totalAll, 1, "only live treasure criteria counted")
    criteriaCount = 2
    equal(treasureScanner:Scan(), true, "complete treasure criteria scan")
    equal(treasureScanner.results.totalAll, 2, "treasure criteria denominator")
    equal(treasureScanner.results.total, 2,
        "navigation-only treasure stays out of visible completion denominator")
    equal(treasureScanner.results.navigationCount, 1,
        "navigation-only treasure display count")
    local treasureNavigation = treasureScanner.results.bySource.navigation[1]
    equal(treasureNavigation.objectID, 444, "navigation-only treasure entity")
    equal(treasureNavigation.navigationOnly, true,
        "navigation-only treasure marker")
    equal(treasureNavigation.collected, nil,
        "navigation-only treasure has no completion state")
    equal(treasureScanner.results._partial, nil,
        "complete treasure scan is not partial")
end

-- Rare and treasure bitmap IDs are locale-independent criteria keys. During
-- the post-login strict window a partial achievement cache never emits a
-- bitmap; once the window elapses, criteria past the live count pack as
-- stable 0-bits instead of blocking the whole broadcast.
do
    CreateFrame = newFrameFactory()
    GetTime = function() return 0 end
    local criteriaCounts = { [10] = 2, [20] = 1 }
    GetAchievementNumCriteria = function(id) return criteriaCounts[id] or 0 end
    GetAchievementCriteriaInfo = function(id, idx)
        local complete = (id == 10 and idx == 1) or id == 20
        return "localized-name-" .. id .. "-" .. idx, 0, complete
    end
    local MC = {
        MountData = {}, PetData = {}, ToyData = {}, DecorationData = {},
        RareData = {
            { achievementID = 10, criteriaCount = 2 },
            { navigationOnly = true, rares = {
                { npcID = 333, name = "Untracked Rare",
                  waypoint = { 1, 0.3, 0.4 } },
            } },
        },
        TreasureData = {
            { achievementID = 20, criteriaCount = 1 },
            { navigationOnly = true, treasures = {
                { objectID = 444, name = "Untracked Treasure",
                  waypoint = { 1, 0.4, 0.5 } },
            } },
        },
        modulesByKey = {},
    }
    loadAddon("addons/Collectionist/Modules/Roster/Bitmap.lua", MC)
    MC.Bitmap:Init()
    equal(MC.Bitmap.ids.rares[1], "10:1", "rare criterion key")
    equal(MC.Bitmap.ids.treasures[1], "20:1", "treasure criterion key")
    equal(#MC.Bitmap.ids.rares, 2,
        "navigation-only rares stay out of roster bitmap")
    equal(#MC.Bitmap.ids.treasures, 1,
        "navigation-only treasures stay out of roster bitmap")

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

    -- Hotfix shrink after the strict window: sharing keeps working and the
    -- removed criterion packs as a stable 0-bit.
    criteriaCounts[10] = 1
    MC.Bitmap._criteriaReady = false
    MC.Bitmap._loginAt = -300
    local settled = MC.Bitmap:Build()
    truthy(settled and settled ~= "", "post-window hotfix shrink still builds")
    local settledDecoded = MC.Bitmap:Decode(settled)
    equal(settledDecoded.rares["10:1"], true, "live criterion bit kept")
    equal(settledDecoded.rares["10:2"], nil, "removed criterion packs as 0-bit")
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

    equal(#entries("decorations") - baseCounts.decorations, 116, "12.0.7 decoration count")
    local neighborhood, special = 0, 0
    for _, decor in ipairs(entries("decorations")) do
        if decor.sourceInfo == "Neighborhood decor vendor (Patch 12.0.7)" then
            neighborhood = neighborhood + 1
        end
    end
    equal(neighborhood, 102, "12.0.7 neighborhood vendor decoration count")
    special = (#entries("decorations") - baseCounts.decorations) - neighborhood
    equal(special, 14, "12.0.7 special decoration count")
    assertIDs("decorations", "decorID", {
        25664, 25665, 25564, 25566, 18802, 25565,
        25307, 20679, 24194, 24193, 23706, 2606,
        21857, 16813,
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

    equal(#entries("mounts") - patch120007Counts.mounts, 24, "12.1 mount count")
    assertIDs("mounts", "mountID", {
        3060, 3054, 3019, 2980, 3061, 3051, 3023, 3053, 3062, 3029, 3063,
        3064, 3043, 2839, 3032, 3031, 3058, 3021, 3030, 2821, 3002, 3003, 3020,
        3069,
    }, "12.1 mount")
    local arcaneGolem = findEntry("mounts", "mountID", 2839)
    equal(arcaneGolem.itemID, 262496, "Delver's Arcane Golem item ID")
    equal(arcaneGolem.waypoint[1], 2635, "Delver's Arcane Golem map")
    equal(arcaneGolem.waypoint[2], 0.6043, "Delver's Arcane Golem x")
    equal(arcaneGolem.waypoint[3], 0.6811, "Delver's Arcane Golem y")
    equal(arcaneGolem.availableAfter, nil,
        "ordinary 12.1 delve chest must not be Season 2 gated")

    equal(#entries("pets") - patch120007Counts.pets, 29, "12.1 pet count")
    assertIDs("pets", "speciesID", {
        5035, 5031, 5029, 5030, 5032, 5028, 5033, 5034, 5071, 5072, 5070,
        5093, 5078, 5076, 5137, 5092, 5125, 5011, 5134, 5133, 5131, 5132,
        5130, 5129, 3526, 5126, 5164, 5026, 5027,
    }, "12.1 pet")

    equal(#entries("toys") - patch120007Counts.toys, 19, "12.1 toy count")
    assertIDs("toys", "itemID", {
        276925, 280419, 280201, 275988, 279054, 274921, 279021,
        277954, 268504, 279052, 276189, 276229, 276258, 267472,
        275825, 276207, 274817, 278557, 275683,
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
    equal(futureCounts.pets, 3, "Season 2 pet gate count")
    equal(futureCounts.toys or 0, 1, "Season 2 toy gate count")
    equal(futureCounts.decorations, 14, "Season 2 decoration gate count")
    equal(futureCounts.achievements, 83, "Season 2 achievement gate count")
    equal(futureTotal, 110, "all Season 2 gated catalog rows")

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
