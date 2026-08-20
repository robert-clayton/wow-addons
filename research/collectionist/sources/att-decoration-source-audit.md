# ATT decoration source coverage audit

Every current item-backed decoration missing from Collectionist is cross-checked against ATT's full category corpus. Direct quest/NPC ancestry from Housing is separated from category-level source leads, external-only records, never-implemented records, and unresolved catalog records.

## Result

- Current item-backed decoration gaps: 816
- Direct ATT source ancestry available: 180
- Additional ATT acquisition-category leads: 159
- Catalog/unsorted-only deferrals: 304
- External-only exclusions: 91
- Never-implemented-only exclusions: 77
- No ATT record: 5

## Interpretation

The prior Housing-only pass understated ATT coverage because some generated factory payloads store children directly on the node rather than under g, and because acquisition records also live in zone, profession, instance, PvP, holiday, and expansion-feature categories. The direct ancestry rows can proceed to expansion/source adjudication now; category-level leads need their local ATT ancestry extracted before ingestion.

Theme and item DB2 expansion values remain non-authoritative. Expansion ownership must follow the content that actually awards the decoration.
