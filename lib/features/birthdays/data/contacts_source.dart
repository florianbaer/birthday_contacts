import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/birthday.dart';

/// Wraps [FlutterContacts] and exposes contacts with a birthday event (SPEC-2).
class ContactsSource {
  const ContactsSource();

  /// Request the contacts permission. Returns true if granted.
  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async => Permission.contacts.isGranted;

  /// Read every contact that has at least one birthday event.
  ///
  /// Contacts without a birthday are filtered out. If a contact has multiple
  /// birthday events the first is kept.
  Future<List<Birthday>> readBirthdays() async {
    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.name, ContactProperty.event},
    );
    final out = <Birthday>[];
    for (final c in contacts) {
      Event? birthday;
      for (final e in c.events) {
        if (e.label.label == EventLabel.birthday) {
          birthday = e;
          break;
        }
      }
      if (birthday == null) continue;
      final name = c.displayName;
      final id = c.id;
      if (id == null || name == null || name.isEmpty) continue;
      out.add(
        Birthday(
          contactId: id,
          displayName: name,
          month: birthday.month,
          day: birthday.day,
          year: birthday.year,
        ),
      );
    }
    return out;
  }
}
