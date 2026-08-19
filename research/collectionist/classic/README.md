# Collectionist Classic ID inventory

This expansion has exact ID manifests, generated runtime data, TOC integration, exact runtime validation, and mocked scanner coverage under Collectionist's `classic` expansion key.

## Snapshots and sources

- Final pre-TBC Classic Era recipe snapshot: `1.13.7.38704`
- Historical retail achievement/criteria snapshot: `7.3.5.26972`
- Current-retail validation snapshot: `12.1.0.69382`
- DB2 exports: `https://wago.tools/db2`
- Current housing catalog: `https://housing.wowdb.com/decor/`
- All The Things source trees: `https://github.com/DFortun81/AllTheThings`

No dedicated Blizzard “Classic Mounts, Pets, and More” article was found in the maintained guide series. ATT chronology and acquisition trees therefore define the broad collectible boundary, the final Classic Era snapshot defines the profession boundary, and current DB2 rows prove stable retail IDs and names.

## Frozen release manifests

The exact ID sets under `manifests/` contain:

- 85 mounts from 99 current IDs mapped from ATT's Vanilla block.
- 59 battle pets from 70 audited current candidates.
- 10 toys from 20 audited current candidates.
- 22 housing decorations assigned by current Classic acquisition requirements.
- 199 player-facing achievements with 1,268 achievement-tree leaves.
- 1,223 recipes, including 19 current Classic housing recipes.
- 0 rare criteria because Classic has no canonical expansion-wide rare checklist achievement comparable to **Bloody Rare** or **Frostbitten**.
- 0 treasure criteria because Classic has no canonical expansion-wide treasure checklist achievement.
- 52 maps, 33 factions, and 5 currencies used as supporting IDs.

Regenerate and validate with:

```powershell
./scripts/generate-collectionist-classic-housing-audit.ps1
./scripts/generate-collectionist-classic-id-inventory.ps1
./scripts/validate-collectionist-classic-manifests.ps1
./scripts/generate-collectionist-classic-lua.ps1
./scripts/validate-collectionist-classic-runtime.ps1
```

## Decoration ownership rule

Housing was introduced in Midnight, but a decoration belongs to the expansion whose content is required to earn or unlock it.

- Include a decoration when its acquisition requires a Classic profession, quest, achievement, dungeon, raid, or equivalent original-world system.
- Creation build, item expansion metadata, visual theme, catalog tag, and vendor location do not establish ownership by themselves.
- A later alternate source does not move an earlier acquisition into a later expansion.
- New housing-vendor stock placed in an old zone is not Classic content without an older acquisition requirement.
- Hidden, DNT, and source-less catalog rows are not collectible manifest entries.

The acquisition-first scan covers all 2,911 live catalog rows and separately audits all 53 Classic-themed rows. Nineteen themed rows are Classic-owned, while three Classic acquisitions sit outside that theme filter, producing exactly 22 decorations:

- 19 Classic profession recipes.
- 1 **Duel-icious** achievement reward.
- 1 **A Binding Contract** quest reward.
- 1 Emperor Dagran Thaurissan encounter drop from Blackrock Depths.

The three non-themed Classic rows are Loch Modan Bearskin Rug, Gnomish Steam-Powered Bed, and Stormwind Forge. The 34 themed exclusions comprise 13 earlier-expansion-tag mismatches whose acquisitions belong to TBC through BFA, five Midnight acquisitions, nine new vendor-location-only rows, and seven internal, DNT, or source-less rows. **Head of the Broodmother** is explicitly Wrath-owned because its earliest acquisition is the Onyxia achievement **More Dots! (25 player)**.

Housing evidence is retained in:

- `sources/housing-wowdb-acquisition-audit.csv`: all 22 confirmed Classic-owned decorations.
- `sources/housing-wowdb-theme-exclusions.csv`: all 34 themed rows rejected by acquisition ownership or collectibility.
- `sources/housing-wowdb-theme-catalog.csv`: the complete 53-row themed candidate set.
- `sources/housing-wowdb-global-acquisition-crosscheck.csv`: the exact 56 rows hit by the theme and reverse acquisition scan.

## Other collectible boundaries

The mount inventory maps 99 current mount IDs from ATT's Vanilla block. Fourteen rows in ATT's NYI subsection are retained only as audit evidence and excluded as never-implemented, deprecated, or internal. The remaining 85 source-owned mounts are retained, including historical rewards and all eight Classic battleground mounts that were previously excluded from the TBC boundary.

The pet inventory unions 54 current species from ATT's Classic chronology with 27 species found in explicit Classic dungeon, raid, world-drop, PvP, and crafting trees. Seven Collector's Edition, BlizzCon, or iCoke pets are excluded by policy. Four Archaeology pets belong to Cataclysm. Twelve later-created pets remain Classic-owned because they are acquired from original Classic dungeons or raids, producing 59 release IDs.

The toy inventory unions all eight original Classic ToyDB rows with current toys found in the same explicit Classic source trees. Nine Archaeology toys belong to Cataclysm and Krastinov's Bag of Horrors belongs to the Mists-era Scholomance encounter. Vial of Green Goo and Familiar Journal remain Classic-owned because their acquisitions require Gnomeregan and Old Scholomance. Dimensional Ripper - Everlook and Ultrasafe Transporter: Gadgetzan are also original Classic Engineering toys. Those four source-owned toys currently overlap later runtime manifests and form an exact temporary transfer boundary.

## Achievement and recipe structure

The Classic achievement selection contains 199 current IDs across ten retail categories:

- 41 Eastern Kingdoms and Kalimdor exploration achievements.
- 54 Alterac Valley, Arathi Basin, and Warsong Gulch achievements.
- 49 Classic dungeon and raid achievements.
- 51 Eastern Kingdoms and Kalimdor quest achievements.
- 4 Classic reputation achievements.
- 1,268 total leaf criteria; 115 achievements with 2–30 leaves expose 1,149 stable runtime task rows.

Seven rows stored under the continent categories actually require TBC starter-zone content—Explore Ghostlands, Explore Eversong Woods, Explore Azuremyst Isle, Explore Bloodmyst Isle, Explore Isle of Quel'Danas, Ghostlands Quests, and Bloodmyst Isle Quests. They were moved into the TBC manifest rather than being absorbed into Classic.

The 1,223 recipes resolve to 114 Alchemy, 248 Blacksmithing, 81 Cooking, 135 Enchanting, 158 Engineering, 5 Inscription, 2 Jewelcrafting, 231 Leatherworking, and 249 Tailoring spells. Inscription and Jewelcrafting contribute only their current Classic housing recipes because those professions did not exist in original Classic. Every selected spell and skill-line ability still exists in current retail.

## Runtime integration

Toy IDs `480`, `482`, and `582` formerly overlapped Legion, while toy ID `1340` overlapped Dragonflight. They now belong only to Classic, and the manifest validator requires zero overlap with every later expansion.

The eight generated catalogs load before The Burning Crusade. Runtime validation requires exact manifest equality, all 52 map constants, exact achievement tasks, TOC ordering, and Lua syntax. The rare and treasure catalogs intentionally register empty sets because Classic has no comparable expansion-wide checklist achievements. Re-run the current-retail generator immediately before packaging to detect upstream DB2 or live-catalog changes.
