import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final bool showOnlineIndicator;
  final bool isOnline;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: .1),
      backgroundImage: imageUrl != null
          ? CachedNetworkImageProvider(imageUrl!)
          : null,
      child: imageUrl == null
          ? Icon(
              Icons.person_rounded,
              size: radius * 1.2,
              color: theme.colorScheme.primary,
            )
          : null,
    );

    if (showOnlineIndicator) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: radius * 0.35,
                height: radius * 0.35,
                decoration: BoxDecoration(
                  color: AppTheme.onlineGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.onlineGreen.withValues(alpha: .5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
