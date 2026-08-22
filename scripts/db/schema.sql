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
    -- Pinning. The ATT checkout that resolved 8,975 recipe sources lived in
    -- %TEMP% with no recorded SHA, so the exact input could not be recovered
    -- and no claim derived from it could be re-checked. Hashing the extracted
    -- artifact does not pin the upstream repository, but it does make "which
    -- bytes produced this row" answerable, and a silent upstream change becomes
    -- a hash change rather than an unexplained diff.
    path        TEXT,                      -- repo-relative file the rows came from
    sha256      TEXT,
    row_count   INTEGER,
    UNIQUE (source, version)
);

-- Upstream records, kept as they arrived rather than merged straight into the
-- catalog. Two different things want answering and only this separation
-- answers both: "what does the catalog ship" and "what does the upstream say
-- exists". Previously the second question needed a bespoke script per audit,
-- and each one re-derived the join a little differently.
CREATE TABLE upstream_row (
    id          INTEGER PRIMARY KEY,
    snapshot_id INTEGER NOT NULL REFERENCES source_snapshot(id) ON DELETE CASCADE,
    domain      TEXT NOT NULL,             -- 'mounts', 'recipes', 'achievements', ...
    expansion   TEXT REFERENCES expansion(key),
    id_kind     TEXT NOT NULL,             -- which collectible column this keys to
    natural_id  INTEGER NOT NULL,
    name        TEXT,
    status      TEXT,                      -- the upstream's own classification
    -- The whole record, so a question nobody has asked yet does not require
    -- re-reading the CSV and re-deciding which columns mattered.
    payload     TEXT NOT NULL,
    UNIQUE (snapshot_id, domain, id_kind, natural_id)
);

CREATE INDEX upstream_lookup ON upstream_row (domain, id_kind, natural_id);

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

-- ------------------------------------------------------- upstream vs catalog

-- The join every gap audit re-implemented, written once. Each audit script had
-- its own copy and they did not agree: one keyed decorations on item_id where
-- another used decor_id, and one read a column by its output name so the whole
-- name-preference walk was dead code.
CREATE VIEW upstream_catalog_match AS
SELECT u.id                AS upstream_id,
       s.source            AS upstream_source,
       u.domain,
       u.expansion         AS upstream_expansion,
       u.id_kind,
       u.natural_id,
       u.name              AS upstream_name,
       u.status            AS upstream_status,
       c.id                AS collectible_id,
       c.module            AS catalog_module,
       c.expansion         AS catalog_expansion,
       c.name              AS catalog_name
FROM upstream_row u
JOIN source_snapshot s ON s.id = u.snapshot_id
LEFT JOIN collectible c
       ON (u.id_kind = 'mount_id'       AND c.mount_id       = u.natural_id)
       OR (u.id_kind = 'species_id'     AND c.species_id     = u.natural_id)
       OR (u.id_kind = 'decor_id'       AND c.decor_id       = u.natural_id)
       OR (u.id_kind = 'spell_id'       AND c.spell_id       = u.natural_id)
       OR (u.id_kind = 'item_id'        AND c.item_id        = u.natural_id
           AND c.module = 'toys')
       OR (u.id_kind = 'achievement_id' AND c.achievement_id = u.natural_id
           AND c.module = 'achievements');

-- Upstream knows about it, the catalog does not ship it.
--
-- Grouped by identity, not by row. The per-expansion inventories OVERLAP --
-- 14,048 distinct recipe ids appear across 23,337 inventory rows, because each
-- expansion re-lists what it considers in scope. Counting rows instead of ids
-- would report one missing recipe as three.
--
-- This is a WORK QUEUE, not a defect list. Most entries here are deliberate:
-- store-only collectibles are excluded by standing policy, and never-
-- implemented records exist in DB2 but not in the game. Filter on statuses
-- before treating any count here as a gap.
CREATE VIEW upstream_missing_from_catalog AS
SELECT domain, id_kind, natural_id,
       MIN(upstream_name)                        AS upstream_name,
       GROUP_CONCAT(DISTINCT upstream_status)    AS statuses,
       GROUP_CONCAT(DISTINCT upstream_expansion) AS expansions
FROM upstream_catalog_match
WHERE collectible_id IS NULL
GROUP BY domain, id_kind, natural_id;

-- The catalog ships an id the upstream inventory does not contain. Far more
-- suspicious than the reverse: either the id is wrong, or it belongs to an
-- expansion whose inventory was never extracted.
CREATE VIEW catalog_missing_from_upstream AS
SELECT c.id, c.module, c.expansion, c.name,
       COALESCE(c.mount_id, c.species_id, c.decor_id, c.spell_id) AS natural_id
FROM collectible c
-- Without this guard the view reports the entire catalog as unmatched whenever
-- upstream has not been ingested -- which is the normal state of the committed
-- database, since ingest writes to build/collectionist-full.db.
WHERE EXISTS (SELECT 1 FROM upstream_row)
  AND c.module IN ('mounts', 'pets', 'decorations', 'recipes')
  AND c.navigation_only = 0
  AND NOT EXISTS (
        SELECT 1 FROM upstream_row u
        WHERE (u.id_kind = 'mount_id'   AND u.natural_id = c.mount_id)
           OR (u.id_kind = 'species_id' AND u.natural_id = c.species_id)
           OR (u.id_kind = 'decor_id'   AND u.natural_id = c.decor_id)
           OR (u.id_kind = 'spell_id'   AND u.natural_id = c.spell_id));

-- Same id, different name -- one row per collectible, not per inventory listing.
--
-- Direction is NOT obvious and this view does not assert one. Checked by hand
-- across all 32: every genuinely different name was the SNAPSHOT being stale or
-- internal, never the catalog. Blizzard renamed the MoP yaks for the Remix
-- event, "The Pigskin" became "The Swineskin", and five decoration rows carry
-- a literal "[DNT] [AUTOGEN]" datamine placeholder upstream against a real name
-- in the catalog. Only the punctuation differences ran the other way.
CREATE VIEW upstream_name_mismatch AS
SELECT collectible_id, catalog_module, catalog_expansion, natural_id,
       MIN(upstream_name) AS upstream_name, catalog_name
FROM upstream_catalog_match
WHERE collectible_id IS NOT NULL
  AND COALESCE(upstream_name, '') <> ''
  AND COALESCE(catalog_name, '')  <> ''
GROUP BY collectible_id
HAVING SUM(CASE WHEN upstream_name = catalog_name THEN 1 ELSE 0 END) = 0;

-- Shipped under an expansion that NO inventory listing this id agrees with.
--
-- Expect ~601 Midnight decorations here permanently. Housing decor was
-- datamined during Dragonflight, so the DF inventory lists it, but a
-- decoration belongs to the expansion whose content AWARDS it -- not to the
-- build that first datamined the item. Those rows are correct as shipped.
--
-- The "no inventory agrees" form is the point. Comparing against each listing
-- separately reported 4,221 mismatches where the real figure is a fraction of
-- that: the inventories overlap by design, so any id listed in three of them
-- disagreed with at least two no matter where the catalog placed it.
CREATE VIEW upstream_expansion_mismatch AS
SELECT collectible_id, catalog_module, catalog_name, catalog_expansion,
       GROUP_CONCAT(DISTINCT upstream_expansion) AS upstream_expansions
FROM upstream_catalog_match
WHERE collectible_id IS NOT NULL AND upstream_expansion IS NOT NULL
GROUP BY collectible_id
HAVING SUM(CASE WHEN upstream_expansion = catalog_expansion THEN 1 ELSE 0 END) = 0;
