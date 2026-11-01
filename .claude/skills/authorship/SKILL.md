---
name: authorship
description: Write and revise this repository's prose in its one house voice, plain, exact and led by figures, modeled on the WSO2 cell-based reference architecture page, without losing a single technical detail. Covers the READMEs, CONTRIBUTING, CLAUDE.md, the documents under docs/, the white paper and executive summary, directory guides, changelog rows, commit messages and pull request titles and descriptions. Use this skill whenever you write, rewrite, edit, tighten, shorten, simplify, restructure, proofread or review any Markdown document in this repository; add a section, an example or a diagram to one; draft a commit message, a pull request or a changelog row; or when someone says the docs are dense, too technical, hard to read or inconsistent, or should read more like the reference architecture, even if the words voice, style or authorship are never said. It changes how a document says things, never what it claims.
argument-hint: "[file or directory]"
allowed-tools: Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/prose-check.py *) Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/detail-check.py *) Bash(python3 tools/scrub-check.py)
---

# Authorship

The repository's documents are exact. This skill makes them easy to read as well, in one voice from the README to the last commit message. The voice is plain, short-sentenced and led by figures, after the [WSO2 cell-based reference architecture](https://github.com/wso2/reference-architecture/blob/master/reference-architecture-cell-based.md).

If the skill was invoked with a path, the target is `$ARGUMENTS`. Otherwise the target is whatever the request names.

## Two goals, one rule

Every piece of writing here has two goals, and they weigh the same:

1. **It reads easily.** Short sentences, one idea each, figures where the subject has a shape.
2. **It loses nothing.** Every claim, qualifier, number, identifier, condition and distinction the original carries survives.

One rule settles any conflict between them: **the original owns meaning.** You change how a claim is said, never what it claims. A sentence that can't get shorter without losing a detail keeps the detail. Where you can't tell what a sentence means, keep its wording and ask.

A rewrite fails in two directions. It drifts back into the dense, chained style that technical writing defaults to. Or it simplifies a *never*, an *only* or an *until* out of existence, and the page reads well and is now wrong. The second failure is the worse one. [references/details.md](references/details.md) names both and says how to catch them.

## The voice in brief

1. **One idea per sentence.** Split any sentence that hangs a chain of clauses off a claim.
2. **Lead with the point.** A paragraph's first sentence is its claim. A page's first paragraph says what it is and who it's for.
3. **Define a term once**, in bold, in a short sentence. Then use it the same way everywhere.
4. **Lists for parallel things, tables for attributes, prose for reasoning.** A table that is already there stays a table, with every row and column.
5. ***You* in guides, *we* sparingly in papers, neither in reference pages.**
6. **Active voice, present tense, a concrete subject.**
7. **Plain words for ordinary English. Terms of art stay exactly as they are.**
8. **One word for one thing.** Report a term used two ways; don't pick silently.
9. **Say exactly how sure.** *Proved*, *checked*, *tested* and *assumed* stay in their places.
10. **Numerals for anything from the build**, words for small counts in ordinary prose.
11. **Figures lead the sections whose subjects have a shape.**
12. **American spelling.**

The rules, the reasons and five rewrites from this repository are in [references/voice.md](references/voice.md).

## What this skill writes, and what it leaves alone

Every public-facing document is in scope, so that the whole repository reads in one voice.

| Writes and revises | Leaves alone unless the owner says otherwise |
| --- | --- |
| `README.md`, `CONTRIBUTING.md`, `CLAUDE.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` | Lean files and their doc comments. `docs/style-guide.md` governs them. |
| Every page under `docs/` | `examples/library/` designs and corpus. They are the model's sources and the method skills' golden answers, and the review line hashes each design. |
| `white-paper.md`, `executive-summary.md` | `skills/`. A change to a method skill's text means re-running its evaluations. |
| Directory READMEs, such as `future/README.md` and `research/README.md` | Anything under `generated/`. It is generated, never written. |
| Research notes under `research/` and problem statements under `future/`. Rewrite them in the voice, by the rules for [dated records](#dated-records) | |
| `CHANGELOG.md` rows, `.github/` templates and issue forms | |
| Commit messages, pull request titles and descriptions | |

A rewrite of `docs/style-guide.md` changes no rule. If making a rule clearer would change what it requires, stop and ask: that is a decision with a changelog row, not an edit.

### Dated records

A research note or a problem statement records what was believed on its date. A rewrite changes how it reads and nothing else:

- **The date line and every revision note stay**, word for word.
- **The vocabulary of the day stays**, even where the public documents now use another word. A directory, a slice, an identifier or a command the note names is kept as the note named it.
- **No hindsight.** Add nothing the note didn't know on its date, and correct nothing it got wrong. A later correction belongs in a dated note.
- **An inconsistency in the record stays.** Keep both sides and raise it in the report.
- **Confidence markers stay**, each against the claim it marked.
- **The rewrite is recorded.** For a research note, add a line to `research/README.md` under what was changed for publication. For a problem statement, the commit says that only the voice changed, as the first rule in `future/README.md` asks.

[details.md](references/details.md#dated-records) has the detail.

## The procedure

### 1. Read and measure

Read the target and the pages that link to it. Then read the reference files the task needs:

- [references/voice.md](references/voice.md), always.
- [references/details.md](references/details.md), for any rewrite.
- [references/page-anatomy.md](references/page-anatomy.md), for a whole page or a new one.
- [references/figures.md](references/figures.md), whenever a section's subject has a shape.
- [references/commits.md](references/commits.md), for a commit message, a pull request or a changelog row.

Measure the target before changing it:

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/prose-check.py <file or directory>
```

The check reports sentence length, long sentences, commas, paragraph length, heading depth, figures, British spellings and broken links, each against its target. Keep the numbers for the report.

### 2. Write the ledger

Before rewriting, write the page's ledger by [details.md](references/details.md): one line per claim, with every quantifier, restriction, condition, bound, number, identifier, distinction and source it carries. Write the strength words in capitals. Also list:

- every code block, which passes through unchanged;
- every link out;
- every heading other pages link to. Find those by searching the repository for the file name followed by `#`.

The ledger is the rewrite's contract. A line missing from the draft is a lost detail. A claim in the draft with no line is an added one. Both are defects.

For new writing, the ledger is the list of sources instead: each claim points at this repository's documents, its build or plain reasoning.

### 3. Shape

Choose the page's shape from [page-anatomy.md](references/page-anatomy.md) and write the outline as headings. Then plan the figures: which sections get one, what kind, and which sentences each node comes from. A figure you can't draw faithfully is a question for the report, not a guess on the page.

### 4. Draft, then read it as a newcomer

Write section by section, by [voice.md](references/voice.md). Keep the original's order unless the shape calls for another. Edit the file in place on the branch: git keeps the before. If the file has uncommitted changes or isn't tracked by git, first copy the original outside the repository, so the detail check has a before to compare with.

Then read the draft as someone new to the method would. Split every sentence that makes you hold more than one thing. Look hardest for the habits [details.md](references/details.md) lists: appositive chains, noun stacks, semicolon runs and definitions tucked inside longer claims.

### 5. Check

Run each check and fix what it finds:

1. **The detail check.** It compares the page with its last committed version, or with the copy you saved. It warns on a changed code block, on missing inline code, numbers or links, and on strength words that went missing. Clear every warning, or explain it in the report.

   ```bash
   python3 ${CLAUDE_SKILL_DIR}/scripts/detail-check.py <file>
   python3 ${CLAUDE_SKILL_DIR}/scripts/detail-check.py <saved original> <file>
   ```

2. **The ledger.** Tick every line against the draft. Nothing missing, nothing added, no claim stronger or weaker.
3. **The independent reading**, for a rewrite longer than about 500 words. Give a subagent the original and the rewrite, and nothing else. Ask it for what was lost, what was added, what changed strength and which terms were swapped. Resolve every item.
4. **The prose check** on the target. Fix each warning or explain it. A long sentence can stay if splitting it loses a detail, but say so.
5. **The links across the repository**, if a heading was renamed. Run the prose check on the repository root and fix every broken link it names in files you're allowed to change.
6. **The scrub gate**, which every document outside `.claude/` must pass:

   ```bash
   python3 tools/scrub-check.py
   ```

### 6. Report

End with a short report:

- **What changed**, per page, in a sentence or two.
- **The numbers before and after**, as a table: sentence mean, long-sentence share, commas, paragraph mean, figures.
- **The details:** the detail check's result, any warning left with its reason, and what the independent reading found.
- **Figures added**, and what each shows.
- **Headings renamed**, and the links fixed.
- **Questions for the owner:** terms used two ways, claims that read as wrong or unclear, sections that want a figure you couldn't draw faithfully, and anything in scope you left alone.

Then stop. Don't commit or push unless asked. When asked, write the message by [commits.md](references/commits.md).

## What this skill never does

- **Never changes what a document claims.** That includes a qualifier, a number, an identifier, a theorem's name, a distinction between two terms, or the meaning of a rule.
- **Never trades a detail for a shorter sentence.**
- **Never invents** a fact, a citation, an example or a figure's node. A gap goes in the report as a question.
- **Never edits inside a code block.**
- **Never updates a dated record** to what is known now. It rewrites the voice and keeps the record.
- **Never copies text or figures** from the reference architecture or any other source.
- **Never commits or pushes** unless asked.
