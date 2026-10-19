import CellCalculus
/-!
# What this project supplies

The principal the calculus is generic over, the zones this project's
boundaries are, the patron ID those zones index, and the fixture values
the examples share. From `corpus/vision.md`, the trust zones, and
`corpus/architecture.md`, the cells by zone.
-/

/-- The zones of the architecture: the desk, which knows names and cards;
    the stacks, which know a member only by a patron token; the office;
    the lobby of channel applications; and the fabric. A member has a
    different ID in each of the two zones that know them. -/
inductive Zone
  /-- The desk: names, contact details, card numbers and the alias map from card to token. -/
  | desk
  /-- The stacks: loans, holds, fines and the catalog, keyed by patron token. -/
  | stacks
  /-- The office: counts, the staff console and the rung of every automation; no member data. -/
  | office
  /-- The lobby: the terminals, the kiosks and the app, fronts with no record of their own. -/
  | lobby
  /-- The fabric: telemetry and the audit trail. -/
  | fabric
  deriving DecidableEq, Repr

/-- The roles a card may hold. A member borrows; a guest may use the
    reading room and may not borrow; a librarian acts for the library. -/
inductive Role
  /-- A member: may check out, check in and renew. -/
  | member
  /-- A guest: may use the reading room and may not borrow. -/
  | guest
  /-- A librarian: may do what a member may, and close a card. -/
  | librarian
  deriving DecidableEq, Repr

/-- A card's ID, as membership issued it: an own ID of the desk, which
    never reaches the stacks. -/
structure CardId where
  /-- The card number as membership issued it; a string such as "C-1041". -/
  raw : String
  deriving DecidableEq, Repr

/-- Who a person is when they act: what membership answered, the card and
    the role it holds. An actor policy matches on the role. -/
structure Principal where
  /-- The card the actor holds, membership's own ID for them. -/
  card : CardId
  /-- The role the card holds, which the actor policies match on. -/
  role : Role
  deriving DecidableEq, Repr

/-- This project's architecture, for the calculus: its principal, with the
    equality and printing instances. -/
instance : Architecture :=
  { Principal := Principal, principalDecEq := inferInstance, principalRepr := inferInstance }

/-- A principal on the wire: `{"card": "C-1041", "role": "member"}`. -/
instance : JsonDecode Principal where
  fromJson j := do
    let role ← match ← Replay.strField j "role" with
      | "member"    => pure Role.member
      | "guest"     => pure Role.guest
      | "librarian" => pure Role.librarian
      | other       => throw s!"unknown role \"{other}\""
    return { card := ⟨← Replay.strField j "card"⟩, role := role }

/-- The same reading at the calculus's name for the principal, which is this type. -/
instance : JsonDecode Architecture.Principal := inferInstanceAs (JsonDecode Principal)

/-- A patron's ID, indexed by the zone that knows it: the subject of every
    event this project records. A record in one zone cannot be built with
    another zone's ID; the alias map between the desk and the stacks is
    the only way across. -/
abbrev PatronId (zone : Zone) := BoundedId Zone zone

/-- A patron ID on the wire is its raw string; the zone is the type's. -/
instance {zone : Zone} : JsonDecode (PatronId zone) where
  fromJson j := do return ⟨← j.getStr?⟩

/-- The patron token the stacks know the examples' member by. -/
def patronToken : PatronId Zone.stacks := ⟨"P-7"⟩

/-- The zero instant, for examples that do not read the clock. -/
def epoch : Instant := ⟨0⟩

/-- The run the examples share. -/
def firstRun : RunId := ⟨"run-1"⟩
