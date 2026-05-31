import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/birthdays/application/providers.dart';
import 'features/birthdays/presentation/birthday_list_page.dart';
import 'features/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = await NotificationService.init();
  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const BirthdayContactsApp(),
    ),
  );
}

class BirthdayContactsApp extends StatelessWidget {
  const BirthdayContactsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birthday Contacts',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const BirthdayListPage(),
    );
  }
}
