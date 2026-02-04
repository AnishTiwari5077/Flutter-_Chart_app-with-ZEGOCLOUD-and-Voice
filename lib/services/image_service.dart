import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      rethrow;
    }
  }

  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      rethrow;
    }
  }

  static Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking video: $e');
      rethrow;
    }
  }

  static Future<File?> cropImage(File imageFile, BuildContext context) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressQuality: 85,
        maxWidth: 1080,
        maxHeight: 1080,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            initAspectRatio: CropAspectRatioPreset.square,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        debugPrint('Cropped image path: ${croppedFile.path}');
        final file = File(croppedFile.path);

        if (await file.exists()) {
          debugPrint(
            'Cropped file exists and size: ${await file.length()} bytes',
          );
          return file;
        } else {
          debugPrint('Cropped file does not exist!');
          return imageFile;
        }
      }
      debugPrint('Cropping was cancelled, returning original');
      return imageFile;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return imageFile;
    }
  }

  static Future<void> showImageSourceDialog(
    BuildContext context,
    Function(File?) onImageSelected, {
    bool allowCrop = true,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select Image Source',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final image = await pickImageFromCamera();
                  debugPrint('Picked from camera: ${image?.path}');

                  if (image != null) {
                    File? finalImage = image;
                    if (allowCrop && context.mounted) {
                      finalImage = await cropImage(image, context);
                      debugPrint('After crop: ${finalImage?.path}');
                    }
                    // Always callback with the final image
                    onImageSelected(finalImage);
                  } else {
                    onImageSelected(null);
                  }
                } catch (e) {
                  debugPrint('Error in camera flow: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to capture image: $e')),
                    );
                  }
                  onImageSelected(null);
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final image = await pickImageFromGallery();
                  debugPrint('Picked from gallery: ${image?.path}');

                  if (image != null) {
                    File? finalImage = image;
                    if (allowCrop && context.mounted) {
                      finalImage = await cropImage(image, context);
                      debugPrint('After crop: ${finalImage?.path}');
                    }
                    // Always callback with the final image
                    onImageSelected(finalImage);
                  } else {
                    onImageSelected(null);
                  }
                } catch (e) {
                  debugPrint('Error in gallery flow: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to select image: $e')),
                    );
                  }
                  onImageSelected(null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
