"""Builds build/collectionist.db from the shipped-data dump.

    luajit scripts/db/dump-shipped-data.lua > build/shipped.jsonl
    python scripts/db/build-db.py

This is the bootstrap. The database is seeded from what ships today so the
emitter can be diffed against the current files byte for byte; only once that
round trip is proven does upstream ingestion (DB2, ATT, HandyNotes) take over
as the authority.

The vocabulary tables (expansion, source_kind) are read out of the addon's own
Lua rather than restated here. Restating them is how the two copies drift, and
drift is what produced an expansion key the addon did not have.
"""

import json
import os
import re
import sqlite3
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ADDON = os.path.join(ROOT, "addons", "Collectionist")
DB_PATH = os.path.join(ROOT, "data", "collectionist.db")
DUMP = os.path.join(ROOT, "build", "shipped.jsonl")
SCHEMA = os.path.join(os.path.dirname(__file__), "schema.sql")

# module -> (list key in Lua, the natural id column that module uses)
MODULES = {
    "mounts":       ("mounts", "mount_id"),
    "pets":         ("pets", "species_id"),
    "toys":         ("toys", "item_id"),
    "decorations":  ("decorations", "decor_id"),
    "recipes":      ("recipes", "spell_id"),
    "rares":        ("rares", "achievement_id"),
    "treasures":    ("treasures", "achievement_id"),
    "achievements": ("achievements", "achievement_id"),
}

# Lua entry field -> collectible column. Anything not listed is carried in the
# module-specific handling below or deliberately dropped.
FIELD_MAP = {
    "mountID": "mount_id", "speciesID": "species_id", "itemID": "item_id",
    "decorID": "decor_id", "id": "spell_id", "achievementID": "achievement_id",
    "npcID": "npc_id", "objectID": "object_id", "questID": "quest_id",
    "name": "name", "source": "source", "sourceInfo": "source_info",
    "petType": "pet_type", "skillLine": "skill_line", "priority": "priority",
    "zone": "zone", "zoneMapID": "zone_map_id", "description": "description", "score": "score",
    "criteriaCount": None,
    "availableAfter": "available_after",
    "faction": "faction",
}


def read_lua_table(path, varname, pattern):
    """Pulls a simple key = value table out of a Lua file by regex.

    Only used for the vocabulary tables, which are flat literals. Content is
    never parsed this way -- it is loaded with LuaJIT instead.
    """
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    m = re.search(varname + r"\s*=\s*\{(.*?)\n\}", text, re.S)
    if not m:
        return []
    return re.findall(pattern, m.group(1))


def load_expansions(con):
    path = os.path.join(ADDON, "Data", "Expansions.lua")
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    rows = re.findall(r'\{\s*key\s*=\s*"(\w+)",\s*label\s*=\s*"([^"]+)",\s*order\s*=\s*(\d+)', text)
    con.executemany("INSERT INTO expansion (key, label, ord) VALUES (?, ?, ?)",
                    [(k, l, int(o)) for k, l, o in rows])
    return len(rows)


def load_modules(con):
    con.executemany("INSERT INTO module (key, list_key, id_column) VALUES (?, ?, ?)",
                    [(k, v[0], v[1]) for k, v in MODULES.items()])


SOURCE_TABLES = [
    ("mounts",       "Modules/Mounts/Data/Mounts.lua",             "MC.MountSourceLabels",       "MC.MountSourceOrder"),
    ("pets",         "Modules/Pets/Data/Pets.lua",                 "MC.PetSourceLabels",         "MC.PetSourceOrder"),
    ("toys",         "Modules/Toys/Data/Toys.lua",                 "MC.ToySourceLabels",         "MC.ToySourceOrder"),
    ("decorations",  "Modules/Decorations/Data/Decorations.lua",   "MC.DecoSourceLabels",        "MC.DecoSourceOrder"),
    ("rares",        "Modules/Rares/Data/Rares.lua",               "MC.RareSourceLabels",        "MC.RareSourceOrder"),
    ("treasures",    "Modules/Treasures/Data/Treasures.lua",       "MC.TreasureSourceLabels",    "MC.TreasureSourceOrder"),
    ("achievements", "Modules/Achievements/Data/Achievements.lua", "MC.AchievementSourceLabels", None),
    ("recipes",      "Modules/Recipes/UI.lua",                     "MC.RecipeSourceLabels",      None),
]


def load_source_kinds(con, observed):
    """Vocabulary from the addon's own label tables, plus any key the data uses.

    A key present in the data but missing from the label table is exactly the
    defect that rendered 101 navigation zones as raw lowercase, so it is
    reported rather than silently accepted -- but still inserted, so the
    bootstrap can reproduce today's output before anything is corrected.
    """
    inserted, undeclared = 0, []
    for module, rel, labels_var, order_var in SOURCE_TABLES:
        path = os.path.join(ADDON, *rel.split("/"))
        if not os.path.exists(path):
            continue
        labels = dict(read_lua_table(path, re.escape(labels_var), r'(\w+)\s*=\s*"([^"]*)"'))
        order = []
        if order_var:
            with open(path, encoding="utf-8") as fh:
                text = fh.read()
            m = re.search(re.escape(order_var) + r"\s*=\s*\{(.*?)\n\}", text, re.S)
            if m:
                order = re.findall(r'"(\w+)"', m.group(1))
        for key, label in labels.items():
            ord_ = order.index(key) if key in order else None
            con.execute("INSERT OR IGNORE INTO source_kind (module, key, label, ord) VALUES (?,?,?,?)",
                        (module, key, label, ord_))
            inserted += 1
    # Backfill anything the data uses that no label table declares.
    for module, key in sorted(observed):
        row = con.execute("SELECT 1 FROM source_kind WHERE module=? AND key=?", (module, key)).fetchone()
        if not row:
            undeclared.append((module, key))
            con.execute("INSERT INTO source_kind (module, key, label, ord) VALUES (?,?,?,NULL)",
                        (module, key, key))
    return inserted, undeclared


def norm_waypoints(wp):
    """Lua waypoints are either one {map,x,y,label} tuple or a list of them."""
    if not isinstance(wp, (list, dict)):
        return []
    if isinstance(wp, dict):
        wp = [wp.get(str(i)) for i in range(1, len(wp) + 1)]
    if wp and isinstance(wp[0], list):
        return [t for t in wp if isinstance(t, list)]
    return [wp]


def main():
    if not os.path.exists(DUMP):
        sys.exit("missing %s - run dump-shipped-data.lua first" % DUMP)
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    con = sqlite3.connect(DB_PATH)
    con.executescript(open(SCHEMA, encoding="utf-8").read())

    n_exp = load_expansions(con)
    load_modules(con)

    # An empty Lua table is indistinguishable from an empty array, so a row with
    # no fields arrives as [] rather than {}. Normalise before anything reads it.
    rows = []
    for line in open(DUMP, encoding="utf-8"):
        r = json.loads(line)
        if not isinstance(r.get("entry"), dict):
            r["entry"] = {}
        if not isinstance(r.get("group"), dict):
            r["group"] = {}
        rows.append(r)

    locations = [r for r in rows if r.get("__kind") == "location"]
    lookups = [r for r in rows if r.get("__kind") in ("recipe_waypoint", "recipe_trainer")]
    rows = [r for r in rows if r.get("__kind") == "collectible"]

    con.executemany("INSERT OR REPLACE INTO location (key, ord, map_id, x, y, label) VALUES (?,?,?,?,?,?)",
                    [(l["key"], l["ord"], l["map"], l["x"], l["y"], l.get("label") or l["key"])
                     for l in locations])

    observed = {(r["module"], (r["entry"].get("source") or r["group"].get("source") or "_unsorted"))
                for r in rows if r["entry"] or r["group"].get("source")}
    n_src, undeclared = load_source_kinds(con, observed)

    snap = con.execute(
        "INSERT INTO source_snapshot (source, version, note) VALUES ('shipped-lua', ?, ?)",
        ("bootstrap", "seeded from the committed Lua, pre-upstream-ingestion")).lastrowid

    # Groups first, so every collectible can point at the one it shipped in.
    group_ids = {}
    for r in rows:
        key = (r["module"], r["expansion"], r.get("groupOrd", 0))
        if key in group_ids:
            continue
        g = r["group"]
        av = g.get("availableAfter")
        cur = con.execute(
            "INSERT INTO content_group (module, expansion, ord, name, category, source,"
            " zone, zone_map_id, skill_line, navigation_only, available_after, is_record)"
            " VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
            (key[0], key[1], key[2], g.get("name"), g.get("category"), g.get("source"),
             g.get("zone"), g.get("zoneMapID"), g.get("skillLine"),
             1 if g.get("navigationOnly") else 0,
             av["__symbol"].rsplit(".", 1)[-1] if isinstance(av, dict) and "__symbol" in av else av,
             1 if (not r["entry"] and g.get("achievementID")) else 0))
        group_ids[key] = cur.lastrowid

    inserted = skipped = 0
    import collections
    nonscalar = collections.Counter()
    for r in rows:
        entry, group, module = r["entry"], r["group"], r["module"]
        if not entry:
            # Rares and treasures declare the achievement AT GROUP LEVEL with no
            # entry list -- the group is the record. Skipping these dropped 104
            # achievement-backed rows and every one of their criteria.
            if not group.get("achievementID"):
                continue
            entry = dict(group)
        col = {"module": module, "expansion": r["expansion"], "snapshot_id": snap,
               "group_id": group_ids.get((module, r["expansion"], r.get("groupOrd", 0))),
               "ord": r.get("entryOrd", 0)}
        # Nested records the addon renders. Flattened rather than given a table
        # each: every one is a fixed set of fields on a single row.
        if entry.get("canBattle") is not None:
            col["can_battle"] = 1 if entry["canBattle"] else 0
        rn = entry.get("renown")
        if isinstance(rn, dict):
            col["renown_faction_id"] = rn.get("factionID")
            col["renown_faction_name"] = rn.get("factionName")
            col["renown_level"] = rn.get("level")
            col["renown_standing"] = rn.get("standing")
        di = entry.get("dropInfo")
        if isinstance(di, dict):
            col["drop_mob"] = di.get("mob")
            col["drop_rate"] = di.get("rate")
            col["drop_zone"] = di.get("zone")
            if di.get("boss") is not None:
                col["drop_boss"] = 1 if di["boss"] else 0
            col["drop_npc_id"] = di.get("npcID")
        for lua_key, db_col in FIELD_MAP.items():
            if db_col is None:
                continue  # derived at emit, never stored
            if lua_key in entry:
                col[db_col] = entry[lua_key]
        # Group attributes fill in what the entry omits.
        for key, db_col in (("source", "source"), ("zone", "zone"),
                            ("skillLine", "skill_line"), ("availableAfter", "available_after")):
            col.setdefault(db_col, group.get(key))
        col["source"] = col.get("source") or "_unsorted"
        col["navigation_only"] = 1 if group.get("navigationOnly") else 0
        col["unavailable"] = 1 if entry.get("unavailable") else 0
        # Empty names are kept, not skipped. See the nameless_collectible
        # view: a handful of rows have no offline-derivable name and the
        # client fills them in. Dropping them here would shrink the catalog
        # for a reason nobody could later reconstruct.
        col.setdefault("name", entry.get("name") or "")

        # Anything that is not a scalar needs its own table, not a column.
        # Collect rather than crash so one pass reports every such field.
        for k, v in list(col.items()):
            if isinstance(v, dict) and "__symbol" in v:
                # A reference to a shared constant. Store the key; the emitter
                # writes the symbol back rather than an expanded copy.
                if k == "available_after":
                    col[k] = v["__symbol"].rsplit(".", 1)[-1]
                    continue
                del col[k]
                continue
            if isinstance(v, (dict, list)):
                nonscalar[k] += 1
                del col[k]

        cols = [k for k, v in col.items() if v is not None]
        try:
            cur = con.execute(
                "INSERT INTO collectible (%s) VALUES (%s)" % (",".join(cols), ",".join("?" * len(cols))),
                [col[k] for k in cols])
        except sqlite3.IntegrityError as e:
            skipped += 1
            if skipped <= 8:
                print("  skip %s id=%s %s: %s" % (module, col.get(MODULES[module][1]), col.get("name"), e))
            continue
        cid = cur.lastrowid
        inserted += 1

        def add_waypoints(wp, role):
            if isinstance(wp, dict) and "__symbol" in wp:
                # waypoint = MC.LOC.<key>: expand from the location table so the
                # coordinates are queryable, but remember the key so the emitter
                # writes the symbol rather than inlining a copy.
                key = wp["__symbol"].rsplit(".", 1)[-1]
                for (o, m, x, y, lb) in con.execute(
                        "SELECT ord, map_id, x, y, label FROM location WHERE key=? ORDER BY ord", (key,)):
                    con.execute("INSERT INTO waypoint (collectible_id, role, ord, location_key, map_id, x, y, label)"
                                " VALUES (?,?,?,?,?,?,?,?)", (cid, role, o, key, m, x, y, lb))
                return
            for i, t in enumerate(norm_waypoints(wp)):
                if not (isinstance(t, list) and len(t) >= 3):
                    continue
                try:
                    con.execute("INSERT INTO waypoint (collectible_id, role, ord, map_id, x, y, label)"
                                " VALUES (?,?,?,?,?,?,?)",
                                (cid, role, i, t[0], t[1], t[2],
                                 (t[3] if len(t) > 3 else col["name"]) or col["name"]))
                except sqlite3.IntegrityError:
                    pass

        add_waypoints(entry.get("waypoint"), "primary")
        # A pin outside the instance for something that lives inside one. Same
        # shape, different meaning -- it must not overwrite the primary.
        add_waypoints(entry.get("overworldWaypoint"), "overworld")

        # Four shapes, not one: { currency = {id, n} }, a second { currency2 = ... }
        # for dual-currency vendors, { item = {id, n} }, and a bare { gold = n }.
        # Handling only the first two dropped 69 of 711 costs.
        for kind, val in (entry.get("cost") or {}).items():
            if isinstance(val, list) and len(val) >= 2:
                is_item = kind.startswith("item")
                con.execute(
                    "INSERT OR IGNORE INTO cost (collectible_id, kind, ord, currency_id, item_id, amount)"
                    " VALUES (?,?,?,?,?,?)",
                    (cid, "item" if is_item else "currency",
                     2 if kind.endswith("2") else 1,
                     None if is_item else val[0], val[0] if is_item else None, val[1]))
            elif isinstance(val, int) and val > 0:
                con.execute("INSERT OR IGNORE INTO cost (collectible_id, kind, amount) VALUES (?,?,?)",
                            (cid, kind, val))

        trees = entry.get("criteriaTreeIDs") or []
        npcs = entry.get("criteriaNPCIDs") or []
        objs = entry.get("criteriaObjectIDs") or []
        names = entry.get("criteriaNames") or []
        for i in range(max(len(trees), len(npcs), len(objs), len(names))):
            def at(arr, want=int):
                v = arr[i] if i < len(arr) else None
                return v if isinstance(v, want) else None
            con.execute("INSERT INTO criterion (collectible_id, ord, tree_id, npc_id, object_id, label)"
                        " VALUES (?,?,?,?,?,?)",
                        (cid, i, at(trees), at(npcs), at(objs), at(names, str)))

        tl = entry.get("taskList") or {}
        if tl.get("intro"):
            con.execute("UPDATE collectible SET task_list_intro=? WHERE id=?", (tl["intro"], cid))
        for i, t in enumerate(tl.get("tasks") or []):
            if not isinstance(t, dict):
                continue
            tw = t.get("waypoint")
            lk = mp = tx = ty = tlb = None
            if isinstance(tw, dict) and "__symbol" in tw:
                lk = tw["__symbol"].rsplit(".", 1)[-1]
                got = con.execute("SELECT map_id, x, y, label FROM location WHERE key=? ORDER BY ord",
                                  (lk,)).fetchone()
                if got:
                    mp, tx, ty, tlb = got
            elif isinstance(tw, list) and len(tw) >= 3:
                mp, tx, ty = tw[0], tw[1], tw[2]
                tlb = tw[3] if len(tw) > 3 else None
            con.execute("INSERT INTO task (collectible_id, ord, label, achievement_id, criteria_id,"
                        " criteria_index, quest_id, item_id, item_count, species_id,"
                        " location_key, map_id, x, y, waypoint_label)"
                        " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                        (cid, i, t.get("label"), t.get("achievementID"), t.get("criteriaID"),
                         t.get("criteriaIndex"), t.get("questID"), t.get("itemID"),
                         t.get("itemCount"), t.get("speciesID"), lk, mp, tx, ty, tlb))

    # Recipe pins live in runtime lookup tables keyed by spell id, not as fields
    # on a row. Attach them to the collectible they belong to; the faction
    # column carries the Alliance/Horde split that trainer pairing produces.
    spell_to_id = dict(con.execute(
        "SELECT spell_id, id FROM collectible WHERE spell_id IS NOT NULL"))
    attached = orphaned = 0
    for r in lookups:
        cid = spell_to_id.get(r["id"])
        if cid is None:
            orphaned += 1
            continue
        val = r["value"]
        role = "recipe" if r["__kind"] == "recipe_waypoint" else "trainer"
        pins = []
        if r["__kind"] == "recipe_waypoint":
            tuples = val if (isinstance(val, list) and val and isinstance(val[0], list)) else [val]
            pins = [("", t) for t in tuples if isinstance(t, list) and len(t) >= 3]
        else:
            for key, faction in (("n", ""), ("a", "Alliance"), ("h", "Horde")):
                t2 = val.get(key) if isinstance(val, dict) else None
                if isinstance(t2, list) and len(t2) >= 3:
                    pins.append((faction, t2))
        for faction, t2 in pins:
            ord_ = con.execute(
                "SELECT COALESCE(MAX(ord) + 1, 0) FROM waypoint"
                " WHERE collectible_id=? AND role=? AND faction=?",
                (cid, role, faction)).fetchone()[0]
            try:
                con.execute("INSERT INTO waypoint (collectible_id, role, ord, faction, map_id, x, y, label)"
                            " VALUES (?,?,?,?,?,?,?,?)",
                            (cid, role, ord_, faction, t2[0], t2[1], t2[2],
                             t2[3] if len(t2) > 3 else "?"))
                attached += 1
            except sqlite3.IntegrityError:
                pass
    print("recipe pins attached %d   orphaned %d" % (attached, orphaned))

    con.commit()

    if nonscalar:
        print("non-scalar fields dropped (each needs its own table):")
        for k, v in nonscalar.most_common():
            print("   %-16s %d" % (k, v))
        print()
    print("expansions %d   source kinds %d   locations %d   collectibles %d   skipped %d"
          % (n_exp, n_src, len(locations), inserted, skipped))
    if undeclared:
        print("\nsource keys used by data but declared in no label table (%d):" % len(undeclared))
        for m, k in undeclared[:12]:
            print("   %-13s %s" % (m, k))
    print()
    for view in ("bad_source_key", "bad_expansion", "waypoint_on_unavailable",
                 "scored_navigation_row", "criterion_gap", "nameless_collectible",
                 "dangling_location"):
        n = con.execute("SELECT COUNT(*) FROM %s" % view).fetchone()[0]
        flag = "clean" if n == 0 else ("%d tracked" % n if view == "nameless_collectible" else "%d VIOLATIONS" % n)
        print("   %-24s %s" % (view, flag))
    con.close()


if __name__ == "__main__":
    main()
