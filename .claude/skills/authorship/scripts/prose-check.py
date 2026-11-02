#!/usr/bin/env python3
"""The prose check.

Measures a Markdown document against the voice the authorship skill writes in:
how long its sentences are, how many run past the long-sentence line, how many
commas each one carries, how long its paragraphs are, how deep its headings go,
where it has figures, and which British spellings it uses. It warns and does not
fail unless --strict is given, because the numbers show where a reader will
struggle; they do not define good prose.

Code blocks, tables, headings and HTML lines are not prose and are not measured.
A Mermaid block, an image or an <img> tag counts as a figure. Inline code counts
as one word, so a long identifier does not inflate a sentence.

It also follows every relative link, in prose and in tables, and warns when the
file is missing or the anchor matches no heading there. A rewrite that renames a
heading breaks the links to it, so run the check over the whole repository after one.

Usage: python3 prose-check.py [--json] [--strict] PATH [PATH ...]
A PATH is a Markdown file or a directory, which is read for *.md files.
"""
import argparse
import json
import os
import re
import statistics
import sys
from urllib.parse import unquote

# The targets, set a little looser than this script measures on the reference page:
# 15.6 words a sentence, 2% of sentences at 35 words or more, 0.8 commas a sentence
# and 43 words a paragraph.
TARGETS = {
    "sentence_mean": 18.0,
    "long_share": 0.05,
    "commas_per_sentence": 1.2,
    "paragraph_mean": 60.0,
}
LONG = 35  # words; a sentence this long or longer is a long sentence
PARAGRAPH_MAX = 100  # words; a paragraph this long is named by its line
HEADING_DEPTH = 3  # the deepest heading the voice uses, ###
SECTION_FIGURE_WORDS = 400  # a section this long with no figure is named
SHOW = 5  # how many of the longest sentences to name

# American spelling throughout. Each pattern names the British form; the value is the fix.
BRITISH = {
    r"behaviour(s?)": r"behavior\1",
    r"behavioural(ly)?": r"behavioral\1",
    r"modell(ing|ed|er|ers)": r"model\1",
    r"organis(e|ed|es|ing|ation|ations|ational)": r"organiz\1",
    r"recognis(e|ed|es|ing)": r"recogniz\1",
    r"serialis(e|ed|es|ing|ation)": r"serializ\1",
    r"normalis(e|ed|es|ing|ation)": r"normaliz\1",
    r"summaris(e|ed|es|ing)": r"summariz\1",
    r"formalis(e|ed|es|ing|ation)": r"formaliz\1",
    r"initialis(e|ed|es|ing|ation)": r"initializ\1",
    r"optimis(e|ed|es|ing|ation)": r"optimiz\1",
    r"prioritis(e|ed|es|ing)": r"prioritiz\1",
    r"artefact(s?)": r"artifact\1",
    r"labell(ed|ing)": r"label\1",
    r"colour(s?)": r"color\1",
    r"favour(s?|ed|ing|ite)": r"favor\1",
    r"centre(s?)": r"center\1",
    r"judgement(s?)": r"judgment\1",
    r"honour(s?|ed|ing|able)": r"honor\1",
    r"per cent": r"percent",
}

SKIP_DIRS = {".git", ".lake", "__pycache__", "node_modules"}
FENCE = re.compile(r"^\s*(```|~~~)\s*([\w-]*)")
LIST_ITEM = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+")
HEADING = re.compile(r"^(#{1,6})\s+(.*)")
LINK = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
HTML_ID = re.compile(r"\b(?:id|name)=\"([^\"]+)\"")


def outside_code(lines):
    """Yield (line number, line) for the lines that are not inside a fenced code block."""
    in_code = False
    for number, line in enumerate(lines, 1):
        if FENCE.match(line):
            in_code = not in_code
            continue
        if not in_code:
            yield number, line


def slug(heading):
    """The anchor GitHub gives a heading."""
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", heading)
    text = re.sub(r"[`*]", "", text).strip().lower()
    return re.sub(r"[^\w\- ]", "", text).replace(" ", "-")


_anchors = {}


def anchors(path):
    if path not in _anchors:
        found, seen = set(), {}
        for _, line in outside_code(open(path, encoding="utf-8").read().splitlines()):
            heading = HEADING.match(line)
            if heading:
                base = slug(heading.group(2))
                count = seen.get(base, 0)
                found.add(base if count == 0 else f"{base}-{count}")
                seen[base] = count + 1
            found.update(HTML_ID.findall(line))
        _anchors[path] = found
    return _anchors[path]


def broken_links(path, lines):
    broken = []
    for number, line in outside_code(lines):
        for target in LINK.findall(re.sub(r"`[^`]*`", "", line)):
            if re.match(r"^[a-z][a-z0-9+.-]*:", target, flags=re.I):
                continue
            file_part, _, anchor = unquote(target).partition("#")
            resolved = os.path.normpath(os.path.join(os.path.dirname(path), file_part)) if file_part else path
            if not os.path.exists(resolved):
                broken.append({"line": number, "link": target, "why": "no such file"})
            elif anchor and resolved.endswith(".md") and anchor not in anchors(resolved):
                broken.append({"line": number, "link": target, "why": "no such heading"})
    return broken


def clean(text):
    """Strip the markup that is not words."""
    text = re.sub(r"!\[[^\]]*\]\([^)]*\)", " ", text)
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"`[^`]*`", "x", text)
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"[*_]{1,3}", "", text)
    text = re.sub(r"\b(e\.g|i\.e|etc|vs|cf)\.", r"\1", text, flags=re.I)
    return re.sub(r"\s+", " ", text).strip()


def sentences(text):
    marked = re.sub(r"([.!?][)\"'\]]?)\s+(?=[A-Z0-9\"'(\[])", "\\1\n", text)
    return [s for s in marked.split("\n") if len(s.split()) >= 2]


def blocks(lines):
    """Yield (kind, first line number, text) for each prose block, and the figures and headings."""
    in_code = False
    current, start, kind = [], 0, None
    out, figures, headings = [], [], []

    def flush():
        nonlocal current, kind
        if current:
            out.append((kind, start, " ".join(current)))
        current, kind = [], None

    for number, raw in enumerate(lines, 1):
        line = raw.rstrip()
        fence = FENCE.match(line)
        if fence:
            if not in_code and fence.group(2).lower() == "mermaid":
                figures.append(number)
            in_code = not in_code
            flush()
            continue
        if in_code:
            continue
        if "![" in line or "<img" in line:
            figures.append(number)
        heading = HEADING.match(line)
        stripped = line.strip()
        if (
            not stripped
            or heading
            or stripped.startswith("|")
            or (stripped.startswith("<") and stripped.endswith(">"))
            or re.fullmatch(r"!\[[^\]]*\]\([^)]*\)", stripped)
        ):
            flush()
            if heading:
                headings.append((number, len(heading.group(1)), heading.group(2).strip()))
            continue
        stripped = re.sub(r"^>\s?", "", stripped)
        item = LIST_ITEM.match(stripped)
        if item:
            flush()
            kind, start, current = "item", number, [stripped[item.end():]]
            continue
        if not current:
            kind, start = "paragraph", number
        current.append(stripped)
    flush()
    return out, figures, headings


def check(path):
    text = open(path, encoding="utf-8").read()
    lines = text.splitlines()
    if lines and lines[0].strip() == "---":
        end = next((i for i, l in enumerate(lines[1:], 1) if l.strip() == "---"), 0)
        lines = [""] * (end + 1) + lines[end + 1:]
    prose, figures, headings = blocks(lines)

    measured, paragraph_words, long_paragraphs, words = [], [], [], 0
    for kind, start, raw in prose:
        body = clean(raw)
        count = len(body.split())
        words += count
        if kind == "paragraph":
            paragraph_words.append(count)
            if count >= PARAGRAPH_MAX:
                long_paragraphs.append((start, count))
        for sentence in sentences(body):
            measured.append((len(sentence.split()), sentence.count(","), start, sentence))

    result = {"path": path, "words": words, "sentences": len(measured), "warnings": [], "notes": []}
    if measured:
        lengths = [m[0] for m in measured]
        result["sentence_mean"] = round(statistics.mean(lengths), 1)
        result["long_share"] = round(sum(n >= LONG for n in lengths) / len(lengths), 3)
        result["commas_per_sentence"] = round(sum(m[1] for m in measured) / len(measured), 2)
        result["longest"] = [
            {"line": s, "words": n, "opening": " ".join(t.split()[:12])}
            for n, _, s, t in sorted(measured, key=lambda m: -m[0])[:SHOW]
            if n >= LONG
        ]
    if paragraph_words:
        result["paragraph_mean"] = round(statistics.mean(paragraph_words), 1)
    result["long_paragraphs"] = [{"line": s, "words": n} for s, n in long_paragraphs]
    result["figures"] = len(figures)
    result["deepest_heading"] = max((h[1] for h in headings), default=0)

    for key, limit in TARGETS.items():
        if key in result and result[key] > limit:
            result["warnings"].append(key)
    if result["long_paragraphs"]:
        result["warnings"].append("long_paragraphs")
    deep = [h for h in headings if h[1] > HEADING_DEPTH]
    if deep:
        result["warnings"].append("deep_headings")
        result["deep_headings"] = [{"line": n, "heading": t} for n, _, t in deep]

    spelling = []
    for number, line in enumerate(lines, 1):
        if line.lstrip().startswith(("```", "~~~")):
            continue
        for pattern, fix in BRITISH.items():
            for match in re.finditer(rf"\b{pattern}\b", line, flags=re.I):
                spelling.append({"line": number, "found": match.group(0),
                                 "use": re.sub(rf"^{pattern}$", fix, match.group(0), flags=re.I)})
    if spelling:
        result["warnings"].append("spelling")
        result["spelling"] = spelling

    links = broken_links(path, lines)
    if links:
        result["warnings"].append("broken_links")
        result["broken_links"] = links

    # A section with many words and no figure is a note, not a warning: only a person can say
    # whether its subject has a shape worth drawing.
    sections, bare = [], []
    h2 = [(n, t) for n, level, t in headings if level == 2]
    for i, (n, title) in enumerate(h2):
        stop = h2[i + 1][0] if i + 1 < len(h2) else len(lines) + 1
        section_words = sum(len(clean(raw).split()) for _, s, raw in prose if n < s < stop)
        has_figure = any(n < f < stop for f in figures)
        sections.append(title)
        if section_words >= SECTION_FIGURE_WORDS and not has_figure:
            bare.append({"line": n, "section": title, "words": section_words})
    if bare:
        result["notes"].append("sections_without_figures")
        result["sections_without_figures"] = bare
    return result


def report(result):
    out = [f"{result['path']}  {result['words']:,} words, {result['sentences']} sentences"]
    if not result["sentences"]:
        return "\n".join(out + ["  no prose to measure"])

    def row(label, value, target, key):
        flag = "warn" if key in result["warnings"] else "ok"
        out.append(f"  {label:<12}{value:<34}{target:<26}{flag}")

    row("sentences", f"{result['sentence_mean']} words on average",
        f"target {TARGETS['sentence_mean']:g} or fewer", "sentence_mean")
    row("long", f"{result['long_share']:.0%} at {LONG} words or more",
        f"target {TARGETS['long_share']:.0%} or fewer", "long_share")
    row("commas", f"{result['commas_per_sentence']} a sentence",
        f"target {TARGETS['commas_per_sentence']:g} or fewer", "commas_per_sentence")
    if "paragraph_mean" in result:
        row("paragraphs", f"{result['paragraph_mean']} words on average",
            f"target {TARGETS['paragraph_mean']:g} or fewer", "paragraph_mean")
    row("headings", f"deepest level {result['deepest_heading']}", f"target {HEADING_DEPTH} or fewer", "deep_headings")
    out.append(f"  {'figures':<12}{result['figures']}")
    for item in result.get("longest", []):
        out.append(f"    a sentence of {item['words']} words, in the block at line {item['line']}: {item['opening']} ...")
    for item in result["long_paragraphs"]:
        out.append(f"    a paragraph of {item['words']} words at line {item['line']}")
    for item in result.get("deep_headings", []):
        out.append(f"    a heading deeper than level {HEADING_DEPTH} at line {item['line']}: {item['heading']}")
    by_line = {}
    for item in result.get("spelling", []):
        by_line.setdefault(item["line"], []).append(f"{item['found']} -> {item['use']}")
    for line, fixes in by_line.items():
        out.append(f"    spelling at line {line}: {', '.join(dict.fromkeys(fixes))}")
    for item in result.get("broken_links", []):
        out.append(f"    a broken link at line {item['line']}: {item['link']} ({item['why']})")
    for item in result.get("sections_without_figures", []):
        out.append(f"    note, line {item['line']}: '{item['section']}' has {item['words']} words and no figure")
    return "\n".join(out)


def files(paths):
    for path in paths:
        if os.path.isdir(path):
            for dirpath, dirnames, filenames in os.walk(path):
                dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS)
                for name in sorted(filenames):
                    if name.endswith(".md"):
                        yield os.path.join(dirpath, name)
        else:
            yield path


def main(argv):
    parser = argparse.ArgumentParser(description="Measure Markdown prose against the authorship voice.")
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--json", action="store_true", help="print the measurements as JSON")
    parser.add_argument("--strict", action="store_true", help="exit 1 if any file has a warning")
    args = parser.parse_args(argv[1:])
    results = [check(path) for path in files(args.paths)]
    warned = sum(1 for r in results if r["warnings"])
    if args.json:
        print(json.dumps(results, indent=2))
    else:
        print("\n\n".join(report(r) for r in results))
        print(f"\n{len(results)} file(s), {warned} with warnings")
    return 1 if args.strict and warned else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
