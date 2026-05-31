import 'package:workmanager/workmanager.dart';

import '../../notifications/notification_scheduler.dart';
import '../../notifications/notification_service.dart';
import '../data/birthday_local_cache.dart';
import '../data/birthday_repository.dart';
import '../data/contacts_source.dart';

const weeklySyncTaskName = 'weekly_contacts_sync';
const weeklySyncUniqueName = 'weekly_contacts_sync_v1';

/// Entry point for the WorkManager isolate. MUST be a top-level function.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != weeklySyncTaskName) return true;
    try {
      final cache = BirthdayLocalCache();
      final service = await NotificationService.init();
      final scheduler = NotificationScheduler(service);
      final repo = BirthdayRepository(
        contacts: const ContactsSource(),
        cache: cache,
        scheduler: scheduler,
      );
      await repo.sync();
      await cache.close();
      return true;
    } catch (_) {
      // Permission revoked or transient failure — let WM retry next cycle.
      return true;
    }
  });
}

/// Registers the weekly sync. Idempotent thanks to [ExistingPeriodicWorkPolicy.keep].
Future<void> registerWeeklySync() async {
  await Workmanager().initialize(backgroundDispatcher);
  await Workmanager().registerPeriodicTask(
    weeklySyncUniqueName,
    weeklySyncTaskName,
    frequency: const Duration(days: 7),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}
