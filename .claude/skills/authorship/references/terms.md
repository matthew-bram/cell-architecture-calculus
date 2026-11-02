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

## Open questions

Terms the documents use in more than one way. Each waits on the owner. Until it is settled, a rewrite keeps each use as it stands.

| Term | The uses | Raised in |
| --- | --- | --- |
| checked | The status word for a decidable claim about one project's values, and the general sense: "checked by the Lean kernel" under *proved*, "every theorem checked", "maps checked by theorem", "the review line checked against the design's hash" | `README.md` |
| fact and event | The prose says a cell "reacts to other cells' facts, and folds its own facts". The types are `ForeignEvent` and `Event`, and the subject is "what an event is about" | `README.md` |
| the library and the example | "Fixtures written for the library" means the worked example | `README.md` |
| the seven steps | The steps "an agent leads or prepares", and the steps where "an agent transcribes, prepares or checks" | `README.md` |
| the calculus | The package ("requires the calculus over git at a tag") and what it says ("the calculus says what is inside one"). Never defined | `README.md` |
