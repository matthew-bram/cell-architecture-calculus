import CellCalculus.Cell
/-!
# Governance of the model over time

The changelog rule, applied to the model. A theorem is never deleted; it is
superseded by name with Lean's `deprecated` attribute. An example is never
deleted; it is marked superseded and the coverage checks run over the live
set. An event version is never removed; the upcaster from every version is
total, which is the exhaustiveness check Lean already does. The model's
header carries the review line, and the build checks it against the design.
-/

/-- The review line: the one step no program can do, recorded where the
    build can see it. The build fails when the design's hash changes and
    this line does not. -/
structure ReviewLine where
  /-- The design document's path, relative to the project. -/
  design     : String
  /-- The design's content hash at review time, the first sixteen hex digits of its SHA-256. -/
  designHash : String
  /-- Who signed, by name; empty while unreviewed. -/
  reviewer   : String
  /-- The date signed, as YYYY-MM-DD; empty while unreviewed. -/
  reviewedOn : String
  deriving Repr

/-- A model's header as first written: one review line and what the model
    has superseded. Superseded by `ProjectHeader` on 2026-10-15, because one
    line cannot sign a package with several designs: the review of the
    second design had to replace the first design's line. -/
structure ModelHeader where
  /-- The one review line. -/
  review     : ReviewLine
  /-- What the model has superseded, as (item, superseded by, on). -/
  superseded : List (String × String × String)
  deriving Repr

/-- A project's header: one review line per design the model is reviewed
    against, so that every design in a package can be signed and the build
    checks each, and what the model has superseded, as (item, superseded
    by, on). -/
structure ProjectHeader where
  /-- One review line per design the package is reviewed against. -/
  reviews    : List ReviewLine
  /-- What the model has superseded, as (item, superseded by, on). -/
  superseded : List (String × String × String)
  deriving Repr

attribute [deprecated ProjectHeader (since := "2026-10-15")] ModelHeader

/-- An example under governance: it may be retired, never deleted. -/
structure GovernedExample (Command Event Refusal : Type) where
  /-- The example itself, kept whether live or retired. -/
  example_     : Example Command Event Refusal
  /-- The id of the example that replaced it, or none while live. -/
  supersededBy : Option String := none
  /-- The date it was retired, as YYYY-MM-DD, or none while live. -/
  retiredOn    : Option String := none
  /-- Why it was retired, in a sentence, or none while live. -/
  because      : Option String := none

/-- Not retired. -/
def GovernedExample.live {Command Event Refusal : Type}
    (g : GovernedExample Command Event Refusal) : Bool := g.supersededBy.isNone

/-- The live examples of a governed set, which coverage runs over. -/
def liveExamplesOf {Command Event Refusal : Type}
    (set : List (GovernedExample Command Event Refusal)) : List (Example Command Event Refusal) :=
  (set.filter GovernedExample.live).map (·.example_)

/-- A reaction example under governance: it may be retired, never deleted.
    The reaction counterpart of `GovernedExample`, added on 2026-10-15 when
    a changed reaction example had no governed shape to retire into. -/
structure GovernedReactionExample (ForeignEvent Event : Type) where
  /-- The reaction example itself, kept whether live or retired. -/
  example_     : ReactionExample ForeignEvent Event
  /-- The id of the example that replaced it, or none while live. -/
  supersededBy : Option String := none
  /-- The date it was retired, as YYYY-MM-DD, or none while live. -/
  retiredOn    : Option String := none
  /-- Why it was retired, in a sentence, or none while live. -/
  because      : Option String := none

/-- Not retired. -/
def GovernedReactionExample.live {ForeignEvent Event : Type}
    (g : GovernedReactionExample ForeignEvent Event) : Bool := g.supersededBy.isNone

/-- The live reaction examples of a governed set. -/
def liveReactionsOf {ForeignEvent Event : Type}
    (set : List (GovernedReactionExample ForeignEvent Event)) : List (ReactionExample ForeignEvent Event) :=
  (set.filter GovernedReactionExample.live).map (·.example_)
