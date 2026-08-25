import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/providers/firebase_status.dart';
import '../../core/storage/local_store.dart';
import '../../core/sync/sync_queue.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final pendingSync = ref.watch(syncQueueProvider).pendingCount;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Analytics opt-in'),
                subtitle: const Text(
                    'Controls Firebase Analytics collection and local consent state.'),
                value: LocalStore.settings
                    .get('analyticsOptIn', defaultValue: true) as bool,
                onChanged: (value) async {
                  await LocalStore.settings.put('analyticsOptIn', value);
                  await ref.read(syncQueueProvider).enqueue(
                      '/account/profile', {'analyticsOptIn': value},
                      method: 'PATCH');
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifications'),
                subtitle: const Text(
                    'Habit, hydration, study, finance, and motivation reminders.'),
                value: LocalStore.settings
                    .get('notificationOptIn', defaultValue: true) as bool,
                onChanged: (value) async {
                  await LocalStore.settings.put('notificationOptIn', value);
                  await ref.read(syncQueueProvider).enqueue(
                      '/account/profile', {'notificationOptIn': value},
                      method: 'PATCH');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(firebaseReady
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded),
                title: const Text('Firebase'),
                subtitle: Text(firebaseReady
                    ? 'Connected for auth, FCM, analytics, crash reports, storage, and sync.'
                    : 'Add Firebase options to enable cloud services.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.login_rounded),
                title: const Text('Login / sync account'),
                subtitle: const Text(
                    'Use the demo account or your Firebase account to sync module data with MySQL.'),
                onTap: () => context.go('/auth'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sync_rounded),
                title: Text('Sync now ($pendingSync pending)'),
                subtitle: const Text(
                    'Push queued local module changes to the backend server.'),
                onTap: () async {
                  final result = await ref.read(syncQueueProvider).flush();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(result.message)));
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.download_rounded),
                title: const Text('Export data'),
                subtitle: const Text(
                    'Download account, habits, finance, study, tasks, AI history, and analytics.'),
                onTap: () async {
                  final response = await ref
                      .read(apiClientProvider)
                      .getJson('/account/export');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Export generated: ${response['ok']}')));
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Secure logout'),
                subtitle: const Text(
                    'Clear local tokens and return to authentication.'),
                onTap: () async {
                  await ref.read(apiClientProvider).clearTokens();
                  if (context.mounted) context.go('/auth');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_forever_rounded,
                    color: Theme.of(context).colorScheme.error),
                title: const Text('Account deletion'),
                subtitle: const Text(
                    'Request a 14-day grace period before permanent Firebase and MySQL deletion.'),
                onTap: () async {
                  await ref.read(apiClientProvider).postJson(
                      '/account/delete/request',
                      {'reason': 'Requested from app'});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Deletion grace period started')));
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
