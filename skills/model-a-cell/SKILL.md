---
name: model-a-cell
description: Turn an annotated design document into a checked model in the cell calculus, the Lean 4 scaffolding in `cell-calculus`: the cell as three pure functions, its examples as theorems, its journey as a term, its contracts, attributes, actor policy, wire codec and sentences, in a module of the project's package that builds, covers every kind, and passes the mutation gate. Use this skill whenever someone asks to model, transcribe, encode, formalize or "write the Lean for" a cell, a capability, a bounded context, a journey, a slice or a design, whenever a design document with Commands, Decide, React or Examples tables appears, whenever a new cell is to be added to a project package such as `Library`, and whenever examples, contracts, promises or quality attributes are to be derived for a design, even if the word "Lean" or "calculus" is never said.
---

# Model a cell

You are deriving a model from a design, not designing. The design owns meaning; you own structure and behavior; nothing you write means something the design did not say. Two agents given the same design must produce the same module, and a reader who did not watch you must be able to tell what every name means. That is why this skill is strict about what you may use, how you name it, and where you stop.

Paths below are relative to this skill's directory; the package root, two levels up, is the directory holding `cell-calculus/`, `docs/`, `tools/` and `examples/`. Read first, every time, in this order:

1. `../../docs/style-guide.md`, the standard the module is held to: what goes where, names, comments, proofs, the shapes you may and may not use, the quantifier rule, the annotation tables, what a reviewer checks.
2. `references/checklist.md`, the acceptance test at each stage, with the commands.
3. `../../examples/library/designs/circulation.md` and its answer, `../../examples/library/Library/Circulation.lean` with `Journeys.lean`, `Envelopes.lean`, `Inputs.lean`, `Promises.lean` beside it: the golden pair. Your module should look like the answer looks, for the same reasons.

The generic package `../../cell-calculus/` is the only source of shapes. Open the module for each shape you use and read its doc comment; the comment says what the shape is for and what it must never be confused with.

Before stage 1, read which calculus the project builds on: the `cell-calculus` entry of its `lake-manifest.json`, whose `inputRev` is the tag it requires and `rev` the commit pinned. The shapes you may use are that release's, and `.lake/packages/cell-calculus/cell-calculus/` is their source as the project sees them. If the package beside this skill is newer and a shape you need is only there, do not use it: model with what the project has, and report that the project is behind and which shape the newer release would give it; moving the project to a release is change-a-model's work. The example inside the cell-calculus repository requires the calculus by path and is always current.

## The procedure

The round trip's first four stages, each with an acceptance test you run before moving on. Stopping at a failed test and reporting it is a success; pressing on past one is the failure mode this skill exists to prevent.

### Stage 1: the cell's I/O

From the design's Commands, Subscribes and Publishes tables, write the five type parameters: the command type, the foreign event type, the event type, the state type, the refusal type. Each is a sum type whose constructors are the table's rows, named by the row's id, carrying the row's fields with their types. Name them `XCommand`, `XEvent`, `XRefusal`, `XState` for the cell `x`. Derive `Repr, DecidableEq` on commands and refusals and `Repr, DecidableEq, BEq` on events, as the answer does.

If the design has no Subscribes rows, the foreign event type is `Unit`. If it has no refusals, the refusal type is `Empty`.

Acceptance: every row of the three tables is a constructor, and no constructor lacks a row. If a table is missing, stop and report which; do not invent rows.

### Stage 2: the type-level model

Write the `Cell` value with `initial` from the State table's defaults, `decide` and `react` as `sorry`, `evolve` from the Publishes rows against the State fields, and `isTerminal` from the Terminal line. Build the module on its own, `lake build Package.X` for the package `Package`, and do not import it from the package root yet: a closed value with a `sorry` in it is evaluated when the fixtures executable loads, and the executable panics. The root import is a stage-three step.

Acceptance: the module builds with `sorry` warnings only in `decide` and `react`. A type error here is a design defect in the tables; report it as such.

### Stage 3: the bodies and the data

Write `decide` from the Decide table, one branch per row in the row's order, each row's "reads" column telling you whether the cell takes `Inputs` instead of a bare command. Write `react` from the React table. A design with Commands and no Decide rows is incomplete: stop and report.

Write the data dictionary as doc comments on every field of the state and every constructor's fields: meaning, domain, example value. A field whose domain admits a value its meaning forbids is a wrong type, so fix the type, do not write the caveat.

Write the universal claims as theorems with the names the design gives them, proved by `simp` with the definitions unfolded, `cases`, or induction with `omega`. If a claim does not go through, report the claim and the goal that remained; do not weaken the statement.

If the design has a Wire table, write the wire structure, `serialize`, `parse`, and the `WireCodec` instance with `parse_serialize := by intro c; cases c <;> rfl`, and the `JsonEncode` instances for the wire command, the events and the refusals, which the fixtures generator renders with, and their `JsonDecode` inverses, which the trace checker reads with. If it has Sentences, write the `Describe` instances. Write the `Kinded` instances for commands, events and refusals. Now add the module to the package root's imports and build the whole package.

Acceptance: `lake build` with no `sorry` and no warnings; every universal claim proved; the codec instance exists.

### Stage 4: the examples, the journey, the contracts, the attributes

Write each Examples row as an `Example` or `ReactionExample` value named by its id, `LOAN-OUT-1` becoming `loanOut1`, with a one-line doc comment saying what the row shows and its `_holds` theorem by `decide`. If the row has a "with" column, the cell's command type is `Inputs` and the answers go in the When.

Write the example list and the three coverage theorems. If one fails, the design is missing an example for the kind the theorem names; report it, do not drop the kind.

If the design has a journey table, write the `Journey` term with `step` names equal to the table's step names, and its contracts as a `Contracts` function by step name, with `rfl` theorems for the folded bounds the design states.

Write each Attributes row with the constructor its scope names and the subject its row names; an attribute's run is subject-indexed, the subject being the project's subject type for the boundary the row names, and a row with no subject is a gap to report. A service level written as a single example in the design is a scope error: report it and write it as `population` with the threshold the design gives or asks for.

Register the cell's views: one line in the `cells` list of `Fixtures.lean`, naming the module, a title and the example list, and one in the `checkers` list of `Replay.lean`, so that its traces replay. The generator and the checker are generic over the instances the module gives; nothing else is written.

Then test the examples' strength, not only their coverage. Coverage says every kind is reached; it does not say every branch is pinned. Add between three and six mutants for the new cell to the project's `mutants.json`, one per Decide branch where a change would be plausible, and run the gate. A mutant that survives is a Decide row with no example that notices it: report the row and the example the design should add, with a suggested id. Do not write the row; the design owns it.

Acceptance: every example holds; coverage holds; `lake exe fixtures` renders the cell's views; `python3 ../../tools/mutants.py mutants.json` is green with the new mutants in it, or the survivors are in the report as missing rows.

## Names and comments

The style guide's rules are the rules. The ones that matter most while writing:

- Type parameters and types are words. Values are named by what they are, examples by their id. Theorems are named subject then claim: `checkOut_idempotent`, `loanOut1_holds`.
- Every declaration carries a doc comment that says what it is and, where the shape has a published name, what it is called: the Decider, the idempotent receiver, a reference monitor. Every one: each example value, each fixture envelope and recorded run, the serializer, the parser and every predicate. The reviewer counts declarations against the comments above them, and one undocumented helper fails the module the same as an undocumented type.
- Imports first, then the module comment with the design's path and the sources.

## What you never do

- Add a shape to the generic package. If the design needs one the calculus lacks, say so in the report and model what you can.
- Write a function from an event to a command, a loop, a header map, a call inside `decide`, or a bounded ID without its boundary.
- Invent a row, a branch, an example or a sentence the design does not carry.
- Delete or weaken anything to make the build pass. A red build with a precise report is the right output when the design is wrong.

## The report

End with a short report, in prose, that says: which stages passed; what the design was missing or wrong, by table and row, including Decide branches no example pins; which theorems were proved and which examples hold; the counts the build and the gate printed; and what the owner must confirm before the review line is signed. Name files only where the reader has to go there.

## Template

`assets/cell-module-template.lean` is the skeleton of a cell module with the sections in order. Copy it and fill it; delete the sections the design does not use.
