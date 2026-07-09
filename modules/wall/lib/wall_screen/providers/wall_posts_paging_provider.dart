import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:wall/wall_screen/providers/profile_wallpost_provider.dart';
import 'dart:developer' as developer;

const int _pageSize = 10;

/// Provides a PagingController tied to an optional profile userId.
/// The provider is auto-disposed when no longer used, and disposes the
/// controller as well. The family parameter is the profile's userId
/// (nullable) — if null the currently authenticated user is used.
final wallPostsPagingControllerProvider =
    Provider.autoDispose.family<PagingController<int, CommunityPost>, String?>(
  (ref, profileUserId) {
    final controller = PagingController<int, CommunityPost>(firstPageKey: 1);

    controller.addPageRequestListener((pageKey) async {
      try {
        final userId = profileUserId ?? ref.read(userStateProvider)?.userId;

        if (userId == null) {
          controller.error = Exception(
            'user_profile_not_available_login_to_view_wall_posts'.tr
          );
          return;
        }

        final wallPosts = await ref
            .read(profilewallsProvider.notifier)
            .fetchUserwallpost(pageKey, _pageSize, userId, ref);

        final isLastPage = wallPosts.length < _pageSize;
        if (isLastPage) {
          controller.appendLastPage(wallPosts);
        } else {
          controller.appendPage(wallPosts, pageKey + 1);
        }
      } catch (error) {
        controller.error = error;
      }
    });

    ref.onDispose(() {
      controller.dispose();
    });

      return controller;
    },
  );

  /// Update a specific post in the PagingController's current item list.
  ///
  /// Usage: call `updatePostInPagingController(ref, profileUserId, updatedPost)`
  /// from a widget or provider that has access to a `WidgetRef`/`Ref`.
  void updatePostInPagingController(
    WidgetRef ref,
    String? profileUserId,
    CommunityPost updatedPost,
  ) {
    try {
      final controller =
          ref.read(wallPostsPagingControllerProvider(profileUserId));

      final currentItems = controller.itemList ?? [];
      final index = currentItems.indexWhere((p) => p.id == updatedPost.id);
      if (index != -1) {
        final newItems = List<CommunityPost>.from(currentItems);
        newItems[index] = updatedPost;
        controller.itemList = newItems;
        developer.log(
          'Updated post ${updatedPost.id} in paging controller for user $profileUserId',
        );
      }
    } catch (e, st) {
      developer.log('Failed to update post ${updatedPost.id}: $e',
          error: e, stackTrace: st);
    }
  }
