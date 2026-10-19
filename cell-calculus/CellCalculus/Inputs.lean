import CellCalculus.Envelope
/-!
# Queries and time as inputs, never calls

`decide` is pure, and a decider may need another cell's answer or the
date. Functional core, imperative shell: the shell gathers every query
answer and the clock reading before it calls `decide` and hands them over
as one argument. A decider that reaches for a clock or a gateway is
rejected at the type, because `decide` returns `Except` and not `IO`.
-/

/-- A query on the owning cell: a pure read of its state, no events, no
    obligation created. -/
abbrev Query (State Answer : Type) := State → Answer

/-- An answer stamped with the owner's version when it was read, so that a
    decision made on it records what it was made on, and the owner can
    refuse the resulting command if it has moved on since. -/
structure Answer (Value : Type) where
  /-- The answer itself. -/
  value : Value
  /-- The owner's version when the answer was read, such as 3. -/
  asOf  : Nat
  deriving Repr, DecidableEq

/-! ## The clock is a cell -/

/-- A tick, with the reading the timer saw. -/
inductive ClockCommand
  /-- A tick with the reading the timer saw. -/
  | tick (now : Instant)
  deriving Repr, DecidableEq

/-- The clock's fact: time advanced to this reading. A timer-driven journey's
    root is one of these. -/
inductive ClockEvent
  /-- Time advanced to this reading. -/
  | ticked (now : Instant)
  deriving Repr, DecidableEq, BEq

/-- The clock's state: the last reading it ticked to. -/
structure ClockState where
  /-- The last reading; the zero instant before any tick. -/
  last : Instant
  deriving Repr

/-- The clock cell. A tick that does not advance the clock is nothing new, so
    the clock is an idempotent receiver like every other cell. -/
def clock : Cell ClockCommand Unit ClockEvent ClockState Empty where
  initial := { last := ⟨0⟩ }
  decide | .tick t, s => if s.last.ms < t.ms then .ok [.ticked t] else .ok []
  react := fun _ _ => []
  evolve | _, .ticked t => { last := t }
  isTerminal := fun _ => false

/-- Time never runs backwards in the clock's history: a late or repeated
    tick emits nothing, for every state and every reading. -/
theorem tick_monotone (s : ClockState) (t : Instant) (h : t.ms ≤ s.last.ms) :
    clock.decide (.tick t) s = .ok [] := by
  simp [clock, Nat.not_lt.mpr h]

variable [Architecture]

/-- What the shell hands a decider: the command, the answers it gathered,
    and the clock it read. A cell that reads inputs is a cell whose command
    type is this, so an example carries the inputs in its When and a trace
    records them, and a replay is exact. -/
structure Inputs (Command Answers : Type) where
  /-- The command, in its envelope. -/
  command : CommandEnvelope Command
  /-- The answers the shell gathered before calling the decider, in the project's record for the cell. -/
  answers : Answers
  /-- The clock reading the shell took before calling the decider. -/
  now     : Instant
  deriving Repr
