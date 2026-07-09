import 'package:get/get_utils/get_utils.dart';
import 'package:portal/portal_urls.dart';
import 'package:flutter/foundation.dart';



// ignore_for_file: empty_catches

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/providers/saved_search/add_client.dart';
import 'package:core/platform/url.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavFiltersLogicNotifier
    extends StateNotifier<AsyncValue<List<AdsListViewModel>>> {
  FavFiltersLogicNotifier(dynamic ref) : super(const AsyncValue.loading()) {
    _loadFiltersAndApply(ref);
  }

  Map<String, dynamic> filters = {};
  String searchQuery = '';
  String excludeQuery = '';
  String sortOrder = '';

  Future<void> _loadFiltersAndApply(dynamic ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      searchQuery = prefs.getString('searchQuery') ?? '';
      excludeQuery = prefs.getString('excludeQuery') ?? '';
      // Załaduj inne filtry, jeśli są potrzebne

      // Po załadowaniu filtrów zastosuj je
      applyFilters(ref);
    } catch (e) {}
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

  bool isFavoriteSync(int adId) {
    final favoritesList = state.maybeWhen(
      data: (ads) => ads.map((ad) => ad.id).toList(),
      orElse: () => [],
    );
    return favoritesList.contains(adId);
  }

  Future<bool> isFavorite(int adId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesList = prefs.getStringList('favorites') ?? [];
    return favoritesList.contains(adId.toString());
  }

  Future<void> toggleFavorite(int adId, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favList = prefs.getStringList('favorites') ?? [];

    final currentList = state.valueOrNull ?? [];

    // ✅ Use state to determine if ad is already in favorites
    final isFav = currentList.any((ad) => ad.id == adId);
    final adIdStr = adId.toString();

    if (isFav) {
      // 🔥 Remove from SharedPreferences and backend
      favList.remove(adIdStr);
      await removeFromFavorites(adId);       
    if (!context.mounted) return;
      context.showSnackBarLikeSection('fav_removed'.tr);

      // ✅ Remove item from state *without resetting entire list*
      state = AsyncData([...currentList]..removeWhere((ad) => ad.id == adId));
    } else {
      favList.add(adIdStr);
      await addToFavorites(adId);       
    if (!context.mounted) return;
      context.showSnackBarLikeSection('fav_added'.tr);

      // 🧠 Use a dummy or full object depending on your logic
      final newAd = const AdsListViewModel().copyWith(id: adId);
      state = AsyncData([...currentList, newAd]);
    }

    await prefs.setStringList('favorites', favList);
  }

  Future<void> addToFavorites(int adId) async {
    try {
      final response = await ApiServices.post(
        URLs.apiFavoriteAdd('$adId'),
        hasToken: true,
      );

      if (response != null && response.statusCode == 200 ||
          response?.statusCode == 201) {
        if (kDebugMode) print('added');
        final prefs = await SharedPreferences.getInstance();
        final favoritesList = prefs.getStringList('favorites') ?? [];
        favoritesList.add(adId.toString());
        await prefs.setStringList('favorites', favoritesList);
      } else {
        if (kDebugMode) print(response?.statusCode);
      }
    } catch (e) {}
  }

  Future<void> removeFromFavorites(int adId) async {
    try {
      final response = await ApiServices.delete(
        PortalUrls.apiFavoriteRemove('$adId'),
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        if (kDebugMode) print('removed');
        final prefs = await SharedPreferences.getInstance();
        final favoritesList = prefs.getStringList('favorites') ?? [];
        favoritesList.remove(adId.toString());
        await prefs.setStringList('favorites', favoritesList);
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
        URLs.apiFavorite,
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
        final Map<String, dynamic> bodyMap = json.decode(decodedBody);

        final listingsJson =
            bodyMap['results'] as List<dynamic>; // 👈 adjust key if needed

        final ads =
            listingsJson
                .map(
                  (item) =>
                      AdsListViewModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
        state = AsyncValue.data(ads);
      } else {
        state = AsyncValue.error('Failed to load favorite ads'.tr, StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final favAdsProvider = StateNotifierProvider<
  FavFiltersLogicNotifier,
  AsyncValue<List<AdsListViewModel>>
>((ref) {
  return FavFiltersLogicNotifier(ref);
});
