# Legion collection inventory

This expansion has exact ID manifests and generated runtime data. The inventory is reproducible from the final Legion DB2 snapshot, current retail DB2 cross-checks, the acquisition-first housing audit, and stable achievement-criteria entity joins.

## Snapshot boundary

- Final Legion snapshot: `7.3.5.26972`
- Current retail cross-check: `12.1.0.69382`

Historical DB2 CSVs come from `https://wago.tools/db2/<Table>/csv?build=<build>&locale=enUS`.

A final Warlords of Draenor DB2 export was not available from that endpoint. Mounts and toys therefore use a reviewed lower-ID boundary in the final Legion snapshot plus explicit Warlords exclusions. Pets use the collectible species boundary beginning at species ID 1699. Every selected runtime ID is also required to exist in current retail.

## Release manifests

- 124 mounts; 22 late-Warlords rows and 7 external-policy rows are excluded from the 153-row historical boundary.
- 106 battle pets; 19 Wrath-acquisition rows, 9 Cataclysm-acquisition rows, 2 Pandaria-acquisition rows, 6 external-policy rows, and 4 internal, placeholder, or never-released pets are excluded.
- 154 toys; 3 Classic-acquisition rows, 13 TBC-acquisition rows, 7 Wrath-acquisition rows, 8 Cataclysm-acquisition rows, 18 Pandaria-acquisition rows, 18 Warlords-acquisition rows, 2 promotional rows, and 6 internal or never-implemented rows are excluded.
- 211 housing decorations assigned by current Legion acquisition paths.
- 305 visible player-facing achievements across eight Legion category roots, with 2,411 stable criteria-tree leaves.
- 773 named recipes in the nine professions supported by Collectionist: 750 historical Legion recipes plus 23 housing recipes taught by Legion profession tiers.
- 185 ordered rare/special-encounter criteria across six achievements.
- 314 ordered treasure/hidden-object criteria across six achievements.
- 12 supporting currencies, 18 factions, and 11 primary maps.

Nine mounts remain visible but are marked unavailable: the seven Legion Gladiator storm dragons, Brawler's Burly Basilisk, and Violet Spellwing. Felbat Pup and Tylarr Gronnden are likewise retained and marked unavailable.

## Rare entity joins

The five Broken Isles adventurer achievements mix creature-kill criteria with completion-quest criteria. Completion quests are not usable NPC IDs. `sources/rare-npc-audit.csv` joins all 105 quest-style criteria to their provider entity using the corresponding stable criteria ID in All The Things' zone data. Commander of Argus contributes 60 direct creature criteria.

- Every one of the 185 criteria resolves to an NPC or game object.
- Seven criteria resolve to game-object IDs rather than NPCs.

The generated rare data preserves separate positional NPC and object arrays so the scanner does not mistake completion quests for NPCs.

## Decoration ownership rule

Housing decor was added after Legion. Expansion ownership follows the content that actually awards or unlocks the decoration, not the housing row's creation build, item expansion field, visual theme, or the date a housing vendor was added.

- Include a decoration when at least one current acquisition path uses Legion content: a Legion quest, achievement, reputation, profession, currency, dungeon, raid, rare, treasure, class hall, or other Legion requirement.
- A later alternate source does not move an older reward forward.
- A new vendor standing in an older location is not enough by itself; the acquisition path or requirement must be Legion content.
- Hidden and internal catalog rows are not collectible manifest entries.

The live `https://housing.wowdb.com/decor/` catalog was scanned acquisition-first on 2026-08-19: all 2,911 rows across 122 catalog pages, followed by all 255 rows carrying the Legion theme tag.

The resulting exact Legion-owned decoration set contains 211 unique decor IDs:

- 197 rows also carry the Legion theme tag.
- 14 rows were found only by scanning the full catalog for Legion acquisition sources despite another expansion theme tag.

The Legion-theme audit rejected 58 rows that do not belong to Legion:

- 2 Battle for Azeroth acquisitions
- 2 Dragonflight acquisitions
- 18 Midnight acquisitions
- 2 The War Within acquisitions
- 3 Wrath acquisitions
- 16 hidden or source-less catalog rows
- 15 internal, deprecated, or DNT rows

## Sources

- `sources/housing-wowdb-acquisition-audit.csv`: the 211 confirmed Legion-owned decoration IDs and their exact acquisition identifiers.
- `sources/housing-wowdb-theme-exclusions.csv`: every Legion-themed row excluded because its actual acquisition belongs elsewhere or it is not collectible.
- `sources/rare-npc-audit.csv`: exact completion-quest criteria to NPC/object joins for the Legion rare achievements.
- `ids/`: broad historical inventories and classification decisions.
- `manifests/`: exact release sets consumed by the Lua generator and validators.

The housing catalog is evidence for current acquisition paths. The final Legion DB2 snapshot remains the source for expansion-era achievement, creature, quest, item, spell, currency, faction, criteria, and profession IDs; current retail DB2 supplies the map and housing tables and verifies retained IDs.
