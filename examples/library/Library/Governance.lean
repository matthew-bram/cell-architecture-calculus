import Library.Journeys
/-!
# This model's governance

The review line, circulation's governed example set with one example
retired, and circulation's event versions with their upcaster.
-/

/-- The project's header: one review line per design. Circulation's says
    "unreviewed" until a reviewer reads the model against the design; the
    review check warns until then and fails if the design changes after.
    A second design gets a second line. -/
def projectHeader : ProjectHeader :=
  { reviews := [ { design := "designs/circulation.md",
                   designHash := "unreviewed", reviewer := "", reviewedOn := "" } ]
  , superseded := [ ("borrowJourney_warns", "borrowJourneyTerm_warns", "2026-10-19") ] }

/-- Circulation's set with one example retired: the close example as first
    written, replaced by the gated `LOAN-ACTOR-4` once the envelope
    arrived, because closing a card is a librarian's command and the old
    row had no actor. -/
def circulationExampleSet : List (GovernedExample CirculationCommand CirculationEvent CirculationRefusal) :=
  [ { example_ := loanOut1 }, { example_ := loanOut2 }, { example_ := loanOut3 }
  , { example_ := loanOut4 }, { example_ := loanOut5 }
  , { example_ := loanIn1 }, { example_ := loanIn2 }, { example_ := loanIn3 }, { example_ := loanIn4 }
  , { example_ := loanRenew1 }, { example_ := loanRenew2 }
  , { example_ := loanClose1
    , supersededBy := some "LOAN-ACTOR-4", retiredOn := some "2026-10-19"
    , because := some "closing a card is a librarian's command; the envelope carries the actor" }
  , { example_ := { id := "LOAN-CLOSE-2", given := [], when := .closeCard,
                    expect := .ok [.cardClosed] } }
  , { example_ := loanClose3 } ]

/-- The live examples, which the generators render and coverage runs over. -/
def liveExamples : List (Example CirculationCommand CirculationEvent CirculationRefusal) :=
  liveExamplesOf circulationExampleSet

theorem liveExamples_allHold       : liveExamples.all (·.holds circulation) = true := by decide
theorem liveExamples_coverCommands : coversCommands liveExamples = true := by decide
theorem liveExamples_coverEvents   : coversEvents   liveExamples = true := by decide
theorem liveExamples_coverRefusals : coversRefusals liveExamples = true := by decide

/-- Notices' reaction examples under governance, none retired yet: the
    shape a changed reaction row retires into. -/
def noticesReactionSet : List (GovernedReactionExample CirculationEvent NoticeEvent) :=
  [ { example_ := noticeWarn1 }, { example_ := noticeWarn2 }, { example_ := noticeWarn3 }
  , { example_ := noticeWarn4 }, { example_ := noticeIn1 }, { example_ := noticeRenew1 }
  , { example_ := noticeClose1 } ]

theorem liveReactions_allHold : (liveReactionsOf noticesReactionSet).all (·.holds notices) = true := by decide

/-- Notices' command examples under governance: its one command, pinned. -/
def noticesExampleSet : List (GovernedExample NoticeCommand NoticeEvent Empty) :=
  [ { example_ := noticeLevel1 } ]

theorem liveNoticeExamples_allHold : (liveExamplesOf noticesExampleSet).all (·.holds notices) = true := by decide

/-- Retiring an example without a successor opens a hole the coverage
    theorem names: with `LOAN-CLOSE-2` and `LOAN-CLOSE-3` also retired, no
    live example closes the card. -/
def circulationSetWithHole : List (GovernedExample CirculationCommand CirculationEvent CirculationRefusal) :=
  circulationExampleSet.map fun g =>
    if g.example_.id == "LOAN-CLOSE-2" || g.example_.id == loanClose3.id
    then { g with supersededBy := some "none yet" } else g

theorem hole_isNamed : coversCommands (liveExamplesOf circulationSetWithHole) = false := by decide

/-- Circulation's first event schema, before keys. Retired: the upcaster
    maps it and no publisher emits it. -/
inductive CirculationEventV0
  /-- A checkout as the first schema recorded it: the copy and the count, no key. -/
  | checkedOut (item : String) (onLoan : Nat)
  /-- A return as the first schema recorded it: the copy, no key. -/
  | checkedIn (item : String)
  /-- The card was closed, as the first schema recorded it. -/
  | cardClosed
  deriving Repr, DecidableEq

/-- The sum over every version ever published. -/
inductive CirculationEventAny
  /-- A fact in the first schema, before keys. -/
  | v0 (e : CirculationEventV0)
  /-- A fact in the current schema. -/
  | v1 (e : CirculationEvent)
  deriving Repr

/-- Total, because Lean checks the match is exhaustive. -/
def upcast : CirculationEventAny → CirculationEvent
  | .v0 (.checkedOut item onLoan) => .checkedOut "v0-unkeyed" item onLoan
  | .v0 (.checkedIn item)         => .checkedIn "v0-unkeyed" item
  | .v0 .cardClosed               => .cardClosed
  | .v1 e                         => e

/-- Replaying a history that mixes versions is replaying its upcast. -/
theorem replay_upcast (h : List CirculationEventAny) :
    (h.map upcast).foldl circulation.evolve circulation.initial = circulation.replay (h.map upcast) := rfl
