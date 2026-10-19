import Library.Envelopes
/-!
# The design's promise on the slice

A limit warning within a minute of the checkout that reached it, as a
predicate over runs.
-/

/-- Whether a command is a checkout. -/
def CirculationCommand.isCheckOut : CirculationCommand → Bool
  | .checkOut _ _ => true
  | _ => false

/-- Whether a recorded fact is a limit warning. -/
def BorrowFact.isWarning : BorrowFact → Bool
  | .inr (.limitWarning _ _) => true
  | _ => false

/-- The promise from the design's Attributes table, on the slice. -/
def warningWithinMinute : RunPromise CirculationCommand BorrowFact (PatronId .stacks) :=
  withinDuration CirculationCommand.isCheckOut BorrowFact.isWarning 60000

/-- A recorded fact at a given millisecond. -/
def factAt (ms : Nat) (id : String) (cause : CausationId) (payload : BorrowFact) :
    EventEnvelope BorrowFact (PatronId .stacks) :=
  { fact id cause payload with recordedAt := ⟨ms⟩ }

/-- A run in which the warning follows the checkout within five seconds. -/
def promptRun : Run CirculationCommand BorrowFact (PatronId .stacks) :=
  { root := memberCheckOut "k5" "b-5"
  , events := [ factAt 1000 "e1" (.ofCommand (.minted "k5")) (.inl (.checkedOut "k5" "b-5" 5))
              , factAt 5000 "e2" (.ofEvent ⟨"e1"⟩)          (.inr (.limitWarning "b-5" 5)) ] }

/-- A run in which the warning comes five minutes after the checkout. -/
def lateRun : Run CirculationCommand BorrowFact (PatronId .stacks) :=
  { root := memberCheckOut "k5" "b-5"
  , events := [ factAt 1000   "e1" (.ofCommand (.minted "k5")) (.inl (.checkedOut "k5" "b-5" 5))
              , factAt 300000 "e2" (.ofEvent ⟨"e1"⟩)          (.inr (.limitWarning "b-5" 5)) ] }

/-- The design's row as an attribute: a population promise at 99 per cent. -/
def warningWithinMinuteAttribute : Attribute CirculationCommand BorrowFact (PatronId .stacks) :=
  .population "a limit warning within a minute of the checkout that reached it" warningWithinMinute 99

theorem promptRun_keeps : warningWithinMinute promptRun = true := by decide
theorem lateRun_burns   : warningWithinMinute lateRun   = false := by decide
theorem burns_namesLateRun : (burns warningWithinMinute [promptRun, lateRun]).length = 1 := by decide
theorem kept_measure : kept warningWithinMinute [promptRun, lateRun, goodRun] = (2, 3) := by decide
theorem warningAttribute_burns :
    warningWithinMinuteAttribute.verdict [promptRun, lateRun, goodRun] = .burned 1 := by decide
theorem warningAttribute_kept :
    warningWithinMinuteAttribute.verdict [promptRun, goodRun] = .kept := by decide
