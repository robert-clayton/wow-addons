local addonName, MC = ...

-- Battle for Azeroth treasures and hidden-object collections. Exact 98 ordered criteria rows.
MC.RegisterContent("bfa", "treasures", {
    { source = "tiragarde_sound", achievementID = 12852, criteriaCount = 10,
      criteriaTreeIDs = { 67943, 67944, 67945, 67946, 67947, 67948, 67949, 67950, 67951, 67952 },
      criteriaNames = { "Hay Covered Chest", "Cutwater Treasure Chest", "Precarious Noble Cache", "Forgotten Smuggler's Stash", "Scrimshaw Cache", "Secret of the Depths", "Soggy Treasure Map", "Faded Treasure Map", "Yellowed Treasure Map", "Singed Treasure Map" }, name = "Treasures of Tiragarde Sound",
      zoneMapID = MC.MAP.TiragardeSound, zone = "Tiragarde Sound" },
    { source = "stormsong_valley", achievementID = 12853, criteriaCount = 10,
      criteriaTreeIDs = { 68003, 68004, 68005, 68006, 68007, 68008, 68009, 68010, 68011, 68012 },
      criteriaNames = { "Weathered Treasure Chest", "Old Ironbound Chest", "Frosty Treasure Chest", "Sunken Strongbox", "Hidden Scholar's Chest", "Smuggler's Stash", "Discarded Lunchbox", "Carved Wooden Chest", "Venture Co. Supply Chest", "Forgotten Chest" }, name = "Treasures of Stormsong Valley",
      zoneMapID = MC.MAP.StormsongValley, zone = "Stormsong Valley" },
    { source = "drustvar", achievementID = 12995, criteriaCount = 10,
      criteriaTreeIDs = { 69017, 69018, 69019, 69020, 69021, 69022, 69023, 69024, 69025, 69077 },
      criteriaNames = { "Web-Covered Chest", "Merchant's Chest", "Runebound Cache", "Runebound Chest", "Runebound Coffer", "Hexed Chest", "Bespelled Chest", "Ensorcelled Chest", "Enchanted Chest", "Stolen Thornspeaker Cache" }, name = "Treasures of Drustvar",
      zoneMapID = MC.MAP.Drustvar, zone = "Drustvar" },
    { source = "nazmir", achievementID = 12771, criteriaCount = 10,
      criteriaTreeIDs = { 67644, 67645, 67646, 67647, 67648, 67649, 67650, 67651, 67652, 67653 },
      criteriaNames = { "Lucky Horace's Lucky Chest", "Partially-Digested Treasure", "Cursed Nazmani Chest", "Cleverly Disguised Chest", "Lost Nazmani Treasure", "Offering to Bwonsamdi", "Shipwrecked Chest", "Venomous Seal", "Swallowed Naga Chest", "Wunja's Trove" }, name = "Treasures of Nazmir",
      zoneMapID = MC.MAP.Nazmir, zone = "Nazmir" },
    { source = "voldun", achievementID = 12849, criteriaCount = 10,
      criteriaTreeIDs = { 67873, 67874, 67875, 67876, 67877, 67878, 67879, 67913, 67914, 67915 },
      criteriaNames = { "Ashvane Spoils", "Grayal's Last Offering", "Lost Explorer's Bounty", "Sandfury Reserve", "Stranded Cache", "Excavator's Greed", "Zem'lan's Buried Treasure", "Lost Offerings of Kimbul", "Deadwood Chest", "Sandsunken Treasure" }, name = "Treasures of Vol'dun",
      zoneMapID = MC.MAP.Voldun, zone = "Vol'dun" },
    { source = "zuldazar", achievementID = 12851, criteriaCount = 10,
      criteriaTreeIDs = { 67899, 67900, 67901, 67902, 67903, 67904, 67905, 67906, 67907, 67908 },
      criteriaNames = { "Offerings of the Chosen", "Witch Doctor's Hoard", "Spoils of Pandaria", "Gift of the Brokenhearted", "Warlord's Cache", "Dazar's Forgotten Chest", "Da White Shark's Bounty", "The Exile's Lament", "Cache of Secrets", "Riches of Tor'nowa" }, name = "Treasures of Zuldazar",
      zoneMapID = MC.MAP.Zuldazar, zone = "Zuldazar" },
    { source = "nazjatar", achievementID = 13549, criteriaCount = 28,
      criteriaTreeIDs = { 79930, 79931, 79932, 79933, 79934, 79935, 79936, 79937, 79938, 79939, 79940, 79941, 79942, 79943, 79944, 79945, 79946, 79947, 79948, 79949, 79951, 79952, 79953, 79954, 79955, 79956, 81025, 81568 },
      criteriaNames = { "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" }, name = "Trove Tracker",
      zoneMapID = MC.MAP.Nazjatar, zone = "Nazjatar" },
    { source = "nazjatar", achievementID = 13836, criteriaCount = 10,
      criteriaTreeIDs = { 81477, 81478, 81479, 81480, 81481, 81482, 81483, 81484, 81485, 81486 },
      criteriaNames = { "Figurine Found", "Figurine Found", "Figurine Found", "Figurine Found", "Figurine Found", "Figurine Found", "Figurine Found", "Figurine Found", "Figurine Found", "Figurine Found" }, name = "Feline Figurines Found",
      zoneMapID = MC.MAP.Nazjatar, zone = "Nazjatar" },
})

local SOURCE_KEYS = {
    { "tiragarde", "Tiragarde Sound" },
    { "stormsong", "Stormsong Valley" },
    { "drustvar", "Drustvar" },
    { "nazmir", "Nazmir" },
    { "voldun", "Vol'dun" },
    { "zuldazar", "Zuldazar" },
    { "nazjatar", "Nazjatar" },
}
local function merge()
    MC.TreasureSourceOrder = MC.TreasureSourceOrder or {}
    MC.TreasureSourceLabels = MC.TreasureSourceLabels or {}
    local have = {}
    for _, key in ipairs(MC.TreasureSourceOrder) do have[key] = true end
    -- The base file already declares every key it owns. Inserting a
    -- second copy put the zone in the order list twice, which draws
    -- its group twice and prints it twice in the /mc summary.
    local at = 0
    for _, pair in ipairs(SOURCE_KEYS) do
        MC.TreasureSourceLabels[pair[1]] = pair[2]
        if not have[pair[1]] then
            at = at + 1
            have[pair[1]] = true
            table.insert(MC.TreasureSourceOrder, at, pair[1])
        end
    end
end
if MC.TreasureSourceOrder then merge() else
    local frame = CreateFrame("Frame"); frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, _, name) if name ~= addonName then return end; self:UnregisterEvent("ADDON_LOADED"); self:SetScript("OnEvent", nil); merge() end)
end
