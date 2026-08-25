import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/life_module.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/local_store.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/metric_ring.dart';

final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.getJson('/dashboard');
    final data = Map<String, dynamic>.from(response['data'] as Map);
    await LocalStore.dashboardCache.put('dashboard', data);
    return data;
  } catch (_) {
    final cached = LocalStore.dashboardCache.get('dashboard');
    if (cached is Map) return Map<String, dynamic>.from(cached);
    return {
      'scores': {
        'lifeScore': 78,
        'habitScore': 72,
        'taskScore': 81,
        'studyScore': 64,
        'financeScore': 86,
        'productivityScore': 74,
      },
      'gamification': {'xp': 8420, 'level': 8, 'activeChallenges': 4},
      'insights': [
        {
          'content':
              'Create one smart routine, finish one item, then sync when the server is reachable.',
        }
      ],
    };
  }
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(dashboardProvider);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('$error')),
      data: (data) => _Dashboard(data: data),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final scores = Map<String, dynamic>.from(data['scores'] as Map? ?? {});
    final gamification =
        Map<String, dynamic>.from(data['gamification'] as Map? ?? {});
    final insights = data['insights'] as List?;
    final firstInsight =
        insights == null || insights.isEmpty ? null : insights.first;
    final insight =
        (firstInsight is Map ? firstInsight['content'] as String? : null) ??
            'Your system is ready for today.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LifeOS X',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(insight),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  MetricRing(
                    value: (scores['lifeScore'] as num? ?? 78).toDouble(),
                    label: 'Life',
                    color: Theme.of(context).colorScheme.primary,
                    size: 88,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go('/ai'),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Ask AI'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/modules/tasks'),
                    icon: const Icon(Icons.today_rounded),
                    label: const Text('Plan'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/settings'),
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Sync'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _StatBlock(
                label: 'Level',
                value: '${gamification['level'] ?? 8}',
                icon: Icons.emoji_events_rounded,
              ),
              _StatBlock(
                label: 'XP',
                value: '${gamification['xp'] ?? 8420}',
                icon: Icons.bolt_rounded,
              ),
              _StatBlock(
                label: 'Missions',
                value: '${gamification['activeChallenges'] ?? 4}',
                icon: Icons.flag_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...lifeModules.map(
          (module) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              onTap: () => context.go(module.route),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: module.color.withValues(alpha: 0.16),
                    child: Icon(module.icon, color: module.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          module.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        GlassCard(
          child: SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    spots: const [
                      FlSpot(0, 42),
                      FlSpot(1, 48),
                      FlSpot(2, 58),
                      FlSpot(3, 53),
                      FlSpot(4, 71),
                      FlSpot(5, 76),
                      FlSpot(6, 78),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
