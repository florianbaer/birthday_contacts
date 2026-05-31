package com.softwareation.birthday_contacts.widget

import android.content.Context

/**
 * Per-widget-instance look-ahead configuration: "show birthdays within N days".
 *
 * Stored in a dedicated SharedPreferences file keyed by appWidgetId rather than
 * via Glance's `updateAppWidgetState`, because this widget's state definition is
 * home_widget's shared (cross-instance) store. See the plan file for the trade-off.
 */
object WidgetConfig {
    private const val PREFS_NAME = "BirthdayWidgetConfig"
    private const val KEY_PREFIX = "lookahead_days_"

    const val DEFAULT_DAYS = 7
    const val MIN_DAYS = 1
    const val MAX_DAYS = 365

    fun read(context: Context, appWidgetId: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getInt(KEY_PREFIX + appWidgetId, DEFAULT_DAYS)
    }

    fun write(context: Context, appWidgetId: Int, days: Int) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putInt(KEY_PREFIX + appWidgetId, clampDays(days))
            .apply()
    }

    fun clear(context: Context, appWidgetId: Int) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_PREFIX + appWidgetId)
            .apply()
    }

    /** Clamp an arbitrary (possibly user-typed) value into the supported range. */
    fun clampDays(days: Int): Int = days.coerceIn(MIN_DAYS, MAX_DAYS)
}
