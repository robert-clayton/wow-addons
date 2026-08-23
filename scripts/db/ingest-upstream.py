"""Loads the upstream inventories into build/collectionist-full.db.

    python scripts/db/ingest-upstream.py

Runs after build-db.py, which owns the schema and the catalog. This copies the
catalog and adds what the *sources* say exists alongside what the addon ships,
so the difference between them is a query rather than a script.

Which files are upstream, and which are not:

    research/collectionist/<exp>/ids/*.csv   DB2 inventories -- upstream
    research/collectionist/sources/att-*.csv ATT extractions -- upstream
    research/collectionist/<exp>/manifests/  derived from ids -- skipped
    research/collectionist/sources/*-audit   outputs of past runs -- skipped

Ingesting the derived files would be the same mistake the navigation audit made
when it read its own previous output as pre-existing coverage and ate its own
tail, going from 721 candidates to 55.

Every snapshot records the file path, its SHA-256 and its row count. That does
not pin the upstream repository -- the ATT checkout that resolved 8,975 recipe
sources lived in %TEMP% and is gone -- but it does make "which bytes produced
this row" answerable, and turns a silent upstream change into a hash change.
"""

import csv
import hashlib
import json
import os
import shutil
import sqlite3
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CATALOG = os.path.join(ROOT, "data", "collectionist.db")
# Ingest lands in a BUILD copy, not the committed catalog. The upstream CSVs are
# already committed under research/ -- 20 MB of them -- and this script rebuilds
# from them deterministically, with a sha256 per file recorded in
# source_snapshot. Committing the ingested copy would store the same data a
# second time in a format git cannot delta, taking the artifact from 6.4 MB to
# 31 MB and re-writing all of it on every build.
DB_PATH = os.path.join(ROOT, "build", "collectionist-full.db")
RESEARCH = os.path.join(ROOT, "research", "collectionist")

# Directory name -> the addon's expansion key. The directories are spelled out
# and the addon abbreviates; a mismatch here is how "dragonflight" was emitted
# where the addon uses "df", matching nothing and breaking the Options filter.
EXPANSION_DIR = {
    "classic": "vanilla",
    "the-burning-crusade": "tbc",
    "wrath-of-the-lich-king": "wrath",
    "cataclysm": "cata",
    "mists-of-pandaria": "mop",
    "warlords-of-draenor": "wod",
    "legion": "legion",
    "battle-for-azeroth": "bfa",
    "shadowlands": "shadowlands",
    "dragonflight": "df",
    "tww": "tww",
    # Added when a player reported an owned pet showing as missing. The repo had
    # no Midnight inventory at all, so catalog_missing_from_upstream flagged 110
    # of 118 Midnight pet rows as unverifiable and nothing could tell a wrong id
    # from an unchecked one.
    "midnight": "midnight",
}

# ids/<file>.csv -> (domain, collectible column, the CSV's id column, name column)
DB2_DOMAINS = {
    "mounts":       ("mounts", "mount_id", "mount_id", "name"),
    "pets":         ("pets", "species_id", "species_id", "name"),
    "toys":         ("toys", "item_id", "item_id", "name"),
    "decorations":  ("decorations", "decor_id", "decor_id", "decor_name"),
    "recipes":      ("recipes", "spell_id", "recipe_spell_id", "name"),
    "achievements": ("achievements", "achievement_id", "achievement_id", "title"),
}


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def compact(row):
    """Drops empty columns before storing. Roughly halves the payload and makes
    a stored NULL mean "the upstream had nothing", not "the column existed"."""
    return {k: v for k, v in row.items() if v not in (None, "") and k}


def snapshot(con, source, version, path, rows):
    rel = os.path.relpath(path, ROOT).replace("\\", "/")
    return con.execute(
        "INSERT INTO source_snapshot (source, version, path, sha256, row_count, note)"
        " VALUES (?,?,?,?,?,?)",
        (source, version, rel, sha256(path), rows,
         "ingested by scripts/db/ingest-upstream.py")).lastrowid


def ingest_csv(con, source, version, path, domain, id_kind, id_col, name_col,
               expansion=None, status_col="status"):
    with open(path, encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.DictReader(fh))
    if not rows:
        return 0, 0
    if id_col not in rows[0]:
        print("   skip %s: no column %r" % (os.path.basename(path), id_col))
        return 0, 0

    snap = snapshot(con, source, version, path, len(rows))
    added = dropped = 0
    for r in rows:
        raw = (r.get(id_col) or "").strip()
        if not raw.isdigit():
            dropped += 1
            continue
        try:
            con.execute(
                "INSERT INTO upstream_row (snapshot_id, domain, expansion, id_kind,"
                " natural_id, name, status, payload) VALUES (?,?,?,?,?,?,?,?)",
                (snap, domain, expansion, id_kind, int(raw),
                 (r.get(name_col) or "").strip() or None,
                 (r.get(status_col) or "").strip() or None,
                 json.dumps(compact(r), separators=(",", ":"), sort_keys=True)))
            added += 1
        except sqlite3.IntegrityError:
            # The same id listed twice in one inventory. Keeping the first is
            # right: these files are ordered, and a later duplicate is a
            # re-listing under a second category rather than a correction.
            dropped += 1
    return added, dropped


def main():
    if not os.path.exists(CATALOG):
        sys.exit("missing %s - run build-db.py first" % CATALOG)
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    shutil.copyfile(CATALOG, DB_PATH)
    con = sqlite3.connect(DB_PATH)
    con.execute("PRAGMA foreign_keys = ON")

    # Idempotent: drop everything this script owns, then re-ingest. Appending
    # would double every row on the second run.
    con.execute("DELETE FROM upstream_row")
    con.execute("DELETE FROM source_snapshot WHERE source IN ('db2', 'att', 'handynotes')")

    total, skipped_files = 0, 0
    for dirname, expansion in sorted(EXPANSION_DIR.items()):
        ids_dir = os.path.join(RESEARCH, dirname, "ids")
        if not os.path.isdir(ids_dir):
            skipped_files += 1
            continue
        for stem, (domain, id_kind, id_col, name_col) in sorted(DB2_DOMAINS.items()):
            path = os.path.join(ids_dir, stem + ".csv")
            if not os.path.exists(path):
                skipped_files += 1
                continue
            added, _ = ingest_csv(con, "db2", "%s/%s" % (dirname, stem), path,
                                  domain, id_kind, id_col, name_col, expansion)
            total += added

    # ATT's recipe acquisition table. Expansion is deliberately left NULL: ATT
    # places content by patch stamp, which disagrees with trade-category
    # placement on 86% of rows and puts zero rows in Vanilla. Recording an
    # expansion here would give a wrong answer an authoritative-looking home.
    att = os.path.join(RESEARCH, "sources", "att-recipe-acquisition.csv")
    att_added = 0
    if os.path.exists(att):
        att_added, _ = ingest_csv(con, "att", "recipe-acquisition", att,
                                  "recipes", "spell_id", "recipe_spell_id", "",
                                  None, status_col="source_kind")
        total += att_added

    # HandyNotes, via the normalised extract. Unlike the DB2 and ATT files this
    # one is produced from the player's WoW install, so normalize-handynotes.py
    # writes it into research/ first -- otherwise the ingest would depend on
    # which addons happen to be installed, and source_snapshot would hash
    # something that does not exist in a checkout.
    hn = os.path.join(RESEARCH, "sources", "handynotes-nodes.csv")
    hn_added = 0
    if os.path.exists(hn):
        with open(hn, encoding="utf-8-sig", newline="") as fh:
            hn_rows = list(csv.DictReader(fh))
        snap = snapshot(con, "handynotes", "nodes", hn, len(hn_rows))
        for r in hn_rows:
            raw = (r.get("natural_id") or "").strip()
            if not raw.isdigit():
                continue
            try:
                con.execute(
                    "INSERT INTO upstream_row (snapshot_id, domain, expansion, id_kind,"
                    " natural_id, name, status, payload) VALUES (?,?,?,?,?,?,?,?)",
                    (snap, r["domain"], None, r["id_kind"], int(raw),
                     (r.get("label") or "").strip() or None,
                     # Publisher count doubles as a confidence signal: a node
                     # two independent addons agree on is stronger evidence
                     # than one only a single publisher lists.
                     "publishers=%s" % (r.get("publisher_count") or "0"),
                     json.dumps(compact(r), separators=(",", ":"), sort_keys=True)))
                hn_added += 1
            except sqlite3.IntegrityError:
                pass
        total += hn_added

    con.commit()

    print("analysis database: %s" % os.path.relpath(DB_PATH, ROOT).replace("\\", "/"))
    print("upstream rows %d   (db2 %d, att %d, handynotes %d)   inventories absent %d"
          % (total, total - att_added - hn_added, att_added, hn_added, skipped_files))
    print()
    for src, n, files in con.execute(
            "SELECT s.source, COUNT(u.id), COUNT(DISTINCT s.id) FROM source_snapshot s"
            " LEFT JOIN upstream_row u ON u.snapshot_id = s.id"
            " WHERE s.source IN ('db2','att','handynotes') GROUP BY s.source"):
        print("   %-5s %6d rows from %d pinned files" % (src, n, files))

    print()
    for view in ("upstream_missing_from_catalog", "catalog_missing_from_upstream",
                 "upstream_name_mismatch", "upstream_expansion_mismatch"):
        n = con.execute("SELECT COUNT(*) FROM %s" % view).fetchone()[0]
        print("   %-32s %d" % (view, n))

    print("\n   upstream_missing_from_catalog by status (a queue, not a defect list):")
    for status, n in con.execute(
            "SELECT COALESCE(statuses,'(none)'), COUNT(*)"
            " FROM upstream_missing_from_catalog GROUP BY 1 ORDER BY 2 DESC LIMIT 10"):
        print("      %-28s %6d" % (status, n))
    q = con.execute(
        "SELECT publishers >= 2, COUNT(*) FROM handynotes_navigation_queue GROUP BY 1").fetchall()
    if q:
        print()
        print("   handynotes_navigation_queue:")
        for corroborated, n in sorted(q, reverse=True):
            print("      %-28s %6d" % ("2+ publishers agree" if corroborated
                                       else "single publisher only", n))
    con.close()


if __name__ == "__main__":
    main()
