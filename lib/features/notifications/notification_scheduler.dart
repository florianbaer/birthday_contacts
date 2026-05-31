import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../birthdays/domain/birthday.dart';
import '../../core/date_utils.dart';
import 'notification_service.dart';

/// Reconciles scheduled birthday notifications with the current cache (SPEC-7).
class NotificationScheduler {
  NotificationScheduler(this._service);

  final NotificationService _service;

  /// Cancel all previously scheduled notifications and reschedule one per
  /// birthday in [birthdays]. Using cancel-all keeps the logic simple and
  /// correct; the work is cheap (a few dozen rows at most).
  Future<void> reconcile(List<Birthday> birthdays, {DateTime? now}) async {
    final clock = now ?? DateTime.now();
    await _service.plugin.cancelAll();
    for (final b in birthdays) {
      final nextDate = nextOccurrence(month: b.month, day: b.day, now: clock);
      final scheduled = tz.TZDateTime(
        tz.local,
        nextDate.year,
        nextDate.month,
        nextDate.day,
        9, // 09:00 local
      );
      final age = ageOnNextOccurrence(birthYear: b.year, nextOcc: nextDate);
      final body = age != null
          ? '${b.displayName} turns $age today'
          : "${b.displayName}'s birthday is today";
      await _service.plugin.zonedSchedule(
        id: stableIdFor(b.contactId),
        title: 'Birthday today',
        body: body,
        scheduledDate: scheduled,
        notificationDetails: NotificationService.notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
  }

  /// Deterministic 31-bit id derived from contactId so cancels are stable
  /// without persisting a mapping.
  static int stableIdFor(String contactId) => contactId.hashCode & 0x7FFFFFFF;
}
