# Working in this repository

What this repository is and how work in it is done, for an agent working beside the owner. Read the README next; it is the index. [CONTRIBUTING.md](CONTRIBUTING.md) carries the rules and the gates in full; this file is the short form and the parts an agent most needs.

## What it is

A method for modelling a system as cells in Lean 4 and holding the code to the model. The generic calculus is `cell-calculus/`, one `lake` package with no dependencies, carrying only universal theorems. The worked example and every skill's golden answer is `examples/library/`, a public library's circulation system written for this repository. The documents that state the method are `docs/`, and the standard every model is held to is `docs/style-guide.md`. The nine skills are `skills/`, one per step of the lifecycle `docs/the-lifecycle.md` lays out that an agent leads or prepares. The two scripts that gate a build and the scrub gate are `tools/`.

## The rules that govern changes

- **The style guide is the standard.** Names, comments, proofs, the shapes a model may use, the annotation grammar, what a reviewer checks. A change to a model follows it; a change to the guide is a decision with a changelog row.
- **The calculus changes by supersession, never by edit.** A public shape that changes keeps its old name, deprecated with its successor and the date; a new shape is additive, with its universal theorem, its doc comments and a mutant its theorem kills. The version is in `cell-calculus/lakefile.toml` and moves with each supersession. The calculus's own mutants, in `cell-calculus/mutants.json`, gate it on its own.
- **The design owns meaning.** A model and a skill never invent a row, a field type, an example or a sentence a design does not state; a gap is reported in the design's open items. A review is prepared by an agent and signed by a person. A green build is not a review, and the example's review line stays unsigned by the owner's decision.
- **The skills change with their evaluations.** Each skill has `evals/evals.json`. A change to a skill is followed by a new run, with and without the skill; the baseline runs on a copy of the repository with `skills/` and `docs/` removed. An assertion is revised only when it encoded a prediction rather than the quality owed, and the commit says so. A skill's goldens point at the example's files by path rather than copying them.
- **Nothing names a tool, a host, a person or another project's domain.** The scrub gate, `tools/scrub-check.py`, reads every text file and fails on any such word; it runs first in CI. A fixture, a design, a comment and this file are all under it.
- **One commit per step**, with a message that says what changed and why, in prose. `main` takes changes only by pull request from a branch named `feature/<name>`, squash-merged, so one pull request is one step. Nothing is pushed by an agent unless the owner asks.

## The commands

```
export PATH="$HOME/.elan/bin:$PATH"
python3 tools/scrub-check.py                                   # clean
cd cell-calculus && lake build && cd ..                        # the calculus, no warnings
python3 tools/mutants.py cell-calculus/mutants.json            # 7 of 7
cd examples/library
lake build && lake exe fixtures                                # the example and its views; generated/ must not change unless the model did
python3 ../../tools/review-check.py Library/Governance.lean .  # warns, by decision
python3 ../../tools/mutants.py mutants.json                    # 10 of 10
lake exe replay traces/circulation-good.json traces/borrow-run-good.json traces/circulation-recorded.json
lake exe replay traces/circulation-retry-twice.json traces/circulation-not-understood.json traces/borrow-run-backwards.json traces/borrow-run-stray.json   # must be rejected
python3 -m unittest discover -s impl -v
python3 impl/record_trace.py                                   # traces/circulation-recorded.json must not change unless the implementation did
```

A warning in a build is a defect to fix, not to report around: the missing-docs linter is on in both packages. The review check warns that the example is unreviewed; that is expected and stays so.

## Releasing

A release is a tag, `v<major>.<minor>.<patch>`, that only a maintainer creates on `main` after adding the changelog row; the release workflow publishes it. A project requires the calculus at a tag, never a branch, so a release without its tag on the remote cannot be built on. The detail is in CONTRIBUTING.

## Where to pick up

The white paper's call to contribute is the direction; the issue forms under `.github/ISSUE_TEMPLATE/` are where a proposed shape, a rejected trace, a second project or a defect arrives. A finding about the corpus or the calculus is first recorded where it was found: a skill's golden, a review packet, or a design's open items.
