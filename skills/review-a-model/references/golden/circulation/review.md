# Review: the circulation slice against its design

Oct 20, 2026 · prepared by the review-a-model skill for the reviewer · design `examples/library/designs/circulation.md` at hash `6f77916800865b09` · model `examples/library/Library/Circulation.lean`, circulation and notices, with `Envelopes.lean` for the gated rows and `Governance.lean` for the governed set

**Scope.** The two cells `Circulation.lean` holds and the rows of the design that transcribe into them: the circulation and notices sections, the four actor rows that `Envelopes.lean` carries, and the governed set. The design's fines, pickup and renewals sections, the journey, the contracts and the attributes are modelled in `Inputs.lean`, `Journeys.lean`, `Policy.lean` and `Promises.lean` and are a second packet's.

## 1. Names

Every name conforms but one. Types are words ending in Command, Event, Refusal, State: `CirculationCommand`, `CirculationEvent`, `CirculationRefusal`, `CirculationState`, `NoticeCommand`, `NoticeEvent`, `NoticeState`; the wire shape is `CirculationWireCommand`. The cells are `circulation` and `notices`, as the capability map names them. Examples are their ids, `loanOut2` for `LOAN-OUT-2`, `noticeWarn3` for `NOTICE-WARN-3`; the fixture is `fiveOut`, named by what it shows; the limit is `loanLimit`. Theorems are subject then claim: `checkOut_idempotent`, `closed_refusesCheckOut`, `circulation_terminalWhenClosed`, `goodTrace_conforms`, `badTrace_rejected`, `parse_unknownKind`, `gateway_refusesDomain`. Hypotheses are `hseen`, `hopen`, `h`.

The one exception: `LOAN-CLOSE-2` is a value with no name. It is written inline in `circulationExampleSet` in `Governance.lean`, where every other example is a named value with its own doc comment and `_holds` theorem. The reviewer cannot hover it, and the feature file is the only place its sentence is read. Finding 3, not blocking: the meaning is right, the name is missing.

## 2. Comments

Every declaration has one. The cell's comment names the idempotent receiver and says which branch it is; the wire shape's says why it is loose, because the wire cannot say what the sum type says; `CirculationWireCommand.keyed` says what it is for; `loanClose3`'s says why it exists, so that a mutant publishing the close again does not survive; `noticeClose1`'s says it is the only row pinning the close. Every field of the state and every constructor's fields carry meaning, domain and an example value, as section 3 asks. The `_holds` theorems carry none, which the guide does not require.

## 3. The theorems state the right thing

| theorem or example | the design's sentence or row | the Lean, in words | same? |
| --- | --- | --- | --- |
| checkOut_idempotent | for every key, item and open-card state in which the key was already honored, a repeated checkout produces no event | for every key, item and state with the key in `seen` and `closed = false`, `decide` returns ok with no events | yes; the open-card condition is the hypothesis `hopen`, as the sentence has it, and the model's comment says why: a closed card refuses first |
| closed_refusesCheckOut | for every key and item, a checkout on a closed card is refused with cardClosed, whatever is on loan | for every key, item and state with `closed = true`, `decide` returns the refusal `cardClosed`; nothing is assumed about `onLoan` or `seen` | yes |
| circulation_notTerminalInitially, circulation_terminalWhenClosed | the state is terminal when the card is closed | the initial state is not terminal; the state after `cardClosed` is terminal | the two points witness the sentence in both directions; the sentence is universal and the theorems are two computations, which is what the Terminal line earns (finding 5, not blocking) |
| goodTrace_conforms, badTrace_rejected | no sentence; principle 4, a loan is booked once, as the model's own evidence | a six-step run with a retried key conforms; a run that booked the retry twice is rejected | yes against the principle; no row to pair with |
| parse_missingItem, parse_unknownKind | a tag circulation does not know and a field a command needs and lacks are the only refusals | a checkout without its item is refused `missingField "item"`; the tag "borrow" is refused `unknownKind "borrow"` | yes |
| gateway_checkOut, gateway_refusesParse, gateway_refusesDomain | the parse is the identity up to shape; a tag circulation does not know is a parse refusal; the domain refusal survives | the serialized checkout through the gateway is booked; "borrow" is refused as a parse; a checkout on a closed card is refused as a domain refusal | yes |
| loanOut1 | nothing; checkOut "k1" "b-1"; ok: checkedOut "k1" "b-1" 1 | the same | yes |
| loanOut2 | checkedOut "k1" "b-1" 1; checkOut "k1" "b-1"; ok, no events | the same | yes |
| loanOut3 | cardClosed; checkOut "k2" "b-2"; refused: cardClosed | the same | yes |
| loanOut4 | five items checked out, "b-1" to "b-5"; checkOut "k6" "b-6"; refused: limitReached | given `fiveOut`, the five checkouts; the same | yes |
| loanOut5 | four items checked out, "b-1" to "b-4"; checkOut "k5" "b-5"; ok: checkedOut "k5" "b-5" 5 | given `fiveOut.take 4`; the same | yes |
| loanIn1 | checkedOut "k1" "b-1" 1; checkIn "k2" "b-1"; ok: checkedIn "k2" "b-1" | the same | yes |
| loanIn2 | nothing; checkIn "k2" "b-9"; refused: notOnLoan | the same | yes |
| loanIn3 | checkedOut "k1" "b-1" 1; checkedIn "k2" "b-1"; checkIn "k2" "b-1"; ok, no events | the same | yes |
| loanIn4 | checkedOut "k1" "b-1" 1; cardClosed; checkIn "k2" "b-1"; ok: checkedIn "k2" "b-1" | the same | yes |
| loanRenew1 | checkedOut "k1" "b-1" 1; renew "k3" "b-1"; ok: renewed "k3" "b-1" | the same | yes |
| loanRenew2 | nothing; renew "k3" "b-9"; refused: notOnLoan | the same | yes |
| loanClose1 | nothing; closeCard; ok: cardClosed; retired as of 2026-10-19, superseded by LOAN-ACTOR-4 | the same, retired in the governed set with that successor, that date and the design's reason | yes |
| LOAN-CLOSE-2, inline | nothing; closeCard; ok: cardClosed | the same, as an unnamed value in the governed set | yes as a value; see check 1 |
| loanClose3 | cardClosed; closeCard; ok, no events | the same | yes |
| noticeLevel1 | nothing; setWarningLevel 9; ok: warningLevelSet 9 | the same | yes |
| noticeWarn1 | nothing; checkedOut "k5" "b-5" 5; limitWarning "b-5" 5 | the same, against the default level 4 | yes |
| noticeWarn2 | nothing; checkedOut "k1" "b-1" 1; nothing | the same | yes |
| noticeWarn3 | nothing; checkedOut "k4" "b-4" 4; nothing | the same; `react` warns on `onLoan > s.warnAt`, strict, so 4 against 4 is quiet, as the row's note "at the level, quiet" says | yes |
| noticeWarn4 | warningLevelSet 9; checkedOut "k5" "b-5" 5; nothing | the same | yes |
| noticeIn1 | nothing; checkedIn "k2" "b-1"; nothing | the same | yes |
| noticeRenew1 | nothing; renewed "k3" "b-1"; nothing | the same | yes |
| noticeClose1 | nothing; cardClosed; nothing | the same | yes |
| loanActor1 | nothing; checkOut "k1" "b-1", from a guest's card; refused at the gate: wrong actor | given nothing, when the checkout in an envelope whose actor is the card C-2002 with the role guest, expect the gate's refusal `wrongActor` naming that actor | yes |
| loanActor2 | nothing; checkOut "k1" "b-1", from a member's card; ok: checkedOut "k1" "b-1" 1 | the same, from C-1041 as a member | yes |
| loanActor3 | cardClosed; checkOut "k2" "b-2", from a member's card; refused: cardClosed | the same, the refusal relabeled `domain cardClosed` by the gate | yes |
| loanActor4 | nothing; closeCard, from a librarian's card; ok: cardClosed | the same, from C-0001 as a librarian | yes |

The governed set agrees with the design's table. `circulationExampleSet` retires `LOAN-CLOSE-1` with `LOAN-ACTOR-4` as its successor, the date 2026-10-19 and the reason that closing a card is a librarian's command, which is the sentence under the design's table; `LOAN-CLOSE-2` and `LOAN-CLOSE-3` are live; the live set is thirteen and the fixtures render thirteen. `noticesReactionSet` and `noticesExampleSet` retire nothing, and the design retires nothing of notices.

One thing a reader could confuse. `Circulation.lean` keeps `circulationExamples`, thirteen values with `loanClose1` in it and `LOAN-CLOSE-2` not, and proves coverage over that list; `Governance.lean` keeps `liveExamples`, the live set, and proves coverage over that too. Both hold, and only the live set reaches the views and the tests. Finding 4, not blocking: two lists where one is the design's, and the first carries a retired example.

## 4. Every branch has an example

| command or fact | branch | example that reaches it |
| --- | --- | --- |
| checkOut | the card is closed | LOAN-OUT-3 |
| checkOut | the key is in seen | LOAN-OUT-2 |
| checkOut | five items are on loan | LOAN-OUT-4 |
| checkOut | otherwise | LOAN-OUT-1, LOAN-OUT-5 |
| checkIn | the key is in seen | LOAN-IN-3 |
| checkIn | the item is not on loan | LOAN-IN-2 |
| checkIn | otherwise | LOAN-IN-1, LOAN-IN-4 |
| renew | the card is closed | **none** |
| renew | the key is in seen | **none** |
| renew | the item is not on loan | LOAN-RENEW-2 |
| renew | otherwise | LOAN-RENEW-1 |
| closeCard | already closed | LOAN-CLOSE-3 |
| closeCard | otherwise | LOAN-CLOSE-2 (LOAN-CLOSE-1 retired) |
| setWarningLevel | always | NOTICE-LEVEL-1 |
| checkedOut, reacting | onLoan over the level | NOTICE-WARN-1 |
| checkedOut, reacting | otherwise | NOTICE-WARN-2, NOTICE-WARN-3, NOTICE-WARN-4 |
| checkedIn, reacting | always | NOTICE-IN-1 |
| renewed, reacting | always | NOTICE-RENEW-1 |
| cardClosed, reacting | always | NOTICE-CLOSE-1 |

Two branches have no example, both on `renew`. A renewal on a closed card, which the design refuses with `cardClosed`, is reached by nothing: `LOAN-RENEW-1` renews on an open card and `LOAN-RENEW-2` on an empty history. A retried renewal, the key already in seen, is reached by nothing either; the checkout and the return each have their retry row and the renewal has none. No mutant in `mutants.json` touches either branch, so a model that renewed on a closed card, or booked a retried renewal twice, would pass the build and the gate. Findings 1 and 2; both block, because a Decide row without an example is the rule against modelling only what is easy, and these two are the rows a retrying terminal and a leaving member exercise.

## 5. The build

| command | last lines |
| --- | --- |
| `lake build` | Build completed successfully (66 jobs); no warnings |
| `lake exe fixtures` | wrote generated/circulation.feature and generated/circulation-examples.json for 13 live examples, Library/Circulation.lean#2465870485711712215+../../cell-calculus/CellCalculus/Cell.lean#3737230006895401021 |
| `python3 ../../tools/review-check.py Library/Governance.lean .` | warning: model not yet reviewed against designs/circulation.md (hash now 6f77916800865b09) |
| `python3 ../../tools/mutants.py mutants.json` | mutation score: 10/10 |

The generated feature file, which is what a non-technical reviewer reads:

```gherkin
# generated from Library/Circulation.lean#2465870485711712215+../../cell-calculus/CellCalculus/Cell.lean#3737230006895401021; do not edit
Feature: circulation lends

Scenario: LOAN-OUT-1
  Given nothing has happened yet
  When a checkout arrives with key k1 for copy b-1
  Then copy b-1 was checked out under key k1, 1 on loan

Scenario: LOAN-OUT-2 (retry after unknown)
  Given copy b-1 was checked out under key k1, 1 on loan
  When a checkout arrives with key k1 for copy b-1
  Then nothing happens

Scenario: LOAN-OUT-3 (refused, card closed)
  Given the card was closed
  When a checkout arrives with key k2 for copy b-2
  Then it is refused because the card is closed

Scenario: LOAN-OUT-4 (the sixth is refused)
  Given copy b-1 was checked out under key k1, 1 on loan
  And copy b-2 was checked out under key k2, 2 on loan
  And copy b-3 was checked out under key k3, 3 on loan
  And copy b-4 was checked out under key k4, 4 on loan
  And copy b-5 was checked out under key k5, 5 on loan
  When a checkout arrives with key k6 for copy b-6
  Then it is refused because five items are already on loan

Scenario: LOAN-OUT-5 (the fifth is fine)
  Given copy b-1 was checked out under key k1, 1 on loan
  And copy b-2 was checked out under key k2, 2 on loan
  And copy b-3 was checked out under key k3, 3 on loan
  And copy b-4 was checked out under key k4, 4 on loan
  When a checkout arrives with key k5 for copy b-5
  Then copy b-5 was checked out under key k5, 5 on loan

Scenario: LOAN-IN-1
  Given copy b-1 was checked out under key k1, 1 on loan
  When a return arrives with key k2 for copy b-1
  Then copy b-1 was checked in under key k2

Scenario: LOAN-IN-2 (not on loan)
  Given nothing has happened yet
  When a return arrives with key k2 for copy b-9
  Then it is refused because the copy is not on loan

Scenario: LOAN-IN-3 (retry after unknown)
  Given copy b-1 was checked out under key k1, 1 on loan
  And copy b-1 was checked in under key k2
  When a return arrives with key k2 for copy b-1
  Then nothing happens

Scenario: LOAN-IN-4 (a closed card's item comes back)
  Given copy b-1 was checked out under key k1, 1 on loan
  And the card was closed
  When a return arrives with key k2 for copy b-1
  Then copy b-1 was checked in under key k2

Scenario: LOAN-RENEW-1
  Given copy b-1 was checked out under key k1, 1 on loan
  When a renewal arrives with key k3 for copy b-1
  Then copy b-1 was renewed under key k3

Scenario: LOAN-RENEW-2 (not on loan)
  Given nothing has happened yet
  When a renewal arrives with key k3 for copy b-9
  Then it is refused because the copy is not on loan

Scenario: LOAN-CLOSE-2
  Given nothing has happened yet
  When the card is closed
  Then the card was closed

Scenario: LOAN-CLOSE-3 (already closed, quiet)
  Given the card was closed
  When the card is closed
  Then nothing happens
```

The feature file carries circulation's command examples only: the notices reactions, the gated rows and the fines examples have no registered renderer, so a reviewer who reads only the views does not see them. Finding 6, not blocking: the reviewer reads those rows in this packet's check 3 instead.

## 6. The review line

Signing would write `design := "designs/circulation.md"`, `designHash := "6f77916800865b09"`, the reviewer's name and the date into the one review line of `projectHeader` in `Library/Governance.lean`, after which the review check says ok and fails the day the design changes. **Not signed.** Findings 1 and 2 block: two Decide rows of `renew` have no example that reaches them, and no mutant stands in for one. The owner adds the two rows to the design, a renewal on a closed card refused and a retried renewal quiet, with ids in the design's style, `LOAN-RENEW-3 (refused, card closed)` and `LOAN-RENEW-4 (retry after unknown)`; model-a-cell adds the values, their theorems and a mutant each; and the review runs again against the new hash.

## Findings

1. renew when the card is closed has no example, and no mutant covers the branch · blocks
2. renew when the key is in seen has no example · blocks
3. LOAN-CLOSE-2 is an unnamed value inline in the governed set, where every other example is a named value with a comment and a theorem · does not block
4. `circulationExamples` in Circulation.lean carries the retired LOAN-CLOSE-1 beside the live set in Governance.lean; both lists prove coverage, and only the live set reaches the views · does not block
5. The Terminal line is pinned at two states, not proved for every state · does not block
6. The generated feature file carries circulation's command examples only; the reaction and gated rows are read in this packet · does not block
