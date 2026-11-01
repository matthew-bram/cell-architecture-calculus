## The wire, and the examples

**Specification by example is a type.** `Cell.lean`.

```lean
structure Example (Command Event Refusal : Type) where
  id     : String
  given  : List Event
  when   : Command
  expect : Except Refusal (List Event)
```

`Example.holds cell ex` is a Boolean the kernel evaluates. The `id` is the row in the design document and the name of the test in the code. A `ReactionExample` is the same with a foreign fact as its When. An example set is a Lean value, and the coverage theorems hold over it: every command kind, every event kind and every refusal reason appears in some example, or the file does not compile. A trace, a list of command and outcome steps the implementation reported, is replayed by `Cell.conforms`, and a trace the model rejects names the step. The Gherkin rendering of each example is a fold over the same value, for the reader who reviews sentences. The example's `circulationExamples_coverCommands`, `_coverEvents` and `_coverRefusals` are the three coverage theorems; `goodTrace_conforms` and `badTrace_rejected` are conformance on a correct run and on one that booked a retry twice.

**Coverage has a second half, and it is mutation.** `tools/mutants.py`. The coverage theorems say every kind is reached; they do not say every branch is pinned. A mutant is one deliberate change to the model, and the examples, traces and theorems must notice: a mutant that builds has found a part of the model nothing pins, and that is a failing test. The example's ten mutants include the limit off by one, the warning at the level rather than over it, and the fine's comparison backwards; each is killed by a named example that sits on the boundary. The source is coverage for formal verification as Chockler, Kupferman and Vardi define it, repeating the verification on mutants of the model.
