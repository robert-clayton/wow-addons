# Collectionist The Burning Crusade ID inventory

This expansion has exact ID manifests, generated runtime data, TOC integration, exact runtime validation, and mocked scanner coverage under Collectionist's `tbc` expansion key.

## Snapshots and sources

- Final Burning Crusade Classic snapshot: `2.5.4.44833`
- Historical retail achievement/criteria snapshot: `7.3.5.26972`
- Current-retail validation snapshot: `12.1.0.69382`
- DB2 exports: `https://wago.tools/db2`
- Blizzard collectible guide: `https://news.blizzard.com/en-us/article/23523203/burning-crusade-mounts-pets-and-more`
- Current housing catalog: `https://housing.wowdb.com/decor/`
- All The Things source trees: `https://github.com/DFortun81/AllTheThings`

ATT patch chronology supplies the broad mount, pet, and toy boundaries. The final TBC Classic snapshot freezes the original profession spells, while current DB2 relationships resolve stable retail IDs. Blizzard's maintained guide independently maps 35 mounts, 47 pets, and 11 toys, but it is evidence rather than an ownership oracle: it omits valid TBC acquisitions and lists three Classic vendor pets.

## Frozen release manifests

The exact ID sets under `manifests/` contain:

- 68 mounts from 90 current IDs mapped from TBC patch rows.
- 65 battle pets from 85 audited current candidates.
- 22 toys from 32 audited current candidates.
- 29 housing decorations assigned by current TBC acquisition requirements.
- 99 player-facing achievements with 842 current-trackable achievement-tree leaves.
- 755 recipes, including 26 current TBC housing recipes.
- 20 ordered rare NPCs from the canonical **Bloody Rare** achievement.
- 0 treasure criteria because TBC has no comparable expansion-wide treasure checklist achievement.
- 16 maps, 22 collectible factions, and 5 currencies used as supporting IDs.

Regenerate and validate with:

```powershell
./scripts/generate-collectionist-tbc-housing-audit.ps1
./scripts/generate-collectionist-tbc-id-inventory.ps1
./scripts/validate-collectionist-tbc-manifests.ps1
./scripts/generate-collectionist-tbc-lua.ps1
./scripts/validate-collectionist-tbc-runtime.ps1
```

## Decoration ownership rule

Housing was introduced after TBC, but a decoration belongs to the expansion whose content is required to earn or unlock it.

- Include a decoration when a current acquisition path requires a TBC achievement, profession, dungeon, raid, encounter, or equivalent TBC system.
- Creation build, item expansion metadata, visual theme, catalog tag, and vendor location do not establish ownership by themselves.
- A later alternate source does not move an earlier TBC acquisition into a later expansion.
- Hidden, DNT, and source-less catalog rows are not collectible manifest entries.

The acquisition-first scan covers all 2,911 live catalog rows and separately audits the 51 TBC-themed rows. Twenty-four themed rows are TBC-owned, while five TBC acquisitions sit outside that theme filter, producing exactly 29 decorations:

- 26 Outland profession recipes.
- 2 Eye of the Storm achievement rewards.
- 1 Nalorakk encounter drop from Zul'Aman.

The five non-themed rows are Arakkoan Alchemist's Concoction, Arakkoan Alchemist's Bottle, Uncontested Battlefield Banner, Netherstorm Battlefield Flag, and Amani Ritual Altar. The 27 themed exclusions comprise 16 hidden or source-less rows, six Midnight Community Coupon rewards, three Midnight Razorwind Shores rewards, the Wrath Kirin Tor Glass Table recipe, and the Midnight login reward Miniature Replica Dark Portal.

Housing evidence is retained in:

- `sources/housing-wowdb-acquisition-audit.csv`: all 29 confirmed TBC-owned decorations.
- `sources/housing-wowdb-theme-exclusions.csv`: all 27 themed rows rejected by acquisition ownership or collectibility.
- `sources/housing-wowdb-theme-catalog.csv`: the complete 51-row themed candidate set.
- `sources/housing-wowdb-global-acquisition-crosscheck.csv`: the exact 56 rows hit by the theme and reverse acquisition scan.

## Other collectible boundaries

The mount inventory maps 90 current mount IDs from ATT's TBC patch sections. Eight pre-existing Classic PvP mounts are assigned to Classic. Nine trading-card, Recruit-a-Friend, BlizzCon, or other external rewards are excluded under policy. Five NYI, duplicate, or internal records are excluded. The remaining 68 mounts are retained. Six ended rewards are marked unavailable rather than dropped: four Gladiator nether drakes, the original Amani War Bear, and the original Brewfest Ram.

The pet inventory is the union of the Blizzard guide, current pets reachable from ATT's TBC source trees, and current species from ATT's 2.x patch rows. This restores TBC holiday, quest, wild, and raid pets omitted by the guide. Sixteen trading-card, collector-edition, regional-promotion, or other external rewards are excluded. Five pets are assigned to Classic acquisition content; three of those Classic pets are incorrectly presented in Blizzard's TBC guide. One retired NYI Lucky species no longer exists in current retail and is recorded as an asserted unmapped source row rather than emitted as an ID.

The toy inventory resolves 19 current collectibles from 22 TBC patch rows, replaces the retired X-52 Rocket Helmet item with its current toy wrapper, and adds 13 later-created toys whose current acquisition uses TBC content. Eight trading-card, store, BlizzCon, or other external rewards are excluded. Arrival of the Naaru and The Last Relic of Argus belong to Cataclysm because they require Archaeology, even though their Draenei dig sites are in Outland.

## Achievement, rare, and recipe structure

The five dedicated TBC achievement categories plus seven starter-zone rows stored under the Eastern Kingdoms and Kalimdor categories contain 99 current IDs:

- 14 exploration, 13 Eye of the Storm, 40 dungeon and raid, 16 quest, and 16 reputation achievements. The extra five exploration and two quest rows cover Eversong Woods, Ghostlands, Azuremyst Isle, Bloodmyst Isle, and Isle of Quel'Danas even though retail stores them under continent categories shared with Classic.
- 845 total leaf criteria; 65 achievements with 2–30 leaves expose 651 stable runtime task rows.
- The 20 **Bloody Rare** leaves resolve directly to rare NPC IDs and form the rare manifest. **Medium Rare** uses the same target set and is not duplicated.

The 755 recipes resolve to 75 Alchemy, 129 Blacksmithing, 24 Cooking, 67 Enchanting, 76 Engineering, 5 Inscription, 157 Jewelcrafting, 128 Leatherworking, and 94 Tailoring spells. Every selected spell and skill-line ability still exists in current retail, and all 26 current TBC housing recipes are explicitly frozen.

## Runtime integration

Twenty-six source-owned rows formerly overlapped later manifests: 13 Warlords of Draenor pet species and 13 Legion toys. They now belong only to TBC, and the manifest validator requires zero overlap with every later expansion.

The eight generated catalogs load before Wrath. Runtime validation requires exact manifest equality, ordered Bloody Rare NPC criteria, all 16 map constants, exact achievement tasks, TOC ordering, and Lua syntax. The treasure catalog intentionally registers an empty set because TBC has no comparable expansion-wide treasure checklist. Re-run the generator against current retail immediately before packaging to detect upstream DB2 or housing-catalog changes.
