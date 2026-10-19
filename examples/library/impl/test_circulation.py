"""The implementation tested against the model's examples, by id.

Every example the model renders into `generated/circulation-examples.json`
becomes one test named by its id: replay the example's history through the
implementation's fold, hand its command to the decider, compare the outcome
exactly. A failing test names the row of the design the code disagrees
with. The fixture's stamp is asserted against `model-stamp.txt` beside this
file, so a regenerated model changes the tests visibly rather than silently.

Run from the example's directory: python3 -m unittest discover -s impl -v
"""
import json
import pathlib
import re
import sys
import unittest

HERE = pathlib.Path(__file__).parent
sys.path.insert(0, str(HERE))
from circulation import decide, replay  # noqa: E402

FIXTURES = HERE.parent / "generated" / "circulation-examples.json"
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
