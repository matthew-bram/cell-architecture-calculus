# Security

The repository holds a Lean package, a worked example with a reference implementation in Python's standard library, and three gate scripts. Nothing in it listens on a network, stores credentials or runs with privileges beyond the build's.

If you find a defect with a security consequence, report it privately through the repository's security advisories rather than in a public issue. That way, a fix can be published with the report. This applies whether the defect is in the gate scripts, in the workflow, or in a claim a document makes about what the method guarantees.

A claim in a document that overstates a guarantee is treated as a defect of this kind, because readers act on it.

The latest tagged release on `main` is supported.
