import CellCalculus.Journey
/-!
# Contracts: non-functional guarantees that fold along a journey

A step's contract is one assumption and a guarantee per viewpoint. The
assumption is the hypothesis of every theorem here: each step actually
honours its own bound. The guarantees fold along the journey algebra, and
the rule differs by viewpoint. Latency is the sum along a sequence and the
max across a fan-out, which is the critical path of the compiled DAG.
Unavailability budgets and costs add along both constructors, because a
`par` is all-must-succeed and so is series for everything but time. Peak
resource is the max along a sequence and the sum across a fan-out.

Sources: Benveniste et al., Contracts for System Design, 2018, for the
assume-guarantee algebra and the timing viewpoint; Le Boudec and Thiran,
Network Calculus, for concatenation as a sum; Dean and Barroso, The Tail
at Scale, for why percentiles do not fold this way.
-/

/-- A step's guarantees, each a natural number so that the folds stay in
    Lean core: milliseconds, failures per million runs, cost in micro-units
    per handled command, and peak resource units. The assumption they are
    made under is stated with the theorem, not here. -/
structure StepContract where
  /-- The step's latency bound in milliseconds, such as 20. -/
  latencyMs         : Nat
  /-- The step's unavailability budget in failures per million runs, such as 10. -/
  unavailabilityPpm : Nat
  /-- The step's cost in micro-units per handled command, such as 5. -/
  costMicros        : Nat
  /-- The step's peak resource in units, such as 2. -/
  peakUnits         : Nat
  deriving Repr, DecidableEq

/-- The contracts of a journey's steps, by step name. -/
abbrev Contracts := String → StepContract

namespace Journey

variable {State Refusal : Type}

/-- The step names a journey mentions. -/
def mentions : Journey State Refusal → String → Prop
  | step name _, n  => name = n
  | seq a b, n      => a.mentions n ∨ b.mentions n
  | par a b _, n    => a.mentions n ∨ b.mentions n

/-- Latency: sum along a sequence, max across a fan-out. -/
def latencyBound (contracts : Contracts) : Journey State Refusal → Nat
  | step name _ => (contracts name).latencyMs
  | seq a b     => a.latencyBound contracts + b.latencyBound contracts
  | par a b _   => max (a.latencyBound contracts) (b.latencyBound contracts)

/-- Unavailability: budgets add along both constructors. -/
def unavailabilityBudget (contracts : Contracts) : Journey State Refusal → Nat
  | step name _ => (contracts name).unavailabilityPpm
  | seq a b     => a.unavailabilityBudget contracts + b.unavailabilityBudget contracts
  | par a b _   => a.unavailabilityBudget contracts + b.unavailabilityBudget contracts

/-- Cost: adds along both constructors. -/
def costBound (contracts : Contracts) : Journey State Refusal → Nat
  | step name _ => (contracts name).costMicros
  | seq a b     => a.costBound contracts + b.costBound contracts
  | par a b _   => a.costBound contracts + b.costBound contracts

/-- Peak resource: max along a sequence, sum across a fan-out, the dual of latency. -/
def peakBound (contracts : Contracts) : Journey State Refusal → Nat
  | step name _ => (contracts name).peakUnits
  | seq a b     => max (a.peakBound contracts) (b.peakBound contracts)
  | par a b _   => a.peakBound contracts + b.peakBound contracts

/-- One run's actual elapsed time, given what each step actually took: a
    sequence takes the sum of its parts, a fan-out the slower branch. -/
def elapsed (actual : String → Nat) : Journey State Refusal → Nat
  | step name _ => actual name
  | seq a b     => a.elapsed actual + b.elapsed actual
  | par a b _   => max (a.elapsed actual) (b.elapsed actual)

/-- The assumption: every step the journey mentions honoured its own bound. -/
def StepsHonoured (contracts : Contracts) (actual : String → Nat) (j : Journey State Refusal) : Prop :=
  ∀ name, j.mentions name → actual name ≤ (contracts name).latencyMs

/-- The compositional theorem. If each step met its own latency bound, the
    journey's elapsed time is within the folded bound, for every journey,
    every set of contracts and every run. Structural induction and `omega`,
    which knows `max` on naturals. -/
theorem elapsed_le_latencyBound (contracts : Contracts) (actual : String → Nat) :
    ∀ j : Journey State Refusal, StepsHonoured contracts actual j →
      j.elapsed actual ≤ j.latencyBound contracts := by
  intro j
  induction j with
  | step name run => intro h; exact h name rfl
  | seq a b iha ihb =>
    intro h
    have ha := iha (fun n hn => h n (Or.inl hn))
    have hb := ihb (fun n hn => h n (Or.inr hn))
    simp only [elapsed, latencyBound]; omega
  | par a b merge iha ihb =>
    intro h
    have ha := iha (fun n hn => h n (Or.inl hn))
    have hb := ihb (fun n hn => h n (Or.inr hn))
    simp only [elapsed, latencyBound]; omega

/-- Refinement: a cell may tighten any guarantee freely, and no journey's
    bound gets worse. Stated for latency, budget and cost. -/
theorem latencyBound_mono (c c' : Contracts) (h : ∀ n, (c' n).latencyMs ≤ (c n).latencyMs) :
    ∀ j : Journey State Refusal, j.latencyBound c' ≤ j.latencyBound c := by
  intro j
  induction j with
  | step name run => exact h name
  | seq a b iha ihb => simp only [latencyBound]; omega
  | par a b merge iha ihb => simp only [latencyBound]; omega

theorem unavailabilityBudget_mono (c c' : Contracts)
    (h : ∀ n, (c' n).unavailabilityPpm ≤ (c n).unavailabilityPpm) :
    ∀ j : Journey State Refusal, j.unavailabilityBudget c' ≤ j.unavailabilityBudget c := by
  intro j
  induction j with
  | step name run => exact h name
  | seq a b iha ihb => simp only [unavailabilityBudget]; omega
  | par a b merge iha ihb => simp only [unavailabilityBudget]; omega

theorem costBound_mono (c c' : Contracts) (h : ∀ n, (c' n).costMicros ≤ (c n).costMicros) :
    ∀ j : Journey State Refusal, j.costBound c' ≤ j.costBound c := by
  intro j
  induction j with
  | step name run => exact h name
  | seq a b iha ihb => simp only [costBound]; omega
  | par a b merge iha ihb => simp only [costBound]; omega

end Journey
