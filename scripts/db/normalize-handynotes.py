"""Normalises the raw HandyNotes dump into one row per real-world thing.

    luajit scripts/db/dump-handynotes.lua "<AddOns>" > build/handynotes.jsonl
    python scripts/db/normalize-handynotes.py

Writes research/collectionist/sources/handynotes-nodes.csv.

Why a committed CSV sits between the dump and the database: every other
upstream in this pipeline is a file in the repo, but HandyNotes is read out of
the player's WoW install, so an ingest straight from the dump would depend on
which addons happen to be installed and at which version. Writing the
normalised extract into research/ makes the result reproducible from a
checkout, exactly as the ATT extraction already is, and lets source_snapshot
hash something that will still exist tomorrow.

The normalisation itself is the point. Twenty addons from two publisher
families cover the same world, and 3,057 of 5,126 distinct quest ids are
described by more than one of them. Importing rows as they arrive would count
most of the set twice.

Identity, in priority order:

  npc id     A rare is the same rare wherever it is listed.
  quest id   For treasures and one-time pickups this is the completion flag --
             the same signal Collectionist stores as questID, and the reason
             the identity contract was widened to accept it.

Coordinates deliberately do NOT participate in identity. The two families place
the same node about one percent apart (quest 79550 sits at 55.26/43.93 for one
and 54.53/42.41 for the other), so keying on position would split every shared
node in two. Each variant is kept in the output instead, so a later decision
about which publisher to trust is still possible.
"""

import collections
import csv
import re
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DUMP = os.path.join(ROOT, "build", "handynotes.jsonl")
OUT = os.path.join(ROOT, "research", "collectionist", "sources", "handynotes-nodes.csv")

# Class names that mean "this is a rare mob" rather than a container or a pin.
RARE_HINTS = ("rare", "elite", "bigmob")

# label = "{quest:75317}" -- the only place 121 skyriding races name theirs.
QUEST_IN_LABEL = re.compile(r"\{quest:(\d+)\}")


def ints(v):
    """quest/loot/id arrive as a scalar, a list, or a nested table."""
    out = []
    if isinstance(v, bool):
        return out
    if isinstance(v, int):
        return [v]
    if isinstance(v, list):
        for x in v:
            out.extend(ints(x))
    elif isinstance(v, dict):
        for k in sorted(v):
            if not str(k).startswith("__"):
                out.extend(ints(v[k]))
    return out


def rewards_of(node):
    """Flattens the reward tree into (kind, id) pairs."""
    out = []
    for r in (node.get("rewards") or []):
        if not isinstance(r, dict):
            continue
        cls = str(r.get("__class") or "")
        kind = cls.rsplit(".", 1)[-1].lower()
        for key in ("id", "item"):
            v = r.get(key)
            if isinstance(v, int) and v > 0:
                out.append((kind, key, v))
    return out


def main():
    if not os.path.exists(DUMP):
        sys.exit("missing %s - run dump-handynotes.lua first" % DUMP)

    rows = []
    for line in open(DUMP, encoding="utf-8"):
        line = line.strip()
        if line:
            rows.append(json.loads(line))

    groups = collections.OrderedDict()
    unkeyed = 0
    unkeyed_by = collections.Counter()
    for r in rows:
        n = r.get("node") or {}
        cls = str(n.get("__class") or "").lower()

        npc = n.get("id") if isinstance(n.get("id"), int) else None
        if npc is None and isinstance(n.get("npc"), int):
            npc = n["npc"]
        quests = ints(n.get("quest"))

        # Some nodes carry the quest only inside a label template --
        # label = "{quest:75317}" -- which no field read would ever find.
        if not quests:
            for k in ("label", "note"):
                v = n.get(k)
                if isinstance(v, str):
                    quests.extend(int(m) for m in QUEST_IN_LABEL.findall(v))

        is_rare = any(h in cls for h in RARE_HINTS) or (npc and not quests)
        if npc and is_rare:
            key = ("rares", "npc_id", npc)
        elif quests:
            # Lowest id, so both publishers agree on the key even when one
            # lists the quest set in a different order.
            key = ("treasures", "quest_id", min(quests))
        elif npc:
            key = ("rares", "npc_id", npc)
        elif isinstance(n.get("achievement"), int) and n.get("criteria") is not None:
            # An achievement-criterion pin: no npc and no quest, but the pair
            # identifies it exactly. Grouped by achievement, which is how
            # Collectionist already models these -- one row carrying N criteria
            # and N waypoints -- rather than as thousands of loose pins.
            key = ("achievement_criteria", "achievement_id", n["achievement"])
        else:
            # Repeatable gathering and container spawns: scavenger pools,
            # disturbed earth, scout packs. These are "N spawn points of type
            # X" with no per-node identity at all, so they are counted by group
            # rather than dropped silently.
            unkeyed += 1
            grp = n.get("group")
            gname = grp.get("value") if isinstance(grp, dict) else grp
            unkeyed_by[str(gname or n.get("__class") or "(none)")] += 1
            continue

        g = groups.get(key)
        if g is None:
            g = groups[key] = {
                "addons": [], "families": set(), "coords": [], "labels": [],
                "classes": set(), "quests": set(), "loot": set(), "rewards": set(),
                "achievements": set(), "maps": set(), "criteria": set(),
            }
        if r["addon"] not in g["addons"]:
            g["addons"].append(r["addon"])
        g["families"].add(r["family"])
        if r.get("map"):
            g["maps"].add(int(r["map"]))
        g["coords"].append("%s:%.4f,%.4f" % (r.get("map") or 0, r["x"], r["y"]))
        g["classes"].add(n.get("__class") or "")
        g["quests"].update(quests)
        g["loot"].update(ints(n.get("loot")))
        g["achievements"].update(ints(n.get("achievement")))
        g["criteria"].update(ints(n.get("criteria")))
        for kind, _, v in rewards_of(n):
            g["rewards"].add("%s:%d" % (kind, v))
        for k in ("label", "note"):
            v = n.get(k)
            if isinstance(v, str) and v.strip() and not v.startswith("ns."):
                if v not in g["labels"]:
                    g["labels"].append(v.strip())

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh, lineterminator="\n")
        w.writerow(["domain", "id_kind", "natural_id", "label", "publishers",
                    "publisher_count", "families", "map_ids", "coords",
                    "quest_ids", "loot_item_ids", "achievement_ids", "criteria_ids", "rewards",
                    "node_classes", "spawn_count", "map_count"])
        for (domain, id_kind, nid), g in sorted(groups.items()):
            # Deduplicate but preserve FIRST-SEEN order. This was
            # sorted(set(...)) over strings like "1536:0.51,0.48", which sorts
            # map ids as ASCII -- "103" before "47", "1525" before "1536". Any
            # consumer taking "the first coordinate" was therefore taking an
            # arbitrary map, and that shipped a real error: pet 2944 (Oonar's
            # Arm) came out in Revendreth because "1525" sorted before the
            # "1536" Maldraxxus spawns that actually award it.
            #
            # First-seen order is the order the publisher wrote them, which is
            # at least meaningful. Consumers that need one point should still
            # pick deliberately rather than take coords[0] -- see the
            # reward-node filter in handynotes-waypoint-candidates.md.
            coords, seen = [], set()
            for c in g["coords"]:
                if c not in seen:
                    seen.add(c)
                    coords.append(c)
            w.writerow([
                domain, id_kind, nid,
                g["labels"][0] if g["labels"] else "",
                ";".join(sorted(g["addons"])),
                len(g["addons"]),
                ";".join(sorted(g["families"])),
                ";".join(str(m) for m in sorted(g["maps"])),
                ";".join(coords),
                ";".join(str(q) for q in sorted(g["quests"])),
                ";".join(str(i) for i in sorted(g["loot"])),
                ";".join(str(a) for a in sorted(g["achievements"])),
                ";".join(str(c) for c in sorted(g["criteria"])),
                ";".join(sorted(g["rewards"])),
                ";".join(sorted(c for c in g["classes"] if c)),
                len(coords),
                # A group spanning several maps cannot be reduced to one pin
                # without a decision. Surfacing the count stops a consumer
                # silently taking the first and calling it the location.
                len(g["maps"]),
            ])

    shared = sum(1 for g in groups.values() if len(g["addons"]) > 1)
    multi = sum(1 for g in groups.values() if len(set(g["coords"])) > 1)
    by_domain = collections.Counter(k[0] for k in groups)
    print("raw nodes            %6d" % len(rows))
    print("normalised           %6d  (%s)"
          % (len(groups), ", ".join("%s %d" % (d, n) for d, n in sorted(by_domain.items()))))
    print("described by >1 addon%6d" % shared)
    print("multi-spawn          %6d" % multi)
    print("no usable identity   %6d  repeatable spawns with no per-node id:" % unkeyed)
    for name, k in unkeyed_by.most_common(6):
        print("      %-26s %5d" % (name, k))
    print("wrote %s" % os.path.relpath(OUT, ROOT).replace("\\", "/"))


if __name__ == "__main__":
    main()
