// lib/widgets/message_bubble.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:new_chart/core/date_formattor.dart';
import 'package:new_chart/models/message_model.dart';
import 'package:new_chart/screens/full_screen_viewer.dart';
import 'package:new_chart/theme/app_theme.dart';
import 'package:new_chart/widgets/message_reactions.dart';
import 'package:new_chart/widgets/voice_message_bubble.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final ThemeData theme;
  final bool isDark;
  final String currentUserId;
  final Function(String messageId, String emoji) onReaction;
  final Function(MessageModel message) onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.theme,
    required this.isDark,
    required this.currentUserId,
    required this.onReaction,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => onLongPress(message),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            gradient: isMe
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: .85),
                    ],
                  )
                : null,
            color: isMe
                ? null
                : (isDark ? AppTheme.cardDark : Colors.grey.shade100),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.replyToContent != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: (isMe ? Colors.white : Colors.black).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.5)
                            : theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    message.replyToContent!,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withValues(alpha: .8)
                          : (isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              // ✅ UPDATED: Add tap to open full screen for images
              if (message.type == MessageType.image && message.mediaUrl != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(
                          imageUrl: message.mediaUrl!,
                          heroTag: 'message_${message.messageId}',
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'message_${message.messageId}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: message.mediaUrl!,
                        memCacheWidth: 800,
                        memCacheHeight: 800,
                        maxWidthDiskCache: 1200,
                        maxHeightDiskCache: 1200,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                          ),
                        ),
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 200),
                      ),
                    ),
                  ),
                )
              else if (message.type == MessageType.voice &&
                  message.mediaUrl != null)
                VoiceMessageBubble(
                  audioUrl: message.mediaUrl!,
                  duration: message.fileName != null
                      ? Duration(
                          seconds:
                              int.tryParse(
                                message.fileName!.replaceAll('s', ''),
                              ) ??
                              0,
                        )
                      : null,
                  isMe: isMe,
                  theme: theme,
                  isDark: isDark,
                )
              else
                Text(
                  message.content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isMe ? Colors.white : null,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),

              if (message.reactions != null && message.reactions!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: MessageReactions(
                    reactions: message.reactions,
                    currentUserId: currentUserId,
                    onReactionTap: (emoji) =>
                        onReaction(message.messageId, emoji),
                    isMyMessage: isMe,
                  ),
                ),

              const SizedBox(height: 6),

              // Timestamp and read status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.isEdited)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        'edited',
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withValues(alpha: .7)
                              : (isDark
                                    ? AppTheme.textTertiaryDark
                                    : AppTheme.textTertiaryLight),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  Text(
                    DateFormatter.formatChatTime(message.timestamp),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withValues(alpha: .85)
                          : (isDark
                                ? AppTheme.textTertiaryDark
                                : AppTheme.textTertiaryLight),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 16,
                      color: message.isRead
                          ? Colors.lightBlueAccent
                          : Colors.white.withValues(alpha: .85),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
