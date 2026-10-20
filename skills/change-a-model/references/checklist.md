# The kinds of change

| The design | The model | Never |
| --- | --- | --- |
| Adds a row | New constructor, branch, example with theorem, as model-a-cell writes them | |
| Changes an example's expectation | New example with a new id; the old retired in its `GovernedExample` with `supersededBy`, `retiredOn`, `because` | Editing the old value |
| Changes a universal claim | New theorem; the old keeps its name and gets `attribute [deprecated <new> (since := "<date>")]` | Changing the old statement |
| Changes a Decide or React branch | The body changes; the example pinning the old branch is retired for one pinning the new; a mutant on the branch is rewritten | Keeping an example that now fails |
| Removes a row | Retired with the reason; coverage reports what the live set no longer reaches | Deleting it |
| Changes an example's expectation so that its `_holds` theorem is now false | The old theorem cannot stay, since its statement is false; its name goes in the header's `superseded` with the successor's, and `<old>_retired : <old example>.holds <cell> = false` takes its place so the reversal is pinned, not forgotten | Keeping a theorem that no longer proves, or dropping its name without a row in the header |
| Changes a reaction example | The same as a command example, in a `GovernedReactionExample` set with `liveReactionsOf` | Editing the reaction example in place |
| Renames a thing | New name; the old as a deprecated alias | A changed statement under the old name |
| Changes an event's fields | A new version type; the sum over versions gains it; the upcaster stays total | Removing a version |
| Changes a threshold or a contract | The value changes; the old is a row in the header's `superseded` | Silent change |
| Moves the project to a new release of the calculus | `rev` in `lakefile.toml` becomes the new tag, `lake update cell-calculus` pins its commit in the manifest, the build runs with the deprecation warnings the release introduces, each naming a successor to move to, and the gate stays green; a changelog row names the two releases | Editing `rev` in passing, or to a branch; a build left warning |
| Changes the design at all | The review check fails on the new hash if the line was signed, or keeps warning if it never was, until the reviewer signs | Re-signing it yourself |

## The commands

From the project's directory, with `tools` the package root's `tools/`:

```
lake build                      # green; only the deprecation warnings you introduced
lake exe fixtures               # the live set rendered
python3 tools/review-check.py <Package>/Governance.lean <repository root>   # fails on the new hash if signed, warns if never signed: correct
python3 tools/mutants.py mutants.json                                       # every mutant killed, none dropped
```
