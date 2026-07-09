import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';

// Media State Model
class MediaState {
  final int currentIndex;
  final bool showControls;
  final bool hasVideoError;
  final VideoPlayerController? videoController;
  final bool isVideoInitialized;
  final bool isVideoPlaying;
  final Duration videoPosition;
  final Duration videoDuration;

  const MediaState({
    required this.currentIndex,
    this.showControls = true,
    this.hasVideoError = false,
    this.videoController,
    this.isVideoInitialized = false,
    this.isVideoPlaying = false,
    this.videoPosition = Duration.zero,
    this.videoDuration = Duration.zero,
  });

  MediaState copyWith({
    int? currentIndex,
    bool? showControls,
    bool? hasVideoError,
    VideoPlayerController? videoController,
    bool? isVideoInitialized,
    bool? isVideoPlaying,
    Duration? videoPosition,
    Duration? videoDuration,
  }) {
    return MediaState(
      currentIndex: currentIndex ?? this.currentIndex,
      showControls: showControls ?? this.showControls,
      hasVideoError: hasVideoError ?? this.hasVideoError,
      videoController: videoController ?? this.videoController,
      isVideoInitialized: isVideoInitialized ?? this.isVideoInitialized,
      isVideoPlaying: isVideoPlaying ?? this.isVideoPlaying,
      videoPosition: videoPosition ?? this.videoPosition,
      videoDuration: videoDuration ?? this.videoDuration,
    );
  }
}

// Supported File Types Enum
enum FileType {
  image,
  video,
  pdf,
  unknown;

  static FileType fromUrl(String url) {
    final extension = url.toLowerCase().split('.').last.split('?').first;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return FileType.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
      case 'm4v':
        return FileType.video;
      case 'pdf':
        return FileType.pdf;
      default:
        return FileType.unknown;
    }
  }

  bool get isImage => this == FileType.image;
  bool get isVideo => this == FileType.video;
  bool get isPdf => this == FileType.pdf;
  bool get isUnknown => this == FileType.unknown;
}

// Extended Media Model
class ExtendedMediaItem {
  final String url;
  final FileType type;
  final String? title;
  final int? size;

  ExtendedMediaItem({
    required this.url,
    required this.type,
    this.title,
    this.size,
  });

  factory ExtendedMediaItem.fromCommunityMedia(CommunityMedia media) {
    return ExtendedMediaItem(
      url: media.url,
      type: media.isImage
          ? FileType.image
          : media.isVideo
          ? FileType.video
          : FileType.fromUrl(media.url),
    );
  }

  bool get isImage => type.isImage;
  bool get isVideo => type.isVideo;
  bool get isPdf => type.isPdf;
}

// Media State Notifier
class MediaStateNotifier extends StateNotifier<MediaState> {
  Timer? _hideControlsTimer;

  MediaStateNotifier(int initialIndex)
      : super(MediaState(currentIndex: initialIndex));

  void initializeMedia(List<ExtendedMediaItem> mediaList, {int? initialIndex}) {
    int newIndex = initialIndex ?? state.currentIndex;

    // 👇 Clamp the index so it never goes out of range
    if (newIndex >= mediaList.length) {
      newIndex = mediaList.length - 1;
    }
    if (newIndex < 0) {
      newIndex = 0;
    }

    // Dispose old video before switching
    _disposeCurrentVideo();

    state = state.copyWith(currentIndex: newIndex);

    final currentMedia = mediaList[newIndex];
    if (currentMedia.isVideo) {
      _initializeVideoController(currentMedia.url);
    }
    _startHideControlsTimer();
  }

  void setCurrentIndex(int index) {
    if (index != state.currentIndex) {
      _disposeCurrentVideo();
      state = state.copyWith(currentIndex: index.clamp(0, index)); // ✅ clamp
    }
  }

  void _initializeVideoController(String url) {
    state.videoController?.dispose();

    if (url.isEmpty) {
      state = state.copyWith(hasVideoError: true);
      return;
    }

    final controller = VideoPlayerController.network(url);
    state = state.copyWith(
      videoController: controller,
      hasVideoError: false,
      isVideoInitialized: false,
    );

    controller
        .initialize()
        .then((_) {
      if (mounted) {
        state = state.copyWith(
          isVideoInitialized: true,
          videoDuration: controller.value.duration,
        );
        controller.addListener(_videoListener);
      }
    })
        .catchError((error) {
      if (mounted) {
        state = state.copyWith(hasVideoError: true);
      }
    });
  }

  void _videoListener() {
    if (mounted && state.videoController != null) {
      final controller = state.videoController!;
      state = state.copyWith(
        isVideoPlaying: controller.value.isPlaying,
        videoPosition: controller.value.position,
      );
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(Duration(seconds: 3), () {
      if (mounted && state.showControls) {
        state = state.copyWith(showControls: false);
      }
    });
  }

  void showControlsTemporarily() {
    state = state.copyWith(showControls: true);
    _startHideControlsTimer();
  }

  void toggleVideoPlayback() {
    if (state.videoController != null && state.isVideoInitialized) {
      if (state.isVideoPlaying) {
        state.videoController!.pause();
      } else {
        state.videoController!.play();
      }
      showControlsTemporarily();
    }
  }

  void seekVideo(Duration position) {
    if (state.videoController != null && state.isVideoInitialized) {
      state.videoController!.seekTo(position);
      showControlsTemporarily();
    }
  }

  void nextMedia(List<ExtendedMediaItem> mediaList) {
    if (state.currentIndex < mediaList.length - 1) {
      final newIndex = state.currentIndex + 1;
      _disposeCurrentVideo();
      state = state.copyWith(currentIndex: newIndex);

      final newMedia = mediaList[newIndex];
      if (newMedia.isVideo) {
        _initializeVideoController(newMedia.url);
      }
      showControlsTemporarily();
    }
  }

  void previousMedia(List<ExtendedMediaItem> mediaList) {
    if (state.currentIndex > 0) {
      final newIndex = state.currentIndex - 1;
      _disposeCurrentVideo();
      state = state.copyWith(currentIndex: newIndex);

      final newMedia = mediaList[newIndex];
      if (newMedia.isVideo) {
        _initializeVideoController(newMedia.url);
      }
      showControlsTemporarily();
    }
  }

  void switchToMedia(int index, List<ExtendedMediaItem> mediaList) {
    if (index >= 0 &&
        index < mediaList.length &&
        index != state.currentIndex) {
      _disposeCurrentVideo();
      state = state.copyWith(currentIndex: index);

      final newMedia = mediaList[index];
      if (newMedia.isVideo) {
        _initializeVideoController(newMedia.url);
      }
      showControlsTemporarily();
    }
  }

  void _disposeCurrentVideo() {
    if (state.videoController != null) {
      state.videoController!.removeListener(_videoListener);
      state.videoController!.dispose();
      state = state.copyWith(
        videoController: null,
        hasVideoError: false,
        isVideoInitialized: false,
        isVideoPlaying: false,
        videoPosition: Duration.zero,
        videoDuration: Duration.zero,
      );
    }
  }

  @override
  void dispose() {
    _disposeCurrentVideo();
    _hideControlsTimer?.cancel();
    super.dispose();
  }
}

// Provider
final mediaStateProvider =
StateNotifierProvider.family<MediaStateNotifier, MediaState, int>(
      (ref, initialIndex) => MediaStateNotifier(initialIndex),
);

// Helper function to format duration
String formatDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
