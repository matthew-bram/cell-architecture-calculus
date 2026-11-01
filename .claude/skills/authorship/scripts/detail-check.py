#!/usr/bin/env python3
"""The detail check.

Compares a rewritten Markdown page with its original and names every
significant detail the original had and the rewrite does not. A rewrite in
the authorship voice changes how a page says things; this check catches the
places where it also changed what the page says.

What it compares:
- code blocks, which must survive byte for byte;
- inline code: identifiers, file names, types and commands;
- numbers, with number words read as numerals, so "seven" matches "7";
- link targets;
- the words that carry a claim's strength: quantifiers such as every and
  only, negations such as never and no, conditions such as unless and
  except, bounds such as at most, and modals such as must and may;
- the four words, proved, checked, tested and assumed;
- terms in bold, and headings.

A missing code block, identifier, number or link is a warning. A strength
word that appears fewer times is a warning too: splitting a sentence rarely
needs to drop one. More strength words, or a changed bold term or heading,
is a note, because a person must judge it. The check reads tokens, not
meaning; a clean result does not prove the meaning survived.

Usage:
  python3 detail-check.py BEFORE AFTER     compare two files
  python3 detail-check.py FILE [--against REV]
                                           compare FILE with its version at
                                           REV in git, by default HEAD
  --json    print the findings as JSON
  --strict  exit 1 if there is any warning
"""
import argparse
import json
import re
import subprocess
import sys
from collections import Counter

FENCE = re.compile(r"^\s*(```|~~~)")

# The words that carry a claim's strength, by what they do. Contractions are
# expanded before counting, so "can't" counts as "not".
STRENGTH = {
    "quantifier": ["every", "each", "all", "always", "any", "both", "either"],
    "negation": ["never", "no", "not", "none", "nothing", "nobody", "nor", "neither", "without"],
    "restriction": ["only", "exactly", "solely", "alone"],
    "condition": ["if", "unless", "until", "except", "once", "provided", "whether"],
    "bound": ["at most", "at least", "more than", "fewer than", "less than", "up to", "no more than"],
    "modal": ["must", "may", "might", "can", "cannot", "should", "shall"],
    "status": ["proved", "checked", "tested", "assumed"],
}
# Strength words a rewrite may legitimately add or drop when it splits sentences.
SOFT = {"can", "if", "any", "all", "both", "either"}

UNITS = {w: i for i, w in enumerate(
    "zero one two three four five six seven eight nine ten eleven twelve thirteen "
    "fourteen fifteen sixteen seventeen eighteen nineteen".split())}
TENS = {w: 10 * i for i, w in enumerate(
    "_ _ twenty thirty forty fifty sixty seventy eighty ninety".split()) if w != "_"}
SCALES = {"hundred": 100, "thousand": 1000}


def read_git(path, rev):
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True).stdout.strip()
    relative = subprocess.run(["git", "ls-files", "--full-name", path], capture_output=True, text=True).stdout.strip()
    if not relative:
        sys.exit(f"{path} is not tracked by git; compare two files instead")
    return subprocess.run(["git", "show", f"{rev}:{relative}"], capture_output=True, text=True, check=True, cwd=root).stdout


def split(text):
    """Return (code blocks, the text outside them)."""
    blocks, outside, current, in_code = [], [], [], False
    for line in text.splitlines():
        if FENCE.match(line):
            if in_code:
                blocks.append("\n".join(current))
                current = []
            in_code = not in_code
            continue
        (current if in_code else outside).append(line)
    return blocks, "\n".join(outside)


def numbers(prose):
    """Every number in the prose, with number words read as numerals."""
    found = Counter(re.findall(r"(?<![\w.])\d+(?:[.,]\d+)*(?![\w])", prose))
    words = re.findall(r"[a-z]+", prose.lower().replace("-", " "))
    i = 0
    while i < len(words):
        if words[i] in UNITS or words[i] in TENS:
            total, current, j, parts = 0, 0, i, 0
            while j < len(words):
                w = words[j]
                if w in UNITS or w in TENS:
                    current += UNITS.get(w, TENS.get(w, 0))
                elif w in SCALES and parts:
                    if SCALES[w] == 100:
                        current *= 100
                    else:
                        total += current * SCALES[w]
                        current = 0
                elif w == "and" and parts and j + 1 < len(words) and (words[j + 1] in UNITS or words[j + 1] in TENS):
                    pass
                else:
                    break
                parts += 1
                j += 1
            value = total + current
            # A lone "one" is usually a pronoun or an article, not a count.
            if not (parts == 1 and words[i] in ("one", "zero")):
                found[str(value)] += 1
            i = j
        else:
            i += 1
    return found


def strength(prose):
    text = re.sub(r"`[^`]*`", " ", prose.lower())
    text = re.sub(r"\bcan't\b", "can not", text)
    text = re.sub(r"\bwon't\b", "will not", text)
    text = re.sub(r"n't\b", " not", text)
    text = re.sub(r"\bcannot\b", "can not", text)
    counts = {}
    for kind, terms in STRENGTH.items():
        for term in terms:
            counts[(kind, term)] = len(re.findall(rf"\b{re.escape(term)}\b", text))
    return counts


def details(text):
    blocks, prose = split(text)
    return {
        "code_blocks": blocks,
        "inline_code": Counter(re.findall(r"`([^`\n]+)`", prose)),
        "numbers": numbers(re.sub(r"`[^`]*`", " ", re.sub(r"\]\([^)]*\)", "]", prose))),
        "links": Counter(re.findall(r"\]\(([^)\s]+)", prose)),
        "strength": strength(re.sub(r"\]\([^)]*\)", "]", prose)),
        "bold": Counter(t.strip() for t in re.findall(r"\*\*([^*]+)\*\*", prose)),
        "headings": [h.strip() for h in re.findall(r"^#{1,6}\s+(.*)$", prose, flags=re.M)],
    }


def compare(before, after):
    b, a = details(before), details(after)
    warnings, notes = [], []
    for block in b["code_blocks"]:
        if block not in a["code_blocks"]:
            first = next((l for l in block.splitlines() if l.strip()), "")
            warnings.append(f"a code block changed or is missing: {first.strip()[:70]}")
    for kind, label in (("inline_code", "inline code"), ("numbers", "a number"), ("links", "a link")):
        for item in sorted(set(b[kind]) - set(a[kind])):
            warnings.append(f"{label} is missing: {item}")
    for (kind, term), count in b["strength"].items():
        after_count = a["strength"][(kind, term)]
        if after_count < count:
            entry = f"'{term}' ({kind}) appears {count} times before and {after_count} after"
            (notes if term in SOFT else warnings).append(entry)
        elif after_count > count and term not in SOFT:
            notes.append(f"'{term}' ({kind}) appears {count} times before and {after_count} after: a claim may be stronger")
    for item in sorted(set(b["bold"]) - set(a["bold"])):
        notes.append(f"a bold term is gone: {item}")
    for item in [h for h in b["headings"] if h not in a["headings"]]:
        notes.append(f"a heading is gone or renamed, so links to it may break: {item}")
    return {"warnings": warnings, "notes": notes}


def main(argv):
    parser = argparse.ArgumentParser(description="Name the details a rewrite lost.")
    parser.add_argument("paths", nargs="+", help="BEFORE AFTER, or one FILE to compare with git")
    parser.add_argument("--against", default="HEAD", help="the git revision of the original, for one FILE")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args(argv[1:])
    if len(args.paths) == 2:
        before = open(args.paths[0], encoding="utf-8").read()
        after = open(args.paths[1], encoding="utf-8").read()
        label = f"{args.paths[0]} -> {args.paths[1]}"
    elif len(args.paths) == 1:
        before = read_git(args.paths[0], args.against)
        after = open(args.paths[0], encoding="utf-8").read()
        label = f"{args.paths[0]} against {args.against}"
    else:
        parser.error("give BEFORE AFTER, or one FILE")
    result = compare(before, after)
    if args.json:
        print(json.dumps({"compared": label, **result}, indent=2))
    else:
        print(label)
        for w in result["warnings"]:
            print(f"  warn  {w}")
        for n in result["notes"]:
            print(f"  note  {n}")
        print(f"{len(result['warnings'])} warning(s), {len(result['notes'])} note(s)")
    return 1 if args.strict and result["warnings"] else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
