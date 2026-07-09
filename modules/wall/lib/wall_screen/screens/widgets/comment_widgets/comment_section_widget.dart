import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:core/common/global_user_card.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:wall/wall_screen/providers/comment_post_provider.dart';
import 'package:wall/wall_screen/screens/widgets/comment_widgets/comment_tile.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wall/wall_screen/screens/widgets/components/feedcard_action_buttons.dart';
import '../../../model/comment_post_model.dart';
import '../../../model/community_post_model.dart';
import 'comment_textfield.dart';
import 'package:get/get_utils/get_utils.dart';

class CommentSection extends ConsumerStatefulWidget {
  final CommunityPost post;
  final bool isMobile;
  final String? feedType; // Feed type to identify which feed to update

  const CommentSection({
    super.key,
    required this.post,
    this.isMobile = false,
    this.feedType,
  });

  @override
  CommentSectionState createState() => CommentSectionState();
}

class CommentSectionState extends ConsumerState<CommentSection> {
  static const _pageSize = 5;
  final PagingController<int, CommunityComment> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      // Call the standalone function directly
      final newItems = await fetchCommunityComments(
        postId: widget.post.id,
        limit: _pageSize,
        offset: pageKey,
        ref: ref,
      );

      // Also update the provider state for other parts of the app
      if (pageKey == 0) {
        // For first page, replace the state
        ref.read(commentsProvider(widget.post.id).notifier).state =
            AsyncValue.data(newItems);
      } else {
        // For subsequent pages, append to existing state
        final currentState = ref.read(commentsProvider(widget.post.id));
        currentState.whenData((currentComments) {
          ref.read(commentsProvider(widget.post.id).notifier).state =
              AsyncValue.data([...currentComments, ...newItems]);
        });
      }

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
      // Also update provider state with error
      ref.read(commentsProvider(widget.post.id).notifier).state =
          AsyncValue.error(error, StackTrace.current);
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(postProvider)??widget.post;

    return Container(
      color: CustomColors.secondaryWidgetColor(context, ref),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.isMobile) _PostHeader(post: widget.post),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        widget.post.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            ref,
                          ),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ActionButtonRow(
                      layoutType: PostActionLayoutType.commentSection,
                      post: post!,
                      feedType: widget.feedType,
                    ),
                    const SizedBox(height: 30),
                    _CommentInteractionBar(post: widget.post,),
                    SizedBox(height: 20),
                    CommentList(pagingController: _pagingController),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: CustomColors.secondaryWidgetTextColor(
                      context,
                      ref,
                    ).withAlpha(51),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  GlobalUserCard(
                    userAsyncValue: ref.watch(userProvider),
                    shape: CardShape.square,
                    size: 30,
                    borderRadius: 12,
                    backgroundColor: Colors.white,
                  ),

                  SizedBox(width: 20),
                  Expanded(
                    child: CommentTextField(
                      postId: widget.post.id,
                      paginationController: _pagingController,
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
}

class _PostHeader extends ConsumerWidget {
  final CommunityPost post;

  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    String formatTimeAgo(DateTime dateTime) {
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
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

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CustomColors.secondaryWidgetTextColor(
                context,
                ref,
              ).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: post.author.avatar != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(post.author.avatar!),
                  )
                : Icon(
                    Icons.person,
                    color: CustomColors.secondaryWidgetColor(context, ref),
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${post.author.firstName} ${post.author.lastName}",
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Text(
                  formatTimeAgo(post.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(153),
                  ),
                ),
                
              ],
            ),
          ),
          // TODO: finish flow
          // IconButton(
          //   onPressed: () {},
          //   icon: Icon(
          //     Icons.more_horiz,
          //     color: CustomColors.secondaryWidgetTextColor(context, ref),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _CommentInteractionBar extends ConsumerWidget { final CommunityPost post;
  const _CommentInteractionBar({super.key,  required this.post,});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPost = ref.watch(postProvider) ?? post;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    overflow: TextOverflow.ellipsis,
                    '${currentPost.author.firstName} ${'and'.tr} ${currentPost.totalLikes} ${'others'.tr}',
                    style: TextStyle(
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        ref,
                      ),
                      fontSize: 13,
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

class CommentList extends ConsumerWidget {
  final PagingController<int, CommunityComment> pagingController;

  const CommentList({required this.pagingController});
  void _updateCommentInPagingController(CommunityComment updated) {
    final items = pagingController.itemList;
    if (items == null) return;

    final index = items.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      items[index] = updated; // Replace with updated
      pagingController.itemList = List.from(items); // Trigger UI rebuild
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double dialogWidth = screenWidth > 800 ? 600 : screenWidth * 0.9;
    double dialogHeight = screenHeight * 0.8;

    // Smaller sizes compared to main post
    double postWidth = dialogWidth * 0.95;
    double aspectRatio = 2.0;
    double imageHeight = postWidth / aspectRatio * 0.6; // Smaller image height

    double avatarSize = postWidth * 0.04; // Smaller avatar
    double titleFontSize = postWidth * 0.03; // Smaller title
    double subtitleFontSize = postWidth * 0.026; // Smaller subtitle
    double horizontalPadding = postWidth * 0.025;
    double verticalPadding = postWidth * 0.015;
    double iconSize = postWidth * 0.028; // Smaller icons
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: PagedListView<int, CommunityComment>(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        pagingController: pagingController,
        builderDelegate: PagedChildBuilderDelegate<CommunityComment>(
          itemBuilder: (context, comment, index) => CommentItem(
            onLikeClicked: (updatedComment) {
              _updateCommentInPagingController(updatedComment); // 🔹
            },
            comment: comment,
            avatarSize: avatarSize,
            titleFontSize: titleFontSize,
            subtitleFontSize: subtitleFontSize,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding,
            iconSize: iconSize,
          ),
          firstPageProgressIndicatorBuilder: (_) =>
              CommentShimmerPlaceholder(itemCount: 10),
          newPageProgressIndicatorBuilder: (_) =>
              CommentShimmerPlaceholder(itemCount: 10),
          noItemsFoundIndicatorBuilder: (_) => SizedBox(
            height: screenHeight * 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  "assets/images/no_comment.svg",
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                ),
                SizedBox(height: 5),
                Text(
                  "No comments yet".tr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Be the first to comment".tr,
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                  ),
                ),
              ],
            ),
          ),
          firstPageErrorIndicatorBuilder: (_) => Center(
            child: Text('${'❌ Error loading comments:'.tr} ${pagingController.error}'),
          ),
        ),
      ),
    );
  }
}
