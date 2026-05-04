// image_upload_helper.dart
// Create this new file in your lib/helpers/ directory

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class ImageUploadHelper {
  /// Pick an image file from device
  static Future<String?> pickImageFromDevice() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        String sourcePath = result.files.single.path!;

        // Copy image to app's permanent storage
        String? savedPath = await _saveImageToAppDirectory(sourcePath);
        return savedPath;
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Save image to app's permanent directory
  static Future<String?> _saveImageToAppDirectory(String sourcePath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = '${appDir.path}/images';

      // Create images directory if it doesn't exist
      final Directory imageDirectory = Directory(imagesDir);
      if (!await imageDirectory.exists()) {
        await imageDirectory.create(recursive: true);
      }

      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(sourcePath);
      final String fileName = 'image_$timestamp$extension';
      final String destinationPath = '$imagesDir/$fileName';

      // Copy file
      final File sourceFile = File(sourcePath);
      await sourceFile.copy(destinationPath);

      // Save mapping in SharedPreferences for future reference
      await _saveImagePathMapping(fileName, destinationPath);

      return destinationPath;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  /// Save image path mapping
  static Future<void> _saveImagePathMapping(
    String fileName,
    String fullPath,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    String? mappingJson = prefs.getString('image_path_mappings');
    Map<String, String> mappings = {};

    if (mappingJson != null) {
      try {
        mappings = Map<String, String>.from(jsonDecode(mappingJson));
      } catch (e) {
        mappings = {};
      }
    }

    mappings[fileName] = fullPath;
    await prefs.setString('image_path_mappings', jsonEncode(mappings));
  }

  /// Check if path is local file
  static bool isLocalFile(String path) {
    return path.startsWith('/') ||
        path.contains('documents/images/') ||
        File(path).existsSync();
  }

  /// Get image type (local, asset)
  static ImageSourceType getImageSourceType(String imagePath) {
    if (imagePath.startsWith('lib/assets/')) {
      return ImageSourceType.asset;
    } else if (isLocalFile(imagePath)) {
      return ImageSourceType.file;
    } else {
      return ImageSourceType.unknown;
    }
  }

  /// Delete uploaded image
  static Future<bool> deleteUploadedImage(String imagePath) async {
    try {
      if (isLocalFile(imagePath) && !imagePath.startsWith('lib/assets/')) {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Get image widget based on source type
  static Widget getImageWidget(
    String imagePath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    final sourceType = getImageSourceType(imagePath);

    switch (sourceType) {
      case ImageSourceType.asset:
        return Image.asset(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder:
              (context, error, stackTrace) =>
                  errorWidget ?? _defaultErrorWidget(width, height),
        );

      case ImageSourceType.file:
        return Image.file(
          File(imagePath),
          width: width,
          height: height,
          fit: fit,
          errorBuilder:
              (context, error, stackTrace) =>
                  errorWidget ?? _defaultErrorWidget(width, height),
        );

      default:
        return errorWidget ?? _defaultErrorWidget(width, height);
    }
  }

  static Widget _defaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade700,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
      ),
    );
  }
}

enum ImageSourceType { asset, file, unknown }
