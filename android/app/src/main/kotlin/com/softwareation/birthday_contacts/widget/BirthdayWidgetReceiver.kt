package com.softwareation.birthday_contacts.widget

import android.content.Context
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class BirthdayWidgetReceiver : HomeWidgetGlanceWidgetReceiver<BirthdayWidget>() {
    override val glanceAppWidget: BirthdayWidget = BirthdayWidget()

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        // Drop each removed instance's per-widget look-ahead setting.
        appWidgetIds.forEach { WidgetConfig.clear(context, it) }
        super.onDeleted(context, appWidgetIds)
    }
}
