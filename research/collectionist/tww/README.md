# Collectionist TWW ID inventory

This is an ID-first acquisition pass for adding **The War Within** (`tww`) to Collectionist. It deliberately defers source prose, costs, coordinates, score weights, task instructions, and Lua registration.

## Snapshots

- Final Dragonflight baseline: `10.2.7.55664`
- Final TWW snapshot: `11.2.7.65299`
- Current-retail validation snapshot: `12.1.0.69382`

DB2 CSVs come from `https://wago.tools/db2/<Table>/csv?build=<build>&locale=enUS`. The Dragonflight-to-TWW difference provides the broad candidate set. Final TWW rows are then joined across the relevant DB2 tables instead of trusting names alone.

The generator expects the three snapshot directories and cached guide HTML under `%TEMP%/collectionist-tww-db2/`. The generated CSVs are committed research artifacts; the temporary source cache is intentionally not part of the addon.

The mount and pet inventories are additionally cross-checked against Wowhead's expansion and patch collection guides. This matters because the final TWW client contains preloaded records for later content, while some TWW releases reuse older themes or source zones.

## Source references

- Build chronology: `https://warcraft.wiki.gg/wiki/Public_client_builds`
- DB2 exports: `https://wago.tools/db2`
- Mount guides: `https://www.wowhead.com/guide/collections/the-war-within/mounts`, `https://www.wowhead.com/guide/collections/the-war-within/mounts-guide-sources-karesh`, and `https://www.wowhead.com/guide/collections/the-war-within/mounts-sources-patch-11-2-7`
- Pet guides: `https://www.wowhead.com/guide/collections/the-war-within/battle-pet-collection-overview`, `https://www.wowhead.com/guide/collections/the-war-within/wild-pet-collection-khaz-algar-safari`, `https://www.wowhead.com/guide/collections/the-war-within/battle-pet-collection-siren-isle`, `https://www.wowhead.com/guide/collections/the-war-within/battle-pet-collection-undermine`, and `https://www.wowhead.com/guide/collections/the-war-within/battle-pets-karesh-sources`
- Rare and treasure guides: `https://www.wowhead.com/guide/the-war-within/azj-kahet-rares-and-treasures`, `https://www.wowhead.com/guide/the-war-within/karesh-rares-and-treasures`, and `https://www.wowhead.com/achievement=41046/clean-up-on-isle-siren`

## Confidence labels

- `guide_confirmed`: present in a TWW collection guide and joined to the DB2 mount or species record through item/spell or creature ID.
- `item_expansion_confirmed`: the toy's item is explicitly marked with `ExpansionID=10`.
- `tww_category_confirmed`: the achievement belongs to a player-facing TWW-specific achievement category. The parallel Dungeons & Raids statistics category is intentionally excluded.
- `db2_tww_signal`: strong TWW item-expansion or source-text evidence, but not yet independently guide-confirmed.
- `snapshot_candidate`: added between the final Dragonflight and final TWW snapshots, but needs classification because the client contains preloaded and cross-expansion records.
- `snapshot_candidate_needs_source_expansion`: valid housing decor ID present during TWW Housing Early Access, but DB2 does not identify which expansion supplies it.
- `noncollectible_pet_battle_npc`: a species-shaped pet-battle opponent row with no summon spell; do not treat it as a journal collectible unless independently guide-confirmed.
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
- `decorations.csv`: decor/item IDs from the final TWW Housing Early Access table.
- `achievements.csv`: broad TWW-era achievement candidates with category and criteria-tree IDs.
- `achievement-criteria.csv`: leaf criterion IDs/assets for TWW-specific achievement categories.
- `rares.csv`: the seven TWW rare-achievement groups with ordered criteria and resolved NPC IDs where available.
- `treasures.csv`: the seven TWW treasure-achievement groups with ordered criteria and asset IDs.
- `recipes.csv`: exact recipe spell IDs under the nine Khaz Algar crafting-profession category trees.
- `maps.csv`, `factions.csv`, and `currencies.csv`: supporting IDs needed by later enrichment.

Every primary collectible inventory includes current-retail validation. Recipes separately record whether the skill-line mapping and spell-name record still exist.

## Validated snapshot totals

- Mounts: 171 guide-confirmed, 1 additional strong DB2 signal, and 118 unresolved snapshot candidates.
- Battle pets: 210 guide-confirmed, 7 additional strong DB2 signals, 39 unresolved collectible candidates, and 36 noncollectible battle-NPC rows.
- Toys: 97 item-expansion-confirmed, 2 additional strong DB2 signals, and 21 unresolved snapshot candidates.
- Recipes: 696 named recipe spell IDs and 8 unnamed Alchemy ability candidates. All 704 skill-line mappings still exist in current retail; the eight candidates have no spell-name record in either snapshot.
- Achievements: 505 current IDs in player-facing TWW-specific categories, plus 1,687 broader snapshot candidates.
- Rare criteria: 140 ordered criteria across seven zone/meta achievements, with NPC IDs resolved.
- Treasure criteria: 86 ordered criteria across seven zone/meta achievements.
- Housing decor: 1,355 current non-internal snapshot candidates needing source-expansion attribution, 80 internal/DNT rows, and one row removed after TWW (`decor_id=11770`, `item_id=257797`).

## Known architectural prerequisite

`MC.RegisterContent` currently supports every Collectionist tab except Recipes. Before TWW recipe rows can be registered cleanly, Recipes needs an additive per-expansion merge path for its per-profession tables. The ID inventory can be completed independently of that change.

## Next ID work

1. Resolve every `snapshot_candidate` mount, pet, and toy to include/exclude.
2. Attribute non-internal housing decor IDs to their actual source expansion.
3. Reduce the broad achievement inventory to the achievement categories Collectionist intends to track.
4. Validate all IDs against current retail and detect IDs whose names or relations changed after TWW.
