# Collectionist content database

The addon's data files are no longer hand-assembled from a pile of other
datasets. `data/collectionist.db` is the authority; the Lua under
`addons/Collectionist/Modules/*/Data/` is emitted from it.

```bash
bash scripts/db/run.sh        # rebuild, re-emit, and prove the two agree
```

Exits non-zero on any difference, so it works as a gate.

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
| 3 | `emit-lua.py` | Writes Lua back out to `build/emitted/` |
| 4 | `dump-emitted-data.lua` | Loads the emitted Lua through the same harness |
| 5 | `compare-roundtrip.py` | Diffs steps 1 and 4 |
| 6 | `ingest-upstream.py` | Copies the catalog and adds the upstream inventories to `build/collectionist-full.db` |

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

## Known gaps

- **The emitter writes to `build/emitted/` only.** It does not yet replace the
  files under `addons/`, which have a hand-tuned layout, comments, and a TOC
  order that the round trip does not model. The proof establishes that it
  *could*; switching over is a separate, reviewable change.
- **132 source keys** are used by data but declared in no label table, so they
  render as raw lowercase. `build-db.py` lists them on every run.
- **HandyNotes is not ingested.** Its rare/treasure navigation candidates are
  the remaining upstream, and they need normalisation (aliases, phase
  duplicates, cross-publisher overlap) before they are loadable.
- **Only the committed catalog is versioned.** `data/collectionist.db` holds
  the catalog alone, at 6.7 MB. Upstream ingest lands in
  `build/collectionist-full.db` (31 MB) because the CSVs behind it are already
  committed under `research/` and the ingest is deterministic — committing the
  loaded copy would store the same 20 MB twice in a format git cannot delta.

## Concurrency

`.gitattributes` marks `*.db` as `binary -merge`. Git cannot merge a SQLite
file and a textual merge would silently corrupt one, so a concurrent edit
surfaces as a conflict — resolve it by re-running `scripts/db/run.sh` rather
than by picking a side.
