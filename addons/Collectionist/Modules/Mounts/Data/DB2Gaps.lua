local _, MC = ...

-- Current DB2 collectible gaps confirmed by source audit.
-- Generated from the exact 18-row include set.

MC.RegisterContent("wrath", "mounts", {
    { source = "vendor", mounts = {
        { mountID = 552, name = "Ironbound Wraithcharger", source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rAuzin|n|cFFFFD200Zone: |rDalaran|n|cFFFFD200Cost: |r5000|Hcurrency:1166|h|TInterface\\ICONS\\PVECurrency-Justice.blp:0|t|h" },
    } },
})

MC.RegisterContent("mop", "mounts", {
    { source = "vendor", mounts = {
        { mountID = 462, name = "Kafa Yak", source = "vendor", sourceInfo = "|cFFFFD200World Event:|r WoW Remix: Mists of Pandaria", unavailable = true },
        { mountID = 484, name = "Black Riding Yak", source = "vendor", sourceInfo = "|cFFFFD200World Event:|r WoW Remix: Mists of Pandaria", unavailable = true },
        { mountID = 485, name = "Modest Expedition Yak", source = "vendor", sourceInfo = "|cFFFFD200World Event:|r WoW Remix: Mists of Pandaria", unavailable = true },
        { mountID = 488, name = "Crimson Water Strider", source = "vendor", sourceInfo = "|cFFFFD200Vendor: |rNat Pagle|n|cFFFFD200Zone: |rGarrison: Fishing Shack|n|cFFFFD200Faction: |rNat Pagle - Honored|n|cFFFFD200Cost: |r100|Hitem:117397|h|TINTERFACE\\ICONS\\INV_Misc_Coin_19.blp:0|t|h" },
    } },
})

MC.RegisterContent("wod", "mounts", {
    { source = "achievement", mounts = {
        { mountID = 416, name = "Felfire Hawk", source = "achievement", sourceInfo = "|cFFFFD200Achievement:|r Mountacular|n|n" },
    } },
})

MC.RegisterContent("legion", "mounts", {
    { source = "drop", mounts = {
        { mountID = 633, name = "Hellfire Infernal", source = "drop", sourceInfo = "|cFFFFD200Drop:|r Gul'dan (Mythic)|n|cFFFFD200Zone:|r The Nighthold", waypoint = { 680, 0.4330, 0.6230, "Hellfire Infernal" } },
    } },
})

MC.RegisterContent("shadowlands", "mounts", {
    { source = "drop", mounts = {
        { mountID = 1374, name = "Bonecleaver's Skullboar", source = "drop", sourceInfo = "|cFFFFD200Vendor:|r Collector Ta'Steld|n|cFFFFD200Zone:|r Oribos|n|cFFFFD200Cost: |r5000|Hcurrency:1166|h|TInterface\\ICONS\\PVECurrency-Justice.blp:0|t|h|n|n" },
    } },
})

MC.RegisterContent("midnight", "mounts", {
    { source = "achievement", mounts = {
        { mountID = 2917, name = "Anu'shalla, Shadow's Guidance", source = "achievement", sourceInfo = "|cFFFFD200Achievement: |rInsurmountable Collection|n|cFFFFD200Category: |rMounts" },
    } },
    -- Love is in the Air, not a rare drop. Filing it under "drop" put it in
    -- the zone sub-grouping that source gets, and with no zone to group by it
    -- landed under an "Unknown" header.
    { source = "worldevent", mounts = {
        { mountID = 2492, name = "Spring Butterfly", source = "worldevent", sourceInfo = "|cFFFFD200World Event:|r Love is in the Air|n|cFFFFD200Drop:|r Apothecary Hummel" },
    } },
    { source = "quest", mounts = {
        { mountID = 2754, name = "Peridot Dragonhawk", source = "quest", sourceInfo = "|cFFFFD200World Quest: |rFrom Darkness, Light|n|cFFFFD200Zone: |rIsle of Quel'Danas", zone = "Isle of Quel'Danas", waypoint = { 2424, 0.5260, 0.4610, "Peridot Dragonhawk" } },
        { mountID = 2818, name = "Emerald Hawkstrider", source = "quest", sourceInfo = "|cFFFFD200Quest: |rThe Battle of the Bridge|n|cFFFFD200Zone: |rSilvermoon City|n|n", zone = "Silvermoon City", waypoint = { 2393, 0.4590, 0.7030, "Emerald Hawkstrider" } },
    } },
    { source = "vendor", mounts = {
        { mountID = 3005, name = "Cerulean Deathwalker", source = "vendor", sourceInfo = "|cFFFFD200Vendor:|r Lindormi|n", zone = "Silvermoon City", waypoint = { 2393, 0.4210, 0.5880, "Cerulean Deathwalker" } },
        { mountID = 3006, name = "Amethyst Mechsuit", source = "vendor", sourceInfo = "|cFFFFD200Vendor:|r Lindormi|n", zone = "Silvermoon City", waypoint = { 2393, 0.4210, 0.5880, "Amethyst Mechsuit" } },
        { mountID = 3007, name = "Blue-Chip Shreddertank", source = "vendor", sourceInfo = "|cFFFFD200Vendor:|r Lindormi|n", zone = "Silvermoon City", waypoint = { 2393, 0.4210, 0.5880, "Blue-Chip Shreddertank" } },
        { mountID = 3008, name = "Profit-Green Shreddertank", source = "vendor", sourceInfo = "|cFFFFD200Vendor:|r Lindormi|n", zone = "Silvermoon City", waypoint = { 2393, 0.4210, 0.5880, "Profit-Green Shreddertank" } },
        { mountID = 3009, name = "Speculative Shreddertank", source = "vendor", sourceInfo = "|cFFFFD200Vendor:|r Lindormi|n", zone = "Silvermoon City", waypoint = { 2393, 0.4210, 0.5880, "Speculative Shreddertank" } },
        { mountID = 3010, name = "High-Yield Shreddertank", source = "vendor", sourceInfo = "|cFFFFD200Vendor:|r Lindormi|n", zone = "Silvermoon City", waypoint = { 2393, 0.4210, 0.5880, "High-Yield Shreddertank" } },
    } },
})
