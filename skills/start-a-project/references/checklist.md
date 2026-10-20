# The acceptance checks

Run from the new package's directory. `Package` is the package's name; `tools/` is the package's own, copied in by the script.

| Check | Command | Pass means |
| --- | --- | --- |
| The five things are sourced | read the corpus beside your notes | Each of package name, calculus source, principal, boundaries and first design has a sentence in the corpus, or is marked not given |
| The require names a release | read `lakefile.toml` | `rev` is a tag, `v<version>`, the newest on the repository unless the owner named another; never a branch |
| The package builds | `lake build` | Success, no warnings, no `sorry`; the first build fetches the calculus at that tag |
| The generators run | `lake exe fixtures` | `generated/` exists and is empty: nothing registered yet |
| The checker runs | `lake exe replay` | Exit code 2, no file named: nothing registered yet |
| The review line | `python3 tools/review-check.py Package/Governance.lean .` | Warns "not yet reviewed"; the design may not exist yet |
| The gate | `python3 tools/mutants.py mutants.json` | `mutation score: 0/0`, exit code 0 |
| Every declaration documented | read `Architecture.lean` | A doc comment above every `inductive`, `structure`, `def` and `abbrev` |

## Reading a failure

- `revision 'v...' not found`: the release tag is not on the remote yet; the release procedure pushes tags, so this is the owner's push to make, not a reason to fall back to a branch.
- `could not read a release tag`: the script could not list the repository's tags, usually no network; pass `--rev v<version>` or `--calculus <checkout>`.
- `cloning https://...` then a connection error: the git require needs the network; `--calculus <checkout>` requires it by path instead.
- `unknown package 'cell-calculus'` or `no such file` with a path require: the `--calculus` path was wrong or not relative to where the package ended up; fix `path` in `lakefile.toml`.
- `toolchain not updated; already up-to-date` is information, not a warning.
- A `sorry` warning: something was written that is not architecture; take it out, it belongs in a cell module.
- `mutation score` not `0/0`: a mutant was listed with no model to mutate; the list is empty until the first cell.
