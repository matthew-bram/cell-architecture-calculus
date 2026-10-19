import CellCalculus.Architecture
import CellCalculus.Cell
import CellCalculus.Journey
import CellCalculus.Contract
import CellCalculus.Envelope
import CellCalculus.Inputs
import CellCalculus.Boundaries
import CellCalculus.Policy
import CellCalculus.Promise
import CellCalculus.Wire
import CellCalculus.Coverage
import CellCalculus.Gherkin
import CellCalculus.Render
import CellCalculus.Replay
import CellCalculus.ContextMap
import CellCalculus.Governance
/-!
# The cell calculus

The generic shapes of the method, with their theorems, and nothing that
belongs to one project. A project supplies one type, its principal, through
the `Architecture` class, says what its events are about by the subject
type it puts on its envelopes, and builds its cells, journeys, examples and
promises from what is here.

One module per idea, in the order a reader should meet them:

- `Cell`: a cell as three pure functions and a fold; the example as a type;
  trace conformance.
- `Journey`: journeys as terms that compile to a directed acyclic graph;
  operational delivery.
- `Contract`: a step's non-functional guarantees and how they fold along
  a journey: latency as sum and max, budgets and cost as sums.
- `Envelope`: what every command and event carries besides its payload; the
  actor gate; the per-run causation check.
- `Inputs`: query answers and the clock as arguments a decider never fetches.
- `Boundaries`, opt-in: identifiers indexed by a trust boundary; the alias
  map; the scrub as a parse. A project without boundaries never imports it.
- `Policy`: the one place a fact may become a command.
- `Promise`: service promises as predicates over runs, and attributes that
  name what they quantify over: one run, a pair, a population, a
  distribution, or the artifact.
- `Wire`, `Coverage`, `Gherkin`: the three classes a project's types
  implement so that fixtures, coverage and readable scenarios are generic.
- `Render`: the generators over those instances; a project's fixtures
  executable is a list of registered cells and one call.
- `Replay`: the trace checker over the same instances and `JsonDecode`,
  with the first rejected step proved to be `conforms`'s negation; a
  project's replay executable is a list of registered cells and runs and
  one call.
- `Governance`: the review lines, one per design, and supersession; the
  governed example, for commands and for reactions.
- `ContextMap`: the subdomain kinds, the upstream and downstream patterns
  and the relationships of a context map, with coverage of every arrow
  as the one computation and its monotonicity as the theorem.

**Version 2, Oct 14, 2026; 2.1 on Oct 15** with `ProjectHeader` superseding
`ModelHeader` and `GovernedReactionExample` beside `GovernedExample`, both
found by the skills' evaluations; **2.2 the same day** adds `Replay`, the
trace checker, and `JsonDecode`, nothing changed; **2.3** adds `ContextMap`. Version 1 was frozen the same morning with one
consumer; the second pass took the consumer's zones, roles and
identifiers out of the generic shapes, so a change of version rather than a
set of deprecated aliases that would have kept them. The skill and the style
guide are written against this API. A change to a public shape is governed by
supersession, never by edit: the old name stays, deprecated, and names its
successor (see `Governance`).

Every theorem here is universal: it holds for every cell, every policy,
every command. Theorems that are computations on one project's values,
discharged by `decide`, live in that project.
-/
