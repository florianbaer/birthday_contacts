package com.softwareation.birthday_contacts.widget

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetWindowTest {

    private fun entry(name: String, daysUntil: Int) =
        Entry(name = name, monthDay = "Jun 14", label = "", age = null, daysUntil = daysUntil)

    private val sample = listOf(
        entry("Today", 0),
        entry("In6", 6),
        entry("In7", 7),
        entry("In10", 10),
    )

    @Test
    fun lookahead1ShowsOnlyToday() {
        assertEquals(listOf("Today"), visibleEntries(sample, 1).map { it.name })
    }

    @Test
    fun lookahead7ShowsThroughDay6ButNotDay7() {
        assertEquals(listOf("Today", "In6"), visibleEntries(sample, 7).map { it.name })
    }

    @Test
    fun lookahead14IncludesDay10() {
        assertEquals(
            listOf("Today", "In6", "In7", "In10"),
            visibleEntries(sample, 14).map { it.name },
        )
    }

    @Test
    fun emptyListStaysEmpty() {
        assertEquals(emptyList<Entry>(), visibleEntries(emptyList(), 7))
    }

    @Test
    fun secondaryLabelEmphasizesTodayAndAppendsAge() {
        assertEquals("Today!", secondaryLabel(entry("A", 0)))
        assertEquals(
            "Today! • turns 30",
            secondaryLabel(Entry("A", "Jun 14", "Today", 30, 0)),
        )
        assertEquals(
            "in 3 days • turns 30",
            secondaryLabel(Entry("A", "Jun 17", "in 3 days", 30, 3)),
        )
        assertEquals("in 3 days", secondaryLabel(Entry("A", "Jun 17", "in 3 days", null, 3)))
    }
}
