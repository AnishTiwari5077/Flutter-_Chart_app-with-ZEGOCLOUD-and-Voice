import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/storage_repository.dart';

class CloudinaryConfig {
  static const String cloudName = 'dbllcmni2';
  static const String uploadPreset = 'new_chart';

  static const String apiKey = '314485714938889';
  static const String apiSecret = 'hS5Yvzqo4a7ywFBXc0uRmproVFQ';
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(
    cloudName: CloudinaryConfig.cloudName,
    uploadPreset: CloudinaryConfig.uploadPreset,
  );
});
