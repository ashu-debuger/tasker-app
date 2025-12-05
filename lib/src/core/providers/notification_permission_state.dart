import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/hive_service.dart';

part 'notification_permission_state.g.dart';

/// Tracks whether the user has been asked for notification permissions
@Riverpod(keepAlive: true)
class NotificationPermissionState extends _$NotificationPermissionState {
  static const String _hasAskedKey = 'notification_permission_asked';

  // Access the app preferences box for simple key-value storage
  Box get _box {
    try {
      return Hive.box(HiveService.appPreferencesBox);
    } catch (e) {
      print('⚠️ Error accessing app preferences box: $e');
      rethrow;
    }
  }

  @override
  bool build() {
    try {
      print('📦 NotificationPermissionState.build() - reading from box');
      final value = _box.get(_hasAskedKey, defaultValue: false);
      print('📦 Got value from box: $value (type: ${value.runtimeType})');
      return value as bool;
    } catch (e, stack) {
      print('💥 Error in NotificationPermissionState.build(): $e');
      print('💥 Stack: $stack');
      // Return false as default if there's an error
      return false;
    }
  }

  /// Mark that we've asked the user for notification permissions
  void markAsAsked() {
    try {
      print('📦 Marking notification permission as asked');
      _box.put(_hasAskedKey, true);
      state = true;
      print('✅ Successfully marked as asked');
    } catch (e, stack) {
      print('💥 Error in markAsAsked(): $e');
      print('💥 Stack: $stack');
    }
  }

  /// Reset the permission state (for testing or if user logs out)
  void reset() {
    try {
      _box.delete(_hasAskedKey);
      state = false;
    } catch (e, stack) {
      print('💥 Error in reset(): $e');
      print('💥 Stack: $stack');
    }
  }
}
