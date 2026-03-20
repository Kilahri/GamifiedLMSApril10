// video_upload_helper.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class VideoUploadHelper {
  /// Extract YouTube video ID from any YouTube URL format
  static String? extractYoutubeId(String url) {
    if (url.isEmpty) return null;

    // Handles:
    // https://www.youtube.com/watch?v=VIDEO_ID
    // https://youtu.be/VIDEO_ID
    // https://www.youtube.com/embed/VIDEO_ID
    // https://www.youtube.com/shorts/VIDEO_ID
    final regexps = [
      RegExp(r'youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be\/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/embed\/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})'),
    ];

    for (final regex in regexps) {
      final match = regex.firstMatch(url);
      if (match != null) return match.group(1);
    }
    return null;
  }

  /// Check if a URL is a YouTube URL
  static bool isYoutubeUrl(String url) {
    return extractYoutubeId(url) != null;
  }

  /// Pick a video file from device
  static Future<String?> pickVideoFromDevice() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        String sourcePath = result.files.single.path!;
        String? savedPath = await _saveVideoToAppDirectory(sourcePath);
        return savedPath;
      }
      return null;
    } catch (e) {
      print('Error picking video: $e');
      return null;
    }
  }

  /// Save video to app's permanent directory
  static Future<String?> _saveVideoToAppDirectory(String sourcePath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videosDir = '${appDir.path}/videos';

      final Directory videoDirectory = Directory(videosDir);
      if (!await videoDirectory.exists()) {
        await videoDirectory.create(recursive: true);
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(sourcePath);
      final String fileName = 'video_$timestamp$extension';
      final String destinationPath = '$videosDir/$fileName';

      final File sourceFile = File(sourcePath);
      await sourceFile.copy(destinationPath);

      await _saveVideoPathMapping(fileName, destinationPath);

      return destinationPath;
    } catch (e) {
      print('Error saving video: $e');
      return null;
    }
  }

  /// Save video path mapping
  static Future<void> _saveVideoPathMapping(
    String fileName,
    String fullPath,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    String? mappingJson = prefs.getString('video_path_mappings');
    Map<String, String> mappings = {};

    if (mappingJson != null) {
      try {
        mappings = Map<String, String>.from(jsonDecode(mappingJson));
      } catch (e) {
        mappings = {};
      }
    }

    mappings[fileName] = fullPath;
    await prefs.setString('video_path_mappings', jsonEncode(mappings));
  }

  /// Check if URL is a valid http/https URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Check if path is local file
  static bool isLocalFile(String filePath) {
    return filePath.startsWith('/') ||
        filePath.contains('documents/videos/') ||
        File(filePath).existsSync();
  }

  /// Get video source type — now includes youtube
  static VideoSourceType getVideoSourceType(String videoUrl) {
    if (videoUrl.isEmpty) return VideoSourceType.unknown;

    if (videoUrl.startsWith('lib/assets/')) {
      return VideoSourceType.asset;
    } else if (isYoutubeUrl(videoUrl)) {
      return VideoSourceType.youtube;
    } else if (isValidUrl(videoUrl)) {
      return VideoSourceType.network;
    } else if (isLocalFile(videoUrl)) {
      return VideoSourceType.file;
    } else {
      return VideoSourceType.unknown;
    }
  }

  /// Delete uploaded video file from device
  static Future<bool> deleteUploadedVideo(String videoPath) async {
    try {
      if (isLocalFile(videoPath) && !videoPath.startsWith('lib/assets/')) {
        final file = File(videoPath);
        if (await file.exists()) {
          await file.delete();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error deleting video: $e');
      return false;
    }
  }
}

enum VideoSourceType { asset, network, file, youtube, unknown }
