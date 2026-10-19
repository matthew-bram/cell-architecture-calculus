# The capability map

The design corpus of the worked example, part two of three · with [vision.md](vision.md) and [architecture.md](architecture.md)

Each capability is one line on its purpose and one on its edge; its design owns the rest. A capability is built once and composed by the journeys ([principle 3](vision.md#principles)).

## The capabilities

**Members**

| Capability | Purpose | Edge |
| --- | --- | --- |
| Membership | Members, their cards and roles, the alias map from card to patron token, the session | Resolves a card to its token on every request and puts the name back on every notice; the only cell that knows both |
| Notices | What a member hears: the welcome, the limit warning, the hold ready, the reminder, the fine, the receipt | Sends through the message provider and the app; carries a name only after membership has put it back |

**The collection**

| Capability | Purpose | Edge |
| --- | --- | --- |
| Catalog | Items and their copies, each copy's status: on the shelf, on loan, on the hold shelf, in transit from the consortium | Reacts to circulation's facts; asks the consortium for what the town does not hold |

**Loans**

| Capability | Purpose | Edge |
| --- | --- | --- |
| Circulation | The loans on a card: check out, check in, renew; the limit of five; closing a card | The only writer of the loan record; books each request once; refuses with a reason |
| Holds | The queue of members waiting on a copy | Places and cancels holds; publishes when a copy is held |
| Pickup | The hold shelf: a copy is ready when it has come in and a hold is waiting, in either order | Remembers whichever fact came first |
| Fines | What is owed: assessed from the loan record and the calendar, settled by payment or write-off | Reads circulation's record and the clock; never estimates |
| Renewals | The proposals to renew, through the ladder: shadow, review, autonomous | The one place a proposal becomes a command to circulation |
| The reading assistant | Proposes renewals before the due day and holds on what the member has read | Proposes only; every proposal goes through renewals |

**Running it**

| Capability | Purpose | Edge |
| --- | --- | --- |
| Reports | Counts: loans, holds, overdue, by branch and month | Reads the stacks by token and never joins a token to a name |
| Operations | The staff console: the rung each automation runs at, the write-offs, the kill switch | Writes only to control queues |

**Platform**

| Capability | Purpose | Owned by |
| --- | --- | --- |
| The terminals | The desk terminals, the kiosks and the members' app: fronts over the desk with no record of their own | the lobby |
| Telemetry | What every cell emits about itself, and the enumerated commands it accepts from the office | the fabric |

Platform capabilities are in every journey and are left out of the journey matrix.

## Core, supporting and generic

| Kind | Capabilities | Why |
| --- | --- | --- |
| Core | Circulation, holds, pickup, fines, renewals, the reading assistant | What the library is for: lending, and lending well |
| Supporting | Membership, catalog, reports, operations | Built for this product, and not the point of it |
| Generic | Notices | Any product sends messages; this one sends them with the name put back |

## The journey matrix

One row per journey, the capabilities its steps name, platform capabilities aside. The row is kept here by hand and checked against the journey's steps table by theorem.

| Journey | Capabilities |
| --- | --- |
| 0 Sign in | membership |
| 1 Join | membership, notices |
| 2 Borrow an item | membership, circulation, catalog, notices |
| 3 Return an item | circulation, catalog, fines, notices |
| 4 Hold an item and pick it up | holds, pickup, notices, membership, circulation |
| 5 An item runs late | fines, notices |
| 6 Renew | assistant, renewals, circulation, notices |
| 7 Leave | membership, circulation, fines |

## Journeys by capability

| Capability | Design | Journeys |
| --- | --- | --- |
| Membership | the membership design, not yet written | 0, 1, 2, 4, 7 |
| Notices | the circulation design, as the reactor it models | 1, 2, 3, 4, 5, 6 |
| Catalog | the catalog design, not yet written | 2, 3 |
| Circulation | [designs/circulation.md](../designs/circulation.md) | 2, 3, 4, 6, 7 |
| Holds | the holds design, not yet written | 4 |
| Pickup | [designs/circulation.md](../designs/circulation.md) | 4 |
| Fines | [designs/circulation.md](../designs/circulation.md) | 3, 5, 7 |
| Renewals | [designs/circulation.md](../designs/circulation.md) | 6 |
| The reading assistant | the assistant design, not yet written | 6 |
| Reports | the reports design, not yet written | none yet |
| Operations | the operations design, not yet written | none yet |
