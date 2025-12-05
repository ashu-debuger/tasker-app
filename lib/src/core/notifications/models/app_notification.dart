import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'notification_type.dart';

part 'app_notification.g.dart';

/// Application notification model
@JsonSerializable(explicitToJson: true)
class AppNotification extends Equatable {
  /// Unique notification ID
  final String id;

  /// User ID of the recipient
  final String userId;

  /// Type of notification
  final NotificationType type;

  /// Notification title
  final String title;

  /// Notification body/message
  final String body;

  /// Optional image URL (e.g., user avatar, project icon)
  final String? imageUrl;

  /// Additional contextual data (project ID, task ID, etc.)
  final Map<String, dynamic> data;

  /// When the notification was created
  final DateTime createdAt;

  /// Whether the notification has been read
  @JsonKey(defaultValue: false)
  final bool isRead;

  /// Optional action URL for deep linking
  final String? actionUrl;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data = const {},
    required this.createdAt,
    this.isRead = false,
    this.actionUrl,
  });

  /// Empty notification for initial state
  static final empty = AppNotification(
    id: '',
    userId: '',
    type: NotificationType.taskReminder,
    title: '',
    body: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Check if notification is empty
  bool get isEmpty => this == AppNotification.empty;

  /// Check if notification is not empty
  bool get isNotEmpty => this != AppNotification.empty;

  /// JSON serialization
  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);

  /// Firestore serialization
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.taskReminder,
      ),
      title: data['title'] as String,
      body: data['body'] as String,
      imageUrl: data['imageUrl'] as String?,
      data: (data['data'] as Map<String, dynamic>?) ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool? ?? false,
      actionUrl: data['actionUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'actionUrl': actionUrl,
    };
  }

  /// Copy with method for immutability
  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? actionUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    body,
    imageUrl,
    data,
    createdAt,
    isRead,
    actionUrl,
  ];
}
