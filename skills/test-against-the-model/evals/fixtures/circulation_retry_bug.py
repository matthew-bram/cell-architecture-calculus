"""The circulation cell, implemented, with a defect: a retried checkout books again.

The reference implementation the example's tests and traces run against.
It speaks the wire shape the model's generator emits: commands and events
as dicts with a "kind", refusals as strings. The seam the method needs is
here and nowhere else: a fold from events to a state, and a decider from
a command and a state to an outcome, both pure. Storage and transport
would wrap these; they never reach inside.
"""

LOAN_LIMIT = 5


def initial():
    """The state before any event."""
    return {"onLoan": [], "seen": [], "closed": False}


def evolve(state, event):
    """The fold: one event applied to the state."""
    kind = event["kind"]
    if kind == "checkedOut":
        return {"onLoan": [event["item"]] + state["onLoan"],
                "seen": [event["key"]] + state["seen"], "closed": state["closed"]}
    if kind == "checkedIn":
        on_loan = list(state["onLoan"])
        if event["item"] in on_loan:
            on_loan.remove(event["item"])
        return {"onLoan": on_loan, "seen": [event["key"]] + state["seen"], "closed": state["closed"]}
    if kind == "renewed":
        return {**state, "seen": [event["key"]] + state["seen"]}
    if kind == "cardClosed":
        return {**state, "closed": True}
    raise ValueError(f"unknown event {event}")


def replay(events):
    """The state as the fold of a history."""
    state = initial()
    for event in events:
        state = evolve(state, event)
    return state


def decide(command, state):
    """The decider. Returns ("ok", [events]) or ("refused", reason)."""
    kind = command["kind"]
    if kind == "checkOut":
        if state["closed"]:
            return ("refused", "cardClosed")
        if len(state["onLoan"]) >= LOAN_LIMIT:
            return ("refused", "limitReached")
        return ("ok", [{"kind": "checkedOut", "key": command["key"], "item": command["item"],
                        "onLoan": len(state["onLoan"]) + 1}])
    if kind == "checkIn":
        if command["key"] in state["seen"]:
            return ("ok", [])
        if command["item"] not in state["onLoan"]:
            return ("refused", "notOnLoan")
        return ("ok", [{"kind": "checkedIn", "key": command["key"], "item": command["item"]}])
    if kind == "renew":
        if state["closed"]:
            return ("refused", "cardClosed")
        if command["key"] in state["seen"]:
            return ("ok", [])
        if command["item"] not in state["onLoan"]:
            return ("refused", "notOnLoan")
        return ("ok", [{"kind": "renewed", "key": command["key"], "item": command["item"]}])
    if kind == "closeCard":
        return ("ok", []) if state["closed"] else ("ok", [{"kind": "cardClosed"}])
    raise ValueError(f"unknown command {command}")
