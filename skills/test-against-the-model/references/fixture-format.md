# The fixtures the model generates

`lake exe fixtures` writes, per registered cell, `generated/<cell>-examples.json` and `generated/<cell>.feature`. The JSON is what the code's tests consume; the feature file is the same examples as Given, When, Then for a reader. The rows below are the worked example's, `examples/library/generated/circulation-examples.json`.

```json
{
  "model": "Library/Circulation.lean#<hash>+../../cell-calculus/CellCalculus/Cell.lean#<hash>",
  "examples": [
    { "id": "LOAN-OUT-2 (retry after unknown)",
      "given": [ { "kind": "checkedOut", "key": "k1", "item": "b-1", "onLoan": 1 } ],
      "when":  { "kind": "checkOut", "key": "k1", "item": "b-1" },
      "then":  { "ok": [] } },
    { "id": "LOAN-OUT-3 (refused, card closed)",
      "given": [ { "kind": "cardClosed" } ],
      "when":  { "kind": "checkOut", "key": "k2", "item": "b-2" },
      "then":  { "refused": "cardClosed" } }
  ]
}
```

- `model` is the stamp: the hash of the cell's module and of the calculus's `Cell.lean` at generation. A test suite records the stamp it was written against, so a regenerated fixture set with a new stamp is visible as a change, never a silent one. The example keeps it in `impl/model-stamp.txt` beside the suite.
- `id` is the design's row, the model's value name in camelCase, and the test's name. The parenthesis is the row's note and travels with the id.
- `given` is the cell's history, events in the wire shape, oldest first. The code replays it to a state.
- `when` is the command in the wire shape, serialized by the model's own serializer, so it is exactly what the gateway receives.
- `then` is one of two shapes: `{"ok": [events]}` or `{"refused": reason}`. The events are in order; an empty list means the command was accepted and nothing new happened, which is the idempotent receiver's answer to a retry.

What a test does with one example: replay `given` through the code's fold to a state, hand `when` to the code's decider in that state, and compare the outcome to `then` exactly: the same events in the same order, or the same refusal. A reaction example (`ReactionExample` in the model) has a foreign event in `when` and a list of events in `then` with no refusal branch.
