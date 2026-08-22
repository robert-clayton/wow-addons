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
            "|cffffd200Search everything.|r A magnifier in the title bar — or /mc find, or just typing anything after /mc — searches every collectible the addon knows by name, zone, or source. \"Storm song\" finds the Stormsong Valley mounts, \"Kael\" finds his drops across five trackers. Results group by tracker, and every row keeps its usual clicks: waypoint, Wowhead link, Alt-click to pin.",
            "Search respects Options > Expansions like the tabs do, but ignores the hide-unavailable and Trading Post toggles — those curate the trackers; search answers whether something exists at all. Your last few queries are remembered as clickable recents.",
            "|cffffd200Collection status on item tooltips.|r Hover a mount, pet, toy, or decoration anywhere in the game — bags, loot, the auction house — and Collectionist appends one line: green \"Collected\", or \"Missing\" plus where to get it, in that source's color. Turn it off in Options > General if you'd rather not know.",
            "Escape backs out of search to whatever tab you were reading; an empty input's Escape leaves search, a full one just clears.",
        } },
    } },
    { version = "1.14.0", sections = {
        { heading = "Added", lines = {
            "|cffffd200Recipes drop map pins.|r Click a recipe you haven't learned and Collectionist points you at it, the same way rares and treasures already did. Around 5,900 recipes now have a location — the vendor who sells it, the boss who drops it, the quest that rewards it, or the trainer who teaches it.",
            "|cffffd200Trainer pins know your faction.|r The data everyone builds these from files each recipe under one faction's trainer, which would have sent Alliance players to Orgrimmar. Every trainer pin is paired instead, so you get your own capital. Neutral hubs like Dalaran, Oribos and Valdrakken are shared, as they are in game.",
            "A vendor who wanders now gets all of his stops pinned rather than one guess at where he might be.",
            "|cffffd200401 recipes that were missing entirely|r, across every profession — Jewelcrafting 90, Inscription 87, Leatherworking 70, Enchanting 40, Blacksmithing 38, Cooking 34, Tailoring 24, and a handful each of Alchemy and Engineering.",
            "|cffffd200180 housing decorations|r that were missing, each with the quest or vendor that awards it.",
            "|cffffd200708 rares and 364 treasures as map locations.|r These are places to go, not things to collect — the game gives no reliable way to know whether you have already got them, so they show as \"Location only\", carry a waypoint, and never count towards your totals or your Collection Score. Pandaria through Midnight.",
        } },
        { heading = "Fixed", lines = {
            "Twelve Draenor recipes said \"Not obtainable\" when they are craftable today — Hexweave Cloth, Truesteel Ingot, Alchemical Catalyst and the rest of the daily-cooldown reagents. They read as trainer-taught now, which is what they are.",
            "Recipes show the \"Click to open profession\" hint again. The hint was checking for something recipe rows never carried, so it never appeared even though the click always worked.",
            "Several hundred recipes named the wrong thing as their source — a quest reward would name the container it sat in rather than the quest. Quest-sourced recipes now name the quest.",
        } },
    } },
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
}
