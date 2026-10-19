#!/usr/bin/env python3
"""The mutation score as a gate.

Each mutant is one deliberate change to a model. The examples, traces and
theorems must notice: a mutant that builds without error has found a part
of the model nothing pins, and that is a failing test.

Usage: python3 mutants.py <mutants.json>

The file names the package to copy, where in the copy to run `lake`, the
build target, and the mutants: each a name, a file relative to the root,
the text to replace, and its replacement. Every path in the file is
relative to the file's own directory, and `ignore` lists directory names
left out of the copy. The whole root is copied so that a path dependency
inside it is copied with it, the mutant is applied, and
the target built on the copy with the build cache, so only the changed
module and what depends on it rebuild. Exits non-zero if any survives.
"""
import json, os, shutil, subprocess, sys, tempfile

LAKE = shutil.which("lake") or os.path.expanduser("~/.elan/bin/lake")

def run(root, cwd, target, ignore, mutant):
    path = os.path.join(root, mutant["file"])
    src = open(path).read()
    if src.count(mutant["old"]) != 1:
        return "operator did not match once", False
    with tempfile.TemporaryDirectory() as d:
        copy = os.path.join(d, "pkg")
        shutil.copytree(root, copy, ignore=shutil.ignore_patterns(*ignore))
        with open(os.path.join(copy, mutant["file"]), "w") as f:
            f.write(src.replace(mutant["old"], mutant["new"]))
        out = subprocess.run([LAKE, "build", target], cwd=os.path.join(copy, cwd),
                             capture_output=True, text=True)
    errors = [l for l in (out.stdout + out.stderr).splitlines() if l.startswith("error:") and ".lean:" in l]
    return f"{len(errors)} error(s)", bool(errors)

def main(argv):
    if len(argv) != 2:
        print(__doc__); return 2
    spec_path = os.path.abspath(argv[1])
    spec = json.load(open(spec_path))
    here = os.path.dirname(spec_path)
    root = os.path.normpath(os.path.join(here, spec.get("root", ".")))
    cwd, target = spec.get("cwd", "."), spec["target"]
    ignore = ["generated"] + spec.get("ignore", [])
    killed = 0
    print(f"{'mutant':26} {'result':22} verdict")
    for mutant in spec["mutants"]:
        result, dead = run(root, cwd, target, ignore, mutant)
        killed += dead
        print(f"{mutant['name']:26} {result:22} {'killed' if dead else 'SURVIVED'}")
    print(f"\nmutation score: {killed}/{len(spec['mutants'])}")
    return 0 if killed == len(spec["mutants"]) else 1

if __name__ == "__main__":
    sys.exit(main(sys.argv))
