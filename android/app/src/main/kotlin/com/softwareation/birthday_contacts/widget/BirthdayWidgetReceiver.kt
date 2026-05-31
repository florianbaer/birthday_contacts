package com.softwareation.birthday_contacts.widget

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class BirthdayWidgetReceiver : HomeWidgetGlanceWidgetReceiver<BirthdayWidget>() {
    override val glanceAppWidget: BirthdayWidget = BirthdayWidget()
}
