import CellCalculus.Cell
/-!
# Coverage: the examples reach the model's structure

"Do the examples have the model's geometry?" has a decidable half: every
command kind, every event kind and every refusal reason the model can
produce appears in some example. A project gives each of its sum types a
`Kinded` instance, and the three coverage checks are generic. They fail the
moment a constructor is added without an example. The other half, that the
examples pin each branch, is mutation, in the build.
-/

/-- A sum type's constructors, numbered, so that coverage can ask whether
    each one appears in some example. -/
class Kinded (α : Type) where
  /-- The number of a value's constructor. -/
  kind  : α → Nat
  /-- Every constructor's number, so that coverage can ask whether each appears in some example. -/
  kinds : List Nat

/-- Every command kind appears as the When of some example. -/
def coversCommands {Command Event Refusal : Type} [Kinded Command]
    (examples : List (Example Command Event Refusal)) : Bool :=
  (Kinded.kinds (α := Command)).all fun k => examples.any fun ex => Kinded.kind ex.when == k

/-- Every event kind appears in the expected events of some example. -/
def coversEvents {Command Event Refusal : Type} [Kinded Event]
    (examples : List (Example Command Event Refusal)) : Bool :=
  (Kinded.kinds (α := Event)).all fun k => examples.any fun ex =>
    match ex.expect with
    | .ok events => events.any (Kinded.kind · == k)
    | .error _ => false

/-- Every refusal reason is the expected refusal of some example. -/
def coversRefusals {Command Event Refusal : Type} [Kinded Refusal]
    (examples : List (Example Command Event Refusal)) : Bool :=
  (Kinded.kinds (α := Refusal)).all fun k => examples.any fun ex =>
    match ex.expect with
    | .error reason => Kinded.kind reason == k
    | .ok _ => false
