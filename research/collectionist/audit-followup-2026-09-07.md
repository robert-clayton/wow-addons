# Collectionist remaining-gap audit — September 7, 2026

Baseline: release **1.14.0**, commit `d923f9b`. This follow-up reviews the
remaining queues from the first audit and the broader coverage audits. These
findings were used to build release **1.15.0**.

## Release resolution

Release 1.15.0 fixes the classifier's patch-boundary and historical-conditional
handling, adds all 64 omitted Inscription recipes, adds all 44 named Patch 12.1
recipes, and replaces 100 false `unavailable` labels with concrete ATT source
ancestry. Forty-two of the new Patch 12.1 recipes have concrete sources; G-00
and Piercing Amani Lapis remain unknown. Eighteen affected recipes remain unavailable because the audited
snapshots do not establish a sufficiently specific current acquisition.

The release also adds all 17 Trading Post collectibles and all 38 reviewed
decorations. It imports the 73 specific criterion matches as 85 coordinate
tuples, including separate physical NPC identities for Consumption and Helmet
Missingway. The remaining waypoint queue is now 97 criteria: 23 rares and 74
treasures.

The 150 additional decoration leads, 249 achievement candidates, shared spawn
pools, dynamic event markers, spell-backed criteria, and unresolved identities
remain research queues because this audit did not establish enough restriction
or routing data for safe runtime entries.

## Findings requiring follow-up

| Area | Finding | Next action |
| --- | --- | --- |
| Recipe classification | **118 shipped Inscription recipes** inherit an invalid NYI classification; **64 omitted Inscription recipes** also have classification conflicts. | Fix patch-section and conditional-branch parsing, then resolve acquisition and removal status per recipe. |
| New recipes | **44 named 12.1 recipe spells** are absent. Forty have concrete ATT routes, two ATT-unsorted recipes have externally corroborated world-drop routes, and two remain unresolved. | Add every recipe identity and use `unknown` where acquisition is unresolved. |
| Trading Post | **17 missing entries: 8 mounts and 9 pets.** | Include their in-game Trading Post routes despite their older shop/promotion origins. |
| Decorations | The original **38 remaining candidates** now have corroborated acquisition sources. | Add them with endeavor, quest, profession, achievement or vendor restrictions. |
| Additional decorations | **150 more missing decorations** have concrete ATT acquisition ancestry. Another **8** have mixed promotion/vendor records. | Review requirements and current availability; vendor resale alone does not establish an in-game unlock. |
| Criterion waypoints | **73 of the 170** previously unresolved criteria now have specific ATT source matches. | Add verified mappings; retain credit IDs separately from physical NPC identities where needed. |
| Achievements | **249 candidates** have an immediate collection-policy basis. | Resolve expansion ownership and prerequisite graphs before adding them. |

Counts describe different identities and are not additive. A decoration can
also have a missing crafting recipe or achievement.

## 1. Inscription source classification is leaking across patch sections

`scripts/generate-collectionist-recipe-acquisition.ps1:102` recognizes headings
with at least three dashes. ATT's Inscription file changes patch sections with
two-dash comments such as `-- PATCH 6.0.1 --`, without necessarily repeating an
acquisition heading. The preceding `--- NYI ---` state therefore carries into
later patch sections. The same error recurs after later NYI blocks.

The acquired Inscription source demonstrates this at lines 706–762: the NYI
block ends, the 6.0.1 section begins, and ordinary Draenor recipes and ink
research follow. Replaying the current parser and a patch-boundary reset
identifies 118 shipped rows whose `source="unavailable"` has this invalid
basis. Examples in `Modules/Recipes/Data/WarlordsOfDraenor.lua` include Card of
Omens (`166669`) and War Paints (`169081`). The Legion file similarly marks
Darkmoon Card of the Legion (`191659`) unavailable.

This affects behavior, not only descriptive text. The recipe scanner treats
these records as Legacies, omits their Collection Score, and removes them from
the list and denominator when Hide unobtainable is enabled.

Of the 64 omitted Inscription candidates, 63 are affected by the same state
leak. The remaining one, Grimoire of the Abyssal (`225553`), exposes a second
parser defect: the raw source has both `AFTER 10.1.5` and `BEFORE 10.1.5`
branches. Reading both unconditionally lets the historical NYI branch overwrite
the retail occurrence.

**The 118 figure is an invalid-classification count, not a claim that every
recipe is currently obtainable.** Removal flags and surviving acquisition
routes must be checked individually. Resetting NYI should not turn all of them
into trainer recipes. The same patch-boundary comparison across the other eight
profession files found no additional shipped NYI leaks of this exact form.

Evidence: [182 affected IDs](sources/followup-2026-09-07/inscription-classification.csv),
[ATT Inscription source](https://github.com/DFortun81/AllTheThings/blob/master/.contrib/Parser/DATAS/00%20-%20Profession%20DB/Inscription.lua).

## 2. The recipe gap queue predates the 12.1 additions

The old queue falls from 844 absent abilities to 443 against the 1.14.0
catalog: 299 UI/training exclusions, 78 uncorroborated abilities, 2
never-implemented-only records and the 64 Inscription conflicts above.

It does not cover the new patch's full recipe set. Matching current ATT
profession sections and compiled acquisition records finds **44 named 12.1
recipes**, all absent from Collectionist. Their professions are Alchemy 4,
Blacksmithing 4, Cooking 8, Enchanting 4, Engineering 7, Inscription 4,
Jewelcrafting 6, Leatherworking 4 and Tailoring 3.

Examples include Concentrated Silvermoon Health Potion (`1289744`), Plant
Protein (`1296450`), Practically Pork (`1296449`), Stretched Snakeskin Rack
(`1296510`) and both new material-refining recipes (`1307462`, `1307466`). ATT
lists eleven distinct recipe spells under Thalassian Recipe in a Bottle
(`278329`); two recipe items teach the same Sweet-And-Sour Skewers spell, so
they must not become two completion entries.

Coiled Snake-Eye (`1291687`), Polished Ammolite (`1291690`) and Piercing Amani
Lapis (`1297680`) have only Unsorted acquisition in the compiled ATT snapshot.
The current profession UI and profession guide identify the first two as world
creature drops, while Piercing Amani Lapis remains unresolved. G-00 (`1297647`)
sits under ATT's broad Craftables grouping, which establishes that the recipe
item can be traded but not how it is acquired, so its runtime source also
remains unknown. Several guide costs and skill thresholds differ from ATT, so
those values still need adjudication. Patch annotations inherited from an
entire zone are not reliable first-availability dates; the 44 count additionally
requires an explicit 12.1 section in the profession source.

Evidence: [44 recipe IDs and source fields](sources/followup-2026-09-07/recipes-12.1.csv),
[12.1 profession guide](https://www.wow-professions.com/news/midnight-patch-12-1-knowledge-point-reset).

## 3. Trading Post coverage still omits older external rewards

The earlier audit listed 130 omissions; 113 have since been added. The remaining
17 are still absent by Mount Journal ID or pet species ID, including Swift
Zhevra, Spectral Gryphon, Spectral Wind Rider, Cindermane Charger, Warforged
Nightmare, The Dreadwake, Hateforged Blazecycle and Soaring Sky Fox.

The pet omissions are Rocket Chicken, Spirit of Competition, Spectral Tiger
Cub, Pandaren Monk, Lil' K.T., Sand Scarab, Lil' Flameo, Thrillbot 9000 and
Chillbot 9000. There are no remaining toys in this queue.

ATT's Trading Post inventory corroborates all 17. Official inventory articles
were found for 15; the evidence CSV explicitly uses ATT for Warforged Nightmare
and Lil' K.T. rather than claiming their original shop listings prove Trading
Post availability. These are rotating collectibles, not necessarily items sold
this month. Blizzard's September inventory independently confirms Swift Zhevra,
Pandaren Monk, Spectral Tiger Cub and Spirit of Competition.

Evidence: [17 IDs and acquisition evidence](sources/followup-2026-09-07/trading-post.csv),
[September Trading Post inventory](https://worldofwarcraft.blizzard.com/en-us/news/24295383).

## 4. Decoration omissions are larger than the original shortlist

The 38 candidates left by the release audit now resolve as:

| Acquisition | Missing decor |
| --- | ---: |
| Every Bakar Has Its Day / Roshai Lightstep | 13 |
| Candle Culture / Timicky | 16 |
| Cursed Keepsake | 3 |
| Arcantina quests and Morta Gage | 2 |
| Throska | 1 |
| Leatherworking | 1 |
| Older achievement/vendor or boss source | 2 |

The two older entries are Nesingwary Mounted Elk Head (`4841`, item `248808`)
and Horde Warlord's Throne (`9263`, item `253242`). The crafting entry is
Stretched Snakeskin Rack: decor `26378`, item `279346`, recipe `1296510`, recipe
item `275334`. Its decor-use spell `1306587` is a separate identity.

Older item pages can still say a Candle Culture reward is unavailable. The
current endeavor reward list and Blizzard's Curse of Ula'tek release article
postdate those pre-release flags. Neighborhood endeavor access and vendor
position still depend on the active endeavor and faction.

Evidence: [38 reviewed items](sources/followup-2026-09-07/decorations-reviewed.csv),
[Every Bakar Has Its Day rewards](https://housing.wowdb.com/endeavors/20/every-bakar-has-its-day/),
[Candle Culture rewards](https://housing.wowdb.com/endeavors/12/you-take-candle/),
[Curse of Ula'tek release](https://worldofwarcraft.blizzard.com/en-gb/news/24294370/curse-of-ulatek-now-live-journey-to-the-coiled-isle).

The broader 816-row DB2 queue has **634 IDs still absent**. All 38 above are
part of those 634. The old source audit extracts detailed ancestry only from
Housing.lua; an item found in Zones.lua or another acquisition category is
classified merely as a file-level lead. Extracting those trees now finds
**150 additional IDs with concrete sources**, plus 8 mixed promotion/vendor
IDs that need external-unlock review. These are candidates for source and
restriction adjudication, not 150 separately verified live purchases.

An independently confirmed example is Embellished Dwarven Tome (`1998`, item
`246108`), listed under Breana Bitterbrand and Craw MacGraw in Twilight
Highlands. Open Tome of Twilight Nihilism (`766`, item `239177`) likewise has
concrete rotating-vendor records for Solelo and Lonalo. Many ordinary vendor
items were missed alongside the newer content.

Evidence: [additional source records](sources/followup-2026-09-07/decoration-additional-sources.csv),
[Embellished Dwarven Tome](https://housing.wowdb.com/decor/1998/embellished-dwarven-tome-1998/).
The remaining broad queue also contains external unlocks, unimplemented entries,
unsorted records and items without acquisition evidence; do not bulk-import it.

## 5. Remaining criterion waypoints and identity problems

| Decision for the original 170 criteria | Count |
| --- | ---: |
| Specific ATT source match recovered | 73 |
| Shared or multi-zone spawn pool needs context | 10 |
| Dynamic Tormentors event marker is not a boss spawn | 15 |
| Moving Clan Aylaag event marker needs event routing | 2 |
| Spell-backed criterion requires a routing identity | 12 |
| No specific match found in the snapshots | 58 |

Most recovered treasure coordinates come from `questID` fields on ATT objects
and NPCs, or an explicit `crit(criteriaID, {achID=...})` child. Searching only
standalone quest factories missed those links.

Two rare IDs are kill-credit identities rather than the physical encounter
NPC. ATT explicitly connects Consumption's criterion asset `180132` to NPC
`179769`, and Helmet Missingway's asset `199645` to NPC `193263`. Completion
identity and the NPC used for a source link must remain distinct.

Blightpaw the Depraved belongs to the Thaldraszus achievement but spawns in
Ohn'ahran Plains, map `2023`, near `90.2, 40.2`. ATT and the HandyNotes core
provider agree. Reject the table-provider record on map `2025` at `31.1, 71.2`.
An achievement's zone must not reject a corroborated encounter just across its
border. Similar multi-zone considerations affect the Dragon Isles lunker rares.

The 12 Forbidden Reach treasure criteria use spell assets. The existing
NPC/object/quest resolver cannot represent them directly. Ten share generic
small-treasure spawn markers, Forbidden Hoard has its own spawn set, and
Spellsworn Reserves still lacks a matching marker in these snapshots.

Evidence: [all 170 decisions and candidate coordinates](sources/followup-2026-09-07/criterion-waypoints.csv).
Release 1.15.0 imports only rows marked `source_backed_pin_candidate`.

## 6. Achievement and navigation queues need scope and deduplication

All 3,527 old achievement candidates remain absent, but the entire queue should
not be added automatically. `scripts/db/achievement-scoping-policy.py` limits
the tracker to collections, qualifying rewards and prerequisites, and selected
expansion features. None of the 3,527 appears in the explicit dropped-ID list;
that alone does not make each one policy-eligible.

There are **249 immediate candidates**: 157 in Collections and 102 whose reward
item is already tracked, with 10 overlapping. This still requires expansion
placement and prerequisite/reward review. The rest needs the same policy
classifier, particularly Legacy and Feats of Strength.

Evidence: [249 priority achievement IDs](sources/followup-2026-09-07/achievement-priority.csv).

Rechecking the coordinate-keyed HandyNotes queues against shipped IDs and
typed DB2 criteria leaves 762 rare NPC identities and 821 treasure quest
identities unmatched. These are provider identities, not net new collectibles:
aliases, shared encounters and phase duplicates still need deduplication. Two
rare records lack names; 251 treasure records lack comments, though some can
still acquire a name through their criteria. The navigation policy permits
quest IDs and excludes location-only entries from completion and score.

The ordinary-source DB2 mount, pet and toy queues have no remaining `include`
rows missing from the addon. Their residual rows are the previously classified
5 mount exclusions, 2 pet exclusions and 19 toy exclusions/missing item records.

## Evidence boundaries

The audit compares the 1.14.0 shipped-data dump with local DB2, ATT and HandyNotes
snapshots, then corroborates targeted availability claims using current web
sources. The exact original ATT commit remains unknown. Fresh profession source
files were read from ATT master on September 7; their hashes and all main local
input hashes are recorded in [snapshot-hashes.csv](sources/followup-2026-09-07/snapshot-hashes.csv).

CSV generation checks enforce the stated identity counts, deduplicate recipe
spells, and separate unresolved or external-unlock cases. Release 1.15.0 uses
only the confirmed subset described above. No live WoW session was available
to validate provider behavior or disputed acquisition requirements.
