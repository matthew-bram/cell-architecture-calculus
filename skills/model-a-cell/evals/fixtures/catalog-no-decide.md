# The catalog keeps the copies

Annotated design for the catalog cell. Incomplete on purpose: it has Commands and Examples but no Decide table.

**Purpose.** The catalog keeps the items and their copies, and each copy's status: on the shelf, on loan, on the hold shelf, or in transit from the consortium.

### Commands

| id | name | sender | fields | refusals |
| --- | --- | --- | --- | --- |
| addCopy | add a copy of an item | a librarian | item : String, copy : String | |
| withdrawCopy | withdraw a copy from the collection | a librarian | copy : String | copyOnLoan |

### Subscribes

| event | from cell |
| --- | --- |
| checkedOut | circulation |
| checkedIn | circulation |

### Publishes

| id | name | fields |
| --- | --- | --- |
| copyAdded | a copy was added | item : String, copy : String |
| copyWithdrawn | a copy was withdrawn | copy : String |
| copyStatusChanged | a copy's status changed | copy : String, status : onShelf, onLoan, onHoldShelf or inTransit |

### State

| field | type | invariant |
| --- | --- | --- |
| copies | List (String × String) | the copies and the item each is a copy of |
| status | List (String × Status) | one status per copy the catalog knows |

### Terminal

Never.

### Examples

| id | given | with | when | expect |
| --- | --- | --- | --- | --- |
| CATALOG-ADD-1 | nothing | | addCopy "i-1" "b-1" | ok: copyAdded "i-1" "b-1" |
| CATALOG-WITHDRAW-1 | copyAdded "i-1" "b-1" | | withdrawCopy "b-1" | ok: copyWithdrawn "b-1" |
| CATALOG-WITHDRAW-2 (on loan) | copyAdded "i-1" "b-1"; copyStatusChanged "b-1" onLoan | | withdrawCopy "b-1" | refused: copyOnLoan |

### Attributes

| name | scope | subject | promise | threshold |
| --- | --- | --- | --- | --- |
| a copy's status follows the loan within a short while | oneRun | | withinDuration isCheckedOut isStatusChanged | |
