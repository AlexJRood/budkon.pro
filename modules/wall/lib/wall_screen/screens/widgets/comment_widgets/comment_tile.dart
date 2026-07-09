import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:shimmer/shimmer.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:wall/emma/anchors/anchors_wall.dart';
import 'package:wall/wall_screen/model/comment_post_model.dart';
import 'package:wall/wall_screen/providers/comment_post_provider.dart';

class CommentItem extends ConsumerWidget {
  final CommunityComment comment;
  final double avatarSize;
  final double titleFontSize;
  final double subtitleFontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double iconSize;
  final ValueChanged<CommunityComment>? onLikeClicked; // NEW

  const CommentItem({
    Key? key,
    required this.comment,
    required this.avatarSize,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconSize,
    this.onLikeClicked, // NEW
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    String formatTimeAgo(DateTime dateTime) {
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'just_now'.tr;
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    }

    void toggleLike() async {
      try {
        final updatedComment = CommunityComment(
          id: comment.id,
          post: comment.post,
          user: comment.user,
          content: comment.content,
          media: comment.media,
          createdAt: comment.createdAt,
          totalLikes: comment.hasUserLiked
              ? comment.totalLikes - 1
              : comment.totalLikes + 1,
          hasUserLiked: !comment.hasUserLiked,
        );

        onLikeClicked?.call(updatedComment); // 🔹 Notify parent immediately

        final success = await ref
            .read(commentlikePostProvider.notifier)
            .toggleLike(
              context: context,
              commentId: comment.id,
              isCurrentlyLiked: comment.hasUserLiked,
            );

        if (success) {
          onLikeClicked?.call(updatedComment); // 🔹 Notify parent immediately
        }
      } catch (e) {
        log('Error toggling like: $e');

        // Revert to original post state
        onLikeClicked?.call(comment); // 🔹 Notify parent immediately

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        padding: EdgeInsets.all(horizontalPadding * 0.8),
        decoration: BoxDecoration(
          color: CustomColors.secondaryWidgetColor(context, ref),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            width: 1,
            color: CustomColors.secondaryWidgetColor(context, ref),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: avatarSize * 0.8,
                  backgroundImage: NetworkImage(comment.user.avatar),
                ),
                SizedBox(width: horizontalPadding * 0.6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${comment.user.firstName} ${comment.user.lastName}",
                        style: TextStyle(
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            ref,
                          ),
                          fontSize: titleFontSize * 0.9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatTimeAgo(comment.createdAt),
                        style: TextStyle(
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            ref,
                          ).withAlpha(153),
                          fontSize: subtitleFontSize * 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                EmmaUiAnchorTarget(
                  anchorKey: '${WallEmmaAnchors.commentLikeButton.anchorKey}_${comment.id}',
                  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                  child: InkWell(
                    onTap: toggleLike, // Call toggleLike on tap
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: comment.hasUserLiked
                              ? HugeIcons.strokeRoundedFavouriteCircle
                              : HugeIcons.strokeRoundedFavourite,
                          color: comment.hasUserLiked
                              ? Colors.red
                              : CustomColors.secondaryWidgetTextColor(
                                  context,
                                  ref,
                                ).withAlpha(178),
                          size: iconSize * 0.8,
                        ),
                        SizedBox(width: horizontalPadding * 0.3),
                        Text(
                          '${comment.totalLikes}',
                          style: TextStyle(
                            color: CustomColors.secondaryWidgetTextColor(
                              context,
                              ref,
                            ).withAlpha(178),
                            fontSize: subtitleFontSize * 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: verticalPadding * 0.5),
            if (comment.media.isNotEmpty && comment.media.first.isImage)
              Padding(
                padding: EdgeInsets.only(bottom: verticalPadding * 0.5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: CachedNetworkImage(
                      imageUrl: comment.media.first.url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: ShimmerColors.base(context),
                        highlightColor: ShimmerColors.highlight(context),
                        child: Container(
                          color: CustomColors.secondaryWidgetColor(
                            context,
                            ref,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => HugeIcon(
                        icon: HugeIcons.strokeRoundedImageDelete01,
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          ref,
                        ),
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            Text(
              comment.content,
              style: TextStyle(
                color: CustomColors.secondaryWidgetTextColor(context, ref),
                fontSize: subtitleFontSize,
              ),
            ),
            SizedBox(height: verticalPadding * 0.5),
          ],
        ),
      ),
    );
  }
}
