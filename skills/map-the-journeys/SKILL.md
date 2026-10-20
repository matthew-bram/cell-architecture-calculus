---
name: map-the-journeys
description: Turn a design corpus, the product vision's journeys, the capability map and the technology architecture, into the journey map the cell calculus method starts from, checked by Lean: the cells with their zones, each journey as a directed acyclic graph of steps labelled with the cells it names, the paths table of every arrow between cells with its kind, and the structural claims as theorems in a module that builds, each journey a DAG, the capability map's matrix row equal to the journey's text, the architecture's direction rule on paths, and a cycle in the corpus reported rather than resolved. Use this skill whenever someone asks to map, transcribe, check or chart the journeys, find the cells, build the paths table, check that the capability map agrees with the journeys, find loops or cycles between journeys, or start modelling a system from its vision and architecture documents before any cell's design is annotated; and whenever someone is writing, drafting or revising a journey, a journey map or a journey section of a vision or product document, so that it is written to the tables the map transcribes and can be mapped at all, even if the words "DAG", "calculus" or "Lean" are never said. It comes before annotate-a-design; a single cell's tables are that skill's.
---

# Map the journeys

You are drawing the first checked picture of the system: which cells exist, where each lives, how each journey moves through them, and which arrows exist between them. Everything later rests on it. A cell that is not on this map cannot be annotated; an arrow that is not in the paths table cannot be a command or a subscription; a journey that loops here will loop in every model built from it. So the map is checked by the kernel, and what it checks is the corpus's own claims: that each journey's steps form a DAG, that the capability map's matrix agrees with the journey's prose, that no path breaks the architecture's direction rule.

The corpus owns meaning. When the corpus is wrong, as when two journeys each name the other as composition, the map says so with a theorem that the cycle exists, and the fix goes to the corpus. You never reorder steps, drop an arrow or move a cell to make a theorem hold.

Paths below are relative to this skill's directory; the package root, two levels up, holds `docs/` and `examples/`. Read first, every time:

1. `../../docs/the-dag-rule.md`: every journey is a DAG, composition against succession, and the three checks choreography must satisfy.
2. `../../examples/library/corpus/`, the three documents of the worked example's corpus; `references/golden/journey-map.md`, the map they yield; and `../../examples/library/JourneyMap.lean`, the Lean that checks it. Your map and your module should look like these, for the same reasons.
3. `../../docs/style-guide.md`, section 9, the two tables a journey section carries and the checks made of them, then sections 2 and 3, for names and comments in the module.

## When the journey is being written

If the ask is to write, draft or revise a journey rather than to map one, the section is written to section 9 of the style guide: the prose the author wants, and beside it the Steps and References tables, so that the section can be mapped the day it is finished. The cells on each step are the owner's decision, from the capability map's names; where the owner has not decided, the cell is "not stated", never a guess, and a role or a surface is never written in the cells column. Each reference is marked composition, succession or pointer by asking the owner which it is. Then map the section, below, so the author sees the checks pass before the journey is handed on. Meaning stays the owner's; the tables are its shape.

## The procedure

### Stage 1: the cells

From the capability map's list of capabilities: one constructor per capability, named as the map names it in lowerCamel, with the map's name in its doc comment. From the technology architecture's placement, the zone of each. From the map, which are platform capabilities, present in every journey and left out of the matrix rows. If the corpus has no capability list, stop and report; the cells are not yours to invent.

Before naming the cells, ask the owner whether there are predetermined domains or subdomains from a source outside the corpus: an enterprise domain model, a capability taxonomy, a context map already drawn, a team or system boundary the organisation has fixed. These are the cells' names' other owner. A context map, which stage 1 of the round trip takes beside the journey map, places each cell in a domain and gives each arrow its relationship kind, and it will be built from the same cells, so the names set here carry into it. If the owner names such a source, record it in the map's header as a source beside the corpus, give the cells table a domain and a subdomain column filled from it, and where the capability map's name for a capability and the domain's name for it disagree, keep the capability map's name as the constructor, put the domain's name in the doc comment, and record the disagreement as a gap for the owner. Never rename a cell, merge two or split one to fit the domain. If the owner names no such source, the report says the question was asked and the answer was none.

Acceptance: every capability on the map is a constructor, every constructor has a zone, and no constructor lacks a row in the map; the owner was asked for domains and subdomains from outside the corpus, and the map records the answer.

### Stage 2: the journeys

For each journey named: where the section carries the Steps and References tables of section 9 of the style guide, one row per row, transcribed and not read. Where it does not, from its Steps section or its bullets, one row per step with the cells the text names on it and the earlier steps it waits on, read from the prose's order and its fan-out and fan-in, and the missing table is a gap written as the rows the author adds. A step may wait only on earlier steps; that is what makes the graph a DAG by construction, and a step that waits on a later one is a cycle the corpus wrote, to report, not to reorder. Record the journeys the text says it reuses, each as composition, succession or pointer where the text says which, and as a gap where it does not.

Where the text names a role rather than a cell, as "the desk" for membership or "the librarian" for whichever cell the librarian acts in, read the cell the role runs in and say so in the gaps.

Acceptance: every step of every journey mapped has a row with at least one cell, and `wellFormed` holds or the cycle is named.

### Stage 3: the paths

Every arrow between cells that the journeys imply and the architecture's paths table lists: from, to, kind, the kinds being those the architecture names, event, query, command, sealed, partner, control. The direction rule the architecture states, as a predicate. An arrow with no kind in the corpus is a gap.

Acceptance: every arrow has a source, a destination and a kind from the corpus.

### Stage 4: the Lean

A module in the project's `Maps` library, `JourneyMap.lean`, in the example's shape: the cells as an inductive with their zone function and platform predicate; `Step` and `Transcribed` with `wellFormed`, which is the calculus's `Journey.nodesOk` over the steps, `Journey` being the calculus's name for the term algebra; each journey as a value named by its title; the matrix row as a value and `sameSet` against the journey's named cells; the paths as a list with the direction predicate; and one theorem per claim, `<journey>_isDag`, `matrixRow<n>_matchesJourney`, `stacks_never_ask_the_desk` or whatever the architecture's rule is named, each by `decide`. A claim the corpus makes that does not hold is kept as a theorem of its negation, `compositionAsWritten_hasCycle`, with a comment saying it is the corpus's defect. Then `lake build`.

Acceptance: the module builds with no warnings; every claim in the map has a theorem; no theorem was made to hold by changing a value.

### Stage 5: the map and the report

Write the map from `journey-map.md`'s shape: the cells table, one table per journey, the paths table, the checks table with each theorem and its outcome, and the gaps. A gap that is a missing table, a missing row or a role where a cell should be is written as the row of section 9's tables the author adds to the journey's section, so that confirming it is pasting it. Then the report.

## What you never do

- Invent a cell, a step, an arrow or a kind the corpus does not name.
- Reorder steps, drop a reuse or move a cell to make a theorem hold. The cycle is the finding.
- Put a platform capability in a matrix row, or compare a row with platform rows left in.
- Mark a claim checked that the module does not prove.
- Invent a domain or a subdomain, or rename, merge or split a cell to fit one. The domains come from the owner's source or not at all; a disagreement between it and the capability map is a gap.

## The report

End with a short report, in prose: which journeys were mapped and from which sections; whether the owner named domains and subdomains from outside the corpus, and if so the source and where it disagrees with the capability map; how many cells, steps and paths; which claims hold and which do not, naming the theorem for each; the gaps; and what comes next, which is mapping the contexts with map-the-contexts, then annotating the first cell's design.
