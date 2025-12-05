import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/providers/providers.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../../projects/domain/models/project.dart';
import '../../../projects/presentation/notifiers/project_list_notifier.dart';
import '../../../routines/domain/models/routine.dart';
import '../../../routines/presentation/notifiers/routine_notifier.dart';
import '../../../tasks/domain/helpers/task_reminder_helper.dart';
import '../../../tasks/domain/models/task.dart';
import '../../../tasks/presentation/providers/user_tasks_provider.dart';
import '../../domain/models/calendar_entry.dart';
import '../widgets/calendar_event_list.dart';
import '../widgets/focus_momentum_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Set<String> _selectedProjectIds = <String>{};
  late TaskReminderHelper _taskReminderHelper;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _focusedDay = today;
    _selectedDay = today;
    _taskReminderHelper = ref.read(taskReminderHelperProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Sign in to view your calendar.')),
          );
        }

        final tasksAsync = ref.watch(userTasksProvider(user.id));
        final routinesAsync = ref.watch(routineProvider(user.id));
        final projectsAsync = ref.watch(projectListProvider);

        return tasksAsync.when(
          data: (tasks) => routinesAsync.when(
            data: (routines) => projectsAsync.when(
              data: (projects) =>
                  _buildContent(context, tasks, routines, projects, user.id),
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) =>
                  Scaffold(body: Center(child: Text('Projects error: $error'))),
            ),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) =>
                Scaffold(body: Center(child: Text('Routines error: $error'))),
          ),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) =>
              Scaffold(body: Center(child: Text('Tasks error: $error'))),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Auth error: $error'))),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Task> tasks,
    List<Routine> routines,
    List<Project> projects,
    String userId,
  ) {
    final firstDay = _firstCalendarDay();
    final lastDay = _lastCalendarDay();
    final projectMap = {for (final project in projects) project.id: project};
    final eventsCache = _buildEventsCache(
      tasks,
      routines,
      projectMap,
      firstDay,
      lastDay,
      userId,
    );
    var selectedEntries = eventsCache[_selectedDay] ?? const <CalendarEntry>[];
    if (_selectedProjectIds.isNotEmpty) {
      selectedEntries = selectedEntries
          .where(
            (entry) =>
                !entry.isTask ||
                _selectedProjectIds.contains(entry.task!.projectId),
          )
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Jump to today',
            onPressed: () {
              setState(() {
                _focusedDay = DateUtils.dateOnly(DateTime.now());
                _selectedDay = _focusedDay;
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger rebuild by calling setState; streams auto refresh.
          if (mounted) setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildLegend(context),
              ),
              if (projects.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildProjectFilter(projects),
                ),
              ],
              const SizedBox(height: 8),
              _buildCalendar(eventsCache, firstDay, lastDay),
              FocusMomentumCard(
                day: _selectedDay,
                tasks: tasks,
                routines: routines,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  DateUtils.isSameDay(
                        _selectedDay,
                        DateUtils.dateOnly(DateTime.now()),
                      )
                      ? 'Today'
                      : 'Agenda for ${_formatDate(_selectedDay)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              CalendarEventList(
                entries: selectedEntries,
                isFiltered: _selectedProjectIds.isNotEmpty,
                onToggleTask: (task, newStatus) async {
                  try {
                    final updatedTask = task.copyWith(status: newStatus);
                    await ref
                        .read(taskRepositoryProvider)
                        .updateTask(updatedTask);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newStatus == TaskStatus.completed
                              ? 'Marked "${task.title}" complete'
                              : 'Moved "${task.title}" back to pending',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Unable to update task: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                onRescheduleTask: (task) => _showRescheduleSheet(context, task),
                onRoutineTap: (routine) {
                  context.push(
                    '/routines/${routine.id}',
                    extra: {'routineId': routine.id, 'userId': userId},
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(
    Map<DateTime, List<CalendarEntry>> eventsCache,
    DateTime firstDay,
    DateTime lastDay,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TableCalendar<CalendarEntry>(
          focusedDay: _focusedDay,
          firstDay: firstDay,
          lastDay: lastDay,
          calendarFormat: _calendarFormat,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
            CalendarFormat.twoWeeks: '2 weeks',
            CalendarFormat.week: 'Week',
          },
          eventLoader: (day) {
            final normalized = DateUtils.dateOnly(day);
            return eventsCache[normalized] ?? const <CalendarEntry>[];
          },
          selectedDayPredicate: (day) => DateUtils.isSameDay(day, _selectedDay),
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          onDaySelected: (selectedDay, focusedDay) {
            if (!DateUtils.isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = DateUtils.dateOnly(selectedDay);
                _focusedDay = focusedDay;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF6750A4),
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return const SizedBox.shrink();

              final entries = events.cast<CalendarEntry>();
              final hasTask = entries.any(
                (e) => e.type == CalendarEntryType.taskDue,
              );
              final hasAssignedTask = entries.any(
                (e) => e.type == CalendarEntryType.assignedTaskDue,
              );
              final hasRoutine = entries.any((e) => e.isRoutine);

              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasTask)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6750A4), // Purple for tasks
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasAssignedTask)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF6C00), // Orange for assigned tasks
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasRoutine)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1ABC9C), // Teal for routines
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: const [
        _LegendChip(color: Color(0xFF6750A4), label: 'Task due'),
        _LegendChip(color: Color(0xFFEF6C00), label: 'Assigned task due'),
        _LegendChip(color: Color(0xFF1ABC9C), label: 'Routine'),
      ],
    );
  }

  Map<DateTime, List<CalendarEntry>> _buildEventsCache(
    List<Task> tasks,
    List<Routine> routines,
    Map<String, Project> projectMap,
    DateTime firstDay,
    DateTime lastDay,
    String userId,
  ) {
    final map = <DateTime, List<CalendarEntry>>{};

    void addEntry(DateTime day, CalendarEntry entry) {
      map.putIfAbsent(day, () => []).add(entry);
    }

    for (final task in tasks) {
      final dueDate = task.dueDate;
      if (dueDate == null) continue;
      final dayKey = DateUtils.dateOnly(dueDate);
      if (dayKey.isBefore(firstDay) || dayKey.isAfter(lastDay)) continue;
      final subtitle = switch (task.status) {
        TaskStatus.completed => 'Completed',
        TaskStatus.inProgress => 'In progress',
        TaskStatus.pending => task.isOverdue ? 'Overdue' : 'Due today',
      };
      final project = projectMap[task.projectId];

      // Determine if this is an assigned task (user is in assignees list)
      final isAssignedToUser = task.assignees.contains(userId);
      final entryType = isAssignedToUser
          ? CalendarEntryType.assignedTaskDue
          : CalendarEntryType.taskDue;

      addEntry(
        dayKey,
        CalendarEntry(
          type: entryType,
          date: dayKey,
          title: task.title,
          subtitle: subtitle,
          task: task,
          project: project,
        ),
      );
    }

    for (final routine in routines) {
      var day = firstDay;
      while (!day.isAfter(lastDay)) {
        if (routine.occursOn(day)) {
          final subtitle = routine.timeOfDay != null
              ? 'at ${routine.timeOfDay}'
              : 'Anytime';
          addEntry(
            day,
            CalendarEntry(
              type: CalendarEntryType.routine,
              date: day,
              title: routine.title,
              subtitle: subtitle,
              routine: routine,
            ),
          );
        }
        day = day.add(const Duration(days: 1));
      }
    }

    // Sort entries per day by time/type
    for (final entries in map.values) {
      entries.sort((a, b) {
        final timeA = _entrySortValue(a);
        final timeB = _entrySortValue(b);
        return timeA.compareTo(timeB);
      });
    }

    return map;
  }

  DateTime _firstCalendarDay() {
    final now = DateTime.now();
    return DateTime(now.year - 1, now.month, now.day);
  }

  DateTime _lastCalendarDay() {
    final now = DateTime.now();
    return DateTime(now.year + 1, now.month, now.day);
  }

  int _entrySortValue(CalendarEntry entry) {
    int base;
    if (entry.isTask) {
      final dueDate = entry.task!.dueDate;
      base = dueDate != null ? (dueDate.hour * 60 + dueDate.minute) : 24 * 60;
    } else {
      if (entry.routine?.timeOfDay != null) {
        final parts = entry.routine!.timeOfDay!.split(':');
        base = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      } else {
        base = 24 * 60 + 1;
      }
    }
    return base;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildProjectFilter(List<Project> projects) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('All projects'),
          selected: _selectedProjectIds.isEmpty,
          onSelected: (_) {
            if (_selectedProjectIds.isNotEmpty) {
              setState(() => _selectedProjectIds.clear());
            }
          },
        ),
        for (final project in projects)
          FilterChip(
            label: Text(project.name.isEmpty ? 'Untitled' : project.name),
            selected: _selectedProjectIds.contains(project.id),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedProjectIds.add(project.id);
                } else {
                  _selectedProjectIds.remove(project.id);
                }
              });
            },
          ),
      ],
    );
  }

  Future<void> _showRescheduleSheet(BuildContext context, Task task) async {
    final selectedDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _RescheduleSheet(initialDate: task.dueDate ?? DateTime.now()),
    );

    if (selectedDate == null) return;

    final template = task.dueDate ?? DateTime.now();
    final combinedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      template.hour,
      template.minute,
    );

    try {
      final updatedTask = task.copyWith(dueDate: combinedDate);
      await ref.read(taskRepositoryProvider).updateTask(updatedTask);
      await _taskReminderHelper.rescheduleTaskReminder(updatedTask);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rescheduled "${task.title}" to ${_formatDate(selectedDate)}',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to reschedule task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _RescheduleSheet extends StatelessWidget {
  const _RescheduleSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _quickOptions();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Align(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Reschedule task',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            for (final option in options)
              ListTile(
                leading: const Icon(Icons.event_available),
                title: Text(option.label),
                subtitle: option.helper != null ? Text(option.helper!) : null,
                onTap: () => Navigator.of(context).pop(option.date),
              ),
            ListTile(
              leading: const Icon(Icons.edit_calendar_outlined),
              title: const Text('Pick another date'),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (selected != null && context.mounted) {
                  Navigator.of(context).pop(selected);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<_QuickDateOption> _quickOptions() {
    final now = DateUtils.dateOnly(DateTime.now());
    final tomorrow = now.add(const Duration(days: 1));
    final nextWeek = now.add(const Duration(days: 7));

    return [
      _QuickDateOption(label: 'Today', helper: _formatFriendly(now), date: now),
      _QuickDateOption(
        label: 'Tomorrow',
        helper: _formatFriendly(tomorrow),
        date: tomorrow,
      ),
      _QuickDateOption(
        label: 'Next week',
        helper: _formatFriendly(nextWeek),
        date: nextWeek,
      ),
    ];
  }

  String _formatFriendly(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }
}

class _QuickDateOption {
  const _QuickDateOption({
    required this.label,
    required this.date,
    this.helper,
  });

  final String label;
  final DateTime date;
  final String? helper;
}
