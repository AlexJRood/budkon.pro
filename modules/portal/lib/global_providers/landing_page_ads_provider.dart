import 'dart:convert';
import 'package:portal/portal_urls.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:get/get_utils/get_utils.dart';
import '../enum/landing_ads_tab.dart';
import '../models/ad_list_view_model.dart';

final landingPageAdsProvider = StateNotifierProvider.family<
    LandingPageAdsNotifier,
    AsyncValue<List<AdsListViewModel>>,
    LandingAdsTab>((ref, tab) {
  return LandingPageAdsNotifier(ref, tab);
});

class LandingPageAdsNotifier
    extends StateNotifier<AsyncValue<List<AdsListViewModel>>> {
  LandingPageAdsNotifier(this.ref, this.tab)
      : super(const AsyncValue.loading()) {
    fetchAds();
  }

  final Ref ref;
  final LandingAdsTab tab;

  Map<String, dynamic> filters = {};
  String searchQuery = '';
  String excludeQuery = '';
  String sortOrder = '';

  Future<void> fetchAds() async {
    state = const AsyncValue.loading();



    try {
      // throw Exception('Test error message - Remove this line after testing');
      final needsAuth = tab == LandingAdsTab.recentlyViewed;
      final hasToken = ApiServices.token != null;

      final response = await ApiServices.get(
        ref: ref,
        PortalUrls.landingPageAds,
        hasToken: needsAuth ? hasToken : false,
        queryParameters: {
          'tab': tab.apiValue,
          ...filters,
          if (searchQuery.isNotEmpty) 'search': searchQuery,
          if (excludeQuery.isNotEmpty) 'exclude': excludeQuery,
          if (sortOrder.isNotEmpty) 'sort': sortOrder,
        },
      );

      if (response != null && response.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final Map<String, dynamic> jsonMap =
        json.decode(decodedBody) as Map<String, dynamic>;

        final List<dynamic> results = jsonMap['results'] ?? [];

        final ads = results
            .map((item) => AdsListViewModel.fromJson(item as Map<String, dynamic>))
            .toList();

        state = AsyncValue.data(ads);
      } else if (response != null && response.statusCode == 401) {
        state = AsyncValue.error(
          'auth_required_recent_ads'.tr,
          StackTrace.current,
        );
      } else {
        state = AsyncValue.error(
          'failed_load_landing_ads'.tr,
          StackTrace.current,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async => fetchAds();
}

