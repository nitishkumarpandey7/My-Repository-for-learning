import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/models/life_module.dart';
import '../../core/sync/sync_queue.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/metric_ring.dart';
import 'module_repository.dart';

class ModuleScreen extends ConsumerStatefulWidget {
  const ModuleScreen({required this.module, super.key});

  final LifeModule module;

  @override
  ConsumerState<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends ConsumerState<ModuleScreen> {
  var _selected = DateTime.now();
  var _view = 'Items';
  late Future<_ModuleState> _state;

  @override
  void initState() {
    super.initState();
    _state = _load();
  }

  @override
  void didUpdateWidget(covariant ModuleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.module.route != widget.module.route) {
      _state = _load();
    }
  }

  Future<_ModuleState> _load() async {
    final repo = ref.read(moduleRepositoryProvider);
    final items = await repo.list(widget.module);
    final reminders = await repo.listReminders(widget.module);
    return _ModuleState(
      items: items,
      reminders: reminders,
      pendingSync: ref.read(syncQueueProvider).pendingCount,
    );
  }

  void _refresh() {
    setState(() => _state = _load());
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    return FutureBuilder<_ModuleState>(
      future: _state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const _ModuleState();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _Header(
              module: module,
              onBack: () => context.go('/dashboard'),
              onAdd: () => _showAddDialog(context),
              onSync: _syncNow,
            ),
            const SizedBox(height: 12),
            _SummaryCard(module: module, state: state),
            const SizedBox(height: 12),
            _SyncCard(
              pendingSync: state.pendingSync,
              failedItems: state.failedItems,
              onSync: _syncNow,
            ),
            const SizedBox(height: 12),
            if (module.title == 'Habits' || module.title == 'Study') ...[
              GlassCard(
                child: TableCalendar(
                  focusedDay: _selected,
                  firstDay: DateTime.utc(2024),
                  lastDay: DateTime.utc(2035),
                  selectedDayPredicate: (day) => isSameDay(day, _selected),
                  onDaySelected: (selectedDay, _) =>
                      setState(() => _selected = selectedDay),
                  calendarFormat: CalendarFormat.week,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Items',
                  icon: Icon(Icons.checklist_rounded),
                  label: Text('Items'),
                ),
                ButtonSegment(
                  value: 'Tools',
                  icon: Icon(Icons.build_rounded),
                  label: Text('Tools'),
                ),
                ButtonSegment(
                  value: 'Stats',
                  icon: Icon(Icons.query_stats_rounded),
                  label: Text('Stats'),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (value) =>
                  setState(() => _view = value.first),
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (_view == 'Tools')
              _ToolsView(
                module: module,
                onSmartRoutine: _createSmartRoutine,
                onReminder: () => _showReminderDialog(context),
                onAnalytics: () => setState(() => _view = 'Stats'),
                onPreset: _createPreset,
              )
            else if (_view == 'Stats')
              _AnalyticsView(module: module, state: state)
            else
              _ItemsView(
                module: module,
                state: state,
                onAdd: () => _showAddDialog(context),
                onChanged: _refresh,
              ),
          ],
        );
      },
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final amountController =
        TextEditingController(text: _defaultAmountFor(widget.module));

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add ${widget.module.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration:
                    InputDecoration(labelText: _titleLabelFor(widget.module)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    InputDecoration(labelText: _amountLabelFor(widget.module)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    await ref.read(moduleRepositoryProvider).create(
          module: widget.module,
          title: title,
          notes: notesController.text.trim(),
          amount: double.tryParse(amountController.text.trim()) ?? 0,
        );
    _refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved on this phone')));
    }
  }

  Future<void> _showReminderDialog(BuildContext context) async {
    final titleController =
        TextEditingController(text: '${widget.module.title} check-in');
    final minutesController = TextEditingController(text: '30');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reminder Engine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Reminder title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minutes from now'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.notifications_active_rounded),
            label: const Text('Schedule'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final minutes = int.tryParse(minutesController.text.trim()) ?? 30;
    await ref.read(moduleRepositoryProvider).createReminder(
          module: widget.module,
          title: titleController.text.trim().isEmpty
              ? '${widget.module.title} reminder'
              : titleController.text.trim(),
          remindAt:
              DateTime.now().add(Duration(minutes: minutes.clamp(1, 10080))),
        );
    _refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Reminder scheduled')));
    }
  }

  Future<void> _createSmartRoutine() async {
    await ref
        .read(moduleRepositoryProvider)
        .createMany(widget.module, _routineFor(widget.module));
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Smart routine created')));
    }
  }

  Future<void> _createPreset(_ModuleCard card) async {
    await ref.read(moduleRepositoryProvider).create(
          module: widget.module,
          title: card.title,
          notes: card.subtitle,
          amount: _presetAmount(widget.module),
        );
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${card.title} added')));
    }
  }

  Future<void> _syncNow() async {
    final result = await ref.read(syncQueueProvider).flush();
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  List<({String title, String notes, double amount})> _routineFor(
    LifeModule module,
  ) {
    switch (module.title) {
      case 'Finance':
        return [
          (
            title: 'Log today expenses',
            notes: 'Capture all cash, UPI, card, and subscription spends.',
            amount: 1,
          ),
          (
            title: 'Check budget leak',
            notes: 'Find one avoidable spend before tonight.',
            amount: 1,
          ),
          (
            title: 'Move money to savings',
            notes: 'Transfer a small amount before spending more.',
            amount: 100,
          ),
        ];
      case 'Study':
        return [
          (
            title: '25 min weak-topic sprint',
            notes: 'Study one difficult topic without switching apps.',
            amount: 0.5,
          ),
          (
            title: '10 question recall test',
            notes: 'Write answers before checking notes.',
            amount: 1,
          ),
          (
            title: 'Revision chain entry',
            notes: 'Mark what to revise tomorrow.',
            amount: 1,
          ),
        ];
      case 'Fitness':
        return [
          (
            title: 'Warm-up mobility',
            notes: 'Neck, shoulders, hips, ankles.',
            amount: 8,
          ),
          (
            title: 'Main workout block',
            notes: '3 rounds at sustainable intensity.',
            amount: 25,
          ),
          (
            title: 'Recovery stretch',
            notes: 'Slow breathing and cool down.',
            amount: 7,
          ),
        ];
      default:
        return [
          (
            title: 'One small start',
            notes: 'Do the smallest visible action in this module.',
            amount: 1,
          ),
          (
            title: 'Focused block',
            notes: 'Work for 25 minutes with notifications away.',
            amount: 1,
          ),
          (
            title: 'Review and reset',
            notes: 'Log progress and choose tomorrow’s next action.',
            amount: 1,
          ),
        ];
    }
  }

  String _titleLabelFor(LifeModule module) {
    switch (module.title) {
      case 'Finance':
        return 'Expense category';
      case 'Study':
        return 'Subject or topic';
      case 'Fitness':
        return 'Workout routine';
      case 'Games':
        return 'Challenge';
      case 'Analytics':
        return 'Metric name';
      default:
        return '${module.title} item';
    }
  }

  String _amountLabelFor(LifeModule module) {
    switch (module.title) {
      case 'Finance':
        return 'Amount';
      case 'Study':
        return 'Target hours';
      case 'Fitness':
        return 'Minutes';
      case 'Games':
        return 'XP reward';
      case 'Analytics':
        return 'Metric value';
      case 'Habits':
        return 'Daily target';
      default:
        return 'Value';
    }
  }

  String _defaultAmountFor(LifeModule module) {
    switch (module.title) {
      case 'Finance':
        return '100';
      case 'Study':
        return '2';
      case 'Fitness':
        return '30';
      case 'Games':
        return '100';
      default:
        return '1';
    }
  }

  double _presetAmount(LifeModule module) {
    switch (module.title) {
      case 'Finance':
        return 100;
      case 'Study':
        return 2;
      case 'Fitness':
        return 30;
      case 'Games':
        return 100;
      default:
        return 1;
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.module,
    required this.onBack,
    required this.onAdd,
    required this.onSync,
  });

  final LifeModule module;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                module.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                module.domain,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onSync,
          icon: const Icon(Icons.sync_rounded),
          tooltip: 'Sync now',
        ),
        const SizedBox(width: 6),
        IconButton.filled(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Add',
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.module, required this.state});

  final LifeModule module;
  final _ModuleState state;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          MetricRing(
            value: state.score,
            label: 'Score',
            color: module.color,
            size: 86,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.metric,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(module.subtitle),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(label: '${state.items.length} items'),
                    _Chip(label: '${state.completedItems} done'),
                    _Chip(label: '${state.reminders.length} reminders'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.pendingSync,
    required this.failedItems,
    required this.onSync,
  });

  final int pendingSync;
  final int failedItems;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
            failedItems > 0
                ? Icons.cloud_off_rounded
                : pendingSync > 0
                    ? Icons.cloud_sync_rounded
                    : Icons.cloud_done_rounded,
            color: failedItems > 0 ? scheme.error : scheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              failedItems > 0
                  ? '$failedItems item(s) failed sync. Check login/server.'
                  : pendingSync > 0
                      ? '$pendingSync queued item(s). Tap Sync now.'
                      : 'Local data is up to date.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: onSync,
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Sync'),
          ),
        ],
      ),
    );
  }
}

class _ItemsView extends ConsumerWidget {
  const _ItemsView({
    required this.module,
    required this.state,
    required this.onAdd,
    required this.onChanged,
  });

  final LifeModule module;
  final _ModuleState state;
  final VoidCallback onAdd;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (state.items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              onTap: onAdd,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: module.color.withValues(alpha: 0.16),
                  child: Icon(Icons.add_task_rounded, color: module.color),
                ),
                title: Text(
                  'Start ${module.title}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Tap here or use + to create an item that saves immediately.',
                ),
              ),
            ),
          ),
        ...state.items.map(
          (item) => _LocalItemTile(
            module: module,
            item: item,
            onChanged: onChanged,
          ),
        ),
        if (state.reminders.isNotEmpty) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Scheduled Reminders',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          ...state.reminders.map((reminder) => _ReminderTile(reminder)),
        ],
      ],
    );
  }
}

class _ToolsView extends StatelessWidget {
  const _ToolsView({
    required this.module,
    required this.onSmartRoutine,
    required this.onReminder,
    required this.onAnalytics,
    required this.onPreset,
  });

  final LifeModule module;
  final VoidCallback onSmartRoutine;
  final VoidCallback onReminder;
  final VoidCallback onAnalytics;
  final ValueChanged<_ModuleCard> onPreset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ToolTile(
          icon: Icons.bolt_rounded,
          color: module.color,
          title: 'Smart Routine',
          subtitle: 'Create a 3-step routine for this module instantly.',
          onTap: onSmartRoutine,
        ),
        _ToolTile(
          icon: Icons.notifications_active_rounded,
          color: module.color,
          title: 'Reminder Engine',
          subtitle: 'Schedule a local reminder record and queue it for sync.',
          onTap: onReminder,
        ),
        _ToolTile(
          icon: Icons.insights_rounded,
          color: module.color,
          title: 'Analytics',
          subtitle: 'Open live stats from your local module data.',
          onTap: onAnalytics,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Quick Missions',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        ..._cardsFor(module).map(
          (card) => _ToolTile(
            icon: card.icon,
            color: module.color,
            title: card.title,
            subtitle: card.subtitle,
            onTap: () => onPreset(card),
          ),
        ),
      ],
    );
  }

  List<_ModuleCard> _cardsFor(LifeModule module) {
    switch (module.title) {
      case 'Finance':
        return const [
          _ModuleCard(Icons.no_meals_rounded, 'No-Spend Challenge',
              'Avoid impulse purchases and win 120 XP.'),
          _ModuleCard(Icons.savings_rounded, 'Savings Quest',
              'Move Rs. 500 toward the emergency fund.'),
          _ModuleCard(Icons.pie_chart_rounded, 'Budget Master',
              'Review budget leaks before tonight.'),
        ];
      case 'Study':
        return const [
          _ModuleCard(Icons.timer_rounded, 'Pomodoro Focus Battle',
              'Start a 25 minute study sprint.'),
          _ModuleCard(Icons.quiz_rounded, 'Quiz Arena',
              'Write 10 weak-topic answers before checking notes.'),
          _ModuleCard(Icons.event_rounded, 'Exam Survival Mode',
              'Create a revision checkpoint for your next exam.'),
        ];
      case 'Games':
        return const [
          _ModuleCard(Icons.directions_walk_rounded, 'Walking Quest',
              'Complete your step mission and earn coins.'),
          _ModuleCard(Icons.casino_rounded, 'Daily Reward Spin',
              'Claim a daily XP reward task.'),
          _ModuleCard(Icons.psychology_rounded, 'AI Challenge',
              'Create a discipline mission for today.'),
        ];
      default:
        return const [
          _ModuleCard(Icons.flag_rounded, 'Daily Win',
              'Create one small, finishable action.'),
          _ModuleCard(Icons.timer_rounded, 'Focus Block',
              'Protect 25 minutes for focused progress.'),
          _ModuleCard(Icons.replay_rounded, 'Reset Plan',
              'Recover from a missed target with a smaller restart.'),
        ];
    }
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView({required this.module, required this.state});

  final LifeModule module;
  final _ModuleState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Analytics',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    barGroups: [
                      _bar(0, state.items.length.toDouble(), module.color),
                      _bar(1, state.completedItems.toDouble(), module.color),
                      _bar(2, state.reminders.length.toDouble(), module.color),
                      _bar(3, state.queuedItems.toDouble(), module.color),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(label: 'Items ${state.items.length}'),
                  _Chip(label: 'Done ${state.completedItems}'),
                  _Chip(label: 'Reminders ${state.reminders.length}'),
                  _Chip(label: 'Queued ${state.queuedItems}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.psychology_rounded, color: module.color),
            title: const Text('Insight'),
            subtitle: Text(state.insightFor(module)),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _bar(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value <= 0 ? 0.2 : value,
          color: color,
          width: 22,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(icon, color: color),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

class _LocalItemTile extends ConsumerWidget {
  const _LocalItemTile({
    required this.module,
    required this.item,
    required this.onChanged,
  });

  final LifeModule module;
  final Map<String, dynamic> item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = _displayTitle(item);
    final completed = item['completed'] == true;
    final syncState = item['syncState']?.toString() ?? 'local';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Checkbox(
            value: completed,
            onChanged: (_) async {
              await ref
                  .read(moduleRepositoryProvider)
                  .toggleComplete(module, item);
              onChanged();
            },
          ),
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              decoration: completed ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_displaySubtitle(item)),
              const SizedBox(height: 6),
              _Chip(label: 'Sync: $syncState'),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete',
            onPressed: () async {
              await ref
                  .read(moduleRepositoryProvider)
                  .delete(module, item['id'] as String);
              onChanged();
            },
          ),
        ),
      ),
    );
  }

  String _displayTitle(Map<String, dynamic> item) {
    return (item['title'] ??
            item['name'] ??
            item['category'] ??
            item['metric_key'] ??
            'Untitled')
        .toString();
  }

  String _displaySubtitle(Map<String, dynamic> item) {
    final parts = <String>[];
    if (item['amount'] != null && module.title == 'Finance') {
      parts.add('Rs. ${item['amount']}');
    }
    if (item['target_hours'] != null) {
      parts.add('${item['target_hours']} hours');
    }
    if (item['estimated_minutes'] != null) {
      parts.add('${item['estimated_minutes']} min');
    }
    if ((item['notes'] ?? item['description']) != null &&
        '${item['notes'] ?? item['description']}'.isNotEmpty) {
      parts.add('${item['notes'] ?? item['description']}');
    }
    return parts.isEmpty ? 'Saved locally' : parts.join(' | ');
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile(this.reminder);

  final Map<String, dynamic> reminder;

  @override
  Widget build(BuildContext context) {
    final rawDate = reminder['remind_at']?.toString();
    final date = rawDate == null ? null : DateTime.tryParse(rawDate);
    final when = date == null
        ? 'Scheduled'
        : DateFormat('MMM d, h:mm a').format(date.toLocal());
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notifications_active_rounded),
          title: Text(
            '${reminder['title'] ?? 'Reminder'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('$when | Sync: ${reminder['syncState'] ?? 'local'}'),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

class _ModuleState {
  const _ModuleState({
    this.items = const [],
    this.reminders = const [],
    this.pendingSync = 0,
  });

  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> reminders;
  final int pendingSync;

  int get completedItems =>
      items.where((item) => item['completed'] == true).length;

  int get queuedItems =>
      items.where((item) => item['syncState'] == 'queued').length;

  int get failedItems =>
      items.where((item) => item['syncState'] == 'failed').length +
      reminders.where((item) => item['syncState'] == 'failed').length;

  double get score {
    if (items.isEmpty) return 0;
    return (completedItems / items.length * 100).clamp(0, 100);
  }

  String insightFor(LifeModule module) {
    if (items.isEmpty) {
      return 'Create one ${module.title.toLowerCase()} item to start generating useful analytics.';
    }
    if (completedItems == 0) {
      return 'You have momentum queued. Complete the smallest item first to start the streak.';
    }
    if (completedItems == items.length) {
      return 'Everything in this module is complete. Add a smart routine for tomorrow.';
    }
    return 'You completed $completedItems of ${items.length}. Finish one more item before adding new work.';
  }
}

class _ModuleCard {
  const _ModuleCard(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}
