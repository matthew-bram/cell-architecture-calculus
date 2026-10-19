<h1 align="center">Hold the Code to the Design</h1>
<h3 align="center">An executive summary of the cell calculus, for technology leaders</h3>

> *Every organization that has broken its systems into services, bounded contexts or cells has the same unsolved problem: nothing shows that the teams agree on what they built, nothing shows that the documents are accurate, and nothing shows that the code went where the documents pointed. The controls in place today, templates and reviews, hold only what a reviewer notices, and the number of things to compare grows faster than anyone's time. This summary presents a method that asks how far a program can hold those promises instead, and answers with a build. The design is written on practices with proved theory under them, with a fixed set of tables added. A machine-checked model is transcribed from the tables; the scenarios a reviewer reads and the fixtures the tests run are generated from the model and never written by hand; and what the code did is replayed into the model, which is the judge. We state what the method changes for an organization, what it removes from the daily work of teams, what it costs, what it does not do, and the evidence so far: a generic package of forty theorems that hold for any project, a worked example with one hundred and twenty-three machine-checked claims, a build that fails when a kind of command, event or refusal has no example or when a deliberate break in the model goes unnoticed, and an implementation that passes every example rendered from its design by id.*

## 1. The problem, from the leader's seat

Decomposition has delivered on independence. Teams own their services, deploy on their own schedule, and scale what they own. What decomposition has not delivered is agreement, and the cost of its absence is paid at integration, in production, and in every audit.

Three things go wrong, and each is a cost a leader already sees on the books:

+ **Teams make the same decisions differently.** How a long-running process carries its state, what a timeout means as opposed to a refusal, what a retry does and whether it can act twice, who may trigger what. Each is easy to decide once. Across many teams and many months the answers drift, and the first sign is when one team's finished work meets another's and they do not fit. The rework arrives late, when it is most expensive.
+ **The documents and the code part company.** A capability map, a journey map and a dozen design documents each make claims the others depend on, kept by hand. The code is built from them, and from the day it ships nothing but a person's memory says whether it still matches. The next change is made against documents that no longer describe the system.
+ **Reviews hold only what a reviewer notices.** A design review, an architecture board, a risk register promising zero drift: each is a promise held by attention. The number of things to compare, journeys against capabilities, designs against code, code against what it did in production, grows faster than the attention available to compare them.

A fourth is new. Agents now write a growing share of the code, from the same documents people read, and nothing shows that the two read them the same way. A method that cannot say what its documents mean, precisely enough for a machine, cannot direct an agent any better than it directs a contractor.

## 2. What the method is

The method keeps the work teams already do and puts a shared, machine-checked model between the design and the code. We state it in one paragraph and expand each piece below.

A **cell**, in the sense of the cell-based architecture, is a self-contained unit with its own data and a gateway as the only way in. The method says what is inside one: three pure functions, one that decides what happens when the cell is asked to do something, one that reacts to what other cells have published, and one that folds the cell's own history into its state, with queries as pure reads of that state. Every cell in every journey, whichever team builds it, is modeled as these three functions. A **journey** across cells is checked to have no loops within one run, and the check is a theorem rather than a diagram review. Every **example** in a design, a Given, When, Then row, is one row in the design and one theorem in the model, under one id, and the examples of a cell registered with the generator become the fixtures its tests run, so that a failing test names a sentence a person can read. In the model, every command and event carries one typed **envelope** that says who is acting, which run it belongs to and what it follows from, with no free-form headers. And what the code did, in a test run today and in production once a cell emits its trace, is replayed into the model, which says at which step, if any, the code took a path the design has no room for.

The model is written in Lean 4, a proof assistant. Teams write their designs with a fixed set of tables, and an engineer or an agent transcribes the tables into the model one row to one definition; the universal theorems are written by whoever writes them, a person or an agent, and reviewed by whether they state the right thing. The kernel then checks what can be checked by computation and proves what holds for every input. People review what the model generates, in plain sentences, and sign for it.

## 3. What it changes for an organization

The guarantees come in two strengths, and the distinction matters. Forty theorems in the generic package hold for any project that builds on it, with nothing to write. The rest hold per cell, where a team states and proves them for its own cells, as the worked example does for one of its four; the full table, each with the cross-team failure it rules out, is in [the lifecycle](docs/the-lifecycle.md).

+ **One shape for every team, in the model.** A cell cannot quietly trigger another cell's command in the model, because the function that would do it cannot be written, and a journey that loops within a run is refused by the compiler. The code is then held to the model by its tests and its traces. Hidden orchestration, the thing that fragments a decentralized architecture, is ruled out of the design by construction rather than by guideline, and found in the code by replay.
+ **A review surface people can read.** Every example of a registered cell is rendered from the model as a Given, When, Then scenario, stamped with the hash of the model it came from. A product owner, a compliance reviewer or an auditor reads the scenarios, never the model, and signs. The thing reviewed is the thing executed.
+ **Decisions made once.** One row per branch of every decision forces questions such as "what happens if the user resumes on two channels at once" to be answered in the design, once, for every team, instead of in each team's code.
+ **A gate that cannot be argued with.** A kind of command, event or refusal no example reaches, a command that does not survive the trip to the wire and back, a design that changed under a signed review: each fails the build, with a message that names the claim. The mutation gate goes further and deliberately breaks the model, one named break per decision a team chooses to guard, to confirm that some example or theorem notices; a break nothing notices is a failing test.
+ **Drift made visible.** The review that says the model matches the design is recorded with the design's content hash, and the build fails when the design changes without a new review. The fixtures carry the model's hash, and the test suite fails when the model changes under it. Drift between design, model and tests cannot be prevented, but in those two directions it can no longer be silent.
+ **The code checked where it ran, not only where the examples looked.** Code that records what it did, in the shape the fixtures already use, has its run replayed by the model, and a run that took a path the design has no room for is rejected at the step, with what the model expected and what the code reported. The worked example does this for a test run; doing it for sampled production runs is the same mechanism, once a cell emits its trace.
+ **Automation and AI placed by the architecture.** Any automated judgment, a recommender, a scheduler, an agent, is a source of facts, and the method proves what can follow from it and nothing about it. The one place an automated decision becomes a command runs through a policy with three rungs, shadow, review and autonomous, and a retried hand-off is proved to be the same command. An organization can turn automation up one rung at a time, with the same mechanism for every team.
+ **End-to-end latency that can be derived.** A journey's latency bound follows from its steps' contracts by a proved rule, on the assumption that each step honors its own; availability budgets and cost fold the same way, with the proof so far that tightening one step never worsens a journey's bound.

## 4. What it removes from the daily work

The method's return is in work that stops being done by hand, and in failures that stop arriving late.

| Today | With the method |
| --- | --- |
| Test fixtures and scenarios written by hand, per team, drifting from the specification | Fixtures and scenarios generated from the one model, stamped with its hash, never edited |
| Specification and tests reconciled by reading both | The same example is the specification, the theorem and, for a registered cell, the test, under one id |
| A capability map and a journey map kept consistent by review | A theorem per journey says the map's row and the journey's table agree, once both are transcribed, re-checked on every change to the model |
| Integration surprises when two teams' journeys meet | The shape is checked before either team builds; what does not fit is refused at the design |
| Retry behavior invented per service | One rule for every gateway, a key the caller minted, and the proof per cell that a repeated command with the same key acts once |
| Branches nobody tested, found in production | Breaks a team writes a mutant for, found by the gate in CI |
| Audits that reconstruct what was built from memory and tickets | The design's hash on the signed review line, the model's hash on every fixture, and traces that show the code did what the model allows |
| Onboarding to a dozen teams' conventions | One shape, one envelope, one review surface across every team |

The proofs the worked example needed were small. Each of its ten universal theorems took one simplification, one case split or one induction, and none needed a proof a person had to invent; the generic package's theorems were written once and are not written again. The example's corpus, maps, design, model, implementation and traces were written in one working session against the calculus as it stood, and the full build succeeded on the first run. In an earlier trial on a private architecture, the generic package and the first project's modules were written by an agent from the documents in two working days.

## 5. What it costs

The method is not free, and its costs are the ones a leader should weigh.

+ **Practices with proved theory under them.** The method assumes idempotent receivers with keys the caller mints, events published from the same record as the state, sagas that record their intent, and cells that keep their history as events or as versioned rows. A system that does not work this way is not one the model describes until it does.
+ **A proof assistant in the build.** Lean 4 is pinned per package and fetched by the build; it needs no library beyond its core. The toolchain releases monthly and upgrades are on purpose. Architects stay at the level of decisions and examples; someone, a person or an agent, writes the per-cell theorems.
+ **Annotation discipline.** Designs carry a fixed set of tables beside their prose, and journey sections carry two. A design with commands and no decision rows fails the same check as one with no examples. No tool reads the tables yet; transcription is done by an engineer or an agent, one row to one definition.
+ **Instrumentation for traces.** A cell whose runs are to be replayed records each command it was handed and the outcome it produced, in the wire shape the fixtures already use. That seam is the implementation's work.
+ **A human review step that stays human.** Whether the model means what the design intended is a person's judgment, recorded where the build can see it. The method makes the review's expiry visible; it does not remove the review.

## 6. What it does not do

We state the limits so that the method is not oversold. The paper gives ten, each with a proposal; these are the ones a leader needs.

+ **It does not prove the design means what people intended.** That is the human review above. In the worked example that review has not yet been signed.
+ **It does not prove the code.** The code is tested against the model through the generated fixtures and replayed traces, on the examples a team wrote and the runs it recorded. Random inputs with the model as the oracle, and the option of shipping a pure cell's model as its production code, are proposals in the paper and not built. The claim today is "agrees with the model on every input tried".
+ **It does not model the failure window.** A timeout, the case where an effect may or may not have landed, is a value in the type and a rule the caller follows, not yet a theorem; the saga that would prove the retry safe is proposed.
+ **It does not prove any judgment.** A person's decision or an AI's answer is a fact the model takes as given. Measuring a judgment's quality separately is a proposal, not a mechanism.
+ **Transcription can vary.** Two transcriptions of the same tables could differ; the tables and the model's refusal of anything off-shape limit it, and golden tests that pin a design to a model are not built.
+ **Composition is partly proved.** That a journey's steps form a DAG is proved for every journey; that a cell waiting on two facts acts the same whichever arrives first is proved for the example's one such cell, and the general form is open.
+ **The evidence is one example, by the method's authors.** Four of the example's eleven cells are modeled, one is implemented, and no team that did not write the calculus has yet modeled a system with it.
+ **Some generators are not built.** The fixtures, the scenarios, the review check, the mutation gate and the trace checker run today. Message schemas, storage definitions, diagrams, the data dictionary as a document, and a signed attestation tying a test run to the model's hash are the next pieces, and the paper's call to contribute lists them.

## 7. The evidence so far

The method was applied end to end to a worked example written for the repository, a public library's circulation system, after an earlier trial on a private architecture. Every row but the last runs in the repository's build.

| Measure | Result |
| --- | --- |
| Universal theorems in the generic package, true for any project | 40 |
| Checks in the example, every example a theorem | 123, ten of them universal about the example's own cells |
| Named examples, each a row in the design and a theorem | 32, across four cells |
| Examples rendered as scenarios and fixtures, for the one cell registered | 13 |
| Mutants, deliberate breaks the examples and theorems must notice | 17, all killed |
| Traces replayed into the model | 7: three conform, including one recorded from the implementation; four rejected for four different reasons |
| Implementation tests, each named by its example's id | 13, all passing, plus the check that the fixtures are the ones the suite was written against |
| Coverage holes found by the mutation gate in the earlier trial | 2, each closed with one example |

The full argument, the calculus shape by shape, the ten places the method can fail and the seven decisions that made it consistent, with what each leaves open, are in [the white paper](white-paper.md).

## 8. How to start

The method is designed to be adopted one journey at a time, and the first journey is the pilot. A team takes one journey it already owns, writes the journey's two tables and the first design's tables, transcribes the maps and one cell, and runs the build: the examples as theorems, the generated scenarios, the mutation gate, the tests against the fixtures by id, and one recorded trace replayed. The [getting-started guide](docs/getting-started.md) walks the twelve steps, each pointing at the file in the worked example that does it, and the example builds from a clean machine with one install.

What a pilot yields is a measurement a leader can use: how many decisions the journey's design had left unmade, found by the tables; how many breaks no example noticed, found by the gate; and whether the running code took a path the design had no room for, found by the first replayed trace. Those three numbers, on one journey, are the business case for the second.

The method is published as open source under the Apache 2.0 license, with the generic calculus, the worked example, the documents and the build in one repository. What comes next is for the people who use it to say, and the three contributions worth most are a second project in any domain, a transcription that holds the same design to the same model, and a rejected trace from running code.
