local _, MC = ...
local LOC = MC.LOC

-- Decorations released with Patch 12.0.7.  The neighborhood inventory is
-- intentionally kept in its own groups: those vendors live inside player
-- neighborhoods and therefore do not have stable world-map waypoints.
MC.RegisterContent("midnight", "decorations", {
    -- Neighborhood vendors -- human furnishings
    {
        source = "vendor",
        decorations = {
            { decorID = 2578, itemID = 246934, name = "Small Covered Wooden Table", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 2579, itemID = 246935, name = "Small Sturdy Wooden Table", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 5851, itemID = 250092, name = "Small Wooden Footstool", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 8985, itemID = 252037, name = "Covered Wooden Desk", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 8986, itemID = 252038, name = "Sturdy Wooden Desk", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12174, itemID = 258570, name = "Refined Wooden Bed", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 14807, itemID = 262962, name = "Carved Wooden Chair", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 17862, itemID = 266233, name = "Short Hanging Tavern Lantern", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 17879, itemID = 266249, name = "Hanging Tavern Lantern", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 17880, itemID = 266250, name = "Long Hanging Tavern Lantern", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 19218, itemID = 268029, name = "Mounted Founder's Point Lantern", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 19219, itemID = 268030, name = "Mounted Tavern Lantern", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 21950, itemID = 272359, name = "Square Woolen Rug", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
        },
    },

    -- Neighborhood vendors -- Founder's Point furnishings
    {
        source = "vendor",
        decorations = {
            { decorID = 2506, itemID = 246803, name = "Arched Wooden Bench", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 2536, itemID = 246870, name = "Farmer's Water Trough", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 2537, itemID = 246871, name = "Hay-Filled Sturdy Feeding Trough", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 2538, itemID = 246872, name = "Carved Stone Bench", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 2540, itemID = 246874, name = "Sturdy Brazier", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 2541, itemID = 246875, name = "Founder's Point Street Light", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 2542, itemID = 246876, name = "Founder's Point Lamppost", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 2543, itemID = 246877, name = "Sturdy Feeding Trough", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 4422, itemID = 248400, name = "Founder's Point Signpost", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 5687, itemID = 249822, name = "Founder's Point Street Sign", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 5688, itemID = 249823, name = "Founder's Point Navigation Sign", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 5855, itemID = 250095, name = "Runed Stone Placard", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 7582, itemID = 250249, name = "Founder's Point Gravestone", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 7583, itemID = 250250, name = "Small Founder's Point Gravestone", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 7584, itemID = 250251, name = "Tall Founder's Point Gravestone", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 7585, itemID = 250252, name = "Large Founder's Point Gravestone", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 8974, itemID = 252004, name = "Wooden Planter Pot", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 8975, itemID = 252005, name = "Wooden Planter Row", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 8976, itemID = 252006, name = "Founder's Point Fence", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 8977, itemID = 252007, name = "Long Founder's Point Fence", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 9056, itemID = 252407, name = "Founder's Point Framed Torch", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 9057, itemID = 252408, name = "Long Old Founder's Point Fence", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 9058, itemID = 252409, name = "Old Founder's Point Fence", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 9059, itemID = 252410, name = "Founder's Point Fencepost", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 9060, itemID = 252412, name = "Old Founder's Point Fencepost", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 9062, itemID = 252414, name = "Broken Founder's Point Fence", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 9063, itemID = 252416, name = "Old Broken Founder's Point Fence", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 9176, itemID = 253018, name = "Founder's Point Standing Torch", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 9630, itemID = 253707, name = "Open Sturdy Wooden Crate", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12169, itemID = 258565, name = "Reinforced Wooden Barrel", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12170, itemID = 258566, name = "Empty Reinforced Wooden Barrel", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12214, itemID = 258818, name = "Padded Wooden Bench", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12215, itemID = 258819, name = "Sturdy Wooden Crate", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 18619, itemID = 267084, name = "Founder's Point Hay Bale", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
        },
    },

    -- Neighborhood vendors -- elven furnishings and flora
    {
        source = "vendor",
        decorations = {
            { decorID = 15598, itemID = 264352, name = "Elegant Elven Bathtub", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 15599, itemID = 264353, name = "Empty Elegant Elven Bathtub", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 17358, itemID = 265653, name = "Elegant Storage Table", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 17359, itemID = 265654, name = "Elegant Elven Washbasin", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 18614, itemID = 267075, name = "Ornate Elven Stove", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 18793, itemID = 267202, name = "Elegant Elven Water Well", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 582, itemID = 245298, name = "Wild Violet Bellflowers", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 584, itemID = 245299, name = "Reaching Violet Bellflowers", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 586, itemID = 245300, name = "Arched Violet Bellflowers", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
        },
    },

    -- Neighborhood vendors -- Razorwind furnishings
    {
        source = "vendor",
        decorations = {
            { decorID = 7688, itemID = 250691, name = "Tusked Leather Tapestry", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 7689, itemID = 250692, name = "Razorwind Banner Pelt", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 10334, itemID = 254395, name = "Razorwind Smith's Hammer", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 10335, itemID = 254396, name = "Razorwind Miner's Pickaxe", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 10336, itemID = 254397, name = "Razorwind Woodworker's Hand Saw", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 10337, itemID = 254398, name = "Razorwind Crafter's Chisel", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 10338, itemID = 254399, name = "Razorwind Peon's Shovel", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 10381, itemID = 254678, name = "Razorwind Logger's Axe", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 10890, itemID = 255706, name = "Razorwind Iron Chandelier", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 10891, itemID = 255707, name = "Low-Hanging Razorwind Iron Chandelier", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 11129, itemID = 256329, name = "Razorwind Standing Tusk", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12193, itemID = 258664, name = "Tusk-Adorned Stitched Rug", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12194, itemID = 258665, name = "Small Stitched Rug", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12453, itemID = 259464, name = "Rolled Razorwind Leathers", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12454, itemID = 259465, name = "Low-Hanging Razorwind Ropes", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12455, itemID = 259466, name = "Knotted Hanging Razorwind Ropes", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12456, itemID = 259467, name = "Tusked Hanging Razorwind Ropes", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12457, itemID = 259468, name = "Plain Hanging Razorwind Ropes", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12458, itemID = 259469, name = "Adorned Hanging Razorwind Ropes", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12459, itemID = 259470, name = "Lightly Adorned Hanging Razorwind Ropes", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 17609, itemID = 265924, name = "High-Mounted Razorwind Bowl Chandelier", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 17610, itemID = 265925, name = "Razorwind Bowl Chandelier", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 17611, itemID = 265926, name = "Low-Hanging Razorwind Bowl Chandelier", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 18620, itemID = 267088, name = "Iron Candlelight Lantern", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
        },
    },

    -- Neighborhood vendors -- Razorwind outdoor furnishings
    {
        source = "vendor",
        decorations = {
            { decorID = 7871, itemID = 251011, name = "Painted Wood Scraps", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 7872, itemID = 251012, name = "Painted Wood Scrap Pile", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 8978, itemID = 252008, name = "Razorwind Wheelbarrow", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 9177, itemID = 253019, name = "Razorwind Banded Planter", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 10893, itemID = 255709, name = "Razorwind Shores Canoe", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 11943, itemID = 258300, name = "Sparse Razorwind Fisher's Rack", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 11949, itemID = 258307, name = "Razorwind Fisher's Rack", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 12192, itemID = 258663, name = "Razorwind River Paddle", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 14346, itemID = 260486, name = "Large Razorwind Farmer's Hay Pile", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 14347, itemID = 260487, name = "Razorwind Farmer's Hay Pile", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 14348, itemID = 260488, name = "Small Razorwind Farmer's Hay Pile", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 14817, itemID = 263031, name = "Twisted Rope Coil", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 14818, itemID = 263032, name = "Razorwind Fishing Net", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 15261, itemID = 263581, name = "Razorwind Roofer's Shingle", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 15262, itemID = 263582, name = "Razorwind Roofer's Shingle Pile", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 15263, itemID = 263583, name = "Tiny Clump of Hay", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 15264, itemID = 263584, name = "Razorwind Construction Crane", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 18618, itemID = 267083, name = "Razorwind Campfire Grill", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 19159, itemID = 267616, name = "Loose Wisps of Hay", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 19215, itemID = 268026, name = "Scattered Wisps of Hay", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 19216, itemID = 268027, name = "Windblown Wisps of Hay", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
            { decorID = 19217, itemID = 268028, name = "Trampled Wisps of Hay", source = "vendor", sourceInfo = "Neighborhood decor vendor (Patch 12.0.7)" },
        },
    },

    -- Void Showdown vendor (Zuronar rotates with Naigtal and Val).
    {
        source = "vendor",
        decorations = {
            { decorID = 25664, itemID = 276432, name = "De-Powered Lightforged Siegebreaker", source = "vendor", sourceInfo = "Zuronar - 500 Voidlight Marl; Prepared for a Showdown", waypoint = LOC.Zuronar, cost = { currency = { MC.CURRENCY.VoidlightMarl, 500 } }, achievementID = 63384 },
            { decorID = 25665, itemID = 276429, name = "Grand Artificer's Lightforged Console", source = "vendor", sourceInfo = "Zuronar - 250 Voidlight Marl; Prepared for a Showdown", waypoint = LOC.Zuronar, cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } }, achievementID = 63384 },
            { decorID = 25564, itemID = 276321, name = "Luminant Defender's Golden Barricade", source = "vendor", sourceInfo = "Zuronar - 150 Voidlight Marl; Pain of Command", waypoint = LOC.Zuronar, cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } }, achievementID = 62905 },
            { decorID = 25566, itemID = 276316, name = "Lightveil's Transport Pad", source = "vendor", sourceInfo = "Zuronar - 250 Voidlight Marl; Prepared for a Showdown", waypoint = LOC.Zuronar, cost = { currency = { MC.CURRENCY.VoidlightMarl, 250 } }, achievementID = 63384 },
            { decorID = 18802, itemID = 267211, name = "Luminant Scout's Golden Fence", source = "vendor", sourceInfo = "Zuronar - 150 Voidlight Marl; Pain of Command", waypoint = LOC.Zuronar, cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } }, achievementID = 62905 },
            { decorID = 25565, itemID = 276318, name = "Luminant Soldier's War Banner", source = "vendor", sourceInfo = "Zuronar - 150 Voidlight Marl; Pain of Command", waypoint = LOC.Zuronar, cost = { currency = { MC.CURRENCY.VoidlightMarl, 150 } }, achievementID = 62905 },
        },
    },

    -- Ritual Sites renown addition.
    {
        source = "renown",
        decorations = {
            { decorID = 25307, itemID = 276083, name = "Sunstrider Omnium Simulacrum", source = "renown", sourceInfo = "Sergeant Vornin - 500 Voidlight Marl", waypoint = LOC.SergeantVornin, zone = "Silvermoon City", cost = { currency = { MC.CURRENCY.VoidlightMarl, 500 } }, renown = { factionID = MC.FACTION.RitualSites, level = 3, factionName = "Ritual Sites" } },
        },
    },

    -- Direct achievement rewards.
    {
        source = "achievement",
        decorations = {
            { decorID = 20679, itemID = 269316, name = "Bartender Bob's \"No Weapons Allowed\" Rack", source = "achievement", sourceInfo = "Jan'alai's Eggstravaganza", zone = "Arcantina", achievementID = 61083, waypoint = { 2541, 0.4200, 0.5010, "Bartender Bob's \"No Weapons Allowed\" Rack" } },
            { decorID = 24194, itemID = 274736, name = "Framed Alliance Pride", source = "achievement", sourceInfo = "Goal!", zone = "Silvermoon City", achievementID = 63343, waypoint = { 2393, 0.3940, 0.5940, "Framed Alliance Pride" } },
            { decorID = 24193, itemID = 274734, name = "Framed Horde Pride", source = "achievement", sourceInfo = "Goal!", zone = "Silvermoon City", achievementID = 63343, waypoint = { 2393, 0.3940, 0.5940, "Framed Horde Pride" } },
            { decorID = 23706, itemID = 274731, name = "Prized Orb of Azeroth", source = "achievement", sourceInfo = "Goal!", zone = "Silvermoon City", achievementID = 63343, waypoint = { 2393, 0.3940, 0.5940, "Prized Orb of Azeroth" } },
        },
    },

    -- Sporefall raid drop.
    {
        source = "drop",
        decorations = {
            { decorID = 2606, itemID = 247235, name = "Luminous Rotshroom", source = "drop", sourceInfo = "Rotmire, Sporefall", zone = "Sporefall", waypoint = { 2413, 0.7350, 0.6640, "Luminous Rotshroom" } },
        },
    },

    -- Patch-era additions to legacy vendors and promotions.
    {
        source = "vendor",
        decorations = {
            { decorID = 21857, itemID = 271971, name = "Tome of Kings", source = "vendor", sourceInfo = "Legacy vendor - 2,000 gold", zone = "Vale of Eternal Blossoms", cost = { gold = 20000000 }, waypoint = { 390, 0.8280, 0.3040, "Tome of Kings" } },
        },
    },
    {
        source = "worldevent",
        decorations = {
            { decorID = 16813, itemID = 265389, name = "Cuddly Cotton Candy Grrgle", source = "worldevent", sourceInfo = "Twitch Drop promotion (expired)", unavailable = true },
        },
    },
})
