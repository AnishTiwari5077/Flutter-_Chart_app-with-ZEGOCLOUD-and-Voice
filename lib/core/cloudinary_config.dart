import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/storage_repository.dart';

class CloudinaryConfig {
  static const String cloudName = ''; // Your cloud name
  static const String uploadPreset = ''; //uploadpreset

  static const String apiKey = '';// api key
  static const String apiSecret = ''; apisecret key
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(
    cloudName: CloudinaryConfig.cloudName,
    uploadPreset: CloudinaryConfig.uploadPreset,
  );
});
