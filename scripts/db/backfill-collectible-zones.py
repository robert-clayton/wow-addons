"""Adds a zone to shipped mount/pet/toy/decoration rows that have none.

    # fetch ATT's compiled categories into build/att/, then:
    for k in mnt p toy de; do
        luajit scripts/extract-att-sources.lua $k build/att/*.lua > build/att-$k.csv
    done
    curl -sL https://wago.tools/db2/UiMap/csv -o build/uimap.csv
    curl -sL https://wago.tools/db2/Mount/csv -o build/mount.csv
    python scripts/db/backfill-collectible-zones.py

Safe to re-run: it only ever fills a row that has neither `zone` nor a
waypoint, and never rewrites one that does. The generated per-expansion files
were frozen (the Lua is the source of truth and no script re-emits it), so
editing them in place is not the drift trap it would have been before.

Four deliberate refusals, because a wrong zone is worse than a blank one --
the column reads as authoritative either way:

  * Rows ATT places on more than one map keep no zone. Wild pets spawn across
    several zones and `zone` is a single string; picking the first would be
    arbitrary. These want a waypoint list, which is a separate job.
  * Rows whose own sourceInfo already enumerates places keep no zone, even
    when ATT offers exactly one map -- see names_several_places().
  * Continent maps (UiMap Type 2) are skipped. "Kalimdor" as a location tells
    a player nothing they cannot already read off the source column.
  * Anything whose map id UiMap does not name is skipped rather than guessed.

Mount ids need a bridge: ATT keys mounts by their summoning spell, the catalog
by C_MountJournal id. DB2 Mount.SourceSpellID joins them.
"""
import csv
import io
import os
import re
import sys

# UiMap.Type: 2 Continent, 3 Zone, 4 Dungeon, 5 Micro, 6 Orphan.
USEFUL_MAP_TYPES = {"3", "4", "5", "6"}

MODULES = {
    "mounts":      ("mnt", "mountID",  "Mounts"),
    "pets":        ("p",   "speciesID", "Pets"),
    "toys":        ("toy", "itemID",   "Toys"),
    "decorations": ("de",  "decorID",  "Decorations"),
}

ROOT = "addons/Collectionist/Modules/%s/Data"


def span_of_entry(text, start):
    """start indexes the entry's opening brace; returns just past its match."""
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


def insert_zone(entry, zone):
    """After sourceInfo when there is one, else before the closing brace."""
    field = ', zone = "%s"' % zone.replace('"', "'")
    last = None
    for last in re.finditer(r'sourceInfo\s*=\s*"(?:[^"\\]|\\.)*"', entry):
        pass
    if last:
        return entry[:last.end()] + field + entry[last.end():]
    close = entry.rstrip()
    cut = len(close) - 1
    return close[:cut].rstrip().rstrip(",") + field + " }" + entry[len(close):]


def load_uimap(path="build/uimap.csv"):
    out = {}
    for r in csv.DictReader(io.open(path, encoding="utf-8-sig")):
        out[r["ID"]] = (r["Name_lang"].strip(), r["Type"].strip())
    return out


def load_spell_to_mount(path="build/mount.csv"):
    out = {}
    for r in csv.DictReader(io.open(path, encoding="utf-8-sig")):
        s = (r.get("SourceSpellID") or "").strip()
        if s.isdigit() and s != "0":
            out[s] = r["ID"]
    return out


def zones_for(module, uimap, spell2mount):
    """catalog id -> zone name, for ids ATT places on exactly one usable map."""
    kind = MODULES[module][0]
    maps = {}
    with io.open("build/att-%s.csv" % kind, encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            key = spell2mount.get(r["id"]) if module == "mounts" else r["id"]
            if not key:
                continue
            m = r["map_id"].strip()
            if not m or m == "0":
                continue
            maps.setdefault(key, set()).add(m)

    stats = {"multi": 0, "unnamed": 0, "continent": 0}
    out = {}
    for key, ms in maps.items():
        if len(ms) > 1:
            stats["multi"] += 1
            continue
        m = next(iter(ms))
        entry = uimap.get(m)
        if not entry or not entry[0]:
            stats["unnamed"] += 1
            continue
        name, kind_id = entry
        if kind_id not in USEFUL_MAP_TYPES:
            stats["continent"] += 1
            continue
        out[key] = name
    return out, stats


# A row whose own sourceInfo enumerates places already knows more than ATT
# does. Wild pets are the clear case: ATT lists one map for Rabbit, while the
# catalog's own prose names fifteen zones it spawns in, so taking ATT's single
# map would have written "Elwynn Forest" onto a pet found across the world and
# contradicted the line right next to it.
def names_several_places(entry):
    last = None
    for last in re.finditer(r'sourceInfo\s*=\s*"((?:[^"\\]|\\.)*)"', entry):
        pass
    return bool(last) and last.group(1).count(",") >= 2


def apply(module, zone_by_id, skipped_prose):
    id_field = MODULES[module][1]
    root = ROOT % MODULES[module][2]
    entry_re = re.compile(r"\{\s*%s\s*=\s*(\d+)\b" % id_field)
    total = 0
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
            zone = zone_by_id.get(m.group(1))
            if (zone and "zone =" not in entry and "waypoint" not in entry
                    and not names_several_places(entry)):
                entry = insert_zone(entry, zone)
                changed += 1
            elif zone and names_several_places(entry):
                skipped_prose[0] += 1
            out.append(text[i:start])
            out.append(entry)
            i = end
        if changed:
            io.open(path, "w", encoding="utf-8", newline="\n").write("".join(out))
            print("    %-26s +%d" % (fn, changed))
            total += changed
    return total


def main():
    uimap = load_uimap()
    spell2mount = load_spell_to_mount()
    grand = 0
    for module in ("mounts", "pets", "toys", "decorations"):
        zone_by_id, stats = zones_for(module, uimap, spell2mount)
        print("%s: %d ids resolve to one named zone" % (module, len(zone_by_id)))
        skipped_prose = [0]
        n = apply(module, zone_by_id, skipped_prose)
        grand += n
        print("  zoned %d rows   (left alone: %d on several maps, %d continent-only,"
              " %d unnamed map, %d already name several places)"
              % (n, stats["multi"], stats["continent"], stats["unnamed"],
                 skipped_prose[0]))
    print("\ntotal rows given a zone: %d" % grand)


if __name__ == "__main__":
    main()
