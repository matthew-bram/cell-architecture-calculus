import CellCalculus
import JourneyMap
/-!
# The context map, as checked

The bounded contexts of `corpus/capability-map.md` and
`corpus/architecture.md`, each cell its own context as the architecture
says, with the subdomain kind the capability map assigns and the
relationships the architecture's paths imply, then the checks the prose
asserts. Every theorem is by `decide`.

Upstream, by kind of path: a fact's publisher is upstream of every cell
that reacts to it; a gateway's owner is upstream of every cell that
queries, commands or controls it; a partner is upstream of the cell that
calls it, which translates at its edge. The architecture's "duplicate by
projection, or query" paragraph is what decides conformist against
anti-corruption layer: a cell that keeps its own projection in a different
shape, or puts a name back, translates; a cell that reacts to the fact as
published conforms.
-/

/-- The bounded contexts: one per cell, as the architecture reads them, and
    the outside parties the partner calls reach. The channel applications
    and the telemetry plane are not contexts. -/
inductive Context
  /-- Membership. -/
  | membership
  /-- Notices. -/
  | notices
  /-- Catalog. -/
  | catalog
  /-- Circulation. -/
  | circulation
  /-- Holds. -/
  | holds
  /-- Pickup. -/
  | pickup
  /-- Fines. -/
  | fines
  /-- Renewals. -/
  | renewals
  /-- The reading assistant. -/
  | assistant
  /-- Reports. -/
  | reports
  /-- Operations. -/
  | operations
  /-- The town's identity provider, outside. -/
  | identityProvider
  /-- The message provider, outside. -/
  | messageProvider
  /-- The payment provider, outside. -/
  | paymentProvider
  /-- The consortium's interlibrary loan service, outside. -/
  | consortium
  deriving DecidableEq, Repr

/-- The context a capability's cell belongs to: itself, since each cell is
    a bounded context; none for a channel application or the telemetry plane. -/
def Cap.context : Cap → Option Context
  | .membership => some .membership | .notices => some .notices | .catalog => some .catalog
  | .circulation => some .circulation | .holds => some .holds | .pickup => some .pickup
  | .fines => some .fines | .renewals => some .renewals | .assistant => some .assistant
  | .reports => some .reports | .operations => some .operations
  | .terminals | .telemetry => none

/-- Whether a context is a party outside the system. -/
def Context.isExternal : Context → Bool
  | .identityProvider | .messageProvider | .paymentProvider | .consortium => true
  | _ => false

/-- The subdomain kind, from the capability map's "Core, supporting and
    generic" table; an outside party has none and reads as generic. -/
def Context.kind : Context → SubdomainKind
  | .circulation | .holds | .pickup | .fines | .renewals | .assistant => .core
  | .membership | .catalog | .reports | .operations => .supporting
  | .notices => .generic
  | .identityProvider | .messageProvider | .paymentProvider | .consortium => .generic

/-- The relationships the architecture's paths imply, one per pair of
    contexts an arrow joins, in the tables' order: the gateway rows, then
    the facts on the fabric, then the partner calls. -/
def contextMap : List (Relationship Context) :=
  [ -- Commands, queries and control through a gateway: the owner offers an open host service.
    .upstreamDownstream .circulation .membership .openHostService .customer
  , .upstreamDownstream .circulation .renewals   .openHostService .customer
  , .upstreamDownstream .circulation .holds      .openHostService .customer
  , .upstreamDownstream .circulation .fines      .openHostService .customer
  , .upstreamDownstream .catalog     .reports    .openHostService .customer
  , .upstreamDownstream .circulation .reports    .openHostService .customer
  , .upstreamDownstream .renewals    .operations .openHostService .customer
  , .upstreamDownstream .membership  .operations .openHostService .customer
    -- Facts on the fabric: the publisher's facts in the event schema.
  , .upstreamDownstream .membership  .circulation .publishedLanguage .conformist
  , .upstreamDownstream .circulation .catalog     .publishedLanguage .conformist
  , .upstreamDownstream .circulation .notices     .publishedLanguage .anticorruptionLayer
  , .upstreamDownstream .circulation .pickup      .publishedLanguage .conformist
  , .upstreamDownstream .circulation .fines       .publishedLanguage .conformist
  , .upstreamDownstream .holds       .pickup      .publishedLanguage .conformist
  , .upstreamDownstream .pickup      .notices     .publishedLanguage .anticorruptionLayer
  , .upstreamDownstream .fines       .notices     .publishedLanguage .anticorruptionLayer
  , .upstreamDownstream .renewals    .notices     .publishedLanguage .anticorruptionLayer
    -- Partner calls: the outside party is upstream, and the cell translates at its edge.
  , .upstreamDownstream .identityProvider .membership .supplier .anticorruptionLayer
  , .upstreamDownstream .messageProvider  .notices    .supplier .anticorruptionLayer
  , .upstreamDownstream .paymentProvider  .fines      .supplier .anticorruptionLayer
  , .upstreamDownstream .consortium       .catalog    .supplier .anticorruptionLayer
  ]

/-- Which end of a path is upstream, by its kind: the publisher of an
    event; the owner of the gateway a query, command, control request or
    session reaches; the party a partner call reaches. -/
def Path.upstream (p : Path) : Cap :=
  match p.kind with
  | .event => p.src
  | .query | .command | .control | .session | .partner => p.dst

/-- The other end. -/
def Path.downstream (p : Path) : Cap :=
  match p.kind with
  | .event => p.dst
  | .query | .command | .control | .session | .partner => p.src

/-- The paths whose both ends are contexts, as pairs of upstream and
    downstream context. The session from the terminals has no context at
    its source and drops out. -/
def arrows : List (Context × Context) :=
  paths.filterMap fun p =>
    match p.upstream.context, p.downstream.context with
    | some u, some d => some (u, d)
    | _, _ => none

/-- Every arrow of the paths table is accounted for by a relationship in
    the right direction. -/
theorem arrows_covered : allCovered contextMap arrows = true := by decide

/-- Every relationship whose upstream is outside the system translates at
    the edge: no partner's shape reaches a cell as it is. -/
theorem partners_translate :
    contextMap.all (fun r => match r.upstreamOf with
      | some u => !u.isExternal || r.translates
      | none => true) = true := by decide

/-- The heuristic that a core context should not conform to a generic one,
    read off the map as the list of places it is broken. The corpus does
    not state the heuristic, so the list is a finding and not a rule. -/
def coreConformingToGeneric : List (Context × Context) :=
  contextMap.filterMap fun r =>
    match r with
    | .upstreamDownstream u d _ .conformist =>
        if u.kind == .generic && d.kind == .core then some (u, d) else none
    | _ => none

/-- Nowhere on this map: the one generic context, notices, is upstream of
    nobody, and every outside party is translated at the edge. -/
theorem coreConformingToGeneric_isEmpty : coreConformingToGeneric = [] := by decide

/-- No context is declared separate ways from another on this map. -/
theorem noSeparateWays :
    contextMap.all (fun r => match r with | .separateWays _ _ => false | _ => true) = true := by decide
