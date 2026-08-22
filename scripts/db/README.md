# Collectionist content database

**The curated Lua under `addons/` is the source of truth.** The database is a
validator built from it, not a source it is built from.

```bash
bash scripts/db/run.sh        # load, validate, and prove the round trip
```

Exits non-zero on any constraint violation or round-trip difference, so it
works as a gate.

`data/collectionist.db` is a build artifact and is not committed. Committing a
binary that nothing can diff, review, blame or merge would make it look
authoritative when it is derived.

### Why the Lua stays the source

Three options were weighed. The deciding question for a CSV-sourced pipeline is
*what writes the CSV* — a script reading ATT or DB2 keeps the external
dependency and merely moves it one hop, while a human writing it means
migrating 50,000 lines into a format that is worse at groups, waypoint lists
and criteria arrays. Either way the emitted Lua still has to be committed
because it is what ships, so every change produces two diffs instead of one.

A database-as-source fails harder: no diff, no review, no blame, no merge, no
hand-edit in an emergency.

Lua keeps hierarchy, 1,065 lines of hand-written reasoning, and line-wise
diffs. The database supplies what Lua alone cannot: constraints that make a bug
class unrepresentable, and reconciliation against upstream.

### No script writes shipped data any more

Six generators owning nine data files were frozen and deleted, along with the
line-rewriting `apply-collectionist-recipe-acquisition.ps1`. Their upstreams
were one-time research artifacts, not live feeds, so a re-run could only
reproduce the same rows or clobber corrections made since — a re-run of
`generate-collectionist-trading-post.ps1` would have restored `petType = 0` on
eight pets that were fixed by hand.

`generate-collectionist-changelog-lua.ps1` is kept: it derives
`Data/Changelog.lua` from `CHANGELOG.md` in the same repo, with no external
dependency.

## Why

Every generator in `scripts/` used to read a different upstream (a DB2 CSV, an
ATT checkout, a HandyNotes addon) and write Lua directly. Nothing reconciled
them, so a row could be right in one file and wrong in another with no place
that could notice. Defects the pipeline shipped as a result:

- an expansion key (`dragonflight`) the addon does not have, so Options could
  not filter those rows
- 101 navigation zone keys absent from the module's source order, rendering as
  raw lowercase in arbitrary order
- a coordinate list flattened to `y = 0`, pinning the top edge of the map
- `petType = 0`, outside the 1-10 family range, which the scanner reads as
  "absent" and so silently masks
- a hand-maintained `criteriaCount` that had drifted from the array it counts

Each of those is now either a `CHECK`, a foreign key, or derived rather than
stored. They are unrepresentable, not merely untested.

## The pipeline

| Step | Script | What it does |
|---|---|---|
| 1 | `dump-shipped-data.lua` | Loads the addon's data files with `MC.RegisterContent` stubbed and dumps every row as JSONL |
| 2 | `build-db.py` | Loads that dump into `data/collectionist.db` under the schema's constraints |
| 3 | `emit-lua.py` | Writes Lua back out to `build/emitted/` (for the proof, not for shipping) |
| 4 | `dump-emitted-data.lua` | Loads the emitted Lua through the same harness |
| 5 | `compare-roundtrip.py` | Diffs steps 1 and 4 |
| 6 | `dump-handynotes.lua` | Loads 20 HandyNotes addons from the WoW install and dumps every map node |
| 7 | `normalize-handynotes.py` | Dedupes across publishers into `research/collectionist/sources/handynotes-nodes.csv` |
| 8 | `ingest-upstream.py` | Copies the catalog and adds every upstream to `build/collectionist-full.db` |

Step 1 **loads** rather than parses. Every previous attempt in this repo to
read these files with regex missed something: nested tables, escaped quotes,
entries split across lines. Stubbing the registration function captures exactly
what the addon itself would receive.

## The oracle is semantic, not byte-for-byte

Byte equality is impossible by construction. The shipped files reference shared
constants — `MC.LOC.Kifaan`, `MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2`,
`MC.MAP.Tanaris` — and by load time a map constant is an integer
indistinguishable from a literal. Table-valued constants are recovered by
identity and written back as symbols; numeric ones cannot be.

So the comparison is on the payload handed to `MC.RegisterContent`, resolved
the way `Scanner` resolves it (`entry.source or group.source`). Whether a field
sat on the group or the entry is not observable to the addon; the value the
scanner ends up with is. Present-and-false is treated as equal to absent for
`unavailable` and `navigationOnly`, which behave identically at runtime.

Current state: **21,948 collectibles, 97 locations, 3,248 recipe pins and 2,921
trainer entries round trip identically.**

## What the schema refuses to store

- **`criteriaCount`** — derived from the criterion rows at emit. A declared
  count that disagrees with its arrays cannot be expressed.
- **Grouping** — `content_group` is a real table. Flattening groups onto rows
  would make the emitter invent the grouping, and a re-emit would reshuffle
  files that a human reads as diffs.
- **A row with no natural identifier** — a `CHECK` requires at least one of
  nine id columns. This is how navigation treasures ended up with dead
  alt-click and Wowhead links.

## Integrity views

Each returns rows only when something is wrong, so a non-empty result *is* the
failure. `build-db.py` prints them on every run.

`bad_source_key` · `bad_expansion` · `waypoint_on_unavailable` ·
`scored_navigation_row` · `criterion_gap` · `nameless_collectible` ·
`dangling_location`

`nameless_collectible` is expected to report 3: those BfA toys survive in
Blizzard's Toy table while their item records are gone from ItemSparse, so no
name is derivable offline and `C_ToyBox` supplies it in game. Tracked rather
than dropped — silently discarding rows at ingest is how a catalog quietly
shrinks.

## Upstream reconciliation

`ingest-upstream.py` loads 48,335 upstream records — 34,289 DB2 rows from 66
per-expansion inventories, and 14,046 ATT recipe-acquisition rows — each with
the file path, its SHA-256, and its row count recorded in `source_snapshot`.
That does not pin the ATT *repository* (the checkout that resolved 8,975 recipe
sources lived in `%TEMP%` and is gone), but it makes "which bytes produced this
row" answerable and turns a silent upstream change into a hash change.

Only genuinely upstream files are read. `manifests/` is derived from `ids/`, and
the `*-audit.csv` files are outputs of previous runs; ingesting either would
repeat the mistake the navigation audit made when it read its own previous
output as pre-existing coverage and went from 721 candidates to 55.

Four views replace what used to be a bespoke script per audit:

| View | Count | What it means |
|---|---|---|
| `upstream_missing_from_catalog` | 15,258 | A work queue, not a defect list — most are `internal_dnt`, `snapshot_candidate` or store-only, excluded by policy. Filter on `statuses`. |
| `catalog_missing_from_upstream` | 467 | The catalog ships an id no inventory contains. 225 are Midnight, which has no inventory. |
| `upstream_name_mismatch` | 10 | All ten verified as the *snapshot* being stale, not the catalog. |
| `upstream_expansion_mismatch` | 687 | 601 are Midnight decorations datamined during DF; correct as shipped. |
| `handynotes_navigation_queue` | 6,341 | Map nodes HandyNotes describes that the catalog does not track, ranked by publisher corroboration. |

`upstream_name_mismatch` and `upstream_expansion_mismatch` are **DB2-only by
construction**. HandyNotes' "name" is a map-pin label written by the publisher,
not a canonical string; including it turned a 10-row list into 509 rows of
noise.

**Grouped by identity, not by row.** The per-expansion inventories overlap by
design — 14,048 distinct recipe ids appear across 23,337 rows — so comparing
each listing separately reported 4,221 expansion mismatches where the real
figure is 687.

### Direction is not obvious, and the views do not assert one

All 32 name differences were checked by hand. Twenty-two were genuinely
different strings, and in **every** case the upstream snapshot was the wrong
side: Blizzard renamed the MoP yaks for the Remix event, "The Pigskin" became
"The Swineskin", and five decoration rows carry a literal `[DNT] [AUTOGEN]`
datamine placeholder upstream against a real name in the catalog. Only the ten
punctuation differences ran the other way — the catalog had substituted `'` for
`"` and dropped apostrophes, presumably to avoid Lua escaping — and those are
now fixed.

Treat a non-empty view as a question, not an answer.

## HandyNotes

Twenty addons from two publisher families, read out of the WoW install:

    core     ns.Map + a class hierarchy    map.nodes[55264393] = Item({...})
    handler  ns.RegisterPoints(zone, pts)  [54534241] = {quest=..., loot={}}

Both lines above describe the **same node** — quest 79550, item 213202 — about
one percent apart on the map. That is the normalisation problem in one line:
the quest id is the identity and the coordinates are not. 3,057 of 5,126
distinct quest ids are described by more than one addon, so importing rows as
they arrive would count most of the set twice.

`dump-handynotes.lua` loads the zone files rather than parsing them, which
matters more here than anywhere else in the pipeline: the coordinate key is an
**integer**, so a node at x < 10% is seven digits rather than eight, and the
pattern-matching audit that preceded this required exactly eight and silently
dropped every one of them. The class hierarchy is open-ended
(`ns.node.FrogPrincess`, `ns.node.DracthyrSupplyChest`), so nothing is
enumerated — any `ns.<kind>.<Name>` auto-vivifies into a recording constructor.

343 of 344 files load. The one failure is a nil table index in the addon's own
source, not a stub gap.

### Identity, and what has none

| Bucket | Rows | Key |
|---|---|---|
| rares | 2,796 | npc id |
| treasures | 4,862 | quest id — the completion flag, and why the identity contract was widened to accept `questID` |
| achievement_criteria | 82 | achievement id, aggregating its criteria |
| *no identity* | 4,843 | — |

The last row is reported by spawn group rather than as a bare number:
scavenger pools (377), scout packs (327), disturbed earth (233), snufflings
(214). These are "N spawn points of type X" with no per-node identity at all.

Two recoveries were worth making: 2,336 pins carry no npc and no quest but do
carry an `achievement` + `criteria` pair, and 121 skyriding races name their
quest only inside a label template (`label = "{quest:75317}"`) where no field
read would find it.

### Why a committed CSV sits in the middle

Every other upstream is a file in the repo; HandyNotes is read from the
player's game install. `normalize-handynotes.py` writes the normalised extract
to `research/collectionist/sources/handynotes-nodes.csv` so the ingest is
reproducible from a checkout and `source_snapshot` hashes something that will
still exist tomorrow. `run.sh` skips the dump when no AddOns directory is
present and ingests the committed CSV regardless.

### The queue

**1,680 untracked nodes are corroborated by two or more independent
publishers** (106 rares, 1,574 treasures); 4,661 more rest on a single
publisher. Sort by `publishers` and the defensible candidates come first.

These are navigation candidates, not collectibles: per existing policy they
render with a "Location only" label, keep waypoint and metadata, can be pinned,
and never enter completion denominators, Collection Score, collected lists or
roster bitmaps.

## Known gaps

- **The emitter writes to `build/emitted/` only, deliberately.** It exists to
  prove the schema models every shipped field: if someone adds a Lua field the
  database cannot represent, the round trip fails and says so. It is not meant
  to replace the files under `addons/`, which carry the hand-written reasoning
  that is the point of keeping them.
- **132 source keys** are used by data but declared in no label table, so they
  render as raw lowercase. `build-db.py` lists them on every run.
- **Neither database is committed.** `data/collectionist.db` (catalog) and
  `build/collectionist-full.db` (catalog + upstream) are both rebuilt by
  `run.sh` from files that are committed: the Lua under `addons/` and the CSVs
  under `research/`.

## Concurrency

`.gitattributes` marks `*.db` as `binary -merge`. Git cannot merge a SQLite
file and a textual merge would silently corrupt one, so a concurrent edit
surfaces as a conflict — resolve it by re-running `scripts/db/run.sh` rather
than by picking a side.
