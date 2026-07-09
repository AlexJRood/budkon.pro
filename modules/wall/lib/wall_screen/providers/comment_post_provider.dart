import 'dart:convert';
import 'package:wall/wall_urls.dart';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart'; // Added import for MediaType
import 'package:core/platform/api_services.dart';
import 'package:core/common/custom_error_handler.dart';

import '../model/comment_post_model.dart';

class PostCommentNotifier extends StateNotifier<AsyncValue<CommunityComment?>> {
  PostCommentNotifier() : super(const AsyncValue.data(null));

  Future<bool> submit({
    required int postId,

    required String content,
    Uint8List? image, // Optional image data
    required WidgetRef ref,
  }) async {
    state = const AsyncValue.loading();
    final comment = await postCommunityComment(
      postId: postId,
      content: content,
      image: image,
      ref: ref,
    );

    if (comment != null) {
      state = AsyncValue.data(comment);

      return true;
    } else {
      state = AsyncValue.error('Failed to post comment', StackTrace.current);
      return false;
    }
  }

  Future<CommunityComment?> postCommunityComment({
    required int postId,
    required String content,
    Uint8List? image,
    required WidgetRef ref,
  }) async {
    log('📩 Initiating comment posting...');

    try {
      // 🧾 Prepare form data (following the same pattern as CreatePostNotifier)
      final formData = FormData();

      // Add required fields
      formData.fields
        ..add(MapEntry('post', postId.toString()))
        ..add(MapEntry('content', content));

      // 🖼 Handle image with compression (if provided)
      if (image != null) {
        log('🖼 Compressing and adding image...');

        // Detect MIME type and extension
        final mimeType = lookupMimeType('', headerBytes: image) ?? 'image/jpeg';
        final extension = mimeType.split('/').last;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = 'comment_image_$timestamp.$extension';

        log('📁 Detected MIME type: $mimeType for file $filename');

        if (mimeType.startsWith('image/')) {
          try {
            final compressedImage = await FlutterImageCompress.compressWithList(
              image,
              quality: 70,
              format: CompressFormat.jpeg,
            );

            log(
              '📉 Compressed image: ${image.length} -> ${compressedImage.length} bytes',
            );

            formData.files.add(
              MapEntry(
                'files',
                MultipartFile.fromBytes(
                  compressedImage,
                  filename: filename,
                  contentType: MediaType.parse(mimeType),
                ),
              ),
            );
          } catch (e) {
            log('❌ Compression failed: $e. Adding original.');
            formData.files.add(
              MapEntry(
                'files',
                MultipartFile.fromBytes(
                  image,
                  filename: filename,
                  contentType: MediaType.parse(mimeType),
                ),
              ),
            );
          }
        } else {
          log('❌ Invalid image format');
          return null;
        }
      }

      log('📦 Final FormData fields: ${formData.fields}');
      log('📁 Attached files: ${formData.files.length}');

      final response = await ApiServices.post(
        WallUrls.communityCommentPost,
        formData: formData,
        hasToken: true,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final comment = CommunityComment.fromJson(response.data);
        log('✅ Comment posted successfully: ${jsonEncode(response.data)}');
        return comment;
      } else {
        log('❌ Failed to post comment. Status: ${response?.statusCode}');
        log('📨 Response: ${response?.data}');
      }
    } catch (e, stack) {
      log('💥 Error while posting comment: $e\n🧵 $stack');
    }
    return null;
  }
}

final postCommentProvider =
    StateNotifierProvider<PostCommentNotifier, AsyncValue<CommunityComment?>>(
      (ref) => PostCommentNotifier(),
    );

Future<List<CommunityComment>> fetchCommunityComments({
  required int postId,
  int limit = 10,
  int offset = 0,
  dynamic ref,
}) async {
  try {
    final url = '${WallUrls.commentGetPost(postId)}&limit=$limit&offset=$offset';
    if (kDebugMode) log('🌐 Sending GET request to: $url');

    final response = await ApiServices.get(url, hasToken: true, ref: ref);

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

    final List<CommunityComment> comments = responseData
        .whereType<Map<String, dynamic>>()
        .map((json) {
          try {
            log('💬 Parsing comment: ${jsonEncode(json)}');
            return CommunityComment.fromJson(json);
          } catch (e) {
            if (kDebugMode) {
              log('❌ Failed to parse CommunityComment:\n${jsonEncode(json)}');
              log('💥 Error: $e');
            }
            return null;
          }
        })
        .whereType<CommunityComment>()
        .toList();

    if (kDebugMode) {
      log(
        '✅ Successfully parsed ${comments.length} comments for post $postId.',
      );
    }

    return comments;
  } catch (e, stackTrace) {
    if (kDebugMode) {
      log('❌ Exception during comments fetch: $e');
      log('🧵 Stack trace: $stackTrace');
    }
    return [];
  }
}

// Optional: Create a StateNotifier for managing comments list
class CommentsNotifier
    extends StateNotifier<AsyncValue<List<CommunityComment>>> {
  CommentsNotifier() : super(const AsyncValue.data([]));

  Future<List<CommunityComment>> fetchComments({
    required int postId,
    int limit = 10,
    int offset = 0,
    dynamic ref,
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      state = const AsyncValue.loading();
    }

    try {
      final comments = await fetchCommunityComments(
        postId: postId,
        limit: limit,
        offset: offset,
        ref: ref,
      );

      if (isRefresh || offset == 0) {
        // Replace existing comments
        state = AsyncValue.data(comments);
      } else {
        // Append to existing comments (pagination)
        final currentComments = state.value ?? [];
        state = AsyncValue.data([...currentComments, ...comments]);
      }

      // Return the fetched comments for pagination logic
      return comments;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow; // Re-throw to let the pagination controller handle the error
    }
  }

  void addNewComment(CommunityComment comment) {
    final currentComments = state.value ?? [];
    state = AsyncValue.data([comment, ...currentComments]);
  }

  void reset() {
    state = const AsyncValue.data([]);
  }
}

// Provider for comments
final commentsProvider =
    StateNotifierProvider.family<
      CommentsNotifier,
      AsyncValue<List<CommunityComment>>,
      int
    >((ref, postId) => CommentsNotifier());

class CommentLikePostNotifier extends StateNotifier<AsyncValue<bool>> {
  CommentLikePostNotifier() : super(const AsyncValue.data(false));

  Future<bool> toggleLike({
    required BuildContext context,
    required int commentId,
    required bool isCurrentlyLiked,
  }) async {
    log('👍 Initiating like toggle for comment $commentId...');
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
              : 'user has liked this comment',
        ),
      );

      // Determine the correct URL based on like/unlike action
      final url = WallUrls.likeToComment(commentId);

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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            Customsnackbar().showSnackBar(
              "Success".tr,
              isCurrentlyLiked ? 'comment_unliked'.tr : 'comment_liked'.tr,
              "success",
              () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          );
        }

        return true;
      } else {
        // Set error state
        state = AsyncValue.error(
          isCurrentlyLiked ? 'failed_to_unlike_post'.tr : 'failed_to_like_post'.tr,
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

// Provider for the CommentLikePostNotifier
final commentlikePostProvider =
    StateNotifierProvider<CommentLikePostNotifier, AsyncValue<bool>>(
      (ref) => CommentLikePostNotifier(),
    );
