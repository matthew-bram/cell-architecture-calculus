# The context map, as checked: the library's cells

Golden answer · from the three corpus documents of the worked example, `../../examples/library/corpus/vision.md`, `capability-map.md` and `architecture.md`, and the journey map beside it, `../../examples/library/JourneyMap.lean` · its Lean is `../../examples/library/ContextMap.lean`, the map as it stands in the example project

**What this document is.** The context map the method takes beside the journey map: each cell's bounded context with the subdomain kind it serves, and for every arrow between two contexts the relationship, upstream to downstream, in the DDD vocabulary the calculus fixes. Every row is the corpus's; every check is a theorem in the Lean; what the corpus does not say is a gap at the end.

**The owner's domains.** Asked; the owner named no enterprise domain or subdomain source outside the corpus, so the domain and subdomain columns read "no source named" and the kinds are the capability map's alone.

## The contexts

Each cell is a bounded context, as the technology architecture reads them: "each capability on the map is one cell, and each cell is one bounded context". The terminals, the kiosks and the app are channel applications "with no record and no bounded context of their own"; telemetry "is a plane every cell emits to, not a cell". The four outside parties of the partner-calls table are contexts too, marked external. Kinds from the capability map's "Core, supporting and generic" table; an outside party has none and reads as generic.

| context | capability map's name | kind | external | domain | subdomain |
| --- | --- | --- | --- | --- | --- |
| membership | Membership | supporting | | no source named | no source named |
| notices | Notices | generic | | no source named | no source named |
| catalog | Catalog | supporting | | no source named | no source named |
| circulation | Circulation | core | | no source named | no source named |
| holds | Holds | core | | no source named | no source named |
| pickup | Pickup | core | | no source named | no source named |
| fines | Fines | core | | no source named | no source named |
| renewals | Renewals | core | | no source named | no source named |
| assistant | The reading assistant | core | | no source named | no source named |
| reports | Reports | supporting | | no source named | no source named |
| operations | Operations | supporting | | no source named | no source named |
| identityProvider | the town's identity provider | generic, by reading | external | | |
| messageProvider | the message provider | generic, by reading | external | | |
| paymentProvider | the payment provider | generic, by reading | external | | |
| consortium | the consortium's interlibrary loan service | generic, by reading | external | | |

## The relationships

One per pair of contexts an arrow joins, in the direction the kind of path gives: a fact's publisher is upstream of every reactor; a gateway's owner is upstream of every cell that queries, commands or controls it; an outside party is upstream of the cell that calls it. In the tables' order: the gateway rows, then the facts on the fabric, then the partner calls.

**Commands, queries and control through a gateway.** The owner offers an open host service, since "each design lists what its gateway offers and what facts it publishes"; the caller is a customer, commanding "through the owner's gateway, in the owner's terms".

| upstream | downstream | offers | takes | from |
| --- | --- | --- | --- | --- |
| circulation | membership | openHostService | customer | "Membership → Circulation, command: check out, check in, renew, on the member's behalf" |
| circulation | renewals | openHostService | customer | "Renewals → Circulation, command: renew, when a proposal is issued" |
| circulation | holds | openHostService | customer | "Holds → Circulation, query: whether a copy is on loan" |
| circulation | fines | openHostService | customer | "Fines → Circulation, query: whether an item is still out" |
| catalog | reports | openHostService | customer | "Reports → Catalog, query: copies by status" |
| circulation | reports | openHostService | customer | "Reports → Circulation, query: loans and overdue counts by token" |
| renewals | operations | openHostService | customer | "Operations → Renewals, control: the rung" |
| membership | operations | openHostService | customer | "Operations → Membership, control: a write-off, a card closed by staff" |

**Facts on the fabric.** The publisher's facts go out "on the fabric in the event schema", a published language. The architecture decides conformist against anti-corruption layer in one sentence: "a reactor that keeps the fact's shape conforms to it; one that keeps its own projection in a different shape, or puts a name back, translates at its edge". Notices puts the name back, so every fact reaching notices is translated.

| upstream | downstream | offers | takes | from |
| --- | --- | --- | --- | --- |
| membership | circulation | publishedLanguage | conformist | "Membership → Circulation: card issued, with its token; card closed" |
| circulation | catalog | publishedLanguage | conformist | "Circulation → Catalog: checked out; checked in" |
| circulation | notices | publishedLanguage | anticorruptionLayer | "Circulation → Notices: checked out, with how many are on loan; renewed; card closed"; the name put back |
| circulation | pickup | publishedLanguage | conformist | "Circulation → Pickup: checked in" |
| circulation | fines | publishedLanguage | conformist | "Circulation → Fines: checked out; checked in" |
| holds | pickup | publishedLanguage | conformist | "Holds → Pickup: hold placed" |
| pickup | notices | publishedLanguage | anticorruptionLayer | "Pickup → Notices: ready for pickup"; the name put back |
| fines | notices | publishedLanguage | anticorruptionLayer | "Fines → Notices: fine assessed; fine settled"; the name put back |
| renewals | notices | publishedLanguage | anticorruptionLayer | "Renewals → Notices: renewal held, for the member to approve"; the name put back |

**Partner calls.** The outside party is upstream with no stated protocol, a supplier; the cell translates at its edge, an anti-corruption layer, since every row of the partner-calls table says what the call carries and never carries.

| upstream | downstream | offers | takes | from |
| --- | --- | --- | --- | --- |
| identityProvider | membership | supplier | anticorruptionLayer | "the sign-in; back: the provider's immutable ID; never a loan" |
| messageProvider | notices | supplier | anticorruptionLayer | "the notice with the name put back, the contact; never a token" |
| paymentProvider | fines | supplier | anticorruptionLayer | "the amount and a payment reference; back: paid or not; never a name with a token beside it" |
| consortium | catalog | supplier | anticorruptionLayer | "a request for an item the town does not hold; back: its copy in transit; never a member" |

## The checks, as theorems

| claim | theorem | outcome |
| --- | --- | --- |
| Every arrow of the journey map's paths table whose both ends are contexts is accounted for by a relationship in the right direction | `arrows_covered` | holds, over seventeen arrows; the session from the terminals drops out, having no context at its source |
| Every relationship whose upstream is outside the system translates at the edge | `partners_translate` | holds, for the four outside parties |
| The heuristic that a core context should not conform to a generic one, read off the map as the list of places it is broken | `coreConformingToGeneric_isEmpty` | holds: the list is empty, since the one generic context, notices, is upstream of nobody, and every outside party is translated at the edge |
| No two contexts are declared separate ways | `noSeparateWays` | holds |

## The heuristics

The corpus states no DDD heuristic, so each is a finding and not a rule. A core context conforming to a generic one: nowhere, by the theorem. A supporting context upstream of a core one: membership is upstream of circulation on the fabric, and circulation conforms to its facts; the corpus says membership's facts are the card and its token, which circulation needs as published. Nothing to resolve.

## Gaps

1. **The session from the terminals.** The terminals have no bounded context, so the session row of the paths table, terminals to membership, is no arrow of this map and is not covered by `arrows_covered`. The architecture says what it carries; whether the lobby's channel applications should be a context of their own, a customer of membership's open host service, is the owner's call.
2. **The partner calls are not in the journey map's paths list.** The four partner relationships are read from the architecture's partner-calls table, and `partners_translate` checks them, but the journey map's `paths` has no partner rows, so `arrows_covered` does not read them. When the paths list gains the partner rows, the coverage theorem covers them too.
3. **The owner named no enterprise domain or subdomain source**, so the map has no domain columns filled. When one is named, each context gains its domain and subdomain, and a name that disagrees with the capability map's is a gap.
4. **Reports.** Reports is a customer of circulation and the catalog through queries and "never joins a token to a name"; whether it keeps a projection of its own, which would make it an anti-corruption layer on a fact relationship the paths table does not list, is for the reports design.
5. **The operations control requests.** Operations controls renewals and membership through their gateways and is read as a customer of each; the architecture's "writes only to control queues" could also be read as a published language from operations downward. The reading here follows the paths table's direction, from operations to the owner's gateway.
6. **Each design adds rows.** The map's relationships are the architecture's; each design adds its own facts and gateway rows, and each adds a relationship here or confirms one. The circulation design's Wire table takes its parse property from the circulation–membership row: a customer, so the parse is the identity up to shape.
