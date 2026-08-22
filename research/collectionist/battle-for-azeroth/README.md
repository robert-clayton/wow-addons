# Battle for Azeroth collection inventory

This expansion has exact ID manifests and generated runtime data. The inventory is reproducible from the final Legion and Battle for Azeroth DB2 snapshots, current retail DB2 cross-checks, the acquisition-first housing audit, and stable achievement-criteria entity joins.

## Snapshot boundary

- Final Legion baseline: `7.3.5.26972`
- Final Battle for Azeroth snapshot: `8.3.7.35662`
- Current retail cross-check: `12.1.0.69382`

Historical DB2 CSVs come from `https://wago.tools/db2/<Table>/csv?build=<build>&locale=enUS`.

## Release manifests

- 140 mounts; 23 external-policy rows and 2 internal/unobtainable rows are excluded from the 165-row snapshot delta.
- 236 battle pets; 11 Pandaria-acquisition rows, 232 non-collectible battle NPCs, 9 external-policy rows, and 1 internal test pet are excluded.
- 135 toys; 6 external-policy rows and 2 internal or never-implemented rows are excluded.
- 136 housing decorations assigned by current BFA acquisition paths.
- 452 visible player-facing achievements across the eight BFA category roots, with 2,851 current-trackable criteria-tree leaves.
- 1,253 named recipes in the nine professions supported by Collectionist: 1,231 historical BFA recipes plus 22 housing recipes taught by Kul Tiran and Zandalari profession tiers.
- 254 current ordered rare/special-encounter criteria across eight achievements.
- 98 ordered treasure/hidden-object criteria across eight achievements.
- 14 supporting currencies, 19 factions, and 10 primary maps.

The seven currently unavailable mounts remain visible and are marked unavailable: the four BFA Gladiator proto-drakes, Bruce, Uncorrupted Voidwing, and Awakened Mindborer.

## Rare entity joins

BFA zone achievements mix creature-kill criteria with completion-quest criteria. The completion quest is not a usable NPC ID. `sources/rare-npc-audit.csv` joins all 158 quest-style criteria to their provider entity using the corresponding stable criteria ID in All The Things' zone data.

- 153 resolve to NPC IDs.
- 5 resolve to game-object IDs: Strange Mushroom Ring, Ancient Sarcophagus, Seething Cache, Urn of Agussu, and Vaultbot.

The generated rare data preserves separate positional NPC and object arrays so the scanner never mistakes a completion quest for an NPC.

## Decoration ownership rule

Housing decor was added after Battle for Azeroth. Expansion ownership follows the content that actually awards or unlocks the decoration, not the housing row's creation build, item expansion field, visual theme, or the date a housing vendor was added.

- Include a decoration when at least one current acquisition path uses Battle for Azeroth content: a BFA quest, achievement, reputation, profession, currency, dungeon, raid, rare, treasure, or other BFA requirement.
- A later alternate source does not move an older reward forward. For example, Bolt Chair remains BFA-owned because it is obtainable in Mechagon for Spare Parts even though it also has a Dornogal source.
- A new vendor standing in an older location is not enough by itself. The vendor must expose an older-content acquisition path or requirement.
- Hidden and internal catalog rows are not collectible manifest entries.

The live `https://housing.wowdb.com/decor/` catalog was scanned acquisition-first on 2026-08-19: all 2,911 rows across 122 catalog pages, followed by the 208 rows carrying the Battle for Azeroth theme tag.

The resulting exact BFA-owned decoration set currently contains 136 unique decor IDs:

- 126 rows also carry the BFA theme tag.
- 10 rows were found only by scanning the full catalog for BFA acquisition sources despite another expansion theme tag.

The BFA-theme audit rejected 82 rows that do not belong to BFA:

- 49 Midnight acquisitions
- 4 Wrath acquisitions
- 1 The War Within acquisition
- 2 Legion acquisitions
- 1 Classic acquisition
- 14 hidden catalog rows
- 11 internal or deprecated DNT rows

The four PvP flag rewards are assigned to Wrath because their required achievements were introduced in patch 3.0.2. The housing reward and vendor were added later, but the unlock requirement is Wrath-era content.

## Sources

- `sources/housing-wowdb-acquisition-audit.csv`: the 136 confirmed BFA-owned decoration IDs and their exact acquisition identifiers.
- `sources/housing-wowdb-theme-exclusions.csv`: every BFA-themed row excluded because its actual acquisition belongs elsewhere or it is not collectible.
- `sources/rare-npc-audit.csv`: exact completion-quest criteria to NPC/object joins for the BFA rare achievements.
- `ids/`: broad snapshot inventories and classification decisions.
- `manifests/`: exact release sets consumed by the Lua generator and validators.

The catalog is evidence for current acquisition paths. Historical DB2 snapshots remain the source for expansion-era achievement, creature, quest, item, spell, currency, faction, criteria, and map IDs.
