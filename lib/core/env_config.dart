import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Cloudinary
  static String get cloudinaryCloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get cloudinaryUploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  // ZEGO
  static int get zegoAppId =>
      int.tryParse(dotenv.env['ZEGO_APP_ID'] ?? '0') ?? 0;
  static String get zegoAppSign => dotenv.env['ZEGO_APP_SIGN'] ?? '';

  // Notifications
  static String get notificationBackendUrl =>
      dotenv.env['NOTIFICATION_BACKEND_URL'] ?? '';

  // Firebase (Android)
  static String get firebaseAndroidApiKey =>
      dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
  static String get firebaseAndroidAppId =>
      dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';

  // Firebase (Shared)
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseDatabaseUrl =>
      dotenv.env['FIREBASE_DATABASE_URL'] ?? '';
  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';

  static bool get isConfigured {
    return cloudinaryCloudName.isNotEmpty &&
        zegoAppId != 0 &&
        firebaseProjectId.isNotEmpty;
  }
}
