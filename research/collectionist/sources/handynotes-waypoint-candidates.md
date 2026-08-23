# HandyNotes waypoint candidates

Companion to `handynotes-waypoint-candidates.csv`. 747 candidate pins for mounts, pets and toys
that currently have no waypoint at all.

**Verdict: ship-filtered.** The identity join (which HandyNotes node awards which collectible) is
sound and survived every attempt to break it. The *coordinate selection* used by the extraction pass
was not, and it shipped at least one pin on the wrong continent. Every coordinate in this file was
re-derived from scratch out of `build/handynotes.jsonl` rather than filtered out of the earlier
output, because the defect was in how coordinates were chosen, not in which rows were chosen.

## Counts

| module | pool | kept | dropped | high | medium | low |
|---|---|---|---|---|---|---|
| mounts | 184 | **130** | 54 | 99 | 30 | 1 |
| pets | 564 | **424** | 140 | 278 | 145 | 1 |
| toys | 235 | **193** | 42 | 142 | 50 | 1 |
| total | 983 | **747** | 236 | 519 | 225 | 3 |

Gap size for context (verified against the DB, not taken from the brief): mounts 1430 rows / 40
pinned, pets 1994 / 79, toys 1076 / 24. So this closes roughly 9% of the mount gap, 22% of the pet
gap and 18% of the toy gap. The rest are vendor, reputation, profession, holiday, dungeon and
promotional sources that HandyNotes never places as a world node; a different source is needed.

### Why rows were dropped

| reason | mounts | pets | toys |
|---|---|---|---|
| F3 reward nodes span more than one map | 15 | 100 | 19 |
| F4 reward nodes too far apart on one map | 33 | 35 | 13 |
| F5 pinned zone contradicts the catalog's own text | 6 | 4 | 10 |
| F6 catalog calls it a World Drop | 0 | 1 | 0 |

## The filter, exactly

1. **F0 — coordinates come from the node that actually awards the item.** Read
   `build/handynotes.jsonl` and take only `ns.reward.Mount.id`, `ns.reward.Pet.id`,
   `ns.reward.Toy.item`. The CSV's flattened `rewards`/`coords` columns are never used for
   geometry. This is the single most important change: `normalize-handynotes.py` unions coordinates
   across every node sharing an npc/quest key, so the CSV's `coords` column mixes the awarding node
   with prerequisite pins, vendor steps, hint pins and `ns.path` route nodes that carry no reward
   at all.
2. **F1 — catalog state.** Row exists in `collectible` for that module, has zero `waypoint` rows,
   `unavailable = 0`, `navigation_only = 0`.
3. **F2 — coordinate constraints.** `map_id > 0`, `0 < x <= 1`, `0 < y <= 1`. Zero rows in the whole
   corpus failed this; nothing was clamped.
4. **F3 — one map only.** Every reward-carrying node for the collectible must sit on the same
   `UiMapID`. If they span two or more, no single pin can represent it and the row is dropped.
5. **F4 — tight enough for one pin.** The emitted point is the observed reward coordinate that
   *minimises the maximum distance to every other reward coordinate*, and that maximum must be
   <= 0.03 of map width. Not "the first spawn" — see below.
6. **F5 — no zone contradiction.** If the collectible's `source_info` / `zone` / `drop_zone` names a
   zone, and the pinned map resolves to a confident zone name, the two must agree.
7. **F6 — not a declared World Drop.** One pet.
8. **Label is always the collectible's own name.** Never the node label.

The emitted coordinate is always a real coordinate that a HandyNotes node awarding that exact
collectible sits on — re-asserted against the raw dump after the fact, 747/747.

## What each reviewer objected to, and what I did

**All three said "suspect", and all three converged on the same root cause.**
`normalize-handynotes.py` writes `sorted(set(coords))` over the string `"mapID:x,y"`, so "the first
spawn" is an ASCII sort of the map-id digits — `"103" < "47"`, `"1525" < "52"`. Reviewer 2 measured
that 450/450 emitted pins were exactly that lexicographic minimum; reviewer 3 got 104/104 on the
multi-point subset. **Acted on: fully.** Coordinate selection was thrown away and rebuilt (F0, F4).
Every confirmed-wrong pin the reviewers produced is now either corrected or dropped:

| reviewer's finding | now |
|---|---|
| Oonar's Arm pinned to 1525 Revendreth, actually Maldraxxus | corrected to 1536 / 0.5144 / 0.4848 |
| Wildseed Cradle pinned to the Gardener's Flute prerequisite | corrected to the Cache of the Moon, 1565 / 0.6389 / 0.3778 |
| Infested Automa Core pinned to an `ns.path` route node on 1970 | corrected to 2066 / 0.4924 / 0.3441 |
| Tricked-Out Thinking Cap on 2023 (1 of 9 spawns) | corrected to 2112 Valdrakken |
| Gift of the Cycle on 2413 with no reward node there | corrected to 2576 |
| Star Chart took the unevidenced TreasureHunter coord | corrected to the reward-carrying WoD coord, 539 / 0.4939 / 0.7358 |
| Mage's Chewed Wand / Primalist Prison (drops from any Primalist rare) | dropped, F3 |
| Mouse, Squirrel, Rat, and the rest of the Safari samplers | dropped, F3 (up to 17 maps) |
| the three Primordial Direhorns pinned to Jade Forest | dropped, F3 |
| Grey Riding Camel (46 figurines spanning 0.69 of Uldum) | dropped, F4 |
| Time-Lost Proto-Drake (patrol route spanning 0.36) | dropped, F4 |
| Mawtouched Geomental (27 nodes, radius 0.22) | dropped, F4 |
| Flayer Youngling (Terokkar vs catalog Hellfire) | dropped, F5 |
| Slithering Brownscale (Tiragarde vs catalog Legion zones) | dropped, F5 |
| the six Netherwing Drakes (Shadowmoon vs catalog Shattrath) | dropped, F5 |

**"`publisher_count` is not corroboration."** Reviewers 2 and 3 both showed it measures which
expansion modules of one author's suite happen to cover a zone, and that the pets ranking's entire
`publisher_count = 3` top tier is one project agreeing with itself. **Acted on: fully, and the
finding is stronger than they stated.** Once the coordinate must come from a reward-carrying node,
only 35 of 983 candidates have reward nodes from more than one addon at all — and every one of
those 35 is a multi-zone critter that F3 drops anyway. So **all 747 surviving rows have
`publishers = 1`**. The column is retained for schema stability but carries no information: the
second "publisher" in the CSV was never corroborating the reward, only contributing extra
coordinates. Ranking by it would have been ranking by noise.

**"The `spawns` count is inflated by publisher near-duplicates."** Reviewer 3 measured 114 of 360
overstated. **Acted on:** `spawns` here counts distinct coordinates among reward-carrying nodes
only, and after F4 it is 1 for 744 of 747 rows.

**"Node labels leak locale keys and hint text"** — `quartermaster_note`, `in_cave`,
`{npc:32630}`, and (reviewer 3) four that got through every agent's filter, including
"Solve a sliding-tiles puzzle" and "Dog!". **Acted on: by removing the feature.** The label is
always the collectible's own name. This loses the genuinely better container names the toys pass
found ("Astrologer's Box", "Swamplighter Hive") — reintroduce them by hand if wanted, but no
automatic label extraction ships here.

**"Reported spot-checks are overstated"** — the Grey Riding Camel "confirmation" actually
contradicted `source_info` (catalog says Feralas). **Acted on:** that row is dropped (F4), and the
zone check in F5 is now mechanical rather than narrative.

**"Emit the multi-waypoint form instead of one point"** (all three reviewers, for the cross-zone
wild pets and the multi-spawn rares). **Not acted on** — the requested CSV schema is one point per
row, and 134 rows are dropped by F3 instead. That is the single biggest recoverable chunk of
coverage and the right follow-up.

## Residual risk this file still carries

- **225 rows are `medium` and 3 are `low`.** `medium` means the F5 zone check could not run: either
  the catalog names no zone, or the pinned map has no confident name in my map-name table (108 rows
  sit on 56 such maps). They are not contradicted, but they are not confirmed either.
- **A single-node pin cannot be checked by geometry.** Where exactly one HandyNotes node awards a
  collectible, this file simply repeats what HandyNotes says. Independent corroboration where it was
  available: for the 231 rows whose node NPC resolves to a name in
  `handynotes-table-rare-gap-audit.csv` or the rares catalog, 192 (83%) name the exact NPC the
  catalog's `source_info` names; the 39 that do not are mostly spelling variants
  (Karokta/Karoktra, Orumo/Oromo) or suffix noise, all in the same zone.
- **Roamers are pinned at one point.** The dump does not serialise HandyNotes POI/path coordinate
  lists, so a roaming rare that HandyNotes draws as a route appears here as its anchor point.
- **10 of the 20 F5 drops are probably my filter being wrong, not the data.** The catalog names a
  *sub-area* of the pinned map, which my zone table cannot resolve: Zskera Vaults inside the
  Forbidden Reach (toys 203852, 204256, 204257, 204262, 204687), Catalyst Gardens inside Zereth
  Mortis (190853), Khaz Algar containing Isle of Dorn (224585), Winterpelt Hollow inside the Azure
  Span (pet 3427), Vision of Orgrimmar = map 1469 (174920), Daggerspine Point inside Eversong (pet
  5020). These are safe to re-admit after a human look. The other 10 are real disagreements and
  should stay out.

## What to spot-check on Wowhead before this ships

Highest value first. Checking roughly 25 rows covers most of the systematic risk.

1. **The vendor pile-ups — 5 checks that validate 42 rows.** One coordinate legitimately carries
   several collectibles when a vendor sells them all; confirm the vendor's location and that they
   really stock the list. `2200 / 0.5022 / 0.618` (Elianna, Emerald Dream — 6 mounts + 7 pets),
   `2151 / 0.3561 / 0.5948` (the Vorquin vendor, 8 mounts), `109 / 0.4352 / 0.3526` (8 vanilla
   pets — also confirm what map 109 is, it has no name in my table), `2151 / 0.2926 / 0.5268`
   (7 pets), `2346 / 0.3538 / 0.4142` (6 Undermine pets).
2. **The three `low` rows** (`confidence = low`, the only ones where the reward nodes are not all on
   the same point).
3. **The 10 likely-false-positive F5 drops listed above** — these are coverage you can get back.
4. **A sample of the 174 `source = wild` pets.** They survive F3, so each is a single-zone species,
   but confirm the pinned zone is a real capture zone for 5–10 of them.
5. **Rows whose node NPC disagrees with `source_info`,** e.g. mount 1313 Rajani Warserpent — the
   catalog says vendor Zhang Ku, HandyNotes attaches it to the rare Rei Lun. Same zone either way,
   so the pin is defensible, but the pin and the source line will name different things.
6. **The 108 rows on unnamed maps** (any row whose `map_id` is not one of the ~101 zone maps): sample
   a few and confirm the map id is the zone you expect.

## Follow-ups worth doing

- Emit the multi-waypoint form `{ {mapID,x,y,"L"}, ... }` and recover the 134 F3 drops plus the 81
  F4 drops. Several F4 drops are two legitimate vendor locations for identical stock (the Emerald
  Dream Whisperbloom pair, radius 0.463, costs 8 rows on its own).
- Fix `scripts/db/normalize-handynotes.py`: (a) `sorted(set(coords))` is a string sort, so "first
  spawn" is meaningless — keep publisher and reward attribution per coordinate instead of unioning;
  (b) `rewards_of()` flattens a reward's `id` and `item` under one prefix, which is what produced
  the phantom `toy:442/454/485` tokens and forced every downstream pass to re-derive the split;
  (c) nodes with no npc/quest/achievement key are dropped entirely, which is why the CSV cannot see
  the Voidtalon, Corridor Creeper, wildseed-spirit and covenant-assault mounts that this pass picks
  up straight from the dump.
- Relabel `publisher_count` in `handynotes-nodes.csv` to something like `suites_listing_node` so it
  is never read as independent agreement again.
