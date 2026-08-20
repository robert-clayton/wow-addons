# Rare and treasure navigation-only policy

## Decision

Collectionist supports navigation-only rare and treasure entries when no
reliable Blizzard completion signal exists. They are map references, not
collectibles:

- render in the normal rare or treasure list with a `Location only` label;
- keep their waypoint, entity ID, source, zone, and expansion metadata;
- may be pinned manually to the Targets overlay;
- never enter completion denominators, Collection Score, collected lists,
  expansion ownership totals, or roster bitmaps;
- never acquire or persist a collected/defeated/looted state.

This avoids the two dishonest alternatives: omitting a useful verified map
location, or pretending an NPC/object has persistent completion when the game
does not expose one.

## Data contract

Navigation-only data uses a top-level registered group:

```lua
{
    navigationOnly = true,
    source = "zone_key",
    zone = "Zone Name",
    rares = {
        { npcID = 123, name = "Rare Name", waypoint = { mapID, x, y } },
    },
}
```

Treasure groups use `treasures` and a stable `objectID` or `itemID`. Every row
must have a name, stable entity identifier, map/coordinates, expansion, and
source provenance. A provider node already represented by an achievement
criterion augments that criterion's metadata instead of becoming a second row.

## HandyNotes audit boundary

The installed HandyNotes corpus contains at least 1,707 raw rare constructor
calls and 771 raw treasure constructor calls outside Collectionist's existing
achievement-backed model. Those are discovery counts, not eligible ingestion
counts: provider overlap, shared-spawn aliases, phased duplicates, one-time
quest nodes, and entries without stable IDs still need normalization and
deduplication. No raw constructor call should be imported directly.

The next ingestion audit must emit one decision per normalized node: augment an
achievement criterion, include as navigation-only, exclude as duplicate, or
defer for missing stable identity/source coordinates.
