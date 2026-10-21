# Compositional specification and verification of non-functional properties across components

Researcher notes, 2026-10-14. Scope: how an end-to-end non-functional property of a journey (latency, availability, cost, confidentiality) follows from per-cell properties; the published theory; what a per-cell non-functional contract should contain; mechanization, including a Lean 4 experiment compiled against the project's own toolchain (Lean 4.34.1, no Mathlib).

Provenance tags used throughout: **[read in source]** = I read the primary text (PDF extracted to text, or page fetched); **[read in summary]** = abstract, publisher page, search snippet or a secondary page; **[from memory]** = not verified against a source this session. **[verified by compilation]** = I compiled it.

Reader's model for reference (read in source: `cell-calculus/CellCalculus/Journey.lean`): `inductive Journey (State Refusal) | step (name) (run : State → Except Refusal State) | seq first second | par left right merge`, with `run` as Kleisli composition in `Except`, and `compile_wellFormed` proving every term is a DAG.

---

## KQ1. Assume-guarantee contracts (Benveniste et al.): the contract algebra and how non-functional viewpoints are handled

### Takeaway
The A/G contract algebra is fully explicit and small: a contract is a pair of assertions (A, G); refinement is contravariant in A and covariant in G; conjunction (∧) is the greatest lower bound and is *the* operator for fusing viewpoints (function, timing, safety, energy); parallel composition (⊗) has the closed form G = G1∩G2, A = (A1∩A2) ∪ ¬(G1∩G2). Non-functional aspects are not special: a timing or scheduling viewpoint is just another contract conjoined with the functional one, and the monograph's Chapter 9 instantiates the whole algebra for scheduling/latency budgets.

### Cited Findings
- The monograph: A. Benveniste, B. Caillaud, D. Nickovic, R. Passerone, J.-B. Raclet, P. Reinkemeier, A. Sangiovanni-Vincentelli, W. Damm, T. Henzinger, K. Larsen, "Contracts for System Design", Foundations and Trends in EDA vol. 12 no. 2-3, pp. 124-400, 2018 **[read in summary]** — [ACM DL](https://dl.acm.org/doi/10.1561/1000000053); free PDF at [INRIA](https://people.rennes.inria.fr/Albert.Benveniste/pub/ContractsMonograph2018.pdf) and [CPS school mirror](https://www.cpsschool.eu/wp-content/uploads/2018/09/main_contracts.pdf) (the mirror is what I read). The 2012 INRIA research report RR-8147 of the same title is the earlier version **[from memory]**.
- Motivation for viewpoints, p. ~2: complex systems involve "a number of different aspects or viewpoints that are generally handled by different teams using different paradigms and tools"; examples include "its safety and reliability characteristics, its energy budget" **[read in source]** — [monograph PDF](https://www.cpsschool.eu/wp-content/uploads/2018/09/main_contracts.pdf).
- Conjunction is the viewpoint-fusion operator (Section 2.2, "Contract Conjunction and Viewpoint Fusion"): "Full specification of a component can be a conjunction of multiple viewpoints, each covering a specific (functional, timing, safety etc.) aspect of the intended design and specified by an individual contract." Required properties: "C1∧C2 ⪯ C1 and C1∧C2 ⪯ C2, and for all contracts C, if C ⪯ C1 and C ⪯ C2, then C ⪯ C1∧C2." **[read in source]** — [monograph PDF](https://www.cpsschool.eu/wp-content/uploads/2018/09/main_contracts.pdf).
- Worked timing viewpoint in the primer (Section 2.2): a contract Cτ1 with inputs tx, ty (arrival times), output tz, "assumptions: true; guarantees: tz ≤ max(tx, ty) + 1"; "Their conjunction C1∧Cτ1 yields a contract that guarantees, in addition to C1 itself, a latency with bound 1ms". The monograph then shows the pitfall: because Cτ1 has no assumption, "the conjunction inherits the weakest assumption of the timing contract, and cancels the assumption of C1", fixed by giving the timing contract the same assumption ("assumptions: y ≠ 0"). **[read in source]** — [monograph PDF](https://www.cpsschool.eu/wp-content/uploads/2018/09/main_contracts.pdf). (Note: the latency guarantee is literally `max` of input arrival times plus a step bound, i.e. the fan-in rule.)
- Meta-theory, Section 4: Property 3 "(independent implementability). Compatible contracts can be independently implemented." Lemma 4.2: refinement is preserved by composition (if C'i ⪯ Ci for all i and ⊗Ci is well defined, then ⊗C'i is well defined and refines). Theorem 4.6: "Under extra Axiom 4, contract composition is associative." **[read in source]** — [monograph PDF](https://www.cpsschool.eu/wp-content/uploads/2018/09/main_contracts.pdf).
- Sub-distributivity of ⊗ over ∧ (Property 6, eq. 4.9) and Comment 4.5: "[(C11∧C21)⊗(C12∧C22)] ⪯ (C11⊗C12) ∧ (C21⊗C22)" — implementing each subsystem against the conjunction of its viewpoints and then composing yields an implementation of the conjunction of the global viewpoints. "This property supports independent implementation for specifications involving multiple viewpoints. Observe that only refinement, not equality, holds." **[read in source]** — [monograph PDF](https://www.cpsschool.eu/wp-content/uploads/2018/09/main_contracts.pdf).
- Quotient, Section 4.5, eq. 4.10: "C1/C2 = max{ C | C ⊗ C2 ⪯ C1 }", existence requires Axiom 3. **[read in source]** — [monograph PDF](https://www.cpsschool.eu/wp-content/uploads/2018/09/main_contracts.pdf).
- A/G instance, Chapter 5 (Definitions 5.3-5.4), with components and assertions as sets of behaviours: "A contract is a pair C = (A, G) of assertions ... legal environments ... E ⊆ A ... implementing C is defined by A × M ⊆ G." Saturation: "C = (A, G) is saturated if G = G ∪ ¬A". For saturated contracts with identical alphabets: (1) "C2 refines C1, written C2 ⪯ C1, iff A2 ⊇ A1 and G2 ⊆ G1"; (2) "C1∧C2 =def (A1∪A2, G1∩G2)"; (3) parallel composition "G = G1∩G2 and A = (A1∩A2) ∪ ¬(G1∩G2)" (eq. 5.7). Theorem 5.2 shows these coincide with the meta-theory's refinement, conjunction and composition; Theorem 5.3: Axiom 4 holds, so ⊗ is associative. **[read in source]** — [monograph PDF](https://www.cpsschool.eu/wp-content/uploads/2018/09/main_contracts.pdf).
- Comment 5.1 on what conjunction means operationally: if an environment satisfies A1 but not A2, "G1 is guaranteed in this case, but G2 is not ... the corresponding contract C2 is relieved from its guarantee, but the other contract C1 'survives'." **[read in source]** — [monograph PDF](https://www.cpsschool.eu/wp-content/uploads/2018/09/main_contracts.pdf).
- Non-functional instantiation, Chapter 9 "Scheduling Contracts" (pp. 169-202): Definition 9.6 "A scheduling contract is a pair C = (A, G) of abstract scheduling components", with the extra predicate "schedulable if A ∩ G ≠ ∅"; Lemma 9.12 gives sufficient conditions for refinement against a conjunction of concrete scheduling contracts (A_j × G ⊑ G_j and A_j ⊑ A). The chapter's motivation: "We study the key step by which time budgets are then ... called scheduling contracts" and abstract scheduling components talk about "duration between trigger and completion, end-to-end duration when traversing" chains. **[read in source]** — [monograph PDF](https://www.cpsschool.eu/wp-content/uploads/2018/09/main_contracts.pdf).
- Chapter 11 is "Contracts for timing in Autosar" (TADL-style timing constraints on data paths; Figure 9.5 "Typical real-time task parameters + timing constraints on data paths"). **[read in source, headings only]** — [monograph PDF](https://www.cpsschool.eu/wp-content/uploads/2018/09/main_contracts.pdf).
- The monograph's own stated gap (Conclusion): "the handling of multiple viewpoints is ... we lack practical handling of heterogeneity" and "currently there is no established notion of viewpoints" in industrial tools. **[read in source]** — [monograph PDF](https://www.cpsschool.eu/wp-content/uploads/2018/09/main_contracts.pdf).
- Tooling: Pacti (Incer et al., 2023) "efficiently computes algebraic operations on contracts" and is "illustrated ... in a variety of case studies" **[read in summary]** — [arXiv 2303.17751](https://arxiv.org/abs/2303.17751). From memory it works over polyhedral (linear-inequality) constraints on real variables and implements composition, quotient and merging, which is exactly the shape of a latency/cost budget contract **[from memory]**.
- Hypercontracts (Incer, Benveniste, Sangiovanni-Vincentelli, Seshia; NFM 2022, FMSD 66(3) 2025): "a general model with a richer structure for its underlying model of components, subsuming simulation preorders ... a richer algebra for its notions of refinement, parallel composition, and quotient"; "conic hypercontracts ... come with a finite description" and are illustrated on "security and the robustness of machine-learning components". **[read in source: abstract]** — [NFM 2022 PDF](https://people.eecs.berkeley.edu/~sseshia/pubdir/nfm22.pdf), [EECS tech report](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2021/EECS-2021-158.html). A secondary summary adds that hypercontracts can express "mean response times, security attributes, and robustness that lie outside the expressivity of trace properties" **[read in summary]** — [search summary citing FMSD 2025](https://www.researchgate.net/publication/392559735_Hypercontracts).

### Inferences
- For the reader's model, a per-cell non-functional contract is naturally an A/G pair *per viewpoint*, conjoined: C_cell = C_fun ∧ C_latency ∧ C_avail ∧ C_cost ∧ C_conf. The monograph's primer example shows the assumption must be repeated on each viewpoint (otherwise conjunction weakens it), so every viewpoint contract should carry the cell's input-validity assumption (in the reader's terms: the decider's acceptance predicate).
- Sequence and fan-out in the journey algebra are *parallel composition with wiring* in contract terms (the output trace of one cell is the input trace of the next). The composed guarantee G1∩G2 is then a conjunction of per-cell timing guarantees over shared timestamp variables, and the end-to-end bound (sum / max) is a *consequence derived inside the conjunction*, not a separate rule — exactly the "tz ≤ max(tx,ty) + 1" pattern.
- Refinement direction gives the governance rule: a cell may always tighten its guarantee (smaller latency bound, higher availability) or weaken its assumption without breaking any journey (Lemma 4.2).
- Confidentiality is a hyperproperty, not a trace property, so plain A/G contracts over trace sets cannot state it; hypercontracts are the published extension.

### Gaps
- I could not retrieve full text of the Pacti paper or the Hypercontracts body, so the exact composition rule for hypercontracts (and its information-flow example) is not quoted here.
- The monograph does not give a general "sum along sequence / max across fan-out" theorem; it gives the machinery from which it follows and worked timing examples.

---

## KQ2. Interface theories: interface automata, timed interfaces, resource interfaces, modal interfaces

### Takeaway
Interface theories give the *compatibility* and *refinement* side of composition (optimistic composition, alternating refinement) and, in their timed and resource variants, treat time and resources as games against the environment; they do not themselves supply arithmetic latency-composition rules, but the monograph shows interface automata and modal interfaces are instances of the same contract meta-theory, so the A/G rules carry over.

### Cited Findings
- Interface automata (de Alfaro and Henzinger, FSE 2001, pp. 109-120): "an automata-based language to capture both input assumptions about the order in which the methods of a component are called, and output guarantees about the order in which the component calls external methods"; "an optimistic approach to composition, according to which two components are compatible if there is some environment that can make them work together"; "one interface refines another if it has weaker input assumptions and stronger output guarantees" (alternating refinement). **[read in summary]** — [IST publication page](https://pub.ist.ac.at/~tah/Publications/interface_automata.html); [PDF](http://web.cs.wpi.edu/~heineman/html/teaching_/CS562/p109-de_alfaro.pdf).
- Timed interfaces (de Alfaro, Henzinger, Stoelinga, EMSOFT 2002, pp. 108-122): "specifying both the timing of the inputs a component expects from the environment, and the timing of the outputs it can produce. Two timed interfaces are compatible if there is a way to use them together such that their timing expectations are met ... a timed interface is encoded as a timed game between two players". **[read in summary]** — [ISTA record](https://research-explorer.ista.ac.at/record/4631); [Springer](https://link.springer.com/chapter/10.1007/3-540-45828-X_9).
- Resource interfaces (Chakrabarti, de Alfaro, Henzinger, Stoelinga, EMSOFT 2003, LNCS 2855): "models interfaces with resource requirements as games with quantitative objectives" **[read in summary]** — [Springer](https://link.springer.com/chapter/10.1007/978-3-540-45212-6_9). From memory, the paper distinguishes a *peak* resource model (every step's consumption must stay under a bound, e.g. memory/power) from an *accumulated/energy* model (total consumption along a run must stay within a budget), and compatibility means there exists a scheduling strategy under which the composed resource use never exceeds the bound **[from memory; Springer page was behind a login redirect]**.
- Modal interfaces (Raclet, Badouel, Benveniste, Caillaud, Legay, Passerone; Fundamenta Informaticae 2011) are developed in the monograph's Chapter 8 with Theorems 8.10-8.18 (compatible quotient, Axiom 4 for ⊗, etc.), and Theorem 8.21 maps A/G refinement into Modal-Interface refinement: "(A1,G1) ⪯AG (A2,G2) implies C1 ⪯MI C2". **[read in source: theorem headers]** — [monograph PDF](https://www.cpsschool.eu/wp-content/uploads/2018/09/main_contracts.pdf). Secondary: [Modal interfaces composition operator](https://www.academia.edu/19279944/Modal_interfaces) **[read in summary]**.
- "From Interface Automata to Hypercontracts" (Incer et al., 2022) shows interface automata are an instance of hypercontracts. **[read in summary]** — [Springer](https://link.springer.com/chapter/10.1007/978-3-031-22337-2_23).
- Interface theories with component reuse (Doyen, Henzinger, Jobstmann, Petrov, EMSOFT 2008) address "shared" components used by several parents, relevant when one cell serves several journeys. **[read in summary]** — [ACM](https://dl.acm.org/doi/10.1145/1450058.1450070).

### Inferences
- For the reader: interface theories matter for the *decider* (input assumptions = which events a cell accepts in which order) more than for the arithmetic of latency; the arithmetic lives in KQ3. A resource-interface style contract ("peak" vs "accumulated") is the right template for *cost*: cost per handled event (peak) and cost budget per journey or per period (accumulated).
- Timed interfaces give the semantics for "a cell must receive its input by t and will produce its output by t+d" as a game; the journey algebra, having no loops, makes the game trivially winnable if each step's bound is honoured.

### Gaps
- No primary-text read of Resource interfaces or Timed interfaces (publisher pages blocked); no explicit per-paper latency-composition theorem found in the interface-theory literature.

---

## KQ3. Compositional performance reasoning: latency along sequences and fan-outs, availability, DAG critical path, network calculus

### Takeaway
Deterministic bounds compose by sum along a sequence and max across a fan-out (critical path of the DAG); distributions compose by convolution along a sequence and by product-of-CDFs (max) across a fan-out, which is the "tail at scale" amplification; availability composes by product in series and 1 - product of unavailabilities in redundant parallel, but an all-must-succeed fan-out is series, not parallel. Network calculus is the rigorous deterministic theory, with the concatenation theorem (service curves compose by min-plus convolution) and "pay bursts only once" showing that the global bound is tighter than the sum of per-hop bounds.

### Cited Findings
**Network calculus (Le Boudec and Thiran, free book, 2001, revised 2022)** — [netCalBook.pdf](https://leboudec.github.io/netcal/latex/netCalBook.pdf), all **[read in source]**:
- Definition 1.2.1 (arrival curve α), Definition 1.3.1 (service curve β): a system offers β if output R* ≥ R ⊗ β, with (f ⊗ g)(t) = inf_{0≤s≤t}{f(s) + g(t−s)}.
- Theorem 1.4.1 (Backlog Bound): "R(t) − R*(t) ≤ sup_{s≥0}{α(s) − β(s)}".
- Theorem 1.4.2 (Delay Bound): "The virtual delay d(t) for all t satisfies: d(t) ≤ h(α, β)" where h is the horizontal deviation, h(α,β) = sup_s inf{τ ≥ 0 : α(s) ≤ β(s+τ)}.
- Theorem 1.4.3 (Output Flow): the output is constrained by α* = α ⊘ β (min-plus deconvolution).
- Theorem 1.4.6 (Concatenation of Nodes): "Assume a flow traverses systems S1 and S2 in sequence. Assume that Si offers a service curve of βi ... Then the concatenation of the two systems offers a service curve of β1 ⊗ β2 to the flow." Proof is three lines: R1 ≥ R ⊗ β1, R* ≥ R1 ⊗ β2 ≥ (R ⊗ β1) ⊗ β2 = R ⊗ (β1 ⊗ β2).
- Rate-latency example: "βR1,T1 ⊗ βR2,T2 = βmin(R1,R2), T1+T2. Thus concatenating Intserv nodes amounts to adding the latency components and taking the minimum of the rates." Also βR,T = δT ⊗ λR (a pure delay T followed by a constant-rate R server).
- "Pay Bursts Only Once": for a token-bucket input γr,b through two rate-latency nodes, the end-to-end bound from the network service curve is D0 = b/R + T0 (R = min Ri, T0 = ΣTi), whereas summing per-node bounds gives D1 + D2 = b/R1 + (b + rT1)/R2 + T0, and "It is easy to see that D0 < D1 + D2. In other words, the bounds obtained by considering the global service curve are better than the bounds obtained by considering every buffer in isolation." "A corollary of Theorem 1.4.6 is also that the end-to-end delay bound does not depend on the order in which nodes are concatenated."
- Stochastic network calculus (survey, Fidler and Rizk, "A Guide to the Stochastic Network Calculus") gives probabilistic bounds; end-to-end bounds via network service envelope "scale linearly in the number of nodes H connected in series" under independence, and the bounds "are usually very loose compared to the simulation ... due to the intensive use of Boole's inequality" **[read in summary]** — [ResearchGate](https://www.researchgate.net/publication/273706692_A_Guide_to_the_Stochastic_Network_Calculus).

**Fan-out / fan-in (max) and tail amplification** — Dean and Barroso, "The Tail at Scale", CACM 2013 **[read in source]** — [PDF](https://www.barroso.org/publications/TheTailAtScale.pdf):
- "consider a system where each server typically responds in 10ms but with a 99th-percentile latency of one second. If a user request is handled on just one such server, one user request in 100 will be slow (one second) ... If a user request must collect responses from 100 such servers in parallel, then 63% of user requests will take more than one second ... Even for services with only one in 10,000 requests experiencing more than one-second latencies at the single-server level, a service with 2,000 such servers will see almost one in five user requests taking more than one second."
- Real Google measurement: "The 99th-percentile latency for a single random request to finish, measured at the root, is 10ms. However, the 99th-percentile latency for all requests to finish is 140ms, and the 99th-percentile latency for 95% of the requests finishing is 70ms, meaning that waiting for the slowest 5% of the requests to complete is responsible for half of the total 99%-percentile latency."
- Mitigations: hedged requests (send the same request to a second replica after the 95th-percentile delay, take the first answer) and tied requests (enqueue at two servers, each told the other's identity, cancel on start); the paper reports hedging at the 95th percentile adds only ~5% load **[read in source, numbers from memory of the paper]**.
- The underlying arithmetic (standard probability, consistent with the paper's 63%): for n independent branches each slow with probability p, P(fan-in slow) = 1 − (1−p)^n; 1 − 0.99^100 ≈ 0.634 **[from memory / elementary]**.
- Fork-join queueing theory: in a fork-join system "the response time of one job is determined, at a downstream join station, by the maximum of the corresponding tasks' response times"; Rizk, Poloczek, Ciucu give "the first computable stochastic bounds on the waiting and response time distributions in fork-join systems" and prove "delays scale as O(log N)" in N parallel servers **[read in summary]** — [Queueing Systems 2016](https://link.springer.com/article/10.1007/s11134-016-9486-x); Fidler, Walker, Jiang derive "end-to-end delay bounds for multi-stage fork-join networks that grow in O(h ln k)" for h stages of k servers, non-asymptotic, using a max-plus server model, validated on Spark **[read in summary]** — [arXiv 1610.06309](https://arxiv.org/abs/1610.06309).

**DAG critical path / real-time DAG tasks**:
- Graham's 1969 bound for a DAG task on m cores: response time ≤ length of the longest path + (total workload − longest path)/m; He et al. (2022) improve it using several long paths and show it "theoretically dominates and empirically outperforms Graham's bound" **[read in summary; formula from memory]** — [arXiv 2211.08800](https://arxiv.org/abs/2211.08800).
- With unbounded parallelism (every branch of a `par` runs at once, which the reader's `par` semantics assumes), Graham's bound collapses to the longest path, i.e. critical path = max over paths of the sum of node bounds, which is PERT's deterministic critical-path method **[from memory]**.

**Availability** (standard reliability-block-diagram theory) **[read in summary]**:
- Series: "the availability of the system equals the product of all component availabilities (e.g., Availability = A × B × C) ... two components with 99% availability connected in series yield 98.01%". Parallel (redundant): "Availability = 1 − (1 − A) × (1 − B) × (1 − C) ... two components in parallel yield 99.99%". Hybrids reduce to series/parallel; k-out-of-n is the general case. — [BMC](https://www.bmc.com/blogs/system-reliability-availability-calculations/), [EventHelix](https://www.eventhelix.com/fault-handling/system-reliability-availability/), [Cortland START sheet](https://web.cortland.edu/matresearch/SerieslParallelSTART.pdf).
- Google's "The Calculus of Service Availability" (Treynor Sloss, Dahlin, Rau, Beyer, ACM Queue 15(2), 2017; CACM reprint): tagline "You're only as available as the sum of your dependencies"; "rule of the extra 9": a critical dependency must offer one more 9 than the service (99.999% for a 99.99% target); equivalently it must be ~10x as reliable so its contribution to the error budget is negligible **[read in summary; Queue/ACM pages returned 403]** — [research.google](https://research.google/pubs/the-calculus-of-service-availability/), [CACM](https://cacm.acm.org/practice/the-calculus-of-service-availability/).
- Google SRE Workbook, "Implementing SLOs": "If a single component is a critical dependency for a particularly high-value interaction, its reliability guarantee should be at least as high as the reliability guarantee of the dependent action." It warns that the parallel formula assumes independence: "deploying the service in two zones should solve that requirement ... However, this reasoning assumes that both services are wholly independent, which is almost never the case" (shared fate, common control planes). If a dependency cannot meet the need, "you need to engineer around that condition" (caching, graceful degradation). **[read in summary via fetch]** — [SRE Workbook](https://sre.google/workbook/implementing-slos/).

### Inferences
- Deterministic worst-case latency over the reader's algebra: bound(step c) = d_c; bound(seq a b) = bound a + bound b; bound(par a b) = max(bound a, bound b). This is network calculus with pure-delay service curves δ_T (δ_T1 ⊗ δ_T2 = δ_T1+T2) plus the fan-in rule. The "pay bursts only once" result says: if cells have *rate* as well as delay (queues), the per-cell bound sum over-approximates; a journey-level service curve is tighter. So a per-cell latency contract should expose (latency T, rate R) as a rate-latency curve, not a single number, if queueing is in scope.
- Probabilistic latency: along seq, the distribution is the convolution of independent step distributions; across par, the CDF of the fan-in is the product of branch CDFs. Percentiles therefore do *not* compose by sum: p99(seq) ≤ p99(a) + p99(b) only as a crude bound (via a union bound: P(a > x or b > y) ≤ 0.02), and p99 of a fan-in over n branches needs each branch at roughly p(1 − 0.01/n). A per-cell contract that promises a percentile must say at which percentile, and the journey-level claim must be derived with the union bound or with the full distribution.
- Availability: seq is series (product); the reader's `par` is *all-must-succeed* (both branches feed `merge`), so it is also series for availability, not redundant parallel. Only an explicit "either branch suffices" construct (which the algebra lacks) earns 1 − Π(1 − A_i). Error budgets (1 − A) add along both constructors to first order, which is why Google reasons in budgets: budget(journey) ≈ Σ budget(cell), and the "extra 9" rule is the discipline that keeps per-cell budgets small relative to the journey's.
- Cost (accumulated resource) composes by sum along both constructors; peak resource (concurrency, memory) composes by max along seq and sum across par, the dual of latency.

### Gaps
- Could not fetch the primary text of "The Calculus of Service Availability" (403 at ACM Queue and Semantic Scholar); the "extra 9" quote is from a search summary.
- No single published source states the seq/par latency rule as a theorem over a term algebra; it is folklore in network calculus (concatenation + δ_T) and in scheduling (critical path). This is why the Lean experiment in KQ6 matters.

---

## KQ4. Compositional verification of microservices and event-driven systems: sagas/choreographies, chaos engineering, SLO composition along the call graph

### Takeaway
The microservice literature treats composition empirically: SLOs are propagated or "diffused" across a dependency graph (product/sum heuristics, or learned Bayesian networks), chaos engineering frames the journey-level availability claim as a falsifiable hypothesis about a steady-state metric, and formal work on choreographies proves safety/deadlock-freedom and saga atomicity rather than timing or availability bounds.

### Cited Findings
- SLO diffusion: Sedlak, Casamayor Pujol, Donta, Dustdar, "Diffusing High-level SLO in Microservice Pipelines" (IEEE SOSE 2024): "a methodology that diffuses high-level SLOs into multiple lower levels of SLOs and parameter assignments"; it learns a Bayesian network over service metrics and, "traversing G from nodes that represent high-level SLOs ... gradually visit their ancestors ... each node is extended with a threshold it must ensure; if it is a root node, it is called a 'parameter', otherwise a 'low-level SLO'", inferred by variable elimination; "we can fulfill high-level SLOs up to 100%", and "the restrictiveness of low-level SLOs and the occurrence of conflicts have a severe impact on SLO fulfillment." **[read in source]** — [PDF](https://dsg.tuwien.ac.at/~sd/papers/SOSE_2024_B_Sedlak.pdf).
- SLO-aware scheduling with time-varying call graphs (Morphis, 2026): "call graph topologies are not fixed and continuously evolve in response to request semantics, conditional business logic, and fluctuating workloads" **[read in summary]** — [arXiv 2602.01044](https://arxiv.org/html/2602.01044). Practitioner rule: a service depending on 5 others at 99.9% each has a ceiling of about 99.5%; "no service should promise an SLO tighter than the weakest service it depends on" **[read in summary; secondary]** — [DEV Community](https://dev.to/samson_tanimawo/service-level-objectives-for-complex-microservices-3j14).
- Chaos engineering, principlesofchaos.org (Netflix-originated): "Chaos Engineering is the discipline of experimenting on a system in order to build confidence in the system's capability to withstand turbulent conditions in production." Principles: "Build a Hypothesis around Steady State Behavior: Focus on the measurable output of a system, rather than internal attributes"; "Vary Real-world Events"; "Run Experiments in Production"; "Automate Experiments to Run Continuously"; "Minimize Blast Radius". **[read in source]** — [principlesofchaos.org](https://principlesofchaos.org/).
- Basiri, Behnam, de Rooij, Hochstein, Kosewski, Reynolds, Rosenthal (Netflix), "Chaos Engineering", IEEE Software 33(3), 2016: "Many large tech organizations are using experimentation to verify the reliability of such systems." **[read in source: abstract]** — [arXiv 1702.05843](https://arxiv.org/abs/1702.05843). Secondary: Netflix's steady-state metric is streams-per-second (SPS); "At Netflix, the quality attribute they focus on most is availability"; Chaos Monkey "randomly selects virtual-machine instances that host production services and terminates them" **[read in summary]** — [InfoQ](https://www.infoq.com/articles/chaos-engineering/).
- Formal verification of microservices, systematic review (2025-26): five clusters, "Actor-based model checking, TLA+ control-plane verification, static code analysis, continuous certification, and runtime/self-adaptive testing"; timed Rebeca/Afra "support complex communication and timing behaviors"; ZENITH is "an 8.6k-line TLA+ specification". **[read in summary]** — [MDPI Software 5(3):32](https://www.mdpi.com/2674-113X/5/3/32).
- Choreographic sagas: "Choreographic sagas are proven deadlock-free, terminate under bounded restarts, and upon termination participants either all succeed or invoke compensating transactions" (Accompanist, 2026) **[read in summary]** — [arXiv 2603.20942](https://arxiv.org/abs/2603.20942); "Verified Parameterized Choreographies" (COORDINATION 2025) **[read in summary]** — [arXiv 2502.15382](https://arxiv.org/pdf/2502.15382).
- Design-time to run-time verification of microservice orchestrations (Camilli et al., 2018): runtime monitoring against the same model used at design time **[read in summary]** — [Springer](https://link.springer.com/chapter/10.1007/978-3-319-74781-1_12).

### Inferences
- The industrial "SLO composition" practice is the A/G algebra done informally: the journey's SLO is the guarantee; the dependency SLOs are assumptions; the "extra 9" rule is a refinement discipline that keeps the composed guarantee provable with a crude union bound. The reader's cell contracts can make this exact.
- Chaos engineering is the empirical side of the availability contract: the steady-state hypothesis is "journey-level availability ≥ A under cell failures the contract assumes", and a chaos experiment is a test of the *assumption* side (what failure events the environment may inject), not of the arithmetic.
- The gap between formal choreography work (safety, deadlock-freedom, atomicity) and the SRE literature (availability, latency) is the space the reader's model can occupy: the DAG compilation theorem already gives the safety side; a latency/availability fold over the same term is the missing half.

### Gaps
- I found no paper that proves a *timing* or *availability* bound for a saga or choreography compositionally; the choreography results are safety results. "Dependency SLOs" exists as practice (Google) but I found no formal treatment beyond the diffusion heuristics above.

---

## KQ5. Session types and choreographies as a formal basis, with timing and cost extensions

### Takeaway
Multiparty session types give global protocol types that project to local types with type safety and deadlock-freedom; timed MPST (Bocchi, Yang, Yoshida, CONCUR 2014) add clocks, constraints and resets to global types and prove time-error freedom and (under feasibility and wait-freedom) time-progress, but they verify *conformance to prescribed timing*, not derived end-to-end bounds; choreographic programming (Montesi) is the executable counterpart, now mechanized in Coq and, as of 2025-26, in Lean 4.

### Cited Findings
- Honda, Yoshida, Carbone, "Multiparty Asynchronous Session Types", POPL 2008; journal version JACM 63(1), 2016: global types describe the whole protocol, are projected to per-participant local types, and well-typed processes enjoy communication safety and progress/deadlock-freedom within a session **[from memory; ACM page returned 403]** — [ACM DL](https://dl.acm.org/doi/10.1145/2827695).
- Timed MPST (Bocchi, Yang, Yoshida; Imperial DTR 2014/3, CONCUR 2014): "a typing theory, based on multiparty session types, for modular verification of real-time choreographic interactions ... a simple calculus with delays and a decidable static proof system. The proof system with time constraints ensures type safety and time-error freedom, namely processes respect the prescribed timing and causalities between interactions. A decidable condition, enforceable on timed global types, guarantees global time-progress". Timed global types carry "clocks, clock constraints, and resets" from communicating timed automata. Theorem 3.3: soundness and completeness of projection to timed local types; Theorem 4.4 (Time-error freedom); feasibility ("every partial execution can be extended to a terminated session") and wait-freedom ("if all senders respect their time constraints, then no receiver has to wait for a message") are decidable (Proposition 5.1) and give time-progress (Theorem 5.4); Theorems 5.6-5.7 characterise a new class of CTAs with progress and liveness. Running example: an Ocean Observatories Initiative sensor protocol with deadlines. **[read in source]** — [DTR14-3 PDF](https://www.doc.ic.ac.uk/research/technicalreports/2014/DTR14-3.pdf).
- Later timed session work: "Timeout Asynchronous Session Types: Safe Asynchronous Mixed-Choice For Timed Interactions" (2024) **[read in summary]** — [arXiv 2401.11197](https://arxiv.org/pdf/2401.11197).
- Compositional MPST: Gheri and Yoshida, "Hybrid Multiparty Session Types: Compositionality for Protocol Specification through Endpoint Projection" (OOPSLA 2023): "the first MPST theory of multiparty compositionality for distributed protocol specification" composing sub-protocols while preserving deadlock freedom **[read in summary]** — [arXiv 2302.01979](https://arxiv.org/abs/2302.01979), [ACM](https://dl.acm.org/doi/abs/10.1145/3586031).
- Choreographic programming (Montesi): "Choreographic Programming is a programming paradigm where programs are choreographies"; endpoint projection compiles them; "Theories of EPP are also usually accompanied by proofs that the compiled code is deadlock-free" ("deadlock-freedom by design"); the book "Introduction to Choreographies" (Cambridge UP, 2023) has its theorems formalized in Coq. **[read in summary]** — [Montesi's bliki](https://www.fabriziomontesi.com/bliki/ChoreographicProgramming).
- Coq mechanizations: Cruz-Filipe, Montesi, Peressotti, "Formalising a Turing-Complete Choreographic Language in Coq" (ITP 2021) and "A Formal Theory of Choreographic Programming" (JAR 2023); Hirsch and Garg, "Pirouette: Higher-Order Typed Functional Choreographies" (POPL 2022) with the whole development in Coq **[read in summary]** — [ITP 2021](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ITP.2021.15), [JAR 2023](https://link.springer.com/article/10.1007/s10817-023-09665-3), [Pirouette](https://people.mpi-sws.org/~dg/papers/popl22-choreographies.pdf).
- Lean 4 mechanizations (new in 2025-26): Qin, Peressotti, Montesi, "Mech: Mechanised Choreographic Programming" — in Lean 4, "the most extensive mechanised theory of CP to date", proving completeness and soundness of EPP, communication safety and deadlock-freedom, covering "general branching in knowledge of choice, general recursion, and nondeterministic choice" **[read in summary]** — [arXiv 2607.15174](https://arxiv.org/abs/2607.15174). Böhler, Daniel, Richter, Weisenburger, Mezini, "Mechanizing Choreographic Programs and Hoare Logic with State Transformers" — mechanized in Lean, proving EPP soundness/completeness, deadlock freedom, confluence, and a verified Hoare logic for choreographies with "point-to-point communication, broadcasting, recursive procedures, and local stateful methods" **[read in summary]** — [arXiv 2608.16346](https://arxiv.org/abs/2608.16346).
- Choreographic programming of isolated transactions (2023) connects choreographies to transactional semantics **[read in summary]** — [arXiv 2304.06399](https://arxiv.org/pdf/2304.06399).

### Inferences
- The reader's journey term is a (loop-free) choreography in which the functional projection (each cell's handle) is already the local program. Timed MPST shows the published way to attach timing: annotate each interaction with a clock constraint and prove the term feasible and wait-free; the end-to-end bound is then an *input* (a deadline on the last interaction) checked for feasibility, not an output. Deriving the bound from per-cell bounds is the dual problem, which is what KQ6's Lean fold does.
- Cost has no session-type extension that I found; it would be an accumulated-resource annotation as in resource interfaces.

### Gaps
- No timed/cost extension of *choreographic programming* (as opposed to session types) found. Could not read the JACM MPST text this session (403).

---

## KQ6. Mechanization: Lean 4 / Coq / Isabelle formalizations, and what Lean 4 core needs to prove seq = sum, par = max over the journey algebra

### Takeaway
Assume/guarantee contracts have a Coq mechanization (Kastenbaum, Boyer, Talpin, ICTAC 2021) that proves the exact algebra of KQ1; network calculus has Isabelle/HOL (Mabille et al., ITP 2013) and Coq (Rakotomalala, Roux, Boyer, NFM 2021) result-certification work; series/parallel availability has an HOL4 formalization; choreographies have Coq and (2025-26) Lean 4 mechanizations. I found no Lean 4 formalization of A/G contracts, interface automata, network calculus or DAG critical-path bounds. The seq-sum/par-max theorem over step/seq/par needs nothing beyond Lean 4 core: structural induction plus `omega` (which handles `Nat.max`) discharges it; I compiled such a proof against the project's toolchain.

### Cited Findings
- Kastenbaum, Boyer, Talpin, "A Mechanically Verified Theory of Contracts" (ICTAC 2021, Coq): "the first mechanized formalization of a theory of assume/guarantee contracts for system design". Components are sets of states; `saturate c = (A, ¬A ∪ G)`; `refines c1 c2 := c2'.A ⊆ c1'.A ∧ c1'.G ⊆ c2'.G` (on saturated forms); `glb c1 c2 = (A1 ∪ A2, G1 ∩ G2)`; `compose c1 c2 = ((A1 ∩ A2) ∪ ¬(G1 ∩ G2), G1 ∩ G2)`. Theorems: `saturate_sound`, `refines_correct` (set definition ⟺ meta-theory's "every implementation of c1 implements c2 and every environment of c2 is an environment of c1"), `glb_correct` (GLB), `compose_correct` and `compose_lowest` (⊗ is the least contract such that implementations compose and each side is an environment for the other), plus extension/elimination of variables for contracts over different alphabets (`extended_compose_correct`). Code: https://github.com/merce-fra/SKT-VerifedContractTheory. Motivating sentence for viewpoints: "we want a component to be fast and correct. There is both a specification for the speed of the component and one for the correctness ... we define the conjunction of contracts as the greatest lower bound of refinement." **[read in source]** — [arXiv 2108.13647](https://arxiv.org/abs/2108.13647), [HAL](https://inria.hal.science/hal-03329311/file/main.pdf).
- Network calculus in Isabelle/HOL: Mabille, Boyer, Fejoz, Merz, "Towards Certifying Network Calculus" (ITP 2013): NC "has been widely used, including for the design and certification of the Airbus A380 AFDX backbone"; approach is result certification: "the NC tool outputs a trace of the calculations it performs, as well as their results. The validity of the trace ... is then established offline by a trusted checker"; formalizes arrival/service curves and the delay bound h(α,β) = sup_{s≥0}(inf{τ ≥ 0 | α(s) ≤ β(s+τ)}). **[read in source]** — [ITP 2013 PDF](https://members.loria.fr/SMerz/papers/itp2013.pdf), [HAL](https://hal.science/hal-00904796).
- Network calculus in Coq: Rakotomalala, Roux, Boyer, "Verifying min-plus Computations with Coq" (NFM 2021, pp. 287-303): "Effective computations rely on operators from the min-plus algebra on real functions. Instead of redeveloping a provably correct implementation, the authors take an existing implementation as an oracle and propose a Coq based verifier"; related Coq library Minerve checks validity of min-plus operations **[read in summary]** — [HAL (blocked by anti-bot this session)](https://hal.science/hal-03176024/document), [NFM 2021 program](https://shemesh.larc.nasa.gov/nfm2021/program.html), [follow-up](https://hal.science/hal-03693417/document).
- Availability in HOL4: Ahmad and Hasan, "Formal Availability Analysis using Theorem Proving" (2016): formalizes "instantaneous and steady-state availability, ABD [availability block diagram] configurations and generic unavailability FT gates", case study the DFH-3 satellite solar array **[read in summary]** — [arXiv 1608.01755](https://arxiv.org/abs/1608.01755).
- Choreographies in Lean 4: Mech (Qin, Peressotti, Montesi) and Böhler et al., cited in KQ5 **[read in summary]** — [arXiv 2607.15174](https://arxiv.org/abs/2607.15174), [arXiv 2608.16346](https://arxiv.org/abs/2608.16346).
- Lean 4 searches for "network calculus", "interface automata", "critical path", "assume-guarantee" returned only unrelated Lean 4 work (computational paths, CRNs, benchmarks) **[read in summary]** — e.g. [arXiv 2511.19142](https://arxiv.org/pdf/2511.19142), [arXiv 2602.01291](https://arxiv.org/html/2602.01291v1). Isabelle has verified shortest-path (not longest-path) algorithms **[read in summary]** — [search results](https://arxiv.org/pdf/1810.11979).
- The Lean 4 experiment **[verified by compilation]**: file `LatencyBound.lean`, kept under `research_notes/`, compiled with `lean LatencyBound.lean` using `~/.elan/bin/lean` (Lean 4.34.1, the version in the project's `lean-toolchain`), no imports, exit code 0, no warnings. Full text, since the exact shape is load-bearing:

```lean
structure StepContract where
  name    : String
  latency : Nat          -- guaranteed upper bound on this cell's handle time

inductive J
  | step (c : StepContract)
  | seq  (first second : J)
  | par  (left right : J)

namespace J

/-- Syntactic bound: sum along seq, max across par. -/
def bound : J → Nat
  | step c    => c.latency
  | seq a b   => a.bound + b.bound
  | par a b   => max a.bound b.bound

/-- Semantic model: an environment assigns an actual duration to each step. -/
def elapsed (actual : StepContract → Nat) : J → Nat
  | step c    => actual c
  | seq a b   => elapsed actual a + elapsed actual b
  | par a b   => max (elapsed actual a) (elapsed actual b)

def mentions : J → StepContract → Prop
  | step c', c  => c' = c
  | seq a b, c  => mentions a c ∨ mentions b c
  | par a b, c  => mentions a c ∨ mentions b c

def StepsHonoured (actual : StepContract → Nat) (j : J) : Prop :=
  ∀ c, j.mentions c → actual c ≤ c.latency

theorem elapsed_le_bound (actual : StepContract → Nat) :
    ∀ j : J, StepsHonoured actual j → j.elapsed actual ≤ j.bound := by
  intro j
  induction j with
  | step c => intro h; exact h c rfl
  | seq a b iha ihb =>
    intro h
    have ha := iha (fun c hc => h c (Or.inl hc))
    have hb := ihb (fun c hc => h c (Or.inr hc))
    simp only [elapsed, bound]; omega
  | par a b iha ihb =>
    intro h
    have ha := iha (fun c hc => h c (Or.inl hc))
    have hb := ihb (fun c hc => h c (Or.inr hc))
    simp only [elapsed, bound]; omega

theorem bound_seq (a b : J) : (seq a b).bound = a.bound + b.bound := rfl
theorem bound_par (a b : J) : (par a b).bound = max a.bound b.bound := rfl

/-- Refinement direction: tightening any step's bound only tightens the journey's. -/
def tighten (f : StepContract → Nat) : J → J
  | step c  => step { c with latency := f c }
  | seq a b => seq (tighten f a) (tighten f b)
  | par a b => par (tighten f a) (tighten f b)

theorem bound_tighten_le (f : StepContract → Nat) (hf : ∀ c, f c ≤ c.latency) :
    ∀ j : J, (tighten f j).bound ≤ j.bound := by
  intro j
  induction j with
  | step c => exact hf c
  | seq a b iha ihb => simp only [tighten, bound]; omega
  | par a b iha ihb => simp only [tighten, bound]; omega

def journey7 : J :=
  seq (step ⟨"arrive", 5⟩)
   (seq (step ⟨"book", 20⟩)
    (seq (step ⟨"threshold", 2⟩)
     (seq (par (step ⟨"analyst", 300⟩) (step ⟨"steward", 40⟩))
          (step ⟨"reach", 10⟩))))

example : journey7.bound = 337 := by decide
end J
```

### Inferences
- What it takes in Lean 4 core: (1) a `Nat`-valued fold over the three constructors (`bound`); (2) a second fold giving a semantic elapsed time under an environment (`elapsed`), which is the "component" of A/G theory; (3) the assumption as a predicate over mentioned steps (`StepsHonoured`), which is the A of the journey's contract; (4) `induction ... with` and `omega`, which knows `+`, `≤` and `Nat.max` (`simp only` unfolds the folds first). No `List`, `Finset` or Mathlib needed. Monotonicity in the refinement direction is the same induction. `decide` evaluates concrete journeys.
- To attach this to the reader's actual `Journey State Refusal`, the leaf `step` needs a contract field (or a side map `String → StepContract` keyed on `name`), and the DAG compiler's node list can carry the bound as the critical path over `needs` (longest path = the same max/sum fold, so the two presentations agree by `compile` correctness).
- Three extensions, each still within core: (a) percentiles via a union bound: carry `(p, d)` and prove P(elapsed > Σd) ≤ Σ(1−p) using Nat-scaled probabilities ("failures per million"), since `omega` handles linear Nat arithmetic; (b) availability: carry an unavailability budget `u` per step and prove budget(seq) = budget(par) = sum (both constructors are all-must-succeed), the series rule; the exact product form needs `Rat`/`Real` (Mathlib) but the first-order budget form does not; (c) cost: sum along both constructors; peak resource: max along seq, sum across par.
- The A/G algebra itself (refinement, conjunction, composition with the ¬(G1∩G2) term) is a different, set-theoretic formalization; Kastenbaum's Coq development is a direct porting target for Lean 4 (`Set`-free: use predicates `State → Prop`), and nothing in it needs classical reals.

### Gaps
- No Lean 4 formalization of A/G contracts, interface automata, network calculus or DAG critical-path bounds was found as of 2026-10; the experiment above is the only Lean 4 artefact in these notes.
- I did not formalize the probabilistic (convolution/product-of-CDFs) rules; those would need Mathlib's measure theory or a discrete-distribution library.

---

## What a per-cell non-functional contract should contain (synthesis across KQ1-KQ6)

Inferred from the findings above, in the monograph's A/G form, one contract per viewpoint, all sharing the cell's input assumption:

- **Assumption (shared by every viewpoint)**: the decider's acceptance predicate on inputs; the input arrival curve or rate (token-bucket (r, b) or "at most n events per window") if queueing is in scope [network calculus, KQ3]; the environment failure events the cell tolerates (the chaos "real-world events" list, KQ4).
- **Latency guarantee**: a deterministic bound d (pure delay δ_d), or a rate-latency curve β_{R,T} if the cell queues; optionally a percentile pair (p, d_p). Composes: seq = sum (δ convolution), par = max; percentiles via union bound [KQ3, KQ6].
- **Availability guarantee**: an unavailability budget u (or A = 1 − u) with the explicit independence/shared-fate assumptions [SRE Workbook]; composes by sum of budgets to first order along both constructors because `par` is all-must-succeed; the "extra 9" rule (u_cell ≤ u_journey/10) is the refinement discipline [KQ3, KQ4].
- **Cost / resource guarantee**: accumulated cost per handled event (sum along both constructors) and peak resource (max along seq, sum across par), after resource interfaces' peak/accumulated split [KQ2].
- **Confidentiality guarantee**: a hyperproperty (noninterference between zones), which needs hypercontracts rather than trace-set A/G; composes by conjunction only when both cells' hypercontracts are stated over the same observers [KQ1].
- **Refinement obligation**: a cell may tighten guarantees or weaken assumptions freely (Lemma 4.2); any other change requires re-deriving every journey's bound. The journey is itself a cell, so its derived contract is a per-cell contract of the same shape, closing the loop with "a journey is a cell".
