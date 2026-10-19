/-!
# The context map: contexts, their subdomains, and the relationships between them

Stage 1 of the round trip takes two maps: the journey map, which places
each cell and draws each arrow, and the context map, which says which
bounded context each cell belongs to, what kind of subdomain the context
serves, and for every pair of contexts an arrow joins, who is upstream,
who is downstream, and under which of the patterns Evans (2003) and
Vernon (2013) name. The names here are those patterns, so that every
project's context map is read the same way, and the one computation is
coverage: every arrow between two contexts is accounted for by a
relationship in the right direction.

What the relationship means downstream in this method: a conformist's
parse is the identity up to shape, and an anti-corruption layer's parse is
a real translation, the only place a refusal means "not understood"
rather than "no". The context map records which, per edge, for the Wire
table of the downstream cell's design.
-/

/-- The kind of subdomain a context serves (Evans): the core, which the
    product competes on; supporting, built for it but not the point;
    generic, which any product needs and could buy. -/
inductive SubdomainKind
  /-- The product competes on it. -/
  | core
  /-- Built for the product, and not the point of it. -/
  | supporting
  /-- Needed by any product and could be bought. -/
  | generic
  deriving Repr, DecidableEq

/-- What the upstream context offers the downstream one. -/
inductive Upstream
  /-- An open host service: a gateway offered to any context, with its protocol stated. -/
  | openHostService
  /-- A published language: facts in a shared, documented schema. -/
  | publishedLanguage
  /-- A supplier with no stated protocol: the downstream's needs are negotiated case by case. -/
  | supplier
  deriving Repr, DecidableEq

/-- How the downstream context takes what the upstream offers. -/
inductive Downstream
  /-- A customer: commands and queries through the upstream's gateway, in the upstream's terms. -/
  | customer
  /-- A conformist: reacts to the upstream's facts as published, keeping its shape; the parse is the identity up to shape. -/
  | conformist
  /-- An anti-corruption layer: translates the upstream's shape into its own at the edge; the parse is a real translation. -/
  | anticorruptionLayer
  deriving Repr, DecidableEq

/-- A relationship between two contexts, as a context map draws it: an
    arrow with its upstream and downstream patterns, or one of the three
    symmetric relationships. -/
inductive Relationship (Context : Type)
  /-- Upstream influences downstream, with what each side does about it. -/
  | upstreamDownstream (upstream downstream : Context) (offers : Upstream) (takes : Downstream)
  /-- Two contexts that succeed or fail together and plan jointly. -/
  | partnership (a b : Context)
  /-- Two contexts sharing a piece of the model, changed only together. -/
  | sharedKernel (a b : Context)
  /-- Two contexts with no connection; an arrow between them is a contradiction. -/
  | separateWays (a b : Context)
  deriving Repr, DecidableEq

namespace Relationship

variable {Context : Type} [BEq Context]

/-- Whether this relationship accounts for an arrow from `upstream` to
    `downstream`: the directed relationship in that direction, a
    partnership or a shared kernel in either, separate ways never. -/
def covers (r : Relationship Context) (upstream downstream : Context) : Bool :=
  match r with
  | .upstreamDownstream u d _ _ => u == upstream && d == downstream
  | .partnership a b | .sharedKernel a b =>
      (a == upstream && b == downstream) || (a == downstream && b == upstream)
  | .separateWays _ _ => false

/-- Whether the downstream side translates at the edge, which is what an
    arrow from outside the system always needs. -/
def translates : Relationship Context → Bool
  | .upstreamDownstream _ _ _ .anticorruptionLayer => true
  | _ => false

/-- The downstream context of a directed relationship, or none. -/
def downstreamOf : Relationship Context → Option Context
  | .upstreamDownstream _ d _ _ => some d
  | _ => none

/-- The upstream context of a directed relationship, or none. -/
def upstreamOf : Relationship Context → Option Context
  | .upstreamDownstream u _ _ _ => some u
  | _ => none

end Relationship

/-- Whether some relationship on the map accounts for the arrow. -/
def covered {Context : Type} [BEq Context]
    (map : List (Relationship Context)) (upstream downstream : Context) : Bool :=
  map.any (·.covers upstream downstream)

/-- Whether every arrow, as a pair of upstream and downstream context, is
    accounted for. A project turns each row of its paths table into one
    pair by its own reading of which end is upstream for each kind of path. -/
def allCovered {Context : Type} [BEq Context]
    (map : List (Relationship Context)) (arrows : List (Context × Context)) : Bool :=
  arrows.all fun (u, d) => covered map u d

/-- Adding a relationship never uncovers an arrow, for every map and every
    pair: the map can be drawn in any order and grown without rechecking
    what was covered. -/
theorem covered_mono {Context : Type} [BEq Context]
    (map : List (Relationship Context)) (r : Relationship Context) (upstream downstream : Context)
    (h : covered map upstream downstream = true) :
    covered (r :: map) upstream downstream = true := by
  simp only [covered, List.any_cons, Bool.or_eq_true]
  exact Or.inr h

/-- The same for every arrow at once. -/
theorem allCovered_mono {Context : Type} [BEq Context]
    (map : List (Relationship Context)) (r : Relationship Context) (arrows : List (Context × Context))
    (h : allCovered map arrows = true) :
    allCovered (r :: map) arrows = true := by
  simp only [allCovered, List.all_eq_true] at h ⊢
  intro arrow ha
  exact covered_mono map r arrow.1 arrow.2 (h arrow ha)

/-- Separate ways covers nothing, for every pair: an arrow between two
    contexts declared apart is always a finding. -/
theorem separateWays_coversNothing {Context : Type} [BEq Context] (a b upstream downstream : Context) :
    (Relationship.separateWays a b).covers upstream downstream = false := rfl
