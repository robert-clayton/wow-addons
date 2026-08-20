# Collectionist broad coverage gap audit

This pass re-baselines the committed Collectionist runtime against current
retail DB2, ATT 12.0.7, and both installed HandyNotes publisher families. It
does not add speculative runtime entries. Each queue below distinguishes a
confirmed catalog omission from records that still need acquisition placement,
deduplication, or a policy decision.

## Confirmed gaps

### Trading Post mounts, pets, and toys

ATT confirms 130 in-game Trading Post collectibles that are absent because the
current DB2 filter treats all rotating sources as external:

| First Trading Post expansion | Mounts | Pets | Toys | Total |
| --- | ---: | ---: | ---: | ---: |
| Dragonflight | 31 | 21 | 7 | 59 |
| The War Within | 38 | 13 | 2 | 53 |
| Midnight | 13 | 5 | 0 | 18 |

The first ATT availability patch determines expansion ownership. Older shop,
TCG, or promotional origins do not override the expansion in which an item
first became obtainable from the in-game Trading Post.

### Cross-expansion achievements

ATT and current achievement DB2 corroborate 3,527 player-facing achievements
that are absent from Collectionist after excluding statistics, hidden tracking
records, internal labels, guild achievements, and records without criteria.
The largest missing families are:

| Top-level category | Count |
| --- | ---: |
| Feats of Strength | 834 |
| Legacy | 709 |
| Professions | 467 |
| World Events | 327 |
| Player vs. Player | 310 |
| Pet Battles | 195 |
| Collections | 157 |

The expansion-specific manifests remain internally complete. The gap is their
scope: cross-expansion categories were never routed into expansion ownership.
These IDs need first-availability placement before runtime generation.

### Profession recipes

Current DB2 contains 844 named trade-category abilities absent from the recipe
runtime. The audit separates 299 profession UI/training records, two ATT-only
never-implemented entries, and 78 current DB2 records that ATT does not yet
corroborate. The remaining 465 are confirmed recipe catalog gaps.

Category expansion names are only routing hints. An old-tier recipe can have a
new restoration source, so final placement must follow ATT source ancestry or
another acquisition source rather than the profession UI category.

## Source-ready and deferred decoration gaps

The existing 816 current item-backed decoration gaps now classify as:

| Decision | Count |
| --- | ---: |
| Direct ATT quest/NPC ancestry available | 180 |
| ATT acquisition-category lead available | 159 |
| Catalog or unsorted only | 304 |
| External shop/promotion only | 91 |
| Never implemented only | 77 |
| No ATT record | 5 |

The Housing extractor previously missed array-style ATT factory payloads. Its
catalog coverage is now 377 decorations rather than 298. Full-corpus scanning
also finds acquisition leads in zone, profession, instance, PvP, holiday, and
expansion-feature data. Expansion ownership must still follow the awarding
content, not the decor theme or item DB2 expansion value.

## Rare and treasure provider queues

The earlier exact raw corpus count remains 1,707 `Rare({...})` and 771
`Treasure({...})` calls. A second installed HandyNotes publisher family uses a
different coordinate-keyed table format and was outside that count. Its stable
identities normalize to:

- 1,714 rare NPC IDs: 993 already represented, 721 navigation candidates;
- 1,400 quest-identified treasure nodes: 566 already represented, 834
  navigation candidates.

These counts are not additive net totals because aliases, phase duplicates,
and cross-publisher overlap still require review. Quest-only treasures also
need a data-contract decision before ingestion: the current navigation-only
contract permits object/item identity but not quest identity.

## Ordinary DB2 collectible result

No further ordinary-source mount, pet, or toy omission surfaced after the
previous DB2 gap additions. The remaining untracked rows outside the Trading
Post queue resolve to shop/TCG/promotion/Recruit-a-Friend sources, placeholders,
tests, obsolete records, missing current item rows, or future preload data.

## Reproducible outputs

- `trading-post-gap-audit.csv`
- `att-achievement-gap-candidates.csv`
- `att-recipe-gap-audit.csv`
- `att-decoration-source-audit.csv`
- `handynotes-table-rare-gap-audit.csv`
- `handynotes-table-treasure-gap-audit.csv`

The matching Markdown summaries document filters and decision boundaries. The
scripts under `scripts/` regenerate every output from the local DB2, ATT, and
installed HandyNotes snapshots.
