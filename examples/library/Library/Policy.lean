import Library.Inputs
/-!
# The renewals policy through the ladder

The policy cell over circulation's command type, gated: a proposal arrives
only by succession from the reading assistant, an approval only from a
member, the rung only from the operator.
-/

/-- The renewals actor policy, from the policy cell's Commands table: the
    assistant proposes, a member approves, the operator sets the rung, and
    nobody else does any of the three. -/
def renewalActorPolicy {Proposal : Type} : ActorPolicy (PolicyCommand Proposal)
  | .policy "assistant",       .propose _ => true
  | .principal ⟨_, .member⟩,   .approve _ => true
  | .operator,                 .setRung _ => true
  | _, _ => false

/-- The renewals policy cell. -/
abbrev RenewalPolicy := (policy CirculationCommand).gated renewalActorPolicy

/-- A proposal arriving by succession from the assistant, keyed by the fact it follows from. -/
def proposeRenewal (item : String) : CommandEnvelope (PolicyCommand CirculationCommand) :=
  { actor := .policy "assistant", key := .derived "assistant" ⟨"due-1"⟩,
    causation := some ⟨"due-1"⟩, correlation := ⟨"run-2"⟩, issuedAt := epoch,
    payload := .propose (.renew "r1" item) }

/-- A member's approval of a held renewal. -/
def memberApproves (item : String) : CommandEnvelope (PolicyCommand CirculationCommand) :=
  { actor := .principal ⟨⟨"C-1041"⟩, .member⟩, key := .minted "ap1", causation := none,
    correlation := ⟨"run-3"⟩, issuedAt := epoch, payload := .approve (.renew "r1" item) }

/-- The same approval from a guest's card, which the policy refuses. -/
def guestApproves (item : String) : CommandEnvelope (PolicyCommand CirculationCommand) :=
  { memberApproves item with actor := .principal ⟨⟨"C-2002"⟩, .guest⟩ }

theorem renewals_shadow :
    RenewalPolicy.handle [] (proposeRenewal "b-1") = .ok [.shadowed (.renew "r1" "b-1")] := by rfl
theorem renewals_review :
    RenewalPolicy.handle [.rungSet .review] (proposeRenewal "b-1") = .ok [.held (.renew "r1" "b-1")] := by rfl
theorem renewals_autonomous :
    RenewalPolicy.handle [.rungSet .autonomous] (proposeRenewal "b-1") = .ok [.issued (.renew "r1" "b-1")] := by rfl
theorem renewals_memberApproves :
    RenewalPolicy.handle [.rungSet .review, .held (.renew "r1" "b-1")] (memberApproves "b-1")
      = .ok [.issued (.renew "r1" "b-1")] := by rfl
theorem renewals_guestRefused :
    RenewalPolicy.handle [.rungSet .review, .held (.renew "r1" "b-1")] (guestApproves "b-1")
      = .error (.wrongActor (.principal ⟨⟨"C-2002"⟩, .guest⟩)) := by rfl

/-- What the shell does with an issue: the renewal reaches circulation as
    its own command, and circulation renews. -/
theorem issued_renews :
    circulation.handle [.checkedOut "k1" "b-1" 1] (.renew "r1" "b-1") = .ok [.renewed "r1" "b-1"] := by rfl
