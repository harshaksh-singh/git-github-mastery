"""Pure functions over a stock table.

A stock table is a mapping from SKU (stock keeping unit, a string) to the number of units on hand.
Every function returns a new mapping and never changes its argument, so the functions are easy to
test and safe to call from request handlers.
"""

from collections.abc import Mapping


class InsufficientStock(Exception):
    """Raised when a shipment asks for more units than are on hand."""

    def __init__(self, sku: str, on_hand: int, requested: int) -> None:
        super().__init__(f"{sku}: requested {requested}, on hand {on_hand}")
        self.sku = sku
        self.on_hand = on_hand
        self.requested = requested


def _check_quantity(quantity: int) -> None:
    if isinstance(quantity, bool) or not isinstance(quantity, int):
        raise TypeError("quantity must be an integer")
    if quantity <= 0:
        raise ValueError("quantity must be positive")


def receive(stock: Mapping[str, int], sku: str, quantity: int) -> dict[str, int]:
    """Return a new stock table with `quantity` units of `sku` added."""
    _check_quantity(quantity)
    updated = dict(stock)
    updated[sku] = updated.get(sku, 0) + quantity
    return updated


def ship(stock: Mapping[str, int], sku: str, quantity: int) -> dict[str, int]:
    """Return a new stock table with `quantity` units of `sku` removed."""
    _check_quantity(quantity)
    on_hand = stock.get(sku, 0)
    if quantity > on_hand:
        raise InsufficientStock(sku, on_hand, quantity)
    updated = dict(stock)
    updated[sku] = on_hand - quantity
    return updated


def total_units(stock: Mapping[str, int]) -> int:
    """Return the number of units on hand across all SKUs."""
    return sum(stock.values())


def low_stock(stock: Mapping[str, int], threshold: int) -> list[str]:
    """Return the SKUs whose quantity is at or below `threshold`, sorted by name."""
    return sorted(sku for sku, quantity in stock.items() if quantity <= threshold)


def reorder_quantity(on_hand: int, target: int, pack_size: int = 1) -> int:
    """Return how many units to order to reach `target`, rounded up to whole packs."""
    if pack_size <= 0:
        raise ValueError("pack_size must be positive")
    shortfall = target - on_hand
    if shortfall <= 0:
        return 0
    packs = -(-shortfall // pack_size)
    return packs * pack_size


def main() -> None:
    """Print a short report. The container image runs this as its command."""
    stock = receive({"widget": 4, "gasket": 40}, "bolt", 12)
    print(f"inventory-api: {total_units(stock)} units on hand across {len(stock)} SKUs")
    print(f"inventory-api: low stock (5 or fewer): {', '.join(low_stock(stock, 5))}")


if __name__ == "__main__":
    main()
