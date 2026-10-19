import CellCalculus
/-!
# The journey map, as checked

Transcribes `corpus/capability-map.md`, `corpus/architecture.md` and the
journey sections of `corpus/vision.md`, then asks Lean to check the
properties the prose asserts. No Mathlib; core Lean 4 only. A journey
transcribed from its tables is `Transcribed` here, held to the same DAG
rule, `Journey.nodesOk`, as the calculus's journey terms; `Journey` is
the calculus's name for the term algebra.

Everything checked here is decidable, finite lists, so every theorem is
discharged by `decide`: Lean computes the answer and the kernel certifies
it. A human proof is never needed for this class of property.
-/

/-- The capabilities on the map, one per row. -/
inductive Cap
  /-- Membership: members, cards, roles, the alias map, the session. -/
  | membership
  /-- Notices: what a member hears. -/
  | notices
  /-- Catalog: items and their copies. -/
  | catalog
  /-- Circulation: the loans on a card. -/
  | circulation
  /-- Holds: the queue waiting on a copy. -/
  | holds
  /-- Pickup: the hold shelf. -/
  | pickup
  /-- Fines: what is owed. -/
  | fines
  /-- Renewals: the proposals to renew, through the ladder. -/
  | renewals
  /-- The reading assistant: proposes renewals and holds. -/
  | assistant
  /-- Reports: the counts. -/
  | reports
  /-- Operations: the staff console and the rungs. -/
  | operations
  /-- The terminals, the kiosks and the app, a platform capability. -/
  | terminals
  /-- Telemetry, a platform capability. -/
  | telemetry
  deriving DecidableEq, Repr

/-- The zones of the technology architecture. -/
inductive Zone
  /-- The desk: names, cards, the alias map. -/
  | desk
  /-- The stacks: loans, holds, fines, the catalog, by token. -/
  | stacks
  /-- The office: counts and the staff console. -/
  | office
  /-- The lobby: the channel applications. -/
  | lobby
  /-- The fabric: telemetry and the audit trail. -/
  | fabric
  deriving DecidableEq, Repr

/-- Placement: the "cells by zone" table. Channel applications are not
    cells but still have a zone. -/
def Cap.zone : Cap → Zone
  | .membership | .notices => .desk
  | .catalog | .circulation | .holds | .pickup | .fines | .renewals | .assistant => .stacks
  | .reports | .operations => .office
  | .terminals => .lobby
  | .telemetry => .fabric

/-- Platform capabilities: in every journey, left out of the matrix rows. -/
def Cap.isPlatform : Cap → Bool
  | .terminals | .telemetry => true
  | _ => false

/-! ## A journey is a DAG of steps, each labelled with capabilities -/

/-- One step of a journey, a row of its Steps table. `needs` lists the
    indices of the steps it waits on. A step may only need *earlier*
    steps; `Transcribed.wellFormed` checks it. That one rule is what
    makes the step graph a DAG by construction. -/
structure Step where
  /-- The step as the journey's table names it. -/
  name  : String
  /-- The capabilities the step's row names. -/
  caps  : List Cap
  /-- The indices of the earlier steps it waits on. -/
  needs : List Nat
  deriving Repr

/-- A journey transcribed from its section: its number, its title, its
    steps, and the journeys its References table names, by kind. -/
structure Transcribed where
  /-- The journey's number on the map. -/
  id          : Nat
  /-- The journey's title. -/
  name        : String
  /-- The steps in order, each waiting only on earlier ones. -/
  steps       : List Step
  /-- The journeys this one runs as a step of its own run. -/
  composition : List Nat
  /-- The journeys whose new run this one's last fact starts. -/
  succession  : List Nat
  /-- The journeys the section merely points the reader at. -/
  pointers    : List Nat
  deriving Repr

/-- Every step waits only on earlier steps: the calculus's `Journey.nodesOk`
    over the steps as nodes, the one DAG rule for transcribed and compiled
    journeys alike. -/
def Transcribed.wellFormed (j : Transcribed) : Bool :=
  Journey.nodesOk 0 (j.steps.map fun s => { name := s.name, needs := s.needs })

/-- The capabilities a journey's steps name, platform rows removed,
    deduplicated in order of first use. -/
def Transcribed.capsNamed (j : Transcribed) : List Cap :=
  j.steps.foldl (fun acc s =>
    s.caps.foldl (fun acc c =>
      if c.isPlatform || acc.contains c then acc else acc ++ [c]) acc) []

/-- Journey 0, "Sign in", as its table reads. -/
def signIn : Transcribed :=
  { id := 0, name := "Sign in"
  , steps := [ { name := "The member signs in", caps := [.membership, .terminals], needs := [] } ]
  , composition := [], succession := [], pointers := [] }

/-- Journey 1, "Join". -/
def join : Transcribed :=
  { id := 1, name := "Join"
  , steps := [ { name := "The resident applies and the card is issued", caps := [.membership], needs := [] }
             , { name := "The welcome goes out", caps := [.notices], needs := [0] } ]
  , composition := [0], succession := [], pointers := [] }

/-- Journey 2, "Borrow an item", as its Steps table reads. Step 1 fans out
    to the catalog and to notices; step 4 fans back in. -/
def borrowAnItem : Transcribed :=
  { id := 2, name := "Borrow an item"
  , steps := [ { name := "The card is presented", caps := [.membership], needs := [] }
             , { name := "The item is checked out", caps := [.circulation], needs := [0] }
             , { name := "The copy is marked on loan", caps := [.catalog], needs := [1] }
             , { name := "The limit warning, if the card is at its limit", caps := [.notices], needs := [1] }
             , { name := "The receipt reaches the member", caps := [.notices, .terminals], needs := [2, 3] } ]
  , composition := [0], succession := [3, 5], pointers := [6] }

/-- Journey 3, "Return an item". -/
def returnAnItem : Transcribed :=
  { id := 3, name := "Return an item"
  , steps := [ { name := "The item is checked in", caps := [.circulation], needs := [] }
             , { name := "The copy is marked on the shelf", caps := [.catalog], needs := [0] }
             , { name := "A late return is assessed", caps := [.fines], needs := [0] }
             , { name := "The member hears, if there is a fine", caps := [.notices], needs := [2] } ]
  , composition := [], succession := [4], pointers := [5] }

/-- Journey 4, "Hold an item and pick it up". -/
def holdAndPickUp : Transcribed :=
  { id := 4, name := "Hold an item and pick it up"
  , steps := [ { name := "The member places the hold", caps := [.holds], needs := [] }
             , { name := "The copy comes in and is ready", caps := [.pickup], needs := [0] }
             , { name := "The member hears", caps := [.notices], needs := [1] }
             , { name := "The member picks it up at the desk", caps := [.membership, .circulation], needs := [2] } ]
  , composition := [0, 2], succession := [5], pointers := [3] }

/-- Journey 5, "An item runs late". -/
def runsLate : Transcribed :=
  { id := 5, name := "An item runs late"
  , steps := [ { name := "The reminder goes out the day before", caps := [.fines, .notices], needs := [] }
             , { name := "The fine is assessed after the due day", caps := [.fines], needs := [0] }
             , { name := "The member pays", caps := [.fines], needs := [1] }
             , { name := "The receipt goes out", caps := [.notices], needs := [2] } ]
  , composition := [], succession := [3], pointers := [6] }

/-- Journey 6, "Renew". -/
def renew : Transcribed :=
  { id := 6, name := "Renew"
  , steps := [ { name := "The member asks, or the assistant proposes", caps := [.assistant, .renewals], needs := [] }
             , { name := "The loan is renewed", caps := [.circulation], needs := [0] }
             , { name := "The member hears", caps := [.notices], needs := [1] } ]
  , composition := [], succession := [5], pointers := [2] }

/-- Journey 7, "Leave". -/
def leave : Transcribed :=
  { id := 7, name := "Leave"
  , steps := [ { name := "The member asks to leave", caps := [.membership], needs := [] }
             , { name := "The card is closed", caps := [.circulation], needs := [0] }
             , { name := "What is owed is settled or written off", caps := [.fines], needs := [0] }
             , { name := "The record is deleted", caps := [.membership], needs := [1, 2] } ]
  , composition := [0], succession := [], pointers := [3] }

/-- Every journey on the map, in order. -/
def journeys : List Transcribed :=
  [signIn, join, borrowAnItem, returnAnItem, holdAndPickUp, runsLate, renew, leave]

theorem signIn_isDag        : signIn.wellFormed        = true := by decide
theorem join_isDag          : join.wellFormed          = true := by decide
theorem borrowAnItem_isDag  : borrowAnItem.wellFormed  = true := by decide
theorem returnAnItem_isDag  : returnAnItem.wellFormed  = true := by decide
theorem holdAndPickUp_isDag : holdAndPickUp.wellFormed = true := by decide
theorem runsLate_isDag      : runsLate.wellFormed      = true := by decide
theorem renew_isDag         : renew.wellFormed         = true := by decide
theorem leave_isDag         : leave.wellFormed         = true := by decide

/-! ## The journey matrix row must agree with the journey's text

The capability map keeps a matrix row per journey, by hand. The journey's
table names capabilities step by step, also by hand. Nothing but a theorem
checks that the two agree. -/

/-- The journey matrix, as written in the capability map, by journey number. -/
def matrixRow : Nat → List Cap
  | 0 => [.membership]
  | 1 => [.membership, .notices]
  | 2 => [.membership, .circulation, .catalog, .notices]
  | 3 => [.circulation, .catalog, .fines, .notices]
  | 4 => [.holds, .pickup, .notices, .membership, .circulation]
  | 5 => [.fines, .notices]
  | 6 => [.assistant, .renewals, .circulation, .notices]
  | 7 => [.membership, .circulation, .fines]
  | _ => []

/-- Two lists name the same capabilities, order and repetition aside. -/
def sameSet (a b : List Cap) : Bool :=
  a.all b.contains && b.all a.contains

theorem matrixRow0_matchesJourney : sameSet signIn.capsNamed        (matrixRow 0) = true := by decide
theorem matrixRow1_matchesJourney : sameSet join.capsNamed          (matrixRow 1) = true := by decide
theorem matrixRow2_matchesJourney : sameSet borrowAnItem.capsNamed  (matrixRow 2) = true := by decide
theorem matrixRow3_matchesJourney : sameSet returnAnItem.capsNamed  (matrixRow 3) = true := by decide
theorem matrixRow4_matchesJourney : sameSet holdAndPickUp.capsNamed (matrixRow 4) = true := by decide
theorem matrixRow5_matchesJourney : sameSet runsLate.capsNamed      (matrixRow 5) = true := by decide
theorem matrixRow6_matchesJourney : sameSet renew.capsNamed         (matrixRow 6) = true := by decide
theorem matrixRow7_matchesJourney : sameSet leave.capsNamed         (matrixRow 7) = true := by decide

/-- The map's claim: the terminals are in every journey a member starts,
    checked step by step for journey 2. -/
theorem journey2_passesThroughTerminals :
    borrowAnItem.steps.any (fun s => s.caps.contains .terminals) = true := by decide

/-! ## A DAG of steps is a functional program

Because every step needs only earlier steps, index order is a topological
order, and the journey runs as a left fold: a pure function from an
initial state through each step. This is the sense in which "a journey is
a DAG" means "a journey is a functional program". -/

/-- A step's effect, kept abstract: a function on an abstract state. -/
def Transcribed.run (j : Transcribed) (σ : α) (step : Step → α → α) : α :=
  j.steps.foldl (fun acc s => step s acc) σ

/-- The capabilities journey 2 touches, in order, as the fold computes them. -/
theorem borrowAnItem_touches :
    borrowAnItem.run ([] : List Cap) (fun s acc => acc ++ s.caps)
      = [.membership, .circulation, .catalog, .notices, .notices, .terminals] := by decide

/-! ## Composition and succession are two relations, and only one may cycle

A References table marks each reference as one of three kinds.
**Composition**: a journey runs another journey as one of its steps
(journey 4 picks up with a checkout as in journey 2). **Succession**: a
journey's last fact is the trigger of a *new instance* of another journey
(a return, journey 3, readies a hold, journey 4). A **pointer** sends the
reader elsewhere and is no edge.

The rule: every journey is a DAG. Composition must be acyclic, because a
cycle there is a journey that contains itself. Succession may cycle,
because each edge is a new fact starting a new run; the everyday loop is a
succession of DAG instances, never one cyclic journey. -/

/-- The successors of a node in an adjacency list. -/
def succs (g : List (Nat × List Nat)) (n : Nat) : List Nat :=
  (g.find? (·.1 == n)).map (·.2) |>.getD []

/-- Is `target` reachable from `n` in at most `fuel` hops? -/
def reaches (g : List (Nat × List Nat)) : Nat → Nat → Nat → Bool
  | 0, _, _ => false
  | fuel + 1, n, target =>
    (succs g n).any fun m => m == target || reaches g fuel m target

/-- Whether some node reaches itself. -/
def hasCycle (g : List (Nat × List Nat)) : Bool :=
  g.any fun (n, _) => reaches g g.length n n

/-- Composition, read off the References tables: which journeys run which as a step. -/
def composition : List (Nat × List Nat) :=
  journeys.map fun j => (j.id, j.composition)

/-- Succession, read off the same tables: whose last fact starts whom. -/
def succession : List (Nat × List Nat) :=
  journeys.map fun j => (j.id, j.succession)

/-- The references with their kinds dropped, every row an edge. -/
def referencesWithoutKinds : List (Nat × List Nat) :=
  journeys.map fun j => (j.id, j.composition ++ j.succession ++ j.pointers)

theorem composition_isAcyclic : hasCycle composition = false := by decide
theorem succession_cycles     : hasCycle succession  = true  := by decide

/-- Read without kinds, the references cycle: a return readies a hold, a
    pickup can run late, a late item is returned. The kind column is what
    makes the map readable at all. -/
theorem referencesWithoutKinds_cycle : hasCycle referencesWithoutKinds = true := by decide

/-! ## A journey is a pipeline in `Except`, and that is why it is a DAG

When a step yields an output from another cell, the output is
`Either[Ex, B]`, in Lean `Except Ex B`, a monad in its right hole. A
journey is then a `do` block: each step is a Kleisli arrow
`A → Except Ex B`, a `Left` short-circuits to the journey's failure
outcome, and nothing retries inside the journey. A retry is a new fact and
a new run.

Why this makes every journey a DAG *by construction*: Lean accepts only
total functions. A `do` block in `Except` is a finite chain of binds; a
step cannot re-enter an earlier step without recursion, and recursion that
Lean cannot prove terminating is rejected at compile time ("fail to show
termination"). So a journey that compiles is acyclic, and no separate DAG
check is needed for the ones written this way. The check `wellFormed`
above is for journeys transcribed from tables; this is for journeys
written as code. -/

/-- The refusals of journey 2 as code: the ways a step says no. -/
inductive Ex
  /-- A guest card may not borrow. -/
  | guestCard
  /-- The card is closed. -/
  | cardClosed
  /-- Five items are already on loan. -/
  | limitReached
  deriving DecidableEq, Repr

/-- What the terminal presents: the card, the copy, and whether the card is a guest's. -/
structure Presented where
  /-- The card number as presented. -/
  card  : String
  /-- The copy's ID as scanned. -/
  item  : String
  /-- Whether the card is a guest's, which membership knows. -/
  guest : Bool
  deriving Repr, DecidableEq
/-- What membership resolved: the token in place of the card, and the copy. -/
structure Resolved where
  /-- The patron token. -/
  token : String
  /-- The copy's ID. -/
  item  : String
  deriving Repr, DecidableEq
/-- What circulation booked: the copy and how many are on loan after it. -/
structure Loan where
  /-- The copy's ID. -/
  item   : String
  /-- How many items the card holds after this one. -/
  onLoan : Nat
  deriving Repr, DecidableEq
/-- What reaches the member: the copy, and whether a warning went with it. -/
structure Receipt where
  /-- The copy's ID. -/
  item   : String
  /-- Whether the limit warning went out. -/
  warned : Bool
  deriving Repr, DecidableEq

-- Each step: a Kleisli arrow. The cell that owns the step is in the comment.
/-- Step 0, membership: the card is resolved; a guest stops here. -/
def resolve (p : Presented) : Except Ex Resolved :=                   -- membership
  if p.guest then .error .guestCard else .ok { token := "P-7", item := p.item }
/-- Step 1, circulation: the item is checked out; the sixth is refused. -/
def checkOutStep (held : Nat) (r : Resolved) : Except Ex Loan :=      -- circulation
  if held ≥ 5 then .error .limitReached else .ok { item := r.item, onLoan := held + 1 }
/-- Step 2, the catalog: the copy is marked on loan. -/
def markCopy (l : Loan) : Except Ex Loan := .ok l                      -- catalog
/-- Steps 3 and 4, notices: the warning if over the level, and the receipt. -/
def receipt (l : Loan) : Except Ex Receipt :=                          -- notices
  .ok { item := l.item, warned := l.onLoan > 4 }

/-- Journey 2 as code, given how many items the card already holds. -/
def journey2 (held : Nat) (p : Presented) : Except Ex Receipt := do
  let r ← resolve p
  let l ← checkOutStep held r
  let l ← markCopy l
  receipt l

-- The outcomes, as facts the kernel can check.
theorem journey2_warns :
    journey2 4 { card := "C-1041", item := "b-5", guest := false } = .ok { item := "b-5", warned := true } := by rfl
theorem journey2_quiet :
    journey2 0 { card := "C-1041", item := "b-1", guest := false } = .ok { item := "b-1", warned := false } := by rfl
theorem journey2_guestStops :
    journey2 0 { card := "C-2002", item := "b-1", guest := true } = .error .guestCard := by rfl
theorem journey2_sixthRefused :
    journey2 5 { card := "C-1041", item := "b-6", guest := false } = .error .limitReached := by rfl

/-- Composition, as code: journey 4's last step runs journey 2 as a step of
    its own run. No recursion, no cycle. -/
def journey4_pickUp (held : Nat) (p : Presented) : Except Ex Receipt :=
  journey2 held p

/-! ## The directions that never reverse

Every path between cells is a row in the paths table. The rule: the
stacks never ask the desk. Each new path a design adds is one more row,
and this theorem is re-checked. -/

/-- The kinds of path the architecture's paths table names. -/
inductive Kind
  /-- A fact published and reacted to. -/
  | event
  /-- A read of the owner's record, stamped. -/
  | query
  /-- A command through the owner's gateway. -/
  | command
  /-- A signed session from a terminal to the desk. -/
  | session
  /-- A control request from the office. -/
  | control
  /-- A call to a party outside the system. -/
  | partner
  deriving DecidableEq, Repr

/-- A row of the paths table: an arrow between two cells with its kind. -/
structure Path where
  /-- Who opens the path. -/
  src  : Cap
  /-- Whom it opens toward. -/
  dst  : Cap
  /-- The kind of path, from the architecture. -/
  kind : Kind
  deriving Repr

/-- The paths table, every arrow between cells the architecture lists. -/
def paths : List Path :=
  [ { src := .terminals,   dst := .membership,  kind := .session }
  , { src := .operations,  dst := .renewals,    kind := .control }
  , { src := .operations,  dst := .membership,  kind := .control }
  , { src := .membership,  dst := .circulation, kind := .command }
  , { src := .renewals,    dst := .circulation, kind := .command }
  , { src := .holds,       dst := .circulation, kind := .query }
  , { src := .fines,       dst := .circulation, kind := .query }
  , { src := .reports,     dst := .catalog,     kind := .query }
  , { src := .reports,     dst := .circulation, kind := .query }
  , { src := .membership,  dst := .circulation, kind := .event }
  , { src := .circulation, dst := .catalog,     kind := .event }
  , { src := .circulation, dst := .notices,     kind := .event }
  , { src := .circulation, dst := .pickup,      kind := .event }
  , { src := .circulation, dst := .fines,       kind := .event }
  , { src := .holds,       dst := .pickup,      kind := .event }
  , { src := .pickup,      dst := .notices,     kind := .event }
  , { src := .fines,       dst := .notices,     kind := .event }
  , { src := .renewals,    dst := .notices,     kind := .event }
  ]

/-- Whether the path is a query or a command opened from the stacks toward
    the desk, which the architecture forbids. A fact the stacks publish is
    collected at the desk and is not an ask. -/
def Path.asksTheDesk (p : Path) : Bool :=
  p.src.zone == .stacks && p.dst.zone == .desk && (p.kind == .query || p.kind == .command)

theorem stacks_never_ask_the_desk : paths.all (fun p => !p.asksTheDesk) = true := by decide

/-- A path that would break the rule, to show the check bites: circulation
    asking membership who a token is. Adding it to the table fails the
    theorem, as `badPath_breaksTheRule` shows. -/
def badPath : Path := { src := .circulation, dst := .membership, kind := .query }

theorem badPath_breaksTheRule : (paths ++ [badPath]).all (fun p => !p.asksTheDesk) = false := by decide

/-! ## Cells form a cyclic graph too, and that is by design

Fines queries circulation; circulation publishes facts fines reacts to.
Choreography between cells is cyclic in the dependency graph. The acyclic
thing is each journey, and the direction rule is on the zones. -/

/-- The cells of the slice as an adjacency list: circulation 0, fines 1, holds 2, notices 3. -/
def cellGraph : List (Nat × List Nat) :=
  [ (0, [1, 3]), (1, [0, 3]), (2, [0]), (3, []) ]

theorem cellGraph_hasCycle : hasCycle cellGraph = true := by decide
