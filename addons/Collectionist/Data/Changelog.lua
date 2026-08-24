local _, MC = ...

-- GENERATED FILE - do not edit.
-- Source: addons/Collectionist/CHANGELOG.md
-- Regenerate: scripts/generate-collectionist-changelog-lua.ps1
--
-- Newest first. WhatsNew.lua shows every entry newer than the version
-- the player last logged in on.
MC.CHANGELOG = {
    { version = "1.16.1", sections = {
        { heading = "Added", lines = {
            "|cffffd200The whole game, not just Midnight.|r Complete catalogs for Classic through The War Within across every tracker — mounts, pets, toys, decorations, recipes, rares, treasures and achievements.",
            "|cffffd200A second interface: Premium.|r An application-style window with sidebar navigation, a collection spine showing progress across every tracker, and a footer that keeps your score and peers in view. The original layout is still there as Simple — switch with /mc style, or in Options > Appearance. Premium is the default for anyone who never picked one.",
            "|cffffd200Search everything.|r A magnifier in the title bar — or /mc find, or just typing anything after /mc — searches every collectible by name, zone, or source. \"Storm song\" finds the Stormsong Valley mounts; \"Kael\" finds his drops across five trackers. Results group by tracker and keep their usual clicks.",
            "|cffffd200Collection status on item tooltips.|r Hover a mount, pet, toy or decoration anywhere in the game — bags, loot, the auction house — and Collectionist appends one line: green \"Collected\", or \"Missing\" plus where to get it. Turn it off in Options > General.",
            "|cffffd200A Targets tab.|r Alt-click anything you're chasing to pin it. Pinned things now have a page of their own in the sidebar, grouped by where they came from, as well as the small on-screen list. It sits with Options at the bottom, in its own colour, because it's what you're working on rather than another collection to browse. Right-click a row to unpin.",
            "|cffffd200Recipes tell you where they come from.|r Around nine in ten used to say \"unknown\". 8,975 now name the trainer, vendor, boss, quest or container that gives them, and the zone: \"Marith Lazuria <Jewelcrafting Supplies>, Dalaran\". Nine remain uncatalogued.",
            "|cffffd200Recipes drop map pins|r, the same way rares and treasures do — roughly 5,900 of them. Trainer pins are faction-paired, so Alliance players get their own capital instead of being sent to Orgrimmar; neutral hubs like Dalaran, Oribos and Valdrakken are shared, as in game. A vendor who wanders gets all his stops pinned rather than one guess.",
            "|cffffd200Locations for thousands of older collectibles.|r 2,854 mounts, pets, toys and decorations gained the zone they come from, and 3,135 of them gained a clickable map pin — including 560 that carry several possible spots.",
            "|cffffd200Reward tracks show live progress.|r A row that needs Preyhunter's Journey rank 8, or Keg Leg's Crew renown 20, now reads your current rank and turns green when you've met it, instead of stating the requirement as plain text.",
            "|cffffd200401 recipes and 180 housing decorations that were missing entirely|r, across every profession, each with the quest or vendor that awards it.",
            "|cffffd200Trading Post pets, mounts and toys are tracked|r — 30 pets, 74 mounts, 9 toys, filed under the expansion whose Trading Post first offered them. Each tab has its own \"Hide Trading Post\" toggle. 17 that began as Trading Card Game codes, Shop purchases, Recruit-a-Friend rewards or promotions are deliberately left out; those cost real money or are gone for good.",
            "|cffffd200Sort rows.|r A control in the title bar cycles Default, A-Z, Z-A, and expansion order both ways. Each tab remembers its own.",
            "|cffffd200Hide unobtainable recipes|r, in Options > Trackers. Recipes removed from the game stop filling the list and stop counting against your totals; they're still counted as Legacies.",
            "A |cffffd200compact mode|r and a slim minimize strip, so Collectionist can sit on screen while you play. In the compact window, clicking the page title opens a list of the other tabs — the sidebar isn't there to switch with.",
            "|cffffd200A quiet \"what's new\" note after updating.|r A small line at the edge of the window the first time you open a new version. Click to read, or ignore it and it leaves on its own. /mc whatsnew any time.",
            "The |cffffd200Ellesmere|r theme, for anyone running EllesmereUI.",
            "The Collection Inspector is a proper window you can move, resize, and close with Escape.",
            "Every expansion appears in the pickers, greyed out until its content ships.",
            "/mc mem reports where the addon's memory is going, and /mc mem gc collects first so you can tell what's held from what's merely uncollected.",
        } },
        { heading = "Changed", lines = {
            "|cffffd200Achievements are scoped to collecting.|r The tab shipped 4,347 achievements — every raid boss kill, battleground objective and reputation grind — and all of it counted against your completion. An achievement is now included only if it's a collection task, a step toward a meta that rewards a collectible or title, a direct collectible or title reward, or an expansion feature. That keeps 2,310 and drops 2,037.",
            "|cffffd200Achievements no longer inflate your Collection Score.|r They were making up 59% of the total, so the number described achievement progress more than it described a collection. The separate achievement-points tally is gone too — the game's own UI is where that belongs.",
            "|cffffd200Collection Score prices recipes by how hard they are to get.|r A recipe that drops from a raid boss counts for more than one you buy from a vendor. Most collections will see their recipe score go up.",
            "|cffffd200Big tabs open instantly.|r Recipes used to build a frame for all 10,318 rows the moment you clicked it, and the game hitched while it did. Only the rows you can see are built now.",
            "|cffffd200Much lighter on memory.|r The search index isn't built until you actually search — it was the single largest thing the addon held, and most sessions never used it. Rare, treasure and achievement progress also stopped rescanning several times a second while you quest.",
            "|cffffd200Recipes list every profession|r, not just the ones this character knows, with a toggle to hide unlearned ones. Recipe unlocks are account-wide, so the browser now matches.",
            "|cffffd200One control decides what a tab shows.|r The per-tab expansion filter is gone; Options > Expansions governs every tracker at once, and toggling expansions no longer rescans once per checkbox.",
            "Options moved into the sidebar as its own tab. Scan lives there now.",
            "Window controls sit where you expect them — minimize, maximize and close at the top right.",
            "The launch expansion is called |cffffd200Vanilla|r rather than Classic, which is what people actually call it.",
            "Fades and slides throughout both layouts, and tabs cross-fade when you switch.",
        } },
        { heading = "Fixed", lines = {
            "|cffffd200Tooltips name where a thing is, not how you get there.|r Hovering a Naigtal rare while standing in Silvermoon reported \"Zone: Silvermoon City\" and printed the portal's coordinates as if they were the rare's. 473 rows could show a wrong zone this way. A new \"Via:\" line names the portal when the route differs from the destination.",
            "|cffffd200Clicking a row now always tells you what happened.|r A waypoint on a map that can't take one — a Horrific Vision, or a phased copy of a zone — reported success while placing nothing. Pins that could never appear have been removed, and rows with no location say so instead of doing nothing.",
            "|cffffd200The Coiled Isle no longer appears twice|r in Rares and Treasures, and 62 zones no longer print twice in the /mc summary.",
            "|cffffd200Rares and treasures show their real names.|r Three different Coiled Isle rares all displayed as \"Slaipaan\" because Blizzard's criterion text repeats, and roughly 650 Legion and Warlords treasures had no name at all — the name was already in our data and only being used to look up coordinates.",
            "A finishing scan no longer paints a tracker list over whatever you were looking at. Search results could be replaced by the last tab's rows a second after you opened them.",
            "Costs no longer print a texture filename where the currency icon should be.",
            "Recipes you can no longer obtain don't count toward Collection Score. They're Legacies, like everywhere else.",
            "Rare and treasure zones show real names instead of raw keys like arathi_highlands, and six zones listed twice under different spellings are merged.",
            "Recipe map pins name the vendor or quest that teaches the recipe, instead of borrowing the name of whatever else stands in the same spot. Quest-sourced recipes name the quest.",
            "Twelve Draenor recipes said \"Not obtainable\" when they're craftable today. Recipes show the \"Click to open profession\" hint again.",
            "Spring Butterfly is filed under World Event rather than Rare Drop, so it stops appearing under an \"Unknown\" heading.",
            "Eight Trading Post pets had an invalid pet family and showed none; some decoration names had their quotes and apostrophes mangled.",
            "Item tooltips no longer break on clients without the modern tooltip API.",
            "Scrollbars can be clicked and dragged. The collection spine keeps its width when collapsing to compact. Collectionist can be expanded again after collapsing all the way to the strip.",
        } },
        { heading = "Removed", lines = {
            "The \"Location only\" rows in Rares and Treasures. They couldn't be collected, a quarter of them duplicated something already tracked, and a collection tracker is the wrong place for a map reference.",
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
