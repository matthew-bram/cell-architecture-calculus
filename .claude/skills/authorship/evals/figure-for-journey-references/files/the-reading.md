# The DAG rule

## The reading that makes it checkable

A first reading of most journey maps finds cycles. Journey 3 of the example, a return, readies a hold, journey 4; a picked-up item can run late, journey 5; a late item is returned, journey 3. Read as one relation, "this journey references that one", the map cycles. The rule says that is a defect of the reading, not a fact to accept, and the sharper reading is what the Lean checks.

**Composition and succession are different relations.**

| Relation | Meaning | In the example | May cycle? |
| --- | --- | --- | --- |
| Composition | A journey runs another journey as one of its steps, in the same run | Picking up a held copy, journey 4's last step, is a checkout as in journey 2; journeys 1, 2, 4 and 7 open with sign-in, journey 0 | Never. A cycle here is a journey that contains itself |
| Succession | A journey's last fact is the trigger of a new run of another journey | A return, journey 3, readies a hold, journey 4; a checkout's loan runs late, journey 5 | Yes. Each edge is a new fact and a new run. The everyday loop is a succession of DAG runs |
| Pointer | The section sends the reader elsewhere | "Renewing instead is journey 6" | No edge |

Under this reading the rule holds: composition is acyclic, `composition_isAcyclic`, and the cycles are all succession, `succession_cycles`. What a journey section must say is which of the three each reference is, which is the References table of [style-guide.md](style-guide.md) section 9; `referencesWithoutKinds_cycle` is the theorem that shows what the map finds when the column is dropped.

**`Either[Ex, B]` is the mechanism that makes a journey a DAG by construction.** In Lean the type is `Except Ex B`, a monad in its right hole. A journey is a `do` block of steps `A → Except Ex B`; a `Left` short-circuits to the failure outcome; fan-out is two steps reading the same value, fan-in is a step taking both. Lean accepts only total functions, so a journey written this way cannot loop: a step that re-entered an earlier step would need recursion, and recursion Lean cannot prove terminating is rejected at compile time with "fail to show termination". So for journeys written as code, the DAG property needs no check; the compiler is the check. For journeys transcribed from tables, `wellFormed` does the same job: every step waits only on earlier steps. The two meet in the journey algebra, whose every term compiles to a graph that satisfies the same rule, `compile_wellFormed`.

**The cell graph is a projection, and its cycles are not journeys.** Fines queries circulation, and circulation publishes facts fines reacts to. Drawn as cell-to-cell edges with both kinds in one picture, that is a cycle, `cellGraph_hasCycle`; as journeys, it is two DAGs that both touch the same two cells. The rule does not require the projection to be acyclic, and no reactive system with feedback has an acyclic projection. What it does require is in the next section.
