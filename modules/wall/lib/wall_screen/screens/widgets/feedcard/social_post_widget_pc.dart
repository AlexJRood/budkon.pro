import 'dart:developer';

import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wall/emma/anchors/anchors_wall.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wall/wall_screen/providers/post_create_provider.dart';
import 'package:wall/wall_screen/providers/wall_post_provider.dart';

import 'package:wall/wall_screen/screens/widgets/components/custom_components.dart';
import 'package:wall/wall_screen/screens/widgets/components/feedcard_action_buttons.dart';
import 'package:wall/wall_screen/screens/widgets/components/popup_menu_actions.dart';
import 'package:wall/wall_screen/screens/widgets/create_post_dialog/post_create_dialog.dart';
import 'package:wall/wall_screen/screens/widgets/create_post_dialog/post_create_screen.dart';

import 'package:wall/wall_screen/screens/widgets/media_dialog/pc/media_viewer_widget_pc.dart';
import 'package:wall/wall_screen/wall_screen_community_pc.dart';
import 'package:feedback/src/provider/feedback_provider.dart';


class SocialPostWidgetPc extends ConsumerStatefulWidget {
  final CommunityPost post;
  final String? feedType;

  const SocialPostWidgetPc({super.key, required this.post, this.feedType});

  @override
  ConsumerState<SocialPostWidgetPc> createState() =>
      _SocialPostWidgetPcState();
}

class _SocialPostWidgetPcState extends ConsumerState<SocialPostWidgetPc> {
  bool _isVisible = false;
  int? asIntOrNull(Object? v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
  @override
  Widget build(BuildContext context) {
    log(widget.post.author.toString());
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final bool isTablet = screenWidth > 700 && screenWidth <= 1100;
        final double postWidth = screenWidth > 700 ? 700 : screenWidth * 0.7;
        final double aspectRatio = screenWidth > 1800 ? 1.1 : 1.7;
        final double imageHeight = postWidth / aspectRatio;

        final double avatarSize = postWidth * 0.035;
        final double titleFontSize = postWidth * 0.028;
        final double subtitleFontSize = postWidth * 0.022;
        final double buttonFontSize = postWidth * 0.024;
        final double horizontalPadding = postWidth * 0.03;
        final double verticalPadding = postWidth * 0.02;
        final double iconSize = postWidth * 0.03;
        final double dynamicPadding =
        screenWidth >= 1980 ? screenWidth / 6 : screenWidth / 8;

        final user = ref.watch(userProvider).valueOrNull;
        final userid = user?.userId;
        final theme = ref.watch(themeColorsProvider);
        return VisibilityDetector(
          key: Key('social-post-pc-${widget.post.id}'),
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
              child: RepaintBoundary(
                child: Card(
                  elevation: 4,
                  color: CustomColors.secondaryWidgetColor(context, ref),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
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
                                ref.read(navigationService).pushNamedScreen(
                                    '${Routes.profile}/${widget.post.author.userId}');
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
                                SizedBox(width: horizontalPadding * 0.8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      EmmaUiAnchorTarget(
                                        anchorKey: '${WallEmmaAnchors.postAuthorName.anchorKey}_${widget.post.id}',
                                        runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                                        tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                                        child: Text(
                                          "${widget.post.author.firstName} ${widget.post.author.lastName}",
                                          style: TextStyle(
                                            color:
                                            CustomColors.secondaryWidgetTextColor(
                                              context,
                                              ref,
                                            ),
                                            fontSize: titleFontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: verticalPadding * 0.5),
                                      if (widget.post.location != null) ...[
                                        Text(
                                          widget.post.location!,
                                          style: TextStyle(
                                            color: CustomColors
                                                .secondaryWidgetTextColor(
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
                                const Spacer(),
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
            
                                    final screenWidth =
                                        MediaQuery.of(context).size.width;
            
                                    if (screenWidth < 800) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PostCreateScreen(post: widget.post),
                                        ),
                                      );
                                    } else {
                                      Navigator.of(context).push(
                                        DialogRoute(
                                          context: context,
                                          builder: (context) => PostCreateDialog(
                                            snackContext: context,
                                            post: widget.post,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  onDelete: () async {
            
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: theme.dashboardContainer,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        title:  Text('Delete Post'.tr,
                                          style: TextStyle(
                                          color: theme.textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),),
                                        content:  Text(
                                          'Are you sure you want to delete this post?'.tr,
                                          style: TextStyle(
                                            color: theme.textColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child:  Text('Cancel'.tr,  style: TextStyle(color: theme.textColor)),
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
                                      final success = await ref
                                          .read(wallPostProvider.notifier)
                                          .deletePost(postId: widget.post.id);
            
                                      if (success && mounted) {
                                        final selectedIndex =
                                        ref.read(selectedIndexProviderWall);
            
                                        await ref
                                            .read(
                                            createPostWithFeedUpdateProvider)
                                            .deletePostFromFeeds(
                                          postId: widget.post.id,
                                          wallType: widget.post.wallType,
                                          tabIndex: selectedIndex,
                                        );
            
                                        log("snack bar triggered");
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          Customsnackbar().showSnackBar(
                                            "deleted".tr,
                                            "post_deleted_successfully".tr,
                                            "success",
                                                () => ScaffoldMessenger.of(context)
                                                .hideCurrentSnackBar(),
                                          ),
                                        );
                                        log("function complete");
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          Customsnackbar().showSnackBar(
                                            "Error".tr,
                                            "failed_to_delete_post".tr,
                                            "error",
                                                () => ScaffoldMessenger.of(context)
                                                .hideCurrentSnackBar(),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  onReport: (){
                                    final feedbackState = BetterFeedback.of(context);
                                    if (feedbackState == null) {
                                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                        SnackBar(
                                          content: Text('Feedback is unavailable in this view.'.tr),
                                        ),
                                      );
                                      return;
                                    }
            
                                    feedbackState.show((feedback) async {
                                      final userObj = await ref
                                          .read(userProvider.future)
                                          .catchError((_) => null);
                                      final int? userId = asIntOrNull(userObj?.userId);
            
            
                                      String? currentPath;
                                      try {
                                        final nav = ref.read(
                                          navigationService,
                                        );
                                        currentPath = nav.currentPath.toString();
                                      } catch (_) {
                                        currentPath = null;
                                      }
            
                                      await ref
                                          .read(feedbackProvider.notifier)
                                          .sendFeedback(
                                          FeedbackModel(
                                            title: feedback.extra?['title']?.toString() ?? '',
                                            description:
                                            feedback.extra?['description']?.toString() ?? feedback.text,
                                            note: feedback.extra?['note']?.toString() ?? '',
                                            image: feedback.screenshot,
                                            isSolved: false,
                                            user: userId ?? 0,
                                            problem: asIntOrNull(feedback.extra?['problem']),
                                            problemString: feedback.extra?['problem_string']?.toString(),
                                            responsiblePerson: asIntOrNull(feedback.extra?['responsible_person']),
                                            path: currentPath,
                                            app: feedback.extra?['app']?.toString() ?? 'hously',
                                            feature: feedback.extra?['feature']?.toString(),
                                            team: feedback.extra?['team']?.toString(),
                                            priority: feedback.extra?['priority']?.toString(),
                                          )
                                      );
                                    });
                                  },
                                  horizontalPadding: horizontalPadding,
                                  iconSize: iconSize,
                                  appIconBuilder: (w, h, c) =>
                                      AppIcons.moreVertical(
                                        width: w,
                                        height: h,
                                        color: c,
                                      ),
                                  iconColorBuilder: (context) =>
                                      CustomColors.secondaryWidgetTextColor(
                                        context,
                                        ref,
                                      ),
                                ),
                                SizedBox(width: horizontalPadding * 0.5),
                              ],
                            ),
                          ),
                        ),
                        if (widget.post.content.trim().isNotEmpty)
                          EmmaUiAnchorTarget(
                            anchorKey: '${WallEmmaAnchors.postContent.anchorKey}_${widget.post.id}',
                            runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                            tapMode: EmmaUiAnchorTapMode.disabled,
                            child: Padding(
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
                          ),
                        if (widget.post.media.isNotEmpty)
                          EmmaUiAnchorTarget(
                            anchorKey: '${WallEmmaAnchors.postMedia.anchorKey}_${widget.post.id}',
                            runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                            tapMode: EmmaUiAnchorTapMode.disabled,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: verticalPadding,
                              ),
                              child: _buildStaggeredMediaGrid(
                                context,
                                widget.post.media,
                                imageHeight,
                                _isVisible,
                              ),
                            ),
                          ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: verticalPadding * 1.2,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(postWidth * 0.012),
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(postWidth * 0.04),
                                  color: CustomColors.thirdWidgetColor(
                                    context,
                                    ref,
                                  ),
                                ),
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedThumbsUp,
                                  color: CustomColors.thirdWidgetTextColor(
                                    context,
                                    ref,
                                  ),
                                  size: iconSize,
                                ),
                              ),
                              SizedBox(width: postWidth * 0.01),
                              Text(
                                "${widget.post.totalLikes.toString()} ${'Likes'.tr}",
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  color: CustomColors.secondaryWidgetTextColor(
                                    context,
                                    ref,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: verticalPadding * 1.2,
                          ),
                          child: ActionButtonRow(
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaggeredMediaGrid(
      BuildContext context,
      List<CommunityMedia> media,
      double imageHeight,
      bool isVisible,
      ) {
    final mediaCount = media.length;

    return RepaintBoundary(
      child: SizedBox(
        height: imageHeight,
        child: _buildMediaLayout(context, media, mediaCount, isVisible),
      ),
    );
  }

  Widget _buildMediaLayout(
      BuildContext context,
      List<CommunityMedia> media,
      int mediaCount,
      bool isVisible,
      ) {
    if (mediaCount == 1) {
      return _buildSingleMedia(context, media[0], 0, isVisible);
    } else if (mediaCount == 2) {
      return _buildTwoMediaLayout(context, media, isVisible);
    } else if (mediaCount == 3) {
      return _buildThreeMediaLayout(context, media, isVisible);
    } else if (mediaCount == 4) {
      return _buildFourMediaLayout(context, media, isVisible);
    } else {
      return _buildMoreThanFourLayout(context, media, isVisible);
    }
  }

  Widget _buildSingleMedia(
      BuildContext context,
      CommunityMedia mediaItem,
      int index,
      bool isVisible,
      ) {
    return GestureDetector(
      onTap: () => _navigateToMediaViewer(context, [mediaItem], 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: _buildMediaContent(context, mediaItem, isVisible),
        ),
      ),
    );
  }

  Widget _buildTwoMediaLayout(
      BuildContext context,
      List<CommunityMedia> media,
      bool isVisible,
      ) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _navigateToMediaViewer(context, media, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: double.infinity,
                child: _buildMediaContent(
                  context,
                  media[0],
                  isVisible && 0 == 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToMediaViewer(context, media, 1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: double.infinity,
                child: _buildMediaContent(
                  context,
                  media[1],
                  isVisible && 1 == 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreeMediaLayout(
      BuildContext context,
      List<CommunityMedia> media,
      bool isVisible,
      ) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToMediaViewer(context, media, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: double.infinity,
                child: _buildMediaContent(
                  context,
                  media[0],
                  isVisible && 0 == 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToMediaViewer(context, media, 1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildMediaContent(
                        context,
                        media[1],
                        isVisible && 1 == 0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToMediaViewer(context, media, 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildMediaContent(
                        context,
                        media[2],
                        isVisible && 2 == 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFourMediaLayout(
      BuildContext context,
      List<CommunityMedia> media,
      bool isVisible,
      ) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToMediaViewer(context, media, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: double.infinity,
                child: _buildMediaContent(
                  context,
                  media[0],
                  isVisible && 0 == 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToMediaViewer(context, media, 1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildMediaContent(
                        context,
                        media[1],
                        isVisible && 1 == 0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            _navigateToMediaViewer(context, media, 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: double.infinity,
                            child: _buildMediaContent(
                              context,
                              media[2],
                              isVisible && 2 == 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            _navigateToMediaViewer(context, media, 3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: double.infinity,
                            child: _buildMediaContent(
                              context,
                              media[3],
                              isVisible && 3 == 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoreThanFourLayout(
      BuildContext context,
      List<CommunityMedia> media,
      bool isVisible,
      ) {
    final extraCount = media.length - 3;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToMediaViewer(context, media, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: double.infinity,
                child: _buildMediaContent(
                  context,
                  media[0],
                  isVisible && 0 == 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToMediaViewer(context, media, 1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildMediaContent(
                        context,
                        media[1],
                        isVisible && 1 == 0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            _navigateToMediaViewer(context, media, 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: double.infinity,
                            child: _buildMediaContent(
                              context,
                              media[2],
                              isVisible && 2 == 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            _navigateToMediaViewer(context, media, 3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildMediaContent(
                                context,
                                media[3],
                                isVisible && 3 == 0,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '+$extraCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaContent(
      BuildContext context,
      CommunityMedia mediaItem,
      bool isVisible,
      ) {
    if (mediaItem.isImage) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final dpr = MediaQuery.of(context).devicePixelRatio;
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // target decode size in physical pixels
          int targetW =
          (w * dpr).round().clamp(320, 1024); // min/max cap
          int targetH =
          (h * dpr).round().clamp(240, 1024);

          return CachedNetworkImage(
            imageUrl: mediaItem.url,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low, // ↓ less GPU load
            memCacheWidth: targetW,
            memCacheHeight: targetH,
            maxWidthDiskCache: 1024,
            maxHeightDiskCache: 1024,
            placeholder: (context, url) => const ProfessionalImagePlaceholder(),
            errorWidget: (context, url, error) =>
            const ProfessionalImagePlaceholder(),
          );
        },
      );
    } else if (mediaItem.isVideo) {
      return _buildVideoWidget(mediaItem, isVisible);
    } else {
      return const ProfessionalImagePlaceholder();
    }
  }

  Widget _buildVideoWidget(CommunityMedia mediaItem, bool isVisible) {
    return _VideoPlayerWidget(
      media: mediaItem,
      isVisible: isVisible,
      isMobile: false,
    );
  }

  void _navigateToMediaViewer(
      BuildContext context,
      List<CommunityMedia> media,
      int initialIndex,
      ) {
    ref.read(postProvider.notifier).setPost(widget.post);
    showDialog(
      context: context,
      builder: (context) => MediaViewerWidget(
        media: media,
        initialIndex: initialIndex,
        postData: widget.post,
        feedType: widget.feedType,
      ),
    );
  }
}

// Video widget stays the same as your latest version;
// no structural UI change, only logic.
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
  ConsumerState<_VideoPlayerWidget> createState() =>
      _VideoPlayerWidgetState();
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
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.media.url));

    _controller!
        .initialize()
        .then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

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
    if (widget.isVisible != oldWidget.isVisible) {
      _handleVideoPlayback();
    }
  }

  void _handleVideoPlayback() {
    if (_controller != null && _isInitialized && mounted) {
      try {
        if (widget.isVisible) {
          if (!_controller!.value.isPlaying) {
            _controller!.play();
            _controller!.setLooping(true);
          }
        } else {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
          }
        }
      } catch (e) {
        log('Error handling video playback: $e');
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
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.grey, size: 50),
        ),
      );
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
