import 'package:get/get_utils/get_utils.dart';
import 'package:portal/portal_urls.dart';

// ignore_for_file: empty_catches

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisplayedFiltersLogicNotifier
    extends StateNotifier<AsyncValue<List<AdsListViewModel>>> {
  DisplayedFiltersLogicNotifier(dynamic ref) : super(const AsyncValue.loading()) {
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

  void setSortOrder(String order,dynamic ref) {
    sortOrder = order;
    _saveFilters();
    applyFilters(ref);
  }

  void setSearchQuery(String query,dynamic ref) {
    searchQuery = query;
    _saveFilters();
    applyFilters(ref);
  }

  void setExcludeQuery(String query,dynamic ref) {
    excludeQuery = query;
    _saveFilters();
    applyFilters(ref);
  }

  void addFilter(String key, dynamic value,dynamic ref) {
    if (value != null && value.toString().isNotEmpty) {
      filters[key] = value;
    } else {
      filters.remove(key);
    }
    _saveFilters();
    applyFilters(ref);
  }

  void removeFilter(String key,dynamic ref) {
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

  Future<bool> isDisplayed(int adId) async {
    final prefs = await SharedPreferences.getInstance();
    final displayedList = prefs.getStringList('displayed') ?? [];
    return displayedList.contains(adId.toString());
  }

  // Upewnij się, że ścieżka do pliku jest poprawna

  Future<void> addToDisplayed(int adId) async {
    try {
      // Wykonanie żądania POST z użyciem Dio
      final response =
          await ApiServices.post(PortalUrls.addDisplayed('$adId'), hasToken: true);

      // Sprawdzenie statusu odpowiedzi
      if (response != null && response.statusCode == 200) {}
    } catch (e) {}
  }

  Future<void> removeFromDisplayed(int adId) async {
    try {
      // Wykonanie żądania POST z użyciem Dio
      final response = await ApiServices.post(
        PortalUrls.removeDisplayed('$adId'),
        hasToken: true,
      );

      // Sprawdzenie statusu odpowiedzi
      if (response != null && response.statusCode == 200) {
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
        ref:ref,
        PortalUrls.apiDisplayed,
        hasToken: true,
        queryParameters: {
          ...filters,
          if (searchQuery.isNotEmpty) 'search': searchQuery,
          if (excludeQuery.isNotEmpty) 'exclude': excludeQuery,
          if (sortOrder.isNotEmpty) 'sort': sortOrder,
        },
      );

      if (response != null && response.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final listingsJson = json.decode(decodedBody) as List<dynamic>;
        final ads = listingsJson
            .map((item) =>
                AdsListViewModel.fromJson(item as Map<String, dynamic>))
            .toList();
        state = AsyncValue.data(ads);
      } else {
        state = AsyncValue.error(
            'Failed to load displayed ads'.tr, StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final displayedAdsProvider = StateNotifierProvider<
    DisplayedFiltersLogicNotifier, AsyncValue<List<AdsListViewModel>>>((ref) {
  return DisplayedFiltersLogicNotifier(ref);
});
