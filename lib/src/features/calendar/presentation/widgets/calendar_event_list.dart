import 'package:flutter/material.dart';

import 'package:tasker/src/features/routines/domain/models/routine.dart';

import '../../../tasks/domain/models/task.dart';
import '../../domain/models/calendar_entry.dart';

class CalendarEventList extends StatelessWidget {
  const CalendarEventList({
    super.key,
    required this.entries,
    required this.onToggleTask,
    required this.onRescheduleTask,
    this.isFiltered = false,
    this.onRoutineTap,
  });

  final List<CalendarEntry> entries;
  final void Function(Task task, TaskStatus newStatus) onToggleTask;
  final Future<void> Function(Task task) onRescheduleTask;
  final bool isFiltered;
  final void Function(Routine routine)? onRoutineTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Text(
          isFiltered
              ? 'No items for this project on the selected day.'
              : 'No plans yet. Tap a future day to start scheduling.',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      separatorBuilder: (context, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _CalendarEntryTile(
          entry: entry,
          onToggleTask: onToggleTask,
          onRescheduleTask: onRescheduleTask,
          onRoutineTap: onRoutineTap,
        );
      },
    );
  }
}

class _CalendarEntryTile extends StatelessWidget {
  const _CalendarEntryTile({
    required this.entry,
    required this.onToggleTask,
    required this.onRescheduleTask,
    required this.onRoutineTap,
  });

  final CalendarEntry entry;
  final void Function(Task task, TaskStatus newStatus) onToggleTask;
  final Future<void> Function(Task task) onRescheduleTask;
  final void Function(Routine routine)? onRoutineTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    IconData icon;
    Color iconColor;
    Widget? trailing;
    String? subtitle = entry.subtitle;
    Widget? subtitleContent;

    if (entry.isTask) {
      icon = entry.isCompleted ? Icons.check_circle : Icons.flag;
      final defaultColor = entry.isAssignedTask
          ? const Color(0xFFEF6C00) // Orange for assigned tasks
          : const Color(0xFF6750A4); // Purple for regular tasks
      iconColor = entry.isCompleted
          ? theme.colorScheme.primary
          : (entry.isOverdue ? Colors.redAccent : defaultColor);
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: entry.isCompleted ? 'Mark as pending' : 'Mark complete',
            icon: Icon(entry.isCompleted ? Icons.undo : Icons.check),
            onPressed: () {
              final task = entry.task!;
              final nextStatus = entry.isCompleted
                  ? TaskStatus.pending
                  : TaskStatus.completed;
              onToggleTask(task, nextStatus);
            },
          ),
          IconButton(
            tooltip: 'Reschedule',
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () {
              final task = entry.task!;
              onRescheduleTask(task);
            },
          ),
        ],
      );
      subtitle ??= entry.task?.description;
    } else {
      icon = Icons.repeat;
      iconColor = const Color(0xFF1ABC9C); // Teal for routines
    }

    if (entry.isTask) {
      final task = entry.task!;
      final projectLabel = task.projectId == null
          ? 'Personal'
          : entry.project?.name ?? 'Project ${_shortId(task.projectId!)}';
      subtitleContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null) Text(subtitle),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _ProjectChip(
              label: projectLabel,
              color: _projectColor(task.projectId),
            ),
          ),
        ],
      );
    } else if (subtitle != null) {
      subtitleContent = Text(subtitle);
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(entry.title),
        subtitle: subtitleContent,
        trailing:
            trailing ??
            (entry.isTask
                ? null
                : const Icon(Icons.chevron_right, color: Colors.grey)),
        onTap: entry.isTask
            ? null
            : () {
                final routine = entry.routine;
                if (routine != null && onRoutineTap != null) {
                  onRoutineTap!(routine);
                }
              },
      ),
    );
  }
}

class _ProjectChip extends StatelessWidget {
  const _ProjectChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color _projectColor(String? projectId) {
  const palette = [
    Color(0xFF6750A4),
    Color(0xFF1ABC9C),
    Color(0xFFEF6C00),
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFD81B60),
  ];
  if (projectId == null) return palette[0];
  final index = projectId.hashCode.abs() % palette.length;
  return palette[index];
}

String _shortId(String projectId) {
  if (projectId.length <= 6) return projectId;
  return '${projectId.substring(0, 6)}...';
}
