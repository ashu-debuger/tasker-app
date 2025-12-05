import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';

typedef QuickActionCallback =
    void Function(String actionType, Map<String, Object?> metadata);

class QuickActionTypes {
  static const quickTask = 'action_quick_task';
  static const stickyNotes = 'action_sticky_notes';
  static const mindMaps = 'action_mind_maps';
  static const quickNote = 'action_quick_note';
}

class QuickActionService {
  QuickActionService({QuickActions? quickActions, this.onAction})
    : _quickActions = quickActions ?? const QuickActions();

  final QuickActions _quickActions;
  final QuickActionCallback? onAction;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!_isSupportedPlatform) {
      _initialized = true;
      return;
    }

    await _quickActions.initialize((String shortcutType) {
      if (shortcutType.isNotEmpty) {
        onAction?.call(shortcutType, const {'source': 'launcher'});
      }
    });

    await _quickActions.setShortcutItems(const <ShortcutItem>[
      ShortcutItem(
        type: QuickActionTypes.quickTask,
        localizedTitle: 'Quick Task',
      ),
      ShortcutItem(
        type: QuickActionTypes.stickyNotes,
        localizedTitle: 'Sticky Notes',
      ),
      ShortcutItem(
        type: QuickActionTypes.mindMaps,
        localizedTitle: 'Mind Maps',
      ),
    ]);

    _initialized = true;
  }

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
}
