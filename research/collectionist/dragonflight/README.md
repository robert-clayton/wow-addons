# Collectionist Dragonflight ID inventory

This is the ID-first acquisition pass for adding **Dragonflight** (`dragonflight`) to Collectionist. It records the complete snapshot difference first, then separates implementation-ready IDs from internal, noncollectible, removed, and unresolved rows. Source prose, costs, coordinates, score weights, and Lua registration remain a later enrichment pass.

## Snapshots

- Final Shadowlands baseline: `9.2.7.45745`
- Final Dragonflight snapshot: `10.2.7.55664`
- Current-retail validation snapshot: `12.1.0.69382`

DB2 CSVs come from `https://wago.tools/db2/<Table>/csv?build=<build>&locale=enUS`. The Shadowlands-to-Dragonflight difference supplies the broad candidate set. Final Dragonflight rows are then joined across item, spell, creature, achievement, criteria, profession, map, faction, and currency tables.

The generator expects snapshot directories under `%TEMP%/collectionist-df-db2/`:

- `shadowlands/`
- `dragonflight/`
- `current/`
- optional `guides/` with the cached Wowhead HTML listed below

The generated CSVs and the housing catalog source list are committed research artifacts. The temporary DB2 and guide cache is intentionally not part of the addon.

Housing decor is a special case: the feature and its records arrived with Midnight, but many decorations are awarded by earlier-expansion content. Decoration ownership therefore follows the acquisition source. DB2 creation date, item expansion fields, and the live catalog's thematic expansion tag are audit evidence only; none assigns an expansion by itself.

## Source references

- Build chronology: `https://warcraft.wiki.gg/wiki/Public_client_builds`
- Shadowlands boundary: `https://warcraft.wiki.gg/wiki/Patch_9.2.7`
- Dragonflight boundary: `https://warcraft.wiki.gg/wiki/Patch_10.2.7`
- DB2 exports: `https://wago.tools/db2`
- Mount guides: `https://www.wowhead.com/guide/mounts-dragonflight`, `https://www.wowhead.com/guide/mounts-patch-10-1`, and `https://www.wowhead.com/guide/mounts-patch-10-2`
- Pet guides: `https://www.wowhead.com/guide/pet-battles/dragonflight-collection-overview`, `https://www.wowhead.com/guide/dragonflight-the-forbidden-reach-pet-battle-collection-overview-19434`, `https://www.wowhead.com/guide/dragonflight-embers-of-neltharion-pet-battle-collection-overview-20081`, `https://www.wowhead.com/guide/dragonflight-fractures-in-time-pet-battle-collection-overview-20817`, and `https://www.wowhead.com/guide/battle-pets/patch-10-2`
- Toy guide: `https://www.wowhead.com/guide/dragonflight-toybox`
- Unavailable pet audit: `https://www.warcraftpets.com/wow-pets/unlisted/`, `https://warcraft.wiki.gg/wiki/Time-Lost_Slyvern`, `https://warcraft.wiki.gg/wiki/Azure_Swoglet`, and `https://warcraft.wiki.gg/wiki/Soot-Stained_Shalewing`
- Unavailable toy audit: `https://warcraft.wiki.gg/wiki/Brewhahat`
- Housing catalog: `https://housing.wowdb.com/decor/?expansion=dragonflight`
- Rare overrides: `https://www.wowhead.com/npc=192362/possessive-hornswog` and `https://www.wowhead.com/npc=203621/brullo-the-strong`

## Confidence labels

- `guide_confirmed`: a mount, pet, or toy is present in the relevant Dragonflight guide and joined to DB2 through item/spell, creature ID, or exact mount name.
- `item_expansion_confirmed`: the associated item is explicitly marked `ExpansionID=9`.
- `db2_dragonflight_signal`: the DB2 source text names a Dragonflight zone, feature, or expansion, but the row lacks a direct guide join.
- `snapshot_candidate`: added between the final Shadowlands and Dragonflight snapshots but still needs classification. This deliberately retains Trading Post, shop, promotion, holiday, Remix, and preloaded rows for triage rather than silently dropping them.
- `include_dragonflight`: an exact manifest row whose acquisition was part of Dragonflight content or a limited event released during Dragonflight.
- `exclude_policy_external`: a shop, Trading Post, Recruit-a-Friend, out-of-game promotion, esports, or BlizzCon reward excluded by Collectionist policy.
- `exclude_cross_expansion`: a record added or converted during Dragonflight whose acquisition remains owned by an older expansion.
- `exclude_unobtainable_or_internal`: a test/preload record with no live acquisition path.
- `noncollectible_pet_battle_npc`: a species-shaped battle opponent with no summon spell and no direct guide ID join.
- `dragonflight_category_confirmed`: a current, player-visible achievement in one of the seven Dragonflight categories. Statistics, guild statistics, and hidden implementation achievements are excluded.
- `dragonflight_category_hidden`: a current achievement under a Dragonflight category whose hidden flag marks it as an implementation component rather than a journal entry.
- `removed_after_dragonflight`: present in final Dragonflight but absent from current retail.
- `catalog_theme_candidate`: a current decor ID in the live housing catalog's Dragonflight theme filter; acquisition evidence is still required before assigning it to Dragonflight.
- `needs_acquisition_expansion`: a current housing row whose acquisition expansion has not been independently attributed.
- `catalog_hidden_unobtainable`: a non-internal themed row with no acquisition source and the live/current hidden-catalog flag; exclude it from expansion manifests.
- `named_recipe`: a Dragon Isles crafting-profession ability with a matching spell-name record.
- `unnamed_db2_ability_candidate`: a Dragon Isles ability whose spell has no name record; retain for auditing, not implementation.
- `internal_dnt`: internal/test content explicitly labeled DNT or DO NOT USE.

## Generated inventories

Run:

```powershell
./scripts/generate-collectionist-dragonflight-id-inventory.ps1
```

The script writes CSVs under `research/collectionist/dragonflight/ids/`:

- `mounts.csv`: mount ID, source spell, item relations, source tooltip, current-retail existence, and confidence.
- `pets.csv`: species, creature, summon spell, item relations, family enum, source tooltip, and confidence.
- `toys.csv`: toy/item IDs, item-expansion signal, source tooltip, and confidence.
- `decorations.csv`: every current housing row, with catalog theme and acquisition expansion kept as separate fields.
- `achievements.csv`: broad Dragonflight-era candidates, current-retail status, category, criteria tree, flags, and points.
- `achievement-criteria.csv`: ordered leaf criteria for the seven player-facing Dragonflight categories.
- `rares.csv`: seven zone rare-achievement groups with 197 ordered criteria and resolved NPC IDs.
- `treasures.csv`: seven zone treasure-achievement groups with 57 ordered criteria/assets.
- `recipes.csv`: exact spell IDs under the nine Dragon Isles crafting-profession category trees.
- `maps.csv`, `factions.csv`, and `currencies.csv`: supporting IDs for later enrichment.

The separately captured `sources/housing-wowdb.csv` contains all 171 rows returned by the live Dragonflight housing filter. `sources/housing-wowdb-details.csv` records the current category, source text, and acquisition IDs shown for those rows. `sources/housing-wowdb-acquisition-audit.csv` keeps the independently assigned acquisition expansion and evidence note. The set has 149 non-internal decor candidates and 22 DNT rows, all of which match current DB2 IDs and names. The filter is a candidate source, not proof that the decorations are obtained from Dragonflight content; 122 rows currently expose a source and 49 do not.

The acquisition audit contains 159 rows and resolves them to 76 Dragonflight, 47 Midnight, 3 Classic, 2 Legion, 1 Wrath, 1 Cataclysm, and 1 Mists of Pandaria acquisition, plus 28 hidden/unobtainable rows. Ten Dragonflight-owned rewards were found outside the Dragonflight theme tag by following their actual acquisition paths: Amirdrassil Stool, Bel'ameth Traveler's Pack, Filigree Moon Lamp, Small Val'sharah Bookcase, and the six post-Reclamation of Gilneas vendor rewards. The remaining 28 non-internal themed rows expose no source and carry the hidden-catalog flag, so they are excluded as unobtainable. `manifests/decorations.csv` contains only the 76 Dragonflight-owned rows.

The mount, pet, and toy inventories now also carry a `release_decision`. Their exact implementation sets are frozen in `manifests/mounts.csv`, `manifests/pets.csv`, and `manifests/toys.csv`. Candidate decisions are ID-anchored so later DB2 text changes cannot silently add or remove rows. Blank Time-Lost Dragonflight pets and the patch 10.1 pet set are unavailable test records; `Brewhahat` and the hidden unnamed toy 1224/item 200142 likewise have no live acquisition path. Holiday additions, Plunderstorm, Secrets of Azeroth, Hearthstone Anniversary, and Mists of Pandaria Remix remain assigned to Dragonflight because those rewards shipped during the Dragonflight release cycle.

`manifests/achievements.csv` contains the 569 current, player-visible achievements in the seven Dragonflight category trees. `manifests/achievement-criteria.csv` contains their 3,203 ordered leaf criteria. The 1,369 hidden category rows remain in the broad inventory for auditing but are not addon entries.

The remaining exact ID manifests contain 973 named Dragon Isles recipe spells, including 25 housing recipes taught by Dragon Isles profession tiers, plus 197 ordered rare criteria and 57 ordered treasure criteria. Three support manifests freeze the 8 currencies, 15 reputations/renown tracks, and 9 map IDs referenced by the selected content. `manifests/summary.csv` is the compact release-set count and identifier contract for the complete ID-first release set.

## Validated snapshot totals

- Mounts: 161 included, 46 external-policy exclusions, and 5 unavailable/internal exclusions. The two `Soar` rows (1608 and 1952) are Dracthyr racial abilities, not collectible mounts. All 212 snapshot IDs still exist in current retail.
- Battle pets: 164 included, 33 external-policy exclusions, 34 unavailable/internal exclusions, and 124 noncollectible battle-NPC rows. Species 3434, 3437, 3439, and 3440 are encounter opponents, while Fyrn (4264) is a later shop pet; none belongs in the Dragonflight acquisition catalog. All 355 snapshot species IDs still exist in current retail.
- Toys: 171 included, 16 external-policy exclusions, 3 older-expansion acquisition exclusions, and 2 unavailable/hidden test records. All 192 snapshot IDs still exist in current retail.
- Source gaps in the final snapshot are overlaid from acquisition references: Rithro's quest, four launch-toy drops/events, the seven persistent Warcraft Rumble Machine prizes, the Stone Breaker quest, and the two ended Hearthstone 10th Anniversary toys.
- Runtime availability flags cover 42 mounts, 6 pets, and 8 toys whose acquisition windows have ended: Remix, Dragonflight seasonal PvP/Mythic+ rewards, the Awakened raid mount, Hearthstone's anniversary, the original Keg Leg's Crew track, the 19th Anniversary pet, four Legend pennants, and the A Greedy Emissary toy.
- Housing decor: 76 acquisition-confirmed Dragonflight rows, 55 source-confirmed rows belonging to other expansions, and 28 hidden/unobtainable themed rows. The broad current table also contains 643 internal/DNT and 2,119 other or still-unattributed rows.
- Recipes: 973 named spell IDs, including 25 current housing recipes, plus 1 internal DNT recipe and 1 unnamed Alchemy ability candidate. Every named, non-internal recipe mapping still exists in current retail.
- Achievements: 569 current player-visible IDs in the seven Dragonflight categories, 1,369 hidden category rows, 617 internal/DNT rows, 16 removed rows, and 806 broader snapshot candidates.
- Rare criteria: 197 ordered criteria across seven zone achievements, all with NPC IDs resolved.
- Treasure criteria: 57 ordered criteria across seven zone achievements.
- Supporting data: 9 maps, 28 expansion-signaled factions (including one DNT row), and 739 broad currency candidates.

## Known triage boundaries

1. The broad snapshot inventories retain excluded Blizzard Shop, Trading Post, Recruit-a-Friend, promotion, esports, BlizzCon, and unavailable records for auditability; only `include_dragonflight` rows enter the exact manifests.
2. Limited in-game events released during Dragonflight are included even when their setting belongs to an older expansion. This matches the TWW treatment of Legion Remix and differs from housing decor, whose ownership explicitly follows its permanent acquisition source.
3. Achievement categories contain many zero-point dragon-race component achievements. The inventory records them faithfully; the implementation pass still needs to decide whether Collectionist tracks every component or only player-facing metas.
4. Housing expansion ownership must come from the documented acquisition source. `HouseDecor` chronology, `ItemSparse.ExpansionID`, and the catalog theme filter do not establish ownership.
5. Coordinates, costs, vendors, prerequisites, source text normalization, and score tiers are not part of this ID-first pass.

## Next ID work

1. Keep the frozen 161-mount, 164-pet, 171-toy, 76-decoration, 569-achievement, 973-recipe, 197-rare, and 57-treasure manifests synchronized with Lua.
2. Attach achievement task rows only where criteria labels add value without creating oversized tooltips.
3. Validate current names and primary IDs against the in-game journal and housing APIs when a retail client is available.
4. Validate current names and primary IDs against the in-game journal and housing APIs when a retail client is available.
