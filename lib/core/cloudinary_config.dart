import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/storage_repository.dart';
import 'env_config.dart';

class CloudinaryConfig {
  static String get cloudName => EnvConfig.cloudinaryCloudName;
  static String get uploadPreset => EnvConfig.cloudinaryUploadPreset;
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(
    cloudName: CloudinaryConfig.cloudName,
    uploadPreset: CloudinaryConfig.uploadPreset,
  );
});
