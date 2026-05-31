import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Owns the [FlutterLocalNotificationsPlugin] singleton and channel setup
/// (SPEC-6, SPEC-8).
class NotificationService {
  NotificationService._(this.plugin);

  static const channelId = 'birthdays';
  static const channelName = 'Birthdays';
  static const channelDescription =
      'Notifies you when a contact has a birthday today.';

  final FlutterLocalNotificationsPlugin plugin;

  static Future<NotificationService> init() async {
    tz.initializeTimeZones();
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      ),
    );

    return NotificationService._(plugin);
  }

  /// Request POST_NOTIFICATIONS (Android 13+) and SCHEDULE_EXACT_ALARM
  /// (Android 14+). Best-effort; returns true if a notification can be posted.
  Future<bool> requestPermissions() async {
    final notif = await Permission.notification.request();
    // exact-alarm permission is opportunistic — the plugin falls back to
    // inexact scheduling if denied.
    await Permission.scheduleExactAlarm.request();
    return notif.isGranted;
  }

  static const androidDetails = AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: channelDescription,
    importance: Importance.high,
    priority: Priority.high,
  );

  static const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(),
  );
}
