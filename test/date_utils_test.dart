import 'package:birthday_contacts/core/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextOccurrence', () {
    test('today returns today', () {
      final now = DateTime(2026, 6, 14);
      expect(
        nextOccurrence(month: 6, day: 14, now: now),
        DateTime(2026, 6, 14),
      );
    });

    test('past date wraps to next year', () {
      final now = DateTime(2026, 6, 14);
      expect(nextOccurrence(month: 1, day: 1, now: now), DateTime(2027, 1, 1));
    });

    test('future date stays in current year', () {
      final now = DateTime(2026, 6, 14);
      expect(
        nextOccurrence(month: 12, day: 31, now: now),
        DateTime(2026, 12, 31),
      );
    });

    test('Feb 29 in non-leap year falls forward to Mar 1', () {
      final now = DateTime(2026, 1, 10); // 2026 is not a leap year
      expect(nextOccurrence(month: 2, day: 29, now: now), DateTime(2026, 3, 1));
    });

    test('Feb 29 in leap year stays Feb 29', () {
      final now = DateTime(2028, 1, 10); // 2028 is a leap year
      expect(
        nextOccurrence(month: 2, day: 29, now: now),
        DateTime(2028, 2, 29),
      );
    });
  });

  group('daysUntil', () {
    test('today = 0', () {
      expect(daysUntil(DateTime(2026, 6, 14), DateTime(2026, 6, 14, 23)), 0);
    });
    test('tomorrow = 1', () {
      expect(daysUntil(DateTime(2026, 6, 15), DateTime(2026, 6, 14)), 1);
    });
  });

  group('ageOnNextOccurrence', () {
    test('null year → null age', () {
      expect(
        ageOnNextOccurrence(birthYear: null, nextOcc: DateTime(2026, 6, 14)),
        null,
      );
    });
    test('returns next year minus birth year', () {
      expect(
        ageOnNextOccurrence(birthYear: 1990, nextOcc: DateTime(2026, 6, 14)),
        36,
      );
    });
  });
}
