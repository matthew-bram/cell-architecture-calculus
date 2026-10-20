"""Tests that consume the model's generated fixtures by example id.

Copy this file into the code's test suite, point FIXTURES at the generated
JSON, record the fixture's stamp beside it, and fill the adapter with the
code's own fold and decider. Every example becomes one test named by its
id; a failing test names the row of the design the code disagrees with.
The stamp is asserted so that a regenerated fixture set is a visible
change. Standard library only; the worked example's suite,
examples/library/impl/test_circulation.py, is this file filled in.

Run from the directory above: python3 -m unittest discover -s <this directory> -v
"""
import json
import pathlib
import re
import sys
import unittest

HERE = pathlib.Path(__file__).parent
sys.path.insert(0, str(HERE))

# The adapter: the code's fold and decider, speaking the wire shape.
# replay(events) -> state ; decide(command, state) -> ("ok", [events]) | ("refused", reason)
from <the implementation> import decide, replay  # noqa: E402

FIXTURES = HERE.parent / "generated" / "<cell>-examples.json"
EXPECTED_STAMP = (HERE / "model-stamp.txt").read_text().strip()

DATA = json.loads(FIXTURES.read_text())
STAMP, EXAMPLES = DATA["model"], DATA["examples"]


class Stamp(unittest.TestCase):
    def test_fixtures_are_the_ones_this_suite_was_written_against(self):
        self.assertEqual(STAMP, EXPECTED_STAMP,
                         "the model was regenerated; read the fixture diff, then update model-stamp.txt")


class Examples(unittest.TestCase):
    """One test per example, added below so that each is named by its id."""


def make_test(example):
    def test(self):
        state = replay(example["given"])
        outcome = decide(example["when"], state)
        expected = example["then"]
        if "ok" in expected:
            self.assertEqual(outcome, ("ok", expected["ok"]),
                             f"{example['id']}: expected ok {expected['ok']}, got {outcome}")
        else:
            self.assertEqual(outcome, ("refused", expected["refused"]),
                             f"{example['id']}: expected refused {expected['refused']}, got {outcome}")
    return test


for example in EXAMPLES:
    name = "test_" + re.sub(r"[^A-Za-z0-9]+", "_", example["id"]).strip("_")
    setattr(Examples, name, make_test(example))

if __name__ == "__main__":
    unittest.main()
