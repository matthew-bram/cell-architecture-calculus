---
name: review-a-model
description: Prepare the human review of a model in the cell calculus against its annotated design, and record the sign-off as the design's review line in the project's header, one per design, which the build checks: the names, the comments, every theorem's statement read against the design's sentence it stands for, every Decide branch against the example that pins it, the four build commands, and the review line with the design's path and hash. Use this skill whenever someone asks to review, check, verify, audit, sign off, approve or "make sure the model matches the design" for a cell, a module, a slice or a package in a project built on `cell-calculus`; whenever a review line is to be signed or a model marked reviewed; whenever the review check warns that a model is unreviewed; and whenever a build is green and someone asks whether the model says what the design says, even if the words "review" or "Lean" are never said. Never sign on your own: the packet is yours, the signature is the reviewer's.
---

# Review a model

A green build proves the model is consistent with itself. It cannot prove the model says what the design says, because a theorem that states the wrong thing proves just as well. That gap is the one step in the method no program can do, and this skill prepares it so that a person can do it in minutes and sign for it where the build can see.

Two things follow. You prepare, the reviewer signs: you never write a hash into the review line unless the reviewer has told you to sign and given their name. And the packet reports what it finds, including what blocks a signature; a packet that says "all good" over an unpinned branch is worse than no review, because the review line will then certify it.

Paths below are relative to this skill's directory; the package root, two levels up, holds `docs/`, `tools/` and `examples/`. Read first, every time:

1. `../../docs/style-guide.md`, section 10, what a reviewer checks and in what order, then sections 2, 3 and 5 for what the first two checks look for.
2. `references/golden/circulation/review.md`, the packet for the worked example's circulation slice against `../../examples/library/designs/circulation.md`, with its findings. Your packet should look like it, for the same reasons.
3. `references/checklist.md`, the six checks with what passes each.

## The procedure

Six checks, in the style guide's order, because each depends on the last. Write the packet as you go, from `assets/review-packet-template.md`.

### Check 1: the names

Every type, field, value and theorem in the module against section 2: types are words that say what they are, values are named by what they are or by their example id, theorems subject then claim. List what does not conform; do not rename anything.

### Check 2: the comments

Every declaration has a doc comment, and the comment says what the thing is called in the sources where it has a name. List what is missing or restates the code.

### Check 3: the theorems state the right thing

This is the check that matters. For every universal theorem in the module, and every theorem the design's Universal claims table names, write a row: the theorem's name, the design's sentence, the Lean statement in words, and whether they say the same thing. A theorem with a hypothesis the sentence does not have states less than the sentence; a sentence with a condition the theorem does not have is a theorem that states more than was asked. For every example value, read its Given, When and Expect against the design's row with the same id. A row whose expectation differs from the design's, in either direction, is a finding, whatever the build says. Then read the governed set: an example the model retired that the design still lists, or a model example the design has no row for, is a finding too.

### Check 4: coverage, by branch

The build checks that every command, event and refusal kind reaches an example. The reviewer checks what the build cannot: that every branch of `decide` and `react` has an example that pins it. Write one row per Decide and React row of the design: the branch, and the example id whose Given and When reach it, or "none". A branch with none is a missing row in the design and blocks the signature.

### Check 5: the build

Run the four commands from the project's directory and record the last lines of each: `lake build`, `lake exe fixtures`, the review check, the mutation gate. Put the generated feature file's content in the packet, since it is what a non-technical reviewer reads.

### Check 6: the review line

State what signing would write: the design's path, its hash now (`shasum -a 256 <design> | cut -c1-16`), and that the reviewer and date are theirs to give. Then one of two endings. If any finding blocks, say so and stop. If nothing blocks and the reviewer has told you to sign and given their name and the date, add or complete the design's review line in the project's `ProjectHeader`, one line per design, with the path, the hash, the name and the date, run the review check and record that it says "ok". Never sign with findings open unless the reviewer has read them and said to.

## What you never do

- Sign on your own, or sign over a blocking finding the reviewer has not seen.
- Fix what you find. A review changes nothing; it reports. The findings go to the design or to model-a-cell.
- Trust the build for check 3. Read every statement.
- Mark a branch covered because an example exists for the command; the example must reach the branch.

## The report

The packet is the report. End with three lines in prose: how many findings and which block, whether the review line was signed, and what the owner does next.
