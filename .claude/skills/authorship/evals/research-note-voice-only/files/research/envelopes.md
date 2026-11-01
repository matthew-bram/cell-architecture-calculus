# The envelopes

Rock 1, worked · Oct 13, 2026 · from [big-rocks.md](big-rocks.md), with the fields in `Calculus.lean`, a recommendation on each open question, and the document edits for the owner to confirm

**Confidence.** **[H]** run here today, or read in the project's own documents; **[M]** read in a specification's summary; **[L]** from memory.

## The rule

Two envelopes, defined once, in the calculus, wrapping every `C` and every `E` of every cell. No property-bag headers: an envelope is a structure with fixed, typed fields, and a cell can read only the fields the type names. A cell that needs a field proposes it here, with a changelog row. Verified today that the alternative is unrepresentable: a decider that reads a header the type does not name is rejected with

```
error: Invalid field `headers`: The environment does not contain `Command.headers`
```

## The fields, as decided here

| Envelope | Field | Type | Why | Who sets it |
| --- | --- | --- | --- | --- |
| Command | `actor` | `Actor`, a sum: a member in a role, a policy cell, a timer, a partner, the control plane | Contract rule 4: every writer checks who is acting. The check is the first branch of every decider | The gateway, from what identity answered; a policy cell or a timer names itself |
| | `key` | `IdempotencyKey`, minted or derived | The idempotent receiver, everywhere | The sender, before the first remote call |
| | `causation` | `Option EventId` | The one fact this command succeeds; `none` for an external root | The sender |
| | `correlation` | `RunId` | The journey run; the same ID on every command and event in one run | The root's sender mints it; everyone else copies |
| | `issuedAt` | `Instant` | What time the sender thought it was; rock 2 reads it and `decide` never fetches a clock | The sender |
| | `payload` | `C` | The cell's own command type | The sender |
| Event | `id` | `EventId` | Unique in the publisher's history | The publisher's shell |
| | `causation` | `CausationId`, a command key or an event ID | The DAG edge: what this fact is a reaction to | The publisher's shell, from the command or the foreign fact in hand |
| | `correlation` | `RunId` | Copied from the cause | The publisher's shell |
| | `version` | `SchemaVersion` | The upcaster's input; Avro's compatibility rule is the wire counterpart | The publisher's build |
| | `tenant` | `TenantId z`, indexed by the zone | Exactly one, of the zone's kind; the index is the point | The publisher's shell |
| | `recordedAt` | `Instant` | When the publisher recorded it, which is not when it happened | The publisher's shell |
| | `payload` | `E` | The cell's own event type | The fold's output |

Two things the table fixes that the rock left loose. The fold never sees an envelope: `decide`, `react` and `evolve` take and return bare payloads, and the shell wraps what they emit. That keeps every theorem about a cell's behavior as it was. And the tenant ID on an event is indexed by zone now, not when rock 4 is worked, because the event envelope needs the field and the index costs one line.

## The four open questions, with a recommendation on each

**1. Is `actor` a sum over kinds, or a reference identity resolves?** A sum, carrying what identity returned: a member is their member ID with its role. Three reasons. Contract rule 4 says identity answers who; if the envelope carried only a member ID, every decider would have to ask identity for the role, and `decide` would no longer be pure, which is rock 2's problem arriving early. A sum makes the actor branch of a decider a `match` the kernel checks is total, so a design cannot forget the timer or the control plane. And the operations model's telemetry already carries an actor as a kind, the tenant, the system, AIOps, a support person, a partner; the envelope's sum refines that kind and projects onto it. The member ID is foreign on every cell but identity, which is what the ID map already says **[H]**.

**2. Does `causation` on a command point at one event, or may a command be the succession of several?** One. A command is the succession of exactly one fact, the one that made the policy cell or the person decide. Where several facts are needed before a command may issue, the fan-in is a cell with memory, theorem 2 of threat 7: the earlier facts are in that cell's history, it emits one fact when the last arrives, and the command succeeds that one. The DAG stays a DAG and nothing is lost: the fan-in cell's own events cite each incoming fact, so the full ancestry is in the traces. Several causes on a command would make a run's root a join, and a root is where a run begins.

**3. Where does the key come from for a command a policy cell or a timer issues?** Derived, as the rock proposed, and the derivation is in the type: `IdempotencyKey.derived (issuer : String) (cause : EventId)`. A retry derives the same key from the same fact without remembering anything, and `derived_injective` says two commands with the same derived key were issued by the same cell for the same fact. A device or a partner mints; everything inside the system derives. The timer's cause is its tick, which is an event once rock 2 makes the clock a cell.

**4. Which fields are in the wire envelope and which does the fabric add?** All of them are in the wire envelope and the fabric adds nothing a cell may read. The fabric may add transport attributes, partition, offset, broker time, and the shell discards them before the parse. Mapped to CloudEvents, which the fabric's wire shape should be a profile of: `id` is `id`; `type` is the payload's kind; `source` is the publishing cell; `time` is `recordedAt`; `correlation` and `causation` are extension attributes, which CloudEvents allows and names the discipline for; `version` is `dataschema`; `tenant` is an extension attribute whose name says the zone **[M]**. The command envelope has no CloudEvents form, because commands go through a gateway and not the fabric; its wire shape is a field of the gateway's generated schema, the same for every gateway.

## What is in the file

| Item | What it says | Status |
| --- | --- | --- |
| `Command C`, `Event E z` | The two envelopes as structures, with `Actor`, `IdempotencyKey`, `CausationId`, `TenantId z` and the ID types | In `Calculus.lean` **[H]** |
| `derived_injective` | A derived key names its issuer and its cause | Proved, by cases **[H]** |
| `Cell.gated` | The actor check as a combinator over any cell: a policy says which actor may issue which command, and the lifted cell refuses before the inner decider sees the command. The refusal type is the actor or the domain | In the file **[H]** |
| `gated_refusesActor`, `gated_delegates`, `gated_replay` | A refused actor gets no further; an allowed actor gets exactly the inner decision; the fold is untouched. Universal in the cell, the policy, the command and the state | Proved, by `simp` and `cases` **[H]** |
| `booksMay`, examples `BOOKS-ACTOR-1` to `4` | The books' policy from its Commands table: the pipeline books, a primary confirms the close. A delegate refused; the pipeline books; a domain refusal survives the gate; a primary closes | Checked by `decide` **[H]** |
| `Run.conforms` | The per-journey pass: every event's correlation is the root's, and every event's causation is the root's key or an event earlier in the run. The events become nodes and the check is `Journey.nodesOk`, the rule the compiled terms and the transcribed journeys are held to | In the file **[H]** |
| `goodRun_conforms` and three rejections | The books-to-alerts run conforms; an alert recorded before the commit it cites, an alert citing a fact from another run, and a commit decided for a key other than the root's are rejected | Checked by `decide` **[H]** |
| `envelope`, `envelope_conforms` | The shell wraps what a decider emits: mints the IDs, stamps the command's key as the causation, copies the correlation. For every command, tenant, clock reading, minting function and list of events, the run so built conforms. The first step of every journey conforms by construction | Proved, by induction, with `envelope_stamps` and `nodesOk_of_noNeeds` as lemmas **[H]** |
| The zone index | An AI-zone event built with the billing ID is rejected: `Type mismatch: billingId has type TenantId Zone.accountServices but is expected to have type TenantId Zone.aiZone` | Run in a copy not kept **[H]** |

The per-journey pass is the piece threat 1 could not do: its conformance replayed one cell's commands. With causation and correlation on every event, a run's shape is checkable without replaying anything, and the replay per cell and the shape per run are two passes over the same traces.

## What this changes in the architecture documents

Not edited; for the owner to confirm, each with a changelog row when done.

- `capability-map.md`, the contract: rule 4 gains the sentence that the actor is carried on the command's envelope and checked as the first branch of the decider; and a candidate rule 8, every command and every event is wrapped in the envelope and nothing else, which is also where the DAG rule's "its gateway returns `Either[Ex, B]`" belongs.
- `product-technology-architecture.md`, the paths: the "carries" column of the domain events table and the commands table names payloads and the tenant ID only, because the envelope is the same on every path, and a sentence above the tables says so and cites this document. The sentence under "every event carries IDs" gains: and its causation, its correlation and its version.
- `data-classification-and-placement.md`, the ID map: the "IDs that no cell owns" paragraph gains run IDs beside event IDs and request IDs, minted by the root's sender; the tenant ID row says the three IDs are one type indexed by zone.
- the books design, interfaces: "every command carries an actor" cites the envelope and the books' policy is its Commands table's "open to" column, which is what `booksMay` transcribes.
- `operations-model.md`, the event schema: the telemetry actor is the projection of the envelope's actor onto its five kinds; a telemetry event about a domain event carries that event's ID and correlation, so a journey can be followed in the log.
- `GLOSSARY.md`, the method: rows for envelope, actor, idempotency key, causation and correlation, each pointing here until the calculus document exists.
- `methodology.md`, method 3: "events carry IDs" gains the envelope's four: its own ID, its cause, its run and its version.

## What this leaves open

- Whether the `version` field belongs on the command envelope too. Commands are not history, so an old command version is a gateway's parse refusal rather than an upcaster's input; proposed: no.
- The `issuedAt` and `recordedAt` pair is Lamport's two clocks and rock 2 decides what a decider may do with them; nothing here reads either.
- `envelope` sets `version := 1`. The publisher's build owns the real value, and the data model's event versioning is rock 7.
- The run ID for a succession: when a policy cell issues a command because a fact arrived, is the new run's correlation fresh or the old one's? Proposed: fresh, with the command's `causation` pointing at the fact, so a run is one journey and the chain of runs is in the causation. Rock 3 should confirm when it places the policy cell.

## Sources

- [CloudEvents specification](https://cloudevents.io/), the `id`, `source`, `type`, `time` and `dataschema` attributes and the extension-attribute rules
- Gregor Hohpe and Bobby Woolf, *Enterprise Integration Patterns*, 2003, "Correlation Identifier," "Message History," "Idempotent Receiver"
- Pat Helland, *Idempotence Is Not a Medical Condition*, 2012, for the key · Leslie Lamport, *Time, Clocks, and the Ordering of Events*, 1978, for why `issuedAt` and `recordedAt` are two fields
- The trial's own documents, not published: the contract, the ID map, the telemetry event schema, [threats.md](threats.md) threat 1 and threat 7, [big-rocks.md](big-rocks.md) rock 1
- `Calculus.lean`, the section "Rock 1: the envelopes"
