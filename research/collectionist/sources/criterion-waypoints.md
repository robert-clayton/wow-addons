# Older rare and treasure waypoints — 1.14.0

`criterion-waypoints.csv` records the frozen coordinates shipped in
`addons/Collectionist/Data/CriteriaWaypoints.lua`. These are source-backed
locations, not observations in a live game client. The curated Lua remains
the source of truth; do not regenerate it blindly against a newer upstream.

The lookup contains 2,207 separate NPC/object/quest identities and 2,630
coordinate tuples. It supplies pins for 1,934 of 2,104 older achievement
criteria (duplicates across achievements count separately). The remaining
26 rare and 144 treasure criteria are listed in
`criterion-waypoint-gaps.csv`; their positions were not inferred from nearby
nodes. Twelve of these treasures are spell-backed criteria with no physical
entity ID in the achievement asset.

## Matching rules

- Match the shipped criteria trees against CriteriaTree/Criteria, respecting
  asset type: KillCreature (0), CompleteQuest (27), UseGameObject (68).
- Prefer the shipped positional NPC/object maps for rare identity. Keep quest
  identities separately so localization and live criterion-count changes do
  not turn quests into NPCs or objects.
- Use NPC or quest records from the committed HandyNotes extract first. Its
  achievement-level aggregates combine unrelated criteria and are excluded.
- Fill remaining identities from ATT nodes' own coordinates, then from a
  completion quest's enclosing NPC or object. Never take sibling coordinates
  or a generic ancestor's location. The extractor now bounds each node's
  own fields; a regression test exercises adjacent and nested nodes.
- Require a known UiMap ID, coordinates strictly inside the map, and a map
  within the achievement's area. Conquering Korthia includes The Maw as well
  as Korthia; I'm In Your Base, Killing Your Dudes belongs to Krasarang Wilds.
- Preserve multiple spawns. Collapse publisher positions within 0.2 percentage
  points on both axes. ATT extraction retains up to four positions on its
  first explicitly named map; the HandyNotes data can include more positions.
- Existing curated rare/treasure coordinates take precedence over this lookup.
  Fallback labels such as `quest 12345` identify unnamed source records and
  must not replace the client's localized criterion names.

## Provenance

HandyNotes publisher names and ATT node identities are recorded per row.
ATT's local compiled snapshots have no recoverable upstream commit; see
[the existing provenance note](README.md). The hashes below identify the
exact inputs used for this audit, without claiming they can reconstruct that
unknown upstream revision. The filtered coordinate extract is committed so
its values remain independently reviewable.

| Input | SHA-256 |
| --- | --- |
| `build/att/Zones.lua` | `2b3fe5a8cf12dd382d003cd25e6aa440c7ad2b7d2d22be4da0f4579403a5857e` |
| `build/att/Instances.lua` | `6749340f92569fc3256c07900efdc3939406ebd9c1a30c9ef2086b5dba928202` |
| `build/att/Secrets.lua` | `7e7d263cdfe0a91ad29996605b058dc3a49627d5174f076aeea3ab158d5faff2` |
| `build/Criteria.csv` | `84343ddf911a9c007b55afac00f7881c4e1d6f1ab9dc1c036ba526e4f9ee1975` |
| `build/CriteriaTree.csv` | `8825851ed17bc428994bf66b6fa89da1c4cf0e7c813fa0e039e41736d5a88146` |
| `build/uimap.csv` | `fcd7c6a8ed41686b0b159b4ce96389875a00cbaa2a1bf93ed328b83878dfdea3` |
| `research/collectionist/sources/handynotes-nodes.csv` | `307c5dbc28cb8978e6113d1d25cb8bfca06d339ddd6ffc73be90edf8b9a23152` |
