import 'dart:convert';
import 'package:wall/wall_urls.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';
class ProfileWallpostProvider extends StateNotifier<AsyncValue<List<CommunityPost>>> {
  ProfileWallpostProvider(dynamic ref) : super(const AsyncValue.loading());

  Future<List<CommunityPost>> fetchUserwallpost(
    int pageKey, 
    int pageSize, 
    String? userId,
    dynamic ref
  ) async {
    try {
      if (userId == null) {
        if (kDebugMode) log('❌ User ID is null');
        return [];
      }

      final response = await ApiServices.get(
        WallUrls.communityPostsList, 
        hasToken: true, 
        ref: ref,
        queryParameters: {
          'author': userId,
          'page': pageKey,
          'page_size': pageSize,
        },
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
        log('✅ Successfully parsed ${posts.length} wall posts for user $userId.');
      }

      return posts;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        log('❌ Exception during wall post fetch: $e');
        log('🧵 Stack trace: $stackTrace');
      }
      return [];
    }
  }

  Future<void> loadUserWallPost(String? userId, dynamic ref) async {
    state = const AsyncValue.loading();

    try {
      final posts = await fetchUserwallpost(1, 20, userId, ref);
      state = AsyncValue.data(posts);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final profilewallsProvider = StateNotifierProvider<ProfileWallpostProvider, AsyncValue<List<CommunityPost>>>((ref) {
  return ProfileWallpostProvider(ref);
});
