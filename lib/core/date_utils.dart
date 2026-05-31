/// Compute the next occurrence of a (month, day) anniversary relative to [now].
///
/// If today matches, today counts as the next occurrence.
/// Feb 29 in a non-leap year falls forward to Mar 1.
DateTime nextOccurrence({
  required int month,
  required int day,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  DateTime candidate = _safeDate(now.year, month, day);
  if (candidate.isBefore(today)) {
    candidate = _safeDate(now.year + 1, month, day);
  }
  return candidate;
}

/// Days from [now] (date-only) until [target] (date-only). 0 == today.
int daysUntil(DateTime target, DateTime now) {
  final t = DateTime(target.year, target.month, target.day);
  final n = DateTime(now.year, now.month, now.day);
  return t.difference(n).inDays;
}

/// Age the person turns on the next occurrence, if their birth year is known.
int? ageOnNextOccurrence({required int? birthYear, required DateTime nextOcc}) {
  if (birthYear == null) return null;
  return nextOcc.year - birthYear;
}

DateTime _safeDate(int year, int month, int day) {
  // Feb 29 → Mar 1 in non-leap years (documented behavior).
  if (month == 2 && day == 29 && !_isLeap(year)) {
    return DateTime(year, 3, 1);
  }
  return DateTime(year, month, day);
}

bool _isLeap(int year) => (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
