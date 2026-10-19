import Library.Circulation
/-!
# Fines decides on circulation's answer and the clock

Circulation's first query, stamped with its version; a fines cell that
assesses a late item on it and on the day it is; the shell as the one
caller of either.
-/

/-- Circulation's version: how many commands it has honored. The loan
    record's lock version; the count is its proxy here. -/
def CirculationState.version (s : CirculationState) : Nat := s.seen.length

/-- Circulation's query: whether a copy is still out, stamped. -/
def stillOut (item : String) : Query CirculationState (Answer Bool) :=
  fun s => { value := s.onLoan.contains item, asOf := s.version }

/-- Stale: the owner has moved on since the answer was read. The owner
    checks this when the decision's command lands, not the decider. -/
def CirculationState.stale (s : CirculationState) (asOf : Nat) : Bool := asOf != s.version

/-- An answer is fresh against the state it was read from. -/
theorem stillOut_fresh (item : String) (s : CirculationState) :
    s.stale (stillOut item s).asOf = false := by
  simp [CirculationState.stale, stillOut]

/-- And stale against that state after any return, for every key and copy. -/
theorem stillOut_staleAfterCheckIn (item : String) (s : CirculationState) (key item' : String) :
    (circulation.evolve s (.checkedIn key item')).stale (stillOut item s).asOf = true := by
  simp [CirculationState.stale, stillOut, circulation, CirculationState.version]

/-- Fines' commands: assess an item that may be late, or settle what is owed. -/
inductive FineCommand
  /-- Assess this copy against the calendar day it was due, such as day 30. -/
  | assess (item : String) (dueDay : Nat)
  /-- Settle what is owed on this copy, by payment or write-off. -/
  | settle (item : String)
  deriving Repr, DecidableEq

/-- Fines' facts. An assessment records the circulation version it was decided on. -/
inductive FineEvent
  /-- A fine was assessed on this copy for this many days late, decided on circulation at this version; `asOf` is circulation's version when the answer was read, such as 3. -/
  | fineAssessed (item : String) (daysLate asOf : Nat)
  /-- What was owed on this copy was settled. -/
  | fineSettled (item : String)
  deriving Repr, DecidableEq, BEq

/-- Why fines says no: the copy is back, or it is not late. -/
inductive FineRefusal
  /-- Circulation says the copy is no longer out, so there is nothing to assess. -/
  | alreadyReturned (item : String)
  /-- Today is not past the due day, so there is nothing to assess yet. -/
  | notOverdue (item : String)
  deriving Repr, DecidableEq, BEq

/-- The queries fines may ask for. -/
inductive QueryName
  /-- Whether the copy is still out, as `stillOut` answers it, stamped. -/
  | stillOut
  deriving Repr, DecidableEq

/-- The record of answers fines' decider may read. -/
structure FineAnswers where
  /-- Whether the copy is still out, with the version it was read at, such as true as of 3. -/
  stillOut : Answer Bool
  deriving Repr

/-- What the shell must gather for each command, declared. -/
def FineCommand.needs : FineCommand → List QueryName
  | .assess _ _ => [.stillOut]
  | .settle _   => []

/-- The copy a command is about, which the shell queries for. -/
def FineCommand.item : FineCommand → String
  | .assess item _ => item
  | .settle item   => item

/-- Fines' projection: the copies with a fine open. -/
structure FineState where
  /-- The copies with a fine open, newest first; empty before any. -/
  owed : List String
  deriving Repr

/-- A day in milliseconds, for reading the clock as a calendar day. -/
def dayMs : Nat := 86400000

/-- The calendar day of a clock reading: whole days since the epoch. -/
def Instant.day (t : Instant) : Nat := t.ms / dayMs

/-- The fines cell, deciding on inputs: the command, the answers, the clock.
    An item is late the day after its due day; the days late are recorded,
    and the amount is the rate in the defaults times the days. -/
def fines : Cell (Inputs FineCommand FineAnswers) Unit FineEvent FineState FineRefusal where
  initial := { owed := [] }
  decide := fun i _ =>
    match i.command.payload with
    | .assess item dueDay =>
        if !i.answers.stillOut.value then .error (.alreadyReturned item)
        else if i.now.day ≤ dueDay then .error (.notOverdue item)
        else .ok [.fineAssessed item (i.now.day - dueDay) i.answers.stillOut.asOf]
    | .settle item => .ok [.fineSettled item]
  react := fun _ _ => []
  evolve
    | s, .fineAssessed item _ _ => { s with owed := item :: s.owed }
    | s, .fineSettled item      => { s with owed := s.owed.erase item }
  isTerminal := fun _ => false

/-- A command that declares no query reads none: the decision is the same
    whatever the shell gathered and whatever time it was. -/
theorem settle_readsNothing (c : CommandEnvelope FineCommand) (item : String)
    (hc : c.payload = .settle item) (q q' : FineAnswers) (t t' : Instant) (s : FineState) :
    fines.decide { command := c, answers := q, now := t } s
      = fines.decide { command := c, answers := q', now := t' } s := by
  simp [fines, hc]

/-- The shell: read the owner, read the clock, then decide. The one place a
    query is called, and it is outside every decider. -/
def assessJourney (circulationHistory : List CirculationEvent) (fineHistory : List FineEvent)
    (command : CommandEnvelope FineCommand) (now : Instant) :
    Except FineRefusal (List FineEvent) :=
  let answers : FineAnswers :=
    { stillOut := stillOut command.payload.item (circulation.replay circulationHistory) }
  fines.handle fineHistory { command := command, answers := answers, now := now }

/-- What an assessment records as its basis is circulation's version at the
    time it was read, for every pair of histories, every copy and every day. -/
theorem assess_recordsCirculationsVersion (ch : List CirculationEvent) (fh : List FineEvent)
    (c : CommandEnvelope FineCommand) (item : String) (dueDay : Nat)
    (hc : c.payload = .assess item dueDay) (now : Instant) (es : List FineEvent)
    (h : assessJourney ch fh c now = .ok es) :
    es = [.fineAssessed item (now.day - dueDay) (circulation.replay ch).version] := by
  simp only [assessJourney, Cell.handle, fines, hc, stillOut, FineCommand.item] at h
  split at h
  · exact absurd h (by simp)
  · split at h
    · exact absurd h (by simp)
    · simpa using h.symm

/-- The schedule's assessment, as the timer, with a minted key, in the shared run. -/
def timerAssess (item : String) (dueDay : Nat) : CommandEnvelope FineCommand :=
  { actor := .timer, key := .minted "a1", causation := none,
    correlation := firstRun, issuedAt := epoch, payload := .assess item dueDay }

/-- A member settling, with a minted key, in the shared run. -/
def memberSettle (item : String) : CommandEnvelope FineCommand :=
  { actor := .principal ⟨⟨"C-1041"⟩, .member⟩, key := .minted "s1", causation := none,
    correlation := firstRun, issuedAt := epoch, payload := .settle item }

/-- Examples gain a *with* clause: the answers the shell supplied are in the When. -/
def fineAssess1 : Example (Inputs FineCommand FineAnswers) FineEvent FineRefusal :=
  { id := "FINE-ASSESS-1 (three days late)", given := [],
    when := { command := timerAssess "b-1" 30, answers := { stillOut := ⟨true, 3⟩ }, now := ⟨33 * dayMs⟩ },
    expect := .ok [.fineAssessed "b-1" 3 3] }

/-- On the due day itself there is nothing to assess. -/
def fineAssess2 : Example (Inputs FineCommand FineAnswers) FineEvent FineRefusal :=
  { id := "FINE-ASSESS-2 (not overdue)", given := [],
    when := { command := timerAssess "b-1" 30, answers := { stillOut := ⟨true, 3⟩ }, now := ⟨30 * dayMs⟩ },
    expect := .error (.notOverdue "b-1") }

/-- A copy that is back is not assessed, however late the day. -/
def fineAssess3 : Example (Inputs FineCommand FineAnswers) FineEvent FineRefusal :=
  { id := "FINE-ASSESS-3 (already returned)", given := [],
    when := { command := timerAssess "b-1" 30, answers := { stillOut := ⟨false, 4⟩ }, now := ⟨33 * dayMs⟩ },
    expect := .error (.alreadyReturned "b-1") }

/-- Settling publishes the settlement, reading nothing. -/
def fineSettle1 : Example (Inputs FineCommand FineAnswers) FineEvent FineRefusal :=
  { id := "FINE-SETTLE-1", given := [.fineAssessed "b-1" 3 3],
    when := { command := memberSettle "b-1", answers := { stillOut := ⟨false, 5⟩ }, now := ⟨40 * dayMs⟩ },
    expect := .ok [.fineSettled "b-1"] }

theorem fineAssess1_holds : fineAssess1.holds fines = true := by decide
theorem fineAssess2_holds : fineAssess2.holds fines = true := by decide
theorem fineAssess3_holds : fineAssess3.holds fines = true := by decide
theorem fineSettle1_holds : fineSettle1.holds fines = true := by decide
