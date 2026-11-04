# What comes next

This directory is the forward record. [research/](../research/) holds the notes that led to the method, as they were written on their days. This directory holds the directions being explored now. Each is stated as a problem before anything is built, with its experiments and their notes beside it once there are any.

Nothing here changes [cell-calculus/](../cell-calculus/) or [examples/library/](../examples/library/) until a shape has been proved and graduates by supersession, with its universal theorem, its doc comments, a mutant its theorem kills and a changelog row, as the [contributor's guide](../CONTRIBUTING.md) says of any shape.

## How a direction is worked

1. **A problem statement first.**
   - Why the direction matters.
   - The hypothesis, in one sentence.
   - What would count as evidence for it, and against it.
   - How it might be explored in proofs of concept.
   - What it is not.

   The statement is dated. It is revised by a dated note rather than rewritten, so a reader can see what was believed before an experiment and what after. A rewrite in the repository's voice is not a revision. It keeps every claim, the date and the words of the day, and its commit says that only the voice changed.
2. **Experiments as packages beside the statement.** Each experiment is a `lake` package under the direction's directory. It requires the calculus, and the example where it needs it, by path. Each reports a cost column and a value column, in the terms its statement fixed. Its working notes are dated, one per experiment.
3. **The four words keep their places.** Proved, checked, tested and assumed mean what the [README](../README.md#what-it-proves-checks-tests-and-assumes) says they mean, here as everywhere. A sentence in a problem statement is a proposal until an experiment's note says which of the four words it earned.
4. **Graduation.** A shape proved here does not move. A copy arrives in the calculus, additive, and the direction's statement records the date and the version the copy arrived in. A shape that fails stays here with the note that says how it failed, because a recorded failure is what the next attempt starts from.
5. **The scrub gate holds here too.** Nothing in this directory names a tool, a host, a person or another project's domain. Every claim in a statement points at this repository's own documents and build, or at plain reasoning.

## The directions

| Date | Direction | What it asks | Status |
| --- | --- | --- | --- |
| Nov 1, 2026 | [into-the-code.md](into-the-code.md) | How far below the cell's boundary the model can go, level by level, so that decisions move left into the model and the code has fewer of them left to make | Problem statement; no experiment yet |
