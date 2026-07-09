// lib/providers/single_post_provider.dart

import 'dart:convert';
import 'package:wall/wall_urls.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:lottie/lottie.dart';

import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:wall/wall_screen/screens/widgets/media_dialog/mobile/media_viewer_widget_mobile.dart';
import 'package:wall/wall_screen/screens/widgets/media_dialog/pc/media_viewer_widget_pc.dart';
import 'package:get/get_utils/get_utils.dart';
import 'dart:developer' as developer;


final singlePostProvider = FutureProvider.family<CommunityPost, int>((
  ref,
  postId,
) async {
  final url = WallUrls.singlePost(postId);

  if(postId == null || postId == "events" || url == "https://www.superbee.cloud/community/posts/-1/") {
    developer.log("⚠️ Invalid postId: $postId", name: "SinglePostProvider");
    return CommunityPost.empty();
  }

  developer.log(
    "🔍 [singlePostProvider] Starting fetch...",
    name: "SinglePostProvider",
  );
  developer.log("📌 URL: $url", name: "SinglePostProvider");

  try {
    final response = await ApiServices.get(ref: ref, url, hasToken: true);

    developer.log("✅ Response received", name: "SinglePostProvider");

    if (response == null) {
      developer.log("❌ Response is null", name: "SinglePostProvider");
      throw Exception('Null response from API');
    }

    developer.log(
      "📄 Status Code: ${response.statusCode}",
      name: "SinglePostProvider",
    );
    developer.log(
      "📄 Headers: ${response.headers}",
      name: "SinglePostProvider",
    );

    if (response.data is Uint8List) {
      developer.log(
        "📦 Data is Uint8List — decoding...",
        name: "SinglePostProvider",
      );
      String jsonString = utf8.decode(response.data);
      developer.log(
        "📄 Decoded JSON String (first 500 chars): ${jsonString.substring(0, jsonString.length > 500 ? 500 : jsonString.length)}",
        name: "SinglePostProvider",
      );
      final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      return CommunityPost.fromJson(decodedJson);
    } else if (response.data is Map<String, dynamic>) {
      developer.log(
        "📦 Data is Map<String, dynamic>: ${jsonEncode(response.data)}",
        name: "SinglePostProvider",
      );
      return CommunityPost.fromJson(response.data);
    } else {
      developer.log(
        "⚠️ Unexpected response data type: ${response.data.runtimeType}",
        name: "SinglePostProvider",
      );
      throw Exception('Unexpected response format');
    }
  } catch (e, stack) {
    developer.log(
      "💥 Exception: $e",
      error: e,
      stackTrace: stack,
      name: "SinglePostProvider",
    );
    rethrow;
  }
});

class SinglePostFetcher extends ConsumerWidget {
  final int postId;
  final int initialIndex;

  const SinglePostFetcher({
    super.key,
    required this.postId,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsyncValue = ref.watch(singlePostProvider(postId));
    final isMobile = MediaQuery.of(context).size.width < 800;

    return postAsyncValue.when(
      data: (postData) {
        // ref.read(postProvider.notifier).setPost(postData);
        return isMobile
            ? MobileMediaViewerWidget(
                isSingle: true,
                media: postData.media,
                initialIndex: initialIndex,
                postData: postData,
              )
            : MediaViewerWidget(
                isSingle: true,
                media: postData.media,
                initialIndex: initialIndex,
                postData: postData,
              );
      },
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/loading.json',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 16),
              Text(
                'Loading post...'.tr,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/file_error.json',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 16),
                Text(
                  'Error Loading Post'.tr,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${'Failed to load post:'.tr}$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Go Back'.tr),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
