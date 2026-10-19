/-!
# A cell as three pure functions

The core of the calculus. Sources: Chassaing's Decider (2021) for `decide`,
`evolve`, `initial` and `isTerminal`; the owner's reaction archetype
`Event => State => Event`; Helland (2012) for the three-valued outcome.
-/

/-- The error side of every gateway's result, `Either[Exception, B]` in the
    owner's notation. It has two shapes and they must never be confused.
    **Refused** is the owner's invariants saying no: deterministic, final,
    and the journey stops at a named outcome. **Unknown** is a timeout or a
    death in the failure window: the effect may or may not have landed. The
    model never produces `unknown`; only the world does. On `unknown` a
    caller may retry with the same idempotency key and may never decide as
    if the effect did not happen. -/
inductive Exception (Reason : Type)
  /-- The owner's invariants said no, with the reason; deterministic and final. -/
  | refused (reason : Reason)
  /-- A timeout or a death in the failure window: the effect may or may not have landed. The world produces it, the model never. -/
  | unknown
  deriving Repr, DecidableEq

/-- A cell: the unit of the architecture, five things, three of them
    functions, all pure. It is Chassaing's Decider with a reaction added and
    the command sink removed. There is no function that returns a command:
    `Event => Command` is not merely forbidden, it is unrepresentable.

    The five type parameters are the cell's **commands**, the **foreign
    events** it subscribes to from other cells, its own **events**, its
    **state**, and its **refusal** reasons. -/
structure Cell (Command ForeignEvent Event State Refusal : Type) where
  /-- The state before any event. -/
  initial    : State
  /-- `Command => State => Event`. Given a command and the current state,
      either a refusal with its reason, or the events that record the
      decision. Pure: it reads nothing and changes nothing. -/
  decide     : Command → State → Except Refusal (List Event)
  /-- `Event => State => Event`. A reaction to another cell's fact, using
      this cell's state, emitting this cell's facts. Never a command. -/
  react      : ForeignEvent → State → List Event
  /-- The fold. State is nothing but the fold of the cell's own events,
      starting from `initial`. -/
  evolve     : State → Event → State
  /-- Whether the state is a sink of the journey: nothing more will happen. -/
  isTerminal : State → Bool

namespace Cell

variable {Command ForeignEvent Event State Refusal : Type}

/-- State as the fold of history: replay every event from the initial state. -/
def replay (cell : Cell Command ForeignEvent Event State Refusal) (history : List Event) : State :=
  history.foldl cell.evolve cell.initial

/-- Handle a command against a history: fold the history, then decide. -/
def handle (cell : Cell Command ForeignEvent Event State Refusal) (history : List Event)
    (command : Command) : Except Refusal (List Event) :=
  cell.decide command (cell.replay history)

/-- Handle a foreign event against a history: fold the history, then react. -/
def handleForeign (cell : Cell Command ForeignEvent Event State Refusal) (history : List Event)
    (fact : ForeignEvent) : List Event :=
  cell.react fact (cell.replay history)

/-- Replay splits over history: the state after `h ++ h'` is the state after
    `h` evolved by `h'`. This is what makes a snapshot sound, for every cell
    and every history. -/
theorem replay_append (cell : Cell Command ForeignEvent Event State Refusal)
    (h h' : List Event) :
    cell.replay (h ++ h') = h'.foldl cell.evolve (cell.replay h) := by
  simp [replay, List.foldl_append]

end Cell

/-- Specification by example, as a type. One example is one row in a design
    document, one theorem in the model and one test in the code, under one
    `id`. `given` is this cell's history, `when` the command, `expect` the
    refusal or the events the design says must follow. -/
structure Example (Command Event Refusal : Type) where
  /-- The row's id in the design, the theorem's name in the model and the test's name in the code, such as "LOAN-OUT-1". -/
  id     : String
  /-- This cell's history before the command, its own events oldest first; empty for a cell that has seen nothing. -/
  given  : List Event
  /-- The command the example hands the cell. -/
  when   : Command
  /-- What the design says must follow: the refusal, or the events in order, an empty list meaning the command was accepted and nothing new happened. -/
  expect : Except Refusal (List Event)

/-- Whether an example holds of a cell: replay the given history, decide the
    command, compare with what was expected. A Boolean the kernel evaluates. -/
def Example.holds {Command ForeignEvent Event State Refusal : Type} [BEq Event] [BEq Refusal]
    (cell : Cell Command ForeignEvent Event State Refusal)
    (example_ : Example Command Event Refusal) : Bool :=
  match cell.handle example_.given example_.when, example_.expect with
  | .ok events,     .ok expected     => events == expected
  | .error reason,  .error expected  => reason == expected
  | _, _ => false

/-- A reaction example: given this cell's history, when a foreign fact
    arrives, then these facts are emitted. -/
structure ReactionExample (ForeignEvent Event : Type) where
  /-- The row's id in the design, the theorem's name in the model and the test's name in the code, such as "NOTICE-WARN-1". -/
  id     : String
  /-- This cell's history before the fact arrives, its own events oldest first. -/
  given  : List Event
  /-- The foreign fact that arrives. -/
  when   : ForeignEvent
  /-- The facts the design says the cell emits in reaction, in order; empty when it stays quiet. -/
  expect : List Event

/-- Whether a reaction example holds of a cell: replay the given history, react to the fact, compare with what was expected. -/
def ReactionExample.holds {Command ForeignEvent Event State Refusal : Type} [BEq Event]
    (cell : Cell Command ForeignEvent Event State Refusal)
    (example_ : ReactionExample ForeignEvent Event) : Bool :=
  cell.handleForeign example_.given example_.when == example_.expect

/-- What a saga persists before its first remote call: the key it minted and
    the command it intends, so that after a death it can retry the same
    intent with the same key. -/
structure Intent (Command : Type) where
  /-- The idempotency key the saga minted before its first remote call; a string the receiver will see again on a retry. -/
  key     : String
  /-- The command the saga intends to send, retried unchanged after a death. -/
  command : Command
  deriving Repr

/-- Lift a cell's local result onto the wire, where `unknown` can also
    appear. The model's refusals become `refused`; nothing the model does
    becomes `unknown`. -/
def liftToWire {Refusal Value : Type} (local_ : Except Refusal Value) :
    Except (Exception Refusal) Value :=
  match local_ with
  | .ok value => .ok value
  | .error reason => .error (.refused reason)

/-- The model never produces `unknown`; only the world does. -/
theorem model_never_unknown {Refusal Value : Type} (result : Except Refusal Value) :
    liftToWire result ≠ .error .unknown := by
  cases result <;> simp [liftToWire]

/-- One step of what an implementation, or a test run, actually did against
    one cell: the command it was given and the outcome it reported. -/
structure TraceStep (Command Event Refusal : Type) where
  /-- The command the implementation was given at this step. -/
  command : Command
  /-- What the implementation reported: the refusal, or the events it recorded. -/
  outcome : Except Refusal (List Event)

/-- Trace conformance: replay a trace through the model and check each step.
    The implementation's output is input to the model, and the model is the
    judge. A trace the model rejects fails at the step where the
    implementation took a path the model has no edge for. -/
def Cell.conforms {Command ForeignEvent Event State Refusal : Type} [BEq Event] [BEq Refusal]
    (cell : Cell Command ForeignEvent Event State Refusal) :
    List (TraceStep Command Event Refusal) → List Event → Bool
  | [], _ => true
  | step :: rest, history =>
    match cell.handle history step.command, step.outcome with
    | .ok events,    .ok reported    => events == reported && cell.conforms rest (history ++ events)
    | .error reason, .error reported => reason == reported && cell.conforms rest history
    | _, _ => false
