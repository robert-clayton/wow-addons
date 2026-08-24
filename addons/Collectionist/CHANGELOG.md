# 1.16.1
*Everything since 1.12.1. The 1.13 through 1.16.0 builds were never published, so all of that work arrives here at once.*

### Added
- **The whole game, not just Midnight.** Complete catalogs for Classic through The War Within across every tracker — mounts, pets, toys, decorations, recipes, rares, treasures and achievements.
- **A second interface: Premium.** An application-style window with sidebar navigation, a collection spine showing progress across every tracker, and a footer that keeps your score and peers in view. The original layout is still there as Simple — switch with `/mc style`, or in Options > Appearance. Premium is the default for anyone who never picked one.
- **Search everything.** A magnifier in the title bar — or `/mc find`, or just typing anything after `/mc` — searches every collectible by name, zone, or source. "Storm song" finds the Stormsong Valley mounts; "Kael" finds his drops across five trackers. Results group by tracker and keep their usual clicks.
- **Collection status on item tooltips.** Hover a mount, pet, toy or decoration anywhere in the game — bags, loot, the auction house — and Collectionist appends one line: green "Collected", or "Missing" plus where to get it. Turn it off in Options > General.
- **A Targets tab.** Alt-click anything you're chasing to pin it. Pinned things now have a page of their own in the sidebar, grouped by where they came from, as well as the small on-screen list. It sits with Options at the bottom, in its own colour, because it's what you're working on rather than another collection to browse. Right-click a row to unpin.
- **Recipes tell you where they come from.** Around nine in ten used to say "unknown". 8,975 now name the trainer, vendor, boss, quest or container that gives them, and the zone: "Marith Lazuria \<Jewelcrafting Supplies\>, Dalaran". Nine remain uncatalogued.
- **Recipes drop map pins**, the same way rares and treasures do — roughly 5,900 of them. Trainer pins are faction-paired, so Alliance players get their own capital instead of being sent to Orgrimmar; neutral hubs like Dalaran, Oribos and Valdrakken are shared, as in game. A vendor who wanders gets all his stops pinned rather than one guess.
- **Locations for thousands of older collectibles.** 2,854 mounts, pets, toys and decorations gained the zone they come from, and 3,135 of them gained a clickable map pin — including 560 that carry several possible spots.
- **Reward tracks show live progress.** A row that needs Preyhunter's Journey rank 8, or Keg Leg's Crew renown 20, now reads your current rank and turns green when you've met it, instead of stating the requirement as plain text.
- **401 recipes and 180 housing decorations that were missing entirely**, across every profession, each with the quest or vendor that awards it.
- **Trading Post pets, mounts and toys are tracked** — 30 pets, 74 mounts, 9 toys, filed under the expansion whose Trading Post first offered them. Each tab has its own "Hide Trading Post" toggle. 17 that began as Trading Card Game codes, Shop purchases, Recruit-a-Friend rewards or promotions are deliberately left out; those cost real money or are gone for good.
- **Sort rows.** A control in the title bar cycles Default, A-Z, Z-A, and expansion order both ways. Each tab remembers its own.
- **Hide unobtainable recipes**, in Options > Trackers. Recipes removed from the game stop filling the list and stop counting against your totals; they're still counted as Legacies.
- A **compact mode** and a slim minimize strip, so Collectionist can sit on screen while you play. In the compact window, clicking the page title opens a list of the other tabs — the sidebar isn't there to switch with.
- **A quiet "what's new" note after updating.** A small line at the edge of the window the first time you open a new version. Click to read, or ignore it and it leaves on its own. `/mc whatsnew` any time.
- The **Ellesmere** theme, for anyone running EllesmereUI.
- The Collection Inspector is a proper window you can move, resize, and close with Escape.
- Every expansion appears in the pickers, greyed out until its content ships.
- `/mc mem` reports where the addon's memory is going, and `/mc mem gc` collects first so you can tell what's held from what's merely uncollected.

### Changed
- **Achievements are scoped to collecting.** The tab shipped 4,347 achievements — every raid boss kill, battleground objective and reputation grind — and all of it counted against your completion. An achievement is now included only if it's a collection task, a step toward a meta that rewards a collectible or title, a direct collectible or title reward, or an expansion feature. That keeps 2,310 and drops 2,037.
- **Achievements no longer inflate your Collection Score.** They were making up 59% of the total, so the number described achievement progress more than it described a collection. The separate achievement-points tally is gone too — the game's own UI is where that belongs.
- **Collection Score prices recipes by how hard they are to get.** A recipe that drops from a raid boss counts for more than one you buy from a vendor. Most collections will see their recipe score go up.
- **Big tabs open instantly.** Recipes used to build a frame for all 10,318 rows the moment you clicked it, and the game hitched while it did. Only the rows you can see are built now.
- **Much lighter on memory.** The search index isn't built until you actually search — it was the single largest thing the addon held, and most sessions never used it. Rare, treasure and achievement progress also stopped rescanning several times a second while you quest.
- **Recipes list every profession**, not just the ones this character knows, with a toggle to hide unlearned ones. Recipe unlocks are account-wide, so the browser now matches.
- **One control decides what a tab shows.** The per-tab expansion filter is gone; Options > Expansions governs every tracker at once, and toggling expansions no longer rescans once per checkbox.
- Options moved into the sidebar as its own tab. Scan lives there now.
- Window controls sit where you expect them — minimize, maximize and close at the top right.
- The launch expansion is called **Vanilla** rather than Classic, which is what people actually call it.
- Fades and slides throughout both layouts, and tabs cross-fade when you switch.

### Fixed
- **Tooltips name where a thing is, not how you get there.** Hovering a Naigtal rare while standing in Silvermoon reported "Zone: Silvermoon City" and printed the portal's coordinates as if they were the rare's. 473 rows could show a wrong zone this way. A new "Via:" line names the portal when the route differs from the destination.
- **Clicking a row now always tells you what happened.** A waypoint on a map that can't take one — a Horrific Vision, or a phased copy of a zone — reported success while placing nothing. Pins that could never appear have been removed, and rows with no location say so instead of doing nothing.
- **The Coiled Isle no longer appears twice** in Rares and Treasures, and 62 zones no longer print twice in the `/mc` summary.
- **Rares and treasures show their real names.** Three different Coiled Isle rares all displayed as "Slaipaan" because Blizzard's criterion text repeats, and roughly 650 Legion and Warlords treasures had no name at all — the name was already in our data and only being used to look up coordinates.
- A finishing scan no longer paints a tracker list over whatever you were looking at. Search results could be replaced by the last tab's rows a second after you opened them.
- Costs no longer print a texture filename where the currency icon should be.
- Recipes you can no longer obtain don't count toward Collection Score. They're Legacies, like everywhere else.
- Rare and treasure zones show real names instead of raw keys like `arathi_highlands`, and six zones listed twice under different spellings are merged.
- Recipe map pins name the vendor or quest that teaches the recipe, instead of borrowing the name of whatever else stands in the same spot. Quest-sourced recipes name the quest.
- Twelve Draenor recipes said "Not obtainable" when they're craftable today. Recipes show the "Click to open profession" hint again.
- Spring Butterfly is filed under World Event rather than Rare Drop, so it stops appearing under an "Unknown" heading.
- Eight Trading Post pets had an invalid pet family and showed none; some decoration names had their quotes and apostrophes mangled.
- Item tooltips no longer break on clients without the modern tooltip API.
- Scrollbars can be clicked and dragged. The collection spine keeps its width when collapsing to compact. Collectionist can be expanded again after collapsing all the way to the strip.

### Removed
- The "Location only" rows in Rares and Treasures. They couldn't be collected, a quarter of them duplicated something already tracked, and a collection tracker is the wrong place for a map reference.

# 1.12.1
### Added
- Now tracking 11 collectibles that were missing: the Umbral Ashes mount; pets Three-Eyed Fish, Pale Hexscale, J'imothy, Lil'Kruul, and Furiostraza (the last two with full Family Battler of Outland and Cataclysm checklists); toys Gold Starfish, Otoola's Recognition, G-00, Ula'tek's Sssacrificial Rain, and Preyhunter's Masquerade.

### Fixed
- Rare and treasure waypoints, scores, and puzzle notes now point at the right target. The lists had been copied from the achievement window's two columns in the wrong order, so most rows carried a neighbor's info.
- Unbound Manawyrm and Retrained Skyrazor track the right mounts. They had Alunira's and Azure Worldchiller's IDs.
- The Silvermoon Court and Hara'ti Inscription contracts are now recognized once you learn them.
- Ten pets show their real battle family.
- The Ever Painting checklist and three relic tasks in the Arcantina and Zul'Aman tick the correct criteria.
- The Ritual Sites gate tracks the actual "Ritual Site Disruptor" achievement.

# 1.12.0
### Added
- Expansion filter in the title bar: Current, All Expansions, or pin one expansion. Also `/mc filter all|current|<expansion>`. The Collection Inspector rescopes peer columns to match.
- **Collection Score**, in the title bar and `/mc score`. Each collectible has a difficulty tier (1 / 5 / 10 / 25 / 50 / 100) and your score is the sum of what you own.
- A **Legacies** count next to the score: collected items that can't be obtained anymore.
- **UI themes**: Modern (slate and bronze, the new default) and Simple (the old warm-gold look). Applies account-wide.
- Everything from **Revelations (12.0.7)**: Void Showdowns in Val and Naigtal, their rares and achievements, Showdown vendors, Rotmire, Dragonflight Timewalking, Midsummer, Lorewalking, Arcantina, and the opening Curse of Ula'tek story.
- Everything from **Curse of Ula'tek (12.1)**: the Coiled Isle, Vaults of Atal'Utek, Curse Surges, Zul'jarra's Forces, Captain Tokka's Crew, Season 2 Prey, three new Delves, Altar of Fangs, and the Venomous Abyss.
- Coiled Isle rare and treasure trackers, with waypoints and puzzle steps.
- New 12.1 housing decor, Community Coupon rewards, pet beds, mounts, pets, toys, and achievements. Season 2 rewards show their regional unlock date.

### Changed
- Achievements get their own row in the Collection Inspector.
- Learned recipes count account-wide now. Your alts share recipe progress.
- Item-priced collectibles show the item icon, how many you're carrying, and whether you can afford it.
- Targets client 12.1.0.
- The panel is wider to fit the new title-bar indicators.
- Collection sharing asks for consent on first run.
- Disabled tabs stay hidden but still feed your score and shared progress.
- Future rewards stay visible for planning.

### Fixed
- A Blizzard hotfix to an achievement can no longer blank a tab. Rows the game can't answer yet are skipped and retried for a couple of minutes.
- If Blizzard adds rares or treasures to an existing achievement, they just show up without needing for the addon to be updated.
- If an achievement's criteria get reordered, waypoints and puzzle steps fall back to safe lookups rather than pointing at the wrong spot.
- Corrected bad collectible records, achievement reward text, rare criterion order, 12.1 vendors, and vendor waypoints.

# 1.6.2
### Changed
- Mounts tab now has dedicated sections for the three Midnight feature systems: Prey, Ritual Sites, and Void Assaults.

# 1.6.1
### Fixed
- Eight mounts in the Mounts tab were showing wrong icons/tooltips because their journal IDs were mistyped. Corrected: 
  - Witherbark Warbear Mother
  - Void-Corrupted Hex Eagle
  - Void-Touched Hawkstrider
  - Void-Touched Snapdragon
  - Void-Corrupted Lynx
  - Retrained Skyrazor
  - Nether-Swept Drake
  - Magister's Spell Bee

# 1.6.0
### Renamed
- The addon is now called **Collectionist** (was "Midnight Collections"). The folder, .toc, and saved variables all use the new name. Existing players' saved data does not auto-migrate; if you had counts/peers/options from a previous version, they'll be reset.
### Added
- New **Achievements** tab tracking Midnight exploration, quest, collection, and feature achievements. Each row shows progress (e.g., "3 / 5"), tooltip lists each criterion with ✓/✗, and clicking drops waypoints for every incomplete criterion.
- Coverage includes Highest Peaks (Vistas), Skyriding Glyph Hunter, Midnight Lore Hunter, Ever Painting, Runestone Rush, Chronicler of the Haranir (all 21 books across 7 quest-gated series), The Party Must Go On, Sacred Buffet Devotee, Glory of the Midnight Hero/Raider, Midnight Safari, Preying For Midnight, Void Response Team, Ritual Site Disruptor, and many more.
- Chronicler of the Haranir tooltip shows each series' parent campaign quest as its own row.
- Collection Inspector now de-duplicates alts that share a Battle.net account into one row, showing the most-recently-seen character.
- "Clear" button in the Inspector header to wipe peer history (with confirmation).
- Click an achievement row to route waypoints when available; falls back to opening the achievement frame for activity-based achievements (e.g., "complete 100 ambushes").
### Fixed
- Decorations no longer get stuck at 0/260 on some reloads (the housing-catalog warmup was orphaning its searcher mid-callback).
- "X peers" indicator no longer over-counts by 1 once the BNet alt cache is built.
- Inspector progress bars now fill all the way to 100% (was capped 8px short).
- Inspector "selected" checkmark renders as a real green check (was a missing-glyph box).
- Re-adding a peer mid-fade-out no longer briefly hides the column.
- After /reload, the addon now waits a randomized 5-30 seconds before announcing itself to guildies, so big-guild raid reload waves don't all hit chat at once.
- Treasures tab icon now actually appears in retail clients.
- Options panel checkboxes word-wrap properly instead of truncating after 5 characters.
### Removed
- Idol of the Depths is no longer in the Toys tracker, not a toy

# 1.5.2
### Added
- Collection Inspector now smoothly animates when you add or remove a peer, with each column fading in/out instead of popping
- Default Inspector height already fits the columns, so the panel no longer jumps the first time you select someone
- Alts that share a Battle.net account collapse to a single row in the peer list, showing the most-recently-seen character
- "Clear" button in the Inspector header to wipe peer history (with confirmation)
- New Toy: Bouncy Mushroom from Naleidea Rivergleam at Delve HQ
- Standardized icon and row sizes across Mounts, Pets, Toys, and Decorations so everything looks uniform
### Fixed
- Inspector progress bars now fill all the way to the right edge at 100%
- Inspector "selected" checkmark renders as a real green check instead of a missing-glyph box
- Treasures tab icon now actually appears (previous icon path didn't exist in retail)
- Currency on Twilight's Blade Top Secret Strategy Training Guide is correctly labeled as Twilight's Blade Insignia
- Pets options checkbox renamed from "Wild Pet Nearby Alerts" to the clearer "Uncollected Pet Hover Alert"
### Removed
- Idol of the Depths is no longer in the Toys tracker (it's a quest item, not a toy)

# 1.5.1
### Added
- Decorations now scan correctly on every login. Fixed a race where the in-game housing catalog wasn't fully ready when the addon scanned, causing decorations to show as 0/260 even when you owned items.
### Fixed
- peer sharing so the addon re-announces itself and pings online guildies for their counts on each login, instead of only showing whoever happened to be cached.

# 1.5.0
### Added
- Sharing, a new optional feature
- A clickable "X peers" indicator in the panel title bar opens the Collection Inspector
- Pick guildies and Battle.net friends, they appear side-by-side on the right with red-to-green progress bars per tracker
- "You" is pinned at the top of the list
- Hover any collectible and it'll show which guildies/friends already own it
- First-launch onboarding popup lets you opt out of any tracker or sharing before anything's broadcast.
- Reorderable trackers. Up/down arrows next to each tracker in the options panel.
- Hide-unavailable toggles for Mounts, Pets, and Toys
### Fixed
- Decorations count doesn't populate correctly
- Tooltip longer overlaps the WoW tooltip near the top of the screen

# 1.4.1
### Added
- Vendor recipes now route through portals like the rest of the addon, and a handful of vendors that were missing waypoints have them now (Ranger Allorn in Eversong, plus Zaralda, Hesta Forlath, and Materialist Ophinell).

# 1.4.0
### Added
- Treasures tab. All 38 zone chests, with step-by-step notes for the puzzle ones.
- Checklists. Collectibles gated on quest chains or meta-achievements now show live ✓/✗ progress in their tooltip, and clicking the row drops waypoints to whatever's left. Works on a couple dozen items including Sootpaw, the Glory mounts, Echo of Aln'sharan, Do Child of Filo, the Family Battler pets, Dundun's Travel Method, Gift of the Cycle, and the rare-kill decorations.
- Per-character settings. alts now inherit your last character's setup instead of starting from defaults.
### Fixed
- Tooltip overlapping the WoW tooltip near the top of the screen
- Shift-click (Wowhead) and ctrl-click (info) not working on collected items and learned recipes
- Dragging the panel can accidentally toggle minimize
- /mc reset sometimes parks the panel off-screen
- Decorations tab lags while you're sorting things into housing chests

# 1.2.0
### Added
- New Rares tab tracking all zone-rare achievements with waypoints
- Multi-spawn waypoints for items like Void-Touched Lynx Kitten
- Portal-aware routing through The Den and Howling Ridge
- Ctrl-click any row prints its full info to chat
- Double-click the title bar to minimize
- Ritual Sites renown gates added for the new pets
- Hides discontinued prepatch items
### Fixed
- Wowhead URL popup not populating correctly
