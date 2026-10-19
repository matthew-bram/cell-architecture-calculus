import Library.Circulation
/-!
# The desk's alias map, and the scrub across it

The one function in the system whose type names two zones. A fact about
a card at the desk becomes a fact about a token in the stacks, with its
envelope kept, so that a run can be followed across the boundary; a card
the map does not know is a refusal, never a guess.
-/

/-- The alias map from the desk's cards to the stacks' tokens, with one
    card in it: the examples' member. Its inverse law is a field, so a map
    that does not invert cannot be constructed. -/
def cardToToken : AliasMap Zone.desk Zone.stacks where
  forward  x := if x.raw == "C-1041" then some ⟨"P-7"⟩ else none
  backward y := if y.raw == "P-7" then some ⟨"C-1041"⟩ else none
  inverts := by
    intro x y h
    cases x with | mk xr =>
    cases y with | mk yr =>
    simp only at h ⊢
    split at h
    · rename_i hx
      injection h with h
      injection h with h
      subst h
      have hxr : xr = "C-1041" := by simpa using hx
      subst hxr
      decide
    · cases h

/-- The checkout fact as the desk records it, about the card. -/
def deskFact : EventEnvelope CirculationEvent (PatronId .desk) :=
  { id := ⟨"e1"⟩, causation := .ofCommand (.minted "k5"), correlation := firstRun,
    version := ⟨1⟩, subject := ⟨"C-1041"⟩, recordedAt := epoch,
    payload := .checkedOut "k5" "b-5" 5 }

/-- The same fact in the stacks, about the token, with its envelope kept. -/
def stacksFact : EventEnvelope CirculationEvent (PatronId .stacks) :=
  { id := ⟨"e1"⟩, causation := .ofCommand (.minted "k5"), correlation := firstRun,
    version := ⟨1⟩, subject := patronToken, recordedAt := epoch,
    payload := .checkedOut "k5" "b-5" 5 }

/-- Circulation's facts carry no identity, so the payload crosses as it is. -/
theorem deskFact_scrubs : scrub cardToToken id deskFact = .ok stacksFact := by rfl

/-- A card the map does not know is refused, never guessed. -/
theorem unknownCard_refused :
    scrub cardToToken id { deskFact with subject := ⟨"C-9999"⟩ } = .error .unknownSubject := by rfl

/-- And the token goes back to the card it came from. -/
theorem stacksFact_reidentifies : reidentify cardToToken id stacksFact = .ok deskFact := by rfl
