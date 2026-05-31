import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/notification_scheduler.dart';
import '../../notifications/notification_service.dart';
import '../data/birthday_local_cache.dart';
import '../data/birthday_repository.dart';
import '../data/contacts_source.dart';
import '../domain/birthday.dart';
import '../../../core/date_utils.dart';

final contactsSourceProvider = Provider((_) => const ContactsSource());

final birthdayCacheProvider = Provider<BirthdayLocalCache>((ref) {
  final cache = BirthdayLocalCache();
  ref.onDispose(cache.close);
  return cache;
});

/// Set by [main] after [NotificationService.init].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('Override in ProviderScope at app start');
});

final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => NotificationScheduler(ref.watch(notificationServiceProvider)),
);

final birthdayRepositoryProvider = Provider<BirthdayRepository>(
  (ref) => BirthdayRepository(
    contacts: ref.watch(contactsSourceProvider),
    cache: ref.watch(birthdayCacheProvider),
    scheduler: ref.watch(notificationSchedulerProvider),
  ),
);

/// Birthdays from cache, sorted by next occurrence ascending (SPEC-3).
final upcomingBirthdaysProvider = StreamProvider<List<UpcomingBirthday>>(
  (ref) => ref.watch(birthdayRepositoryProvider).watchUpcoming().map((list) {
    final now = DateTime.now();
    final enriched = list.map((b) {
      final next = nextOccurrence(month: b.month, day: b.day, now: now);
      return UpcomingBirthday(
        birthday: b,
        nextOccurrence: next,
        daysUntil: daysUntil(next, now),
        ageTurning: ageOnNextOccurrence(birthYear: b.year, nextOcc: next),
      );
    }).toList()..sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));
    return enriched;
  }),
);

final lastSyncedAtProvider = FutureProvider<DateTime?>(
  (ref) => ref.watch(birthdayRepositoryProvider).lastSyncedAt(),
);

class UpcomingBirthday {
  const UpcomingBirthday({
    required this.birthday,
    required this.nextOccurrence,
    required this.daysUntil,
    required this.ageTurning,
  });

  final Birthday birthday;
  final DateTime nextOccurrence;
  final int daysUntil;
  final int? ageTurning;
}
