import Library
/-!
# This project's trace checker

`lake exe replay <trace.json>...` replays every trace named against the
checker its `cell` or `run` field names, prints one line per trace, and
exits non-zero if any is rejected. The checker is `Replay` in the calculus
and is generic over the instances a cell's module gives its types; a new
cell adds one line to `checkers`. Of the traces under `traces/`, four are
the runs `Circulation.lean` and `Envelopes.lean` hold as values, in the wire
shape; two, the stray fact and the command not understood, are written for
the checker alone; and one is what `impl/record_trace.py` records from the
reference implementation.
-/

/-- Every cell and run whose traces the checker accepts. -/
def checkers : List Replay.Registered :=
  [ Replay.register "circulation" "Library/Circulation.lean" circulation
  , Replay.registerRun CirculationCommand BorrowFact (PatronId .stacks) "borrow" "Library/Envelopes.lean" ]

/-- The entry point: check every trace file named on the command line. -/
def main (args : List String) : IO UInt32 :=
  Replay.run checkers "../../cell-calculus/CellCalculus/Cell.lean" args
