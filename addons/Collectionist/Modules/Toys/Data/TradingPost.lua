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
-- Trading Post toys. Bought with Trader's Tender in game and rotated back
-- into the shop over time, so they are tracked like anything else earnable.
-- Expansion is the one whose Trading Post first offered the item, not the
-- expansion its model or original promotion came from.

MC.RegisterContent("df", "toys", {
    { source = "tradingpost", toys = {
        { itemID = 206268, name = "Ethereal Transmogrifier", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.1.5", zone = "Dornogal" },
        { itemID = 206347, name = "Mannequin Charm", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.5", zone = "Dornogal" },
        { itemID = 212500, name = "Delicate Silk Parasol", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.6", zone = "Dornogal" },
        { itemID = 212523, name = "Delicate Jade Parasol", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.5", zone = "Dornogal" },
        { itemID = 212524, name = "Delicate Crimson Parasol", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.7", zone = "Dornogal" },
        { itemID = 218112, name = "Colorful Beach Chair", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.7", zone = "Dornogal" },
        { itemID = 220692, name = "X-treme Water Blaster Display", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r10.2.7", zone = "Dornogal" },
    } },
})

MC.RegisterContent("tww", "toys", {
    { source = "tradingpost", toys = {
        { itemID = 112324, name = "Nightmarish Hitching Post", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.0.7" },
        { itemID = 212525, name = "Delicate Ebony Parasol", source = "tradingpost", sourceInfo = "|cFFFFD200Trading Post|r|n|cFFFFD200First offered: |r11.0.2", zone = "Dornogal" },
    } },
})

