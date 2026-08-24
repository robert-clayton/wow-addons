local _, MC = ...

-- Classic toys. Generated from the exact 10-row release manifest.
MC.RegisterContent("vanilla", "toys", {
    { source = "drop", toys = {
        { itemID = 1973, name = "Orb of Deception", source = "drop", sourceInfo = "|cFFFFD200Drop: |rWorld Drop" },
        { itemID = 13379, name = "Piccolo of the Flaming Fire", source = "drop", sourceInfo = "|cFFFFD200Drop: |rHearthsinger Forresten|n|cFFFFD200Zone: |rStratholme" },
        { itemID = 141331, name = "Vial of Green Goo", source = "drop", sourceInfo = "|cFFFFD200Drop:|r Endgineer Omegaplugg|n" },
        { itemID = 208096, name = "Familiar Journal", source = "drop", sourceInfo = "|cFFFFD200Discovery:|r Naxxramas|n" },
    } },
    { source = "quest", toys = {
        { itemID = 21540, name = "Elune's Lantern", source = "quest", sourceInfo = "|cFFFFD200Quest: |rElune's Blessing|n|cFFFFD200Zone: |rMoonglade", zone = "Moonglade", waypoint = { 80, 0.5360, 0.3530, "Elune's Lantern" } },
    } },
    { source = "profession", toys = {
        { itemID = 17716, name = "Snowmaster 9000", source = "profession", sourceInfo = "|cFFFFD200Profession: |rEngineering" },
        { itemID = 18660, name = "World Enlarger", source = "profession", sourceInfo = "|cFFFFD200Profession: |rEngineering" },
        { itemID = 18986, name = "Ultrasafe Transporter: Gadgetzan", source = "profession", sourceInfo = "|cFFFFD200Profession: |rEngineering" },
        { itemID = 18984, name = "Dimensional Ripper - Everlook", source = "profession", sourceInfo = "|cFFFFD200Profession: |rEngineering" },
    } },
    { source = "worldevent", toys = {
        { itemID = 17712, name = "Winter Veil Disguise Kit", source = "worldevent", sourceInfo = "|cFFFFD200World Event: |rFeast of Winter Veil" },
    } },
})
