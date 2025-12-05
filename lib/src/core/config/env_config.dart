import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for Tasker app
///
/// This class provides centralized access to environment variables.
/// Make sure to call [EnvConfig.init()] before using any values.
class EnvConfig {
  EnvConfig._();

  static bool _initialized = false;

  /// Initialize environment configuration
  /// Must be called before accessing any environment variables
  static Future<void> init() async {
    if (_initialized) return;
    await dotenv.load(fileName: '.env');
    _initialized = true;
  }

  /// Get a required environment variable
  /// Throws if the variable is not set
  static String _getRequired(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Environment variable $key is required but not set');
    }
    return value;
  }

  // ═══════════════════════════════════════════════════════════════════
  // BACKEND API CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════

  /// Main Tasker backend API base URL
  static String get apiBaseUrl => _getRequired('TASKER_API_BASE_URL');

  /// API key for authenticating with the Tasker backend
  static String get apiKey => _getRequired('TASKER_API_KEY');

  // ═══════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════

  /// Check if environment is properly configured
  static bool get isConfigured => _initialized;

  /// Get all loaded environment variables (for debugging)
  static Map<String, String> get allVariables => Map.from(dotenv.env);
}
