local _, MC = ...

-- Patch 12.1: Curse of Ula'tek.
-- The source key and its label are already declared in the base file.
-- Re-adding the key here put it in MC.RareSourceOrder twice, and the
-- render walks that list, so the whole Coiled Isle group drew twice.

MC.RegisterContent("midnight", "rares", {
    { source = "coiled_isle", achievementID = 63358, criteriaCount = 12,
      criteriaNPCIDs = {
          264854, 268049, 268090, 265237, 265262, 263456,
          258916, 258920, 257906, 256631, 261109, 261142,
      }, name = "Coiled to Strike", zoneMapID = MC.MAP.CoiledIsle, zone = "The Coiled Isle" },
    { source = "coiled_isle", achievementID = 63390, criteriaCount = 5,
      criteriaNPCIDs = { 255088, 257863, 258254, 255927, 255087 },
      name = "Turn the Surge", zoneMapID = MC.MAP.CoiledIsle, zone = "The Coiled Isle" },
})

local added = {
    -- Coiled to Strike
    [264854] = { MC.MAP.CoiledIsle, 0.5378, 0.7206, "Farthik the Plunderer" },
    [268049] = { MC.MAP.CoiledIsle, 0.5025, 0.6927, "Siltmouth" },
    [268090] = { MC.MAP.CoiledIsle, 0.2493, 0.7370, "Kari'zah the Forgotten" },
    [265237] = { MC.MAP.CoiledIsle, 0.3178, 0.5670, "Lockjaw" },
    [265262] = { MC.MAP.CoiledIsle, 0.4415, 0.5039, "Hisstara" },
    [263456] = { MC.MAP.VaultsDepths, 0.3800, 0.1750, "Szarith the Fanged" },
    [258916] = { MC.MAP.CoiledIsle, 0.6944, 0.4485, "Garsecg" },
    [258920] = { MC.MAP.CoiledIsle, 0.5237, 0.4310, "Nar'zira" },
    [257906] = { MC.MAP.CoiledIsle, 0.5729, 0.6847, "Coin-Eye Skully" },
    [256631] = { MC.MAP.CoiledIsle, 0.6992, 0.6349, "Big Mon" },
    [261109] = { MC.MAP.CoiledIsle, 0.5737, 0.4017, "Sss'alik" },
    [261142] = { MC.MAP.CoiledIsle, 0.5227, 0.3243, "Destra" },
    -- Turn the Surge. Curse Surge bosses are encounter-spawned; these are
    -- the associated surge locations when a fixed map coordinate is known.
    [255088] = { MC.MAP.CoiledIsle, 0.2660, 0.6490, "Looming Mutagenitor" },
    [258254] = { MC.MAP.CoiledIsle, 0.7130, 0.3140, "Ss'akrithos" },
    [255087] = { MC.MAP.CoiledIsle, 0.4700, 0.6220, "Malformed Leviathan" },
}

for npcID, waypoint in pairs(added) do
    MC.RareNPCs[npcID] = waypoint
    if MC.RareCoords then MC.RareCoords[waypoint[4]] = waypoint end
end
