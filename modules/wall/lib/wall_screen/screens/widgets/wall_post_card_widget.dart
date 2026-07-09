import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/common/middle_mouse_gesture.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'dart:ui' as ui;
import 'package:hugeicons/hugeicons.dart';
import 'package:video_player/video_player.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wall/wall_screen/screens/widgets/components/feedcard_action_buttons.dart';
import 'package:wall/wall_screen/screens/widgets/media_dialog/pc/media_viewer_widget_pc.dart';

// Media carousel widget for handling multiple media items
class MediaCarouselWidget extends StatefulWidget {
  final List<CommunityMedia> media;
  final double width;
  final double height;
  final bool isVisible;

  const MediaCarouselWidget({
    super.key,
    required this.media,
    required this.width,
    required this.height,
    required this.isVisible,
  });

  @override
  State<MediaCarouselWidget> createState() => _MediaCarouselWidgetState();
}

class _MediaCarouselWidgetState extends State<MediaCarouselWidget> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController?> _videoControllers = {};
  final Map<int, bool> _videoInitialized = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeVideos();
  }

  void _initializeVideos() {
    for (int i = 0; i < widget.media.length; i++) {
      final media = widget.media[i];
      if (media.mediaType.toLowerCase() == 'video') {
        _videoControllers[i] = VideoPlayerController.networkUrl(
          Uri.parse(media.url),
        );
        _videoInitialized[i] = false;

        _videoControllers[i]!.initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoInitialized[i] = true;
            });

            // Auto-play if this is the current video and widget is visible
            if (i == _currentIndex && widget.isVisible) {
              _videoControllers[i]!.play();
              _videoControllers[i]!.setLooping(true);
            }
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(MediaCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle visibility changes for video playback
    if (widget.isVisible != oldWidget.isVisible) {
      _handleVideoPlayback();
    }
  }

  void _handleVideoPlayback() {
    final currentController = _videoControllers[_currentIndex];
    if (currentController != null && _videoInitialized[_currentIndex] == true) {
      if (widget.isVisible) {
        currentController.play();
      } else {
        currentController.pause();
      }
    }
  }

  void _onPageChanged(int index) {
    if (mounted) {
      setState(() {
        // Pause previous video
        final prevController = _videoControllers[_currentIndex];
        if (prevController != null) {
          prevController.pause();
        }

        _currentIndex = index;

        // Play current video if visible and initialized
        final currentController = _videoControllers[index];
        if (currentController != null &&
            _videoInitialized[index] == true &&
            widget.isVisible) {
          currentController.play();
        }
      });
    }
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMediaItem(CommunityMedia media, int index) {
    if (media.mediaType.toLowerCase() == 'video') {
      final controller = _videoControllers[index];
      final isInitialized = _videoInitialized[index] ?? false;

      if (controller == null || !isInitialized) {
        return Stack(
          children: [
            _buildShimmerPlaceholder(),
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          ],
        );
      }

      return Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          // Play/Pause overlay
          if (!controller.value.isPlaying)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPlay,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () {
                    controller.play();
                  },
                ),
              ),
            ),
        ],
      );
    } else {
      // Image
      return CachedNetworkImage(
        imageUrl: media.url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildShimmerPlaceholder(),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedImageNotFound01,
              color: Colors.grey,
              size: 50,
            ),
          ),
        ),
        filterQuality: FilterQuality.low,
        memCacheWidth: widget.width.toInt(),
        memCacheHeight: widget.height.toInt(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedImageNotFound01,
            color: Colors.grey,
            size: 50,
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: widget.media.length,
          itemBuilder: (context, index) {
            return _buildMediaItem(widget.media[index], index);
          },
        ),

        // Media indicators
        if (widget.media.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.media.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentIndex
                        ? Colors.white
                        : Colors.white.withAlpha(128),
                  ),
                ),
              ),
            ),
          ),

        // Media type indicator
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(153),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon:
                      widget.media[_currentIndex].mediaType.toLowerCase() ==
                          'video'
                      ? HugeIcons.strokeRoundedVideo01
                      : HugeIcons.strokeRoundedImage01,
                  color: Colors.white,
                  size: 12,
                ),
                if (widget.media.length > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${_currentIndex + 1}/${widget.media.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _videoControllers.values) {
      controller?.dispose();
    }
    super.dispose();
  }
}

class WallPostCardWidget extends ConsumerStatefulWidget {
  /// Wall post model
  final CommunityPost post;

  /// Hero tag – unique ID (e.g., 'post-123')
  final String tag;

  /// Main image URL to display
  final String mainImageUrl;

  /// Whether system theme is dark
  final bool isDefaultDarkSystem;

  /// Background color
  final Color color;

  /// Text color in current theme
  final Color textColor;

  /// Text field color (used in dark theme)
  final Color textFieldColor;

  /// Placeholder widget used by CachedNetworkImage during loading
  final Widget buildShimmerPlaceholder;

  /// Function building list of PieMenu actions
  final dynamic buildPieMenuActions;

  final double aspectRatio;
  final bool isMobile;
  final bool isOwnUser;

  /// 🆕 New optional callbacks
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const WallPostCardWidget({
    super.key,
    required this.post,
    required this.tag,
    required this.mainImageUrl,
    required this.isDefaultDarkSystem,
    required this.color,
    required this.textColor,
    required this.textFieldColor,
    required this.buildShimmerPlaceholder,
    required this.buildPieMenuActions,
    required this.aspectRatio,
    required this.isMobile,
    this.isOwnUser = false,
    this.onEditTap,
    this.onDeleteTap,
  });

  @override
  ConsumerState<WallPostCardWidget> createState() => _WallPostCardWidgetState();
}

class _WallPostCardWidgetState extends ConsumerState<WallPostCardWidget> {
  bool _isVisible = false;

  void _navigateToMediaViewer(
    BuildContext context,
    List<CommunityMedia> media,
    int initialIndex,
  ) {
    //ref.read(postProvider.notifier).setPost(widget.post);
    showDialog(
      context: context,
      builder: (context) => MediaViewerWidget(
        media: media,
        initialIndex: initialIndex,
        postData: widget.post,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;

        // Calculations dependent on container
        double itemWidth = containerWidth;
        itemWidth = max(150.0, min(itemWidth, 250.0));

        double minBaseTextSize = 12;
        double maxBaseTextSize = 14;
        double baseTextSize =
            minBaseTextSize +
            (itemWidth - 150) /
                (240 - 150) *
                (maxBaseTextSize - minBaseTextSize);
        baseTextSize = max(minBaseTextSize, min(baseTextSize, maxBaseTextSize));

        double minBasePadding = 2;
        double maxBasePadding = 4;
        double basePadding =
            minBasePadding +
            (itemWidth - 150) / (240 - 150) * (maxBasePadding - minBasePadding);
        basePadding = max(minBasePadding, min(basePadding, maxBasePadding));

        double minBase = 4;
        double maxBase = 10;
        double base =
            minBase + (itemWidth - 150) / (240 - 150) * (maxBase - minBase);
        base = max(minBase, min(base, maxBase));

        final dpr = MediaQuery.of(context).devicePixelRatio;
        final cardHeight = itemWidth / widget.aspectRatio;
        final targetMemW = (itemWidth * dpr).round();
        final targetMemH = (cardHeight * dpr).round();

        // Sensible disk cache bounds for thumbnails/cards
        final diskW = min(1024, (itemWidth * 2).round());
        final diskH = min(1024, (cardHeight * 2).round());

        return VisibilityDetector(
          key: Key('wall-post-${widget.post.id}'),
          onVisibilityChanged: (info) {
            final isVisible = info.visibleFraction > 0.5;
            if (isVisible != _isVisible) {
              if (!mounted) return;
              setState(() {
                if (mounted) {
                  _isVisible = isVisible;
                }
              });
            }
          },
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: MiddleClickDetector(
              onMiddleClick: () {
                debugPrint('Middle click detected on wall post!');
                // Handle middle click action for wall post
              },
              child: PieMenu(
                theme: PieTheme.of(context).copyWith(
                  overlayColor: (() {
                    final theme = ref.watch(themeColorsProvider);
                    final bool uiIsDark =
                        theme.textColor.computeLuminance() > 0.5;

                    final base = uiIsDark ? Colors.black : Colors.white;
                    return base.withValues(alpha: 0.70);
                  })(),
                ),
                onPressedWithDevice: (kind) {
                  if (kind == PointerDeviceKind.mouse ||
                      kind == PointerDeviceKind.touch) {
                    // Handle wall post tap action
                    debugPrint('Wall post tapped: ${widget.post.id}');
                    _navigateToMediaViewer(context, [widget.post.media[0]], 0);
                  }
                },
                actions: widget.buildPieMenuActions,
                child: Hero(
                  tag: widget.tag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(widget.isMobile ? 0 : 6),
                                ),
                                child: MediaCarouselWidget(
                                  media: widget.post.media,
                                  width: itemWidth,
                                  height:
                                      cardHeight *
                                      0.6, // 60% of card height for media
                                  isVisible: _isVisible,
                                ),
                              ),
                            ),
                            IntrinsicHeight(
                              child: ClipRRect(
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(
                                    sigmaX: 20,
                                    sigmaY: 20,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        widget.isMobile ? 0 : 6,
                                      ),
                                      color: theme.sideBarbackground.withAlpha(
                                        (255 * 0.75).toInt(),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(base),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Author info
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: baseTextSize + 2,
                                                  backgroundImage:
                                                      widget
                                                          .post
                                                          .author
                                                          .avatar
                                                          .isNotEmpty
                                                      ? CachedNetworkImageProvider(
                                                          widget
                                                              .post
                                                              .author
                                                              .avatar,
                                                        )
                                                      : null,
                                                  backgroundColor:
                                                      Colors.grey[300],
                                                  child:
                                                      widget
                                                          .post
                                                          .author
                                                          .avatar
                                                          .isEmpty
                                                      ? HugeIcon(
                                                          icon: HugeIcons
                                                              .strokeRoundedUser,
                                                          size:
                                                              baseTextSize + 2,
                                                          color:
                                                              Colors
                                                                  .grey[600] ??
                                                              Colors.grey,
                                                        )
                                                      : null,
                                                ),
                                                SizedBox(
                                                  width: basePadding * 2,
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${widget.post.author.firstName} ${widget.post.author.lastName}',
                                                        style: AppTextStyles
                                                            .interMedium
                                                            .copyWith(
                                                              color: theme
                                                                  .textColor,
                                                              fontSize:
                                                                  baseTextSize +
                                                                  1,
                                                            ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      Text(
                                                        '@${widget.post.author.username}',
                                                        style: AppTextStyles
                                                            .interLight
                                                            .copyWith(
                                                              color: theme
                                                                  .textColor
                                                                  .withAlpha(
                                                                    ((0.7 as num).clamp(
                                                                              0,
                                                                              1,
                                                                            ) *
                                                                            255)
                                                                        .round(),
                                                                  ),
                                                              fontSize:
                                                                  baseTextSize -
                                                                  1,
                                                            ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: basePadding),

                                            // Post content
                                            if (widget.post.content.isNotEmpty)
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      widget.post.content,
                                                      style: AppTextStyles
                                                          .interRegular
                                                          .copyWith(
                                                            color:
                                                                theme.textColor,
                                                            fontSize:
                                                                baseTextSize,
                                                          ),
                                                      maxLines: 3,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (widget.isOwnUser)
                                                    if (widget.onEditTap !=
                                                        null)
                                                      _buildActionButton(
                                                        icon: HugeIcons
                                                            .strokeRoundedEdit02,
                                                        color:
                                                            Colors.blueAccent,
                                                        onTap:
                                                            widget.onEditTap!,
                                                      ),
                                                  const SizedBox(width: 8),

                                                  // 🗑️ Delete Button
                                                  if (widget.onDeleteTap !=
                                                      null)
                                                    _buildActionButton(
                                                      icon: HugeIcons
                                                          .strokeRoundedDelete02,
                                                      color: Colors.redAccent,
                                                      onTap:
                                                          widget.onDeleteTap!,
                                                    ),
                                                ],
                                              ),

                                            SizedBox(height: basePadding),

                                            // Location if available
                                            if (widget.post.location != null &&
                                                widget
                                                    .post
                                                    .location!
                                                    .isNotEmpty)
                                              Row(
                                                children: [
                                                  HugeIcon(
                                                    icon: HugeIcons
                                                        .strokeRoundedLocation01,
                                                    size: baseTextSize + 1,
                                                    color: theme.textColor
                                                        .withAlpha(178),
                                                  ),
                                                  SizedBox(width: basePadding),
                                                  Expanded(
                                                    child: Text(
                                                      widget.post.location!,
                                                      style: AppTextStyles
                                                          .interLight
                                                          .copyWith(
                                                            color: theme
                                                                .textColor
                                                                .withAlpha(
                                                                  ((0.7 as num).clamp(
                                                                            0,
                                                                            1,
                                                                          ) *
                                                                          255)
                                                                      .round(),
                                                                ),
                                                            fontSize:
                                                                baseTextSize -
                                                                1,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                            SizedBox(height: basePadding),
                                            Divider(
                                              color: theme.textColor.withAlpha(
                                                76,
                                              ),
                                            ),

                                            // Post stats and date
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    HugeIcon(
                                                      icon:
                                                          widget
                                                              .post
                                                              .hasUserLiked
                                                          ? HugeIcons
                                                                .strokeRoundedFavourite
                                                          : HugeIcons
                                                                .strokeRoundedFavourite,
                                                      size: baseTextSize + 2,
                                                      color:
                                                          widget
                                                              .post
                                                              .hasUserLiked
                                                          ? Colors.red
                                                          : theme.textColor
                                                                .withAlpha(
                                                                  ((0.7 as num).clamp(
                                                                            0,
                                                                            1,
                                                                          ) *
                                                                          255)
                                                                      .round(),
                                                                ),
                                                    ),
                                                    SizedBox(
                                                      width: basePadding,
                                                    ),
                                                    Text(
                                                      '${widget.post.totalLikes}',
                                                      style: AppTextStyles
                                                          .interLight
                                                          .copyWith(
                                                            color:
                                                                theme.textColor,
                                                            fontSize:
                                                                baseTextSize,
                                                          ),
                                                    ),
                                                    SizedBox(
                                                      width: basePadding * 3,
                                                    ),
                                                    HugeIcon(
                                                      icon: HugeIcons
                                                          .strokeRoundedComment01,
                                                      size: baseTextSize + 2,
                                                      color: theme.textColor
                                                          .withAlpha(178),
                                                    ),
                                                    SizedBox(
                                                      width: basePadding,
                                                    ),
                                                    Text(
                                                      '${widget.post.totalComments}',
                                                      style: AppTextStyles
                                                          .interLight
                                                          .copyWith(
                                                            color:
                                                                theme.textColor,
                                                            fontSize:
                                                                baseTextSize,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  DateFormat.yMMMd().format(
                                                    widget.post.createdAt,
                                                  ),
                                                  style: AppTextStyles
                                                      .interLight
                                                      .copyWith(
                                                        color: theme.textColor
                                                            .withAlpha(128),
                                                        fontSize:
                                                            baseTextSize - 2,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Build individual action buttons
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(128),
          shape: BoxShape.circle,
        ),
        child: HugeIcon(icon: icon, color: color, size: 18),
      ),
    );
  }
}
