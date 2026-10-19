import Library.Architecture
import Library.Circulation
import Library.Journeys
import Library.Envelopes
import Library.Inputs
import Library.Policy
import Library.Promises
import Library.Boundaries
import Library.Governance
/-!
# The library's circulation slice

One project's instantiation of the cell calculus: its zones and roles,
circulation and notices with their examples as theorems, the borrow
journey across the two cells and the hold shelf's fan-in, the envelopes on
circulation's commands, fines deciding on circulation's answer and the
clock, the renewals policy through the ladder, the promise on the slice,
the desk's alias map with the scrub across it, and the model's governance.
Every theorem here is a computation on this project's values, discharged
by `decide` or `rfl`; the universal theorems are in the calculus.

The design the model is transcribed from is `designs/circulation.md`; the
corpus it serves is under `corpus/`.
-/
