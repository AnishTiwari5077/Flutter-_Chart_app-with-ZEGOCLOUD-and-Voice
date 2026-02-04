import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get cloudinaryCloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get cloudinaryUploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  static int get zegoAppId =>
      int.tryParse(dotenv.env['ZEGO_APP_ID'] ?? '0') ?? 0;
  static String get zegoAppSign => dotenv.env['ZEGO_APP_SIGN'] ?? '';
  static String get notificationBackendUrl =>
      dotenv.env['NOTIFICATION_BACKEND_URL'] ?? '';

  static bool get isConfigured {
    return cloudinaryCloudName.isNotEmpty && zegoAppId != 0;
  }
}
