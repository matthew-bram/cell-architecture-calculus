import Lean.Data.Json
import CellCalculus.Envelope
import CellCalculus.Wire
import CellCalculus.Gherkin
/-!
# The trace checker, generic over a cell's instances

Stage 6 of the round trip: what the code did, recorded as a trace in the
wire shape, is input to the model, and the model is the judge. A project's
replay executable reads each trace, parses its commands with the same
`parse` the gateway uses, replays it through the cell with `Cell.conforms`
or checks a run's shape with `Run.conforms`, and names the step where the
code took a path the model has no edge for.

Two things are added here beside the executable. `JsonDecode`, the reading
of a value from JSON, which a project gives its wire command, its events
and its refusals as it gives them `JsonEncode`; the envelopes' fields are
decoded here once for every project. And `Cell.firstRejection` with
`Run.firstRejection`, which say *which* step or fact the model rejects, each
proved to be none exactly when `conforms` holds, so that the executable's
verdict is the theorem's and not a second opinion.

JSON is read with `Lean.Data.Json` from the toolchain; the package still
requires nothing.
-/

open Lean (Json)

/-- One reading per value from JSON, the inverse of `JsonEncode` for what a
    trace carries. A project gives an instance to each wire command, event
    and refusal type; the envelopes' fields have theirs below. -/
class JsonDecode (α : Type) where
  /-- The value read from JSON, or why it could not be. -/
  fromJson : Json → Except String α

/-! ## The first rejected step, and that it is `conforms`'s negation -/

/-- Why a trace was rejected at a step: what the model expected of the
    command in that state, and what the trace reported. -/
structure Rejection (Event Refusal : Type) where
  /-- The index of the step, counting from zero. -/
  step     : Nat
  /-- What the model decides for that command in that state. -/
  expected : Except Refusal (List Event)
  /-- What the trace says the code did. -/
  reported : Except Refusal (List Event)

/-- The first step at which the trace disagrees with the model, or none.
    The same walk as `Cell.conforms`, keeping the index and both outcomes. -/
def Cell.firstRejection {Command ForeignEvent Event State Refusal : Type} [BEq Event] [BEq Refusal]
    (cell : Cell Command ForeignEvent Event State Refusal) :
    List (TraceStep Command Event Refusal) → List Event → Nat → Option (Rejection Event Refusal)
  | [], _, _ => none
  | step :: rest, history, i =>
    match cell.handle history step.command, step.outcome with
    | .ok events, .ok reported =>
        if events == reported then cell.firstRejection rest (history ++ events) (i + 1)
        else some { step := i, expected := .ok events, reported := .ok reported }
    | .error reason, .error reported =>
        if reason == reported then cell.firstRejection rest history (i + 1)
        else some { step := i, expected := .error reason, reported := .error reported }
    | expected, reported => some { step := i, expected := expected, reported := reported }

/-- The executable's verdict is the theorem's: no step is rejected exactly
    when the trace conforms, for every cell, trace, history and index. -/
theorem Cell.firstRejection_isNone {Command ForeignEvent Event State Refusal : Type}
    [BEq Event] [BEq Refusal] (cell : Cell Command ForeignEvent Event State Refusal)
    (trace : List (TraceStep Command Event Refusal)) (history : List Event) (i : Nat) :
    (cell.firstRejection trace history i).isNone = cell.conforms trace history := by
  induction trace generalizing history i with
  | nil => rfl
  | cons step rest ih =>
    simp only [Cell.firstRejection, Cell.conforms]
    cases h : cell.handle history step.command <;> cases h' : step.outcome <;> simp only
    · split <;> simp_all
    · rfl
    · rfl
    · split <;> simp_all

/-- The first node of a step graph that waits on a node not before it, with
    its index, or none. The same walk as `Journey.nodesOk`. -/
def Journey.firstBadNode : Nat → List Journey.Node → Option (Nat × Journey.Node)
  | _, [] => none
  | i, node :: rest =>
      if node.needs.all (· < i) then Journey.firstBadNode (i + 1) rest else some (i, node)

theorem Journey.firstBadNode_isNone (i : Nat) (nodes : List Journey.Node) :
    (Journey.firstBadNode i nodes).isNone = Journey.nodesOk i nodes := by
  induction nodes generalizing i with
  | nil => rfl
  | cons node rest ih =>
    simp only [Journey.firstBadNode, Journey.nodesOk]
    cases node.needs.all (· < i) <;> simp [ih]

/-- Why a run was rejected on its shape alone: a fact recorded under another
    run, or a fact that cites one not before it. -/
inductive RunRejection
  /-- A fact recorded under another run's correlation, named with it. -/
  | strayEvent (id : EventId) (correlation : RunId)
  /-- A fact, at its index, that cites a fact not before it. -/
  | badNode (index : Nat) (node : Journey.Node)

theorem List.find?_not_isNone {α : Type} (p : α → Bool) (l : List α) :
    (l.find? (fun x => !p x)).isNone = l.all p := by
  induction l with
  | nil => rfl
  | cons x xs ih => cases hp : p x <;> simp [hp, ih]

variable [Architecture]

/-- The first reason a run fails its shape check, or none. The same two
    checks as `Run.conforms`, in the same order. -/
def Run.firstRejection {Command Event Subject : Type} (run : Run Command Event Subject) :
    Option RunRejection :=
  match run.events.find? (fun e => !(e.correlation == run.root.correlation)) with
  | some e => some (.strayEvent e.id e.correlation)
  | none => (Journey.firstBadNode 0 run.toNodes).map fun (i, node) => .badNode i node

theorem Run.firstRejection_isNone {Command Event Subject : Type} (run : Run Command Event Subject) :
    run.firstRejection.isNone = run.conforms := by
  simp only [Run.firstRejection, Run.conforms, Run.sameRun]
  rw [← List.find?_not_isNone, ← Journey.firstBadNode_isNone]
  cases run.events.find? (fun e => !(e.correlation == run.root.correlation)) <;>
    cases Journey.firstBadNode 0 run.toNodes <;> rfl

/-! ## Reading the envelopes' fields, once for every project -/

namespace Replay

/-- A string field of a JSON object. -/
def strField (j : Json) (name : String) : Except String String := do (← j.getObjVal? name).getStr?
/-- A natural-number field of a JSON object. -/
def natField (j : Json) (name : String) : Except String Nat := do (← j.getObjVal? name).getNat?
/-- An array field of a JSON object, as a list. -/
def arrField (j : Json) (name : String) : Except String (List Json) := do
  return (← (← j.getObjVal? name).getArr?).toList
/-- An absent array field reads as empty. -/
def optArrField (j : Json) (name : String) : Except String (List Json) :=
  match j.getObjVal? name with
  | .error _ => .ok []
  | .ok v => do return (← v.getArr?).toList
/-- A field read by its type's instance. -/
def decodeField {α : Type} [JsonDecode α] (j : Json) (name : String) : Except String α := do
  JsonDecode.fromJson (← j.getObjVal? name)
/-- Every element read by its type's instance. -/
def decodeList {α : Type} [JsonDecode α] (js : List Json) : Except String (List α) :=
  js.mapM JsonDecode.fromJson

instance : JsonDecode EventId where fromJson j := do return ⟨← j.getStr?⟩
instance : JsonDecode RunId where fromJson j := do return ⟨← j.getStr?⟩
instance : JsonDecode Instant where fromJson j := do return ⟨← j.getNat?⟩
instance : JsonDecode SchemaVersion where fromJson j := do return ⟨← j.getNat?⟩

/-- `{"minted": "k1"}` or `{"derived": {"issuer": "...", "cause": "e1"}}`. -/
instance : JsonDecode IdempotencyKey where
  fromJson j :=
    match j.getObjVal? "minted" with
    | .ok raw => do return .minted (← raw.getStr?)
    | .error _ =>
      match j.getObjVal? "derived" with
      | .ok d => do return .derived (← strField d "issuer") ⟨← strField d "cause"⟩
      | .error _ => .error "a key is {\"minted\": ...} or {\"derived\": {\"issuer\": ..., \"cause\": ...}}"

/-- `{"ofCommand": key}` or `{"ofEvent": "e1"}`. -/
instance : JsonDecode CausationId where
  fromJson j :=
    match j.getObjVal? "ofCommand" with
    | .ok key => do return .ofCommand (← JsonDecode.fromJson key)
    | .error _ =>
      match j.getObjVal? "ofEvent" with
      | .ok id => do return .ofEvent ⟨← id.getStr?⟩
      | .error _ => .error "a causation is {\"ofCommand\": key} or {\"ofEvent\": id}"

/-- `{"principal": ...}`, `{"policy": "pipeline"}`, `"timer"`, `{"partner": "..."}`
    or `"operator"`; the principal is the project's, read by its instance. -/
instance [JsonDecode Architecture.Principal] : JsonDecode Actor where
  fromJson j :=
    match j.getStr? with
    | .ok "timer" => .ok .timer
    | .ok "operator" => .ok .operator
    | .ok other => .error s!"an actor is \"timer\", \"operator\" or an object, not \"{other}\""
    | .error _ =>
      match j.getObjVal? "principal", j.getObjVal? "policy", j.getObjVal? "partner" with
      | .ok p, _, _ => do return .principal (← JsonDecode.fromJson p)
      | _, .ok c, _ => do return .policy (← c.getStr?)
      | _, _, .ok n => do return .partner (← n.getStr?)
      | _, _, _ => .error "an actor is {\"principal\": ...}, {\"policy\": ...}, {\"partner\": ...}, \"timer\" or \"operator\""

/-- A parse refusal as a sentence. -/
def describeParse : ParseRefusal → String
  | .unknownKind kind => s!"unknown kind \"{kind}\""
  | .missingField field => s!"missing field \"{field}\""

/-- A command on the wire, parsed by the same `parse` the gateway uses; a
    parse refusal is the reading's error. -/
def decodeCommand {Command Wire : Type} [JsonDecode Wire] [WireCodec Command Wire]
    (j : Json) : Except String Command := do
  match WireCodec.parse (← (JsonDecode.fromJson j : Except String Wire)) with
  | .ok command => return command
  | .error reason => throw s!"the command is not understood: {describeParse reason}"

/-- The command envelope's fields: actor, key, causation (null for a root),
    correlation, issuedAt, and the payload in the wire shape. -/
def decodeCommandEnvelope {Command Wire : Type} [JsonDecode Wire] [WireCodec Command Wire]
    [JsonDecode Architecture.Principal] (j : Json) : Except String (CommandEnvelope Command) := do
  let causation ← match j.getObjVal? "causation" with
    | .error _ => pure none
    | .ok Json.null => pure none
    | .ok c => do pure (some ⟨← c.getStr?⟩)
  return { actor := ← decodeField j "actor", key := ← decodeField j "key", causation := causation
         , correlation := ← decodeField j "correlation", issuedAt := ← decodeField j "issuedAt"
         , payload := ← decodeCommand (← j.getObjVal? "payload") }

/-- The event envelope's fields: id, causation, correlation, version, the
    subject by the project's instance, recordedAt, and the payload. -/
def decodeEventEnvelope {Event Subject : Type} [JsonDecode Event] [JsonDecode Subject]
    (j : Json) : Except String (EventEnvelope Event Subject) := do
  return { id := ← decodeField j "id", causation := ← decodeField j "causation"
         , correlation := ← decodeField j "correlation", version := ← decodeField j "version"
         , subject := ← decodeField j "subject", recordedAt := ← decodeField j "recordedAt"
         , payload := ← decodeField j "payload" }

/-- One step of a cell's trace as recorded, the command still on the wire:
    `{"command": wire, "outcome": {"ok": [events]} | {"refused": reason}}`. -/
structure WireStep (Wire Event Refusal : Type) where
  /-- The command as the trace carries it, not yet parsed. -/
  command : Wire
  /-- What the code reported: the refusal, or the events it recorded. -/
  outcome : Except Refusal (List Event)

/-- One step read from JSON, its command left on the wire. -/
def decodeStep {Event Refusal Wire : Type} [JsonDecode Wire] [JsonDecode Event] [JsonDecode Refusal]
    (j : Json) : Except String (WireStep Wire Event Refusal) := do
  let outcome ← j.getObjVal? "outcome"
  let outcome ← match outcome.getObjVal? "ok" with
    | .ok es => do pure (.ok (← decodeList (← es.getArr?).toList))
    | .error _ => do pure (.error (← decodeField outcome "refused"))
  return { command := ← decodeField j "command", outcome := outcome }

/-- Parse every step's command with the cell's codec. A refusal names the
    step: the code sent a command the model has no shape for. -/
def parseSteps {Command Event Refusal Wire : Type} [WireCodec Command Wire] :
    List (WireStep Wire Event Refusal) → Nat → Except (Nat × ParseRefusal) (List (TraceStep Command Event Refusal))
  | [], _ => .ok []
  | step :: rest, i =>
    match WireCodec.parse step.command with
    | .error reason => .error (i, reason)
    | .ok command => do return { command := command, outcome := step.outcome } :: (← parseSteps rest (i + 1))

/-- What the checker says of one trace. -/
inductive Verdict
  /-- The model agrees with every step, or every fact of the run is in place; with the count. -/
  | conforms (steps : Nat)
  /-- The first step or fact the model rejects, as a sentence. -/
  | rejected (message : String)
  /-- The file could not be read, with the reason. -/
  | malformed (reason : String)

/-- An outcome as the sentences the Gherkin uses. -/
def describeOutcome {Event Refusal : Type} [Describe Event] [Describe Refusal] :
    Except Refusal (List Event) → String
  | .error reason => Describe.describe reason
  | .ok [] => "nothing happens"
  | .ok es => String.intercalate "; " (es.map Describe.describe)

/-- A registered checker: the name a trace's `cell` or `run` field names,
    the module whose hash stamps it, and the check. -/
structure Registered where
  /-- The name a trace's `cell` or `run` field gives. -/
  name   : String
  /-- The module whose hash stamps the checker. -/
  module : System.FilePath
  /-- The verdict on a trace's JSON. -/
  check  : Json → Verdict

/-- Register a cell: a trace naming it is replayed from its `history` through
    its `steps`, each command parsed by the cell's codec. -/
def register {Command ForeignEvent Event State Refusal Wire : Type}
    [BEq Event] [BEq Refusal] [JsonDecode Wire] [WireCodec Command Wire]
    [JsonDecode Event] [JsonDecode Refusal] [Describe Event] [Describe Refusal]
    (name : String) (module : System.FilePath)
    (cell : Cell Command ForeignEvent Event State Refusal) : Registered :=
  { name := name, module := module
  , check := fun j =>
      let read : Except String (List Event × List (WireStep Wire Event Refusal)) := do
        let history ← decodeList (← optArrField j "history")
        let steps ← (← arrField j "steps").mapM decodeStep
        return (history, steps)
      match read with
      | .error reason => .malformed reason
      | .ok (history, steps) =>
        match parseSteps (Command := Command) steps 0 with
        | .error (i, reason) => .rejected s!"step {i}: the command is not understood: {describeParse reason}"
        | .ok trace =>
          match cell.firstRejection trace history 0 with
          | none => .conforms trace.length
          | some r => .rejected s!"step {r.step}: the model expected {describeOutcome r.expected}, the trace reported {describeOutcome r.reported}" }

/-- Register a run: a trace naming it is checked on its shape, every fact
    under the root's correlation and every citation earlier in the run. -/
def registerRun (Command Event Subject : Type) {Wire : Type}
    [JsonDecode Wire] [WireCodec Command Wire] [JsonDecode Event] [JsonDecode Subject]
    [JsonDecode Architecture.Principal]
    (name : String) (module : System.FilePath) : Registered :=
  { name := name, module := module
  , check := fun j =>
      let read : Except String (Run Command Event Subject) := do
        return { root := ← decodeCommandEnvelope (← j.getObjVal? "root")
               , events := ← (← arrField j "events").mapM decodeEventEnvelope }
      match read with
      | .error reason => .malformed reason
      | .ok run =>
        match run.firstRejection with
        | none => .conforms run.events.length
        | some (.strayEvent id correlation) =>
            .rejected s!"fact {id.raw} is recorded under run {correlation.raw}, the root's is {run.root.correlation.raw}"
        | some (.badNode i node) =>
            .rejected s!"fact {node.name} at index {i} cites a fact not before it: {node.needs}" }

/-- Check every trace file named on the command line against the registered
    checkers, one line per file, and exit non-zero if any is rejected or
    cannot be read. A trace that carries a `model` stamp different from the
    checker's gets a warning, since it was recorded against another model. -/
def run (registered : List Registered) (calculus : System.FilePath) (args : List String) :
    IO UInt32 := do
  if args.isEmpty then
    IO.eprintln "usage: replay <trace.json>..."
    return 2
  let calculusSource ← IO.FS.readFile calculus
  let mut failures := 0
  for path in args do
    let text ← IO.FS.readFile path
    let verdict ← match Json.parse text with
      | .error reason => pure (Verdict.malformed s!"not JSON: {reason}")
      | .ok j =>
        let name := (j.getObjVal? "cell").toOption <|> (j.getObjVal? "run").toOption
        match name >>= (·.getStr?.toOption) with
        | none => pure (Verdict.malformed "no \"cell\" or \"run\" field")
        | some name =>
          match registered.find? (·.name == name) with
          | none => pure (Verdict.malformed s!"no checker registered for \"{name}\"")
          | some checker => do
            let model ← IO.FS.readFile checker.module
            let stamp := s!"{checker.module}#{hash model}+{calculus}#{hash calculusSource}"
            match (j.getObjVal? "model").toOption >>= (·.getStr?.toOption) with
            | some recorded => if recorded != stamp then
                IO.eprintln s!"{path}: warning: recorded against {recorded}, the model is {stamp}"
            | none => pure ()
            pure (checker.check j)
    match verdict with
    | .conforms n => IO.println s!"{path}: conforms, {n} steps"
    | .rejected message => IO.println s!"{path}: rejected at {message}"; failures := failures + 1
    | .malformed reason => IO.println s!"{path}: cannot be read: {reason}"; failures := failures + 1
  return if failures == 0 then 0 else 1

end Replay
