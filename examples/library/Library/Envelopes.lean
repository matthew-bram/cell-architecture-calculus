import Library.Circulation
/-!
# The envelopes on circulation's commands

Circulation's actor policy from its Commands table's sender column, the
gated examples, and the borrow journey as a recorded run with its shape
checked.
-/

/-- Circulation's actor policy, from the sender column: a member or a
    librarian checks out, checks in and renews; the renewals policy cell
    renews; a librarian closes; a guest does nothing. -/
def circulationActorPolicy : ActorPolicy CirculationCommand
  | .principal ⟨_, .member⟩,    .checkOut _ _ => true
  | .principal ⟨_, .member⟩,    .checkIn _ _  => true
  | .principal ⟨_, .member⟩,    .renew _ _    => true
  | .principal ⟨_, .librarian⟩, _             => true
  | .policy "renewals",         .renew _ _    => true
  | _, _ => false

/-- A checkout from a member's card, with a minted key, in the shared run. -/
def memberCheckOut (key item : String) : CommandEnvelope CirculationCommand :=
  { actor := .principal ⟨⟨"C-1041"⟩, .member⟩, key := .minted key, causation := none,
    correlation := firstRun, issuedAt := epoch, payload := .checkOut key item }

/-- The same checkout from a guest's card, which the policy refuses. -/
def guestCheckOut (key item : String) : CommandEnvelope CirculationCommand :=
  { actor := .principal ⟨⟨"C-2002"⟩, .guest⟩, key := .minted key, causation := none,
    correlation := firstRun, issuedAt := epoch, payload := .checkOut key item }

/-- The close, from a librarian's card. -/
def librarianClose : CommandEnvelope CirculationCommand :=
  { actor := .principal ⟨⟨"C-0001"⟩, .librarian⟩, key := .minted "close-1", causation := none,
    correlation := firstRun, issuedAt := epoch, payload := .closeCard }

/-- A guest's checkout is refused at the gate before circulation is consulted. -/
def loanActor1 : Example (CommandEnvelope CirculationCommand) CirculationEvent (GatedRefusal CirculationRefusal) :=
  { id := "LOAN-ACTOR-1 (guest refused)", given := [],
    when := guestCheckOut "k1" "b-1",
    expect := .error (.wrongActor (.principal ⟨⟨"C-2002"⟩, .guest⟩)) }

/-- A member's checkout passes the gate and is booked. -/
def loanActor2 : Example (CommandEnvelope CirculationCommand) CirculationEvent (GatedRefusal CirculationRefusal) :=
  { id := "LOAN-ACTOR-2 (member borrows)", given := [],
    when := memberCheckOut "k1" "b-1", expect := .ok [.checkedOut "k1" "b-1" 1] }

/-- A domain refusal passes through the gate relabeled: the card is closed. -/
def loanActor3 : Example (CommandEnvelope CirculationCommand) CirculationEvent (GatedRefusal CirculationRefusal) :=
  { id := "LOAN-ACTOR-3 (domain refusal survives the gate)", given := [.cardClosed],
    when := memberCheckOut "k2" "b-2", expect := .error (.domain .cardClosed) }

/-- A librarian's close passes the gate and closes the card. -/
def loanActor4 : Example (CommandEnvelope CirculationCommand) CirculationEvent (GatedRefusal CirculationRefusal) :=
  { id := "LOAN-ACTOR-4 (librarian closes)", given := [],
    when := librarianClose, expect := .ok [.cardClosed] }

theorem loanActor1_holds : loanActor1.holds (circulation.gated circulationActorPolicy) = true := by decide
theorem loanActor2_holds : loanActor2.holds (circulation.gated circulationActorPolicy) = true := by decide
theorem loanActor3_holds : loanActor3.holds (circulation.gated circulationActorPolicy) = true := by decide
theorem loanActor4_holds : loanActor4.holds (circulation.gated circulationActorPolicy) = true := by decide

/-- The same policy as a rule set: three permits and one forbid, so that
    the trio applies to it. -/
def circulationRules : RuleSet CirculationCommand :=
  { permits := [ fun actor command => match actor, command with
                   | .principal ⟨_, .member⟩, .checkOut _ _ | .principal ⟨_, .member⟩, .checkIn _ _
                   | .principal ⟨_, .member⟩, .renew _ _ => true
                   | _, _ => false
               , fun actor _ => match actor with
                   | .principal ⟨_, .librarian⟩ => true
                   | _ => false
               , fun actor command => match actor, command with
                   | .policy "renewals", .renew _ _ => true
                   | _, _ => false ]
  , forbids := [ fun actor _ => match actor with
                   | .principal ⟨_, .guest⟩ => true
                   | _ => false ] }

theorem circulationRules_guestRefused :
    circulationRules.policy (.principal ⟨⟨"C-2002"⟩, .guest⟩) (.checkOut "k1" "b-1") = false := by decide
theorem circulationRules_memberBorrows :
    circulationRules.policy (.principal ⟨⟨"C-1041"⟩, .member⟩) (.checkOut "k1" "b-1") = true := by decide
theorem circulationRules_memberCannotClose :
    circulationRules.policy (.principal ⟨⟨"C-1041"⟩, .member⟩) .closeCard = false := by decide

/-! ## The borrow journey as recorded facts -/

/-- A fact from either cell of the slice, as a run records them together. -/
abbrev BorrowFact := Sum CirculationEvent NoticeEvent

/-- A borrow fact on the wire is either cell's event, told apart by its kind. -/
instance : JsonDecode BorrowFact where
  fromJson j := do
    match ← Replay.strField j "kind" with
    | "checkedOut" | "checkedIn" | "renewed" | "cardClosed" => return .inl (← JsonDecode.fromJson j)
    | _ => return .inr (← JsonDecode.fromJson j)

/-- A recorded fact about the patron in the stacks, under the shared run, at the epoch. -/
def fact (id : String) (cause : CausationId) (payload : BorrowFact) : EventEnvelope BorrowFact (PatronId .stacks) :=
  { id := ⟨id⟩, causation := cause, correlation := firstRun, version := ⟨1⟩,
    subject := patronToken, recordedAt := epoch, payload := payload }

/-- The slice's run as recorded: the fifth checkout, then the warning citing it. -/
def goodRun : Run CirculationCommand BorrowFact (PatronId .stacks) :=
  { root := memberCheckOut "k5" "b-5"
  , events := [ fact "e1" (.ofCommand (.minted "k5")) (.inl (.checkedOut "k5" "b-5" 5))
              , fact "e2" (.ofEvent ⟨"e1"⟩)          (.inr (.limitWarning "b-5" 5)) ] }

/-- The warning recorded before the checkout it cites. -/
def backwardsRun : Run CirculationCommand BorrowFact (PatronId .stacks) :=
  { root := memberCheckOut "k5" "b-5"
  , events := [ fact "e2" (.ofEvent ⟨"e1"⟩)          (.inr (.limitWarning "b-5" 5))
              , fact "e1" (.ofCommand (.minted "k5")) (.inl (.checkedOut "k5" "b-5" 5)) ] }

/-- The warning cites a fact from some other run. -/
def strayRun : Run CirculationCommand BorrowFact (PatronId .stacks) :=
  { root := memberCheckOut "k5" "b-5"
  , events := [ fact "e1" (.ofCommand (.minted "k5")) (.inl (.checkedOut "k5" "b-5" 5))
              , fact "e2" (.ofEvent ⟨"e0"⟩)          (.inr (.limitWarning "b-5" 5)) ] }

/-- The checkout was decided for a different key than the root's. -/
def wrongRootRun : Run CirculationCommand BorrowFact (PatronId .stacks) :=
  { root := memberCheckOut "k5" "b-5"
  , events := [ fact "e1" (.ofCommand (.minted "k9")) (.inl (.checkedOut "k9" "b-5" 5)) ] }

theorem goodRun_conforms      : goodRun.conforms      = true  := by decide
theorem backwardsRun_rejected : backwardsRun.conforms = false := by decide
theorem strayRun_rejected     : strayRun.conforms     = false := by decide
theorem wrongRootRun_rejected : wrongRootRun.conforms = false := by decide
