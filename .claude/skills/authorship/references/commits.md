# Commit messages and pull requests

How a change describes itself. `main` takes changes by squash merge, so a pull request's title and description become the one commit on `main`. Write them as the commit message.

## The title

- **One line, 72 characters or fewer.**
- **Says what is now true**, in the present tense: "The forward record carries no reference to any other project". The repository's titles state an outcome, not a command.
- **Names the area** the change is in when it isn't obvious: the calculus, the example, a document, a skill, a gate.
- **No trailing period.** GitHub appends the pull request number when it merges.

## The body

- **A blank line after the title**, then prose wrapped at 72 characters.
- **What changed, then why.** One short paragraph each is usually enough. The pull request template asks for "one or two sentences in prose".
- **The why is the reason, not the work.** "So the statement rests only on facts a reader can check" beats "Edited three files".
- **Name the decision and whose it was** when an owner decided: "removed by the owner's decision".
- **Say what was not done** when a reader would expect it.
- **Lists only for parallel items**, such as the files a mechanical rename touched.
- **No attribution lines** and no tool names.

## Before and after

A commit from before this skill existed, written as one line of 569 characters:

```text
The forward record carries no reference to any other project. The one remaining bullet in what is already known, which disclosed that the direction was seeded by private notes on another project, is removed by the owner's decision, so the problem statement stands on three facts from this repository and on plain reasoning and nothing else. The directory README's fifth rule, which had asked a seeded direction to disclose its seed, now says instead what the statement already does: every claim points at this repository's own documents and build or at plain reasoning.
```

The same message in the voice:

```text
The forward record carries no reference to any other project

The problem statement's "what is already known" kept one bullet saying
the direction was seeded by private notes on another project. It is
removed by the owner's decision. The statement now rests on three facts
from this repository and on plain reasoning, and on nothing else.

The directory README's fifth rule asked a seeded direction to disclose
its seed. It now says what the statement already does: every claim
points at this repository's own documents and build, or at plain
reasoning.
```

## The pull request description

Fill the template in `.github/pull_request_template.md`:

1. **What changed, and why.** The commit body, as above.
2. **Which kind of change.** Keep the lines that apply and delete the rest.
3. **The gates.** Tick only the ones you ran, and say which you didn't.
4. **The rules.** Tick each one that holds.

A pull request that rewrites documents adds one more line under *What changed*: the prose check's numbers for each page, before and after.

## A changelog row

One row per decision, newest first. The date, what changed in one sentence, and why in one sentence. A voice rewrite with no change in meaning is not a decision and gets no row. A change to what the style guide requires is a decision and does.
