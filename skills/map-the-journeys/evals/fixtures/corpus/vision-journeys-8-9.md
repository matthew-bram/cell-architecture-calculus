# The circulation system: vision, two journeys added

An excerpt in the form of the worked example's vision, `examples/library/corpus/vision.md`: two journey sections the town adds when it joins the consortium's interlibrary loan service. Each carries its two tables beside its prose, as the vision's other sections do.

**Beyond the town**

8. Request an item from the consortium.
9. Return a consortium item.

## Journey 8: request an item from the consortium

The member asks for an item the town does not hold. The catalog asks the consortium for it, a hold is placed for the member, and when the copy arrives in transit and is received it goes to the hold shelf as any held copy does. The member hears, and picks it up at the desk as in journey 4. When the member is done with it, it goes back to the consortium, journey 9.

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The member asks for an item the town does not hold | catalog | | request sent | the consortium |
| 1 | The copy arrives in transit and is received | catalog | 0 | copy status changed | |
| 2 | A hold is placed for the member | holds | 0 | hold placed | |
| 3 | The copy is ready | pickup | 1, 2 | ready for pickup | |
| 4 | The member hears | notices | 3 | notice sent | the message provider |

| journey | kind | at step |
| --- | --- | --- |
| 0 | composition | 0 |
| 9 | composition | |
| 4 | pointer | |

Step 3 waits on two facts that arrive in either order: the copy received by the catalog and the hold placed. Picking the copy up is journey 4's and is only pointed at here.

## Journey 9: return a consortium item

The copy is checked in as any copy is, then the catalog sends it back to the consortium, and the member hears that it is on its way. A further request is journey 8.

| # | step | cells | waits on | publishes | partner |
| --- | --- | --- | --- | --- | --- |
| 0 | The item is checked in | circulation | | checked in | |
| 1 | The copy is sent back | catalog | 0 | copy status changed | the consortium |
| 2 | The member hears | notices | 1 | notice sent | the message provider |

| journey | kind | at step |
| --- | --- | --- |
| 8 | composition | |
| 3 | pointer | |

The check-in itself is journey 3's and is only pointed at here.
