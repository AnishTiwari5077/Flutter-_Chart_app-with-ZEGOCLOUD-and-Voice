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
  static const String uploadPreset = 'flutter_present'; // e.g., 'my_app_preset'

  // Optional: API Key and Secret (for backend operations)
  static const String apiKey = '892336869665979';
  static const String apiSecret = '84oTVFESrL7ZVxBWPuxK1wmo8Tk';
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
