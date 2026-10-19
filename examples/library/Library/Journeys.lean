import Library.Circulation
/-!
# A journey across two cells, and the hold shelf's fan-in

The member's checkout is the root command. Circulation decides; its facts
fan out to notices, which reacts. Nothing commands back. Then pickup, the
cell that waits for two facts in either order.
-/

/-- The journey by hand, as a `do` block in `Except`. It cannot loop, by
    totality, and no reaction can issue a command, by the type. -/
def borrowJourney (circulationHistory : List CirculationEvent) (noticeHistory : List NoticeEvent)
    (command : CirculationCommand) : Except CirculationRefusal (List CirculationEvent × List NoticeEvent) := do
  let facts ← circulation.handle circulationHistory command
  let raised := facts.foldl (fun acc f => acc ++ notices.handleForeign noticeHistory f) []
  pure (facts, raised)

theorem borrowJourney_quiet :
    borrowJourney [] [] (.checkOut "k1" "b-1") = .ok ([.checkedOut "k1" "b-1" 1], []) := by rfl

theorem borrowJourney_warns :
    borrowJourney (fiveOut.take 4) [] (.checkOut "k5" "b-5")
      = .ok ([.checkedOut "k5" "b-5" 5], [.limitWarning "b-5" 5]) := by rfl

theorem borrowJourney_refused :
    borrowJourney [.cardClosed] [] (.checkOut "k1" "b-1") = .error .cardClosed := by rfl

/-- The product of the two cells' histories: the journey's state. -/
abbrev Shelf := List CirculationEvent × List NoticeEvent

/-- The same journey as a term of the algebra. Its compiled graph is well
    formed by `compile_wellFormed`, not by a separate check. -/
def borrowJourneyTerm (command : CirculationCommand) : Journey Shelf CirculationRefusal :=
  .seq (.step "circulation decides" fun (ch, nh) => do
          let es ← circulation.handle ch command; pure (ch ++ es, nh))
       (.step "notices reacts" fun (ch, nh) =>
          pure (ch, nh ++ ch.foldl (fun acc f => acc ++ notices.handleForeign nh f) []))

theorem borrowJourneyTerm_warns :
    (borrowJourneyTerm (.checkOut "k5" "b-5")).run (fiveOut.take 4, [])
      = .ok (fiveOut, [.limitWarning "b-5" 5]) := by rfl

-- Governance: the hand-written journey's theorem is superseded by the term's.
-- It stays, and any use of it warns and names the successor; nothing is deleted.
attribute [deprecated borrowJourneyTerm_warns (since := "2026-10-19")] borrowJourney_warns

/-- The slice's contracts, by step name, from the design's Contracts table. -/
def sliceContracts : Contracts := fun name =>
  match name with
  | "circulation decides" => { latencyMs := 30, unavailabilityPpm := 20,  costMicros := 4, peakUnits := 2 }
  | "notices reacts"      => { latencyMs := 10, unavailabilityPpm := 100, costMicros := 2, peakUnits := 1 }
  | _                     => { latencyMs := 0,  unavailabilityPpm := 0,   costMicros := 0, peakUnits := 0 }

/-- The journey's bounds, folded from its steps' contracts. -/
theorem borrowJourneyTerm_latency :
    (borrowJourneyTerm (.checkOut "k1" "b-1")).latencyBound sliceContracts = 40 := by rfl
theorem borrowJourneyTerm_budget :
    (borrowJourneyTerm (.checkOut "k1" "b-1")).unavailabilityBudget sliceContracts = 120 := by rfl

theorem borrowJourneyTerm_dag :
    Journey.nodesOk 0 ((borrowJourneyTerm (.checkOut "k1" "b-1")).compile 0 []).1 = true := by
  exact (Journey.compile_wellFormed _ 0 [] rfl).1

/-! ## Choreography realizes composition: fan-in with memory

In the composite function, the hold shelf is a function of two arguments
and time is gone. In the world the two facts arrive one at a time, in
either order, and the reacting cell must remember the first while waiting
for the second. -/

/-- What circulation and holds each publish about a copy, as pickup sees them. -/
inductive ShelfFact
  /-- Circulation's fact: the copy came in. -/
  | returned (item : String)
  /-- Holds' fact: a hold is waiting on the copy. -/
  | held (item : String)
  deriving Repr, DecidableEq

/-- Pickup's facts: each arrival seen, and the copy ready once both are in. -/
inductive PickupEvent
  /-- Pickup saw the copy come in. -/
  | sawReturn (item : String)
  /-- Pickup saw a hold waiting on the copy. -/
  | sawHold (item : String)
  /-- The copy is on the hold shelf: it came in and a hold was waiting. -/
  | readyForPickup (item : String)
  deriving Repr, DecidableEq, BEq

/-- What pickup remembers about one copy: whether it has come in and
    whether a hold is waiting, until both are true. -/
structure PickupState where
  /-- Whether the copy has come in; false until circulation's fact arrives. -/
  returned : Bool
  /-- Whether a hold is waiting; false until holds' fact arrives. -/
  held     : Bool
  deriving Repr

/-- Fan-in with memory, one record per copy. The first fact is remembered;
    the second completes it. -/
def pickup : Cell Unit ShelfFact PickupEvent PickupState Empty where
  initial := { returned := false, held := false }
  decide := fun _ _ => .ok []
  react
    | .returned item, s => if s.held then [.sawReturn item, .readyForPickup item] else [.sawReturn item]
    | .held item, s     => if s.returned then [.sawHold item, .readyForPickup item] else [.sawHold item]
  evolve
    | s, .sawReturn _      => { s with returned := true }
    | s, .sawHold _        => { s with held := true }
    | s, .readyForPickup _ => s
  isTerminal := fun s => s.returned && s.held

/-- The denotation: the copy ready, as a function of both facts. -/
def ready (item : String) : List PickupEvent := [.readyForPickup item]

/-- Whether a fact is the copy ready. -/
def PickupEvent.isReady : PickupEvent → Bool
  | .readyForPickup _ => true
  | _ => false

/-- The operational reading computes the denotational one, in either order,
    for every copy. -/
theorem deliver_returnFirst (item : String) :
    (pickup.deliver [] [.returned item, .held item]).filter PickupEvent.isReady = ready item := by
  simp [Cell.deliver, Cell.handleForeign, Cell.replay, pickup, ready, PickupEvent.isReady]

theorem deliver_holdFirst (item : String) :
    (pickup.deliver [] [.held item, .returned item]).filter PickupEvent.isReady = ready item := by
  simp [Cell.deliver, Cell.handleForeign, Cell.replay, pickup, ready, PickupEvent.isReady]

/-- And the fan-in fires exactly once: nothing is ready after one fact alone. -/
theorem deliver_oneFact_notReady (item : String) :
    (pickup.deliver [] [.returned item]).filter PickupEvent.isReady = [] := by
  simp [Cell.deliver, Cell.handleForeign, Cell.replay, pickup, PickupEvent.isReady]

/-- The return came first; the hold completes it. -/
def pickup1 : ReactionExample ShelfFact PickupEvent :=
  { id := "PICKUP-1 (the return first)", given := [.sawReturn "b-1"],
    when := .held "b-1", expect := [.sawHold "b-1", .readyForPickup "b-1"] }

/-- The hold came first; the return completes it. -/
def pickup2 : ReactionExample ShelfFact PickupEvent :=
  { id := "PICKUP-2 (the hold first)", given := [.sawHold "b-1"],
    when := .returned "b-1", expect := [.sawReturn "b-1", .readyForPickup "b-1"] }

/-- One fact alone readies nothing. -/
def pickup3 : ReactionExample ShelfFact PickupEvent :=
  { id := "PICKUP-3 (one alone)", given := [],
    when := .returned "b-1", expect := [.sawReturn "b-1"] }

theorem pickup1_holds : pickup1.holds pickup = true := by decide
theorem pickup2_holds : pickup2.holds pickup = true := by decide
theorem pickup3_holds : pickup3.holds pickup = true := by decide
