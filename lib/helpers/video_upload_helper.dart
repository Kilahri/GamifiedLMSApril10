// video_upload_helper.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class VideoUploadHelper {
  /// Extract YouTube video ID from any YouTube URL format
  static String? extractYoutubeId(String url) {
    if (url.isEmpty) return null;
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
  static bool isYoutubeUrl(String url) => extractYoutubeId(url) != null;

  /// Pick a video from device AND upload it to Firebase Storage.
  /// Returns the public download URL (https://...) on success, null on failure.
  // static Future<String?> pickVideoFromDevice({
  //   void Function(double progress)? onProgress,
  // }) async {
  //   try {
  //     final result = await FilePicker.platform.pickFiles(
  //       type: FileType.video,
  //       allowMultiple: false,
  //     );

  //     if (result == null || result.files.single.path == null) return null;

  //     final filePath = result.files.single.path!;
  //     final fileName = path.basename(filePath);
  //     final timestamp = DateTime.now().millisecondsSinceEpoch;
  //     final storagePath = 'teacher_videos/${timestamp}_$fileName';

  //     final ref = FirebaseStorage.instance.ref().child(storagePath);
  //     final uploadTask = ref.putFile(File(filePath));

  //     // Report upload progress if caller wants it
  //     if (onProgress != null) {
  //       uploadTask.snapshotEvents.listen((snapshot) {
  //         final progress = snapshot.bytesTransferred / snapshot.totalBytes;
  //         onProgress(progress);
  //       });
  //     }

  //     await uploadTask;
  //     final downloadUrl = await ref.getDownloadURL();
  //     return downloadUrl; // e.g. "https://firebasestorage.googleapis.com/..."
  //   } catch (e) {
  //     print('VideoUploadHelper error: $e');
  //     return null;
  //   }
  // }

  /// Check if URL is a valid http/https URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  /// Check if path is a local file (asset or on-device path)
  static bool isLocalFile(String filePath) {
    return filePath.startsWith('/') ||
        filePath.contains('documents/videos/') ||
        File(filePath).existsSync();
  }

  /// Determine video source type
  static VideoSourceType getVideoSourceType(String videoUrl) {
    if (videoUrl.isEmpty) return VideoSourceType.unknown;
    if (videoUrl.startsWith('lib/assets/')) return VideoSourceType.asset;
    if (isYoutubeUrl(videoUrl)) return VideoSourceType.youtube;
    // Firebase Storage and other https URLs → network
    if (isValidUrl(videoUrl)) return VideoSourceType.network;
    if (isLocalFile(videoUrl)) return VideoSourceType.file;
    return VideoSourceType.unknown;
  }
}

enum VideoSourceType { asset, network, file, youtube, unknown }
