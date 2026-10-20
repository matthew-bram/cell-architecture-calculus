# Enterprise domain model, the town's services

From the town's IT office, Sep 2026. The domains and subdomains every service the town runs places its capabilities in. A service's own names stay its own; this model is where they are placed, not what they are called.

| Domain | Subdomain | Kind | What belongs here |
| --- | --- | --- | --- |
| Lending | Lending | core | Loans and the queue waiting on a copy: check out, check in, renew, the limit, holds placed and cancelled |
| Lending | Hold shelf | core | A copy ready for pickup when it has come in and a hold is waiting |
| Lending | Fines | core | What is owed, assessed from the loan record and the calendar, settled or written off |
| Lending | Renewals | core | Proposals to renew, through the ladder |
| Lending | Recommendations | core | What the member might read next, from what they have read |
| Lending | Renewal proposals | core | Proposing a renewal before the due day when no hold is waiting |
| Collection | Catalog | supporting | Items and their copies, each copy's status; the consortium's items in transit |
| Members | Membership | supporting | Members, cards, roles, the alias map, the session |
| Member relations | Notices | core | What a member hears: the welcome, the limit warning, the hold ready, the reminder, the fine, the receipt |
| Running the library | Reports | supporting | Counts by branch and month |
| Running the library | Operations | supporting | The staff console, the rungs, the write-offs, the kill switch |

Placement is by what a capability owns, not by who builds it. A capability that owns two subdomains' things is a question for the service, not a split made here.
