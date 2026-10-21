# The research record

The notes that led to the method, dated and in the order they were written, during an earlier trial on a private architecture, before the library example existed. They are the record of how the calculus took its shape: the hypothesis tested against a real corpus, the threats to it with a proposal for each, the seven problems that stood in the way, and each of those worked through with a recommendation for the owner. The public documents, the [white paper](../white-paper.md), [docs/](../docs/) and the [example](../examples/library/), supersede the notes wherever they differ; a note says what was found on its day, not what the repository holds now.

## The notes

| Date | Note | What it is |
| --- | --- | --- |
| Oct 12, 2026 | [research.md](research.md) | The hypothesis that every journey is a DAG, tested against the trial's journeys, capability map and architecture; what Lean can and cannot do for the three wants; the proof of concept and what it caught; revised the same day when the owner split composition from succession |
| Oct 12, 2026 | [threats.md](threats.md) | Ten threats to the hypothesis with a proposal for each; the first, whether the model and the examples have the same geometry, worked in depth as consistency, coverage, conformance and provenance, with the first mutant that survived |
| Oct 12, 2026 | [big-rocks.md](big-rocks.md) | The seven problems in the way of a consistent method, ranked, each with its problem, proposed rule, shape in the calculus, open questions and prior art |
| Oct 13, 2026 | [envelopes.md](envelopes.md) | Rock 1 worked: the two envelopes with fixed, typed fields, the four open questions answered, the actor gate and the per-run shape check |
| Oct 13, 2026 | [queries-time-and-zones.md](queries-time-and-zones.md) | Rocks 2 and 4 worked: queries and the clock as inputs a decider never fetches; identifiers indexed by zone with the scrub as the one function whose type names two |
| Oct 14, 2026 | [policy-promises-and-governance.md](policy-promises-and-governance.md) | Rocks 3, 5 and 7 worked: the policy cell as the one place a fact becomes a command; promises as predicates over runs; supersession in place of edit |
| Oct 14, 2026 | [the-build.md](the-build.md) | Rock 6 worked: the build as it first ran, the second hole mutation found, what was not built, and the three open questions |
| Oct 14, 2026 | [value-attributes.md](value-attributes.md) | Quality attributes sorted into four families by what they quantify over, and what each family needs from Lean; the synthesis of the five literature notes below |
| Oct 14, 2026 | [research_notes/](research_notes/Value%20attributes%20as%20mathematics/) | The five literature notes behind it, on temporal logics and traces, hyperproperties and security as types, quality-attribute scenarios, probabilistic and resource verification, and compositional contracts, with `LatencyBound.lean`, the sixty-line experiment that proves the latency fold in Lean core |

The trial's own Lean files, `Calculus.lean` and `Journeys.lean`, which the notes cite, are not published. Their public successors are [cell-calculus/](../cell-calculus/), where every shape the notes propose lives with its theorem, and [examples/library/JourneyMap.lean](../examples/library/JourneyMap.lean), the journey map of the public corpus. `LatencyBound.lean` is published as it was written and compiles against the pinned toolchain.

## What was changed for publication

The notes are otherwise as written on their dates. Four things were changed so that nothing in them names a tool, a host, a person or another project's domain, which is the rule the whole repository is held to.

- **The trial's documents are cited, not linked.** Every link into the trial's repository is replaced by the document's name in plain text; the documents themselves are not published. A note's "what this changes in the architecture documents" section therefore names documents a reader cannot open.
- **The trial's names are replaced by neutral ones**, consistently across every note: the unit its data is partitioned by, its restricted zone, the cell modelled first, the threshold that fires an alert, the sum set aside, two of its roles, its member identifier and its assistant each have one neutral name here. A Lean identifier quoted from the trial's files is renamed the same way, so a name in these notes does not match the file it describes.
- **Sentences quoted from the trial's documents are paraphrased** where they carried those names. References to the trial's numbered principles, methods, rules and risk rows are kept as numbers; they point at documents a reader cannot open and are left as the record of what was cited.
- **A byline, local paths and one citation's address** were removed or replaced; the method documents the notes cite are pointed at their public paths under `docs/`.

What was lost is small and bounded: a reader cannot follow a citation into the trial's corpus, and the trial's vocabulary, which carried some of its meaning, is read through the neutral names. What was not changed is the substance: every finding, every count, every theorem named and every open question is as it was on the day.
