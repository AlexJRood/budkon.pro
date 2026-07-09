import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/network_monitoring_urls.dart';

// ignore_for_file: empty_catches

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/screens/feed_pop/widgets/nm_like_section_mid.dart';
import 'package:core/platform/url.dart';
import 'package:core/platform/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';




class NMFavFiltersLogicNotifier extends StateNotifier<AsyncValue<List<MonitoringAdsModel>>> {
  NMFavFiltersLogicNotifier(dynamic ref) : super(const AsyncValue.loading()) {
    _loadFiltersAndApplyNM(ref);
  }

  Map<String, dynamic> filters = {};
  String searchQuery = '';
  String excludeQuery = '';
  String sortOrder = '';

  Future<void> _loadFiltersAndApplyNM(dynamic ref) async {
    final prefs = await SharedPreferences.getInstance();
    searchQuery = prefs.getString('searchQuery') ?? '';
    excludeQuery = prefs.getString('excludeQuery') ?? '';
    // Załaduj inne filtry, jeśli są potrzebne

    // Po załadowaniu filtrów zastosuj je
    NMapplyFilters(ref);
  }

  Future<void> _saveFiltersNM() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('searchQuery', searchQuery);
    await prefs.setString('excludeQuery', excludeQuery);
    // Zapisz inne filtry, jeśli są potrzebne
  }

  void setSortOrder(String order,dynamic ref) {
    sortOrder = order;
    _saveFiltersNM();
    NMapplyFilters(ref);
  }

  void setSearchQuery(String query,dynamic ref) {
    searchQuery = query;
    _saveFiltersNM();
    NMapplyFilters(ref);
  }

  void setExcludeQuery(String query,dynamic ref) {
    excludeQuery = query;
    _saveFiltersNM();
    NMapplyFilters(ref);
  }

  void addFilter(String key, dynamic value,dynamic ref) {
    if (value != null && value.toString().isNotEmpty) {
      filters[key] = value;
    } else {
      filters.remove(key);
    }
    _saveFiltersNM();
    NMapplyFilters(ref);
  }

  void removeFilter(String key,dynamic ref) {
    filters.remove(key);
    _saveFiltersNM();
    NMapplyFilters(ref);
  }

  void clearFilters(dynamic ref) {
    filters.clear();
    searchQuery = '';
    excludeQuery = '';
    _saveFiltersNM();
    NMapplyFilters(ref);
  }

  // ignore: non_constant_identifier_names
  bool NMisFavoriteSync(int adId) {
    final favoritesList = state.maybeWhen(
      data: (ads) => ads.map((ad) => ad.id).toList(),
      orElse: () => [],
    );
    return favoritesList.contains(adId);
  }

  Future<bool> isFavoriteNM(int adId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesList = prefs.getStringList('favorites') ?? [];
    return favoritesList.contains(adId.toString());
  }


  Future<void> toggleFavorite(
      MonitoringAdsModel ad,
      int? transactionId,
      int? clientId,
      BuildContext context
    ) async {
    final prefs = await SharedPreferences.getInstance();
    final browseListIds = prefs.getStringList('BrowseLists') ?? [];
    bool isInBrowseList = browseListIds.contains(ad.id.toString());
    
    // Pobieramy bieżącą listę modeli ze stanu
    final currentAds = state.maybeWhen(data: (ads) => ads, orElse: () => <MonitoringAdsModel>[]);

    if (isInBrowseList) {
      // Usuń z listy (w SharedPreferences i lokalnie)
      browseListIds.remove(ad.id.toString());
      await removeFromFavoritesNM(ad.id, transactionId, clientId);       
    if (!context.mounted) return;
      context.showSnackBarLikeSection('removed_from_viewing_list'.tr);
      
      final updatedAds = currentAds.where((item) => item.id != ad.id).toList();
      state = AsyncData(updatedAds);
    } else {
      // Dodaj do listy (w SharedPreferences i lokalnie)
      browseListIds.add(ad.id.toString());
      await addToFavoritesNM(ad.id, transactionId, clientId );       
    if (!context.mounted) return;
      context.showSnackBarLikeSection('Added to viewing list'.tr);
      
      final updatedAds = [...currentAds, ad];
      state = AsyncData(updatedAds);
    }
    await prefs.setStringList('BrowseLists', browseListIds);
  }





Future<void> addToFavoritesNM(
  int adId,
  int? transactionId,
  int? clientId,
  ) async {
  try {
    // POST request with optional fields only when not null
    final response = await ApiServices.post(
      NetworkMonitoringUrls.addFavoriteNetwork('$adId'),
      data: <String, dynamic>{
        if (transactionId != null) 'transaction': transactionId,
        if (clientId != null) 'client': clientId,
      },
      hasToken: true,
    );

    // Accept any 2xx as success
    final ok = response != null &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;

    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList('favorites') ?? <String>[];

      // Avoid duplicates
      final idStr = adId.toString();
      if (!favoritesList.contains(idStr)) {
        favoritesList.add(idStr);
        await prefs.setStringList('favorites', favoritesList);
      }
    } else {
      // Optional: log unexpected status
      debugPrint('addToFavoritesNM: unexpected status ${response?.statusCode}');
    }
  } catch (e, st) {
    // Don't swallow errors silently; at least log them
    debugPrint('addToFavoritesNM error: $e\n$st');
  }
}


  Future<void> removeFromFavoritesNM(
  int adId,
  int? transactionId,
  int? clientId,
  ) async {
    try {
      final response = await ApiServices.post(
        NetworkMonitoringUrls.removeFavoriteNetwork('$adId'),
      data: <String, dynamic>{
        if (transactionId != null) 'transaction': transactionId,
        if (clientId != null) 'client': clientId,
      },
        hasToken: true,
      );

      // Sprawdzenie statusu odpowiedzi
      if (response != null && response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final favoritesList = prefs.getStringList('favorites') ?? [];
        favoritesList.remove(adId.toString());
        await prefs.setStringList('favorites', favoritesList);
      } else {}
    } catch (e) {}
  }

  // ignore: non_constant_identifier_names
  Future<void> NMapplyFilters(dynamic ref) async {
    state = const AsyncValue.loading();

    if (ApiServices.token == null) {
      state = AsyncValue.error('Token not found'.tr, StackTrace.current);
      return;
    }

    try {
      final response = await ApiServices.get(
        ref: ref,
        URLs.favoriteNetwork,
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
          final listingsJson = json.decode(decodedBody) as Map<dynamic, dynamic>;
          final adsResults = listingsJson['results'] as List<dynamic>;

        
          final adsData = adsResults.map((item) => MonitoringAdsModel.fromJson(item as Map<String, dynamic>)).toList();

        state = AsyncValue.data(adsData);

      } else {
        state =
            AsyncValue.error('Failed to load favorite ads'.tr, StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final nMFavAdsProvider = StateNotifierProvider<NMFavFiltersLogicNotifier,
    AsyncValue<List<MonitoringAdsModel>>>((ref) {
  return NMFavFiltersLogicNotifier(ref);
});
