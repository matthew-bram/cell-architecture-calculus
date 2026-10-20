---
name: replay-a-trace
description: Replay what an implementation did against its model in the cell calculus, so that the code is checked everywhere it ran and not only where the examples looked: traces recorded in the wire shape, one per cell or per run, handed to the project's replay executable, which parses each command with the model's own parse, replays the trace through the cell by the same conformance the model's theorems use, checks a run's shape, every fact under the root's run and every citation earlier, and names the step where the code took a path the model has no edge for; a rejected trace read as a defect in the code or a learning for the design, never as a trace to edit. Use this skill whenever someone asks to replay, check, validate, audit or conform traces, logs, runs, event streams, execution histories, recorded test runs or production output against the model, the design or the spec; whenever a service's recorded behaviour is to be compared with what was modelled beyond its examples; whenever the replay executable rejects a trace and someone asks whether the code or the model is wrong; and whenever a project has a model and running code and no trace yet, even if the words "trace", "conformance", "calculus" or "Lean" are never said. It is stage 6 of the round trip; testing the code against the examples is test-against-the-model, and a change to the model is change-a-model.
---

# Replay a trace

The examples check the code where the design looked. A trace checks it where it ran: in a test, in a staging run, in production. The running code records what it did, each command it was handed and the outcome it produced, in the same wire shape the fixtures use, and the model replays it. The implementation's output is input to the model, and the model is the judge. A trace the model rejects fails at the step where the implementation took a path the model has no edge for, and the executable names that step, what the model expected there and what the code reported.

The verdict is a theorem's, not a second opinion. The executable walks the trace with `Cell.firstRejection`, which the calculus proves is none exactly when `Cell.conforms` holds, the same function the model's own trace theorems use; a run's shape is checked by `Run.firstRejection`, proved against `Run.conforms` the same way. So a trace the executable accepts is one the kernel would accept, and a step it names is one a theorem would refuse.

What this skill does not do is judge which side is wrong. A rejection means the code and the model disagree at a step; whether that is a defect in the code or a learning the design must take is the owner's call, and the answer goes to the code or, through change-a-model, to the design. The trace is never edited to pass.

Paths below are relative to this skill's directory; the package root, two levels up, holds `cell-calculus/` and `examples/`. Read first, every time:

1. `references/trace-format.md`: the two shapes a trace takes, a cell's steps and a run's facts, what each field is and where its names come from, the verdict lines and the exit codes.
2. `../../examples/library/traces/`: the seven traces of the example project, three that conform and four rejected, one of each kind of rejection, and `references/golden/output.txt`, the executable's output on them.
3. `../../examples/library/Replay.lean`, the registration list, `../../examples/library/impl/record_trace.py`, the recorder at the implementation's seam, and `../../cell-calculus/CellCalculus/Replay.lean`, what the executable does with a trace and the two theorems behind it.

## The procedure

### Stage 1: the recording seam

Find where the code can record a command and its outcome in the wire shape: the gateway, the handler, the test harness's log. The recording is the same serialization the fixtures use, so if the code already speaks the wire for the fixtures, a trace is that serialization written out in order. One file per cell per run of the code; a journey across cells is a run file, the root command's envelope and the facts recorded under its correlation from every cell it touched.

Each file should carry the `model` stamp from the fixtures the code was built against, so a trace recorded against another model is said to be, rather than silently compared.

If the code has no seam, because what it decided is not separable from how it stored or sent it, say so: a trace needs the command and the outcome as the model's types see them, and making them visible is the implementation's work.

Acceptance: the seam is named, or its absence reported; a trace file exists for the cell or run in question.

### Stage 2: the checker knows the cell

Read the project's `Replay.lean`. Every cell whose traces are to be checked is one `Replay.register` line, with its module path, and every run shape one `Replay.registerRun` line naming its command, event and subject types. Registration needs `JsonDecode` instances for the cell's wire command, its events and its refusals, beside the `JsonEncode` instances the fixtures already use, and for a run the project's principal and subject; the envelopes' own fields are decoded by the calculus. If the cell is not registered, add the line and the instances, in the cell's module, as circulation's are.

Acceptance: `lake build` is green and the cell's or run's name is in `checkers`.

### Stage 3: replay

From the project's directory:

```
lake exe replay <trace.json>...
```

One line per file. `conforms, n steps` is the model agreeing with every step. `rejected at step i: the model expected ..., the trace reported ...` is the first disagreement. `rejected at step i: the command is not understood: ...` is a command the model's parse refuses, an unknown kind or a missing field. For a run, `rejected at fact e ... cites a fact not before it` or `... is recorded under run r, the root's is r'`. `cannot be read` is the file, not the code: the JSON or a field the recorder left out. A warning on standard error says the trace's stamp is not the model's.

The exit code is zero only when every trace named conforms, so a set of known-good traces is a CI step, and a set of known-bad ones is a CI step that must fail, as the example's workflow, `../../.github/workflows/ci.yml`, runs them.

Acceptance: every trace in question has a verdict line.

### Stage 4: read a rejection

For each rejected trace, in the report:

- **Not understood.** The code sent a command the model has no shape for. Either the code's wire is wrong, which is a code defect, or the design has a command the model never got, which goes to the design. Quote the kind or field.
- **Disagreement at a step.** Replay the trace's history up to that step in prose: what had happened, what was asked, what the model says follows, what the code did. Quote the model's expectation and the code's report from the verdict line, and the Decide row of the design the expectation comes from. Then say which of two things it is, as a finding and not a decision: the code disagrees with a row the owner stands by, a code defect with the trace's step as its test; or the row does not say what the running system needs, a learning that goes to the design through change-a-model, where the step becomes an example row with an id.
- **A run's shape.** The code's shell wrote the envelopes wrong: a fact citing one recorded after it, or one from another run. That is the shell, not a decider; say which fact and which field.
- **Cannot be read.** The recorder, not the code; say which field.

Acceptance: every rejection has a paragraph that names the step, both sides, and the design row, and ends with the owner's two options.

### Stage 5: keep the traces

A trace that conformed is kept with the code's tests as a known-good trace, and a trace that found a defect is kept as a known-bad one until the fix lands and it conforms, or as a known-bad one for good if it records a path the model must keep refusing. Both run in CI, the good ones to pass, the bad ones to be rejected.

## What you never do

- Edit, trim or reorder a trace to make it conform. The disagreement is the finding.
- Decide, in a rejected case, that the model is wrong. Report; the owner decides.
- Write a trace by hand from what the code should have done. A trace is what the code did.
- Register a cell with instances that do not invert its encoders. A trace the fixtures' own JSON cannot round-trip is a decoder defect, found when a fixture's `given` and `when` fail to read.

## The report

End with a short report, in prose: the traces replayed and their stamps; the seam they were recorded at; how many conformed; for each rejection, the step, both sides, the design row and the owner's two options; and what the owner does next.
