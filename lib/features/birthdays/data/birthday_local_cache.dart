import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/birthday.dart';

part 'birthday_local_cache.g.dart';

class BirthdayRows extends Table {
  TextColumn get contactId => text()();
  TextColumn get displayName => text()();
  IntColumn get month => integer()();
  IntColumn get day => integer()();
  IntColumn get year => integer().nullable()();

  @override
  Set<Column> get primaryKey => {contactId};
}

/// Local SQLite cache implementing SPEC-4. Replaced wholesale on each sync —
/// contacts is the source of truth.
@DriftDatabase(tables: [BirthdayRows])
class BirthdayLocalCache extends _$BirthdayLocalCache {
  BirthdayLocalCache() : super(driftDatabase(name: 'birthday_cache'));

  @override
  int get schemaVersion => 1;

  Future<List<Birthday>> readAll() async {
    final rows = await select(birthdayRows).get();
    return rows
        .map(
          (r) => Birthday(
            contactId: r.contactId,
            displayName: r.displayName,
            month: r.month,
            day: r.day,
            year: r.year,
          ),
        )
        .toList();
  }

  /// Atomically replace the cache contents with [birthdays] (SPEC-4).
  Future<void> replaceAll(List<Birthday> birthdays) async {
    await transaction(() async {
      await delete(birthdayRows).go();
      await batch((b) {
        b.insertAll(
          birthdayRows,
          birthdays.map(
            (b) => BirthdayRowsCompanion.insert(
              contactId: b.contactId,
              displayName: b.displayName,
              month: b.month,
              day: b.day,
              year: Value(b.year),
            ),
          ),
        );
      });
    });
  }

  Stream<List<Birthday>> watchAll() {
    return select(birthdayRows).watch().map(
      (rows) => rows
          .map(
            (r) => Birthday(
              contactId: r.contactId,
              displayName: r.displayName,
              month: r.month,
              day: r.day,
              year: r.year,
            ),
          )
          .toList(),
    );
  }
}
