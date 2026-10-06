"""Stock arithmetic for a small inventory service."""

from inventory_api.stock import (
    InsufficientStock,
    low_stock,
    receive,
    reorder_quantity,
    ship,
    total_units,
)

__version__ = "0.1.0"

__all__ = [
    "InsufficientStock",
    "__version__",
    "low_stock",
    "receive",
    "reorder_quantity",
    "ship",
    "total_units",
]
