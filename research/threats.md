# Threats to the hypothesis, and the proposals for each

Oct 12, 2026 · proposals for section 7 of the [white paper](../white-paper.md), with the first threat worked in depth and demonstrated in `Calculus.lean`

**Confidence.** **[H]** run here today, or read in the source; **[M]** read in a search summary or abstract; **[L]** from memory.

## Threat 1. The model and the specification by example may not be the same geometry

The owner's framing: how do we prove the model has the same geometry as the specs? Is it a hash or a git record after review? Can the geometry of the model be linked to the test output?

"Same geometry" is four different claims, and each has a different proof. A hash answers only the fourth.

| Claim | What it means | How it is proved | Status |
| --- | --- | --- | --- |
| **Consistency** | Every example agrees with the model | Each example is a theorem: `ex.holds cell = true` by `decide`. If the model changes, the theorem fails and names the example | Done. `booksExamples_allHold` **[H]** |
| **Coverage** | The examples reach every part of the model's geometry | Two halves. *Structural:* every command kind, refusal reason and event kind appears in some example, as a theorem over the example set. *Behavioral:* mutate the model and require that at least one example fails; a mutant no example kills is a branch the examples do not pin | Structural done: `booksExamples_coverCommands`, `coverEvents`, `coverRefusals`. Behavioral demonstrated by hand below **[H]** |
| **Conformance** | The implementation's behavior is a behavior the model allows | The test output is *input to the model*. A trace of (command, outcome) steps is replayed through the cell's `handle` and each step compared. A trace the model rejects names the step | Done. `goodTrace_conforms`, `badTrace_rejected` **[H]** |
| **Provenance** | These tests ran against this model, and this model was reviewed against this design | A content hash of the generated example set and of the model, carried in an attestation the test run signs; a review record binding the design's hash to the model's | Proposed below |

### Consistency and coverage, in the file

The example set for the books slice is a Lean value, `booksExamples`. Four theorems hold over it: every example holds, and the examples between them exercise both command kinds, both event kinds and the one refusal reason. Add a constructor to any of the three types without an example and the coverage theorem fails at compile time. This is cheap, decidable and the first line of defense.

The behavioral half is mutation, the standard answer to "are my tests strong enough to notice a change to the thing" (Chockler, Kupferman and Vardi for model checking, where coverage and vacuity are both "repeating the verification on mutant inputs" **[M]**; MuAlloy for Alloy and MutDafny for Dafny specifications **[M]**). Run today by hand on two mutants of the books cell:

| Mutant | What changed | Result |
| --- | --- | --- |
| A retry books again | The idempotent-receiver branch of `decide` removed | Killed by five theorems: the retry example `ex2`, the universal `commit_idempotent` (unsolved goals), `booksExamples_allHold`, `goodTrace_conforms` and `badTrace_rejected` **[H]** |
| The terminal predicate flipped | `isTerminal` made always false | **Survived.** Zero errors. No example, trace or theorem looks at `isTerminal` **[H]** |

The surviving mutant is the finding: the example set has a hole exactly where the model has a part nothing pins. That is what "the examples do not have the model's geometry" looks like in practice, and mutation finds it mechanically. Proposal: a mutation script over the Lean model with a small operator set (remove a branch, flip a Boolean, swap a constructor, change a comparison), run in CI, with the mutation score reported per cell and a surviving mutant treated like a failing test.

### Conformance, in the file

`Cell.conforms` takes a list of trace steps and replays them: fold the history, decide the command, compare with what the implementation reported, extend the history with the model's events, continue. A good trace of five steps conforms; a trace from an implementation that booked a retry twice is rejected at the second step. This is trace validation as Cirstea, Kuppe and Merz do it for TLA+ (SEFM 2024), where the implementation is instrumented to record updates to specification variables and the model checker decides whether the trace is a behavior of the spec; they report detecting discrepancies "in all cases" across several distributed programs **[M]**. Here the model is executable, so the checker is a fold and no model checker is needed.

What this gives that a hash cannot: the link between the geometry of the model and the output of the tests is that the output is replayed through the geometry. If the implementation took a path the model has no edge for, the replay fails at that step. Proposal: every test run and, later, every production cell emits its trace in one JSON shape (cell, command, outcome, in order); a small Lean executable reads it and replays it; CI runs it on the test traces, and operations samples it on production traces.

### Provenance, the part a hash is for

The hash answers "which model and which examples did these tests run against," and nothing more. Proposal, in the shape the project already uses for the private zone's attestation:

1. **The examples are generated, never copied.** A Lean `main` emits the example set as JSON. The implementation's test suite reads that JSON and runs each example by id. There is no hand-written copy of an example in the code, so there is no transcription to grok.
2. **The test run attests what it ran.** The run records the SHA-256 of the examples JSON and of the model file, the commit of each, and the per-id results, as an in-toto attestation with a test-result predicate **[M]**. The release pipeline refuses a build whose attestation names a model hash other than the one at the commit being released.
3. **The review binds design to model.** The one step no program can do is "the model means what the design's prose intended." That is a human review, and its record is a line in the model file's header: the design document's path and content hash at the time of review, and who reviewed. CI fails when the design document's hash changes and the model's review line does not. Drift between prose and model becomes visible the day it happens, even though it cannot be prevented.
4. **The design's example table is generated from the model**, not written in the design. The design cites the ids; the table is rendered from the examples JSON. Reverses the direction for the one part of the design that can be generated, which is the Verso idea applied with today's tools.

### What is still not proved

Conformance on traces is conformance on the traces seen. Refinement, that *every* implementation behavior is a model behavior, is a proof and needs the code in a form Lean can reason about; the roadmap puts it after the oracle. Mutation scores are evidence, not proof. The review in step 3 is a review.

## Threat 2. Examples are not coverage

Proposal: three layers of input, one oracle.

- **The examples**, hand-chosen, readable, the design's own rows, held to the coverage theorems above.
- **Random inputs from the types.** Plausible, the Lean 4 property-based testing library, derives generators and shrinkers from a type's structure (`SampleableExt`, `Shrinkable`) **[M]**. The model is then tested against its own universal properties on thousands of inputs with shrinking to a minimal counterexample, in Lean, before the code exists.
- **Differential testing**, the Cedar pattern: the same random inputs run through the implementation, the outputs compared with the model's **[H, from the Cedar papers]**. The generator is shared, so the example set, the property tests and the differential tests are one input stream with three consumers.

The surviving mutant above is also a coverage finding, and mutation closes the loop: random inputs that kill a mutant become examples.

## Threat 3. The model-to-code link is testing, not proof

Three proposals in rising strength, chosen per cell by how much the invariant is worth.

1. **Traces and differential tests** (threats 1 and 2) for every cell. The claim is "agrees with the model on every input tried," written that way.
2. **The model is the code for the pure core.** Lean compiles to C and links as a native library. A cell's `decide`, `react` and `evolve` are pure functions with no I/O, which is exactly what can be compiled from the model and called from the production runtime through an FFI, with the runtime owning I/O, storage and the fabric. SampCert at AWS shipped this way and was faster than what it replaced **[M]**. For the books core, where "booked once" and "postings sum to zero" are the product, this is the proposal: the model *is* the decider, and the only thing left to test is the shell around it.
3. **Refinement proofs** for the cells that stay hand-written: a simulation relation between the production state and the model state, proved to be preserved by every command. LeanMachines gives the Event-B form of this on Lean 4 **[M]**. Last, and only where 2 is impossible.

## Threat 4. The agents are never proved

Proposal: make the boundary a type and test it as a boundary.

- A role's judgment enters the model as a root event in the **result schema**, which is already a published language. Write the schema's parser and validator in Lean; it is the oracle the runtime's validator is differentially tested against, and a judgment that does not parse never becomes an event.
- Theorems about what a judgment *cannot* do: by the cell type, a reaction to a judgment event emits events and never commands; by the paths, a judgment never reaches the private zone. These are already by construction and should be stated as theorems so they are visible.
- The role's own quality is **assumed** and measured: principle 11's per-role test sets are the evidence, reported beside the theorems and never mixed with them. The paper's sentence is "the method proves everything downstream of a judgment and nothing about it."

## Threat 5. The window is not in the model

Proposal: model the saga's state machine and prove the one theorem that matters, without deciding the operational question.

- A saga as a cell whose events are `intentRecorded key cmd`, `remoteAnswered key outcome` and `resultRecorded`, with `unknown` an explicit answer. The theorem: for any receiver with the idempotent property (the one `commit_idempotent` establishes for the books), the replayed state after "intent, unknown, retry with the same key, ok" equals the state after "intent, ok". That is the error risk ratio's safety condition stated once and proved for every key.
- Whether commands over RPC between cells are allowed, and how the ratio is budgeted, stay deferred as the owner asked. The theorem is the precondition any answer must satisfy.

## Threat 6. Event sourcing is a commitment

Proposal: each cell's data design names its history and its fold, in one of two forms.

- **An event store**: the cell's events are the stored facts; `replay` is literal.
- **Versioned rows**: the books design already chose "versioned rows as the change log." A row version is an event; `evolve` is the row-version function; the current row is the snapshot. `replay_append` is the theorem that a snapshot plus later versions equals a full replay, which is what makes the versioned-row form sound.

A cell that chooses neither is a cell the calculus does not describe, and the data classification document should carry a column saying which form each cell takes.

## Threat 7. Composition of cells is unproved

**Revised 2026-10-12, after the owner's reframing: each cell's API is a function in the archetypes, so cell interactions compose into a composite function.** That turns the threat into three theorems, two of which are now in `Calculus.lean`.

Two compositions hide in "composite function," and they must be kept apart. *Combining* two cells into one bigger cell, the sum of commands and events over the product of states, is fmodel's `combine`, a monoid **[M]**; it adds no edges and is about packaging. *Composing along a journey*, where one cell's published events are another's foreign input, is Kleisli composition in `Except` for commands and function composition for reactions; the journey DAG is its data-flow graph. The threat was about the second.

What the reframing gives:

- **A journey is a cell.** The composite of a `decide` and a `react` has the decider signature: a root command in, the product of histories as state, a refusal or events out. Composition is closed, journeys compose into journeys under the same rules, and the whole system is one cell. The "composition" relation between journeys is function application.
- **Associativity is why the boundaries may be wrong.** Function composition is associative and `combine` is a commutative monoid, so where the cut between cells falls is a parenthesization and the composite is the same under every choice. The methodology's rule that statements move whole when a boundary moves is this theorem.
- **Time disappears in the composite, and that is the theorem with content.** Fan-in is a function of two arguments; in the world the two facts arrive one at a time and the cell must remember the first. The composite is the denotation; the choreography is the operational reading; theorem 2 is that they agree.
- **The composite's state is a product, never a merge.** A cell seeing only its own state is visible in the type of every journey. Method 3 is a type.
- **What it does not change is `unknown`.** Kleisli composition short-circuits on it, correctly for the function and silently for effects already landed upstream. The composite specifies the happy path and the refusals; the saga specifies recovery. With idempotent receivers (threat 5's theorem), the saga collapses to "retry the composite from the recorded intent until no step returns unknown."

The three theorems, and their status:

| Theorem | Statement | Status |
| --- | --- | --- |
| 1. The algebra compiles to a DAG | A `Journey` term is built from `step`, `seq` and `par` only. `compile` numbers its nodes and records what each waits on. `compile_wellFormed`: for every term, every node waits only on earlier nodes, and the outputs are numbered below the end. Structural induction over the three constructors, with `nodesOk_append` as the lemma. `run_seq` and `run_par` are the compositionality equations, definitional | **Proved** **[H]** |
| 2. Choreography realizes composition | A reports cell with memory, delivered the Analyst's and the Steward's looks one at a time in either order, emits exactly the digest the two-argument function gives, for every pair of looks; and nothing after one look alone. `deliver_analystFirst`, `deliver_stewardFirst`, `deliver_oneLook_noDigest`, universal in the looks, by `simp` | **Proved for the fan-in slice** **[H]**. The general form, for any cell whose `react` and `evolve` satisfy a stated memory discipline, is the next step |
| 3. `combine` is a monoid and preserves every structural theorem | fmodel's operator with its laws | Not started. Fiddly on product states, no new insight; worth having for the boundary argument |

The books-to-alerts journey is also now a term, `commitJourneyTerm`, which runs to the same outcome as the hand-written `do` block and whose compiled graph is well formed by theorem 1 rather than by a separate check. A transcribed journey from the vision document and a composed one from the algebra are now held to one rule, `nodesOk`.

## Threat 8. Projections, queries and fan-in with memory are thin

Proposal: two more archetypes in the calculus, both already expressible.

- **View**: `F → V → V`, a fold over foreign events into a consumer's own shape. Event Modeling's view slice, with Given/Then examples (no When). fmodel's `View` is this.
- **Query**: `S → Q → A`, a pure read, no events, no obligation. Examples are Given/Then.
- **Fan-in with memory** is a reaction whose state remembers the first fact: `react` emits nothing and `evolve` records; the second fact's `react` finds it and emits. A worked example in the geometry catalogue, with the theorem that the fan-in emits exactly once.

## Threat 9. Toolchain churn and adoption

Proposal: a `lake` project with the toolchain pinned, CI on every change to the model or the documents, upgrades on purpose and recorded. The owner stays at the `decide` layer; universal theorems are written by agents and reviewed as proofs are reviewed, by whether they state the right thing. The two universal theorems so far took one `simp` call each.

## Threat 10. Modeling what is easy to model

Proposal: the annotation grammar makes behavior mandatory. A design's Lean file must contain a `decide` for every command in its Commands table and a `react` for every foreign event in its Subscribes table, and the coverage theorems of threat 1 must hold over its examples. A design whose model has tables and no decisions fails the same check as one with no examples. The vertical slice in the roadmap is the proof that this is bearable.

## Sources

- Hana Chockler, Orna Kupferman and Moshe Vardi, [Coverage Metrics for Formal Verification](https://www.cs.huji.ac.il/~ornak/publications/charme03a.pdf), CHARME 2003; *Coverage Metrics for Temporal Logic Model Checking*, TACAS 2001 · Orna Kupferman, [Sanity Checks in Formal Verification](https://www.cs.huji.ac.il/~ornak/publications/concur06b.pdf), CONCUR 2006
- Kaiyuan Wang et al., [MuAlloy: a mutation testing framework for Alloy](https://kaiyuanw.github.io/papers/paper7-icse18.pdf), ICSE 2018 · [MutDafny](https://arxiv.org/pdf/2511.15403), 2025
- Horatiu Cirstea, Markus Kuppe, Benjamin Loillier and Stephan Merz, [Validating Traces of Distributed Programs Against TLA+ Specifications](https://arxiv.org/abs/2404.16075), SEFM 2024
- [Plausible](https://github.com/leanprover-community/plausible), property-based testing for Lean 4
- Fraktalio, [fmodel](https://github.com/fraktalio/fmodel) and [Aggregating the Behaviour](https://fraktalio.com/fmodel/docs/domain/aggregating-the-behaviour)
- [in-toto and SLSA](https://slsa.dev/blog/2023/05/in-toto-and-slsa); the in-toto attestation framework's test-result predicate
- Cedar and SampCert: see [foundations.md](../docs/foundations.md) and the [white paper](../white-paper.md) bibliography
- This directory: `Calculus.lean`, the sections "Threat 1, mechanism A" and "mechanism B"; the two mutants were run in copies not kept
