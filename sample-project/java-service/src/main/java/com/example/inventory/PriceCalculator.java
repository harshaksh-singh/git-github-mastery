package com.example.inventory;

import java.math.BigDecimal;
import java.math.RoundingMode;

/** Price arithmetic for inventory lines. Amounts are BigDecimal, never double. */
public final class PriceCalculator {

    private PriceCalculator() {
    }

    /** Returns unitPrice times quantity, rounded to two decimal places. */
    public static BigDecimal lineTotal(BigDecimal unitPrice, int quantity) {
        if (unitPrice == null) {
            throw new IllegalArgumentException("unitPrice must not be null");
        }
        if (unitPrice.signum() < 0) {
            throw new IllegalArgumentException("unitPrice must not be negative");
        }
        if (quantity < 0) {
            throw new IllegalArgumentException("quantity must not be negative");
        }
        return unitPrice.multiply(BigDecimal.valueOf(quantity)).setScale(2, RoundingMode.HALF_UP);
    }

    /** Returns amount reduced by percent (0 to 100), rounded to two decimal places. */
    public static BigDecimal applyDiscount(BigDecimal amount, int percent) {
        if (amount == null) {
            throw new IllegalArgumentException("amount must not be null");
        }
        if (percent < 0 || percent > 100) {
            throw new IllegalArgumentException("percent must be between 0 and 100");
        }
        BigDecimal factor = BigDecimal.valueOf(100 - percent).divide(BigDecimal.valueOf(100));
        return amount.multiply(factor).setScale(2, RoundingMode.HALF_UP);
    }
}
