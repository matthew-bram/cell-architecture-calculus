# Getting started: modeling your own system

This guide shows how a team builds its own package on the calculus, step by step. Each step comes with the file in the worked example that does it. The example is a public library's circulation system, under [examples/library](../examples/library/). Your system is whatever it is, and the shapes are the same.

The one rule throughout is that the design owns meaning. Every type, branch and example you write points at a sentence in your corpus or your design. Where the corpus does not say, you write a gap in the design's open items, never a guess in the model.

## 0. Before you start

Install Lean's version manager once. Each package pins the toolchain, which is fetched on first use.

```
curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y --default-toolchain none
export PATH="$HOME/.elan/bin:$PATH"
```

Build the example first, so you know what green looks like. The commands are in its [README](../examples/library/README.md).

## 1. Write the corpus

The corpus is three documents, in whatever form your organization already writes them. Add two tables to every journey section, so that the maps can be transcribed rather than read.

| Document | What it carries | In the example |
| --- | --- | --- |
| The vision | The principles, the trust zones, the journey map, and one section per journey with its **Steps** table (step, cells, waits on, publishes, partner) and its **References** table (journey, kind, at step) | [corpus/vision.md](../examples/library/corpus/vision.md) |
| The capability map | One line per capability on its purpose and its edge; which are core, supporting and generic; the journey matrix, one row per journey naming the capabilities its steps use | [corpus/capability-map.md](../examples/library/corpus/capability-map.md) |
| The architecture | The cells by zone, how cells communicate, the paths table with every arrow and its kind, the partner calls, and the direction rule | [corpus/architecture.md](../examples/library/corpus/architecture.md) |

The columns are fixed by [style guide section 9](style-guide.md#9-the-annotation-a-journey-carries). The cells column names capabilities and nothing else. It never names a role, a surface or a team. A reference is composition, succession or pointer, and [the DAG rule](the-dag-rule.md) says which is which.

## 2. Start the package

A package starts as:

- a `lakefile.toml` that requires the calculus over git, at a tag;
- a pinned toolchain;
- a root module;
- an `Architecture` module;
- a `Governance` module with an unreviewed review line;
- the two map modules and the two executables, empty;
- an empty mutants file;
- the gate scripts;
- a workflow.

There is no cell yet. Here is the build file, for a project named `clinic`:

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

Copy `lean-toolchain` from the calculus, so the two agree. The example requires the calculus by path instead, in its [lakefile.toml](../examples/library/lakefile.toml), because it lives in the same repository.

## 3. Define the two types the calculus is generic over

The calculus is generic over exactly two types, which your project supplies. Both are algebraic data types that you define from your corpus.

**The principal** is who a person or system is when they act, as your identity capability answers it. It is a structure whose fields each have a meaning and a domain. A field that is one of a fixed few things is a sum type, not a string. Declare the `Architecture` instance with it.

**The subject** is what an event is about: the one identifier its record is keyed by.

- **Where your architecture has trust boundaries**, enumerate the zones. Make the subject a `BoundedId` indexed by the zone that knows it. Then the kernel refuses a record in one zone built with another zone's ID.
- **Where it has none**, the subject is a plain ID, or `Unit` until the corpus says.

Here is a principal for a clinic, with the `Architecture` instance declared with it:

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

In the example this is [Library/Architecture.lean](../examples/library/Library/Architecture.lean). Its principal is a card with a role. It has five zones, and the patron ID is bounded by the zone that knows it.

## 4. Map the journeys

Transcribe the vision's tables into a module:

- one constructor per capability, with its zone;
- one `Transcribed` value per journey, from its Steps and References tables;
- the matrix rows, from the capability map;
- the paths table, from the architecture;
- one theorem per claim the corpus makes.

The claims are the same for every project:

- each journey is a DAG;
- each matrix row equals its journey's table;
- composition is acyclic;
- no path breaks the direction rule.

A claim that does not hold is kept as the theorem of its negation, with a comment saying it is the corpus's defect. You never reorder a step or drop a reference to make a theorem pass.

In the example this is [JourneyMap.lean](../examples/library/JourneyMap.lean).

## 5. Map the contexts

The context map holds:

- one constructor per bounded context, the outside parties included;
- the kind each serves, from the capability map;
- for every arrow in the paths table, one relationship in the standard vocabulary, upstream to downstream.

A publisher is upstream of its reactors. A gateway's owner is upstream of its callers. An outside party is upstream of the cell that calls it.

The theorems say that:

- every arrow is covered;
- every outside party is translated at the edge;
- where a heuristic is broken, it is named. One such heuristic is "a core context should not conform to a generic one".

In the example this is [ContextMap.lean](../examples/library/ContextMap.lean).

## 6. Write the first design to the tables

A design is prose where the meaning is, and the fixed tables of [style guide section 8](style-guide.md#8-the-annotation-a-design-carries) where the model is transcribed from. The tables are Commands, Subscribes, Publishes, State, Decide, React, Terminal, Examples, Universal claims, Sentences, Wire, the journey, Contracts and Attributes.

Write one Decide row per branch, in the order the design checks them. One example per row is the coverage rule.

In the example this is [designs/circulation.md](../examples/library/designs/circulation.md).

## 7. Model the cell

Each cell gets one module, transcribed one row to one definition.

1. **The five types**, your cell's algebraic data types:
   - the command type, from the Commands rows;
   - the foreign event type, from Subscribes;
   - the event type, from Publishes;
   - the state, from State;
   - the refusal type, from the refusals column.

   Each constructor carries the row's fields, and a doc comment with the field's meaning, domain and an example value.
2. **The cell**:
   - `initial`, from the State defaults;
   - `decide`, with one branch per Decide row, in the row's order;
   - `react`, from the React rows;
   - `evolve`, from Publishes against State;
   - `isTerminal`, from the Terminal line.

   A cell whose decision needs another cell's answer or the clock takes `Inputs` instead of a bare command.
3. **The examples**, as values named by their id. Each has its `_holds` theorem, by `decide`. The universal claims are theorems by `simp`.
4. **The instances**:
   - `Kinded`, for coverage;
   - `WireCodec`, with the round trip proved by cases;
   - `JsonEncode` and `JsonDecode`, for the fixtures and the traces;
   - `Describe`, for the sentences.
5. **The coverage theorems** over the example list, and three to six **mutants** in `mutants.json`, one per branch where a change would be plausible. A mutant that survives is a missing row in the design.

In the example:

- [Library/Circulation.lean](../examples/library/Library/Circulation.lean) for the cell;
- [Library/Inputs.lean](../examples/library/Library/Inputs.lean) for a cell that reads an answer and the clock;
- [Library/Journeys.lean](../examples/library/Library/Journeys.lean) for the journey as a term and a fan-in cell;
- [Library/Envelopes.lean](../examples/library/Library/Envelopes.lean) for the actor policy and the recorded runs;
- [mutants.json](../examples/library/mutants.json) for the gate.

## 8. Generate the views

Register the cell in `Fixtures.lean`, which takes one line. Then run `lake exe fixtures`.

The generator writes a feature file for reviewers and a JSON fixture file for the tests. Both are stamped with the model's hash. Commit them. The build regenerates them, and they are never edited.

In the example these are [Fixtures.lean](../examples/library/Fixtures.lean) and [generated/](../examples/library/generated/).

## 9. Test your code against the fixtures

Your implementation needs one seam: a pure fold from events to a state, and a pure decider from a command and a state to an outcome, speaking the wire shape.

The test suite loads the fixtures and asserts the stamp. Then it runs one test per example, named by its id. Each test replays the given history, decides the command and compares the outcome exactly.

A failing test names the row of the design that the code disagrees with. Which side is wrong is a decision for the design, never a fixture to edit.

In the example: [impl/circulation.py](../examples/library/impl/circulation.py) for the seam, and [impl/test_circulation.py](../examples/library/impl/test_circulation.py) for the suite, which any language can copy.

## 10. Replay what the code did

Register the cell in `Replay.lean`. Then record what your code did, in test or in production, as a trace in the same wire shape. A trace holds each command the code was handed and the outcome it produced.

`lake exe replay` parses each command with the model's own parse, and replays the trace. It names the step where the code took a path the model has no edge for.

A trace that conformed is kept with the tests, as a known-good trace. A trace that found a defect is kept as a known-bad trace until the fix lands.

In the example: [Replay.lean](../examples/library/Replay.lean), [impl/record_trace.py](../examples/library/impl/record_trace.py), and the seven traces under [traces/](../examples/library/traces/).

## 11. Review, sign, and change by supersession

A green build proves that the model is consistent with itself. It does not prove that the model says what the design says.

A reviewer reads:

- the names;
- the comments;
- every theorem's statement, against the design's sentence;
- every Decide branch, against the example that pins it;
- the generated feature file.

Then the reviewer signs the review line in `Governance.lean`, with the design's path and hash. From then on, the build fails whenever the design changes under the signature.

A change after that is never an edit:

- **A changed example** gets a new id. The old one is retired with its successor, the date and the reason.
- **A changed theorem** gets a successor. The old one is deprecated by name.
- **A changed event** gets a new version, with the upcaster kept total.

The coverage theorems run over the live set. So retiring without a successor fails the build, by name.

In the example this is [Library/Governance.lean](../examples/library/Library/Governance.lean).

## 12. Wire the gates into CI

Wire in the same commands the example's [README](../examples/library/README.md) lists, in the order the example's [workflow](../.github/workflows/ci.yml) runs them:

1. the build;
2. the fixtures, with a check that the committed views did not change;
3. the review check;
4. the mutation gate;
5. the traces that must conform, and the traces that must be rejected;
6. the tests;
7. the recorded trace, replayed.
