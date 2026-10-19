# The style guide

The standard a model in the cell calculus is held to.

The purpose is consistency: two authors given the same design produce the same model, and a reader who did not write the model can tell what every name means without opening the sources. The examples are from the worked example, [examples/library](../examples/library/).

## 1. What goes where

| Package | Holds | Never holds |
| --- | --- | --- |
| `cell-calculus` | The generic shapes and their universal theorems, generic over a project's principal through the `Architecture` class and over the subject of an event as a type parameter | Anything about one project; any theorem discharged by `decide` or `rfl` on a value; Mathlib |
| A project's package | The project's `Architecture` instance, its cells, examples, journeys, contracts, attributes, runs and governance, and every theorem that is a computation on its values | A new generic shape. A shape a project needs proposes it to the generic package, with a changelog row |

One idea per module, named for the idea: `Cell`, `Journey`, `Contract`, `Envelope`, `Inputs`, `Boundaries`, `Policy`, `Promise`, `Wire`, `Coverage`, `Gherkin`, `Render`, `Replay`, `Governance`, `ContextMap`. A project mirrors the split by concern: `Architecture`, then one module per cell or slice, then `Journeys`, `Envelopes`, `Inputs`, `Policy`, `Promises`, `Boundaries`, `Governance`.

Imports come first in a file, before the module comment. The root module of each package imports every module and carries the package's overview.

## 2. Names

**Types are words.** A type parameter that has a role is named for the role: `Cell (Command ForeignEvent Event State Refusal : Type)`, `Journey (State Refusal : Type)`, `Example (Command Event Refusal : Type)`. A Greek letter is for a parameter that is genuinely arbitrary and has no role, and then Lean's conventions hold: `α β` for any type, `σ` for a state, `ε` for an error. Single Latin capitals are never used as type parameters.

**Types say what they are.** A command type ends in `Command`, an event type in `Event`, a refusal type in `Refusal`, a state type in `State`: `CirculationCommand`, `CirculationEvent`, `CirculationRefusal`, `CirculationState`. An envelope is `CommandEnvelope` or `EventEnvelope`. A wire shape ends in `WireCommand`. A refusal that wraps another says so: `GatedRefusal`, `GatewayRefusal`.

**Fields are words.** `expect`, not `then_`; `command`, not `cmd`; `subject`, not `subj`; `issuedAt` and `recordedAt`, which are two fields because they are two clocks.

**Values are named by what they are.** A cell by its name in the capability map: `circulation`, `notices`, `fines`, `pickup`, `clock`. An example by its id in the design: `loanOut2` for `LOAN-OUT-2`, `noticeWarn3` for `NOTICE-WARN-3`. A fixture by its meaning: `epoch`, `firstRun`, `patronToken`. A recorded run by what it shows: `goodRun`, `backwardsRun`, `strayRun`. Never `ex1`, `t0`, `run1`, `q`, `at_`.

**Functions are verbs or the noun of what they return.** `replay`, `handle`, `scrub`, `reidentify`, `succeed`, `envelope`; `latencyBound`, `unavailabilityBudget`, `toNodes`, `toGherkin`.

**Theorems are named for what they state**, subject first, then the claim, with an underscore between: `replay_append`, `checkOut_idempotent`, `compile_wellFormed`, `envelope_conforms`, `scrub_roundTrip`, `tick_monotone`, `elapsed_le_latencyBound`, `latencyBound_mono`, `forbid_overrides`, `population_kept_of_all`. An example's theorem is its name plus `_holds`: `loanOut2_holds`. A rejection's theorem says so: `badTrace_rejected`, `lateRun_burns`. Hypotheses inside a proof keep Lean's short conventions: `h`, `hc`, `ih`, `iha`.

**Reserved words.** `then` is a keyword, so the example field is `expect`. `Exception` is the `Ex` of `Either[Ex, B]` and keeps its two constructors, `refused` and `unknown`.

## 3. Comments

Every declaration carries a doc comment, `/-- ... -/`, that a reader sees on hover. It says what the thing is, what it is for, and, where the shape has a published name, what it is called in the sources: "the Decider", "the idempotent receiver", "Kleisli composition", "a reference monitor". A field in a structure gets its own doc comment when its meaning is not obvious from its name; the envelopes are the model.

Every module opens, after its imports, with a module comment, `/-! # Title ... -/`, that says what the module is about and names its sources. A section inside a module is `/-! ## Title -/`.

An example value is a declaration too: its doc comment is one line saying what the row shows, the line a reviewer reads beside the id, as `loanOut2` says a retry books nothing. A fixture envelope, a recorded run, a serializer, a parser and a predicate each carry one. The reviewer counts every `inductive`, `structure`, `def` and `abbrev` against the doc comment above it, so an undocumented helper fails review the same as an undocumented type.

A comment never restates the code. It says why, or what it is called, or what it must never be confused with. The `Exception` comment is the model: it says what each constructor means and names the bug that confusing them produces.

A doc comment cannot precede an `attribute` command; use a line comment there.

## 4. Proofs

| Claim | Discharged by | Lives in |
| --- | --- | --- |
| A computation on one project's values: an example holds, a run conforms, a trace is rejected, a bound equals a number | `decide` for Boolean and natural-number equalities; `rfl` for an `Except` equality | The project's package |
| A universal statement: for every cell, every history, every command, every key | `simp` with the definitions unfolded, `cases` on a sum, structural `induction` on a term or a list, `omega` for natural-number and integer arithmetic including `max` | The generic package, or the project's when it is about the project's cells |
| A law a type must satisfy to have an instance: the codec's round trip, the alias map's inverse | A field of the class or structure, proved at the instance | The project's instance |

No `sorry` outside stage 2 of the round trip, where the bodies are not yet written and the build is expected to fail stage 3. No `native_decide`. No Mathlib in the generic package; a claim that needs reals, distributions or filters is a distributional attribute and is marked measured until a project decides to take the dependency.

A universal theorem states its hypotheses as named arguments, not as `∀` in the conclusion, so that the hypothesis is visible in the signature: `(h : may envelope.actor envelope.payload = false)`.

The deprecated attribute goes beside the theorem it supersedes, in the same module, with the successor's name and the date.

## 5. The shapes a model may use, and the ones it may not

A model is built only from the generic package's shapes. A project introduces no new generic shape; it proposes one.

| Use | Never |
| --- | --- |
| `Cell` with its three functions and the fold | A function from an event to a command, anywhere |
| `Journey.step`, `seq`, `par` | A loop, a retry in place, a step that re-enters an earlier step |
| `CommandEnvelope` and `EventEnvelope` with their fixed fields | A header map, a field a cell reads that the type does not name |
| `Inputs` for a decider that needs an answer or the clock | A call to a gateway or a clock inside `decide` |
| `BoundedId` from `Boundaries`, as the envelope's subject, for an ID the project's alias map maps | An ID without its boundary; an opaque ID with a boundary it does not need; a subject the generic package names |
| `AliasMap`, `scrub`, `reidentify` | A second function whose type names two boundaries |
| `succeed` into a `policy` cell at a journey boundary | An event becoming a command inside a journey |
| `RunPromise` and `Attribute` with its scope | An attribute with no scope; a service level written as a single example; a confidentiality claim checked on one run |
| `StepContract` and the folds | An end-to-end number nobody derived |
| `GovernedExample`, `deprecated`, the review line | A deleted theorem or example; an edited proof that was in the way |
| `Actor`'s five kinds: a principal, a policy cell, a timer, a partner, the operator | A sixth kind added in a project; a project that needs one proposes it to the generic package, with a changelog row |

## 6. The data dictionary is the acceptance test for the types

A type signature is only as true as the values that fill it. Every field has a meaning, a domain and an example value, and a field whose domain admits a value its meaning forbids is a wrong type, not a missing comment. An integer that may be null is `Option Int` or it is a defect. A string that is really one of four things is a sum. A number with a unit names the unit in the field: `latencyMs`, `unavailabilityPpm`, `costMicros`.

## 7. Every attribute names its quantifier before its example

Before a quality attribute gets an example, its statement says what it ranges over, and the `Attribute` constructor fixes it: `oneRun` for a deadline, an ordering or a count; `pair` for a confidentiality claim; `population` with a threshold for a service level; `distribution` for anything that says probability or expected, which is measured and says by what; `artifact` for a structural rule. An example then has the matching shape: one run, a pair of runs, a sample with a ratio, or no example.

## 8. The annotation a design carries

Fixed headings and columns in a design document, prose elsewhere. The model is transcribed from these one to one; [designs/circulation.md](../examples/library/designs/circulation.md) is the worked instance.

| Table | Columns | Becomes |
| --- | --- | --- |
| Commands | id, name, sender, fields, refusals | `XCommand`, `XRefusal`, and the senders as the actor policy |
| Subscribes | event, from cell | the `ForeignEvent` parameter |
| Publishes | id, name, fields | `XEvent` |
| State | field, type, invariant | `XState`, and a theorem per invariant |
| Decide | command, reads, branch, outcome, one row per branch | the body of `decide`; "reads" names the queries, and an empty "reads" earns a no-reads theorem |
| React | foreign event, branch, outcome | the body of `react` |
| Examples | id, given, with, when, expect | `Example` values, each with its `_holds` theorem |
| Contracts | step, latencyMs, unavailabilityPpm, costMicros, peakUnits | `Contracts` |
| Attributes | name, scope, subject, promise or relation or measure, threshold | `Attribute` values, each over the subject its row names: what the run's events are about and, where the project has boundaries, in which one |

A design with Commands and no Decide rows fails the same check as one with no examples.

## 9. The annotation a journey carries

Fixed headings and columns in each journey section of the vision document, prose elsewhere: the touchpoints, the moments that matter and the member's view stay as the author wrote them, and the map never reads them. The journey map transcribes the two tables one to one and checks them. A section without them is read out of its prose, and every reading is a gap. [corpus/vision.md](../examples/library/corpus/vision.md) is the worked instance.

| Table | Columns | Becomes |
| --- | --- | --- |
| Steps | #, step, cells, waits on, publishes, partner | one `Step` per row with its cells, and `wellFormed` over them; the published fact names the arrow from this step's cells to the cells of the steps that wait on it, which is a row of the architecture's paths table and later a row of a design's Publishes |
| References | journey, kind, at step | the composition relation where the kind is composition, with the step the other journey runs as; the succession relation where the kind is succession, from this journey's final fact; no edge where the kind is pointer |

The columns:

- **cells** holds the capability map's names and nothing else: never a role, a surface or a team. "The desk" is not a cell; membership is. A platform cell is named on the step where it acts, the terminals on the step that shows the receipt, because the capability map's "in every journey" is a claim checked step by step, not a reason to leave it off. A step whose cell is not decided says "not stated", and the map records the gap; a role in the column is read to a cell and recorded as a gap too.
- **waits on** holds step numbers, all earlier. Fan-out is two steps waiting on the same one; fan-in is one step waiting on several. A step that waits on a later step is a cycle, which the map reports and never reorders.
- **publishes** is the fact that moves the journey on, in the design's words where a design exists and in the journey's own words where it does not. The step with no fact is the last.
- **partner** names a party that is not a cell, the message provider, the payment provider, so that the arrow is a partner call and not a missing cell.
- A condition on a step, "if the card is at its limit", is a mode of that step's cells, written in the step's text, not a row of its own.
- **kind** is one of composition, succession or pointer, from [the DAG rule](the-dag-rule.md): composition runs another journey as a step of this run and must be acyclic; succession is this journey's final fact starting a new run of another, and may cycle; a pointer sends the reader elsewhere and is no edge.

What a journey decides, and what it does not. Per step, five things: the cells, what it waits on, the fact that moves it on, any partner, and where the run ends. The kind of each arrow is the architecture's paths table's. A field, a refusal, an example is the design's, section 8. The capability map's matrix row for a journey is the set of cells in its Steps table, platform cells aside: generated from the table where the map can be, compared with it by theorem where the map is kept by hand.

The checks, one theorem each in the journey map, which an author writes the tables to:

| Check | Theorem |
| --- | --- |
| Every step waits only on earlier steps | `<journey>_isDag` |
| The capability map's matrix row equals the cells on the steps | `matrixRow<n>_matchesJourney` |
| Every arrow the steps imply is a row of the paths table with a kind, and no path breaks the architecture's direction rule | the rule's theorem, named as the architecture names the rule |
| Composition between journeys is acyclic | `composition_isAcyclic` |
| A platform cell the map claims for every journey is on a step of this one | `journey<n>_passesThrough<cell>` |

A journey whose Steps table names a role in the cells column, or whose References table has no kind, fails the same check as a design with Commands and no Decide rows.

## 10. What a reviewer checks

In this order, because each depends on the last.

1. **The names.** Every type, field, value and theorem follows section 2, and a reader can tell what each is from its name.
2. **The comments.** Every declaration has one, and it says what the thing is called in the sources where it has a name.
3. **The theorems state the right thing.** Read each universal theorem's statement against the design's sentence it stands for. A proof of the wrong statement is the failure mode a kernel cannot catch.
4. **Coverage.** Every command kind, event kind and refusal reason appears in an example, which the build checks, and every branch of `decide` has an example, which the reviewer checks.
5. **The build.** `lake build`, the generators, the review check and the mutation score all green.
6. **The review line.** The project's header names the design and its hash, and the reviewer signs it.

## 11. Governance

A theorem or an example is never deleted. A theorem is superseded with `deprecated`, naming its successor and the date; an example is retired in its `GovernedExample` with the successor, the date and the reason. An event version is never removed; the upcaster stays total. A change to a public shape of the generic package is a supersession and a changelog row, never an edit. A boundary move is a rename with a deprecated alias, never a change of statement.
