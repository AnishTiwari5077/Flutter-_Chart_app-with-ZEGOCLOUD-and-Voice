// lib/services/message_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add or remove reaction to message (toggle)
  Future<void> addReaction(
    String chatId,
    String messageId,
    String emoji,
    String userId,
  ) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(messageRef);
      final data = snapshot.data();

      if (data == null) return;

      Map<String, dynamic> reactionsMap = Map<String, dynamic>.from(
        data['reactions'] ?? {},
      );

      Map<String, List<String>> reactions = {};
      reactionsMap.forEach((key, value) {
        reactions[key] = List<String>.from(value);
      });

      if (reactions.containsKey(emoji)) {
        if (!reactions[emoji]!.contains(userId)) {
          reactions[emoji]!.add(userId);
        } else {
          // Remove reaction if already exists (toggle)
          reactions[emoji]!.remove(userId);
          if (reactions[emoji]!.isEmpty) {
            reactions.remove(emoji);
          }
        }
      } else {
        reactions[emoji] = [userId];
      }

      transaction.update(messageRef, {'reactions': reactions});
    });
  }

  // Edit message
  Future<void> editMessage(
    String chatId,
    String messageId,
    String newContent,
  ) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
          'content': newContent,
          'isEdited': true,
          'editedAt': DateTime.now().toIso8601String(),
        });
  }

  // Delete message
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Get message by ID
  Future<MessageModel?> getMessageById(String chatId, String messageId) async {
    final doc = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (!doc.exists) return null;
    return MessageModel.fromMap(doc.data()!);
  }
}
