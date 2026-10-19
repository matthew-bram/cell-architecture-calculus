# The calculus

The shapes of the method, each with its theorem, its source and the file it lives in. The generic shapes are the package [`cell-calculus`](../cell-calculus/), one module per idea, carrying only universal theorems, generic over a project's principal through one class and over the subject an event is about as a type parameter, with trust boundaries as an opt-in module. One project's instantiation is the package [`Library`](../examples/library/) in the worked example, and every claim below is shown on it.

Stated in Lean, because the statement is also the check. Type parameters are words, not letters, and every declaration carries a comment saying what it is and what the shape is called in the sources.

## The problem the calculus answers

Documentation for software has three defects it cannot cure on its own: nothing shows it is understood the same way by every reader, nothing shows it is accurate, and nothing shows that the code built from it went where it pointed. The documents make claims about structure, which capabilities exist, which journeys use them, which zones may talk to which, and the claims are kept by hand in several places that drift. Once the code exists nothing but a person's memory says whether it went where the documents pointed.

The calculus is the answer in four steps, each feeding the next. Design on practices with proved theory under them. State the design's structural and behavioural claims as a model in Lean, where what is decidable is decided by computation and what is universal is proved. Derive the specification by example from the model, so that each example is one row in the design, one theorem in the model and one test in the code. Carry the examples' results against the implementation, and the implementation's traces, back to the model as the judge. One rule makes the four steps one lifecycle: the domain types and the examples are authored once, in Lean, and everything else is generated from them or replayed into them. Prose owns meaning. Lean owns structure and behaviour. Generated views own nothing.

## The cell

The word is the cell-based reference architecture's: a cell is a self-contained unit of components with its own record and a gateway as the only way in, independently deployable and observable, communicating with other cells through its gateway and the facts it publishes. The calculus takes that unit and says what is inside it.

**Outcomes have three values.** `Cell.lean`.

```lean
inductive Exception (Reason : Type)
  | refused (reason : Reason)
  | unknown
```

`Either[Ex, B]` at every gateway, and `Ex` is itself a sum, `Either[Refused, Unknown]`. *Refused* is the cell's invariants saying no: deterministic, final, the journey stops at a named outcome. *Unknown* is the failure window: the effect may or may not have landed. The two sides come from different places, and the types say so. A cell's `decide` returns `Except Refusal (List Event)`, the inner `Either[Refused, B]`, so a cell can say yes or a deterministic no and nothing else. The third value is added only where a result crosses the wire: `liftToWire` maps a cell's result into `Except (Exception Refusal) B`, turning a refusal into `refused` and never producing `unknown`, which is the theorem `model_never_unknown`. Only the world produces it. The model's job is to say what the caller may do on it: retry with the same key, never decide as if the effect did not happen. Conflating the two is the specific bug the window produces, a timeout treated as a refusal and an effect that landed compensated away.

**A cell is three pure functions.** `Cell.lean`.

```lean
structure Cell (Command ForeignEvent Event State Refusal : Type) where
  initial    : State
  decide     : Command → State → Except Refusal (List Event)   -- Command => State => Event
  react      : ForeignEvent → State → List Event              -- Event => State => Event
  evolve     : State → Event → State                          -- the fold
  isTerminal : State → Bool
```

The parameters are the cell's commands, the foreign events it subscribes to, its own events, its state and its refusal reasons. It is the Decider of functional event sourcing with a reaction added and the command sink removed. No function returns a command. `Event => Command` is not forbidden by a rule; it is unrepresentable, and an attempt to write it is rejected at the type. State is the fold of the cell's own events and nothing else: `replay history = history.foldl evolve initial`. Determinism is not a property to test; the functions are pure by construction. `replay_append`, that replaying `h ++ h'` equals replaying `h` and then folding `h'`, holds for every cell and every history, and it is what makes a snapshot sound.

In the example, `circulation` decides checkouts, returns, renewals and the close on the loans a card holds; `notices` reacts to circulation's facts and commands nothing; `pickup` reacts to two cells' facts and remembers whichever came first. The idempotent receiver is a theorem about the cell, not a test of one case: `checkOut_idempotent` says that for every key, item and open-card state in which the key was already honored, a repeated checkout produces no event.

**Six rules the calculus takes from the foundations**, each with its source in [foundations.md](foundations.md).

1. Every gateway is an idempotent receiver. A command carries a key its caller minted before the first remote call and persisted with the caller's intent.
2. A command's outcome has three values, not two. `unknown` is the window made visible.
3. A saga records its intent before its first remote effect and its result after its last, and is resumable from the intent between the two.
4. Events are published from the same record as the state, never from memory: the outbox.
5. Queries create no obligation and carry no window.
6. Non-determinism lives at the roots. People, time, partners and any automated judgement are sources of facts. A judgement is an event carried in a published schema; everything downstream is a pure reaction, testable with the judgement as a Given. This is the rule that lets a language model, or any heuristic, sit inside a deterministic architecture.

## Journeys

**A journey is a DAG by construction, two ways.** `Journey.lean`, and `JourneyMap.lean` in the example. A journey transcribed from a design's tables is a list of steps, each naming the earlier steps it waits on, and `wellFormed` checks that every edge points backwards. A journey written as code is a `do` block in `Except` whose steps are the cells' `handle` and `handleForeign`. Lean accepts only total functions, so a journey that re-entered an earlier step would need recursion it cannot prove terminating, and is rejected with "fail to show termination".

**A journey is a term, and every term compiles to a DAG.** The two ways meet in an algebra with three constructors and no loop:

```lean
inductive Journey (State Refusal : Type)
  | step (name : String) (run : State → Except Refusal State)
  | seq  (first second : Journey State Refusal)
  | par  (left right : Journey State Refusal) (merge : State → State → State)
```

`run` is its denotation, one function; `run_seq` and `run_par` say the composite is the composition, by definition. `compile` numbers a term's steps and records what each waits on. The theorem `compile_wellFormed`, by structural induction over the three constructors, says every term's compiled graph satisfies the same `nodesOk` rule the transcribed journeys are held to, so a journey from the vision document and a journey composed in the algebra are checked by one rule. The borrow journey of the example, circulation deciding then notices reacting, is such a term, and `borrowJourneyTerm_warns` says it runs to the same outcome as the hand-written `do` block.

**A journey is a cell.** The composite of a `decide` and a `react` has the decider's signature: a root command in, the product of histories as state, a refusal or events out. Composition is closed, so journeys compose into journeys under the same rules and the whole system is one cell. Two consequences. The composite's state is a product and never a merge, so a cell seeing only its own state is visible in the type of every journey. And function composition is associative, so where the cut between cells falls is a parenthesization and the composite is the same under every choice: a boundary can move without the behaviour changing.

**Choreography realizes composition.** In the composite, fan-in is a function of two arguments and time is gone. In the world the two facts arrive one at a time, in either order, and the reacting cell must remember the first while waiting for the second. The composite is the denotation; the choreography is the operational reading; the theorem with content is that they agree. For the example's hold shelf, which readies a copy when it has come in and a hold is waiting, `deliver_returnFirst` and `deliver_holdFirst` say that delivering the two facts one at a time in either order readies the copy exactly as the two-argument function does, for every copy, and `deliver_oneFact_notReady` says nothing is ready after one fact alone.

**Composition and succession.** A journey may run another as a step (composition), and that relation must be acyclic. A journey's last fact may be the trigger of a new run of another (succession), and that relation may cycle, because each edge is a new fact and a new run. The everyday loop of a product is a succession of DAG runs, never one cyclic journey. The example's `composition_isAcyclic` and `succession_cycles` are the two theorems, and `referencesWithoutKinds_cycle` shows what the map would find if the two were mixed. The full argument is [the-dag-rule.md](the-dag-rule.md).

**Contracts fold along a journey.** `Contract.lean`. A step's non-functional contract is one assumption and a guarantee per viewpoint, and the guarantees fold along the journey algebra with a rule per viewpoint: latency is the sum along a sequence and the max across a fan-out, which is the critical path of the compiled DAG; unavailability budgets and cost add along both constructors, because a `par` is all-must-succeed and so is series for everything but time; peak resource is the dual of latency. `elapsed_le_latencyBound` is the compositional theorem: if every step honoured its own bound, the journey's run is within the folded bound, for every journey, every set of contracts and every run. The three monotonicity theorems are the refinement direction: a cell may tighten a guarantee and no journey's bound gets worse. The sources are Benveniste and others on contracts for system design, and network calculus for concatenation as a sum.

## The wire, and the examples

**The wire is a projection, and the parse is in the model.** `Wire.lean`. Proto, JSON Schema and Avro cannot say what the model's sum types say: no invariants, loose fields. So the wire shape is a projection of the model's type, and what the projection loses is a list per schema, every item of which is one thing, a refusal at parse time. A command type's codec is a class, `WireCodec`, whose third field is the round-trip law, so an instance cannot exist without the proof that every command survives the wire. The gateway, parse then decide, is generic over the class, its refusal type is the sum of the two kinds, and `gateway_serialize` says that for every cell, history and command, the gateway on a serialized command is the cell's own decision. The same pair serializes every example into a fixture and parses every trace back, so the model and the tests share bytes rather than a description of the data. Two more classes make the rest generic: `Kinded` numbers a sum type's constructors so the coverage checks are one definition for every project, and `Describe` gives each constructor a sentence so the Gherkin renderer is too.

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

## The envelopes, inputs, boundaries

**The envelopes.** `Envelope.lean`. Nothing so far said what a command or an event carries besides its payload. Two envelopes, defined once, wrap every command and every event:

```lean
structure CommandEnvelope (Payload : Type) where
  actor       : Actor              -- what identity answered, never looked up in decide
  key         : IdempotencyKey     -- minted by a device or partner; derived from the cause inside
  causation   : Option EventId     -- the one fact this command succeeds
  correlation : RunId              -- the journey run
  issuedAt    : Instant
  payload     : Payload

structure EventEnvelope (Payload Subject : Type) where
  id          : EventId
  causation   : CausationId        -- a command key or an event id: the DAG edge
  correlation : RunId
  version     : SchemaVersion
  subject     : Subject            -- what the event is about; a bounded ID where the project has zones
  recordedAt  : Instant
  payload     : Payload
```

No property-bag headers: a cell reads only the fields the type names, and a decider that reaches for a header the envelope lacks is rejected at the type. The fold never sees an envelope; the shell wraps what a decider emits. `Actor` is a sum over the five kinds of sender any system has, a principal in the project's own terms, a policy cell, the timer, a partner and the operator, so a decider's actor branch is a `match` the kernel checks is total. `Cell.gated` lifts any cell to the envelope with a policy saying which actor may issue which command: a refused actor gets no further, an allowed actor gets exactly the inner decision, and the fold is untouched, each a theorem for every cell and policy. A policy written as permits and forbids carries Cedar's trio as theorems: a forbid overrides every permit, a permit is required, an empty set of permits denies everything, and the rules are a set, so their order and duplicates do not matter. A derived key names its issuer and its cause, so a retry derives the same key without remembering anything. With causation and correlation on every event, a run's shape is checkable without replaying it: the events become nodes needing the event they cite, and `Run.conforms` is `nodesOk` again, the rule the compiled journeys are held to. `envelope_conforms` says that what the shell publishes on any command, for any cell, subject, clock reading and minting function, is a run that conforms. In the example a guest's checkout is refused before circulation is consulted, `loanActor1_holds`, and a run in which the warning was recorded before the checkout it cites is rejected on shape alone, `backwardsRun_rejected`.

**Inputs, never calls.** `Inputs.lean`. `decide` is pure, and a decider may need another cell's answer or the date. The shell gathers every query answer and the clock reading before it calls `decide` and hands them over as one argument beside the command. A decider that reaches for the clock is rejected at the type, because `decide` returns `Except` and not `IO`. A query is a pure read of the owning cell's state, and its answer is stamped with the owner's version, so a decision made on it records what it was made on and the owner refuses the resulting command if it has moved on since. The clock is a cell whose events are ticks, and `tick_monotone` says its history never runs backwards. A command that declares no query reads none, for every envelope, every pair of answers and every pair of readings. Examples gain a *with* clause and traces record the inputs, so a replay is exact. In the example, fines assesses a late item on circulation's stamped answer and the day it is: `stillOut_fresh`, `stillOut_staleAfterCheckIn` and `assess_recordsCirculationsVersion` are the three halves, and `settle_readsNothing` is the no-reads theorem.

**Boundaries as types.** `Boundaries.lean`, opt-in. An identifier that must not cross a trust boundary is indexed by the boundary that knows it, so the kernel refuses a record in one boundary built with another boundary's ID. The alias map carries its inverse law as a field, so a map that does not invert cannot be constructed. The scrub is a parse from one boundary's event to another's, owned by one cell and the one function in the system whose type names two boundaries; `scrub_keepsEnvelope` says the run is one run on both sides, and `scrub_roundTrip` says that what the scrub lets through, re-identification returns exactly, for every map, tokenizer and event. In the example the desk knows a member by card and the stacks by patron token, the map between them has its inverse proved, and `deskFact_scrubs` carries a checkout fact across with its envelope kept.

## Where a fact may become a command

`Policy.lean`. In exactly one place: at a journey boundary, as succession. A journey ends with a fact; the fabric lifts the fact into a command to the one cell that subscribes to it as a root, mechanically, with the key derived from the fact, the fact as the cause and a fresh run, so that a retry of the lift is the same command, `succeed_sameKey`. That cell is a policy cell, whose `decide` is the one place a proposal becomes a downstream command and whose every branch names its rung: in shadow a proposal is recorded and never issues, in review it is held until a person approves it, in autonomous it issues, and an approval issues only what was held, each a theorem for every proposal and state. Any automation, a recommender, a scheduler, an agent, is this one shape, and the gated policy cell refuses an approval from the wrong actor before it looks at the ladder. In the example the reading assistant's renewal proposal runs through the three rungs, a member's approval issues it and a guest's is refused at the gate.

## Promises, and what an attribute quantifies over

`Promise.lean`. With `issuedAt`, `recordedAt`, `causation` and `correlation` on every event, a promise is a predicate over runs, evaluated in the same pass that checks a run's shape: within a duration, at most a count, never after a fence. The runs that fail are named, and a measure, the count kept over the count seen, sits beside the promise. `withinDuration_mono` says loosening a limit never breaks a kept promise, which is why a promise can be tightened in steps.

A quality attribute is checkable only once it says what it ranges over, so the `Attribute` type fixes that in its constructor: one run, which is a promise; a pair of runs, the shape of a confidentiality claim no single run can refute; a population, a promise with a threshold, which is a hyperproperty over the window; a distribution, which no finite set of traces checks and which the attribute says is measured; or the artifact, a decided proposition about the model itself. `population_kept_of_all` says a promise every run keeps is kept at any threshold. The example's "a limit warning within a minute of the checkout that reached it" is one line, a population promise at 99 per cent, and a run whose warning came five minutes late burns it by name.

## Governance of the model

`Governance.lean`. The changelog rule applied to the model. A theorem is never deleted; it is superseded by name with Lean's `deprecated` attribute, so a use of the old one warns and names its successor. An example is never deleted; it is marked superseded with the date and the reason, and the coverage theorems run over the live set, so that retiring an example without a successor fails coverage and the failure names the command kind, `hole_isNamed`. An event version is never removed; the upcaster from every version ever published is total by exhaustiveness, which is the check Lean already does. The project's header carries one review line per design, the design's path and its content hash at review, and the build checks it: a warning while unreviewed, a failure when the design changes under a signed line.

## The context map

`ContextMap.lean`. The journey map says which cells exist, where each lives and which arrows join them. The context map says what each arrow means to the two sides, in the vocabulary Evans and Vernon fixed: who is upstream and who is downstream, an open host service, a published language or a plain supplier upstream, a customer, a conformist or an anti-corruption layer downstream, partnership, shared kernel or separate ways where the design says so. The one computation is coverage: every arrow between two contexts is accounted for by a relationship in the right direction, `allCovered`, and adding a relationship never uncovers an arrow, `covered_mono`. What the relationship means in this method: a conformist's parse is the identity up to shape, and an anti-corruption layer's parse is a real translation, the only place a refusal means "not understood" rather than "no". In the example, notices translates because it puts the name back, every outside party is translated at the edge, and no core context conforms to a generic one.

## What it proves, checks, tests and assumes

Four words, in those places and no others. *Proved*: a universal theorem in the calculus or about a project's cells, true for every input, by `simp`, `cases` or induction. *Checked*: a decidable claim about one project's values, by `decide` or `rfl`. *Tested*: the code against the model, through the fixtures and the traces. *Assumed*: the world, every judgement a person or an automation makes, and whether the model means what the design intended.

## Limits

Each is a place the method can fail and what it does about it.

1. **The specification gap.** Lean proves the model, never that the model means what the prose intended. Four claims stand in for "the examples have the model's geometry", each with a different proof. Consistency: every example agrees with the model; a theorem. Coverage: the examples reach every part of the model; the structural half is a theorem over the example set, the behavioural half is mutation. Conformance: the implementation's behaviour is one the model allows; the trace is replayed. Provenance: these tests ran against this model, and this model was reviewed against this design; the stamp on every view and the review line in the header. What is not proved is refinement, that *every* implementation behaviour is a model behaviour. Mutation scores are evidence. The review is a review.
2. **Examples are not coverage.** Thirteen examples prove thirteen points. The next layer is random inputs drawn from the types with the compiled model as the oracle, the pattern Amazon used for Cedar, and random inputs that kill a mutant become examples. It is not built.
3. **The model-to-code link is testing, not proof.** In rising strength: traces and tests for every cell, with the claim written as "agrees with the model on every input tried"; the model as the code for a pure core, since `decide`, `react` and `evolve` have no I/O and Lean compiles to C; refinement proofs last and only where the second is impossible.
4. **Judgements are never proved.** A judgement is a root fact. The boundary is a type, the schema's parser is the oracle, and the theorems state what a judgement cannot do: a reaction to it emits events and never commands. Its quality is measured and reported beside the theorems, never mixed with them.
5. **The window is a value, not a model.** `unknown` is in the type and a rule in a comment. The saga as a cell with intent recorded, remote answered and result recorded, and the theorem that "intent, unknown, retry with the same key, ok" equals "intent, ok" for any idempotent receiver, is the next piece of theory.
6. **Event sourcing is a commitment.** Each cell keeps its history, as an event store where `replay` is literal or as versioned rows where a row version is an event and the current row is the snapshot that `replay_append` makes sound. A cell that keeps neither is one the calculus does not describe.
7. **Modelling what is easy to model.** A method that proves structure and skips behaviour proves the cheap thing. The annotation grammar makes behaviour mandatory: a design's model must contain a `decide` for every command in its Commands table and a `react` for every foreign event in its Subscribes table, and the coverage theorems must hold. A design with tables and no decisions fails the same check as one with no examples.

## Sources

- Adzic, Gojko. *Specification by Example.* Manning, 2011.
- Benveniste, Albert, and others. *Contracts for System Design.* Foundations and Trends in EDA, 2018.
- Bernhardt, Gary. "Functional Core, Imperative Shell." 2012.
- Chassaing, Jérémie. "Functional Event Sourcing Decider." 2021. https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider
- Chockler, Hana, Orna Kupferman, and Moshe Vardi. "Coverage Metrics for Formal Verification." CHARME, 2003.
- Cirstea, Horatiu, Markus Kuppe, Benjamin Loillier, and Stephan Merz. "Validating Traces of Distributed Programs Against TLA+ Specifications." SEFM, 2024. https://arxiv.org/abs/2404.16075
- Cutler, Joseph W., and others. "Cedar: A New Language for Expressive, Fast, Safe, and Analyzable Authorization." OOPSLA, 2024. https://arxiv.org/abs/2403.04651
- Dean, Jeffrey, and Luiz André Barroso. "The Tail at Scale." Communications of the ACM, 2013.
- Disselkoen, Craig, and others. "How We Built Cedar: A Verification-Guided Approach." FSE Industry, 2024. https://arxiv.org/abs/2407.01688
- Dymitruk, Adam. "Event Modeling." https://eventmodeling.org/
- Evans, Eric. *Domain-Driven Design.* Addison-Wesley, 2003.
- Garcia-Molina, Hector, and Kenneth Salem. "Sagas." SIGMOD, 1987.
- Helland, Pat. "Data on the Outside versus Data on the Inside." CIDR, 2005. "Life beyond Distributed Transactions." CIDR, 2007. "Idempotence Is Not a Medical Condition." ACM Queue, 2012.
- Hohpe, Gregor, and Bobby Woolf. *Enterprise Integration Patterns.* Addison-Wesley, 2003.
- King, Alexis. "Parse, Don't Validate." 2019. https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/
- Kingsbury, Kyle. "Jepsen: Bufstream 0.1.0." 2024. https://jepsen.io/analyses/bufstream-0.1.0
- Kupferman, Orna. "Sanity Checks in Formal Verification." CONCUR, 2006.
- Lamport, Leslie. "Time, Clocks, and the Ordering of Events in a Distributed System." Communications of the ACM, 1978.
- Le Boudec, Jean-Yves, and Patrick Thiran. *Network Calculus.* Springer, 2001.
- de Moura, Leonardo, and Sebastian Ullrich. "The Lean 4 Theorem Prover and Programming Language." CADE, 2021.
- Richardson, Chris. *Microservices Patterns.* Manning, 2018.
- Treat, Tyler. "You Cannot Have Exactly-Once Delivery." 2015.
- Vernon, Vaughn. *Implementing Domain-Driven Design.* Addison-Wesley, 2013.
- WSO2. "Cell-Based Architecture." https://github.com/wso2/reference-architecture/blob/master/reference-architecture-cell-based.md
- Young, Greg. *Versioning in an Event Sourced System.* Leanpub, 2017.
