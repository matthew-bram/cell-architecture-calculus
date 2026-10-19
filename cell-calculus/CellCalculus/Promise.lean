import CellCalculus.Envelope
/-!
# Promises as trace predicates

A service promise is a predicate over runs, evaluated in the same pass that
checks a run's shape, with a measure beside it. A burn is a failing
predicate with the run that failed it named. The predicates read the
envelope's times and kinds, never a payload's content.
-/

variable [Architecture]

/-- A promise about one run. -/
abbrev RunPromise (Command Event Subject : Type) :=
  Run Command Event Subject → Bool

/-- The runs that failed a promise, named. -/
def burns {Command Event Subject : Type} (promise : RunPromise Command Event Subject)
    (runs : List (Run Command Event Subject)) : List (Run Command Event Subject) :=
  runs.filter fun run => !promise run

/-- The measure beside a promise: how many of the runs kept it, over how
    many were seen. The window is the list handed in. -/
def kept {Command Event Subject : Type} (promise : RunPromise Command Event Subject)
    (runs : List (Run Command Event Subject)) : Nat × Nat :=
  ((runs.filter promise).length, runs.length)

/-- Within a duration: for every run whose root is one of these, a target
    fact is recorded within `limit` of the root's issue. -/
def withinDuration {Command Event Subject : Type}
    (isRoot : Command → Bool) (isTarget : Event → Bool) (limit : Nat) :
    RunPromise Command Event Subject := fun run =>
  !isRoot run.root.payload ||
    run.events.any fun e => isTarget e.payload && e.recordedAt.ms ≤ run.root.issuedAt.ms + limit

/-- At most this many target facts in a run. -/
def atMostCount {Command Event Subject : Type}
    (isTarget : Event → Bool) (n : Nat) : RunPromise Command Event Subject := fun run =>
  (run.events.filter fun e => isTarget e.payload).length ≤ n

/-- Never after: no `later` fact is recorded after a `fence` fact. -/
def neverAfter {Command Event Subject : Type}
    (fence later : Event → Bool) : RunPromise Command Event Subject := fun run =>
  match run.events.find? (fun e => fence e.payload) with
  | none   => true
  | some f => run.events.all fun e => !later e.payload || e.recordedAt.ms ≤ f.recordedAt.ms

/-- Loosening the limit never breaks a kept promise, for every root, target,
    limit and run. The reason a promise can be tightened in steps. -/
theorem withinDuration_mono {Command Event Subject : Type}
    (isRoot : Command → Bool) (isTarget : Event → Bool) (d d' : Nat) (hd : d ≤ d')
    (run : Run Command Event Subject)
    (h : withinDuration isRoot isTarget d run = true) :
    withinDuration isRoot isTarget d' run = true := by
  simp only [withinDuration, Bool.or_eq_true, Bool.not_eq_true', List.any_eq_true,
    Bool.and_eq_true, decide_eq_true_eq] at h ⊢
  rcases h with h | ⟨e, he, ht, hle⟩
  · exact Or.inl h
  · exact Or.inr ⟨e, he, ht, by omega⟩

/-! ## Every attribute names what it quantifies over

A quality attribute is checkable only once its statement says what it
ranges over. One run: a promise, two-valued on a recorded run. A pair of
runs: a relation, the shape of a confidentiality claim, which no single run
can refute. A population: a promise and a threshold, kept over seen, a
hyperproperty over the window. A distribution: not checkable on any finite
set of traces, so it is measured and the attribute says by what. The
artifact: a decided proposition about the model itself. -/

/-- What an attribute's statement ranges over. -/
inductive Scope
  /-- One recorded run: a deadline, an ordering, a count. -/
  | oneRun
  /-- A pair of runs: a relation, the shape of a confidentiality claim. -/
  | pair
  /-- A population of runs with a threshold: a service level. -/
  | population
  /-- A distribution, measured rather than checked. -/
  | distribution
  /-- The model itself: a structural rule. -/
  | artifact
  deriving Repr, DecidableEq

/-- An attribute with its scope fixed by its constructor, so that an
    attribute cannot be written without saying what it quantifies over. -/
inductive Attribute (Command Event Subject : Type)
  /-- A promise every run must keep, named. -/
  | oneRun (name : String) (promise : RunPromise Command Event Subject)
  /-- A relation every ordered pair of runs must satisfy, named. -/
  | pair (name : String) (relation : Run Command Event Subject → Run Command Event Subject → Bool)
  /-- A promise and the percentage of runs that must keep it, named. -/
  | population (name : String) (promise : RunPromise Command Event Subject) (thresholdPercent : Nat)
  /-- A claim about a distribution, named, with what measures it. -/
  | distribution (name : String) (measuredBy : String)
  /-- A decided proposition about the model, named, with its truth. -/
  | artifact (name : String) (holds : Bool)

/-- What an attribute ranges over, read off its constructor. -/
def Attribute.scope {Command Event Subject : Type} : Attribute Command Event Subject → Scope
  | .oneRun .. => .oneRun
  | .pair .. => .pair
  | .population .. => .population
  | .distribution .. => .distribution
  | .artifact .. => .artifact

/-- What the checker says about an attribute over a window of runs. -/
inductive Verdict
  /-- Every run in the window kept it. -/
  | kept
  /-- This many runs in the window failed it. -/
  | burned (count : Nat)
  /-- Not checkable on a window: a distribution. -/
  | notCheckable
  deriving Repr, DecidableEq

/-- Evaluate an attribute over a window of runs. A pair attribute is checked
    over every ordered pair in the window; a population attribute over the
    ratio; a distributional one is never checked here. -/
def Attribute.verdict {Command Event Subject : Type}
    (a : Attribute Command Event Subject) (runs : List (Run Command Event Subject)) : Verdict :=
  match a with
  | .oneRun _ promise =>
      let failed := burns promise runs
      if failed.isEmpty then .kept else .burned failed.length
  | .pair _ relation =>
      let failed := runs.filter fun r => !(runs.all fun r' => relation r r')
      if failed.isEmpty then .kept else .burned failed.length
  | .population _ promise threshold =>
      let (k, n) := kept promise runs
      if threshold * n ≤ k * 100 then .kept else .burned (n - k)
  | .distribution .. => .notCheckable
  | .artifact _ holds => if holds then .kept else .burned 1

/-- A population attribute whose promise every run keeps is kept at any
    threshold up to one hundred per cent, for every window. -/
theorem population_kept_of_all {Command Event Subject : Type}
    (name : String) (promise : RunPromise Command Event Subject) (threshold : Nat)
    (ht : threshold ≤ 100) (runs : List (Run Command Event Subject))
    (h : runs.all promise = true) :
    (Attribute.population name promise threshold).verdict runs = .kept := by
  have hfilter : runs.filter promise = runs :=
    List.filter_eq_self.mpr (by simpa [List.all_eq_true] using h)
  have hle : threshold * runs.length ≤ runs.length * 100 := by
    rw [Nat.mul_comm runs.length 100]; exact Nat.mul_le_mul_right _ ht
  simp [Attribute.verdict, kept, hfilter, hle]
