"""Record what the implementation did, as a trace the model replays.

Drives the implementation through one run at the seam, writing each
command it was handed and the outcome it produced in the wire shape, with
the stamp of the fixtures it was built against, to
`traces/circulation-recorded.json`. The model's trace checker then replays
it: `lake exe replay traces/circulation-recorded.json`. A trace is what
the code did; nothing here is written from what it should have done.

Run from the example's directory: python3 impl/record_trace.py
"""
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).parent
sys.path.insert(0, str(HERE))
from circulation import decide, replay  # noqa: E402

STAMP = (HERE / "model-stamp.txt").read_text().strip()
OUT = HERE.parent / "traces" / "circulation-recorded.json"

# The run: five checkouts, the fifth retried, a sixth refused, a return,
# a renewal, the close, and a checkout after it.
COMMANDS = [
    {"kind": "checkOut", "key": "r1", "item": "b-1"},
    {"kind": "checkOut", "key": "r2", "item": "b-2"},
    {"kind": "checkOut", "key": "r3", "item": "b-3"},
    {"kind": "checkOut", "key": "r4", "item": "b-4"},
    {"kind": "checkOut", "key": "r5", "item": "b-5"},
    {"kind": "checkOut", "key": "r5", "item": "b-5"},
    {"kind": "checkOut", "key": "r6", "item": "b-6"},
    {"kind": "checkIn", "key": "r7", "item": "b-2"},
    {"kind": "renew", "key": "r8", "item": "b-1"},
    {"kind": "closeCard"},
    {"kind": "checkOut", "key": "r9", "item": "b-2"},
]


def main():
    history, steps = [], []
    for command in COMMANDS:
        verdict, payload = decide(command, replay(history))
        if verdict == "ok":
            steps.append({"command": command, "outcome": {"ok": payload}})
            history = history + payload
        else:
            steps.append({"command": command, "outcome": {"refused": payload}})
    OUT.write_text(json.dumps({"cell": "circulation", "model": STAMP, "history": [], "steps": steps}, indent=1) + "\n")
    print(f"wrote {OUT.relative_to(HERE.parent)} with {len(steps)} steps")


if __name__ == "__main__":
    main()
