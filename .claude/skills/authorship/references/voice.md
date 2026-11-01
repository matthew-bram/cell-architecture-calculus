# The voice

How this repository's prose should read, rule by rule, with a rewrite from the repository's own pages for each.

- [Where the voice comes from](#where-the-voice-comes-from)
- [What the repository already does well](#what-the-repository-already-does-well)
- [The rules](#the-rules)
- [Before and after](#before-and-after)
- [Words](#words)

## Where the voice comes from

The documents here are exact. The aim is to make them just as easy to read. The model for readability is the [WSO2 cell-based reference architecture](https://github.com/wso2/reference-architecture/blob/master/reference-architecture-cell-based.md), the page the README already cites for the word *cell*. We take how it reads. We never take what it says.

Measured with `scripts/prose-check.py`, that page averages about 16 words a sentence. Only 2% of its sentences run to 35 words or more. It uses fewer than one comma a sentence and about 43 words a paragraph. It also carries 27 figures in about 6,000 words. Measured the same way when this skill was written, the repository's pages ran 6% to 18% long sentences and 1.1 to 1.8 commas a sentence. `docs/the-calculus.md` averaged 102 words a paragraph. The whole repository had one figure.

**What we take from it:**

- **Short sentences.** One idea each, and a plain subject and verb.
- **Figures that lead.** Most sections open with a diagram, and the prose then walks through it.
- **Terms defined at first use.** The term is in bold, inside a short sentence that says what it is.
- **A table of terms up front** on a page that introduces several at once.
- **Bullets with a bold lead word** for parallel items, and numbered lists for steps and recommendations.
- **A worked example told in order**, one part at a time.
- **Page furniture.** A title, a one-line subtitle, a short abstract and a linked list of sections. The white paper already has these.

**What we leave behind:**

- Its typos and grammar slips.
- Its product, vendor and consulting material.
- Headings five levels deep. Three is the limit here.
- Its text. Never copy a sentence or a figure from it. Describe the quality in our own words, and write our own figures.

## What the repository already does well

Keep these. The rewrite changes how things are said, not these habits.

- **Exactness.** Every number comes from the build. Every identifier, file name and command is exact.
- **The four words.** *Proved*, *checked*, *tested* and *assumed* mean what the [README](../../../../README.md#what-it-proves-checks-tests-and-assumes) says, and only that.
- **Headings that state the claim.** "Outcomes have three values" tells the reader more than "Outcomes". A heading that states a claim is held to the claim: it must say no more than its section does.
- **Pointing at the file.** "In the example this is `Circulation.lean`" lets a reader check the claim. A bare pointer may become a short sentence, "It is in `Circulation.lean`", but it gains no verb the page doesn't use. "`tools/mutants.py` runs it" says what the script does, and the page never said that.
- **The original owns meaning.** A rewrite changes how a claim is said, never what it claims. This is the documents' version of the rule that the design owns meaning.

## The rules

### 1. One idea per sentence

The repository's most common habit is the chain. A sentence states a claim, then hangs a list of clauses off it with commas. Each clause is fine. Together they make the reader hold five things at once.

Split the chain. State the claim in one sentence. Put the items in a list, or give each its own sentence.

A sentence with more than three commas is usually a chain. A sentence of 35 words or more nearly always is.

### 2. Lead with the point

The first sentence of a paragraph says what the paragraph claims. The rest supports it.

The first paragraph of a page says what the page is and who it is for. A reader should know in two sentences whether to keep reading.

### 3. Define a term once, in bold, in a short sentence

Write "A **cell** is a self-contained unit of components." Then use *cell* the same way for the rest of the page.

Don't define a term by apposition in the middle of a longer claim. If a page introduces more than three terms, put them in a table near the top.

### 4. Lists for parallel things, tables for attributes, prose for reasoning

- **A list** holds items of the same kind: steps, options, rules.
- **A table** holds items that each have the same attributes: a name, what it does, where it lives.
- **Prose** holds reasoning: because, so, unless, which is why.

Don't turn reasoning into bullets. A bullet list of "because" clauses loses the because.

**Keep a table that is already there.** Its rows and columns are part of what the page says: they tell the reader which things share which attributes. Don't dissolve it into prose, split it in two, or drop a column. Each cell keeps what it says, word for word, even when it runs long. The reader looks for an item in its row, so moving it out of the cell loses where it was. Inside a cell you may split a semicolon into sentences, and nothing more.

### 5. Address the reader the way the page needs

- **Guides** say *you*: "Install Lean's version manager once."
- **Papers** say *we* for the authors, sparingly: "We report the method applied end to end."
- **Reference pages** use neither. The subject is the shape: "A journey is a term."

### 6. Active voice, present tense, a concrete subject

Write "The kernel checks every example," not "Every example is checked." Use the passive only when the actor doesn't matter or is unknown.

### 7. Plain words

Use the common word. The [word table](#words) lists the replacements. Cut words that add no fact: *simply*, *just*, *very*, *clearly*, *in fact*, *it is worth noting that*.

Plain words are for ordinary English, never for a term of art. *Fold*, *refusal*, *supersession*, *principal*, *composition*, *succession* and every other term a page here defines stay exactly as they are. If the reader may not know one, explain it at first use. Don't swap it for a friendlier word.

### 8. One word for one thing

Use the term the defining page uses. Don't vary it for elegance. If the repository uses two words for one thing today, report it to the owner. Don't pick one silently.

### 9. Say exactly how sure

Use the four words in their places. Write *may* only when something may. Don't hedge a proved theorem, and don't upgrade an assumption to a fact.

### 10. Numbers

Use numerals for anything that comes from the build or that a reader might compare: "40 universal theorems", "7 of 7", "version 2.3.0". Use words for small numbers in ordinary prose: "three pure functions", "two tables".

### 11. Links and code

- **Link the first mention** of a page, file or source, not every mention.
- **Link text names the target.** Write `the [DAG rule](docs/the-dag-rule.md)`, never `click [here](docs/the-dag-rule.md)`.
- **Inline code** marks identifiers, file names, types and commands.
- **A sentence before each code block** says what it shows.
- **Never edit inside a code block** in a rewrite. A Lean block is compiled elsewhere, and a command block is run.

### 12. American spelling

*behavior*, *modeling*, *organization*, *judgment*, *labeled*, *serialize*. The prose check flags the British forms.

## Before and after

Each pair is a passage from this repository and a rewrite in the voice. Every claim in the original survives, and nothing is added.

### A chain split into a claim and a list

From `docs/the-calculus.md`, *The problem the calculus answers*:

```markdown
Documentation for software has three defects it cannot cure on its own: nothing shows it is understood the same way by every reader, nothing shows it is accurate, and nothing shows that the code built from it went where it pointed. The documents make claims about structure, which capabilities exist, which journeys use them, which zones may talk to which, and the claims are kept by hand in several places that drift. Once the code exists nothing but a person's memory says whether it went where the documents pointed.
```

```markdown
Software documentation has three defects it can't cure on its own:

- Nothing shows that every reader understands it the same way.
- Nothing shows that it is accurate.
- Nothing shows that the code built from it went where it pointed.

Documents make claims about structure: which capabilities exist, which journeys use them, and which zones may talk to which. Those claims are kept by hand, in several places, and the places drift apart. Once the code exists, nothing but a person's memory says whether it went where the documents pointed.
```

The three defects were parallel, so they became a list. The claims about structure were a list inside a sentence, so they moved behind a colon. "Several places that drift" became its own sentence.

### A term defined at first use

From `docs/the-calculus.md`, *The cell*:

```markdown
The word is the cell-based reference architecture's: a cell is a self-contained unit of components with its own record and a gateway as the only way in, independently deployable and observable, communicating with other cells through its gateway and the facts it publishes. The calculus takes that unit and says what is inside it.
```

```markdown
The word *cell* comes from the cell-based reference architecture. A **cell** is a self-contained unit of components. It keeps its own record, and its gateway is the only way in. It can be deployed and observed on its own. It talks to other cells through its gateway and through the facts it publishes.

The calculus takes that unit and says what is inside it.
```

One sentence of 45 words became five short ones. Each says one thing about a cell. The last line gets its own paragraph because it is the point of the section.

### A technical paragraph with the identifiers kept exact

From `docs/the-calculus.md`, *Outcomes have three values*:

```markdown
`Either[Ex, B]` at every gateway, and `Ex` is itself a sum, `Either[Refused, Unknown]`. *Refused* is the cell's invariants saying no: deterministic, final, the journey stops at a named outcome. *Unknown* is the failure window: the effect may or may not have landed. The two sides come from different places, and the types say so. A cell's `decide` returns `Except Refusal (List Event)`, the inner `Either[Refused, B]`, so a cell can say yes or a deterministic no and nothing else. The third value is added only where a result crosses the wire: `liftToWire` maps a cell's result into `Except (Exception Refusal) B`, turning a refusal into `refused` and never producing `unknown`, which is the theorem `model_never_unknown`. Only the world produces it. The model's job is to say what the caller may do on it: retry with the same key, never decide as if the effect did not happen. Conflating the two is the specific bug the window produces, a timeout treated as a refusal and an effect that landed compensated away.
```

```markdown
Every gateway returns `Either[Ex, B]`: a value, or an exception `Ex`. `Ex` is itself a sum, `Either[Refused, Unknown]`.

- **Refused** is the cell's invariants saying no. It is deterministic and final, and the journey stops at a named outcome.
- **Unknown** is the failure window. The effect may or may not have landed.

The two come from different places, and the types keep them apart. A cell's `decide` returns `Except Refusal (List Event)`, which is the inner `Either[Refused, B]`. So a cell can say yes or a deterministic no, and nothing else.

The third value appears only where a result crosses the wire. `liftToWire` maps a cell's result into `Except (Exception Refusal) B`. It turns a refusal into `refused` and never produces `unknown`; that is the theorem `model_never_unknown`. Only the world produces *unknown*. The model's job is to say what the caller may do about it: retry with the same key, and never decide as if the effect didn't happen.

Mixing the two up is the bug the failure window produces. A timeout gets treated as a refusal, and an effect that did land is compensated away.
```

Every identifier is unchanged. The two kinds of exception were parallel, so they became a list with the terms in bold. The one long paragraph became four, each with one job.

### A guide paragraph that speaks to the reader

From `README.md`, the section on modeling your own system:

```markdown
A team's own package is a `lakefile.toml` that requires the calculus over git at a tag, plus the two types the calculus is generic over, both algebraic data types defined from your corpus: the **principal**, who a person or system is when they act, and the **subject**, what an event is about, bounded by a trust zone where you have one. From there, each cell is five types transcribed from its design's tables, the command, foreign event, event, state and refusal types, and one `Cell` value with a branch per row of the Decide table.
```

```markdown
Your own package starts as a `lakefile.toml` that requires the calculus over git, at a tag. Then you define the two types the calculus is generic over. Both are algebraic data types, defined from your corpus:

- The **principal** is who a person or system is when they act.
- The **subject** is what an event is about, bounded by a trust zone where you have one.

Each cell is then five types, transcribed from its design's tables: the command, foreign event, event, state and refusal types. One `Cell` value ties them together, with a branch for each row of the Decide table.
```

The page is a guide, so it says *you* throughout. The two defined terms became a list, each in bold with its definition.

### A page that leads with what it is

From `future/README.md`, the opening:

```markdown
The forward record. [research/](../research/) holds the notes that led to the method, as they were written on their days. This directory holds the directions being explored now, each stated as a problem before anything is built, with its experiments and their notes beside it once there are any. Nothing here changes [cell-calculus/](../cell-calculus/) or [examples/library/](../examples/library/) until a shape has been proved and graduates by supersession, with its universal theorem, its doc comments, a mutant its theorem kills and a changelog row, as the [contributor's guide](../CONTRIBUTING.md) says of any shape.
```

```markdown
This directory is the forward record. It holds the directions being explored now. [research/](../research/) looks back: it keeps the notes that led to the method, as they were written. This directory looks ahead.

Each direction starts as a problem statement, written before anything is built. Its experiments and their notes sit beside it once there are any.

Nothing here changes [cell-calculus/](../cell-calculus/) or [examples/library/](../examples/library/) until a shape has been proved and graduates by supersession. A shape that graduates carries what the [contributor's guide](../CONTRIBUTING.md) asks of any shape: its universal theorem, its doc comments, a mutant its theorem kills, and a changelog row.
```

The fragment "The forward record." became a sentence that says what the page is. The contrast with `research/` got its own sentence, and so did each rule. The *until* stays in the same sentence as what it limits.

The first drafts of these rewrites lost three details: the identifier `Ex`, the *until* in this last pair, and a *nothing but* that became *only*. The detail check caught all three. [details.md](details.md) says what counts as a detail and how to keep it.

## Words

Use the left column's replacement. A dash means cut the word and say the fact instead.

| Instead of | Write |
| --- | --- |
| utilize, leverage | use |
| in order to | to |
| is able to | can |
| prior to | before |
| a number of | some, or the number |
| whereby, wherein | where, in which |
| conflate | mix up, treat as the same |
| it is worth noting that, note that | — |
| simply, just, very, clearly, in fact | — |
| seamless, robust, powerful, elegant | — |

Contractions are fine in guides and READMEs: *don't*, *it's*, *can't*. Papers and reference pages use them sparingly.
