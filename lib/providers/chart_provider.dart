// lib/providers/chart_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:new_chart/models/chart_model.dart';
import 'package:new_chart/services/notification_services.dart';
import 'package:new_chart/services/message_service.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

final chatListProvider = StreamProvider<List<ChatModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: currentUser.uid)
      .snapshots()
      .asyncMap((snapshot) async {
        try {
          final chats = snapshot.docs
              .map((doc) {
                try {
                  return ChatModel.fromMap(doc.data());
                } catch (e) {
                  print('Error parsing chat ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<ChatModel>()
              .toList();

          chats.sort((a, b) {
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });

          return chats;
        } catch (e) {
          print('Error in chatListProvider: $e');
          return <ChatModel>[];
        }
      });
});

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  chatId,
) {
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return MessageModel.fromMap(doc.data());
              } catch (e) {
                print('Error parsing message ${doc.id}: $e');
                print('Data: ${doc.data()}');
                return null;
              }
            })
            .whereType<MessageModel>()
            .toList();
      });
});

// 🆕 Message service provider
final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService();
});

final chatServiceProvider = Provider((ref) => ChatService(ref));

class ChatService {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  ChatService(this.ref);

  // 🆕 UPDATED: Send message with reply support
  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String content,
    required MessageType type,
    String? mediaUrl,
    String? fileName,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderId,
  }) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) throw Exception('Not authenticated');

      final messageId = _uuid.v4();
      final message = MessageModel(
        messageId: messageId,
        senderId: currentUser.uid,
        receiverId: receiverId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        mediaUrl: mediaUrl,
        replyToMessageId: replyToMessageId,
        replyToContent: replyToContent,
        replyToSenderId: replyToSenderId,
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': _getLastMessagePreview(type, content),
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'lastMessageType': type.toString().split('.').last,
        'lastMessageSenderId': currentUser.uid,
        'unreadCount.$receiverId': FieldValue.increment(1),
        'updatedAt': message.timestamp.millisecondsSinceEpoch,
      });

      final receiverDoc = await _firestore
          .collection('users')
          .doc(receiverId)
          .get();

      if (receiverDoc.exists) {
        final receiverData = UserModel.fromMap(receiverDoc.data()!);
        if (receiverData.fcmToken.isNotEmpty) {
          await NotificationService.sendNotification(
            token: receiverData.fcmToken,
            title: currentUser.username,
            body: _getLastMessagePreview(type, content),
            data: {
              'type': 'message',
              'chatId': chatId,
              'senderId': currentUser.uid,
            },
          );
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$currentUserId': 0,
      });

      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }

  Future<void> clearConversation(String chatId) async {
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageType': null,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error clearing conversation: $e');
      rethrow;
    }
  }

  Future<String> getOrCreateChat(String otherUserId) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) throw Exception('Not authenticated');

      final chatId = generateChatId(currentUser.uid, otherUserId);

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        final otherUserDoc = await _firestore
            .collection('users')
            .doc(otherUserId)
            .get();

        if (!otherUserDoc.exists) {
          throw Exception('User not found');
        }

        final otherUser = UserModel.fromMap(otherUserDoc.data()!);

        await _firestore.collection('chats').doc(chatId).set({
          'chatId': chatId,
          'participants': [currentUser.uid, otherUserId],
          'participantsData': {
            currentUser.uid: {
              'username': currentUser.username,
              'avatarUrl': currentUser.avatarUrl,
            },
            otherUserId: {
              'username': otherUser.username,
              'avatarUrl': otherUser.avatarUrl,
            },
          },
          'lastMessage': null,
          'lastMessageTime': null,
          'lastMessageType': null,
          'lastMessageSenderId': null,
          'unreadCount': {currentUser.uid: 0, otherUserId: 0},
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      return chatId;
    } catch (e) {
      print('Error getting or creating chat: $e');
      rethrow;
    }
  }

  String _getLastMessagePreview(MessageType type, String content) {
    switch (type) {
      case MessageType.text:
        return content.length > 50 ? '${content.substring(0, 50)}...' : content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.file:
        return '📎 File';
    }
  }

  String generateChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }
}
