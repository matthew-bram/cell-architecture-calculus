# The journey map, as checked: the library's eight journeys

Golden answer · from the three corpus documents of the worked example, `../../examples/library/corpus/vision.md`, `capability-map.md` and `architecture.md` · its Lean is `../../examples/library/JourneyMap.lean`, the map as it stands in the example project

**What this document is.** The map the method starts from: the cells with their zones, every journey as a DAG of steps each labelled with the cells it names, the arrows between cells as rows of the paths table, and the checks the Lean makes of them. Every row is the corpus's; every check is a theorem in the Lean; what the corpus does not say is a gap at the end.

**The owner's domains.** Asked; the owner named no enterprise domain or subdomain source outside the corpus, so the cells table has no domain columns and the names are the capability map's alone.

## The cells

From the capability map's list, one constructor per capability, and the technology architecture's "cells by zone" table for the zone. Platform capabilities are in every journey and left out of the matrix rows. The terminals are channel applications with a zone and no cell of their own; telemetry is a plane, not a cell.

| cell | capability map's name | zone | platform |
| --- | --- | --- | --- |
| membership | Membership | desk | |
| notices | Notices | desk | |
| catalog | Catalog | stacks | |
| circulation | Circulation | stacks | |
| holds | Holds | stacks | |
| pickup | Pickup | stacks | |
| fines | Fines | stacks | |
| renewals | Renewals | stacks | |
| assistant | The reading assistant | stacks | |
| reports | Reports | office | |
| operations | Operations | office | |
| terminals | The terminals | lobby | platform |
| telemetry | Telemetry | fabric | platform |

## The journeys

One table per journey, transcribed row for row from the Steps table of its section in the vision, and its References table beneath. A step waits only on earlier steps; the Lean's `wellFormed` is the check.

### Journey 0: sign in

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The member signs in | membership, terminals | | session opened | the identity provider |

References: none.

### Journey 1: join

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The resident applies and the card is issued | membership | | card issued | |
| 1 | The welcome goes out | notices | 0 | notice sent | the message provider |

References: 0, composition, at step 0.

### Journey 2: borrow an item

Step 1 fans out to the catalog and to notices; step 4 fans back in.

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The card is presented | membership | | card resolved | |
| 1 | The item is checked out | circulation | 0 | checked out | |
| 2 | The copy is marked on loan | catalog | 1 | copy status changed | |
| 3 | The limit warning, if the card is at its limit | notices | 1 | notice sent | the message provider |
| 4 | The receipt reaches the member | notices, terminals | 2, 3 | | |

References: 0, composition, at step 0; 3, succession; 5, succession; 6, pointer.

### Journey 3: return an item

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The item is checked in | circulation | | checked in | |
| 1 | The copy is marked on the shelf | catalog | 0 | copy status changed | |
| 2 | A late return is assessed | fines | 0 | fine assessed | |
| 3 | The member hears, if there is a fine | notices | 2 | notice sent | the message provider |

References: 4, succession; 5, pointer.

### Journey 4: hold an item and pick it up

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The member places the hold | holds | | hold placed | |
| 1 | The copy comes in and is ready | pickup | 0 | ready for pickup | |
| 2 | The member hears | notices | 1 | notice sent | the message provider |
| 3 | The member picks it up at the desk | membership, circulation | 2 | checked out | |

References: 0, composition, at step 0; 2, composition, at step 3; 3, pointer; 5, succession.

### Journey 5: an item runs late

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The reminder goes out the day before | fines, notices | | notice sent | the message provider |
| 1 | The fine is assessed after the due day | fines | 0 | fine assessed | |
| 2 | The member pays | fines | 1 | fine settled | the payment provider |
| 3 | The receipt goes out | notices | 2 | notice sent | the message provider |

References: 3, succession; 6, pointer.

### Journey 6: renew

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The member asks, or the assistant proposes | assistant, renewals | | renewal issued | |
| 1 | The loan is renewed | circulation | 0 | renewed | |
| 2 | The member hears | notices | 1 | notice sent | the message provider |

References: 2, pointer; 5, succession.

### Journey 7: leave

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The member asks to leave | membership | | leaving requested | |
| 1 | The card is closed | circulation | 0 | card closed | |
| 2 | What is owed is settled or written off | fines | 0 | fine settled | |
| 3 | The record is deleted | membership | 1, 2 | record deleted | |

References: 0, composition, at step 0; 3, pointer.

## The journey matrix

From the capability map, by hand; checked against each journey's table by theorem, platform cells aside.

| journey | capabilities |
| --- | --- |
| 0 | membership |
| 1 | membership, notices |
| 2 | membership, circulation, catalog, notices |
| 3 | circulation, catalog, fines, notices |
| 4 | holds, pickup, notices, membership, circulation |
| 5 | fines, notices |
| 6 | assistant, renewals, circulation, notices |
| 7 | membership, circulation, fines |

## The paths

From the technology architecture's three paths tables: sessions and control, commands and queries through a gateway, facts on the fabric. The rule the architecture states: the stacks never ask the desk, which is no query and no command from a cell in the stacks toward a cell at the desk. The partner calls are a fourth table in the architecture and are not rows of the Lean's `paths` list; see gap 4.

| from | to | kind |
| --- | --- | --- |
| terminals | membership | session |
| operations | renewals | control |
| operations | membership | control |
| membership | circulation | command |
| renewals | circulation | command |
| holds | circulation | query |
| fines | circulation | query |
| reports | catalog | query |
| reports | circulation | query |
| membership | circulation | event |
| circulation | catalog | event |
| circulation | notices | event |
| circulation | pickup | event |
| circulation | fines | event |
| holds | pickup | event |
| pickup | notices | event |
| fines | notices | event |
| renewals | notices | event |

## The checks, as theorems

| claim | theorem | outcome |
| --- | --- | --- |
| Each journey's steps form a DAG: every step waits only on earlier steps | `signIn_isDag`, `join_isDag`, `borrowAnItem_isDag`, `returnAnItem_isDag`, `holdAndPickUp_isDag`, `runsLate_isDag`, `renew_isDag`, `leave_isDag` | holds, all eight |
| The capability map's matrix row names the same cells the journey's table names, platform cells aside | `matrixRow0_matchesJourney` to `matrixRow7_matchesJourney` | holds, all eight |
| The map's claim that the terminals are in every journey a member starts, checked step by step for journey 2 | `journey2_passesThroughTerminals` | holds |
| A DAG of steps runs as a left fold: journey 2 touches membership, circulation, catalog, notices, notices, terminals in that order | `borrowAnItem_touches` | holds |
| Composition between journeys is acyclic | `composition_isAcyclic` | holds |
| Succession cycles: a return readies a hold, a pickup can run late, a late item is returned | `succession_cycles` | holds, by design: each edge is a new fact starting a new run |
| Read with the kind column dropped, the references cycle | `referencesWithoutKinds_cycle` | holds, which is why the kind column is required |
| Journey 2 as a pipeline in `Except` runs to its outcome: the fifth item warns, the first is quiet, a guest stops at the desk, the sixth is refused | `journey2_warns`, `journey2_quiet`, `journey2_guestStops`, `journey2_sixthRefused` | holds, all four, by `rfl` |
| No query and no command opens from the stacks toward the desk | `stacks_never_ask_the_desk` | holds |
| A query from circulation to membership, added to the table, would break the rule | `badPath_breaksTheRule` | holds: the check bites |
| Cells form a cyclic graph, circulation and fines each way; the acyclic thing is each journey, and the direction rule is on the zones | `cellGraph_hasCycle` | holds, by design |

## Gaps

Every arrow a journey's waits-on column implies, from the cells of the step waited on to the cells of the step waiting, was looked for in the paths table. Where the fact that moves the journey on reaches a cell the table has no row for, it is listed here for the owner; nothing was added to the table.

1. **Journey 1, step 1.** Notices waits on membership's "card issued". The paths table has no row from membership to notices; the facts-on-the-fabric table lists membership's facts as reaching circulation only.
2. **Journey 2, step 4.** Notices waits on the catalog's "copy status changed", and the table has no row from catalog to notices. The receipt reaches the terminals, and the only row touching the terminals is the session into membership, whose "back: what the member may see" is the reading here.
3. **Journey 4, step 3.** Membership and circulation wait on notices' "notice sent". The table has no row from notices to either; the member acting on the notice is a person, not an arrow, and the corpus should say so or add the row.
4. **Journey 6, step 0.** The assistant and renewals share the step, and the architecture says the assistant's proposals reach circulation only through renewals. The paths table has no row from assistant to renewals; the lift from the assistant's fact to renewals' proposal is the one succession the architecture describes in prose and nowhere in a table.
5. **Journey 7, steps 2 and 3.** Fines waits on membership's "leaving requested", and membership waits on circulation's "card closed" and fines' "fine settled". The table has no row from membership to fines, from circulation to membership or from fines to membership. The last two are facts flowing from the stacks to the desk, which the direction rule allows for facts, but the table does not list them.
6. **The partner calls.** The architecture's partner-calls table, membership to the identity provider, notices to the message provider, fines to the payment provider, catalog to the consortium, is not transcribed into the Lean's `paths` list, so the direction rule is not checked over it and the context map's coverage theorem does not read it. The journeys name the partners on their steps as the vision does.
7. **Platform capabilities on steps.** The capability map says the terminals and telemetry are in every journey. The terminals are named on journey 0's step and journey 2's last step and nowhere else; telemetry is named on no step. The theorem checks the claim for journey 2 only.
8. **Journey 2, step 0.** Membership publishes "card resolved", which the facts-on-the-fabric table does not list; the arrow to circulation is read as the command row, "on the member's behalf, with the token in place of the card".
