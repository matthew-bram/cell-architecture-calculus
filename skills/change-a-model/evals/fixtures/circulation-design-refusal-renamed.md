# Circulation

| | |
| --- | --- |
| Status | Draft, for review |
| Layer | Application |
| File | `designs/circulation.md` |
| Implements | Principles [1](../corpus/vision.md#principles), [4](../corpus/vision.md#principles), [5](../corpus/vision.md#principles), [6](../corpus/vision.md#principles) |
| Serves | Journeys [2](../corpus/vision.md#journey-2-borrow-an-item), [3](../corpus/vision.md#journey-3-return-an-item), [4](../corpus/vision.md#journey-4-hold-an-item-and-pick-it-up), [5](../corpus/vision.md#journey-5-an-item-runs-late), [6](../corpus/vision.md#journey-6-renew), [7](../corpus/vision.md#journey-7-leave) |
| Owner of | The loan record and its invariants; the limit; closing a card's loans; the gateway and the facts it publishes. Beside it, the three cells that live on its facts: notices as it warns, fines as it assesses, pickup as it readies the hold shelf; and renewals, the policy cell through which a proposal reaches it |
| Last updated | 2026-10-20 |

This design is written to the method's tables: prose where the meaning is, and a fixed set of tables the model is transcribed from one row to one definition. A table holds only what the prose states; what the prose does not state is in the open items, never in a table.

## Purpose

Circulation keeps the loans on a card: what is out, and the requests it has already honored. It is the only writer of the loan record ([capability map](../corpus/capability-map.md#the-capabilities)); every other cell changes it by commands through its gateway, and it enforces the invariants. It knows a member by the patron token the desk put in place of the card and nothing else ([principle 1](../corpus/vision.md#principles)).

It is not the catalog, which keeps the copies and their status; not holds, which keeps the queue; not fines, which keeps what is owed. Those live on circulation's facts.

## What it owns

- **The loans.** The items on loan on a card, newest first. A card holds at most five items; the sixth checkout is refused.
- **The requests honored.** Every command carries the key its sender minted before the first attempt. A key already honored is nothing new: the same request seen twice, from a retry, a double scan or a dropped connection, is one loan ([principle 4](../corpus/vision.md#principles)).
- **Whether the card is closed.** A closed card takes no new loans and no renewals; its items still come back. Once closed, a card stays closed.
- **The facts.** Every fact names the patron token and the copy, never a name. A checkout says how many items the card now holds, so that a reactor need not keep the loans to know.

## Interfaces

The gateway, in the three verbs ([architecture](../corpus/architecture.md#how-cells-communicate)). Every command carries an actor: a member's card with its role, the renewals policy cell, or a librarian. A guest card may use the reading room and may not borrow; circulation refuses a guest at the gate, before the loan record is consulted. Closing a card is a librarian's command.

### Commands

| id | name | sender | fields | refusals |
| --- | --- | --- | --- | --- |
| checkOut | check an item out | a member, or a librarian on the member's behalf | key : String, item : String | cardClosed; fiveAlreadyOnLoan |
| checkIn | check an item in | a member, or a librarian | key : String, item : String | notOnLoan |
| renew | renew a loan | a member, a librarian, or the renewals policy cell when a proposal is issued | key : String, item : String | cardClosed; notOnLoan |
| closeCard | close the card | a librarian | | |

### Subscribes

| event | from cell |
| --- | --- |
| none | |

Membership's "card closed" reaches circulation as the `closeCard` command through the gateway, not as a subscribed fact; the paths table gives the command.

### Publishes

| id | name | fields |
| --- | --- | --- |
| checkedOut | an item was checked out | key : String, item : String, onLoan : Nat, the number of items on the card after this one |
| checkedIn | an item was checked in | key : String, item : String |
| renewed | a loan was renewed | key : String, item : String |
| cardClosed | the card was closed | |

### State

| field | type | invariant |
| --- | --- | --- |
| onLoan | List String | the items on loan, newest first; never more than five |
| seen | List String | the keys already honored, newest first |
| closed | Bool | once true, stays true |

### Decide

| command | reads | branch | outcome |
| --- | --- | --- | --- |
| checkOut | | the card is closed | refused: cardClosed |
| checkOut | | the key is in seen | ok, no events |
| checkOut | | five items are on loan | refused: fiveAlreadyOnLoan |
| checkOut | | otherwise | ok: checkedOut key item, with the count after this one |
| checkIn | | the key is in seen | ok, no events |
| checkIn | | the item is not on loan | refused: notOnLoan |
| checkIn | | otherwise | ok: checkedIn key item |
| renew | | the card is closed | refused: cardClosed |
| renew | | the key is in seen | ok, no events |
| renew | | the item is not on loan | refused: notOnLoan |
| renew | | otherwise | ok: renewed key item |
| closeCard | | already closed | ok, no events |
| closeCard | | otherwise | ok: cardClosed |

The reads column is empty on every row: circulation decides on its own history. Who is acting is the sender column's rule, checked at the gate before `decide`, not a branch.

### Terminal

The state is terminal when the card is closed.

### Examples

| id | given | with | when | expect |
| --- | --- | --- | --- | --- |
| LOAN-OUT-1 | nothing | | checkOut "k1" "b-1" | ok: checkedOut "k1" "b-1" 1 |
| LOAN-OUT-2 (retry after unknown) | checkedOut "k1" "b-1" 1 | | checkOut "k1" "b-1" | ok, no events |
| LOAN-OUT-3 (refused, card closed) | cardClosed | | checkOut "k2" "b-2" | refused: cardClosed |
| LOAN-OUT-4 (the sixth is refused) | five items checked out, "b-1" to "b-5" | | checkOut "k6" "b-6" | refused: fiveAlreadyOnLoan |
| LOAN-OUT-5 (the fifth is fine) | four items checked out, "b-1" to "b-4" | | checkOut "k5" "b-5" | ok: checkedOut "k5" "b-5" 5 |
| LOAN-IN-1 | checkedOut "k1" "b-1" 1 | | checkIn "k2" "b-1" | ok: checkedIn "k2" "b-1" |
| LOAN-IN-2 (not on loan) | nothing | | checkIn "k2" "b-9" | refused: notOnLoan |
| LOAN-IN-3 (retry after unknown) | checkedOut "k1" "b-1" 1; checkedIn "k2" "b-1" | | checkIn "k2" "b-1" | ok, no events |
| LOAN-IN-4 (a closed card's item comes back) | checkedOut "k1" "b-1" 1; cardClosed | | checkIn "k2" "b-1" | ok: checkedIn "k2" "b-1" |
| LOAN-RENEW-1 | checkedOut "k1" "b-1" 1 | | renew "k3" "b-1" | ok: renewed "k3" "b-1" |
| LOAN-RENEW-2 (not on loan) | nothing | | renew "k3" "b-9" | refused: notOnLoan |
| LOAN-CLOSE-1 | nothing | | closeCard | ok: cardClosed |
| LOAN-CLOSE-2 | nothing | | closeCard | ok: cardClosed |
| LOAN-CLOSE-3 (already closed, quiet) | cardClosed | | closeCard | ok, no events |
| LOAN-ACTOR-1 (guest refused) | nothing | | checkOut "k1" "b-1", from a guest's card | refused at the gate: wrong actor |
| LOAN-ACTOR-2 (member borrows) | nothing | | checkOut "k1" "b-1", from a member's card | ok: checkedOut "k1" "b-1" 1 |
| LOAN-ACTOR-3 (domain refusal survives the gate) | cardClosed | | checkOut "k2" "b-2", from a member's card | refused: cardClosed |
| LOAN-ACTOR-4 (librarian closes) | nothing | | closeCard, from a librarian's card | ok: cardClosed |

LOAN-CLOSE-1 is retired as of 2026-10-19, superseded by LOAN-ACTOR-4, because closing a card is a librarian's command and the row names no actor; LOAN-CLOSE-2 is the live close example without the envelope. The four ACTOR rows transcribe the sender column through the gate: the actor rides on the command's envelope and is checked before circulation decides.

### Universal claims

| name | sentence |
| --- | --- |
| checkOut_idempotent | for every key, item and open-card state in which the key was already honored, a repeated checkout produces no event |
| closed_refusesCheckOut | for every key and item, a checkout on a closed card is refused with cardClosed, whatever is on loan |

### Sentences

| value | sentence |
| --- | --- |
| checkOut key item | a checkout arrives with key {key} for copy {item} |
| checkIn key item | a return arrives with key {key} for copy {item} |
| renew key item | a renewal arrives with key {key} for copy {item} |
| closeCard | the card is closed |
| checkedOut key item n | copy {item} was checked out under key {key}, {n} on loan |
| checkedIn key item | copy {item} was checked in under key {key} |
| renewed key item | copy {item} was renewed under key {key} |
| cardClosed | the card was closed |
| refusal cardClosed | it is refused because the card is closed |
| refusal fiveAlreadyOnLoan | it is refused because five items are already on loan |
| refusal notOnLoan | it is refused because the copy is not on loan |

### Wire

| command | kind | fields |
| --- | --- | --- |
| checkOut | "checkOut" | key, item |
| checkIn | "checkIn" | key, item |
| renew | "renew" | key, item |
| closeCard | "closeCard" | |

The parse is the identity up to shape: membership forwards the member's request in circulation's own terms, a customer of circulation's gateway, so a tag circulation does not know and a field a command needs and lacks are the only refusals.

## Notices

**Purpose.** Notices keeps the warning level and warns when a checkout takes a card over it ([principle 5](../corpus/vision.md#principles)). It commands nothing. The name is put back by membership before anything leaves the desk; this design models the decision to warn and not the sending.

### Commands

| id | name | sender | fields | refusals |
| --- | --- | --- | --- | --- |
| setWarningLevel | set the warning level | a librarian | level : Nat | |

### Subscribes

| event | from cell |
| --- | --- |
| checkedOut | circulation |
| checkedIn | circulation |
| renewed | circulation |
| cardClosed | circulation |

### Publishes

| id | name | fields |
| --- | --- | --- |
| limitWarning | the card is at its limit | item : String, onLoan : Nat |
| warningLevelSet | the warning level was set | level : Nat |

### State

| field | type | invariant |
| --- | --- | --- |
| warnAt | Nat | the level last set; 4 before any, so that the fifth item warns |

### Decide

| command | reads | branch | outcome |
| --- | --- | --- | --- |
| setWarningLevel | | always | ok: warningLevelSet level |

### React

| foreign event | branch | outcome |
| --- | --- | --- |
| checkedOut key item onLoan | onLoan over the level | limitWarning item onLoan |
| checkedOut key item onLoan | otherwise | nothing |
| checkedIn key item | always | nothing |
| renewed key item | always | nothing |
| cardClosed | always | nothing |

### Examples

| id | given | with | when | expect |
| --- | --- | --- | --- | --- |
| NOTICE-WARN-1 | nothing | | checkedOut "k5" "b-5" 5 | limitWarning "b-5" 5 |
| NOTICE-WARN-2 (quiet) | nothing | | checkedOut "k1" "b-1" 1 | nothing |
| NOTICE-WARN-3 (at the level, quiet) | nothing | | checkedOut "k4" "b-4" 4 | nothing |
| NOTICE-WARN-4 (the level raised) | warningLevelSet 9 | | checkedOut "k5" "b-5" 5 | nothing |
| NOTICE-LEVEL-1 | nothing | | setWarningLevel 9 | ok: warningLevelSet 9 |
| NOTICE-IN-1 (a return is quiet) | nothing | | checkedIn "k2" "b-1" | nothing |
| NOTICE-RENEW-1 (a renewal is quiet) | nothing | | renewed "k3" "b-1" | nothing |
| NOTICE-CLOSE-1 (the close is quiet) | nothing | | cardClosed | nothing |

### Sentences

| value | sentence |
| --- | --- |
| setWarningLevel n | the warning level is set to {n} |
| limitWarning item n | the card is at its limit with copy {item}, {n} on loan |
| warningLevelSet n | the warning level was set to {n} |

## Fines

**Purpose.** Fines assesses what a late item costs, from the loan record and the calendar, never from an estimate ([principle 6](../corpus/vision.md#principles)). The assessment is the one decision in this design that needs another cell's answer and the date: whether the item is still out, which circulation answers stamped with its version, and the day it is, which the clock gives. The shell gathers both before fines decides; fines never asks for either. A fine is for a day late: the days late are recorded, and the amount is the days times the rate in the defaults.

### Commands

| id | name | sender | fields | refusals |
| --- | --- | --- | --- | --- |
| assess | assess an item that may be late | the schedule, as the timer | item : String, dueDay : Nat, the calendar day the item was due | alreadyReturned; notOverdue |
| settle | settle what is owed on an item | a member paying, or a librarian writing off | item : String | |

### Subscribes

| event | from cell |
| --- | --- |
| none | |

### Publishes

| id | name | fields |
| --- | --- | --- |
| fineAssessed | a fine was assessed | item : String, daysLate : Nat, asOf : Nat, circulation's version when the answer was read |
| fineSettled | a fine was settled | item : String |

### State

| field | type | invariant |
| --- | --- | --- |
| open | List String | the items with a fine open, newest first |

### Decide

| command | reads | branch | outcome |
| --- | --- | --- | --- |
| assess | stillOut, the clock | the item is not still out | refused: alreadyReturned |
| assess | stillOut, the clock | today is not past the due day | refused: notOverdue |
| assess | stillOut, the clock | otherwise | ok: fineAssessed item, the days past the due day, the version the answer carried |
| settle | | always | ok: fineSettled item |

Today is the clock reading in whole days since the epoch. The `settle` row reads nothing, which earns it the no-reads theorem: its decision is the same whatever the shell gathered and whatever time it was.

### Examples

| id | given | with | when | expect |
| --- | --- | --- | --- | --- |
| FINE-ASSESS-1 (three days late) | nothing | still out, as of circulation's version 3; day 33 | assess "b-1" due day 30 | ok: fineAssessed "b-1" 3 3 |
| FINE-ASSESS-2 (not overdue) | nothing | still out, as of 3; day 30 | assess "b-1" due day 30 | refused: notOverdue |
| FINE-ASSESS-3 (already returned) | nothing | not out, as of 4; day 33 | assess "b-1" due day 30 | refused: alreadyReturned |
| FINE-SETTLE-1 | fineAssessed "b-1" 3 3 | | settle "b-1" | ok: fineSettled "b-1" |

### Universal claims

| name | sentence |
| --- | --- |
| settle_readsNothing | for every settle command, every pair of answers and every pair of clock readings, the decision is the same |
| assess_recordsCirculationsVersion | for every pair of histories and every assessment that succeeds, the fact records circulation's version at the time the answer was read |

## Pickup

**Purpose.** The hold shelf, one record per copy. A copy is ready for pickup when it has come in and a hold is waiting on it, and the two facts arrive in either order: pickup remembers whichever came first ([journey 4](../corpus/vision.md#journey-4-hold-an-item-and-pick-it-up)). It commands nothing.

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

### Universal claims

| name | sentence |
| --- | --- |
| deliver_returnFirst | for every copy, delivering the return and then the hold readies the copy exactly once |
| deliver_holdFirst | for every copy, delivering the hold and then the return readies the copy exactly once |
| deliver_oneFact_notReady | for every copy, one fact alone readies nothing |

## Renewals

**Purpose.** The policy cell: the one place a fact becomes a command ([architecture](../corpus/architecture.md#how-cells-communicate)). The reading assistant's proposal to renew arrives by succession from its own fact; what happens to it is the rung the office set. In shadow the proposal is recorded and nothing is issued; in review it is held until the member approves; autonomous, it is issued, and the shell turns the issue into circulation's `renew` command.

### Commands

| id | name | sender | fields | refusals |
| --- | --- | --- | --- | --- |
| propose | propose a renewal | the reading assistant, as a policy cell | the renewal, as circulation's command | |
| approve | approve a held renewal | a member | the renewal | notHeld |
| setRung | set the rung | the operator | rung : shadow, review or autonomous | |

The cell is the calculus's policy cell over circulation's command type; its state, facts and branches are the calculus's, and this design adds only the sender column. The claims it makes are the calculus's theorems: in shadow nothing issues, in review a proposal is held, an approval issues only what was held.

## The journey: borrow

| step | cell | archetype | reads |
| --- | --- | --- | --- |
| circulation decides | circulation | decide | |
| notices reacts | notices | react | |

Sequence: circulation decides, then notices reacts on what it published. The journey's state is the two cells' histories.

### Contracts

| step | latencyMs | unavailabilityPpm | costMicros | peakUnits |
| --- | --- | --- | --- | --- |
| circulation decides | 30 | 20 | 4 | 2 |
| notices reacts | 10 | 100 | 2 | 1 |

### Attributes

| name | scope | subject | promise | threshold |
| --- | --- | --- | --- | --- |
| a limit warning within a minute of the checkout that reached it | population | the patron in the stacks | withinDuration isCheckOut isWarning 60000 | 99 |
| a closed card takes no new loan | artifact | the patron in the stacks | closed_refusesCheckOut | |
| a write from a guest is refused | artifact | the patron in the stacks | the gate's theorem, gated_refusesActor, with the sender column as the policy | |

## Defaults

| Default | Value | Behavior it tunes |
| --- | --- | --- |
| Loan limit | 5 items | The sixth checkout is refused |
| Warning level | 4 | The checkout that takes the card over it warns |
| Fine rate | 10 cents a day | The amount a fine's days late cost |

## Open items

- **The due day.** Circulation does not keep due days in this draft; the schedule carries the due day on the assessment. Whether circulation should publish the due day on each checkout, so that fines keeps its own projection, is a question for the holds and fines designs.
- **A hold on a renewed item.** The assistant proposes a renewal only when no hold waits; whether circulation should also refuse a renewal when a hold waits, with a query of holds, is open.
- **Grace days.** None in this draft: an item is late the day after its due day.
