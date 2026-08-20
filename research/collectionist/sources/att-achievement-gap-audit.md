# ATT achievement coverage gap audit

Current retail achievement DB2 is cross-checked with achievement IDs curated by ATT and every Collectionist runtime data file. Statistics, hidden tracking records, guild-only records, explicit internal labels, and records without a criteria tree are separated before reporting player-facing catalog gaps.

## Result

- Player-facing catalog gaps needing expansion placement: 3527
- exclude statistic: 2095
- exclude hidden tracking: 2391
- exclude internal label: 515
- defer no criteria tree: 544
- historical att only: 1074
- ATT guild-only catalog records excluded before the personal scan: 478

## Player-facing gaps by top-level category

| Category | Count |
| --- | ---: |
| Feats of Strength | 834 |
| Legacy | 709 |
| Professions | 467 |
| World Events | 327 |
| Player vs. Player | 310 |
| Pet Battles | 195 |
| Collections | 157 |
| Dungeons & Raids | 115 |
| Expansion Features | 102 |
| Exploration | 86 |
| Reputation | 64 |
| Delves | 45 |
| Quests | 45 |
| Characters | 40 |
| Housing | 31 |

## Interpretation

The existing expansion-category manifests are internally complete, but they do not cover the cross-expansion achievement families above. The largest missing families are legacy/feat, profession, world-event, PvP, pet-battle, and collection achievements. These rows are confirmed live catalog records; needs_placement means their first obtainable expansion still has to be assigned without relying on achievement ID ranges or theme alone.

This audit deliberately does not turn statistics or hidden tracking records into Collectionist goals.
