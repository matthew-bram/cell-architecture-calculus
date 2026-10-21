# The big rocks

Oct 12, 2026 · seven things still in the way of a consistent method, each exploded so a later session can pick one up and think it through. Ranked by how much consistency rests on it. Each has the problem, why it blocks consistency, a proposed rule, what it means in the calculus and in the documents, the questions still open, and the prior art to read.

Status of each: **open**, unless marked.

## 1. The envelopes

**Status: worked 2026-10-13, for the owner's confirmation.** The fields are in `Calculus.lean` and the four open questions each have a recommendation in [envelopes.md](envelopes.md).

**The problem.** Nothing says what every command and every event carries besides its payload. The owner's rule from the start: no property-bag headers, where a message carries a map of string keys that any cell may read or ignore. An envelope is a structure with fixed, typed fields, and a cell can only read the fields the type names.

**Why it blocks consistency.** Until the envelope is fixed, each cell decides what "who sent this" and "have I seen this" mean, and the method is inconsistent at the first gateway. Four other rocks need its fields: authorization needs the actor; threat 5 needs the key; per-journey traces need causation; promises need the correlation and the times.

**Proposed rule.** Two envelopes, defined once, in the calculus, and every `C` and `E` of every cell is wrapped in them. No cell adds a field; a cell that needs one proposes it here, with a changelog row.

| Envelope | Field | Type | Why |
| --- | --- | --- | --- |
| Command | `actor` | `Actor` (a member in a role, a policy cell, a timer, a partner, the control plane) | Contract rule 4: every writer checks who is acting; the check is a refusal reason in `decide` |
| | `key` | `IdempotencyKey`, minted by the sender before the first remote call | The idempotent receiver, everywhere; threat 5's theorem applies by construction |
| | `causation` | `Option EventId` | The event, if any, whose succession this command is; `none` for an external root |
| | `correlation` | `RunId` | The journey run; the same ID on every command and event in one run |
| | `issuedAt` | `Instant` | What time the sender thought it was; the clock rock reads it |
| | `payload` | `C` | The cell's own command type |
| Event | `id` | `EventId` | Minted by the publisher, unique in the cell's history |
| | `causation` | `CausationId` (a command key or an event ID) | The DAG edge: what this fact is a reaction to |
| | `correlation` | `RunId` | Same as the command's |
| | `version` | `SchemaVersion` | The upcaster's input; Avro's compatibility rule is the wire counterpart |
| | `tenant` | `TenantId zone` | Exactly one, of the zone's kind; see rock 4 |
| | `recordedAt` | `Instant` | When the publisher recorded it, which is not when it happened |
| | `payload` | `E` | The cell's own event type |

**In the calculus.**

```lean
structure Command (C : Type) where
  actor       : Actor
  key         : IdempotencyKey
  causation   : Option EventId
  correlation : RunId
  issuedAt    : Instant
  payload     : C

structure Event (E : Type) (z : Zone) where
  id          : EventId
  causation   : CausationId
  correlation : RunId
  version     : SchemaVersion
  tenant   : TenantId z
  recordedAt  : Instant
  payload     : E
```

`Cell.decide` takes `Command C`, so the actor check is a branch of every decider and a row in every design's Decide table. The conformance checker gains a second pass: in a journey trace, every event's `causation` points at a command key or event ID earlier in the same `correlation`, and the graph they form is the journey's compiled DAG. That is the per-journey trace conformance threat 1 could not do per cell.

**In the documents.** The envelope is one table in the calculus document and nowhere else; designs cite it. The paths table's "carries" column says payload types only, because the envelope is the same on every path. The glossary gets `actor`, `key`, `causation`, `correlation`.

**Open questions.**

- Is `actor` a sum over kinds (member, policy cell, timer, partner, control plane) or a reference identity resolves? The contract says identity answers who; the envelope should carry what identity returned, not a lookup.
- Does `causation` on a command point at one event or may a command be the succession of several? If several, fan-in at a journey boundary needs a rule.
- Where does the key come from for a command issued by a policy cell or a timer? Proposal: derived deterministically from the causing event's ID, so a retry mints the same key.
- Which fields are in the wire envelope and which the fabric adds? Avro and CloudEvents both have opinions.

**Prior art.** CloudEvents specification, the `id`, `source`, `type`, `time` attributes and the extension discipline · Hohpe and Woolf, *Correlation Identifier* and *Message History* · Helland 2012 on the key · Lamport 1978 for why `issuedAt` and `recordedAt` are two fields.

## 2. Queries and time as inputs, never calls

**Status: worked 2026-10-13, for the owner's confirmation.** The shapes are in `Calculus.lean` and the three open questions each have a recommendation in [queries-time-and-zones.md](queries-time-and-zones.md).

**The problem.** `decide` is pure, but the pipeline needs a balance from the books to decide, and statement day needs today's date. If `decide` reaches out to a gateway or a clock, purity is gone and with it every theorem about it.

**Why it blocks consistency.** Without one rule, some deciders will call and some will be called with, and the examples for the two kinds look different, the traces differ, and the fan-in with memory of theorem 2 has no stable meaning for "the state at the time."

**Proposed rule.** Functional core, imperative shell. The shell gathers every query result and the clock reading before it calls `decide`, and passes them as one argument. A step in the algebra lists its query inputs by name. The clock is a cell whose events are ticks; a timer-driven journey's root is a tick, and `issuedAt` on every command is a reading the decider may use and never fetch.

**In the calculus.**

```lean
structure Cell (C F E S Q ρ : Type) where
  queries : Q → List QueryName          -- what the shell must gather, declared
  decide  : Command C → S → Q → Except ρ (List E)
  ...
```

`Q` is a record of the answers this cell's deciders may read; the shell fills it from other cells' gateways. A query is `S → QueryName → Answer` on the owning cell, pure, no events. Examples gain a `with` clause beside Given, When and Then: the query answers the shell supplied. Traces record `Q` with each command, so a replay is exact.

**In the documents.** A design's Decide table gains a column, "reads," naming the queries. The methodology's duplication test (query when exact and now, project otherwise) becomes the rule for what goes in `Q` against what goes in `S`.

**Open questions.**

- Is a stale answer in `Q` a refusal, an `unknown`, or a decision made on old data and recorded as such? The books' balance against allocations is the case to settle it on.
- Does a tick carry the wall clock, a logical clock, or both? Lamport says both, and `recordedAt` already separates them.
- Can a decider's `queries` depend on the command, so the shell gathers only what this command needs?

**Prior art.** Gary Bernhardt, *Functional Core, Imperative Shell*, 2012 · the Reader pattern · Chassaing's Decider, which has no `Q` and leaves the question to the host · the methodology's duplication test, method 5.

## 3. Where `Event => Command` is allowed to exist

**Status: worked 2026-10-14, for the owner's confirmation.** The succession lift and the policy cell are in `Calculus.lean`; the three open questions each have a recommendation in [policy-promises-and-governance.md](policy-promises-and-governance.md).

**The problem.** The sink is unrepresentable inside a cell, and the product has it by design. The ladder's autonomous rung turns a role's proposal into an action with no human. Service operations turns telemetry into a control-plane request. The Steward moves an allocation after a goal is picked. Each is an event becoming a command.

**Why it blocks consistency.** If the sink is "forbidden except when needed," every design will find its exception and the DAG rule is a preference. If it is placed precisely, the rule holds everywhere and the exceptions are a kind of root.

**Proposed rule.** The sink exists only at a journey boundary, as succession, and never inside a journey. A journey ends with a fact: "proposal published," "trigger fired." A new journey starts with a command whose sender is a **policy cell**, and senders are roots. The policy cell is a decider: its command is the proposal plus the ladder's rung, its state is the ladder's configuration from the management plane, its `decide` either issues the downstream command or refuses with "shadow" or "review." The event-to-command step is therefore `decide` with a reason, never `react`.

**In the calculus.** A `Policy` is a `Cell` whose `C` is `Proposal × Rung` and whose events are `commandIssued` or `heldForReview`. The journey algebra does not change; the succession relation gains a rule that every succession edge passes through a policy cell or a person. A theorem: in the compiled graph of any journey, no node's `needs` crosses a journey boundary, which is theorem 1 plus the succession list.

**In the documents.** The agent runtime's open item, roles as cells or tools, resolves: a role is a source of judgment events; the policy cell is where its judgments become commands; the ladder is the policy cell's configuration. Service operations is the same shape with telemetry as the judgment. The journeys' "What it reuses" sections mark each succession edge with its policy cell or its person.

**Open questions.**

- Is a person approving a review card a policy cell with a human in the loop, or a different kind of root? Proposal: the same cell, with the rung "review" meaning the command's `actor` must be a primary.
- Does the policy cell keep the proposal as state until the rung allows, and for how long?
- The hero journey's signal, falling behind, is a succession from reminders to a plan mention; which cell is its policy?

**Prior art.** Event Modeling's automation slice, the "todo list" pattern, which this rule constrains · the operations model's ladder, shadow, review, autonomous · Richardson's orchestration saga, which this rule confines to one cell.

## 4. Zones as types

**Status: worked 2026-10-13, for the owner's confirmation.** The scrub, its inverse and the alias map with its invariant as a field are in `Calculus.lean`; the three open questions each have a recommendation in [queries-time-and-zones.md](queries-time-and-zones.md), one of them narrowing the proposal below to the IDs the ID map maps.

**The problem.** Principle 17 says an event never carries two tenant IDs and the AI zone never sees the private zone's. Today it is a theorem over a paths table and a review of each design.

**Why it blocks consistency.** A theorem over a table is only as complete as the table. A type is checked in every design, in every event, forever, by the type checker, without anyone remembering to add a row.

**Proposed rule.** Index the tenant ID by zone. An event type in the AI zone is constructed with `TenantId .aiZone` and cannot be constructed with `TenantId .privateZone`; the kernel refuses. The scrub is a parse between zones: `scrub : Event E .privateZone → Event E' .aiZone`, owned by the private zone's cell, and the only function in the system whose type mentions two zones. Re-identification is its inverse, same owner.

**In the calculus.**

```lean
inductive Zone | privateZone | aiZone | accountServices | opsZone
structure TenantId (z : Zone) where raw : String   -- opaque; the index is the point
```

Theorems come for free: no cell's `E` in the AI zone mentions an private zone ID, because it cannot. The one theorem worth writing is that `scrub` and `reidentify` round-trip on the alias map, which is the alias map design's invariant.

**In the documents.** Data classification's "one tenant ID per zone" becomes the type's index. Method 3 is restated as a type. The paths table's "never carries" column loses the ID rows, because the type carries them.

**Open questions.**

- Account IDs and the books' IDs are per zone too; which IDs get the index? Proposal: every ID that identifies a tenant's thing.
- The devices: a device holds the private zone's view; is a device a zone?
- Does the index leak into the wire schemas, and how? Proposal: the zone is a field of the Avro record and the registry is per zone.

**Prior art.** Phantom types and indexed families, the standard technique · Helland 2005, data on the outside · the project's data classification and placement.

## 5. Promises as trace predicates

**Status: worked 2026-10-14, for the owner's confirmation.** The promise shapes, the burns and the measure are in `Calculus.lean`; the three open questions each have a recommendation in [policy-promises-and-governance.md](policy-promises-and-governance.md).

**The problem.** The risk register's promises, an alert within hours of data arriving, zero statements in the wrong context, 80% of alerts rated useful, are reviews and measurements held by attention.

**Why it blocks consistency.** The method checks behavior by replaying traces and checks nothing about time, cost or frequency. A promise that lives outside the checker is a promise the method does not keep.

**Proposed rule.** A trace carries `issuedAt`, `recordedAt`, `causation` and `correlation` (rock 1). A promise is a predicate over traces: "for every run whose root is new data arriving, the alert event's `recordedAt` minus the root's `issuedAt` is under the threshold." The same conformance pass evaluates promises, reports the measure, and a burn is a failing predicate with the run that failed it named.

**In the calculus.** `Promise := List (Trace) → Bool` with a measure beside it; a library of predicate shapes: within-duration, at-most-count, never-after, always-before. The risk register's "measure" column becomes a reference to a predicate.

**In the documents.** Each design's risks, measures and promises table gains a column naming the predicate. Promises the checker cannot evaluate, "rated useful," stay as measurements and say so.

**Open questions.**

- Which promises are about one run and which about a population? "80% useful" is a population promise and needs a window.
- Do production traces carry enough to evaluate without carrying tenant data? They carry IDs and times, which is what the predicates read; worth confirming against telemetry's schema.
- Is a promise a theorem over the model as well, where the model has time? Possibly for ordering promises; not for durations.

**Prior art.** Runtime verification and temporal logic over finite traces, LTLf · the operations model's risk register · Cirstea, Kuppe and Merz 2024 for traces as the input.

## 6. The build

**Status: worked 2026-10-14.** A `lake` project with the fixtures generator, the mutation score and the review-line check running, and CI written; what is not built and the three open questions are in [the-build.md](the-build.md).

**The problem.** The method today is two Lean files run by hand, generators that do not exist yet, and a transcription from design to Lean done by an agent with judgment.

**Why it blocks consistency.** Until it is a pipeline, consistency depends on who ran it and when. A method that is a practice drifts; a method that is a build fails loudly.

**Proposed rule.** One `lake` project with the toolchain pinned. CI on every change to a design or the model. Generators as `lake exe` targets: Lean to proto, to Avro, to JSON Schema and OpenAPI, to Gherkin, to Mermaid for the Event Modeling view, to the data dictionary. The trace checker as an executable reading the wire shape. The mutation script with its score. Golden tests for transcription: a fixture design document and the Lean it must produce, so the same document produces the same model every time, and the agent's skill is held to the golden set.

**In the documents.** The round-trip document's acceptance tests become CI jobs. A design's status header gains "model: checked at `<hash>`."

**Open questions.**

- Does the transcription run as a Lean metaprogram over a structured design, or as an agent skill with golden tests? Both; the metaprogram for the tables, the agent for the prose, and the golden tests over both.
- Where does the project live: in this repository, lifted out, or both with the generated views copied in?
- How is the review line in the model header signed, and by what identity?

**Prior art.** Lean's `lake` and the Lean FRO's Verso for the literate direction · in-toto for the attestations · the Cedar repository's layout, `cedar-spec` beside the implementation, as the worked example.

## 7. Governance of the model over time

**Status: worked 2026-10-14, for the owner's confirmation.** The review line, supersession by `deprecated`, retired examples with live coverage and the total upcaster are in `Calculus.lean`; the three open questions each have a recommendation in [policy-promises-and-governance.md](policy-promises-and-governance.md).

**The problem.** A journey changes. An event gets a new version. An example no longer describes the product. The documents have a rule for this, the changelog, superseding adds a row and leaves the old one; the model has none, and a proof that is in the way can be edited to pass.

**Why it blocks consistency.** A model whose history is not governed is a model whose theorems mean "true at the moment someone last touched them."

**Proposed rule.** The changelog rule, applied to the model. A theorem is never deleted; it is superseded, with the superseding theorem naming it. An example is never deleted; it is marked superseded with the date and the design change that retired it, and the coverage theorems exclude superseded examples. An event version is never removed; its upcaster is total forever, and a retired version is one the upcaster maps and no publisher emits. The model's header carries the review line from rock 6 and the list of superseded items.

**In the calculus.** `Example` gains `supersededBy : Option String`. `Journey` terms are values and can be versioned like examples. The upcaster's totality is the exhaustiveness check Lean already does.

**In the documents.** The changelog gets rows for model changes, pointing at the Lean file and the theorem. The conventions document gets the rule in one line.

**Open questions.**

- When a design's boundary moves and statements move whole, what moves in the model, and does associativity (threat 7) make it a rename rather than a change?
- How long does a retired event version keep its upcaster? Proposal: as long as any history contains it, which the retention windows bound.
- Who may supersede a theorem?

**Prior art.** The project's changelog and conventions · Avro schema evolution and the registry's compatibility modes · Greg Young, *Versioning in an Event Sourced System*, 2017.

## Parked, on purpose

All seven rocks are worked as of 2026-10-14, each with what it leaves open in its note. What remains parked:

- **The saga and commands over RPC between cells**, and how the error risk ratio is budgeted. The owner's call; the rocks above do not depend on it, and rock 1's key is the precondition any answer needs.
- **Threat 7's remainder**: the general memory discipline for theorem 2 and the monoid laws for combining cells.

## Suggested order

1 first, because 3 and 5 need its fields and threat 1's per-journey traces need its causation. Then 2 and 4 together, since both are types the designs will use on day one. Then 3, which resolves an open item in the methodology. Then 6, so the rest runs. 5 and 7 when the first traces exist.
