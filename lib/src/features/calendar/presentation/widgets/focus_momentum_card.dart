import 'package:flutter/material.dart';

import '../../../tasks/domain/models/task.dart';
import '../../../routines/domain/models/routine.dart';

class FocusMomentumCard extends StatelessWidget {
  const FocusMomentumCard({
    super.key,
    required this.day,
    required this.tasks,
    required this.routines,
  });

  final DateTime day;
  final List<Task> tasks;
  final List<Routine> routines;

  @override
  Widget build(BuildContext context) {
    final normalized = DateUtils.dateOnly(day);
    final dayTasks = tasks
        .where(
          (task) =>
              task.dueDate != null &&
              DateUtils.isSameDay(task.dueDate, normalized),
        )
        .toList();
    final completed = dayTasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    final dueCount = dayTasks.length;
    final routinesCount = routines
        .where((routine) => routine.occursOn(normalized))
        .length;

    final focusScore = _calculateFocusScore(dueCount, completed, routinesCount);
    final suggestion = _buildSuggestion(dayTasks, routinesCount, focusScore);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Focus momentum',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _ScoreChip(score: focusScore),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _StatLabel(label: 'Due tasks', value: '$completed / $dueCount'),
                _StatLabel(label: 'Routines', value: '$routinesCount planned'),
              ],
            ),
            const SizedBox(height: 12),
            Text(suggestion, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  int _calculateFocusScore(
    int dueCount,
    int completedCount,
    int routinesCount,
  ) {
    final total = dueCount + routinesCount;
    if (total == 0) {
      return completedCount > 0 ? 80 : 60;
    }
    final completionRatio = completedCount / total;
    final base = (completionRatio * 100).clamp(0, 100);
    return base.round();
  }

  String _buildSuggestion(
    List<Task> dayTasks,
    int routinesCount,
    int focusScore,
  ) {
    if (dayTasks.isEmpty && routinesCount == 0) {
      return 'Open space day. Schedule a micro-routine to keep momentum.';
    }

    if (focusScore >= 80) {
      return 'Great balance. Lock in the wins by reflecting for two minutes.';
    }

    if (dayTasks.isNotEmpty) {
      final nextTask = dayTasks.first;
      return 'Start with "${nextTask.title}" to unblock the rest of the day.';
    }

    return 'Lean on your routine to anchor the day and avoid drift.';
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    Color color;
    if (score >= 80) {
      color = Colors.green;
    } else if (score >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatLabel extends StatelessWidget {
  const _StatLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}
