/-!
# What a project supplies

One type. Everything else in the calculus is generic over it, or takes what
it needs as a type parameter where the need is local, such as the subject
an event is about.
-/

/-- The one thing one project's architecture fixes and the calculus does
    not: its **principal**, who a human or system actor is when it acts. A
    seat with a role, a user with a scope, a service account: the calculus
    never looks inside, and an actor policy is the project's `match` on it.
    A project declares one instance. The decidable-equality and printing
    instances are carried along so that examples over the project's values
    can be checked by `decide` and printed by the generators. -/
class Architecture where
  /-- Who a human or system actor is, in the project's own terms. -/
  Principal : Type
  /-- Decidable equality on the principal, so that examples over the project's actors are checked by `decide`. -/
  principalDecEq : DecidableEq Principal
  /-- Printing of the principal, for the generators and the kernel's messages. -/
  principalRepr : Repr Principal

instance [a : Architecture] : DecidableEq a.Principal := a.principalDecEq
instance [a : Architecture] : Repr a.Principal := a.principalRepr
