# Collectionist TWW ID inventory

This began as the ID-first acquisition pass for adding **The War Within** (`tww`) to Collectionist. The frozen release manifests are now registered in the addon; source prose and structured metadata are included where the evidence supports them, while coordinates and other details are never inferred.

## Snapshots

- Final Dragonflight baseline: `10.2.7.55664`
- Final TWW snapshot: `11.2.7.65299`
- Current-retail validation snapshot: `12.1.0.69382`

DB2 CSVs come from `https://wago.tools/db2/<Table>/csv?build=<build>&locale=enUS`. The Dragonflight-to-TWW difference provides the broad candidate set. Final TWW rows are then joined across the relevant DB2 tables instead of trusting names alone.

The generator expects the three snapshot directories and cached guide HTML under `%TEMP%/collectionist-tww-db2/`. The generated CSVs are committed research artifacts; the temporary source cache is intentionally not part of the addon.

Housing decor is a special case: the feature and its records arrived with Midnight, but many decorations are awarded by earlier-expansion content. Decoration ownership therefore follows the acquisition source. DB2 creation date and the live catalog's thematic expansion tag are retained as audit evidence only; neither assigns an expansion by itself.

The mount and pet inventories are additionally cross-checked against Wowhead's expansion and patch collection guides. This matters because the final TWW client contains preloaded records for later content, while some TWW releases reuse older themes or source zones.

## Source references

- Build chronology: `https://warcraft.wiki.gg/wiki/Public_client_builds`
- DB2 exports: `https://wago.tools/db2`
- Mount guides: `https://www.wowhead.com/guide/collections/the-war-within/mounts`, `https://www.wowhead.com/guide/collections/the-war-within/mounts-guide-sources-karesh`, and `https://www.wowhead.com/guide/collections/the-war-within/mounts-sources-patch-11-2-7`
- Pet guides: `https://www.wowhead.com/guide/collections/the-war-within/battle-pet-collection-overview`, `https://www.wowhead.com/guide/collections/the-war-within/wild-pet-collection-khaz-algar-safari`, `https://www.wowhead.com/guide/collections/the-war-within/battle-pet-collection-siren-isle`, `https://www.wowhead.com/guide/collections/the-war-within/battle-pet-collection-undermine`, and `https://www.wowhead.com/guide/collections/the-war-within/battle-pets-karesh-sources`
- Pet preload corrections: `https://warcraft.wiki.gg/wiki/Family_Battler_of_Northrend` and `https://www.wowhead.com/npc=222077/waddles`
- Rare and treasure guides: `https://www.wowhead.com/guide/the-war-within/azj-kahet-rares-and-treasures`, `https://www.wowhead.com/guide/the-war-within/karesh-rares-and-treasures`, and `https://www.wowhead.com/achievement=41046/clean-up-on-isle-siren`
- Housing catalog: `https://housing.wowdb.com/decor/?expansion=the-war-within`
- Brawler's Guild season attribution for `decor_id=10913`, `12263`, and `14815`: `https://warcraft.wiki.gg/wiki/Brawler%27s_Guild`
- Lich King Lorewalking attribution for `decor_id=11453`: `https://warcraft.wiki.gg/wiki/Lorewalking%3A_The_Lich_King`

## Confidence labels

- `guide_confirmed`: present in a TWW collection guide and joined to the DB2 mount or species record through item/spell or creature ID.
- `item_expansion_confirmed`: the toy's item is explicitly marked with `ExpansionID=10`.
- `tww_category_confirmed`: the achievement belongs to a player-facing TWW-specific achievement category and does not carry the hidden/internal DB2 flag. The parallel Dungeons & Raids statistics category is intentionally excluded.
- `tww_category_hidden`: a TWW-category helper, criterion-level, copy, tracker, or other internal achievement carrying the hidden DB2 flag; retain for relation audits but exclude from the release manifest.
- `db2_tww_signal`: strong TWW item-expansion or source-text evidence, but not yet independently guide-confirmed.
- `snapshot_candidate`: added between the final Dragonflight and final TWW snapshots, but needs classification because the client contains preloaded and cross-expansion records.
- `snapshot_candidate_needs_source_expansion`: valid housing decor ID present in the final TWW client data, but no live catalog acquisition source assigns it to an expansion.
- `acquisition_tww_confirmed`: a current decor whose documented vendor, quest, achievement, encounter, currency, or Khaz Algar profession source is TWW content.
- `acquisition_dragonflight_confirmed`: a TWW-themed catalog row whose documented acquisition source is Dragonflight content.
- `acquisition_midnight_confirmed`: a TWW-themed catalog row whose documented acquisition source is Midnight content.
- `catalog_acquisition_unresolved`: a usable TWW-themed catalog row whose acquisition source is absent or not specific enough to assign an expansion.
- `catalog_hidden_unobtainable`: a TWW-themed catalog row whose live item page has no acquisition source and explicitly carries `HIDDENINCATALOG`; exclude it until current evidence changes.
- `noncollectible_pet_battle_npc`: a species-shaped pet-battle opponent row with no summon spell; do not treat it as a journal collectible unless independently guide-confirmed.
- `post_tww_preload`: a collectible row present in the final TWW data but released or sourced in Midnight; exclude it from TWW.
- `internal_dnt`: internal/test housing row; do not add to the addon.
- `removed_after_tww`: present in the final TWW snapshot but absent from current retail.
- `named_recipe`: a Khaz Algar skill-line ability with a corresponding spell-name record.
- `unnamed_db2_ability_candidate`: a Khaz Algar skill-line ability with no spell-name record; retain for auditing, but do not treat it as an implementation-ready recipe.

## Generated inventories

Run:

```powershell
./scripts/generate-collectionist-tww-id-inventory.ps1
```

The script writes CSVs under `research/collectionist/tww/ids/`:

- `mounts.csv`: mount ID, source spell, associated item IDs, and confidence.
- `pets.csv`: species, creature, summon spell, associated item IDs, family enum, and flags.
- `toys.csv`: toy and item IDs.
- `decorations.csv`: decor/item IDs from the final TWW client table plus current TWW-themed live-catalog rows, enriched with acquisition text/IDs and an independently derived acquisition expansion.
- `achievements.csv`: broad TWW-era achievement candidates with category and criteria-tree IDs.
- `achievement-criteria.csv`: leaf criterion IDs/assets for TWW-specific achievement categories.
- `rares.csv`: the seven TWW rare-achievement groups with ordered criteria and resolved NPC IDs where available.
- `treasures.csv`: the seven TWW treasure-achievement groups with ordered criteria and asset IDs.
- `recipes.csv`: exact recipe spell IDs under the nine Khaz Algar crafting-profession category trees.
- `maps.csv`, `factions.csv`, and `currencies.csv`: supporting IDs needed by later enrichment.

Every primary collectible inventory includes current-retail validation. Recipes separately record whether the skill-line mapping and spell-name record still exist.

The script also writes release inclusion manifests under `research/collectionist/tww/manifests/`. These are the exact ID sets intended for addon registration, separated from the broader audit inventories. The decoration manifest is filtered by acquisition evidence and excludes theme-only, cross-expansion, internal, and hidden catalog rows. Mount, pet, and toy rows carry an explicit `release_decision`; their manifests preserve the addon's documented store/promotion/internal exclusions and include confirmed TWW-era event additions.

Current manifest totals are 186 mounts, 200 pets, 99 toys, 108 decorations, 696 recipes, 381 player-facing achievements with 1,987 achievement-tree leaves, 140 rare criteria, and 86 treasure criteria. `manifests/summary.csv` records the identifier field for each set. The addon data now matches the mount, pet, toy, decoration, recipe, and achievement manifests exactly; `scripts/validate-collectionist-tww-manifests.ps1` enforces those primary-ID sets.

## Validated snapshot totals

- Mounts: 171 guide-confirmed, 1 additional strong DB2 signal, 44 confirmed Legion Remix additions, 69 store/trading/promotion exclusions, and 5 unavailable/internal rows.
- Battle pets: 210 guide-confirmed, 5 additional strong TWW DB2 signals, 2 audited Midnight preloads, 39 unresolved collectible candidates, and 36 noncollectible battle-NPC rows.
- Toys: 97 item-expansion-confirmed, 2 additional strong DB2 signals, and 21 unresolved snapshot candidates.
- Recipes: 696 named recipe spell IDs, including the exact 24 housing recipes taught by Khaz Algar profession tiers, and 8 unnamed Alchemy ability candidates. All 704 skill-line mappings still exist in current retail; the eight candidates have no spell-name record in either snapshot.
- Achievements: 381 current player-facing IDs in TWW-specific categories, 124 hidden/internal category rows retained for relationship auditing, and 1,687 broader snapshot candidates.
- Rare criteria: 140 ordered criteria across seven zone/meta achievements, with NPC IDs resolved.
- Treasure criteria: 86 ordered criteria across seven zone/meta achievements.
- Housing decor: 108 source-confirmed TWW acquisitions, 33 Midnight acquisitions, one Dragonflight acquisition, 14 hidden/unobtainable catalog rows, 91 internal/DNT rows, 1,231 snapshot rows without acquisition attribution, and one row removed after TWW (`decor_id=11770`, `item_id=257797`). The 2,911-row full-catalog acquisition pass adds six non-TWW-themed rewards: K'areshi Protectorate Portal, Cartel Collector's Cage, Gob-chanical Trash Heap, Tale of the Penultimate Lich King, Brawler's Guild Punching Bag, and Brawler's Barricade. All 163 TWW-themed live-catalog IDs and names still match current DB2. Creation chronology is recorded but does not control expansion ownership.

## Implemented release boundary

1. The 186-mount module includes all 44 Legion Remix Mount Journal rewards, retains their official Bronze costs, and marks them unavailable because the event ended. The Druid Remix reward is a flight form rather than a mount and is not in the mount manifest.
2. The decoration module contains only the 108 acquisition-confirmed TWW rows. The 14 hidden housing rows stay excluded unless a live acquisition source appears.
3. All 381 player-facing achievements are registered as 161 general, 113 delve, 34 dungeon, and 73 raid rows. Multi-criterion achievements with 2-30 criteria expose 1,485 stable criteria IDs in progress tooltips. Single-objective achievements and three unusually large counters defer to Blizzard's native achievement UI.
4. Mount, pet, toy, decoration, achievement, and recipe manifest equality is a checked release gate alongside the Lua runtime and TOC smoke tests.

## Remaining validation work

1. Exercise the housing and achievement APIs in a live retail client so catalog lookup readiness and localized criteria labels are verified beyond mocks/static tables.
2. Re-run the current-retail snapshot generator before packaging to detect IDs whose names, flags, or relations changed after this inventory was frozen.
3. Continue the equivalent acquisition classification backward from Battle for Azeroth.
