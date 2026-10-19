# Foundations: the prior art under the calculus

Every shape in the calculus has a published statement by someone who arrived at it on their own. The method's authority is that the shapes were found more than once; the references are so a reader can check it. Beside each source is how it was checked when this was written: **[H]** read in full, **[M]** read in a summary, **[L]** from memory.

## 1. The two archetypes are the Decider

| The calculus's term | Published form | Source |
| --- | --- | --- |
| `Command => State => Event`, the `decide` field | `decide: 'c -> 's -> 'e list` | Chassaing, *Functional Event Sourcing Decider*, 2021 **[H]** |
| The fold, `evolve` | `evolve: 's -> 'e -> 's`, with `initialState: 's` | Same **[H]** |
| `Event => State => Event`, the `react` field | Not in the Decider record. Chassaing's post gives one example, "the WeatherChanged event leads to a PrepareForRain command," and defers composition to "another story" **[H]**. Event Modeling's "automation" slice is the same reaction, with the command step the calculus forbids **[M]** | |
| `Event => Command`, the sink the calculus removes | Chassaing's example above; Event Modeling's automation pattern; Richardson's "saga as process manager" | Richardson, *Microservices Patterns*, 2018 **[L]** |

The exact record, as published:

```fsharp
type Decider<'c,'e,'s> =
    { decide: 'c -> 's -> 'e list
      evolve: 's -> 'e -> 's
      initialState: 's
      isTerminal: 's -> bool }
```

What the calculus adds that the record lacks: the reaction `Event => State => Event` as a first-class archetype, so that a cell's response to another cell's fact is pure and emits a fact, never a command. That is the restriction that makes the event graph between cells acyclic, which [the-dag-rule.md](the-dag-rule.md) records. What the record adds that the two archetypes alone lack: `evolve`, which makes state the fold of the cell's own events and nothing else, and `isTerminal`, which is the sink of a journey.

The same shape is Akka Persistence's `commandHandler: (State, Command) => Effect[Event, State]` and `eventHandler: (State, Event) => State`, a Decider with the effect wrapped **[L]**. Fraktalio's fmodel library gives the Decider a `combine` operator, a monoid over the sum of commands and events and the product of states, which is the published form of "two cells packaged as one" **[M]**.

## 2. The saga lives inside the owning cell, and the window has a name

The calculus's position on a write that crosses two cells: the saga runs in the decider of the cell that owns the aggregate; only after its call graph completes is the state recorded and the events propagated; queries are always safe; commands carry a blast radius.

| The calculus's term | Published form | Source |
| --- | --- | --- |
| Saga | A long-lived transaction written as a sequence of local transactions, each with a compensating transaction, so that either all complete or compensations run for the partial execution | Garcia-Molina and Salem, *Sagas*, SIGMOD 1987 **[M]** |
| The saga in the decider, not between cells | Richardson's orchestration-based saga with the orchestrator inside one service **[L]** | |
| The failure window: between the first remote state change and the local commit that records it, in which the process dies and the retry is not idempotent | "There is a failure window in which the work is successfully applied to the database, but a failure prevents the messaging system from knowing the message was consumed. The messaging system will redrive the delivery of the message." | Helland, *Idempotence Is Not a Medical Condition*, ACM Queue, 2012 **[M]** |
| The same window, named for the two writes | The dual-write problem: a state change and a publication that cannot be made atomic without a distributed transaction | The transactional outbox pattern, Richardson; Debezium's outbox documentation **[M]** |
| The window does not go away, it moves | "Change data capture relocates the dual write rather than eliminating it. Instead of occurring in the application handler, the dual write now sits in the relay delivery loop." | The outbox literature **[M]**; the same point is in Helland 2012 |
| Two clocks on every event | Logical clocks order events by causality, not by wall clock; wall clock and causal order disagree and the disagreement is where retries land | Lamport, *Time, Clocks, and the Ordering of Events*, 1978; Fidge 1988 and Mattern 1989 for vector clocks **[L]** |
| Entities, messages, at-least-once | A system without distributed transactions is entities that own their data, messages between them delivered at least once, and activities that are idempotent against repeated messages | Helland, *Life beyond Distributed Transactions*, CIDR 2007 **[L]** |
| Events are data on the outside | Data that leaves a cell is immutable, identified and versioned; data inside is mutable and private | Helland, *Data on the Outside versus Data on the Inside*, CIDR 2005 **[L]** |

**The holes in exactly-once, with the published evidence.** Three, in rising strength:

1. **Exactly-once delivery is impossible at the transport.** Two generals. Treat, *You Cannot Have Exactly-Once Delivery*, 2015, and the *Redux*: the achievable thing is at-least-once delivery with idempotent processing, "effectively once" **[M]**.
2. **Kafka's exactly-once is scoped to Kafka.** It covers a read-process-write loop whose reads and writes are both Kafka topics. A consumer that changes a database, calls another cell or sends a notification is outside the transaction, and nothing reverts that effect on abort. Confluent's own delivery-semantics documentation states the scope **[M]**. In the architectures this calculus describes every interesting step is such an effect: a command to another cell's gateway, a notification, a partner call.
3. **Kafka's transaction protocol itself has an unresolved ordering flaw.** Jepsen's Bufstream analysis (Kingsbury, 2024) characterized, in Kafka and not only in Bufstream, "write loss, aborted read, and torn transactions caused by the lack of message ordering constraints in the Kafka transaction protocol." Cause: "There is no sequence number to order requests from the same client. There is no concept of a transaction number." A delayed `EndTxn` can commit or abort a different, later transaction. Tracked as KAFKA-17754; unresolved at publication **[H]**.

So the window is not a gap in any one design; it is the floor every design stands on, named by Helland in 2012, and a fabric's exactly-once claim does not remove it for anything that leaves the fabric.

## 3. Verification-guided development

Amazon's Cedar is the worked example of the lifecycle this method wants. Cedar's evaluator, authorizer and validator are total Lean functions over algebraic datatypes with the security properties proved; the Rust production engine is held to the Lean model by differential random testing, millions of random policies and requests evaluated in both with any difference a bug; property-based testing covers the parts not modelled. The authors name the method verification-guided development **[H]**. SampCert went further: the verified Lean code is the production code **[M]**.

Two other practices meet it. Specification by example (Adzic, 2011) gives examples as the shared specification and the executable test. Trace validation (Cirstea, Kuppe, Loillier and Merz, 2024) gives the backward half: the implementation is instrumented to record what it did, and a checker decides whether the recorded trace is a behaviour of the specification; they report finding discrepancies in every distributed program they tried it on. When the model is executable, as it is here, the checker is a fold and no model checker is needed. Coverage for formal verification (Chockler, Kupferman and Vardi, 2001 and 2003) is the published answer to "do the examples have the model's geometry": repeat the verification on mutants of the model, and a part no property notices when mutated is a part the properties do not cover **[M]**. "Parse, don't validate" (King, 2019) gives the gateway: turn loose input into a typed value once, or refuse with a reason, so that nothing past the boundary has to check again **[H]**.

## 4. What the calculus takes from this

Six rules, each with its source above.

1. **Every gateway is an idempotent receiver.** A command carries an idempotency key minted by the caller before the first remote call and persisted with the caller's intent, so a retry after the caller's death is recognized by the receiver and answered with the first result. Helland 2012; Hohpe and Woolf, *Enterprise Integration Patterns*, "Idempotent Receiver", 2003 **[L]**; Stripe's idempotency keys, Leach 2017 **[L]**.
2. **A command's outcome has three values, not two.** `Either[Ex, B]` is right at the type level, but `Ex` is itself a sum, `Either[Refused, Unknown]`: a deterministic no from the cell's invariants, or a timeout or a death in the window. The cell's own type is the inner `Either[Refused, B]`; the window is added only where a result crosses the wire, and the model never produces it. Refused is final and the journey stops at its named outcome. Unknown is the window made visible: the caller may only retry with the same key, never with a new one, and never decide as if the effect did not happen. Helland 2012.
3. **The saga records its intent before its first remote effect, and its result after its last.** Between the two records the saga is resumable from the intent, which is what durable-execution engines do by persisting the workflow's history before each step and requiring each external effect to be idempotent **[M]**. Garcia-Molina and Salem 1987 for compensation when a later step refuses.
4. **Events are published from the same record as the state, never from memory.** The outbox: the event row and the state change in one local write, relayed after. The relay's own window is accepted and covered by rule 1 at every receiver.
5. **Queries create no obligation and carry no window.** Meyer's command-query separation is the rule for one object: a method either changes state or answers a question, never both. Command Query Responsibility Segregation, CQRS, is Young's lift of it to a system: commands go to the model that decides, queries to a model built for reading, often a projection kept apart from the record it is read from. The calculus takes the segregation and makes both halves types. A query is `State → Answer`, a pure read of the owning cell's record that emits no event and leaves nothing to compensate, so it has no window. What it reads is data on the outside in Helland's sense, so it may be stale, and CQRS's "eventual consistency" becomes a field: every answer is stamped with the owner's version, the decision made on it records that version, and the owner judges the staleness when the resulting command arrives. A cell that keeps its own projection from another's facts is the read model; the architecture's "duplicate by projection, or query" is the choice between the two. Meyer 1988 **[L]**; Young 2010 **[L]**.
6. **Non-determinism lives at the roots.** People, time, partners and any automated judgement are sources of facts. A judgement is an event in a published schema; everything downstream is a pure reaction. This is what lets a language model sit inside a deterministic architecture, and it is Chassaing's point that decisions are materialized as events before state changes.

## Sources

- Jérémie Chassaing, [Functional Event Sourcing Decider](https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider), 2021
- Pat Helland, [Idempotence Is Not a Medical Condition](https://cacm.acm.org/practice/idempotence-is-not-a-medical-condition/), ACM Queue, 2012 · *Life beyond Distributed Transactions: an Apostate's Opinion*, CIDR 2007 · *Data on the Outside versus Data on the Inside*, CIDR 2005
- Hector Garcia-Molina and Kenneth Salem, [Sagas](https://www.cs.cornell.edu/andru/cs711/2002fa/reading/sagas.pdf), SIGMOD 1987
- Kyle Kingsbury, [Jepsen: Bufstream 0.1.0](https://jepsen.io/analyses/bufstream-0.1.0), 2024
- Tyler Treat, [You Cannot Have Exactly-Once Delivery Redux](https://bravenewgeek.com/you-cannot-have-exactly-once-delivery-redux/) · Confluent, [Kafka message delivery guarantees](https://docs.confluent.io/kafka/design/delivery-semantics.html)
- Chris Richardson, [Saga pattern](https://microservices.io/patterns/data/saga.html) and transactional outbox, microservices.io; *Microservices Patterns*, 2018
- Leslie Lamport, *Time, Clocks, and the Ordering of Events in a Distributed System*, 1978 · Colin Fidge, *Timestamps in Message-Passing Systems*, 1988 · Friedemann Mattern, *Virtual Time and Global States of Distributed Systems*, 1989
- Gregor Hohpe and Bobby Woolf, *Enterprise Integration Patterns*, 2003 · Brandur Leach, *Implementing Stripe-like Idempotency Keys in Postgres*, 2017
- Bertrand Meyer, *Object-Oriented Software Construction*, 1988, command-query separation · Greg Young, *CQRS Documents*, 2010, Command Query Responsibility Segregation
- Adam Dymitruk, [Event Modeling](https://eventmodeling.org/) · Fraktalio, [fmodel](https://github.com/fraktalio/fmodel) · Temporal, [durable execution](https://temporal.io/blog/temporal-replaces-state-machines-for-distributed-applications)
- Joseph W. Cutler and others, [Cedar](https://arxiv.org/abs/2403.04651), OOPSLA 2024 · Craig Disselkoen and others, [How We Built Cedar](https://arxiv.org/abs/2407.01688), FSE 2024
- Gojko Adzic, *Specification by Example*, 2011 · Horatiu Cirstea and others, [Validating Traces of Distributed Programs Against TLA+ Specifications](https://arxiv.org/abs/2404.16075), 2024 · Hana Chockler, Orna Kupferman and Moshe Vardi, *Coverage Metrics for Formal Verification*, 2003 · Alexis King, [Parse, Don't Validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/), 2019
