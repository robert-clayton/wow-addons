local _, MC = ...

-- GENERATED FILE - do not edit.
-- Source: addons/Collectionist/CHANGELOG.md
-- Regenerate: scripts/generate-collectionist-changelog-lua.ps1
--
-- Newest first. WhatsNew.lua shows every entry newer than the version
-- the player last logged in on.
MC.CHANGELOG = {
    { version = "1.16.0", sections = {
        { heading = "Changed", lines = {
            "|cffffd200The Premium shell is now the default.|r If you never picked a window style you'll come back to the sidebar layout instead of the compact panel. If you deliberately chose Simple, you keep it — Options > Appearance still switches either way.",
            "|cffffd200Big tabs open instantly now.|r Recipes used to build a frame for all 10,318 rows the moment you clicked it, and the game hitched while it did. Only the rows you can actually see are built now, so switching tabs is immediate no matter how much you track.",
            "|cffffd200Much lighter on memory.|r The search index is no longer built at all until you actually search — it was the single largest thing the addon held, and most sessions never used it. Item tooltips keep working: they use a much smaller lookup of their own. Rare, treasure and achievement progress also stopped rescanning several times a second while you quest.",
            "Turning expansions on and off in Options no longer rescans everything once per checkbox — it settles once when you're done clicking.",
        } },
        { heading = "Added", lines = {
            "|cffffd200Sort rows.|r A control in the title bar cycles Default, A-Z, Z-A, and expansion order both ways. Each tab remembers its own.",
            "|cffffd200Locations for older collectibles.|r 519 mounts, pets and toys outside the current expansion now have a map pin where before they had nothing.",
            "|cffffd200Hide unobtainable recipes|r, in Options > Trackers. Recipes removed from the game stop filling the list and stop counting against your totals; they're still counted as Legacies.",
            "In the compact window, clicking the page title opens a list of the other tabs — the sidebar isn't there to switch with.",
            "/mc mem reports where the addon's memory is going, and /mc mem gc collects first so you can tell what's held from what's merely uncollected.",
        } },
        { heading = "Fixed", lines = {
            "Recipes you can no longer obtain no longer count toward Collection Score. They're Legacies, the same as every other tracker treats them.",
            "Rare and treasure zones show their real names instead of raw keys like arathi_highlands, and six zones that were listed twice under different spellings are merged.",
            "Recipe map pins name the vendor or quest that actually teaches the recipe, instead of borrowing the name of whatever else stands in the same spot.",
            "Eight Trading Post pets had an invalid pet family and showed none; a handful of decoration names had their quotes and apostrophes mangled.",
            "Item tooltips no longer break on clients without the modern tooltip API.",
        } },
        { heading = "Removed", lines = {
            "The \"Location only\" rows in Rares and Treasures. They couldn't be collected, a quarter of them duplicated something already tracked, and a collection tracker is the wrong place for a map reference.",
        } },
    } },
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
}
