---
name: annotate-a-design
description: Turn a prose design document into the annotated design the method's tables require, Commands, Subscribes, Publishes, State, Decide, React, Terminal, Examples, Universal claims, Sentences, Wire, the journey, Contracts and Attributes, each row traced to the design's own sentence, with every gap the design leaves recorded as a question or a proposal for the owner and nothing invented. Use this skill whenever someone asks to annotate, tabulate, structure, formalize or prepare a design, a capability, a cell, a bounded context, a service or a slice for modelling; whenever a prose design, architecture document or spec is to be turned into examples, specification by example, Gherkin, scenarios or tables; whenever model-a-cell would be next and no annotated design exists; and whenever someone asks what a design is missing before it can be modelled, even if the words "annotate", "tables", "calculus" or "Lean" are never said.
---

# Annotate a design

You are drafting the review surface, not the model. A person who cannot read Lean can read a table, and the tables you write are what that person confirms before an agent transcribes them into types. That is why one rule governs everything here: a table holds only what the design states, and everything a table needs that the design does not give goes in the gaps section as a question or a proposal. A proposal in a table looks like a decision the owner made. A proposal in the gaps looks like what it is.

The second reason for the rule is downstream. The model-a-cell skill transcribes these tables one row to one definition and refuses to invent a row. If a row here is invented, the model is wrong with a clean build, which is the one failure a kernel cannot catch.

Paths below are relative to this skill's directory; the package root, two levels up, holds `docs/` and `examples/`. Read first, every time:

1. `../../docs/style-guide.md`, section 8, the tables and their columns, then sections 6 and 7, why a field's domain must match its meaning and why an attribute names its quantifier before its example.
2. `references/golden/holds-shelf/source.md` and `answer.md`: a prose design and the annotation of one slice of it; and `../../examples/library/designs/circulation.md`, a design written to the tables from the start, which is what a confirmed annotation becomes. Your annotation should look like the answer looks, including its provenance and gaps sections, for the same reasons.
3. `assets/annotated-design-template.md`, the skeleton with the sections in order.

## The procedure

### Stage 1: the scope and the source

Fix three things: the design's path; its content hash, `shasum -a 256 <file> | cut -c1-16`, which the header carries so that the model's review line can cite it; and the slice. A design usually describes one cell with many commands, and the owner names which commands, or which workflow, this annotation covers. Annotating a whole design is fine when asked; annotating a slice without saying which is not.

Then read the design once through for its shape: the sections that carry interfaces, the data, the rules, the risks and promises. A design that is a stub, with its sections empty or holding only a prompt to a future author, has nothing to annotate. Stop and report which sections are empty; do not annotate the stub's scope paragraph into tables.

Acceptance: path, hash and slice are written in the header, and the design has sentences for the slice.

### Stage 2: the shape

From the interfaces and the data: Commands, Subscribes, Publishes, State, Terminal.

- A command's id is lowerCamel from the design's name for it; its sender is the design's "open to" or equivalent, with the kind named as the calculus names actors, a member with a role, a policy cell, a timer, a partner, the operator; its fields are the design's data words with types where the design gives them and "not stated" where it does not; its refusals are the design's checks, one refusal per check that can say no.
- Subscribes is what the design says the cell listens to from other cells. Something the design lists under "what it needs" that arrives as a command is a command, not a subscription; say so under the table.
- Publishes is the design's facts, with the fields the design says each carries.
- State is what the design says the cell keeps, with each invariant the design states as a sentence in the invariant column.
- Terminal is the design's sentence, or "not stated".

Acceptance: every row has a line in the provenance section pointing at the design's words and where they are. A row you cannot point at is not written.

### Stage 3: the behaviour

From the checks and the rules: Decide, React, Universal claims.

- Decide has one row per check the design states for a command, in the design's order, then an otherwise row with the fact the design says is published. The reads column names the queries the design says the decision reads; empty when it reads only its own history. A check on who is acting belongs to the sender column and the gate, not to Decide.
- React has one row per branch the design states for a subscribed fact.
- Universal claims are the design's sentences with "never", "always", "every", "once", "at most", each named as the style guide names theorems and restated as the sentence a theorem will stand for.
- A command with checks and no stated outcome, or a stated outcome with no stated checks, is a gap, not a guess.

Acceptance: no Decide row without a sentence; every command has either an otherwise row or a gap.

### Stage 4: the journey, the contracts, the attributes, and what the design does not give

- The journey, where the design describes a workflow: one row per step, each a cell deciding or reacting, and a sentence giving the sequence. A wait on a person between two steps is a wait, not a loop.
- Contracts, where the design gives a step's latency, availability or cost; "not stated" otherwise.
- Attributes, from the risks, measures and promises: each with the scope its statement quantifies over, one run, a pair, a population with a threshold, a distribution that is measured, or the artifact; its subject from the design's placement of the data; its promise in the calculus's words where it fits, `withinDuration`, `neverAfter`, `atMostCount`, or the measure in prose.
- Examples: the design's own, if it gives any, as rows. Otherwise the table is empty and the gaps propose one per Decide row, with ids in the design's style, as shapes the owner makes concrete.
- Sentences and Wire: the design's, or "not stated".

Acceptance: every attribute's scope is one of the five, with a threshold only where the scope is population; the examples table holds no row the design does not give.

### Stage 5: provenance, gaps, report

The provenance section is a table, row of the annotation to the design's words to where in the design. The gaps section is a numbered list, each a question or a proposal written so that confirming it is moving it into a table. Then the report.

## What you never do

- Invent a row, a field type, an example, a sentence or a refusal the design does not state. The gaps section exists so that you never have to.
- Put a proposal in a table, or resolve an ambiguity in the design silently by picking a reading.
- Annotate a stub, or a design whose relevant sections are empty.
- Edit the design. The annotation is a separate document that cites the design; the owner edits the design when confirming.

## The report

End with a short report, in prose: the slice and the source's hash; how many rows each table holds; what the design was missing, by table, which is the gaps section in a paragraph; and what comes next, which is the owner confirming the tables and model-a-cell transcribing them.
