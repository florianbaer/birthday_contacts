import Flutter
import UIKit
import UserNotifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register iOS BGTaskScheduler identifiers. These MUST match the Dart-side
    // `uniqueName` values in lib/features/birthdays/application/sync_service.dart
    // AND the BGTaskSchedulerPermittedIdentifiers entries in Info.plist.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "weekly_contacts_sync_v1",
      frequency: NSNumber(value: 7 * 24 * 60 * 60))
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "daily_widget_refresh_v1",
      frequency: NSNumber(value: 24 * 60 * 60))

    // Let flutter_local_notifications surface foreground notifications on iOS.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
