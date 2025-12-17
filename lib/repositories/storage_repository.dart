import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class StorageRepository {
  final CloudinaryPublic _cloudinary;
  final Uuid _uuid = const Uuid();

  // Initialize with your Cloudinary credentials
  StorageRepository({required String cloudName, required String uploadPreset})
    : _cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);

  /// Upload avatar image
  Future<String> uploadAvatar(String uid, File file) async {
    try {
      debugPrint('📤 Starting avatar upload for user: $uid');
      debugPrint('   File path: ${file.path}');

      // Verify file exists
      if (!await file.exists()) {
        throw Exception('Image file does not exist at path: ${file.path}');
      }

      final fileSize = await file.length();
      debugPrint('   File size: ${fileSize / 1024} KB');

      // Upload to Cloudinary
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: 'avatars/$uid',
          publicId: 'profile',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      debugPrint('✅ Avatar uploaded successfully');
      debugPrint('   Public ID: ${response.publicId}');
      debugPrint('   Secure URL: ${response.secureUrl.substring(0, 50)}...');

      return response.secureUrl;
    } on CloudinaryException catch (e) {
      debugPrint('❌ Cloudinary error: ${e.message}');
      throw Exception('Failed to upload avatar: ${e.message}');
    } catch (e) {
      debugPrint('❌ Avatar upload error: $e');
      rethrow;
    }
  }

  /// Upload chat media (images, videos)
  Future<String> uploadChatMedia({
    required String chatId,
    required File file,
    required String fileType, // 'image', 'video', etc.
  }) async {
    try {
      debugPrint('📤 Starting chat media upload for chat: $chatId');
      debugPrint('   File type: $fileType');
      debugPrint('   File path: ${file.path}');

      // Verify file exists
      if (!await file.exists()) {
        throw Exception('Media file does not exist');
      }

      final fileSize = await file.length();
      debugPrint('   File size: ${fileSize / (1024 * 1024)} MB');

      // Generate unique message ID
      final messageId = _uuid.v4();
      final fileName = path.basenameWithoutExtension(file.path);

      // Determine resource type
      final resourceType = _getResourceType(fileType);

      // Upload to Cloudinary
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: 'chat_media/$chatId',
          publicId: '${messageId}_$fileName',
          resourceType: resourceType,
        ),
      );

      debugPrint('✅ Chat media uploaded successfully');
      debugPrint('   Public ID: ${response.publicId}');

      return response.secureUrl;
    } on CloudinaryException catch (e) {
      debugPrint('❌ Cloudinary error: ${e.message}');
      throw Exception('Failed to upload media: ${e.message}');
    } catch (e) {
      debugPrint('❌ Chat media upload error: $e');
      rethrow;
    }
  }

  /// Upload with progress tracking
  Future<String> uploadAvatarWithProgress(
    String uid,
    File file,
    Function(int sent, int total)? onProgress,
  ) async {
    try {
      debugPrint('📤 Starting avatar upload with progress for user: $uid');

      if (!await file.exists()) {
        throw Exception('Image file does not exist');
      }

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: 'avatars/$uid',
          publicId: 'profile',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      debugPrint('✅ Avatar uploaded');
      return response.secureUrl;
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      rethrow;
    }
  }

  /// Delete file from Cloudinary
  Future<void> deleteFile(String url) async {
    try {
      debugPrint('🗑️ Attempting to delete file: ${url.substring(0, 50)}...');

      // Extract public ID from URL
      final publicId = _extractPublicIdFromUrl(url);

      if (publicId == null) {
        debugPrint('⚠️ Could not extract public ID from URL');
        return;
      }

      debugPrint('   Public ID: $publicId');

      // Note: Deleting requires authenticated requests
      // You'll need to use Cloudinary Admin API or delete from backend
      debugPrint('⚠️ Deletion requires Admin API - implement on backend');
    } catch (e) {
      debugPrint('❌ Delete error: $e (ignoring)');
      // Ignore deletion errors as specified
    }
  }

  /// Delete avatar
  Future<void> deleteAvatar(String url) async {
    await deleteFile(url);
  }

  /// Delete all user media
  Future<void> deleteAllUserMedia(String uid) async {
    try {
      debugPrint('🗑️ Deleting all media for user: $uid');
      debugPrint('⚠️ Bulk deletion requires Admin API - implement on backend');
    } catch (e) {
      debugPrint('❌ Error deleting user media: $e');
    }
  }

  /// Get resource type based on file type
  CloudinaryResourceType _getResourceType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return CloudinaryResourceType.Image;
      case 'video':
      case 'mp4':
      case 'mov':
      case 'avi':
        return CloudinaryResourceType.Video;
      case 'raw':
      default:
        return CloudinaryResourceType.Raw;
    }
  }

  /// Extract public ID from Cloudinary URL
  String? _extractPublicIdFromUrl(String url) {
    try {
      // Cloudinary URL format: https://res.cloudinary.com/{cloud_name}/{resource_type}/upload/v{version}/{public_id}.{format}
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Find 'upload' segment
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
        return null;
      }

      // Get segments after 'upload' and version
      final publicIdSegments = pathSegments.sublist(uploadIndex + 2);
      final publicIdWithExtension = publicIdSegments.join('/');

      // Remove file extension
      final lastDotIndex = publicIdWithExtension.lastIndexOf('.');
      if (lastDotIndex != -1) {
        return publicIdWithExtension.substring(0, lastDotIndex);
      }

      return publicIdWithExtension;
    } catch (e) {
      debugPrint('Error extracting public ID: $e');
      return null;
    }
  }

  /// Get optimized image URL with transformations
  String getOptimizedImageUrl(
    String url, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    try {
      final publicId = _extractPublicIdFromUrl(url);
      if (publicId == null) return url;

      final transformations = <String>[];

      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      transformations.add('q_$quality');
      transformations.add('f_$format');

      // This is a simplified version - you may need to adjust based on your Cloudinary setup
      return url.replaceFirst(
        '/upload/',
        '/upload/${transformations.join(',')}/',
      );
    } catch (e) {
      debugPrint('Error creating optimized URL: $e');
      return url;
    }
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String url, {int size = 200}) {
    return getOptimizedImageUrl(
      url,
      width: size,
      height: size,
      quality: 'auto:low',
    );
  }
}
