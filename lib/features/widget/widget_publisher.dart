import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../../core/date_utils.dart';
import '../birthdays/domain/birthday.dart';

/// Pushes the next-7-days subset of birthdays to the Android home-screen
/// widget. See SPEC-W1/W2 in the plan file.
class WidgetPublisher {
  static const _payloadKey = 'widget_upcoming_week_json';
  static const _generatedAtKey = 'widget_generated_at_iso';
  static const _androidReceiver =
      'com.softwareation.birthday_contacts.widget.BirthdayWidgetReceiver';

  const WidgetPublisher();

  Future<void> publish(List<Birthday> all, {DateTime? now}) async {
    if (!Platform.isAndroid) return; // iOS widget not yet implemented.
    final clock = now ?? DateTime.now();
    final upcoming =
        all
            .map((b) {
              final next = nextOccurrence(
                month: b.month,
                day: b.day,
                now: clock,
              );
              return _Entry(
                birthday: b,
                nextOccurrence: next,
                daysUntil: daysUntil(next, clock),
                age: ageOnNextOccurrence(birthYear: b.year, nextOcc: next),
              );
            })
            .where((e) => e.daysUntil >= 0 && e.daysUntil <= 6)
            .toList()
          ..sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));

    final payload = jsonEncode(
      upcoming.map((e) => e.toJson()).toList(growable: false),
    );
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
