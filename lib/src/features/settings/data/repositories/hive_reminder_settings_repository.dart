import 'dart:async';

import 'package:hive/hive.dart';
import 'package:tasker/src/features/settings/domain/models/reminder_settings.dart';

import 'reminder_settings_repository.dart';

/// Hive-backed implementation for reminder settings persistence.
class HiveReminderSettingsRepository implements ReminderSettingsRepository {
  HiveReminderSettingsRepository(this._box);

  static const String _settingsKey = 'reminder_settings';

  final Box<ReminderSettings> _box;

  @override
  ReminderSettings getCurrentSettings() {
    return _box.get(_settingsKey, defaultValue: ReminderSettings.defaults) ??
        ReminderSettings.defaults;
  }

  @override
  Stream<ReminderSettings> watchSettings() async* {
    yield getCurrentSettings();
    yield* _box.watch(key: _settingsKey).map((_) => getCurrentSettings());
  }

  @override
  Future<void> saveSettings(ReminderSettings settings) {
    return _box.put(_settingsKey, settings);
  }

  @override
  Future<void> resetToDefaults() {
    return saveSettings(ReminderSettings.defaults);
  }
}
