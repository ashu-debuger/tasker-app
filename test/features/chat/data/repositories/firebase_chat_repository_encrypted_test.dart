import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:tasker/src/features/chat/data/repositories/firebase_chat_repository.dart';
import 'package:tasker/src/features/chat/domain/models/chat_message.dart';
import 'package:tasker/src/core/encryption/encryption_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late EncryptionService encryptionService;
  late FirebaseChatRepository repository;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    FlutterSecureStorage.setMockInitialValues({});
    encryptionService = EncryptionService();
    await encryptionService.initialize(); // Initialize encryption service
    repository = FirebaseChatRepository(fakeFirestore, encryptionService);
  });

  group('FirebaseChatRepository - Encryption', () {
    test('encrypts message when isEncrypted is true', () async {
      // Arrange
      final message = ChatMessage(
        id: 'msg1',
        projectId: 'project1',
        senderId: 'user1',
        senderName: 'Test User',
        text: 'Secret message',
        isEncrypted: true,
        createdAt: DateTime.now(),
      );

      // Act
      await repository.sendMessage(message);

      // Assert
      final doc = await fakeFirestore
          .collection('chats')
          .doc('project1')
          .collection('messages')
          .doc('msg1')
          .get();

      expect(doc.exists, true);
      expect(doc.data()?['isEncrypted'], true);
      expect(doc.data()?['text'], isNot('Secret message')); // Text should be encrypted
      expect(doc.data()?['text'], isNotEmpty);
    });

    test('does not encrypt message when isEncrypted is false', () async {
      // Arrange
      final message = ChatMessage(
        id: 'msg2',
        projectId: 'project1',
        senderId: 'user1',
        senderName: 'Test User',
        text: 'Plain message',
        isEncrypted: false,
        createdAt: DateTime.now(),
      );

      // Act
      await repository.sendMessage(message);

      // Assert
      final doc = await fakeFirestore
          .collection('chats')
          .doc('project1')
          .collection('messages')
          .doc('msg2')
          .get();

      expect(doc.exists, true);
      expect(doc.data()?['isEncrypted'], false);
      expect(doc.data()?['text'], 'Plain message'); // Text should be plain
    });

    test('decrypts encrypted message when retrieving', () async {
      // Arrange
      final plainText = 'This is a secret message';
      final encryptedText = await encryptionService.encrypt(plainText);
      
      await fakeFirestore
          .collection('chats')
          .doc('project1')
          .collection('messages')
          .doc('msg3')
          .set({
        'projectId': 'project1',
        'senderId': 'user1',
        'senderName': 'Test User',
        'text': encryptedText,
        'isEncrypted': true,
        'createdAt': DateTime.now().toIso8601String(),
        'isDeleted': false,
      });

      // Act
      final message = await repository.getMessageById('project1', 'msg3');

      // Assert
      expect(message, isNotNull);
      expect(message!.text, plainText); // Should be decrypted
      expect(message.isEncrypted, true);
    });

    test('handles decryption failure gracefully', () async {
      // Arrange - Store invalid encrypted data
      await fakeFirestore
          .collection('chats')
          .doc('project1')
          .collection('messages')
          .doc('msg4')
          .set({
        'projectId': 'project1',
        'senderId': 'user1',
        'senderName': 'Test User',
        'text': 'invalid-encrypted-data',
        'isEncrypted': true,
        'createdAt': DateTime.now().toIso8601String(),
        'isDeleted': false,
      });

      // Act
      final message = await repository.getMessageById('project1', 'msg4');

      // Assert
      expect(message, isNotNull);
      expect(message!.text, '[Unable to decrypt message]');
      expect(message.isEncrypted, true);
    });

    test('encrypts edited message if original was encrypted', () async {
      // Arrange - Create encrypted message
      final originalMessage = ChatMessage(
        id: 'msg5',
        projectId: 'project1',
        senderId: 'user1',
        senderName: 'Test User',
        text: 'Original secret',
        isEncrypted: true,
        createdAt: DateTime.now(),
      );
      await repository.sendMessage(originalMessage);

      // Act - Edit the message
      await repository.editMessage('project1', 'msg5', 'Updated secret');

      // Assert
      final doc = await fakeFirestore
          .collection('chats')
          .doc('project1')
          .collection('messages')
          .doc('msg5')
          .get();

      expect(doc.data()?['text'], isNot('Updated secret')); // Should be encrypted
      expect(doc.data()?['editedAt'], isNotNull);
    });

    test('does not encrypt edited message if original was plain', () async {
      // Arrange - Create plain message
      final originalMessage = ChatMessage(
        id: 'msg6',
        projectId: 'project1',
        senderId: 'user1',
        senderName: 'Test User',
        text: 'Original plain',
        isEncrypted: false,
        createdAt: DateTime.now(),
      );
      await repository.sendMessage(originalMessage);

      // Act - Edit the message
      await repository.editMessage('project1', 'msg6', 'Updated plain');

      // Assert
      final doc = await fakeFirestore
          .collection('chats')
          .doc('project1')
          .collection('messages')
          .doc('msg6')
          .get();

      expect(doc.data()?['text'], 'Updated plain'); // Should be plain
      expect(doc.data()?['editedAt'], isNotNull);
    });

    test('streams and decrypts encrypted messages', () async {
      // Arrange - Create mix of encrypted and plain messages
      final plainText1 = 'Secret 1';
      final plainText2 = 'Secret 2';
      final encrypted1 = await encryptionService.encrypt(plainText1);
      final encrypted2 = await encryptionService.encrypt(plainText2);

      await fakeFirestore
          .collection('chats')
          .doc('project1')
          .collection('messages')
          .doc('msg7')
          .set({
        'projectId': 'project1',
        'senderId': 'user1',
        'senderName': 'Test User',
        'text': encrypted1,
        'isEncrypted': true,
        'createdAt': DateTime.now().toIso8601String(),
        'isDeleted': false,
      });

      await fakeFirestore
          .collection('chats')
          .doc('project1')
          .collection('messages')
          .doc('msg8')
          .set({
        'projectId': 'project1',
        'senderId': 'user1',
        'senderName': 'Test User',
        'text': 'Plain message',
        'isEncrypted': false,
        'createdAt': DateTime.now().toIso8601String(),
        'isDeleted': false,
      });

      await fakeFirestore
          .collection('chats')
          .doc('project1')
          .collection('messages')
          .doc('msg9')
          .set({
        'projectId': 'project1',
        'senderId': 'user1',
        'senderName': 'Test User',
        'text': encrypted2,
        'isEncrypted': true,
        'createdAt': DateTime.now().toIso8601String(),
        'isDeleted': false,
      });

      // Act
      final messages = await repository
          .streamMessagesForProject('project1')
          .first;

      // Assert
      expect(messages.length, 3);
      
      final encryptedMessages = messages.where((m) => m.isEncrypted).toList();
      expect(encryptedMessages.length, 2);
      expect(encryptedMessages.any((m) => m.text == plainText1), true);
      expect(encryptedMessages.any((m) => m.text == plainText2), true);

      final plainMessage = messages.firstWhere((m) => !m.isEncrypted);
      expect(plainMessage.text, 'Plain message');
    });

    test('round-trip encryption: send encrypted message and retrieve decrypted', () async {
      // Arrange
      const secretText = 'Top secret information';
      final message = ChatMessage(
        id: 'msg10',
        projectId: 'project1',
        senderId: 'user1',
        senderName: 'Test User',
        text: secretText,
        isEncrypted: true,
        createdAt: DateTime.now(),
      );

      // Act - Send and retrieve
      await repository.sendMessage(message);
      final retrieved = await repository.getMessageById('project1', 'msg10');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.text, secretText);
      expect(retrieved.isEncrypted, true);
      expect(retrieved.id, message.id);
      expect(retrieved.senderId, message.senderId);
    });
  });
}
