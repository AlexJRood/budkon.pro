import 'package:get/get_utils/get_utils.dart';
import 'package:wall/wall_urls.dart';

import '../model/community_post_model.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:core/platform/api_services.dart';
import 'dart:developer';
import 'package:core/common/custom_error_handler.dart';

import '../model/create_post_model.dart';

class CreatePostNotifier extends StateNotifier<AsyncValue<CommunityPost?>> {
  CreatePostNotifier() : super(const AsyncValue.data(null));

  Future<bool> createPost({
    required BuildContext context,
    required CreatePostState formState,
  }) async {
    log('📩 Initiating post creation...');

    try {
      // 🔍 Validate required fields
      final missingFields = <String>[];
      if (formState.content.trim().isEmpty) missingFields.add("Content");
      if (formState.wallType.trim().isEmpty) missingFields.add("Wall Type");

      if (missingFields.isNotEmpty) {
        log('⚠️ Missing fields: ${missingFields.join(', ')}');
        final snackBar = Customsnackbar().showSnackBar(
          "missing_fields".tr,
          'please_fill_in_fields'.tr + missingFields.join(', '),
          "warning",
          () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return false;
      }

      // 🧾 Prepare form data
      final formData = FormData();

      formData.fields
        ..add(MapEntry('content', formState.content))
        ..add(MapEntry('wall_type', formState.wallType));

      if (formState.location?.isNotEmpty ?? false) {
        formData.fields.add(MapEntry('location', formState.location!));
      }
      if (formState.lat != null) {
        formData.fields.add(MapEntry('lat', formState.lat.toString()));
      }
      if (formState.lon != null) {
        formData.fields.add(MapEntry('lon', formState.lon.toString()));
      }

      for (final id in formState.taggedUserIds) {
        formData.fields.add(MapEntry('tagged_users', id.toString()));
      }

      // 🖼 Handle images with compression
      if (formState.imagesData != null && formState.imagesData!.isNotEmpty) {
        log(
          '🖼 Compressing and adding ${formState.imagesData!.length} image(s)...',
        );
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        for (final entry in formState.imagesData!.asMap().entries) {
          final index = entry.key;
          final imageData = entry.value;

          // Detect MIME type and extension
          final mimeType = lookupMimeType('', headerBytes: imageData);
          final extension = mimeType?.split('/').last ?? 'jpg';
          final filename = 'file_${timestamp}_$index.$extension';

          log('📁 Detected MIME type: $mimeType for file $filename');

          if (mimeType != null && mimeType.startsWith('image/')) {
            try {
              final compressed = await FlutterImageCompress.compressWithList(
                imageData,
                quality: 70,
                format: CompressFormat.jpeg,
              );

              log(
                '📉 Compressed image $index: ${imageData.length} -> ${compressed.length} bytes',
              );

              formData.files.add(
                MapEntry(
                  'files',
                  MultipartFile.fromBytes(compressed, filename: filename),
                ),
              );
            } catch (e) {
              log(
                '❌ Compression failed for image $index: $e. Adding original.',
              );
              formData.files.add(
                MapEntry(
                  'files',
                  MultipartFile.fromBytes(imageData, filename: filename),
                ),
              );
            }
          } else {
            // It's not an image: likely a video or unknown type
            log('🎥 Skipping compression. Attaching as is: $filename');
            formData.files.add(
              MapEntry(
                'files',
                MultipartFile.fromBytes(imageData, filename: filename),
              ),
            );
          }
        }
      }

      log('📦 Final FormData fields: ${formData.fields}');
      log('📁 Attached files: ${formData.files.length}');

      final response = await ApiServices.post(
        WallUrls.communityPosts,
        formData: formData,
        hasToken: true,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final post = CommunityPost.fromJson(response.data);
        state = AsyncValue.data(post);

        log('✅ Post successfully created: ${response.data}');
        ScaffoldMessenger.of(context).showSnackBar(
          Customsnackbar().showSnackBar(
            "Success".tr,
            'post_created'.tr,
            "success",
            () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        );
        return true;
      } else {
        log('❌ Failed to create post. Status: ${response?.statusCode}');
        log('📨 Response: ${response?.data}');
        ScaffoldMessenger.of(context).showSnackBar(
          Customsnackbar().showSnackBar(
            "Error".tr,
            "failed_to_create_post".tr,
            "error",
            () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        );
      }
    } catch (e, stack) {
      log('💥 Exception during post creation\n🧨 $e\n🧵 $stack');
      ScaffoldMessenger.of(context).showSnackBar(
        Customsnackbar().showSnackBar(
          "Error".tr,
          "unexpected_error_occurred".tr,
          "error",
          () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      );
    }

    log('🚫 Post creation failed.');
    return false;
  }

   // ===============================================================
  // ✏️ EDIT POST
  // ===============================================================
  Future<bool> editPost({
    required BuildContext context,
    required int postId,
    required CreatePostState formState,
  }) async {
    log('✏️ Initiating post edit for ID: $postId');

    try {
      final formData = FormData();

      formData.fields
        ..add(MapEntry('content', formState.content))
        ..add(MapEntry('wall_type', formState.wallType));

      if (formState.location?.isNotEmpty ?? false) {
        formData.fields.add(MapEntry('location', formState.location!));
      }
      if (formState.lat != null) {
        formData.fields.add(MapEntry('lat', formState.lat.toString()));
      }
      if (formState.lon != null) {
        formData.fields.add(MapEntry('lon', formState.lon.toString()));
      }

      for (final id in formState.taggedUserIds) {
        formData.fields.add(MapEntry('tagged_users', id.toString()));
      }

      // 🗑 Handle media deletion (edit mode only)
      if (formState.deleteMediaIds.isNotEmpty) {
        log('🗑 Marking ${formState.deleteMediaIds.length} media file(s) for deletion...');
        for (final mediaId in formState.deleteMediaIds) {
          formData.fields.add(MapEntry('delete_media_ids', mediaId.toString()));
        }
      }

      // 🖼 Handle new media uploads
      if (formState.imagesData != null && formState.imagesData!.isNotEmpty) {
        log('🖼 Adding ${formState.imagesData!.length} file(s) for edit...');
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        for (final entry in formState.imagesData!.asMap().entries) {
          final index = entry.key;
          final imageData = entry.value;

          final mimeType = lookupMimeType('', headerBytes: imageData);
          final extension = mimeType?.split('/').last ?? 'jpg';
          final filename = 'edit_${timestamp}_$index.$extension';

          formData.files.add(
            MapEntry(
              'files',
              MultipartFile.fromBytes(imageData, filename: filename),
            ),
          );
        }
      }

      final response = await ApiServices.patch(
        WallUrls.editPost(postId),
        formData: formData,
        hasToken: true,
      );
      

      if (response != null && (response.statusCode == 200 || response.statusCode == 202)) {
         final post = CommunityPost.fromJson(response.data);
        state = AsyncValue.data(post);
        log('✅ Post $postId edited successfully.');
        log('Post data: ${post.toJson()}');
        // ScaffoldMessenger.of(context).showSnackBar(
        //   Customsnackbar().showSnackBar(
        //     "Success",
        //     "Post updated successfully",
        //     "success",
        //     () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        //   ),
        // );
        return true;
      } else {
        log('❌ Failed to edit post. Status: ${response?.statusCode}');
        // ScaffoldMessenger.of(context).showSnackBar(
        //   Customsnackbar().showSnackBar(
        //     "Error",
        //     "Failed to update post",
        //     "error",
        //     () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        //   ),
        // );
      }
    } catch (e, stack) {
      log('💥 Exception during post edit\n🧨 $e\n🧵 $stack');
      ScaffoldMessenger.of(context).showSnackBar(
        Customsnackbar().showSnackBar(
          "Error".tr,
          'unexpected_error_while_editing_post'.tr,
          "error",
          () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      );
    }

    log('🚫 Post edit failed.');
    return false;
  }

  // ===============================================================
  // 🗑 DELETE POST
  // ===============================================================
  Future<bool> deletePost({
  
    required int postId,
  }) async {
    log('🗑 Initiating delete for post ID: $postId');

    try {
      final response = await ApiServices.delete(
        WallUrls.deletePost(postId),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        log('✅ Post $postId deleted successfully.');
        // if (context.mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     Customsnackbar().showSnackBar(
        //       "Deleted",
        //       "Post deleted successfully",
        //       "success",
        //       () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        //     ),
        //   );
        // }
        return true;
      } else {
        log('❌ Failed to delete post. Status: ${response?.statusCode}');
        // if (context.mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     Customsnackbar().showSnackBar(
        //       "Error",
        //       "Failed to delete post",
        //       "error",
        //       () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        //     ),
        //   );
        // }
        return false;
      }
    } catch (e, stack) {
      log('💥 Exception during delete\n🧨 $e\n🧵 $stack');
    
      return false;
    }

    
  }

}

final wallPostProvider =
    StateNotifierProvider<CreatePostNotifier, AsyncValue<CommunityPost?>>(
      (ref) => CreatePostNotifier(),
    );


 

Future<List<CommunityPost>> fetchCommunityPosts({
  int pageKey = 1,
  int pageSize = 10,
  dynamic ref,
  String type = 'all',
}) async {
  try {
    String baseUrl;
    Map<String, dynamic> queryParameters = {
      'page': pageKey,
      'page_size': pageSize,
    };

    switch (type) {
      case 'all':
        baseUrl = WallUrls.communityPostsList;
        break;
      case 'agents':
        baseUrl = WallUrls.communityPostsListAgents;
        break;
      case 'flipers':
        baseUrl = WallUrls.communityPostsListFlipers;
        break;
      case 'favourites':
        baseUrl = WallUrls.communityPostsListFavorites;
        break;
      case 'groups':
        baseUrl = WallUrls.communityPostsListGroups;
        break;
      case 'developers':
        baseUrl = WallUrls.communityPostsListDevelopers;
        break;
      default:
        baseUrl = WallUrls.communityPostsList;
    }

    if (kDebugMode) log('🌐 Sending GET request to: $baseUrl with params: $queryParameters');

    final response = await ApiServices.get(
      baseUrl, 
      hasToken: true, 
      ref: ref,
      queryParameters: queryParameters,
    );

    if (response == null) {
      if (kDebugMode) log('❌ Response is null');
      return [];
    }

    if (response.statusCode != 200) {
      if (kDebugMode) log('❌ Bad status code: ${response.statusCode}');
      return [];
    }

    dynamic responseData = response.data;

    // Decode bytes if it's List<int>
    if (responseData is List<int>) {
      responseData = utf8.decode(responseData);
    }

    // Decode JSON if it's a String
    if (responseData is String) {
      try {
        responseData = json.decode(responseData);
      } catch (e) {
        if (kDebugMode) log('❌ JSON decode error: $e');
        return [];
      }
    }

    // Narrow down to 'results' or 'data'
    if (responseData is Map) {
      if (responseData.containsKey('results')) {
        responseData = responseData['results'];
      } else if (responseData.containsKey('data')) {
        responseData = responseData['data'];
      }
    }

    // Final validation: must be a List
    if (responseData is! List) {
      if (kDebugMode) {
        log('❌ Unexpected response format: ${responseData.runtimeType}');
        log('📦 Full Response: $responseData');
      }
      return [];
    }

    final List<CommunityPost> posts = responseData
        .whereType<Map<String, dynamic>>()
        .map((json) {
          try {
            return CommunityPost.fromJson(json);
          } catch (e) {
            if (kDebugMode) {
              log('❌ Failed to parse CommunityPost:\n${jsonEncode(json)}');
              log('💥 Error: $e');
            }
            return null;
          }
        })
        .whereType<CommunityPost>()
        .toList();

    if (kDebugMode) {
      log('✅ Successfully parsed ${posts.length} posts.');
    }

    return posts;
  } catch (e, stackTrace) {
    if (kDebugMode) {
      log('❌ Exception during post fetch: $e');
      log('🧵 Stack trace: $stackTrace');
    }
    return [];
  }
}

class CommunityPostsNotifier
    extends StateNotifier<AsyncValue<List<CommunityPost>>> {
  CommunityPostsNotifier() : super(const AsyncValue.data([]));

  Future<List<CommunityPost>> fetchPosts({
    int pageKey = 1,
    int pageSize = 10,
    dynamic ref,
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      state = const AsyncValue.loading();
    }

    try {
      final posts = await fetchCommunityPosts(
        pageKey: pageKey,
        pageSize: pageSize,
        ref: ref,
      );

      if (isRefresh || pageKey == 1) {
        state = AsyncValue.data(posts);
      } else {
        final currentPosts = state.value ?? [];
        state = AsyncValue.data([...currentPosts, ...posts]);
      }

      return posts;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  void addNewPost(CommunityPost post) {
    final currentPosts = state.value ?? [];
    state = AsyncValue.data([post, ...currentPosts]);
  }

  void reset() {
    state = const AsyncValue.data([]);
  }
}

final communityPostsProvider =
    StateNotifierProvider<
      CommunityPostsNotifier,
      AsyncValue<List<CommunityPost>>
    >((ref) => CommunityPostsNotifier());


class LikePostNotifier extends StateNotifier<AsyncValue<bool>> {
  LikePostNotifier() : super(const AsyncValue.data(false));

  Future<bool> toggleLike({
    required BuildContext context,
    required int postId,
    required bool isCurrentlyLiked,
  }) async {
    log('👍 Initiating like toggle for post $postId...');
    log('📊 Current like status: $isCurrentlyLiked');

    try {
      // Set loading state
      state = const AsyncValue.loading();

      // 🧾 Prepare form data
      final formData = FormData();
      formData.fields.add(
        MapEntry(
          'content',
          isCurrentlyLiked
              ? 'user has removed the like'
              : 'user has liked this post',
        ),
      );

      // Determine the correct URL based on like/unlike action
      final url = WallUrls.communityPostAddLike(postId);

      log('📦 FormData prepared with content: "${formData.fields[0].value}"');
      log('🌐 Sending POST request to: $url');

      final response = isCurrentlyLiked
          ? await ApiServices.delete(url, hasToken: true)
          : await ApiServices.post(url, formData: formData, hasToken: true);

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        log('✅ Like toggle successful: ${response.data}');

        // Set success state
        state = const AsyncValue.data(true);

        // Show success message
        // if (context.mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     Customsnackbar().showSnackBar(
        //       "Success",
        //       isCurrentlyLiked ? "Post unliked" : "Post liked",
        //       "success",
        //       () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        //     ),
        //   );
        // }

        return true;
      } else {
        // Set error state
        state = AsyncValue.error(
          'Failed to ${isCurrentlyLiked ? "unlike" : "like"} post',
          StackTrace.current,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            Customsnackbar().showSnackBar(
              "Error".tr,
              isCurrentlyLiked ? 'failed_to_unlike_post'.tr : 'failed_to_like_post'.tr,
              "error",
              () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          );
        }

        return false;
      }
    } catch (e, stackTrace) {
      log('💥 Exception during like toggle\n🧨 $e\n🧵 $stackTrace');

      // Set error state
      state = AsyncValue.error(e, stackTrace);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          Customsnackbar().showSnackBar(
            "Error".tr,
            'unexpected_error_occurred'.tr,
            "error",
            () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        );
      }

      return false;
    }
  }

  // Method to reset the state
  void reset() {
    state = const AsyncValue.data(false);
  }
}

// Provider for the LikePostNotifier
final likePostProvider =
    StateNotifierProvider<LikePostNotifier, AsyncValue<bool>>(
      (ref) => LikePostNotifier(),
    );
