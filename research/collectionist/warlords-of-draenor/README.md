# Warlords of Draenor collection inventory

This expansion has exact ID inventories, release manifests, generated runtime data, and manifest-to-runtime validation. The final Legion snapshot supplies the historical boundary because the final Warlords DB2 snapshot is unavailable; every selected release ID is also checked against current retail.

## Release manifests

- 68 mounts from a 73-row historical boundary; five store or collector-edition mounts are excluded.
- 84 battle pets from a 104-row collectible boundary; 13 TBC-acquisition pets, six external promotional/shop pets, and the Legion collector-edition pet are excluded.
- 91 toys from a 101-row acquisition audit. Eight older toys merely exposed by Warlords vendors, Noble's Eternal Elementium Signet, and Soft Foam Sword are excluded.
- 80 housing decorations assigned by current Warlords acquisition paths.
- 402 visible player-facing achievements across 13 Warlords category roots, with 3,036 stable criteria-tree leaves.
- 337 current named recipes: 316 surviving historical recipes plus 21 housing recipes taught by Draenor profession tiers. The inventory retains 37 historical recipe rows whose ability or spell name no longer exists in current retail.
- 72 ordered rare criteria across three canonical achievements; the duplicate partial Tanaan achievement is excluded.
- 368 ordered treasure criteria across three canonical achievements; threshold and partial duplicates are excluded.
- 17 supporting currencies, 20 factions, and 9 primary maps.

Seven retained mounts are marked unavailable: Core Hound, Warlord's Deathwheel, Challenger's War Yeti, the three Warlords Gladiator gronnlings, and Grove Warden. Blizzard's original notices establish the limited anniversary window, the September 30, 2014 chopper qualification cutoff, the Challenge Mode shutdown, each PvP season end, and Grove Warden's removal at Legion launch.

## Decoration ownership rule

Housing was introduced after Warlords, so a decoration's creation build, item expansion field, visual theme, or catalog expansion tag cannot assign it to Warlords. Ownership follows the content actually required to earn or unlock it.

- Include a decoration when at least one current acquisition path requires Warlords content: a Warlords quest, achievement, reputation, profession, currency, dungeon, raid, rare, treasure, garrison system, or equivalent Warlords requirement.
- A vendor merely standing in a Warlords zone is not sufficient. The purchase or unlock must itself depend on Warlords content.
- A later alternate source does not move an earlier acquisition forward.
- Hidden, source-less, internal, deprecated, and DNT rows are not collectible manifest entries.

## Housing result

The live `https://housing.wowdb.com/decor/` catalog was scanned acquisition-first on 2026-08-19: all 2,911 rows across 122 catalog pages, followed by the 142 rows carrying the Warlords theme tag.

The exact Warlords-owned set contains 80 decoration IDs:

- 21 crafted through Draenor profession categories
- 26 vendor or reputation acquisitions
- 27 quest unlocks
- 5 dungeon or raid drops
- 1 achievement unlock

The 142-row theme catalog contains 62 exclusions whose acquisition belongs to another expansion or which are not collectible. The reverse global scan found no Warlords acquisition outside the Warlords theme set. Its 83 source-signal candidates resolve to all 80 confirmed decorations plus exactly three known non-Warlords rows: Rolled Scroll (126), Gate of the Apexis (3835), and an internal DNT garrison torch (21889).

The global ID cross-check independently accounts for:

- all 27 decorations linked to quests recorded in Warlords ATT source trees
- all 48 decorations linked to Warlords NPCs
- all 41 decorations linked to Warlords currencies
- all 21 Draenor-profession decorations

`Secrets of Skettis` (achievement 9415), required by decoration 12200, is an acquisition support ID even though Blizzard places it under the generic Archaeology achievement category rather than a Draenor category.

## Sources

- `sources/housing-wowdb-acquisition-audit.csv`: the 80 confirmed Warlords-owned decorations and exact acquisition identifiers.
- `sources/housing-wowdb-theme-exclusions.csv`: all 62 Warlords-themed rows rejected by acquisition ownership or collectibility.
- `sources/housing-wowdb-theme-catalog.csv`: the complete 142-row themed candidate catalog.
- `sources/housing-wowdb-global-acquisition-crosscheck.csv`: the 83 source-signal candidates from the full 2,911-row reverse scan.
- `sources/blizzard-wod-collectibles.csv`: all 190 rows in Blizzard's maintained Warlords mount, pet, and toy guide, including rows added after the final Legion snapshot.
- `ids/`: broad historical candidates, current-retail checks, and release decisions.
- `manifests/`: exact release sets consumed by `scripts/generate-collectionist-wod-lua.ps1` and both Warlords validators.

The housing catalog establishes current acquisition paths. Final Legion DB2 provides the nearest historical boundary for Warlords achievements, criteria, mounts, pets, toys, recipes, currencies, and factions; current retail DB2 verifies that selected IDs still exist and supplies the 21 explicit Draenor `House Decor` profession recipes added with housing. Runtime validation proves that the shipped Lua contains the exact manifest sets, ordered rare and treasure criteria, unavailable classifications, map constants, and all 981 eligible achievement task rows.
