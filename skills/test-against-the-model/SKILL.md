---
name: test-against-the-model
description: Wire an implementation's test suite to the fixtures a model in the cell calculus generates, so that every example of the design runs against the code by its id: load the generated JSON, replay each example's history through the code's fold, hand its command to the code's decider, compare the outcome exactly, name each test by the example's id, assert the fixture stamp, and read a failure as the design row the code disagrees with. Use this skill whenever someone asks to test, validate, verify or check an implementation, a service, a handler, an aggregate or a gateway against its model, its design, its examples, its scenarios, its fixtures or its Gherkin; whenever generated JSON examples or feature files are to be consumed by tests; whenever a team asks how the code is tested against the model or how to write tests from the spec; and whenever a test against the fixtures fails and someone asks whether the code or the model is wrong, even if the words "fixture", "calculus" or "Lean" are never said. It is for the code's side; a change to the model is change-a-model.
---

# Test against the model

The model's examples are the design's rows, proved against the model by the kernel. The code is right when it agrees with every one of them, and the fixtures are how it is asked: the same Given, When and Then, serialized by the model's own serializer, with the row's id on each. That gives the test suite three properties the method depends on. A test is named by the design's row, so a failure names a sentence someone can read. The fixture is the thing the reviewer read as Gherkin, so what is tested is what was reviewed. And the fixture carries the model's hash, so a regenerated model changes the tests visibly rather than silently.

What this skill does not do is judge the model. A failing test means the code and the model disagree on a row; which is wrong is the owner's call, and the answer goes to the code or, through change-a-model, to the design. The suite never edits a fixture to pass.

Paths below are relative to this skill's directory; the package root, two levels up, holds `examples/`. Read first, every time:

1. `references/fixture-format.md`: the JSON's shape, what each field is, what a test does with one example.
2. `assets/test_examples_template.py`: the suite's skeleton, with the adapter the code supplies.
3. `../../examples/library/generated/circulation-examples.json` and `circulation.feature` beside it: a fixture set as the generator writes it, and its readable form; and `../../examples/library/impl/test_circulation.py`, the example's own suite over them, which the template is drawn from.

## The procedure

### Stage 1: the fixtures and the code's seam

Find the generated fixture set for the cell, and read its stamp and its ids. Then find the code's seam: the function that folds history into state and the one that decides a command in a state, whatever they are called. If the code has no such seam, because its decision is tangled with its storage or its transport, say so: the test needs a pure decider to call, and making one is the implementation's work, not the test's. Do not write a test that stands up a database to replay four events.

The code must speak the wire shape, or the adapter must translate. If the code's command and event types differ from the wire's, the adapter maps them in both directions, and that mapping is itself a thing to keep small and visible.

Acceptance: the stamp and the ids are written down; the seam is named, or its absence reported.

### Stage 2: the suite

From the template: load the JSON, assert the stamp, one parameterized test per example named by its id, replay `given`, decide `when`, compare to `then` exactly, in the code's test framework and language. Exactly means the same events in the same order and nothing else; a test that checks only the count, or only the first event, is not testing the row.

Acceptance: the suite runs. Every test is named by its example's id. No example is skipped or filtered.

### Stage 3: read the result

Green: every row of the design holds against the code, and the report says so with the stamp.

Red: the report names each failing id, quotes the row's Given, When and Then from the feature file, shows what the code did instead, and says which of two things it is. Either the code disagrees with a row the owner stands by, which is a code defect with the row as its test, or the row is wrong, which is a design change that goes through change-a-model. The suite says which rows disagree; it does not decide which side is right, and it never changes a fixture.

If the stamp test fails, the model was regenerated: read the fixture diff before anything else, because the rows changed under the suite.

## What you never do

- Edit, filter or skip a fixture to make the suite pass.
- Write a test whose name is not an example id, or one that checks less than the row's whole `then`.
- Decide, in a failing case, that the model is wrong. Report; the owner decides.
- Stand up storage or transport to run an example. If the decider needs them, that is the finding.

## The report

End with a short report, in prose: the fixture set and its stamp; the seam the suite calls; how many tests and their outcome; for each failure the id, the row and what the code did; and what the owner does next.
