# The traces the model replays

`lake exe replay <file>...` reads each file as JSON, looks for a `cell` or a `run` field, hands the file to the checker registered under that name in the project's `Replay.lean`, and prints one verdict line per file. Two shapes. The examples are the worked example's, `examples/library/traces/`.

## A cell's trace

```json
{
  "cell": "circulation",
  "model": "Library/Circulation.lean#…+../../cell-calculus/CellCalculus/Cell.lean#…",
  "history": [ { "kind": "checkedOut", "key": "k0", "item": "b-0", "onLoan": 1 } ],
  "steps": [
    { "command": { "kind": "checkOut", "key": "a", "item": "b-1" },
      "outcome": { "ok": [ { "kind": "checkedOut", "key": "a", "item": "b-1", "onLoan": 2 } ] } },
    { "command": { "kind": "checkOut", "key": "a", "item": "b-1" },
      "outcome": { "ok": [] } },
    { "command": { "kind": "closeCard" },
      "outcome": { "ok": [ { "kind": "cardClosed" } ] } },
    { "command": { "kind": "checkOut", "key": "c", "item": "b-2" },
      "outcome": { "refused": "cardClosed" } }
  ]
}
```

- `cell` is the name the project registered the cell under, as the fixtures name it.
- `model`, optional, is the stamp of the fixtures the code was built against, copied from `generated/<cell>-examples.json`. When it differs from the model the checker was built from, the checker warns on standard error and replays anyway.
- `history`, optional, is the cell's history before the first step, events in the wire shape, oldest first; absent means the cell started from its initial state.
- `steps` are what the code did, in order. `command` is in the wire shape, exactly what the gateway received, and is parsed by the model's own `parse`; `outcome` is `{"ok": [events]}` or `{"refused": reason}`, as the fixtures' `then`. An empty `ok` is the command accepted and nothing new happening, the idempotent receiver's answer to a retry.

The checker folds each accepted step's events into the history before the next, as `Cell.conforms` does.

## A run's trace

```json
{
  "run": "borrow",
  "root": {
    "actor": { "principal": { "card": "C-1041", "role": "member" } },
    "key": { "minted": "k5" },
    "causation": null,
    "correlation": "run-1",
    "issuedAt": 0,
    "payload": { "kind": "checkOut", "key": "k5", "item": "b-5" }
  },
  "events": [
    { "id": "e1", "causation": { "ofCommand": { "minted": "k5" } }, "correlation": "run-1",
      "version": 1, "subject": "P-7", "recordedAt": 0,
      "payload": { "kind": "checkedOut", "key": "k5", "item": "b-5", "onLoan": 5 } },
    { "id": "e2", "causation": { "ofEvent": "e1" }, "correlation": "run-1",
      "version": 1, "subject": "P-7", "recordedAt": 0,
      "payload": { "kind": "limitWarning", "item": "b-5", "onLoan": 5 } }
  ]
}
```

- `run` is the name the project registered the run shape under, with its command, event and subject types.
- `root` is the command envelope that started the run. `actor` is `{"principal": …}` in the project's own shape, `{"policy": "<cell>"}`, `{"partner": "<name>"}`, `"timer"` or `"operator"`. `key` is `{"minted": "…"}` or `{"derived": {"issuer": "…", "cause": "<event id>"}}`. `causation` is an event id or `null` for an external root. `payload` is the command in the wire shape.
- `events` are the facts recorded under the run, from every cell it touched, in the order recorded. `causation` is `{"ofCommand": key}` or `{"ofEvent": "<event id>"}`. `subject` is in the project's shape for the subject type the run was registered with, here the patron token the stacks know the member by. `payload` is the event in the wire shape; a run across cells decodes it by its kind.

The checker tests the shape only, without replaying any cell: every fact carries the root's correlation, and every fact cites the root's key or a fact recorded before it. That is `Run.conforms`.

## The verdicts

| line | meaning |
| --- | --- |
| `<file>: conforms, n steps` | the model agrees with every step, or every fact of the run is in place |
| `<file>: rejected at step i: the model expected …, the trace reported …` | the first step where the code's outcome is not the model's; the sentences are the project's `Describe` instances, the ones the Gherkin uses |
| `<file>: rejected at step i: the command is not understood: unknown kind "…"` or `missing field "…"` | the model's parse refused the command, the loss list of the wire |
| `<file>: rejected at fact e at index i cites a fact not before it: [j]` | the run's causation is not a DAG |
| `<file>: rejected at fact e is recorded under run r, the root's is r'` | a fact from another run |
| `<file>: cannot be read: …` | the JSON, a missing field or an unregistered name; the recorder's defect, not the code's |
| `<file>: warning: recorded against …, the model is …` on standard error | the stamp differs; the verdict stands, the comparison is across models |

Exit code 0 when every file conforms, 1 when any is rejected or cannot be read, 2 with no file named.

## Where the names come from

The wire shapes of commands, events and refusals are the project's `JsonEncode` instances, which the fixtures are rendered with, inverted by its `JsonDecode` instances; the envelopes' fields are the calculus's `CommandEnvelope` and `EventEnvelope`, decoded once for every project in `CellCalculus/Replay.lean`. A trace is therefore readable by the checker exactly when the fixtures are, and a recorder that writes the fixtures' shapes writes traces. The example's recorder is `examples/library/impl/record_trace.py`.
