# Holds and the hold shelf

| | |
| --- | --- |
| Status | Draft, for annotation |
| Layer | Application |
| File | `designs/holds.md` |
| Implements | Principles [1](../corpus/vision.md#principles), [4](../corpus/vision.md#principles), [5](../corpus/vision.md#principles) |
| Serves | Journeys [3](../corpus/vision.md#journey-3-return-an-item), [4](../corpus/vision.md#journey-4-hold-an-item-and-pick-it-up) |
| Owner of | The queue of members waiting on a copy and its invariants; the gateway and the facts it publishes. Beside it, the hold shelf: pickup, the cell that lives on holds' facts and circulation's |
| Last updated | 2026-10-20 |

This design is prose. It says what the two cells do, who may ask them, what each refuses and what each publishes, in sentences; the tables the model is transcribed from are drafted from these sentences by annotation and confirmed by the owner before anything is modelled. A sentence that is not here is not in a table.

## Purpose

Holds keeps the queue on a copy: which members are waiting for it, in the order they asked. It is the only writer of that queue ([capability map](../corpus/capability-map.md#the-capabilities)); every other cell changes it by commands through its gateway, and it enforces the invariants. It knows a member by the patron token the desk put in place of the card and nothing else ([principle 1](../corpus/vision.md#principles)).

It is not circulation, which keeps the loans; not the catalog, which keeps the copies and their status; not pickup, which keeps the hold shelf. Pickup lives on holds' facts and on circulation's, and is described in its own section below because the two are designed together.

## What it owns

- **The queue.** One record per copy. The patron tokens waiting on it, first first. A patron is never in the queue twice: a second hold from a patron already waiting is refused.
- **The requests honored.** Every command carries the key its sender minted before the first attempt. A key already honored is nothing new: the same request seen twice, from a retry, a double tap or a dropped connection, is one hold ([principle 4](../corpus/vision.md#principles)).
- **The facts.** Every fact names the patron token and the copy, never a name. A placed hold says where in the queue it is, so that a reactor need not keep the queue to know.

## Interfaces

The gateway, in the three verbs ([architecture](../corpus/architecture.md#how-cells-communicate)). Every command carries an actor: a member's card with its role, or a librarian acting on the member's behalf. A guest card may use the reading room and may not hold; holds refuses a guest at the gate, before the queue is consulted.

**Place a hold.** A member, or a librarian on the member's behalf, asks to hold a copy. The request carries the key the sender minted, the copy, and the patron token the desk put in place of the card. Holds checks, in this order: if the key was already honored, nothing new happens and the answer is yes; if the patron is already waiting on the copy, the hold is refused because the patron is already waiting; otherwise the hold is placed, and the fact says the patron's place in the queue, which is one more than the number waiting before it.

**Cancel a hold.** A member, or a librarian, asks to withdraw a hold. The request carries the key, the copy and the patron token. Holds checks, in this order: if the key was already honored, nothing new happens; if the patron is not waiting on the copy, the cancel is refused because the patron is not waiting; otherwise the hold is cancelled.

Holds subscribes to nothing in this draft. It decides on its own history: no decision reads another cell's record or the clock. Who is acting is the gate's rule, checked before holds decides, not a check of its own.

**What it publishes.** Two facts on the fabric. *A hold was placed*, with the key, the copy, the patron token and the position in the queue after this one. *A hold was cancelled*, with the key, the copy and the patron token.

**What it keeps.** Per copy, the tokens waiting, first first, never the same token twice; and the keys already honored, newest first. Nothing in the record is ever done: a copy's queue can always be joined again, so there is no terminal state.

## Rules

- A hold is placed once. For every key, copy and patron, and every history in which the key was already honored, a repeated place produces no event.
- The first hold is first. For every key, copy and patron, a hold placed on an empty queue with a fresh key is at position one.
- After a cancel the queue closes up: the next hold is one place earlier than it would have been.

## The hold shelf

Pickup is the hold shelf, one record per copy. A copy is ready for pickup when it has come in and a hold is waiting on it, and the two facts arrive in either order: pickup remembers whichever came first ([journey 4](../corpus/vision.md#journey-4-hold-an-item-and-pick-it-up)). It commands nothing, and it accepts no command: everything it does is a reaction.

**What it listens to.** Circulation's *checked in*, which pickup reads as the copy returned; and holds' *hold placed*, which pickup reads as the copy held.

**What it publishes.** Three facts, each naming the copy. *The copy came in.* *A hold is waiting on the copy.* *The copy is on the hold shelf.*

**What it keeps.** Per copy, whether the copy has come in and whether a hold is waiting.

**How it reacts.** When the copy returns and a hold is waiting, pickup records that it saw the return and that the copy is ready. When the copy returns and no hold is waiting, it records only that it saw the return. When a hold is placed and the copy has already come in, it records that it saw the hold and that the copy is ready. When a hold is placed and the copy has not come in, it records only that it saw the hold.

**When it is done.** The record is finished when the copy has come in and a hold is waiting.

**What must always hold.** For every copy, delivering the return and then the hold readies the copy exactly once. For every copy, delivering the hold and then the return readies the copy exactly once. For every copy, one fact alone readies nothing.

**Three examples the owner has given.** First, the return came first: given that pickup saw the copy b-1 come in, when a hold on b-1 arrives, pickup records that it saw the hold and that b-1 is ready. Second, the hold came first: given that pickup saw a hold on b-1, when b-1 comes in, pickup records that it saw the return and that b-1 is ready. Third, one alone: given nothing, when b-1 comes in, pickup records only that it saw the return.

## Risks, measures and promises

- **A member waits without knowing.** The measure is the time from the member's request to the fact that acknowledges it. The promise: a hold acknowledged within a minute of the request, for ninety-nine in a hundred requests, measured over the patron's runs in the stacks.
- **The same member twice in a queue.** The measure is the number of queues holding a token twice. The promise: none, which the rule above makes a claim about the model rather than a count.
- **A copy readied twice, or never.** The measure is the number of copies readied other than exactly once when both facts are in. The promise: none, by the three claims the hold shelf makes.
- **A write from the wrong actor.** The measure is the number of commands accepted from a guest's card. The promise: none; the gate refuses before holds decides.

Every fact in this design is about a patron token in the stacks and nothing in another zone; a name is put back at the desk, by membership, before a member hears anything.

## Defaults

| Default | Value | Behavior it tunes |
| --- | --- | --- |
| Acknowledgement | 1 minute | The time the promise allows between a request and its fact |

## Open items

- **A hold on a copy that is on the shelf.** The paths table lists a query from holds to circulation, whether a copy is on loan. Whether holds should refuse a hold on a copy that is not out, with that query as the decision's read, is open; in this draft holds reads nothing.
- **Fulfilling a hold.** When the member picks the copy up, the checkout is circulation's fact and names no patron. How the hold leaves the queue, by a cancel from the desk or by a fact pickup publishes, is open.
- **Expiry.** A copy on the hold shelf that nobody collects. Whether the hold expires, after how long, and who publishes that it did, is open.
