import CellCalculus.Cell
/-!
# Journeys as terms, and every term a DAG

A journey is built from three constructors and nothing else: a step, a
sequence, and a fan-out with a fan-in. There is no loop constructor, so a
journey cannot re-enter a step. The theorem `compile_wellFormed` turns that
into a checked fact: every term compiles to a graph in which each node waits
only on earlier nodes, the same rule a journey transcribed from prose is
held to.
-/

/-- A journey over a product state. `step` is one cell's `handle` or
    `handleForeign` on that state; `seq` threads the state through two
    journeys; `par` runs two journeys from the same state and merges their
    results. Kleisli composition in `Except`: a refusal anywhere ends the
    journey at that named outcome. -/
inductive Journey (State Refusal : Type)
  /-- One cell's `handle` or `handleForeign` on the state, named for the design's step. -/
  | step (name : String) (run : State → Except Refusal State)
  /-- The second journey on the first's result. -/
  | seq  (first second : Journey State Refusal)
  /-- Both journeys from the same state, their results merged: a fan-out with its fan-in. -/
  | par  (left right : Journey State Refusal) (merge : State → State → State)

namespace Journey

variable {State Refusal : Type}

/-- The denotation of a journey: one function from a state to a refusal or
    a state. -/
def run : Journey State Refusal → State → Except Refusal State
  | step _ f, s => f s
  | seq a b, s => do let s' ← a.run s; b.run s'
  | par a b merge, s => do
      let x ← a.run s
      let y ← b.run s
      pure (merge x y)

/-- Compositionality, by definition: running a sequence is running the first
    and then the second. -/
theorem run_seq (a b : Journey State Refusal) (s : State) :
    (seq a b).run s = (a.run s >>= b.run) := rfl

/-- Compositionality, by definition: running a fan-out is running both
    branches from the same state and merging. -/
theorem run_par (a b : Journey State Refusal) (merge : State → State → State) (s : State) :
    (par a b merge).run s = (a.run s >>= fun x => b.run s >>= fun y => pure (merge x y)) := rfl

/-- A node of the compiled step graph: its name and the indices of the
    nodes it waits on. -/
structure Node where
  /-- The step's name, or "join" for a fan-in. -/
  name  : String
  /-- The indices of the nodes this one waits on, all below its own. -/
  needs : List Nat

/-- The one rule that makes a step graph a DAG: every node at index `i`
    waits only on indices below `i`. Index order is then a topological
    order and the journey is a left fold. -/
def nodesOk : Nat → List Node → Bool
  | _, [] => true
  | i, node :: rest => node.needs.all (· < i) && nodesOk (i + 1) rest

theorem nodesOk_append (k : Nat) (xs ys : List Node) :
    nodesOk k (xs ++ ys) = (nodesOk k xs && nodesOk (k + xs.length) ys) := by
  induction xs generalizing k with
  | nil => simp [nodesOk]
  | cons x xs ih =>
    simp only [List.cons_append, nodesOk, ih, List.length_cons]
    rw [show k + 1 + xs.length = k + (xs.length + 1) from by omega, Bool.and_assoc]

/-- A list of nodes none of which waits on anything is well formed from any
    starting index. -/
theorem nodesOk_of_noNeeds (k : Nat) (nodes : List Node)
    (h : ∀ node ∈ nodes, node.needs = []) : nodesOk k nodes = true := by
  induction nodes generalizing k with
  | nil => rfl
  | cons node rest ih =>
    simp only [nodesOk, h node (List.mem_cons_self ..), List.all_nil, Bool.true_and]
    exact ih (k + 1) fun m hm => h m (List.mem_cons_of_mem _ hm)

/-- Compile a term to nodes, numbering from `k`, with `inputs` the indices
    whose output flows into the term. Returns the nodes and the term's
    output indices. -/
def compile : Journey State Refusal → Nat → List Nat → List Node × List Nat
  | step name _, k, inputs => ([⟨name, inputs⟩], [k])
  | seq a b, k, inputs =>
      let (na, oa) := a.compile k inputs
      let (nb, ob) := b.compile (k + na.length) oa
      (na ++ nb, ob)
  | par a b _, k, inputs =>
      let (na, oa) := a.compile k inputs
      let (nb, ob) := b.compile (k + na.length) inputs
      (na ++ nb ++ [⟨"join", oa ++ ob⟩], [k + na.length + nb.length])

/-- Every journey term compiles to a well-formed step graph. If everything
    flowing in is numbered below `k`, every compiled node waits only on
    earlier nodes and the outputs are numbered below the end. By structural
    induction on the term: the only way to build a journey is with the three
    constructors, and each preserves the invariant. -/
theorem compile_wellFormed (j : Journey State Refusal) (k : Nat) (inputs : List Nat)
    (hins : inputs.all (· < k) = true) :
    nodesOk k (j.compile k inputs).1 = true ∧
    (j.compile k inputs).2.all (· < k + (j.compile k inputs).1.length) = true := by
  induction j generalizing k inputs with
  | step name f =>
    simp only [compile, nodesOk, List.length_singleton, List.all_cons, List.all_nil]
    constructor
    · simpa using hins
    · simp
  | seq a b iha ihb =>
    simp only [compile]
    obtain ⟨ha, hoa⟩ := iha k inputs hins
    obtain ⟨hb, hob⟩ := ihb (k + (a.compile k inputs).1.length) (a.compile k inputs).2 hoa
    refine ⟨?_, ?_⟩
    · rw [nodesOk_append, ha, hb]; rfl
    · simp only [List.length_append]
      rw [List.all_eq_true] at hob ⊢
      intro x hx; have := hob x hx; simp at this ⊢; omega
  | par a b m iha ihb =>
    simp only [compile]
    obtain ⟨ha, hoa⟩ := iha k inputs hins
    have hins' : inputs.all (· < k + (a.compile k inputs).1.length) = true := by
      rw [List.all_eq_true] at hins ⊢
      intro x hx; have := hins x hx; simp at this ⊢; omega
    obtain ⟨hb, hob⟩ := ihb (k + (a.compile k inputs).1.length) inputs hins'
    refine ⟨?_, ?_⟩
    · rw [nodesOk_append, nodesOk_append, ha, hb]
      simp only [Bool.true_and, nodesOk, Bool.and_true, List.length_append, List.all_append,
        Bool.and_eq_true]
      refine ⟨?_, ?_⟩
      · rw [List.all_eq_true] at hoa ⊢; intro x hx; have := hoa x hx; simp at this ⊢; omega
      · rw [List.all_eq_true] at hob ⊢; intro x hx; have := hob x hx; simp at this ⊢; omega
    · simp only [List.all_cons, List.all_nil, Bool.and_true, List.length_append,
        List.length_singleton, decide_eq_true_eq]
      omega

end Journey

/-- Operational delivery: foreign facts arrive one at a time, in some order,
    and the cell's own history grows with what it emits. This is the
    choreography's reading of a journey; the composite function is its
    denotation. A fan-in cell with memory is one for which the two agree. -/
def Cell.deliver {Command ForeignEvent Event State Refusal : Type}
    (cell : Cell Command ForeignEvent Event State Refusal) :
    List Event → List ForeignEvent → List Event
  | _, [] => []
  | history, fact :: facts =>
      let emitted := cell.handleForeign history fact
      emitted ++ cell.deliver (history ++ emitted) facts
