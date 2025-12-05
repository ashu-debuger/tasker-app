import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:tasker/src/core/utils/app_logger.dart';

/// Service for handling end-to-end encryption of sensitive data
/// Uses AES-GCM for authenticated encryption
class EncryptionService {
  final FlutterSecureStorage _secureStorage;
  final AesGcm _algorithm;
  static const _logTag = '[EncryptionService]';

  static const String _masterKeyStorageKey = 'encryption_master_key';
  static const int _keyLength = 32; // 256 bits
  static const int _nonceLength = 12; // 96 bits (recommended for GCM)

  EncryptionService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
      _algorithm = AesGcm.with256bits();

  /// Initialize encryption by ensuring a master key exists
  Future<void> initialize() async {
    appLogger.i('$_logTag Initialization requested');
    try {
      final existingKey = await logTimedAsync(
        '$_logTag SecureStorage read master key',
        () => _secureStorage.read(key: _masterKeyStorageKey),
        level: Level.debug,
      );

      if (existingKey == null) {
        appLogger.w('$_logTag Master key missing - generating new key');
        await _generateAndStoreMasterKey();
      } else {
        appLogger.d('$_logTag Master key already present');
      }
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generate a new master encryption key and store it securely
  Future<void> _generateAndStoreMasterKey() async {
    appLogger.i('$_logTag Generating master key');
    try {
      final secretKey = await logTimedAsync(
        '$_logTag Create master key material',
        () => _algorithm.newSecretKey(),
        level: Level.debug,
      );
      final keyBytes = await logTimedAsync(
        '$_logTag Extract master key bytes',
        () => secretKey.extractBytes(),
        level: Level.debug,
      );
      final keyBase64 = base64Encode(keyBytes);
      await logTimedAsync(
        '$_logTag Persist master key',
        () => _secureStorage.write(key: _masterKeyStorageKey, value: keyBase64),
        level: Level.debug,
      );
      appLogger.i('$_logTag Master key stored successfully');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Master key generation failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get the master encryption key
  Future<SecretKey> _getMasterKey() async {
    final keyBase64 = await logTimedAsync(
      '$_logTag SecureStorage read master key',
      () => _secureStorage.read(key: _masterKeyStorageKey),
      level: Level.debug,
    );
    if (keyBase64 == null) {
      appLogger.e('$_logTag Master key not found when requested');
      throw Exception(
        'Master encryption key not found. Call initialize() first.',
      );
    }
    final keyBytes = base64Decode(keyBase64);
    appLogger.d('$_logTag Master key loaded for operation');
    return SecretKey(keyBytes);
  }

  /// Encrypt plaintext data
  /// Returns base64-encoded encrypted data with nonce prepended
  Future<String> encrypt(String plaintext) async {
    if (plaintext.isEmpty) {
      appLogger.d('$_logTag Encrypt called with empty payload');
      return '';
    }

    try {
      final payloadLength = plaintext.length;
      appLogger.d('$_logTag Encrypt request length=$payloadLength');
      final secretKey = await _getMasterKey();
      final plaintextBytes = utf8.encode(plaintext);

      // Encrypt the data
      final secretBox = await logTimedAsync(
        '$_logTag AES encrypt payload length=$payloadLength',
        () => _algorithm.encrypt(
          plaintextBytes,
          secretKey: secretKey,
        ),
        level: Level.debug,
      );

      // Combine nonce + ciphertext + mac for storage
      // Format: nonce(12) + ciphertext(variable) + mac(16)
      final combined = Uint8List.fromList([
        ...secretBox.nonce,
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ]);

      appLogger.i(
        '$_logTag Encrypt success cipherSize=${formatDataSize(combined.length)}',
      );
      return base64Encode(combined);
    } catch (e) {
      appLogger.e(
        '$_logTag Encrypt failed ${buildErrorContext({'payloadLength': plaintext.length})}',
        error: e,
      );
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }

  /// Decrypt encrypted data
  /// Expects base64-encoded data with nonce prepended
  Future<String> decrypt(String encryptedData) async {
    if (encryptedData.isEmpty) {
      appLogger.d('$_logTag Decrypt called with empty payload');
      return '';
    }

    try {
      final secretKey = await _getMasterKey();
      final combined = base64Decode(encryptedData);
      appLogger.d(
        '$_logTag Decrypt request cipherSize=${formatDataSize(combined.length)}',
      );

      // Extract nonce, ciphertext, and MAC
      final nonce = combined.sublist(0, _nonceLength);
      final macBytes = combined.sublist(combined.length - 16);
      final cipherText = combined.sublist(_nonceLength, combined.length - 16);

      // Create SecretBox for decryption
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));

      // Decrypt the data
      final plaintextBytes = await logTimedAsync(
        '$_logTag AES decrypt payload size=${combined.length}',
        () => _algorithm.decrypt(
          secretBox,
          secretKey: secretKey,
        ),
        level: Level.debug,
      );

      appLogger.i('$_logTag Decrypt success');
      return utf8.decode(plaintextBytes);
    } catch (e) {
      appLogger.e(
        '$_logTag Decrypt failed ${buildErrorContext({'cipherSize': encryptedData.length})}',
        error: e,
      );
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }

  /// Check if encryption is initialized (master key exists)
  Future<bool> isInitialized() async {
    final key = await logTimedAsync(
      '$_logTag SecureStorage read master key (isInitialized)',
      () => _secureStorage.read(key: _masterKeyStorageKey),
      level: Level.debug,
    );
    final hasKey = key != null;
    appLogger.d('$_logTag isInitialized result=$hasKey');
    return hasKey;
  }

  /// Check if master key exists (alias for isInitialized)
  Future<bool> hasMasterKey() async {
    return await isInitialized();
  }

  /// Delete the master key (use with caution - makes all encrypted data unrecoverable)
  Future<void> deleteMasterKey() async {
    appLogger.w('$_logTag Deleting master key');
    try {
      await logTimedAsync(
        '$_logTag SecureStorage delete master key',
        () => _secureStorage.delete(key: _masterKeyStorageKey),
      );
      appLogger.w('$_logTag Master key deleted');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Failed to delete master key',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Export master key as base64 for backup (store securely!)
  Future<String?> exportMasterKey() async {
    final key = await logTimedAsync(
      '$_logTag SecureStorage read master key (export)',
      () => _secureStorage.read(key: _masterKeyStorageKey),
      level: Level.debug,
    );
    appLogger.i('$_logTag exportMasterKey requested hasKey=${key != null}');
    return key;
  }

  /// Import a previously exported master key
  Future<void> importMasterKey(String keyBase64) async {
    // Validate the key format
    try {
      final keyBytes = base64Decode(keyBase64);
      if (keyBytes.length != _keyLength) {
        throw EncryptionException(
          'Invalid key length: expected $_keyLength bytes',
        );
      }
      appLogger.i(
        '$_logTag Importing master key length=${keyBytes.length}',
      );
      await logTimedAsync(
        '$_logTag SecureStorage write imported master key',
        () => _secureStorage.write(key: _masterKeyStorageKey, value: keyBase64),
      );
      appLogger.i('$_logTag Master key import successful');
    } catch (e) {
      appLogger.e('$_logTag Failed to import master key', error: e);
      throw EncryptionException('Failed to import master key: $e');
    }
  }

  /// Generate a key for project-specific encryption (for shared projects)
  Future<String> generateProjectKey() async {
    try {
      final secretKey = await logTimedAsync(
        '$_logTag Create project key material',
        () => _algorithm.newSecretKey(),
        level: Level.debug,
      );
      final keyBytes = await secretKey.extractBytes();
      appLogger.d('$_logTag Generated project key length=${keyBytes.length}');
      return base64Encode(keyBytes);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Failed to generate project key',
        error: e,
        stackTrace: stackTrace,
      );
      throw EncryptionException('Failed to generate project key: $e');
    }
  }

  /// Encrypt data with a specific project key (for shared encrypted content)
  Future<String> encryptWithProjectKey(
    String plaintext,
    String projectKeyBase64,
  ) async {
    if (plaintext.isEmpty) {
      appLogger.d('$_logTag encryptWithProjectKey empty payload');
      return '';
    }

    try {
      final keyBytes = base64Decode(projectKeyBase64);
      final secretKey = SecretKey(keyBytes);
      final plaintextBytes = utf8.encode(plaintext);

      final secretBox = await logTimedAsync(
        '$_logTag encryptWithProjectKey payload length=${plaintext.length}',
        () => _algorithm.encrypt(
          plaintextBytes,
          secretKey: secretKey,
        ),
        level: Level.debug,
      );

      final combined = Uint8List.fromList([
        ...secretBox.nonce,
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ]);

      appLogger.i(
        '$_logTag encryptWithProjectKey success cipherSize=${formatDataSize(combined.length)}',
      );
      return base64Encode(combined);
    } catch (e) {
      appLogger.e('$_logTag encryptWithProjectKey failed', error: e);
      throw EncryptionException('Failed to encrypt with project key: $e');
    }
  }

  /// Decrypt data with a specific project key
  Future<String> decryptWithProjectKey(
    String encryptedData,
    String projectKeyBase64,
  ) async {
    if (encryptedData.isEmpty) {
      appLogger.d('$_logTag decryptWithProjectKey empty payload');
      return '';
    }

    try {
      final keyBytes = base64Decode(projectKeyBase64);
      final secretKey = SecretKey(keyBytes);
      final combined = base64Decode(encryptedData);

      final nonce = combined.sublist(0, _nonceLength);
      final macBytes = combined.sublist(combined.length - 16);
      final cipherText = combined.sublist(_nonceLength, combined.length - 16);

      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));

      final plaintextBytes = await logTimedAsync(
        '$_logTag decryptWithProjectKey cipherSize=${combined.length}',
        () => _algorithm.decrypt(
          secretBox,
          secretKey: secretKey,
        ),
        level: Level.debug,
      );

      appLogger.i('$_logTag decryptWithProjectKey success');
      return utf8.decode(plaintextBytes);
    } catch (e) {
      appLogger.e('$_logTag decryptWithProjectKey failed', error: e);
      throw EncryptionException('Failed to decrypt with project key: $e');
    }
  }
}

/// Exception thrown when encryption/decryption operations fail
class EncryptionException implements Exception {
  final String message;

  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
