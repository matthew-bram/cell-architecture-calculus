import Package.Architecture
-- `Package` is the project package's name: `Library` in the worked example.
/-!
# <The cell>, as its design reads

Transcribed from `<path to the design>` by the model-a-cell skill. The
design owns meaning; this module owns structure and behavior. Sources the
design names: <sources>.
-/

/-- The cell's commands, one constructor per row of the Commands table. -/
inductive XCommand
  | exampleCommand (field : String)
  deriving Repr, DecidableEq

/-- The cell's facts, one constructor per row of the Publishes table. -/
inductive XEvent
  | exampleHappened (field : String)
  deriving Repr, DecidableEq, BEq

/-- Why the cell says no, one constructor per refusal in the Commands table. -/
inductive XRefusal
  | exampleRefusal
  deriving Repr, DecidableEq, BEq

/-- The fold of the cell's history, one field per row of the State table.
    Each field's comment is its dictionary entry: meaning, domain, example. -/
structure XState where
  /-- <meaning>; <domain>; for example <value>. -/
  exampleField : Nat
  deriving Repr

/-- The cell. `decide` has one branch per Decide row in the table's order;
    `react` one per React row; `evolve` one per event; `isTerminal` from
    the Terminal line. -/
def x : Cell XCommand Unit XEvent XState XRefusal where
  initial := { exampleField := 0 }
  decide
    | .exampleCommand field, _ => .ok [.exampleHappened field]
  react := fun _ _ => []
  evolve
    | s, .exampleHappened _ => s
  isTerminal := fun _ => false

/-! ## The examples, as theorems. Each `id` is the row in the design and the
    name of the test in code; each value's doc comment is one line saying
    what the row shows. -/

/-- <What the row shows: the first example command is accepted and its fact published.> -/
def xExample1 : Example XCommand XEvent XRefusal :=
  { id := "X-EXAMPLE-1", given := [], when := .exampleCommand "a",
    expect := .ok [.exampleHappened "a"] }

theorem xExample1_holds : xExample1.holds x = true := by decide

/-! ## Universal claims, named as the design names them -/

/-! ## Coverage -/

instance : Kinded XCommand where
  kind | .exampleCommand _ => 0
  kinds := [0]

instance : Kinded XEvent where
  kind | .exampleHappened _ => 0
  kinds := [0]

instance : Kinded XRefusal where
  kind | .exampleRefusal => 0
  kinds := [0]

def xExamples : List (Example XCommand XEvent XRefusal) := [xExample1]

theorem xExamples_allHold       : xExamples.all (·.holds x) = true := by decide
theorem xExamples_coverCommands : coversCommands xExamples = true := by decide
theorem xExamples_coverEvents   : coversEvents   xExamples = true := by decide
theorem xExamples_coverRefusals : coversRefusals xExamples = true := by decide

/-! ## The wire shape, as a projection -/

/-- What the wire carries: a tag and loose optional fields, one per field any
    command has, because the wire cannot say what the sum type says. -/
structure XWireCommand where
  kind  : String
  field : Option String := none
  deriving Repr, DecidableEq

/-- The projection onto the wire: the sum becomes a tag and optional fields. -/
def XCommand.serialize : XCommand → XWireCommand
  | .exampleCommand field => { kind := "exampleCommand", field := some field }

/-- The parse back, with the loss as refusals: a missing field or an unknown tag. -/
def XCommand.parse (w : XWireCommand) : Except ParseRefusal XCommand :=
  match w.kind with
  | "exampleCommand" =>
      match w.field with
      | some field => .ok (.exampleCommand field)
      | none       => .error (.missingField "field")
  | other => .error (.unknownKind other)

/-- The codec, with its round trip proved by cases: the instance cannot
    exist without it. -/
instance : WireCodec XCommand XWireCommand where
  serialize := XCommand.serialize
  parse := XCommand.parse
  parse_serialize := by intro c; cases c <;> rfl

/-! ## The wire renderings the fixtures carry -/

instance : JsonEncode XWireCommand where
  toJson w :=
    let field := match w.field with | some f => ",\"field\":\"" ++ f ++ "\"" | none => ""
    "{\"kind\":\"" ++ w.kind ++ "\"" ++ field ++ "}"

instance : JsonEncode XEvent where
  toJson | .exampleHappened f => "{\"kind\":\"exampleHappened\",\"field\":\"" ++ f ++ "\"}"

instance : JsonEncode XRefusal where
  toJson | .exampleRefusal => "\"exampleRefusal\""

/-! ## The wire readings the trace checker uses, the encoders' inverses -/

instance : JsonDecode XWireCommand where
  fromJson j := do
    return { kind := ← Replay.strField j "kind", field := (Replay.strField j "field").toOption }

instance : JsonDecode XEvent where
  fromJson j := do
    match ← Replay.strField j "kind" with
    | "exampleHappened" => return .exampleHappened (← Replay.strField j "field")
    | other             => throw s!"unknown event kind \"{other}\""

instance : JsonDecode XRefusal where
  fromJson j := do
    match ← j.getStr? with
    | "exampleRefusal" => return .exampleRefusal
    | other            => throw s!"unknown refusal \"{other}\""

/-! ## Predicates the contracts, attributes and mutants use; each documented -/

/-- Whether a fact is the example happening. -/
def XEvent.isExampleHappened : XEvent → Bool
  | .exampleHappened _ => true

/-! ## The sentences a reader reviews -/

instance : Describe XCommand where
  describe | .exampleCommand field => s!"an example command arrives with {field}"

instance : Describe XEvent where
  describe | .exampleHappened field => s!"an example happened with {field}"

instance : Describe XRefusal where
  describe | .exampleRefusal => "it is refused for the example reason"
