#!/usr/bin/env python3
"""Lay down a new project package on the cell calculus.

Usage:
  python3 start.py --package Clinic --dir path/to/clinic
                   [--name "Clinic scheduling"] [--boundaries clinic,billing]
                   [--design designs/scheduling.md]
                   [--git URL --rev REV | --calculus path/to/cell-calculus]

By default the package requires the calculus from its git repository at
its newest release tag, so nothing has to be cloned beside the project:
`lake build` fetches it into the project's own `.lake/packages` and the
manifest pins the commit. A local checkout is used instead when
`--calculus` names it, which is what the example inside the
cell-architecture-calculus repository does.

Writes the package's build file in the shape docs/getting-started.md gives,
its root module, `Architecture.lean` with a placeholder principal to replace
from the design corpus, `Governance.lean` with an unreviewed review line,
the two map modules empty, an empty generators executable, an empty trace
checker, an empty mutants file, the two tool scripts the gates run, and a
CI workflow. Nothing here is a cell: the package builds with no warnings
and holds no model until the first design is annotated and modelled.
Refuses to overwrite an existing directory.
"""
import argparse, json, os, re, shutil, subprocess, sys

REPOSITORY = "https://github.com/matthew-bram/cell-architecture-calculus.git"

def die(msg): print("error:", msg); sys.exit(2)

def newest_release(git):
    """The newest v<major>.<minor>.<patch> tag on the remote, or None."""
    try:
        out = subprocess.run(["git", "ls-remote", "--tags", git], capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode != 0:
        return None
    tags = re.findall(r"refs/tags/(v\d+\.\d+\.\d+)$", out.stdout, re.M)
    if not tags:
        return None
    return max(set(tags), key=lambda t: tuple(int(n) for n in t[1:].split(".")))

def main():
    a = argparse.ArgumentParser()
    a.add_argument("--package", required=True, help="the Lean package name, PascalCase, e.g. Clinic")
    a.add_argument("--dir", required=True, help="the directory to create")
    a.add_argument("--calculus", help="a local checkout of the cell-calculus package, instead of the git require")
    a.add_argument("--git", default=REPOSITORY, help="the repository the package requires the calculus from")
    a.add_argument("--rev", help="the tag to require; defaults to the newest release tag on that repository, never a branch")
    a.add_argument("--name", help="the project's name in prose; defaults to the package name")
    a.add_argument("--boundaries", help="comma-separated trust boundaries, lowerCamel, e.g. clinic,billing; omit if none")
    a.add_argument("--design", default="designs/README.md", help="path of the first design, relative to the repository root")
    o = a.parse_args()
    if not re.fullmatch(r"[A-Z][A-Za-z0-9]*", o.package): die("--package must be PascalCase, a Lean module name")
    bounds = [b.strip() for b in o.boundaries.split(",")] if o.boundaries else []
    for b in bounds:
        if not re.fullmatch(r"[a-z][A-Za-z0-9]*", b): die(f"boundary {b!r} must be lowerCamel, a constructor name")
    name = o.name or o.package
    d = os.path.abspath(o.dir)
    if os.path.exists(d): die(f"{d} exists; this script never overwrites")
    here = os.path.dirname(os.path.abspath(__file__)); package_root = os.path.normpath(os.path.join(here, "..", "..", ".."))
    if o.calculus:
        calc = os.path.abspath(o.calculus)
        if not os.path.isfile(os.path.join(calc, "lakefile.toml")): die(f"no lakefile.toml in {calc}")
        rel_calc = os.path.relpath(calc, d)
        root = os.path.commonpath([d, calc]); rel_root = os.path.relpath(root, d); cwd = os.path.relpath(d, root)
        require = f'path = "{rel_calc}"'
        cell_lean = f"{rel_calc}/CellCalculus/Cell.lean"
        toolchain = open(os.path.join(calc, "lean-toolchain")).read()
        rev = None
    else:
        rev = o.rev or newest_release(o.git)
        if not rev: die(f"could not read a release tag from {o.git}; pass --rev v<version>")
        if o.rev and not re.fullmatch(r"v\d+\.\d+\.\d+", o.rev): die("--rev must be a release tag, v<major>.<minor>.<patch>, never a branch")
        rel_root, cwd = ".", "."
        require = f'git = "{o.git}"\nrev = "{rev}"\nsubDir = "cell-calculus"'
        cell_lean = ".lake/packages/cell-calculus/cell-calculus/CellCalculus/Cell.lean"
        toolchain = open(os.path.join(package_root, "cell-calculus", "lean-toolchain")).read()
    os.makedirs(os.path.join(d, o.package)); os.makedirs(os.path.join(d, "tools"))
    os.makedirs(os.path.join(d, ".github", "workflows"))
    for tool in ("mutants.py", "review-check.py"):
        shutil.copy(os.path.join(package_root, "tools", tool), os.path.join(d, "tools", tool))
    slug = re.sub(r"(?<!^)(?=[A-Z])", "-", o.package).lower()
    P = o.package
    w = lambda p, s: open(os.path.join(d, p), "w").write(s)

    w("lean-toolchain", toolchain)
    w("lakefile.toml", f'''# The {name} package: its maps, its cells with their examples, journeys,
# promises and governance, built on the generic cell calculus.
name = "{slug}"
defaultTargets = ["Maps", "{P}", "fixtures", "replay"]

# The data dictionary is a build check: every constructor and field carries
# a doc comment, or the build warns.
[leanOptions]
linter.missingDocs = true

[[require]]
name = "cell-calculus"
{require}

# The two maps the method starts from: the journeys as checked DAGs with
# the paths table and the direction rule, and the context map beside it.
[[lean_lib]]
name = "Maps"
roots = ["JourneyMap", "ContextMap"]

# The model: one module per cell or slice, then journeys, envelopes,
# inputs, policy, promises and governance, as the style guide lays out.
[[lean_lib]]
name = "{P}"

# The generators: the live examples rendered as Gherkin and JSON fixtures.
[[lean_exe]]
name = "fixtures"
root = "Fixtures"

# The trace checker: traces in the wire shape replayed into the model.
[[lean_exe]]
name = "replay"
root = "Replay"
''')
    w(f"{P}.lean", f'''import {P}.Architecture
import {P}.Governance
/-!
# The {name} model

One project's instantiation of the cell calculus: its principal{", its boundaries" if bounds else ""}
and, as they are modelled, its cells with their examples as theorems, its
journeys, envelopes, inputs, policy, promises and governance. Every theorem
here is a computation on this project's values, discharged by `decide` or
`rfl`; the universal theorems are in the calculus.
-/
''')
    bound_block = ""
    if bounds:
        constructors = "\n".join(
            f"  /-- The {b} boundary, as the corpus names it; say here what it holds and what it never sees. -/\n  | {b}"
            for b in bounds)
        bound_block = f'''
/-- The trust boundaries of the architecture: an identifier that must not
    cross one is indexed by the boundary that knows it. From the design
    corpus; add a constructor when the corpus adds a boundary, never remove
    one. -/
inductive Boundary
{constructors}
  deriving DecidableEq, Repr

/-- An ID the project's alias map maps, indexed by the boundary that knows
    it: the subject of every event this project records. A record in one
    boundary cannot be built with another boundary's ID; the alias map is
    the only way across. -/
abbrev SubjectId (boundary : Boundary) := BoundedId Boundary boundary
'''
    w(f"{P}/Architecture.lean", f'''import CellCalculus
/-!
# What this project supplies

The principal the calculus is generic over{", the boundaries this project's IDs are indexed by," if bounds else ","}
and the fixture values the examples share.
-/

/-- Who a person or system is when they act, in this project's terms: what
    the identity capability answers. Replace the one field with what the
    design corpus says identifies an actor, a card and a role, a user and a
    scope, and give each field its dictionary comment. An actor policy
    matches on it. -/
structure Principal where
  /-- The actor's identifier; a placeholder until the corpus names the fields. -/
  id : String
  deriving DecidableEq, Repr

/-- This project's architecture, for the calculus: its principal, with the
    equality and printing instances. -/
instance : Architecture :=
  {{ Principal := Principal, principalDecEq := inferInstance, principalRepr := inferInstance }}
{bound_block}
/-- The zero instant, for examples that do not read the clock. -/
def epoch : Instant := ⟨0⟩

/-- The run the examples share. -/
def firstRun : RunId := ⟨"run-1"⟩
''')
    w(f"{P}/Governance.lean", f'''import {P}.Architecture
/-!
# This model's governance

The review line and what the model has superseded. A theorem or an example
is never deleted here; it is superseded or retired with its successor named.
-/

/-- The project's header: one review line per design. The first says
    "unreviewed" until a reviewer reads the first module against its
    design; the review check warns until then and fails if the design
    changes after. A second design gets a second line. -/
def projectHeader : ProjectHeader :=
  {{ reviews := [ {{ design := "{o.design}", designHash := "unreviewed", reviewer := "", reviewedOn := "" }} ]
  , superseded := [] }}
''')
    w("JourneyMap.lean", '''import CellCalculus
/-!
# The journey map, as checked

Empty until the corpus's journey sections are transcribed here: the
capabilities with their zones, each journey as a DAG of steps from its
Steps table, the matrix rows, the paths table with the direction rule, and
one theorem per claim, each by `decide`.
-/
''')
    w("ContextMap.lean", '''import CellCalculus
import JourneyMap
/-!
# The context map, as checked

Empty until the journey map exists: one context per cell with its
subdomain kind, one relationship per arrow upstream to downstream, and the
coverage, translation and heuristic theorems, each by `decide`.
-/
''')
    w("Fixtures.lean", f'''import {P}
/-!
# This project's generators

`lake exe fixtures` renders every cell registered below. The renderer is
`Render` in the calculus and is generic over the instances a cell's module
gives its types; a new cell adds one line to `cells`.
-/

/-- Every cell whose views the build renders. A new cell adds one line. -/
def cells : List Render.Registered := []

/-- The entry point: render every registered cell into `generated/`. -/
def main : IO UInt32 := Render.run cells "{cell_lean}"
''')
    w("Replay.lean", f'''import {P}
/-!
# This project's trace checker

`lake exe replay <trace.json>...` replays every trace named against the
checker its `cell` or `run` field names, prints one line per trace, and
exits non-zero if any is rejected. The checker is `Replay` in the calculus
and is generic over the instances a cell's module gives its types; a new
cell adds one line to `checkers`.
-/

/-- Every cell and run whose traces the checker accepts. A new cell adds one line. -/
def checkers : List Replay.Registered := []

/-- The entry point: check every trace file named on the command line. -/
def main (args : List String) : IO UInt32 :=
  Replay.run checkers "{cell_lean}" args
''')
    w("mutants.json", json.dumps({"package": slug, "root": rel_root, "cwd": cwd, "target": P,
        "ignore": [".git", ".github", "generated", "tools"], "mutants": []}, indent=1) + "\n")
    wd = f"    defaults:\n      run:\n        working-directory: {cwd}\n" if cwd != "." else ""
    prefix = cwd + "/" if cwd != "." else ""
    w(".github/workflows/model.yml", f'''# The {name} model's build: the kernel checks every theorem, the generators
# render the views and the committed ones must not change, the review line
# is checked against the design, and the mutation score gates. Once the
# first traces are recorded, add a step that replays the known-good ones
# and must pass, and one that replays the known-bad ones and must fail,
# as the worked example's workflow does.
name: model

on:
  push:
  pull_request:

jobs:
  model:
    runs-on: ubuntu-24.04
{wd}    steps:
      - uses: actions/checkout@v5
      - name: Install Lean's version manager
        run: |
          curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y --default-toolchain none
          echo "$HOME/.elan/bin" >> "$GITHUB_PATH"
      - name: Build the model
        run: lake build
      - name: Render the views and check they are the committed ones
        run: |
          lake exe fixtures
          git diff --exit-code -- {prefix}generated/
      - name: Check the review line
        run: python3 tools/review-check.py {P}/Governance.lean .
      - name: Run the mutation gate
        run: python3 tools/mutants.py mutants.json
''')
    w(".gitignore", ".lake/\n")
    print(f"wrote {d}")
    if not o.calculus: print(f"the package requires cell-calculus at {rev} from {o.git}; the first build fetches it and the manifest pins the commit")
    print(f"next: replace Principal's fields in {P}/Architecture.lean from the design corpus, then")
    print(f"  cd {o.dir} && lake build && lake exe fixtures")
    print(f"  python3 tools/review-check.py {P}/Governance.lean .")
    print(f"  python3 tools/mutants.py mutants.json")

if __name__ == "__main__":
    main()
