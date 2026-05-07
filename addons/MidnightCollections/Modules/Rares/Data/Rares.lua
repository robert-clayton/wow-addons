local _, MC = ...

MC.RareSourceOrder = { "eversong", "zulaman", "harandar", "voidstorm" }
MC.RareSourceLabels = {
    eversong  = "Eversong Woods",
    zulaman   = "Zul'Aman",
    harandar  = "Harandar",
    voidstorm = "Voidstorm",
}

-- Each entry is one zone-rare achievement. The Scanner pulls the rare list
-- and completion state directly from the achievement's criteria at scan time,
-- so we don't need to hardcode every rare's name.
MC.RareData = {
    { source = "eversong",  achievementID = 61507, name = "A Bloody Song",
      zoneMapID = MC.MAP.Eversong, zone = "Eversong Woods" },
    { source = "zulaman",   achievementID = 62122, name = "Tallest Tree in the Forest",
      zoneMapID = MC.MAP.ZulAman, zone = "Zul'Aman" },
    { source = "harandar",  achievementID = 61264, name = "Leaf None Behind",
      zoneMapID = MC.MAP.Harandar, zone = "Harandar" },
    { source = "voidstorm", achievementID = 62130, name = "The Ultimate Predator",
      zoneMapID = MC.MAP.Voidstorm, zone = "Voidstorm" },
}

-- npcID -> { mapID, x, y, "Name" }
-- Coords sourced from HandyNotes_Midnight (May 2026).
-- The Scanner also auto-builds a name-keyed mirror (MC.RareCoords) below
-- so it can fall back to name lookup when the achievement criterion's
-- assetID doesn't match HandyNotes' npcID (e.g. legacy NPC reuses).
MC.RareNPCs = {
    -- Eversong Woods (15)
    [246332] = { MC.MAP.Eversong, 0.5192, 0.7380, "Warden of Weeds" },
    [246633] = { MC.MAP.Eversong, 0.4505, 0.7825, "Harried Hawkstrider" },
    [240129] = { MC.MAP.Eversong, 0.5470, 0.6018, "Overfester Hydra" },
    [250582] = { MC.MAP.Eversong, 0.3770, 0.6420, "Bloated Snapdragon" },
    [250719] = { MC.MAP.Eversong, 0.6274, 0.4907, "Cre'van" },
    [250683] = { MC.MAP.Eversong, 0.3638, 0.3637, "Coralfang" },
    [250754] = { MC.MAP.Eversong, 0.3665, 0.7718, "Lady Liminus" },
    [250876] = { MC.MAP.Eversong, 0.4019, 0.8539, "Terrinor" },
    [250841] = { MC.MAP.Eversong, 0.4905, 0.8775, "Bad Zed" },
    [250780] = { MC.MAP.Eversong, 0.3481, 0.2098, "Waverly" },
    [250826] = { MC.MAP.Eversong, 0.5642, 0.7760, "Banuran" },
    [250806] = { MC.MAP.Eversong, 0.5920, 0.7920, "Lost Guardian" },
    [255302] = { MC.MAP.Eversong, 0.4231, 0.6891, "Duskburn" },
    [255329] = { MC.MAP.Eversong, 0.5168, 0.4599, "Malfunctioning Construct" },
    [255348] = { MC.MAP.Eversong, 0.4499, 0.3855, "Dame Bloodshed" },
    -- Zul'Aman (15)
    [242023] = { MC.MAP.ZulAman, 0.3441, 0.3305, "Necrohexxer Raz'ka" },
    [242024] = { MC.MAP.ZulAman, 0.5180, 0.1862, "The Snapping Scourge" },
    [242025] = { MC.MAP.ZulAman, 0.5185, 0.7291, "Skullcrusher Harak" },
    [242028] = { MC.MAP.ZulAman, 0.2895, 0.2444, "Lightwood Borer" },
    [245975] = { MC.MAP.ZulAman, 0.5087, 0.6514, "Mrrlokk" },
    [247976] = { MC.MAP.ZulAman, 0.3899, 0.4997, "Poacher Rav'ik" },
    [242031] = { MC.MAP.ZulAman, 0.3048, 0.4456, "Spinefrill" },
    [242032] = { MC.MAP.ZulAman, 0.4629, 0.5113, "Oophaga" },
    [242033] = { MC.MAP.ZulAman, 0.4777, 0.3422, "Tiny Vermin" },
    [242034] = { MC.MAP.ZulAman, 0.2130, 0.7055, "Voidtouched Crustacean" },
    [242035] = { MC.MAP.ZulAman, 0.3959, 0.2097, "The Devouring Invader" },
    [242026] = { MC.MAP.ZulAman, 0.3371, 0.8897, "Elder Oaktalon" },
    [242027] = { MC.MAP.ZulAman, 0.4768, 0.2056, "Depthborn Eelamental" },
    [245691] = { MC.MAP.ZulAman, 0.4639, 0.4339, "The Decaying Diamondback" },
    [245692] = { MC.MAP.ZulAman, 0.4529, 0.4170, "Asha the Empowered" },
    -- Harandar (15)
    [248741] = { MC.MAP.Harandar, 0.5116, 0.4535, "Rhazul" },
    [249844] = { MC.MAP.Harandar, 0.6871, 0.4070, "Chironex" },
    [249849] = { MC.MAP.Harandar, 0.6917, 0.5986, "Ha'kalawe" },
    [249902] = { MC.MAP.Harandar, 0.7263, 0.6928, "Tallcap the Truthspreader" },
    [249962] = { MC.MAP.Harandar, 0.5993, 0.4684, "Queen Lashtongue" },
    [249997] = { MC.MAP.Harandar, 0.6457, 0.4794, "Chlorokyll" },
    [250086] = { MC.MAP.Harandar, 0.6555, 0.3269, "Stumpy" },
    [250180] = { MC.MAP.Harandar, 0.5638, 0.3299, "Serrasa" },
    [250226] = { MC.MAP.Harandar, 0.4593, 0.3134, "Mindrot" },
    [250231] = { MC.MAP.Harandar, 0.4065, 0.4299, "Dracaena" },
    [250246] = { MC.MAP.Harandar, 0.3659, 0.7516, "Treetop" },
    [250317] = { MC.MAP.Harandar, 0.2811, 0.8181, "Oro'ohna" },
    [250321] = { MC.MAP.Harandar, 0.2727, 0.7032, "Pterrock" },
    [250347] = { MC.MAP.Harandar, 0.3969, 0.6070, "Ahl'ua'huhi" },
    [250358] = { MC.MAP.Harandar, 0.4420, 0.1658, "Annulus the Worldshaker" },
    -- Voidstorm (14, two on the Slayer's Rise sub-map)
    [244272] = { MC.MAP.Voidstorm,   0.2951, 0.5008, "Sundereth the Caller" },
    [238498] = { MC.MAP.Voidstorm,   0.3405, 0.8198, "Territorial Voidscythe" },
    [241443] = { MC.MAP.Voidstorm,   0.3616, 0.8355, "Tremora" },
    [256922] = { MC.MAP.Voidstorm,   0.4366, 0.5154, "Screammaxa the Matriarch" },
    [256923] = { MC.MAP.Voidstorm,   0.4705, 0.8063, "Bane of the Vilebloods" },
    [256924] = { MC.MAP.Voidstorm,   0.3923, 0.6392, "Aeonelle Blackstar" },
    [256925] = { MC.MAP.Voidstorm,   0.3789, 0.7177, "Lotus Darkblossom" },
    [256926] = { MC.MAP.Voidstorm,   0.5572, 0.7945, "Queen o' War" },
    [256808] = { MC.MAP.Voidstorm,   0.4881, 0.5326, "Ravengerus" },
    [257027] = { MC.MAP.SlayersRise, 0.4633, 0.4094, "Rakshur the Bonegrinder" },
    [256770] = { MC.MAP.Voidstorm,   0.3549, 0.5023, "Bilemaw the Gluttonous" },
    [245182] = { MC.MAP.SlayersRise, 0.4088, 0.8899, "Eruundi" },
    [245044] = { MC.MAP.Voidstorm,   0.4017, 0.4130, "Nightbrood" },
    [256821] = { MC.MAP.Voidstorm,   0.5394, 0.6272, "Far'thana the Mad" },
}

-- name-keyed mirror, used by the Scanner when the criterion's assetID
-- doesn't match HandyNotes' npcID (legacy NPCs reused for new criteria etc.)
MC.RareCoords = {}
for _, coords in pairs(MC.RareNPCs) do
    local nm = coords[4]
    if nm then MC.RareCoords[nm] = coords end
end

-- Aliases for spelling drift between HandyNotes and the achievement criterion.
-- Add new entries as players spot rares with `waypoint: none` in the ctrl-click
-- output: the key is the criterion's name, the value is the HandyNotes name.
local NAME_ALIASES = {
    ["Mrrlok"] = "Mrrlokk",
}
for criterion, handyName in pairs(NAME_ALIASES) do
    MC.RareCoords[criterion] = MC.RareCoords[handyName]
end
