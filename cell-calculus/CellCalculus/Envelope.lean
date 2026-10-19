import CellCalculus.Architecture
import CellCalculus.Cell
import CellCalculus.Journey
/-!
# The envelopes

What every command and every event carries besides its payload. No
property-bag headers: an envelope is a structure with fixed, typed fields,
and a cell can read only the fields the type names. The fold never sees an
envelope; the shell wraps what a decider emits.
-/

/-- An event's own ID, minted by its publisher and unique in that cell's history. -/
structure EventId where
  /-- The ID as the publisher minted it; a string such as "e1". -/
  raw : String
  deriving DecidableEq, Repr

/-- A journey run's ID: the same on every command and event in one run. -/
structure RunId where
  /-- The run's ID as minted when the run began; a string such as "run-1". -/
  raw : String
  deriving DecidableEq, Repr

/-- A wall-clock reading, in milliseconds. Two of them appear on every
    trace, what the sender thought the time was and when the publisher
    recorded the fact, because the two disagree and the disagreement is
    where retries land (Lamport 1978). -/
structure Instant where
  /-- Milliseconds since the epoch, such as 0. -/
  ms : Nat
  deriving DecidableEq, Repr

/-- The version of an event's schema: the upcaster's input. -/
structure SchemaVersion where
  /-- The version number, 1 for the first schema published. -/
  n : Nat
  deriving DecidableEq, Repr

/-- The idempotency key every command carries. **Minted** by a device or a
    partner before the first remote call and persisted with the intent.
    **Derived** from the causing event when a cell inside the system issues
    the command, so that a retry derives the same key without remembering
    anything. -/
inductive IdempotencyKey
  /-- Minted by a device or a partner before the first remote call; a string such as "k1". -/
  | minted (raw : String)
  /-- Derived by the cell that issued the command, from its own name and the fact it follows from, so that a retry derives the same key. -/
  | derived (issuer : String) (cause : EventId)
  deriving DecidableEq, Repr

/-- A derived key names its issuer and its cause: two commands with the same
    derived key were issued by the same cell for the same fact. -/
theorem derived_injective (issuer issuer' : String) (cause cause' : EventId)
    (h : IdempotencyKey.derived issuer cause = IdempotencyKey.derived issuer' cause') :
    issuer = issuer' ∧ cause = cause' := by
  cases h; exact ⟨rfl, rfl⟩

/-- What a fact is a reaction to: the command that was decided, or the
    foreign fact that was reacted to. This is the edge of the journey's DAG. -/
inductive CausationId
  /-- The fact was decided on this command, named by its key. -/
  | ofCommand (key : IdempotencyKey)
  /-- The fact was a reaction to this foreign fact. -/
  | ofEvent (id : EventId)
  deriving DecidableEq, Repr

variable [Architecture]

/-- Who is acting, carried on the command and never looked up inside
    `decide`: what the gateway established about the sender, as a sum over
    the five kinds of sender any system has, so that a decider's actor
    branch is a `match` the kernel checks is total. A `principal` is the
    project's own type; the other four are the system acting on itself, a
    schedule, an outside party, and whoever runs the system. -/
inductive Actor
  /-- A human or system actor in the project's own terms, as the identity capability answered. -/
  | principal (who : Architecture.Principal)
  /-- A cell of the system acting on its own, named: the sender of a command by succession. -/
  | policy (cell : String)
  /-- The schedule: a clock-driven root. -/
  | timer
  /-- An outside party, named, such as an aggregator. -/
  | partner (name : String)
  /-- Whoever runs the system. -/
  | operator
  deriving DecidableEq, Repr

/-- The command envelope. The sender fills every field; the gateway checks
    the actor first. -/
structure CommandEnvelope (Payload : Type) where
  /-- Who is acting. -/
  actor       : Actor
  /-- The idempotent receiver's key. -/
  key         : IdempotencyKey
  /-- The one fact this command succeeds, or `none` for an external root. -/
  causation   : Option EventId
  /-- The journey run. -/
  correlation : RunId
  /-- What time the sender thought it was. A decider may read it and never
      fetch a clock. -/
  issuedAt    : Instant
  /-- The cell's own command. -/
  payload     : Payload
  deriving Repr

/-- The event envelope. The publisher's shell fills every field from the
    command or the foreign fact in hand; the fold sees only the payload.
    `Subject` is what the event is about, the one identifier its record is
    keyed by: a bounded ID where the project has trust boundaries (see
    `Boundaries`), a plain ID where it does not, `Unit` where there is
    nothing to say. No universal theorem reads it; the scrub does. -/
structure EventEnvelope (Payload Subject : Type) where
  /-- Minted by the publisher, unique in its history. -/
  id          : EventId
  /-- The command or the fact this is a reaction to. -/
  causation   : CausationId
  /-- Copied from the cause. -/
  correlation : RunId
  /-- The upcaster's input. -/
  version     : SchemaVersion
  /-- Exactly one subject, of the kind this envelope's type names. -/
  subject     : Subject
  /-- When the publisher recorded it, which is not when it happened. -/
  recordedAt  : Instant
  /-- The cell's own event. -/
  payload     : Payload
  deriving Repr

/-! ## The actor check is the first branch of every decider -/

/-- What a gateway can refuse once the envelope is in: the actor, before the
    decider is consulted, or the domain, from the decider. -/
inductive GatedRefusal (Refusal : Type)
  /-- The actor may not issue this command; the decider was not consulted. -/
  | wrongActor (actor : Actor)
  /-- The decider refused, with the cell's own reason. -/
  | domain (reason : Refusal)
  deriving Repr, DecidableEq

/-- A cell's actor policy: may this actor issue this command? One row of the
    design's Decide table per answer. -/
def ActorPolicy (Command : Type) := Actor → Command → Bool

/-- Lift a cell to the envelope. The actor check becomes the first branch of
    its decider, and the inner decider never sees a command from an actor
    the policy refused. The reaction and the fold are untouched. -/
def Cell.gated {Command ForeignEvent Event State Refusal : Type}
    (cell : Cell Command ForeignEvent Event State Refusal) (may : ActorPolicy Command) :
    Cell (CommandEnvelope Command) ForeignEvent Event State (GatedRefusal Refusal) where
  initial := cell.initial
  decide := fun envelope state =>
    if may envelope.actor envelope.payload then
      match cell.decide envelope.payload state with
      | .ok events    => .ok events
      | .error reason => .error (.domain reason)
    else .error (.wrongActor envelope.actor)
  react      := cell.react
  evolve     := cell.evolve
  isTerminal := cell.isTerminal

/-- A refused actor gets no further: the inner decider is not consulted. -/
theorem gated_refusesActor {Command ForeignEvent Event State Refusal : Type}
    (cell : Cell Command ForeignEvent Event State Refusal) (may : ActorPolicy Command)
    (envelope : CommandEnvelope Command) (state : State)
    (h : may envelope.actor envelope.payload = false) :
    (cell.gated may).decide envelope state = .error (.wrongActor envelope.actor) := by
  simp [Cell.gated, h]

/-- An allowed actor gets exactly the inner decision, with a domain refusal
    relabeled. -/
theorem gated_delegates {Command ForeignEvent Event State Refusal : Type}
    (cell : Cell Command ForeignEvent Event State Refusal) (may : ActorPolicy Command)
    (envelope : CommandEnvelope Command) (state : State)
    (h : may envelope.actor envelope.payload = true) :
    (cell.gated may).decide envelope state
      = (cell.decide envelope.payload state).mapError GatedRefusal.domain := by
  simp only [Cell.gated, h, ite_true]
  cases cell.decide envelope.payload state <;> rfl

/-- The fold is untouched: the gated cell replays to the same state. -/
theorem gated_replay {Command ForeignEvent Event State Refusal : Type}
    (cell : Cell Command ForeignEvent Event State Refusal) (may : ActorPolicy Command)
    (history : List Event) : (cell.gated may).replay history = cell.replay history := rfl

/-! ## The per-run pass: causation is the DAG -/

/-- A journey run as recorded: the root command and the events recorded
    under its correlation, from every cell the run touched. -/
structure Run (Command Event Subject : Type) where
  /-- The command envelope that began the run. -/
  root   : CommandEnvelope Command
  /-- The facts recorded under the root's correlation, from every cell the run touched, in the order recorded. -/
  events : List (EventEnvelope Event Subject)

/-- The index of an event ID in a list, or the list's length when absent,
    which no node may wait on. -/
def indexOf (id : EventId) : List EventId → Nat → Nat
  | [], n => n
  | x :: xs, n => if x == id then n else indexOf id xs (n + 1)

/-- Turn a run's events into step nodes: each event waits on the event it
    cites, or on nothing when it cites the root command. -/
def Run.toNodes {Command Event Subject : Type} (run : Run Command Event Subject) :
    List Journey.Node :=
  let ids := run.events.map (·.id)
  run.events.map fun event =>
    { name  := event.id.raw
    , needs := match event.causation with
        | .ofCommand key => if key == run.root.key then [] else [ids.length]
        | .ofEvent id    => [indexOf id ids 0] }

/-- Every event in the run carries the root's correlation. -/
def Run.sameRun {Command Event Subject : Type} (run : Run Command Event Subject) : Bool :=
  run.events.all (·.correlation == run.root.correlation)

/-- A run conforms when it is one run and its causation graph satisfies the
    same `nodesOk` rule the compiled journey terms are held to. Checkable
    without replaying any cell. -/
def Run.conforms {Command Event Subject : Type} (run : Run Command Event Subject) : Bool :=
  run.sameRun && Journey.nodesOk 0 run.toNodes

/-- What the shell does with a decider's output: mint the IDs, stamp the
    command's key as the causation, copy the correlation. -/
def envelope {Command Event Subject : Type}
    (command : CommandEnvelope Command) (subject : Subject) (now : Instant)
    (mint : Nat → EventId) : List Event → Nat → List (EventEnvelope Event Subject)
  | [], _ => []
  | event :: rest, n =>
      { id := mint n, causation := .ofCommand command.key, correlation := command.correlation,
        version := ⟨1⟩, subject := subject, recordedAt := now, payload := event }
        :: envelope command subject now mint rest (n + 1)

theorem envelope_stamps {Command Event Subject : Type}
    (command : CommandEnvelope Command) (subject : Subject) (now : Instant)
    (mint : Nat → EventId) (events : List Event) (n : Nat) :
    ∀ e ∈ envelope command subject now mint events n,
      e.causation = .ofCommand command.key ∧ e.correlation = command.correlation := by
  induction events generalizing n with
  | nil => intro e h; simp [envelope] at h
  | cons event rest ih =>
    intro e h
    simp only [envelope, List.mem_cons] at h
    rcases h with rfl | h
    · exact ⟨rfl, rfl⟩
    · exact ih n.succ e h

/-- What a cell publishes on a command conforms by construction: for every
    command, subject, clock reading, minting function and emitted list.
    The first step of every journey is a DAG before anything is checked. -/
theorem envelope_conforms {Command Event Subject : Type}
    (command : CommandEnvelope Command) (subject : Subject) (now : Instant)
    (mint : Nat → EventId) (events : List Event) :
    (Run.mk command (envelope command subject now mint events 0)).conforms = true := by
  simp only [Run.conforms, Bool.and_eq_true]
  constructor
  · simp only [Run.sameRun, List.all_eq_true]
    intro e he
    have := (envelope_stamps command subject now mint events 0 e he).2
    simp [this]
  · apply Journey.nodesOk_of_noNeeds
    intro node hnode
    simp only [Run.toNodes, List.mem_map] at hnode
    obtain ⟨e, he, rfl⟩ := hnode
    have := (envelope_stamps command subject now mint events 0 e he).1
    simp [this]

/-! ## A policy as rules, and the three things a rule set must satisfy

A policy written as permits and forbids, the way Cedar writes one. The
three theorems are Cedar's: a forbid overrides every permit, a permit is
required for anything to pass, and an empty set of permits denies
everything. Two more say the rules are a set: their order and their
duplicates do not matter. -/

/-- A permit or a forbid: does this rule match this actor and command? -/
abbrev Rule (Command : Type) := Actor → Command → Bool

/-- A policy as permits and forbids, the way Cedar writes one. -/
structure RuleSet (Command : Type) where
  /-- The rules any one of which must match for an actor's command to pass. -/
  permits : List (Rule Command)
  /-- The rules none of which may match; a forbid overrides every permit. -/
  forbids : List (Rule Command)

/-- The policy a rule set denotes: some permit matches and no forbid does. -/
def RuleSet.policy {Command : Type} (rules : RuleSet Command) : ActorPolicy Command :=
  fun actor command =>
    rules.permits.any (fun rule => rule actor command)
      && !rules.forbids.any (fun rule => rule actor command)

/-- A forbid overrides every permit. -/
theorem forbid_overrides {Command : Type} (rules : RuleSet Command) (actor : Actor) (command : Command)
    (h : rules.forbids.any (fun rule => rule actor command) = true) :
    rules.policy actor command = false := by
  simp [RuleSet.policy, h]

/-- An explicit permit is required: nothing passes without one. -/
theorem permit_required {Command : Type} (rules : RuleSet Command) (actor : Actor) (command : Command)
    (h : rules.policy actor command = true) :
    rules.permits.any (fun rule => rule actor command) = true := by
  simp only [RuleSet.policy, Bool.and_eq_true] at h
  exact h.1

/-- Default deny: with no permits, everything is refused. -/
theorem default_deny {Command : Type} (rules : RuleSet Command) (actor : Actor) (command : Command)
    (h : rules.permits = []) : rules.policy actor command = false := by
  simp [RuleSet.policy, h]

/-- The order of the rules does not matter. -/
theorem order_independent {Command : Type} (p q f : List (Rule Command)) (actor : Actor) (command : Command) :
    (RuleSet.mk (p ++ q) f).policy actor command = (RuleSet.mk (q ++ p) f).policy actor command := by
  simp [RuleSet.policy, List.any_append, Bool.or_comm]

/-- Nor do duplicates. -/
theorem duplicate_independent {Command : Type} (p f : List (Rule Command)) (actor : Actor) (command : Command) :
    (RuleSet.mk (p ++ p) f).policy actor command = (RuleSet.mk p f).policy actor command := by
  simp [RuleSet.policy, List.any_append]

/-- And at the gate: a decision that is not an actor refusal was permitted. -/
theorem gated_permitRequired {Command ForeignEvent Event State Refusal : Type}
    (cell : Cell Command ForeignEvent Event State Refusal) (may : ActorPolicy Command)
    (envelope : CommandEnvelope Command) (state : State)
    (hne : (cell.gated may).decide envelope state ≠ .error (.wrongActor envelope.actor)) :
    may envelope.actor envelope.payload = true := by
  cases hm : may envelope.actor envelope.payload with
  | true => rfl
  | false => exact absurd (gated_refusesActor cell may envelope state hm) hne
