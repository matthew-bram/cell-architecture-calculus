import Library
/-!
# This project's generators

`lake exe fixtures` renders every cell registered below. The renderer is
`Render` in the calculus and is generic over the instances a cell's module
gives its types; a new cell adds one line to `cells`.
-/

/-- Every cell whose views the build renders. -/
def cells : List Render.Registered :=
  [ Render.register "circulation" "Library/Circulation.lean" "circulation lends" liveExamples
  , Render.register "holds" "Library/Holds.lean" "holds queues" holdExamples ]

/-- The entry point: render every registered cell into `generated/`. -/
def main : IO UInt32 := Render.run cells "../../cell-calculus/CellCalculus/Cell.lean"
