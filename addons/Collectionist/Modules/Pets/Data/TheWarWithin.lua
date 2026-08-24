local _, MC = ...
local T = MC.SCORE_TIERS

-- The War Within (wave 1) pets.
-- Sources derived from research/collectionist/tww/ids/pets.csv: all
-- guide_confirmed rows plus triage-approved db2_tww_signal / snapshot rows.
-- The ID inventory carries no coordinates, so no waypoints yet — entries
-- marked "source not yet documented" also need a later enrichment pass.
-- Catalog policy: Trading Post, In-Game Shop, and out-of-game promotion pets
-- (28 guide-confirmed rows) are deliberately excluded; a 29th exclusion
-- (species 4837, "Worm, Cosmic - Critter (Red)") is an internal test row.

-- Worm Theory (40869) — earns Lil' Bonechewer. Criterion order follows
-- CriteriaTree order_path 0-2 in the research inventory.
local WORM_THEORY_TASKS = {
    intro = "Complete the three Rak-Ush / Wormlands quests.",
    tasks = {
        { achievementID = 40869, criteriaIndex = 1, label = "Grub Run" },
        { achievementID = 40869, criteriaIndex = 2, label = "Wormcraft Rumble" },
        { achievementID = 40869, criteriaIndex = 3, label = "Worm Sign, Sealed, Delivered" },
    },
}

-- In with the Cartels (41349) — earns Iron Chick. Honored (9000) with all
-- four Undermine cartels; criterion order follows order_path 0-3.
local IN_WITH_THE_CARTELS_TASKS = {
    intro = "Reach Honored with all four Undermine cartels.",
    tasks = {
        { achievementID = 41349, criteriaIndex = 1, label = "Bilgewater Cartel" },
        { achievementID = 41349, criteriaIndex = 2, label = "Blackwater Cartel" },
        { achievementID = 41349, criteriaIndex = 3, label = "Steamwheedle Cartel" },
        { achievementID = 41349, criteriaIndex = 4, label = "Venture Co." },
    },
}

MC.RegisterContent("tww", "pets", {
    -- Wild battle pets (captured through pet battles). 58 species.
    {
        source = "wild",
        pets = {
            { speciesID = 4456, npcID = 222066, name = "Arachnoid Hatchling",    petType = 8,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet, City of Threads, Hallowfall, Shadowvein Extraction Site, The Ringing Deeps", canBattle = true, zone = "Khaz Algar" },
            { speciesID = 4457, npcID = 222071, name = "Chitin Burrower",        petType = 8,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet, City of Threads, Hallowfall, Shadowvein Extraction Site, The Ringing Deeps", canBattle = true, zone = "Khaz Algar" },
            { speciesID = 4460, npcID = 222195, name = "Arathi Chicken",         petType = 3,  source = "wild", sourceInfo = "Wild pet battle: Hallowfall",                    canBattle = true, zone = "Hallowfall" },
            { speciesID = 4461, npcID = 222194, name = "Greenlands Chicken",     petType = 3,  source = "wild", sourceInfo = "Wild pet battle: Hallowfall",                    canBattle = true, zone = "Hallowfall" },
            { speciesID = 4471, npcID = 222325, name = "Aubergine Scootlefish",  petType = 9,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet",                     canBattle = true, zone = "Azj-Kahet" },
            { speciesID = 4477, npcID = 222344, name = "Verdant Scootlefish",    petType = 9,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet",                     canBattle = true, zone = "Azj-Kahet" },
            { speciesID = 4480, npcID = 222351, name = "Shadowy Oozeling",       petType = 6,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet",                     canBattle = true, zone = "Azj-Kahet" },
            { speciesID = 4481, npcID = 222354, name = "Voidling Ooze",          petType = 6,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet",                     canBattle = true, zone = "Azj-Kahet" },
            { speciesID = 4483, npcID = 222421, name = "Vile Bloodtick",         petType = 5,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet",                     canBattle = true, zone = "Azj-Kahet" },
            { speciesID = 4484, npcID = 222420, name = "Frenzied Bloodtick",     petType = 5,  source = "wild", sourceInfo = "Wild pet battle: The Ringing Deeps",             canBattle = true, zone = "The Ringing Deeps" },
            { speciesID = 4485, npcID = 222499, name = "Mossy Snail",            petType = 5,  source = "wild", sourceInfo = "Wild pet battle: Isle of Dorn",                  canBattle = true, zone = "Isle of Dorn" },
            { speciesID = 4498, npcID = 222582, name = "Ebon Ploughworm",        petType = 5,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet, City of Threads, Hallowfall, Shadowvein Extraction Site, The Ringing Deeps", canBattle = true, zone = "Khaz Algar" },
            { speciesID = 4499, npcID = 222584, name = "Common Ploughworm",      petType = 5,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet, City of Threads, Hallowfall, Shadowvein Extraction Site, The Ringing Deeps", canBattle = true, zone = "Khaz Algar" },
            { speciesID = 4507, npcID = 222592, name = "Hemospore",              petType = 6,  source = "wild", sourceInfo = "Wild pet battle: The Ringing Deeps",             canBattle = true, zone = "The Ringing Deeps" },
            { speciesID = 4510, npcID = 222608, name = "Winged Arachnoid",       petType = 3,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet, Hallowfall",         canBattle = true, zone = "Azj-Kahet" },
            { speciesID = 4514, npcID = 222613, name = "Fallowspark Glowfly",    petType = 3,  source = "wild", sourceInfo = "Wild pet battle: Dornogal, Hallowfall, Isle of Dorn, The Ringing Deeps", canBattle = true, zone = "Khaz Algar" },
            { speciesID = 4515, npcID = 222614, name = "Azure Flickerfly",       petType = 3,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet, City of Threads, Hallowfall, Shadowvein Extraction Site, The Ringing Deeps", canBattle = true, zone = "Khaz Algar" },
            { speciesID = 4516, npcID = 222615, name = "Vibrant Glowfly",        petType = 3,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet, City of Threads, Hallowfall, Shadowvein Extraction Site, The Ringing Deeps", canBattle = true, zone = "Khaz Algar" },
            { speciesID = 4518, npcID = 222713, name = "Magmashell Crawler",     petType = 7,  source = "wild", sourceInfo = "Wild pet battle: Dornogal, The Ringing Deeps",   canBattle = true, zone = "The Ringing Deeps" },
            { speciesID = 4521, npcID = 222736, name = "Subterranean Dartswog",  petType = 9,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet, City of Threads, Hallowfall, Isle of Dorn, The Ringing Deeps", canBattle = true, zone = "Khaz Algar" },
            { speciesID = 4522, npcID = 222739, name = "Troglofrog",             petType = 9,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet, City of Threads, Deepforge Golemworks, Hallowfall, Isle of Dorn, The Ringing Deeps", canBattle = true, zone = "Khaz Algar" },
            { speciesID = 4525, npcID = 222774, name = "Fragrant Stonelamb",     petType = 5,  source = "wild", sourceInfo = "Wild pet battle: Isle of Dorn",                  canBattle = true, zone = "Isle of Dorn" },
            { speciesID = 4526, npcID = 222775, name = "Sandstone Mosswool",     petType = 5,  source = "wild", sourceInfo = "Wild pet battle: Dornogal, Isle of Dorn",        canBattle = true, zone = "Isle of Dorn" },
            { speciesID = 4529, npcID = 222778, name = "Shale Mosswool",         petType = 5,  source = "wild", sourceInfo = "Wild pet battle: Isle of Dorn",                  canBattle = true, zone = "Isle of Dorn" },
            { speciesID = 4533, npcID = 222875, name = "Meek Bloodlasher",       petType = 7,  source = "wild", sourceInfo = "Wild pet battle: Hallowfall, Isle of Dorn, The Ringing Deeps", canBattle = true, zone = "Khaz Algar" },
            { speciesID = 4535, npcID = 222877, name = "Ghostcap Menace",        petType = 7,  source = "wild", sourceInfo = "Wild pet battle: Hallowfall, Isle of Dorn, The Ringing Deeps", canBattle = true, zone = "Khaz Algar" },
            { speciesID = 4538, npcID = 223094, name = "Cobalt Ramolith",        petType = 8,  source = "wild", sourceInfo = "Wild pet battle: Isle of Dorn",                  canBattle = true, zone = "Isle of Dorn" },
            { speciesID = 4539, npcID = 223093, name = "Granite Ramolith",       petType = 8,  source = "wild", sourceInfo = "Wild pet battle: Isle of Dorn",                  canBattle = true, zone = "Isle of Dorn" },
            { speciesID = 4540, npcID = 223092, name = "Alabaster Stonecharger", petType = 8,  source = "wild", sourceInfo = "Wild pet battle: Isle of Dorn",                  canBattle = true, zone = "Isle of Dorn" },
            { speciesID = 4541, npcID = 223090, name = "Bedrock Stonecharger",   petType = 8,  source = "wild", sourceInfo = "Wild pet battle: Dornogal, Isle of Dorn",        canBattle = true, zone = "Isle of Dorn" },
            { speciesID = 4544, npcID = 223136, name = "Umbral Amalgam",         petType = 6,  source = "wild", sourceInfo = "Wild pet battle: Hallowfall",                    canBattle = true, zone = "Hallowfall" },
            { speciesID = 4571, npcID = 223706, name = "Pinkskin Burrower",      petType = 8,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet, The Ringing Deeps",  canBattle = true, zone = "The Ringing Deeps" },
            { speciesID = 4573, npcID = 223712, name = "Skittish Sniffler",      petType = 8,  source = "wild", sourceInfo = "Wild pet battle: Azj-Kahet, The Ringing Deeps",  canBattle = true, zone = "The Ringing Deeps" },
            { speciesID = 4574, npcID = 223715, name = "Snuffling",              petType = 8,  source = "wild", sourceInfo = "Wild pet battle: The Ringing Deeps",             canBattle = true, zone = "The Ringing Deeps" },
            { speciesID = 4577, npcID = 223698, name = "Cinderhoney Emberstinger", petType = 7, source = "wild", sourceInfo = "Wild pet battle: Isle of Dorn",                 canBattle = true, zone = "Isle of Dorn" },
            { speciesID = 4628, npcID = 230394, name = "Tidal Kroling",          petType = 8,  source = "wild", sourceInfo = "Wild pet battle: Siren Isle",                    canBattle = true, zone = "Siren Isle" },
            { speciesID = 4651, npcID = 231477, name = "Wily Rat",               petType = 5,  source = "wild", sourceInfo = "Wild pet battle: Undermine",                     canBattle = true, zone = "Undermine" },
            { speciesID = 4652, npcID = 231470, name = "Acid-Drenched Rat",      petType = 5,  source = "wild", sourceInfo = "Wild pet battle: Undermine",                     canBattle = true, zone = "Undermine" },
            { speciesID = 4654, npcID = 231481, name = "Underroach",             petType = 5,  source = "wild", sourceInfo = "Wild pet battle: Undermine",                     canBattle = true, zone = "Undermine" },
            { speciesID = 4656, npcID = 231550, name = "Bombshell Crab",         petType = 9,  source = "wild", sourceInfo = "Wild pet battle: Undermine",                     canBattle = true, zone = "Undermine" },
            { speciesID = 4657, npcID = 231567, name = "Venture Bombshell",      petType = 9,  source = "wild", sourceInfo = "Wild pet battle: Undermine",                     canBattle = true, zone = "Undermine" },
            { speciesID = 4658, npcID = 231570, name = "Cave Crab",              petType = 9,  source = "wild", sourceInfo = "Wild pet battle: Undermine",                     canBattle = true, zone = "Undermine" },
            { speciesID = 4659, npcID = 231572, name = "Kaja Crab",              petType = 9,  source = "wild", sourceInfo = "Wild pet battle: Zuldazar (added with Undermine)", canBattle = true, zone = "Zuldazar" },
            { speciesID = 4660, npcID = 231574, name = "Paleshell Crab",         petType = 9,  source = "wild", sourceInfo = "Wild pet battle: Undermine",                     canBattle = true, zone = "Undermine" },
            { speciesID = 4662, npcID = 231577, name = "Varmint MK II",          petType = 10, source = "wild", sourceInfo = "Wild pet battle: Undermine",                     canBattle = true, zone = "Undermine" },
            { speciesID = 4663, npcID = 231579, name = "Lime Roboclucker",       petType = 10, source = "wild", sourceInfo = "Wild pet battle: Undermine",                     canBattle = true, zone = "Undermine" },
            { speciesID = 4666, npcID = 231616, name = "Tropical Frog",          petType = 9,  source = "wild", sourceInfo = "Wild pet battle: Zuldazar (added with Undermine)", canBattle = true, zone = "Zuldazar" },
            { speciesID = 4667, npcID = 231684, name = "Spring-Loaded Ribbitron", petType = 10, source = "wild", sourceInfo = "Wild pet battle: Undermine",                    canBattle = true, zone = "Undermine" },
            { speciesID = 4668, npcID = 231686, name = "Ultrahopper EX",         petType = 10, source = "wild", sourceInfo = "Wild pet battle: Undermine",                     canBattle = true, zone = "Undermine" },
            { speciesID = 4693, npcID = 231728, name = "Alchemical Runoff",      petType = 6,  source = "wild", sourceInfo = "Wild pet battle: Undermine",                     canBattle = true, zone = "Undermine" },
            { speciesID = 4702, npcID = 234097, name = "Rusty Kroling",          petType = 8,  source = "wild", sourceInfo = "Wild pet battle: Siren Isle",                    canBattle = true, zone = "Siren Isle" },
            { speciesID = 4703, npcID = 234101, name = "Cave Kroling",           petType = 8,  source = "wild", sourceInfo = "Wild pet battle: Siren Isle",                    canBattle = true, zone = "Siren Isle" },
            { speciesID = 4710, npcID = 234367, name = "Pillaged Parrot",        petType = 3,  source = "wild", sourceInfo = "Wild pet battle: Siren Isle",                    canBattle = true, zone = "Siren Isle" },
            { speciesID = 4711, npcID = 234369, name = "Snapdragon Pup",         petType = 9,  source = "wild", sourceInfo = "Wild pet battle: Siren Isle",                    canBattle = true, zone = "Siren Isle" },
            { speciesID = 4723, npcID = 234710, name = "Cliffreach Cub",         petType = 8,  source = "wild", sourceInfo = "Wild pet battle: Siren Isle",                    canBattle = true, zone = "Siren Isle" },
            { speciesID = 4724, npcID = 234734, name = "Battleboar Piglet",      petType = 8,  source = "wild", sourceInfo = "Wild pet battle: Siren Isle",                    canBattle = true, zone = "Siren Isle" },
            { speciesID = 4731, npcID = 236040, name = "Storm-Infused Snapdragon", petType = 9, source = "wild", sourceInfo = "Wild pet battle: Siren Isle (Seafury Tempest)", canBattle = true, zone = "Siren Isle" },
            { speciesID = 4732, npcID = 236041, name = "Scavenging Snapdragon",  petType = 9,  source = "wild", sourceInfo = "Wild pet battle: Siren Isle (Seafury Tempest)",  canBattle = true, zone = "Siren Isle" },
        },
    },

    -- Vendor pets. 39 entries.
    {
        source = "vendor",
        pets = {
            -- Kej vendors (Azj-Kahet / City of Threads)
            { speciesID = 4455, itemID = 221486, npcID = 222046, name = "Rak-Ush Threadling",  petType = 8, source = "vendor", sourceInfo = "Ves'trak - 2,250 Kej",
              canBattle = true, zone = "Azj-Kahet", cost = { currency = { MC.CURRENCY.Kej, 2250 } } },
            { speciesID = 4464, itemID = 221850, npcID = 222202, name = "Bean",                petType = 8, source = "vendor", sourceInfo = "Pelefien - 2,250 Kej",
              canBattle = true, zone = "City of Threads", cost = { currency = { MC.CURRENCY.Kej, 2250 } } },
            { speciesID = 4476, itemID = 222968, npcID = 222341, name = "Itchbite",            petType = 4, source = "vendor", sourceInfo = "Clutchmother Marn'tiq - 2,250 Kej",
              canBattle = true, zone = "City of Threads", cost = { currency = { MC.CURRENCY.Kej, 2250 } } },
            { speciesID = 4491, itemID = 222972, npcID = 222575, name = "Jump Jump",           petType = 8, source = "vendor", sourceInfo = "Lady Vinazian or Y'tekhi - 2,250 Kej",
              canBattle = true, zone = "Azj-Kahet", cost = { currency = { MC.CURRENCY.Kej, 2250 } } },
            { speciesID = 4492, itemID = 222973, npcID = 222576, name = "Fringe",              petType = 8, source = "vendor", sourceInfo = "Clutchmother Marn'tiq - 2,250 Kej",
              canBattle = true, zone = "City of Threads", cost = { currency = { MC.CURRENCY.Kej, 2250 } } },

            -- Resonance Crystal vendors
            { speciesID = 4463, itemID = 221848, npcID = 222200, name = "Tiberius",            petType = 8, source = "vendor", sourceInfo = "Auralia Steelstrike - 6,500 Resonance Crystals",
              canBattle = true, zone = "Hallowfall", cost = { currency = { MC.CURRENCY.ResonanceCrystals, 6500 } } },
            { speciesID = 4530, itemID = 222965, npcID = 222779, name = "Loamy",               petType = 5, source = "vendor", sourceInfo = "Auditor Balwurz - 6,500 Resonance Crystals",
              canBattle = true, zone = "Dornogal", cost = { currency = { MC.CURRENCY.ResonanceCrystals, 6500 } } },
            { speciesID = 4576, itemID = 223623, npcID = 223717, name = "Guacamole",           petType = 8, source = "vendor", sourceInfo = "Waxmonger Squick - 6,500 Resonance Crystals",
              canBattle = true, zone = "The Ringing Deeps", cost = { currency = { MC.CURRENCY.ResonanceCrystals, 6500 } } },
            { speciesID = 4632, itemID = 232853, npcID = 231468, name = "Eepy",                petType = 8, source = "vendor", sourceInfo = "Lab Assistant Laszly - 6,500 Resonance Crystals",
              canBattle = true, zone = "Undermine", cost = { currency = { MC.CURRENCY.ResonanceCrystals, 6500 } } },
            { speciesID = 4637, itemID = 232839, npcID = 231457, name = "Wavebreaker Mechasaur", petType = 10, source = "vendor", sourceInfo = "Boatswain Hardee - 6,500 Resonance Crystals",
              canBattle = true, zone = "Undermine", cost = { currency = { MC.CURRENCY.ResonanceCrystals, 6500 } } },
            { speciesID = 4641, itemID = 232851, npcID = 231450, name = "Rocketfist",          petType = 10, source = "vendor", sourceInfo = "Shredz the Scrapper - 6,500 Resonance Crystals",
              canBattle = true, zone = "Undermine", cost = { currency = { MC.CURRENCY.ResonanceCrystals, 6500 } } },
            { speciesID = 4645, itemID = 232845, npcID = 231458, name = "Bilgewater Junkhauler", petType = 10, source = "vendor", sourceInfo = "Rocco Razzboom - 6,500 Resonance Crystals",
              canBattle = true, zone = "Undermine", cost = { currency = { MC.CURRENCY.ResonanceCrystals, 6500 } } },
            { speciesID = 4794, itemID = 238986, npcID = 241297, name = "Mister Mans",         petType = 8, source = "vendor", sourceInfo = "Lars Bronsmaelt - 6,500 Resonance Crystals",
              canBattle = true, zone = "Hallowfall", cost = { currency = { MC.CURRENCY.ResonanceCrystals, 6500 } } },
            { speciesID = 4804, itemID = 241188, npcID = 242652, name = "Swiftpaw",            petType = 8, source = "vendor", sourceInfo = "Lars Bronsmaelt - 6,500 Resonance Crystals",
              canBattle = true, zone = "Hallowfall", cost = { currency = { MC.CURRENCY.ResonanceCrystals, 6500 } } },

            -- Polished Pet Charm world vendors
            { speciesID = 4495, itemID = 221494, npcID = 222079, name = "Skippy",              petType = 9, source = "vendor", sourceInfo = "World pet-charm vendors - 50 Polished Pet Charms", zone = "Dornogal",
              canBattle = true, cost = { item = { 163036, 50 } } },
            { speciesID = 4511, itemID = 221761, npcID = 222607, name = "Venomwing",           petType = 3, source = "vendor", sourceInfo = "World pet-charm vendors - 50 Polished Pet Charms", zone = "Dornogal",
              canBattle = true, cost = { item = { 163036, 50 } } },
            { speciesID = 4524, itemID = 221811, npcID = 222764, name = "Starkstripe Hopper",  petType = 9, source = "vendor", sourceInfo = "World pet-charm vendors - 50 Polished Pet Charms", zone = "Dornogal",
              canBattle = true, cost = { item = { 163036, 50 } } },
            { speciesID = 4546, itemID = 222978, npcID = 223088, name = "Sandstone Ramolith",  petType = 8, source = "vendor", sourceInfo = "World pet-charm vendors - 50 Polished Pet Charms", zone = "Dornogal",
              canBattle = true, cost = { item = { 163036, 50 } } },
            { speciesID = 4586, itemID = 224101, npcID = 224090, name = "Brown Leafbug",       petType = 5, source = "vendor", sourceInfo = "World pet-charm vendors - 50 Polished Pet Charms", zone = "Dornogal",
              canBattle = true, cost = { item = { 163036, 50 } } },

            -- Undercoin
            { speciesID = 4543, itemID = 222974, npcID = 223135, name = "Sir Shady Mrrgglton Junior", petType = 6, source = "vendor", sourceInfo = "Sir Finley Mrrgglton - 10,000 Undercoin",
              canBattle = true, zone = "Dornogal", cost = { currency = { MC.CURRENCY.Undercoin, 10000 } } },

            -- Item-cost vendors
            { speciesID = 4597, itemID = 224760, npcID = 225632, name = "Wobbles",             petType = 7, source = "vendor", sourceInfo = "Gnawbles - gem turn-in (item 224642)",
              canBattle = true, zone = "The Ringing Deeps", cost = { item = { 224642, 1 } } },
            { speciesID = 4598, itemID = 224646, npcID = 225554, name = "Coppers",             petType = 1, source = "vendor", sourceInfo = "Gnawbles - gem turn-in (item 224642)",
              canBattle = true, zone = "The Ringing Deeps", cost = { item = { 224642, 1 } } },
            { speciesID = 4638, itemID = 232842, npcID = 231455, name = "Crimson Mechasaur",   petType = 10, source = "vendor", sourceInfo = "Ditty Fuzeboy - 10 Empty Kaja'Cola Cans",
              canBattle = true, zone = "Undermine", cost = { item = { 234741, 10 } } },
            { speciesID = 4644, itemID = 232841, npcID = 231453, name = "Professor Punch",     petType = 10, source = "vendor", sourceInfo = "Ditty Fuzeboy - 8 Empty Kaja'Cola Cans",
              canBattle = true, zone = "Undermine", cost = { item = { 234741, 8 } } },
            { speciesID = 4648, itemID = 232846, npcID = 231461, name = "Steamwheedle Flunkie", petType = 10, source = "vendor", sourceInfo = "Ditty Fuzeboy - 5 Empty Kaja'Cola Cans",
              canBattle = true, zone = "Undermine", cost = { item = { 234741, 5 } } },
            { speciesID = 4649, itemID = 232850, npcID = 231459, name = "Blackwater Kegmover", petType = 10, source = "vendor", sourceInfo = "Ditty Fuzeboy - 5 Empty Kaja'Cola Cans",
              canBattle = true, zone = "Undermine", cost = { item = { 234741, 5 } } },
            { speciesID = 4650, itemID = 232849, npcID = 231460, name = "Venture Companyman",  petType = 10, source = "vendor", sourceInfo = "Ditty Fuzeboy - 5 Empty Kaja'Cola Cans",
              canBattle = true, zone = "Undermine", cost = { item = { 234741, 5 } } },
            { speciesID = 4661, itemID = 232840, npcID = 231622, name = "Mechagopher",         petType = 10, source = "vendor", sourceInfo = "Ditty Fuzeboy - 5 Empty Kaja'Cola Cans",
              canBattle = true, zone = "Undermine", cost = { item = { 234741, 5 } } },
            { speciesID = 4653, itemID = 232859, npcID = 231479, name = "Lab Rat",             petType = 5, source = "vendor", sourceInfo = "Angelo Rustbin - 3 Vintage Kaja'Cola Cans",
              canBattle = true, zone = "Undermine", cost = { currency = { 3220, 3 } } },
            { speciesID = 4655, itemID = 232858, npcID = 231548, name = "Cruncher",            petType = 5, source = "vendor", sourceInfo = "Angelo Rustbin - 1 Vintage Kaja'Cola Can",
              canBattle = true, zone = "Undermine", cost = { currency = { 3220, 1 } } },

            -- Raid vendors (Liberation of Undermine)
            { speciesID = 4640, itemID = 232844, npcID = 231454, name = "Fun-Size Flarendo",   petType = 10, source = "vendor", sourceInfo = "Snix Longpocket inside Liberation of Undermine (cost undocumented)",
              canBattle = true, zone = "Liberation of Undermine", score = T.medium },
            { speciesID = 4643, itemID = 232806, npcID = 231448, name = "Tiny Torq",           petType = 10, source = "vendor", sourceInfo = "Skitto Screwjack inside Liberation of Undermine (cost undocumented)",
              canBattle = true, zone = "Liberation of Undermine", score = T.medium },

            -- Siren Isle / K'aresh
            { speciesID = 4727, itemID = 234395, npcID = 235130, name = "Skitterbite",         petType = 8, source = "vendor", sourceInfo = "Soweezi - 750 Flame-Blessed Iron",
              canBattle = true, zone = "Siren Isle", cost = { currency = { MC.CURRENCY.FlameBlessedIron, 750 } } },
            { speciesID = 4829, itemID = 244910, npcID = 245476, name = "Penumbral Terror",    petType = 6, source = "vendor", sourceInfo = "Shad'anis - 4 Untethered Coins",
              canBattle = true, zone = "K'aresh", cost = { currency = { MC.CURRENCY.UntetheredCoin, 4 } } },
            { speciesID = 4832, itemID = 244913, npcID = 245479, name = "Looker Gaz'kreth Jr.", petType = 6, source = "vendor", sourceInfo = "Manaforge Vandals (Shadow Point)",
              canBattle = true, zone = "K'aresh",
              renown = { factionID = MC.FACTION.ManaforgeVandals, level = 13, factionName = "Manaforge Vandals" }, score = T.medium },
            { speciesID = 4859, itemID = 246694, npcID = 247463, name = "Zo'ya",               petType = 8, source = "vendor", sourceInfo = "Manaforge Vandals (Shadow Point)",
              canBattle = true, zone = "K'aresh",
              renown = { factionID = MC.FACTION.ManaforgeVandals, level = 8, factionName = "Manaforge Vandals" }, score = T.medium },

            -- Horrific Visions Revisited vendor
            { speciesID = 4756, itemID = 235980, npcID = 238064, name = "Scourge of the Aspects", petType = 2, source = "vendor",
              sourceInfo = "Torie - 5,000 Displaced Corrupted Mementos (Horrific Visions Revisited)",
              canBattle = true, zone = "Dornogal", cost = { currency = { 3149, 5000 } }, score = T.medium },

            -- Vendor rows the ID inventory could not name — needs enrichment.
            { speciesID = 4478, npcID = 222348, name = "Caustic Oozeling",       petType = 6, source = "vendor", sourceInfo = "Vendor (name not yet documented)",
              canBattle = true },
            { speciesID = 4502, npcID = 222585, name = "Kaheti Bull Worm",       petType = 5, source = "vendor", sourceInfo = "Vendor (name not yet documented)",
              canBattle = true },
        },
    },

    -- Drop pets. 37 entries.
    {
        source = "drop",
        pets = {
            -- Dungeon and rare drops
            { speciesID = 4469, itemID = 223155, npcID = 222318, name = "Bop",                 petType = 3, source = "drop", sourceInfo = "Goldie Baronbottom, Cinderbrew Meadery",
              canBattle = true, zone = "Cinderbrew Meadery", dropInfo = { mob = "Goldie Baronbottom", zone = "Cinderbrew Meadery", boss = true }, score = T.medium },
            { speciesID = 4759, itemID = 236768, npcID = 238393, name = "Craboom",             petType = 9, source = "drop", sourceInfo = "Swampface, Operation: Floodgate",
              canBattle = true, zone = "Operation: Floodgate", dropInfo = { mob = "Swampface", zone = "Operation: Floodgate", boss = true }, score = T.medium },
            { speciesID = 4726, itemID = 234379, npcID = 235124, name = "Crackleroar",         petType = 8, source = "drop", sourceInfo = "Stormtouched Pridetalon, Siren Isle",
              canBattle = true, zone = "Siren Isle", dropInfo = { mob = "Stormtouched Pridetalon", zone = "Siren Isle" }, score = T.medium },
            { speciesID = 4834, itemID = 244915, npcID = 245481, name = "Jimmy",               petType = 8, source = "drop", sourceInfo = "Morgil the Netherspawn, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Morgil the Netherspawn", zone = "K'aresh" }, score = T.medium },
            { speciesID = 4838, itemID = 245214, npcID = 245496, name = "Palek'ti, the Mouth of Nothingness", petType = 8, source = "drop", sourceInfo = "Malek'ta, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Malek'ta", zone = "K'aresh" }, score = T.medium },
            { speciesID = 4842, itemID = 245254, npcID = 245500, name = "Duskthief",           petType = 3, source = "drop", sourceInfo = "The Nightreaver, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "The Nightreaver", zone = "K'aresh" }, score = T.medium },
            { speciesID = 4846, itemID = 245272, npcID = 245504, name = "Heka'Tarnos, Bringer of Discord", petType = 5, source = "drop", sourceInfo = "Heka'tamos, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Heka'tamos", zone = "K'aresh" }, score = T.medium },

            -- Undermine activity and container drops
            { speciesID = 4636, itemID = 232852, npcID = 231464, name = "Mutt",                petType = 8, source = "drop", sourceInfo = "Shipping and Handling crates, Undermine",
              canBattle = true, zone = "Undermine", dropInfo = { mob = "Shipping and Handling", zone = "Undermine" } },
            { speciesID = 4646, itemID = 232847, npcID = 231463, name = "Personal-Use Sapper", petType = 10, source = "drop", sourceInfo = "Shipping and Handling crates, Undermine",
              canBattle = true, zone = "Undermine", dropInfo = { mob = "Shipping and Handling", zone = "Undermine" } },
            { speciesID = 4639, itemID = 232838, npcID = 231456, name = "Viridian Mechasaur",  petType = 10, source = "drop", sourceInfo = "Sifted Pile of Scrap, Undermine",
              canBattle = true, zone = "Undermine", dropInfo = { mob = "Sifted Pile of Scrap", zone = "Undermine" } },
            { speciesID = 4755, itemID = 235909, npcID = 237976, name = "Gleam",               petType = 7, source = "drop", sourceInfo = "Gallagio Garbage, Undermine",
              canBattle = true, zone = "Undermine", dropInfo = { mob = "Gallagio Garbage", zone = "Undermine" } },

            -- K'aresh Vibrating Box drops
            { speciesID = 4825, itemID = 244467, npcID = 245215, name = "Veridian Thorntail",  petType = 5, source = "drop", sourceInfo = "Vibrating Box, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Vibrating Box", zone = "K'aresh" } },
            { speciesID = 4826, itemID = 244468, npcID = 245217, name = "Scrappy Thorntail",   petType = 5, source = "drop", sourceInfo = "Vibrating Box, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Vibrating Box", zone = "K'aresh" } },
            { speciesID = 4827, itemID = 244907, npcID = 245474, name = "Dread Horrorling",    petType = 6, source = "drop", sourceInfo = "Vibrating Box, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Vibrating Box", zone = "K'aresh" } },
            { speciesID = 4828, itemID = 244909, npcID = 245475, name = "Impartial Watcher",   petType = 6, source = "drop", sourceInfo = "Vibrating Box, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Vibrating Box", zone = "K'aresh" } },
            { speciesID = 4833, itemID = 244914, npcID = 245480, name = "Xanthous Siphonmite", petType = 8, source = "drop", sourceInfo = "Vibrating Box, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Vibrating Box", zone = "K'aresh" } },
            { speciesID = 4835, itemID = 244916, npcID = 245482, name = "Cyan Siphonmite",     petType = 8, source = "drop", sourceInfo = "Vibrating Box, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Vibrating Box", zone = "K'aresh" } },
            { speciesID = 4836, itemID = 245212, npcID = 245494, name = "Vitriolic Inchshifter", petType = 8, source = "drop", sourceInfo = "Vibrating Box, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Vibrating Box", zone = "K'aresh" } },
            { speciesID = 4839, itemID = 245215, npcID = 245497, name = "Shimmering Inchshifter", petType = 8, source = "drop", sourceInfo = "Vibrating Box, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Vibrating Box", zone = "K'aresh" } },
            { speciesID = 4840, itemID = 245252, npcID = 245498, name = "Graceful Cosmic Ray Pup", petType = 3, source = "drop", sourceInfo = "Vibrating Box, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Vibrating Box", zone = "K'aresh" } },
            { speciesID = 4844, itemID = 245253, npcID = 245502, name = "Inquisitive Cosmic Ray Pup", petType = 3, source = "drop", sourceInfo = "Vibrating Box, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Vibrating Box", zone = "K'aresh" } },
            { speciesID = 4847, itemID = 245273, npcID = 245505, name = "Copper Lapbug",       petType = 5, source = "drop", sourceInfo = "Vibrating Box, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Vibrating Box", zone = "K'aresh" } },
            { speciesID = 4848, itemID = 245274, npcID = 245506, name = "Cerulean Lapbug",     petType = 5, source = "drop", sourceInfo = "Vibrating Box, K'aresh",
              canBattle = true, zone = "K'aresh", dropInfo = { mob = "Vibrating Box", zone = "K'aresh" } },

            -- Summon-item pets whose exact source the ID inventory does not
            -- record yet — all flagged for a later enrichment pass.
            { speciesID = 4458, itemID = 221195, npcID = 222069, name = "Illskitter",          petType = 8, source = "drop", sourceInfo = "Drop (source mob not yet documented)",
              canBattle = true },
            { speciesID = 4459, itemID = 221492, npcID = 222081, name = "Moss Skipper",        petType = 9, source = "drop", sourceInfo = "Source not yet documented",
              canBattle = true },
            { speciesID = 4493, itemID = 221493, npcID = 222080, name = "Redthroat Skipling",  petType = 9, source = "drop", sourceInfo = "Source not yet documented",
              canBattle = true },
            { speciesID = 4474, itemID = 222969, npcID = 222340, name = "Anub'Rekyute",        petType = 4, source = "drop", sourceInfo = "Source not yet documented",
              canBattle = true, zone = "Azj-Kahet" },
            { speciesID = 4512, itemID = 221759, npcID = 222609, name = "Sceaduthax",          petType = 3, source = "drop", sourceInfo = "Source not yet documented",
              canBattle = true },
            { speciesID = 4519, itemID = 221764, npcID = 222714, name = "Burntram",            petType = 7, source = "drop", sourceInfo = "Source not yet documented",
              canBattle = true },
            { speciesID = 4545, itemID = 222979, npcID = 223087, name = "Clay Stonecharger",   petType = 8, source = "drop", sourceInfo = "Source not yet documented",
              canBattle = true },
            { speciesID = 4633, itemID = 232856, npcID = 231467, name = "Scruff",              petType = 8, source = "drop", sourceInfo = "Source not yet documented",
              canBattle = true, zone = "Undermine" },
            { speciesID = 4634, itemID = 232854, npcID = 231465, name = "Grinner",             petType = 8, source = "drop", sourceInfo = "Source not yet documented",
              canBattle = true, zone = "Undermine" },
            { speciesID = 4709, itemID = 233057, npcID = 234366, name = "Rock Hound Mica",     petType = 8, source = "drop", sourceInfo = "Siren Isle - source not yet documented",
              canBattle = true, zone = "Siren Isle" },
            { speciesID = 4725, npcID = 234908, name = "Titan Orb",                            petType = 10, source = "drop", sourceInfo = "Siren Isle - source not yet documented",
              canBattle = true, zone = "Siren Isle" },
            { speciesID = 4813, itemID = 243158, npcID = 244263, name = "Ixthal the Observling", petType = 6, source = "drop", sourceInfo = "K'aresh - source not yet documented",
              canBattle = true, zone = "K'aresh" },
            -- Journal name looks like an internal record ("- Orange" suffix);
            -- kept because it is guide-joined and live, but verify in-game.
            { speciesID = 4824, itemID = 244464, npcID = 245204, name = "Baby Karesh Fox - Orange", petType = 5, source = "drop", sourceInfo = "K'aresh - source not yet documented",
              canBattle = true, zone = "K'aresh" },
            { speciesID = 4830, itemID = 244911, npcID = 245477, name = "Rhay'Dahr",           petType = 6, source = "drop", sourceInfo = "K'aresh - source not yet documented",
              canBattle = true, zone = "K'aresh" },
        },
    },

    -- Quest pets. 8 entries.
    {
        source = "quest",
        pets = {
            { speciesID = 4462, itemID = 220782, npcID = 222203, name = "Thunder",             petType = 8, source = "quest", sourceInfo = "Quest: Tale of Tails",
              canBattle = true, zone = "Hallowfall" },
            { speciesID = 4465, itemID = 221849, npcID = 222201, name = "Vanilla",             petType = 8, source = "quest", sourceInfo = "Quest: Save Tomothy",
              canBattle = true, zone = "Hallowfall" },
            { speciesID = 4520, itemID = 222964, npcID = 222717, name = "Fathom Incher",       petType = 9, source = "quest", sourceInfo = "Quest: Return to the Sea",
              canBattle = true, zone = "Hallowfall" },
            { speciesID = 4542, itemID = 222980, npcID = 223138, name = "Slim",                petType = 9, source = "quest", sourceInfo = "Quest: Grand, Gutsy Solutions",
              canBattle = true, zone = "Azj-Kahet" },
            { speciesID = 4570, itemID = 223625, npcID = 223351, name = "Cinderwold Sizzlestinger", petType = 7, source = "quest", sourceInfo = "Quest: Home Is Where the Candle Is",
              canBattle = true, zone = "The Ringing Deeps" },
            { speciesID = 4582, itemID = 223803, npcID = 223861, name = "Rak-Ush Battleshell", petType = 8, source = "quest", sourceInfo = "Quest: Permanent Hire",
              canBattle = true, zone = "Azj-Kahet" },
            { speciesID = 4642, itemID = 232843, npcID = 231451, name = "Mega-Mecha Gorilla",  petType = 10, source = "quest", sourceInfo = "Quest: Mega-Mecha Gorilla",
              canBattle = true, zone = "Undermine" },
            { speciesID = 4701, itemID = 232895, npcID = 234071, name = "Spotty",              petType = 5, source = "quest", sourceInfo = "Quest: Unsolicited Feedback",
              canBattle = true, zone = "Undermine" },
        },
    },

    -- Treasure pets. 18 entries.
    {
        source = "treasure",
        pets = {
            { speciesID = 3362, itemID = 224579, npcID = 192365, name = "Sapphire Crab",      petType = 8, source = "treasure", sourceInfo = "Magical Treasure Chest (Lionel), Isle of Dorn",
              canBattle = true, zone = "Isle of Dorn" },
            { speciesID = 4470, itemID = 224439, npcID = 222319, name = "Oop'lajax",           petType = 9, source = "treasure", sourceInfo = "Scary Dark Chest, The Ringing Deeps",
              canBattle = true, zone = "The Ringing Deeps" },
            { speciesID = 4472, itemID = 221819, npcID = 222326, name = "Shadowbog Hopper",    petType = 9, source = "treasure", sourceInfo = "Shadowrooted Vine, Hallowfall",
              canBattle = true, zone = "Hallowfall" },
            { speciesID = 4473, itemID = 222966, npcID = 222339, name = "Spinner",             petType = 4, source = "treasure", sourceInfo = "Trapped Trove, City of Threads",
              canBattle = true, zone = "City of Threads" },
            { speciesID = 4513, itemID = 221760, npcID = 222606, name = "Pillarnest Bonedrinker", petType = 3, source = "treasure", sourceInfo = "Nest Egg, Azj-Kahet",
              canBattle = true, zone = "Azj-Kahet" },
            { speciesID = 4527, itemID = 224450, npcID = 222782, name = "Lil' Moss Rosy",      petType = 5, source = "treasure", sourceInfo = "Mosswool Flower, Isle of Dorn",
              canBattle = true, zone = "Isle of Dorn" },
            { speciesID = 4534, itemID = 221546, npcID = 222880, name = "Nightfarm Growthling", petType = 7, source = "treasure", sourceInfo = "Nightfarm Growthling treasure, Hallowfall",
              canBattle = true, zone = "Hallowfall" },
            { speciesID = 4536, itemID = 221548, npcID = 222879, name = "Blightbud",           petType = 7, source = "treasure", sourceInfo = "Dislodged Blockage, The Ringing Deeps",
              canBattle = true, zone = "The Ringing Deeps" },
            { speciesID = 4594, itemID = 224549, npcID = 225238, name = "Dalaran Sewer Turtle", petType = 9, source = "treasure", sourceInfo = "Dalaran wreckage, Isle of Dorn",
              canBattle = true, zone = "Isle of Dorn" },
            { speciesID = 4596, itemID = 224766, npcID = 225537, name = "Faithful Dog",        petType = 8, source = "treasure", sourceInfo = "Half-Buried Dog Bowl, Isle of Dorn",
              canBattle = false, zone = "Isle of Dorn" },
            { speciesID = 4599, itemID = 225544, npcID = 226125, name = "Mind Slurp",          petType = 6, source = "treasure", sourceInfo = "Memory Cache, Azj-Kahet",
              canBattle = true, zone = "Azj-Kahet" },
            { speciesID = 4708, itemID = 233056, npcID = 234365, name = "Marmaduke",           petType = 8, source = "treasure", sourceInfo = "Discovery: Siren Isle",
              canBattle = true, zone = "Siren Isle", score = T.medium },
            { speciesID = 4845, itemID = 245269, npcID = 245503, name = "Mr. Long-Legs",       petType = 5, source = "treasure", sourceInfo = "Ancient Coffer, K'aresh",
              canBattle = true, zone = "K'aresh" },

            -- Horrific Visions Revisited corrupted chests (11.1.5)
            { speciesID = 4747, itemID = 235794, npcID = 237850, name = "Eye of Chaos",        petType = 6, source = "treasure", sourceInfo = "Valeera's Corrupted Chest, Vision of Stormwind (Revisited)",
              canBattle = true, zone = "Vision of Stormwind", score = T.medium },
            { speciesID = 4748, itemID = 235793, npcID = 237852, name = "Void-Scarred Parrot", petType = 3, source = "treasure", sourceInfo = "Wyrmbane's Corrupted Chest, Vision of Stormwind (Revisited)",
              canBattle = true, zone = "Vision of Stormwind", score = T.medium },
            { speciesID = 4749, itemID = 235795, npcID = 237855, name = "Void-Scarred Scorpid", petType = 8, source = "treasure", sourceInfo = "Garona's Corrupted Chest, Vision of Orgrimmar (Revisited)",
              canBattle = true, zone = "Vision of Orgrimmar", score = T.medium },
            { speciesID = 4750, itemID = 235797, npcID = 237856, name = "Void-Scarred Tallstrider Chick", petType = 3, source = "treasure", sourceInfo = "Geya'rah's Corrupted Chest, Vision of Orgrimmar (Revisited)",
              canBattle = true, zone = "Vision of Orgrimmar", score = T.medium },

            -- Tazavesh secret — Wowhead still lists the source as unknown.
            { speciesID = 4860, itemID = 246723, npcID = 247465, name = "Unfazed Diver",       petType = 8, source = "treasure", sourceInfo = "Tazavesh, the Veiled Market - secret (source not yet documented)",
              canBattle = true, zone = "Tazavesh, the Veiled Market" },
        },
    },

    -- Achievement pets. 7 entries.
    {
        source = "achievement",
        pets = {
            { speciesID = 4517, itemID = 221821, npcID = 222711, name = "Waxwick",             petType = 7, source = "achievement", sourceInfo = "Khaz Algar Safari",
              canBattle = true, achievementID = 40194, score = T.long },
            { speciesID = 4500, itemID = 225934, npcID = 222583, name = "Lil' Bonechewer",     petType = 5, source = "achievement", sourceInfo = "Worm Theory - Rak-Ush, Azj-Kahet",
              canBattle = true, zone = "Azj-Kahet", achievementID = 40869, taskList = WORM_THEORY_TASKS, score = T.medium },
            { speciesID = 4490, itemID = 222970, npcID = 222574, name = "Fuzzy",               petType = 8, source = "achievement", sourceInfo = "Family Battler of Khaz Algar",
              canBattle = true, achievementID = 40980, score = T.long },
            { speciesID = 4581, itemID = 223802, npcID = 223859, name = "Ruby-Eyed Stagshell", petType = 8, source = "achievement", sourceInfo = "A Champion's Tour: The War Within (world PvP world quests)",
              canBattle = true, achievementID = 40088, score = T.long },
            { speciesID = 4631, itemID = 232855, npcID = 231469, name = "Foreman",             petType = 8, source = "achievement", sourceInfo = "Family Battler of Undermine", zone = "Undermine",
              canBattle = true, achievementID = 41551, score = T.long },
            { speciesID = 4664, itemID = 232807, npcID = 231621, name = "Iron Chick",          petType = 10, source = "achievement", sourceInfo = "In with the Cartels (Honored with all four Undermine cartels)",
              canBattle = true, zone = "Undermine", achievementID = 41349, taskList = IN_WITH_THE_CARTELS_TASKS, score = T.long },
            { speciesID = 4841, itemID = 245255, npcID = 245499, name = "Starlight",           petType = 3, source = "achievement", sourceInfo = "Bounty Seeker - complete 4 Warrants in K'aresh",
              canBattle = true, zone = "K'aresh", achievementID = 41979, score = T.medium },
        },
    },

    -- Delve pets (Heavy Trunk / bountiful chest drops). 7 entries.
    {
        source = "delve",
        pets = {
            { speciesID = 4489, itemID = 222971, npcID = 222532, name = "Bouncer",             petType = 8, source = "delve", sourceInfo = "Nerubian Delve's Heavy Trunk",
              canBattle = true, score = T.medium },
            { speciesID = 4496, itemID = 221496, npcID = 222078, name = "Wriggle",             petType = 9, source = "delve", sourceInfo = "Kobyss Delve's Heavy Trunk",
              canBattle = true, score = T.medium },
            { speciesID = 4506, itemID = 225337, npcID = 222590, name = "Violet Sporbit",      petType = 6, source = "delve", sourceInfo = "Fungarian Delve's Heavy Trunk",
              canBattle = true, score = T.medium },
            { speciesID = 4537, itemID = 221820, npcID = 222883, name = "Chester",             petType = 1, source = "delve", sourceInfo = "Delve's Bountiful Coffer and Hidden Trove",
              canBattle = true, score = T.medium },
            { speciesID = 4575, itemID = 223624, npcID = 223718, name = "Sneef",               petType = 8, source = "delve", sourceInfo = "Kobold Delve's Heavy Trunk",
              canBattle = true, score = T.medium },
            { speciesID = 4647, itemID = 232848, npcID = 231462, name = "Mr. DELVER",          petType = 10, source = "delve", sourceInfo = "Goblin Delve's Heavy Trunk",
              canBattle = true, score = T.medium },
            { speciesID = 4843, itemID = 245256, npcID = 245501, name = "Sao'rhon",            petType = 3, source = "delve", sourceInfo = "Ethereal Delve's Heavy Trunk",
              canBattle = true, score = T.medium },
        },
    },

    -- Profession pets. 2 entries.
    {
        source = "profession",
        pets = {
            { speciesID = 4467, itemID = 220771, npcID = 222298, name = "Hallowed Glowfly",    petType = 3, source = "profession", sourceInfo = "Gathered from Hallowfall Sparkflies",
              canBattle = true, zone = "Hallowfall" },
            { speciesID = 4482, itemID = 223487, npcID = 222359, name = "Writhing Transmutagen", petType = 6, source = "profession", sourceInfo = "Alchemy - Khaz Algar Thaumaturgy discovery",
              canBattle = true, score = T.medium },
        },
    },

    -- Event pets: holidays, anniversary, Timewalking, Remix, Plunderstorm.
    -- All in-game events (store/promo rows are excluded by catalog policy).
    -- 25 entries.
    {
        source = "event",
        pets = {
            -- Children's Week (TWW-added orphan reward pets)
            { speciesID = 3245, itemID = 241193, npcID = 185425, name = "Helpful Workshop Bot", petType = 10, source = "event", sourceInfo = "Children's Week",
              canBattle = true, score = T.medium },
            { speciesID = 4466, itemID = 221851, npcID = 222204, name = "Argos",               petType = 8, source = "event", sourceInfo = "Children's Week",
              canBattle = true, score = T.medium },
            { speciesID = 4635, itemID = 232857, npcID = 231466, name = "Goggles",             petType = 8, source = "event", sourceInfo = "Children's Week",
              canBattle = true, score = T.medium },

            -- WoW's 20th Anniversary (11.0.5)
            { speciesID = 4614, itemID = 228740, npcID = 229779, name = "Gizmo the Pure",      petType = 5, source = "event", sourceInfo = "WoW's 20th Anniversary event", zone = "Tanaris",
              canBattle = true, score = T.medium },
            { speciesID = 4450, itemID = 218086, npcID = 220420, name = "Remembered Riverpaw", petType = 6, source = "event", sourceInfo = "Remembrancer Amuul (Dalaran) or Memory of a Duke (Searing Gorge) - 10,000 Residual Memories", zone = "Dalaran",
              canBattle = true, cost = { currency = { MC.CURRENCY.ResidualMemories, 10000 } }, score = T.medium },
            { speciesID = 4451, itemID = 218245, npcID = 220675, name = "Remembered Construct", petType = 6, source = "event", sourceInfo = "Remembrancer Amuul (Dalaran) or Echo of the Silver Hand (Dragonblight) - 10,000 Residual Memories", zone = "Dalaran",
              canBattle = true, cost = { currency = { MC.CURRENCY.ResidualMemories, 10000 } }, score = T.medium },
            { speciesID = 4452, itemID = 218246, npcID = 220680, name = "Remembered Spawn",    petType = 6, source = "event", sourceInfo = "Remembrancer Amuul (Dalaran) or Forgotten Hero (Dustwallow Marsh) - 10,000 Residual Memories", zone = "Dalaran",
              canBattle = true, cost = { currency = { MC.CURRENCY.ResidualMemories, 10000 } }, score = T.medium },
            { speciesID = 4678, itemID = 228781, npcID = 231840, name = "Lil'Doomy",           petType = 1, source = "event", sourceInfo = "Historian Ma'di (Tanaris) - 10 Bronze Celebration Tokens",
              canBattle = true, zone = "Tanaris", cost = { currency = { 3100, 10 } }, score = T.medium },
            { speciesID = 4679, itemID = 230011, npcID = 231841, name = "Lil'Kaz",             petType = 1, source = "event", sourceInfo = "Lord Kazzak (Blasted Lands) during the anniversary event",
              canBattle = true, zone = "Blasted Lands", dropInfo = { mob = "Lord Kazzak", zone = "Blasted Lands", boss = true }, score = T.long },

            -- Timewalking vendors (2,200 Timewarped Badges each)
            { speciesID = 4592, itemID = 224406, npcID = 224915, name = "Misty",               petType = 8, source = "event", sourceInfo = "Bobadormu / Grannadormu (Tanaris) - 2,200 Timewarped Badges",
              canBattle = true, zone = "Tanaris", cost = { currency = { MC.CURRENCY.TimewarpedBadges, 2200 } }, score = T.medium },
            { speciesID = 4593, itemID = 224410, npcID = 224916, name = "Craggles",            petType = 8, source = "event", sourceInfo = "Bobadormu / Grannadormu (Tanaris) - 2,200 Timewarped Badges",
              canBattle = true, zone = "Tanaris", cost = { currency = { MC.CURRENCY.TimewarpedBadges, 2200 } }, score = T.medium },
            { speciesID = 4686, itemID = 231356, npcID = 232579, name = "Specter",             petType = 8, source = "event", sourceInfo = "Auzin (Dalaran, WotLK Timewalking) - 2,200 Timewarped Badges",
              canBattle = true, zone = "Dalaran", cost = { currency = { MC.CURRENCY.TimewarpedBadges, 2200 } }, score = T.medium },
            { speciesID = 4689, itemID = 231365, npcID = 232585, name = "Karazhan Syphoner",   petType = 6, source = "event", sourceInfo = "Cupri (Shattrath City, TBC Timewalking) - 2,200 Timewarped Badges",
              canBattle = true, zone = "Shattrath City", cost = { currency = { MC.CURRENCY.TimewarpedBadges, 2200 } }, score = T.medium },
            { speciesID = 4911, itemID = 254876, npcID = 253374, name = "P.O.S.T. Assistant",  petType = 6, source = "event", sourceInfo = "Collector Ta'steld (Oribos, Shadowlands Timewalking) - 2,200 Timewarped Badges",
              canBattle = true, zone = "Oribos", cost = { currency = { MC.CURRENCY.TimewarpedBadges, 2200 } }, score = T.medium },
            -- BfA Timewalking vendor Churbro — cost not in the ID inventory.
            { speciesID = 4849, itemID = 245543, npcID = 245545, name = "Flotsam Harvester",   petType = 10, source = "event", sourceInfo = "Churbro (Zuldazar / Boralus Harbor, BfA Timewalking) - cost undocumented", zone = "Zuldazar",
              canBattle = true, score = T.medium },
            { speciesID = 4852, itemID = 245574, npcID = 245647, name = "Lil' Daz'ti",         petType = 8, source = "event", sourceInfo = "Churbro (Zuldazar / Boralus Harbor, BfA Timewalking) - cost undocumented", zone = "Zuldazar",
              canBattle = true, score = T.medium },

            -- WoW Remix: Legion
            { speciesID = 4801, itemID = 239699, npcID = 242176, name = "Tidbit",              petType = 5, source = "event", sourceInfo = "WoW Remix: Legion",
              canBattle = true, score = T.medium },
            { speciesID = 4802, itemID = 239705, npcID = 242180, name = "Morsel",              petType = 5, source = "event", sourceInfo = "WoW Remix: Legion",
              canBattle = true, score = T.medium },
            { speciesID = 4901, itemID = 252301, npcID = 251889, name = "Fledgling Warden's Companion", petType = 3, source = "event", sourceInfo = "WoW Remix: Legion", zone = "Azsuna",
              canBattle = true, score = T.medium },

            -- Holiday events
            { speciesID = 4691, itemID = 232531, npcID = 233564, name = "Grunch",              petType = 8, source = "event", sourceInfo = "Feast of Winter Veil - quest: You're A Mean One...",
              canBattle = true, score = T.medium },
            { speciesID = 4694, itemID = 232653, npcID = 233965, name = "Portentous Present",  petType = 6, source = "event", sourceInfo = "Feast of Winter Veil",
              canBattle = true, score = T.medium },
            { speciesID = 4851, itemID = 245544, npcID = 245616, name = "Tiny Snow Buddy",     petType = 7, source = "event", sourceInfo = "Feast of Winter Veil", zone = "Orgrimmar",
              canBattle = true, score = T.medium },
            { speciesID = 4704, itemID = 232923, npcID = 234131, name = "Living Rose",         petType = 7, source = "event", sourceInfo = "Love is in the Air - 40 Love Tokens",
              canBattle = true, cost = { item = { 49927, 40 } }, score = T.medium },

            -- Plunderstorm
            { speciesID = 4692, itemID = 233247, npcID = 233797, name = "Sparklesnap",         petType = 9, source = "event", sourceInfo = "Plunderstorm special event",
              canBattle = true, score = T.medium },
            { speciesID = 4695, itemID = 235988, npcID = 233967, name = "Parley",              petType = 3, source = "event", sourceInfo = "Plunderstorm special event",
              canBattle = true, score = T.medium },
        },
    },
})
