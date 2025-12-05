import '../models/chat_message.dart';

/// Repository interface for chat operations
abstract class ChatRepository {
  /// Send a new message to a project chat
  Future<void> sendMessage(ChatMessage message);

  /// Stream messages for a specific project
  /// Messages are ordered by creation time (newest first)
  Stream<List<ChatMessage>> streamMessagesForProject(String projectId);

  /// Get a specific message by ID
  Future<ChatMessage?> getMessageById(String projectId, String messageId);

  /// Edit an existing message
  Future<void> editMessage(String projectId, String messageId, String newText);

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String projectId, String messageId);

  /// Get message count for a project
  Future<int> getMessageCount(String projectId);

  /// Mark messages as read for current user (for future read receipts)
  Future<void> markMessagesAsRead(String projectId, String userId);
}
