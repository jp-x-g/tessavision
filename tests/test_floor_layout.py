"""Regression checks for the console's fixed-width floor boxes.

Run with python3 tests/test_floor_layout.py [path/to/compose.sh].
"""

import pathlib
import re
import subprocess
import sys
import unittest


source = pathlib.Path(sys.argv[1]) if __name__ == "__main__" and len(sys.argv) > 1 else pathlib.Path(__file__).resolve().parents[1] / "compose.sh"
text = source.read_text()
# Exercise the actual rendering functions without starting the display loop.
functions = text[text.index("\tH=9"):text.index("\tmake_floor_box 1F")]
ansi = re.compile(r"\x1b\[[0-9;]*m")


def render(command, *args):
    result = subprocess.run(
        ["bash", "-c", "export LANG=C.UTF-8 LC_ALL=C.UTF-8\n"
         "CURRENT_FLOOR=3F; RED=$'\\033[31m'; RESET=$'\\033[0m'\n"
         + functions + "\n" + command, "layout-test", *args],
        check=True, capture_output=True,
    )
    return ansi.sub("", result.stdout.decode("utf-8")).splitlines()


class FloorLayoutTests(unittest.TestCase):
    def assert_row(self, row):
        self.assertEqual(len(row), 60, repr(row))
        self.assertEqual((row[0], row[14], row[59]), ("║", "│", "║"))

    def test_unicode_padding_and_truncation(self):
        for floor in ("1F", "3F", "4F"):
            for title in ("in Lean – Henry Robbins", "Café — tonight’s discussion",
                          "a" * 43 + "é", "a" * 43 + "é" + "overflow", ""):
                with self.subTest(floor=floor, title=title):
                    row, = render('print_event_row_parts "$1" "$2" "$3"',
                                  floor, "19:00 - 21:00", title)
                    self.assert_row(row)
                    self.assertEqual(row[15:59], title[:44].ljust(44))

    def test_current_event_wrapping(self):
        event = "19:00 - 21:00|SF Lean: Verified mixed-integer programming in Lean – Henry Robbins"
        rows = render('ROWS_PRINTED=0; print_wrapped_event 3F "$1"', event)
        self.assertEqual(len(rows), 2)
        for row in rows:
            self.assert_row(row)
        self.assertEqual(rows[1][15:59].rstrip(), "in Lean – Henry Robbins")

    def test_long_unicode_word(self):
        rows = render('ROWS_PRINTED=0; print_wrapped_event 3F "$1"', "time|" + "é" * 90)
        self.assertEqual(len(rows), 3)
        for row in rows:
            self.assert_row(row)

    def test_empty_box_geometry(self):
        for floor in ("1F", "2F", "3F", "4F"):
            rows = render('make_floor_box "$1" /dev/null /dev/stdout', floor)
            self.assertEqual(len(rows), 11)
            self.assertTrue(all(len(row) == 60 for row in rows))
            for row in rows[1:-1]:
                self.assert_row(row)


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
