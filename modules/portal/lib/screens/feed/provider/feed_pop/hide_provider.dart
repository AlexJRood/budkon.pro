import 'package:get/get_utils/get_utils.dart';
import 'package:portal/portal_urls.dart';
import 'package:flutter/foundation.dart';

// ignore_for_file: empty_catches

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/common/models/ad/hide_ads_view_model.dart';
import 'package:network_monitoring/providers/saved_search/add_client.dart';
import 'package:core/platform/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HideFiltersLogicNotifier
    extends StateNotifier<AsyncValue<List<HideAdsViewModel>>> {
  HideFiltersLogicNotifier(dynamic ref) : super(const AsyncValue.loading()) {
    _loadFiltersAndApply(ref);
  }

  Map<String, dynamic> filters = {};
  String searchQuery = '';
  String excludeQuery = '';
  String sortOrder = '';

  Future<void> _loadFiltersAndApply(dynamic ref) async {
    final prefs = await SharedPreferences.getInstance();
    searchQuery = prefs.getString('searchQuery') ?? '';
    excludeQuery = prefs.getString('excludeQuery') ?? '';
    // Załaduj inne filtry, jeśli są potrzebne

    // Po załadowaniu filtrów zastosuj je
    applyFilters(ref);
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('searchQuery', searchQuery);
    await prefs.setString('excludeQuery', excludeQuery);
    // Zapisz inne filtry, jeśli są potrzebne
  }

  void setSortOrder(String order, dynamic ref) {
    sortOrder = order;
    _saveFilters();
    applyFilters(ref);
  }

  void setSearchQuery(String query, dynamic ref) {
    searchQuery = query;
    _saveFilters();
    applyFilters(ref);
  }

  void setExcludeQuery(String query, dynamic ref) {
    excludeQuery = query;
    _saveFilters();
    applyFilters(ref);
  }

  void addFilter(String key, dynamic value, dynamic ref) {
    if (value != null && value.toString().isNotEmpty) {
      filters[key] = value;
    } else {
      filters.remove(key);
    }
    _saveFilters();
    applyFilters(ref);
  }

  void removeFilter(String key, dynamic ref) {
    filters.remove(key);
    _saveFilters();
    applyFilters(ref);
  }

  void clearFilters(dynamic ref) {
    filters.clear();
    searchQuery = '';
    excludeQuery = '';
    _saveFilters();
    applyFilters(ref);
  }

  Future<bool> isHide(int adId) async {
    final hiddenAds = state.valueOrNull?.map((ad) => ad.id).toSet() ?? {};
    return hiddenAds.contains(adId);
  }

  Future<void> toggleHide(int adId,BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hideList = prefs.getStringList('hide') ?? [];
    bool isHidden = hideList.contains(adId.toString());

    if (isHidden) {
      hideList.remove(adId.toString());
      await removeFromHide(adId);       
    if (!context.mounted) return;
      context.showSnackBarLikeSection('remove_hide:'.tr);
    } else {
      hideList.add(adId.toString());
      await addToHide(adId);       
    if (!context.mounted) return;
      context.showSnackBarLikeSection('add_hide'.tr);
    }

    await prefs.setStringList('hide', hideList);
    state = AsyncData(
      hideList
          .map((id) => const HideAdsViewModel().copyWith(
                id: int.parse(id),
              ))
          .toList(),
    );
  }

  Future<void> addToHide(int adId) async {
    try {
      final response = await ApiServices.post(
        PortalUrls.apiHideAdd('$adId'),
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        if (kDebugMode) print('added to hide');
        final prefs = await SharedPreferences.getInstance();
        final hideList = prefs.getStringList('hide') ?? [];
        hideList.add(adId.toString());
        await prefs.setStringList('hide', hideList);
      } else {}
    } catch (e) {}
  }

  Future<void> removeFromHide(int adId) async {
    try {
      final response = await ApiServices.post(
        PortalUrls.apiHideRemove('$adId'),
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        if (kDebugMode) print('removed from hide');
        final prefs = await SharedPreferences.getInstance();
        final hideList = prefs.getStringList('hide') ?? [];
        hideList.remove(adId.toString());
        await prefs.setStringList('hide', hideList);
      } else {}
    } catch (e) {}
  }

  Future<void> applyFilters(dynamic ref) async {
    state = const AsyncValue.loading();

    if (ApiServices.token == null) {
      state = AsyncValue.error('Token not found'.tr, StackTrace.current);
      return;
    }

    try {
      final response = await ApiServices.get(
        ref: ref,
        PortalUrls.apiHide,
        hasToken: true,
        queryParameters: {
          ...filters,
          if (searchQuery.isNotEmpty) 'search': searchQuery,
          if (excludeQuery.isNotEmpty) 'exclude': excludeQuery,
          if (sortOrder.isNotEmpty) 'sort': sortOrder,
        },
      );

      if (response != null && response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final ads = data
            .map((item) =>
                HideAdsViewModel.fromJson(item as Map<String, dynamic>))
            .toList();
        state = AsyncValue.data(ads);
      } else {
        state = AsyncValue.error('Failed to load hide ads'.tr, StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final hideAdsProvider = StateNotifierProvider<HideFiltersLogicNotifier,
    AsyncValue<List<HideAdsViewModel>>>((ref) {
  return HideFiltersLogicNotifier(ref);
});
