import CellCalculus.Envelope
/-!
# Where a fact may become a command

The sink `Event => Command` is unrepresentable inside a cell. It exists in
exactly one place: at a journey boundary, as succession. A journey ends
with a fact; the fabric lifts the fact into a command to the one cell that
subscribes to it as a root, mechanically; that cell is a policy cell, and
its `decide` is the one place a proposal becomes a downstream command,
with every branch naming its rung.
-/

/-- The ladder, from the management plane: how much a policy cell may do on
    its own with a proposal. -/
inductive Rung
  /-- Record what would have happened; issue nothing. -/
  | shadow
  /-- Hold for a person. -/
  | review
  /-- Issue. -/
  | autonomous
  deriving Repr, DecidableEq

/-- The policy cell's commands: a proposal arriving by succession, a
    person's approval of a held one, and the rung set by a release. -/
inductive PolicyCommand (Proposal : Type)
  /-- A proposal arriving by succession from the fact it follows. -/
  | propose (proposal : Proposal)
  /-- A person's approval of a held proposal. -/
  | approve (proposal : Proposal)
  /-- The rung set by a release. -/
  | setRung (rung : Rung)
  deriving Repr, DecidableEq

/-- The policy cell's facts. `issued` is the one the shell turns into the
    downstream command. -/
inductive PolicyEvent (Proposal : Type)
  /-- In shadow: recorded, nothing issued. -/
  | shadowed (proposal : Proposal)
  /-- In review: held for a person. -/
  | held (proposal : Proposal)
  /-- Issued; the shell turns it into the downstream command. -/
  | issued (proposal : Proposal)
  /-- The rung changed. -/
  | rungSet (rung : Rung)
  deriving Repr, BEq, DecidableEq

/-- Why the policy cell says no. -/
inductive PolicyRefusal
  /-- The approval names a proposal the cell never held. -/
  | notHeld
  deriving Repr, DecidableEq, BEq

/-- The rung, and the proposals held for a person. -/
structure PolicyState (Proposal : Type) where
  /-- The rung the cell is on; shadow before any is set. -/
  rung : Rung
  /-- The proposals held for a person, newest first. -/
  held : List Proposal
  deriving Repr

/-- The policy cell. Every branch of `decide` names its rung. -/
def policy (Proposal : Type) [BEq Proposal] :
    Cell (PolicyCommand Proposal) Unit (PolicyEvent Proposal) (PolicyState Proposal) PolicyRefusal where
  initial := { rung := .shadow, held := [] }
  decide
    | .propose p, s => match s.rung with
        | .shadow     => .ok [.shadowed p]
        | .review     => .ok [.held p]
        | .autonomous => .ok [.issued p]
    | .approve p, s => if s.held.contains p then .ok [.issued p] else .error .notHeld
    | .setRung r, _ => .ok [.rungSet r]
  react := fun _ _ => []
  evolve
    | s, .held p     => { s with held := p :: s.held }
    | s, .issued p   => { s with held := s.held.filter (· != p) }
    | s, .rungSet r  => { s with rung := r }
    | s, .shadowed _ => s
  isTerminal := fun _ => false

/-- Whether a fact is an issue. -/
def PolicyEvent.isIssued {Proposal : Type} : PolicyEvent Proposal → Bool
  | .issued _ => true
  | _ => false

/-- In shadow, a proposal never issues, whatever it proposes. -/
theorem shadow_neverIssues {Proposal : Type} [BEq Proposal] (p : Proposal)
    (s : PolicyState Proposal) (h : s.rung = .shadow) :
    ((policy Proposal).decide (.propose p) s).map (·.any PolicyEvent.isIssued) = .ok false := by
  simp [policy, h, Except.map, PolicyEvent.isIssued]

/-- In review, a proposal never issues on its own; it is held. -/
theorem review_holds {Proposal : Type} [BEq Proposal] (p : Proposal)
    (s : PolicyState Proposal) (h : s.rung = .review) :
    (policy Proposal).decide (.propose p) s = .ok [.held p] := by
  simp [policy, h]

/-- An approval issues only what was held: a person cannot approve a
    proposal the cell never saw. -/
theorem approve_onlyHeld {Proposal : Type} [BEq Proposal] (p : Proposal)
    (s : PolicyState Proposal) (h : s.held.contains p = false) :
    (policy Proposal).decide (.approve p) s = .error .notHeld := by
  simp [policy, h]

variable [Architecture]

/-- Succession: the mechanical lift of a published fact into a command for
    the policy cell that subscribes to it. No judgment here. The key is
    derived from the fact, the causation is the fact, the run is fresh. -/
def succeed {Event Proposal Subject : Type} (issuer : String)
    (pick : Event → Option Proposal) (newRun : RunId) (now : Instant)
    (e : EventEnvelope Event Subject) : Option (CommandEnvelope Proposal) :=
  (pick e.payload).map fun proposal =>
    { actor := .policy issuer, key := .derived issuer e.id, causation := some e.id,
      correlation := newRun, issuedAt := now, payload := proposal }

/-- A retry of the lift derives the same key and cites the same fact, for
    every fact and every pick: succession is idempotent by construction. -/
theorem succeed_sameKey {Event Proposal Subject : Type} (issuer : String)
    (pick : Event → Option Proposal) (r r' : RunId) (t t' : Instant)
    (e : EventEnvelope Event Subject) (c c' : CommandEnvelope Proposal)
    (h : succeed issuer pick r t e = some c) (h' : succeed issuer pick r' t' e = some c') :
    c.key = c'.key ∧ c.causation = c'.causation := by
  unfold succeed at h h'
  cases hp : pick e.payload with
  | none => simp [hp] at h
  | some p =>
    simp [hp] at h h'
    subst h h'
    exact ⟨rfl, rfl⟩
