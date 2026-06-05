import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../application/providers.dart';
import '../application/sync_service.dart';
import '../data/birthday_repository.dart';
import 'widgets/birthday_search_delegate.dart';

class BirthdayListPage extends ConsumerStatefulWidget {
  const BirthdayListPage({super.key});

  @override
  ConsumerState<BirthdayListPage> createState() => _BirthdayListPageState();
}

class _BirthdayListPageState extends ConsumerState<BirthdayListPage> {
  bool _syncing = false;
  String? _error;
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstRunSync());
    _initWidgetLaunch();
  }

  @override
  void dispose() {
    _widgetClickSub?.cancel();
    super.dispose();
  }

  /// Opens the tapped contact when the app is launched (cold) or resumed (warm)
  /// from a widget row. The widget encodes the contact as
  /// `birthdaycontacts://contact?id=<contactId>` (see BirthdayWidget.kt).
  Future<void> _initWidgetLaunch() async {
    _widgetClickSub = HomeWidget.widgetClicked.listen(_handleWidgetUri);
    _handleWidgetUri(await HomeWidget.initiallyLaunchedFromHomeWidget());
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null || uri.host != 'contact') return;
    final contactId = uri.queryParameters['id'];
    if (contactId != null && contactId.isNotEmpty) _openContact(contactId);
  }

  Future<void> _firstRunSync() async {
    final source = ref.read(contactsSourceProvider);
    final hadPermission = await source.hasPermission();
    if (!hadPermission) {
      final granted = await source.requestPermission();
      if (!granted) {
        setState(() => _error = 'permission');
        return;
      }
    }
    await ref.read(notificationServiceProvider).requestPermissions();
    // Register background jobs the first time we have permission.
    // ExistingPeriodicWorkPolicy.keep makes this idempotent on subsequent runs.
    await registerBackgroundJobs();
    await _sync();
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _error = null;
    });
    try {
      await ref.read(birthdayRepositoryProvider).sync();
      ref.invalidate(lastSyncedAtProvider);
    } on PermissionDeniedException {
      setState(() => _error = 'permission');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(upcomingBirthdaysProvider);
    final lastSynced = ref.watch(lastSyncedAtProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Birthdays'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(list.value ?? const []),
          ),
          IconButton(
            tooltip: 'Sync now',
            icon: _syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: _syncing ? null : _sync,
          ),
        ],
        bottom: lastSynced == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Last synced ${DateFormat.yMMMd().add_Hm().format(lastSynced)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
      ),
      body: _error == 'permission'
          ? _PermissionEmpty(
              onOpenSettings: openAppSettings,
              onRetry: _firstRunSync,
            )
          : RefreshIndicator(
              onRefresh: _sync,
              child: list.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (items) => items.isEmpty
                    ? _EmptyState(onSync: _sync)
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final b = items[i];
                          final date = DateFormat.MMMd().format(
                            b.nextOccurrence,
                          );
                          final until = switch (b.daysUntil) {
                            0 => 'Today',
                            1 => 'Tomorrow',
                            final d => 'in $d days',
                          };
                          final age = b.ageTurning != null
                              ? ' • turns ${b.ageTurning}'
                              : '';
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(_initials(b.birthday.displayName)),
                            ),
                            title: Text(b.birthday.displayName),
                            subtitle: Text('$date • $until$age'),
                            onTap: () => _openContact(b.birthday.contactId),
                          );
                        },
                      ),
              ),
            ),
    );
  }

  Future<void> _openSearch(List<UpcomingBirthday> all) async {
    final selected = await showSearch<UpcomingBirthday?>(
      context: context,
      delegate: BirthdaySearchDelegate(all),
    );
    if (selected != null) await _openContact(selected.birthday.contactId);
  }

  Future<void> _openContact(String contactId) async {
    try {
      await FlutterContacts.native.showViewer(contactId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't open contact: $e")));
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSync});
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.cake_outlined, size: 64),
        const SizedBox(height: 16),
        const Center(child: Text('No birthdays found in your contacts.')),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: onSync,
            icon: const Icon(Icons.sync),
            label: const Text('Sync now'),
          ),
        ),
      ],
    );
  }
}

class _PermissionEmpty extends StatelessWidget {
  const _PermissionEmpty({required this.onOpenSettings, required this.onRetry});
  final Future<bool> Function() onOpenSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_outline, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Birthday Contacts needs permission to read your contacts.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => onOpenSettings(),
            child: const Text('Open app settings'),
          ),
        ],
      ),
    );
  }
}
