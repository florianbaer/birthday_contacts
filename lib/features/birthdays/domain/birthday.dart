import 'package:flutter/foundation.dart';

/// A contact's birthday extracted from the device contacts (SPEC-2).
///
/// The combination of [contactId] is treated as a stable identity; [year] may
/// be null because many contacts only record month/day.
@immutable
class Birthday {
  const Birthday({
    required this.contactId,
    required this.displayName,
    required this.month,
    required this.day,
    this.year,
  });

  final String contactId;
  final String displayName;
  final int month; // 1..12
  final int day; // 1..31
  final int? year;

  Birthday copyWith({
    String? contactId,
    String? displayName,
    int? month,
    int? day,
    int? year,
    bool clearYear = false,
  }) => Birthday(
    contactId: contactId ?? this.contactId,
    displayName: displayName ?? this.displayName,
    month: month ?? this.month,
    day: day ?? this.day,
    year: clearYear ? null : (year ?? this.year),
  );

  @override
  bool operator ==(Object other) =>
      other is Birthday &&
      other.contactId == contactId &&
      other.displayName == displayName &&
      other.month == month &&
      other.day == day &&
      other.year == year;

  @override
  int get hashCode => Object.hash(contactId, displayName, month, day, year);
}
