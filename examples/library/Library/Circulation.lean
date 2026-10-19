import Library.Architecture
/-!
# Circulation lends, notices warns

From `designs/circulation.md`: the loans on a card, each request booked
once, the limit of five, a closed card that takes no new loans; and
notices, which keeps a warning level and warns when a checkout takes the
card over it. The shape is what matters; the design owns the real one.
-/

/-- Circulation's commands. Each carries the key its sender minted before
    the first attempt, so that a retry is nothing new. -/
inductive CirculationCommand
  /-- Check an item out: the key a string the sender minted, such as "k1"; the item the copy's ID, such as "b-1". -/
  | checkOut (key item : String)
  /-- Check an item in, under a key and naming the copy. -/
  | checkIn (key item : String)
  /-- Renew a loan, under a key and naming the copy. -/
  | renew (key item : String)
  /-- Close the card, after which every checkout and renewal is refused. -/
  | closeCard
  deriving Repr, DecidableEq

/-- Circulation's facts. A checkout says how many items the card now
    holds, so that a reactor need not keep the loans to know. -/
inductive CirculationEvent
  /-- An item was checked out, with its key, the copy, and the number on loan after it, such as 5. -/
  | checkedOut (key item : String) (onLoan : Nat)
  /-- An item was checked in, with its key and the copy. -/
  | checkedIn (key item : String)
  /-- A loan was renewed, with its key and the copy. -/
  | renewed (key item : String)
  /-- The card was closed. -/
  | cardClosed
  deriving Repr, DecidableEq, BEq

/-- Why circulation says no. -/
inductive CirculationRefusal
  /-- The card is closed, so the checkout or renewal is refused whatever its key. -/
  | cardClosed
  /-- Five items are already on loan, so the checkout is refused. -/
  | limitReached
  /-- The copy is not on loan, so there is nothing to check in or renew. -/
  | notOnLoan
  deriving Repr, DecidableEq, BEq

/-- The fold of circulation's history: the items on loan, the keys already
    honored, and whether the card is closed. -/
structure CirculationState where
  /-- The items on loan, newest first; empty before any checkout, never more than five. -/
  onLoan : List String
  /-- The keys already honored, newest first; empty before any command. -/
  seen   : List String
  /-- Whether the card is closed: false until the close and true forever after. -/
  closed : Bool
  deriving Repr

/-- The loan limit from the design's defaults: five items on a card. -/
def loanLimit : Nat := 5

/-- The circulation cell. The idempotent receiver is the second branch of
    each of the first three commands: a key already honored produces no
    new event. -/
def circulation : Cell CirculationCommand Unit CirculationEvent CirculationState CirculationRefusal where
  initial := { onLoan := [], seen := [], closed := false }
  decide
    | .checkOut key item, s =>
        if s.closed then .error .cardClosed
        else if s.seen.contains key then .ok []
        else if s.onLoan.length ≥ loanLimit then .error .limitReached
        else .ok [.checkedOut key item (s.onLoan.length + 1)]
    | .checkIn key item, s =>
        if s.seen.contains key then .ok []
        else if !s.onLoan.contains item then .error .notOnLoan
        else .ok [.checkedIn key item]
    | .renew key item, s =>
        if s.closed then .error .cardClosed
        else if s.seen.contains key then .ok []
        else if !s.onLoan.contains item then .error .notOnLoan
        else .ok [.renewed key item]
    | .closeCard, s =>
        if s.closed then .ok [] else .ok [.cardClosed]
  react := fun _ _ => []
  evolve
    | s, .checkedOut key item _ => { s with onLoan := item :: s.onLoan, seen := key :: s.seen }
    | s, .checkedIn key item    => { s with onLoan := s.onLoan.erase item, seen := key :: s.seen }
    | s, .renewed key _         => { s with seen := key :: s.seen }
    | s, .cardClosed            => { s with closed := true }
  isTerminal := fun s => s.closed

/-- Notices' facts: the card is at its limit, or the level was set. -/
inductive NoticeEvent
  /-- The card is at its limit after this copy, with the number on loan. -/
  | limitWarning (item : String) (onLoan : Nat)
  /-- The warning level was set, to this many items. -/
  | warningLevelSet (level : Nat)
  deriving Repr, DecidableEq, BEq

/-- Notices' one command: set the level a checkout must take the card over to warn. -/
inductive NoticeCommand
  /-- Set the warning level; a count of items, such as 4. -/
  | setWarningLevel (level : Nat)
  deriving Repr, DecidableEq

/-- Notices' projection: the warning level, 4 before any is set, so that
    the fifth item warns. -/
structure NoticeState where
  /-- The level a checkout must take the card over to warn; 4 before any is set. -/
  warnAt : Nat
  deriving Repr

/-- Notices subscribes to circulation's facts and keeps its own projection,
    a warning level. It emits its own facts and commands nothing. -/
def notices : Cell NoticeCommand CirculationEvent NoticeEvent NoticeState Empty where
  initial := { warnAt := 4 }
  decide
    | .setWarningLevel level, _ => .ok [.warningLevelSet level]
  react
    | .checkedOut _ item onLoan, s => if onLoan > s.warnAt then [.limitWarning item onLoan] else []
    | .checkedIn _ _, _  => []
    | .renewed _ _, _    => []
    | .cardClosed, _     => []
  evolve
    | s, .warningLevelSet level => { s with warnAt := level }
    | s, .limitWarning _ _      => s
  isTerminal := fun _ => false

/-! ## The examples, as theorems. Each `id` is the row in the design and the
    name of the test in code. -/

/-- Five checkouts, the card full. -/
def fiveOut : List CirculationEvent :=
  [.checkedOut "k1" "b-1" 1, .checkedOut "k2" "b-2" 2, .checkedOut "k3" "b-3" 3,
   .checkedOut "k4" "b-4" 4, .checkedOut "k5" "b-5" 5]

/-- The first checkout on an open card is booked, one on loan. -/
def loanOut1 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-OUT-1", given := [], when := .checkOut "k1" "b-1",
    expect := .ok [.checkedOut "k1" "b-1" 1] }

/-- A retry after the answer was lost: the same key again, and nothing new is booked. -/
def loanOut2 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-OUT-2 (retry after unknown)", given := [.checkedOut "k1" "b-1" 1],
    when := .checkOut "k1" "b-1", expect := .ok [] }

/-- A checkout on a closed card is refused, whatever its key. -/
def loanOut3 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-OUT-3 (refused, card closed)", given := [.cardClosed],
    when := .checkOut "k2" "b-2", expect := .error .cardClosed }

/-- The sixth checkout is refused. -/
def loanOut4 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-OUT-4 (the sixth is refused)", given := fiveOut,
    when := .checkOut "k6" "b-6", expect := .error .limitReached }

/-- The fifth checkout is fine: the limit is five, not four. -/
def loanOut5 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-OUT-5 (the fifth is fine)", given := fiveOut.take 4,
    when := .checkOut "k5" "b-5", expect := .ok [.checkedOut "k5" "b-5" 5] }

/-- A return of an item on loan is recorded. -/
def loanIn1 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-IN-1", given := [.checkedOut "k1" "b-1" 1],
    when := .checkIn "k2" "b-1", expect := .ok [.checkedIn "k2" "b-1"] }

/-- A return of an item that is not on loan is refused. -/
def loanIn2 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-IN-2 (not on loan)", given := [],
    when := .checkIn "k2" "b-9", expect := .error .notOnLoan }

/-- A retried return is quiet. -/
def loanIn3 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-IN-3 (retry after unknown)",
    given := [.checkedOut "k1" "b-1" 1, .checkedIn "k2" "b-1"],
    when := .checkIn "k2" "b-1", expect := .ok [] }

/-- A closed card's item still comes back. -/
def loanIn4 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-IN-4 (a closed card's item comes back)",
    given := [.checkedOut "k1" "b-1" 1, .cardClosed],
    when := .checkIn "k2" "b-1", expect := .ok [.checkedIn "k2" "b-1"] }

/-- A renewal of an item on loan is recorded. -/
def loanRenew1 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-RENEW-1", given := [.checkedOut "k1" "b-1" 1],
    when := .renew "k3" "b-1", expect := .ok [.renewed "k3" "b-1"] }

/-- A renewal of an item that is not on loan is refused. -/
def loanRenew2 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-RENEW-2 (not on loan)", given := [],
    when := .renew "k3" "b-9", expect := .error .notOnLoan }

/-- The first close of an open card publishes the close. -/
def loanClose1 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-CLOSE-1", given := [], when := .closeCard, expect := .ok [.cardClosed] }

/-- A close of an already-closed card is quiet, so a mutant that published
    the close again would not survive. -/
def loanClose3 : Example CirculationCommand CirculationEvent CirculationRefusal :=
  { id := "LOAN-CLOSE-3 (already closed, quiet)", given := [.cardClosed],
    when := .closeCard, expect := .ok [] }

/-- Setting the level publishes it; notices' one command, with no refusal. -/
def noticeLevel1 : Example NoticeCommand NoticeEvent Empty :=
  { id := "NOTICE-LEVEL-1", given := [], when := .setWarningLevel 9,
    expect := .ok [.warningLevelSet 9] }

/-- The fifth item takes the card over the default level and warns. -/
def noticeWarn1 : ReactionExample CirculationEvent NoticeEvent :=
  { id := "NOTICE-WARN-1", given := [],
    when := .checkedOut "k5" "b-5" 5, expect := [.limitWarning "b-5" 5] }

/-- The first item is quiet. -/
def noticeWarn2 : ReactionExample CirculationEvent NoticeEvent :=
  { id := "NOTICE-WARN-2 (quiet)", given := [],
    when := .checkedOut "k1" "b-1" 1, expect := [] }

/-- At the level, quiet: the warning is for the item that goes over it. -/
def noticeWarn3 : ReactionExample CirculationEvent NoticeEvent :=
  { id := "NOTICE-WARN-3 (at the level, quiet)", given := [],
    when := .checkedOut "k4" "b-4" 4, expect := [] }

/-- With the level raised, the fifth item is quiet. -/
def noticeWarn4 : ReactionExample CirculationEvent NoticeEvent :=
  { id := "NOTICE-WARN-4 (the level raised)", given := [.warningLevelSet 9],
    when := .checkedOut "k5" "b-5" 5, expect := [] }

/-- A return is quiet. -/
def noticeIn1 : ReactionExample CirculationEvent NoticeEvent :=
  { id := "NOTICE-IN-1 (a return is quiet)", given := [],
    when := .checkedIn "k2" "b-1", expect := [] }

/-- A renewal is quiet. -/
def noticeRenew1 : ReactionExample CirculationEvent NoticeEvent :=
  { id := "NOTICE-RENEW-1 (a renewal is quiet)", given := [],
    when := .renewed "k3" "b-1", expect := [] }

/-- The close is quiet, and nothing but this row pins it. -/
def noticeClose1 : ReactionExample CirculationEvent NoticeEvent :=
  { id := "NOTICE-CLOSE-1 (the close is quiet)", given := [],
    when := .cardClosed, expect := [] }

theorem loanOut1_holds   : loanOut1.holds circulation   = true := by decide
theorem loanOut2_holds   : loanOut2.holds circulation   = true := by decide
theorem loanOut3_holds   : loanOut3.holds circulation   = true := by decide
theorem loanOut4_holds   : loanOut4.holds circulation   = true := by decide
theorem loanOut5_holds   : loanOut5.holds circulation   = true := by decide
theorem loanIn1_holds    : loanIn1.holds circulation    = true := by decide
theorem loanIn2_holds    : loanIn2.holds circulation    = true := by decide
theorem loanIn3_holds    : loanIn3.holds circulation    = true := by decide
theorem loanIn4_holds    : loanIn4.holds circulation    = true := by decide
theorem loanRenew1_holds : loanRenew1.holds circulation = true := by decide
theorem loanRenew2_holds : loanRenew2.holds circulation = true := by decide
theorem loanClose1_holds : loanClose1.holds circulation = true := by decide
theorem loanClose3_holds : loanClose3.holds circulation = true := by decide
theorem noticeLevel1_holds : noticeLevel1.holds notices = true := by decide
theorem noticeWarn1_holds  : noticeWarn1.holds notices  = true := by decide
theorem noticeWarn2_holds  : noticeWarn2.holds notices  = true := by decide
theorem noticeWarn3_holds  : noticeWarn3.holds notices  = true := by decide
theorem noticeWarn4_holds  : noticeWarn4.holds notices  = true := by decide
theorem noticeIn1_holds    : noticeIn1.holds notices    = true := by decide
theorem noticeRenew1_holds : noticeRenew1.holds notices = true := by decide
theorem noticeClose1_holds : noticeClose1.holds notices = true := by decide

/-- The idempotent receiver, for every key, item and history: a checkout
    whose key circulation has already honored produces no new event,
    unless the card is closed, in which case it is refused like any other. -/
theorem checkOut_idempotent (key item : String) (s : CirculationState)
    (hseen : key ∈ s.seen) (hopen : s.closed = false) :
    circulation.decide (.checkOut key item) s = .ok [] := by
  simp [circulation, hseen, hopen]

/-- A closed card takes no new loan, for every key, item and history,
    whatever is on loan and whatever keys were honored. -/
theorem closed_refusesCheckOut (key item : String) (s : CirculationState)
    (h : s.closed = true) :
    circulation.decide (.checkOut key item) s = .error .cardClosed := by
  simp [circulation, h]

/-- The terminal predicate is pinned: open at first, terminal once closed. -/
theorem circulation_notTerminalInitially : circulation.isTerminal circulation.initial = false := by decide
theorem circulation_terminalWhenClosed :
    circulation.isTerminal (circulation.replay [.cardClosed]) = true := by decide

/-! ## Coverage: the examples reach every kind -/

instance : Kinded CirculationCommand where
  kind | .checkOut _ _ => 0 | .checkIn _ _ => 1 | .renew _ _ => 2 | .closeCard => 3
  kinds := [0, 1, 2, 3]

instance : Kinded CirculationEvent where
  kind | .checkedOut _ _ _ => 0 | .checkedIn _ _ => 1 | .renewed _ _ => 2 | .cardClosed => 3
  kinds := [0, 1, 2, 3]

instance : Kinded CirculationRefusal where
  kind | .cardClosed => 0 | .limitReached => 1 | .notOnLoan => 2
  kinds := [0, 1, 2]

/-- The example set for the circulation slice, the one the design cites. -/
def circulationExamples : List (Example CirculationCommand CirculationEvent CirculationRefusal) :=
  [loanOut1, loanOut2, loanOut3, loanOut4, loanOut5, loanIn1, loanIn2, loanIn3, loanIn4,
   loanRenew1, loanRenew2, loanClose1, loanClose3]

theorem circulationExamples_allHold       : circulationExamples.all (·.holds circulation) = true := by decide
theorem circulationExamples_coverCommands : coversCommands circulationExamples = true := by decide
theorem circulationExamples_coverEvents   : coversEvents   circulationExamples = true := by decide
theorem circulationExamples_coverRefusals : coversRefusals circulationExamples = true := by decide

/-! ## Conformance: the test output replayed into the model -/

/-- A run the implementation reported: two checkouts, a retry, a return, the close, a refusal. -/
def goodTrace : List (TraceStep CirculationCommand CirculationEvent CirculationRefusal) :=
  [ { command := .checkOut "a" "b-1", outcome := .ok [.checkedOut "a" "b-1" 1] }
  , { command := .checkOut "b" "b-2", outcome := .ok [.checkedOut "b" "b-2" 2] }
  , { command := .checkOut "a" "b-1", outcome := .ok [] }
  , { command := .checkIn "c" "b-1",  outcome := .ok [.checkedIn "c" "b-1"] }
  , { command := .closeCard,          outcome := .ok [.cardClosed] }
  , { command := .checkOut "d" "b-3", outcome := .error .cardClosed } ]

/-- The same run from an implementation that booked the retry twice. -/
def badTrace : List (TraceStep CirculationCommand CirculationEvent CirculationRefusal) :=
  [ { command := .checkOut "a" "b-1", outcome := .ok [.checkedOut "a" "b-1" 1] }
  , { command := .checkOut "a" "b-1", outcome := .ok [.checkedOut "a" "b-1" 2] } ]

theorem goodTrace_conforms : circulation.conforms goodTrace [] = true  := by decide
theorem badTrace_rejected  : circulation.conforms badTrace  [] = false := by decide

/-! ## The wire shape, as a projection -/

/-- What proto, JSON or Avro would carry: a tag and loose optional fields,
    because the wire cannot say what the model's sum type says. -/
structure CirculationWireCommand where
  /-- The tag the wire carries for the command's kind: "checkOut", "checkIn", "renew" or "closeCard"; any other string is a parse refusal. -/
  kind : String
  /-- The command's key, present for all but the close; absent where needed is a parse refusal. -/
  key  : Option String := none
  /-- The copy's ID, present for all but the close; absent where needed is a parse refusal. -/
  item : Option String := none
  deriving Repr, DecidableEq

/-- The projection onto the wire: the sum becomes a tag and optional fields. -/
def CirculationCommand.serialize : CirculationCommand → CirculationWireCommand
  | .checkOut key item => { kind := "checkOut", key := some key, item := some item }
  | .checkIn key item  => { kind := "checkIn",  key := some key, item := some item }
  | .renew key item    => { kind := "renew",    key := some key, item := some item }
  | .closeCard         => { kind := "closeCard" }

/-- The two fields every command but the close carries, or the one that is missing. -/
def CirculationWireCommand.keyed (w : CirculationWireCommand)
    (make : String → String → CirculationCommand) : Except ParseRefusal CirculationCommand :=
  match w.key, w.item with
  | some key, some item => .ok (make key item)
  | none, _ => .error (.missingField "key")
  | _, none => .error (.missingField "item")

/-- The parse back, with the loss as refusals: a missing field or an unknown tag. -/
def CirculationCommand.parse (w : CirculationWireCommand) : Except ParseRefusal CirculationCommand :=
  match w.kind with
  | "checkOut"  => w.keyed CirculationCommand.checkOut
  | "checkIn"   => w.keyed CirculationCommand.checkIn
  | "renew"     => w.keyed CirculationCommand.renew
  | "closeCard" => .ok .closeCard
  | other       => .error (.unknownKind other)

/-- The codec, with its round trip proved by cases: the instance cannot
    exist without it. -/
instance : WireCodec CirculationCommand CirculationWireCommand where
  serialize := CirculationCommand.serialize
  parse := CirculationCommand.parse
  parse_serialize := by intro c; cases c <;> rfl

/-- The loss list, as refusals: what the wire can carry that the model will not. -/
theorem parse_missingItem :
    CirculationCommand.parse { kind := "checkOut", key := some "k1" } = .error (.missingField "item") := by rfl
theorem parse_unknownKind :
    CirculationCommand.parse { kind := "borrow" } = .error (.unknownKind "borrow") := by rfl

theorem gateway_checkOut :
    gateway circulation [] (CirculationCommand.checkOut "k1" "b-1").serialize
      = .ok [.checkedOut "k1" "b-1" 1] := by rfl
theorem gateway_refusesParse :
    gateway circulation [] ({ kind := "borrow" } : CirculationWireCommand)
      = .error (.parse (.unknownKind "borrow")) := by rfl
theorem gateway_refusesDomain :
    gateway circulation [.cardClosed] (CirculationCommand.checkOut "k1" "b-1").serialize
      = .error (.domain .cardClosed) := by rfl

/-! ## The wire renderings the fixtures carry -/

instance : JsonEncode CirculationWireCommand where
  toJson w :=
    let key := match w.key with | some k => ",\"key\":\"" ++ k ++ "\"" | none => ""
    let item := match w.item with | some i => ",\"item\":\"" ++ i ++ "\"" | none => ""
    "{\"kind\":\"" ++ w.kind ++ "\"" ++ key ++ item ++ "}"

instance : JsonEncode CirculationEvent where
  toJson
    | .checkedOut k i n => "{\"kind\":\"checkedOut\",\"key\":\"" ++ k ++ "\",\"item\":\"" ++ i ++ "\",\"onLoan\":" ++ toString n ++ "}"
    | .checkedIn k i    => "{\"kind\":\"checkedIn\",\"key\":\"" ++ k ++ "\",\"item\":\"" ++ i ++ "\"}"
    | .renewed k i      => "{\"kind\":\"renewed\",\"key\":\"" ++ k ++ "\",\"item\":\"" ++ i ++ "\"}"
    | .cardClosed       => "{\"kind\":\"cardClosed\"}"

instance : JsonEncode CirculationRefusal where
  toJson
    | .cardClosed   => "\"cardClosed\""
    | .limitReached => "\"limitReached\""
    | .notOnLoan    => "\"notOnLoan\""

/-! ## The wire readings the trace checker uses, the encoders' inverses -/

instance : JsonDecode CirculationWireCommand where
  fromJson j := do
    return { kind := ← Replay.strField j "kind"
           , key := (Replay.strField j "key").toOption
           , item := (Replay.strField j "item").toOption }

instance : JsonDecode CirculationEvent where
  fromJson j := do
    match ← Replay.strField j "kind" with
    | "checkedOut" => return .checkedOut (← Replay.strField j "key") (← Replay.strField j "item") (← Replay.natField j "onLoan")
    | "checkedIn"  => return .checkedIn (← Replay.strField j "key") (← Replay.strField j "item")
    | "renewed"    => return .renewed (← Replay.strField j "key") (← Replay.strField j "item")
    | "cardClosed" => return .cardClosed
    | other        => throw s!"unknown event kind \"{other}\""

instance : JsonDecode CirculationRefusal where
  fromJson j := do
    match ← j.getStr? with
    | "cardClosed"   => return .cardClosed
    | "limitReached" => return .limitReached
    | "notOnLoan"    => return .notOnLoan
    | other          => throw s!"unknown refusal \"{other}\""

instance : JsonDecode NoticeEvent where
  fromJson j := do
    match ← Replay.strField j "kind" with
    | "limitWarning"    => return .limitWarning (← Replay.strField j "item") (← Replay.natField j "onLoan")
    | "warningLevelSet" => return .warningLevelSet (← Replay.natField j "level")
    | other             => throw s!"unknown notice kind \"{other}\""

/-! ## The sentences a reader reviews -/

instance : Describe CirculationEvent where
  describe
    | .checkedOut key item n => s!"copy {item} was checked out under key {key}, {n} on loan"
    | .checkedIn key item    => s!"copy {item} was checked in under key {key}"
    | .renewed key item      => s!"copy {item} was renewed under key {key}"
    | .cardClosed            => "the card was closed"

instance : Describe CirculationCommand where
  describe
    | .checkOut key item => s!"a checkout arrives with key {key} for copy {item}"
    | .checkIn key item  => s!"a return arrives with key {key} for copy {item}"
    | .renew key item    => s!"a renewal arrives with key {key} for copy {item}"
    | .closeCard         => "the card is closed"

instance : Describe CirculationRefusal where
  describe
    | .cardClosed   => "it is refused because the card is closed"
    | .limitReached => "it is refused because five items are already on loan"
    | .notOnLoan    => "it is refused because the copy is not on loan"
