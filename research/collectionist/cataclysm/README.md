# Collectionist Cataclysm ID inventory

This expansion has exact ID manifests, generated runtime data, TOC integration, exact runtime validation, and mocked scanner coverage. It registers under Collectionist's `cata` expansion key.

## Snapshots and sources

- Final Wrath Classic baseline: `3.4.3.54261`
- Cataclysm Classic snapshot: `4.4.2.60895`
- Final Legion retail relationship snapshot: `7.3.5.26972`
- Current-retail validation snapshot: `12.1.0.69382`
- DB2 exports: `https://wago.tools/db2`
- Build chronology: `https://warcraft.wiki.gg/wiki/Public_client_builds`
- Blizzard collectible guide: `https://news.blizzard.com/en-us/article/23492555/cataclysm-mounts-pets-and-more`
- Current housing catalog: `https://housing.wowdb.com/decor/`
- All The Things source trees: `https://github.com/DFortun81/AllTheThings`

The historical snapshot difference supplies the broad mount and recipe boundary. Current DB2 relationships resolve stable retail IDs and prove that the selected records still exist. Blizzard's guide supplies an independent acquisition check for 22 unique mounts, 40 pets, and 9 toys; ATT patch and acquisition data covers the collectible rows the guide does not enumerate.

The Blizzard page contains several link defects that are preserved in `sources/blizzard-cataclysm-collectibles.csv` rather than silently trusted: Brown Riding Camel is duplicated and points at a Pandaria direhorn item, Mylune's Call points at Ash-Covered Horn, the Alliance Tol Barad Searchlight points at Battle Horn, and the Fandral row splits one item across two links. Mapping uses the guide text plus current item, spell, creature, and faction evidence.

## Frozen release manifests

The exact ID sets under `manifests/` contain:

- 48 mounts from 63 audited Cataclysm-era candidates.
- 42 pets: 40 from the official Cataclysm acquisition guide plus Pterrordax Hatchling and Voodoo Figurine from Cataclysm Archaeology.
- 40 toys from 61 audited patch/source candidates.
- 46 housing decorations assigned by current Cataclysm acquisition paths.
- 233 player-facing achievements with 707 achievement-tree leaves.
- 690 recipes, including 20 current Cataclysm housing recipes.
- 0 rare and 0 treasure tracker criteria: Cataclysm has no canonical expansion-wide checklist achievement equivalent to the dedicated rare/treasure trackers used by later expansions.
- 15 maps, 11 factions, and 15 currencies used as supporting IDs.

`scripts/generate-collectionist-cata-id-inventory.ps1` regenerates the inventories and manifests. `scripts/validate-collectionist-cata-manifests.ps1` freezes exact counts, source boundaries, current-retail existence, guide mappings, profession/category totals, housing ownership, and zero later-expansion overlap.

## Decoration ownership rule

Housing was introduced after Cataclysm, but a decoration belongs to the expansion whose content is required to earn or unlock it.

- Include a decoration when a current acquisition path requires a Cataclysm quest, achievement, reputation, profession, dungeon, raid, or equivalent Cataclysm system.
- A record's creation build, item expansion field, visual theme, catalog tag, or vendor location does not establish ownership by itself.
- A later alternate acquisition path does not move an earlier Cataclysm unlock forward.
- A later quest or vendor placed in an old zone remains owned by that later expansion when no Cataclysm requirement is involved.

The acquisition-first scan covers all 2,911 live catalog rows and separately audits the 58 Cataclysm-themed rows. The exact result is 46 Cataclysm-owned decorations:

- 20 Cataclysm profession recipes.
- 20 Cataclysm quest rewards or quest-gated vendor unlocks.
- 2 Cataclysm achievements.
- 2 Cataclysm reputation-vendor rewards.
- 2 Cataclysm dungeon/raid drops.

Only 33 of those 46 carry the Cataclysm theme tag. The reverse full-catalog scan found 13 source-owned decorations outside that theme: Lordaeron Fence, Lordaeron Fencepost, Tauren Bluff Rug, Shadowforge Wooden Box, Shadowforge Grinding Wheel, Thelsamar Hanging Lantern, Stormwind Footlocker, Westfall Woven Basket, Stormwind Arched Trellis, City Wanderer's Candleholder, Stormwind Weapon Rack, Shadowforge Lamppost, and Twilight Fire Canister.

The 25 Cataclysm-themed exclusions are fully classified as one Classic acquisition, two Burning Crusade acquisitions, two Legion acquisitions, three Battle for Azeroth acquisitions, six Dragonflight acquisitions, three Midnight acquisitions, and eight internal/DNT rows. In particular, the six Reclamation of Gilneas vendor rewards remain Dragonflight-owned even though their appearance and location are Gilnean.

Housing evidence is retained in:

- `sources/housing-wowdb-acquisition-audit.csv`: all 46 confirmed Cataclysm-owned decorations.
- `sources/housing-wowdb-theme-exclusions.csv`: all 25 themed rows rejected by acquisition ownership or collectibility.
- `sources/housing-wowdb-theme-catalog.csv`: the complete 58-row Cataclysm-themed candidate set.
- `sources/housing-wowdb-global-acquisition-crosscheck.csv`: the exact 71 rows hit by the theme and reverse acquisition scan.

## Other collectible boundaries

The mount inventory retains 48 source/release-owned rows. Thirteen store, trading-card, recruit-a-friend, or promotion mounts are excluded; the internal Tiger row is excluded; and Felfire Hawk is assigned to Warlords because its live collection achievement was added there. The Vicious, Ruthless, and Cataclysmic Gladiator drakes remain in the manifest but are marked unavailable. The Cataclysmic Gladiator row is explicitly recovered from its preserved retail item/achievement because the selected Cataclysm Classic snapshot omits the Mount record.

The toy inventory starts from all 55 ATT ToyDB rows tagged to patches 4.0.1 through 4.3.2, rejects 14 art-template records and 7 trading-card/promotion items, resolves three later replacement item wrappers, and adds six source-owned rewards outside that patch slice: Darkspear Pride and Gnomeregan Pride from the Cataclysm pre-launch events, the Draenei Archaeology reward The Last Relic of Argus, Fandral's Seed Pouch, and the two Cataclysm Timewalking toys. This produces 40 current toy IDs. MiniZep Controller and both pre-launch event toys are retained but marked unavailable.

Nine Cata-raid pets and eight converted/source-owned toys formerly overlapped the Legion manifests. The Cataclysm runtime integration transfers all 17 rows to Cataclysm ownership and the validator now requires zero later-expansion overlap.

## Achievement and recipe structure

The eight Cataclysm achievement categories contain 233 current IDs:

- 62 dungeon, 62 raid, 8 exploration, 43 quest, and 9 reputation achievements.
- 15 Battle for Gilneas, 20 Twin Peaks, and 14 Tol Barad achievements.
- 707 total leaf criteria; 90 achievements with 2–30 leaves expose 500 stable runtime task rows.

The 690 recipes resolve to 47 Alchemy, 91 Blacksmithing, 33 Cooking, 53 Enchanting, 38 Engineering, 38 Inscription, 225 Jewelcrafting, 95 Leatherworking, and 70 Tailoring spells. Every selected spell and skill-line ability still exists in current retail, and all 20 current Cataclysm housing recipes are explicitly frozen.

## Runtime integration

The eight generated Cataclysm Lua catalogs load before Mists of Pandaria. Runtime validation requires exact manifest equality, exact achievement task criteria, all 15 map constants, TOC ordering, and Lua syntax. The rare and treasure catalogs intentionally register empty sets because no canonical Cataclysm-wide checklist matches those trackers.

Regenerate and validate with:

```powershell
./scripts/generate-collectionist-cata-housing-audit.ps1
./scripts/generate-collectionist-cata-id-inventory.ps1
./scripts/validate-collectionist-cata-manifests.ps1
./scripts/generate-collectionist-cata-lua.ps1
./scripts/validate-collectionist-cata-runtime.ps1
```

Re-run the current-retail generator immediately before packaging to detect upstream DB2 or live-catalog changes.
