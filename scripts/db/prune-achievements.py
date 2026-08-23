"""Removes achievement entries from the shipped Lua by achievementID.

Entries are multi-line and carry nested tables (taskList, criteria arrays), so
this matches braces rather than lines. A regex would truncate an entry in the
middle of its task list and leave the file parsing but wrong, which is worse
than not running at all.
"""
import io
import json
import os
import re
import sys

DROP = set(json.load(io.open("research/collectionist/sources/dropped-achievements.json", encoding="utf-8")))
ENTRY = re.compile(r"\{\s*achievementID\s*=\s*(\d+)\b")


def span_of_entry(text, start):
    """start is the index of the entry's opening brace. Returns the index just
    past its matching close brace, skipping over string literals."""
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


def prune(text):
    out, i, removed = [], 0, 0
    while True:
        m = ENTRY.search(text, i)
        if not m:
            out.append(text[i:])
            break
        aid = int(m.group(1))
        start = m.start()
        end = span_of_entry(text, start)
        # Swallow a trailing comma and the rest of the line.
        j = end
        while j < len(text) and text[j] in ", \t":
            j += 1
        if j < len(text) and text[j] == "\n":
            j += 1
        if aid in DROP:
            # Also drop the indentation that preceded the entry.
            k = start
            while k > 0 and text[k - 1] in " \t":
                k -= 1
            out.append(text[i:k])
            removed += 1
        else:
            out.append(text[i:j])
        i = j
    return "".join(out), removed


def main():
    root = "addons/Collectionist/Modules/Achievements/Data"
    total = 0
    for fn in sorted(os.listdir(root)):
        if not fn.endswith(".lua"):
            continue
        p = os.path.join(root, fn)
        s = io.open(p, encoding="utf-8").read()
        new, n = prune(s)
        if n:
            # Groups whose entries are all gone would emit `achievements = {}`;
            # a scanner skips them, but leaving them is litter.
            new = re.sub(r"\n\s*\{[^{}\n]*achievements\s*=\s*\{\s*\}\s*\},", "", new)
            io.open(p, "w", encoding="utf-8", newline="\n").write(new)
            total += n
            print("  %-28s -%d" % (fn, n))
    print("removed %d entries" % total)


if __name__ == "__main__":
    main()
