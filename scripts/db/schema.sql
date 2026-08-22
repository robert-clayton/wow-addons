-- Collectionist content database.
--
-- One place where every source lands, gets reconciled, and gets constrained.
-- The addon never reads this; it is a build-time authority from which the
-- shipped Lua is emitted.
--
-- Constraints here are not decoration. Each one below closes a bug class that
-- actually shipped:
--
--   expansion FK      "dragonflight" emitted where the addon uses "df"; the
--                     key matched nothing and Options could not filter it.
--   source FK         101 navigation zone keys absent from the module's source
--                     order, rendering as raw lowercase in random order.
--   waypoint CHECKs   a coordinate list flattened to y = 0, pinning the top
--                     edge of the map. Nothing at runtime would have noticed.
--   pet_type CHECK    petType = 0, outside the 1-10 family range, which the
--                     scanner reads as "absent" and so silently masks.
--   criterion UNIQUE  23 criteria attached to the wrong achievement.
--   provenance        the navigation audit read its own previous output as if
--                     it were pre-existing coverage and ate its own tail.

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------- vocabulary

CREATE TABLE expansion (
    key         TEXT PRIMARY KEY,          -- 'vanilla', 'df', 'midnight'
    label       TEXT NOT NULL,
    ord         INTEGER NOT NULL UNIQUE
);

CREATE TABLE module (
    key         TEXT PRIMARY KEY,          -- 'mounts', 'recipes', ...
    list_key    TEXT NOT NULL,             -- the Lua table field name
    id_column   TEXT NOT NULL              -- which natural id this module uses
);

-- Source vocabulary is per module: "drop" means something different to Rares
-- than to Recipes, and each module has its own order/label tables in Lua.
CREATE TABLE source_kind (
    module      TEXT NOT NULL REFERENCES module(key),
    key         TEXT NOT NULL,             -- 'vendor', 'azsuna', 'tradingpost'
    label       TEXT NOT NULL,             -- what the player sees
    ord         INTEGER,                   -- render order; NULL sorts last
    PRIMARY KEY (module, key)
);

-- Where a row came from, and from which snapshot of it. Makes the unpinned-ATT
-- problem visible per row rather than invisible, and makes it impossible for a
-- generated row to be mistaken for upstream truth.
CREATE TABLE source_snapshot (
    id          INTEGER PRIMARY KEY,
    source      TEXT NOT NULL,             -- 'db2', 'att', 'handynotes', 'curated', 'generated'
    version     TEXT,                      -- build number, commit sha, addon version
    fetched_at  TEXT,
    note        TEXT,
    UNIQUE (source, version)
);

-- ---------------------------------------------------------------- content

-- The Lua ships groups of entries, not a flat list, and the group is not just
-- packaging: it carries the rendered header name, the category, and attributes
-- every entry inherits. Flattening it onto rows loses which rows belonged
-- together, so an emitter would have to invent the grouping -- and a re-emit
-- would reshuffle files that a human reads as diffs.
CREATE TABLE content_group (
    id              INTEGER PRIMARY KEY,
    module          TEXT NOT NULL REFERENCES module(key),
    expansion       TEXT NOT NULL REFERENCES expansion(key),
    ord             INTEGER NOT NULL,      -- position within its registration
    name            TEXT,
    category        TEXT,
    source          TEXT,
    zone            TEXT,
    zone_map_id     INTEGER,
    skill_line      INTEGER,
    navigation_only INTEGER NOT NULL DEFAULT 0 CHECK (navigation_only IN (0, 1)),
    available_after TEXT,
    -- Rares and treasures sometimes declare the achievement at group level with
    -- no entry list at all: the group IS the record. The emitter has to write
    -- those back without an entry list, and that cannot be inferred from the
    -- rows, so it is recorded here.
    is_record       INTEGER NOT NULL DEFAULT 0 CHECK (is_record IN (0, 1)),
    UNIQUE (module, expansion, ord)
);

CREATE TABLE collectible (
    id              INTEGER PRIMARY KEY,
    group_id        INTEGER REFERENCES content_group(id),
    ord             INTEGER,               -- position within its group
    module          TEXT NOT NULL REFERENCES module(key),
    expansion       TEXT NOT NULL REFERENCES expansion(key),
    source          TEXT NOT NULL,
    name            TEXT NOT NULL,
    source_info     TEXT,

    -- Natural identifiers. Exactly which one is populated depends on the
    -- module; the CHECK below enforces that rather than trusting the emitter.
    mount_id        INTEGER,
    species_id      INTEGER,
    item_id         INTEGER,
    decor_id        INTEGER,
    spell_id        INTEGER,               -- recipes
    achievement_id  INTEGER,
    npc_id          INTEGER,
    object_id       INTEGER,
    quest_id        INTEGER,

    -- Module-specific attributes.
    pet_type        INTEGER,
    skill_line      INTEGER,               -- recipes, crafted decor
    priority        INTEGER,
    zone            TEXT,
    zone_map_id     INTEGER,
    description     TEXT,
    category        TEXT,                  -- achievements
    score           INTEGER,               -- per-item weight override

    -- Attributes the addon renders but that no column previously held. Each
    -- was being dropped at load with only a count to show for it, which is a
    -- catalog quietly losing detail rather than a schema saying "not yet".
    can_battle      INTEGER CHECK (can_battle IN (0, 1)),
    faction         TEXT CHECK (faction IN ('Alliance', 'Horde')),
    renown_faction_id   INTEGER,
    renown_faction_name TEXT,
    renown_level        INTEGER,
    -- Three rows express the requirement as a standing name rather than a
    -- numeric level. Storing only the number would drop them.
    renown_standing     TEXT,
    drop_mob        TEXT,
    drop_rate       TEXT,
    drop_zone       TEXT,
    drop_boss       INTEGER CHECK (drop_boss IN (0, 1)),
    drop_npc_id     INTEGER,
    -- The prose line rendered above an achievement's checklist.
    task_list_intro TEXT,

    unavailable     INTEGER NOT NULL DEFAULT 0 CHECK (unavailable IN (0, 1)),
    -- A map reference, not a collectible: renders and pins, but never enters
    -- completion totals, Collection Score, collected lists or the bitmap.
    navigation_only INTEGER NOT NULL DEFAULT 0 CHECK (navigation_only IN (0, 1)),
    available_after TEXT,

    snapshot_id     INTEGER REFERENCES source_snapshot(id),

    FOREIGN KEY (module, source) REFERENCES source_kind(module, key),
    CHECK (pet_type IS NULL OR pet_type BETWEEN 1 AND 10),
    CHECK (score IS NULL OR score > 0),
    -- Every row needs at least one natural identifier, or nothing downstream
    -- can address it -- which is how navigation treasures ended up with dead
    -- alt-click and Wowhead links.
    CHECK (COALESCE(mount_id, species_id, item_id, decor_id, spell_id,
                    achievement_id, npc_id, object_id, quest_id) IS NOT NULL)
);

CREATE INDEX collectible_module_exp ON collectible (module, expansion);
CREATE INDEX collectible_source     ON collectible (module, source);

-- Natural keys are unique per module. This is what makes a duplicate ID a
-- write failure instead of something a test has to notice later.
CREATE UNIQUE INDEX collectible_mount   ON collectible (mount_id)      WHERE mount_id IS NOT NULL;
CREATE UNIQUE INDEX collectible_species ON collectible (species_id)    WHERE species_id IS NOT NULL;
CREATE UNIQUE INDEX collectible_decor   ON collectible (decor_id)      WHERE decor_id IS NOT NULL;
CREATE UNIQUE INDEX collectible_spell   ON collectible (spell_id)      WHERE spell_id IS NOT NULL;

-- ---------------------------------------------------------------- locations

-- MC.LOC: named places the data files reference by symbol rather than by
-- copying coordinates. Keeping them as a table means a vendor who moves is
-- corrected once, and it preserves the distinction between "these two rows are
-- the same place" and "these two rows happen to share coordinates" -- which is
-- what a coordinate-only key lost, labelling 111 recipes with another source.
CREATE TABLE location (
    key         TEXT NOT NULL,
    ord         INTEGER NOT NULL DEFAULT 0,   -- roamers have several stops
    map_id      INTEGER NOT NULL CHECK (map_id > 0),
    x           REAL NOT NULL CHECK (x > 0 AND x <= 1),
    y           REAL NOT NULL CHECK (y > 0 AND y <= 1),
    label       TEXT NOT NULL CHECK (label <> ''),
    PRIMARY KEY (key, ord)
);

-- ---------------------------------------------------------------- waypoints

-- Normalised rather than inlined: one collectible can have several spawns, and
-- the renderer already understands a list. `ord` keeps them stable.
CREATE TABLE waypoint (
    collectible_id  INTEGER NOT NULL REFERENCES collectible(id) ON DELETE CASCADE,
    -- One collectible legitimately carries several *kinds* of pin: a treasure
    -- inside an instance also has an overworld entrance, and a recipe has both
    -- a vendor pin and a per-faction trainer. Without this they collide on
    -- (id, ord) and one silently overwrites the other.
    role            TEXT NOT NULL DEFAULT 'primary'
                    CHECK (role IN ('primary', 'overworld', 'recipe', 'trainer')),
    ord             INTEGER NOT NULL,
    -- Set when the row referenced MC.LOC.<key> rather than inline coordinates.
    -- The emitter writes the symbol back so the Lua keeps its shared reference.
    location_key    TEXT,
    map_id          INTEGER NOT NULL CHECK (map_id > 0),
    x               REAL NOT NULL CHECK (x > 0 AND x <= 1),
    y               REAL NOT NULL CHECK (y > 0 AND y <= 1),
    label           TEXT NOT NULL CHECK (label <> ''),
    -- '' means "both factions". A NULL here would not deduplicate: SQLite
    -- permits NULLs in a PRIMARY KEY, so two identical rows would both insert.
    faction         TEXT NOT NULL DEFAULT '' CHECK (faction IN ('', 'Alliance', 'Horde')),
    PRIMARY KEY (collectible_id, role, faction, ord)
);

-- ---------------------------------------------------------------- criteria

-- Rares and treasures hang off achievement criteria; the arrays in Lua are
-- positional and index-paired, which is exactly how 23 rows ended up attached
-- to the wrong achievement and how a resize of one array shifted every
-- waypoint after it.
CREATE TABLE criterion (
    collectible_id  INTEGER NOT NULL REFERENCES collectible(id) ON DELETE CASCADE,
    ord             INTEGER NOT NULL,      -- position in the achievement
    tree_id         INTEGER,
    npc_id          INTEGER,
    object_id       INTEGER,
    label           TEXT,
    PRIMARY KEY (collectible_id, ord)
);

-- Achievement checklists.
CREATE TABLE task (
    collectible_id  INTEGER NOT NULL REFERENCES collectible(id) ON DELETE CASCADE,
    ord             INTEGER NOT NULL,
    label           TEXT,
    achievement_id  INTEGER,
    criteria_id     INTEGER,
    criteria_index  INTEGER,
    quest_id        INTEGER,
    -- A checklist step can require an item or a pet, and can carry its own pin
    -- (224 inline tuples plus 27 references to a shared MC.LOC place). None of
    -- these are derivable from the parent row.
    item_id         INTEGER,
    item_count      INTEGER,
    species_id      INTEGER,
    location_key    TEXT,
    map_id          INTEGER CHECK (map_id IS NULL OR map_id > 0),
    x               REAL CHECK (x IS NULL OR (x > 0 AND x <= 1)),
    y               REAL CHECK (y IS NULL OR (y > 0 AND y <= 1)),
    waypoint_label  TEXT,
    PRIMARY KEY (collectible_id, ord)
);

-- Region-keyed release schedules (MC.CONTENT_RELEASE.<key>). One row per
-- region rather than 110 expanded copies of the same table.
CREATE TABLE content_release (
    key         TEXT NOT NULL,
    region_id   INTEGER NOT NULL,
    available_at INTEGER,
    badge       TEXT,
    PRIMARY KEY (key, region_id)
);

CREATE TABLE cost (
    collectible_id  INTEGER NOT NULL REFERENCES collectible(id) ON DELETE CASCADE,
    kind            TEXT NOT NULL,         -- 'currency', 'gold', 'item'
    ord             INTEGER NOT NULL DEFAULT 1,
    currency_id     INTEGER,
    item_id         INTEGER,
    amount          INTEGER NOT NULL CHECK (amount > 0),
    PRIMARY KEY (collectible_id, kind, ord)
);

-- ---------------------------------------------------------------- integrity

-- Queries that replace hand-written validators. Each returns rows only when
-- something is wrong, so a non-empty result IS the failure.

CREATE VIEW bad_source_key AS
SELECT c.module, c.source, COUNT(*) AS rows
FROM collectible c
LEFT JOIN source_kind s ON s.module = c.module AND s.key = c.source
WHERE s.key IS NULL
GROUP BY c.module, c.source;

CREATE VIEW bad_expansion AS
SELECT c.module, c.expansion, COUNT(*) AS rows
FROM collectible c
LEFT JOIN expansion e ON e.key = c.expansion
WHERE e.key IS NULL
GROUP BY c.module, c.expansion;

-- A pin on something that cannot be obtained is a bug, not a shortcut.
CREATE VIEW waypoint_on_unavailable AS
SELECT c.id, c.module, c.name
FROM collectible c JOIN waypoint w ON w.collectible_id = c.id
WHERE c.unavailable = 1;

-- Navigation rows must never carry a score override; they are not collectibles.
CREATE VIEW scored_navigation_row AS
SELECT id, module, name FROM collectible
WHERE navigation_only = 1 AND score IS NOT NULL;

-- A row with no name is legitimate only where the client resolves one at
-- runtime: three BfA toys survive in Blizzard's Toy table while their item
-- records are gone from ItemSparse, so no name is derivable offline and
-- C_ToyBox supplies it in game. Tracked rather than dropped -- silently
-- discarding rows at ingest is how a catalog quietly shrinks.
CREATE VIEW nameless_collectible AS
SELECT id, module, expansion, COALESCE(item_id, mount_id, species_id, decor_id, spell_id) AS natural_id
FROM collectible WHERE name = '';

CREATE VIEW criterion_gap AS
SELECT collectible_id, COUNT(*) AS n, MAX(ord) AS max_ord
FROM criterion GROUP BY collectible_id HAVING COUNT(*) <> MAX(ord) + 1;

-- A waypoint that names a location which does not exist would emit a nil
-- reference into Lua and break the file at load.
CREATE VIEW dangling_location AS
SELECT DISTINCT w.location_key
FROM waypoint w
WHERE w.location_key IS NOT NULL
  AND w.location_key NOT IN (SELECT key FROM location);
