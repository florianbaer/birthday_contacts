import 'package:shared_preferences/shared_preferences.dart';

import '../../notifications/notification_scheduler.dart';
import '../domain/birthday.dart';
import 'birthday_local_cache.dart';
import 'contacts_source.dart';

/// Orchestrates a sync from the device contacts into the local cache and
/// reschedules notifications (SPEC-5).
class BirthdayRepository {
  BirthdayRepository({
    required this.contacts,
    required this.cache,
    required this.scheduler,
  });

  final ContactsSource contacts;
  final BirthdayLocalCache cache;
  final NotificationScheduler scheduler;

  static const _lastSyncedKey = 'last_synced_at';

  Stream<List<Birthday>> watchUpcoming() => cache.watchAll();

  Future<DateTime?> lastSyncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_lastSyncedKey);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  /// Sync from contacts. Throws [_PermissionDeniedException] when the contacts
  /// permission is not granted.
  Future<void> sync() async {
    if (!await contacts.hasPermission()) {
      throw const PermissionDeniedException();
    }
    final fresh = await contacts.readBirthdays();
    await cache.replaceAll(fresh);
    await scheduler.reconcile(fresh);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncedKey, DateTime.now().toIso8601String());
  }
}

class PermissionDeniedException implements Exception {
  const PermissionDeniedException();
  @override
  String toString() => 'Contacts permission denied';
}
