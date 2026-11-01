# cell-architecture-calculus

A strongly typed approach to validating a cell-based architecture, in Lean 4, with functional theorems. A cell, in the sense of the [WSO2 cell-based reference architecture](https://github.com/wso2/reference-architecture/blob/master/reference-architecture-cell-based.md), is a self-contained unit with its own record and a gateway as the only way in. The calculus says what is inside one: three pure functions, a fold, and a terminal predicate. From that shape the rest follows. Journeys across cells are terms that compile to directed acyclic graphs. Every example in a design is a theorem in the model and a test in the code, under one id. The running code's traces are replayed into the model, and the model is the judge.

The repository holds the generic calculus as one Lean package with no dependencies, a worked example that carries the whole round trip, the documents that state the method, the two scripts that gate a build, and nine skills, one per step of the lifecycle an agent leads or prepares, each written and evaluated against the example.

## The case for the method

Two papers at the root of the repository make the argument, for two readers.

| Paper | For whom | What it is |
| --- | --- | --- |
| [White paper](white-paper.md) | Architects and engineers | The hypothesis, the prior art each shape stands on, the calculus shape by shape with its theorems, the method as documents and a round trip, the evidence from the worked example with every number taken from the build, the ten places the method can fail with a proposal for each, the seven problems that had to be decided with what each leaves open, and a call to contribute |
| [Executive summary](executive-summary.md) | Technology leaders | The problem from the leader's seat, what the method changes for an organization, what it removes from the daily work, what it costs, what it does not do, the evidence in one table, and how to start with a one-journey pilot |

## In twenty lines

A cell decides on commands, reacts to other cells' facts, and folds its own facts into its state. No function returns a command, so one cell cannot quietly trigger another: that wiring cannot be written.

```lean
structure Cell (Command ForeignEvent Event State Refusal : Type) where
  initial    : State
  decide     : Command → State → Except Refusal (List Event)   -- Command => State => Event
  react      : ForeignEvent → State → List Event              -- Event => State => Event
  evolve     : State → Event → State                          -- the fold
  isTerminal : State → Bool
```

An example is a row in a design, a value in the model and a test in the code. The kernel evaluates whether it holds.

```lean
/-- A retry after the answer was lost: the same key again, and nothing new is booked. -/
def loanOut2 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-OUT-2 (retry after unknown)", given := [.checkedOut "k1" "b-1" 1],
    when := .checkOut "k1" "b-1", expect := .ok [] }

theorem loanOut2_holds : loanOut2.holds circulation = true := by decide
```

The same example, rendered from that value and never written by hand, is what a reviewer reads and what the implementation's test suite runs:

```gherkin
Scenario: LOAN-OUT-2 (retry after unknown)
  Given copy b-1 was checked out under key k1, 1 on loan
  When a checkout arrives with key k1 for copy b-1
  Then nothing happens
```
