# Collectionist Mists of Pandaria ID inventory

This expansion has exact ID manifests, generated runtime data, TOC integration, exact runtime validation, and mocked scanner coverage. Ownership follows the content required for acquisition, including housing decorations introduced by the Midnight housing system.

## Snapshot and source boundary

- Final Legion historical snapshot: `7.3.5.26972`
- Mists of Pandaria Classic cross-check: `5.5.4.68806`
- Current retail cross-check: `12.1.0.69382`
- Official maintained collectible guide: `https://news.blizzard.com/en-us/article/23463728/mists-of-pandaria-mounts-pets-and-more`
- DB2 exports: `https://wago.tools/db2`
- Current housing catalog: `https://housing.wowdb.com/decor/`

The final Legion snapshot supplies current-retail-compatible achievement and criteria-tree IDs for the complete Pandaria category roots. Mists Classic supplies the original expansion boundary for profession abilities and historical spell names. Current retail proves that selected collectible, achievement, profession, map, faction, and currency IDs still exist.

The generator expects the cached DB2 snapshots and official-guide capture under `%TEMP%`, as declared in `scripts/generate-collectionist-mop-id-inventory.ps1`. The generated CSVs are durable research artifacts; the temporary raw snapshots are not part of the addon.

## Exact manifests

- 89 mounts from a 104-row historical boundary. Seven external-policy rewards, five other-expansion acquisitions, and three uncollectible/internal records are excluded.
- 152 battle pets mapped from Blizzard's maintained Pandaria guide.
- 59 toys mapped from Blizzard's maintained Pandaria guide.
- 41 housing decorations assigned by their current Pandaria acquisition paths.
- 407 current, visible achievements across 11 Pandaria category roots, with 1,563 stable criteria-tree leaves.
- 978 current profession abilities: 957 surviving Pandaria recipes plus 21 housing recipes taught by Pandaria profession tiers.
- 104 ordered rare criteria across four canonical achievements, all carrying direct NPC IDs.
- 98 ordered treasure criteria across six canonical achievements: 46 quest-completion IDs and 52 object IDs.
- 10 supporting currencies, 26 factions, and 12 primary maps.

Ten retained mounts are marked unavailable: the four Challenge Mode phoenixes, four ended Gladiator mounts, the original Brawler's Guild mushan, and Kor'kron War Wolf.

The achievement manifest contains the following current category totals: 44 dungeons, 106 raids, 64 quests, 48 exploration, 20 reputations, 11 Silvershard Mines, 10 Temple of Kotmogu, 10 Deepwind Gorge, 19 Proving Grounds, 69 scenarios, and 6 Timeless Isle PvP achievements. Of their criteria, 127 achievements have 2–30 useful task rows, totaling 1,002 runtime task entries.

## Decoration ownership rule

Housing was introduced in Midnight, but that does not make every decoration Midnight content. A decoration belongs to the expansion whose content is required to earn or unlock it.

- Include a decoration when at least one current acquisition path requires Pandaria content: a Pandaria quest, achievement, reputation, profession, currency, dungeon, raid, rare, treasure, or equivalent Pandaria system.
- The record's creation build, item expansion field, visual theme, catalog expansion tag, or vendor location does not establish ownership by itself.
- A later alternate source does not move an earlier acquisition forward.
- Hidden, source-less, internal, deprecated, and DNT rows are not collectible manifest entries.

## Housing result

The live housing catalog was scanned acquisition-first on 2026-08-19. The 64 Pandaria-themed rows resolve to 40 Pandaria acquisitions and 24 exclusions. A reverse scan of all 2,911 catalog rows found one additional Pandaria quest reward outside the theme set, **Wooden Doghouse** (decor 4488, quest 30526), for an exact 41-decoration manifest.

The 41 owned decorations break down as:

- 21 crafted through Pandaria profession categories
- 11 vendor or reputation acquisitions
- 5 quest rewards
- 2 achievement unlocks
- 2 drops or treasures

The 24 themed exclusions are fully classified: four Legion acquisitions, two The War Within acquisitions, eleven Midnight/later acquisitions, four hidden source-less rows, and three internal/DNT rows. The global source-signal scan contains 70 rows and independently resolves all 41 Pandaria-owned decorations; its other 29 signals belong to Legion, The War Within, Midnight, or noncollectible records.

## Official guide audit

The captured Blizzard guide contains 56 mount rows, 153 rows in its pet table, and 59 toy rows.

- All 56 mount rows map to 55 unique mount IDs; Astral Cloud Serpent appears twice. The guide's `Purple Dragon Turtle` link is incorrect and is mapped by exact name. Its second `Azure Cloud Serpent` label links to the distinct Heavenly Azure Cloud Serpent item and is mapped through the item effect. Ban-Lu (mount 864) is correctly excluded as a Legion acquisition; the other 54 guide IDs occur in the Pandaria mount manifest.
- Exactly 152 pet rows map to 152 unique species. The only unmapped pet-table row is actually the duplicated Amber Primordial Direhorn mount item (94230).
- All 59 toy rows map one-to-one to current toy and item IDs.

## Profession result

The recipe manifest contains 37 Alchemy, 196 Blacksmithing, 34 Cooking, 37 Enchanting, 48 Engineering, 44 Inscription, 200 Jewelcrafting, 252 Leatherworking, and 130 Tailoring spells.

Eight valid Masterwork Ghost-Forged Blacksmithing abilities (122600–122607) still exist in the current profession table but no longer have current localized `SpellName` rows. Their IDs remain current and their display names come from the Mists Classic snapshot. Four later retail additions under Pandaria-labelled category trees are excluded because they do not exist in the Mists Classic profession boundary.

## Generated artifacts

- `sources/blizzard-mop-collectibles.csv`: exact guide-row mapping and known guide defects.
- `sources/housing-wowdb-acquisition-audit.csv`: all 41 confirmed Pandaria-owned decorations and acquisition identifiers.
- `sources/housing-wowdb-theme-exclusions.csv`: all 24 themed rows rejected by acquisition ownership or collectibility.
- `sources/housing-wowdb-theme-catalog.csv`: the complete 64-row themed candidate set.
- `sources/housing-wowdb-global-acquisition-crosscheck.csv`: all 70 source-signal rows from the full reverse scan.
- `ids/`: broad historical candidates, current-retail checks, and release decisions.
- `manifests/`: the exact sets consumed by the runtime generator and validators.

Regenerate and validate with:

```powershell
./scripts/generate-collectionist-mop-housing-audit.ps1
./scripts/generate-collectionist-mop-id-inventory.ps1
./scripts/validate-collectionist-mop-manifests.ps1
./scripts/generate-collectionist-mop-lua.ps1
./scripts/validate-collectionist-mop-runtime.ps1
```

## Runtime integration

The eight generated Pandaria Lua catalogs register under the existing `mop` expansion key and load before Warlords of Draenor. Runtime validation requires exact manifest equality, stable rare and treasure order, exact achievement task criteria, map constants, TOC ordering, and Lua syntax.

The 31 source-owned Pandaria rows formerly retained by later expansion catalogs have been transferred to Pandaria ownership:

- Legion: pet species 2017 and 2018, plus 18 toys.
- Battle for Azeroth: 11 Pandaria raid-drop pet species (2579–2590, excluding 2588).

The Pandaria manifest validator now requires zero overlap with every later expansion for mounts, pets, toys, decorations, achievements, and recipes.
