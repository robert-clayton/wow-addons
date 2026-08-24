local _, MC = ...

-- GENERATED FILE - do not edit.
-- Source: addons/Collectionist/CHANGELOG.md
-- Regenerate: scripts/generate-collectionist-changelog-lua.ps1
--
-- Newest first. WhatsNew.lua shows every entry newer than the version
-- the player last logged in on.
MC.CHANGELOG = {
    { version = "1.13.0", sections = {
        { heading = "Added", lines = {
            "|cffffd200The whole game, not just Midnight.|r Complete catalogs for Classic through The War Within, across every tracker.",
            "|cffffd200A second interface: Premium.|r Sidebar navigation, a spine showing progress across every tracker, and your score always in view. The old layout is still there as Simple — /mc style switches.",
            "|cffffd200Search everything.|r A magnifier in the title bar, or /mc find, or just type after /mc. Searches every collectible by name, zone, or source.",
            "|cffffd200Collection status on item tooltips.|r Hover a mount, pet, toy or decoration anywhere in the game and see whether you have it, and where to get it if not.",
            "|cffffd200A Targets tab.|r Alt-click anything you're chasing to pin it. Pinned things get their own page as well as the small on-screen list.",
            "|cffffd200Recipes tell you where they come from|r, and drop map pins. Trainer pins send you to your own faction's capital, and a vendor who wanders gets all his stops.",
            "|cffffd200Locations for thousands of older collectibles|r — the zone it comes from, and a clickable pin.",
            "|cffffd200Reward tracks show live progress.|r A row needing Preyhunter's Journey rank 8 reads your current rank and turns green once you've met it.",
            "|cffffd200Trading Post pets, mounts and toys are tracked|r, with a \"Hide Trading Post\" toggle on each tab.",
            "|cffffd200Sort rows|r — Default, A-Z, Z-A, or expansion order. Each tab remembers its own.",
            "|cffffd200Hide unobtainable recipes|r, in Options > Trackers.",
            "A |cffffd200compact mode|r and a minimize strip, so Collectionist can sit on screen while you play.",
            "Hundreds of recipes and housing decorations that were missing entirely.",
            "A quiet \"what's new\" note after updating, and the Ellesmere theme for anyone running EllesmereUI.",
        } },
        { heading = "Changed", lines = {
            "|cffffd200Achievements are scoped to collecting.|r Raid kills, battleground objectives and reputation grinds no longer fill the tab or count against your completion. About half are gone.",
            "|cffffd200Achievements no longer inflate your Collection Score|r, and the separate achievement-points tally is gone — the game's own UI is where that belongs.",
            "|cffffd200Collection Score prices recipes by how hard they are to get.|r Most collections will see their recipe score go up.",
            "|cffffd200Big tabs open instantly|r, and the addon holds far less memory while you play.",
            "|cffffd200Recipes list every profession|r, not just the ones this character knows.",
            "|cffffd200One control decides what a tab shows|r — Options > Expansions governs every tracker at once.",
            "The launch expansion is called |cffffd200Vanilla|r rather than Classic.",
        } },
        { heading = "Fixed", lines = {
            "Tooltips name where a thing is, rather than the portal you'd travel through to reach it.",
            "Clicking a row always tells you what happened, instead of quietly doing nothing.",
            "The Coiled Isle no longer appears twice in Rares and Treasures.",
            "Rares and treasures show their real names. Several shared one name, and hundreds of Legion and Warlords treasures had none at all.",
            "A finishing scan no longer paints a tracker list over your search results.",
            "Costs show the currency icon instead of a filename.",
            "Recipes you can no longer obtain don't count toward Collection Score.",
            "Rare and treasure zones show real names instead of keys like arathi_highlands.",
            "Spring Butterfly is filed under World Event, so it stops showing up under \"Unknown\".",
            "Scrollbars can be dragged, and the window expands again after collapsing to the strip.",
        } },
        { heading = "Removed", lines = {
            "The \"Location only\" rows in Rares and Treasures. They couldn't be collected, and a collection tracker is the wrong place for a map reference.",
        } },
    } },
    { version = "1.12.1", sections = {
        { heading = "Added", lines = {
            "Now tracking 11 collectibles that were missing: the Umbral Ashes mount; pets Three-Eyed Fish, Pale Hexscale, J'imothy, Lil'Kruul, and Furiostraza (the last two with full Family Battler of Outland and Cataclysm checklists); toys Gold Starfish, Otoola's Recognition, G-00, Ula'tek's Sssacrificial Rain, and Preyhunter's Masquerade.",
        } },
        { heading = "Fixed", lines = {
            "Rare and treasure waypoints, scores, and puzzle notes now point at the right target. The lists had been copied from the achievement window's two columns in the wrong order, so most rows carried a neighbor's info.",
            "Unbound Manawyrm and Retrained Skyrazor track the right mounts. They had Alunira's and Azure Worldchiller's IDs.",
            "The Silvermoon Court and Hara'ti Inscription contracts are now recognized once you learn them.",
            "Ten pets show their real battle family.",
            "The Ever Painting checklist and three relic tasks in the Arcantina and Zul'Aman tick the correct criteria.",
            "The Ritual Sites gate tracks the actual \"Ritual Site Disruptor\" achievement.",
        } },
    } },
    { version = "1.12.0", sections = {
        { heading = "Added", lines = {
            "Expansion filter in the title bar: Current, All Expansions, or pin one expansion. Also /mc filter all|current|<expansion>. The Collection Inspector rescopes peer columns to match.",
            "|cffffd200Collection Score|r, in the title bar and /mc score. Each collectible has a difficulty tier (1 / 5 / 10 / 25 / 50 / 100) and your score is the sum of what you own.",
            "A |cffffd200Legacies|r count next to the score: collected items that can't be obtained anymore.",
            "|cffffd200UI themes|r: Modern (slate and bronze, the new default) and Simple (the old warm-gold look). Applies account-wide.",
            "Everything from |cffffd200Revelations (12.0.7)|r: Void Showdowns in Val and Naigtal, their rares and achievements, Showdown vendors, Rotmire, Dragonflight Timewalking, Midsummer, Lorewalking, Arcantina, and the opening Curse of Ula'tek story.",
            "Everything from |cffffd200Curse of Ula'tek (12.1)|r: the Coiled Isle, Vaults of Atal'Utek, Curse Surges, Zul'jarra's Forces, Captain Tokka's Crew, Season 2 Prey, three new Delves, Altar of Fangs, and the Venomous Abyss.",
            "Coiled Isle rare and treasure trackers, with waypoints and puzzle steps.",
            "New 12.1 housing decor, Community Coupon rewards, pet beds, mounts, pets, toys, and achievements. Season 2 rewards show their regional unlock date.",
        } },
        { heading = "Changed", lines = {
            "Achievements get their own row in the Collection Inspector.",
            "Learned recipes count account-wide now. Your alts share recipe progress.",
            "Item-priced collectibles show the item icon, how many you're carrying, and whether you can afford it.",
            "Targets client 12.1.0.",
            "The panel is wider to fit the new title-bar indicators.",
            "Collection sharing asks for consent on first run.",
            "Disabled tabs stay hidden but still feed your score and shared progress.",
            "Future rewards stay visible for planning.",
        } },
        { heading = "Fixed", lines = {
            "A Blizzard hotfix to an achievement can no longer blank a tab. Rows the game can't answer yet are skipped and retried for a couple of minutes.",
            "If Blizzard adds rares or treasures to an existing achievement, they just show up without needing for the addon to be updated.",
            "If an achievement's criteria get reordered, waypoints and puzzle steps fall back to safe lookups rather than pointing at the wrong spot.",
            "Corrected bad collectible records, achievement reward text, rare criterion order, 12.1 vendors, and vendor waypoints.",
        } },
    } },
    { version = "1.6.2", sections = {
        { heading = "Changed", lines = {
            "Mounts tab now has dedicated sections for the three Midnight feature systems: Prey, Ritual Sites, and Void Assaults.",
        } },
    } },
    { version = "1.6.1", sections = {
        { heading = "Fixed", lines = {
            "Eight mounts in the Mounts tab were showing wrong icons/tooltips because their journal IDs were mistyped. Corrected:",
            "Witherbark Warbear Mother",
            "Void-Corrupted Hex Eagle",
            "Void-Touched Hawkstrider",
            "Void-Touched Snapdragon",
            "Void-Corrupted Lynx",
            "Retrained Skyrazor",
            "Nether-Swept Drake",
            "Magister's Spell Bee",
        } },
    } },
}
