import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tasker/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tasker/src/features/routines/domain/models/routine.dart';
import 'package:tasker/src/features/routines/presentation/notifiers/routine_notifier.dart';
import 'package:tasker/src/features/routines/presentation/widgets/routine_dialog.dart';
import 'package:tasker/src/features/routines/presentation/widgets/routine_insights_card.dart';
import 'package:tasker/src/core/routing/app_router.dart';

class RoutinesListScreen extends ConsumerWidget {
  const RoutinesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authProvider);

    return authStateAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Please log in to view routines')),
          );
        }

        final routinesAsync = ref.watch(routineProvider(user.id));
        final todaysRoutinesAsync = ref.watch(todaysRoutinesProvider(user.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Routines'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showRoutineDialog(context, ref, user.id),
              ),
            ],
          ),
          body: routinesAsync.when(
            data: (routines) => routines.isEmpty
                ? const Center(
                    child: Text('No routines yet. Tap + to create one.'),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInsightsSection(
                          context,
                          ref,
                          routines,
                          todaysRoutinesAsync,
                          user.id,
                        ),
                        // Today's Active Routines Section
                        _buildTodaysSection(
                          context,
                          ref,
                          todaysRoutinesAsync,
                          user.id,
                        ),
                        const Divider(height: 32),
                        // All Routines Grouped by Frequency
                        _buildAllRoutinesSection(
                          context,
                          ref,
                          routines,
                          user.id,
                        ),
                      ],
                    ),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text('Error loading routines: $err')),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Auth error: $err'))),
    );
  }

  Widget _buildTodaysSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Routine>> todaysRoutinesAsync,
    String userId,
  ) {
    return todaysRoutinesAsync.when(
      data: (todaysRoutines) {
        if (todaysRoutines.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No routines scheduled today',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep momentum by planning a quick routine anchor.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              _showRoutineDialog(context, ref, userId),
                          icon: const Icon(Icons.add),
                          label: const Text('Plan routine'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.push(AppRoutes.calendar),
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Open calendar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "Today's routines",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TodayHighlightCard(
                routineCount: todaysRoutines.length,
                nextRoutine: _nextRoutine(todaysRoutines),
                onOpenCalendar: () => context.push(AppRoutes.calendar),
              ),
            ),
            const SizedBox(height: 8),
            ...todaysRoutines.map(
              (routine) => _buildRoutineCard(context, ref, routine, userId),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error loading today\'s routines: $err'),
      ),
    );
  }

  Routine? _nextRoutine(List<Routine> routines) {
    if (routines.isEmpty) return null;

    final withTime = routines.where((r) => r.timeOfDay != null).toList();
    if (withTime.isEmpty) {
      return routines.first;
    }

    withTime.sort(
      (a, b) => _timeValue(a.timeOfDay!).compareTo(_timeValue(b.timeOfDay!)),
    );
    return withTime.first;
  }

  int _timeValue(String timeOfDay) {
    final parts = timeOfDay.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  Widget _buildInsightsSection(
    BuildContext context,
    WidgetRef ref,
    List<Routine> routines,
    AsyncValue<List<Routine>> todaysRoutinesAsync,
    String userId,
  ) {
    if (routines.isEmpty) {
      return RoutineInsightsCard(
        routines: const [],
        todaysRoutines: const [],
        onPlanRoutine: () => _showRoutineDialog(context, ref, userId),
      );
    }

    return todaysRoutinesAsync.when(
      data: (today) => RoutineInsightsCard(
        routines: routines,
        todaysRoutines: today,
        onPlanRoutine: () => _showRoutineDialog(context, ref, userId),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Insights unavailable: $error'),
      ),
    );
  }

  Widget _buildAllRoutinesSection(
    BuildContext context,
    WidgetRef ref,
    List<Routine> routines,
    String userId,
  ) {
    final dailyRoutines = routines
        .where((r) => r.frequency == RoutineFrequency.daily)
        .toList();
    final weeklyRoutines = routines
        .where((r) => r.frequency == RoutineFrequency.weekly)
        .toList();
    final customRoutines = routines
        .where((r) => r.frequency == RoutineFrequency.custom)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'All Routines',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        if (dailyRoutines.isNotEmpty) ...[
          _buildFrequencyHeader('Daily'),
          ...dailyRoutines.map(
            (routine) => _buildRoutineCard(context, ref, routine, userId),
          ),
        ],
        if (weeklyRoutines.isNotEmpty) ...[
          _buildFrequencyHeader('Weekly'),
          ...weeklyRoutines.map(
            (routine) => _buildRoutineCard(context, ref, routine, userId),
          ),
        ],
        if (customRoutines.isNotEmpty) ...[
          _buildFrequencyHeader('Custom'),
          ...customRoutines.map(
            (routine) => _buildRoutineCard(context, ref, routine, userId),
          ),
        ],
      ],
    );
  }

  Widget _buildFrequencyHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildRoutineCard(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
    String userId,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(routine.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (routine.description != null && routine.description!.isNotEmpty)
              Text(routine.description!),
            const SizedBox(height: 4),
            Text(
              _getFrequencyText(routine),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (routine.timeOfDay != null)
              Text(
                'Time: ${routine.timeOfDay}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        onTap: () {
          context.push(
            '/routines/${routine.id}',
            extra: {'routineId': routine.id, 'userId': userId},
          );
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: routine.isActive,
              onChanged: (value) async {
                await ref
                    .read(routineProvider(userId).notifier)
                    .toggleRoutineActive(routine.id);
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  _showRoutineDialog(context, ref, userId, routine: routine);
                } else if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Routine'),
                      content: const Text(
                        'Are you sure you want to delete this routine?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await ref
                        .read(routineProvider(userId).notifier)
                        .deleteRoutine(routine.id);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFrequencyText(Routine routine) {
    switch (routine.frequency) {
      case RoutineFrequency.daily:
        return 'Every day';
      case RoutineFrequency.weekly:
        if (routine.daysOfWeek.isEmpty) {
          return 'Weekly';
        }
        final days = routine.daysOfWeek
            .map((day) => _getDayName(day))
            .join(', ');
        return 'Weekly: $days';
      case RoutineFrequency.custom:
        if (routine.daysOfWeek.isEmpty) {
          return 'Custom schedule';
        }
        final days = routine.daysOfWeek
            .map((day) => _getDayName(day))
            .join(', ');
        return 'Custom: $days';
    }
  }

  String _getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  void _showRoutineDialog(
    BuildContext context,
    WidgetRef ref,
    String userId, {
    Routine? routine,
  }) {
    showDialog(
      context: context,
      builder: (context) => RoutineDialog(userId: userId, routine: routine),
    );
  }
}

class _TodayHighlightCard extends StatelessWidget {
  const _TodayHighlightCard({
    required this.routineCount,
    required this.nextRoutine,
    required this.onOpenCalendar,
  });

  final int routineCount;
  final Routine? nextRoutine;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = routineCount == 1
        ? '1 routine on deck today'
        : '$routineCount routines on deck today';
    final detail = nextRoutine == null
        ? 'Plan a quick habit anchor to stay consistent.'
        : (nextRoutine!.timeOfDay != null
              ? 'Next up at ${nextRoutine!.timeOfDay}'
              : 'Next routine can happen anytime.');

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sunny, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.85,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onOpenCalendar,
                icon: const Icon(Icons.calendar_today),
                label: const Text('View in calendar'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
