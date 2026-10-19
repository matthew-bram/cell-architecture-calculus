# The technology architecture

The design corpus of the worked example, part three of three · with [vision.md](vision.md) and [capability-map.md](capability-map.md)

## Cells

A cell is the unit of the architecture, in the sense of the cell-based reference architecture: a self-contained component with its own record, a gateway that is the only way in, and the facts it publishes as the only way its record reaches anyone else. Each capability on the map is one cell, and each cell is one bounded context: it owns a multi-step process and runs it as its own workflow. The terminals, the kiosks and the app are channel applications, fronts over the desk, with no record and no bounded context of their own; telemetry is a plane every cell emits to, not a cell.

### The cells by zone

| Zone | Cells | What the zone holds | Gateway into the zone |
| --- | --- | --- | --- |
| The desk | Membership; notices | Names, contact details, card numbers, the alias map, keyed by card | Signed sessions from the terminals; the identity provider; the desk's control queue |
| The stacks | Circulation; holds; pickup; fines; renewals; the reading assistant; catalog | Loans, holds, the hold shelf, fines, proposals, the catalog, keyed by patron token or by copy | Only requests the desk forwards with the token in place of the card; the stacks' control queue |
| The office | Reports; operations | Counts and the staff console; the rung of every automation; no member data | Staff sign-in; read-only feeds from the stacks |
| The lobby | None; the channel applications | Nothing after the session ends | The identity provider's sign-in |
| The fabric | None; telemetry | What every cell emits; the audit trail; the kill switch | Read-only feeds in; the office reads |

### Workflows

A bounded context owns a multi-step process and runs it as its own workflow.

| Workflow | Cell that runs it |
| --- | --- |
| Issue a card, mint its token, close the card and delete the record | Membership |
| Check out, check in, renew; the limit; closing a card's loans | Circulation |
| The hold shelf: a copy in and a hold waiting, in either order | Pickup |
| Assess, remind, settle, write off | Fines |
| A proposal's ladder: shadow, review, autonomous | Renewals |

## How cells communicate

Three verbs. A **command** goes through the owner's gateway, in the owner's terms, and the owner decides: it may refuse, with a reason, and it never does half. A **query** reads the owner's record, stamped with the owner's version at the read, so that a decision made on the answer records what it was made on. A **fact** is published on the fabric in the event schema, and any cell may react to it; the publisher never knows who. Each design lists what its gateway offers and what facts it publishes.

A cell that needs another cell's data either keeps its own projection from the facts, in whatever shape suits it, or queries. Duplicate by projection, or query; never reach into another cell's record.

A reaction never issues a command. A cell that reacts to a fact publishes its own facts and nothing else. The one place a fact becomes a command is a policy cell at the start of a journey: the fabric lifts the fact into a proposal, and the policy cell's ladder decides what happens to it. Renewals is the one policy cell in this architecture; the reading assistant's proposals reach circulation only through it.

### The ladder

Every automation runs at a rung the office sets: **shadow**, where a proposal is recorded and nothing is issued; **review**, where it is held until a person approves; **autonomous**, where it is issued. A new automation starts in shadow.

## The paths

Every arrow between cells is a row here. A design that adds a path adds a row.

### Sessions and control

| From | To | Kind | Carries | Never carries |
| --- | --- | --- | --- | --- |
| A terminal, a kiosk or the app | Membership | session | The signed-in card, the requests the member makes; back: what the member may see | A token; anything after the session ends |
| Operations | Renewals | control | The rung | A proposal |
| Operations | Membership | control | A write-off, a card closed by staff | A name the office reads back |

### Commands and queries through a gateway

| From | To | Kind | What it asks | Who enforces |
| --- | --- | --- | --- | --- |
| Membership | Circulation | command | Check out, check in, renew, on the member's behalf, with the token in place of the card; close the card's loans when the member leaves | Circulation: booked once, at most five, a closed card takes no new loans |
| Renewals | Circulation | command | Renew, when a proposal is issued | Circulation: the item is on loan |
| Holds | Circulation | query | Whether a copy is on loan | Circulation, stamped with its version |
| Fines | Circulation | query | Whether an item is still out, for the assessment | Circulation, stamped with its version |
| Reports | Catalog | query | Copies by status, for the counts | Catalog |
| Reports | Circulation | query | Loans and overdue counts by token | Circulation; reports never joins a token to a name |

### Facts on the fabric

| From | To | Kind | The fact |
| --- | --- | --- | --- |
| Membership | Circulation | event | Card issued, with its token; card closed |
| Circulation | Catalog | event | Checked out; checked in |
| Circulation | Notices | event | Checked out, with how many are on loan; renewed; card closed |
| Circulation | Pickup | event | Checked in |
| Circulation | Fines | event | Checked out; checked in |
| Holds | Pickup | event | Hold placed |
| Pickup | Notices | event | Ready for pickup |
| Fines | Notices | event | Fine assessed; fine settled |
| Renewals | Notices | event | Renewal held, for the member to approve |

A fact the stacks publish about a token is collected at the desk, where membership puts the name back before notices sends anything. A reactor that keeps the fact's shape conforms to it; one that keeps its own projection in a different shape, or puts a name back, translates at its edge.

### Partner calls

| From | To | Carries | Never carries |
| --- | --- | --- | --- |
| Membership | The identity provider | The sign-in; back: the provider's immutable ID | A loan |
| Notices | The message provider | The notice with the name put back, the contact | A token |
| Fines | The payment provider | The amount and a payment reference; back: paid or not | A name with a token beside it |
| Catalog | The consortium | A request for an item the town does not hold; back: its copy in transit | A member |

### The direction rule

**The stacks never ask the desk.** No query and no command opens from the stacks zone toward the desk zone. The desk forwards requests into the stacks with the token in place of the card, and collects facts out of the stacks to put the name back ([principle 2](vision.md#principles)). A cell in the stacks that needs to know who a token is has made a design error, and the paths table has no row for it.

The office reads the stacks and the desk reads nothing from the office. The lobby reaches only the desk.
