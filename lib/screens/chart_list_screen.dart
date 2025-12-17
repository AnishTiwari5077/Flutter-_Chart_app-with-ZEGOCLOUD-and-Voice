import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_chart/core/date_formattor.dart';
import 'package:new_chart/providers/chart_provider.dart';
import 'package:new_chart/screens/conversation_screen.dart';
import 'package:new_chart/widgets/empty_state.dart';
import 'package:new_chart/widgets/user_avatar.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatListProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Chats'), elevation: 0),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              message: 'No chats yet',
              subtitle: 'Start chatting with your friends',
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 72,
              color: isDark
                  ? Colors.grey.shade800.withOpacity(0.5)
                  : Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final friendId = chat.participants.firstWhere(
                (id) => id != currentUser?.uid,
              );

              return Consumer(
                builder: (context, ref, child) {
                  final friendAsync = ref.watch(userStreamProvider(friendId));

                  return friendAsync.when(
                    data: (friend) {
                      if (friend == null) return const SizedBox.shrink();

                      final unreadCount =
                          chat.unreadCount[currentUser?.uid] ?? 0;
                      final hasUnread = unreadCount > 0;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ConversationScreen(
                                  chatId: chat.chatId,
                                  friend: friend,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                UserAvatar(
                                  imageUrl: friend.avatarUrl,
                                  showOnlineIndicator: true,
                                  isOnline: friend.isOnline,
                                  radius: 28,
                                ),

                                const SizedBox(width: 12),

                                // Chat Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Username
                                      Text(
                                        friend.username,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: hasUnread
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: isDark
                                                  ? AppTheme.textPrimaryDark
                                                  : AppTheme.textPrimaryLight,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const SizedBox(height: 4),

                                      // Last Message
                                      Text(
                                        chat.lastMessage ?? 'No messages yet',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: hasUnread
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: hasUnread
                                                  ? (isDark
                                                        ? AppTheme
                                                              .textPrimaryDark
                                                        : AppTheme
                                                              .textPrimaryLight)
                                                  : (isDark
                                                        ? AppTheme
                                                              .textSecondaryDark
                                                        : AppTheme
                                                              .textSecondaryLight),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Time and Unread Badge
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Time
                                    if (chat.lastMessageTime != null)
                                      Text(
                                        DateFormatter.formatChatTime(
                                          chat.lastMessageTime!,
                                        ),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 12,
                                          fontWeight: hasUnread
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: hasUnread
                                              ? theme.colorScheme.primary
                                              : (isDark
                                                    ? AppTheme.textSecondaryDark
                                                    : AppTheme
                                                          .textSecondaryLight),
                                        ),
                                      ),

                                    // Unread Badge
                                    if (hasUnread) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          unreadCount > 99
                                              ? '99+'
                                              : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 16,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 14,
                                  width: 180,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
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
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Chats',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
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
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(chatListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
