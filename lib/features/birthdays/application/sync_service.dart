import 'package:workmanager/workmanager.dart';

import '../../notifications/notification_scheduler.dart';
import '../../notifications/notification_service.dart';
import '../../widget/widget_publisher.dart';
import '../data/birthday_local_cache.dart';
import '../data/birthday_repository.dart';
import '../data/contacts_source.dart';

const weeklySyncTaskName = 'weekly_contacts_sync';
const weeklySyncUniqueName = 'weekly_contacts_sync_v1';
const dailyWidgetRefreshTaskName = 'daily_widget_refresh';
const dailyWidgetRefreshUniqueName = 'daily_widget_refresh_v1';

/// Entry point for the WorkManager isolate. MUST be a top-level function.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, _) async {
    try {
      switch (task) {
        case weeklySyncTaskName:
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
        case dailyWidgetRefreshTaskName:
          // Re-render widget labels only. No contacts read needed — works
          // even if permission was revoked. SPEC-W3.
          final cache = BirthdayLocalCache();
          final all = await cache.readAll();
          await const WidgetPublisher().publish(all);
          await cache.close();
          return true;
        default:
          return true;
      }
    } catch (_) {
      // Permission revoked or transient failure — let WM retry next cycle.
      return true;
    }
  });
}

/// Registers the weekly contacts sync and the daily widget refresh.
/// Idempotent thanks to [ExistingPeriodicWorkPolicy.keep].
Future<void> registerBackgroundJobs() async {
  await Workmanager().initialize(backgroundDispatcher);
  await Workmanager().registerPeriodicTask(
    weeklySyncUniqueName,
    weeklySyncTaskName,
    frequency: const Duration(days: 7),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
  await Workmanager().registerPeriodicTask(
    dailyWidgetRefreshUniqueName,
    dailyWidgetRefreshTaskName,
    frequency: const Duration(days: 1),
    initialDelay: _delayUntilNextMidnightPlus5Min(DateTime.now()),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}

Duration _delayUntilNextMidnightPlus5Min(DateTime now) {
  final next = DateTime(now.year, now.month, now.day + 1, 0, 5);
  return next.difference(now);
}
