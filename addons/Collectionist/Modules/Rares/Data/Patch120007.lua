local _, MC = ...

-- Patch 12.0.7 rotating Showdown worlds.  Criterion order is the live
-- achievement order; keeping the NPC IDs stable also makes roster bitmaps
-- locale-independent.
MC.RegisterContent("midnight", "rares", {
    { source = "val", achievementID = 62881, criteriaCount = 10,
      criteriaNPCIDs = {
          261965, 262421, 261716, 264865, 264864,
          264866, 264868, 264869, 264870, 265269,
      },
      name = "Showdown Slugger: Val", zoneMapID = MC.MAP.Val, zone = "Val" },
    { source = "naigtal", achievementID = 62883, criteriaCount = 10,
      criteriaNPCIDs = {
          263947, 263950, 263954, 263955, 264569,
          264574, 264571, 264576, 267422, 265698,
      },
      name = "Showdown Slugger: Naigtal", zoneMapID = MC.MAP.Naigtal, zone = "Naigtal" },
})

local added = {
    -- Val
    [261965] = { MC.MAP.Val, 0.552, 0.656, "Sleet-Rune" },
    [262421] = { MC.MAP.Val, 0.382, 0.794, "Atomus" },
    [261716] = { MC.MAP.Val, 0.672, 0.424, "Glacial Broodmother" },
    [264865] = { MC.MAP.Val, 0.497, 0.792, "Mercilus" },
    [264864] = { MC.MAP.Val, 0.286, 0.746, "Xirah" },
    [264866] = { MC.MAP.Val, 0.446, 0.528, "Krilkan" },
    [264868] = { MC.MAP.Val, 0.330, 0.430, "Opprimius" },
    [264869] = { MC.MAP.Val, 0.232, 0.419, "Nelgothar" },
    [264870] = { MC.MAP.Val, 0.355, 0.576, "The Horror Below" },
    [265269] = { MC.MAP.Val, 0.460, 0.646, "Shadowguard Destroyer" },
    -- Naigtal
    [263947] = { MC.MAP.Naigtal, 0.376, 0.618, "Interminable Uarn" },
    [263950] = { MC.MAP.Naigtal, 0.442, 0.510, "Broxion" },
    [263954] = { MC.MAP.Naigtal, 0.777, 0.380, "Swalewing Matriarch" },
    [263955] = { MC.MAP.Naigtal, 0.677, 0.629, "Lomelith" },
    [264569] = { MC.MAP.Naigtal, 0.288, 0.629, "Auredar's Chassis" },
    [264574] = { MC.MAP.Naigtal, 0.703, 0.764, "Warp Agent Xi'grivr" },
    [264571] = { MC.MAP.Naigtal, 0.538, 0.516, "Indomitable Mk XII" },
    [264576] = { MC.MAP.Naigtal, 0.561, 0.614, "Slaipaan" },
    [267422] = { MC.MAP.Naigtal, 0.290, 0.180, "Warbringer Thal'kuur" },
    [265698] = { MC.MAP.Naigtal, 0.488, 0.474, "Voidwarped Sporebat" },
}

for npcID, waypoint in pairs(added) do
    MC.RareNPCs[npcID] = waypoint
    if MC.RareCoords then MC.RareCoords[waypoint[4]] = waypoint end
end
