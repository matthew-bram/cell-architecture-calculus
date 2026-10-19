#!/usr/bin/env python3
"""The review line.

A project's header names, for each design the model was reviewed against,
the document's path and its content hash at review time. This check
recomputes each hash. If the header says "unreviewed" it warns; if the header names a hash
and the document has changed since, it fails: drift between prose and
model is visible the day it happens.

Usage: python3 review-check.py <governance module> <design root>

The module is the Lean file holding the `ProjectHeader` value, one review
line per design; the design root is the directory the design paths are
relative to. The worst outcome over the lines is the exit code.
"""
import hashlib, os, re, sys

def check(design, recorded, root):
    path = os.path.join(root, design)
    if recorded == "unreviewed":
        if not os.path.exists(path):
            print(f"warning: model not yet reviewed; {design} does not exist yet under {root}"); return 0
        actual = hashlib.sha256(open(path, "rb").read()).hexdigest()[:16]
        print(f"warning: model not yet reviewed against {design} (hash now {actual})"); return 0
    if not os.path.exists(path):
        print(f"FAIL: design document not found: {path}"); return 1
    actual = hashlib.sha256(open(path, "rb").read()).hexdigest()[:16]
    if recorded != actual:
        print(f"FAIL: {design} changed since review: recorded {recorded}, now {actual}"); return 1
    print(f"ok: model reviewed against {design} at {actual}"); return 0

def main(argv):
    if len(argv) != 3:
        print(__doc__); return 2
    module, root = argv[1], argv[2]
    src = open(module).read()
    lines = re.findall(r'design\s*:=\s*"([^"]+)",\s*designHash\s*:=\s*"([^"]+)"', src, re.S)
    if not lines:
        print(f"no review line found in {module}"); return 1
    return max(check(design, recorded, root) for design, recorded in lines)

if __name__ == "__main__":
    sys.exit(main(sys.argv))
