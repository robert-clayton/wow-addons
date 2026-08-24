"""Second pass: Dragonflight renown rows.

Same idea as the first pass, but these state the requirement in the coloured
"Faction: X | Renown: N" form rather than free prose, so both the faction and
the level are unambiguous. No Dragonflight row had ever carried the structured
field -- the feature had only been applied to Midnight tracks.

The prose segment is removed, since the structured line renders the same fact
with live progress attached.
"""
import io
import re

ROWS = [
    ("addons/Collectionist/Modules/Mounts/Data/Dragonflight.lua",
     "Royal Seafeather", "KegLegsCrew", "Keg Leg's Crew", 20),
    ("addons/Collectionist/Modules/Mounts/Data/Dragonflight.lua",
     "Silver Tidestallion", "KegLegsCrew", "Keg Leg's Crew", 10),
    ("addons/Collectionist/Modules/Mounts/Data/Dragonflight.lua",
     "Polly Roger", "KegLegsCrew", "Keg Leg's Crew", 39),
    ("addons/Collectionist/Modules/Pets/Data/Dragonflight.lua",
     "Whiskuk", "IskaaraTuskarr", "Iskaara Tuskarr", 9),
    ("addons/Collectionist/Modules/Pets/Data/Dragonflight.lua",
     "Backswimmer Timbertooth", "IskaaraTuskarr", "Iskaara Tuskarr", 9),
    ("addons/Collectionist/Modules/Pets/Data/Dragonflight.lua",
     "Magic Nibbler", "ValdrakkenAccord", "Valdrakken Accord", 18),
    ("addons/Collectionist/Modules/Pets/Data/Dragonflight.lua",
     "Crimson Proto-Whelp", "ValdrakkenAccord", "Valdrakken Accord", 18),
    ("addons/Collectionist/Modules/Pets/Data/Dragonflight.lua",
     "Black Skitterbug", "DragonscaleExpedition", "Dragonscale Expedition", 11),
    ("addons/Collectionist/Modules/Pets/Data/Dragonflight.lua",
     "Gray Marmoni", "DragonscaleExpedition", "Dragonscale Expedition", 11),
    ("addons/Collectionist/Modules/Pets/Data/Dragonflight.lua",
     "Glamrok", "KegLegsCrew", "Keg Leg's Crew", 30),
    ("addons/Collectionist/Modules/Pets/Data/Dragonflight.lua",
     "Bubbles", "KegLegsCrew", "Keg Leg's Crew", 11),
    ("addons/Collectionist/Modules/Pets/Data/Dragonflight.lua",
     "Happy", "KegLegsCrew", "Keg Leg's Crew", 6),
    ("addons/Collectionist/Modules/Toys/Data/Dragonflight.lua",
     "Swarthy Warning Sign", "KegLegsCrew", "Keg Leg's Crew", 16),
]

# "|cFFFFD200Faction: |rKeg Leg's Crew|n|cFFFFD200Renown: |r20" and any |n that
# separated it from the rest of the line.
SEGMENT = re.compile(
    r'(?:\|n)?\|cFFFFD200Faction: \|r[^|]*\|n\|cFFFFD200Renown: \|r\d+')
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
            at = text.find('name = "%s"' % name)
            if at < 0:
                print("  MISS  %s" % name)
                continue
            start, end = text.rfind("{", 0, at), -1
            while start >= 0:
                try:
                    end = span_of_entry(text, start)
                except ValueError:
                    end = -1
                if end > at:
                    break
                start = text.rfind("{", 0, start)
            if start < 0 or end <= at:
                print("  MISS  %s (no span)" % name)
                continue
            entry = text[start:end]
            if "renown" in entry:
                print("  SKIP  %s already has renown" % name)
                continue

            new_entry = entry
            last = None
            for last in re.finditer(r'sourceInfo\s*=\s*(%s)' % STRING, new_entry):
                pass
            if last:
                cleaned = SEGMENT.sub("", last.group(1))
                # Where the faction line WAS the whole source text, stripping it
                # leaves sourceInfo = "" and the row loses its source entirely.
                # Keep the prose in that case: saying it twice beats saying
                # nothing.
                if cleaned.strip('"').strip():
                    new_entry = (new_entry[:last.start(1)] + cleaned
                                 + new_entry[last.end(1):])

            field = ('renown = { factionID = MC.FACTION.%s, level = %d,\n'
                     '              factionName = "%s" }' % (const, level, label))
            close = new_entry.rstrip()
            cut = len(close) - 1
            new_entry = (close[:cut].rstrip().rstrip(",") + ",\n              "
                         + field + " }" + new_entry[len(close):])
            text = text[:start] + new_entry + text[end:]
            total += 1
        io.open(path, "w", encoding="utf-8", newline="\n").write(text)
        print("  %s" % path)
    print("attached renown to %d Dragonflight rows" % total)


if __name__ == "__main__":
    main()
