import CellCalculus.Cell
/-!
# A generated view: the example as Gherkin

The non-technical reader reviews this text; the code's tests run it. Nobody
edits it. A project gives each type a sentence per constructor through
`Describe`, and the renderer is a fold over the example.
-/

/-- One plain sentence per value, for the reader who reviews scenarios. -/
class Describe (α : Type) where
  /-- The sentence for a value, as a reader of scenarios should read it. -/
  describe : α → String

/-- Render an example as a Gherkin scenario. -/
def Example.toGherkin {Command Event Refusal : Type}
    [Describe Command] [Describe Event] [Describe Refusal]
    (ex : Example Command Event Refusal) : String :=
  let sentences (es : List Event) : String :=
    String.join (es.map fun (e : Event) => "\n  And " ++ Describe.describe e)
  let given := match ex.given with
    | [] => "  Given nothing has happened yet"
    | e :: es => "  Given " ++ Describe.describe e ++ sentences es
  let expect := match ex.expect with
    | .error reason => "  Then " ++ Describe.describe reason
    | .ok [] => "  Then nothing happens"
    | .ok (e :: es) => "  Then " ++ Describe.describe e ++ sentences es
  s!"Scenario: {ex.id}\n{given}\n  When {Describe.describe ex.when}\n{expect}"

/-- Render an example set as one Gherkin feature file, stamped so that a
    view without a stamp is not a view. -/
def featureFile {Command Event Refusal : Type}
    [Describe Command] [Describe Event] [Describe Refusal]
    (title stamp : String) (examples : List (Example Command Event Refusal)) : String :=
  "# generated from " ++ stamp ++ "; do not edit\nFeature: " ++ title ++ "\n\n"
    ++ String.intercalate "\n\n" (examples.map Example.toGherkin) ++ "\n"
