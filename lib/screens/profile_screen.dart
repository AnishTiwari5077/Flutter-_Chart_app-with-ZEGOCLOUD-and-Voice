// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_chart/core/error_handler.dart';
import 'package:new_chart/core/validator.dart';
import 'package:new_chart/services/image_service.dart';
import 'package:new_chart/widgets/loading_overlay.dart';
import 'package:new_chart/widgets/user_avatar.dart';

import '../../providers/auth_provider.dart';

import '../../repositories/user_repository.dart';
import '../../repositories/storage_repository.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

// Constants
class ProfileConstants {
  static const double avatarRadius = 60.0;
  static const double editAvatarRadius = 50.0;
  static const double spacing = 24.0;
  static const double cardSpacing = 12.0;
  static const double buttonPaddingHorizontal = 32.0;
  static const double buttonPaddingVertical = 12.0;
}

// Providers
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(
    cloudName: 'dbllcmni2',
    uploadPreset: 'flutter_present',
  );
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = false;

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

  Future<void> _logout() async {
    final confirm = await ErrorHandler.showConfirmDialog(
      context,
      'Logout',
      'Are you sure you want to logout?',
    );

    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      // Perform logout
      await ref.read(authRepositoryProvider).signOut();

      // The AuthenticationWrapper in main.dart will handle:
      // 1. Invalidating all providers
      // 2. Uninitializing Zego
      // 3. Navigating to SignInScreen

      // No need to manually navigate or clean up here
      print('✅ Logout successful');
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: 64,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'User not found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(ProfileConstants.spacing),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Avatar with edit indicator
                  Stack(
                    children: [
                      UserAvatar(
                        imageUrl: user.avatarUrl,
                        radius: ProfileConstants.avatarRadius,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Username
                  Text(
                    user.username,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Email
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),

                  const SizedBox(height: ProfileConstants.spacing),

                  // Status Card
                  _buildStatusCard(user.isOnline, theme, isDark),

                  const SizedBox(height: ProfileConstants.cardSpacing),

                  // Info Cards
                  _buildInfoCard(
                    icon: Icons.person_outlined,
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

                  const SizedBox(height: ProfileConstants.spacing * 1.5),

                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _editProfile,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ProfileConstants.buttonPaddingHorizontal,
                          vertical: ProfileConstants.buttonPaddingVertical,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Member Since
                  Text(
                    'Member since ${user.createdAt.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
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
                    'Error Loading Profile',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ErrorHandler.getErrorMessage(error),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(currentUserProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
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
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 24),
        ),
        title: Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isOnline, ThemeData theme, bool isDark) {
    final statusColor = isOnline ? Colors.green : Colors.grey;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.circle, color: statusColor, size: 24),
        ),
        title: Text(
          'Status',
          style: theme.textTheme.labelLarge?.copyWith(
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isOnline ? 'Online' : 'Offline',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// Edit Profile Dialog
class EditProfileDialog extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfileDialog({super.key, required this.user});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  bool _isLoading = false;
  File? _newAvatar;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _newAvatar = null;
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_isLoading) return;

    try {
      await ImagePickerService.showImageSourceDialog(context, (file) {
        if (file != null && mounted) {
          setState(() => _newAvatar = file);
        }
      }, allowCrop: true);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Failed to pick image: ${ErrorHandler.getErrorMessage(e)}',
        );
      }
    }
  }

  void _removeAvatar() {
    if (_isLoading) return;
    setState(() => _newAvatar = null);
  }

  bool _hasChanges() {
    final usernameChanged =
        _usernameController.text.trim() != widget.user.username;
    final avatarChanged = _newAvatar != null;
    return usernameChanged || avatarChanged;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasChanges()) {
      Navigator.of(context).pop(false);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final storageRepo = ref.read(storageRepositoryProvider);

      final newUsername = _usernameController.text.trim();
      if (newUsername != widget.user.username && newUsername.isNotEmpty) {
        await userRepo.updateUsername(widget.user.uid, newUsername);
      }

      if (_newAvatar != null) {
        final avatarUrl = await storageRepo.uploadAvatar(
          widget.user.uid,
          _newAvatar!,
        );
        await userRepo.updateAvatar(widget.user.uid, avatarUrl);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ErrorHandler.showSuccessSnackBar(
          context,
          'Profile updated successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update profile';

        if (e is NetworkException) {
          errorMessage = 'Network error: ${e.message}';
        } else if (e is ValidationException) {
          errorMessage = 'Validation error: ${e.message}';
        } else {
          errorMessage = ErrorHandler.getErrorMessage(e);
        }

        ErrorHandler.showErrorSnackBar(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Updating profile...',
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(ProfileConstants.spacing),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Profile',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: ProfileConstants.spacing),
                  _buildAvatarPicker(theme),
                  const SizedBox(height: ProfileConstants.spacing),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    validator: Validators.validateUsername,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _saveChanges(),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: ProfileConstants.spacing),
                  _buildActionButtons(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker(ThemeData theme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _pickAvatar,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: ProfileConstants.editAvatarRadius,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage: _getAvatarImage(),
              child: _getAvatarPlaceholder(theme),
            ),
          ),
        ),
        if (_newAvatar != null)
          Positioned(
            top: -5,
            right: -5,
            child: GestureDetector(
              onTap: _isLoading ? null : _removeAvatar,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isLoading ? null : _pickAvatar,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? _getAvatarImage() {
    if (_newAvatar != null) {
      return FileImage(_newAvatar!) as ImageProvider;
    } else if (widget.user.avatarUrl != null) {
      return NetworkImage(widget.user.avatarUrl!) as ImageProvider;
    }
    return null;
  }

  Widget? _getAvatarPlaceholder(ThemeData theme) {
    if (_newAvatar == null && widget.user.avatarUrl == null) {
      return Icon(
        Icons.person_outlined,
        size: 50,
        color: theme.colorScheme.primary,
      );
    }
    return null;
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveChanges,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}

// Custom Exception Classes
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
