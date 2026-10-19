## What changed, and why

<!-- One or two sentences in prose. The merged commit message is taken from here, and the repository keeps one commit per step. -->

## Which kind of change

<!-- Keep the lines that apply. -->

- A change to the worked example or its documents, by the style guide
- A new shape in the calculus, additive, with its universal theorem, its doc comments and a mutant its theorem kills
- A supersession in the calculus: the old name stays, deprecated with the date and its successor, and the version in `cell-calculus/lakefile.toml` moves
- A change to a gate script or the workflow
- A document only

## The gates

<!-- CI runs these; say here whether you ran them locally. -->

- [ ] `lake build` in both packages with no warnings
- [ ] `python3 tools/mutants.py` on both mutants files, every mutant killed
- [ ] `lake exe fixtures` leaves `examples/library/generated/` unchanged, or the model changed and the views with it
- [ ] `lake exe replay` accepts the good traces and rejects the bad ones
- [ ] `python3 -m unittest discover -s impl` in the example
- [ ] `python3 tools/scrub-check.py` is clean

## The rules

- [ ] Every row, type and example in a model points at a sentence in a design or the corpus; a gap is in the design's open items, not in the model
- [ ] No theorem or example was deleted or edited in place; a change is a supersession or a retirement with its successor, date and reason
- [ ] `CHANGELOG.md` has a row if a decision was made
- [ ] The branch is `feature/<name>`
