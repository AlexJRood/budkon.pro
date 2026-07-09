import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';

import 'package:core/theme/backgroundgradient.dart';
import 'package:wall/wall_screen/screens/widgets/components/error_dialog_widget.dart';
import 'package:wall/wall_screen/screens/widgets/components/shimmer_dialog_widget.dart';

// Provider for video controller state
final videoControllerProvider =
StateNotifierProvider.family<VideoControllerNotifier, VideoControllerState,
    String>((ref, url) {
  return VideoControllerNotifier(url);
});

class VideoControllerState {
  final VideoPlayerController? controller;
  final bool isInitialized;
  final bool hasError;
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  VideoControllerState({
    this.controller,
    this.isInitialized = false,
    this.hasError = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  VideoControllerState copyWith({
    VideoPlayerController? controller,
    bool? isInitialized,
    bool? hasError,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    return VideoControllerState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      hasError: hasError ?? this.hasError,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class VideoControllerNotifier extends StateNotifier<VideoControllerState> {
  final String url;

  VideoControllerNotifier(this.url) : super(VideoControllerState()) {
    _initializeController();
  }

  void _initializeController() {
    if (url.isEmpty) {
      state = state.copyWith(hasError: true);
      return;
    }

    final controller = VideoPlayerController.network(url);
    state = state.copyWith(controller: controller);

    controller.initialize().then((_) {
      state = state.copyWith(
        isInitialized: true,
        duration: controller.value.duration,
        position: controller.value.position,
        isPlaying: controller.value.isPlaying,
      );
    }).catchError((error) {
      state = state.copyWith(hasError: true);
    });

    controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (state.controller != null) {
      state = state.copyWith(
        isPlaying: state.controller!.value.isPlaying,
        position: state.controller!.value.position,
      );
    }
  }

  void play() {
    state.controller?.play();
  }

  void pause() {
    state.controller?.pause();
  }

  void seekTo(Duration position) {
    state.controller?.seekTo(position);
  }

  @override
  void dispose() {
    state.controller?.removeListener(_videoListener);
    state.controller?.dispose();
    super.dispose();
  }
}

// Provider for controls visibility
final videoControlsProvider =
StateNotifierProvider<VideoControlsNotifier, VideoControlsState>((ref) {
  return VideoControlsNotifier();
});

class VideoControlsState {
  final bool showControls;
  final bool showPlayButton;

  VideoControlsState({
    this.showControls = true,
    this.showPlayButton = false,
  });

  VideoControlsState copyWith({
    bool? showControls,
    bool? showPlayButton,
  }) {
    return VideoControlsState(
      showControls: showControls ?? this.showControls,
      showPlayButton: showPlayButton ?? this.showPlayButton,
    );
  }
}

class VideoControlsNotifier extends StateNotifier<VideoControlsState> {
  Timer? _hideControlsTimer;

  VideoControlsNotifier() : super(VideoControlsState()) {
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(Duration(seconds: 3), () {
      state = state.copyWith(showControls: false);
    });
  }

  void showControlsTemporarily() {
    state = state.copyWith(showControls: true);
    _startHideControlsTimer();
  }

  void showPlayButton() {
    state = state.copyWith(showPlayButton: true);
  }

  void hidePlayButton() {
    state = state.copyWith(showPlayButton: false);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }
}

class VideoPlayerWidget extends ConsumerStatefulWidget {
  final CommunityMedia mediaItem;
  final VoidCallback? onTap;

  const VideoPlayerWidget({
    Key? key,
    required this.mediaItem,
    this.onTap,
  }) : super(key: key);

  @override
  ConsumerState<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends ConsumerState<VideoPlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;
  late AnimationController _playButtonController;
  late Animation<double> _playButtonAnimation;

  @override
  void initState() {
    super.initState();

    _controlsAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _controlsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _playButtonController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _playButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _playButtonController,
        curve: Curves.elasticOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controlsAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    _playButtonController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final videoState =
    ref.read(videoControllerProvider(widget.mediaItem.url));
    final videoNotifier =
    ref.read(videoControllerProvider(widget.mediaItem.url).notifier);
    final controlsNotifier = ref.read(videoControlsProvider.notifier);

    if (videoState.isPlaying) {
      videoNotifier.pause();
      controlsNotifier.showPlayButton();
      _playButtonController.forward().then((_) {
        Future.delayed(Duration(milliseconds: 800), () {
          if (mounted) {
            controlsNotifier.hidePlayButton();
            _playButtonController.reverse();
          }
        });
      });
    } else {
      videoNotifier.play();
      controlsNotifier.hidePlayButton();
      _playButtonController.reverse();
    }

    controlsNotifier.showControlsTemporarily();
  }

  void _onTap() {
    final controlsNotifier = ref.read(videoControlsProvider.notifier);
    controlsNotifier.showControlsTemporarily();
    widget.onTap?.call();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoControllerProvider(widget.mediaItem.url));
    final controlsState = ref.watch(videoControlsProvider);
    final videoNotifier =
    ref.read(videoControllerProvider(widget.mediaItem.url).notifier);

    // Update controls animation based on state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controlsState.showControls) {
        _controlsAnimationController.forward();
      } else {
        _controlsAnimationController.reverse();
      }
    });

    if (videoState.hasError || videoState.controller == null) {
      return MediaErrorContent();
    }

    if (!videoState.isInitialized) {
      return LoadingShimmer();
    }

    return GestureDetector(
      onTap: _onTap,
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: videoState.controller!.value.aspectRatio,
              child: VideoPlayer(videoState.controller!),
            ),
          ),

          // Play button overlay
          if (controlsState.showPlayButton)
            Center(
              child: AnimatedBuilder(
                animation: _playButtonAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _playButtonAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(178),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Center play/pause button for tap interaction
          Center(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.transparent,
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controlsAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _controlsAnimation.value,
                  child: child,
                );
              },
              child: Container(
                padding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: CustomColors.secondaryWidgetColor(context, ref),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            videoState.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: CustomColors.secondaryWidgetTextColor(
                                context, ref),
                            size: 30,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        Expanded(
                          child: Slider(
                            value: videoState.position.inSeconds.toDouble(),
                            max: videoState.duration.inSeconds.toDouble(),
                            onChanged: (value) {
                              videoNotifier
                                  .seekTo(Duration(seconds: value.toInt()));
                              ref
                                  .read(videoControlsProvider.notifier)
                                  .showControlsTemporarily();
                            },
                            activeColor:
                            CustomColors.secondaryWidgetTextColor(
                                context, ref),
                            inactiveColor:
                            CustomColors.secondaryWidgetTextColor(
                                context, ref)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(videoState.position),
                            style: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(
                                  context, ref)
                                  .withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(videoState.duration),
                            style: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(
                                  context, ref)
                                  .withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
