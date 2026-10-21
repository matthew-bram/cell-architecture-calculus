# Lean and the journeys

Research note · Oct 12, 2026 · an agent, from the owner's hypothesis

The owner's hypothesis, stated this morning: journeys as the documents define them are directed acyclic graphs; if so, they can be proven up and down the stack as a mathematical functional program; and if that holds, a proof assistant such as Lean could represent the graph during data modeling and become a pillar of the documentation method. The want behind it: a way to show that the documentation is (1) understood the same way by any agent and any human, (2) accurate and eventually testable, and (3) actually lands in the code.

This note tests the hypothesis against the journeys as written in `architecture-vision.md`, the capability map and the product technology architecture, reads what Lean can and cannot do for each of the three wants, and reports a proof of concept run today against the real capability map. The Lean file, `Journeys.lean`, was beside this note in the trial's repository and is not published; its public successor is `../examples/library/JourneyMap.lean`. This note was written in `docs/research` and moved to this directory the same day; the owner's reading of the cycle finding is in [the-dag-rule.md](../docs/the-dag-rule.md), and the "Revised the same day" section below carries the change.

**Confidence.** **[H]** run here today, or read in the project's own documents or the tool's own documentation; **[M]** read in a search summary or a paper abstract; **[L]** reported by third parties or not verifiable here. Links in Sources were fetched on Oct 12, 2026 unless listed under "Could not verify."

## Summary

**Revised the same day: see "Revised the same day" below.** The first reading, kept here as written, found the journeys cyclic; the owner's rule turns that into a distinction between two relations, and the Lean file now checks both.

**The hypothesis is right about the step inside a journey and wrong about the journeys as a whole, and that is fine.** Each journey's steps form a directed acyclic graph: every step waits only on earlier steps, with fan-out and fan-in (journey 7's step 5 runs the Analyst and the Steward side by side, and step 6 joins them). But the journeys reference each other in cycles: 7 reuses 11 and 12, and both end by booking "as in journey 7"; 7 reuses 9, and 9 "starts with new data arriving (journey 7)". The vision calls journey 7 "the everyday loop" because it is one. The cell graph is cyclic too, by design: budgets commands the books and the books publish events budgets reacts to. The acyclic things are the zone graph, whose directions never reverse, and the composition relation from journey to capability to design. **[H]**

**The DAG condition is sufficient, not necessary, for the functional reading.** A journey whose steps wait only on earlier steps is a fold: a pure function from a starting state through each step, with index order as a topological order. That is what "a journey is a functional program" means precisely, and Lean states it in four lines. The cyclic journey graph is a state machine; each of its finite walks is a DAG of step occurrences, and its invariants are proved by induction on traces. Lean handles both; the cycle costs nothing. **[H]**

**Lean fits, with its scope stated exactly: it proves the model, never the prose and never the production code.** Against the three wants:

1. *Understood by any agent and any human.* A Lean definition has one meaning and the kernel checks it, so two readers cannot disagree about what it says. Agents write and check Lean well in 2026, and the proof of concept below was written by one in an hour. Humans still need the prose beside it; Lean's own answer to that is Verso, a literate framework in which prose and checked code are one source. What Lean cannot do is prove that the formal model means what the prose intended. That gap, the specification gap, is a human review, and it stays. **[H]**
2. *Accurate and testable.* Internal consistency is decidable today and costs no proof effort: the journey matrix agrees with each journey's text, every path respects the directions that never reverse, each journey passes through the private zone, each statement has one owner. Accuracy to the world (that a tenant behaves this way, that an aggregator sends this) is outside any proof assistant. "Eventually testable" is exactly the pattern AWS used for Cedar: the Lean model is executable and is the oracle, and the production implementation is tested against it with millions of random inputs. **[H]**
3. *Lands deep in the code.* By generation and differential testing, not by proof, unless the code is written in Lean. The honest chain is: prose → Lean model (proved) → generated types, schemas and tables (derived, so they cannot drift) → production code (tested against the model). The same gap exists for TLA+ and Alloy, with the same answer. **[H]**

**The proof of concept ran.** Eleven theorems about the real capability map, zones, journey 7 as a step graph and as an `Except` pipeline, and the composition and succession relations between journeys, each discharged by `decide` or `rfl` (Lean computes the answer and the kernel certifies it). Two deliberately wrong theorems, a path from the AI zone toward the private zone and a drifted matrix row, were rejected with "decide proved that the proposition is false." Lean 4.34.1, core only, no library. **[H]**

**Recommendation.** Adopt Lean as a pillar in three steps, the first of which pays for itself now: (1) a checked structural model of the map, the matrix, the zones and the paths, kept beside the documents and run in CI; (2) the aggregate invariants from data classification and placement proved on executable models of the books core; (3) the Cedar pattern for the bookkeeping pipeline, the one place where "the same transaction booked once" is a correctness claim worth an oracle. Record the rule as an owner's method in the methodology. The costs are real and listed below; the first step costs a day.

## Revised the same day

The owner read the cycle finding and ruled: choreography must not take a cyclic shape, every journey is a DAG, and the mechanism is that any output one cell yields to another is `Either[Ex, B]`. [the-dag-rule.md](../docs/the-dag-rule.md) records the rule. What it changes in this note:

- **The cycles found were in a relation that mixes two things.** "What it reuses" names both *composition*, a journey running another as a step, and *succession*, a journey's last fact triggering a new instance of another. Split, composition is acyclic and succession is where the everyday loop lives. The Lean file now checks both: `composition_isAcyclic`, `succession_cycles`, and `reuseAsWritten_hasCycle` for the old reading. **[H]**
- **A journey written in `Except` is a DAG by construction.** `Either[Ex, B]` is Lean's `Except Ex B`. Journey 7 is now in the file as a `do` block of Kleisli arrows with fan-out and fan-in, and three facts about it check: a good run's outcome, a duplicate short-circuiting, an alert firing. A journey that tried to loop inside itself was rejected at compile time with "fail to show termination", because Lean accepts only total functions. **[H]**
- **The cell graph's cycle is a projection, not a journey.** Budgets commanding the books and reacting to their events is two different journeys' steps landing on the same two cells. The rule the owner's goal needs is on journeys, and on the event graph between cells; the rule document says which and how to check it.

## The hypothesis, tested against the documents

| Structure | Acyclic? | Evidence |
| --- | --- | --- |
| The steps of one journey | Yes | Every "Steps" section is numbered, and a step uses only what earlier steps produced; journey 7 fans out at step 5 and joins at 6. Encoded and checked: `newDataArrives_isDag` **[H]** |
| The journeys as a graph, by "What it reuses" | No | 7 → 11 → 7 ("the loop closes when the file is booked (journey 7)"); 7 → 12 → 7 ("the data catches up through journey 7"); 7 → 9 → 7 ("it starts with new data arriving (journey 7)"); 14 → 7 and 14 → 9. Checked: `reuseAsWritten_hasCycle`. Revised: split into composition, acyclic, and succession, cyclic; see [the-dag-rule.md](../docs/the-dag-rule.md) **[H]** |
| Journey → capability (the matrix) | Yes | Bipartite; one direction only. Trivially acyclic **[H]** |
| Capability → capability (the paths) | No, by design | Budgets commands the books' allocations; the books publish the facts budgets reacts to (method 5). Choreography is cyclic in the dependency graph. Checked: `cellGraph_hasCycle` **[H]** |
| Zone → zone (the directions that never reverse) | Yes | The private zone opens toward the AI zone and never the reverse; devices reach only the private zone and the edge; the operations zone reads logs and writes only to control-plane queues. Checked on a slice: `aiZone_never_opens_toward_privateZone` **[H]** |
| Document ownership ("each statement has one owner") | A tree | One owner per statement; others cite. The citation graph has cycles (the map cites the methodology and the methodology cites the map), but citation is not ownership **[H]** |

Two refinements the test forces on the hypothesis:

- **The DAG is over step occurrences, not capabilities.** Notifications appears at step 1 and step 6 of several journeys. The matrix row is "in the order the journey uses them," a walk through the capability graph, and a walk may revisit a node. So the nodes of the journey's DAG are its steps, each labeled with the capabilities it uses, and a capability can label many steps. The proof of concept encodes it this way.
- **"Up and down the stack" means three different relations.** Down from a journey is composition: journey → steps → capabilities → designs → aggregates. Across is choreography: cell → event → cell, cyclic. Down from a cell is refinement: the design's rules → the data model → the code. Only the first is a DAG. The second is a state machine. The third is where proof meets code, and the section on landing in the code says how far it reaches.

## What Lean can and cannot do for the three wants

### Understood by any agent and any human

What Lean gives is a single meaning. `def matrixRow7 : List Cap := [...]` means exactly one thing, the kernel checks that every use of it is well-typed, and a theorem about it either checks or does not. Two agents reading the file cannot disagree about what the file says. That is stronger than any prose convention, including this project's "one owner per statement" rule, which is enforced by review.

Agents write Lean. The field moved fast between 2024 and 2026: Lean Copilot automates about three quarters of proof steps when driving a proof on its own **[M]**; agentic systems mechanized a 14,000-line Lean development with an 87% task success rate **[M]**; the Lean FRO's current roadmap says "AI-generated proofs are becoming a major source" of tactic use and plans documentation for agent compatibility **[H]**. The proof of concept below is a small example: an agent wrote it from the documents in one sitting and every check passed on the second compile. For the decidable class of property this note recommends first, the agent never writes a proof at all; it writes a definition and the word `decide`.

Humans read Lean less easily, and this project's documents are written for a human owner first. Two answers. The near one: the markdown stays the owner of meaning and the Lean file is cited from it, like a research note; a reader who does not read Lean reads the theorem names and the comments, which the proof of concept keeps in plain language. The further one is Verso, the Lean FRO's literate framework, which "produces PDFs and interactive web pages from a single literate source," with cross-references to Lean declarations checked at build time, so the prose cannot name something that does not exist **[H]**. The FRO's roadmap for September 2026 to February 2027 moves Verso "from prototyping to maturity and adoption" and adds Verso Blueprints, "dependency-graph project views in the same framework" **[H]**. That is a document in which the journey's prose, its step graph and the graph's drawing are one checked source. It is not mature enough today to move this project's documents into; it is the direction to watch.

What Lean cannot do is close the specification gap. A model that type-checks can still be the wrong model of what the prose meant, and nothing in the kernel knows the prose. The review that compares them stays a human job, and the model is a third artifact beside the prose and the code that must be kept honest. The mitigation is to make the model small and to derive from it rather than copy it: a matrix generated from the Lean file cannot drift from it.

### Accurate and eventually testable

Three layers, in rising cost.

**Decidable structure, today, at no proof cost.** Everything in the proof of concept is this layer. Finite lists, finite enumerations, a Boolean function, and `decide`. Properties this covers in the project's documents now:

- the journey matrix row equals the capabilities the journey's steps name (two hand-kept tables that nothing checks today);
- every journey but 1 and 18 passes through the private zone; every one passes through telemetry;
- every path's initiator respects the zone directions that never reverse;
- every event carries exactly one tenant ID for its zone (method 3);
- every capability on the map has exactly one design and one zone, and every design's "Serves" row is its column of the matrix;
- every term a design uses is in the glossary or in that design's own context (methodology risk row 4).

Four of the methodology's five risk rows are "0 at each review" promises about exactly this kind of structure. They could be theorems that run instead of reviews that are held.

**Invariants on aggregates, with proofs.** The aggregate roots in data classification and placement each name an invariant: allocations always sum to the account's balance; a transaction's postings sum to zero; a posted transaction is never edited, only corrected by a new one that points at it; one transaction changes one aggregate. Each is a theorem about an executable model of the aggregate: define the state, define each command as a function, prove each command preserves the invariant. Dependent types let the invariant live in the type itself, so a state that breaks it cannot be constructed. These proofs are short for the books (sums, list membership) and the LeanMachines work shows the pattern at scale for state machines with refinement, Event-B's method on Lean 4, where "machine states, event structures and refinement steps cannot be constructed fully without discharging the prescribed proof obligations" **[M]**. Cost: hours to days per aggregate, and the agent tooling above applies.

**Accuracy to the world: not Lean's.** That tenants download files, that an aggregator's webhook carries what the paths table says, that a bank statement arrives monthly: these are research notes and tests against real systems. Lean's model takes them as assumptions, and the honest form is to write them as such, so the reader sees what is proved and what is assumed.

"Eventually testable" is the third layer, and it is the next section.

### Landing in the code

The precise claim Lean supports: the production code can be shown to agree with the proved model, by testing, on every input tried. Not proved, unless the production code is itself in Lean, which for a system of private zones, phones and a cloud event fabric it will not be.

**The Cedar pattern** is the worked example and it comes from AWS, which also funds the Lean FRO **[H]**. Cedar's evaluator, authorizer and validator are written as total Lean functions over algebraic datatypes, and the security properties are proved about them. The Rust engine that runs in production is tested against the Lean model by differential random testing: "millions of random policies and requests are evaluated in both the Rust engine and the Lean model with results compared," and any difference is a bug **[H]**. The authors call it verification-guided development: "write an executable model of the system and mechanically prove properties about the model; write production code and use differential random testing to check that the production code matches the model; and use property-based testing to check properties of unmodeled parts" **[H]**. SampCert, AWS's differential-privacy sampler, went further: the verified Lean code is the production code, and it is "twice as fast as the previous one," deployed in AWS Clean Rooms **[M]**.

For this project the Cedar pattern fits one place well and others loosely:

| Where | What the Lean model is | How the code is held to it |
| --- | --- | --- |
| Bookkeeping pipeline: dedupe, pair, stage, commit | An executable model over normalized transactions, with "the same transaction seen twice is booked once" and "postings sum to zero" proved | Differential random testing of the production pipeline against the model, with synthetic tenants, which the contract's rule 7 already asks for |
| The books' commands and the close's lock | The aggregate models with their invariants | The same; plus the model's command list generates the gateway's command enumeration |
| The map, matrix, zones and paths | The structural model | Generated artifacts: the matrix table, each design's "Serves" row, the path table, the event-schema types in the implementation language. A generated table cannot drift; a hand-kept one can |
| The journeys as state machines | Each journey's step graph; the reuse graph | Trace tests: a run of the real system emits the events; the model says which traces are allowed. TLA+'s "trace validation" is the same idea |
| Agent roles' bounded tools | A list of (role, tool, gateway, verb) | Generated allowlists; the runtime refuses what the list omits |

The relation that reaches deepest, then, is generation: the types the code is written against come from the model, so the direction the documents point is the direction the compiler enforces. The relation that reaches furthest is testing against an oracle. Proof reaches the model and stops there, and a document that says so is more trustworthy than one that claims more.

## The proof of concept

`Journeys.lean`, about 200 lines, core Lean 4.34.1 with no library. What it encodes, from the documents:

- `Cap`: the twenty application capabilities and three platform capabilities as an enumeration; `Cap.zone` from the "cells by zone" table; `Cap.isPlatform`.
- `Step` and `Journey`: a step names its capabilities and the earlier steps it waits on; a journey is its steps and the journeys it reuses. `Journey.wellFormed` is the one rule that makes the step graph a DAG by construction.
- `newDataArrives`: journey 7's six steps, with step 5 split into the Analyst and the Steward.
- `matrixRow7`: row 7 of the capability map's journey matrix, as written.
- `composition` and `succession`: the "What it reuses" references among journeys 0, 7, 8, 9, 10, 11, 12, 14 and 26, split by whether a journey runs another as a step or its last fact starts a new run; `reuseGraphAsWritten` keeps the unsplit reading.
- `journey7` as an `Except Ex` pipeline: six Kleisli arrows in a `do` block, with `Ex` the named exceptions, fan-out to the Analyst and the Steward and fan-in at the last step; `journey11_download` shows succession as code, a new run of 7 and no recursion.
- `paths`: seven rows of the paths table, each with initiator, target and kind.
- `Journey.run`: the fold that reads a DAG of steps as a functional program.

What it checks, each by `decide`:

| Theorem | Claim in the documents | Result |
| --- | --- | --- |
| `newDataArrives_isDag` | A journey's steps wait only on earlier steps | Checks |
| `matrixRow7_matchesJourney` | The matrix row and the journey's text name the same capabilities | Checks: the two hand-kept tables agree today |
| `journey7_passesThroughPrivateZone` | The private zone is in every journey but 1 and 18 | Checks |
| `composition_isAcyclic` | No journey runs itself through the journeys it runs as steps | Checks: the owner's rule holds for composition |
| `succession_cycles`, `reuseAsWritten_hasCycle` | The everyday loop is a succession of runs; read unsplit, the references cycle | Checks: the cycle is in succession only |
| `journey7_ok`, `journey7_shortCircuits`, `journey7_alert_fires` | A journey in `Except` runs to its outcome, or stops at a named exception | Checks, by `rfl` |
| `aiZone_never_opens_toward_privateZone` | The AI zone opens nothing toward the private zone | Checks on the slice |
| `cellGraph_hasCycle` | Cells are cyclic by design | Checks |

What it caught when given wrong input, in a copy not kept: a query from the books to the private zone added to the paths, and a matrix row with alerts dropped and goals added. Both rejected: "Tactic `decide` proved that the proposition ... is false." **[H]**

Two things it does not do, on purpose. It does not model all 27 journeys; the point was to show the shape, and the rest is transcription. It does not prove anything that needs a written proof; every check is a computation the kernel certifies, which is the class this note recommends starting with.

To run it: install Lean's version manager `elan` (one script, ~1 minute, puts `lean` and `lake` in `~/.elan`), then `lean Journeys.lean`. Today's run used an install confined to the session's temporary directory; nothing was added to the machine.

## How this would become a pillar of the method

A candidate owner's method, in the methodology's form, for the owner to accept or reword:

**The structural claims of the documents are a model that checks** (proposed 2026-10-12). The map, the matrix, the zones, the paths, each journey's steps and each aggregate's invariant are definitions in a Lean model kept with the documents, and the claims the documents make about them are theorems that run. Why: the methodology's risk rows promise "0 at each review" for drift between the three views, misplaced statements, interpreted foreign IDs and forked language, and a promise that a program checks is kept more often than one a review holds. Implies: the markdown stays the owner of meaning and cites the model the way it cites a research note; what can be generated from the model is generated, never copied; a design that adds a path, an event or a journey step adds it to the model in the same change, and the check runs in CI; the production code is tested against executable models where the model is the oracle, starting with the pipeline; proof reaches the model, and the documents say so.

In the order of work it slots after the books' data model and before the technology reference, because the first useful theorems are about the structures those two documents fix. Three steps:

1. **Structure, a day.** Transcribe the map, the matrix, the zones and the full paths table; encode all 27 journeys' steps and reuse lists; run in CI. Generate the matrix and each design's "Serves" row from it, or check them against it. The methodology's risk rows 1, 2 and 4 become theorems.
2. **Aggregates, days.** Executable models of the books core's aggregates with their invariants proved, read from the books' data model. The gateway's command enumeration is generated from them.
3. **Oracle, when the pipeline is built.** The Cedar pattern on the bookkeeping pipeline: the model as the oracle, synthetic tenants as the input generator, differential tests in the release pipeline.

## Alternatives considered

| Tool | What it is best at | Why not first here |
| --- | --- | --- |
| Alloy | Finite relational models with an instant counterexample finder; the classic tool for "every X has one Y" structure | Covers step 1 as well as Lean and finds counterexamples faster, but stops there: no executable model, no proofs, no path to step 2 or 3, and little agent tooling in 2026 |
| TLA+, Quint | Concurrent and distributed protocols; model checking of state machines; trace validation against a running system | Right for the fabric and the choreography if a protocol bug is suspected; a second language with no link to the data model or the code's types. Worth adding for crossing the zones if the bridge turns out to be subtle |
| Event-B | Refinement from an abstract machine to code with proof obligations | Its method on Lean 4 exists as LeanMachines **[M]**, so Lean gives it without a second tool |
| Property tests in the implementation language | Cheap, familiar, runs in CI | The right step 3 complement, and no substitute for a checked model: a property test cannot say the matrix and the journey agree |
| Dafny, F\* | Verified programs in their own language | Smaller ecosystems, far less agent tooling, no literate story like Verso |

Lean's case: one language for definitions, executable code and proofs, so step 1 grows into steps 2 and 3 without changing tools; dependent types that let an invariant live in the data model's type; the best agent tooling of any proof assistant in 2026; the AWS precedent at exactly the pattern recommended; and the FRO's roadmap putting "first-class support for intrinsic verification" and "building blocks that let external teams verify real software in Lean" in the next six months **[H]**.

## Costs and risks

- **The learning curve.** Lean's decidable layer is learnable in a day; writing proofs is not. The recommendation keeps the owner at the first layer and lets agents carry the second.
- **A third artifact.** Prose, model and code can drift three ways instead of two. Mitigation: generate from the model wherever a table or a type is concerned, keep the model small, and make adding to it part of the same change as adding to a design.
- **Toolchain churn.** Lean releases monthly and a file pinned to one version may need edits at the next **[H]**. Pin the version in the repository (a `lean-toolchain` file) and upgrade on purpose.
- **Overclaiming.** The failure mode of formal methods in documentation is a page that says "proven" about something only modeled. The documents should say what is proved, what is checked by computation, what is tested against the model, and what is assumed, in those words.
- **Verso is not ready for this project's documents.** The FRO calls it prototyping moving to maturity. Watch it; do not move the markdown into it yet.

## Could not verify

- [LeanMachines: State-based Modeling with Refinement (a Lean4 Framework)](https://dl.acm.org/doi/10.1145/3796230), ACM returned 403; the description here is from the search summary **[M]**.
- The Lean Copilot figures and the 14,000-line mechanization are from search summaries of the papers, not the papers **[M]**.

## Sources

- Run here: Lean 4.34.1 (arm64-apple-darwin), `Journeys.lean`, Oct 12, 2026
- [The Lean FRO Year 4, Part 1 roadmap](https://lean-lang.org/fro/roadmap/y4-1/) · [Lean FRO, about](https://lean-lang.org/fro/about/) · [Amazon is investing in the Lean FRO](https://www.amazon.science/news/amazon-is-investing-in-the-lean-focused-research-organization) · [The Lean Theorem Prover: Design, Evolution, and Impact](https://leodemoura.github.io/static/floc26/) · [Software Verification in Lean 2026](https://beneficial-ai-foundation.github.io/SVIL2026/)
- [How we built Cedar with automated reasoning and differential testing](https://www.amazon.science/blog/how-we-built-cedar-with-automated-reasoning-and-differential-testing) · [How We Built Cedar: A Verification-Guided Approach](https://arxiv.org/abs/2407.01688) · [cedar-spec, the Lean definitional implementation](https://github.com/cedar-policy/cedar-spec)
- [Lean4Agent: Formal Modeling and Verification for Agent Workflow and Trajectory](https://arxiv.org/abs/2606.06523) · [Automating Formal Verification with Agent-Guided Tree Search](https://arxiv.org/pdf/2605.27485) · [Lean Copilot](https://www.emergentmind.com/topics/lean-copilot) · [LeanMachines](https://dl.acm.org/doi/10.1145/3796230)
- The trial's own documents, not published: `architecture-vision.md`, journey map · `capability-map.md` · `methodology.md` · `product-technology-architecture.md` · `data-classification-and-placement.md`
