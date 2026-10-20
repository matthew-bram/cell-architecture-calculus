---
name: start-a-project
description: Set up a new project package on the cell calculus, the Lean 4 scaffolding in `cell-calculus`, from a design corpus: the package's build file requiring the calculus, its `Architecture` with the project's principal and, where the architecture has trust boundaries, its boundary type and bounded ID, an unreviewed review line, an empty generators executable and an empty mutation gate, building with no warnings and holding no cell yet. Use this skill whenever someone wants to begin modelling a system, product, service or domain with the calculus, start or bootstrap or scaffold a Lean model for a new project, asks where to start, has an architecture or design corpus and no package to model it in, or wants a second project beside an existing one, even if the words "Lean", "calculus" or "package" are never said. Do not use it to add a cell to a package that exists; that is model-a-cell.
---

# Start a project

You are laying down the one package a project's whole model will live in, and fixing the two things the calculus is generic over: who acts, and what an event is about. Everything after this, every cell, journey and promise, builds on those two types, so a wrong principal or an invented boundary here is a wrong type everywhere later. The package you leave behind holds no cell. That is the point: a project starts with a building, empty, reviewed-nothing-yet package, and its first cell arrives by the model-a-cell skill from an annotated design.

Paths below are relative to this skill's directory; the package root, two levels up, holds `cell-calculus/`, `docs/`, `tools/` and `examples/`. Read first, every time:

1. `../../docs/style-guide.md`, sections 1, 2 and 6: what goes where, how things are named, and why a field whose domain admits a value its meaning forbids is a wrong type; then `../../docs/getting-started.md`, sections 2 and 3, the build file and the two types a project supplies.
2. `../../cell-calculus/CellCalculus.lean`, the overview, then the doc comments in `CellCalculus/Architecture.lean` and `CellCalculus/Boundaries.lean`: what a project supplies and what it opts into.
3. `../../examples/library/Library/Architecture.lean`: the worked answer, a principal that is a card with a role, five zones, and the patron ID as a bounded ID.

## The procedure

### Stage 1: five things from the corpus

Read the design corpus you are given, the architecture document, the capability map, the product vision, whatever exists, for exactly these, and write down where each came from:

1. **The package name.** PascalCase, from the product or program's name: `Library`, `Clinic`. It is a Lean module name and it will be in every import.
2. **Where the calculus comes from.** By default the package requires it from its git repository, and `lake build` fetches it into the project's own `.lake/packages` and pins the commit in the manifest, so nothing is cloned beside the project and no path is needed. Only when working inside the cell-calculus repository itself, or on a checkout the owner names, does the package require it by path. Never copy the calculus into the project.
3. **The principal.** Who a human or system actor is when they act, as the identity capability answers it: a seat with a role, a user with a scope, a staff member with a role. Its fields, each with a meaning and a domain. A field that is one of a fixed few things is a sum type, not a string. If the corpus does not say who acts, the placeholder stays and the report says so; do not invent an identity model.
4. **The boundaries, if any.** The trust boundaries an identifier must not cross: zones, tenants, regions, under whatever name the architecture uses. An architecture with one boundary has none to declare. If the corpus names none, there are none, and the events' subject is whatever the corpus says an event is about, or `Unit` until it does. Never invent a boundary to have one.
5. **The first design's path.** The document the first cell will be modelled from, relative to the repository root, so the review line names it from day one. If no design exists yet, the path where it will be.
6. **The calculus release.** The package requires the calculus at a tag, and the script's default is the newest release tag on the calculus's repository, which it reads from the remote, so the project builds on a released calculus. Keep that default unless the owner names another release; never pass a branch, because a branch moves and a tag does not. The report states the release the package requires. A project that later needs a newer release moves to it through change-a-model, not by editing the require in passing.

Acceptance: each of the six has a source in the corpus, a default the report names, or is explicitly marked as not given. A principal or a boundary you cannot point to a sentence for is not written.

### Stage 2: the package

Run the script, which writes the files and refuses to overwrite anything:

```
python3 scripts/start.py --package <Package> --name "<the project's name>" \
  --dir <where the package goes> [--boundaries <a,b,c>] --design <first design's path> \
  [--rev v<release>] [--calculus <a local checkout, instead of the git require>]
```

It writes `lakefile.toml` in the shape `docs/getting-started.md` gives, requiring the calculus from its repository, or by relative path when a checkout was given; `<Package>.lean`, the root; `<Package>/Architecture.lean` with a placeholder principal, and the boundary type and `SubjectId` when boundaries were given; `<Package>/Governance.lean` with an unreviewed review line naming the first design; `JourneyMap.lean` and `ContextMap.lean`, empty until the two map skills fill them; `Fixtures.lean` and `Replay.lean` with empty registration lists; `mutants.json` with no mutants and the right root, working directory and target; the two tool scripts the gates run, under `tools/`, so the project owns its gates; a CI workflow; and `lean-toolchain` copied from the calculus so the two agree.

### Stage 3: the architecture

Open `<Package>/Architecture.lean` and replace the placeholder principal with the corpus's: the fields with their dictionary comments, a sum type for each field that is one of a fixed few things, declared above `Principal` with its own comment. If boundaries were given, rename `SubjectId` to what the corpus calls the thing an event is about, `PatronId`, `PatientId`, and keep its comment true. Every declaration carries a doc comment; the reviewer counts them.

Then the four commands, from the package's directory; the tools are the package's own:

```
export PATH="$HOME/.elan/bin:$PATH"
lake build
lake exe fixtures
python3 tools/review-check.py <Package>/Governance.lean .
python3 tools/mutants.py mutants.json
```

The first build fetches the calculus from its repository over the network, unless a checkout was given.

Acceptance: the build succeeds with no warnings; the generators create `generated/` and write nothing, since no cell is registered; the review check warns that the model is unreviewed; the gate prints a score of zero of zero. A warning in the build is a defect to fix, not to report around.

## What you never do

- Write a cell, an example or a theorem about the domain here. The package is empty on purpose; the first cell comes from an annotated design through model-a-cell.
- Invent a boundary, a role or a principal field the corpus does not state. A placeholder with a report beats a plausible guess, because the guess becomes the index on every event.
- Copy the example project and edit it down. The script writes exactly what a project needs and nothing of the example's domain.
- Add a shape to the generic package, or copy the calculus into the project. The require is by git, or by path to a checkout.

## The report

End with a short report, in prose: the six things and where each came from, the calculus release among them, or that the corpus did not give it; what remains a placeholder for the owner to confirm; the four commands' outcomes; and what comes next, which is annotating the first design.
