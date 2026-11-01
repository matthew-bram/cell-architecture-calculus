# Keeping the details

How to make a technical page easier to read without losing anything it says. Read this before any rewrite.

- [The two ways a rewrite fails](#the-two-ways-a-rewrite-fails)
- [What counts as a significant detail](#what-counts-as-a-significant-detail)
- [The ledger](#the-ledger)
- [The detail check](#the-detail-check)
- [The independent reading](#the-independent-reading)
- [Dated records](#dated-records)
- [When the two goals pull apart](#when-the-two-goals-pull-apart)

## The two ways a rewrite fails

A rewrite has two jobs: make the page easy to read, and keep everything it says. It can fail at either.

**It drifts back to dense.** A model writing technical prose has a default style, and the default is the chain this voice is trying to undo. You can see it in these habits:

- appositive chains: "the fold, `evolve`, the function that ...";
- noun stacks and nominalizations: "the transcription of the tables into the model's types";
- semicolons joining three or four clauses;
- a colon that opens a list in the middle of a sentence;
- a definition tucked into a longer claim.

The cure is a second pass. Read the draft as a newcomer would, and split every sentence that makes you hold more than one thing.

**It simplifies away a detail.** Shorter sentences invite shorter claims. A *never* goes missing when a sentence is split. An *at a tag, never a branch* becomes *at a tag*. A term of art becomes a friendlier word that means something else. These losses are worse than density, because the page still reads well and is now wrong.

The cure is the ledger, the detail check and the independent reading below.

## What counts as a significant detail

Any of these changes what a page claims if it goes missing:

| Kind | Examples from this repository |
| --- | --- |
| **Quantifiers** | every, each, all, any, no, none |
| **Restrictions** | only, exactly, nothing but, the one place |
| **Negations and prohibitions** | never, not, cannot, without |
| **Conditions and limits** | unless, until, except, where you have one, once |
| **Bounds** | at most, at least, three to six, 7 of 7 |
| **Modality** | must, may, should, can |
| **Direction** | maps into, generates, replayed into, upstream of, waits on |
| **Scope** | in the example, in the calculus, in a project, by path, at a tag |
| **Status** | proved, checked, tested, assumed |
| **Identifiers** | `liftToWire`, `model_never_unknown`, `Circulation.lean`, `lake exe fixtures` |
| **Numbers and versions** | 40 universal theorems, version 2.3.0, seventeen operators |
| **Sources** | Chassaing, 2021; Helland; the **[H]**, **[M]** and **[L]** markers |
| **Distinctions** | refusal against unknown; composition against succession against pointer |
| **Non-goals** | what the method does not do; what a direction is not |
| **Structure** | a table's rows and columns; a numbered list's order; which section a claim sits in |

A distinction is the easiest of these to lose. Two terms that sound alike in plain English often mean different things here. Never merge them for smoothness.

## The ledger

Before rewriting a page, write its ledger: one line per claim, in your own short words, with every detail from the table above that the claim carries.

```text
1. Every gateway returns Either[Ex, B]; Ex = Either[Refused, Unknown].
2. Refused: the cell's invariants say no; deterministic, final; journey stops at a named outcome.
3. Unknown: the failure window; the effect may or may not have landed.
4. decide returns Except Refusal (List Event): yes or a deterministic no, NOTHING ELSE.
5. The third value is added ONLY where a result crosses the wire.
6. liftToWire: refusal -> refused; NEVER produces unknown (theorem model_never_unknown).
```

Write the strength words in capitals, so they stand out when you tick them off. After the draft, tick every line against it. A line you can't tick is a lost detail. A claim in the draft that has no line is an added one. Both are defects.

For a whole page the ledger is long, and that's the point. It is the rewrite's contract. Keep it in your working notes, not in the repository.

## The detail check

`scripts/detail-check.py` compares the rewrite with the original, token by token:

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/detail-check.py <file>
python3 ${CLAUDE_SKILL_DIR}/scripts/detail-check.py <before> <after>
```

With one file it compares the file with its last committed version. It reports:

- **Warnings** for a code block that changed, and for inline code, a number or a link that went missing. It also warns when a strength word appears fewer times than before.
- **Notes** for a strength word that appears more often, which may mean a stronger claim. It also notes a bold term or a heading that changed.

Clear every warning. Either restore the detail, or say in the report why its absence is right. A note needs a look, not always a change: "a branch per row" becoming "a branch for each row" adds an *each* and changes nothing.

The check reads tokens, not meaning. It catches a dropped *until*. It can't tell that a sentence now says the reverse of what it said. That is what the ledger and the independent reading are for.

## The independent reading

For a rewrite longer than about 500 words, ask a second reader that hasn't seen your ledger. In Claude Code, that is a subagent. Give it the original and the rewrite, and nothing else. Ask it to list:

1. every claim or detail in the original that the rewrite lacks;
2. every claim in the rewrite that the original doesn't make;
3. every claim whose strength changed: weaker, stronger, narrower or broader;
4. every term of art replaced by a different word.

Don't tell it what you changed or why. A reader who knows your intent sees what you meant to write. Resolve every item it lists before reporting.

## Dated records

The notes under `research/` and the problem statements under `future/` are records. Each says what was believed on its date, and its value is that it hasn't been tidied since. A rewrite in the voice is allowed. Bringing the record up to date is not.

Take `research/the-build.md`, worked on Oct 14:

- **It names things as they were.** The project directory was `lean-journeys`, the slice was the books slice, and the header was `calculusHeader`. Today's names differ. The rewrite keeps the old ones.
- **It carries a revision note**, "Revised Oct 15, 2026", in a blockquote. The note stays word for word, and so does the date line under the title.
- **It marks its confidence.** **[H]** means run on the day and **[M]** means written but not yet run. Each marker stays against the claim it marked.
- **It disagrees with itself.** The table reports a mutation score of 10 of 10, and the last section says a clean run prints 8 of 8. The rewrite keeps both numbers and raises the mismatch as a question. A record's inconsistency is part of the record.
- **Its commands are the commands of the day.** `python3 mutants.py` took no arguments then. The rewrite doesn't add today's arguments.

When a dated record is rewritten, the directory's README records it. In `research/README.md` that is a line under what was changed for publication, with the date of the rewrite. Say there that only the voice changed: every finding, count, theorem name and open question is as it was.

## When the two goals pull apart

Sometimes a sentence can't get shorter without losing a detail. Keep the detail.

A 40-word sentence that is exact beats two 20-word sentences that aren't. Say so in the report: the prose check's numbers are a guide to where a reader will struggle, not an order to cut.

When you can't tell what a sentence means, don't guess. Keep its wording, mark it in the report as a question for the owner, and move on.

When a sentence is clear and wrong, the same holds. Take a heading that disagrees with its section. The white paper's section 4.2 was once headed "A cell is three pure functions". Its text said a cell is an initial state, three pure functions, one of which is the fold, and a terminal predicate.

A rewrite keeps such a heading's claim as it stands and reports the gap. The fix is a change of meaning, so it is made apart from the rewrite, before or after it. A voice change that also fixes a fact makes its reviewer hunt for the one sentence that moved among hundreds that didn't.
