// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_chart/core/env_config.dart';
import 'package:new_chart/core/error_handler.dart';
import 'package:new_chart/widgets/loading_overlay.dart';
import 'package:new_chart/widgets/profile_edit_dialog.dart';
import 'package:new_chart/widgets/user_avatar.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/storage_repository.dart';
import '../../theme/app_theme.dart';

class ProfileConstants {
  static const double avatarRadius = 60.0;
  static const double editAvatarRadius = 50.0;
  static const double spacing = 24.0;
  static const double cardSpacing = 12.0;
  static const double buttonPaddingHorizontal = 32.0;
  static const double buttonPaddingVertical = 12.0;
  static const double sectionSpacing = 32.0;
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(
    cloudName: EnvConfig.cloudinaryCloudName,
    uploadPreset: EnvConfig.cloudinaryUploadPreset,
  );
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = false;
  bool _isTogglingStatus = false;

  Future<void> _editProfile() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditProfileDialog(user: currentUser),
    );

    if (result == true) {
      ref.invalidate(currentUserProvider);
    }
  }

  Future<void> _toggleOnlineStatus(bool currentStatus) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() => _isTogglingStatus = true);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      await userRepository.updateUserStatus(
        userId: currentUser.uid,
        isOnline: !currentStatus,
      );

      // Refresh the user data
      ref.invalidate(currentUserProvider);

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Status updated to ${!currentStatus ? "Online" : "Offline"}',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          ErrorHandler.getErrorMessage(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingStatus = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await ErrorHandler.showConfirmDialog(
      context,
      'Logout',
      'Are you sure you want to logout?',
    );

    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).logout();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorSnackBar(
          context,
          ErrorHandler.getErrorMessage(e),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Logging out...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: _isLoading ? null : _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: currentUserAsync.when(
          data: (user) {
            if (user == null) {
              return _buildEmptyState(theme, isDark);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(ProfileConstants.spacing),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Avatar Section
                  _buildAvatarSection(user, theme),

                  const SizedBox(height: 20),

                  // Username & Email
                  _buildUserInfo(user, theme, isDark),

                  const SizedBox(height: ProfileConstants.sectionSpacing),

                  // Privacy & Settings Section
                  _buildSectionHeader('Privacy & Settings', theme, isDark),
                  const SizedBox(height: ProfileConstants.cardSpacing),

                  // Online Status Toggle
                  _buildOnlineStatusCard(user.isOnline, theme, isDark),

                  const SizedBox(height: ProfileConstants.sectionSpacing),

                  // Account Information Section
                  _buildSectionHeader('Account Information', theme, isDark),
                  const SizedBox(height: ProfileConstants.cardSpacing),

                  _buildInfoCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Username',
                    subtitle: user.username,
                    theme: theme,
                    isDark: isDark,
                  ),

                  const SizedBox(height: ProfileConstants.cardSpacing),

                  _buildInfoCard(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: user.email,
                    theme: theme,
                    isDark: isDark,
                  ),

                  const SizedBox(height: ProfileConstants.cardSpacing),

                  _buildInfoCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Member Since',
                    subtitle: _formatDate(user.createdAt),
                    theme: theme,
                    isDark: isDark,
                  ),

                  const SizedBox(height: ProfileConstants.sectionSpacing),

                  // Actions Section
                  _buildSectionHeader('Actions', theme, isDark),
                  const SizedBox(height: ProfileConstants.cardSpacing),

                  // Edit Profile Button
                  _buildActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    onPressed: _isLoading ? null : _editProfile,
                    isPrimary: true,
                    theme: theme,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error, theme, isDark),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(dynamic user, ThemeData theme) {
    return Stack(
      children: [
        Hero(
          tag: 'profile_avatar_${user.uid}',
          child: UserAvatar(
            imageUrl: user.avatarUrl,
            radius: ProfileConstants.avatarRadius,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _editProfile,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(dynamic user, ThemeData theme, bool isDark) {
    return Column(
      children: [
        Text(
          user.username,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppTheme.textPrimaryDark
                : AppTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 16,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
            ),
            const SizedBox(width: 6),
            Text(
              user.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildOnlineStatusCard(bool isOnline, ThemeData theme, bool isDark) {
    final statusColor = isOnline ? Colors.green : Colors.grey;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isOnline
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: statusColor,
            size: 24,
          ),
        ),
        title: Text(
          'Online Status',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.textPrimaryDark
                : AppTheme.textPrimaryLight,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isOnline ? 'Visible to all users' : 'Appear offline to others',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
            ),
          ),
        ),
        trailing: _isTogglingStatus
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Switch(
                value: isOnline,
                onChanged: _isTogglingStatus
                    ? null
                    : (value) => _toggleOnlineStatus(isOnline),
                activeThumbColor: Colors.green,
              ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 24),
        ),
        title: Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isPrimary,
    required ThemeData theme,
  }) {
    return SizedBox(
      width: double.infinity,
      child: isPrimary
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: ProfileConstants.buttonPaddingHorizontal,
                  vertical: ProfileConstants.buttonPaddingVertical + 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: ProfileConstants.buttonPaddingHorizontal,
                  vertical: ProfileConstants.buttonPaddingVertical + 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 80,
            color: isDark
                ? AppTheme.textSecondaryDark.withValues(alpha: 0.5)
                : AppTheme.textSecondaryLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'User Not Found',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load profile information',
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

  Widget _buildErrorState(Object error, ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ErrorHandler.getErrorMessage(error),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => ref.invalidate(currentUserProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
