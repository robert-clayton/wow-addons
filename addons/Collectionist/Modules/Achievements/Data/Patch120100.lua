local _, MC = ...

local M = MC.MAP

-- Patch 12.1 (The Curse of Ula'tek), released August 11, 2026.
MC.RegisterContent("midnight", "achievements", {
    --------------------------------------------------------------------
    -- The Coiled Isle campaign and optional stories.
    --------------------------------------------------------------------
    {
        category = "quests",
        source = "metas",
        achievements = {
            {
                achievementID = 62297,
                name          = "The Curse of Ula'tek",
                zone          = "Zul'Aman + Coiled Isle",
                description   = "Complete the six storylines spanning Zul'Aman and the Coiled Isle.",
                taskList = {
                    intro = "Complete the five Zul'jan chapters, then The Call of the Void on the Coiled Isle.",
                    tasks = {
                        { achievementID = 62297, criteriaIndex = 1, label = "Legacy of the Amani" },
                        { achievementID = 62297, criteriaIndex = 2, label = "An Island of Fangs" },
                        { achievementID = 62297, criteriaIndex = 3, label = "Ghosts of the Past" },
                        { achievementID = 62297, criteriaIndex = 4, label = "Original Sin" },
                        { achievementID = 62297, criteriaIndex = 5, label = "The Battle for Atal'Utek" },
                        { achievementID = 62297, criteriaIndex = 6, label = "The Call of the Void" },
                    },
                },
            },
            {
                achievementID = 63641,
                name          = "Snake Charmed, I'm Sure",
                zone          = "Coiled Isle",
                description   = "Complete all 11 optional Coiled Isle storylines.",
                taskList = {
                    intro = "Optional storylines open around the island as the main campaign advances.",
                    tasks = {
                        { achievementID = 63641, criteriaIndex = 1, label = "Strange Friends in Odd Places" },
                        { achievementID = 63641, criteriaIndex = 2, label = "Tokka's Crew" },
                        { achievementID = 63641, criteriaIndex = 3, label = "Ancient Anthropology" },
                        { achievementID = 63641, criteriaIndex = 4, label = "Bone Deep" },
                        { achievementID = 63641, criteriaIndex = 5, label = "The Honored Med'jai" },
                        { achievementID = 63641, criteriaIndex = 6, label = "Don't be Afrayed" },
                        { achievementID = 63641, criteriaIndex = 7, label = "A Bond of Brothers" },
                        { achievementID = 63641, criteriaIndex = 8, label = "The Troubles of Mlurkkr Mire" },
                        { achievementID = 63641, criteriaIndex = 9, label = "Somethin' Bad Inside" },
                        { achievementID = 63641, criteriaIndex = 10, label = "Living Legend" },
                        { achievementID = 63641, criteriaIndex = 11, label = "The Monster's Mother" },
                    },
                },
            },
            { achievementID = 63633, name = "A Stack of Snacks", zone = "Coiled Isle",
              description = "Feed Ki'clak 5 snacks by completing the Ki'clak Snack Attack World Quest five times.",
              waypoint = { M.CoiledIsle, 0.6930, 0.5230, "Ki'clak Snack Attack" } },
        },
    },
    {
        category = "exploration",
        source = "explore",
        achievements = {
            { achievementID = 63640, name = "Explore the Coiled Isle", zone = "Coiled Isle",
              description = "Explore the Coiled Isle and reveal every covered area of its map." },
        },
    },
    {
        category = "exploration",
        source = "glyphs",
        achievements = {
            {
                achievementID = 63395,
                name          = "The Coiled Isles Glyph Hunter",
                zone          = "Coiled Isle",
                description   = "Collect all 11 Skyriding Glyphs on the Coiled Isle.",
                taskList = {
                    intro = "Fly through each glyph; every task links to its individual achievement and exact location.",
                    tasks = {
                        { achievementID = 63394, label = "The Fangs", waypoint = { M.CoiledIsle, 0.3740, 0.6050, "The Fangs glyph" } },
                        { achievementID = 63420, label = "The Forum", waypoint = { M.CoiledIsle, 0.2660, 0.6310, "The Forum glyph" } },
                        { achievementID = 63421, label = "The Wreck of Sethralis's Scales", waypoint = { M.CoiledIsle, 0.2880, 0.7520, "Sethralis's Scales glyph" } },
                        { achievementID = 63422, label = "Southern Island", waypoint = { M.CoiledIsle, 0.4060, 0.9050, "Southern Island glyph" } },
                        { achievementID = 63423, label = "Gate of the Eastern Fang", waypoint = { M.CoiledIsle, 0.4590, 0.6490, "Eastern Fang glyph" } },
                        { achievementID = 63424, label = "Tokka's Landing", waypoint = { M.CoiledIsle, 0.5890, 0.4890, "Tokka's Landing glyph" } },
                        { achievementID = 63425, label = "The Whispering Marsh", waypoint = { M.CoiledIsle, 0.6410, 0.6070, "Whispering Marsh glyph" } },
                        { achievementID = 63426, label = "The Wreck of Paku's Talon", waypoint = { M.CoiledIsle, 0.7030, 0.4820, "Paku's Talon glyph" } },
                        { achievementID = 63427, label = "The Serpent's Tail", waypoint = { M.CoiledIsle, 0.5200, 0.3840, "Serpent's Tail glyph" } },
                        { achievementID = 63428, label = "Blistering Terrace", waypoint = { M.CoiledIsle, 0.4290, 0.3060, "Blistering Terrace glyph" } },
                        { achievementID = 63430, label = "Gate of the Serpent's Eye", waypoint = { M.CoiledIsle, 0.4380, 0.4420, "Serpent's Eye glyph" } },
                    },
                },
            },
            { achievementID = 63394, name = "Skyriding Glyphs: The Fangs", zone = "Coiled Isle", description = "Collect the Skyriding Glyph at The Fangs.", waypoint = { M.CoiledIsle, 0.3740, 0.6050, "The Fangs glyph" } },
            { achievementID = 63420, name = "Skyriding Glyphs: The Forum", zone = "Coiled Isle", description = "Collect the Skyriding Glyph at The Forum.", waypoint = { M.CoiledIsle, 0.2660, 0.6310, "The Forum glyph" } },
            { achievementID = 63421, name = "Skyriding Glyphs: The Wreck of Sethralis's Scales", zone = "Coiled Isle", description = "Collect the Skyriding Glyph at the wreck of Sethralis's Scales.", waypoint = { M.CoiledIsle, 0.2880, 0.7520, "Sethralis's Scales glyph" } },
            { achievementID = 63422, name = "Skyriding Glyphs: Southern Island", zone = "Coiled Isle", description = "Collect the Skyriding Glyph at the Southern Island.", waypoint = { M.CoiledIsle, 0.4060, 0.9050, "Southern Island glyph" } },
            { achievementID = 63423, name = "Skyriding Glyphs: Gate of the Eastern Fang", zone = "Coiled Isle", description = "Collect the Skyriding Glyph at the Gate of the Eastern Fang.", waypoint = { M.CoiledIsle, 0.4590, 0.6490, "Eastern Fang glyph" } },
            { achievementID = 63424, name = "Skyriding Glyphs: Tokka's Landing", zone = "Coiled Isle", description = "Collect the Skyriding Glyph at Tokka's Landing.", waypoint = { M.CoiledIsle, 0.5890, 0.4890, "Tokka's Landing glyph" } },
            { achievementID = 63425, name = "Skyriding Glyphs: The Whispering Marsh", zone = "Coiled Isle", description = "Collect the Skyriding Glyph at The Whispering Marsh.", waypoint = { M.CoiledIsle, 0.6410, 0.6070, "Whispering Marsh glyph" } },
            { achievementID = 63426, name = "Skyriding Glyphs: The Wreck of Paku's Talon", zone = "Coiled Isle", description = "Collect the Skyriding Glyph at the wreck of Paku's Talon.", waypoint = { M.CoiledIsle, 0.7030, 0.4820, "Paku's Talon glyph" } },
            { achievementID = 63427, name = "Skyriding Glyphs: The Serpent's Tail", zone = "Coiled Isle", description = "Collect the Skyriding Glyph at The Serpent's Tail.", waypoint = { M.CoiledIsle, 0.5200, 0.3840, "Serpent's Tail glyph" } },
            { achievementID = 63428, name = "Skyriding Glyphs: Blistering Terrace", zone = "Coiled Isle", description = "Collect the Skyriding Glyph at Blistering Terrace.", waypoint = { M.CoiledIsle, 0.4290, 0.3060, "Blistering Terrace glyph" } },
            { achievementID = 63430, name = "Skyriding Glyphs: Gate of the Serpent's Eye", zone = "Coiled Isle", description = "Collect the Skyriding Glyph at the Gate of the Serpent's Eye.", waypoint = { M.CoiledIsle, 0.4380, 0.4420, "Serpent's Eye glyph" } },
        },
    },
    {
        category = "exploration",
        source = "lore",
        achievements = {
            { achievementID = 63662, name = "Student of Hissstory", zone = "Coiled Isle",
              description = "Discover all lore objects on the Coiled Isle. The Treasures tab tracks their locations." },
        },
    },
    {
        category = "exploration",
        source = "zone",
        achievements = {
            {
                achievementID = 63639,
                name          = "Ula'tek Uncoiled",
                zone          = "Coiled Isle",
                description   = "Complete the primary Coiled Isle exploration meta.",
                taskList = {
                    intro = "Finish the campaign, rares, treasures, and map exploration achievements.",
                    tasks = {
                        { achievementID = 62297, label = "The Curse of Ula'tek" },
                        { achievementID = 63358, label = "Coiled to Strike" },
                        { achievementID = 63359, label = "Treasures of the Coiled Isle" },
                        { achievementID = 63640, label = "Explore the Coiled Isle" },
                    },
                },
            },
            { achievementID = 63358, name = "Coiled to Strike", zone = "Coiled Isle", description = "Defeat every rare creature on the Coiled Isle. The Rares tab tracks each target." },
            { achievementID = 63359, name = "Treasures of the Coiled Isle", zone = "Coiled Isle", description = "Discover the hidden treasures across the Coiled Isle. The Treasures tab tracks each one." },
            { achievementID = 63381, name = "Cursebreaker", zone = "Coiled Isle", description = "Defeat 300 Curse Surges on the Coiled Isle." },
            { achievementID = 63382, name = "It's Definitely Something", zone = "Coiled Isle", description = "Complete the unusual Mother of Monsters event on the Coiled Isle." },
            { achievementID = 63390, name = "Turn the Surge", zone = "Coiled Isle", description = "Defeat every type of Curse Surge on the Coiled Isle." },
            { achievementID = 63167, name = "Tour of Duty: The Coiled Isle", zone = "Coiled Isle", description = "Earn 1,000 Honor on the Coiled Isle while in War Mode." },
            {
                achievementID = 63432,
                name          = "Mysterious Mix Master",
                zone          = "Coiled Isle",
                description   = "Collect all 10 offering types from Ofi's Cauldron.",
                taskList = {
                    intro = "Collect each distinct offering produced by Ofi's Cauldron.",
                    tasks = {
                        { achievementID = 63432, criteriaID = 115810, label = "Choleric Offering" },
                        { achievementID = 63432, criteriaID = 115811, label = "Virulent Offering" },
                        { achievementID = 63432, criteriaID = 115812, label = "Volatile Offering" },
                        { achievementID = 63432, criteriaID = 115815, label = "Phlegmatic Offering" },
                        { achievementID = 63432, criteriaID = 115814, label = "Odious Offering" },
                        { achievementID = 63432, criteriaID = 115816, label = "Pestilent Offering" },
                        { achievementID = 63432, criteriaID = 115819, label = "Melancholic Offering" },
                        { achievementID = 63432, criteriaID = 115817, label = "Fragile Offering" },
                        { achievementID = 63432, criteriaID = 115818, label = "Eerie Offering" },
                        { achievementID = 63432, criteriaID = 115813, label = "Balanced Offering" },
                    },
                },
            },
        },
    },
    {
        category = "collections",
        source = "pets",
        achievements = {
            { achievementID = 62492, name = "The Coiled Isle Safari", zone = "Coiled Isle",
              description = "Collect every wild battle pet on the Coiled Isle. The Pets tab tracks all eight species." },
        },
    },

    --------------------------------------------------------------------
    -- Vaults of Atal'Utek exploration.
    --------------------------------------------------------------------
    {
        category = "exploration",
        source = "zone",
        achievements = {
            {
                achievementID = 63630,
                name          = "Assault the Vault",
                zone          = "Vaults of Atal'Utek",
                description   = "Complete every major activity achievement within the Vaults of Atal'Utek. Reward: Venomous Coiler mount.",
                taskList = {
                    intro = "Finish the repeatable activities, special events, lore, and Altar of Corrosion progression.",
                    tasks = {
                        { achievementID = 63598, label = "Roll the Patrol" },
                        { achievementID = 63600, label = "Spike the Strike" },
                        { achievementID = 63599, label = "Submerge the Incursion" },
                        { achievementID = 63601, label = "Oppose the Foes" },
                        { achievementID = 62649, label = "A Lone Wanderer" },
                        { achievementID = 62604, label = "Dance While Everyone Watches" },
                        { achievementID = 62600, label = "Ritual Behavior" },
                        { achievementID = 62601, label = "Soft Underbelly" },
                        { achievementID = 63610, label = "The Honored Dead" },
                        { achievementID = 63636, label = "Fully Corroded" },
                    },
                },
            },
            { achievementID = 62649, name = "A Lone Wanderer", zone = "Vaults of Atal'Utek", description = "Collect the large wandering Soul Globes during the Earth and Sky event." },
            { achievementID = 62604, name = "Dance While Everyone Watches", zone = "Vaults of Atal'Utek", description = "Dance while defending each stone in the Cache of Three event." },
            { achievementID = 63636, name = "Fully Corroded", zone = "Vaults of Atal'Utek", description = "Unlock every talent point at the Altar of Corrosion. Reward: the Corroded title." },
            { achievementID = 63601, name = "Oppose the Foes", zone = "Vaults of Atal'Utek", description = "Defeat every Ancient Foe within the Vaults." },
            { achievementID = 63653, name = "Pro Poison Patroller", zone = "Vaults of Atal'Utek", description = "Complete 250 patrols within the Vaults." },
            { achievementID = 62600, name = "Ritual Behavior", zone = "Vaults of Atal'Utek", description = "Deliver each of the three offering types to the Summoning Ritual event." },
            { achievementID = 63598, name = "Roll the Patrol", zone = "Vaults of Atal'Utek", description = "Complete all 12 patrol variants within the Vaults." },
            { achievementID = 63596, name = "Snake Stompin'", zone = "Vaults of Atal'Utek", description = "Stomp 1,000 Insidious Snakes within the Vaults." },
            { achievementID = 62601, name = "Soft Underbelly", zone = "Vaults of Atal'Utek", description = "Eliminate each threat inside the Underbelly." },
            { achievementID = 63600, name = "Spike the Strike", zone = "Vaults of Atal'Utek", description = "Complete every strike variant within the Vaults." },
            { achievementID = 63599, name = "Submerge the Incursion", zone = "Vaults of Atal'Utek", description = "Complete every incursion variant within the Vaults." },
            {
                achievementID = 63610,
                name          = "The Honored Dead",
                zone          = "Vaults of Atal'Utek",
                description   = "Discover all 12 Funerary Inscriptions throughout the Vaults.",
                taskList = {
                    intro = "Read every funerary inscription in the outdoor vault and its interior chambers.",
                    tasks = {
                        { achievementID = 63610, criteriaID = 116407, label = "To a daughter", waypoint = { M.VaultsOfAtalUtek, 0.4950, 0.5660, "Funerary inscription" } },
                        { achievementID = 63610, criteriaID = 116408, label = "To a lover", waypoint = { M.VaultsOfAtalUtek, 0.5220, 0.4520, "Funerary inscription" } },
                        { achievementID = 63610, criteriaID = 116409, label = "To parents" },
                        { achievementID = 63610, criteriaID = 116410, label = "To a dream", waypoint = { M.VaultsOfAtalUtek, 0.5560, 0.4060, "Funerary inscription" } },
                        { achievementID = 63610, criteriaID = 116411, label = "To a captain", waypoint = { M.VaultsOfAtalUtek, 0.5290, 0.3390, "Funerary inscription" } },
                        { achievementID = 63610, criteriaID = 116412, label = "To sons", waypoint = { M.VaultsOfAtalUtek, 0.4290, 0.4120, "Funerary inscription" } },
                        { achievementID = 63610, criteriaID = 116413, label = "To failure", waypoint = { M.VaultsOfAtalUtek, 0.4580, 0.6180, "Funerary inscription" } },
                        { achievementID = 63610, criteriaID = 116414, label = "To a father", waypoint = { M.VaultsOfAtalUtek, 0.4640, 0.2400, "Funerary inscription" } },
                        { achievementID = 63610, criteriaID = 116415, label = "To a sister", waypoint = { M.VaultsOfAtalUtek, 0.4680, 0.0760, "Funerary inscription" } },
                        { achievementID = 63610, criteriaID = 116416, label = "To comrades" },
                        { achievementID = 63610, criteriaID = 116417, label = "To a stranger", waypoint = { M.VaultsOfAtalUtek, 0.4260, 0.3310, "Funerary inscription" } },
                        { achievementID = 63610, criteriaID = 116418, label = "To a shield-bearer", waypoint = { M.VaultsOfAtalUtek, 0.5610, 0.2840, "Funerary inscription" } },
                    },
                },
            },
        },
    },

    --------------------------------------------------------------------
    -- Coiled Isle fishing progression.
    --------------------------------------------------------------------
    {
        category = "features",
        source = "professions",
        achievements = {
            {
                achievementID = 63635,
                name          = "Tokka's Terrible Trials",
                zone          = "Coiled Isle",
                description   = "Complete Captain Tokka's four fishing achievements. Reward: the Bloodsailor title.",
                taskList = {
                    intro = "Complete the fish collection, trophy ranks, reputation, and equipped-rod challenge.",
                    tasks = {
                        { achievementID = 63629, label = "Angler of The Coiled Isle" },
                        { achievementID = 63632, label = "Toxic Trophies" },
                        { achievementID = 63631, label = "Captain Tokka's Crew" },
                        { achievementID = 63634, label = "Where Did You Get That?" },
                    },
                },
            },
            {
                achievementID = 63629,
                name          = "Angler of The Coiled Isle",
                zone          = "Coiled Isle",
                description   = "Catch all 14 fish species found around the Coiled Isle.",
                taskList = {
                    intro = "Catch each species once; progression may require advancing Captain Tokka's fishing system.",
                    tasks = {
                        { achievementID = 63629, criteriaID = 116447, label = "Spotted Killifish" },
                        { achievementID = 63629, criteriaID = 116448, label = "Dirty Darter" },
                        { achievementID = 63629, criteriaID = 116449, label = "Ula'tek Snakehead" },
                        { achievementID = 63629, criteriaID = 116450, label = "Sulfurous Sludgefish" },
                        { achievementID = 63629, criteriaID = 116451, label = "Coiled Stargorger" },
                        { achievementID = 63629, criteriaID = 116452, label = "Toxic Tlhapi" },
                        { achievementID = 63629, criteriaID = 116453, label = "Polluted Puffer" },
                        { achievementID = 63629, criteriaID = 116454, label = "Blightswarmer" },
                        { achievementID = 63629, criteriaID = 116455, label = "Oozing Goby" },
                        { achievementID = 63629, criteriaID = 116456, label = "Giggling Skull" },
                        { achievementID = 63629, criteriaID = 116457, label = "Grotesque Sturgeon" },
                        { achievementID = 63629, criteriaID = 116458, label = "Many-Eyed Flounder" },
                        { achievementID = 63629, criteriaID = 116459, label = "Twin-Headed Snipefish" },
                        { achievementID = 63629, criteriaID = 116460, label = "Loathsome Anglerfish" },
                    },
                },
            },
            { achievementID = 63631, name = "Captain Tokka's Crew", zone = "Coiled Isle", description = "Reach Bloodsworn Crew reputation with Captain Tokka." },
            { achievementID = 63632, name = "Toxic Trophies", zone = "Coiled Isle", description = "Earn Trophy rank with the eight specified venomous fish." },
            {
                achievementID = 63512,
                name          = "Treasures of the Damned",
                zone          = "Coiled Isle",
                description   = "Fish up all 10 artifacts belonging to Captain Tokka's departed crewmates.",
                taskList = {
                    intro = "Recover each unique artifact while fishing around the island.",
                    tasks = {
                        { achievementID = 63512, criteriaID = 116085, label = "Bonemail Gauntlet" },
                        { achievementID = 63512, criteriaID = 116086, label = "Forgotten Amani Fishing Rod" },
                        { achievementID = 63512, criteriaID = 116087, label = "Ghostcaller's Bell" },
                        { achievementID = 63512, criteriaID = 116088, label = "Malevolent Fishing Codex" },
                        { achievementID = 63512, criteriaID = 116089, label = "Lump of Crystalline Malachite" },
                        { achievementID = 63512, criteriaID = 116090, label = "Ritual Dagger" },
                        { achievementID = 63512, criteriaID = 116091, label = "Sealed Vial of Mysterious Green Liquid" },
                        { achievementID = 63512, criteriaID = 116092, label = "Shrieking Tacklebox" },
                        { achievementID = 63512, criteriaID = 116093, label = "Spiritsurge Incense" },
                        { achievementID = 63512, criteriaID = 116094, label = "Summoning Salt" },
                    },
                },
            },
            { achievementID = 63634, name = "Where Did You Get That?", zone = "Coiled Isle", description = "Speak with Captain Tokka while The Coiled Huntress fishing rod is equipped." },
            { achievementID = 63510, name = "The Briny Best", zone = "Midnight fishing", description = "Reach 2,500 Midnight Anglin' Score in the Fishing Journal. Reward: the Briny title." },
        },
    },

    --------------------------------------------------------------------
    -- Season 2 character progression and Prey journey.
    --------------------------------------------------------------------
    {
        category = "features",
        source = "season",
        achievements = {
            { achievementID = 62410, name = "Adventurer of the Mist", zone = "Midnight Season 2", description = "Outgrow the use of Adventurer Mistcrests during Midnight Season 2." },
            { achievementID = 62411, name = "Veteran of the Mist", zone = "Midnight Season 2", description = "Outgrow the use of Veteran Mistcrests during Midnight Season 2." },
            { achievementID = 62412, name = "Champion of the Mist", zone = "Midnight Season 2", description = "Outgrow the use of Champion Mistcrests during Midnight Season 2." },
            { achievementID = 62414, name = "Hero of the Mist", zone = "Midnight Season 2", description = "Outgrow the use of Hero Mistcrests during Midnight Season 2." },
            { achievementID = 62416, name = "Myth of the Mist", zone = "Midnight Season 2", description = "Reach an average item level of 331 during Midnight Season 2." },
            { achievementID = 62871, name = "Midnight Season 2: Catalyst Unbound", zone = "Midnight Season 2", description = "Unlock your class set bonuses during Midnight Season 2.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { achievementID = 62872, name = "Midnight Season 2: Serpent Scion", zone = "Midnight Season 2", description = "Earn 1,600 PvP rating, 2,000 Mythic+ rating, or defeat Ula'tek on Heroic or Mythic difficulty.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            {
                achievementID = 63473,
                name          = "Sssensational!",
                zone          = "Midnight Season 2",
                description   = "Complete one of the season's highest-end PvE or PvP achievements. Reward: Sssensational Stone appearance unlock.",
                availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2,
                taskList = {
                    intro = "Only one of these three alternatives is required.",
                    tasks = {
                        { achievementID = 63476, label = "Mythic: Ula'tek" },
                        { achievementID = 62931, label = "Elite: Midnight Season 2" },
                        { achievementID = 62448, label = "Midnight Keystone Hero: Season 2" },
                    },
                },
            },
        },
    },
    {
        category = "features",
        source = "prey",
        achievements = {
            { achievementID = 63611, name = "Big Prey Hunter (Season 2)", zone = "Midnight (all zones)", description = "Complete the Preyhunter's Journey before Midnight Season 2 ends." },
            {
                achievementID = 63415,
                name          = "Prey: Coiled Nightmares",
                zone          = "Coiled Isle",
                description   = "Defeat all four named Coiled Isle Prey targets.",
                availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2,
                taskList = {
                    intro = "Defeat both target pairs from the Coiled Isle hunt rotation.",
                    tasks = {
                        { achievementID = 63415, criteriaIndex = 1, label = "Janoa the Fang" },
                        { achievementID = 63415, criteriaIndex = 2, label = "Kursak the Coiled" },
                        { achievementID = 63415, criteriaIndex = 3, label = "Batani the Scaled" },
                        { achievementID = 63415, criteriaIndex = 4, label = "Kadani the Claw" },
                    },
                },
            },
            { achievementID = 63416, name = "That's a Wrap", zone = "Coiled Isle", description = "Complete a Prey Hunt on the Coiled Isle." },
            { achievementID = 63451, name = "Scales for Days", zone = "Coiled Isle", description = "Defeat Batani the Scaled or Kadani the Claw on Nightmare mode.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { achievementID = 63452, name = "Fangs for the Memories", zone = "Coiled Isle", description = "Defeat Janoa the Fang or Kursak the Coiled on Nightmare mode.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { achievementID = 63453, name = "One, Two, Ral'kala's Coming for You", zone = "Coiled Isle", description = "Defeat Ral'kala on Nightmare mode or with Curse of the Isle active.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { achievementID = 63454, name = "Nine, Ten, Never Sleep Again", zone = "Coiled Isle", description = "Defeat Ral'kala on Nightmare mode or with Curse of the Isle active 50 times.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { achievementID = 63457, name = "Let Sleeping Skulls Lie", zone = "Coiled Isle", description = "Loot 100 Ossified Relics during Prey Hunts.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { achievementID = 63642, name = "Sashay Away", zone = "Coiled Isle", description = "Survive 100 Toxic Snare barrages on Hard or Nightmare mode." },
            { achievementID = 63643, name = "You Guys, Again?", zone = "Coiled Isle", description = "Kill 150 Pack Scouts on Hard or Nightmare mode." },
            { achievementID = 63644, name = "Kill Me Now", zone = "Coiled Isle", description = "Kill 200 Venom-Bloated Pythons on Hard or Nightmare mode." },
        },
    },

    --------------------------------------------------------------------
    -- Housing Vacation Season and new Arcantina visitors.
    --------------------------------------------------------------------
    {
        category = "features",
        source = "housing",
        achievements = {
            {
                achievementID = 63606,
                name          = "Superlative Souvenir Seeker",
                zone          = "Player neighborhoods",
                description   = "Find all Secret Souvenirs in both neighborhood themes during the Vacation Season endeavor.",
                taskList = {
                    intro = "Each neighborhood has 60 Secret Souvenirs available during Vacation Season.",
                    tasks = {
                        { achievementID = 63441, label = "Souvenir Seeker, Razorwind Shores" },
                        { achievementID = 63605, label = "Souvenir Seeker, Founder's Point" },
                    },
                },
            },
            { achievementID = 63441, name = "Souvenir Seeker, Razorwind Shores", zone = "Razorwind Shores", description = "Find all 60 Secret Souvenirs in a Razorwind Shores neighborhood during Vacation Season." },
            { achievementID = 63605, name = "Souvenir Seeker, Founder's Point", zone = "Founder's Point", description = "Find all 60 Secret Souvenirs in a Founder's Point neighborhood during Vacation Season." },
        },
    },
    {
        category = "exploration",
        source = "zone",
        achievements = {
            {
                achievementID = 63619,
                name          = "New Friends",
                zone          = "The Arcantina",
                description   = "Complete the new visitor quests from Chen and Flynn, and Vanessa and Garona.",
                taskList = {
                    intro = "Complete both visitor pair questlines in the Arcantina.",
                    tasks = {
                        { achievementID = 63619, criteriaID = 108597, label = "Chen and Flynn" },
                        { achievementID = 63619, criteriaID = 108598, label = "Vanessa and Garona" },
                    },
                },
            },
            {
                achievementID = 63620,
                name          = "Well Decorated",
                zone          = "The Arcantina",
                description   = "Retrieve and display the two relics from the new Arcantina visitor quests.",
                taskList = {
                    intro = "Recover and display both optional quest relics.",
                    tasks = {
                        { achievementID = 63620, criteriaID = 108608, label = "Stormstout Brewery Lantern" },
                        { achievementID = 63620, criteriaID = 108607, label = "Wooden Toy Sword" },
                    },
                },
            },
        },
    },

    --------------------------------------------------------------------
    -- Newly extended holiday checklists.
    --------------------------------------------------------------------
    {
        category = "exploration",
        source = "events",
        achievements = {
            {
                achievementID = 63253,
                name          = "A Round on the House in Midnight",
                zone          = "Midnight (all zones)",
                description   = "Donate to all eight Brewfest Bar Tab Barrels in Midnight zones.",
                taskList = {
                    intro = "Visit every listed inn during Brewfest and contribute to its Bar Tab Barrel.",
                    tasks = {
                        { achievementID = 63253, criteriaID = 114942, label = "Eversong Woods: Silvermoon" },
                        { achievementID = 63253, criteriaID = 114943, label = "Eversong Woods: Tranquillien" },
                        { achievementID = 63253, criteriaID = 114944, label = "Eversong Woods: Arcantina" },
                        { achievementID = 63253, criteriaID = 114945, label = "Harandar: Har'athir" },
                        { achievementID = 63253, criteriaID = 114946, label = "Harandar: The Den" },
                        { achievementID = 63253, criteriaID = 114947, label = "Voidstorm: Locus Point" },
                        { achievementID = 63253, criteriaID = 114948, label = "Zul'Aman: Amani'Zar" },
                        { achievementID = 63253, criteriaID = 114949, label = "Zul'Aman: Witherbark Bluffs" },
                    },
                },
            },
            {
                achievementID = 63400,
                name          = "Tricks and Treats of Midnight",
                zone          = "Midnight (all zones)",
                description   = "Visit all 15 Hallow's End Candy Buckets in Midnight zones.",
                taskList = {
                    intro = "Visit each inn during Hallow's End and loot its Candy Bucket.",
                    tasks = {
                        { achievementID = 63400, criteriaIndex = 1, label = "Eversong Woods: Arcantina" },
                        { achievementID = 63400, criteriaIndex = 2, label = "Eversong Woods: Fairbreeze Village" },
                        { achievementID = 63400, criteriaIndex = 3, label = "Eversong Woods: Silvermoon" },
                        { achievementID = 63400, criteriaIndex = 4, label = "Eversong Woods: Tranquillien" },
                        { achievementID = 63400, criteriaIndex = 5, label = "Harandar: Har'alnor" },
                        { achievementID = 63400, criteriaIndex = 6, label = "Harandar: Har'athir" },
                        { achievementID = 63400, criteriaIndex = 7, label = "Harandar: Har'kuai" },
                        { achievementID = 63400, criteriaIndex = 8, label = "Harandar: Har'mara" },
                        { achievementID = 63400, criteriaIndex = 9, label = "Harandar: The Den" },
                        { achievementID = 63400, criteriaIndex = 10, label = "Voidstorm: Locus Point" },
                        { achievementID = 63400, criteriaIndex = 11, label = "Voidstorm: Slayer's Rise" },
                        { achievementID = 63400, criteriaIndex = 12, label = "Voidstorm: The Ingress" },
                        { achievementID = 63400, criteriaIndex = 13, label = "Zul'Aman: Amani'Zar" },
                        { achievementID = 63400, criteriaIndex = 14, label = "Zul'Aman: Camp Stonewash" },
                        { achievementID = 63400, criteriaIndex = 15, label = "Zul'Aman: Witherbark Bluffs" },
                    },
                },
            },
        },
    },

    --------------------------------------------------------------------
    -- Midnight Season 2 delves and the two new Coiled Isle delves.
    --------------------------------------------------------------------
    {
        category = "features",
        source = "delves",
        achievements = {
            { achievementID = 63326, name = "My Venomous Nemesis", zone = "Azta'rec's Lair", description = "Defeat Azta'rec in his lair during Midnight Season 2." },
            { achievementID = 63332, name = "Purging the Poison", zone = "Azta'rec's Lair", description = "Defeat Azta'rec at the season's challenge tier before the next delve season. Reward: the Poisonous title.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { achievementID = 63333, name = "Let Me Solo Him: Azta'rec", zone = "Azta'rec's Lair", description = "Defeat Azta'rec at the season's solo challenge tier without another player in the party. Reward: Apophic Soul Crusher mount.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { achievementID = 62889, name = "Midnight Delves: Tier 4 (Season 2)", zone = "Midnight delves", description = "Complete a Tier 4 delve with lives remaining during Season 2." },
            { achievementID = 62890, name = "Midnight Delves: Tier 5 (Season 2)", zone = "Midnight delves", description = "Complete a Tier 5 delve with lives remaining during Season 2." },
            { achievementID = 62891, name = "Midnight Delves: Tier 6 (Season 2)", zone = "Midnight delves", description = "Complete a Tier 6 delve with lives remaining during Season 2." },
            { achievementID = 62892, name = "Midnight Delves: Tier 7 (Season 2)", zone = "Midnight delves", description = "Complete a Tier 7 delve with lives remaining during Season 2." },
            { achievementID = 62893, name = "Midnight Delves: Tier 8 (Season 2)", zone = "Midnight delves", description = "Complete a Tier 8 delve with lives remaining during Season 2." },
            { achievementID = 62894, name = "Midnight Delves: Tier 9 (Season 2)", zone = "Midnight delves", description = "Complete a Tier 9 delve with lives remaining during Season 2." },
            { achievementID = 62895, name = "Midnight Delves: Tier 10 (Season 2)", zone = "Midnight delves", description = "Complete a Tier 10 delve with lives remaining during Season 2." },
            { achievementID = 62897, name = "Midnight Delves: Tier 11 (Season 2)", zone = "Midnight delves", description = "Complete a Tier 11 delve with lives remaining during Season 2. Reward: the Immortal title." },
            { achievementID = 63433, name = "Midnight: Journey's End (Season 2)", zone = "Midnight delves", description = "Complete the Delver's Journey before Midnight Season 2 ends." },
            { achievementID = 63434, name = "Buddy System VII: Valeera", zone = "Midnight delves", description = "Raise delve companion Valeera to level 70." },
            { achievementID = 63435, name = "Buddy System VIII: Valeera", zone = "Midnight delves", description = "Raise delve companion Valeera to level 80." },
            {
                achievementID = 63170,
                name          = "Gnarldor Isle Discoveries",
                zone          = "Gnarldor Isle",
                description   = "Find all three Sturdy Chests hidden in Gnarldor Isle.",
                taskList = {
                    intro = "Open all three Sturdy Chests in the delve.",
                    tasks = {
                        { achievementID = 63170, criteriaID = 114794, label = "Southeast Sturdy Chest", waypoint = { 2635, 0.6040, 0.6820, "Sturdy Chest" } },
                        { achievementID = 63170, criteriaID = 114795, label = "Central Sturdy Chest", waypoint = { 2635, 0.5240, 0.4090, "Sturdy Chest" } },
                        { achievementID = 63170, criteriaID = 114796, label = "West Sturdy Chest", waypoint = { 2635, 0.2870, 0.4170, "Sturdy Chest" } },
                    },
                },
            },
            { achievementID = 63437, name = "Gnarldor Isle Stories", zone = "Gnarldor Isle", description = "Complete every story variant of the Gnarldor Isle delve." },
            {
                achievementID = 63171,
                name          = "The Ring of Glory Discoveries",
                zone          = "The Ring of Glory",
                description   = "Find all three Sturdy Chests hidden in The Ring of Glory.",
                taskList = {
                    intro = "Open all three Sturdy Chests in the delve.",
                    tasks = {
                        { achievementID = 63171, criteriaID = 114798, label = "Southwest Sturdy Chest", waypoint = { 2633, 0.2520, 0.7370, "Sturdy Chest" } },
                        { achievementID = 63171, criteriaID = 114799, label = "South Sturdy Chest", waypoint = { 2633, 0.4860, 0.9490, "Sturdy Chest" } },
                        { achievementID = 63171, criteriaID = 114800, label = "North Sturdy Chest", waypoint = { 2633, 0.4410, 0.2270, "Sturdy Chest" } },
                    },
                },
            },
            { achievementID = 63436, name = "The Ring of Glory Stories", zone = "The Ring of Glory", description = "Complete every story variant of The Ring of Glory delve." },
        },
    },

    --------------------------------------------------------------------
    -- Sporefall's second encounter and The Venomous Abyss raid.
    --------------------------------------------------------------------
    {
        category = "features",
        source = "raid",
        achievements = {
            { achievementID = 63683, name = "Nymrissa Wavecaller", zone = "Tidebound Grotto", description = "Defeat Nymrissa Wavecaller in the Tidebound Grotto on any difficulty." },
            { achievementID = 63681, name = "Heroic: Nymrissa Wavecaller", zone = "Tidebound Grotto", description = "Defeat Nymrissa Wavecaller on Heroic difficulty or higher.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { achievementID = 63682, name = "Mythic: Nymrissa Wavecaller", zone = "Tidebound Grotto", description = "Defeat Nymrissa Wavecaller on Mythic difficulty.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { achievementID = 63686, name = "Nymrissa Wavecaller Guild Run", zone = "Tidebound Grotto", description = "Defeat Nymrissa Wavecaller on Normal difficulty or higher in a guild group.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { achievementID = 63687, name = "Heroic: Nymrissa Wavecaller Guild Run", zone = "Tidebound Grotto", description = "Defeat Nymrissa Wavecaller on Heroic difficulty or higher in a guild group.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
            { achievementID = 63688, name = "Mythic: Nymrissa Wavecaller Guild Run", zone = "Tidebound Grotto", description = "Defeat Nymrissa Wavecaller on Mythic difficulty in a guild group.", availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2 },
        },
    },
    {
        category = "features",
        source = "raid",
        availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2,
        achievements = {
            { achievementID = 63530, name = "The Venomous Abyss: Essence of Ula'tek", zone = "The Venomous Abyss", description = "Defeat Nek'zali, Entombed Sentinels, and Vashnik." },
            { achievementID = 63531, name = "The Venomous Abyss: Beasts of Ula'tek", zone = "The Venomous Abyss", description = "Defeat The Lost Explorers, Sszorak, and The Twin Fangs." },
            { achievementID = 63532, name = "The Venomous Abyss: Ula'tek", zone = "The Venomous Abyss", description = "Defeat The Coiled Altar and Ula'tek." },
            { achievementID = 63521, name = "The Venomous Abyss", zone = "The Venomous Abyss", description = "Defeat every boss in The Venomous Abyss on any difficulty." },
            { achievementID = 63520, name = "Heroic: The Venomous Abyss", zone = "The Venomous Abyss", description = "Defeat every boss in The Venomous Abyss on Heroic difficulty." },
            { achievementID = 63522, name = "Mythic: The Venomous Abyss", zone = "The Venomous Abyss", description = "Defeat every boss in The Venomous Abyss on Mythic difficulty." },
            {
                achievementID = 63254,
                name          = "Glory of the Venomous Raider",
                zone          = "The Venomous Abyss",
                description   = "Complete all eight encounter challenges. Reward: Crimson Venomfang mount.",
                taskList = {
                    intro = "Complete each challenge on Normal difficulty or higher.",
                    tasks = {
                        { achievementID = 63418, label = "Well, Well, Little Sky" },
                        { achievementID = 63250, label = "Is Venom Stasis A Joke To You?" },
                        { achievementID = 63645, label = "Accidental Inclusion" },
                        { achievementID = 63397, label = "Kept You Waiting Huh?" },
                        { achievementID = 63391, label = "Jumping Through Hoops" },
                        { achievementID = 63656, label = "Taking a Bite out of Slime" },
                        { achievementID = 63669, label = "Watch Out Behind You" },
                        { achievementID = 63609, label = "No Egg Scramble" },
                    },
                },
            },
            { achievementID = 63472, name = "Fang Fatale", zone = "The Venomous Abyss", description = "Complete the Fang Fatale raid milestone in The Venomous Abyss." },
            { achievementID = 63646, name = "The Venomous Abyss Guild Run", zone = "The Venomous Abyss", description = "Defeat every boss on Normal difficulty or higher while in a guild group." },
            { achievementID = 63647, name = "Heroic: The Venomous Abyss Guild Run", zone = "The Venomous Abyss", description = "Defeat every boss on Heroic difficulty or higher while in a guild group." },
            { achievementID = 63670, name = "Comforting Da Spirits", zone = "The Venomous Abyss", description = "Experience an Ancestral Vision and comfort every trapped spirit scattered within it." },
            { achievementID = 63418, name = "Well, Well, Little Sky", zone = "The Venomous Abyss", description = "Defeat Nek'zali after returning Kupamanduka to the Soulcoil Well on Normal difficulty or higher." },
            { achievementID = 63250, name = "Is Venom Stasis A Joke To You?", zone = "The Venomous Abyss", description = "Defeat the Entombed Sentinels after each restores over half its health with Vitriolic Stasis." },
            { achievementID = 63397, name = "Kept You Waiting Huh?", zone = "The Venomous Abyss", description = "Defeat Vashnik after killing the Solidified Snake Venom on Normal difficulty or higher." },
            { achievementID = 63645, name = "Accidental Inclusion", zone = "The Venomous Abyss", description = "Defeat The Lost Explorers including Hoji on Normal difficulty or higher." },
            { achievementID = 63391, name = "Jumping Through Hoops", zone = "The Venomous Abyss", description = "Defeat Sszorak while jumping through each ring that appears on Normal difficulty or higher." },
            { achievementID = 63656, name = "Taking a Bite out of Slime", zone = "The Venomous Abyss", description = "Defeat The Twin Fangs after feeding Ithraz the required slimes in order during Ravenous Feast." },
            { achievementID = 63669, name = "Watch Out Behind You", zone = "The Venomous Abyss", description = "Defeat The Coiled Altar while every player is afflicted by Unnerving Fixation." },
            { achievementID = 63609, name = "No Egg Scramble", zone = "The Venomous Abyss", description = "Defeat Ula'tek before the Greasy Hatchling breaks on Normal difficulty or higher." },
            { achievementID = 63523, name = "Mythic: Nek'zali the Soulcoiler", zone = "The Venomous Abyss", description = "Defeat Nek'zali the Soulcoiler on Mythic difficulty." },
            { achievementID = 63524, name = "Mythic: Entombed Sentinels", zone = "The Venomous Abyss", description = "Defeat the Entombed Sentinels on Mythic difficulty." },
            { achievementID = 63526, name = "Mythic: Vashnik the Malignant", zone = "The Venomous Abyss", description = "Defeat Vashnik the Malignant on Mythic difficulty." },
            { achievementID = 63525, name = "Mythic: The Lost Explorers", zone = "The Venomous Abyss", description = "Defeat The Lost Explorers on Mythic difficulty." },
            { achievementID = 63527, name = "Mythic: Sszorak", zone = "The Venomous Abyss", description = "Defeat Sszorak on Mythic difficulty." },
            { achievementID = 63528, name = "Mythic: The Twin Fangs", zone = "The Venomous Abyss", description = "Defeat The Twin Fangs on Mythic difficulty." },
            { achievementID = 63529, name = "Mythic: The Coiled Altar", zone = "The Venomous Abyss", description = "Defeat The Coiled Altar on Mythic difficulty." },
            { achievementID = 63476, name = "Mythic: Ula'tek", zone = "The Venomous Abyss", description = "Defeat Ula'tek on Mythic difficulty." },
            { achievementID = 63650, name = "Ahead of the Curve: Ula'tek", zone = "The Venomous Abyss", description = "Defeat Ula'tek on Heroic difficulty or higher during Midnight Season 2." },
            { achievementID = 63651, name = "Cutting Edge: Ula'tek", zone = "The Venomous Abyss", description = "Defeat Ula'tek on Mythic difficulty before the next raid tier." },
            { achievementID = 63652, name = "Hall of Fame: Ula'tek", zone = "The Venomous Abyss", description = "Be among the first 200 guilds worldwide to defeat Ula'tek on Mythic difficulty." },
            { achievementID = 63648, name = "Mythic: Ula'tek Guild Run", zone = "The Venomous Abyss", description = "Defeat Ula'tek on Mythic difficulty while in a guild group." },
        },
    },

    --------------------------------------------------------------------
    -- Altar of Fangs dungeon.
    --------------------------------------------------------------------
    {
        category = "features",
        source = "dungeons",
        achievements = {
            { achievementID = 63679, name = "In Case Of Emergency", zone = "Altar of Fangs", description = "Reverse the ritual performed on Slitherfang in the Altar of Fangs." },
            { achievementID = 62282, name = "Altar of Fangs", zone = "Altar of Fangs", description = "Defeat Slitherfang in the Altar of Fangs on any difficulty." },
            { achievementID = 62283, name = "Heroic: Altar of Fangs", zone = "Altar of Fangs", description = "Defeat Slitherfang in the Altar of Fangs on Heroic difficulty or higher." },
            { achievementID = 62284, name = "Mythic: Altar of Fangs", zone = "Altar of Fangs", description = "Defeat Slitherfang in the Altar of Fangs on Mythic difficulty." },
        },
    },

    --------------------------------------------------------------------
    -- Midnight Mythic+ Season 2.
    --------------------------------------------------------------------
    {
        category = "features",
        source = "season",
        availableAfter = MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2,
        achievements = {
            { achievementID = 62437, name = "Keystone Hero: The Blinding Vale", zone = "The Blinding Vale", description = "Complete The Blinding Vale at Mythic Level 10 or higher within the time limit." },
            { achievementID = 62438, name = "Keystone Hero: Voidscar Arena", zone = "Voidscar Arena", description = "Complete Voidscar Arena at Mythic Level 10 or higher within the time limit." },
            { achievementID = 62439, name = "Keystone Hero: Den of Nalorakk", zone = "Den of Nalorakk", description = "Complete Den of Nalorakk at Mythic Level 10 or higher within the time limit." },
            { achievementID = 62440, name = "Keystone Hero: Murder Row", zone = "Murder Row", description = "Complete Murder Row at Mythic Level 10 or higher within the time limit." },
            { achievementID = 62441, name = "Keystone Hero: Altar of Fangs", zone = "Altar of Fangs", description = "Complete Altar of Fangs at Mythic Level 10 or higher within the time limit." },
            { achievementID = 62442, name = "Keystone Hero: Ruby Life Pools (Midnight Season 2)", zone = "Ruby Life Pools", description = "Complete Ruby Life Pools at Mythic Level 10 or higher within the time limit during Season 2." },
            { achievementID = 62443, name = "Keystone Hero: Temple of Sethraliss", zone = "Temple of Sethraliss", description = "Complete Temple of Sethraliss at Mythic Level 10 or higher within the time limit." },
            { achievementID = 62444, name = "Keystone Hero: Kings' Rest", zone = "Kings' Rest", description = "Complete Kings' Rest at Mythic Level 10 or higher within the time limit." },
            { achievementID = 63621, name = "Keystone Victor: Altar of Fangs", zone = "Altar of Fangs", description = "Complete Altar of Fangs within the Season 2 Keystone Victor requirements." },
            { achievementID = 63622, name = "Keystone Victor: Den of Nalorakk", zone = "Den of Nalorakk", description = "Complete Den of Nalorakk within the Season 2 Keystone Victor requirements." },
            { achievementID = 63623, name = "Keystone Victor: Murder Row", zone = "Murder Row", description = "Complete Murder Row within the Season 2 Keystone Victor requirements." },
            { achievementID = 63624, name = "Keystone Victor: The Blinding Vale", zone = "The Blinding Vale", description = "Complete The Blinding Vale within the Season 2 Keystone Victor requirements." },
            { achievementID = 63625, name = "Keystone Victor: Voidscar Arena", zone = "Voidscar Arena", description = "Complete Voidscar Arena within the Season 2 Keystone Victor requirements." },
            { achievementID = 63626, name = "Keystone Victor: Kings' Rest", zone = "Kings' Rest", description = "Complete Kings' Rest within the Season 2 Keystone Victor requirements." },
            { achievementID = 63627, name = "Keystone Victor: Ruby Life Pools", zone = "Ruby Life Pools", description = "Complete Ruby Life Pools within the Season 2 Keystone Victor requirements." },
            { achievementID = 63628, name = "Keystone Victor: Temple of Sethraliss", zone = "Temple of Sethraliss", description = "Complete Temple of Sethraliss within the Season 2 Keystone Victor requirements." },
            { achievementID = 62445, name = "Midnight Keystone Explorer: Season 2", zone = "Midnight Season 2", description = "Complete a Mythic+ dungeon within the time limit during Season 2." },
            { achievementID = 62446, name = "Midnight Keystone Conqueror: Season 2", zone = "Midnight Season 2", description = "Reach 1,500 Mythic+ rating during Season 2. Reward: the Venomous title." },
            { achievementID = 62447, name = "Midnight Keystone Master: Season 2", zone = "Midnight Season 2", description = "Reach 2,000 Mythic+ rating during Season 2. Reward: Breath of Blight mount." },
            { achievementID = 62448, name = "Midnight Keystone Hero: Season 2", zone = "Midnight Season 2", description = "Reach 2,500 Mythic+ rating during Season 2." },
            { achievementID = 62449, name = "Midnight Keystone Legend: Season 2", zone = "Midnight Season 2", description = "Reach 3,000 Mythic+ rating during Season 2. Reward: Breath of Ruin mount." },
            { achievementID = 62436, name = "Venomous Hero: Midnight Season 2", zone = "Midnight Season 2", description = "Finish Season 2 with Mythic+ rating in the top 0.1% of your region." },
            { achievementID = 62417, name = "Midnight Season 2: Resilient Keystone 12", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 12." },
            { achievementID = 62418, name = "Midnight Season 2: Resilient Keystone 13", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 13." },
            { achievementID = 62419, name = "Midnight Season 2: Resilient Keystone 14", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 14." },
            { achievementID = 62420, name = "Midnight Season 2: Resilient Keystone 15", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 15." },
            { achievementID = 62421, name = "Midnight Season 2: Resilient Keystone 16", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 16." },
            { achievementID = 62422, name = "Midnight Season 2: Resilient Keystone 17", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 17." },
            { achievementID = 62423, name = "Midnight Season 2: Resilient Keystone 18", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 18." },
            { achievementID = 62424, name = "Midnight Season 2: Resilient Keystone 19", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 19." },
            { achievementID = 62425, name = "Midnight Season 2: Resilient Keystone 20", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 20." },
            { achievementID = 62426, name = "Midnight Season 2: Resilient Keystone 21", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 21." },
            { achievementID = 62427, name = "Midnight Season 2: Resilient Keystone 22", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 22." },
            { achievementID = 62428, name = "Midnight Season 2: Resilient Keystone 23", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 23." },
            { achievementID = 62429, name = "Midnight Season 2: Resilient Keystone 24", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 24." },
            { achievementID = 62430, name = "Midnight Season 2: Resilient Keystone 25", zone = "Midnight Season 2", description = "Time every Season 2 Mythic+ dungeon at keystone level 25." },
        },
    },
})
