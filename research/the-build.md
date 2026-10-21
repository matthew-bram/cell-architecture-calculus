# The build

Rock 6, worked · Oct 14, 2026 · from [big-rocks.md](big-rocks.md): what runs, what it found on its first run, what is not built, and the open questions with a recommendation on each

**Confidence.** **[H]** run here today; **[M]** written and not yet run on a runner.

> **Revised Oct 15, 2026.** The scripts below are now data-driven: `mutants.py` takes a mutants file, with the generic package's mutants in `cell-calculus/mutants.json` under their own CI job and the project's in `mutants.json`; `review-check.py` takes the governance module and the design root; the renderer is `Render` in the calculus and `Fixtures.lean` is the registration list. The commands as they are today are in the README. The record below is as the rock was worked on Oct 14.

## What runs

Two `lake` packages: `cell-calculus`, the generic shapes with their universal theorems and no dependencies, and this directory's package, which requires it by path and holds the project's slice. The toolchain is pinned by `lean-toolchain` in both.

| Step | Command | What it does | Status |
| --- | --- | --- | --- |
| The check | `lake build` | Builds the generic package, then `Journeys` and the project's library and `Fixtures` as an executable; every theorem is checked by the kernel | Runs **[H]** |
| The generators | `lake exe fixtures` | Renders the books slice's live examples from the one Lean value, two ways: `generated/books.feature`, Gherkin for the reader, and `generated/books-examples.json`, fixtures in the wire shape for the code's tests, serialized by the gateway's own serializer. Both carry the model's hash; a view without a stamp is not a view | Runs **[H]** |
| The review line | `python3 review-check.py` | Reads the design path and hash from `calculusHeader`, recomputes the design's hash, warns while the header says unreviewed, fails when the design changed since the review | Runs; warns today **[H]** |
| The mutation score | `python3 mutants.py` | Applies ten named mutants, seven to the generic package and three to the project's, one at a time, in a copy of both packages; each must be killed by at least one theorem; the score is the gate | Runs; 10 of 10 **[H]** |
| CI | The CI file at the repository root | The four steps above on every change under `lean-journeys` or `docs`, with the generated views as artifacts | Written, not yet run on a runner **[M]** |

## What the first run found

The mutation gate found a hole on its first run. The eight operators then were: the retry books again; the terminal flag flipped; the alert fires at the limit; the actor gate wide open; the move compares backwards; shadow issues; the clock runs backwards; the scrub forgets the map. Two were added with the contracts and the rule sets: the sequence bound takes the max instead of the sum, killed by the compositional theorem; and forbids ignored, killed by forbid-overrides. Seven were killed. **The alert at the limit survived**: `amount > limit` mutated to `amount >= limit` and nothing noticed, because the two alert examples sat at 5000 against 500 and 50 against 1000, and no example sat on the boundary. One example at the boundary, `ALERTS-THRESHOLD-3`, killed it.

That is the second hole mutation has found in this model. The first, the terminal flag, was found by hand under threat 1 and closed today with two examples so that the gate could be green. The pattern in both is the same: a branch the examples never reach, found mechanically, closed with one row.

## What is not built

- **The other generators.** Proto, Avro, JSON Schema and OpenAPI from the types; Mermaid for the Event Modeling view; the data dictionary from the types and their docstrings. The fixtures executable is the shape they take: one `lake exe` per view, each stamped.
- **The trace checker as an executable.** `Cell.conforms` and `Run.conforms` are in the model; the executable that reads traces in the wire shape and replays them is not.
- **Golden tests for transcription.** A fixture design document and the Lean it must produce, so that the same document produces the same model every time. This is where the skill lives.
- **The superseded-list check.** `review-check.py` checks the review line; a deleted theorem is caught only by a use of it.
- **Attestation.** The run records nothing yet; in-toto is the proposed form.

## The three open questions, with a recommendation on each

**1. Does the transcription run as a Lean metaprogram over a structured design, or as an agent skill with golden tests?** Both, as the rock proposed, and the skill first. The annotation grammar's tables are regular enough for a metaprogram, but the grammar is a first cut and the skill will change it; an agent held to golden tests finds what the grammar is missing faster than a parser does. When the tables stop changing, the metaprogram takes the tables and the skill keeps the prose. The skill is the owner's next piece of work and its golden set is the fixture design plus the Lean in this directory.

**2. Where does the project live?** Here, until the skill exists, then lifted whole, as the README says. The CI file is at the repository root because the CI runner reads it there; on lifting it moves with the directory and loses its `cd`.

**3. How is the review line signed, and by what identity?** By the reviewer's commit, for now: the line names the reviewer and the commit that set it is signed by them. In-toto attestation is the form once the build produces one; the line's hash becomes a field of the attestation and the release pipeline refuses a build whose attestation names another model.

## To run it

```
curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y --default-toolchain none
cd lean-journeys && lake build && lake exe fixtures && python3 review-check.py && python3 mutants.py
```

`elan` reads `lean-toolchain` and fetches the pinned version on first use. A clean run prints the Gherkin once from the model's `#eval`, writes the two generated files, warns that the model is unreviewed, and prints a mutation score of 8 of 8.

## Sources

- Lake, the Lean build tool, in the Lean reference · Cedar's repository layout, `cedar-spec` beside the implementation, as the worked example
- [in-toto and SLSA](https://slsa.dev/blog/2023/05/in-toto-and-slsa)
- [threats.md](threats.md) threat 1 for mutation and provenance · [round-trip.md](../docs/the-lifecycle.md) for the acceptance tests the steps implement
- `lakefile.toml`, `Fixtures.lean`, `mutants.py`, `review-check.py`, the CI file at the repository root
