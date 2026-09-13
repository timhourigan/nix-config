import unittest

from app import price


class TestPrice(unittest.TestCase):
    def test_price(self):
        self.assertEqual(price([10, 20]), 36.0)
        self.assertEqual(price([]), 0)


if __name__ == "__main__":
    unittest.main()
