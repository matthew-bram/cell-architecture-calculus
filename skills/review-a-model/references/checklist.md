# The six checks

In the style guide's order. Each depends on the one before it.

| Check | What is read | Pass means | Blocks a signature when |
| --- | --- | --- | --- |
| 1 Names | Every declaration against style guide section 2 | Every name conforms | Never on its own; listed for model-a-cell |
| 2 Comments | Every declaration against section 3 | Every declaration has a comment that says what it is | Never on its own; listed |
| 3 Statements | Every universal theorem against the design's sentence; every example against the design's row; the governed set against the design's table | Every pair says the same thing | A theorem states something other than its sentence; an example expects something other than its row; the design and the model disagree on which examples are live |
| 4 Branches | Every Decide and React row against the examples that reach it | Every branch has an example | A branch has none |
| 5 Build | `lake build`, `lake exe fixtures`, the review check, the mutation gate | All green; the review check warns "unreviewed" | Any red |
| 6 Review line | The design's path and hash; the reviewer's name and date, as the design's own line in the project's `ProjectHeader` | Written only when told, then the review check says "ok" for that line | Not applicable |

## Reading the model for check 3

- A hypothesis in the theorem's signature, `(hopen : s.closed = false)`, is a condition. The design's sentence must carry the same condition, or the theorem states less.
- `by decide` on an example proves the model agrees with the example value, not that the value agrees with the design. Read the value.
- A `GovernedExample` with `supersededBy` is retired; the design's Examples table should not list it as live, and should list its successor.
