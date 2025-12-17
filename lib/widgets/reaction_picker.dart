// lib/widgets/reaction_picker.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onReactionSelected;

  const ReactionPicker({super.key, required this.onReactionSelected});

  static const List<String> quickReactions = [
    '❤️',
    '👍',
    '😂',
    '😮',
    '😢',
    '🙏',
    '🔥',
    '🎉',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: quickReactions.map((emoji) {
          return GestureDetector(
            onTap: () => onReactionSelected(emoji),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
