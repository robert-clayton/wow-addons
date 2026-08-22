# Cross-expansion source audits

Audit queues and acquisition data that span expansions, as opposed to the
per-expansion `research/collectionist/<expansion>/` trees.

## Provenance of the AllTheThings-derived data

`att-recipe-acquisition.csv`, `att-recipe-gap-audit.csv`,
`att-decoration-source-audit.csv`, `att-achievement-gap-candidates.csv` and
`trading-post-gap-audit.csv` all derive from a local AllTheThings checkout,
consumed by `scripts/extract-att-sources.lua`, `scripts/extract-att-names.lua`
and the `generate-collectionist-*` orchestrators.

**The checkout is not pinned, and the exact revision used is not recoverable.**

| | |
|---|---|
| Location | `%TEMP%\collectionist-att-12007` (transient) |
| Commit | **unknown** — `.git` is empty in this checkout |
| Version | **unknown** — `AllTheThings.toc` reads `## Version: @project-version@`, i.e. an unpackaged source tree |
| Client builds it declares | `11508, 11509, 20506, 30405, 38001, 40402, 50504, 120007, 120100, 120105` |
| Licence | MIT (`LICENSE` in the checkout) |

The highest declared interface, `120105`, puts the checkout at or after client
12.1.5. That is the only bound available.

### What this costs

Every ATT-derived figure shipped through 1.14.0 — 8,975 resolved recipe
sources, 3,115 waypoints, 885 faction-paired trainers, 401 recipe gaps, 180
decorations, 708 rares, 364 treasures — was produced from a tree that cannot be
reconstructed. Re-running any generator against a fresh clone will produce
*some* different output, and there is no way to tell which differences are
upstream data improvements and which are regressions in our own tooling.

### Fixing it

1. Re-clone AllTheThings with its history intact, to a durable path rather than
   `%TEMP%`.
2. Record the commit SHA and clone date in the table above.
3. Re-run `scripts/generate-collectionist-recipe-acquisition.ps1` and diff the
   result against the committed `att-recipe-acquisition.csv`. Investigate every
   difference before accepting it — that diff is the only audit of the
   unpinned period we will ever get.
4. Keep the SHA current whenever the checkout is refreshed.

Until then, treat the numbers as measured but not reproducible.

## Correctness

These audits prove *structure*, not *truth*. The validators check that an ID
exists, that a coordinate is in range, that a name is non-empty — none of them
check that a vendor is actually standing where ATT says. ATT is a
community-maintained catalog and is wrong in places; the Draenor
daily-cooldown reagents it classified as never-implemented, corrected in
1.14.0, are one confirmed example.

A stratified sample against Wowhead — roughly 50 waypoints and 30 newly
ingested rows, spread across source kinds and expansions — has not yet been
done and is the outstanding verification debt.
