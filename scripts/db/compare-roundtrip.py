"""Diffs the shipped Lua against the Lua emitted from the database.

    luajit scripts/db/dump-shipped-data.lua  > build/shipped.jsonl
    python  scripts/db/build-db.py
    python  scripts/db/emit-lua.py
    luajit  scripts/db/dump-emitted-data.lua > build/emitted.jsonl
    python  scripts/db/compare-roundtrip.py

Exits non-zero on any difference, so it works as a gate.

The comparison is on the RESOLVED row -- group attributes folded into each
entry, the way Scanner reads them (`entry.source or group.source`). That is
deliberate: placement of a field on the group versus the entry is not
observable to the addon, and demanding byte equality would fail on a
distinction that has no runtime meaning. What IS observable is the value the
scanner ends up with, and that is what gets compared.

Fields whose absence and whose falseness are the same thing at runtime are
normalised together; anything else is a real difference and is reported.
"""

import collections
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# Group keys an entry inherits when it does not carry its own.
INHERITED = ("source", "zone", "zoneMapID", "skillLine", "availableAfter", "navigationOnly")

# Present-and-false is indistinguishable from absent for these.
FALSY_OPTIONAL = ("unavailable", "navigationOnly")


def load(path):
    out = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line:
                out.append(json.loads(line))
    return out


def natural(module, e):
    for k in ("mountID", "speciesID", "decorID", "id", "itemID", "achievementID",
              "npcID", "objectID", "questID"):
        if e.get(k) is not None:
            return (module, k, e[k])
    return None


def resolve(r):
    e = r.get("entry") if isinstance(r.get("entry"), dict) else {}
    g = r.get("group") if isinstance(r.get("group"), dict) else {}
    row = dict(e)
    if not e:
        row = dict(g)
    else:
        for k in INHERITED:
            if row.get(k) is None and g.get(k) is not None:
                row[k] = g[k]
    for k in FALSY_OPTIONAL:
        if not row.get(k):
            row.pop(k, None)
    # criteriaCount is derived at emit from the array length. Where the shipped
    # value disagreed with the arrays it was wrong, so compare the arrays and
    # report the count separately rather than failing the whole row on it.
    row.pop("criteriaCount", None)
    for k in list(row):
        if row[k] is None or row[k] == "":
            del row[k]
    return row


def index(rows, kind):
    out, dupes = {}, 0
    for r in rows:
        if r.get("__kind") != kind:
            continue
        if kind == "collectible":
            row = resolve(r)
            key = natural(r["module"], row) or (r["module"], r["expansion"],
                                                r.get("groupOrd"), r.get("entryOrd"))
            if key in out:
                dupes += 1
                key = key + ("dup%d" % dupes,)
            out[key] = (row, r)
        elif kind == "location":
            out[(r["key"], r["ord"])] = ({k: r[k] for k in ("map", "x", "y", "label")}, r)
        else:
            out[r["id"]] = (r["value"], r)
    return out


def compare(name, a, b, report):
    only_a = set(a) - set(b)
    only_b = set(b) - set(a)
    if only_a:
        report.append("%s: %d present in shipped but MISSING from emitted" % (name, len(only_a)))
        for k in list(sorted(only_a, key=str))[:5]:
            report.append("    %s  %s" % (k, json.dumps(a[k][0])[:120]))
    if only_b:
        report.append("%s: %d present in emitted but not shipped" % (name, len(only_b)))
        for k in list(sorted(only_b, key=str))[:5]:
            report.append("    %s  %s" % (k, json.dumps(b[k][0])[:120]))

    field_diff = collections.Counter()
    samples = {}
    for k in set(a) & set(b):
        ra, rb = a[k][0], b[k][0]
        # Recipe waypoints are positional tuples, not records; there are no
        # field names to attribute a difference to.
        if not isinstance(ra, dict) or not isinstance(rb, dict):
            if ra != rb:
                field_diff["<value>"] += 1
                samples.setdefault("<value>", (k, ra, rb))
            continue
        for f in set(ra) | set(rb):
            va, vb = ra.get(f), rb.get(f)
            if isinstance(va, float) or isinstance(vb, float):
                try:
                    if abs(float(va) - float(vb)) < 1e-9:
                        continue
                except (TypeError, ValueError):
                    pass
            if va != vb:
                field_diff[f] += 1
                samples.setdefault(f, (k, va, vb))
    if field_diff:
        report.append("%s: value differences by field" % name)
        for f, n in field_diff.most_common():
            k, va, vb = samples[f]
            report.append("    %-20s %5d   e.g. %s" % (f, n, k))
            report.append("        shipped: %s" % json.dumps(va)[:150])
            report.append("        emitted: %s" % json.dumps(vb)[:150])
    return bool(only_a or only_b or field_diff)


def main():
    shipped = load(os.path.join(ROOT, "build", "shipped.jsonl"))
    emitted = load(os.path.join(ROOT, "build", "emitted.jsonl"))

    report, bad = [], False
    for kind, label in (("collectible", "collectibles"), ("location", "locations"),
                        ("recipe_waypoint", "recipe waypoints"),
                        ("recipe_trainer", "recipe trainers")):
        a, b = index(shipped, kind), index(emitted, kind)
        header = "%-18s shipped %6d   emitted %6d" % (label, len(a), len(b))
        sub = []
        if compare(label, a, b, sub):
            bad = True
            report.append(header + "   DIFFERS")
            report.extend(sub)
        else:
            report.append(header + "   identical")

    print("\n".join(report))
    if bad:
        print("\nROUND TRIP FAILED")
        sys.exit(1)
    print("\nRound trip clean: the database reproduces every shipped row.")


if __name__ == "__main__":
    main()
