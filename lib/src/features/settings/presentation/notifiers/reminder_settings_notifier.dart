import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/providers.dart';
import '../../domain/models/reminder_settings.dart';
import '../../data/repositories/reminder_settings_repository.dart';

part 'reminder_settings_notifier.g.dart';

/// Exposes persisted reminder settings and helper mutations.
@Riverpod(keepAlive: true)
class ReminderSettingsNotifier extends _$ReminderSettingsNotifier {
  late final ReminderSettingsRepository _repository;
  StreamSubscription<ReminderSettings>? _subscription;

  @override
  ReminderSettings build() {
    _repository = ref.watch(reminderSettingsRepositoryProvider);
    _subscription = _repository.watchSettings().listen((settings) {
      state = settings;
    });
    ref.onDispose(() => _subscription?.cancel());
    return _repository.getCurrentSettings();
  }

  Future<void> updateTaskLeadMinutes(int minutes) {
    final updated = state.copyWith(taskLeadMinutes: minutes);
    return _repository.saveSettings(updated);
  }

  Future<void> updateRoutineLeadMinutes(int minutes) {
    final updated = state.copyWith(routineLeadMinutes: minutes);
    return _repository.saveSettings(updated);
  }

  Future<void> updateSettings(ReminderSettings settings) {
    return _repository.saveSettings(settings);
  }

  Future<void> resetToDefaults() {
    return _repository.resetToDefaults();
  }
}
