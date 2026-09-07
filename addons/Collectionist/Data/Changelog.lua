local _, MC = ...

-- GENERATED FILE - do not edit.
-- Source: addons/Collectionist/CHANGELOG.md
-- Regenerate: scripts/generate-collectionist-changelog-lua.ps1
--
-- Newest first. WhatsNew.lua shows every entry newer than the version
-- the player last logged in on.
MC.CHANGELOG = {
    { version = "1.15.0", sections = {
        { heading = "Added", lines = {
            "108 recipes: 44 Patch 12.1 recipes and 64 older Inscription recipes that were omitted by a source-classification conflict.",
            "38 source-verified housing decorations, including current neighborhood endeavors, Arcantina rewards, and two older boss/vendor rewards.",
            "8 mounts and 9 pets whose current in-game Trading Post acquisition was hidden by their older promotional origin.",
            "73 more older rare and treasure criteria now have source-backed map pins.",
        } },
        { heading = "Fixed", lines = {
            "Corrected 100 Inscription recipes that were falsely marked unobtainable after an NYI heading leaked across patch sections.",
            "Historical ATT conditional branches can no longer overwrite current-retail recipe classifications.",
            "Rare criteria that use invisible credit creatures now route and link to the physical rare.",
        } },
    } },
    { version = "1.14.0", sections = {
        { heading = "Added", lines = {
            "Map pins for more than 1,900 older rare and treasure achievement criteria, from Outland through Dragonflight.",
            "Long Silvermoon Table and Replica Dark Iron Mole Machine, with item IDs, vendors, costs, and unlock information.",
        } },
        { heading = "Fixed", lines = {
            "Search and item tooltips correctly report mount ownership. Mount and toy search results use the correct icons.",
            "Search results and newly pinned Targets use the same recipe, trainer, mount, pet, and toy locations as their tracker tabs.",
            "Treasure links distinguish completion quests from game objects. Rares keep the correct ID type when achievement criteria change.",
            "Clicking a collectible with multiple spawns keeps every location in your current zone, including all three J'imothy bushes.",
            "A rejected TomTom marker no longer causes a Lua error on multi-location or prerequisite clicks, and success messages count only markers actually placed.",
            "Corrected 31 missing or incorrect pet families, primarily Trading Post pets.",
            "Moved \"I'm In Your Base, Killing Your Dudes\" to Krasarang Wilds.",
            "Content validation preserves pet how-to guides and now fails when it rejects data instead of silently dropping it.",
        } },
    } },
    { version = "1.13.2", sections = {
        { heading = "Added", lines = {
            "|cffffd200How-to guides for 100 more pets.|r Every secret, puzzle and multi-step unlock in the Pets tab now spells out what to actually do, across all twelve expansions. Hover Baa'l, Uuna, Terky, Jenafur or Mr. Pinchy's crawdad box to see the steps, coordinates and gotchas.",
        } },
    } },
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
}
