local _, MC = ...

-- HAND-MAINTAINED. Edit this file directly.
--
-- One-time extraction from the Trading Post inventory. Out-of-game
-- origins (Shop, TCG, Recruit-a-Friend) are excluded by standing policy.
--
-- Frozen from its generator, which has been deleted. The upstream it read is a
-- one-time research artifact, not a live feed -- re-running it could only
-- reproduce the same rows or clobber corrections made since. One such
-- correction is already in history: a generator re-run would have restored
-- petType = 0 on eight Trading Post pets.
--
-- Validated by scripts/db/run.sh, which loads this into the content database
-- and fails on any constraint violation.
--
-- Trading Post mounts. Bought with Trader's Tender in game and rotated back
-- into the shop over time, so they are tracked like anything else earnable.
-- Expansion is the one whose Trading Post first offered the item, not the
-- expansion its model or original promotion came from.
--
-- 8 whose original source was a TCG code, the in-game Shop, Recruit-a-Friend
-- or a promotion are deliberately NOT listed here, pending review.

MC.RegisterContent("df", "mounts", {
    { source = "tradingpost", mounts = {
        { mountID = 125, name = "Riding Turtle", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.7", zone = "Dornogal", itemID = 23720, waypoint = { 2339, 0.4807, 0.5216, "Riding Turtle" } },
        { mountID = 371, name = "Blazing Hippogryph", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.6", zone = "Dornogal", itemID = 54069, waypoint = { 2339, 0.4807, 0.5216, "Blazing Hippogryph" } },
        { mountID = 376, name = "Celestial Steed", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.0.5", itemID = 54811 },
        { mountID = 382, name = "X-53 Touring Rocket", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.5", zone = "Dornogal", itemID = 54860, waypoint = { 2339, 0.4807, 0.5216, "X-53 Touring Rocket" } },
        { mountID = 439, name = "Tyrael's Charger", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.1.5", itemID = 76755 },
        { mountID = 646, name = "Coldflame Infernal", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.1.7", itemID = 137576 },
        { mountID = 1266, name = "Alabaster Stormtalon", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.1.5", itemID = 207964 },
        { mountID = 1267, name = "Alabaster Thunderwing", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.1.5", itemID = 207963 },
        { mountID = 1468, name = "Amber Skitterfly", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.6", zone = "Dornogal", itemID = 192766, waypoint = { 2339, 0.4807, 0.5216, "Amber Skitterfly" } },
        { mountID = 1573, name = "Magenta Cloud Serpent", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.0.5", zone = "Dornogal", itemID = 189978, waypoint = { 2339, 0.4807, 0.5216, "Magenta Cloud Serpent" } },
        { mountID = 1574, name = "Crusty Crawler", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.1.7", itemID = 190168 },
        { mountID = 1575, name = "Quawks", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.1.0", zone = "Dornogal", itemID = 190169, waypoint = { 2339, 0.4816, 0.5199, "Quawks" } },
        { mountID = 1577, name = "Ash'adar, Harbinger of Dawn", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.0.5", zone = "Dornogal", itemID = 190231, waypoint = { 2339, 0.4816, 0.5199, "Ash'adar, Harbinger of Dawn" } },
        { mountID = 1582, name = "Savage Green Battle Turtle", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.1.0", itemID = 190613 },
        { mountID = 1586, name = "Armored Golden Pterrordax", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.0", zone = "Dornogal", itemID = 190767, waypoint = { 2339, 0.4807, 0.5216, "Armored Golden Pterrordax" } },
        { mountID = 1742, name = "Felcrystal Scorpion", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.1.5", zone = "Dornogal", itemID = 206027, waypoint = { 2339, 0.4807, 0.5216, "Felcrystal Scorpion" } },
        { mountID = 1784, name = "Royal Swarmer", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.1.0", zone = "Dornogal", itemID = 206976, waypoint = { 2339, 0.4807, 0.5216, "Royal Swarmer" } },
        { mountID = 1785, name = "Ancestral Clefthoof", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.1.5", zone = "Dornogal", itemID = 207821, waypoint = { 2339, 0.4807, 0.5216, "Ancestral Clefthoof" } },
        { mountID = 1799, name = "Eve's Ghastly Rider", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.1.7", itemID = 208598 },
        { mountID = 1841, name = "Crimson Glimmerfur", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.0", zone = "Dornogal", itemID = 210919, waypoint = { 2339, 0.4807, 0.5216, "Crimson Glimmerfur" } },
        { mountID = 1942, name = "Jeweled Copper Scarab", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.0", zone = "Dornogal", itemID = 211074, waypoint = { 2339, 0.4807, 0.5216, "Jeweled Copper Scarab" } },
        { mountID = 1956, name = "Fur-endship Fox", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.5", zone = "Dornogal", itemID = 212227, waypoint = { 2339, 0.4807, 0.5216, "Fur-endship Fox" } },
        { mountID = 2035, name = "Majestic Azure Peafowl", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.5", zone = "Dornogal", itemID = 212630, waypoint = { 2339, 0.4807, 0.5216, "Majestic Azure Peafowl" } },
        { mountID = 2039, name = "Savage Blue Battle Turtle", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.6", zone = "Dornogal", itemID = 212920, waypoint = { 2339, 0.4807, 0.5216, "Savage Blue Battle Turtle" } },
        { mountID = 2152, name = "Pearlescent Goblin Wave Shredder", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.7", zone = "Dornogal", itemID = 221814, waypoint = { 2339, 0.4807, 0.5216, "Pearlescent Goblin Wave Shredder" } },
        { mountID = 2189, name = "Underlight Corrupted Behemoth", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.7", zone = "Dornogal", itemID = 223285, waypoint = { 2339, 0.4807, 0.5216, "Underlight Corrupted Behemoth" } },
    } },
})

MC.RegisterContent("midnight", "mounts", {
    { source = "tradingpost", mounts = {
        { mountID = 2825, name = "Cloudborn Razorwing", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r12.0.0", itemID = 260580 },
        { mountID = 2833, name = "Arboreal Pseudoshell", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r12.0.1", itemID = 260893 },
        { mountID = 2845, name = "Vicious Snapvine", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r12.0.1", itemID = 262705 },
        { mountID = 2852, name = "Comfy Bel'ameth Flying Quilt", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r12.0.1", itemID = 263451 },
        { mountID = 2853, name = "Comfy Silvermoon Flying Quilt", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r12.0.1", itemID = 263452 },
        { mountID = 2928, name = "Pyrewood Rebel's Rouncey", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r12.0.5", itemID = 268363 },
        { mountID = 2929, name = "Gilneas Loyalist's Rouncey", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r12.0.5", itemID = 268364 },
        { mountID = 2940, name = "Dusk-Painted Sun Roc", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r12.0.5", itemID = 268877 },
        { mountID = 2941, name = "Flame-Painted Sun Roc", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r12.0.5", itemID = 268876 },
        { mountID = 2973, name = "Blackwater X-TREME Firework Rocket", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r12.0.7", itemID = 273317 },
        { mountID = 2975, name = "Bilgewater X-TREME Firework Rocket", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r12.0.7", itemID = 273651 },
        { mountID = 2994, name = "Badlands Buzzard", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r12.0.7", itemID = 274681 },
    } },
})

MC.RegisterContent("tww", "mounts", {
    { source = "tradingpost", mounts = {
        { mountID = 1550, name = "Depthstalker", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.0.2", zone = "Dornogal", itemID = 187674, waypoint = { 2339, 0.4816, 0.5199, "Depthstalker" } },
        { mountID = 1824, name = "Brown-Furred Spiky Bakar", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.5", itemID = 210141 },
        { mountID = 1945, name = "Jeweled Sapphire Scarab", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.2.5", itemID = 211085 },
        { mountID = 1958, name = "Twilight Sky Prowler", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.0.5", zone = "Dornogal", itemID = 212229, waypoint = { 2339, 0.4807, 0.5216, "Twilight Sky Prowler" } },
        { mountID = 2036, name = "Brilliant Sunburst Peafowl", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.0.7", itemID = 212631 },
        { mountID = 2198, name = "Kor'kron Warsaber", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.0.0", zone = "Dornogal", itemID = 223449, waypoint = { 2339, 0.4807, 0.5216, "Kor'kron Warsaber" } },
        { mountID = 2201, name = "Sentinel War Wolf", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.0.0", zone = "Dornogal", itemID = 223469, waypoint = { 2339, 0.4807, 0.5216, "Sentinel War Wolf" } },
        { mountID = 2238, name = "Plunderlord's Golden Crocolisk", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.0.2", zone = "Dornogal", itemID = 226040, waypoint = { 2339, 0.4816, 0.5199, "Plunderlord's Golden Crocolisk" } },
        { mountID = 2239, name = "Keg Leg's Radiant Crocolisk", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.0.2", zone = "Dornogal", itemID = 226041, waypoint = { 2339, 0.4807, 0.5216, "Keg Leg's Radiant Crocolisk" } },
        { mountID = 2249, name = "Hand of Reshkigaal", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.0.2", zone = "Dornogal", itemID = 226506, waypoint = { 2339, 0.4807, 0.5216, "Hand of Reshkigaal" } },
        { mountID = 2329, name = "Silvermoon Sweeper", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.0.7", itemID = 233023 },
        { mountID = 2347, name = "Savage Alabaster Battle Turtle", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.0.7", itemID = 233354 },
        { mountID = 2482, name = "Lively Darkmoon Charger", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.0", itemID = 235555 },
        { mountID = 2483, name = "Violet Darkmoon Charger", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.0", itemID = 235556 },
        { mountID = 2488, name = "Shimmermist Free Runner", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.0", itemID = 235646 },
        { mountID = 2489, name = "Pearlescent Butterfly", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.0", itemID = 235650 },
        { mountID = 2491, name = "Ruby Butterfly", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.0", itemID = 235657 },
        { mountID = 2495, name = "Emerald Snail", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.0", itemID = 235662 },
        { mountID = 2504, name = "Spotted Black Riding Goat", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.5", itemID = 236415 },
        { mountID = 2520, name = "Spring Harvesthog", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.5", itemID = 238897 },
        { mountID = 2524, name = "Coldflame Cormaera", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.5", itemID = 238941 },
        { mountID = 2527, name = "Molten Cormaera", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.5", itemID = 238967 },
        { mountID = 2575, name = "Grandmaster's Prophetic Board", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.7", itemID = 243572 },
        { mountID = 2577, name = "Grandmaster's Royal Board", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.7", itemID = 243591 },
        { mountID = 2579, name = "Forsaken's Grotesque Charger", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.7", itemID = 243594 },
        { mountID = 2580, name = "Wailing Banshee's Charger", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.7", itemID = 243596 },
        { mountID = 2600, name = "Unarmored Deathtusk Felboar", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.1.7", itemID = 245936 },
        { mountID = 2621, name = "Legion-Forged Elekk", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.2.0", itemID = 246921 },
        { mountID = 2625, name = "The Headless Horseman's Hallowed Charger", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.2.0", itemID = 247723 },
        { mountID = 2627, name = "High Shaman's Aerie Gryphon", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.2.0", itemID = 247792 },
        { mountID = 2628, name = "Cinder-Plumed Highland Gryphon", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.2.0", itemID = 247793 },
        { mountID = 2630, name = "Ornery Breezestrider", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.2.0", itemID = 247795 },
        { mountID = 2645, name = "Kalu'ak Crest-Horn", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.2.5", itemID = 248994 },
        { mountID = 2696, name = "Highlands Gobbler", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.2.5", itemID = 250926 },
        { mountID = 2699, name = "Prized Turkey", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.2.5", itemID = 250929 },
        { mountID = 2823, name = "Savage Crimson Battle Turtle", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.2.7", itemID = 260409 },
    } },
})

