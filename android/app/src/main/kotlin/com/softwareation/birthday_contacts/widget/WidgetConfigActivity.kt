package com.softwareation.birthday_contacts.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.RadioGroup
import androidx.glance.appwidget.GlanceAppWidgetManager
import com.softwareation.birthday_contacts.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Configuration screen shown when the widget is added (and re-openable via the
 * widget's reconfigure affordance). Lets the user pick how many days ahead the
 * widget looks, stored per appWidgetId by [WidgetConfig].
 */
class WidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // If the user backs out, leave the widget un-added.
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.widget_config)

        val options = findViewById<RadioGroup>(R.id.options)
        val customDays = findViewById<EditText>(R.id.custom_days)

        // Custom field is only editable when its radio is selected.
        options.setOnCheckedChangeListener { _, checkedId ->
            customDays.isEnabled = checkedId == R.id.option_custom
            if (checkedId == R.id.option_custom) customDays.requestFocus()
        }

        prefill(WidgetConfig.read(this, appWidgetId), options, customDays)

        findViewById<Button>(R.id.save).setOnClickListener {
            save(selectedDays(options, customDays))
        }
    }

    /** Select the radio matching [days], or fall back to Custom with the value filled in. */
    private fun prefill(days: Int, options: RadioGroup, customDays: EditText) {
        when (days) {
            1 -> options.check(R.id.option_today)
            7 -> options.check(R.id.option_week)
            14 -> options.check(R.id.option_two_weeks)
            30 -> options.check(R.id.option_month)
            else -> {
                options.check(R.id.option_custom)
                customDays.setText(days.toString())
            }
        }
    }

    private fun selectedDays(options: RadioGroup, customDays: EditText): Int =
        when (options.checkedRadioButtonId) {
            R.id.option_today -> 1
            R.id.option_week -> 7
            R.id.option_two_weeks -> 14
            R.id.option_month -> 30
            R.id.option_custom ->
                WidgetConfig.clampDays(customDays.text.toString().toIntOrNull() ?: WidgetConfig.DEFAULT_DAYS)
            else -> WidgetConfig.DEFAULT_DAYS
        }

    private fun save(days: Int) {
        WidgetConfig.write(this, appWidgetId, days)

        // Re-render this widget instance with the new window.
        CoroutineScope(Dispatchers.Main).launch {
            val glanceId = GlanceAppWidgetManager(applicationContext).getGlanceIdBy(appWidgetId)
            BirthdayWidget().update(applicationContext, glanceId)
        }

        setResult(
            RESULT_OK,
            Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId),
        )
        finish()
    }
}
