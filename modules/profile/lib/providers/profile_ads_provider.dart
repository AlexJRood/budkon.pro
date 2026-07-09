import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

class ProfileAdsNotifier extends StateNotifier<AsyncValue<List<AdsListViewModel>>> {
  ProfileAdsNotifier(dynamic ref) : super(const AsyncValue.loading());

  Future<List<AdsListViewModel>> fetchUserAdvertisements(
    int pageKey, 
    int pageSize, 
    int userId,
    dynamic ref
  ) async {
    try {
      final response = await ApiServices.get(
        ref: ref,
        URLs.apiAdvertisements,
        hasToken: true,
        queryParameters: {
          'user_id': userId,
          'page': pageKey,
          'pageSize': pageSize,
        },
      );

      if (response != null && response.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final listingsJson = json.decode(decodedBody) as Map<dynamic, dynamic>;
        final newList = listingsJson['results'] as List<dynamic>;

        log('Profile Ads - New List: ${newList.length}');
        log('Profile Ads - pagekey: $pageKey');
        log('Profile Ads - pageSize: $pageSize');
        log('Profile Ads - userId: $userId');

        return newList.map((item) {
          return AdsListViewModel.fromJson(item as Map<String, dynamic>);
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user advertisements: $e');
      }
      throw Exception('Failed to fetch user advertisements');
    }
    return [];
  }

  Future<void> loadUserAds(int userId, dynamic ref) async {
    state = const AsyncValue.loading();

    try {
      final ads = await fetchUserAdvertisements(1, 20, userId, ref);
      state = AsyncValue.data(ads);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final profileAdsProvider = StateNotifierProvider<ProfileAdsNotifier, AsyncValue<List<AdsListViewModel>>>((ref) {
  return ProfileAdsNotifier(ref);
});
