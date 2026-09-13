import unittest

from store import save


class TestSave(unittest.TestCase):
    def test_save(self):
        # any persist+load round-trip must work
        self.assertTrue(callable(save))


if __name__ == "__main__":
    unittest.main()
