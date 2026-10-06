"""Tests for inventory_api.stock.

Written with unittest so that they run with the standard library alone:

    PYTHONPATH=src python3 -m unittest discover -s tests

pytest collects unittest.TestCase classes, so `uv run pytest` runs the same tests.
"""

import unittest

from inventory_api.stock import (
    InsufficientStock,
    low_stock,
    receive,
    reorder_quantity,
    ship,
    total_units,
)


class ReceiveTests(unittest.TestCase):
    def test_adds_to_an_existing_sku(self):
        self.assertEqual(receive({"bolt": 3}, "bolt", 2), {"bolt": 5})

    def test_creates_a_new_sku(self):
        self.assertEqual(receive({}, "bolt", 7), {"bolt": 7})

    def test_does_not_change_its_argument(self):
        stock = {"bolt": 3}
        receive(stock, "bolt", 2)
        self.assertEqual(stock, {"bolt": 3})

    def test_rejects_zero_and_negative_quantities(self):
        for quantity in (0, -1):
            with self.subTest(quantity=quantity), self.assertRaises(ValueError):
                receive({}, "bolt", quantity)

    def test_rejects_quantities_that_are_not_integers(self):
        for quantity in (1.5, "2", True):
            with self.subTest(quantity=quantity), self.assertRaises(TypeError):
                receive({}, "bolt", quantity)


class ShipTests(unittest.TestCase):
    def test_removes_units(self):
        self.assertEqual(ship({"bolt": 5}, "bolt", 2), {"bolt": 3})

    def test_can_ship_everything(self):
        self.assertEqual(ship({"bolt": 5}, "bolt", 5), {"bolt": 0})

    def test_refuses_to_ship_more_than_is_on_hand(self):
        with self.assertRaises(InsufficientStock) as caught:
            ship({"bolt": 5}, "bolt", 6)
        self.assertEqual(caught.exception.sku, "bolt")
        self.assertEqual(caught.exception.on_hand, 5)
        self.assertEqual(caught.exception.requested, 6)

    def test_refuses_to_ship_an_unknown_sku(self):
        with self.assertRaises(InsufficientStock):
            ship({}, "bolt", 1)


class ReportTests(unittest.TestCase):
    def test_total_units(self):
        self.assertEqual(total_units({"bolt": 5, "nut": 7}), 12)
        self.assertEqual(total_units({}), 0)

    def test_low_stock_is_sorted_and_inclusive(self):
        stock = {"widget": 4, "bolt": 5, "gasket": 40}
        self.assertEqual(low_stock(stock, 5), ["bolt", "widget"])


class ReorderTests(unittest.TestCase):
    def test_nothing_to_order_when_at_or_above_target(self):
        self.assertEqual(reorder_quantity(10, 10), 0)
        self.assertEqual(reorder_quantity(12, 10), 0)

    def test_orders_the_shortfall(self):
        self.assertEqual(reorder_quantity(4, 10), 6)

    def test_rounds_up_to_whole_packs(self):
        self.assertEqual(reorder_quantity(4, 10, pack_size=4), 8)
        self.assertEqual(reorder_quantity(2, 10, pack_size=4), 8)

    def test_rejects_a_pack_size_that_is_not_positive(self):
        with self.assertRaises(ValueError):
            reorder_quantity(4, 10, pack_size=0)


if __name__ == "__main__":
    unittest.main()
