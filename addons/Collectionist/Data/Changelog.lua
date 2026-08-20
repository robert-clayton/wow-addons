local _, MC = ...

-- GENERATED FILE - do not edit.
-- Source: addons/Collectionist/CHANGELOG.md
-- Regenerate: scripts/generate-collectionist-changelog-lua.ps1
--
-- Newest first. WhatsNew.lua shows every entry newer than the version
-- the player last logged in on.
MC.CHANGELOG = {
    { version = "1.13.2", sections = {
        { heading = "Added", lines = {
            "|cffffd200Trading Post mounts and toys join the pets.|r 74 mounts and 9 toys, filed under the expansion whose Trading Post first offered them. Each tab has its own \"Hide Trading Post\" toggle if you would rather not see them.",
            "17 collectibles that only reached the Trading Post after starting life as Trading Card Game codes, in-game Shop purchases, Recruit-a-Friend rewards or promotions are deliberately left out. Those are still bought with real money or gone for good, depending on which.",
        } },
    } },
    { version = "1.13.1", sections = {
        { heading = "Added", lines = {
            "|cffffd200Recipes tell you where they come from.|r Around nine in ten recipes in the browser used to say \"unknown\" — nothing about who teaches them or where to look. 8,975 of them now name the trainer, vendor, boss, quest or container that gives them, and the zone it is in: \"Marith Lazuria <Jewelcrafting Supplies>, Dalaran\". Nine are still uncatalogued, all Inscription glyphs and Pandaria profession items.",
            "Recipes sort into headings that match how you actually get them, including World Drop, Treasure, PvP, and Not obtainable for recipes that exist in the client but were never released.",
            "|cffffd200Trading Post pets are tracked.|r 30 of them, filed under the expansion whose Trading Post first offered them. They are bought with Trader's Tender you earn in game and they come back around, so leaving them out was making collections look more complete than they were. Hide them with \"Hide Trading Post\" in the Pets options.",
            "|cffffd200A quiet \"what's new\" note after updating.|r The first time you open Collectionist on a new version, a small line appears at the edge of the window. Click it to read the changes, or ignore it and it leaves on its own. /mc whatsnew any time; turn it off in Options.",
        } },
        { heading = "Changed", lines = {
            "|cffffd200Collection Score prices recipes by how hard they are to get.|r While almost every recipe was filed as \"unknown\" they all scored the same flat amount regardless of source. Now that the addon knows the difference, a recipe that drops from a raid boss counts for more than one you buy from a vendor. Most collections will see their recipe score go up.",
        } },
    } },
    { version = "1.13.0", sections = {
        { heading = "Added", lines = {
            "|cffffd200The whole game, not just Midnight.|r Complete Classic, The Burning Crusade, Wrath of the Lich King, Cataclysm, Mists of Pandaria, Warlords of Draenor, Legion, Battle for Azeroth, Shadowlands, Dragonflight, and The War Within catalogs for every tracker, with exact manifest validation for collectible, achievement, recipe, rare, and treasure IDs.",
            "|cffffd200A second interface: Premium.|r An application-style window with sidebar navigation, a collection spine showing progress across every tracker, and a footer that keeps your score and peers in view. The original layout is still there as Simple — switch with /mc style.",
            "A |cffffd200compact mode|r and a slim minimize strip, so Collectionist can sit on screen while you play without taking a quarter of it.",
            "|cffffd200Pinned targets.|r Alt-click anything you're chasing to keep it in a small overlay, wherever you are in the addon.",
            "The |cffffd200Ellesmere|r theme, for anyone running EllesmereUI.",
            "The Collection Inspector is now a proper window you can move, resize, and close with Escape.",
            "Every expansion appears in the pickers, greyed out until its content ships, so you can see what's coming.",
            "Housing decorations are assigned to the expansion where they are obtained, including pre-Midnight rewards that only entered the housing catalog when housing launched.",
            "Housing recipes taught by an older expansion's profession tiers are tracked with that expansion as well.",
            "Release-cycle rewards from Remix, seasonal play, anniversaries, Plunderstorm, and other ended events remain under their original expansion and are marked unavailable where their acquisition window has closed.",
        } },
        { heading = "Changed", lines = {
            "|cffffd200Achievements no longer inflate your Collection Score.|r There are three times as many of them as the next-largest tracker and they carried the heaviest weights, so they were making up 59% of the total — the number described achievement progress more than it described a collection. The separate achievement-points tally is gone too; the game's own achievement UI is where that belongs.",
            "|cffffd200Recipes list every profession|r, not just the ones this character knows, with a toggle to hide the ones you haven't learned. Recipe unlocks are account-wide, so the browser now matches.",
            "|cffffd200One control decides what a tab shows.|r The per-tab expansion filter is gone; Options > Expansions governs every tracker at once.",
            "Options moved out of a side dock and into the sidebar as its own tab. Scan lives there now.",
            "Window controls sit where you expect them — minimize, maximize, and close at the top right of the header.",
            "The launch expansion is called |cffffd200Vanilla|r rather than Classic, which is what people actually call it.",
            "Fades and slides throughout both layouts, and tabs cross-fade when you switch.",
            "Tracker headings dropped their subtitle blurbs.",
        } },
        { heading = "Fixed", lines = {
            "Scrollbars can be clicked and dragged.",
            "The collection spine kept its full width when collapsing to compact.",
            "The first time you hovered a sidebar entry it flashed near-white instead of lifting slightly.",
            "Collectionist could not be expanded again after collapsing it all the way down to the strip.",
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
}
