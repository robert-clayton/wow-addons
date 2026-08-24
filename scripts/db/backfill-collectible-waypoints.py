"""Adds map pins to shipped mount/pet/toy/decoration rows that have none.

Run after backfill-collectible-zones.py, which shares its inputs:

    python scripts/db/backfill-collectible-waypoints.py

Safe to re-run: a row that already carries a waypoint is never rewritten.

Shape follows Data/Locations.lua -- one spot is `{ map, x, y, "label" }`, and
several become a list of those, which Core already renders as "N possible
locations". Map ids are raw integers rather than MC.MAP.* constants: most of
these maps have no constant, and Data/Locations.lua already sanctions the raw
form for exactly that case.

About the label. Every existing waypoint names the NPC you walk to ("Kuri
(Har'kuai)"), and that is the better string -- but it is not obtainable here.
ATT's compiled categories strip names and read them from the client at
runtime, its LocalizationDB holds UI strings rather than creature names, and
the DB2 Creature export resolves 215 of the 3,251 NPC parents these rows point
at. So the label is the collectible's own name. On a map pin or a TomTom arrow
"Snowy Owl" reads correctly as what you are walking to, which is the job the
string has to do; it just is not the source's name. If NPC names become
available, relabelling is a re-run.

Coordinates are ATT's 0-100 pairs converted to the 0-1 fractions the addon
uses, at 4dp. Map id 0 is dropped: MC.AddWaypoint rejects it, and a pin that
silently does nothing is worse than no pin.
"""
import csv
import io
import os
import re

# Beyond this many spots the list stops being navigation and starts being a
# statement that the thing drops everywhere. Exactly one row is affected.
MAX_SPOTS = 6

# UiMap.Type: 3 Zone, 4 Dungeon, 5 Micro, 6 Orphan. Continent (2) is not
# somewhere you can walk to.
USEFUL_MAP_TYPES = {"3", "4", "5", "6"}

MODULES = {
    "mounts":      ("mnt", "mountID",   "Mounts"),
    "pets":        ("p",   "speciesID", "Pets"),
    "toys":        ("toy", "itemID",    "Toys"),
    "decorations": ("de",  "decorID",   "Decorations"),
}

ROOT = "addons/Collectionist/Modules/%s/Data"
STRING = r'"(?:[^"\\]|\\.)*"'


def span_of_entry(text, start):
    depth, i, n = 0, start, len(text)
    while i < n:
        c = text[i]
        if c == '"':
            i += 1
            while i < n and text[i] != '"':
                i += 2 if text[i] == "\\" else 1
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise ValueError("unbalanced braces from offset %d" % start)


def name_of(entry):
    m = re.search(r'\bname\s*=\s*(%s)' % STRING, entry)
    return m.group(1) if m else None


def format_spot(map_id, x, y, name):
    return '{ %s, %.4f, %.4f, %s }' % (map_id, x, y, name)


def insert_waypoint(entry, spots, name):
    if len(spots) == 1:
        m, x, y = spots[0]
        field = ", waypoint = " + format_spot(m, x, y, name)
    else:
        inner = ", ".join(format_spot(m, x, y, name) for m, x, y in spots)
        field = ", waypoint = { " + inner + " }"
    close = entry.rstrip()
    cut = len(close) - 1
    return close[:cut].rstrip().rstrip(",") + field + " }" + entry[len(close):]


def load_uimap(path="build/uimap.csv"):
    return {r["ID"]: (r["Name_lang"].strip(), r["Type"].strip())
            for r in csv.DictReader(io.open(path, encoding="utf-8-sig"))}


def load_spell_to_mount(path="build/mount.csv"):
    out = {}
    for r in csv.DictReader(io.open(path, encoding="utf-8-sig")):
        s = (r.get("SourceSpellID") or "").strip()
        if s.isdigit() and s != "0":
            out[s] = r["ID"]
    return out


def spots_for(module, uimap, spell2mount):
    """catalog id -> [(map_id, x, y)], deduped and ordered deterministically."""
    kind = MODULES[module][0]
    found, capped = {}, 0
    with io.open("build/att-%s.csv" % kind, encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            key = spell2mount.get(r["id"]) if module == "mounts" else r["id"]
            if not key:
                continue
            m, x, y = (r["map_id"].strip(), r["coord_x"].strip(),
                       r["coord_y"].strip())
            if not (m and m != "0" and x and y):
                continue
            if uimap.get(m, ("", ""))[1] not in USEFUL_MAP_TYPES:
                continue
            try:
                fx, fy = float(x) / 100.0, float(y) / 100.0
            except ValueError:
                continue
            if not (0.0 < fx < 1.0 and 0.0 < fy < 1.0):
                continue
            found.setdefault(key, set()).add((m, round(fx, 4), round(fy, 4)))

    out = {}
    for key, spots in found.items():
        ordered = sorted(spots, key=lambda s: (int(s[0]), s[1], s[2]))
        if len(ordered) > MAX_SPOTS:
            capped += 1
            ordered = ordered[:MAX_SPOTS]
        out[key] = ordered
    return out, capped


def apply(module, spots_by_id):
    id_field = MODULES[module][1]
    root = ROOT % MODULES[module][2]
    entry_re = re.compile(r"\{\s*%s\s*=\s*(\d+)\b" % id_field)
    total, unnamed = 0, 0
    for fn in sorted(os.listdir(root)):
        if not fn.endswith(".lua"):
            continue
        path = os.path.join(root, fn)
        text = io.open(path, encoding="utf-8").read()
        out, i, changed = [], 0, 0
        while True:
            m = entry_re.search(text, i)
            if not m:
                out.append(text[i:])
                break
            start, end = m.start(), span_of_entry(text, m.start())
            entry = text[start:end]
            spots = spots_by_id.get(m.group(1))
            if spots and "waypoint" not in entry:
                label = name_of(entry)
                if label:
                    entry = insert_waypoint(entry, spots, label)
                    changed += 1
                else:
                    unnamed += 1
            out.append(text[i:start])
            out.append(entry)
            i = end
        if changed:
            io.open(path, "w", encoding="utf-8", newline="\n").write("".join(out))
            print("    %-26s +%d" % (fn, changed))
            total += changed
    return total, unnamed


def main():
    uimap = load_uimap()
    spell2mount = load_spell_to_mount()
    grand = 0
    for module in ("mounts", "pets", "toys", "decorations"):
        spots, capped = spots_for(module, uimap, spell2mount)
        n, unnamed = apply(module, spots)
        grand += n
        print("%s: pinned %d rows   (%d capped at %d spots, %d had no name to"
              " label with)" % (module, n, capped, MAX_SPOTS, unnamed))
    print("\ntotal rows given a map pin: %d" % grand)


if __name__ == "__main__":
    main()
