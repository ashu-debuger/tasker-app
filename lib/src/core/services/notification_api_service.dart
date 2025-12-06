import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/env_config.dart';
import '../utils/app_logger.dart';

/// Service for sending push notifications via backend API
class NotificationApiService {
  static const String _tag = '[NotificationAPI]';

  // Backend URL from environment configuration
  String get _baseUrl => '${EnvConfig.apiBaseUrl}/fcm';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get Firebase ID token for authentication
  Future<String?> _getAuthToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        appLogger.w('$_tag No authenticated user');
        return null;
      }
      final token = await user.getIdToken();
      appLogger.d('$_tag Got auth token for user: ${user.uid}');
      return token;
    } catch (e) {
      appLogger.e('$_tag Error getting auth token', error: e);
      return null;
    }
  }

  /// Send notification to a single user
  Future<bool> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      appLogger.i('$_tag Sending notification to: $userId');

      final token = await _getAuthToken();
      if (token == null) {
        appLogger.e('$_tag Cannot send - no auth token');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        }),
      );

      appLogger.d('$_tag Response status: ${response.statusCode}');
      appLogger.d('$_tag Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        appLogger.i('$_tag Notification sent successfully');
        return result['success'] == true;
      } else {
        appLogger.e(
          '$_tag Failed with status ${response.statusCode}: ${response.body}',
        );
        return false;
      }
    } catch (e, stack) {
      appLogger.e(
        '$_tag Error sending notification',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Send notification to multiple users
  Future<bool> sendToMultipleUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      appLogger.i('$_tag Sending notification to ${userIds.length} users');

      final token = await _getAuthToken();
      if (token == null) {
        appLogger.e('$_tag Cannot send - no auth token');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/send-multiple'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userIds': userIds,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        appLogger.i('$_tag Batch notification sent successfully');
        return result['success'] == true;
      } else {
        appLogger.e('$_tag Failed with status ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      appLogger.e(
        '$_tag Error sending batch notification',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Send test notification to yourself
  Future<bool> sendTestNotification() async {
    try {
      appLogger.i('$_tag Sending test notification');

      final token = await _getAuthToken();
      if (token == null) {
        appLogger.e('$_tag Cannot send - no auth token');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/test'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        appLogger.i('$_tag Test notification sent');
        return result['success'] == true;
      } else {
        appLogger.e('$_tag Test failed with status ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      appLogger.e('$_tag Error sending test', error: e, stackTrace: stack);
      return false;
    }
  }
}
