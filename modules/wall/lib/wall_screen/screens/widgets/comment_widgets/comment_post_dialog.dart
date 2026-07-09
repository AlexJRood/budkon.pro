import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shimmer/shimmer.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:wall/emma/anchors/anchors_wall.dart';
import 'package:wall/wall_screen/model/comment_post_model.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:wall/wall_screen/screens/widgets/comment_widgets/comment_section_widget.dart';
import 'package:wall/wall_screen/screens/widgets/components/feedcard_action_buttons.dart';
import 'package:wall/wall_screen/screens/widgets/components/thumbnail_video_widget.dart';

import 'package:core/common/global_user_card.dart';

import '../../../providers/comment_post_provider.dart';
import 'comment_textfield.dart';
import '../components/custom_components.dart';
import 'package:get/get_utils/get_utils.dart';
// Dummy comment model

class CommentsDialog extends ConsumerStatefulWidget {
  final CommunityPost post;
  final String? feedType; // Feed type to identify which feed to update

  const CommentsDialog({super.key, required this.post, this.feedType});

  @override
  ConsumerState<CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends ConsumerState<CommentsDialog> {
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
    _scrollController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double dialogWidth = screenWidth > 800 ? 700 : screenWidth * 0.9;
    double dialogHeight = screenHeight * 0.9;

    // Smaller sizes compared to main post
    double postWidth = dialogWidth * 0.95;
    double aspectRatio = 2.0;
    double imageHeight = postWidth / aspectRatio * 0.6; // Smaller image height

    double avatarSize = postWidth * 0.02; // Smaller avatar
    double titleFontSize = postWidth * 0.025; // Smaller title
    double subtitleFontSize = postWidth * 0.02; // Smaller subtitle
    double horizontalPadding = postWidth * 0.025;
    double verticalPadding = postWidth * 0.015;
    double iconSize = postWidth * 0.028; // Smaller icons
    final userAsyncValue = ref.watch(userProvider);
    final post = ref.watch(postProvider);

    return EmmaUiAnchorTarget(
       anchorKey: WallEmmaAnchors.commentsDialog.anchorKey,

       spec: WallEmmaAnchors.commentsDialog,
       runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
       tapMode: EmmaUiAnchorTapMode.disabled,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: BoxDecoration(
            color: CustomColors.secondaryWidgetColor(context, ref),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(horizontalPadding),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
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
                    Text(
                      'Comments'.tr,
                      style: TextStyle(
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          ref,
                        ),
                        fontSize: titleFontSize * 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: EdgeInsets.all(horizontalPadding * 0.3),
                        child: AppIcons.close(
                          width: iconSize * 1.2,
                          height: iconSize * 1.2,
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            ref,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      // Mini post preview
                      Container(
                        margin: EdgeInsets.all(horizontalPadding),
                        decoration: BoxDecoration(
                          color: CustomColors.secondaryWidgetColor(context, ref),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CustomColors.secondaryWidgetTextColor(
                              context,
                              ref,
                            ).withAlpha(26),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author row
                            Padding(
                              padding: EdgeInsets.all(horizontalPadding),
                              child: Row(
                                children: [
                                  AvatarImageWidget(
                                    imageUrl: widget.post.author.avatar,
                                    avatarSize: avatarSize,
                                  ),
                                  SizedBox(width: horizontalPadding * 0.8),
                                  Text(
                                    widget.post.author.username.trim().isNotEmpty
                                        ? widget.post.author.username
                                        : 'Anonymous'.tr,
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
                                ],
                              ),
                            ),
      
                            // Post content
                            if (widget.post.content.trim().isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                  vertical: verticalPadding * 0.5,
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
      
                            // Media Grid (smaller)
                            if (widget.post.media.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.all(horizontalPadding),
                                child: SizedBox(
                                  height: imageHeight,
                                  child: _buildMediaLayout(
                                    context,
                                    widget.post.media,
                                    widget.post.media.length,
                                  ),
                                ),
                              ),
      
                            SizedBox(height: verticalPadding),
                          ],
                        ),
                      ),
      
                      ActionButtonRow(
                        layoutType: PostActionLayoutType.commentSection,
                        post: post!,
                        feedType: widget.feedType,
                      ),
                      SizedBox(height: verticalPadding),
                      // Comments section
                      CommentList(pagingController: _pagingController),
      
                      SizedBox(height: verticalPadding * 2),
                    ],
                  ),
                ),
              ),
      
              // Comment input section
              Container(
                padding: EdgeInsets.all(horizontalPadding),
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
      
                    SizedBox(width: horizontalPadding * 0.8),
                    EmmaUiAnchorTarget(
                      anchorKey: WallEmmaAnchors.commentTextField.anchorKey,

                      spec: WallEmmaAnchors.commentTextField,
                      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                      child: Expanded(
                        child: CommentTextField(
                          paginationController: _pagingController,
                          postId: widget.post.id,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaLayout(
    BuildContext context,
    List<CommunityMedia> media,
    int mediaCount,
  ) {
    if (mediaCount == 1) {
      return _buildSingleMedia(context, media[0]);
    } else if (mediaCount == 2) {
      return _buildTwoMediaLayout(context, media);
    } else if (mediaCount == 3) {
      return _buildThreeMediaLayout(context, media);
    } else if (mediaCount == 4) {
      return _buildFourMediaLayout(context, media);
    } else {
      return _buildMoreThanFourLayout(context, media);
    }
  }

  Widget _buildSingleMedia(BuildContext context, CommunityMedia mediaItem) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: _buildMediaContent(context, mediaItem),
      ),
    );
  }

  Widget _buildTwoMediaLayout(
    BuildContext context,
    List<CommunityMedia> media,
  ) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: double.infinity,
              child: _buildMediaContent(context, media[0]),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: double.infinity,
              child: _buildMediaContent(context, media[1]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreeMediaLayout(
    BuildContext context,
    List<CommunityMedia> media,
  ) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: double.infinity,
              child: _buildMediaContent(context, media[0]),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    child: _buildMediaContent(context, media[1]),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    child: _buildMediaContent(context, media[2]),
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
  ) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: double.infinity,
              child: _buildMediaContent(context, media[0]),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    child: _buildMediaContent(context, media[1]),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: double.infinity,
                          child: _buildMediaContent(context, media[2]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: double.infinity,
                          child: _buildMediaContent(context, media[3]),
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
  ) {
    final extraCount = media.length - 3;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: double.infinity,
              child: _buildMediaContent(context, media[0]),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    child: _buildMediaContent(context, media[1]),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: double.infinity,
                          child: _buildMediaContent(context, media[2]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildMediaContent(context, media[3]),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildMediaContent(BuildContext context, CommunityMedia mediaItem) {
    if (mediaItem.isImage) {
      return CachedNetworkImage(
        imageUrl: mediaItem.url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: ShimmerColors.base(context),
          highlightColor: ShimmerColors.highlight(context),
          child: Container(color: ShimmerColors.background(context)),
        ),
        errorWidget: (context, url, error) => ProfessionalImagePlaceholder(),
      );
    } else if (mediaItem.isVideo) {
      return VideoThumbnail(media: mediaItem);
    } else {
      return ProfessionalImagePlaceholder();
    }
  }
}
