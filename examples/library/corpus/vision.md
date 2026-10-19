# The circulation system: vision

The design corpus of the worked example, part one of three · the other two are [capability-map.md](capability-map.md) and [architecture.md](architecture.md)

A town's public library lends items to its members: books, films, tools, a telescope. The circulation system is what keeps the loans: who has what, when it is due, what is waiting on the hold shelf, what is owed. It runs at the desk, in the self-service terminals, and in the members' app.

What makes it worth modelling is not the arithmetic. It is that a reading record is private, that a loan must be booked exactly once however many times a flaky terminal retries, and that a dozen journeys, from joining to leaving, pass through the same handful of capabilities and must agree on what each one does.

## Principles

1. **A reading record is private.** The stacks know a member by a patron token and never by name, card number or contact. Nothing in the stacks can say who borrowed what; only the desk can, and only for the member it serves.
2. **Identity flows toward the member, never toward the stacks.** The desk resolves a card to its token on the way in and puts the name back on the way out. The stacks never ask the desk who a token is.
3. **Every capability is built once and composed by the journeys.** A journey names the capabilities it uses and the earlier journeys it reuses, instead of describing them again.
4. **A loan is booked once.** The same request seen twice, from a retry, a double scan or a dropped connection, is one loan, not two.
5. **Quiet unless it matters.** The member hears when a card is at its limit, when a hold is ready, when an item runs late. Nothing else.
6. **A fine is calculated, never estimated.** Every amount a member sees comes from the loan record and the calendar.
7. **A member can leave with nothing left behind.** Closing a card ends its loans, settles what is owed, and deletes the member's record.

## Trust zones

| Zone | Holds | Does | Never |
| --- | --- | --- | --- |
| The desk | Members' names, contact details and card numbers; the alias map from each card to its patron token | Issues cards; resolves a card to its token on every request; puts the name back on every notice before it goes out | Holds a loan record |
| The stacks | Loans, holds, fines and renewals, keyed by patron token; the catalog | Runs circulation, one patron at a time | Sees a name, a contact detail or a card number; asks the desk who a token is ([principle 2](#principles)) |
| The office | Counts, reports and the staff console; the rung every automation runs at | Runs the library | Sees a member's loans by name |
| The lobby | The desk terminals, the self-service kiosks and the members' app: fronts over the desk, with no record of their own | Signs members in; shows and collects | Holds anything after the session ends |
| Outside | The consortium's interlibrary loan service, the message provider, the payment provider, the town's identity provider | Answers the one call each is made for | Sees more than that call carries |

**Coming in.** A terminal signs the member in through the town's identity provider and the desk opens a session. Every request the member makes carries the card; the desk swaps the card for the patron token and passes the request to the stacks.

**Going out.** The stacks write facts about tokens. The desk collects the ones a member should hear, puts the name and the contact back, and sends the notice.

| Stage | What it looks like |
| --- | --- |
| At the desk | Card C-1041, Ana Souza, ana@example.org |
| What the stacks see | Patron P-7 checked out copy b-5, five on loan |
| What the stacks write | Patron P-7 is at the limit |
| What the member reads | Ana, that was your fifth item; return one before borrowing another |

## The journey map

**Foundation**

0. Sign in, at a terminal or in the app. Every other journey starts from here.

**Joining**

1. Join: apply for a card and get it.

**Everyday**

2. Borrow an item.
3. Return an item.
4. Hold an item and pick it up.

**When things run late**

5. An item runs late: the reminder, the fine, the payment.
6. Renew, by hand or on the library's proposal.

**Leaving**

7. Leave: close the card and delete the record.

Each journey section carries two tables beside its prose: the steps, each with the cells it names, the earlier steps it waits on, the fact that moves the journey on and any outside party it calls; and the references to other journeys, each marked composition, succession or pointer. The map is transcribed from the tables; the prose stays the author's.

## Journey 0: sign in

The member signs in at a terminal, a kiosk or the app, through the town's identity provider, and the desk opens a session on the card. Every other journey starts here and names this one.

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The member signs in | membership, terminals | | session opened | the identity provider |

| journey | kind | at step |
| --- | --- | --- |
| none | | |

## Journey 1: join

A resident applies at the desk or in the app. The desk issues the card, mints the patron token the stacks will know them by, and welcomes them.

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The resident applies and the card is issued | membership | | card issued | |
| 1 | The welcome goes out | notices | 0 | notice sent | the message provider |

| journey | kind | at step |
| --- | --- | --- |
| 0 | composition | 0 |

## Journey 2: borrow an item

The everyday loop. The member presents the card and the item, or scans both at a kiosk. The desk resolves the card, circulation books the loan, the catalog marks the copy out, and the member hears about it only if it matters ([principle 5](#principles)).

### Steps

1. **The card is presented.** The desk resolves it to the patron token. A guest card, which may use the reading room and not borrow, stops here.
2. **The item is checked out.** The loan is booked once, whatever the terminal retried ([principle 4](#principles)). A card holds at most five items; the sixth is refused. A closed card takes no new loans.
3. **The copy is marked on loan** in the catalog, so the next search says so.
4. **The limit warning,** if this was the fifth item: a notice that one more will be refused.
5. **The receipt reaches the member,** on the terminal or in the app.

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The card is presented | membership | | card resolved | |
| 1 | The item is checked out | circulation | 0 | checked out | |
| 2 | The copy is marked on loan | catalog | 1 | copy status changed | |
| 3 | The limit warning, if the card is at its limit | notices | 1 | notice sent | the message provider |
| 4 | The receipt reaches the member | notices, terminals | 2, 3 | | |

### What it references

| journey | kind | at step |
| --- | --- | --- |
| 0 | composition | 0 |
| 3 | succession | |
| 5 | succession | |
| 6 | pointer | |

Signing in runs as the first step. A loan ends in a return, journey 3, or runs late, journey 5; each starts as a new run when this one's last fact is in. Renewal is journey 6's and is only pointed at here.

### Moments that matter

- **Trust.** The same item never shows twice on a card, and a refused checkout says why in one line.
- **Noise.** One notice at the limit, none before it.
- **Speed at the desk.** A queue forms behind a slow checkout; the receipt is on the terminal before the member has pocketed the card.

## Journey 3: return an item

The item is scanned at the desk or dropped in the return slot. Circulation records the return, the catalog marks the copy on the shelf, and if the copy came back late, the fine is assessed and the member hears.

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The item is checked in | circulation | | checked in | |
| 1 | The copy is marked on the shelf | catalog | 0 | copy status changed | |
| 2 | A late return is assessed | fines | 0 | fine assessed | |
| 3 | The member hears, if there is a fine | notices | 2 | notice sent | the message provider |

| journey | kind | at step |
| --- | --- | --- |
| 4 | succession | |
| 5 | pointer | |

If a hold is waiting on the copy, journey 4 picks it up from the return. The fine's reminder and payment are journey 5's.

## Journey 4: hold an item and pick it up

The member places a hold on a copy that is out. When the copy comes in, it goes to the hold shelf, the member hears, and picking it up is a checkout as in journey 2.

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The member places the hold | holds | | hold placed | |
| 1 | The copy comes in and is ready | pickup | 0 | ready for pickup | |
| 2 | The member hears | notices | 1 | notice sent | the message provider |
| 3 | The member picks it up at the desk | membership, circulation | 2 | checked out | |

| journey | kind | at step |
| --- | --- | --- |
| 0 | composition | 0 |
| 2 | composition | 3 |
| 3 | pointer | |
| 5 | succession | |

Step 1 waits on two facts that arrive in either order: the hold placed here and the copy checked in by a run of journey 3. Pickup remembers whichever came first. A picked-up item can run late, journey 5.

## Journey 5: an item runs late

The day before an item is due, the member is reminded. Each day after the due day the fine grows, calculated from the loan record and the calendar ([principle 6](#principles)). The member pays in the app or at the desk.

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The reminder goes out the day before | fines, notices | | notice sent | the message provider |
| 1 | The fine is assessed after the due day | fines | 0 | fine assessed | |
| 2 | The member pays | fines | 1 | fine settled | the payment provider |
| 3 | The receipt goes out | notices | 2 | notice sent | the message provider |

| journey | kind | at step |
| --- | --- | --- |
| 3 | succession | |
| 6 | pointer | |

The item comes back by journey 3, as a new run. Renewing instead is journey 6.

## Journey 6: renew

The member asks to renew, or the library proposes it: the day before an item is due, if no hold is waiting on it, the reading assistant proposes a renewal. What happens to the proposal depends on the rung the office has set: in shadow it is recorded and nothing is issued; in review it is held until the member approves; autonomous, it is issued. Circulation renews the loan.

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The member asks, or the assistant proposes | assistant, renewals | | renewal issued | |
| 1 | The loan is renewed | circulation | 0 | renewed | |
| 2 | The member hears | notices | 1 | notice sent | the message provider |

| journey | kind | at step |
| --- | --- | --- |
| 2 | pointer | |
| 5 | succession | |

## Journey 7: leave

The member asks to leave. The card is closed, which refuses new loans and waits for the items out to come back; what is owed is settled or written off; then the member's record, the alias map entry with it, is deleted ([principle 7](#principles)).

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The member asks to leave | membership | | leaving requested | |
| 1 | The card is closed | circulation | 0 | card closed | |
| 2 | What is owed is settled or written off | fines | 0 | fine settled | |
| 3 | The record is deleted | membership | 1, 2 | record deleted | |

| journey | kind | at step |
| --- | --- | --- |
| 0 | composition | 0 |
| 3 | pointer | |
