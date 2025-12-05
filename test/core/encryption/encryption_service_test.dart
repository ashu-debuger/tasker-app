import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tasker/src/core/encryption/encryption_service.dart';

void main() {
  group('EncryptionService', () {
    late EncryptionService encryptionService;
    late FlutterSecureStorage mockStorage;

    setUp(() {
      // Configure FlutterSecureStorage to use memory for tests
      FlutterSecureStorage.setMockInitialValues({});
      mockStorage = const FlutterSecureStorage();
      encryptionService = EncryptionService(secureStorage: mockStorage);
    });

    test('initialize creates master key', () async {
      await encryptionService.initialize();
      expect(await encryptionService.isInitialized(), true);
    });

    test('encrypt and decrypt roundtrip works', () async {
      await encryptionService.initialize();

      const plaintext = 'Hello, this is a secret message!';
      final encrypted = await encryptionService.encrypt(plaintext);
      final decrypted = await encryptionService.decrypt(encrypted);

      expect(decrypted, plaintext);
      expect(encrypted, isNot(plaintext));
    });

    test('encrypt empty string returns empty string', () async {
      await encryptionService.initialize();

      final encrypted = await encryptionService.encrypt('');
      expect(encrypted, '');
    });

    test('decrypt empty string returns empty string', () async {
      await encryptionService.initialize();

      final decrypted = await encryptionService.decrypt('');
      expect(decrypted, '');
    });

    test('encrypt produces different output for same input (nonce randomization)', () async {
      await encryptionService.initialize();

      const plaintext = 'Same message';
      final encrypted1 = await encryptionService.encrypt(plaintext);
      final encrypted2 = await encryptionService.encrypt(plaintext);

      expect(encrypted1, isNot(encrypted2));
      expect(await encryptionService.decrypt(encrypted1), plaintext);
      expect(await encryptionService.decrypt(encrypted2), plaintext);
    });

    test('encrypt with project key and decrypt with project key works', () async {
      await encryptionService.initialize();

      final projectKey = await encryptionService.generateProjectKey();
      const plaintext = 'Shared project message';

      final encrypted = await encryptionService.encryptWithProjectKey(
        plaintext,
        projectKey,
      );
      final decrypted = await encryptionService.decryptWithProjectKey(
        encrypted,
        projectKey,
      );

      expect(decrypted, plaintext);
    });

    test('export and import master key works', () async {
      await encryptionService.initialize();

      const originalPlaintext = 'Test message';
      final encrypted = await encryptionService.encrypt(originalPlaintext);

      // Export the key
      final exportedKey = await encryptionService.exportMasterKey();
      expect(exportedKey, isNotNull);

      // Create new service and import key
      final newService = EncryptionService(secureStorage: mockStorage);
      await newService.deleteMasterKey();
      await newService.importMasterKey(exportedKey!);

      // Should be able to decrypt with imported key
      final decrypted = await newService.decrypt(encrypted);
      expect(decrypted, originalPlaintext);
    });

    test('throws EncryptionException when trying to encrypt without initialization', () async {
      expect(
        () => encryptionService.encrypt('test'),
        throwsA(isA<EncryptionException>()),
      );
    });

    test('handles unicode characters correctly', () async {
      await encryptionService.initialize();

      const plaintext = 'Hello 世界 🌍 émojis';
      final encrypted = await encryptionService.encrypt(plaintext);
      final decrypted = await encryptionService.decrypt(encrypted);

      expect(decrypted, plaintext);
    });

    test('handles long text correctly', () async {
      await encryptionService.initialize();

      final plaintext = 'A' * 10000; // 10,000 characters
      final encrypted = await encryptionService.encrypt(plaintext);
      final decrypted = await encryptionService.decrypt(encrypted);

      expect(decrypted, plaintext);
      expect(decrypted.length, 10000);
    });
  });
}
