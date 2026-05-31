import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../../core/date_utils.dart';
import '../birthdays/domain/birthday.dart';

/// Maximum look-ahead the publisher emits. Each widget instance applies its own
/// (smaller) window natively, so we publish up to a full year and let the
/// Android widget filter by its per-instance "show within N days" setting.
const maxWindowDays = 365;

/// Builds the JSON-ready widget entries for [all] relative to [now]: maps each
/// birthday to its next occurrence, keeps those within [maxDays], and sorts by
/// next occurrence ascending (so today sorts first).
///
/// Pure and platform-channel-free so it can be unit-tested directly.
List<Map<String, Object?>> buildWidgetEntries(
  List<Birthday> all,
  DateTime now, {
  int maxDays = maxWindowDays,
}) {
  final upcoming =
      all
          .map((b) {
            final next = nextOccurrence(month: b.month, day: b.day, now: now);
            return _Entry(
              birthday: b,
              nextOccurrence: next,
              daysUntil: daysUntil(next, now),
              age: ageOnNextOccurrence(birthYear: b.year, nextOcc: next),
            );
          })
          .where((e) => e.daysUntil >= 0 && e.daysUntil <= maxDays)
          .toList()
        ..sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));
  return upcoming.map((e) => e.toJson()).toList(growable: false);
}

/// Pushes up to a year of upcoming birthdays to the Android home-screen widget.
/// The widget itself trims this to each instance's configured look-ahead window.
class WidgetPublisher {
  static const _payloadKey = 'widget_upcoming_week_json';
  static const _generatedAtKey = 'widget_generated_at_iso';
  static const _androidReceiver =
      'com.softwareation.birthday_contacts.widget.BirthdayWidgetReceiver';

  const WidgetPublisher();

  Future<void> publish(List<Birthday> all, {DateTime? now}) async {
    if (!Platform.isAndroid) return; // iOS widget not yet implemented.
    final clock = now ?? DateTime.now();
    final payload = jsonEncode(buildWidgetEntries(all, clock));
    await HomeWidget.saveWidgetData<String>(_payloadKey, payload);
    await HomeWidget.saveWidgetData<String>(
      _generatedAtKey,
      clock.toIso8601String(),
    );
    await HomeWidget.updateWidget(qualifiedAndroidName: _androidReceiver);
  }
}

class _Entry {
  _Entry({
    required this.birthday,
    required this.nextOccurrence,
    required this.daysUntil,
    required this.age,
  });

  final Birthday birthday;
  final DateTime nextOccurrence;
  final int daysUntil;
  final int? age;

  Map<String, Object?> toJson() => {
    'name': birthday.displayName,
    'monthDay': _formatMonthDay(nextOccurrence),
    'label': switch (daysUntil) {
      0 => 'Today',
      1 => 'Tomorrow',
      final d => 'in $d days',
    },
    'age': age,
    'daysUntil': daysUntil,
  };
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatMonthDay(DateTime d) => '${_months[d.month - 1]} ${d.day}';
