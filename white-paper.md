<h1 align="center">Generate the Math, Then Validate the Implementation With It</h1>
<h3 align="center">A cell calculus in Lean 4 as the spine of a product development lifecycle</h3>

> *Software documentation has three defects it cannot cure on its own: nothing shows that every reader understands it the same way, nothing shows that it is accurate, and nothing shows that the code built from it went where it pointed. This paper presents a lifecycle in which the design is written on practices with proved theory under them, the design's structural and behavioral claims are a model in the Lean proof assistant, the specification by example is derived from that model so that each example is one row in the design, one theorem in the model and one test in the code, and the results of running those examples against the implementation are carried back to the model to confirm that the design's proofs still hold. The lifecycle has one rule: the domain types and the examples are authored once, in Lean, and everything else is generated from them or replayed into them. The shape of the model is a small calculus built on the cell of the cell-based architecture. A cell is three pure functions; every gateway returns a value or a refusal, with the failure window as a third value the model never produces; a journey is a term in an algebra that compiles to a directed acyclic graph; a journey is itself a cell; every command and event is wrapped in one typed envelope with no free-form headers; and the shape "an event becomes a command" is unrepresentable inside a cell. The calculus is the Decider of functional event sourcing with a reaction archetype added and a command sink removed, standing on Helland's failure window, Garcia-Molina and Salem's sagas, and Amazon's verification-guided development of Cedar. We report the method applied end to end on a worked example, a public library's circulation system: forty universal theorems in the generic package, one hundred and twenty-three checks in the example, a mutation gate of seventeen operators all killed, seven traces of which four are rejected for four different reasons, and a reference implementation tested against the generated fixtures by example id; and from an earlier trial on a private architecture, two coverage holes the mutation gate found that the examples had not. We state what the method proves, checks, tests and assumes, in those words; we give a proposal for each of the ten places it can fail; and we record the seven problems that had to be decided before the method was consistent, with what each leaves open.*

## 1. Introduction

Enterprise architects have spent a decade decomposing systems into units that teams can own: services, bounded contexts, cells. The decomposition has delivered on independence of deployment and of ownership. It has not delivered on agreement. The documents that describe such a system are read by people and, increasingly, by agents writing much of the code, and nothing shows that they read the same thing the same way. The documents make claims about structure, which capabilities exist, which journeys use them, which zones may talk to which, and the claims are kept by hand in several places that drift. The documents point at code, and once the code exists nothing but a person's memory says whether it went where the documents pointed.

The method starts from a corpus that is already well organized: one owner per statement, a capability map with a journey matrix, a cell per capability, and three verbs between cells. Such a methodology's risk register may promise zero of four kinds of drift at each review, between the matrix and the journeys, between the journeys and the designs, between the designs and the code, and between the code and what it does in production. A review is a promise held by attention and convention. The usual controls are reviews and templates, and both depend on it: a template says what a design should contain, not whether two designs agree, and a review catches what the reviewer notices, while the number of things to compare grows faster than anyone's time. The question this paper answers is whether those promises can be held by a program instead, and how far up and down the lifecycle a program can hold them.

Our answer is a calculus: a small set of shapes, stated in Lean 4, that every cell in a system is built from, with the theorems that hold for every cell built from them. The shapes are not new. Each has a published statement by someone who arrived at it independently, and the calculus's authority is that the shapes were found more than once. What is new is that they are one typed vocabulary, checked by a kernel, from which the examples a reviewer reads and the fixtures a test suite runs are generated, and into which the running system's traces are replayed.

The rest of this paper is structured as follows:

+ [**Section 2**](#2-the-hypothesis): States the hypothesis as four steps and one rule.
+ [**Section 3**](#3-foundations): Names the prior art each shape stands on.
+ [**Section 4**](#4-the-calculus): Defines the calculus, shape by shape, each with its theorem.
+ [**Section 5**](#5-the-method-as-documents-and-as-a-round-trip): Defines the method as five documents and a six-stage round trip.
+ [**Section 6**](#6-evidence): Reports the method applied to a worked example.
+ [**Section 7**](#7-where-it-can-fail-and-what-we-propose): Lists the ten places the method can fail, with a proposal for each.
+ [**Section 8**](#8-seven-problems-that-stood-in-the-way): Records seven problems that had to be decided before the method was consistent.
+ [**Section 9**](#9-a-call-to-contribute): Says where the method is open and asks for what comes next.
+ [**Section 10**](#10-conclusion): States what the method proves, checks, tests and assumes.

## 2. The hypothesis

Four steps, each feeding the next, and the last feeding back to the first.

1. **Design on strong practices with proved theory under them.** Not "best practices". Practices whose published statement comes with a proof or an impossibility result: the Decider for pure decision-making, Helland's failure window for at-least-once delivery, sagas for long-lived work without distributed transactions, Lamport's ordering for what "before" means across cells [22].
2. **Validate the design with Lean.** The design's structural claims become definitions and theorems. What is decidable is decided by computation; what is universal is proved.
3. **Use the design to generate the specification by example.** Each slice of behavior gets Given, When, Then examples. The model says what *then* must be for any *given* and *when*; the examples are chosen to cover the design's decisions and are theorems before they are tests. The fixtures the code's tests consume, and the readable form a reviewer reads, are rendered from the examples and never written by hand.
4. **Validate the examples against the design's proofs.** The same examples run against the implementation. A pass means the code agrees with the model on that example. A trace of the real system replayed into the model says whether the run was one the model allows. A failure in either direction names the slice and the example.

In one line: generate the math, then validate the implementation with the math. The rule that makes the four steps one lifecycle: **prose owns meaning, Lean owns structure and behavior, generated views own nothing, and the running system's traces are input to the model, with the model as the judge.**

## 3. Foundations

Every piece of the calculus has a prior statement by someone who arrived at it on their own. We name each here; the full lineage with its sources is in [foundations.md](docs/foundations.md).

**The Decider.** Chassaing gives functional event sourcing's core as a record of four things: `decide: Command -> State -> Event list`, `evolve: State -> Event -> State`, an initial state and a terminal predicate [1]. Decision is separated from state change by materializing the decision as events first. The same shape is Akka Persistence's command handler and event handler [23], and Event Modeling is the documentation method built on it, with commands, events and views on a swimlane per cell and Given, When, Then on each slice [2]. Fraktalio's fmodel library gives the Decider a `combine` operator, a monoid over the sum of commands and events and the product of states, which is the published form of "two cells packaged as one" [3].

**The reaction, and the forbidden sink.** The Decider record has no reaction. Chassaing's post gives one example of an event leading to a command and defers composition. Event Modeling admits an "automation" slice, `Event => Command`. This calculus adds `Event => State => Event` as a first-class, pure archetype and removes `Event => Command` from inside a cell entirely. The reason is geometric: a reaction that issues a command puts orchestration back into choreography and is the only way a journey can return to a cell it has already passed through. Forbid it, and every journey is rooted at a command or an external fact, every internal edge is an event, and the event graph between cells can be checked acyclic. Where a product needs an event to become a command, at the autonomous rung of an automation's ladder for instance, Section 4 places it: at a journey boundary, as a decision by a policy cell, never as a reaction.

**The failure window.** Helland: "There is a failure window in which the work is successfully applied to the database, but a failure prevents the messaging system from knowing the message was consumed. The messaging system will redrive the delivery of the message." [4] Precisely, the window is between the first remote state change a saga causes and the local commit of the offset that records it, and its cost is sized against the cost of the effect. The outbox literature calls the two writes the dual-write problem and makes the point that the window moves rather than disappears. Helland's earlier work gives the architecture that lives with it: entities that own their data, messages delivered at least once, activities idempotent against repeated messages [5], and the rule that data leaving an entity is immutable and identified [6].

**Why exactly-once does not remove the window.** Treat's two-generals argument covers delivery [7]. Confluent's own documentation scopes Kafka's exactly-once to a read-process-write loop whose ends are both Kafka topics; a consumer that calls another cell, changes a database or sends a notification is outside the transaction [8]. Jepsen's analysis of Bufstream characterized a flaw in Kafka's transaction protocol itself: "There is no sequence number to order requests from the same client. There is no concept of a transaction number," so a delayed `EndTxn` can commit or abort a different, later transaction, producing write loss, aborted reads and torn transactions. It is tracked as KAFKA-17754 and was unresolved at publication [9]. The window is the floor every design stands on.

**Sagas.** Garcia-Molina and Salem: a long-lived transaction as a sequence of local transactions, each with a compensating transaction [10]. This calculus runs a saga only inside the cell that owns the aggregate, consistent with the rule that orchestration happens inside a cell and choreography between them. Durable-execution engines, Temporal and Azure Durable Functions among them, are the industrial form: the workflow's history is persisted before each step and each external effect must be idempotent [24]. Amazon States Language is a managed runtime for the same shape, and it already requires a retried task to be idempotent [11].

**Command-query segregation.** Meyer's rule for one object, a method either changes state or answers a question, lifted by Young to a system: commands go to the model that decides, queries to a model built for reading [12]. The calculus takes the segregation and makes the staleness of a read a field rather than a caveat.

**Verification-guided development.** Amazon's Cedar is the worked example of the lifecycle this paper wants. Cedar's evaluator, authorizer and validator are total Lean functions over algebraic datatypes with the security properties proved; the Rust production engine is held to the Lean model by differential random testing, millions of random policies and requests evaluated in both with any difference a bug; property-based testing covers the parts not modeled. The authors name the method verification-guided development [13]. SampCert went further: the verified Lean code is the production code, twice as fast as what it replaced [25].

**Specification by example and trace validation.** Adzic gives the practice of examples as the shared specification and the executable test [14]. Cirstea, Kuppe, Loillier and Merz give trace validation its current form for TLA+: the implementation is instrumented to record updates to the specification's variables, and the model checker decides whether the recorded trace is a behavior of the specification; they report finding discrepancies in every distributed program they tried it on [15]. The two are the forward and backward halves of step 4. When the model is executable, as it is here, the checker is a fold and no model checker is needed.

**Coverage and mutation.** Chockler, Kupferman and Vardi define coverage for formal verification as repeating the verification on mutants of the model: a part of the model no property notices when mutated is a part the properties do not cover [16]. Kupferman names the same family of checks sanity checks [17]. MuAlloy and MutDafny carry the idea to Alloy and Dafny specifications [26]. It is the published answer to "do the examples have the model's geometry", and Section 6 reports it run.

**Parse, don't validate.** King: a boundary should turn loose input into a typed value once, or refuse with a reason, so that nothing past the boundary has to check again [18]. Every gateway in the calculus is parse, then decide, and what the wire cannot say about the model is a parse refusal.

## 4. The calculus

We state the calculus in Lean, because the statement is also the check. The generic shapes are the package `cell-calculus`, sixteen modules, one per idea, carrying only universal theorems, generic over a project's principal through one class and over the subject an event is about as a type parameter, with trust boundaries as an opt-in module. A project's own cells and every computation on them are a second package that builds on the first; the worked example's is `Library`. Type parameters are words, not letters, and every declaration carries a comment saying what it is and what the shape is called in the sources.

### 4.1 Outcomes have three values

```lean
inductive Exception (Reason : Type)
  | refused (reason : Reason)
  | unknown
```

Every gateway returns `Either[Ex, B]`, and `Ex` is itself a sum, `Either[Refused, Unknown]`. **Refused** is the cell's invariants saying no: deterministic, final, the journey stops at a named outcome. **Unknown** is the window: the effect may or may not have landed. The two sides come from different places, and the types say so. A cell's own result is the inner `Either[Refused, B]`; the window is added only where a result crosses the wire, and `liftToWire` is that lift, which turns a refusal into `refused` and never produces `unknown`. That is the theorem `model_never_unknown`: the model never produces unknown, only the world does. The model's job is to say what the caller may do on it: retry with the same key, never decide as if the effect did not happen. Conflating the two is the specific bug the window produces, a timeout treated as a refusal and an effect that landed compensated away.

### 4.2 A cell is three pure functions

A **cell** in this method is the cell of the cell-based architecture: a self-contained unit with its own data, a gateway as the only way in, and the facts it publishes as the only way its data reaches anyone else [19]. What the reference architecture leaves open is what happens inside the gateway, and that is where teams diverge. We close it with a definition. A cell is **three pure functions**, one of which is a fold.

```lean
structure Cell (Command ForeignEvent Event State Refusal : Type) where
  initial    : State
  decide     : Command → State → Except Refusal (List Event)   -- Command => State => Event
  react      : ForeignEvent → State → List Event              -- Event => State => Event
  evolve     : State → Event → State                          -- the fold
  isTerminal : State → Bool
```

It **decides** what happens when it is asked to do something, returning either the facts that record the decision or a refusal with a reason. It **reacts** to facts other cells have published, emitting facts of its own and never a command. It **evolves** its state by folding in its own facts, so that the state is nothing more than the history replayed. The parameters are the cell's commands, the foreign events it subscribes to, its own events, its state and its refusal reasons. Each function is plain, with no I/O, and that has two consequences for an enterprise. The behavior of a cell is testable without a database, a broker or a network, because the function can be called directly with a history and a command. And one cell cannot trigger another: there is no function that returns a command, so the hidden orchestration that fragments a decentralized architecture is not discouraged by a review guideline, it cannot be written. An attempt is rejected at the type:

```
error: Type mismatch
  CirculationCommand.closeCard
has type
  CirculationCommand
but is expected to have type
  NoticeEvent
```

For example, in a library's circulation system the cell that owns loans decides a checkout and publishes the fact that a copy went out; the cell that sends notices reacts to that fact, and nothing in it can reach back and change a loan.

State is the fold of the cell's own events and nothing else: `replay history = history.foldl evolve initial`. Determinism is not a property to test; the functions are pure by construction. `replay_append`, that replaying `h ++ h'` equals replaying `h` and then folding `h'`, holds for every cell and every history, and it is what makes a snapshot sound.

**Six rules the calculus takes from the foundations**, each with its source in Section 3.

1. Every gateway is an idempotent receiver. A command carries a key its caller minted before the first remote call and persisted with the caller's intent.
2. A command's outcome has three values, not two. `unknown` is the window made visible.
3. A saga records its intent before its first remote effect and its result after its last, and is resumable from the intent between the two.
4. Events are published from the same record as the state, never from memory: the outbox.
5. Queries create no obligation and carry no window.
6. Non-determinism lives at the roots. People, time and any automated judgment are sources of facts. A judgment is an event carried in a published schema; everything downstream is a pure reaction, testable with the judgment as a Given. This is the rule that lets a language model, or any heuristic, sit inside a deterministic architecture.

### 4.3 A journey is a DAG by construction, two ways

A **journey** is the path one request takes through the cells, from a root command or an external fact to the facts that end it. A journey transcribed from the tables of its section in the vision is a list of steps, each naming the earlier steps it waits on, and `wellFormed` checks that every edge points backwards. A journey written as code is a `do` block in `Except` whose steps are the cells' `handle` and `handleForeign`. Lean accepts only total functions, so a journey that re-entered an earlier step would need recursion it cannot prove terminating, and is rejected:

```
error: fail to show termination
```

### 4.4 A journey is a term, and every term compiles to a DAG

The two ways meet in an algebra with three constructors and no loop:

```lean
inductive Journey (State Refusal : Type)
  | step (name : String) (run : State → Except Refusal State)
  | seq  (first second : Journey State Refusal)
  | par  (left right : Journey State Refusal) (merge : State → State → State)
```

`run` is its denotation, one function; `run_seq` and `run_par` say the composite is the composition, by definition. `compile` numbers a term's steps and records what each waits on. The theorem `compile_wellFormed`, by structural induction over the three constructors with `nodesOk_append` as its lemma, says every term's compiled graph satisfies the same `nodesOk` rule the transcribed journeys are held to, so a journey from the vision document and a journey composed in the algebra are checked by one rule. The example's borrow journey, circulation deciding then notices reacting, is such a term, and it raises the same warning as the hand-written `do` block does.

### 4.5 A journey is a cell

The composite of a `decide` and a `react` has the decider's signature: a root command in, the product of histories as state, a refusal or events out. Composition is closed, so journeys compose into journeys under the same rules and the whole system is one cell. Two consequences follow. The composite's state is a product and never a merge, so a cell seeing only its own state is visible in the type of every journey. And function composition is associative, so where the cut between cells falls is a parenthesization and the composite is the same under every choice; the rule that statements move whole when a boundary moves is this theorem.

### 4.6 Choreography realizes composition

In the composite, fan-in is a function of both facts and time is gone. In the world the two facts arrive one at a time, in either order, and the reacting cell must remember the first while waiting for the second. The composite is the denotation; the choreography is the operational reading; the theorem with content is that they agree. For the example's hold shelf, which readies a copy when it has come in and a hold is waiting on it, `deliver_returnFirst` and `deliver_holdFirst` say that delivering the two facts one at a time in either order readies the copy exactly as the denotation does, for every copy, and `deliver_oneFact_notReady` says nothing is ready after one fact alone.

### 4.7 Composition and succession

A journey may run another as a step, which we call **composition**, and that relation must be acyclic. A journey's last fact may be the trigger of a new run of another, which we call **succession**, and that relation may cycle, because each edge is a new fact and a new run. The everyday loop of a product is a succession of DAG runs, never one cyclic journey. Read as one relation, "this journey references that one", almost every journey map cycles; read by kind, composition is acyclic and the cycles are all succession, where they belong. The full argument is [the-dag-rule.md](docs/the-dag-rule.md).

### 4.8 The wire is a projection, and the parse is in the model

Proto, JSON Schema and Avro cannot say what the model's sum types say: no invariants, loose fields. So the wire shape is a projection of the model's type, and what the projection loses is a list per schema, every item of which is one thing, a refusal at parse time. A command type's codec is a class, `WireCodec`, whose third field is the round-trip law, so an instance cannot exist without the proof that every command survives the wire. The gateway, parse then decide, is generic over the class, its refusal type is the sum of the two kinds, and `gateway_serialize` says that for every cell, history and command, the gateway on a serialized command is the cell's own decision. The same pair serializes every example into a fixture and parses every trace back, so the model and the tests share bytes rather than a description of the data. Two more classes make the rest generic: `Kinded` numbers a sum type's constructors so the coverage checks are one definition for every project, and `Describe` gives each constructor a sentence so the Gherkin renderer is too.

### 4.9 Specification by example is a type

```lean
structure Example (Command Event Refusal : Type) where
  id     : String
  given  : List Event
  when   : Command
  expect : Except Refusal (List Event)
```

`Example.holds cell ex` is a Boolean the kernel evaluates. The `id` is the row in the design document and the name of the test in the code. A `ReactionExample` is the same with a foreign fact as its When. An example set is a Lean value, and the coverage theorems hold over it: every command kind, every event kind and every refusal reason appears in some example, or the file does not compile. A **trace**, a list of command and outcome steps the implementation reported, is replayed by `Cell.conforms`, and a trace the model rejects names the step. A Gherkin rendering of each example is a fold over the same value, for the reader who reviews sentences.

### 4.10 The envelopes

Nothing so far said what a command or an event carries besides its payload. Two **envelopes**, defined once, wrap every command and every event:

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

No property-bag headers: a cell reads only the fields the type names, and a decider that reaches for a header the envelope lacks is rejected at the type. The fold never sees an envelope; the shell wraps what a decider emits. `Actor` is a sum over the five kinds of sender any system has, a principal in the project's own terms, a policy cell, the timer, a partner and the operator, so a decider's actor branch is a `match` the kernel checks is total. `Cell.gated` lifts any cell to the envelope with a policy saying which actor may issue which command: a refused actor gets no further, an allowed actor gets exactly the inner decision, and the fold is untouched, each a theorem for every cell and policy. A policy written as permits and forbids carries Cedar's trio as theorems: a forbid overrides every permit, a permit is required, an empty set of permits denies everything, and the rules are a set, so their order and duplicates do not matter. A derived key names its issuer and its cause, `derived_injective`, so a retry derives the same key without remembering anything. With causation and correlation on every event, a run's shape is checkable without replaying it: the events become nodes needing the event they cite, and `Run.conforms` is `nodesOk` again, the rule the compiled journeys are held to. `envelope_conforms`, with two lemmas, says that what the shell publishes on any command, for any cell, subject, clock reading and minting function, is a run that conforms. The decisions behind the fields are in Section 8.

### 4.11 Inputs, never calls

`decide` is pure, and a decider may need another cell's answer or the date. The shell gathers every query answer and the clock reading before it calls `decide` and hands them over as one argument, `Inputs Command Answers`, beside the command. A decider that reaches for the clock is rejected at the type, because `decide` returns `Except` and not `IO`. A query is a pure read of the owning cell's state, and its answer is stamped with the owner's version, so a decision made on it records what it was made on, and the owner can refuse the resulting command if it has moved on since. In the example, fines assesses a late item on circulation's stamped answer and the day it is: `stillOut_fresh` says the answer is fresh against the state it came from, `stillOut_staleAfterCheckIn` says it is stale after any return, both for every state, copy and key, and `assess_recordsCirculationsVersion` says the assessment records the version it was read at, for every pair of histories, every copy and every day. The clock is a cell whose events are ticks, and `tick_monotone` says its history never runs backwards. A command that declares no query reads none, `settle_readsNothing`, for every envelope, every pair of answers and every pair of readings. Examples gain a *with* clause and traces record the inputs, so a replay is exact.

### 4.12 Boundaries as types

An identifier that must not cross a trust boundary is indexed by the boundary that knows it, so the kernel refuses a record in one boundary built with another boundary's ID. The alias map carries its inverse law as a field, so a map that does not invert cannot be constructed. The scrub is a parse from one boundary's event to another's, owned by one cell and the one function in the system whose type names two boundaries; `scrub_keepsEnvelope` says the run is one run on both sides of the boundary, and `scrub_roundTrip` says that what the scrub lets through, re-identification returns exactly, for every map, tokenizer and event. In the example the desk knows a member by card and the stacks by patron token; the map between them has its inverse proved, a checkout fact crosses with its envelope kept, and a card the map does not know is refused rather than guessed.

### 4.13 Where an event may become a command

In exactly one place: at a journey boundary, as succession. A journey ends with a fact; the fabric lifts the fact into a command to the one cell that subscribes to it as a root, mechanically, with the key derived from the fact, the fact as the cause and a fresh run, so that a retry of the lift is the same command, `succeed_sameKey`. That cell is a **policy cell**, whose `decide` is the one place a proposal becomes a downstream command and whose every branch names its rung: in shadow a proposal is recorded and never issues, in review it is held until a person approves it, in autonomous it issues, and an approval issues only what was held, each a theorem for every proposal and state. Any automation, a recommender, a scheduler, an agent, is this one shape, and the gated policy cell refuses an approval from the wrong actor before it looks at the ladder. In the example the reading assistant's renewal proposal runs through the three rungs, a member's approval issues it and a guest's is refused at the gate.

### 4.14 Promises as trace predicates

With `issuedAt`, `recordedAt`, `causation` and `correlation` on every event, a **promise** is a predicate over runs, evaluated in the same pass that checks a run's shape: within a duration, at most a count, never after a fence. The runs that fail are named, and a measure, the count kept over the count seen, sits beside the promise. `withinDuration_mono` says loosening a limit never breaks a kept promise, which is why a promise can be tightened in steps. The example's "a limit warning within a minute of the checkout that reached it" is one line on the slice, and a run whose warning came nearly five minutes after the checkout burns it by name.

### 4.15 Contracts, and what an attribute quantifies over

A step's **contract** is one assumption and a guarantee per viewpoint, and the guarantees fold along the journey algebra with a rule per viewpoint: latency is the sum along a sequence and the max across a fan-out, which is the critical path of the compiled DAG; unavailability budgets and cost add along both constructors, because a `par` is all-must-succeed and so is series for everything but time; peak resource is the dual of latency [20]. `elapsed_le_latencyBound` is the compositional theorem: if every step honored its own bound, the journey's run is within the folded bound, for every journey, every set of contracts and every run. The three monotonicity theorems are the refinement direction: a cell may tighten a guarantee and no journey's bound gets worse.

A quality **attribute** is checkable only once it says what it ranges over, so the `Attribute` type fixes that in its constructor: one run, which is a promise; a pair of runs, the shape of a confidentiality claim no single run can refute; a population, a promise with a threshold, which is a hyperproperty over the window; a distribution, which no finite set of traces checks and which the attribute says is measured; or the artifact, a decided proposition about the model itself. `population_kept_of_all` says a promise every run keeps is kept at any threshold.

### 4.16 Governance of the model

The changelog rule applied to the model. A theorem is never deleted; it is superseded by name with Lean's `deprecated` attribute, so a use of the old one warns and names its successor. An example is never deleted; it is marked superseded with the date and the reason, and the coverage theorems run over the live set, so that retiring an example without a successor fails coverage, `hole_isNamed`. An event version is never removed; the upcaster from every version ever published is total by exhaustiveness. The project's header carries one **review line** per design, the design's path and its content hash at review, and the build checks it: a warning while unreviewed, a failure when the design changes under a signed line.

### 4.17 The context map

The journey map says which cells exist, where each lives and which arrows join them. The context map says what each arrow means to the two sides, in the vocabulary Evans and Vernon fixed [21]: who is upstream and who is downstream, an open host service, a published language or a plain supplier upstream, a customer, a conformist or an anti-corruption layer downstream, partnership, shared kernel or separate ways where the design says so. The one computation is coverage: every arrow between two contexts is accounted for by a relationship in the right direction, and adding a relationship never uncovers an arrow. What the relationship means in this method: a conformist's parse is the identity up to shape, and an anti-corruption layer's parse is a real translation, the only place a refusal means "not understood" rather than "no".

## 5. The method, as documents and as a round trip

Five documents, each owning one thing, and the Lean beside them.

| Document | Owns | Where |
| --- | --- | --- |
| The calculus | The types, the three functions, the three-valued outcome, the forbidden shape, non-determinism at the roots, the journey algebra, the wire as a projection | `cell-calculus`, and Section 4 |
| The geometry | The catalogue of allowed journey shapes: root, decide, fan-out, fan-in with memory, sink, succession, and the view and query archetypes. New features are modeled by picking from it | Not drafted; the fan-in with memory is worked in the example |
| The annotation | The fixed tables a design and a journey carry so that the model is transcribed one to one. Prose stays the owner of meaning | [style-guide.md](docs/style-guide.md), sections 8 and 9 |
| The examples | Given, When, Then rules and the one-id convention across design, theorem and test | In the calculus; coverage and conformance in Section 4 |
| The round trip | The six stages from the maps to the traces and back, with the artifact, the direction of generation and the acceptance test at each | [the-lifecycle.md](docs/the-lifecycle.md) |

**The six stages.**

| Stage | Input | Artifact | Direction | Acceptance test |
| --- | --- | --- | --- | --- |
| 1. The cell's I/O | The journey map and the context map | Per cell: commands in and from whom, facts subscribed and from whom, facts published, queries offered, partner calls; the paths table; the relationship on each arrow | Maps → paths → the type parameters of each `Cell` | Every arrow on either map is a paths row and a parameter of some cell |
| 2. The type-level model | Stage 1, and each design's tables, with each journey's steps carrying their cells | A module per cell with its five types and the bodies as `sorry`; the journeys as terms | Tables → Lean | Compiles; every structural theorem holds: each journey a DAG, composition acyclic, every cell in a zone, every platform cell the map claims for every journey on a step of each, and, once each design lists its facts, the event graph between cells acyclic |
| 3. The data model | Stage 2, and the data | State and event types, invariants as types or theorems, the bodies written; the data dictionary, with a meaning, a domain and an example value per field; `parse` and `serialize` per gateway; proto, JSON Schema and Avro generated from the types, with the loss list per schema | Lean → wire schemas | Zero sorries; every field's domain matches its meaning, so an integer that may be null is a wrong type and not a missing comment; `parse (serialize c) = .ok c` for every command; every loss is a parse refusal; coverage holds |
| 4. Specification by example | Stage 3 | Examples as values, each a theorem; fixtures in the wire shape; feature files | Lean → fixtures and features | Every example holds; coverage over commands, events and refusals; a surviving mutant is a failing test |
| 5. The code | Stage 4 | The implementation, its tests consuming the fixtures by id; for a pure core, the model itself compiled from Lean and called through a foreign function interface | Fixtures → tests | Every example passes against the implementation; differential tests on random inputs from one shared generator agree with the model |
| 6. The traces | The running tests, then production | Traces in the wire shape, parsed by the same `parse`, replayed by `Cell.conforms` | Traces → Lean | Every test trace conforms; production traces sampled and replayed; a rejected trace names the step |

The cycle closes at stage 6: a trace the model rejects is either a bug in the code or a learning for the model, and the next change is to the design and its Lean file, which regenerates everything below it. The verbs at each hop: *proved* for universal theorems, *checked* for decidable claims, *tested* for the implementation against the model, *assumed* for the world.

**Where the two sources meet.** Prose and Lean: the review that says the model captures the prose is human, and it is recorded as a line in the project's header with the design document's path and content hash at review time and the reviewer; the build fails when the design's hash changes and the line does not. Drift between prose and model cannot be prevented; it can be made visible the day it happens. Lean and the wire: one `parse` and `serialize` pair per gateway, written once and used four ways, by the production gateway, by fixture emission, by trace ingestion and by the round-trip theorem. Avro for events has a reason beyond fit: the registry's compatibility rules are the wire counterpart of the theorem that the upcaster from every historical event version is total, which Lean checks by exhaustiveness [27].

**What a non-technical reader reviews.** Two kinds of artifact and nothing in between. Authored prose that owns meaning: the journeys and each design's purpose and rules, edited by people. Generated views that own nothing: rendered from the Lean, stamped with the model's hash, never edited by hand. Three are planned, and the first is built: Gherkin feature files from the examples, which are also what the code's tests run; Event Modeling diagrams from the journey DAGs, swimlanes per cell in time order; and the data dictionary from the types and their doc comments, with a missing doc comment a build warning that the gates treat as a failure. The dictionary is also the acceptance test for the types, because a type signature is only as true as the values that fill it: a field whose domain admits a value its meaning forbids is a wrong type. A view without a stamp is not a view.

**The annotation grammar.** Fixed headings and columns in a design; prose elsewhere. Commands (id, name, sender, fields, refusals) become the command type, the refusal type, the actor policy, and rows of the paths table. Subscribes becomes the foreign event type. Publishes becomes the event type. State (field, type, invariant) becomes the state type and a theorem per invariant. Decide and React, one row per branch, become the bodies, with one example per row as the coverage rule. Examples become `Example` values. Each journey section carries its Steps table, with the cells on each step and the earlier steps it waits on, and its References table, each reference marked composition, succession or pointer. A design with Commands and no Decide rows fails the same check as one with no examples, and a journey with a role where a cell should be fails the same way; that is the rule against modeling only what is easy.

**The build.** One `lake` project per package with the toolchain pinned. `lake build` checks every theorem. `lake exe fixtures` renders the live examples as Gherkin and as JSON fixtures in the wire shape, each stamped with the model's hash. `lake exe replay` parses each trace with the gateway's own parse, replays it, and names the step where the code took a path the model has no edge for; the executable's verdict is a theorem's, since the first rejected step is proved to be none exactly when `conforms` holds. A review-line check warns while the model is unreviewed and fails when the design changes after a review. A mutation script applies named mutants, seven on the calculus and ten on the example, and requires each to be killed; the score is a gate. CI runs all of it on every change. Not built: the generators for schemas, storage and diagrams, and golden tests that pin the same design to the same model.

**Where a workflow engine fits.** Amazon States Language is not a review format: it is JSON, it allows cycles, and it is an execution language. It fits one place, the saga inside a cell, whose Lean is projected to the DAG subset of the language, `Parallel` for fan-out and fan-in, `Catch` for refused, `Retry` for unknown. The engine's execution history is then a trace and feeds back at stage 6.

## 6. Evidence

The method applied end to end on a worked example written for this repository: a public library's circulation system, with a design corpus of three documents, eight journeys, eleven cells, one design written to the annotation grammar, and a reference implementation. Everything in the two tables below and in the theorems named is in the repository and runs in CI, on Lean 4.34.1 with no library beyond core, against the calculus at version 2.3.0. The negatives that are type errors were run in copies not kept.

| Package | What it encodes | Theorems | How discharged |
| --- | --- | --- | --- |
| `cell-calculus`, sixteen modules | The generic shapes: the cell and the fold, the example type and trace conformance; the journey algebra with its DAG theorem and operational delivery; contracts and their folds with the compositional latency theorem; the envelopes, the actor gate, rule sets with Cedar's trio, the per-run causation pass and the run the shell builds; inputs, the stamped answer and the clock; the alias map, the scrub and re-identification; succession and the policy cell; the promise shapes and attributes by scope; the codec, coverage and description classes with the generic gateway; the trace checker with its verdict proved to be the theorem's; the review line and governed examples; the context map's vocabulary and coverage | 40 | All universal, by `simp`, cases and induction; none by `decide` |
| `Library`, the example | The journey map, every journey a DAG and every matrix row equal to its table; the context map with every arrow covered; the principal, the zones and the patron ID as a bounded ID; thirty-two named examples as theorems across four cells, circulation, notices, fines and pickup, with the codec instance, coverage, traces and sentences; the borrow journey as a `do` block and as a term with its contracts, and the hold shelf's fan-in; the envelopes on circulation's commands, the policy as a rule set, and four recorded runs; fines deciding on circulation's stamped answer and the clock; the renewals ladder; the promise as a population attribute; the alias map with the scrub; the governed example set and the upcaster | 123 | `decide` and `rfl`; ten universal, about this project's cells |

Findings worth reporting beyond "it passes":

- **The matrix and the journeys' tables agree, checked for all eight journeys.** Two hand-kept tables that nothing checked before now have a theorem between them, one per journey.
- **The references cycle when read without their kinds.** Composition is acyclic and succession cycles by design, with the return readying a hold, the pickup running late and the late item returned as the cycle. Both are theorems, and so is the cycle the map finds when the kind column is dropped. In the earlier trial the same cycle appeared as a wording defect in the documents on the first day: the references mixed the two relations, and the fix was to say which relation each reference is, which the References table now requires.
- **Forty universal theorems in the generic package, true for any project, and ten more about the example's cells.** `replay_append` for every cell and history. `checkOut_idempotent`: for every key, item and open-card state in which the key was already honored, a repeated checkout produces no event; the idempotent receiver is a theorem about the cell, not a test of one case. `closed_refusesCheckOut` for every key, item and history. `model_never_unknown`. `compile_wellFormed` for every journey term, with `nodesOk_append` as its lemma. The three fan-in theorems for every copy. The three actor-check theorems for every cell, policy, command and state. `derived_injective`. `envelope_conforms` for every command, cell, subject, clock reading and minting function, with two lemmas. The three staleness theorems, the no-reads theorem and the monotone tick. The scrub's two, for every alias map, tokenizer and event. Succession's idempotence and the policy cell's three. The promise's monotonicity. The generic gateway on a serialized command. The compositional latency theorem and three monotonicity theorems for contracts; the population theorem for attributes; Cedar's trio and the two set laws for rule sets; coverage's monotonicity on the context map. Beside them, the codec's round-trip law, proved at every instance by cases. Each took one `simp`, one `cases` or one induction; none needed a proof a person had to invent.
- **The examples cover the model's structure, and conformance is a fold.** Four theorems over circulation's example set: every example holds, and between them the examples reach all four command kinds, all four event kinds and all three refusal reasons. A six-step trace from a correct implementation conforms; a trace from an implementation that booked a retry twice is rejected at the second step.
- **Mutation gates the build.** Seventeen operators across the two packages: seven on the calculus, ten on the example, among them the loan limit off by one, the warning at the level rather than over it, the fine's comparison backwards, a closed card still lending, and the hold shelf readying on one fact. The gate reports every one killed, and the examples that sit on the boundaries, the fifth item accepted and the fourth item quiet, are the kind that kills an off-by-one. In the earlier trial the gate found two holes the examples had not: a terminal predicate made always false survived, because nothing looked at it, and a threshold moved from "over the limit" to "at the limit" survived, because both examples sat far from the boundary. Each was closed with one example. A surviving mutant is what "the examples do not have the model's geometry" looks like in practice, and the build treats it as a failing test.
- **The wire round-trips, and the loss list is two refusals.** Every circulation command serializes and parses back; a checkout with no item and an unknown kind are refused by name; the gateway refuses a parse and refuses a domain rule with different reasons.
- **The actor check is one combinator, and circulation's policy is its sender column.** A guest's checkout is refused before circulation decides; a member's is booked; a domain refusal survives the gate; a librarian closes the card. Four examples by `decide`, the same policy as a rule set with three permits and one forbid, and the three theorems hold for any cell.
- **A run's shape is checked without replaying it.** The borrow run conforms. A warning recorded before the checkout it cites, a warning citing another run's fact, and a checkout decided for a key other than the root's are each rejected by the same `nodesOk` rule the compiled journeys use; for the two recorded as traces, the replay executable names the fact and the field.
- **A decision records the version it was made on.** Fines assesses an item on circulation's stamped answer and the clock; the recorded version is circulation's at the read, for every pair of histories; the answer is fresh against the state it came from and stale after any return. Whether the owner refuses a command decided on a stale answer is the owner's rule, stated in Section 8 and not yet a theorem.
- **The policy cell, the promise and the scrub, on the slice.** The renewal proposal runs through shadow, review and autonomous to the outcome each rung names; a member's approval issues the held renewal and a guest's is refused by the actor gate. A warning nearly five minutes after its checkout burns the promise, and the burn names the run. A checkout fact crosses from the desk to the stacks with its envelope kept, comes back exactly, and a card the alias map does not know is refused.
- **The round trip closes.** The generator writes thirteen live examples as a feature file and as JSON fixtures, stamped with the model's hash. A Python implementation with a pure fold and decider passes all thirteen, each test named by the example's id, plus the stamp check. A trace recorded from that implementation, eleven steps including a retry, a refused sixth item, a return, a renewal, the close and a checkout after it, is replayed and conforms. The same executable rejects the four bad traces for four different reasons: a retry booked twice, a command the model does not understand, a fact citing one recorded after it, and a fact from another run.
- **The kernel refuses wrong inputs.** Two are kept as theorems of the negation: a path opened from the stacks toward the desk fails the direction rule, and the references read without kinds cycle. The rest were run in copies not kept. A matrix row that drifts from its journey's table fails its theorem, and a wrong Given, When, Then fails its `_holds`, each with a message that names the claim. A reaction that emits a command, a decider that reads a header the envelope does not have, and an event in one zone carrying another zone's ID are type errors that name the type or the field. A retry in place fails to show termination. An alias map that does not invert cannot be constructed, because its inverse law is a proof obligation. The first mutant fails the build.
- **Cost.** The example's corpus, maps, design, model, implementation and traces were written in one working session against the calculus as it stood, and the full build, every theorem included, succeeded on the first run. In the earlier trial, the generic package and the first project's modules were written by an agent from the documents in two working days, with at most two compile-fix rounds per section.

## 7. Where it can fail, and what we propose

We state these so the paper does not overclaim. Each is a place the method can fail, what would show it, and what we propose to do about it.

1. **The specification gap, and whether the examples have the model's geometry.** Lean proves the model, never that the model means what the prose intended. "Same geometry" is four claims, each with a different proof, and a hash answers only the fourth. *Consistency*: every example agrees with the model; each is a theorem, done. *Coverage*: the examples reach every part of the model; the structural half is a theorem over the example set, done, and the behavioral half is mutation, run as a gate, which has found holes already. *Conformance*: the implementation's behavior is one the model allows; the trace is input to the model and replayed, done. *Provenance*: these tests ran against this model, and this model was reviewed against this design. The examples are generated from the model and never copied; every view carries the model's hash; every test run and later every production cell emits its trace in one shape and a Lean executable replays it; the review that binds design to model is a line in the model's header, and CI fails when the design's hash changes and the line does not. We propose for the rest that the test run sign an in-toto attestation naming the hash of the examples and the model, and that the release pipeline refuse a build whose attestation names another [28]. What is still not proved: refinement, that *every* implementation behavior is a model behavior, needs the code in a form Lean can reason about. Mutation scores are evidence. The review is a review. The gap does not close.
2. **Examples are not coverage.** Thirteen examples prove thirteen points. We propose three layers of input and one oracle. The examples, hand-chosen and held to the coverage theorems. Random inputs drawn from the types, with Plausible, Lean's property-based testing library, deriving generators and shrinkers from the type's structure, so the model is tested against its own universal properties before the code exists [29]. Differential testing, the Cedar pattern, with the same generator driving the implementation and the outputs compared with the model's. Random inputs that kill a mutant become examples.
3. **The model-to-code link is testing, not proof.** We propose three strengths, chosen per cell by what the invariant is worth. Traces and differential tests for every cell, with the claim written as "agrees with the model on every input tried". The model as the code for the pure core: `decide`, `react` and `evolve` have no I/O, Lean compiles to C, and the production runtime calls the compiled model through a foreign function interface while owning I/O, storage and the fabric; SampCert shipped this way. Refinement proofs, a simulation relation between production state and model state preserved by every command, in the Event-B style LeanMachines gives on Lean 4 [30], last and only where the second is impossible. For a cell where "booked once" is the product, we propose the second.
4. **Judgments are never proved.** A judgment, by a person or an automation, is a root fact. We propose to make the boundary a type and test it as a boundary. The result schema's parser and validator are written in Lean and are the oracle the runtime's validator is tested against; a judgment that does not parse never becomes an event. Theorems state what a judgment cannot do: a reaction to it emits events and never commands, and by the paths it never reaches a zone it may not. The judgment's quality is assumed and measured, by a test set per kind of judgment, reported beside the theorems and never mixed with them. The paper's sentence is "the method proves everything downstream of a judgment and nothing about it".
5. **The window is not in the model.** `unknown` is a value in the type and a rule in a comment. We propose to model the saga as a cell whose events are intent recorded, remote answered and result recorded, with `unknown` an explicit answer, and to prove one theorem: for any receiver with the idempotent property, the state after "intent, unknown, retry with the same key, ok" equals the state after "intent, ok". That is the window's safety condition stated once for every key. Whether commands over RPC between cells are allowed, and how the window's cost is budgeted, are deferred; the theorem is the precondition any answer must satisfy.
6. **Event sourcing is a commitment.** We propose that each cell's data design name its history and its fold in one of two forms. An event store, where `replay` is literal. Versioned rows, where a row version is an event, `evolve` is the row-version function, the current row is the snapshot, and `replay_append` is what makes the snapshot sound. A cell that chooses neither is a cell the calculus does not describe, and the data classification of a system should carry a column saying which form each cell takes.
7. **Composition of cells is partly proved: two of its three theorems.** The algebra compiles every term to a DAG, proved. The fan-in cell with memory realizes the composite in either delivery order, proved for the example's hold shelf. What remains is the general form of the second theorem, for any cell whose `react` and `evolve` satisfy a stated memory discipline, and fmodel's `combine` as a monoid that preserves every structural theorem, which is fiddly on product states and worth having for the boundary argument. What composition does not change is `unknown`: Kleisli composition short-circuits on it, correctly for the function and silently for effects already landed upstream. The composite specifies the happy path and the refusals; the saga specifies recovery; with idempotent receivers the saga collapses to "retry the composite from the recorded intent until no step returns unknown".
8. **Projections, queries and fan-in with memory** are present in every architecture and thin in the calculus. We propose two more archetypes, both already expressible. A view, `ForeignEvent → View → View`, a fold over foreign events into a consumer's own shape, with Given, Then examples; fmodel's `View` is this. A query, `State → Query → Answer`, a pure read with no events and no obligation. Fan-in with memory is the hold shelf of Section 4, to be entered in the geometry catalogue with its once-only theorem.
9. **Toolchain churn and adoption.** Lean releases monthly; each package pins a version, and CI runs on every change, so upgrades are on purpose and recorded. An architect stays at the `decide` layer; universal theorems are written by whoever writes them, a person or an agent, and reviewed as proofs are reviewed, by whether they state the right thing.
10. **Modeling what is easy to model.** A method that proves structure and skips behavior proves the cheap thing. The annotation grammar makes behavior mandatory: a design's model must contain a `decide` for every command in its Commands table and a `react` for every foreign event in its Subscribes table, and the coverage theorems must hold over its examples. A design whose model has tables and no decisions fails the same check as one with no examples.

## 8. Seven problems that stood in the way

Seven things had to be decided before the method was consistent, ranked by how much consistency rests on each. Each is a decision the method takes, and where a shape of the calculus carries it, the shape is named; the rest are rules a project's documents carry. We record the decisions so that a reader knows which were taken, can take a different one, and can see what each leaves open.

| Problem | What was missing | The decisions taken | What it leaves open |
| --- | --- | --- | --- |
| 1. The envelopes | Nothing said what every command and event carries besides its payload, and four other problems need those fields | The actor is a sum carrying what identity returned, not a reference a decider resolves; a command has one cause, and fan-in is a cell with memory; internal senders derive the key from the causing event; every field rides the wire, as a CloudEvents profile for events and a field of each gateway's schema for commands, and the fabric adds nothing a cell may read [31] | The schema generators that would emit the profile |
| 2. Queries and time as inputs | `decide` was pure, and a decider needs another cell's answer or the date | A stale answer is neither a refusal nor an `unknown` at the decider but a decision recorded with the owner's version, and the owner refuses the resulting command if stale; a tick carries the wall clock and the logical clock is the envelope's causation with each owner's version; the queries a decider needs are declared per command, with a no-reads theorem where the declaration is empty | The owner's refusal of a stale command as a theorem |
| 3. Where `Event => Command` may exist | The sink is unrepresentable in a cell and every product has it somewhere, at an automation's autonomous rung | A person approving a held proposal is the same policy cell, with the approval gated to the right actor; a held proposal is the cell's aggregate, kept until approved or replaced by a newer one for the same subject; every automation has its own policy cell | A subject on the policy cell's held proposals, so that replacement is a shape and not a rule |
| 4. Boundaries as types | One ID per zone was a theorem over a paths table, which is only as complete as the table | The index goes on exactly the IDs the alias map maps, not on opaque IDs that are safe to cross; a device is an endpoint of a zone and not a zone; the zone rides the wire in the schema's namespace, with the registry and topics per zone, not as a field | The registry and topics, which are the fabric's |
| 5. Promises as trace predicates | Service promises, an alert within an hour, zero statements in the wrong context, were held by attention | The shapes are per run and the measure is the population over a window; the checker reads the telemetry's kinds and times, never a payload, so it can run in an operations zone that sees no data; ordering promises are also theorems over the model, duration promises are checks only | The checker as a service over live telemetry |
| 6. The build | The method was files run by hand and a transcription done with judgment | A `lake` project per package, the fixtures generator, the trace checker, the review-line check and the mutation gate, all in CI; transcription is held to the annotation grammar and to the worked example as its golden set, and becomes a metaprogram over the tables once they stop changing; the review line is signed by the reviewer's commit until attestation exists | Golden tests for transcription; the attestation |
| 7. Governance of the model over time | The documents had a changelog rule; the model had none, and a proof in the way could be edited to pass | A boundary move is a rename with a `deprecated` alias for one release, never a change of statement; an upcaster branch outlives the oldest retained history that needs it; the reviewer on the review line may supersede, and the deprecated attribute and the header's superseded entry go together | A build check that the attribute and the entry agree |

Still parked on purpose: the saga and commands over RPC between cells, which none of the seven depends on; and the remainder of item 7 in Section 7.

## 9. A call to contribute

The method is published so that the people who use it say what comes next. Section 7 lists ten places it can fail, each with the proposal we would make; Section 8 lists what each decision leaves open; the build lists what it does not yet generate. We do not rank them, because the ranking belongs to whoever models the next system, and the method's own next test is exactly that: a system that is not the example, modeled by a team that did not write the calculus.

Three kinds of contribution are worth more than the rest. A **second project**, whatever its domain, with what the calculus lacked for it fed back as proposals: a shape with the universal theorem it would carry, arriving beside the old one and never in its place. A **transcription** that holds the same design to the same module, so that two authors produce one model. And a **rejected trace** from running code, with the step it was rejected at and the design row it disagreed with, because that is the one artifact the method cannot produce for itself. The repository's [contributor's guide](CONTRIBUTING.md) says how each arrives and the gates it passes.

## 10. Conclusion

The hypothesis survives contact with a worked example, after an earlier trial on a private architecture, with its scope made exact. A design written on proved practice can be a model Lean checks; the model can generate the examples the code is tested against, the fixtures the tests consume and the views a reviewer reads; the examples and traces can be carried back to the model, which is the judge. What the method proves is the model. What it checks is the structure. What it tests is the code against the model. What it assumes is the world and every judgment made in it. A lifecycle that says those four words in the right places is one whose documentation is understood the same way by every reader, accurate about everything it can be accurate about, and demonstrably the thing the code was built against. The evidence is one hundred and sixty-three theorems, fifty of them universal and forty of those generic over any project, seventeen mutants killed, four kinds of bad trace rejected by name, an implementation that passes every example of its design by id, and from the earlier trial two coverage holes found by mutation and one wording defect found in the documents on the first day. The seven things that stood between this and a consistent method are decided and written down, each with what it leaves open. What comes next is whatever the next system teaches.

## References

[1] Chassaing, Jérémie. "Functional Event Sourcing Decider." 2021. https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider

[2] Dymitruk, Adam. "Event Modeling." https://eventmodeling.org/

[3] Fraktalio. "fmodel" and "Aggregating the Behaviour." https://github.com/fraktalio/fmodel · https://fraktalio.com/fmodel/docs/domain/aggregating-the-behaviour

[4] Helland, Pat. "Idempotence Is Not a Medical Condition." Communications of the ACM 55(5) and ACM Queue 10(4), 2012. https://cacm.acm.org/practice/idempotence-is-not-a-medical-condition/

[5] Helland, Pat. "Life beyond Distributed Transactions: an Apostate's Opinion." CIDR, 2007.

[6] Helland, Pat. "Data on the Outside versus Data on the Inside." CIDR, 2005.

[7] Treat, Tyler. "You Cannot Have Exactly-Once Delivery," 2015, and "Redux," 2017. https://bravenewgeek.com/you-cannot-have-exactly-once-delivery-redux/

[8] Confluent. "Kafka Message Delivery Guarantees." https://docs.confluent.io/kafka/design/delivery-semantics.html

[9] Kingsbury, Kyle. "Jepsen: Bufstream 0.1.0." November 2024. https://jepsen.io/analyses/bufstream-0.1.0 · KAFKA-17754.

[10] Garcia-Molina, Hector, and Kenneth Salem. "Sagas." SIGMOD, 1987. https://www.cs.cornell.edu/andru/cs711/2002fa/reading/sagas.pdf

[11] Amazon Web Services. "Amazon States Language." https://states-language.net/

[12] Meyer, Bertrand. *Object-Oriented Software Construction.* Prentice Hall, 1988. Young, Greg. "CQRS Documents." 2010.

[13] Cutler, Joseph W., et al. "Cedar: A New Language for Expressive, Fast, Safe, and Analyzable Authorization." OOPSLA, 2024. https://arxiv.org/abs/2403.04651. Disselkoen, Craig, et al. "How We Built Cedar: A Verification-Guided Approach." FSE Industry, 2024. https://arxiv.org/abs/2407.01688

[14] Adzic, Gojko. *Specification by Example: How Successful Teams Deliver the Right Software.* Manning, 2011.

[15] Cirstea, Horatiu, Markus Kuppe, Benjamin Loillier, and Stephan Merz. "Validating Traces of Distributed Programs Against TLA+ Specifications." SEFM, 2024. https://arxiv.org/abs/2404.16075

[16] Chockler, Hana, Orna Kupferman, and Moshe Vardi. "Coverage Metrics for Temporal Logic Model Checking." TACAS, 2001; "Coverage Metrics for Formal Verification." CHARME, 2003. https://www.cs.huji.ac.il/~ornak/publications/charme03a.pdf

[17] Kupferman, Orna. "Sanity Checks in Formal Verification." CONCUR, 2006. https://www.cs.huji.ac.il/~ornak/publications/concur06b.pdf

[18] King, Alexis. "Parse, Don't Validate." 2019. https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/

[19] WSO2. "Cell-Based Architecture: A Decentralized Reference Architecture for Cloud Native Applications." https://github.com/wso2/reference-architecture/blob/master/reference-architecture-cell-based.md

[20] Benveniste, Albert, et al. *Contracts for System Design.* Foundations and Trends in Electronic Design Automation, 2018. Le Boudec, Jean-Yves, and Patrick Thiran. *Network Calculus.* Springer, 2001. Dean, Jeffrey, and Luiz André Barroso. "The Tail at Scale." Communications of the ACM, 2013.

[21] Evans, Eric. *Domain-Driven Design: Tackling Complexity in the Heart of Software.* Addison-Wesley, 2003. Vernon, Vaughn. *Implementing Domain-Driven Design.* Addison-Wesley, 2013.

[22] Lamport, Leslie. "Time, Clocks, and the Ordering of Events in a Distributed System." Communications of the ACM 21(7), 1978. Fidge, Colin. "Timestamps in Message-Passing Systems That Preserve the Partial Ordering." Australian Computer Science Communications 10(1), 1988. Mattern, Friedemann. "Virtual Time and Global States of Distributed Systems." Parallel and Distributed Algorithms, 1989.

[23] Lightbend. "Akka Persistence: Event Sourcing." https://doc.akka.io/

[24] Temporal. "Durable Execution." https://temporal.io/blog/temporal-replaces-state-machines-for-distributed-applications. Microsoft. "Azure Durable Functions." https://learn.microsoft.com/azure/azure-functions/durable/

[25] Tristan, Jean-Baptiste, et al. "SampCert: Verified Differential Privacy." Amazon Science, 2024.

[26] Wang, Kaiyuan, et al. "MuAlloy: A Mutation Testing Framework for Alloy." ICSE, 2018. https://kaiyuanw.github.io/papers/paper7-icse18.pdf. "MutDafny." 2025. https://arxiv.org/pdf/2511.15403

[27] Apache Software Foundation. "Apache Avro Specification: Schema Resolution." https://avro.apache.org/docs/

[28] in-toto and SLSA. "in-toto and SLSA." 2023. https://slsa.dev/blog/2023/05/in-toto-and-slsa

[29] Plausible. Property-based testing for Lean 4. https://github.com/leanprover-community/plausible

[30] LeanMachines. "LeanMachines: State-based Modeling with Refinement (a Lean4 Framework)." https://dl.acm.org/doi/10.1145/3796230

[31] CloudEvents. "CloudEvents Specification." CNCF. https://cloudevents.io/

Further reading: Bernhardt, Gary, "Functional Core, Imperative Shell," 2012. Hohpe, Gregor, and Bobby Woolf, *Enterprise Integration Patterns*, 2003, "Idempotent Receiver," "Correlation Identifier," "Message History." Leach, Brandur, "Implementing Stripe-like Idempotency Keys in Postgres," 2017. Lean FRO, "The Lean FRO Year 4, Part 1 Roadmap," 2026. de Moura, Leonardo, and Sebastian Ullrich, "The Lean 4 Theorem Prover and Programming Language," CADE, 2021. Newcombe, Chris, et al., "How Amazon Web Services Uses Formal Methods," Communications of the ACM 58(4), 2015. Richardson, Chris, *Microservices Patterns*, Manning, 2018. Young, Greg, *Versioning in an Event Sourced System*, Leanpub, 2017.
