import CellCalculus.Envelope
/-!
# Boundaries as types

An identifier that must not cross a trust boundary is indexed by the
boundary that knows it, so the kernel refuses a record in one boundary built
with another boundary's ID. The scrub is a parse between boundaries, owned
by one cell, and the one function in the system whose type names two
boundaries; re-identification is its inverse.

This module is opt-in. A project with trust boundaries enumerates them in
its own package and makes a bounded ID the subject of its events; a project
without them never imports this module and its subject is whatever it is.
-/

/-- An identifier indexed by the boundary that knows it. Only the IDs the
    project's ID map maps take this index; an opaque ID that is safe to
    cross does not. -/
structure BoundedId (Boundary : Type) (boundary : Boundary) where
  /-- The identifier as the boundary's cell minted it; a string such as "L-7", with no meaning in any other boundary. -/
  raw : String
  deriving DecidableEq, Repr

/-- The alias map between two boundaries' IDs, with its invariant as a
    field: a map that does not invert cannot be constructed. -/
structure AliasMap {Boundary : Type} (source target : Boundary) where
  /-- The source boundary's ID to the target's, or none when the source ID is not mapped. -/
  forward  : BoundedId Boundary source → Option (BoundedId Boundary target)
  /-- The target boundary's ID back to the source's, or none when the target ID is not mapped. -/
  backward : BoundedId Boundary target → Option (BoundedId Boundary source)
  /-- What goes forward comes back: the alias map's invariant. -/
  inverts  : ∀ x y, forward x = some y → backward y = some x

/-- An unmapped subject is a refusal, never a guess. -/
inductive ScrubRefusal
  /-- The event's subject is not in the alias map, so nothing is guessed. -/
  | unknownSubject
  deriving Repr, DecidableEq

/-- The scrub: parse an event from the source boundary into the target
    boundary. The subject goes through the map, the payload through
    `tokenize`, and the envelope's id, causation, correlation and version
    are kept, so a run can be followed across the boundary. -/
def scrub {Payload Scrubbed Boundary : Type} {source target : Boundary}
    (map : AliasMap source target) (tokenize : Payload → Scrubbed)
    (e : EventEnvelope Payload (BoundedId Boundary source)) :
    Except ScrubRefusal (EventEnvelope Scrubbed (BoundedId Boundary target)) :=
  match map.forward e.subject with
  | none   => .error .unknownSubject
  | some s => .ok { id := e.id, causation := e.causation, correlation := e.correlation,
                    version := e.version, subject := s, recordedAt := e.recordedAt,
                    payload := tokenize e.payload }

/-- The inverse of the scrub, with the same owner. -/
def reidentify {Payload Scrubbed Boundary : Type} {source target : Boundary}
    (map : AliasMap source target) (detokenize : Scrubbed → Payload)
    (e : EventEnvelope Scrubbed (BoundedId Boundary target)) :
    Except ScrubRefusal (EventEnvelope Payload (BoundedId Boundary source)) :=
  match map.backward e.subject with
  | none   => .error .unknownSubject
  | some s => .ok { id := e.id, causation := e.causation, correlation := e.correlation,
                    version := e.version, subject := s, recordedAt := e.recordedAt,
                    payload := detokenize e.payload }

/-- The scrub keeps the envelope: the per-run pass sees one run on both
    sides of the boundary. -/
theorem scrub_keepsEnvelope {Payload Scrubbed Boundary : Type} {source target : Boundary}
    (map : AliasMap source target) (tokenize : Payload → Scrubbed)
    (e : EventEnvelope Payload (BoundedId Boundary source))
    (e' : EventEnvelope Scrubbed (BoundedId Boundary target))
    (h : scrub map tokenize e = .ok e') :
    e'.id = e.id ∧ e'.causation = e.causation ∧ e'.correlation = e.correlation := by
  unfold scrub at h
  split at h
  · exact absurd h (by simp)
  · cases h; exact ⟨rfl, rfl, rfl⟩

/-- Round trip: what the scrub lets through, re-identification returns
    exactly, for every map, every tokenizer with an inverse, every event. -/
theorem scrub_roundTrip {Payload Scrubbed Boundary : Type} {source target : Boundary}
    (map : AliasMap source target) (tokenize : Payload → Scrubbed) (detokenize : Scrubbed → Payload)
    (hdet : ∀ x, detokenize (tokenize x) = x)
    (e : EventEnvelope Payload (BoundedId Boundary source))
    (e' : EventEnvelope Scrubbed (BoundedId Boundary target))
    (h : scrub map tokenize e = .ok e') :
    reidentify map detokenize e' = .ok e := by
  unfold scrub at h
  split at h
  · exact absurd h (by simp)
  · rename_i hh _ hfwd
    cases h
    simp [reidentify, map.inverts _ _ hfwd, hdet]
