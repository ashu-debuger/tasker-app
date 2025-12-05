import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../../core/encryption/encryption_service.dart';
import '../../../../core/utils/app_logger.dart';

/// Firebase implementation of ChatRepository
class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore;
  final EncryptionService _encryptionService;
  static const _logTag = '[Chat:Repo]';

  /// Firestore collection path for chat messages
  static const String _chatsCollection = 'chats';

  FirebaseChatRepository(this._firestore, this._encryptionService);

  /// Get reference to project's chat collection
  CollectionReference<Map<String, dynamic>> _getProjectChatCollection(
    String projectId,
  ) {
    return _firestore
        .collection(_chatsCollection)
        .doc(projectId)
        .collection('messages');
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    appLogger.i(
      '$_logTag sendMessage projectId=${message.projectId} messageId=${message.id}',
    );
    final chatRef = _getProjectChatCollection(message.projectId);

    // Encrypt message text if encryption is enabled
    final messageToSend = await _encryptMessageIfNeeded(
      message,
      context: 'sendMessage',
    );

    await logTimedAsync(
      '$_logTag sendMessage write messageId=${messageToSend.id}',
      () => chatRef.doc(messageToSend.id).set(messageToSend.toFirestore()),
    );
    appLogger.i('$_logTag sendMessage success messageId=${messageToSend.id}');
  }

  @override
  Stream<List<ChatMessage>> streamMessagesForProject(String projectId) {
    appLogger.d('$_logTag streamMessages subscribed projectId=$projectId');
    return _getProjectChatCollection(projectId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(100) // Limit to last 100 messages for performance
        .snapshots()
        .asyncMap((snapshot) async {
          final messages = <ChatMessage>[];
          for (final doc in snapshot.docs) {
            final decryptedMessage = await _decryptMessageIfNeeded(
              ChatMessage.fromFirestore(doc.id, doc.data()),
              context: 'streamMessages',
            );
            messages.add(decryptedMessage);
          }
          appLogger.d(
            '$_logTag streamMessages snapshot=${messages.length} projectId=$projectId',
          );
          return messages;
        });
  }

  @override
  Future<ChatMessage?> getMessageById(
    String projectId,
    String messageId,
  ) async {
    appLogger.d(
      '$_logTag getMessageById projectId=$projectId messageId=$messageId',
    );
    final doc = await logTimedAsync(
      '$_logTag getMessage doc messageId=$messageId',
      () => _getProjectChatCollection(projectId).doc(messageId).get(),
      level: Level.debug,
    );

    if (!doc.exists) return null;

    final message = await _decryptMessageIfNeeded(
      ChatMessage.fromFirestore(doc.id, doc.data()!),
      context: 'getMessageById',
    );
    appLogger.i('$_logTag getMessageById success messageId=$messageId');
    return message;
  }

  @override
  Future<void> editMessage(
    String projectId,
    String messageId,
    String newText,
  ) async {
    appLogger.i('$_logTag editMessage projectId=$projectId messageId=$messageId');
    // Check if message is encrypted
    final existingMessage = await getMessageById(projectId, messageId);
    if (existingMessage == null) {
      throw Exception('Message not found');
    }

    String textToSave = newText;
    if (existingMessage.isEncrypted) {
      textToSave = await _encryptText(newText, messageId, context: 'editMessage');
    }

    await logTimedAsync(
      '$_logTag editMessage write messageId=$messageId',
      () => _getProjectChatCollection(projectId).doc(messageId).update({
            'text': textToSave,
            'editedAt': DateTime.now().toIso8601String(),
          }),
    );
    appLogger.i('$_logTag editMessage success messageId=$messageId');
  }

  @override
  Future<void> deleteMessage(String projectId, String messageId) async {
    appLogger.w('$_logTag deleteMessage projectId=$projectId messageId=$messageId');
    await logTimedAsync(
      '$_logTag deleteMessage update messageId=$messageId',
      () => _getProjectChatCollection(projectId).doc(messageId).update({
            'isDeleted': true,
            'text': '[Message deleted]',
            'editedAt': DateTime.now().toIso8601String(),
          }),
    );
    appLogger.i('$_logTag deleteMessage success messageId=$messageId');
  }

  @override
  Future<int> getMessageCount(String projectId) async {
    appLogger.d('$_logTag getMessageCount projectId=$projectId');
    final snapshot = await logTimedAsync(
      '$_logTag getMessageCount query projectId=$projectId',
      () => _getProjectChatCollection(projectId)
          .where('isDeleted', isEqualTo: false)
          .count()
          .get(),
      level: Level.debug,
    );

    final count = snapshot.count ?? 0;
    appLogger.i('$_logTag getMessageCount result=$count projectId=$projectId');
    return count;
  }

  @override
  Future<void> markMessagesAsRead(String projectId, String userId) async {
    // Placeholder for future read receipts feature
    // This would update a separate collection tracking read status
    // For now, this is a no-op
    appLogger.d('$_logTag markMessagesAsRead noop projectId=$projectId userId=$userId');
  }

  Future<ChatMessage> _encryptMessageIfNeeded(
    ChatMessage message, {
    required String context,
  }) async {
    if (!message.isEncrypted) return message;
    final encryptedText = await _encryptText(
      message.text,
      message.id,
      context: context,
    );
    return message.copyWith(text: encryptedText);
  }

  Future<String> _encryptText(
    String text,
    String messageId, {
    required String context,
  }) async {
    try {
      return await logTimedAsync(
        '$_logTag $context encrypt messageId=$messageId',
        () => _encryptionService.encrypt(text),
        level: Level.debug,
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag $context encrypt failed messageId=$messageId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ChatMessage> _decryptMessageIfNeeded(
    ChatMessage message, {
    required String context,
  }) async {
    if (!message.isEncrypted) return message;
    try {
      final decryptedText = await _encryptionService.decrypt(message.text);
      return message.copyWith(text: decryptedText);
    } catch (e, stackTrace) {
      appLogger.w(
        '$_logTag $context decrypt failed messageId=${message.id}',
        error: e,
        stackTrace: stackTrace,
      );
      return message.copyWith(text: '[Unable to decrypt message]');
    }
  }
}
