# HandyNotes table-provider navigation gap audit

The prior 1,707 Rare and 771 Treasure constructor counts cover one HandyNotes publisher family. Seven additional installed plugins use coordinate-keyed zone tables, so their stable NPC, quest, and criteria IDs require a separate scan.

## Result

- Unique table-provider rare NPCs: 1939
- Already represented by Collectionist rare data: 1178
- Additional rare navigation candidates: 761
- Unique quest-identified treasure nodes: 1623
- Already represented by Collectionist treasure criteria/quests: 661
- Additional quest-identity treasure candidates: 962

## Additional candidates by expansion

| Expansion | Rare NPCs | Treasure quests |
| --- | ---: | ---: |
| mists_of_pandaria | 57 | 44 |
| wod | 252 | 29 |
| legion | 65 | 334 |
| battle_for_azeroth | 186 | 169 |
| shadowlands | 40 | 128 |
| dragonflight | 98 | 72 |
| tww | 49 | 77 |
| midnight | 14 | 109 |

## Interpretation

These are normalized provider identities, not an ingestion list. Rare NPCs still need alias/phasing and coordinate review. Quest-only treasures need an explicit data-contract decision because the current navigation-only policy names objectID/itemID, while these providers supply a stable quest completion flag instead.
