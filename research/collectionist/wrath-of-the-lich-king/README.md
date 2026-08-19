# Collectionist Wrath of the Lich King ID inventory

This expansion has exact ID manifests, generated runtime data, TOC integration, exact runtime validation, and mocked scanner coverage under Collectionist's `wrath` expansion key.

## Snapshots and sources

- Final Wrath Classic snapshot: `3.4.3.54261`
- Historical retail achievement/criteria snapshot: `7.3.5.26972`
- Current-retail validation snapshot: `12.1.0.69382`
- DB2 exports: `https://wago.tools/db2`
- Blizzard collectible guide: `https://news.blizzard.com/en-us/article/23507736/wrath-of-the-lich-king-mounts-pets-and-more`
- Current housing catalog: `https://housing.wowdb.com/decor/`
- All The Things source trees: `https://github.com/DFortun81/AllTheThings`

ATT patch chronology supplies the broad mount and toy boundary, the final Wrath Classic snapshot supplies the profession boundary, and current DB2 relationships resolve stable retail IDs. Blizzard's maintained guide independently maps 49 mounts, 50 pets, and 25 toys. The guide is evidence rather than an ownership oracle: Censer of Eternal Agony is listed there but is acquired from the Pandaria Timeless Isle and is therefore excluded from Wrath.

## Frozen release manifests

The exact ID sets under `manifests/` contain:

- 93 mounts from 110 current IDs mapped from Wrath patch rows.
- 50 battle pets from the official acquisition guide, including later-added pets whose acquisition requires Wrath zones or raids.
- 36 toys from 46 audited current candidates.
- 27 housing decorations assigned by current Wrath acquisition requirements.
- 384 player-facing achievements with 1,352 achievement-tree leaves.
- 860 recipes, including 21 current Wrath housing recipes.
- 23 ordered rare NPCs from the canonical **Frostbitten** achievement.
- 0 treasure criteria because Wrath has no comparable expansion-wide treasure checklist achievement.
- 13 maps, 19 factions, and 13 currencies used as supporting IDs.

Regenerate and validate with:

```powershell
./scripts/generate-collectionist-wrath-housing-audit.ps1
./scripts/generate-collectionist-wrath-id-inventory.ps1
./scripts/validate-collectionist-wrath-manifests.ps1
./scripts/generate-collectionist-wrath-lua.ps1
./scripts/validate-collectionist-wrath-runtime.ps1
```

## Decoration ownership rule

Housing was introduced after Wrath, but a decoration belongs to the expansion whose content is required to earn or unlock it.

- Include a decoration when a current acquisition path requires a Wrath quest, achievement, profession, dungeon, raid, daily, or equivalent Wrath system.
- Creation build, item expansion metadata, visual theme, catalog tag, and vendor location do not establish ownership by themselves.
- A later alternate source does not move an earlier Wrath acquisition into a later expansion.
- Hidden and source-less catalog rows are not collectible manifest entries.

The acquisition-first scan covers all 2,911 live catalog rows and separately audits the 22 Wrath-themed rows. Nineteen themed rows are Wrath-owned, while eight Wrath acquisitions sit outside that theme filter, producing exactly 27 decorations:

- 21 Northrend profession recipes.
- 2 direct quest rewards.
- 2 achievement rewards.
- 1 Dalaran cooking-daily reward.
- 1 Pit of Saron encounter drop.

The eight non-themed rows are Head of the Broodmother, Wooden Outhouse, Nesingwary Mounted Shoveltusk Head, Snowfall Tribe Scare-Totem, Eversong Party Platter, Wolvar Postbag, Kirin Tor Glass Table, and Murloc Driftwood Hut. Head of the Broodmother remains Wrath-owned because its oldest acquisition is the Onyxia achievement **More Dots! (25 player)**; a later vendor source does not move it forward. The three themed exclusions are Banner of the Ebon Blade and Yellowed Kelp Pile, whose acquisitions require Midnight, plus the hidden and source-less Breanni's Menagerie Aquarium row.

Housing evidence is retained in:

- `sources/housing-wowdb-acquisition-audit.csv`: all 27 confirmed Wrath-owned decorations.
- `sources/housing-wowdb-theme-exclusions.csv`: all 3 themed rows rejected by acquisition ownership or collectibility.
- `sources/housing-wowdb-theme-catalog.csv`: the complete 22-row themed candidate set.
- `sources/housing-wowdb-global-acquisition-crosscheck.csv`: the exact 30 rows hit by the theme and reverse acquisition scan.

## Other collectible boundaries

The mount inventory maps 110 current mount IDs from ATT's Wrath patch sections. Thirteen trading-card, store, recruit-a-friend, or other external-policy rewards are excluded. Four rows marked NYI by ATT are excluded as never-implemented/internal: Black Polar Bear, both Grand Caravan Mammoths, and Blue Skeletal Warhorse. The remaining 93 mounts are retained. Ten historical rewards are marked unavailable rather than dropped: Black and Plagued Proto-Drakes, four ended Gladiator frost wyrms, Swift Horde Wolf, Swift Alliance Steed, and the two Crusader warhorses.

The toy inventory resolves 42 current IDs from 44 Wrath patch rows, replaces the retired Chef's Hat item with its current wrapper, and adds the three current Wrath Timewalking toys. Seven trading-card rewards are excluded under the external policy. Censer of Eternal Agony is assigned to Pandaria. Darkspear Pride and Gnomeregan Pride are assigned to Cataclysm because their acquisition required the Cataclysm pre-launch quest events; the Cataclysm research manifest was corrected to retain both as unavailable toys.

## Achievement, rare, and recipe structure

The seven Wrath achievement categories contain 384 current IDs:

- 12 exploration, 80 dungeon, 203 raid, 21 quest, 14 reputation, 19 Wintergrasp, and 35 Argent Tournament achievements.
- 1,352 total leaf criteria; 239 achievements with 2–30 leaves expose 1,207 stable runtime task rows.
- The 23 `Frostbitten` leaves all resolve directly to rare NPC IDs and form the rare manifest.

The 860 recipes resolve to 69 Alchemy, 128 Blacksmithing, 46 Cooking, 69 Enchanting, 51 Engineering, 29 Inscription, 217 Jewelcrafting, 154 Leatherworking, and 97 Tailoring spells. Every selected spell and skill-line ability still exists in current retail, and all 21 current Wrath housing recipes are explicitly frozen.

## Runtime integration

Twenty-six source-owned rows formerly overlapped the Legion manifests: 19 pet species and 7 toys. They now belong only to Wrath, and the manifest validator requires zero overlap with every later expansion.

The eight generated catalogs load before Cataclysm. Runtime validation requires exact manifest equality, ordered Frostbitten NPC criteria, all 13 map constants, exact achievement tasks, TOC ordering, and Lua syntax. The treasure catalog intentionally registers an empty set because Wrath has no comparable expansion-wide treasure checklist. Re-run the generator against current retail immediately before packaging to detect upstream DB2 or housing-catalog changes.
