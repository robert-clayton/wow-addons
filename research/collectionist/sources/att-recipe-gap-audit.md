# ATT recipe coverage gap audit

Current named retail profession abilities are compared with every Collectionist recipe and ATT's curated recipe catalog. Profession UI glossary/stat entries, optional-reagent internals, training steps, and ATT-only never-implemented recipes are classified separately.

## Result

- Current named trade-category abilities absent from Collectionist: 844
- Confirmed ATT recipe gaps needing source placement: 465
- Non-recipe UI/training exclusions: 299
- ATT never-implemented-only exclusions: 2
- DB2 abilities not corroborated by ATT: 78

## Confirmed gaps by profession

| Profession | Count |
| --- | ---: |
| Inscription | 151 |
| Jewelcrafting | 90 |
| Leatherworking | 70 |
| Enchanting | 40 |
| Blacksmithing | 38 |
| Cooking | 34 |
| Tailoring | 24 |
| Alchemy | 9 |
| Engineering | 9 |

## Category expansion hints

| Hint | Count |
| --- | ---: |
| classic | 156 |
| wrath | 91 |
| tbc | 89 |
| legion | 61 |
| wod | 36 |
| midnight | 14 |
| cataclysm | 7 |
| battle_for_azeroth | 5 |
| mists_of_pandaria | 4 |
| shadowlands | 2 |

## Interpretation

These are real recipe catalog omissions, but the category expansion is only a routing hint. It is not final ownership: recipes grouped under an old profession tier can be newly restored or newly obtainable in a later expansion. Final ingestion must use ATT source ancestry or another acquisition source before assigning the expansion.
