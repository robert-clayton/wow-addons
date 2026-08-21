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

Treasure groups use `treasures` and a stable `objectID`, `itemID` or `questID`.
Every row must have a name, stable entity identifier, map/coordinates,
expansion, and source provenance. A provider node already represented by an
achievement criterion augments that criterion's metadata instead of becoming a
second row.

**Contract extension (2026-08-20): `questID` is an accepted treasure identity.**
The second-publisher table providers below key their nodes on a quest
completion flag rather than an object or item. A completed quest is as stable
an identity as an object ID and is what the game itself uses to remember the
pickup, so the contract now names it. Nothing else changes: these rows are
still navigation-only and still never acquire a collected state.

The name requirement is load-bearing and was enforced on ingestion: 409 of the
834 quest-identified treasure candidates carry neither a provider comment nor a
criteria ID, and a nameless "Location only" pin is not worth shipping. They
remain deferred until a name can be resolved.

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

## Second-publisher table providers

The constructor count does not cover seven installed HandyNotes plugins from a
second publisher. Those plugins use coordinate-keyed zone tables rather than
`Rare({...})` and `Treasure({...})` nodes. The reproducible table-provider audit
normalizes their stable identities separately:

- 1,714 unique coordinate-backed rare NPC IDs, of which 993 are already in
  Collectionist and 721 remain navigation candidates;
- 1,400 unique quest-identified treasure nodes, of which 566 already map to a
  Collectionist treasure criterion or quest and 834 remain candidates.

These remain audit queues, not import lists. Rare aliases and phase duplicates
still require review. Quest-only treasures also require an explicit extension
of the navigation-only identity contract, which currently permits object or
item IDs but not quest IDs.
