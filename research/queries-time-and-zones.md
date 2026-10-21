# Queries and time as inputs, and zones as types

Rocks 2 and 4, worked · Oct 13, 2026 · from [big-rocks.md](big-rocks.md), with the shapes in `Calculus.lean`, a recommendation on each open question, and the document edits for the owner to confirm

**Confidence.** **[H]** run here today, or read in the project's own documents; **[M]** read in a specification's summary; **[L]** from memory.

## Rock 2. Queries and time as inputs, never calls

### The rule

Functional core, imperative shell. The shell gathers every query answer and the clock reading before it calls `decide`, and hands them over as one argument beside the command. A decider never calls out. Verified today that the alternative is unrepresentable: a decider that reads the clock itself is rejected with

```
error: Type mismatch: IO.monoMsNow has type BaseIO Nat
```

because `decide` returns `Except`, not `IO`, and there is no way to run an effect inside it.

Nothing in the generic `Cell` changes. A cell that reads inputs is a cell whose command type is `Inputs C Q`: the command envelope, the record of answers `Q`, and the clock reading. So an example carries the inputs in its When, which is the *with* clause the rock asked for; a trace records them with each command; and a replay is exact because the inputs are in the trace and not in the world.

| Shape | What it is | In the file |
| --- | --- | --- |
| `Query S A` | A pure read of the owning cell's state, no events, no obligation; rock 8's query archetype | `booksAvailable` |
| `Answer A` | A value stamped with the owner's version when it was read | `{ value, asOf }` |
| `Inputs C Q` | The command, the answers, the clock | `budgets` takes `Inputs BudgetCmd BudgetAnswers` |
| `needs` | What the shell must gather for each command, declared | `BudgetCmd.needs` |
| The clock | A cell whose events are ticks; a timer-driven journey's root is a tick | `clock`, `tick_monotone` |

### The three open questions, with a recommendation on each

**1. Is a stale answer a refusal, an `unknown`, or a decision made on old data and recorded as such?** The third, with the check where the invariant lives. The decider cannot know its answer is stale, so it is neither a refusal nor an `unknown` at the decider. The decision is made on the answers given and records their version: `moveRequested amount asOf` carries the books' version the balance was read at, and `move_recordsOwnersVersion` says that for every pair of histories the recorded version is the books' at the time of the read. The owner then checks the version when the resulting command lands, and refuses it if a commit has landed since; that is the books' data model's lock version doing the job it was designed for. `available_fresh` and `available_staleAfterCommit` are the two halves: an answer is fresh against the state it was read from, and stale against that state after any commit, for every key and amount. The books' balance against allocations, the case the rock named, is exactly this: budgets decides the move on the stamped balance, and the books refuse the move if the balance moved first. The duplication test in method 5, query when exact and now, gains its meaning of "now": the owner's version at the read, checked at the write.

**2. Does a tick carry the wall clock, a logical clock, or both?** The wall clock, and the logical clock is already there. Lamport's point is that two clocks are needed, and the envelope supplies the second: causation orders events across cells, and each owner's version orders them within a cell. A tick carries an `Instant`; `recordedAt` and `issuedAt` are wall-clock readings; nothing in the calculus decides on wall-clock order between cells. Vector clocks are not needed because every cell's history is totally ordered and cross-cell order is causation, which the per-journey pass checks. `tick_monotone` says a late or repeated tick emits nothing, so the clock cell's history never runs backwards and the clock is an idempotent receiver like every other cell.

**3. Can a decider's `queries` depend on the command?** Yes, and it should, so the shell gathers only what this command needs. `BudgetCmd.needs` declares it per command. What the type does not enforce is that a decider reads only what its command declared, and the honest form of that is a theorem per command that declares nothing: `setTarget_readsNothing` says the decision is the same whatever the shell gathered and whatever time it was, for every envelope, every pair of answers and every pair of readings. The annotation grammar should ask for that theorem for every Decide row whose "reads" column is empty.

### What the books slice gains

`BooksState.version` as the count of commits honored, the books' data model's lock version in proxy; `booksAvailable` as the books' first query; `budgets` as the first cell that decides on another's answer; `moveJourney` as the shell, the one place a query is called, outside every decider; the clock cell; two examples with a *with* clause, `BUDGETS-MOVE-1` and `2`.

## Rock 4. Zones as types

### The rule

An ID the ID map maps is indexed by its zone, so a record or an event in one zone cannot be built with another zone's ID: the kernel refuses, as the envelope work showed with the billing ID in an AI-zone event. The scrub is a parse between zones, owned by the private zone's cell, and the one function in the system whose type names two zones; re-identification is its inverse with the same owner. The alias map carries its invariant as a field, so a map that does not invert cannot be constructed. Verified today:

```
error: Tactic `rfl` failed: some { raw := "B-1" } is not definitionally equal to some x
```

for a map that sent two tenants to one token and tried to claim it inverts.

| Shape | What it is | In the file |
| --- | --- | --- |
| `TenantId z` | The tenant's ID, indexed by zone: billing in account services, books in the AI zone, storage in storage | Rock 1; `storage` added to `Zone` today |
| `IdMap a b` | Forward and backward lookups between two zones' IDs, with `inverts` as a field | `IdMap .privateZone .aiZone` |
| `scrub` | Private-zone event in, AI-zone event or a refusal out; tenant through the map, payload through the tokenizer, envelope kept | `scrub`, `ScrubRefusal.unknownTenant` |
| `reidentify` | The inverse, same owner | `reidentify` |

Two theorems, both universal. `scrub_keepsEnvelope`: the scrubbed event has the original's id, causation and correlation, so the per-journey pass of rock 1 sees one run on both sides of the boundary. `scrub_roundTrip`: for every map, every tokenizer with an inverse and every event, what the scrub lets through, re-identification returns exactly. The second is the alias map design's invariant, stated once.

### The three open questions, with a recommendation on each

**1. Which IDs get the index?** Those the ID map maps, and only those: the tenant's billing, books and storage IDs. The rock proposed every ID that identifies a tenant's thing, and the ID map says why that is too many: the account ID, with its label as its name, is held by loading files and connected accounts on the private zone and by the books in the AI zone, as one opaque ID that is safe to cross. Indexing it would make one ID two types and force a map where the design has none. The rule is therefore: an ID is indexed by zone exactly when crossing a zone with it is a re-identification risk, which is exactly when the ID map maps it. **[H]**, from the ID map.

**2. Is a device a zone?** No. A device is an endpoint of the private zone: what reaches it is re-identified data sealed for that device, by the paths table, so what it holds is the private zone's view with the private zone's IDs. Making it a zone would add an index value with no ID of its own to map. The device ID is an own ID of the private zone's cell, which is where the ID map already puts it. **[H]**

**3. Does the index leak into the wire schemas, and how?** It should, in the schema's name and not in a field. The Avro namespace, or the record name, carries the zone, and the schema registry and the topics are per zone, so a consumer in the AI zone cannot deserialize a private-zone record even by accident, and a producer cannot publish one to the wrong zone's topic without a registry refusal. The tenant attribute on the CloudEvents envelope names its zone, as rock 1 proposed. This is the wire counterpart of the type index: the type stops the wrong ID at compile time inside the model, and the registry stops it at publish time outside it. **[M]** for the registry's behavior; the shape is the project's to decide.

## What this changes in the architecture documents

Not edited; for the owner to confirm, each with a changelog row when done.

- `methodology.md`, method 5: the duplication test gains "a query's answer is stamped with the owner's version, and the owner refuses a command made on a stale answer"; and a candidate seventh method, a decider reads inputs and never calls, with the clock a cell.
- the books' data model: the lock version is the `asOf` stamp on every answer the books' gateway returns, and the version check on a move between allocations is named.
- `product-technology-architecture.md`, queries and commands: the "who enforces" column for budgets' move gains the version check; the anatomy of a cell shows the shell gathering inputs before the decider.
- [round-trip.md](../docs/the-lifecycle.md), the annotation grammar: the Decide table gains a "reads" column naming the queries, with the no-reads theorem required where it is empty; the Examples table gains a "with" column.
- `data-classification-and-placement.md`, the ID map: the three tenant IDs are one type indexed by zone; the rule for which IDs are indexed is stated as "those this map maps"; the account ID is named as the opaque ID that crosses.
- `alias-map-and-scrubbing.md`, when picked up: its invariant is `IdMap.inverts`, and the scrub and re-identification are the two functions with two zones in their type.
- `crossing-the-zones.md`, when picked up: the registry and the topics per zone, the zone in the schema's namespace.
- `GLOSSARY.md`, the method: rows for inputs, answer and its version, tick.

## What this leaves open

- The `Q` record is per cell and filled whole; `needs` tells the shell what to fetch. Whether an unfilled field should be an `Option` the decider must match on, so that reading an undeclared answer is a type error rather than a theorem, is worth trying on the second cell that reads inputs.
- The budgets example emits a request and the books' version check on it is stated here and not yet modeled, because adding a command to the books slice ripples through its parse, serialize, kinds and coverage; the next books change should carry it.
- The alias map here is a function pair; the real one is a table in the private zone's cell with retention and rotation, and `inverts` must survive both. Rock 7 governs that.

## Sources

- Gary Bernhardt, *Functional Core, Imperative Shell*, 2012 · Leslie Lamport, *Time, Clocks, and the Ordering of Events*, 1978
- Pat Helland, *Data on the Outside versus Data on the Inside*, 2005, for why an answer carries its version
- Apache Avro specification, namespaces and schema resolution; Confluent Schema Registry, subject naming per topic **[M]**
- The trial's own documents, not published: the ID map, the paths, method 5, [envelopes.md](envelopes.md), [big-rocks.md](big-rocks.md) rocks 2 and 4
- `Calculus.lean`, the sections "Rock 2" and "Rock 4"
