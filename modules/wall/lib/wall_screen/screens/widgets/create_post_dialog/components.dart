import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get_utils/get_utils.dart';
/// ================== Thumbnail ==================
class Thumbnail extends ConsumerWidget {
  final dynamic file; // PlatformFile | File
  const Thumbnail({super.key, required this.file});

  bool _isImage(String path) =>
      path.toLowerCase().endsWith('.png') ||
      path.toLowerCase().endsWith('.jpg') ||
      path.toLowerCase().endsWith('.jpeg') ||
      path.toLowerCase().endsWith('.gif') ||
      path.toLowerCase().endsWith('.webp');

  bool _isVideo(String path) {
    final videoExtensions = [
      'mp4',
      'avi',
      'mov',
      'wmv',
      'flv',
      'webm',
      'mkv',
      '3gp',
      'm4v',
    ];
    return videoExtensions.contains(path.split('.').last.toLowerCase());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb && file is PlatformFile && file.bytes != null) {
      if (_isImage(file.name)) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            file.bytes!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const ErrorThumbnail(),
          ),
        );
      } else if (_isVideo(file.name)) {
        return VideoThumbnailCreatePost(fileName: file.name);
      }
      return FileThumbnail(fileName: file.name);
    } else if (file is File) {
      if (_isImage(file.path)) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const ErrorThumbnail(),
          ),
        );
      } else if (_isVideo(file.path)) {
        return VideoThumbnailCreatePost(fileName: file.path);
      }
      return FileThumbnail(fileName: file.path);
    }
    return const FileThumbnail(fileName: '');
  }
}

/// ================== Video Thumbnail ==================
class VideoThumbnailCreatePost extends ConsumerWidget {
  final String fileName;
  const VideoThumbnailCreatePost({super.key, required this.fileName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withAlpha(204),
            Colors.blue.withAlpha(204),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.play_circle_fill, size: 32, color: Colors.white),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.videocam, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// ================== File Thumbnail ==================
class FileThumbnail extends ConsumerWidget {
  final String fileName;
  const FileThumbnail({super.key, required this.fileName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData icon;
    Color color;

    String extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart;
        color = Colors.green;
        break;
      case 'ppt':
      case 'pptx':
        icon = Icons.slideshow;
        color = Colors.orange;
        break;
      case 'txt':
        icon = Icons.text_snippet;
        color = Colors.grey;
        break;
      case 'zip':
      case 'rar':
      case '7z':
        icon = Icons.archive;
        color = Colors.brown;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Icon(icon, size: 32, color: color),
    );
  }
}

/// ================== Error Thumbnail ==================
class ErrorThumbnail extends ConsumerWidget {
  const ErrorThumbnail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withAlpha(76)),
      ),
      child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
    );
  }
}

/// ================== Network Media Thumbnail (for existing media) ==================
class NetworkMediaThumbnail extends ConsumerWidget {
  final String url;
  const NetworkMediaThumbnail({super.key, required this.url});

  bool _isImage(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.png') ||
        lowerUrl.contains('.jpg') ||
        lowerUrl.contains('.jpeg') ||
        lowerUrl.contains('.gif') ||
        lowerUrl.contains('.webp');
  }

  bool _isVideo(String url) {
    final videoExtensions = [
      'mp4',
      'avi',
      'mov',
      'wmv',
      'flv',
      'webm',
      'mkv',
      '3gp',
      'm4v',
    ];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.contains('.$ext'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isImage(url)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const ErrorThumbnail(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    } else if (_isVideo(url)) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Video thumbnail background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.withAlpha(204),
                  Colors.blue.withAlpha(204),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Play icon
          const Icon(Icons.play_circle_fill, size: 48, color: Colors.white),
          // Video badge
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'VIDEO'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // For other file types
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withAlpha(76)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, size: 32, color: Colors.grey),
            const SizedBox(height: 4),
            Text(
              'FILE'.tr,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }
}
