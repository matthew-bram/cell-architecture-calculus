# The policy cell, promises as trace predicates, and governance of the model

Rocks 3, 5 and 7, worked · Oct 14, 2026 · from [big-rocks.md](big-rocks.md), with the shapes in `Calculus.lean`, a recommendation on each open question, and the document edits for the owner to confirm

**Confidence.** **[H]** run here today, or read in the project's own documents; **[M]** read in a specification's summary; **[L]** from memory.

## Rock 3. Where `Event => Command` is allowed to exist

### The rule

The sink is unrepresentable inside a cell and the product has it by design. It exists in exactly one place: at a journey boundary, as succession. A journey ends with a fact. The fabric lifts the fact into a command to the one cell that subscribes to it as a root, mechanically and with no decision in it: the key is derived from the fact, the causation is the fact, the run is fresh. That cell is a **policy cell**, and its `decide` is the one place a proposal becomes a downstream command, with every branch naming its rung. Event-to-command is `decide` with a reason, never `react`.

| Shape | What it is | In the file |
| --- | --- | --- |
| `succeed` | The lift: a published fact to a command for a subscribed policy cell; actor the issuing cell, key derived from the fact's id, causation the fact, a fresh run | `succeed`, `succeed_sameKey` |
| `Rung` | Shadow, review, autonomous; the ladder, from the management plane | `Rung` |
| `policy P` | The cell: a proposal in shadow is recorded, in review is held, in autonomous is issued; an approval issues only what was held; the rung is set by a release | `policy`, `shadow_neverIssues`, `review_holds`, `approve_onlyHeld` |
| `policyMay` | A proposal arrives only by succession from the agent runtime, an approval only from a primary, the rung only from the control plane | `policyMay`, the gated `StewardPolicy` |

Four universal theorems: a retry of the lift derives the same key and cites the same fact, for every fact and every pick, so succession is idempotent by construction; in shadow a proposal never issues; in review it is held; an approval issues only what was held. Five decidable runs of the Steward's move through the ladder, including a delegate's approval refused by the actor gate before the policy cell looks.

### The three open questions, with a recommendation on each

**1. Is a person approving a review card a policy cell with a human in the loop, or a different kind of root?** The same cell. The rung "review" means the proposal is held and the command that issues it is `approve`, whose actor the gate requires to be a primary. The person is a root in the sense every member is, a sender of commands, and the policy cell is where their approval meets the held proposal. `steward_primaryApproves` and `steward_delegateRefused` are the two cases **[H]**.

**2. Does the policy cell keep the proposal as state until the rung allows, and for how long?** Yes, in `held`, which is its aggregate. How long is a retention rule for the data classification document, and the proposal here: a held proposal lives until it is approved, or until a newer proposal for the same subject arrives and replaces it, latest wins per subject, or until the window the operations model gives review cards closes. The first two are in the fold once a subject is on the proposal; the third is a tick the cell reacts to, now that the clock is a cell.

**3. The hero journey's signal, falling behind, is a succession from reminders to a plan mention; which cell is its policy?** The agent runtime's. A mention is a message, which is conversation's command, and the runtime owns the ladder for what a role's output may do. So the reminder's fact lifts into a proposal to the runtime's policy cell, whose rung decides whether the assistant speaks on its own or a review card asks first. Service operations is the same shape with telemetry as the judgment and its own policy cell, which the operations model already calls the trigger's ladder.

## Rock 5. Promises as trace predicates

### The rule

A promise is a predicate over runs, evaluated in the same pass that checks a run's shape, with a measure beside it. A burn is a failing predicate with the run that failed it named. The envelope's four fields, `issuedAt`, `recordedAt`, `causation` and `correlation`, are what the predicates read.

| Shape | What it is | In the file |
| --- | --- | --- |
| `RunPromise` | A predicate on one run | |
| `burns`, `kept` | The runs that failed, named; and the count kept over the count seen | `burns_namesLateRun`, `kept_measure` |
| `withinDuration` | For every run whose root is one of these, a target fact within the limit of the root's issue | `alertWithinHour` on the slice; `promptRun_keeps`, `lateRun_burns` |
| `atMostCount`, `neverAfter` | At most this many target facts; no later fact after a fence fact | |
| `withinDuration_mono` | Loosening the limit never breaks a kept promise, for every root, target, limit and run; the reason a promise can be tightened in steps | Proved **[H]** |

### The three open questions, with a recommendation on each

**1. Which promises are about one run and which about a population?** `withinDuration`, `atMostCount` and `neverAfter` are per run; `kept` is the population measure and its window is the list of runs handed to it, which the trace checker takes from a time range. "80% of alerts rated useful" is a population promise over a fact that does not exist yet: the rating. Until conversation publishes "alert rated" as an event, it is a measurement and the register says so; once it does, it is `kept` of "an alert run contains a rating fact that says useful" over the window.

**2. Do production traces carry enough to evaluate without carrying tenant data?** For timing and counting, yes: the shapes read `issuedAt`, `recordedAt` and which kind of fact an event is, and the telemetry schema already carries kind, tenant ID of the zone and time. What they must not read is the payload's content. The library here takes `E → Bool` on the payload, which in the model is a kind test; in the checker it should be a test on the telemetry's kind field, so that a promise can be evaluated in the operations zone on de-identified traces. Recommend that the trace checker's input is the telemetry event, not the domain event.

**3. Is a promise a theorem over the model as well?** For ordering, yes: "no statement after the close" is `neverAfter` on traces and is also a theorem on the model, because the model orders a cell's events and `replay` is deterministic. For durations, no: the model has no clock between cells, and a duration promise is a fact about the world the trace checker holds. The register should say which of its rows are theorems and which are checks.

## Rock 7. Governance of the model over time

### The rule

The changelog rule, applied to the model. A theorem is never deleted; it is superseded by name, with Lean's own `deprecated` attribute, so any use of the old one warns and names the new one. An example is never deleted; it is marked superseded with the date and the design change that retired it, and the coverage theorems run over the live examples only. An event version is never removed; the upcaster from every version is total, which is the exhaustiveness check Lean already does. The model's header carries the review line and the superseded list, and the build checks the review line against the design's hash.

| Shape | What it is | In the file |
| --- | --- | --- |
| `ReviewLine`, `ModelHeader`, `calculusHeader` | The design's path and content hash at review, the reviewer, the date; the superseded list | Header says "unreviewed" today, and `review-check.py` warns |
| `attribute [deprecated ...]` | A superseded theorem stays; a use warns and names the successor | `commitJourney_fires`, superseded by `commitJourneyTerm_fires` |
| `RetiredExample` | An example with `supersededBy`, `retiredOn`, `because`; `live` filters | `booksSet`, with `BOOKS-LOCK-1` retired in favor of the gated `BOOKS-ACTOR-4` |
| `liveExamples` and its four theorems | Consistency and coverage over the live set | **[H]** |
| `hole_isNamed` | Retiring an example without a successor fails coverage, and the theorem names the command kind | **[H]** |
| `BooksEventAny`, `upcast` | The sum over every version published; the upcaster total by exhaustiveness; a retired version is one the upcaster maps and no publisher emits | `replay_upcast` |

### The three open questions, with a recommendation on each

**1. When a boundary moves and statements move whole, what moves in the model?** Definitions move between namespaces or files and theorem names stay. Threat 7's associativity says the composite is the same under every cut, so the move is a rename and not a change of meaning, and the build should treat it so: a renamed theorem gets a `deprecated` alias under the old name for one release, and the superseded list records the move. A move that changes a theorem's statement is not a rename and gets a new name.

**2. How long does a retired event version keep its upcaster?** As long as any history contains it, which the retention windows in the data classification document bound: ninety days for a lapsed plan, the tenant's lifetime for the books. The practical rule is that an upcaster branch is removed only when the oldest retained history is newer than the version, and the removal is a changelog row.

**3. Who may supersede a theorem?** The reviewer named on the review line, and the build enforces the form: a `deprecated` attribute and a superseded-list entry together, or the build fails. A theorem that is simply deleted fails the build because the superseded list does not name it, which is the check the next step of the build should add.

## What this changes in the architecture documents

Not edited; for the owner to confirm, each with a changelog row when done.

- `agent-runtime.md`: the open item, roles as cells or tools, resolves: a role is a source of judgment facts; the runtime's policy cell is where a judgment becomes a command; the ladder is that cell's configuration from the management plane.
- `service-operations.md`, when picked up: the trigger's ladder is a policy cell with telemetry as the judgment.
- `architecture-vision.md`, the journey map: each succession edge in "What it reuses" names its policy cell or the person who sends the next command.
- `operations-model.md`, the risk register and every design's risks table: a column naming the predicate shape, or "measurement" where the checker cannot evaluate it, and whether the row is also a theorem.
- `data-classification-and-placement.md`: retention of held proposals; the rule that an upcaster branch outlives the oldest history that needs it.
- `CONVENTIONS.md`: one line, the changelog rule applies to the model: theorems and examples are superseded, never deleted.
- `GLOSSARY.md`, the method: rows for succession, policy cell, rung, promise, review line.

## What this leaves open

- The policy cell's `held` has no subject yet, so "latest wins per subject" is stated and not modeled.
- The promise library reads the payload kind; the checker should read the telemetry kind, and that mapping is the telemetry design's.
- The build checks the review line and not yet the superseded list; a deleted theorem is caught only by a use of it.
- The model's header is unreviewed. The first review against the books design is the owner's, and the date and hash go on the line.

## Sources

- Richardson, *Microservices Patterns*, 2018, the orchestration saga, which rock 3 confines to one cell · Adam Dymitruk, Event Modeling's automation slice, which the policy cell constrains
- Runtime verification over finite traces, LTLf, for the promise shapes **[L]** · Cirstea, Kuppe, Loillier and Merz 2024 for traces as the input
- Greg Young, *Versioning in an Event Sourced System*, 2017 · Lean's `deprecated` attribute, in the Lean reference
- The trial's own documents, not published: the operations model, the agent runtime, [envelopes.md](envelopes.md), [queries-time-and-zones.md](queries-time-and-zones.md), [big-rocks.md](big-rocks.md) rocks 3, 5 and 7
- `Calculus.lean`, the sections "Rock 3", "Rock 5" and "Rock 7"
