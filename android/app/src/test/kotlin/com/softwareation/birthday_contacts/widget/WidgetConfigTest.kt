package com.softwareation.birthday_contacts.widget

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetConfigTest {

    @Test
    fun clampsBelowMinimumToOne() {
        assertEquals(1, WidgetConfig.clampDays(0))
        assertEquals(1, WidgetConfig.clampDays(-5))
    }

    @Test
    fun clampsAboveMaximumTo365() {
        assertEquals(365, WidgetConfig.clampDays(9999))
        assertEquals(365, WidgetConfig.clampDays(366))
    }

    @Test
    fun passesThroughValidValues() {
        assertEquals(7, WidgetConfig.clampDays(7))
        assertEquals(30, WidgetConfig.clampDays(30))
        assertEquals(1, WidgetConfig.clampDays(1))
        assertEquals(365, WidgetConfig.clampDays(365))
    }
}
