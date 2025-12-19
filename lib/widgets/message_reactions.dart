// lib/widgets/message_reactions.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MessageReactions extends StatelessWidget {
  final Map<String, List<String>>? reactions;
  final String currentUserId;
  final Function(String emoji) onReactionTap;
  final bool isMyMessage;

  const MessageReactions({
    super.key,
    this.reactions,
    required this.currentUserId,
    required this.onReactionTap,
    required this.isMyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions == null || reactions!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: reactions!.entries.map((entry) {
        final emoji = entry.key;
        final users = entry.value;
        final hasReacted = users.contains(currentUserId);

        return GestureDetector(
          onTap: () => onReactionTap(emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasReacted
                  ? theme.colorScheme.primary.withValues(alpha: .2)
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasReacted
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${users.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasReacted
                        ? theme.colorScheme.primary
                        : (isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
