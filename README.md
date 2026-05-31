# Birthday Contacts

Lists the birthdays from your device contacts, sorts them by next occurrence,
and notifies you on the day. Android-first; iOS support is scaffolded but not
yet finished.

## Features

- Reads birthdays directly from the device's Contacts — the contacts app is the
  source of truth. A local SQLite cache (Drift) is replaced wholesale on every
  sync so deletions in Contacts propagate.
- Background re-sync once a week via WorkManager (registered after the first
  contacts-permission grant).
- Local notification at 09:00 local time on each contact's birthday, scheduled
  yearly via `flutter_local_notifications` `zonedSchedule`.
- Material 3 in-app search over names (case- and diacritics-insensitive,
  token-prefix friendly — `an sm` finds "Anna Smith").
- Tap any row → opens that contact in the system Contacts app.
- **Android home-screen widget** showing birthdays in the next 7 days, built
  with Jetpack Glance, resizable, refreshed daily at ~00:05 plus on every sync.

## Architecture

Layered Flutter app with Riverpod for state management:

```
lib/
├── core/                                 # date math
├── features/
│   ├── birthdays/
│   │   ├── data/                         # ContactsSource, Drift cache, Repository
│   │   ├── application/                  # Riverpod providers, WorkManager dispatcher
│   │   ├── domain/                       # Birthday model
│   │   └── presentation/                 # list page + Material 3 search delegate
│   ├── notifications/                    # local notification scheduler
│   └── widget/                           # publishes widget payload to home_widget prefs
android/app/src/main/kotlin/.../widget/   # Glance AppWidget (BirthdayWidget + Receiver)
android/app/src/main/res/xml/             # AppWidgetProviderInfo (resize metadata)
```

Specs and decisions are documented in
[`/Users/florian/.claude/plans/check-how-to-setup-expressive-milner.md`](../../.claude/plans/check-how-to-setup-expressive-milner.md).

## Getting started

### Prerequisites (macOS)

```bash
brew install --cask flutter
brew install --cask android-commandlinetools openjdk@17
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" \
  "emulator" "system-images;android-34;google_apis;arm64-v8a"
yes | sdkmanager --licenses
flutter config --android-sdk /opt/homebrew/share/android-commandlinetools
flutter config --jdk-dir /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
flutter doctor
```

Android Studio is optional — the command-line tools above plus an AVD created
via `avdmanager` are sufficient.

### Run

```bash
flutter pub get
dart run build_runner build    # generates Drift code (*.g.dart)
flutter run -d <android-device-id>
```

### Tests + lint

```bash
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed .
```

### Build APK

```bash
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk
```

## Continuous integration

`.github/workflows/ci.yml` runs on every push to `main`:

1. `dart format --set-exit-if-changed .`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --debug` (Linux) — uploaded as `app-debug-apk`.
5. `flutter build ios --no-codesign --debug` (macOS) — uploaded as `app-ios-debug`.

### Releases

`.github/workflows/release.yml` runs when a tag matching `v*` is pushed
(e.g. `git tag v0.1.0 && git push origin v0.1.0`). It builds release APK +
AAB on Linux and a release `Runner.app.zip` on macOS (still `--no-codesign`
in CI), then attaches all three to a GitHub Release with auto-generated
notes. Android release builds currently use the debug signing config —
swap in a real keystore via repository secrets before publishing to the
Play Store.

## Known caveats

- **Android Gradle Plugin pinned to 8.7.3.** `home_widget` 0.9.2 ships a
  Gradle script that conditionally skips applying its Kotlin plugin on AGP 9,
  which leaves the plugin's classes unresolved. Bump back to AGP 9 once the
  plugin ships a Built-in-Kotlin compatible release.
- **iOS app + background sync + notifications run.** The **iOS home-screen
  widget is deferred** — WidgetKit needs a Widget Extension target that's
  easiest to scaffold in Xcode (`File → New Target → Widget Extension`).
  Running on a real iPhone requires opening `ios/Runner.xcworkspace` once to
  set the development team for signing; CI builds with `--no-codesign`.
- **Feb 29 birthdays** notify on **Mar 1** in non-leap years (documented in
  `lib/core/date_utils.dart`).
- Code generation is gitignored (`*.g.dart`); run `dart run build_runner build`
  after a fresh clone.
