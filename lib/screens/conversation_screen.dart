// lib/screens/conversation_screen.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:new_chart/core/date_formattor.dart';
import 'package:new_chart/core/env_config.dart';
import 'package:new_chart/core/error_handler.dart';
import 'package:new_chart/providers/chart_provider.dart';
import 'package:new_chart/services/image_service.dart';
import 'package:new_chart/services/zego_services.dart';
import 'package:new_chart/widgets/message_bubble.dart';
import 'package:new_chart/widgets/user_avatar.dart';
import 'package:new_chart/widgets/reaction_picker.dart';
import 'package:new_chart/widgets/reply_preview.dart';
import 'package:new_chart/widgets/typing_indicator.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../models/user_model.dart';
import '../widgets/voice_recorder_button.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
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

  // ✅ FIX: Store repository reference to avoid using ref in dispose
  late final _userRepository = ref.read(userRepositoryProvider);
  String? _currentUserId;

  Timer? _typingTimer;
  bool _isCurrentlyTyping = false;

  MessageModel? _replyToMessage;
  String? _replyToSenderName;

  @override
  void initState() {
    super.initState();

    // Store current user ID
    _currentUserId = ref.read(currentUserProvider).value?.uid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });

    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // ✅ FIX: Use stored repository instead of ref
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();

    // ✅ FIX: Stop typing using stored values
    if (_isCurrentlyTyping && _currentUserId != null) {
      _userRepository.updateTypingStatus(
        userId: _currentUserId!,
        isTyping: false,
      );
    }

    super.dispose();
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty && !_isCurrentlyTyping) {
      _startTyping();
    } else if (_messageController.text.isEmpty && _isCurrentlyTyping) {
      _stopTyping();
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _stopTyping();
    });
  }

  void _startTyping() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    _isCurrentlyTyping = true;
    _userRepository.updateTypingStatus(
      userId: currentUser.uid,
      isTyping: true,
      chatId: widget.chatId,
    );
  }

  void _stopTyping() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    if (_isCurrentlyTyping) {
      _isCurrentlyTyping = false;
      _userRepository.updateTypingStatus(
        userId: currentUser.uid,
        isTyping: false,
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      await ref
          .read(chatServiceProvider)
          .markMessagesAsRead(widget.chatId, currentUser.uid);
    }
  }

  void _setReplyMessage(MessageModel message, String senderName) {
    setState(() {
      _replyToMessage = message;
      _replyToSenderName = senderName;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
      _replyToSenderName = null;
    });
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final content = _messageController.text.trim();
    _messageController.clear();
    _stopTyping();

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

      _cancelReply();
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, ErrorHandler.getErrorMessage(e));
    } finally {
      setState(() => _isSending = false);
    }
  }

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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ErrorHandler.showSuccessSnackBar(context, 'Copied to clipboard');
  }

  Future<void> _capturePhoto() async {
    try {
      final image = await ImagePickerService.pickImageFromCamera();
      if (image != null) {
        await _sendMediaMessage(MessageType.image, image);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Failed to capture photo: ${ErrorHandler.getErrorMessage(e)}',
        );
      }
    }
  }

  Future<void> _sendVoiceMessage(String audioPath, Duration duration) async {
    setState(() => _isSending = true);

    try {
      final storageRepo = StorageRepository(
        cloudName: EnvConfig.cloudinaryCloudName,
        uploadPreset: EnvConfig.cloudinaryUploadPreset,
      );

      final file = File(audioPath);
      final audioUrl = await storageRepo.uploadChatMedia(
        chatId: widget.chatId,
        file: file,
        fileType: 'voice',
      );

      await ref
          .read(chatServiceProvider)
          .sendMessage(
            chatId: widget.chatId,
            receiverId: widget.friend.uid,
            content: 'Voice message',
            type: MessageType.voice,
            mediaUrl: audioUrl,
            fileName: '${duration.inSeconds}s',
          );

      if (await file.exists()) {
        await file.delete();
      }

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Voice message sent');
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

  Future<void> _sendMediaMessage(MessageType type, File file) async {
    setState(() => _isSending = true);

    try {
      final storageRepo = StorageRepository(
        cloudName: EnvConfig.cloudinaryCloudName,
        uploadPreset: EnvConfig.cloudinaryUploadPreset,
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
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: Colors.purple,
                      onTap: () async {
                        Navigator.pop(context);
                        await _capturePhoto();
                      },
                      theme: theme,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
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
            color: isDark
                ? color.withValues(alpha: .1)
                : color.withValues(alpha: .05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: .3), width: 1),
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
                      color: color.withValues(alpha: .3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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

  Future<void> _showBlockOptions() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final isBlocked = await _userRepository.isUserBlocked(
      currentUser.uid,
      widget.friend.uid,
    );

    if (!mounted) return;

    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? AppTheme.cardDark
              : AppTheme.cardLight,
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
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  isBlocked ? Icons.block : Icons.block_outlined,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  isBlocked
                      ? 'Unblock ${widget.friend.username}'
                      : 'Block ${widget.friend.username}',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                subtitle: Text(
                  isBlocked
                      ? 'You will be able to receive messages from this user'
                      : 'You will no longer receive messages from this user',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _toggleBlockUser(isBlocked);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBlockUser(bool currentlyBlocked) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    try {
      if (currentlyBlocked) {
        await _userRepository.unblockUser(currentUser.uid, widget.friend.uid);
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(
            context,
            '${widget.friend.username} unblocked',
          );
        }
      } else {
        final confirm = await ErrorHandler.showConfirmDialog(
          context,
          'Block ${widget.friend.username}?',
          'You will no longer receive messages from this user.',
        );

        if (!confirm) return;

        await _userRepository.blockUser(currentUser.uid, widget.friend.uid);
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(
            context,
            '${widget.friend.username} blocked',
          );
          Navigator.pop(context);
        }
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
    final friendAsync = ref.watch(userStreamProvider(widget.friend.uid));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ✅ FIX: Check if user is blocked
    final isBlockedFuture = currentUser != null
        ? _userRepository.isUserBlocked(currentUser.uid, widget.friend.uid)
        : Future.value(false);

    return FutureBuilder<bool>(
      future: isBlockedFuture,
      builder: (context, blockSnapshot) {
        final isBlocked = blockSnapshot.data ?? false;

        // ✅ FIX: Show blocked user UI
        if (isBlocked) {
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
              title: Text(widget.friend.username),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    if (value == 'unblock') {
                      _toggleBlockUser(true);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'unblock',
                      child: Row(
                        children: [
                          Icon(
                            Icons.block,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Unblock User',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: .1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.block_rounded,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'User Blocked',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have blocked ${widget.friend.username}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _toggleBlockUser(true),
                      icon: const Icon(Icons.block),
                      label: const Text('Unblock User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

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
            title: friendAsync.when(
              data: (friend) {
                if (friend == null) {
                  return Text(widget.friend.username);
                }

                return Row(
                  children: [
                    Stack(
                      children: [
                        UserAvatar(
                          imageUrl: friend.avatarUrl,
                          radius: 20,
                          showOnlineIndicator: false,
                        ),
                        if (friend.isOnline)
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
                            friend.username,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            friend.isTyping &&
                                    friend.typingInChatId == widget.chatId
                                ? 'typing...'
                                : friend.isOnline
                                ? 'Online'
                                : DateFormatter.formatOnlineStatus(
                                    friend.lastSeen,
                                  ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color:
                                  friend.isTyping &&
                                      friend.typingInChatId == widget.chatId
                                  ? theme.colorScheme.primary
                                  : friend.isOnline
                                  ? AppTheme.onlineGreen
                                  : (isDark
                                        ? AppTheme.textTertiaryDark
                                        : AppTheme.textTertiaryLight),
                              fontStyle:
                                  friend.isTyping &&
                                      friend.typingInChatId == widget.chatId
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => Row(
                children: [
                  UserAvatar(imageUrl: widget.friend.avatarUrl, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.friend.username,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              error: (_, __) => Row(
                children: [
                  UserAvatar(imageUrl: widget.friend.avatarUrl, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.friend.username,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
                  } else if (value == 'block') {
                    _showBlockOptions();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(
                          Icons.block_rounded,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Block User',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
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
                                color: theme.colorScheme.primary.withValues(
                                  alpha: .1,
                                ),
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

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            key: const PageStorageKey('messages_list'),
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe = message.senderId == currentUser?.uid;

                              return MessageBubble(
                                key: ValueKey(message.messageId),
                                message: message,
                                isMe: isMe,
                                theme: theme,
                                isDark: isDark,
                                currentUserId: currentUser?.uid ?? '',
                                onReaction: _addReaction,
                                onLongPress: _showMessageOptions,
                              );
                            },
                          ),
                        ),

                        friendAsync.when(
                          data: (friend) {
                            if (friend != null &&
                                friend.isTyping &&
                                friend.typingInChatId == widget.chatId) {
                              return TypingIndicator(isDark: isDark);
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
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
                              color: theme.colorScheme.error.withValues(
                                alpha: .1,
                              ),
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

              if (_replyToMessage != null && _replyToSenderName != null)
                ReplyPreview(
                  replyToMessage: _replyToMessage!,
                  senderName: _replyToSenderName!,
                  onCancel: _cancelReply,
                ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.05,
                      ),
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
                            onChanged: (value) => setState(() {}),
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
                      else if (_messageController.text.isEmpty)
                        VoiceRecorderButton(
                          onRecordingComplete: _sendVoiceMessage,
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(alpha: .8),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: .3,
                                ),
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
      },
    );
  }
}

class _MessageOptionsSheet extends StatelessWidget {
  final MessageModel message;
  final bool isMyMessage;
  final Function(String emoji) onReactionSelected;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onCopy;

  const _MessageOptionsSheet({
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ReactionPicker(onReactionSelected: onReactionSelected),
            ),

            const Divider(height: 1),

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
      onTap: onTap,
    );
  }
}
