import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/storage_repository.dart';

// ==========================================
// 1. CREATE A CONFIG FILE FOR CLOUDINARY
// ==========================================
// lib/core/cloudinary_config.dart

class CloudinaryConfig {
  // Get these from your Cloudinary dashboard
  // https://cloudinary.com/console
  static const String cloudName = 'dbllcmni2'; // e.g., 'dxxxxx'
  static const String uploadPreset = 'new_chart'; // e.g., 'my_app_preset'

  // Optional: API Key and Secret (for backend operations)
  static const String apiKey = '314485714938889';
  static const String apiSecret = 'hS5Yvzqo4a7ywFBXc0uRmproVFQ';
}

// ==========================================
// 2. UPDATE YOUR STORAGE REPOSITORY PROVIDER
// ==========================================
// Replace your existing storageRepositoryProvider with this:

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(
    cloudName: CloudinaryConfig.cloudName,
    uploadPreset: CloudinaryConfig.uploadPreset,
  );
});
