import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

class CompanyAdsNotifier extends StateNotifier<AsyncValue<List<AdsListViewModel>>> {
  CompanyAdsNotifier(dynamic ref) : super(const AsyncValue.loading());

  Future<List<AdsListViewModel>> fetchCompanyAdvertisements(
    int pageKey, 
    int pageSize, 
    int companyId,
    dynamic ref
  ) async {
    try {
      final response = await ApiServices.get(
        ref: ref,
        URLs.apiAdvertisements,
        hasToken: true,
        queryParameters: {
          'company_id': companyId,
          'page': pageKey,
          'pageSize': pageSize,
        },
      );

      if (response != null && response.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final listingsJson = json.decode(decodedBody) as Map<dynamic, dynamic>;
        final newList = listingsJson['results'] as List<dynamic>;

        log('Company Ads - New List: ${newList.length}');
        log('Company Ads - pagekey: $pageKey');
        log('Company Ads - pageSize: $pageSize');
        log('Company Ads - companyId: $companyId');

        return newList.map((item) {
          return AdsListViewModel.fromJson(item as Map<String, dynamic>);
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching company advertisements: $e');
      }
      throw Exception('Failed to fetch company advertisements');
    }
    return [];
  }

  Future<void> loadCompanyAds(int companyId, dynamic ref) async {
    state = const AsyncValue.loading();

    try {
      final ads = await fetchCompanyAdvertisements(1, 20, companyId, ref);
      state = AsyncValue.data(ads);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final companyAdsProvider = StateNotifierProvider<CompanyAdsNotifier, AsyncValue<List<AdsListViewModel>>>((ref) {
  return CompanyAdsNotifier(ref);
});
