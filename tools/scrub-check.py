#!/usr/bin/env python3
"""The scrub gate.

The repository is about the method and the example, and nothing in it names
a tool, a host, a person or another project's domain. This check reads
every tracked text file and fails on any pattern below, naming the file
and the line. It runs in CI so that the rule holds after every change.

Usage: python3 tools/scrub-check.py [root]
"""
import os
import re
import sys

PATTERNS = [
    r"claude", r"anthropic", r"gitlab", r"\bcto/",
    r"household", r"enclave", r"personal.?finance", r"\bledger\b", r"caretaker", r"treasurer",
    r"tripwire", r"\bseat-\d", r"earmark",
    r"matthew", r"\bbram\b",
    r"/private/tmp", r"/Users/", r"\{\{FILL-",
]
# The repository's own address is the one place a name belongs.
REPOSITORY = "github.com/matthew-bram/cell-architecture-calculus"
# The maintainers' handles are operational, not authorship, and appear only where GitHub reads them.
ALLOWED = [REPOSITORY, "@matthew-bram"]
SKIP_DIRS = {".git", ".lake", "__pycache__"}
SKIP_FILES = {os.path.join("tools", "scrub-check.py")}
TEXT = {".md", ".lean", ".py", ".json", ".toml", ".yml", ".yaml", ".feature", ".txt", ""}


def main(argv):
    root = os.path.abspath(argv[1] if len(argv) > 1 else os.path.join(os.path.dirname(__file__), ".."))
    pattern = re.compile("|".join(PATTERNS), re.IGNORECASE)
    hits = 0
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            path = os.path.join(dirpath, name)
            rel = os.path.relpath(path, root)
            if rel in SKIP_FILES or os.path.splitext(name)[1] not in TEXT:
                continue
            try:
                lines = open(path, encoding="utf-8").read().splitlines()
            except (UnicodeDecodeError, OSError):
                continue
            for number, line in enumerate(lines, 1):
                scrubbed = line
                for allowed in ALLOWED:
                    scrubbed = scrubbed.replace(allowed, "")
                match = pattern.search(scrubbed)
                if match:
                    hits += 1
                    print(f"{rel}:{number}: {match.group(0)!r} in: {line.strip()[:120]}")
    print(f"\n{hits} hit(s)" if hits else "clean")
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
