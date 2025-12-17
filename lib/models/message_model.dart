// lib/models/message_model.dart

enum MessageType { text, image, video, audio, file }

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? mediaUrl;

  // 🆕 NEW FIELDS FOR REACTIONS & REPLIES
  final Map<String, List<String>>? reactions; // emoji: [userId1, userId2]
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToSenderId;
  final bool isEdited;
  final DateTime? editedAt;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.mediaUrl,
    this.reactions,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderId,
    this.isEdited = false,
    this.editedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'mediaUrl': mediaUrl,
      'reactions': reactions,
      'replyToMessageId': replyToMessageId,
      'replyToContent': replyToContent,
      'replyToSenderId': replyToSenderId,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] as String,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      content: map['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: map['isRead'] as bool? ?? false,
      mediaUrl: map['mediaUrl'] as String?,
      reactions: map['reactions'] != null
          ? Map<String, List<String>>.from(
              (map['reactions'] as Map).map(
                (key, value) =>
                    MapEntry(key.toString(), List<String>.from(value)),
              ),
            )
          : null,
      replyToMessageId: map['replyToMessageId'] as String?,
      replyToContent: map['replyToContent'] as String?,
      replyToSenderId: map['replyToSenderId'] as String?,
      isEdited: map['isEdited'] as bool? ?? false,
      editedAt: map['editedAt'] != null
          ? DateTime.parse(map['editedAt'] as String)
          : null,
    );
  }

  MessageModel copyWith({
    String? messageId,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? mediaUrl,
    Map<String, List<String>>? reactions,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderId,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      reactions: reactions ?? this.reactions,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}
