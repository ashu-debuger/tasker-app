import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../quick_actions/quick_action_service.dart';
import '../utils/app_logger.dart';

typedef TileActionCallback =
    void Function(String actionType, Map<String, Object?> metadata);

class TileActionService {
  TileActionService({
    TileActionCallback? onAction,
    MethodChannel? channel,
    Duration? debounceWindow,
  }) : _onAction = onAction,
       _channel = channel ?? const MethodChannel(_channelName),
       _debounceWindow = debounceWindow ?? const Duration(milliseconds: 500);

  static const String _channelName = 'in.devmantra.tasker/tiles';

  final TileActionCallback? _onAction;
  final MethodChannel _channel;
  final Duration _debounceWindow;

  bool _initialized = false;
  DateTime? _lastEmittedAt;

  Future<void> initialize() async {
    if (_initialized || !_isSupportedPlatform) return;

    _channel.setMethodCallHandler(_handleMethodCall);

    final initialAction = await _channel.invokeMethod<String>('getTileAction');
    if (initialAction != null) {
      await _notify(initialAction);
    }

    _initialized = true;
  }

  bool get _isSupportedPlatform => !kIsWeb && Platform.isAndroid;

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onTileAction') {
      final action = call.arguments as String?;
      if (action != null) {
        await _notify(action);
      }
    }
  }

  Future<void> _notify(String rawAction) async {
    if (_isDebounced()) return;
    final mapped = _mapTileAction(rawAction);
    if (mapped == null) return;

    try {
      _onAction?.call(mapped.type, mapped.metadata ?? const {});
      _lastEmittedAt = DateTime.now();
      await _channel.invokeMethod('clearTileAction');
    } catch (error, stackTrace) {
      appLogger.e(
        'Tile action handling failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  ({String type, Map<String, Object?>? metadata})? _mapTileAction(
    String rawAction,
  ) {
    switch (rawAction) {
      case 'create_quick_task':
        return (
          type: QuickActionTypes.quickTask,
          metadata: const {'source': 'tile'},
        );
      case 'create_quick_note':
        return (
          type: QuickActionTypes.quickNote,
          metadata: const {'source': 'tile'},
        );
      default:
        return null;
    }
  }

  bool _isDebounced() {
    if (_lastEmittedAt == null) return false;
    return DateTime.now().difference(_lastEmittedAt!) < _debounceWindow;
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    _channel.setMethodCallHandler(null);
    _initialized = false;
  }
}
