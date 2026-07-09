import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:wall/wall_screen/screens/widgets/components/custom_components.dart';
import 'package:wall/wall_screen/screens/widgets/components/error_dialog_widget.dart';
import 'package:wall/wall_screen/screens/widgets/components/shimmer_dialog_widget.dart';
import 'package:get/get_utils/get_utils.dart';
import 'media_state_provider.dart';

class FileHandler extends ConsumerStatefulWidget {
  final ExtendedMediaItem mediaItem;
  final int providerId;
  final bool showCommentToggle;
  final bool areCommentsVisible;

  final VoidCallback? onToggleComments;

  const FileHandler({
    super.key,
    required this.mediaItem,
    required this.providerId,
    this.showCommentToggle =false,
    this.areCommentsVisible = false,
    this.onToggleComments,
  });

  @override
  ConsumerState<FileHandler> createState() => _FileHandlerState();
}

class _FileHandlerState extends ConsumerState<FileHandler> {
  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaStateProvider(widget.providerId));

    switch (widget.mediaItem.type) {
      case FileType.image:
        return _buildImageContent(context, ref);
      case FileType.video:
        return _buildVideoContent(context, ref, mediaState);
      case FileType.pdf:
        return _buildPdfContent(context, ref);
      default:
        return _buildUnsupportedContent(context, ref);
    }
  }

  Widget _buildImageContent(BuildContext context, WidgetRef ref) {
    
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CachedNetworkImage(
        fit: BoxFit.cover,
        imageUrl: widget.mediaItem.url,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => LoadingShimmer(),
        errorWidget: (context, url, error) => ProfessionalImagePlaceholder(
          width: double.infinity,
          height: double.infinity,
        ),
        fadeInDuration: Duration(milliseconds: 300),
        fadeOutDuration: Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildVideoContent(
    BuildContext context,
    WidgetRef ref,
    MediaState mediaState,
  ) {
    if (mediaState.hasVideoError || mediaState.videoController == null) {
      return MediaErrorContent();
    }

    return mediaState.isVideoInitialized
        ? Container(
            color: Colors.black,
            child: GestureDetector(
              onTap: () => ref
                  .read(mediaStateProvider(widget.providerId).notifier)
                  .showControlsTemporarily(),
              child: Stack(
                children: [
                  // Video Player
                  Center(
                    child: AspectRatio(
                      aspectRatio:
                          mediaState.videoController!.value.aspectRatio,
                      child: VideoPlayer(mediaState.videoController!),
                    ),
                  ),

                  // Modern Video Controls Overlay
                  _buildModernVideoControls(context, ref, mediaState),
                ],
              ),
            ),
          )
        : LoadingShimmer();
  }

  Widget _buildModernVideoControls(
    BuildContext context,
    WidgetRef ref,
    MediaState mediaState,
  ) {
    return AnimatedOpacity(
      opacity: mediaState.showControls ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withAlpha(26),
              Colors.black.withAlpha(178),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Center Play/Pause Button
            Center(
              child: GestureDetector(
                onTap: () {
                  ref
                      .read(mediaStateProvider(widget.providerId).notifier)
                      .toggleVideoPlayback();
                },
                child: AnimatedOpacity(
                  opacity: mediaState.isVideoPlaying ? 0.0 : 1.0,
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(178),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Progress Bar
                  _buildProgressBar(context, ref, mediaState),

                  // Control Buttons
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Play/Pause Button
                        IconButton(
                          icon: Icon(
                            mediaState.isVideoPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            ref
                                .read(
                                  mediaStateProvider(
                                    widget.providerId,
                                  ).notifier,
                                )
                                .toggleVideoPlayback();
                          },
                        ),

                        // Skip back 10s
                        IconButton(
                          icon: Icon(
                            Icons.replay_10,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => _skipSeconds(-10, ref, mediaState),
                        ),

                        // Skip forward 10s
                        IconButton(
                          icon: Icon(
                            Icons.forward_10,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => _skipSeconds(10, ref, mediaState),
                        ),

                        // Time Display
                        Expanded(
                          child: Center(
                            child: Text(
                              '${formatDuration(mediaState.videoPosition)} / ${formatDuration(mediaState.videoDuration)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        // Volume Button
                        IconButton(
                          icon: Icon(
                            mediaState.videoController!.value.volume > 0
                                ? Icons.volume_up
                                : Icons.volume_off,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => _toggleMute(ref, mediaState),
                        ),
                        SizedBox(width: 8),
                        // Toggle Comments / Fullscreen Button
                        if (widget.showCommentToggle)
                          IconButton(
                            icon: Icon(
                              widget.areCommentsVisible
                                  ? Icons.fullscreen       // comments shown
                                  : Icons.fullscreen_exit, // comments hidden+
                              color: Colors.white,
                              size: 24,
                            ),
                            tooltip: widget.areCommentsVisible
                                ? 'Hide comments'.tr
                                : 'Show comments'.tr,
                            onPressed: widget.onToggleComments,
                          ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    WidgetRef ref,
    MediaState mediaState,
  ) {
    return Container(
      height: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          // Background track
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(76),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Buffered progress
          if (mediaState.videoController!.value.buffered.isNotEmpty)
            FractionallySizedBox(
              widthFactor:
                  mediaState
                      .videoController!
                      .value
                      .buffered
                      .last
                      .end
                      .inSeconds /
                  mediaState.videoDuration.inSeconds.clamp(1, double.infinity),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(128),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // Played progress
          FractionallySizedBox(
            widthFactor:
                mediaState.videoPosition.inSeconds /
                mediaState.videoDuration.inSeconds.clamp(1, double.infinity),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Interactive slider (invisible but captures gestures)
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) {
                final RenderBox renderBox =
                    context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(
                  details.globalPosition,
                );
                final progress = localPosition.dx / renderBox.size.width;
                final newPosition = Duration(
                  milliseconds: (progress * mediaState.videoDuration.inMilliseconds)
                      .round(),
                );
                ref
                    .read(mediaStateProvider(widget.providerId).notifier)
                    .seekVideo(newPosition);
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  void _skipSeconds(int seconds, WidgetRef ref, MediaState mediaState) {
    final currentPosition = mediaState.videoPosition;
    final newPosition = Duration(
      milliseconds: (currentPosition.inMilliseconds + (seconds * 1000)).clamp(
        0,
        mediaState.videoDuration.inMilliseconds,
      ),
    );
    ref
        .read(mediaStateProvider(widget.providerId).notifier)
        .seekVideo(newPosition);
  }

  void _toggleMute(WidgetRef ref, MediaState mediaState) {
    final controller = mediaState.videoController!;
    final newVolume = controller.value.volume > 0 ? 0.0 : 1.0;
    controller.setVolume(newVolume);
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw '${'could_not_launch'.tr} $url';
    }
  }

  Widget _buildPdfContent(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CustomColors.secondaryWidgetColor(context, ref),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CustomColors.secondaryWidgetTextColor(
                  context,
                  ref,
                ).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedFile02,
                  size: 64,
                  color: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ).withValues(alpha: 0.7),
                ),
                SizedBox(height: 16),
                Text(
                  'PDF Document'.tr,
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                if (widget.mediaItem.title != null)
                  Text(
                    widget.mediaItem.title!,
                    style: TextStyle(
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        ref,
                      ).withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _openPdf(widget.mediaItem.url);
                  },
                  icon: Icon(Icons.open_in_new, size: 18),
                  label: Text('Open PDF'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.secondaryWidgetTextColor(
                      context,
                      ref,
                    ),
                    foregroundColor: CustomColors.secondaryWidgetColor(
                      context,
                      ref,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedContent(BuildContext context, WidgetRef ref) {
    final extension = widget.mediaItem.url
        .split('.')
        .last
        .split('?')
        .first
        .toUpperCase();

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CustomColors.secondaryWidgetColor(context, ref),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CustomColors.secondaryWidgetTextColor(
                  context,
                  ref,
                ).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedFileUnknown,
                  size: 64,
                  color: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ).withValues(alpha: 0.7),
                ),
                SizedBox(height: 16),
                Text(
                  'Unsupported File Type'.tr,
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '.$extension ${'files are not supported'.tr}',
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(
                      context,
                      ref,
                    ).withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Download or open in external app
                  },
                  icon: Icon(Icons.download, size: 18),
                  label: Text('Download File'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.secondaryWidgetTextColor(
                      context,
                      ref,
                    ),
                    foregroundColor: CustomColors.secondaryWidgetColor(
                      context,
                      ref,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Navigation Button Widget
class NavigationButton extends ConsumerWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLeft;

  const NavigationButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: CustomColors.secondaryWidgetColor(context, ref),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onPressed,
          child: Container(
            width: 50,
            height: 50,
            child: HugeIcon(
              icon: icon,
              color: onPressed != null
                  ? CustomColors.secondaryWidgetTextColor(context, ref)
                  : Colors.grey[600]!,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

// Media Counter Widget
class MediaCounter extends ConsumerWidget {
  final ExtendedMediaItem currentMedia;
  final int currentIndex;
  final int totalCount;

  const MediaCounter({
    super.key,
    required this.currentMedia,
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData getIcon() {
      switch (currentMedia.type) {
        case FileType.video:
          return Icons.videocam;
        case FileType.pdf:
          return Icons.picture_as_pdf;
        case FileType.image:
          return Icons.image;
        default:
          return Icons.insert_drive_file;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CustomColors.secondaryWidgetColor(
          context,
          ref,
        ).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getIcon(),
            color: CustomColors.secondaryWidgetTextColor(
              context,
              ref,
            ).withValues(alpha: 0.8),
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            '${currentIndex + 1} / $totalCount',
            style: TextStyle(
              color: CustomColors.secondaryWidgetTextColor(context, ref),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
