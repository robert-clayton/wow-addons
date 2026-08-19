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
