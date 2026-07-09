import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/lottie.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:wall/wall_screen/providers/wall_post_provider.dart';
import 'package:wall/wall_screen/screens/widgets/components/custom_components.dart';
import 'package:wall/wall_screen/screens/widgets/feedcard/social_post_widget_pc.dart';
import 'package:wall/wall_screen/screens/widgets/feedcard/social_post_widget_mobile.dart';
import 'package:core/ui/device_type_util.dart';

/// Factory for building tab views
Widget buildFeedTab(String title, String type, {bool isMobile = false}) {
  return FeedListView(title: title, type: type, isMobile: isMobile);
}

final feedPagingControllerProvider =
StateNotifierProvider.family<FeedPagingControllerNotifier,
    PagingController<int, CommunityPost>, String>((ref, feedType) {
  return FeedPagingControllerNotifier(ref, feedType);
});

class FeedPagingControllerNotifier
    extends StateNotifier<PagingController<int, CommunityPost>> {
  final Ref ref;
  final String feedType;
  static const _pageSize = 10;
  bool _isInitialized = false;

  FeedPagingControllerNotifier(this.ref, this.feedType)
      : super(PagingController<int, CommunityPost>(firstPageKey: 1)) {
    _initialize();
  }

  void _initialize() {
    log('Initializing FeedPagingController for $feedType');
    state.addPageRequestListener(_fetchPage);
    _isInitialized = true;

    // Force initial load
    Future.microtask(() {
      if (mounted && (state.itemList?.isEmpty ?? true)) {
        log('Triggering initial refresh for $feedType');
        state.refresh();
      }
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    if (!_isInitialized) {
      log('Controller not initialized for $feedType, skipping fetch');
      return;
    }

    try {
      log(
        'Fetching page for $feedType with pageKey: $pageKey, pageSize: $_pageSize',
      );

      final newItems = await fetchCommunityPosts(
        pageKey: pageKey,
        pageSize: _pageSize,
        ref: ref,
        type: feedType,
      );

      log('Fetched ${newItems.length} items for $feedType');

      if (!mounted) {
        log('Controller disposed, not updating state');
        return;
      }

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        state.appendLastPage(newItems);
        log('Last page appended for $feedType');
      } else {
        final nextPageKey = pageKey + 1;
        state.appendPage(newItems, nextPageKey);
        log('Page appended for $feedType, next key: $nextPageKey');
      }
    } catch (error, stackTrace) {
      log('Error fetching page for $feedType: $error');
      log('Stack trace: $stackTrace');
      if (mounted) {
        state.error = error;
      }
    }
  }

  void updatePost(CommunityPost updatedPost) {
    if (!mounted) return;

    final currentItems = state.itemList ?? [];
    final index = currentItems.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) {
      currentItems[index] = updatedPost;
      state.itemList = [...currentItems];
      log('Updated post ${updatedPost.id} in $feedType feed');
    }
  }

  void addNewPost(CommunityPost newPost) {
    if (!mounted) return;

    final currentItems = state.itemList ?? [];
    state.itemList = [newPost, ...currentItems];
    log('Added new post ${newPost.id} to $feedType feed');
  }

  void deletePost(int postId) {
    if (!mounted) return;

    final currentItems = state.itemList ?? [];
    final updatedItems =
    currentItems.where((post) => post.id != postId).toList();
    state.itemList = updatedItems;
    log('Deleted post $postId from $feedType feed');
  }

  void refresh() {
    if (!mounted) return;
    log('Refreshing $feedType feed');
    state.refresh();
  }

  @override
  void dispose() {
    log('Disposing FeedPagingController for $feedType');
    _isInitialized = false;
    state.dispose();
    super.dispose();
  }
}

/// Generic Feed List
class FeedListView extends ConsumerStatefulWidget {
  final String title;
  final String type;
  final bool isMobile;

  const FeedListView({
    super.key,
    required this.title,
    required this.type,
    this.isMobile = false,
  });

  @override
  FeedListViewState createState() => FeedListViewState();
}

class FeedListViewState extends ConsumerState<FeedListView>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    log('Initializing FeedListView for ${widget.type}');
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for AutomaticKeepAliveClientMixin

    final pagingController = ref.watch(
      feedPagingControllerProvider(widget.type),
    );

    log(
      'Building FeedListView for ${widget.type}, controller state: ${pagingController.itemList?.length ?? 0} items',
    );

    final cardBuilder = widget.isMobile
        ? (CommunityPost post) => SocialPostWidgetMobile(
      post: post,
      feedType: widget.type,
    )
        : (CommunityPost post) => SocialPostWidgetPc(
      post: post,
      feedType: widget.type,
    );

    return CustomScrollView(
      key: ValueKey('feed_${widget.type}'),
      slivers: [
        if (widget.isMobile) ...[
          SliverToBoxAdapter(
              child: PostComposerMobile(),
          ),
        ],
        if (!widget.isMobile) ...[
          SliverToBoxAdapter(
              child: PostComposer(),
          ),
        ],
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 0 : 16),
          sliver: PagedSliverList<int, CommunityPost>(
            pagingController: pagingController,
            builderDelegate: PagedChildBuilderDelegate<CommunityPost>(
              itemBuilder: (_, post, __) => Padding(
                padding: EdgeInsets.only(bottom: widget.isMobile ? 0 : 8),
                child: cardBuilder(post),
              ),
              firstPageProgressIndicatorBuilder: (_) {
                log('Showing first page progress indicator for ${widget.type}');
                return SocialPostShimmerPlaceholder(
                  itemCount: 3,
                  isMobile: widget.isMobile,
                );
              },
              newPageProgressIndicatorBuilder: (_) {
                log('Showing new page progress indicator for ${widget.type}');
                return SocialPostShimmerPlaceholder(
                  itemCount: 1,
                  isMobile: widget.isMobile,
                );
              },
              noItemsFoundIndicatorBuilder: (_) {
                log('No items found for ${widget.type}');
                return Center(child: AppLottie.noResults(size: 250));
              },
              firstPageErrorIndicatorBuilder: (_) {
                log('First page error for ${widget.type}');
                return Center(child: AppLottie.error(size: 250));
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 70)),
      ],
    );
  }
}
