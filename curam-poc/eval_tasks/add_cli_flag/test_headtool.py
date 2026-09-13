import subprocess
import sys
import unittest


class TestHead(unittest.TestCase):
    def test_no_limit(self):
        out = subprocess.run(
            [sys.executable, "headtool.py"],
            input="a\nb\nc\n",
            text=True,
            capture_output=True,
        )
        self.assertEqual(out.stdout, "a\nb\nc\n")


if __name__ == "__main__":
    unittest.main()
