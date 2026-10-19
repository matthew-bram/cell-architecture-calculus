import CellCalculus.Wire
import CellCalculus.Gherkin
/-!
# The generators, generic over a cell's instances

A project's fixtures executable renders every registered cell's live
examples from the one Lean value, two ways: Gherkin for the reader, and
JSON fixtures in the wire shape for the code's tests, each stamped with the
hash of the cell's module and of the calculus so that a view without a
stamp is not a view. The rendering is generic over the `Describe`,
`WireCodec` and `JsonEncode` instances a cell's module gives its types;
registering a cell is one line in the project's `cells` list, and the
project's `main` is one call to `Render.run`.
-/

namespace Render

/-- A JSON string literal. -/
def quote (s : String) : String := "\"" ++ s ++ "\""
/-- One JSON object field, name to a rendered value. -/
def field (name value : String) : String := quote name ++ ":" ++ value
/-- A JSON array of rendered values. -/
def list (xs : List String) : String := "[" ++ String.intercalate "," xs ++ "]"
/-- A JSON object of rendered fields. -/
def object (fields : List String) : String := "{" ++ String.intercalate "," fields ++ "}"

/-- One example as a JSON fixture, its When serialized by the gateway's own codec. -/
def exampleJson {Command Event Refusal Wire : Type}
    [WireCodec Command Wire] [JsonEncode Wire] [JsonEncode Event] [JsonEncode Refusal]
    (ex : Example Command Event Refusal) : String :=
  let expect := match ex.expect with
    | .ok es   => object [field "ok" (list (es.map JsonEncode.toJson))]
    | .error r => object [field "refused" (JsonEncode.toJson r)]
  object [ field "id" (quote ex.id)
         , field "given" (list (ex.given.map JsonEncode.toJson))
         , field "when" (JsonEncode.toJson (WireCodec.serialize ex.when : Wire))
         , field "then" expect ]

/-- A registered cell: its name, the module whose hash stamps its views, and
    the two renderings of its live examples, each a function of the stamp. -/
structure Registered where
  /-- The cell's name, which names its files under `generated/`. -/
  name    : String
  /-- The module whose hash stamps the cell's views. -/
  module  : System.FilePath
  /-- The feature file, given the stamp. -/
  feature : String → String
  /-- The JSON fixtures, given the stamp. -/
  json    : String → String
  /-- How many live examples are rendered. -/
  count   : Nat

/-- Register a cell from its example list and the instances its module provides. -/
def register {Command Event Refusal Wire : Type}
    [Describe Command] [Describe Event] [Describe Refusal]
    [WireCodec Command Wire] [JsonEncode Wire] [JsonEncode Event] [JsonEncode Refusal]
    (name : String) (module : System.FilePath) (title : String)
    (examples : List (Example Command Event Refusal)) : Registered :=
  { name := name, module := module, count := examples.length
  , feature := fun stamp => featureFile title stamp examples
  , json := fun stamp => object [ field "model" (quote stamp)
                                , field "examples" (list (examples.map exampleJson)) ] ++ "\n" }

/-- Render every registered cell's views into `out`, stamping each with the
    hash of the cell's module and of the calculus file at `calculus`, both
    read relative to the working directory. -/
def run (cells : List Registered) (calculus : System.FilePath)
    (out : System.FilePath := "generated") : IO UInt32 := do
  let calculusSource ← IO.FS.readFile calculus
  IO.FS.createDirAll out
  for cell in cells do
    let model ← IO.FS.readFile cell.module
    let stamp := s!"{cell.module}#{hash model}+{calculus}#{hash calculusSource}"
    IO.FS.writeFile (out / s!"{cell.name}.feature") (cell.feature stamp)
    IO.FS.writeFile (out / s!"{cell.name}-examples.json") (cell.json stamp)
    IO.println s!"wrote {out}/{cell.name}.feature and {out}/{cell.name}-examples.json for {cell.count} live examples, {stamp}"
  return 0

end Render
