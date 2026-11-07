# Page anatomy

The shapes a page in this repository takes. Pick the shape before writing a word, then write the outline as headings.

- [Every page](#every-page)
- [The root README](#the-root-readme)
- [A directory README](#a-directory-readme)
- [A paper](#a-paper)
- [A guide](#a-guide)
- [A reference page](#a-reference-page)
- [A rules page](#a-rules-page)
- [A problem statement](#a-problem-statement)
- [A research note](#a-research-note)
- [The changelog](#the-changelog)

## Every page

- **One H1**, the page's name. Sentence case, no trailing period.
- **An opening paragraph** of two or three sentences. It says what the page is, who it is for, and where to go instead if this is the wrong page.
- **Headings to level 3 at most.** H2 for sections, H3 for parts of a section. If a page needs H4, split the page.
- **Headings that say something.** A claim ("A journey is a term") or a task ("Write the corpus") beats a label ("Journeys").
- **Numbered H2s** only where order matters: a paper's sections, a guide's steps, a style guide's rules.
- **A figure near the top** of any section whose subject has a shape. [figures.md](figures.md) says when.
- **No orphan sections.** A heading followed by one sentence is a paragraph in the section above it.

Renaming a heading changes its anchor. Before renaming one, search the repository for links to it and fix them in the same change.

## The root README

The front door. A reader decides here whether the method is worth their time.

1. **Title and one paragraph.** What the repository is, in plain words, with the link to the reference architecture for the word *cell*.
2. **A figure of the round trip.** One example's round trip, drawn from the opening: from the design into the model and the code, and back to the model through the code's traces.
3. **The case for the method.** The two papers and who each is for.
4. **How a claim becomes a theorem.** The five roles of a formal argument for a reader new to formal methods: the rulebook, the givens, the claim, the proof and the outcome, with each one's standard name, shown for 2 + 2 = 4 and for an example in this repository, ending with which of the four words each kind of theorem takes.
5. **The calculus changes as the state of the art does.** The thesis that the calculus is not fixed: each version is the method as published practice stood when that version was written. Then why practice will move: the published sources the shapes stand on, the evidence that is still open and the part of the problem that is new. Then what stays fixed (a theorem holds for the version it was proved against) and what moves between versions (the shapes, the practices and the names), how a change arrives (by supersession, with a project moving to a newer tag when it chooses), and the calculus's history so far, from version 1 to the first public release.
6. **The idea in code.** The short Lean and Gherkin excerpts, each with a sentence saying what it shows.
7. **Quick start.** Install, build, run the gates.
8. **Modeling your own system.** The short form of the guide, as a table of steps.
9. **The layout, the documents, the skills.** One table each.
10. **What it proves, checks, tests and assumes.** The four words.
11. **License.**

## A directory README

What the directory holds, how its contents are worked, and an index.

1. **One paragraph:** what is here and how it relates to its neighbors.
2. **How it is worked:** numbered rules, one claim each, if the directory has rules.
3. **The index:** a table of its files or entries, newest first if they are dated.

## A paper

`white-paper.md` and `executive-summary.md`. Read start to finish by someone deciding whether to adopt the method.

```markdown
<h1 align="center">Title</h1>
<h3 align="center">One-line subtitle</h3>

> *Abstract, in italics, 150 to 250 words. The problem, what the paper presents, and the evidence with its numbers.*

## 1. Introduction

The problem, then the question the paper answers. It ends with the roadmap:

The rest of this paper is structured as follows:

+ [**Section 2**](#2-...): One sentence on what the section does.
+ ...

## 2. ... numbered sections, each opening with its claim or its figure

## References

[1] Author, *Title*, year.
```

The abstract is the one place a long paragraph is allowed. Even there, keep each sentence to one idea. A reader who stops after the abstract should know the claim and the evidence.

## A guide

`docs/getting-started.md` and `docs/the-lifecycle.md`. Followed by someone doing the thing.

1. **Opening:** what the reader will have at the end, and the one rule that holds throughout.
2. **Before you start:** what to install or read first.
3. **Numbered steps as H2s:** `## 1. Write the corpus`. Each step says what to do, shows the table or figure that defines it, and ends with where the example does it ("In the example this is `corpus/`").
4. **What next:** where to go when the steps are done.

Guides say *you*. Each step starts with a verb.

## A reference page

`docs/the-calculus.md`, `docs/foundations.md`, `docs/the-dag-rule.md`. Looked up, not read straight through.

1. **Opening:** what the page covers and how each entry is laid out.
2. **Terms:** a table near the top when the page introduces more than three terms.
3. **One section per shape or idea.** The heading states the claim. Then, in order:
   - the figure or the code that shows the shape;
   - the definition, with the term in bold;
   - the theorem or the check that holds it, by name;
   - the file it lives in;
   - the source it comes from, if any.
4. **Limits:** what the page doesn't cover or the shapes don't do.

## A rules page

`docs/style-guide.md`, `CONTRIBUTING.md`, `CLAUDE.md`. Consulted while working.

- **Numbered sections**, one per area.
- **Each rule in bold as a short imperative or claim**, then the reason in one or two sentences, then an example.
- A rule's meaning never changes in a rewrite. A change to what the style guide requires is a decision with a changelog row, not an edit.

## A problem statement

Under `future/`. Its fields are fixed by `future/README.md`:

- why the direction matters;
- the hypothesis, in one sentence;
- what would count as evidence for it, and against it;
- how it might be explored;
- what it is not.

A problem statement is dated. It is revised by a dated note, so a reader can see what was believed before an experiment and what after. A rewrite in the voice is not a revision: it keeps every claim, the date and the vocabulary of the day. [details.md](details.md#dated-records) says how.

## A research note

Under `research/`. A dated record of how the method took its shape.

1. **Title**, then **the date line**: what the note is, the date, and the note it follows from.
2. **The confidence key**, if the note marks claims **[H]**, **[M]** or **[L]**.
3. **Revision notes**, as dated blockquotes, directly under the key.
4. **The sections the note had**, in its order, each opening with its claim.
5. **Sources**, last.

Everything in [dated records](details.md#dated-records) applies.

## The changelog

`CHANGELOG.md` has one row per decision, newest first: date, what changed, why. Each cell is one sentence. The *why* names the reason, not the work done.
