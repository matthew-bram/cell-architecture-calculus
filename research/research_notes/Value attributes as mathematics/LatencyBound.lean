/-!
Experiment: can Lean 4 core (no Mathlib) prove that the end-to-end latency
bound of a journey built from step/seq/par is the sum of the steps' bounds
along a sequence and the max across a fan-out?

The journey algebra mirrors cell-calculus/CellCalculus/Journey.lean but
carries a per-step contract: a latency bound in Nat (e.g. milliseconds).
-/

/-- A per-step non-functional contract, for now just a latency bound. -/
structure StepContract where
  name    : String
  latency : Nat          -- guaranteed upper bound on this cell's handle time

/-- The same three constructors as `Journey`, with the contract on the leaf. -/
inductive J
  | step (c : StepContract)
  | seq  (first second : J)
  | par  (left right : J)

namespace J

/-- Syntactic bound: sum along seq, max across par. -/
def bound : J → Nat
  | step c    => c.latency
  | seq a b   => a.bound + b.bound
  | par a b   => max a.bound b.bound

/-- A semantic model: an environment assigns an actual duration to each step
    (one run of the journey). A run of a seq takes the sum of its parts; a
    run of a par takes the max (both branches start together and the
    fan-in waits for the slower). -/
def elapsed (actual : StepContract → Nat) : J → Nat
  | step c    => actual c
  | seq a b   => elapsed actual a + elapsed actual b
  | par a b   => max (elapsed actual a) (elapsed actual b)

/-- The steps a journey mentions. -/
def mentions : J → StepContract → Prop
  | step c', c  => c' = c
  | seq a b, c  => mentions a c ∨ mentions b c
  | par a b, c  => mentions a c ∨ mentions b c

/-- Every step honours its contract. -/
def StepsHonoured (actual : StepContract → Nat) (j : J) : Prop :=
  ∀ c, j.mentions c → actual c ≤ c.latency

/-- The compositional theorem: if each step meets its own latency bound,
    the journey's elapsed time is bounded by the syntactic bound. The
    proof is structural induction plus `omega`, which knows `max` on Nat. -/
theorem elapsed_le_bound (actual : StepContract → Nat) :
    ∀ j : J, StepsHonoured actual j → j.elapsed actual ≤ j.bound := by
  intro j
  induction j with
  | step c =>
    intro h
    exact h c rfl
  | seq a b iha ihb =>
    intro h
    have ha := iha (fun c hc => h c (Or.inl hc))
    have hb := ihb (fun c hc => h c (Or.inr hc))
    simp only [elapsed, bound]
    omega
  | par a b iha ihb =>
    intro h
    have ha := iha (fun c hc => h c (Or.inl hc))
    have hb := ihb (fun c hc => h c (Or.inr hc))
    simp only [elapsed, bound]
    omega

/-- The bound of a sequence is the sum of the bounds (by definition). -/
theorem bound_seq (a b : J) : (seq a b).bound = a.bound + b.bound := rfl

/-- The bound of a fan-out is the max of the bounds (by definition). -/
theorem bound_par (a b : J) : (par a b).bound = max a.bound b.bound := rfl

/-- Monotonicity (the refinement direction of a contract): tightening any
    one step's bound can only tighten the journey's bound. Stated for the
    whole assignment of latencies. -/
def tighten (f : StepContract → Nat) : J → J
  | step c  => step { c with latency := f c }
  | seq a b => seq (tighten f a) (tighten f b)
  | par a b => par (tighten f a) (tighten f b)

theorem bound_tighten_le (f : StepContract → Nat) (hf : ∀ c, f c ≤ c.latency) :
    ∀ j : J, (tighten f j).bound ≤ j.bound := by
  intro j
  induction j with
  | step c => exact hf c
  | seq a b iha ihb => simp only [tighten, bound]; omega
  | par a b iha ihb => simp only [tighten, bound]; omega

/-- Availability in series/parallel, with probabilities as rationals is not
    in core; but the *shape* of the rule is: unavailability adds up along a
    sequence (union bound), and across an all-must-succeed fan-out it also
    adds up. Here in Nat as "budgeted failures per million". -/
def failBudget : J → Nat
  | step c  => c.latency  -- stand-in field; a real contract carries its own
  | seq a b => a.failBudget + b.failBudget
  | par a b => a.failBudget + b.failBudget

/-- A concrete journey in the shape of journey 7: arrive → book → threshold
    → (analyst ∥ steward) → reach. -/
def journey7 : J :=
  seq (step ⟨"arrive", 5⟩)
   (seq (step ⟨"book", 20⟩)
    (seq (step ⟨"threshold", 2⟩)
     (seq (par (step ⟨"analyst", 300⟩) (step ⟨"steward", 40⟩))
          (step ⟨"reach", 10⟩))))

example : journey7.bound = 337 := by decide

end J
