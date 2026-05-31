package com.softwareation.birthday_contacts.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.unit.ColorProvider
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import com.softwareation.birthday_contacts.MainActivity
import com.softwareation.birthday_contacts.R
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity
import org.json.JSONArray

class BirthdayWidget : GlanceAppWidget() {
    override val stateDefinition: GlanceStateDefinition<HomeWidgetGlanceState> =
        HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        val lookaheadDays = WidgetConfig.read(context, appWidgetId)
        provideContent {
            GlanceTheme {
                Content(context, currentState(), lookaheadDays)
            }
        }
    }

    @Composable
    private fun Content(context: Context, state: HomeWidgetGlanceState, lookaheadDays: Int) {
        val json = state.preferences.getString("widget_upcoming_week_json", "[]") ?: "[]"
        val entries = visibleEntries(parseEntries(json), lookaheadDays)

        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(GlanceTheme.colors.widgetBackground)
                .cornerRadius(24.dp)
                .padding(14.dp)
                .clickable(actionStartActivity<MainActivity>(context)),
        ) {
            when {
                entries.isEmpty() -> EmptyState(lookaheadDays)
                LocalSize.current.height.value < 140f -> CompactView(entries.first())
                else -> FullView(entries)
            }
        }
    }

    @Composable
    private fun EmptyState(lookaheadDays: Int) {
        val text = when (lookaheadDays) {
            1 -> "No birthdays today"
            else -> "No birthdays in the next $lookaheadDays days"
        }
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            CakeIcon(size = 28.dp, tint = GlanceTheme.colors.primary)
            Spacer(GlanceModifier.height(8.dp))
            Text(
                text = text,
                style = TextStyle(
                    color = GlanceTheme.colors.onSurfaceVariant,
                    fontSize = 13.sp,
                    textAlign = TextAlign.Center,
                ),
            )
        }
    }

    @Composable
    private fun CompactView(e: Entry) {
        val isToday = e.daysUntil == 0
        Row(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Avatar(name = e.name, highlighted = isToday)
            Spacer(GlanceModifier.width(10.dp))
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(
                    text = if (isToday) "🎉 ${e.name}" else e.name,
                    style = TextStyle(
                        color = GlanceTheme.colors.onSurface,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 1,
                )
                Spacer(GlanceModifier.height(2.dp))
                Text(
                    text = secondaryLabel(e),
                    style = TextStyle(
                        color = GlanceTheme.colors.primary,
                        fontSize = 12.sp,
                        fontWeight = if (isToday) FontWeight.Bold else FontWeight.Medium,
                    ),
                    maxLines = 1,
                )
            }
            DateBadge(monthDay = e.monthDay, today = isToday)
        }
    }

    @Composable
    private fun FullView(entries: List<Entry>) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Header(count = entries.size)
            Spacer(GlanceModifier.height(8.dp))
            LazyColumn(modifier = GlanceModifier.fillMaxWidth()) {
                items(entries, itemId = { it.name.hashCode().toLong() }) { entry ->
                    Column(modifier = GlanceModifier.fillMaxWidth()) {
                        EntryRow(entry)
                        Divider()
                    }
                }
            }
        }
    }

    @Composable
    private fun Header(count: Int) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            CakeIcon(size = 18.dp, tint = GlanceTheme.colors.primary)
            Spacer(GlanceModifier.width(8.dp))
            Text(
                text = "Birthdays",
                style = TextStyle(
                    color = GlanceTheme.colors.onSurface,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                ),
            )
            Spacer(GlanceModifier.defaultWeight())
            Text(
                text = "$count",
                style = TextStyle(
                    color = GlanceTheme.colors.onSurfaceVariant,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                ),
            )
        }
    }

    @Composable
    private fun EntryRow(e: Entry) {
        val isToday = e.daysUntil == 0
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(vertical = 4.dp)
                .background(
                    if (isToday) GlanceTheme.colors.primaryContainer
                    else ColorProvider(Color.Transparent)
                )
                .cornerRadius(14.dp)
                .padding(horizontal = 8.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Avatar(name = e.name, highlighted = isToday)
            Spacer(GlanceModifier.width(10.dp))
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(
                    text = if (isToday) "🎉 ${e.name}" else e.name,
                    style = TextStyle(
                        color = if (isToday) GlanceTheme.colors.onPrimaryContainer
                        else GlanceTheme.colors.onSurface,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 1,
                )
                Spacer(GlanceModifier.height(2.dp))
                Text(
                    text = secondaryLabel(e),
                    style = TextStyle(
                        color = if (isToday) GlanceTheme.colors.onPrimaryContainer
                        else GlanceTheme.colors.primary,
                        fontSize = 11.sp,
                        fontWeight = if (isToday) FontWeight.Bold else FontWeight.Medium,
                    ),
                    maxLines = 1,
                )
            }
            DateBadge(monthDay = e.monthDay, today = isToday)
        }
    }

    @Composable
    private fun Divider() {
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .height(1.dp)
                .padding(horizontal = 8.dp)
                .background(GlanceTheme.colors.outline),
        ) {}
    }

    @Composable
    private fun DateBadge(monthDay: String, today: Boolean) {
        // "Jun 14" → month "Jun" + day "14"
        val parts = monthDay.split(' ', limit = 2)
        val month = parts.getOrNull(0)?.uppercase() ?: ""
        val day = parts.getOrNull(1) ?: ""
        Column(
            modifier = GlanceModifier
                .background(
                    if (today) GlanceTheme.colors.primary
                    else GlanceTheme.colors.secondaryContainer
                )
                .cornerRadius(12.dp)
                .padding(horizontal = 10.dp, vertical = 4.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = month,
                style = TextStyle(
                    color = if (today) GlanceTheme.colors.onPrimary
                    else GlanceTheme.colors.onSecondaryContainer,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                ),
            )
            Text(
                text = day,
                style = TextStyle(
                    color = if (today) GlanceTheme.colors.onPrimary
                    else GlanceTheme.colors.onSecondaryContainer,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                ),
            )
        }
    }

    @Composable
    private fun Avatar(name: String, highlighted: Boolean = false) {
        val palette = listOf(
            0xFFEF5350L, 0xFFAB47BCL, 0xFF5C6BC0L, 0xFF26A69AL,
            0xFFFFA726L, 0xFF8D6E63L, 0xFF26C6DAL, 0xFF66BB6AL,
        )
        val bg = Color(palette[(name.hashCode() and 0x7FFFFFFF) % palette.size])
        Box(
            modifier = GlanceModifier
                .size(36.dp)
                .background(if (highlighted) GlanceTheme.colors.primary else ColorProvider(bg))
                .cornerRadius(18.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = initials(name),
                style = TextStyle(
                    color = if (highlighted) GlanceTheme.colors.onPrimary
                    else ColorProvider(Color.White),
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                ),
            )
        }
    }

    @Composable
    private fun CakeIcon(size: androidx.compose.ui.unit.Dp, tint: ColorProvider) {
        Image(
            provider = ImageProvider(R.drawable.ic_cake),
            contentDescription = null,
            modifier = GlanceModifier.size(size),
            colorFilter = ColorFilter.tint(tint),
        )
    }

    private fun initials(name: String): String {
        val parts = name.trim().split(Regex("\\s+")).filter { it.isNotEmpty() }
        if (parts.isEmpty()) return "?"
        if (parts.size == 1) return parts[0].first().uppercaseChar().toString()
        return "${parts.first().first().uppercaseChar()}${parts.last().first().uppercaseChar()}"
    }

}

internal data class Entry(
    val name: String,
    val monthDay: String,
    val label: String,
    val age: Int?,
    val daysUntil: Int,
)

/**
 * Trim the published (up to a year) superset to this instance's window:
 * a look-ahead of N days shows daysUntil in 0..N-1 (so N=7 == today + 6).
 */
internal fun visibleEntries(entries: List<Entry>, lookaheadDays: Int): List<Entry> =
    entries.filter { it.daysUntil in 0..(lookaheadDays - 1) }

/** Secondary line: emphasizes today and appends the age when known. */
internal fun secondaryLabel(e: Entry): String {
    val label = if (e.daysUntil == 0) "Today!" else e.label
    return if (e.age != null) "$label • turns ${e.age}" else label
}

internal fun parseEntries(json: String): List<Entry> {
    return try {
        val arr = JSONArray(json)
        buildList(arr.length()) {
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                add(
                    Entry(
                        name = o.optString("name"),
                        monthDay = o.optString("monthDay"),
                        label = o.optString("label"),
                        age = if (o.isNull("age")) null else o.optInt("age"),
                        daysUntil = if (o.isNull("daysUntil")) 99 else o.optInt("daysUntil"),
                    ),
                )
            }
        }
    } catch (_: Throwable) {
        emptyList()
    }
}
