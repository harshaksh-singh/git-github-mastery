package com.example.inventory;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class PriceCalculatorTest {

    @Test
    void lineTotalMultipliesAndRounds() {
        assertEquals(new BigDecimal("59.97"), PriceCalculator.lineTotal(new BigDecimal("19.99"), 3));
        assertEquals(new BigDecimal("0.00"), PriceCalculator.lineTotal(new BigDecimal("19.99"), 0));
    }

    @Test
    void lineTotalRejectsNegativeInput() {
        assertThrows(IllegalArgumentException.class,
                () -> PriceCalculator.lineTotal(new BigDecimal("-1.00"), 1));
        assertThrows(IllegalArgumentException.class,
                () -> PriceCalculator.lineTotal(new BigDecimal("1.00"), -1));
    }

    @Test
    void applyDiscountReducesTheAmount() {
        assertEquals(new BigDecimal("90.00"), PriceCalculator.applyDiscount(new BigDecimal("100.00"), 10));
        assertEquals(new BigDecimal("0.00"), PriceCalculator.applyDiscount(new BigDecimal("100.00"), 100));
        assertEquals(new BigDecimal("16.99"), PriceCalculator.applyDiscount(new BigDecimal("19.99"), 15));
    }

    @Test
    void applyDiscountRejectsPercentOutsideRange() {
        assertThrows(IllegalArgumentException.class,
                () -> PriceCalculator.applyDiscount(new BigDecimal("100.00"), 101));
        assertThrows(IllegalArgumentException.class,
                () -> PriceCalculator.applyDiscount(new BigDecimal("100.00"), -1));
    }
}
