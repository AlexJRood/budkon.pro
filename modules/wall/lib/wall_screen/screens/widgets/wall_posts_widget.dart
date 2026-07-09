import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:core/user/user/user_model.dart';
import 'package:core/theme/apptheme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:core/theme/lottie.dart';
import 'package:wall/wall_screen/providers/wall_posts_paging_provider.dart';
import 'package:wall/wall_screen/screens/widgets/wall_post_card_widget.dart';
import 'package:core/user/user/user_provider.dart';

class WallPostsWidgetSliver extends ConsumerWidget {
  final int grid;
  final UserModel? profile;

  const WallPostsWidgetSliver({super.key, required this.grid, this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final pagingController = ref.watch(
      wallPostsPagingControllerProvider(profile?.userId),
    );

    return PagedSliverGrid<int, CommunityPost>(
      pagingController: pagingController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: grid,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      builderDelegate: PagedChildBuilderDelegate<CommunityPost>(
        itemBuilder: (context, post, index) {
          return WallPostCardWidget(
            post: post,
            tag: 'wall-post-${post.id}',
            mainImageUrl: post.media.isNotEmpty ? post.media.first.url : '',
            isDefaultDarkSystem: Theme.of(context).brightness == Brightness.dark,
            color: theme.sideBarbackground,
            textColor: theme.textColor,
            textFieldColor: theme.textFieldColor,
            buildShimmerPlaceholder: _buildShimmerPlaceholder(theme),
            buildPieMenuActions: _buildPieMenuActions(ref, post, context),
            aspectRatio: 0.8,
            isMobile: MediaQuery.of(context).size.width < 600,
            isOwnUser:
                post.author.userId.toString() == ref.read(userStateProvider)?.userId,
          );
        },
        firstPageProgressIndicatorBuilder: (_) =>
            Center(child: AppLottie.loading(size: 120)),
        newPageProgressIndicatorBuilder: (_) =>
            Center(child: AppLottie.loading(size: 120)),
        noItemsFoundIndicatorBuilder: (_) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLottie.noResults(size: 200),
              const SizedBox(height: 16),
              Text(
                'No wall posts found'.tr,
                style: TextStyle(
                  color: theme.textColor.withAlpha(204),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        firstPageErrorIndicatorBuilder: (_) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.textColor.withAlpha(153)),
              const SizedBox(height: 16),
              Text(
                'Failed to load wall posts'.tr,
                style: TextStyle(color: theme.textColor.withAlpha(204), fontSize: 16),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => pagingController.refresh(),
                child: Text('Retry'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieAction> _buildPieMenuActions(
    WidgetRef ref,
    CommunityPost post,
    BuildContext context,
  ) {
    final theme = ref.watch(themeColorsProvider);
    return [
      PieAction(
        tooltip: Text(post.hasUserLiked ? "Unlike".tr : "Like".tr,style: TextStyle(color: theme.textColor),),
        onSelect: () {},
        child: FaIcon(
          post.hasUserLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
          color: post.hasUserLiked ? Colors.red : null,
        ),
      ),
      PieAction(
        tooltip: Text('Comment'.tr,style: TextStyle(color: theme.textColor),),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.comment),
      ),
      PieAction(
        tooltip: Text('Share'.tr,style: TextStyle(color: theme.textColor),),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.shareNodes),
      ),
    ];
  }

  Widget _buildShimmerPlaceholder(ThemeColors theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.textFieldColor.withAlpha(76),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(Icons.photo, size: 48, color: theme.textColor.withAlpha(128)),
      ),
    );
  }
}
