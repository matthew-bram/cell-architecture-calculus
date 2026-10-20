---
name: map-the-contexts
description: Turn a design corpus and its journey map into the context map the cell calculus method takes beside it, checked by Lean: each cell's bounded context, the subdomain kind each context serves, the owner's enterprise domains and subdomains where there are any, and for every arrow between two contexts a relationship in the standard DDD vocabulary, who is upstream and who is downstream, an open host service, a published language or a plain supplier upstream, a customer, a conformist or an anti-corruption layer downstream, partnership, shared kernel or separate ways where the corpus says so; with every arrow's coverage, every partner's translation and the places a heuristic is broken as theorems in a module that builds, and a relationship the corpus does not state recorded as a gap, never invented. Use this skill whenever someone asks to draw, map, chart, check or standardize the context map, the bounded contexts, the domains and subdomains, the upstream and downstream relationships, the integration patterns between contexts, who conforms to whom or where an anti-corruption layer belongs, whenever a journey map exists and the designs are about to be annotated, and whenever two teams disagree about which side of an integration owns the shape, even if the words "DDD", "context map", "calculus" or "Lean" are never said. It comes after map-the-journeys and before annotate-a-design, whose Wire table takes the parse's property from this map.
---

# Map the contexts

The journey map says which cells exist, where each lives and which arrows join them. The context map says what each arrow means to the two sides: which context is upstream and which downstream, and under which pattern. Those are decisions teams otherwise make one integration at a time and differently each time, and they are the decisions this method moves left: a conformist's parse is the identity up to shape, an anti-corruption layer's parse is a real translation and the one place a refusal means "not understood", a customer commands through the owner's gateway in the owner's terms. The context map fixes which, per edge, before any design's Wire table is written, and the Lean checks that every arrow the journey map draws has a relationship in the right direction.

The corpus owns meaning. The contexts are the cells the architecture says are bounded contexts; the subdomain kinds are the capability map's; the relationships are read off the paths tables and the architecture's rules for how cells communicate; the enterprise domains and subdomains are the owner's, from the source map-the-journeys asked for and recorded. Where the corpus does not say which pattern an edge has, the edge is a gap with the reading proposed, not a row. A DDD heuristic the corpus does not state, such as a core context not conforming to a generic one, is reported where the map breaks it and never used to change the map.

Paths below are relative to this skill's directory; the package root, two levels up, holds `docs/`, `cell-calculus/` and `examples/`. Read first, every time:

1. `../../cell-calculus/CellCalculus/ContextMap.lean`: the vocabulary, subdomain kinds, upstream and downstream patterns, the relationship, coverage and its theorem. Every map uses these names and no others.
2. `references/golden/context-map.md`, the context map of the worked example's corpus under `../../examples/library/corpus/`, and `../../examples/library/ContextMap.lean`, the Lean that checks it, beside the journey map of map-the-journeys. Your map and your module should look like these.
3. `../../docs/the-lifecycle.md`, the round trip's stage 1 and the paragraph "Lean and the wire", for what the relationship becomes downstream.
4. The journey map for the project, from map-the-journeys: its cells table, its paths table, and its record of the owner's answer about domains and subdomains from outside the corpus.

## The procedure

### Stage 1: the contexts

From the journey map's cells and the architecture's statement of which capabilities are cells: one constructor per bounded context, named as the cell is, with the capability map's name in its doc comment; a channel application or a platform plane that the architecture says has no bounded context of its own gets none. Each outside party a partner call reaches is a context too, marked external, named as the architecture's partner table names it. Where the architecture groups several cells into one context, the grouping is the architecture's and the map says so; without such a statement, each cell is its own context, and the map says that too.

Then the kinds: from the capability map's classification of capabilities as core, supporting or generic, one kind per context. Then the owner's domains and subdomains: where map-the-journeys recorded a source outside the corpus, a domain and a subdomain column filled from it, the corpus's name kept as the constructor and the source's in the doc comment, a disagreement a gap. Where it recorded none, ask once more, and record the answer.

Acceptance: every cell with a bounded context is a constructor, every constructor has a kind, every external party has a constructor, and the domain columns are filled or the map says the owner named no source.

### Stage 2: the relationships

For every arrow in the paths tables between two contexts, one relationship, upstream to downstream, by the kind of path: the publisher of a fact is upstream of every cell that reacts to it; the owner of a gateway is upstream of every cell that queries or commands it; an outside party is upstream of the cell that calls it. One pair of contexts in one direction is one relationship, however many arrows run between them.

The patterns, from the corpus's words:

- **Upstream.** An open host service where the design says the gateway is offered to any cell with its protocol stated, as "each design lists what its gateway offers". A published language where the facts go out in a shared, documented schema, as domain events on a fabric with an event schema do. A supplier where the corpus states no protocol, which is what an outside party is.
- **Downstream.** A customer where the cell commands or queries through the gateway in the owner's terms. A conformist where the cell reacts to the fact as published, keeping its shape. An anti-corruption layer where the cell keeps its own projection in a different shape, or translates at a partner's edge, as "duplicate by projection" and an adapter's contract say.
- **Symmetric.** Partnership, shared kernel or separate ways only where the corpus says two contexts plan together, share a piece of the model, or have no connection. Never inferred.

An arrow whose pattern the corpus's words do not decide is a relationship in the map with its pattern proposed in the gaps, not written as a row.

Acceptance: every arrow between contexts has a relationship with its direction, and every pattern points at the corpus's sentence in the provenance.

### Stage 3: the Lean

A module in the project's `Maps` library, `ContextMap.lean`, beside the journey map, in the example's shape: `Context` as an inductive with `isExternal` and `kind`; the cell-to-context function; `contextMap` as the list of relationships in the tables' order; `Path.upstream` and `Path.downstream` by kind; the paths as pairs of contexts; and one theorem per claim by `decide`: `<arrows>_covered` with `allCovered`, `partners_translate` over every external upstream, `noSeparateWays` or the separate-ways pairs named, and each heuristic as a list computed from the map with a theorem pinning where it is broken, `coreConformingToGeneric_is…`. A claim that does not hold is kept as the theorem of its negation with the comment that it is the corpus's defect. Then `lake build`.

Acceptance: the module builds with no warnings; every claim in the map has a theorem; no relationship was added or turned to make a theorem hold.

### Stage 4: the map and the report

Write the map from `context-map.md`'s shape: the contexts table with kind, domain and subdomain, one row per relationship with its upstream and downstream patterns and the corpus row it comes from, the checks table with each theorem and its outcome, the heuristics with where each is broken, and the gaps. Then the report.

## What you never do

- Invent a context, a grouping of cells, a relationship, a pattern or a domain the corpus or the owner's source does not state.
- Turn a relationship, change a pattern or drop an arrow to make a theorem hold. An uncovered arrow is the finding.
- Resolve a heuristic. Where the map breaks one, say where, and leave the fix to the owner.
- Decide a cell's Wire table here. The map says whether the parse translates; the design says how.

## The report

End with a short report, in prose: which tables the contexts and relationships came from; whether the owner named domains and subdomains and from what source; how many contexts, how many external, how many relationships by pattern; which claims hold and which do not, naming the theorem for each; where each heuristic is broken; the gaps; and what comes next, which is annotating the first cell's design with its Wire table's parse property read from this map.
