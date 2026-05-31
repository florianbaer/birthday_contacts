import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';

/// Material 3 search experience over the cached upcoming-birthday list.
///
/// Substring + token-prefix match on the display name, case- and
/// diacritics-insensitive. Empty query → show everything sorted by next
/// occurrence (same as the main list).
class BirthdaySearchDelegate extends SearchDelegate<UpcomingBirthday?> {
  BirthdaySearchDelegate(this._all) : super(searchFieldLabel: 'Search names');

  final List<UpcomingBirthday> _all;

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: 'Clear',
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    tooltip: 'Back',
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildSuggestions(BuildContext context) => _resultList(context);

  @override
  Widget buildResults(BuildContext context) => _resultList(context);

  Widget _resultList(BuildContext context) {
    final results = _filter(query);
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            query.isEmpty ? 'Type to search' : 'No matches for "$query"',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) {
        final b = results[i];
        final date = DateFormat.MMMd().format(b.nextOccurrence);
        final until = switch (b.daysUntil) {
          0 => 'Today',
          1 => 'Tomorrow',
          final d => 'in $d days',
        };
        return ListTile(
          leading: CircleAvatar(child: Text(_initials(b.birthday.displayName))),
          title: _Highlighted(text: b.birthday.displayName, query: query),
          subtitle: Text('$date • $until'),
          onTap: () => close(context, b),
        );
      },
    );
  }

  List<UpcomingBirthday> _filter(String raw) {
    final q = _normalize(raw);
    if (q.isEmpty) return _all;
    return _all.where((b) {
      final name = _normalize(b.birthday.displayName);
      if (name.contains(q)) return true;
      // Token-prefix match: "an sm" → "Anna Smith".
      final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
      final nameTokens = name.split(RegExp(r'\s+'));
      return tokens.every((t) => nameTokens.any((n) => n.startsWith(t)));
    }).toList();
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

/// Lowercase + strip common Latin diacritics so "Müller" matches "muller".
String _normalize(String s) {
  final lower = s.toLowerCase().trim();
  final buf = StringBuffer();
  for (final c in lower.runes) {
    buf.writeCharCode(_diacriticsMap[c] ?? c);
  }
  return buf.toString();
}

const Map<int, int> _diacriticsMap = {
  0xe0: 0x61, 0xe1: 0x61, 0xe2: 0x61, 0xe3: 0x61, 0xe4: 0x61, 0xe5: 0x61, // a
  0xe7: 0x63, // c
  0xe8: 0x65, 0xe9: 0x65, 0xea: 0x65, 0xeb: 0x65, // e
  0xec: 0x69, 0xed: 0x69, 0xee: 0x69, 0xef: 0x69, // i
  0xf1: 0x6e, // n
  0xf2: 0x6f, 0xf3: 0x6f, 0xf4: 0x6f, 0xf5: 0x6f, 0xf6: 0x6f, 0xf8: 0x6f, // o
  0xf9: 0x75, 0xfa: 0x75, 0xfb: 0x75, 0xfc: 0x75, // u
  0xfd: 0x79, 0xff: 0x79, // y
  0xdf: 0x73, // ß → s (approximate)
};

class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.query});
  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) return Text(text);
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyLarge ?? const TextStyle();
    final highlight = base.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.primary,
    );
    final lowerText = _normalize(text);
    final lowerQuery = _normalize(query);
    final i = lowerText.indexOf(lowerQuery);
    if (i < 0) return Text(text, style: base);
    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(text: text.substring(i, i + query.length), style: highlight),
          TextSpan(text: text.substring(i + query.length)),
        ],
      ),
    );
  }
}
