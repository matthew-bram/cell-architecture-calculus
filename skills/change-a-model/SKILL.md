---
name: change-a-model
description: Carry a change in an annotated design into its model in the cell calculus by governance, never by edit: a changed row becomes a successor with the old theorem deprecated or the old example retired, each naming its successor, the date and the reason; a removed row is retired, never deleted; a renamed thing keeps its old name as a deprecated alias; a changed event gets a new version with the upcaster kept total; the model header records the supersession and the review line is left for the reviewer to sign again; the build and the gate go green and the changelog gets its row. Use this skill whenever a design, a table, a rule, an example, a field, a name or a threshold changes after a model exists, whenever someone asks to update, revise, rename, fix, remove, deprecate, retire, migrate or version anything in a model or its design, whenever the review check fails because a design changed, and whenever a rejected trace or a review finding sends a change back to the design, even if the words "supersede", "governance" or "Lean" are never said. Do not use it for the first model of a design; that is model-a-cell.
---

# Change a model

A model under this method is never edited in the way code is edited, because every theorem and example in it is a claim someone reviewed and a test someone's code passes by id. Deleting one deletes the evidence; changing one in place changes what an id means. So a change is a supersession: the new claim arrives beside the old, the old says what replaced it and when and why, and everything that cited the old keeps working while it warns. The review line, which certified the old model against the old design, is not yours to re-sign; the design's hash changed, the check fails, and the reviewer signs again after reading what changed.

Paths below are relative to this skill's directory; the package root, two levels up, holds `docs/`, `tools/` and `examples/`. Read first, every time:

1. `../../docs/style-guide.md`, section 11, governance, and section 4's last line, where the deprecated attribute goes.
2. `../../examples/library/Library/Governance.lean` and the deprecated attribute in `Journeys.lean`: the worked answer, a theorem superseded by name, an example retired with its successor and reason, an event version kept with a total upcaster, and the project header's `superseded` list.
3. `references/checklist.md`, the kinds of change and what each does to the model.

## The procedure

### Stage 1: the diff, by row

Put the old and the new annotated design side by side and list every row that differs, by table and id: added, changed, removed, renamed. A change the design does not state is not a change you make; a change in the design's prose with no row behind it is a gap for the annotate-a-design skill first.

Acceptance: a list of rows, each tagged with its kind. Nothing else moves.

### Stage 2: one move per kind

For each row, the move the checklist gives its kind, and no other:

- **An added row** is new code: a constructor, a branch, an example with its theorem, written as model-a-cell writes them.
- **A changed row** is a successor. A changed example gets a new id and a new value with its `_holds` theorem; the old example stays, retired in its `GovernedExample` with `supersededBy`, `retiredOn` and `because`. A changed universal claim gets a new theorem; the old keeps its name and statement and gets `attribute [deprecated <successor> (since := "<date>")]` beside it. A changed Decide branch changes the body of `decide`, which is what the examples and mutants then judge; the example that pinned the old branch is retired for one that pins the new.
- **A removed row** is retired the same way, with no successor named and the reason given. The coverage theorems then say whether the live set still reaches every kind; if not, that is the design's gap, reported.
- **A renamed thing** keeps its old name as a deprecated alias of the new, never a changed statement.
- **A changed event's fields** are a new event version: the old version type stays, the sum over versions gains a constructor, and the upcaster stays total, which the build checks by exhaustiveness.
- **A changed threshold or contract** is a changed value in a `Contracts` function or an attribute, with the old recorded in the model header's `superseded` list.
- **A move to a new release of the calculus** is a change of `rev` in `lakefile.toml` to the new tag and `lake update cell-calculus`, which pins the commit in the manifest; the release's deprecations then warn, each naming the successor the project moves to, and the changelog row names both releases. Never a branch, and never done in passing while carrying another change.

Then the project's header: one row in `superseded` per supersession, old name, new name, date. Then the mutants: a mutant whose text no longer matches is rewritten to the new text, never dropped; the gate's score must not fall.

Acceptance: `lake build` green with only the deprecation warnings you introduced, each naming its successor; `lake exe fixtures` renders the live set; the gate green with every mutant still killed; the review check **fails**, naming the design's new hash, if the line had been signed, and keeps warning if the model was never reviewed; either is the state you leave it in, because the signature is not yours.

### Stage 3: what you leave for people

The review line is the reviewer's. Report the design's new hash and what signing would write, and stop. Add the changelog row to the project's changelog if it has one, in the project's form, saying what changed and which document owns it.

## What you never do

- Delete a theorem, an example, a constructor or an event version. Retire, deprecate, alias, version.
- Edit an example's expectation in place, or a theorem's statement in place.
- Re-sign the review line, or change the recorded hash to make the check pass.
- Make a change the design does not state, including the plausible consequence of the one it does.

## The report

End with a short report, in prose: each row of the diff and the move it got; what was deprecated or retired and for what; the build, the fixtures, the gate and the review check's outcomes; and what the reviewer signs after reading.
