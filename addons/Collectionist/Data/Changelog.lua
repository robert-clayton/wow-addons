local _, MC = ...

-- GENERATED FILE - do not edit.
-- Source: addons/Collectionist/CHANGELOG.md
-- Regenerate: scripts/generate-collectionist-changelog-lua.ps1
--
-- Newest first. WhatsNew.lua shows every entry newer than the version
-- the player last logged in on.
MC.CHANGELOG = {
    { version = "1.13.1", sections = {
        { heading = "Added", lines = {
            "|cffffd200J'imothy is catchable.|r Blizzard switched the Silvermoon raccoon secret on, so the Pets tab now marks all three Ensorcelled Cryptid spawns and explains how to break the barrier and claim the Stubby Whistle before he wanders off.",
        } },
        { heading = "Changed", lines = {
            "Pets can carry a |cffffd200How to|r write-up in their tooltip, the same way treasures already did.",
        } },
    } },
    { version = "1.13.0", sections = {
        { heading = "Added", lines = {
            "|cffffd200The whole game, not just Midnight.|r Complete catalogs for Classic through The War Within, across every tracker.",
            "|cffffd200Collection Score|r Like Raider.IO or Achievement Points, but better because collectors > all! Heavily WIP.",
            "|cffffd200A new Premium interface.|r Sidebar navigation and more!",
            "|cffffd200Search everything.|r A magnifier in the title bar, or /mc find, or just type after /mc. Searches every collectible by name, zone, or source.",
            "|cffffd200Collection status on item tooltips.|r Hover a mount, pet, toy or decoration anywhere in the game and see whether you have it, and where to get it if not.",
            "|cffffd200A Targets tab.|r Alt-click anything you're chasing to pin it. Pinned things get their own page as well as the small on-screen list. (*Many known bugs with this, will be fixed soon)",
            "|cffffd200Reward tracks show live progress.|r Many of the \"non-major\" factions weren't using the \"can you actually buy this?\" feature. It does now!",
            "|cffffd200Trading Post pets, mounts and toys are tracked|r, with a \"Hide Trading Post\" toggle on each tab.",
            "|cffffd200Sort rows|r Default, A-Z, Z-A, or expansion order.",
            "|cffffd200Hide unobtainable recipes|r, in Options > Trackers.",
            "A |cffffd200compact mode|r and a minimize strip, so Collectionist can sit on screen while you play despite the new interface's Full view.",
            "Hundreds of recipes and housing decorations that were missing entirely. So yeah, fixed.",
            "A quiet \"what's new\" note after updating",
        } },
        { heading = "Changed", lines = {
            "Virtualized Rows to try and keep performance costs down.",
            "|cffffd200Recipes list every profession|r, not just the ones the character you're on knows.",
            "|cffffd200One control decides what a tab shows|r Options > Expansions governs every tracker at once.",
        } },
        { heading = "Fixed", lines = {
            "Tooltips name where a thing is, rather than the portal you'd travel through to reach it.",
            "Clicking a row always tells you what happened, instead of quietly doing nothing.",
            "The Coiled Isle no longer appears twice in Rares and Treasures.",
            "Rares and treasures show their real names. Several shared one name, and hundreds of Legion and Warlords treasures had none at all.",
            "Rare and treasure zones show real names instead of keys like arathi_highlands.",
            "Scrollbars can be dragged, and the window expands again after collapsing to the strip.",
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
}
