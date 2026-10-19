import CellCalculus.Cell
/-!
# The wire is a projection, and the parse is in the model

Proto, JSON and Avro cannot say what the model's sum types say, so the wire
shape is a projection of the model's type and what the projection loses is
a parse refusal. A project implements `WireCodec` for each command type,
and the gateway, parse then decide, is generic.
-/

/-- What a parse can refuse: the wire can carry what the model will not. -/
inductive ParseRefusal
  /-- The wire's tag names no command of the model. -/
  | unknownKind (kind : String)
  /-- A field the command needs is absent from the wire. -/
  | missingField (field : String)
  deriving Repr, DecidableEq

/-- A command type's wire shape, with the round trip as a law: an instance
    cannot exist without the proof that every command survives the wire.
    The same pair serializes every example into a fixture and parses every
    trace back. -/
class WireCodec (Command : Type) (Wire : outParam Type) where
  /-- The projection onto the wire. -/
  serialize : Command → Wire
  /-- The parse back, with what the projection lost as refusals. -/
  parse     : Wire → Except ParseRefusal Command
  /-- Every model command survives the wire. -/
  parse_serialize : ∀ command, parse (serialize command) = .ok command

/-- What a gateway can refuse: the parse, or the domain. The only place both
    refusal kinds meet. -/
inductive GatewayRefusal (Refusal : Type)
  /-- The parse refused: not understood. -/
  | parse  (reason : ParseRefusal)
  /-- The decider refused, with the cell's own reason: understood, and no. -/
  | domain (reason : Refusal)
  deriving Repr, DecidableEq

/-- The gateway: parse, then decide. -/
def gateway {Command ForeignEvent Event State Refusal Wire : Type} [WireCodec Command Wire]
    (cell : Cell Command ForeignEvent Event State Refusal) (history : List Event) (wire : Wire) :
    Except (GatewayRefusal Refusal) (List Event) :=
  match WireCodec.parse wire with
  | .error reason => .error (.parse reason)
  | .ok command =>
      match cell.handle history command with
      | .error reason => .error (.domain reason)
      | .ok events => .ok events

/-- A serialized command reaches the decider: the gateway on the wire form of
    a command is the cell's handle of that command, for every cell, history
    and command. -/
theorem gateway_serialize {Command ForeignEvent Event State Refusal Wire : Type}
    [WireCodec Command Wire] (cell : Cell Command ForeignEvent Event State Refusal)
    (history : List Event) (command : Command) :
    gateway cell history (WireCodec.serialize command)
      = (cell.handle history command).mapError GatewayRefusal.domain := by
  simp only [gateway, WireCodec.parse_serialize]
  cases cell.handle history command <;> rfl

/-- One JSON rendering per value, for the fixtures a code's tests consume.
    A project gives each command, event and refusal type an instance; the
    generator is then one function for every cell. Added after version 1 as
    an addition, not a change: nothing above depends on it. -/
class JsonEncode (α : Type) where
  /-- The value rendered as JSON text. -/
  toJson : α → String
