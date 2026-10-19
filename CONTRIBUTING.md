# Contributing

How work in this repository is done. The [README](README.md) is the index; [docs/style-guide.md](docs/style-guide.md) is the standard every model is held to.

## The rules

- **The style guide is the standard.** Names, comments, proofs, the shapes a model may use, the annotation grammar, what a reviewer checks. A change to a model follows it; a change to the guide is a decision with a changelog row.
- **The calculus changes by supersession, never by edit.** A public shape that changes keeps its old name, deprecated with its successor and the date; a new shape is additive. The version is in `cell-calculus/lakefile.toml` and moves with each supersession. The calculus's own mutants, in `cell-calculus/mutants.json`, gate it on its own.
- **The design owns meaning.** A model never invents a row, a field type, an example or a sentence its design does not state; a gap is reported in the design's open items. The example's corpus and design are in-repository so that every row the model carries has a sentence to point at.
- **A review is a person's.** The review line in a project's header is signed by a reviewer who has read the model against the design, never by a build and never by an agent. The example's line stays unsigned on purpose: the line and the check are there for a project's designs, where the gate is a person's.
- **One commit per step**, with a message that says what changed and why, in prose.

## The gates

Every change passes all of them, and CI runs them on every push.

```
export PATH="$HOME/.elan/bin:$PATH"
cd cell-calculus && lake build && cd ..                        # the calculus, no warnings
python3 tools/mutants.py cell-calculus/mutants.json            # 7 of 7
cd examples/library
lake build && lake exe fixtures                                # the example and its views; generated/ is committed and must not change unless the model did
python3 ../../tools/review-check.py Library/Governance.lean .  # warns, by decision
python3 ../../tools/mutants.py mutants.json                    # 10 of 10
lake exe replay traces/circulation-good.json traces/borrow-run-good.json traces/circulation-recorded.json
lake exe replay traces/circulation-retry-twice.json traces/circulation-not-understood.json traces/borrow-run-backwards.json traces/borrow-run-stray.json   # must be rejected
python3 -m unittest discover -s impl -v
python3 impl/record_trace.py                                   # traces/circulation-recorded.json is committed and must not change unless the implementation did
```

A warning in a build is a defect to fix, not to report around: the missing-docs linter is on in both packages, and an undocumented constructor fails review the same as an undocumented type.

## Branches, pull requests and releases

`main` is protected. Nothing is pushed to it; every change arrives as a pull request from a branch named `feature/<name>`, and a pull request from any other branch fails its first check. A pull request merges when a maintainer has approved it, every conversation on it is resolved, and the four CI jobs are green: the branch name, the scrub gate, the calculus and the example. Merges are squashes, so one pull request is one commit on `main` and one step in the repository's history; write the pull request's title and description as the commit message, in prose, saying what changed and why. The merged branch is deleted.

A pull request that changes a public shape of the calculus is a supersession, never an edit: the old name stays, deprecated with the date and its successor, the version in `cell-calculus/lakefile.toml` moves, and `CHANGELOG.md` gets its row. A pull request that adds a shape is additive and carries its universal theorem, its doc comments and a mutant its theorem kills. A pull request that changes the example follows the style guide and leaves every gate green, with the generated views and the recorded trace regenerated if the model or the implementation changed.

A release is a tag. When `main` holds what the next release should, a maintainer adds the row to `CHANGELOG.md`, tags the commit `v<major>.<minor>.<patch>` and pushes the tag; the release workflow publishes the GitHub release with notes generated from the merged pull requests. Only maintainers can create a `v*` tag. The repository's version moves by the usual rule: the major for a change a project building on a tag must act on, the minor for a shape added or a document rewritten, the patch for a fix. The calculus's own version in its build file moves independently, by supersession. A project requires the calculus at a tag, never a branch, so a release without its tag on the remote cannot be built on.

Maintainers are listed in `.github/CODEOWNERS`. A maintainer may merge their own pull request once the checks are green, which is the one bypass the protection allows; everything else goes through review.

## Adding a cell to the example

1. Write its design to the tables of style guide section 8, under `examples/library/designs/`, with a sentence in the prose for every row.
2. Add its rows to the corpus where the maps read them: the capability map, the paths table, the journeys that pass through it. Rebuild the maps and let the theorems say what no longer holds.
3. Transcribe the tables into a module under `Library/`, one row to one definition, in the shape of `Circulation.lean`: the five types, the cell, the examples named by id with their `_holds` theorems, the `Kinded`, `WireCodec`, `JsonEncode`, `JsonDecode` and `Describe` instances, the coverage theorems.
4. Register it in `Fixtures.lean` and `Replay.lean`, one line each.
5. Add three to six mutants for it to `mutants.json`, one per branch where a change would be plausible, and run the gate. A mutant that survives is a missing example; add the row to the design first, then the example.
6. Add a review line for the design to `Governance.lean`, unreviewed.

## Proposing a shape to the calculus

A project introduces no new generic shape. If a model needs one the calculus lacks, open an issue that states the shape, the universal theorem it would carry and the project that needs it. A shape that is accepted arrives as a new module or a new declaration, additive, with its theorem, its doc comments, and a mutant in `cell-calculus/mutants.json` that its theorem kills; a shape that replaces one arrives beside the old, which is deprecated with the date and its successor's name. The version in `cell-calculus/lakefile.toml` moves, and the changelog gets its row.

## Building on the calculus from another repository

A project's `lakefile.toml` requires the calculus over git with `subDir = "cell-calculus"` and a tag as `rev`, never a branch, so that `lake build` fetches it into the project's own `.lake/packages` and the manifest pins the commit. The example inside this repository requires it by path instead. A move to a newer tag is a change like any other: the deprecations warn, each naming the successor the project moves to.
