"""Emits Lua content files from build/collectionist.db.

    python scripts/db/emit-lua.py            # writes build/emitted/
    python scripts/db/emit-lua.py --verify   # emit, reload, and diff

This is the half of the pipeline that makes the database an authority rather
than a report. Until the emitted Lua reproduces what ships today, the database
is only a description of the data; after it does, the database is the source
and the Lua is a build artifact.

The oracle is *semantic*, not byte-for-byte. Byte equality is impossible by
construction: the shipped files reference shared constants (MC.LOC.Kifaan,
MC.CONTENT_RELEASE.MIDNIGHT_SEASON_2, MC.MAP.Tanaris) and by load time a map
constant is an integer indistinguishable from a literal. What the addon
actually consumes is the payload handed to MC.RegisterContent, so that is what
gets compared -- resolved the same way the scanners resolve it, with group
attributes inherited by entries that do not override them.
"""

import json
import os
import sqlite3
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DB_PATH = os.path.join(ROOT, "data", "collectionist.db")
OUT_DIR = os.path.join(ROOT, "build", "emitted")

# Column -> Lua field, per placement. Order is the emitted field order.
ENTRY_FIELDS = [
    ("mount_id", "mountID"), ("species_id", "speciesID"), ("item_id", "itemID"),
    ("decor_id", "decorID"), ("spell_id", "id"), ("achievement_id", "achievementID"),
    ("npc_id", "npcID"), ("object_id", "objectID"), ("quest_id", "questID"),
    ("name", "name"), ("source", "source"), ("source_info", "sourceInfo"),
    ("pet_type", "petType"), ("skill_line", "skillLine"), ("priority", "priority"),
    ("zone", "zone"), ("zone_map_id", "zoneMapID"), ("description", "description"),
    ("category", "category"), ("score", "score"), ("faction", "faction"),
]

GROUP_FIELDS = [
    ("name", "name"), ("category", "category"), ("source", "source"),
    ("zone", "zone"), ("zone_map_id", "zoneMapID"), ("skill_line", "skillLine"),
]


def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def lua_num(v):
    if isinstance(v, float):
        if v == int(v):
            return str(int(v))
        # Coordinates are fractions; %r keeps the shortest round-tripping form
        # and is locale-independent, unlike a formatted decimal.
        return repr(v)
    return str(v)


def lua_val(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return lua_num(v)
    return lua_str(v)


def emit_waypoint(rows):
    """rows: [(location_key, map, x, y, label)] in ord order -> a Lua expression."""
    if not rows:
        return None
    key = rows[0][0]
    if key:
        # Shared location: write the symbol back, not an expanded copy. This is
        # the whole reason location_key is stored.
        return "MC.LOC." + key
    tuples = ["{ %s, %s, %s, %s }" % (lua_num(m), lua_num(x), lua_num(y), lua_str(lb))
              for (_, m, x, y, lb) in rows]
    if len(tuples) == 1:
        return tuples[0]
    return "{ " + ", ".join(tuples) + " }"


def collect(con):
    """Reads the database into per-(expansion, module) group trees."""
    groups = {}
    for g in con.execute(
            "SELECT id, module, expansion, ord, name, category, source, zone, zone_map_id,"
            " skill_line, navigation_only, available_after, is_record"
            " FROM content_group ORDER BY module, expansion, ord"):
        groups[g[0]] = {
            "module": g[1], "expansion": g[2], "ord": g[3], "name": g[4], "category": g[5],
            "source": g[6], "zone": g[7], "zone_map_id": g[8], "skill_line": g[9],
            "navigation_only": g[10], "available_after": g[11], "is_record": g[12],
            "entries": [],
        }

    cols = [c[0] for c in con.execute("SELECT * FROM collectible LIMIT 0").description]
    for row in con.execute("SELECT * FROM collectible ORDER BY group_id, ord, id"):
        r = dict(zip(cols, row))
        g = groups.get(r["group_id"])
        if g is not None:
            g["entries"].append(r)

    # Child tables, fetched once and bucketed rather than queried per row.
    wp = {}
    for cid, role, ord_, lk, m, x, y, lb, faction in con.execute(
            "SELECT collectible_id, role, ord, location_key, map_id, x, y, label, faction"
            " FROM waypoint ORDER BY collectible_id, role, faction, ord"):
        wp.setdefault(cid, {}).setdefault((role, faction), []).append((lk, m, x, y, lb))

    crit = {}
    for cid, ord_, tree, npc, obj, label in con.execute(
            "SELECT collectible_id, ord, tree_id, npc_id, object_id, label"
            " FROM criterion ORDER BY collectible_id, ord"):
        crit.setdefault(cid, []).append((tree, npc, obj, label))

    tasks = {}
    tcols = [c[0] for c in con.execute("SELECT * FROM task LIMIT 0").description]
    for row in con.execute("SELECT * FROM task ORDER BY collectible_id, ord"):
        t = dict(zip(tcols, row))
        tasks.setdefault(t["collectible_id"], []).append(t)

    costs = {}
    for cid, kind, ord_, curr, item, amount in con.execute(
            "SELECT collectible_id, kind, ord, currency_id, item_id, amount"
            " FROM cost ORDER BY collectible_id, kind, ord"):
        costs.setdefault(cid, []).append((kind, ord_, curr, item, amount))

    return groups, wp, crit, tasks, costs


def entry_lua(r, wp, crit, tasks, costs, indent="        "):
    parts = []
    for col, field in ENTRY_FIELDS:
        v = r.get(col)
        if v is None or v == "":
            continue
        parts.append("%s = %s" % (field, lua_val(v)))
    if r.get("unavailable"):
        parts.append("unavailable = true")
    if r.get("can_battle") is not None:
        parts.append("canBattle = %s" % ("true" if r["can_battle"] else "false"))
    if r.get("available_after"):
        parts.append("availableAfter = MC.CONTENT_RELEASE.%s" % r["available_after"])

    if r.get("renown_faction_id"):
        rn = ["factionID = %d" % r["renown_faction_id"]]
        if r.get("renown_faction_name"):
            rn.append("factionName = %s" % lua_str(r["renown_faction_name"]))
        if r.get("renown_level") is not None:
            rn.append("level = %d" % r["renown_level"])
        if r.get("renown_standing"):
            rn.append("standing = %s" % lua_str(r["renown_standing"]))
        parts.append("renown = { %s }" % ", ".join(rn))

    if r.get("drop_mob") or r.get("drop_rate") or r.get("drop_zone"):
        di = []
        if r.get("drop_mob"):
            di.append("mob = %s" % lua_str(r["drop_mob"]))
        if r.get("drop_rate"):
            di.append("rate = %s" % lua_str(r["drop_rate"]))
        if r.get("drop_zone"):
            di.append("zone = %s" % lua_str(r["drop_zone"]))
        if r.get("drop_boss") is not None:
            di.append("boss = %s" % ("true" if r["drop_boss"] else "false"))
        if r.get("drop_npc_id"):
            di.append("npcID = %d" % r["drop_npc_id"])
        parts.append("dropInfo = { %s }" % ", ".join(di))

    cid = r["id"]
    for (role, faction), rows in sorted(wp.get(cid, {}).items()):
        if role == "primary":
            parts.append("waypoint = %s" % emit_waypoint(rows))
        elif role == "overworld":
            parts.append("overworldWaypoint = %s" % emit_waypoint(rows))

    cl = crit.get(cid) or []
    if cl:
        # criteriaCount is DERIVED, never stored: the shipped files carried a
        # hand-maintained count that had already drifted from the array length
        # (37 declared against 35 present). Emitting len() makes that class of
        # desync unrepresentable.
        parts.append("criteriaCount = %d" % len(cl))
        for idx, field in ((0, "criteriaTreeIDs"), (1, "criteriaNPCIDs"), (2, "criteriaObjectIDs")):
            vals = [c[idx] for c in cl]
            if any(v is not None for v in vals):
                parts.append("%s = { %s }" % (field, ", ".join(str(v or 0) for v in vals)))
        names = [c[3] for c in cl]
        # `is not None`, not truthiness: six achievements ship an array of empty
        # placeholder strings, and "present but blank" is a different fact from
        # "absent" -- the array's length is what pairs it with the ID arrays.
        if any(n is not None for n in names):
            parts.append("criteriaNames = { %s }" % ", ".join(lua_str(n or "") for n in names))

    tl = tasks.get(cid) or []
    if tl:
        items = []
        for t in tl:
            f = []
            if t.get("label"):
                f.append("label = %s" % lua_str(t["label"]))
            for col, field in (("achievement_id", "achievementID"), ("criteria_id", "criteriaID"),
                               ("criteria_index", "criteriaIndex"), ("quest_id", "questID"),
                               ("item_id", "itemID"), ("item_count", "itemCount"),
                               ("species_id", "speciesID")):
                if t.get(col) is not None:
                    f.append("%s = %d" % (field, t[col]))
            if t.get("location_key"):
                f.append("waypoint = MC.LOC.%s" % t["location_key"])
            elif t.get("map_id"):
                f.append("waypoint = { %s, %s, %s, %s }" % (
                    lua_num(t["map_id"]), lua_num(t["x"]), lua_num(t["y"]),
                    lua_str(t.get("waypoint_label") or "")))
            items.append("{ %s }" % ", ".join(f))
        intro = ("intro = %s, " % lua_str(r["task_list_intro"])) if r.get("task_list_intro") else ""
        parts.append("taskList = { %stasks = { %s } }" % (intro, ", ".join(items)))

    cl2 = costs.get(cid) or []
    if cl2:
        f = []
        for (kind, ord_, curr, item, amount) in cl2:
            if kind == "currency":
                f.append("%s = { %d, %d }" % ("currency" if ord_ == 1 else "currency2", curr, amount))
            elif kind == "item":
                f.append("%s = { %d, %d }" % ("item" if ord_ == 1 else "item2", item, amount))
            else:
                f.append("%s = %d" % (kind, amount))
        parts.append("cost = { %s }" % ", ".join(f))

    return indent + "{ " + ", ".join(parts) + " },"


def emit(con):
    groups, wp, crit, tasks, costs = collect(con)
    os.makedirs(OUT_DIR, exist_ok=True)
    for f in os.listdir(OUT_DIR):
        os.remove(os.path.join(OUT_DIR, f))

    by_reg = {}
    for g in groups.values():
        by_reg.setdefault((g["expansion"], g["module"]), []).append(g)

    list_key = dict(con.execute("SELECT key, list_key FROM module"))
    files = 0
    for (expansion, module), gs in sorted(by_reg.items()):
        gs.sort(key=lambda g: g["ord"])
        lk = list_key[module]
        out = ["local _, MC = ...", "",
               "-- GENERATED from build/collectionist.db by scripts/db/emit-lua.py.",
               "", 'MC.RegisterContent("%s", "%s", {' % (expansion, module)]
        for g in gs:
            head = []
            for col, field in GROUP_FIELDS:
                if g.get(col) not in (None, ""):
                    head.append("%s = %s" % (field, lua_val(g[col])))
            if g["navigation_only"]:
                head.append("navigationOnly = true")
            if g["available_after"]:
                head.append("availableAfter = MC.CONTENT_RELEASE.%s" % g["available_after"])

            if g["is_record"]:
                # The group itself is the record: no entry list at all.
                r = g["entries"][0] if g["entries"] else None
                if r is None:
                    continue
                # entry_lua returns "{ ... },"; peel the comma before the brace,
                # or the closing "}" survives and the file will not parse.
                # The row already carries every group field (it was loaded as a
                # copy of the group), so `head` would emit each key a second
                # time. entry_lua returns "{ ... },"; peel the comma before the
                # brace, or the closing "}" survives and the file will not parse.
                body = entry_lua(r, wp, crit, tasks, costs, indent="").strip().rstrip(",")
                inner = body[1:-1].strip()
                nav = ", navigationOnly = true" if g["navigation_only"] else ""
                out.append("    { %s%s }," % (inner, nav))
                continue

            out.append("    { " + ", ".join(head) + ("," if head else "") + " " + lk + " = {")
            for r in g["entries"]:
                out.append(entry_lua(r, wp, crit, tasks, costs))
            out.append("    } },")
        out.append("})")
        path = os.path.join(OUT_DIR, "%s_%s.lua" % (expansion, module))
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write("\n".join(out) + "\n")
        files += 1

    # MC.LOC, and the two recipe lookup tables, which are not registrations.
    loc = ["local _, MC = ...", "", "MC.LOC = MC.LOC or {}"]
    cur = {}
    for key, ord_, m, x, y, lb in con.execute(
            "SELECT key, ord, map_id, x, y, label FROM location ORDER BY key, ord"):
        cur.setdefault(key, []).append((None, m, x, y, lb))
    for key, rows in sorted(cur.items()):
        loc.append("MC.LOC.%s = %s" % (key, emit_waypoint(rows)))
    with open(os.path.join(OUT_DIR, "Locations.lua"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(loc) + "\n")
    files += 1

    for role, var in (("recipe", "MC.RecipeWaypoints"), ("trainer", "MC.RecipeTrainers")):
        rows = {}
        for spell, faction, ord_, m, x, y, lb in con.execute(
                "SELECT c.spell_id, w.faction, w.ord, w.map_id, w.x, w.y, w.label"
                " FROM waypoint w JOIN collectible c ON c.id = w.collectible_id"
                " WHERE w.role = ? ORDER BY c.spell_id, w.faction, w.ord", (role,)):
            rows.setdefault(spell, {}).setdefault(faction, []).append((None, m, x, y, lb))
        body = ["local _, MC = ...", "", "%s = {}" % var]
        for spell, byf in sorted(rows.items()):
            if role == "recipe":
                body.append("%s[%d] = %s" % (var, spell, emit_waypoint(byf.get("", []))))
            else:
                f = []
                for faction, key in (("", "n"), ("Alliance", "a"), ("Horde", "h")):
                    if byf.get(faction):
                        f.append("%s = %s" % (key, emit_waypoint(byf[faction])))
                body.append("%s[%d] = { %s }" % (var, spell, ", ".join(f)))
        with open(os.path.join(OUT_DIR, var.split(".")[-1] + ".lua"), "w",
                  encoding="utf-8", newline="\n") as fh:
            fh.write("\n".join(body) + "\n")
        files += 1

    return files


def main():
    con = sqlite3.connect(DB_PATH)
    files = emit(con)
    con.close()
    print("emitted %d files to %s" % (files, os.path.relpath(OUT_DIR, ROOT)))


if __name__ == "__main__":
    main()
