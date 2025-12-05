import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tasker/src/features/routines/domain/models/routine.dart';
import 'package:tasker/src/features/routines/presentation/notifiers/routine_notifier.dart';

class RoutineDialog extends ConsumerStatefulWidget {
  final String userId;
  final Routine? routine;

  const RoutineDialog({super.key, required this.userId, this.routine});

  @override
  ConsumerState<RoutineDialog> createState() => _RoutineDialogState();
}

class _RoutineDialogState extends ConsumerState<RoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late RoutineFrequency _selectedFrequency;
  late Set<int> _selectedDays;
  TimeOfDay? _selectedTime;
  late bool _isActive;
  late bool _reminderEnabled;
  late int _reminderMinutesBefore;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.routine?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.routine?.description ?? '',
    );
    _selectedFrequency = widget.routine?.frequency ?? RoutineFrequency.daily;
    _selectedDays = widget.routine?.daysOfWeek.toSet() ?? {};
    _isActive = widget.routine?.isActive ?? true;
    _reminderEnabled = widget.routine?.reminderEnabled ?? false;
    _reminderMinutesBefore = widget.routine?.reminderMinutesBefore ?? 15;

    if (widget.routine?.timeOfDay != null) {
      final parts = widget.routine!.timeOfDay!.split(':');
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.routine == null ? 'Create Routine' : 'Edit Routine'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Morning workout',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'e.g., 30 min cardio and stretching',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RoutineFrequency>(
                initialValue: _selectedFrequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: RoutineFrequency.values.map((frequency) {
                  return DropdownMenuItem(
                    value: frequency,
                    child: Text(_getFrequencyLabel(frequency)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFrequency = value;
                      if (value == RoutineFrequency.daily) {
                        _selectedDays.clear();
                      }
                    });
                  }
                },
              ),
              if (_selectedFrequency != RoutineFrequency.daily) ...[
                const SizedBox(height: 16),
                const Text(
                  'Days of Week',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final isSelected = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(_getDayLabel(day)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }),
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Time (optional)'),
                subtitle: Text(
                  _selectedTime == null
                      ? 'No time set'
                      : _selectedTime!.format(context),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedTime != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedTime = null;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _selectedTime = time;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reminder'),
                subtitle: _reminderEnabled
                    ? Text('$_reminderMinutesBefore minutes before')
                    : const Text('Enable notifications for this routine'),
                value: _reminderEnabled,
                onChanged: _selectedTime != null
                    ? (value) {
                        setState(() {
                          _reminderEnabled = value;
                        });
                      }
                    : null,
              ),
              if (_reminderEnabled) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Remind me'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _reminderMinutesBefore.toDouble(),
                          min: 0,
                          max: 60,
                          divisions: 12,
                          label: '$_reminderMinutesBefore min',
                          onChanged: (value) {
                            setState(() {
                              _reminderMinutesBefore = value.toInt();
                            });
                          },
                        ),
                      ),
                      Text('$_reminderMinutesBefore min before'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _saveRoutine, child: const Text('Save')),
      ],
    );
  }

  String _getFrequencyLabel(RoutineFrequency frequency) {
    switch (frequency) {
      case RoutineFrequency.daily:
        return 'Daily';
      case RoutineFrequency.weekly:
        return 'Weekly';
      case RoutineFrequency.custom:
        return 'Custom';
    }
  }

  String _getDayLabel(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  Future<void> _saveRoutine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFrequency != RoutineFrequency.daily && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day for this routine'),
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final timeOfDay = _selectedTime == null
        ? null
        : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    final notifier = ref.read(routineProvider(widget.userId).notifier);

    try {
      if (widget.routine == null) {
        // Create new routine
        await notifier.createRoutine(
          title: title,
          description: description.isEmpty ? null : description,
          frequency: _selectedFrequency,
          daysOfWeek: _selectedFrequency == RoutineFrequency.daily
              ? null
              : (_selectedDays.toList()..sort()),
          timeOfDay: timeOfDay,
          isActive: _isActive,
          reminderEnabled: _reminderEnabled,
          reminderMinutesBefore: _reminderMinutesBefore,
        );
      } else {
        // Update existing routine
        final updatedRoutine = widget.routine!.copyWith(
          title: title,
          description: description.isEmpty ? null : description,
          frequency: _selectedFrequency,
          daysOfWeek: _selectedFrequency == RoutineFrequency.daily
              ? null
              : (_selectedDays.toList()..sort()),
          timeOfDay: timeOfDay,
          isActive: _isActive,
          reminderEnabled: _reminderEnabled,
          reminderMinutesBefore: _reminderMinutesBefore,
        );
        await notifier.updateRoutine(updatedRoutine);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving routine: $e')));
      }
    }
  }
}
