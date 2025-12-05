import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:tasker/src/core/config/env_config.dart';
import 'package:tasker/src/core/utils/app_logger.dart';
import 'package:tasker/src/features/settings/data/models/cliq_user_mapping.dart';
import 'package:tasker/src/features/settings/data/models/cliq_notification_settings.dart';
import 'package:tasker/src/features/settings/data/models/cliq_linking_result.dart';

/// Repository for managing Zoho Cliq integration
class CliqRepository {
  static const _logTag = '[CliqRepository]';

  // Backend API configuration from environment
  static String get _baseUrl => EnvConfig.apiBaseUrl;
  static String get _apiKey => EnvConfig.apiKey;

  final FirebaseFirestore _firestore;

  CliqRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════
  // USER MAPPING
  // ═══════════════════════════════════════════════════════════════════

  /// Check if a user has linked their Cliq account
  Future<bool> isCliqLinked(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('cliq_user_mappings')
          .where('tasker_user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag isCliqLinked failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get Cliq user mapping for a Tasker user
  Future<CliqUserMapping?> getCliqMapping(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('cliq_user_mappings')
          .where('tasker_user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return CliqUserMapping.fromFirestore(snapshot.docs.first);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag getCliqMapping failed',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Generate a linking code for connecting Cliq account
  /// The user will use this code in Cliq with /tasker link <code>
  /// Returns CliqLinkingResult with code and challenge number for verification
  Future<CliqLinkingResult?> generateLinkingCode(
    String userId,
    String email,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/cliq/bot/generate-link-code'),
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
        body: jsonEncode({'userId': userId, 'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CliqLinkingResult.fromJson(data['data']);
        }
      }

      appLogger.w('$_logTag generateLinkingCode failed: ${response.body}');
      return null;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag generateLinkingCode error',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Verify challenge number for secure account linking
  /// Called after user selects the correct challenge number in the UI
  Future<bool> verifyChallenge({
    required String code,
    required int challengeNumber,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/cliq/verify-challenge'),
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
        body: jsonEncode({
          'code': code,
          'challengeNumber': challengeNumber,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      appLogger.w('$_logTag verifyChallenge failed: ${response.body}');
      return false;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag verifyChallenge error',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Unlink Cliq account
  Future<bool> unlinkCliq(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/cliq/bot/unlink'),
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag unlinkCliq error',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // NOTIFICATION SETTINGS
  // ═══════════════════════════════════════════════════════════════════

  /// Get notification settings for a user
  Future<CliqNotificationSettings> getNotificationSettings(
    String userId,
  ) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (!doc.exists) {
        return CliqNotificationSettings.defaults();
      }

      return CliqNotificationSettings.fromFirestore(doc);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag getNotificationSettings failed',
        error: e,
        stackTrace: stackTrace,
      );
      return CliqNotificationSettings.defaults();
    }
  }

  /// Update notification settings
  Future<bool> updateNotificationSettings(
    String userId,
    CliqNotificationSettings settings,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .set(settings.toFirestore(), SetOptions(merge: true));

      appLogger.i('$_logTag Notification settings updated for user $userId');
      return true;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag updateNotificationSettings failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Enable Do Not Disturb for a specified duration
  Future<bool> enableDoNotDisturb(String userId, {int hours = 1}) async {
    try {
      final until = DateTime.now().add(Duration(hours: hours));

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .set({
            'doNotDisturb': {
              'enabled': true,
              'until': Timestamp.fromDate(until),
            },
          }, SetOptions(merge: true));

      appLogger.i('$_logTag DND enabled for $hours hours for user $userId');
      return true;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag enableDoNotDisturb failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Disable Do Not Disturb
  Future<bool> disableDoNotDisturb(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .set({
            'doNotDisturb': {'enabled': false, 'until': null},
          }, SetOptions(merge: true));

      appLogger.i('$_logTag DND disabled for user $userId');
      return true;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag disableDoNotDisturb failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Update quiet hours settings
  Future<bool> updateQuietHours(
    String userId, {
    required bool enabled,
    int startHour = 22,
    int endHour = 8,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .set({
            'quiet_hours': {
              'enabled': enabled,
              'start': startHour,
              'end': endHour,
            },
          }, SetOptions(merge: true));

      appLogger.i('$_logTag Quiet hours updated for user $userId');
      return true;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag updateQuietHours failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // REAL-TIME STREAMS
  // ═══════════════════════════════════════════════════════════════════

  /// Stream of Cliq link status changes
  Stream<bool> watchCliqLinkStatus(String userId) {
    return _firestore
        .collection('cliq_user_mappings')
        .where('tasker_user_id', isEqualTo: userId)
        .where('is_active', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Stream of notification settings changes
  Stream<CliqNotificationSettings> watchNotificationSettings(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('notifications')
        .snapshots()
        .map((doc) {
          if (!doc.exists) return CliqNotificationSettings.defaults();
          return CliqNotificationSettings.fromFirestore(doc);
        });
  }

  // ═══════════════════════════════════════════════════════════════════
  // NOTIFICATION HISTORY
  // ═══════════════════════════════════════════════════════════════════

  /// Get recent notifications sent to user
  Future<List<Map<String, dynamic>>> getNotificationHistory(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('notification_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag getNotificationHistory failed',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}
