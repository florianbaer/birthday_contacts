import 'package:birthday_contacts/features/birthdays/domain/birthday.dart';
import 'package:birthday_contacts/features/widget/widget_publisher.dart';
import 'package:flutter_test/flutter_test.dart';

Birthday _b(String name, {required int month, required int day, int? year}) =>
    Birthday(
      contactId: name,
      displayName: name,
      month: month,
      day: day,
      year: year,
    );

void main() {
  // Fixed "now": 2026-06-14 (2026 is not a leap year).
  final now = DateTime(2026, 6, 14, 9, 30);

  group('buildWidgetEntries', () {
    test('empty input yields empty list', () {
      expect(buildWidgetEntries([], now), isEmpty);
    });

    test('keeps entries up to maxDays and drops those beyond', () {
      final entries = buildWidgetEntries(
        [
          _b('Today', month: 6, day: 14), // daysUntil 0
          _b('Edge', month: 6, day: 14), // see maxDays test below
          _b('Yesterday', month: 6, day: 13), // wraps to next year → > maxDays
        ],
        now,
        maxDays: 5,
      );
      final names = entries.map((e) => e['name']).toList();
      expect(names, containsAll(['Today', 'Edge']));
      expect(names, isNot(contains('Yesterday')));
    });

    test('boundary: daysUntil == maxDays included, maxDays+1 excluded', () {
      // now = Jun 14. +5 days = Jun 19, +6 days = Jun 20.
      final entries = buildWidgetEntries(
        [_b('In5', month: 6, day: 19), _b('In6', month: 6, day: 20)],
        now,
        maxDays: 5,
      );
      final names = entries.map((e) => e['name']).toList();
      expect(names, contains('In5'));
      expect(names, isNot(contains('In6')));
    });

    test('sorted by next occurrence ascending, today first', () {
      final entries = buildWidgetEntries(
        [
          _b('In3', month: 6, day: 17),
          _b('Today', month: 6, day: 14),
          _b('In1', month: 6, day: 15),
        ],
        now,
        maxDays: 30,
      );
      expect(entries.map((e) => e['name']).toList(), ['Today', 'In1', 'In3']);
    });

    test('labels: Today / Tomorrow / in N days', () {
      final entries = buildWidgetEntries(
        [
          _b('Today', month: 6, day: 14),
          _b('Tomorrow', month: 6, day: 15),
          _b('Later', month: 6, day: 17),
        ],
        now,
        maxDays: 30,
      );
      final byName = {for (final e in entries) e['name']: e['label']};
      expect(byName['Today'], 'Today');
      expect(byName['Tomorrow'], 'Tomorrow');
      expect(byName['Later'], 'in 3 days');
    });

    test('age populated when year known, null otherwise', () {
      final entries = buildWidgetEntries(
        [
          _b('WithYear', month: 6, day: 14, year: 1990),
          _b('NoYear', month: 6, day: 14),
        ],
        now,
        maxDays: 30,
      );
      final byName = {for (final e in entries) e['name']: e['age']};
      expect(byName['WithYear'], 36); // turns 36 in 2026
      expect(byName['NoYear'], isNull);
    });

    test('Feb 29 in non-leap year falls forward to Mar 1', () {
      final janNow = DateTime(2026, 1, 10); // non-leap year
      final entries = buildWidgetEntries(
        [_b('Leapling', month: 2, day: 29)],
        janNow,
        maxDays: 365,
      );
      expect(entries.single['monthDay'], 'Mar 1');
    });
  });
}
