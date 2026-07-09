import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/user/user/user_provider.dart'
    show userProvider, userStateProvider;
import 'package:visibility_detector/visibility_detector.dart';
import 'package:video_player/video_player.dart';
import 'package:shimmer/shimmer.dart';

import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';
import 'package:wall/emma/anchors/anchors_wall.dart';

import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wall/wall_screen/providers/post_create_provider.dart';
import 'package:wall/wall_screen/providers/wall_post_provider.dart';

import 'package:wall/wall_screen/screens/widgets/components/custom_components.dart';
import 'package:wall/wall_screen/screens/widgets/components/feedcard_action_buttons.dart';

import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:wall/wall_screen/screens/widgets/components/popup_menu_actions.dart';
import 'package:wall/wall_screen/screens/widgets/create_post_dialog/post_create_dialog.dart';
import 'package:wall/wall_screen/screens/widgets/create_post_dialog/post_create_screen.dart';
import 'package:wall/wall_screen/screens/widgets/media_dialog/mobile/media_viewer_widget_mobile.dart';
import 'package:wall/wall_screen/wall_screen_community_pc.dart';

class SocialPostWidgetMobile extends ConsumerStatefulWidget {
  final CommunityPost post;
  final String? feedType; // Feed type to identify which feed to update

  const SocialPostWidgetMobile({super.key, required this.post, this.feedType});

  @override
  ConsumerState<SocialPostWidgetMobile> createState() =>
      _SocialPostWidgetMobileState();
}

class _SocialPostWidgetMobileState
    extends ConsumerState<SocialPostWidgetMobile> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).valueOrNull;
    final userid = user?.userId;
    double screenWidth = MediaQuery.of(context).size.width;
    double postWidth = screenWidth;
    double aspectRatio = 1; // Mobile: more square feel
    double imageHeight = postWidth / aspectRatio;

    double avatarSize = 24;
    double titleFontSize = 14;
    double subtitleFontSize = 12;
    double buttonFontSize = 13;
    double horizontalPadding = 5;
    double verticalPadding = 8;
    double iconSize = 18;
    final theme = ref.watch(themeColorsProvider);
    return VisibilityDetector(
      key: Key('social-post-mobile-${widget.post.id}'),
      onVisibilityChanged: (info) {
        final isVisible = info.visibleFraction > 0.5;
        if (isVisible != _isVisible) {
          if (mounted) {
            setState(() {
              _isVisible = isVisible;
            });
          }
        }
      },
      child: EmmaUiAnchorTarget(
         anchorKey: '${WallEmmaAnchors.postCard.anchorKey}_${widget.post.id}',
         runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
         tapMode: EmmaUiAnchorTapMode.disabled,
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: CustomColors.secondaryWidgetColor(context, ref),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            width: postWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: InkWell(
                    onTap: () {
                      final now = DateTime.now().toIso8601String();
        
                      log("[$now] 🔹 tapped on this ontap");
                      log("[$now] 👤 userid: $userid");
                      log(
                        "[$now] 🧑‍💻 post author id: ${widget.post.author.userId}",
                      );
        
                      if (userid == widget.post.author.userId.toString()) {
                        log("[$now] 🚀 routing to main user profile");
                        ref
                            .read(navigationService)
                            .pushNamedScreen('${Routes.profile}');
                      } else {
                        log("[$now] 🌍 routing to public user profile");
                        ref
                            .read(navigationService)
                            .pushNamedScreen(
                              '${Routes.profile}/${widget.post.author.userId}',
                            );
                      }
                    },
        
                    child: Row(
                      children: [
                        EmmaUiAnchorTarget(
                          anchorKey: '${WallEmmaAnchors.postAuthorAvatar.anchorKey}_${widget.post.id}',
                          runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                          tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                          child: AvatarImageWidget(
                            imageUrl: widget.post.author.avatar,
                            avatarSize: avatarSize,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${widget.post.author.firstName} ${widget.post.author.lastName}",
                                style: TextStyle(
                                  color: CustomColors.secondaryWidgetTextColor(
                                    context,
                                    ref,
                                  ),
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.post.location != null) ...[
                                Text(
                                  widget.post.location!,
                                  style: TextStyle(
                                    color: CustomColors.secondaryWidgetTextColor(
                                      context,
                                      ref,
                                    ).withValues(alpha: 0.5),
                                    fontSize: subtitleFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        CustomPopupMenuButton(
                          showEdit:
                              widget.post.author.userId.toString() ==
                              ref.read(userStateProvider)?.userId,
                          showDelete:
                              widget.post.author.userId.toString() ==
                              ref.read(userStateProvider)?.userId,
                          onEdit: () {
                            ref
                                .read(postCreateStateProvider.notifier)
                                .initializeFromPost(widget.post);
        
                            // Check screen width to determine navigation
                            final screenWidth = MediaQuery.of(context).size.width;
        
                            if (screenWidth < 800) {
                              // Navigate to PostCreateScreen for mobile
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PostCreateScreen(post: widget.post),
                                ),
                              );
                            } else {
                              // Show dialog for desktop
                              Navigator.of(context).push(
                                DialogRoute(
                                  context: context,
                                  builder: (context) => PostCreateDialog(
                                    snackContext: context,
                                    post: widget.post, // The post to edit
                                  ),
                                ),
                              );
                            }
                          },
                          onDelete: () async {
                            // Show confirmation dialog
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: theme.dashboardContainer,
                                shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                    ),
                                title: Text('Delete Post'.tr,
                                style: TextStyle(
                                          color: theme.textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        )),
                                content: Text(
                                  'Are you sure you want to delete this post?'.tr,
                                  style: TextStyle(
                                            color: theme.textColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                     ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: Text('Cancel'.tr,style: TextStyle(color: theme.textColor)),
                                  ),
                                   ElevatedButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: theme.themeColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                            child: Text('Delete'.tr,  style: TextStyle(color: theme.themeColorText)),
                                      ),
                                ],
                              ),
                            );
        
                            if (confirmed == true) {
                              // Store context before async operations
        
                              // Call delete API
                              final success = await ref
                                  .read(wallPostProvider.notifier)
                                  .deletePost(postId: widget.post.id);
        
                              if (success && mounted) {
                                // Get current tab index
                                final selectedIndex = ref.read(
                                  selectedIndexProviderWall,
                                );
        
                                // Remove from all feeds using tab index
                                await ref
                                    .read(createPostWithFeedUpdateProvider)
                                    .deletePostFromFeeds(
                                      postId: widget.post.id,
                                      wallType: widget.post.wallType,
                                      tabIndex: selectedIndex,
                                    );
        
                                // Remove the post from profile wall pagination controller
        
                                log("snack bar triggered");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  Customsnackbar().showSnackBar(
                                    "deleted".tr,
                                    "post_deleted_successfully".tr,
                                    "success",
                                    () => ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar(),
                                  ),
                                );
                                log("function complete");
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  Customsnackbar().showSnackBar(
                                    "Error".tr,
                                    "failed_to_delete_post".tr,
                                    "error",
                                    () => ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar(),
                                  ),
                                );
                              }
                            }
                          },
                          onReport: () { if (kDebugMode) print("Report tapped"); },
                          horizontalPadding: horizontalPadding,
                          iconSize: iconSize,
                          appIconBuilder: (w, h, c) => AppIcons.moreVertical(
                            width: w,
                            height: h,
                            color: c,
                          ),
                          iconColorBuilder: (context) =>
                              CustomColors.secondaryWidgetTextColor(context, ref),
                        ),
                        SizedBox(width: 8),
                        // InkWell(
                        //   onTap: () => print('Close tapped'),
                        //   child: AppIcons.close(
                        //     width: iconSize,
                        //     height: iconSize,
                        //     color: CustomColors.secondaryWidgetTextColor(
                        //       context,
                        //       ref,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
        
                // Post text
                if (widget.post.content.trim().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Text(
                      widget.post.content,
                      style: TextStyle(
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          ref,
                        ),
                        fontSize: subtitleFontSize,
                      ),
                    ),
                  ),
        
                // Media
                if (widget.post.media.isNotEmpty)
                  _buildMobileMediaList(
                    context,
                    widget.post.media,
                    imageHeight,
                    _isVisible,
                  ),
        
                SizedBox(height: 5),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: CustomColors.thirdWidgetColor(context, ref),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedThumbsUp,
                          size: 15,
                          color: CustomColors.thirdWidgetTextColor(context, ref),
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        "${widget.post.totalLikes.toString()} ${'Likes'.tr}",
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            ref,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: ActionButtonRow(
                    isMobile: true,
                    buttonFontsize: buttonFontSize,
                    iconSize: iconSize,
                    layoutType: PostActionLayoutType.postcard,
                    post: widget.post,
                    feedType: widget.feedType,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// On mobile: just a vertical list of images/videos
  Widget _buildMobileMediaList(
    BuildContext context,
    List<CommunityMedia> media,
    double imageHeight,
    bool isVisible,
  ) {
    final PageController _pageController = PageController();

    return Column(
      children: [
        SizedBox(
          height: imageHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: media.length,
            itemBuilder: (context, index) {
              final item = media[index];
              return InkWell(
                onTap: () => _navigateToMediaViewer(context, media, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 12,
                    ),
                    width: double.infinity,
                    height: imageHeight,
                    child: _buildMediaContent(context, item, index, isVisible),
                  ),
                ),
              );
            },
          ),
        ),

        // Page Indicator
        if (media.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: media.length,
              effect: ExpandingDotsEffect(
                activeDotColor: CustomColors.thirdWidgetColor(context, ref),
                dotColor: CustomColors.secondaryWidgetTextColor(
                  context,
                  ref,
                ).withValues(alpha: 0.5),
                dotHeight: 6,
                dotWidth: 6,
                expansionFactor: 3,
                spacing: 4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaContent(
    BuildContext context,
    CommunityMedia mediaItem,
    int index,
    bool isVisible,
  ) {
    if (mediaItem.isImage) {
      return ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(10),
        child: CachedNetworkImage(
          imageUrl: mediaItem.url,
          fit: BoxFit.cover,
          placeholder: (context, url) => ProfessionalImagePlaceholderMobile(),
          errorWidget: (context, url, error) =>
              ProfessionalImagePlaceholderMobile(),
        ),
      );
    } else if (mediaItem.isVideo) {
      return _buildVideoWidget(mediaItem, isVisible);
    } else {
      return ProfessionalImagePlaceholderMobile();
    }
  }

  Widget _buildVideoWidget(CommunityMedia mediaItem, bool isVisible) {
    return _VideoPlayerWidget(
      media: mediaItem,
      isVisible: isVisible,
      isMobile: true,
    );
  }

  void _navigateToMediaViewer(
    BuildContext context,
    List<CommunityMedia> media,
    int initialIndex,
  ) {
     if (!mounted) return; 
    ref.read(postProvider.notifier).setPost(widget.post);
    showDialog(
      context: context,
      barrierDismissible: true,
      useSafeArea: false,
      builder: (context) => Dialog.fullscreen(
        child: MobileMediaViewerWidget(
          media: media,
          initialIndex: initialIndex,
          postData: widget.post,
          feedType: widget.feedType,
        ),
      ),
    );
  }
}

// Enhanced video player widget with visibility-based autoplay
class _VideoPlayerWidget extends ConsumerStatefulWidget {
  final CommunityMedia media;
  final bool isVisible;
  final bool isMobile;

  const _VideoPlayerWidget({
    required this.media,
    required this.isVisible,
    this.isMobile = false,
  });

  @override
  ConsumerState<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends ConsumerState<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.media.url));

    _controller!
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });

            // Auto-play if visible
            if (widget.isVisible) {
              _controller!.play();
              _controller!.setLooping(true);
            }
          }
        })
        .catchError((_) {
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        });
  }

  @override
  void didUpdateWidget(covariant _VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle visibility changes for video playback
    if (widget.isVisible != oldWidget.isVisible) {
       if (mounted) {
        _handleVideoPlayback();
      }
    }
  }

  void _handleVideoPlayback() {
    if (_controller != null && _isInitialized) {
      if (widget.isVisible) {
        _controller!.play();
      } else {
        _controller!.pause();
      }
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

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return ProfessionalImagePlaceholderMobile();
    }

    if (_controller == null || !_isInitialized) {
      return Stack(
        children: [
          _buildShimmerPlaceholder(),
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 10),
      child: Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),

          // Play/Pause overlay
          if (!_controller!.value.isPlaying)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: widget.isMobile ? 32 : 40,
                  ),
                  onPressed: () {
                    _controller!.play();
                  },
                ),
              ),
            ),

          // Expand icon for media viewer
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: CustomColors.secondaryWidgetTextColor(
                  context,
                  ref,
                ).withAlpha(153),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowExpand,
                color: CustomColors.secondaryWidgetColor(context, ref),
                size: widget.isMobile ? 16 : 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class ProfessionalImagePlaceholderMobile extends ConsumerWidget {
  const ProfessionalImagePlaceholderMobile({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final defaultIconColor = CustomColors.secondaryWidgetTextColor(
      context,
      ref,
    ).withAlpha(128);

    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Icon(Icons.image_outlined, color: defaultIconColor, size: 28),
      ),
    );
  }
}
