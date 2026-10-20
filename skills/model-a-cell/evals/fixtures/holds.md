# Holds queues the members waiting on a copy

Annotated design for the holds cell, confirmed by the owner from the annotation of `designs/holds.md`: one record per copy, the patron tokens waiting on it in the order they asked, each request honored once, a patron never in the queue twice.

**Purpose.** Holds keeps the queue on a copy: which members are waiting for it, in the order they asked. It is the only writer of that queue; every other cell changes it by commands through its gateway, and it enforces the invariants. It knows a member by the patron token the desk put in place of the card and nothing else.

### Commands

| id | name | sender | fields | refusals |
| --- | --- | --- | --- | --- |
| place | place a hold | a member, or a librarian on the member's behalf | key : String, item : String, patron : String | alreadyWaiting |
| cancel | cancel a hold | a member, or a librarian | key : String, item : String, patron : String | notWaiting |

### Subscribes

| event | from cell |
| --- | --- |
| none | |

### Publishes

| id | name | fields |
| --- | --- | --- |
| holdPlaced | a hold was placed | key : String, item : String, patron : String, position : Nat, the place in the queue after this one |
| holdCancelled | a hold was cancelled | key : String, item : String, patron : String |

### State

| field | type | invariant |
| --- | --- | --- |
| waiting | List String | the patron tokens waiting, first first; never the same token twice |
| seen | List String | the keys already honored, newest first |

### Decide

| command | reads | branch | outcome |
| --- | --- | --- | --- |
| place | | the key is in seen | ok, no events |
| place | | the patron is already waiting | refused: alreadyWaiting |
| place | | otherwise | ok: holdPlaced key item patron, with the position one more than the number waiting |
| cancel | | the key is in seen | ok, no events |
| cancel | | the patron is not waiting | refused: notWaiting |
| cancel | | otherwise | ok: holdCancelled key item patron |

The reads column is empty on every row: holds decides on its own history. Who is acting is the sender column's rule, checked at the gate before `decide`, not a branch.

### Terminal

Never: a copy's queue can always be joined again.

### Examples

| id | given | with | when | expect |
| --- | --- | --- | --- | --- |
| HOLD-PLACE-1 | nothing | | place "k1" "b-1" "P-7" | ok: holdPlaced "k1" "b-1" "P-7" 1 |
| HOLD-PLACE-2 (retry after unknown) | holdPlaced "k1" "b-1" "P-7" 1 | | place "k1" "b-1" "P-7" | ok, no events |
| HOLD-PLACE-3 (already waiting) | holdPlaced "k1" "b-1" "P-7" 1 | | place "k2" "b-1" "P-7" | refused: alreadyWaiting |
| HOLD-PLACE-4 (second in the queue) | holdPlaced "k1" "b-1" "P-7" 1 | | place "k2" "b-1" "P-8" | ok: holdPlaced "k2" "b-1" "P-8" 2 |
| HOLD-PLACE-5 (back in the queue after cancelling) | holdPlaced "k1" "b-1" "P-7" 1; holdCancelled "k3" "b-1" "P-7" | | place "k4" "b-1" "P-7" | ok: holdPlaced "k4" "b-1" "P-7" 1 |
| HOLD-CANCEL-1 | holdPlaced "k1" "b-1" "P-7" 1 | | cancel "k3" "b-1" "P-7" | ok: holdCancelled "k3" "b-1" "P-7" |
| HOLD-CANCEL-2 (not waiting) | nothing | | cancel "k3" "b-1" "P-7" | refused: notWaiting |
| HOLD-CANCEL-3 (retry after unknown) | holdPlaced "k1" "b-1" "P-7" 1; holdCancelled "k3" "b-1" "P-7" | | cancel "k3" "b-1" "P-7" | ok, no events |
| HOLD-CANCEL-4 (the queue closes up) | holdPlaced "k1" "b-1" "P-7" 1; holdPlaced "k2" "b-1" "P-8" 2; holdCancelled "k3" "b-1" "P-7" | | place "k4" "b-1" "P-9" | ok: holdPlaced "k4" "b-1" "P-9" 2 |

### Universal claims

| name | sentence |
| --- | --- |
| place_idempotent | for every key, copy, patron and state in which the key was already honored, a repeated place produces no event |
| firstHold_isFirst | for every key, copy and patron, a hold placed on an empty queue with a fresh key is at position 1 |

### Sentences

| value | sentence |
| --- | --- |
| place key item patron | a hold arrives with key {key} for copy {item} from patron {patron} |
| cancel key item patron | a cancel arrives with key {key} for copy {item} from patron {patron} |
| holdPlaced key item patron n | patron {patron} is waiting on copy {item} under key {key}, {n} in the queue |
| holdCancelled key item patron | patron {patron}'s hold on copy {item} was cancelled under key {key} |
| refusal alreadyWaiting | it is refused because the patron is already waiting |
| refusal notWaiting | it is refused because the patron is not waiting |

### Wire

| command | kind | fields |
| --- | --- | --- |
| place | "place" | key, item, patron |
| cancel | "cancel" | key, item, patron |

The parse is the identity up to shape: membership forwards the member's request in holds' own terms, a customer of holds' gateway, so a tag holds does not know and a field a command needs and lacks are the only refusals.

## The journey: hold

| step | cell | archetype | reads |
| --- | --- | --- | --- |
| holds decides | holds | decide | |

Sequence: one step; the copy readying on the hold shelf is pickup's reaction in journey 4, outside this cell's journey.

### Contracts

| step | latencyMs | unavailabilityPpm | costMicros | peakUnits |
| --- | --- | --- | --- | --- |
| holds decides | 30 | 20 | 4 | 2 |

### Attributes

| name | scope | subject | promise | threshold |
| --- | --- | --- | --- | --- |
| a hold acknowledged within a minute of the request | population | the patron in the stacks | withinDuration isPlace isPlaced 60000 | 99 |
| a write from a guest is refused | artifact | the patron in the stacks | the gate's theorem, gated_refusesActor, with the sender column as the policy | |

## Open items

- **A hold on a copy that is on the shelf.** The paths table lists a query from holds to circulation, whether a copy is on loan. Whether holds should refuse a hold on a copy that is not out, with that query as the decision's read, is open; in this draft holds reads nothing.
- **Fulfilling a hold.** When the member picks the copy up, the checkout is circulation's fact and names no patron. How the hold leaves the queue, by a cancel from the desk or by a fact pickup publishes, is open.
- **Expiry.** A copy on the hold shelf that nobody collects. Whether the hold expires, after how long, and who publishes that it did, is open.
