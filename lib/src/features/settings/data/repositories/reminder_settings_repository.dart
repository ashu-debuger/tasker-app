import 'package:tasker/src/features/settings/domain/models/reminder_settings.dart';

/// Contract for persisting and retrieving reminder settings.
abstract class ReminderSettingsRepository {
  /// Latest stored reminder configuration.
  ReminderSettings getCurrentSettings();

  /// Stream updates whenever the stored settings change.
  Stream<ReminderSettings> watchSettings();

  /// Persist the provided settings atomically.
  Future<void> saveSettings(ReminderSettings settings);

  /// Reset to the default configuration.
  Future<void> resetToDefaults();
}
