"""Adds a zone to shipped decoration rows that have none, from ATT housing data.

    luajit scripts/extract-att-housing-sources.lua <ATT Housing.lua> > housing.csv
    python scripts/db/backfill-decoration-zones.py housing.csv

Only rows that already lack both `zone` and `waypoint` are touched, and only
where ATT resolves the decor to a map this script has an unambiguous name for.
Anything else is left alone and reported -- a wrong zone is worse than none,
because the list reads as authoritative either way.

Map names come from DB2 UiMap, not from a reverse-derived lookup: build/_mapnames.json
maps 62 to both Darkshore and harandar, and labelling from it would be a guess.
"""
import csv
import io
import os
import re
import sys

# Deliberately partial. 84;85;2339 (a quest offered in all three capitals) has
# no single zone name that is not a guess, so those rows keep no zone at all.
MAP_ZONE = {
    "2352": "Founder's Point",
    "2351": "Razorwind Shores",
    # Available in either neighbourhood: naming one would be wrong for half
    # the players who read it.
    "2351;2352": "Housing Neighborhood",
}

ROOT = "addons/Collectionist/Modules/Decorations/Data"
ENTRY = re.compile(r"\{\s*decorID\s*=\s*(\d+)\b")


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


def insert_zone(entry, zone):
    """After sourceInfo when there is one, else before the closing brace."""
    field = ', zone = "%s"' % zone
    m = None
    for m in re.finditer(r'sourceInfo\s*=\s*"(?:[^"\\]|\\.)*"', entry):
        pass
    if m:
        return entry[:m.end()] + field + entry[m.end():]
    close = entry.rstrip()
    assert close.endswith("}")
    cut = len(close) - 1
    return close[:cut].rstrip().rstrip(",") + field + " }" + entry[len(close):]


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else "build/att-housing.csv"
    zone_by_decor, skipped = {}, {}
    for r in csv.DictReader(io.open(src, encoding="utf-8")):
        maps = (r.get("map_ids") or "").strip()
        if not maps:
            continue
        if maps in MAP_ZONE:
            zone_by_decor[r["decor_id"]] = MAP_ZONE[maps]
        else:
            skipped[maps] = skipped.get(maps, 0) + 1

    total = 0
    for fn in sorted(os.listdir(ROOT)):
        if not fn.endswith(".lua"):
            continue
        path = os.path.join(ROOT, fn)
        text = io.open(path, encoding="utf-8").read()
        out, i, changed = [], 0, 0
        while True:
            m = ENTRY.search(text, i)
            if not m:
                out.append(text[i:])
                break
            start = m.start()
            end = span_of_entry(text, start)
            entry = text[start:end]
            zone = zone_by_decor.get(m.group(1))
            # Never overwrite a curated zone or a waypoint that implies one.
            if zone and "zone =" not in entry and "waypoint" not in entry:
                entry = insert_zone(entry, zone)
                changed += 1
            out.append(text[i:start])
            out.append(entry)
            i = end
        if changed:
            io.open(path, "w", encoding="utf-8", newline="\n").write("".join(out))
            print("  %-24s +%d" % (fn, changed))
            total += changed
    print("zoned %d decoration rows" % total)
    if skipped:
        print("left alone (no unambiguous zone name):")
        for maps, n in sorted(skipped.items(), key=lambda kv: -kv[1]):
            print("   maps %-14s %d" % (maps, n))


if __name__ == "__main__":
    main()
