import 'package:flutter/material.dart';

import '../../domain/models/routine.dart';

/// Summarizes a user's routines and surfaces quick insights.
class RoutineInsightsCard extends StatelessWidget {
  const RoutineInsightsCard({
    super.key,
    required this.routines,
    required this.onPlanRoutine,
    this.todaysRoutines,
  });

  final List<Routine> routines;
  final List<Routine>? todaysRoutines;
  final VoidCallback onPlanRoutine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeRoutines = routines
        .where((routine) => routine.isActive)
        .toList();
    final activeCount = activeRoutines.length;
    final reminderCount = activeRoutines
        .where((routine) => routine.reminderEnabled)
        .length;
    final todayCount = todaysRoutines?.length ?? 0;

    final weeklyLoad = _computeWeeklyLoad(activeRoutines);
    final hasLoad = weeklyLoad.any((count) => count > 0);
    final maxLoad = hasLoad ? weeklyLoad.reduce((a, b) => a > b ? a : b) : 0;
    final minLoad = hasLoad ? weeklyLoad.reduce((a, b) => a < b ? a : b) : 0;
    final balanceScore = !hasLoad
        ? 0
        : (100 - ((maxLoad - minLoad) / (maxLoad == 0 ? 1 : maxLoad) * 100))
              .clamp(0, 100)
              .round();

    final busyDayIndex = hasLoad ? weeklyLoad.indexOf(maxLoad) : null;
    final lightDayIndex = hasLoad ? weeklyLoad.indexOf(minLoad) : null;

    final insightMessage = _buildInsightMessage(
      activeCount: activeCount,
      balanceScore: balanceScore,
      busyDayIndex: busyDayIndex,
      lightDayIndex: lightDayIndex,
    );

    final todayMessage = todayCount == 0
        ? 'No routines on deck today. Add a 2-min win to keep momentum.'
        : todayCount == 1
        ? 'One routine queued today—block out five minutes and crush it.'
        : '$todayCount routines scheduled today. Batch them to stay in flow.';

    final reminderCoverage = activeCount == 0
        ? 0
        : ((reminderCount / activeCount) * 100).round();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _BalanceBadge(score: balanceScore),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Routine rhythm',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(insightMessage, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: onPlanRoutine,
                  child: const Text('Plan routine'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: balanceScore / 100,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InsightTile(
                  icon: Icons.playlist_add_check_circle,
                  label: 'Active routines',
                  value: activeCount.toString(),
                  helperText: todayMessage,
                ),
                _InsightTile(
                  icon: Icons.notifications_active,
                  label: 'Reminder coverage',
                  value: '$reminderCoverage%',
                  helperText: reminderCoverage >= 70
                      ? 'Great accountability signal'
                      : 'Enable reminders for critical habits',
                ),
                if (busyDayIndex != null && lightDayIndex != null)
                  _InsightTile(
                    icon: Icons.calendar_today,
                    label: 'Load map',
                    value:
                        '${_dayLabel(busyDayIndex)} → ${_dayLabel(lightDayIndex)}',
                    helperText: busyDayIndex == lightDayIndex
                        ? 'Evenly distributed week'
                        : 'Shift one habit to ${_dayLabel(lightDayIndex)}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<int> _computeWeeklyLoad(List<Routine> routines) {
    final load = List<int>.filled(7, 0);
    for (final routine in routines) {
      final targetDays = _targetDaysForRoutine(routine);
      for (final day in targetDays) {
        if (day >= 1 && day <= 7) {
          load[day - 1] += 1;
        }
      }
    }
    return load;
  }

  Iterable<int> _targetDaysForRoutine(Routine routine) {
    if (routine.frequency == RoutineFrequency.daily ||
        routine.daysOfWeek.isEmpty) {
      return List<int>.generate(7, (index) => index + 1);
    }
    return routine.daysOfWeek;
  }

  String _buildInsightMessage({
    required int activeCount,
    required int balanceScore,
    required int? busyDayIndex,
    required int? lightDayIndex,
  }) {
    if (activeCount == 0) {
      return 'Create your first routine to unlock smart reminders.';
    }

    if (balanceScore >= 80) {
      return 'Nice balance! Your habits are evenly spread.';
    }

    if (busyDayIndex != null &&
        lightDayIndex != null &&
        busyDayIndex != lightDayIndex) {
      return 'Consider moving one habit from ${_dayLabel(busyDayIndex)} to ${_dayLabel(lightDayIndex)}.';
    }

    return 'Dial in one more micro-routine to increase consistency.';
  }

  static String _dayLabel(int index) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (index < 0 || index >= labels.length) return 'Day';
    return labels[index];
  }
}

class _BalanceBadge extends StatelessWidget {
  const _BalanceBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = score >= 80
        ? Colors.green
        : score >= 50
        ? Colors.amber
        : Colors.redAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 6,
                color: color,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            Text(
              '$score%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Balance', style: theme.textTheme.labelMedium),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.helperText,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(value, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  helperText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
