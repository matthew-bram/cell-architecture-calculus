# The hold shelf readies a copy once

Annotated design · the pickup slice of `designs/holds.md` at hash `d8873348e0cb0852`, a copy of which is `source.md` beside this file · drafted by the annotate-a-design skill, for the owner's confirmation

**Scope.** The slice the owner named: the hold shelf, pickup, the cell that readies a copy when it has come in and a hold is waiting, in either order. The holds cell itself, placing and cancelling a hold, is outside it and keeps its sentences for a later annotation.

**What this document is.** The tables hold only what the design states, each row traced to its sentence in the provenance section. What a table needs and the design does not give is in the gaps section as a question or a proposal for the owner, never in a table. The design owns meaning; this annotation owns nothing until the owner confirms it, and then the design does.

## Pickup

**Purpose.** From the design: the hold shelf, one record per copy; a copy is ready for pickup when it has come in and a hold is waiting on it, the two facts arriving in either order, and pickup remembers whichever came first. It commands nothing and accepts no command.

### Commands

| id | name | sender | fields | refusals |
| --- | --- | --- | --- | --- |
| none | | | | |

### Subscribes

| event | from cell |
| --- | --- |
| checkedIn, as the copy returned | circulation |
| holdPlaced, as the copy held | holds |

### Publishes

| id | name | fields |
| --- | --- | --- |
| sawReturn | the copy came in | item : String |
| sawHold | a hold is waiting on the copy | item : String |
| readyForPickup | the copy is on the hold shelf | item : String |

### State

| field | type | invariant |
| --- | --- | --- |
| returned | Bool | whether the copy has come in |
| held | Bool | whether a hold is waiting |

### Decide

| command | reads | branch | outcome |
| --- | --- | --- | --- |
| none | | | |

The cell accepts no command, so there is no Decide row; every row of its behaviour is a React row.

### React

| foreign event | branch | outcome |
| --- | --- | --- |
| returned item | a hold is waiting | sawReturn item; readyForPickup item |
| returned item | otherwise | sawReturn item |
| held item | the copy has come in | sawHold item; readyForPickup item |
| held item | otherwise | sawHold item |

### Terminal

The state is terminal when the copy has come in and a hold is waiting.

### Examples

| id | given | with | when | expect |
| --- | --- | --- | --- | --- |
| PICKUP-1 (the return first) | sawReturn "b-1" | | held "b-1" | sawHold "b-1"; readyForPickup "b-1" |
| PICKUP-2 (the hold first) | sawHold "b-1" | | returned "b-1" | sawReturn "b-1"; readyForPickup "b-1" |
| PICKUP-3 (one alone) | nothing | | returned "b-1" | sawReturn "b-1" |

The ids are proposed, in the project's style; the rows are the design's three examples as it gives them.

### Universal claims

| name | sentence |
| --- | --- |
| deliver_returnFirst | for every copy, delivering the return and then the hold readies the copy exactly once |
| deliver_holdFirst | for every copy, delivering the hold and then the return readies the copy exactly once |
| deliver_oneFact_notReady | for every copy, one fact alone readies nothing |

### Sentences

Not stated; see gaps.

### Wire

Not applicable: the cell accepts no command, so nothing of it is on the wire as a command. Its facts' wire shape is not stated; see gaps.

## The journey

Not stated as a journey of its own; the design places pickup at step 1 of journey 4, waiting on the hold placed in that run and the copy checked in by a run of journey 3. See gaps.

### Contracts

Not stated; see gaps.

### Attributes

| name | scope | subject | promise or relation or measure | threshold |
| --- | --- | --- | --- | --- |
| a copy readied exactly once when both facts are in | artifact | the copy, in the stacks | the three universal claims above, as theorems | |

## Provenance

| row | the design's words | where |
| --- | --- | --- |
| the empty Commands table and the empty Decide table | "It commands nothing, and it accepts no command: everything it does is a reaction" | The hold shelf, opening paragraph |
| Subscribes | "Circulation's *checked in*, which pickup reads as the copy returned; and holds' *hold placed*, which pickup reads as the copy held" | The hold shelf, what it listens to |
| Publishes | "Three facts, each naming the copy. *The copy came in.* *A hold is waiting on the copy.* *The copy is on the hold shelf.*" | The hold shelf, what it publishes |
| State | "Per copy, whether the copy has come in and whether a hold is waiting" | The hold shelf, what it keeps |
| React, the four rows in order | "When the copy returns and a hold is waiting … saw the return and that the copy is ready. When the copy returns and no hold is waiting … only that it saw the return. When a hold is placed and the copy has already come in … saw the hold and that the copy is ready. When a hold is placed and the copy has not come in … only that it saw the hold" | The hold shelf, how it reacts |
| Terminal | "The record is finished when the copy has come in and a hold is waiting" | The hold shelf, when it is done |
| the three universal claims | "For every copy, delivering the return and then the hold readies the copy exactly once. For every copy, delivering the hold and then the return readies the copy exactly once. For every copy, one fact alone readies nothing" | The hold shelf, what must always hold |
| the three examples | "First, the return came first … Second, the hold came first … Third, one alone …" | The hold shelf, three examples the owner has given |
| "in either order" and "remembers whichever came first" | the same words | The hold shelf, opening paragraph; journey 4 of the vision |
| the attribute | "A copy readied twice, or never … The promise: none, by the three claims the hold shelf makes" | Risks, measures and promises, row 3 |
| the subject | "Every fact in this design is about a patron token in the stacks"; "one record per copy" | Risks, measures and promises, last paragraph; The hold shelf |

## Gaps, for the owner

Each is a question or a proposal. A proposal is written so that confirming it is moving it into the table above.

1. **The subject of pickup's facts.** The design keys the hold shelf by copy and says every fact is about a patron token in the stacks, yet pickup's three facts name only the copy. The project's subject type is the patron ID; which patron a readied copy is about, the first in the queue or none, decides whether pickup's facts can carry the project's subject at all. Proposal: the first patron in the queue, carried on *hold placed* and copied onto *ready for pickup*.
2. **Sentences.** None given for pickup's facts. Needed for the Gherkin a reviewer reads; proposed, in the design's voice: "copy {item} came in", "a hold is waiting on copy {item}", "copy {item} is on the hold shelf".
3. **The wire shape of the facts.** Not stated. Proposal: a tag per fact, "sawReturn", "sawHold", "readyForPickup", each with the field `item`.
4. **The ids of the examples.** The design gives the three examples without ids; PICKUP-1 to PICKUP-3 are proposed above with the design's own phrases as their notes.
5. **The journey.** Pickup's step belongs to journey 4, which composes journey 2 at its last step and succeeds from a run of journey 3; the design does not restate the step here. Proposal: the journey table stays in journey 4's section of the vision, and this design's journey table is left empty.
6. **Contracts.** No latency, availability or cost for the reaction. The acknowledgement promise in the risks is holds', not pickup's.
7. **Expiry.** The open item says a copy nobody collects may expire. If it does, the terminal state is not "both facts in" but "both facts in or expired", and a fourth fact and a fifth React row follow; nothing is written until the owner decides.
