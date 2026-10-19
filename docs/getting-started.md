# Getting started: modelling your own system

How a team builds its own package on the calculus, step by step, with the file in the worked example that does each step. The example is a public library's circulation system under [examples/library](../examples/library/); your system is whatever it is, and the shapes are the same.

The one rule throughout: the design owns meaning. Every type, branch and example you write points at a sentence in your corpus or your design. Where the corpus does not say, you write a gap in the design's open items, never a guess in the model.

## 0. Before you start

Install Lean's version manager once. The toolchain is pinned by each package and fetched on first use.

```
curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y --default-toolchain none
export PATH="$HOME/.elan/bin:$PATH"
```

Build the example first, so you know what green looks like: the commands are in its [README](../examples/library/README.md).

## 1. Write the corpus

Three documents, in whatever form your organisation already writes them, with two tables added to every journey section so that the maps can be transcribed rather than read.

| Document | What it carries | In the example |
| --- | --- | --- |
| The vision | The principles, the trust zones, the journey map, and one section per journey with its **Steps** table (step, cells, waits on, publishes, partner) and its **References** table (journey, kind, at step) | [corpus/vision.md](../examples/library/corpus/vision.md) |
| The capability map | One line per capability on its purpose and its edge; which are core, supporting and generic; the journey matrix, one row per journey naming the capabilities its steps use | [corpus/capability-map.md](../examples/library/corpus/capability-map.md) |
| The architecture | The cells by zone, how cells communicate, the paths table with every arrow and its kind, the partner calls, and the direction rule | [corpus/architecture.md](../examples/library/corpus/architecture.md) |

The columns are fixed by [style guide section 9](style-guide.md#9-the-annotation-a-journey-carries). The cells column names capabilities and nothing else: never a role, a surface or a team. A reference is composition, succession or pointer, and [the DAG rule](the-dag-rule.md) says which is which.

## 2. Start the package

A package is a `lakefile.toml` that requires the calculus over git at a tag, a pinned toolchain, a root module, and an `Architecture` module. Nothing else yet.

```toml
name = "clinic"
defaultTargets = ["Maps", "Clinic", "fixtures", "replay"]

[leanOptions]
linter.missingDocs = true          # every field and constructor carries a sentence, or the build warns

[[require]]
name = "cell-calculus"
git = "https://github.com/matthew-bram/cell-architecture-calculus.git"
rev = "v1.0.0"                     # a tag, never a branch
subDir = "cell-calculus"

[[lean_lib]]
name = "Maps"
roots = ["JourneyMap", "ContextMap"]

[[lean_lib]]
name = "Clinic"

[[lean_exe]]
name = "fixtures"
root = "Fixtures"

[[lean_exe]]
name = "replay"
root = "Replay"
```

Copy `lean-toolchain` from the calculus so the two agree. The example requires the calculus by path instead, because it lives in the same repository: [lakefile.toml](../examples/library/lakefile.toml).

## 3. Fix the two things the calculus is generic over

The calculus is generic over exactly two types your project supplies, and both are algebraic data types you define from your corpus.

**The principal**: who a person or system is when they act, as your identity capability answers it. A structure whose fields each have a meaning and a domain; a field that is one of a fixed few things is a sum type, not a string. Declare the `Architecture` instance with it.

**The subject**: what an event is about, the one identifier its record is keyed by. Where your architecture has trust boundaries, enumerate the zones and make the subject a `BoundedId` indexed by the zone that knows it, so the kernel refuses a record in one zone built with another zone's ID. Where it has none, the subject is a plain ID, or `Unit` until the corpus says.

```lean
inductive Role
  /-- A clinician: may book, see and close an appointment. -/
  | clinician
  /-- A receptionist: may book and see, never close. -/
  | receptionist
  deriving DecidableEq, Repr

structure Principal where
  /-- The staff ID as the identity capability issued it; a string such as "S-12". -/
  staff : StaffId
  /-- The role the staff member holds, which the actor policies match on. -/
  role  : Role
  deriving DecidableEq, Repr

instance : Architecture :=
  { Principal := Principal, principalDecEq := inferInstance, principalRepr := inferInstance }
```

In the example: [Library/Architecture.lean](../examples/library/Library/Architecture.lean), a card with a role as the principal, five zones, and the patron ID bounded by the zone that knows it.

## 4. Map the journeys

Transcribe the vision's tables into a module: one constructor per capability with its zone, one `Transcribed` value per journey from its Steps and References tables, the matrix rows from the capability map, the paths table from the architecture, and one theorem per claim the corpus makes. The claims are the same for every project: each journey is a DAG, each matrix row equals its journey's table, composition is acyclic, no path breaks the direction rule. A claim that does not hold is kept as the theorem of its negation, with a comment saying it is the corpus's defect; you never reorder a step or drop a reference to make a theorem pass.

In the example: [JourneyMap.lean](../examples/library/JourneyMap.lean).

## 5. Map the contexts

One constructor per bounded context, the outside parties included; the kind each serves from the capability map; and for every arrow in the paths table one relationship in the standard vocabulary, upstream to downstream. A publisher is upstream of its reactors, a gateway's owner is upstream of its callers, an outside party is upstream of the cell that calls it. The theorems: every arrow covered, every outside party translated at the edge, and where a heuristic such as "a core context should not conform to a generic one" is broken, named.

In the example: [ContextMap.lean](../examples/library/ContextMap.lean).

## 6. Write the first design to the tables

A design is prose where the meaning is, and the fixed tables of [style guide section 8](style-guide.md#8-the-annotation-a-design-carries) where the model is transcribed from: Commands, Subscribes, Publishes, State, Decide, React, Terminal, Examples, Universal claims, Sentences, Wire, the journey, Contracts, Attributes. One Decide row per branch, in the order the design checks them; one example per row is the coverage rule.

In the example: [designs/circulation.md](../examples/library/designs/circulation.md).

## 7. Model the cell

One module per cell, transcribed one row to one definition.

1. **The five types**, your cell's algebraic data types: the command type from the Commands rows, the foreign event type from Subscribes, the event type from Publishes, the state from State, the refusal type from the refusals column. Each constructor carries the row's fields and a doc comment with the field's meaning, domain and an example value.
2. **The cell**: `initial` from the State defaults, `decide` with one branch per Decide row in the row's order, `react` from the React rows, `evolve` from Publishes against State, `isTerminal` from the Terminal line. A cell whose decision needs another cell's answer or the clock takes `Inputs` instead of a bare command.
3. **The examples** as values named by their id, each with its `_holds` theorem by `decide`; the universal claims as theorems by `simp`.
4. **The instances**: `Kinded` for coverage, `WireCodec` with the round trip proved by cases, `JsonEncode` and `JsonDecode` for the fixtures and the traces, `Describe` for the sentences.
5. **The coverage theorems** over the example list, and three to six **mutants** in `mutants.json`, one per branch where a change would be plausible. A mutant that survives is a missing row in the design.

In the example: [Library/Circulation.lean](../examples/library/Library/Circulation.lean) for the cell, [Library/Inputs.lean](../examples/library/Library/Inputs.lean) for a cell that reads an answer and the clock, [Library/Journeys.lean](../examples/library/Library/Journeys.lean) for the journey as a term and a fan-in cell, [Library/Envelopes.lean](../examples/library/Library/Envelopes.lean) for the actor policy and the recorded runs, [mutants.json](../examples/library/mutants.json) for the gate.

## 8. Generate the views

Register the cell in `Fixtures.lean`, one line, and run `lake exe fixtures`. The generator writes a feature file for reviewers and a JSON fixture file for the tests, both stamped with the model's hash. Commit them; they are regenerated by the build and never edited.

In the example: [Fixtures.lean](../examples/library/Fixtures.lean) and [generated/](../examples/library/generated/).

## 9. Test your code against the fixtures

Your implementation needs one seam: a pure fold from events to a state, and a pure decider from a command and a state to an outcome, speaking the wire shape. The test suite loads the fixtures, asserts the stamp, and runs one test per example named by its id: replay the given history, decide the command, compare the outcome exactly. A failing test names the row of the design the code disagrees with; which side is wrong is a decision for the design, never a fixture to edit.

In the example: [impl/circulation.py](../examples/library/impl/circulation.py) for the seam and [impl/test_circulation.py](../examples/library/impl/test_circulation.py) for the suite, which any language can copy.

## 10. Replay what the code did

Register the cell in `Replay.lean` and record what your code did, in test or in production, as a trace in the same wire shape: each command it was handed and the outcome it produced. `lake exe replay` parses each command with the model's own parse, replays the trace, and names the step where the code took a path the model has no edge for. A trace that conformed is kept with the tests as a known-good trace; one that found a defect is kept as a known-bad trace until the fix lands.

In the example: [Replay.lean](../examples/library/Replay.lean), [impl/record_trace.py](../examples/library/impl/record_trace.py), and the seven traces under [traces/](../examples/library/traces/).

## 11. Review, sign, and change by supersession

A green build proves the model is consistent with itself, not that it says what the design says. A reviewer reads the names, the comments, every theorem's statement against the design's sentence, every Decide branch against the example that pins it, and the generated feature file, then signs the review line in `Governance.lean` with the design's path and hash. From then on the build fails whenever the design changes under the signature.

A change after that is never an edit. A changed example gets a new id and the old is retired with its successor, the date and the reason; a changed theorem gets a successor and the old is deprecated by name; a changed event gets a new version with the upcaster kept total. The coverage theorems run over the live set, so retiring without a successor fails the build by name.

In the example: [Library/Governance.lean](../examples/library/Library/Governance.lean).

## 12. Wire the gates into CI

The same commands the example's [README](../examples/library/README.md) lists, in the order the example's [workflow](../.github/workflows/ci.yml) runs them: the build, the fixtures with a check that the committed views did not change, the review check, the mutation gate, the traces that must conform and the traces that must be rejected, the tests, and the recorded trace replayed.
