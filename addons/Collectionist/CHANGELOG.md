# 1.12.0
### Fixed
- Tabs no longer go permanently blank when Blizzard removes or hotfixes an achievement mid-patch. Rows the game can't answer for yet are skipped and picked up automatically within a couple of minutes, and rares or treasures Blizzard adds to an existing achievement now show up without waiting for an addon update.
- Guild sharing keeps working after achievement hotfixes instead of silently stopping — "Owned by" tooltip lines and your shared counts no longer vanish for the whole guild when one achievement changes. Shared counts also hold steady while your own data is still loading, so guildmates never see your collection briefly shrink after you log in.
- Switching the expansion filter right after logging in now shows the correct rows within a couple of seconds instead of leaving the previous filter's list on screen.
- The panel opens at a usable size after upgrading, instead of squashing the title-bar buttons together at a width saved by an older version.
- Fresh installs and returning players learn about guildmates' shared collections at login again. The request only goes out when your peer list is empty or stale, so guild-wide reload waves stay quiet.
- If a rare or treasure achievement changes shape, waypoints and puzzle instructions now fall back to safe lookups instead of possibly pointing at the wrong spot.
- Thin highlight lines from the Recipes tab's progress bars no longer linger over other tabs.

# 1.11.0
### Added
- Full **Revelations (12.0.7)** coverage: Void Showdowns in Val and Naigtal, their rare metas and achievements, Showdown vendors, Rotmire, Dragonflight Timewalking, Midsummer rewards, Lorewalking, Arcantina, and the opening Curse of Ula'tek story.
- Full **Curse of Ula'tek (12.1)** coverage: the Coiled Isle, Vaults of Atal'Utek, Curse Surges, Zul'jarra's Forces, Captain Tokka's Crew, Season 2 Prey, three new Delves, Altar of Fangs, and the Venomous Abyss.
- Coiled Isle rare and treasure trackers with waypoints and puzzle instructions.
- New 12.1 housing decor, Community Coupon rewards, pet beds, mounts, pets, toys, and achievements. Season 2 rewards are clearly labeled with their regional unlock date.
### Changed
- Updated the client interface target to 12.1.0.
- Item-based collectible costs now show the item icon, live inventory count, and affordability color in tooltips.
### Fixed
- Future rewards stay visible for planning without entering completion totals or Collection Score before their regional unlock; the schedule follows Blizzard's corrected patch-week and Season 2 rollout.
- Achievement, rare, and treasure scans now wait for complete Blizzard data instead of publishing false incomplete snapshots, and achievement icons use the correct API field.
- Housing decor ownership now recognizes redeemable copies and current Housing API signatures, with correct item-icon fallbacks.
- Corrected invalid and missing collectible records, achievement reward text, rare criterion order, 12.1 vendors, and vendor waypoints.
- Large roster snapshots can no longer combine chunks from different broadcasts, and wide peer columns remain clipped to the scrolling area.
- Release archives now enforce tag/version/changelog agreement, honor packaging exclusions, compile and smoke-load every shipped Lua file, and publish permanent GitHub Releases.

# 1.10.0
### Added
- Achievements now appear as their own row in the Collection Inspector, so you can compare achievement progress with guildmates like any other collection.
- **UI themes.** Two looks to choose from: **Modern** (the new default — slate and bronze with subtle gradients and row separators) and **Simple** (the classic warm-gold appearance from earlier versions). Switch anytime in `/mc options` or with `/mc theme modern|simple`. Your choice is shared account-wide across all your characters.
### Changed
- Collection Score now uses six clearer time tiers (1 / 5 / 10 / 25 / 50 / 100).
- Disabled tracker tabs stay hidden but continue to keep score and shared progress current.
### Fixed
- Sharing now waits for explicit first-run consent, retries safely after encounters, and no longer creates guild-wide reply storms on login.
- Collection updates now refresh score and sharing even when their tab is not open.
- Rare and treasure ownership sharing uses locale-independent criterion IDs and waits for the full achievement cache.
- Legacy-item totals use the same denominator for every player, regardless of ownership or display settings.
- The minimap right-click summary now waits for its scan, and says which expansion slice its per-source breakdown covers.
- Inspector filters no longer reset when peers are selected, and wide comparisons scroll instead of growing off-screen.
- “Current” selects the newest expansion available to each tracker rather than blanking trackers without newer content.

# 1.9.0
### Added
- **Collection Score (CS).** A time-investment score: each collectible has a weight (1 / 5 / 25 / 100 / 500) and your CS is the sum across everything you've collected. Shown in the panel title bar, in the Inspector, and via `/mc score`.
- **Legacies count** alongside the CS — a separate tally of collected items that are no longer obtainable.
- Recipe progress persists in the account-wide recipe ledger so learned recipes count across alts.

# 1.8.0
### Added
- Collection Inspector's expansion filter now rescopes peer columns, falling back to account-wide totals for peers without an expansion slice.
### Fixed
- Bitmap ownership probes query achievement criteria directly instead of filter-scoped scanner results.

# 1.7.0
### Added
- Expansion filter in the title bar, with Current, All Expansions, and pinned-expansion modes.
- `/mc filter all|current|<expansion>` slash command.
- Internal registration infrastructure for adding older-expansion content.

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
