"""Attaches the structured `renown` field to rows that only state the
requirement in prose.

A row whose sourceInfo says "reward track level 8" but carries no `renown`
renders that as dead text: no live progress, no green/red. The tooltip feature
exists; these rows just never opted in.

Only rows whose faction AND level are unambiguous from the prose, and whose
faction has a constant in MC.FACTION, are touched. Everything else is listed
and left alone -- inventing a factionID would make the tooltip confidently
show the wrong track's progress.
"""
import io
import re

# (file, name, factionConstant, factionName, level)
ROWS = [
    ("addons/Collectionist/Modules/Pets/Data/Patch120100.lua",
     "Preyhunter's Riftbreaker", "PreyhuntersJourney", "Preyhunter's Journey", 8),
    ("addons/Collectionist/Modules/Pets/Data/Patch120100.lua",
     "Preyhunter's Prismguard", "PreyhuntersJourney", "Preyhunter's Journey", 8),
    ("addons/Collectionist/Modules/Toys/Data/Patch120100.lua",
     "Preyhunter's Trophy Stand", "PreyhuntersJourney", "Preyhunter's Journey", 4),
    ("addons/Collectionist/Modules/Toys/Data/Patch120100.lua",
     "Companion Command Crystal", "PreyhuntersJourney", "Preyhunter's Journey", 4),
    ("addons/Collectionist/Modules/Mounts/Data/Mounts.lua",
     "Preyseeker's Hubris", "PreyhuntersJourney", "Preyhunter's Journey", 5),
    ("addons/Collectionist/Modules/Mounts/Data/Mounts.lua",
     "Preyseeker's Wrath", "PreyhuntersJourney", "Preyhunter's Journey", 10),
    ("addons/Collectionist/Modules/Mounts/Data/Mounts.lua",
     "Silvermoon's Arcane Defender", "DelversJourney", "Delver's Journey", 5),
    ("addons/Collectionist/Modules/Pets/Data/Patch120100.lua",
     "Venom Elemental", "CaptainTokka", "Captain Tokka", 4),
    ("addons/Collectionist/Modules/Pets/Data/Patch120100.lua",
     "Three-Eyed Fish", "CaptainTokka", "Captain Tokka", 4),
    ("addons/Collectionist/Modules/Decorations/Data/Patch120100.lua",
     "Aged Tortollan Scroll Case", "CaptainTokka", "Captain Tokka", 2),
    ("addons/Collectionist/Modules/Decorations/Data/Patch120100.lua",
     "Yellowed Kelp Pile", "CaptainTokka", "Captain Tokka", 2),
    ("addons/Collectionist/Modules/Decorations/Data/Patch120100.lua",
     "Hanging Yellowed Kelp", "CaptainTokka", "Captain Tokka", 3),
    ("addons/Collectionist/Modules/Decorations/Data/Patch120100.lua",
     "Blue Tortollan Signpost", "CaptainTokka", "Captain Tokka", 4),
    ("addons/Collectionist/Modules/Decorations/Data/Patch120100.lua",
     "Rustic Fishing Rack", "CaptainTokka", "Captain Tokka", 4),
    ("addons/Collectionist/Modules/Decorations/Data/Patch120100.lua",
     "Traditional Tortollan Tent", "CaptainTokka", "Captain Tokka", 5),
    ("addons/Collectionist/Modules/Decorations/Data/Decorations.lua",
     "Twilight Tabernacle", "DelversJourney", "Delver's Journey", 1),
    ("addons/Collectionist/Modules/Decorations/Data/Decorations.lua",
     "Fungal Chest", "DelversJourney", "Delver's Journey", 2),
    ("addons/Collectionist/Modules/Decorations/Data/Decorations.lua",
     "Amani Strongbox", "DelversJourney", "Delver's Journey", 3),
    ("addons/Collectionist/Modules/Decorations/Data/Decorations.lua",
     "Ancient Kaldorei Coffer", "DelversJourney", "Delver's Journey", 4),
    ("addons/Collectionist/Modules/Decorations/Data/Decorations.lua",
     "Root-Wrapped Reliquary", "DelversJourney", "Delver's Journey", 7),
    ("addons/Collectionist/Modules/Decorations/Data/Decorations.lua",
     "Corewarden's Spoils", "DelversJourney", "Delver's Journey", 8),
    ("addons/Collectionist/Modules/Decorations/Data/Decorations.lua",
     "Delver's Bountiful Coffer", "DelversJourney", "Delver's Journey", 10),
]

# The prose is redundant once the structured field renders a live line, and
# leaving both makes the tooltip say it twice -- the same reason the earlier
# renown migration stripped it.
STRIP = [
    (re.compile(r"\s*-\s*Prey Season 2 reward track level \d+"), ""),
    (re.compile(r",\s*Captain Tokka [Rr]ank \d+"), ""),
    (re.compile(r"\s*-\s*Captain Tokka rank \d+"), ""),
    (re.compile(r",\s*Rank \d+\s*(?=\")"), ""),
    (re.compile(r"\s*-\s*Rank \d+\s*(?=\")"), ""),
    (re.compile(r",\s*Delver's Journey Renown \d+"), ""),
    (re.compile(r"\s*-\s*Captain Tokka rank \d+,"), " -"),
]

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
    raise ValueError("unbalanced braces")


def main():
    by_file = {}
    for path, name, const, label, level in ROWS:
        by_file.setdefault(path, []).append((name, const, label, level))

    total = 0
    for path, rows in sorted(by_file.items()):
        text = io.open(path, encoding="utf-8").read()
        for name, const, label, level in rows:
            needle = 'name = "%s"' % name
            at = text.find(needle)
            if at < 0:
                print("  MISS  %-30s in %s" % (name, path))
                continue
            start = text.rfind("{", 0, at)
            # Walk back to the entry's own opening brace, not a nested one.
            while True:
                try:
                    end = span_of_entry(text, start)
                except ValueError:
                    end = -1
                if end > at:
                    break
                start = text.rfind("{", 0, start)
                if start < 0:
                    break
            if start < 0 or end <= at:
                print("  MISS  %-30s (no entry span)" % name)
                continue
            entry = text[start:end]
            if "renown" in entry:
                print("  SKIP  %-30s already has renown" % name)
                continue

            new_entry = entry
            m = None
            for m in re.finditer(r'sourceInfo\s*=\s*(%s)' % STRING, new_entry):
                pass
            if m:
                prose = m.group(1)
                cleaned = prose
                for rx, rep in STRIP:
                    cleaned = rx.sub(rep, cleaned)
                cleaned = re.sub(r'\s*[-,]\s*"$', '"', cleaned)
                cleaned = re.sub(r',\s*"$', '"', cleaned)
                new_entry = new_entry[:m.start(1)] + cleaned + new_entry[m.end(1):]

            field = ('renown = { factionID = MC.FACTION.%s, level = %d,\n'
                     '                         factionName = "%s" }'
                     % (const, level, label))
            close = new_entry.rstrip()
            cut = len(close) - 1
            new_entry = (close[:cut].rstrip().rstrip(",") + ",\n              "
                         + field + " }" + new_entry[len(close):])

            text = text[:start] + new_entry + text[end:]
            total += 1
        io.open(path, "w", encoding="utf-8", newline="\n").write(text)
        print("  %s" % path)
    print("attached renown to %d rows" % total)


if __name__ == "__main__":
    main()
