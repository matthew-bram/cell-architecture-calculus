# The acceptance checks, by stage

Run from the project package's directory, the one with `lakefile.toml` that requires `cell-calculus`. `Package` below is that package's name, `Library` in the worked example, and `tools` is the project's own `tools/` directory, which the start script copies in; from the example project it is `../../tools`. Set the toolchain on the path once:

```
export PATH="$HOME/.elan/bin:$PATH"
```

| Stage | Check | Command | Pass means |
| --- | --- | --- | --- |
| 1 | Every table row is a constructor | read the design beside the types | No row without a constructor, no constructor without a row |
| 2 | The shape compiles, on its own | `lake build Package.X` | Success, with `sorry` warnings only in `decide` and `react`; the module is not yet imported from the root |
| 3 | The bodies and the data, in the whole package | `lake build` | No `sorry`; no warnings; every universal theorem proved; the root now imports the module |
| 3 | The wire round-trips | the `WireCodec` instance | The instance exists, so the law is proved |
| 4 | Every example holds | `lake build` | Every `_holds` theorem by `decide` |
| 4 | Coverage | `lake build` | `coversCommands`, `coversEvents`, `coversRefusals` over the example list, each `= true` by `decide` |
| 4 | The views render | `lake exe fixtures` | Writes `generated/<cell>.feature` and `generated/<cell>-examples.json` for the registered cell |
| 4 | The checker knows the cell | `lake build` | The cell is one line in `Replay.lean`'s `checkers`, with its `JsonDecode` instances |
| 4 | The gate holds, with the cell's own mutants | `python3 tools/mutants.py mutants.json` | Every mutant killed, including the three to six added for the new cell; a survivor is reported as a missing example row |
| 4 | The review line | `python3 tools/review-check.py Package/Governance.lean <design root>` | Warns "unreviewed" until the owner signs; never fails |

A check that fails is reported with the table and row, or the theorem and the goal that remained. The module is left in the state that produced the report, with the failing theorem present, so the reader can see it.

## Reading a failure

- `Tactic decide proved that the proposition ... is false`: an example disagrees with the decider, or coverage found a kind no example reaches. Read which, and report the row or the kind.
- `unsolved goals` on a universal theorem: the statement may be right and the proof too weak, or the statement wrong. Report the goal verbatim; do not change the statement.
- `Fields missing`: a State or envelope field the design did not supply.
- `Type mismatch` naming two boundaries: an ID crossed one without the scrub.
- `fail to show termination`: a journey loops; the design's steps re-enter an earlier step.
- `invalid field`: a decider read something the type does not name, usually a header or a query answer that should be an input.
- `unknown identifier` or `unknown constant` for a name the generic package has, such as `ProjectHeader`: the project's pinned calculus predates it; see `inputRev` in `lake-manifest.json`, model with the release the project has, and report the shape the newer release would give.
- `INTERNAL PANIC: executed 'sorry'` from `lake exe fixtures`: a stage-two module is imported from the root; take the import out until stage three passes.
