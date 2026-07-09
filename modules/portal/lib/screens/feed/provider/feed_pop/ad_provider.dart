import 'package:get/get_utils/get_utils.dart';

// lib/providers/ad_provider.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/url.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/screens/feed/widgets/feed_pop/feed_pop.dart';
import 'package:core/platform/api_services.dart';

final adProvider =
    FutureProvider.family<AdsListViewModel, String>((ref, feedAdSlug) async {
  final response = await ApiServices.get(
    ref: ref,
    '${URLs.apiAdvertisements}$feedAdSlug',
  );

  if (response != null && response.statusCode == 200) {
    final decodedBody = utf8.decode(response.data);
    final listingsJson = json.decode(decodedBody) as Map<dynamic, dynamic>;

    return AdsListViewModel.fromJson(listingsJson as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load advertisement');
  }
});

class AdFetcher extends ConsumerWidget {
  final String feedAdSlug;
  final String tag;

  const AdFetcher({required this.feedAdSlug, required this.tag, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adAsyncValue = ref.watch(adProvider(feedAdSlug));

    return adAsyncValue.when(
      data: (ad) => FeedPopPage(adFeedPop: ad, tagFeedPop: tag),
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.transparent,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('${'Error'.tr}: $error'.tr)),
      ),
    );
  }
}
