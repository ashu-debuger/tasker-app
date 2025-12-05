import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:tasker/src/core/storage/adapters/app_user_adapter.dart';
import 'package:tasker/src/core/storage/adapters/chat_message_adapter.dart';
import 'package:tasker/src/core/storage/adapters/project_adapter.dart';
import 'package:tasker/src/core/storage/adapters/subtask_adapter.dart';
import 'package:tasker/src/core/storage/adapters/task_adapter.dart';
import 'package:tasker/src/core/storage/adapters/routine_adapter.dart';
import 'package:tasker/src/core/storage/adapters/sticky_note_adapter.dart';
import 'package:tasker/src/core/storage/adapters/mind_map_adapter.dart';
import 'package:tasker/src/core/storage/adapters/reminder_settings_adapter.dart';
import 'package:tasker/src/core/storage/adapters/diary_entry_adapter.dart';
import 'package:tasker/src/core/utils/app_logger.dart';
import 'package:tasker/src/features/settings/domain/models/reminder_settings.dart';
import 'package:tasker/src/features/diary/models/diary_entry.dart';

/// Service to initialize and manage Hive local storage
class HiveService {
  static const _logTag = '[HiveService]';

  /// Box names for different data types
  static const String projectsBox = 'projects';
  static const String tasksBox = 'tasks';
  static const String subtasksBox = 'subtasks';
  static const String chatMessagesBox = 'chat_messages';
  static const String routinesBox = 'routines';
  static const String stickyNotesBox = 'sticky_notes';
  static const String mindMapsBox = 'mind_maps';
  static const String mindMapNodesBox = 'mind_map_nodes';
  static const String diaryEntriesBox = 'diary_entries';
  static const String userBox = 'user';
  static const String syncQueueBox = 'sync_queue';
  static const String settingsBox = 'settings';
  static const String appPreferencesBox = 'app_preferences';

  /// Initialize Hive and register all adapters
  static Future<void> init() async {
    appLogger.i('$_logTag Initialization requested');
    try {
      await logTimedAsync(
        '$_logTag Hive initFlutter',
        () => Hive.initFlutter(),
        level: Level.debug,
      );

      _registerAdapters();

      await _openBoxes();
      appLogger.i('$_logTag Hive initialized successfully');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Close all Hive boxes
  static Future<void> close() async {
    appLogger.i('$_logTag Close requested');
    try {
      await logTimedAsync('$_logTag Hive close', () => Hive.close());
      appLogger.i('$_logTag Hive closed successfully');
    } catch (e, stackTrace) {
      appLogger.e('$_logTag Close failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Clear all data (useful for logout)
  static Future<void> clearAll() async {
    appLogger.w('$_logTag clearAll requested');
    try {
      await _clearBox(projectsBox);
      await _clearBox(tasksBox);
      await _clearBox(subtasksBox);
      await _clearBox(chatMessagesBox);
      await _clearBox(routinesBox);
      await _clearBox(stickyNotesBox);
      await _clearBox(mindMapsBox);
      await _clearBox(mindMapNodesBox);
      await _clearBox(diaryEntriesBox);
      await _clearBox(userBox);
      await _clearBox(syncQueueBox);
      appLogger.w('$_logTag clearAll complete');
    } catch (e, stackTrace) {
      appLogger.e('$_logTag clearAll failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  static void _registerAdapters() {
    appLogger.d('$_logTag Registering Hive adapters');
    Hive.registerAdapter(AppUserAdapter());
    Hive.registerAdapter(ProjectAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(SubtaskAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    Hive.registerAdapter(RoutineAdapter());
    Hive.registerAdapter(NotePositionAdapter());
    Hive.registerAdapter(StickyNoteAdapter());
    Hive.registerAdapter(MindMapAdapter());
    Hive.registerAdapter(NodeColorAdapter());
    Hive.registerAdapter(MindMapNodeAdapter());
    Hive.registerAdapter(ReminderSettingsAdapter());
    Hive.registerAdapter(DiaryEntryAdapter());
    appLogger.d('$_logTag Adapter registration complete');
  }

  static Future<void> _openBoxes() async {
    appLogger.d('$_logTag Opening Hive boxes');
    await _openBox(projectsBox);
    await _openBox(tasksBox);
    await _openBox(subtasksBox);
    await _openBox(chatMessagesBox);
    await _openBox(routinesBox);
    await _openBox(stickyNotesBox);
    await _openBox(mindMapsBox);
    await _openBox(mindMapNodesBox);
    await _openBox(userBox);
    await _openBox(appPreferencesBox);
    await _openTypedBox<Map>(syncQueueBox);
    await _openTypedBox<ReminderSettings>(settingsBox);
    await _openTypedBox<DiaryEntry>(diaryEntriesBox);
    appLogger.d('$_logTag Boxes opened successfully');
  }

  static Future<void> _openBox(String name) {
    return logTimedAsync(
      '$_logTag Open box $name',
      () => Hive.openBox(name),
      level: Level.debug,
    );
  }

  static Future<void> _openTypedBox<T>(String name) {
    return logTimedAsync(
      '$_logTag Open box $name',
      () => Hive.openBox<T>(name),
      level: Level.debug,
    );
  }

  static Future<void> _clearBox(String name) {
    return logTimedAsync(
      '$_logTag Clear box $name',
      () => Hive.box(name).clear(),
    );
  }
}
