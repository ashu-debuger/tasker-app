import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../../core/providers/providers.dart';
import '../../../auth/data/repositories/auth_repository.dart';

part 'chat_notifier.g.dart';

/// Notifier for managing chat messages in a project
@riverpod
class ChatNotifier extends _$ChatNotifier {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  @override
  Stream<List<ChatMessage>> build(String projectId) {
    return _repository.streamMessagesForProject(projectId);
  }

  /// Send a new message to the project chat
  Future<void> sendMessage({
    required String projectId,
    required String text,
    bool isEncrypted = false,
  }) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to send messages');
    }

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: projectId,
      senderId: currentUser.id,
      senderName: currentUser.displayName ?? currentUser.email,
      text: text.trim(),
      isEncrypted: isEncrypted,
      createdAt: DateTime.now(),
    );

    await _repository.sendMessage(message);
  }

  /// Edit an existing message
  Future<void> editMessage({
    required String projectId,
    required String messageId,
    required String newText,
  }) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to edit messages');
    }

    // Verify the message belongs to the current user
    final message = await _repository.getMessageById(projectId, messageId);
    if (message == null) {
      throw Exception('Message not found');
    }

    if (message.senderId != currentUser.id) {
      throw Exception('You can only edit your own messages');
    }

    await _repository.editMessage(projectId, messageId, newText.trim());
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage({
    required String projectId,
    required String messageId,
  }) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to delete messages');
    }

    // Verify the message belongs to the current user
    final message = await _repository.getMessageById(projectId, messageId);
    if (message == null) {
      throw Exception('Message not found');
    }

    if (message.senderId != currentUser.id) {
      throw Exception('You can only delete your own messages');
    }

    await _repository.deleteMessage(projectId, messageId);
  }

  /// Get message count for the project
  Future<int> getMessageCount(String projectId) async {
    return await _repository.getMessageCount(projectId);
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String projectId) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) return;

    await _repository.markMessagesAsRead(projectId, currentUser.id);
  }
}
