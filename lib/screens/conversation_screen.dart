// lib/screens/conversation_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:new_chart/core/date_formattor.dart';
import 'package:new_chart/core/error_handler.dart';
import 'package:new_chart/providers/chart_provider.dart';
import 'package:new_chart/services/image_service.dart';
import 'package:new_chart/services/zego_services.dart';

import 'package:new_chart/widgets/user_avatar.dart';
import 'package:new_chart/widgets/message_reactions.dart';
import 'package:new_chart/widgets/reaction_picker.dart';
import 'package:new_chart/widgets/reply_preview.dart';

import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/storage_repository.dart';
import '../../theme/app_theme.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String chatId;
  final UserModel friend;

  const ConversationScreen({
    super.key,
    required this.chatId,
    required this.friend,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  // 🆕 NEW FIELDS FOR REPLY FUNCTIONALITY
  MessageModel? _replyToMessage;
  String? _replyToSenderName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      await ref
          .read(chatServiceProvider)
          .markMessagesAsRead(widget.chatId, currentUser.uid);
    }
  }

  // 🆕 NEW METHOD: Set reply message
  void _setReplyMessage(MessageModel message, String senderName) {
    setState(() {
      _replyToMessage = message;
      _replyToSenderName = senderName;
    });
  }

  // 🆕 NEW METHOD: Cancel reply
  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
      _replyToSenderName = null;
    });
  }

  // 🆕 UPDATED: Send text message with reply support
  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      await ref
          .read(chatServiceProvider)
          .sendMessage(
            chatId: widget.chatId,
            receiverId: widget.friend.uid,
            content: content,
            type: MessageType.text,
            replyToMessageId: _replyToMessage?.messageId,
            replyToContent: _replyToMessage?.content,
            replyToSenderId: _replyToMessage?.senderId,
          );

      _cancelReply(); // Clear reply after sending
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, ErrorHandler.getErrorMessage(e));
    } finally {
      setState(() => _isSending = false);
    }
  }

  // 🆕 NEW METHOD: Add/remove reaction
  Future<void> _addReaction(String messageId, String emoji) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    try {
      await ref
          .read(messageServiceProvider)
          .addReaction(widget.chatId, messageId, emoji, currentUser.uid);
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, ErrorHandler.getErrorMessage(e));
    }
  }

  // 🆕 NEW METHOD: Show message options bottom sheet
  Future<void> _showMessageOptions(MessageModel message) async {
    final currentUser = ref.read(currentUserProvider).value;
    final isMyMessage = message.senderId == currentUser?.uid;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageOptionsSheet(
        message: message,
        isMyMessage: isMyMessage,
        onReactionSelected: (emoji) {
          Navigator.pop(context);
          _addReaction(message.messageId, emoji);
        },
        onReply: () {
          Navigator.pop(context);
          _setReplyMessage(
            message,
            isMyMessage ? 'You' : widget.friend.username,
          );
        },
        onEdit: isMyMessage
            ? () {
                Navigator.pop(context);
                _editMessage(message);
              }
            : null,
        onDelete: isMyMessage
            ? () {
                Navigator.pop(context);
                _deleteMessage(message);
              }
            : null,
        onCopy: () {
          Navigator.pop(context);
          _copyToClipboard(message.content);
        },
      ),
    );
  }

  // 🆕 NEW METHOD: Edit message
  Future<void> _editMessage(MessageModel message) async {
    final controller = TextEditingController(text: message.content);

    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new message',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newContent != null &&
        newContent.isNotEmpty &&
        newContent != message.content) {
      try {
        await ref
            .read(messageServiceProvider)
            .editMessage(widget.chatId, message.messageId, newContent);
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(context, 'Message edited');
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            ErrorHandler.getErrorMessage(e),
          );
        }
      }
    }

    controller.dispose();
  }

  // 🆕 NEW METHOD: Delete message
  Future<void> _deleteMessage(MessageModel message) async {
    final confirm = await ErrorHandler.showConfirmDialog(
      context,
      'Delete Message',
      'Are you sure you want to delete this message?',
    );

    if (!confirm) return;

    try {
      await ref
          .read(messageServiceProvider)
          .deleteMessage(widget.chatId, message.messageId);
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Message deleted');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          ErrorHandler.getErrorMessage(e),
        );
      }
    }
  }

  // 🆕 NEW METHOD: Copy to clipboard
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ErrorHandler.showSuccessSnackBar(context, 'Copied to clipboard');
  }

  Future<void> _sendMediaMessage(MessageType type, File file) async {
    setState(() => _isSending = true);

    try {
      final storageRepo = StorageRepository(
        cloudName: 'dbllcmni2',
        uploadPreset: 'flutter_present',
      );
      final mediaUrl = await storageRepo.uploadChatMedia(
        chatId: widget.chatId,
        file: file,
        fileType: type.toString().split('.').last,
      );

      await ref
          .read(chatServiceProvider)
          .sendMessage(
            chatId: widget.chatId,
            receiverId: widget.friend.uid,
            content: type == MessageType.image
                ? 'Image'
                : type == MessageType.video
                ? 'Video'
                : 'File',
            type: type,
            mediaUrl: mediaUrl,
            fileName: file.path.split('/').last,
          );

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Sent successfully');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          ErrorHandler.getErrorMessage(e),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  // lib/screens/conversation_screen.dart (Part 2 - UI Methods and Build)

  Future<void> _showAttachmentOptions() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Attachment',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildAttachmentOption(
                      icon: Icons.image_rounded,
                      label: 'Photo',
                      color: Colors.blue,
                      onTap: () async {
                        Navigator.pop(context);
                        final image =
                            await ImagePickerService.pickImageFromGallery();
                        if (image != null) {
                          await _sendMediaMessage(MessageType.image, image);
                        }
                      },
                      theme: theme,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildAttachmentOption(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      color: Colors.red,
                      onTap: () async {
                        Navigator.pop(context);
                        final video =
                            await ImagePickerService.pickVideoFromGallery();
                        if (video != null) {
                          await _sendMediaMessage(MessageType.video, video);
                        }
                      },
                      theme: theme,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildAttachmentOption(
                      icon: Icons.insert_drive_file_rounded,
                      label: 'Document',
                      color: Colors.orange,
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await FilePicker.platform.pickFiles();
                        if (result != null &&
                            result.files.single.path != null) {
                          final file = File(result.files.single.path!);
                          await _sendMediaMessage(MessageType.file, file);
                        }
                      },
                      theme: theme,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.1) : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearConversation() async {
    final confirm = await ErrorHandler.showConfirmDialog(
      context,
      'Clear Conversation',
      'Are you sure you want to clear all messages? This action cannot be undone.',
    );

    if (!confirm) return;

    try {
      await ref.read(chatServiceProvider).clearConversation(widget.chatId);
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Conversation cleared');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          ErrorHandler.getErrorMessage(e),
        );
      }
    }
  }

  Future<void> _makeAudioCall() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    if (!ZegoService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call service not ready yet')),
      );
      return;
    }

    final callID = '${widget.chatId}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: [ZegoCallUser(widget.friend.uid, widget.friend.username)],
        isVideoCall: false,
        resourceID: "zego_call",
        callID: callID,
        notificationTitle: 'Incoming call',
        notificationMessage: '${currentUser.username} is calling you...',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to start call')));
      }
    }
  }

  Future<void> _makeVideoCall() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    if (!ZegoService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call service not ready yet')),
      );
      return;
    }

    final callID = '${widget.chatId}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: [ZegoCallUser(widget.friend.uid, widget.friend.username)],
        isVideoCall: true,
        resourceID: "zego_call",
        callID: callID,
        notificationTitle: 'Incoming video call',
        notificationMessage: '${currentUser.username} is video calling you...',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start video call')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final currentUser = ref.watch(currentUserProvider).value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                UserAvatar(
                  imageUrl: widget.friend.avatarUrl,
                  radius: 20,
                  showOnlineIndicator: false,
                ),
                if (widget.friend.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.onlineGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.appBarTheme.backgroundColor!,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friend.username,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatOnlineStatus(widget.friend.lastSeen),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.textTertiaryDark
                          : AppTheme.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: _makeAudioCall,
            tooltip: 'Voice Call',
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: _makeVideoCall,
            tooltip: 'Video Call',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'clear') {
                _clearConversation();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Clear Chat',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No messages yet',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Say hi to ${widget.friend.username}!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.uid;

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      theme: theme,
                      isDark: isDark,
                      currentUserId: currentUser?.uid ?? '',
                      onReaction: _addReaction,
                      onLongPress: _showMessageOptions,
                    );
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Unable to Load Messages',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 🆕 Reply Preview (shows when replying to a message)
          if (_replyToMessage != null && _replyToSenderName != null)
            ReplyPreview(
              replyToMessage: _replyToMessage!,
              senderName: _replyToSenderName!,
              onCancel: _cancelReply,
            ),

          // Message Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    onPressed: _showAttachmentOptions,
                    tooltip: 'Attach file',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppTheme.textTertiaryDark
                                : AppTheme.textTertiaryLight,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        style: theme.textTheme.bodyLarge,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (_isSending)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _sendTextMessage,
                        tooltip: 'Send',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... (Continue in next part with MessageBubble and MessageOptionsSheet)

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final ThemeData theme;
  final bool isDark;
  final String currentUserId;
  final Function(String messageId, String emoji) onReaction;
  final Function(MessageModel message) onLongPress;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.theme,
    required this.isDark,
    required this.currentUserId,
    required this.onReaction,
    required this.onLongPress,
  }) : super(key: key);

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
                      theme.colorScheme.primary.withOpacity(0.85),
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
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🆕 Reply indicator (shows which message this is replying to)
              if (message.replyToContent != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: (isMe ? Colors.white : Colors.black).withOpacity(
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: isMe
                            ? Colors.white.withOpacity(0.5)
                            : theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    message.replyToContent!,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.8)
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

              // Message content (text or image)
              if (message.type == MessageType.image && message.mediaUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: message.mediaUrl!,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.error_outline_rounded, size: 48),
                    ),
                    fit: BoxFit.cover,
                  ),
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

              // 🆕 Reactions display
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
                  // 🆕 Edited indicator
                  if (message.isEdited)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        'edited',
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
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
                          ? Colors.white.withOpacity(0.85)
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
                          : Colors.white.withOpacity(0.85),
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

/////////////////////////////////////next
///
///
///
///
///
///
///
// lib/screens/conversation_screen.dart (Part 4 - MessageOptionsSheet Widget)

/// 🆕 Message Options Bottom Sheet
class _MessageOptionsSheet extends StatelessWidget {
  final MessageModel message;
  final bool isMyMessage;

  final Function(String emoji) onReactionSelected;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onCopy;

  const _MessageOptionsSheet({
    super.key,
    required this.message,
    required this.isMyMessage,
    required this.onReactionSelected,
    required this.onReply,
    this.onEdit,
    this.onDelete,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag Handle ───────────────────────────────
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Emoji Reaction Picker ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ReactionPicker(onReactionSelected: onReactionSelected),
            ),

            const Divider(height: 1),

            // ── Actions ──────────────────────────────────
            _buildOption(
              context,
              icon: Icons.reply_rounded,
              label: 'Reply',
              onTap: onReply,
            ),

            if (onEdit != null && message.type == MessageType.text)
              _buildOption(
                context,
                icon: Icons.edit_rounded,
                label: 'Edit',
                onTap: onEdit,
              ),

            if (message.type == MessageType.text)
              _buildOption(
                context,
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: onCopy,
              ),

            if (onDelete != null)
              _buildOption(
                context,
                icon: Icons.delete_rounded,
                label: 'Delete',
                onTap: onDelete,
                isDestructive: true,
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: onTap is nullable
  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? theme.colorScheme.error
            : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive
              ? theme.colorScheme.error
              : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
        ),
      ),
      onTap: onTap, // ✅ SAFE & ANALYZER-APPROVED
    );
  }
}
