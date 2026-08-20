# Trading Post collectible gap audit

ATT's curated Trading Post catalog is compared with current retail DB2 and every Collectionist runtime data file. The first ATT availability patch assigns each item to the expansion in which it first became obtainable from the Trading Post, regardless of its older promotional or shop origin.

## Result

- Confirmed policy gaps: 130
- Already tracked: 4
- Missing current DB2 record: 0
- Placeholder/internal: 0

## Confirmed gaps by expansion and kind

| Expansion | Mounts | Pets | Toys | Total |
| --- | ---: | ---: | ---: | ---: |
| dragonflight | 31 | 21 | 7 | 59 |
| tww | 38 | 13 | 2 | 53 |
| midnight | 13 | 5 | 0 | 18 |

## Interpretation

Collectionist's current DB2 gap filter treats the Trading Post as an external-source exclusion. That is no longer a completeness-safe policy: these collectibles are acquired in game, rotate back into availability, and can be assigned to the expansion of their first Trading Post appearance. Rows marked confirmed_policy_gap are therefore real catalog omissions, not speculative preload records.

The CSV retains every ATT catalog item, including already-tracked and source-incomplete rows, so later runs can detect source drift without re-adjudicating the whole category.
