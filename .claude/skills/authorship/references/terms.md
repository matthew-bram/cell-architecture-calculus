# Terms

The repository's terms of art, each with the one definition the documents give it. Voice rules 3 and 8 say a term is defined once and used one way everywhere. This sheet is how that holds across pages rewritten in different sessions.

- **Read it at step 1** of every rewrite, beside `voice.md`.
- **Use each term as defined here.** Don't swap in a word from the "Not" column.
- **Add what a page settles.** When a rewrite defines a term or settles a wording, add its row in the same change, naming the page.
- **Report a term used two ways.** Add it under [Open questions](#open-questions) and ask the owner. Never pick one sense silently.
- **Dated records are exempt.** A research note or a problem statement keeps the vocabulary of its day, by [details.md](details.md#dated-records).

## The terms

| Term | The one definition | Defined in | Not |
| --- | --- | --- | --- |
| **cell** | A self-contained unit with its own record and a gateway as the only way in, in the sense of the WSO2 cell-based reference architecture | `README.md` | service, component, module |
| what is inside a cell | An initial state; three pure functions, one of which is the fold; a terminal predicate | `README.md` | "three pure functions" alone; the fold counted beside the three |
| the fold | `evolve`, one of the cell's three pure functions | `README.md` | reducer, apply |
| **principal** | Who a person or system is when they act | `README.md` | user, actor, identity |
| **subject** | What an event is about, bounded by a trust zone where you have one | `README.md` | |
| example | A row in a design, a value in the model and a test in the code, under one id | `README.md` | |
| id | What an example's theorem in the model and its test in the code share: each example is both "under one id" | `README.md` | identifier, key |
| journey | A term across cells that compiles to a directed acyclic graph | `README.md` | |
| **proved** | A universal theorem, true for every cell, every history, every command, checked by the Lean kernel | `README.md` | |
| **checked** | A decidable claim about one project's values, such as "this journey has no loops", computed by the kernel | `README.md` | |
| **tested** | The code against the model, through the generated fixtures and the replayed traces | `README.md` | |
| **assumed** | The world outside the model, and whether the model means what the design's prose intended | `README.md` | |
| skill | A procedure with its acceptance test at every stage, the rule of what it never does, and the report it ends with | `README.md` | |
| design | Prose where the meaning is, and the fixed tables of style guide section 8 where the model is transcribed from. The design owns meaning | `docs/getting-started.md` | spec |
| lifecycle step | One of the lifecycle's nine steps, cited by number and named as the page names it: 1 Draw the design corpus; 2 Map, annotate, then transcribe the shape; 3 Decide the data; 4 Add the data to the model; 5 Generate; 6 Validate the specs; 7 Build against the specs; 8 Replay the traces; 9 Change it | `docs/the-lifecycle.md` | stage, which is the round trip's |
| the hard gate | Lifecycle step 6, Validate the specs: a person checks the model against the design, which no kernel can do, and signs the review line | `docs/the-lifecycle.md` | |
| stage of the round trip | One of the round trip's six stages, cited by number, each with its input, artifact, direction and acceptance test: 1 The cell's I/O; 2 The type-level model; 3 The data model; 4 Specification by example; 5 The code; 6 The traces | `docs/the-lifecycle.md` | step, which is the lifecycle's |
| the guide's steps | The numbered sections of the getting-started guide, 0 to 12. "The twelve steps" are 1 to 12; section 0 is what to do before you start | `docs/getting-started.md` | |
| fixture | The JSON rendering of an example in the wire shape, one per example, serialized by the model's own serializer and stamped with the model's hash. The tests consume the fixtures by example id | `docs/the-lifecycle.md` step 5, `docs/getting-started.md` step 8 | test data, test vector |
| feature file | The Given, When, Then of every example, rendered from the model as Gherkin for reviewers and stamped with the model's hash | `docs/the-lifecycle.md` step 5, `docs/getting-started.md` step 8 | scenario file |
| view | A rendering generated from the model, stamped with the model's hash and never edited by hand. Views own nothing, and a view without a stamp is not a view. The two built are the feature file and the JSON fixtures | `docs/the-lifecycle.md`, `docs/getting-started.md` step 8, `examples/library/README.md` | |
| stamp | The model's hash, which every rendering carries and the test suite asserts | `docs/the-lifecycle.md`, `docs/getting-started.md` | |
| trace | What running code did, in test or in production, recorded in the wire shape: each command the code was handed and the outcome it produced | `docs/getting-started.md` step 10, `docs/the-lifecycle.md` step 8 | log |
| replay | What `lake exe replay` does to a trace: it parses each command with the model's own parse, replays the trace, and names the step where the code took a path the model has no edge for. A trace is "replayed into the model" in the one rule and "replayed against the model" at lifecycle step 8 | `docs/getting-started.md` step 10, `docs/the-lifecycle.md` | |
| known-good trace, known-bad trace | A trace that conformed, kept with the tests; and a trace that found a defect, kept until the fix lands | `docs/getting-started.md` step 10 | |
| review line | The line in the project's header, `Governance.lean`, that records a design's review: the design's path, its content hash at review time, and the reviewer. It says "unreviewed" until a person signs | `docs/the-lifecycle.md`, `examples/library/designs/README.md` | sign-off |
| review check | The check that warns while a review line is unreviewed, and fails when a design changes under a signed line | `examples/library/README.md`, `examples/library/designs/README.md` | |
| mutant | A deliberate change to the model that the examples and theorems must notice. A mutant that survives is a missing row in the design | `examples/library/README.md`, `docs/getting-started.md` step 7 | |
| mutation gate | The mutation score as a gate, over a package's `mutants.json`. A surviving mutant is a failing test | `README.md`, `docs/the-lifecycle.md` stage 4 | |
| seam | The one interface an implementation needs: a pure fold from events to a state, and a pure decider from a command and a state to an outcome, speaking the wire shape | `docs/getting-started.md` step 9 | |
| data dictionary | Every field with its meaning, domain and example value. It is the acceptance test for the types, and today the doc comments are the dictionary | `docs/the-lifecycle.md` | |

## Open questions

Terms the documents use in more than one way. Each waits on the owner. Until it is settled, a rewrite keeps each use as it stands.

| Term | The uses | Raised in |
| --- | --- | --- |
| checked | The status word for a decidable claim about one project's values, and the general sense: "checked by the Lean kernel" under *proved*, "every theorem checked", "maps checked by theorem", "the review line checked against the design's hash". The lifecycle also says the code "is checked against the model's examples" at step 7 and against the model "everywhere it ran" at step 8, which the four words call *tested*. At step 6 "a person checks the model against the design", which they call *assumed*. Its guarantees table says "Checked, per trace" for the traces, which the README puts under *tested* | `README.md`, `docs/the-lifecycle.md` |
| fact and event | The prose says a cell "reacts to other cells' facts, and folds its own facts". The types are `ForeignEvent` and `Event`, and the subject is "what an event is about". The lifecycle's design tables hold "the facts it publishes and subscribes to", and stage 1 lists "facts subscribed" and "facts published", while its guarantees say "every command, event and refusal". In the getting-started guide the Publishes rows become "the event type", and the seam folds "events" | `README.md`, `docs/the-lifecycle.md`, `docs/getting-started.md` |
| the library and the example | "Fixtures written for the library" means the worked example. The example's README is titled "The library: the worked example" and calls itself "this package" | `README.md`, `examples/library/README.md` |
| the seven steps | The steps "an agent leads or prepares", and the steps where "an agent transcribes, prepares or checks". The lifecycle, where the nine steps are laid out, gives no count of seven. Its text names an agent at steps 1, 2, 3, 4 and 7, beside people at 1, 3 and 7. Its line above the figure says an agent "transcribes and enriches at 2 and 4", and the machine "checks and generates at 2, 5 and 8". Steps 6, 8 and 9 name no agent, while the README's skills table puts a skill at each | `README.md`, `docs/the-lifecycle.md` |
| the calculus | The package ("requires the calculus over git at a tag") and what it says ("the calculus says what is inside one"). Never defined. The getting-started guide uses both: "requires the calculus over git" and "copy `lean-toolchain` from the calculus" for the package, "the calculus is generic over exactly two types" for what it says | `README.md`, `docs/getting-started.md` |
| journey map | The corpus's journey map, which people draw at lifecycle step 1 and which the vision carries (the guide's step 1 table), and the checked module an agent draws from the corpus at lifecycle step 2, `JourneyMap.lean` (the guide's step 4) | `docs/the-lifecycle.md`, `docs/getting-started.md` |
| the design corpus | Three documents, named two ways: "the vision", "the capability map" and "the architecture" in the getting-started guide's step 1; "the technology architecture, the capability map, the journey map" in the lifecycle's step 1 and its figure | `docs/getting-started.md`, `docs/the-lifecycle.md` |
| step | A lifecycle step, 1 to 9; one of the guide's steps, 0 to 12, "the twelve steps"; a journey's step, a row of its Steps table; and the step of a trace where a run is rejected | `docs/the-lifecycle.md`, `docs/getting-started.md` |
| run and trace | Whether a rejected run and a rejected trace are one thing. Lifecycle steps 8 and 9 and the figure say a "run" is rejected or checked at a step; the round trip says "a trace the model rejects" and "a rejected trace names the step"; the guarantees say a trace holds runs ("Checked, per trace" for "a run's facts") | `docs/the-lifecycle.md` |
| the one rule | Two different rules, each called "the one rule": "the design owns meaning" in the getting-started guide, and "the domain types and the examples are authored once, in Lean; everything else is generated from them or replayed into them" in the lifecycle | `docs/getting-started.md`, `docs/the-lifecycle.md` |
| the specs | "Validate the specs" (lifecycle step 6) and "Build against the specs" (step 7). The page never says what the specs are. At step 6 a reader reads the feature files and the reviewer reads the model; at step 7 the tests consume the fixtures | `docs/the-lifecycle.md` |
