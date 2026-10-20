import Library.Architecture
/-!
# Holds queues the members waiting on a copy

From `designs/holds.md`: one record per copy, the patron tokens waiting on
it in the order they asked, each request honored once, a patron never in
the queue twice. The design owns meaning; this module owns structure and
behavior. Sources the design names: the capability map's holds row,
journey 4 of the vision, the paths table of the architecture.
-/

/-- Holds' commands. Each carries the key its sender minted before the
    first attempt, the copy, and the patron token membership put in place
    of the card. -/
inductive HoldCommand
  /-- Place a hold: the key a string the sender minted, such as "k1"; the copy's ID, such as "b-1"; the patron token, such as "P-7". -/
  | place (key item patron : String)
  /-- Cancel a hold, under a key, naming the copy and the patron. -/
  | cancel (key item patron : String)
  deriving Repr, DecidableEq

/-- Holds' facts. A placed hold says where in the queue it is, so that a
    reactor need not keep the queue to know. -/
inductive HoldEvent
  /-- A hold was placed, with its key, the copy, the patron, and the place in the queue after it, such as 1. -/
  | holdPlaced (key item patron : String) (position : Nat)
  /-- A hold was cancelled, with its key, the copy and the patron. -/
  | holdCancelled (key item patron : String)
  deriving Repr, DecidableEq, BEq

/-- Why holds says no. -/
inductive HoldRefusal
  /-- The patron is already waiting on the copy, so a second hold is refused. -/
  | alreadyWaiting
  /-- The patron is not waiting on the copy, so there is nothing to cancel. -/
  | notWaiting
  deriving Repr, DecidableEq, BEq

/-- The fold of holds' history: the queue and the keys already honored. -/
structure HoldState where
  /-- The patron tokens waiting, first first; empty before any hold, never the same token twice. -/
  waiting : List String
  /-- The keys already honored, newest first; empty before any command. -/
  seen    : List String
  deriving Repr

/-- The holds cell. The idempotent receiver is the first branch of each
    command: a key already honored produces no new event. -/
def holds : Cell HoldCommand Unit HoldEvent HoldState HoldRefusal where
  initial := { waiting := [], seen := [] }
  decide
    | .place key item patron, s =>
        if s.seen.contains key then .ok []
        else if s.waiting.contains patron then .error .alreadyWaiting
        else .ok [.holdPlaced key item patron (s.waiting.length + 1)]
    | .cancel key item patron, s =>
        if s.seen.contains key then .ok []
        else if !s.waiting.contains patron then .error .notWaiting
        else .ok [.holdCancelled key item patron]
  react := fun _ _ => []
  evolve
    | s, .holdPlaced key _ patron _  => { s with waiting := s.waiting ++ [patron], seen := key :: s.seen }
    | s, .holdCancelled key _ patron => { s with waiting := s.waiting.erase patron, seen := key :: s.seen }
  isTerminal := fun _ => false

/-! ## The examples, as theorems. Each `id` is the row in the design and the
    name of the test in code. -/

/-- The first hold on a copy is placed, first in the queue. -/
def holdPlace1 : Example HoldCommand HoldEvent HoldRefusal :=
  { id := "HOLD-PLACE-1", given := [], when := .place "k1" "b-1" "P-7",
    expect := .ok [.holdPlaced "k1" "b-1" "P-7" 1] }

/-- A retry after the answer was lost: the same key again, and nothing new is placed. -/
def holdPlace2 : Example HoldCommand HoldEvent HoldRefusal :=
  { id := "HOLD-PLACE-2 (retry after unknown)", given := [.holdPlaced "k1" "b-1" "P-7" 1],
    when := .place "k1" "b-1" "P-7", expect := .ok [] }

/-- A second hold from a patron already waiting is refused, whatever its key. -/
def holdPlace3 : Example HoldCommand HoldEvent HoldRefusal :=
  { id := "HOLD-PLACE-3 (already waiting)", given := [.holdPlaced "k1" "b-1" "P-7" 1],
    when := .place "k2" "b-1" "P-7", expect := .error .alreadyWaiting }

/-- A second patron joins the queue behind the first. -/
def holdPlace4 : Example HoldCommand HoldEvent HoldRefusal :=
  { id := "HOLD-PLACE-4 (second in the queue)", given := [.holdPlaced "k1" "b-1" "P-7" 1],
    when := .place "k2" "b-1" "P-8", expect := .ok [.holdPlaced "k2" "b-1" "P-8" 2] }

/-- A patron who cancelled may hold again, and is first on an empty queue. -/
def holdPlace5 : Example HoldCommand HoldEvent HoldRefusal :=
  { id := "HOLD-PLACE-5 (back in the queue after cancelling)",
    given := [.holdPlaced "k1" "b-1" "P-7" 1, .holdCancelled "k3" "b-1" "P-7"],
    when := .place "k4" "b-1" "P-7", expect := .ok [.holdPlaced "k4" "b-1" "P-7" 1] }

/-- A waiting patron's hold is cancelled. -/
def holdCancel1 : Example HoldCommand HoldEvent HoldRefusal :=
  { id := "HOLD-CANCEL-1", given := [.holdPlaced "k1" "b-1" "P-7" 1],
    when := .cancel "k3" "b-1" "P-7", expect := .ok [.holdCancelled "k3" "b-1" "P-7"] }

/-- A cancel from a patron who is not waiting is refused. -/
def holdCancel2 : Example HoldCommand HoldEvent HoldRefusal :=
  { id := "HOLD-CANCEL-2 (not waiting)", given := [],
    when := .cancel "k3" "b-1" "P-7", expect := .error .notWaiting }

/-- A retried cancel is quiet. -/
def holdCancel3 : Example HoldCommand HoldEvent HoldRefusal :=
  { id := "HOLD-CANCEL-3 (retry after unknown)",
    given := [.holdPlaced "k1" "b-1" "P-7" 1, .holdCancelled "k3" "b-1" "P-7"],
    when := .cancel "k3" "b-1" "P-7", expect := .ok [] }

/-- After a cancel the queue closes up: the next hold is second, not third. -/
def holdCancel4 : Example HoldCommand HoldEvent HoldRefusal :=
  { id := "HOLD-CANCEL-4 (the queue closes up)",
    given := [.holdPlaced "k1" "b-1" "P-7" 1, .holdPlaced "k2" "b-1" "P-8" 2, .holdCancelled "k3" "b-1" "P-7"],
    when := .place "k4" "b-1" "P-9", expect := .ok [.holdPlaced "k4" "b-1" "P-9" 2] }

theorem holdPlace1_holds  : holdPlace1.holds holds  = true := by decide
theorem holdPlace2_holds  : holdPlace2.holds holds  = true := by decide
theorem holdPlace3_holds  : holdPlace3.holds holds  = true := by decide
theorem holdPlace4_holds  : holdPlace4.holds holds  = true := by decide
theorem holdPlace5_holds  : holdPlace5.holds holds  = true := by decide
theorem holdCancel1_holds : holdCancel1.holds holds = true := by decide
theorem holdCancel2_holds : holdCancel2.holds holds = true := by decide
theorem holdCancel3_holds : holdCancel3.holds holds = true := by decide
theorem holdCancel4_holds : holdCancel4.holds holds = true := by decide

/-! ## Universal claims, named as the design names them -/

/-- The idempotent receiver, for every key, copy, patron and history: a hold
    whose key holds has already honored produces no new event. -/
theorem place_idempotent (key item patron : String) (s : HoldState) (hseen : key ∈ s.seen) :
    holds.decide (.place key item patron) s = .ok [] := by
  simp [holds, hseen]

/-- A hold placed on an empty queue with a fresh key is first, for every
    key, copy and patron. -/
theorem firstHold_isFirst (key item patron : String) (s : HoldState)
    (hfresh : key ∉ s.seen) (hempty : s.waiting = []) :
    holds.decide (.place key item patron) s = .ok [.holdPlaced key item patron 1] := by
  simp [holds, hfresh, hempty]

/-- The terminal predicate is pinned: a copy's queue is never done. -/
theorem holds_neverTerminal : holds.isTerminal (holds.replay [.holdPlaced "k1" "b-1" "P-7" 1]) = false := by decide

/-! ## Coverage: the examples reach every kind -/

instance : Kinded HoldCommand where
  kind | .place _ _ _ => 0 | .cancel _ _ _ => 1
  kinds := [0, 1]

instance : Kinded HoldEvent where
  kind | .holdPlaced _ _ _ _ => 0 | .holdCancelled _ _ _ => 1
  kinds := [0, 1]

instance : Kinded HoldRefusal where
  kind | .alreadyWaiting => 0 | .notWaiting => 1
  kinds := [0, 1]

/-- The example set for holds, the one the design cites. -/
def holdExamples : List (Example HoldCommand HoldEvent HoldRefusal) :=
  [holdPlace1, holdPlace2, holdPlace3, holdPlace4, holdPlace5,
   holdCancel1, holdCancel2, holdCancel3, holdCancel4]

theorem holdExamples_allHold       : holdExamples.all (·.holds holds) = true := by decide
theorem holdExamples_coverCommands : coversCommands holdExamples = true := by decide
theorem holdExamples_coverEvents   : coversEvents   holdExamples = true := by decide
theorem holdExamples_coverRefusals : coversRefusals holdExamples = true := by decide

/-! ## The wire shape, as a projection -/

/-- What the wire carries: a tag and loose optional fields, because the
    wire cannot say what the model's sum type says. -/
structure HoldWireCommand where
  /-- The tag the wire carries for the command's kind: "place" or "cancel"; any other string is a parse refusal. -/
  kind   : String
  /-- The command's key; absent is a parse refusal. -/
  key    : Option String := none
  /-- The copy's ID; absent is a parse refusal. -/
  item   : Option String := none
  /-- The patron token; absent is a parse refusal. -/
  patron : Option String := none
  deriving Repr, DecidableEq

/-- The projection onto the wire: the sum becomes a tag and optional fields. -/
def HoldCommand.serialize : HoldCommand → HoldWireCommand
  | .place key item patron  => { kind := "place",  key := some key, item := some item, patron := some patron }
  | .cancel key item patron => { kind := "cancel", key := some key, item := some item, patron := some patron }

/-- The three fields every command carries, or the first that is missing. -/
def HoldWireCommand.keyed (w : HoldWireCommand)
    (make : String → String → String → HoldCommand) : Except ParseRefusal HoldCommand :=
  match w.key, w.item, w.patron with
  | some key, some item, some patron => .ok (make key item patron)
  | none, _, _ => .error (.missingField "key")
  | _, none, _ => .error (.missingField "item")
  | _, _, none => .error (.missingField "patron")

/-- The parse back, with the loss as refusals: a missing field or an unknown tag. -/
def HoldCommand.parse (w : HoldWireCommand) : Except ParseRefusal HoldCommand :=
  match w.kind with
  | "place"  => w.keyed HoldCommand.place
  | "cancel" => w.keyed HoldCommand.cancel
  | other    => .error (.unknownKind other)

/-- The codec, with its round trip proved by cases: the instance cannot
    exist without it. -/
instance : WireCodec HoldCommand HoldWireCommand where
  serialize := HoldCommand.serialize
  parse := HoldCommand.parse
  parse_serialize := by intro c; cases c <;> rfl

/-- The loss list, as refusals: what the wire can carry that the model will not. -/
theorem parse_missingPatron :
    HoldCommand.parse { kind := "place", key := some "k1", item := some "b-1" } = .error (.missingField "patron") := by rfl
theorem parse_unknownHoldKind :
    HoldCommand.parse { kind := "reserve" } = .error (.unknownKind "reserve") := by rfl

/-! ## The wire renderings the fixtures carry -/

instance : JsonEncode HoldWireCommand where
  toJson w :=
    let key := match w.key with | some k => ",\"key\":\"" ++ k ++ "\"" | none => ""
    let item := match w.item with | some i => ",\"item\":\"" ++ i ++ "\"" | none => ""
    let patron := match w.patron with | some p => ",\"patron\":\"" ++ p ++ "\"" | none => ""
    "{\"kind\":\"" ++ w.kind ++ "\"" ++ key ++ item ++ patron ++ "}"

instance : JsonEncode HoldEvent where
  toJson
    | .holdPlaced k i p n  => "{\"kind\":\"holdPlaced\",\"key\":\"" ++ k ++ "\",\"item\":\"" ++ i ++ "\",\"patron\":\"" ++ p ++ "\",\"position\":" ++ toString n ++ "}"
    | .holdCancelled k i p => "{\"kind\":\"holdCancelled\",\"key\":\"" ++ k ++ "\",\"item\":\"" ++ i ++ "\",\"patron\":\"" ++ p ++ "\"}"

instance : JsonEncode HoldRefusal where
  toJson
    | .alreadyWaiting => "\"alreadyWaiting\""
    | .notWaiting     => "\"notWaiting\""

/-! ## The wire readings the trace checker uses, the encoders' inverses -/

instance : JsonDecode HoldWireCommand where
  fromJson j := do
    return { kind := ← Replay.strField j "kind"
           , key := (Replay.strField j "key").toOption
           , item := (Replay.strField j "item").toOption
           , patron := (Replay.strField j "patron").toOption }

instance : JsonDecode HoldEvent where
  fromJson j := do
    match ← Replay.strField j "kind" with
    | "holdPlaced"    => return .holdPlaced (← Replay.strField j "key") (← Replay.strField j "item") (← Replay.strField j "patron") (← Replay.natField j "position")
    | "holdCancelled" => return .holdCancelled (← Replay.strField j "key") (← Replay.strField j "item") (← Replay.strField j "patron")
    | other           => throw s!"unknown hold kind \"{other}\""

instance : JsonDecode HoldRefusal where
  fromJson j := do
    match ← j.getStr? with
    | "alreadyWaiting" => return .alreadyWaiting
    | "notWaiting"     => return .notWaiting
    | other            => throw s!"unknown refusal \"{other}\""

/-! ## The sentences a reader reviews -/

instance : Describe HoldCommand where
  describe
    | .place key item patron  => s!"a hold arrives with key {key} for copy {item} from patron {patron}"
    | .cancel key item patron => s!"a cancel arrives with key {key} for copy {item} from patron {patron}"

instance : Describe HoldEvent where
  describe
    | .holdPlaced key item patron n  => s!"patron {patron} is waiting on copy {item} under key {key}, {n} in the queue"
    | .holdCancelled key item patron => s!"patron {patron}'s hold on copy {item} was cancelled under key {key}"

instance : Describe HoldRefusal where
  describe
    | .alreadyWaiting => "it is refused because the patron is already waiting"
    | .notWaiting     => "it is refused because the patron is not waiting"

/-! ## The journey, the contract, the attribute and the actor policy -/

/-- The design's one-step journey: holds decides on the command. -/
def holdsJourney (command : HoldCommand) : Journey (List HoldEvent) HoldRefusal :=
  .step "holds decides" fun h => do
    let es ← holds.handle h command
    pure (h ++ es)

/-- The step's contract, from the design's Contracts table. -/
def holdsContracts : Contracts := fun name =>
  match name with
  | "holds decides" => { latencyMs := 30, unavailabilityPpm := 20, costMicros := 4, peakUnits := 2 }
  | _               => { latencyMs := 0,  unavailabilityPpm := 0,  costMicros := 0, peakUnits := 0 }

/-- The journey's latency bound is its one step's. -/
theorem holdsJourney_latency :
    (holdsJourney (.place "k1" "b-1" "P-7")).latencyBound holdsContracts = 30 := by rfl

/-- Whether a command is a hold being placed. -/
def HoldCommand.isPlace : HoldCommand → Bool
  | .place _ _ _ => true
  | _ => false

/-- Whether a fact is a hold placed. -/
def HoldEvent.isPlaced : HoldEvent → Bool
  | .holdPlaced _ _ _ _ => true
  | _ => false

/-- The promise from the design's Attributes table: a hold acknowledged
    within a minute of the request. -/
def holdAcknowledgedWithinMinute : RunPromise HoldCommand HoldEvent (PatronId .stacks) :=
  withinDuration HoldCommand.isPlace HoldEvent.isPlaced 60000

/-- The design's row as an attribute: a population promise at 99 per cent,
    over the patron in the stacks. -/
def holdAcknowledgedAttribute : Attribute HoldCommand HoldEvent (PatronId .stacks) :=
  .population "a hold acknowledged within a minute of the request" holdAcknowledgedWithinMinute 99

/-- Holds' actor policy, from the sender column: a member places and
    cancels, a librarian does either on the member's behalf, nobody else. -/
def holdsActorPolicy : ActorPolicy HoldCommand
  | .principal ⟨_, .member⟩,    _ => true
  | .principal ⟨_, .librarian⟩, _ => true
  | _, _ => false

theorem holdsActorPolicy_memberPlaces :
    holdsActorPolicy (.principal ⟨⟨"C-1041"⟩, .member⟩) (.place "k1" "b-1" "P-7") = true := by decide
theorem holdsActorPolicy_guestRefused :
    holdsActorPolicy (.principal ⟨⟨"C-2002"⟩, .guest⟩) (.place "k1" "b-1" "P-7") = false := by decide
