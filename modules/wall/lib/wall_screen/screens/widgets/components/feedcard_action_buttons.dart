import 'dart:developer';

import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:wall/emma/anchors/anchors_wall.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:wall/wall_screen/providers/wall_post_provider.dart';
import 'package:wall/wall_screen/screens/widgets/comment_widgets/comment_post_dialog.dart';
import 'package:wall/wall_screen/screens/widgets/comment_widgets/comment_section_widget.dart';
import 'package:wall/wall_screen/screens/widgets/all_screens_list.dart';

import 'package:wall/wall_screen/services/haptics/emoji_haptic.dart';
import 'package:wall/wall_screen/services/haptics/global_haptic_service.dart';
import 'package:get/get_utils/get_utils.dart';

enum PostActionLayoutType { postcard, commentSection }

class ActionButtonRow extends ConsumerWidget {
  final PostActionLayoutType layoutType;
  final double? iconSize;
  final double? buttonFontsize;
  final CommunityPost post;
  final bool isMobile;
  final bool isTablet;
  final String? feedType; // Add feedType to identify which feed to update

  const ActionButtonRow({
    super.key,
    required this.layoutType,
    this.iconSize,
    this.buttonFontsize,
    required this.post,
    this.isMobile = false,
    this.isTablet = false,
    this.feedType, // Optional feedType parameter
  });

  void _showCommentsDialog(BuildContext context, WidgetRef ref) {
    ref.read(postProvider.notifier).setPost(post);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CommentsDialog(post: post, feedType: feedType),
    );
  }

  void _showCommentsBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true, // ✅ tap outside closes
      enableDrag: true, // ✅ swipe down closes
      backgroundColor: Colors.transparent, // ✅ so curve is visible
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: CustomColors.secondaryWidgetColor(context, ref),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), // ✅ curved top left
                topRight: Radius.circular(20), // ✅ curved top right
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: CommentSection(
                post: post,
                feedType: feedType,
                // if CommentSection is scrollable, pass scrollController here
                // scrollController: scrollController,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleLike(
    WidgetRef ref,
    BuildContext context,
    bool hasUserLiked,
  ) async {
    try {
      // Create optimistic updated post with toggled like status
      final updatedPost = CommunityPost(
        id: post.id,
        author: post.author,
        content: post.content,
        media: post.media,
        wallType: post.wallType,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
        totalLikes: hasUserLiked ? post.totalLikes - 1 : post.totalLikes + 1,
        totalComments: post.totalComments,
        hasUserLiked: !hasUserLiked,
        location: post.location,
        lat: post.lat,
        lon: post.lon,
        taggedUsers: post.taggedUsers,
        taggedUsersData: post.taggedUsersData,
      );

      // Perform optimistic update using provider directly
      if (feedType != null) {
        ref
            .read(feedPagingControllerProvider(feedType!).notifier)
            .updatePost(updatedPost);
      }

      ref.read(postProvider.notifier).setPost(updatedPost);

      // Call API to toggle like
      final success = await ref
          .read(likePostProvider.notifier)
          .toggleLike(
            context: context,
            postId: post.id,
            isCurrentlyLiked: hasUserLiked,
          );

      // If API call fails, revert to original state
      if (!success) {
        // Revert to original post state using provider directly
        if (feedType != null) {
          ref
              .read(feedPagingControllerProvider(feedType!).notifier)
              .updatePost(post);
        }
        ref.read(postProvider.notifier).setPost(post);
      }
    } catch (error, stackTrace) {
      // Log error
      log('Error toggling like: $error\n$stackTrace');

      // Revert to original post state using provider directly
      if (feedType != null) {
        ref
            .read(feedPagingControllerProvider(feedType!).notifier)
            .updatePost(post);
      }
      ref.read(postProvider.notifier).setPost(post);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          Customsnackbar().showSnackBar(
            "Error".tr,
            "unexpected_error_occurred".tr,
            "error",
            () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = CustomColors.secondaryWidgetTextColor(context, ref);
    final likeButtonKey = GlobalKey();
    final copyButtonKey = GlobalKey();
    final shareButtonKey = GlobalKey();
    double resolvedIconSize;
    double resolvedFontsize;
    switch (layoutType) {
      case PostActionLayoutType.postcard:
        resolvedFontsize = buttonFontsize ?? 14;
        break;
      case PostActionLayoutType.commentSection:
        resolvedFontsize = buttonFontsize ?? 12;
        break;
    }
    switch (layoutType) {
      case PostActionLayoutType.postcard:
        resolvedIconSize = iconSize ?? 24;
        break;
      case PostActionLayoutType.commentSection:
        resolvedIconSize = iconSize ?? 18;
        break;
    }

    Widget buildAction(
      IconData icon,
      String label,
      Function(BuildContext) onTap, {
      bool isActive = false,
      GlobalKey? buttonKey,
    }) {
      // Check screen width for mobile layout

      final screenWidth = MediaQuery.of(context).size.width;
      final showTextLabels = !isMobile || screenWidth >= 430;

      return InkWell(
        key: buttonKey,
        onTap: () => onTap(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: showTextLabels ? 12.0 : 8.0,
            vertical: 8.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? CustomColors.thirdWidgetColor(context, ref)
                    : color,
                // Different color for active state
                size: resolvedIconSize,
              ),
              if (showTextLabels) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? CustomColors.thirdWidgetColor(context, ref)
                        : color,
                    fontSize: resolvedFontsize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        // BoxFit.scaleDown ensures the Row shrinks to fit the tablet width
        // instead of throwing a yellow/black overflow error.
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Like Action
            Material(
              color: Colors.transparent,
              child: EmmaUiAnchorTarget(
                 anchorKey: '${WallEmmaAnchors.postLikeButton.anchorKey}_${post.id}',
                 runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                 tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                child: buildAction(
                  post.hasUserLiked
                      ? Icons.thumb_up_alt
                      : Icons.thumb_up_alt_outlined,
                  post.hasUserLiked ? 'Liked'.tr : 'Like'.tr,
                      (context) async {
                    
                    final RenderBox? box =
                    likeButtonKey.currentContext?.findRenderObject()
                    as RenderBox?;
                    if (box != null && post.hasUserLiked == false) {
                      final position = box.localToGlobal(
                        Offset(box.size.width / 2, box.size.height / 2),
                      );
                      EmojiBurstService.instance.success(context, position);
                    }
                    if ((box != null && post.hasUserLiked == true)) {
                      final position = box.localToGlobal(
                        Offset(box.size.width / 2, box.size.height / 2),
                      );
                      EmojiBurstService.instance.dislike(context, position);
                    }
                    
                    _toggleLike(ref, context, post.hasUserLiked);
                  },
                  isActive: post.hasUserLiked,
                  buttonKey: likeButtonKey,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 10 : 20),
            // 2. Comment Action
            if (layoutType != PostActionLayoutType.commentSection)
              EmmaUiAnchorTarget(
                anchorKey: '${WallEmmaAnchors.postCommentButton.anchorKey}_${post.id}',
                runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                child: buildAction(HugeIcons.strokeRoundedComment01, "Comment".tr, (context) {
                  if (isMobile) {
                    ref.read(postProvider.notifier).setPost(post);
                    final postdata = ref.read(postProvider);
                    if (postdata != null) {
                      _showCommentsBottomSheet(context, ref);
                    }
                    return;
                  } else {
                    _showCommentsDialog(context, ref);
                  }
                }),
              ),
            if (layoutType != PostActionLayoutType.commentSection)
              SizedBox(width: isTablet ? 10 : 20),
            // 3. Copy Action
            EmmaUiAnchorTarget(
              anchorKey: '${WallEmmaAnchors.postCopyButton.anchorKey}_${post.id}',
              runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
              tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
              child: buildAction(HugeIcons.strokeRoundedCopy01, "Copy".tr, (context) async {
                final RenderBox? box =
                copyButtonKey.currentContext?.findRenderObject() as RenderBox?;
                if (box != null) {
                  final position = box.localToGlobal(
                    Offset(box.size.width / 2, box.size.height / 2),
                  );
                  EmojiBurstService.instance.copy(context, position);
                }
                await Clipboard.setData(
                  ClipboardData(text: "https://hously.pro/wall/${post.id}/"),
                );
              }, buttonKey: copyButtonKey),
            ),
            SizedBox(width: isTablet ? 10 : 20),
            // 4. Share Action
            EmmaUiAnchorTarget(
              anchorKey: '${WallEmmaAnchors.postShareButton.anchorKey}_${post.id}',
              runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
              tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
              child: buildAction(HugeIcons.strokeRoundedShare08, "Share".tr, (context) async {
                final RenderBox? box =
                shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
                if (box != null) {
                  final position = box.localToGlobal(
                    Offset(box.size.width / 2, box.size.height / 2),
                  );
                  EmojiBurstService.instance.share(context, position);
                }
                await Future.delayed(const Duration(seconds: 1));
                try {
                  await Share.share(
                    "https://hously.pro/wall/${post.id}/",
                    subject: "Check this out!",
                  );
                } catch (e) {
                  log("Sharing failed: $e");
                }
              }, buttonKey: shareButtonKey),
            ),
          ],
        ),
      ),
    );
  }
}

// Alternative approach using copyWith method
extension CommunityPostExtension on CommunityPost {
  CommunityPost copyWith({
    int? id,
    CommunityAuthor? author,
    String? content,
    List<CommunityMedia>? media,
    String? wallType,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalLikes,
    int? totalComments,
    bool? hasUserLiked,
    String? location,
    double? lat,
    double? lon,
    List<int>? taggedUsers,
    List<TaggedUserData>? taggedUsersData,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      media: media ?? this.media,
      wallType: wallType ?? this.wallType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalLikes: totalLikes ?? this.totalLikes,
      totalComments: totalComments ?? this.totalComments,
      hasUserLiked: hasUserLiked ?? this.hasUserLiked,
      location: location ?? this.location,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      taggedUsers: taggedUsers ?? this.taggedUsers,
      taggedUsersData: taggedUsersData ?? this.taggedUsersData,
    );
  }
}

/// StateNotifier to manage a single selected post
class CommunityPostStateNotifier extends StateNotifier<CommunityPost?> {
  CommunityPostStateNotifier() : super(null);

  /// Store or update the post
  void setPost(CommunityPost post) {
    state = post;
  }

  /// Clear the post
  void clearPost() {
    state = null;
  }
}

/// Riverpod provider
final postProvider =
    StateNotifierProvider<CommunityPostStateNotifier, CommunityPost?>((ref) {
      return CommunityPostStateNotifier();
    });
