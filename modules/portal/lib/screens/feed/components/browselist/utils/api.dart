// ignore_for_file: empty_catches

import 'dart:convert';
import 'package:portal/portal_urls.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:core/platform/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BrowseListLogicNotifier
    extends StateNotifier<AsyncValue<List<AdsListViewModel>>> {
  BrowseListLogicNotifier(dynamic ref) : super(const AsyncValue.loading()) {
    _loadFiltersAndApply(ref);
  }

  Map<String, dynamic> filters = {};
  String searchQuery = '';
  String excludeQuery = '';
  String sortOrder = 'date_desc';

  Future<void> _loadFiltersAndApply(dynamic ref) async {
    final prefs = await SharedPreferences.getInstance();
    searchQuery = prefs.getString('searchQuery') ?? '';
    excludeQuery = prefs.getString('excludeQuery') ?? '';
    // Załaduj inne filtry, jeśli są potrzebne

    // Po załadowaniu filtrów zastosuj je
    await applyFilters(ref);
  }

  Future<void> loadOfflineBrowseList() async {
    final prefs = await SharedPreferences.getInstance();
    final offlineRaw = prefs.getStringList('offline_browse_list') ?? [];

    if (offlineRaw.isEmpty) {
      debugPrint('📭 No offline ads found.');
      return;
    }

    final List<AdsListViewModel> loadedAds = [];
    for (final item in offlineRaw) {
      try {
        final decoded = json.decode(item);
        final ad = AdsListViewModel.fromJson(decoded as Map<String, dynamic>);
        loadedAds.add(ad);
      } catch (e) {
        debugPrint('⚠️ Failed to parse ad from shared preferences: $e');
      }
    }

    debugPrint('📦 Loaded ${loadedAds.length} offline ads');
    final currentAds = state.maybeWhen(
      data: (ads) => ads,
      orElse: () => <AdsListViewModel>[],
    );
    final allAds = [...loadedAds, ...currentAds];
    state = AsyncValue.data(allAds);
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

  bool isBrowseListSync(int adId) {
    final browseListsList = state.maybeWhen(
      data: (ads) => ads.map((ad) => ad.id).toList(),
      orElse: () => [],
    );
    return browseListsList.contains(adId);
  }

  Future<bool> isBrowseList(int adId) async {
    final prefs = await SharedPreferences.getInstance();
    final browseListsList = prefs.getStringList('BrowseLists') ?? [];
    return browseListsList.contains(adId.toString());
  }

  // Zmieniamy sygnaturę removeFromBrowseLists, aby przyjmowała int adId:
  Future<void> removeFromBrowseLists(int adId) async {
    try {
      final response = await ApiServices.delete(
        PortalUrls.portalBrowseListRemove('$adId'),
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        if (kDebugMode) debugPrint('removed');
        final prefs = await SharedPreferences.getInstance();
        final browseListsList = prefs.getStringList('BrowseLists') ?? [];
        browseListsList.remove(adId.toString());
        await prefs.setStringList('BrowseLists', browseListsList);
      }
    } catch (e) {
      // Obsługa błędu
    }
  }

  // Funkcja addToBrowseLists pozostaje bez zmian, bo przyjmuje int adId
  Future<void> addToBrowseLists(int adId) async {
    try {
      debugPrint('Younis ${PortalUrls.portalBrowseListAdd('$adId')}');
      final response = await ApiServices.post(
        PortalUrls.portalBrowseListAdd('$adId'),
        hasToken: true,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        if (kDebugMode) debugPrint('added');
        final prefs = await SharedPreferences.getInstance();
        final browseListsList = prefs.getStringList('BrowseLists') ?? [];
        // Zapobiegamy duplikatom – dodajemy tylko, jeśli nie ma
        if (!browseListsList.contains(adId.toString())) {
          browseListsList.add(adId.toString());
          await prefs.setStringList('BrowseLists', browseListsList);
        }
      } else {
        if (kDebugMode) debugPrint(response?.statusCode.toString());
      }
    } catch (e) {
      // Obsługa błędu
    }
  }

  Future<void> toggleBrowseList(
    AdsListViewModel ad,
    BuildContext context,
  ) async {
    // Sprawdź, czy ogłoszenie znajduje się już w liście pobranej z API (stan providera)
    final isInBrowseList = state.maybeWhen(
      data: (ads) => ads.any((item) => item.id == ad.id),
      orElse: () => false,
    );

    // Pobieramy listę z SharedPreferences – będziemy ją aktualizować
    final prefs = await SharedPreferences.getInstance();
    final prefsList = prefs.getStringList('BrowseLists') ?? [];

    if (isInBrowseList) {
      // Jeśli ogłoszenie jest już w liście, usuwamy je:
      await removeFromBrowseLists(ad.id);
      if (!context.mounted) return;
      context.showSnackBarSafe('removed_from_browse_list'.tr);

      // Aktualizujemy stan providera: usuwamy model o danym id
      final currentAds = state.maybeWhen(
        data: (ads) => ads,
        orElse: () => <AdsListViewModel>[],
      );
      final updatedAds = currentAds.where((item) => item.id != ad.id).toList();
      state = AsyncData(updatedAds);

      // Usuwamy też z SharedPreferences
      prefsList.remove(ad.id.toString());
    } else {
      // Jeśli ogłoszenia nie ma – dodajemy je:
      await addToBrowseLists(ad.id);
      if (!context.mounted) return;
      context.showSnackBarSafe('added_to_browse_list'.tr);

      // Aktualizujemy stan: dodajemy cały model ogłoszenia
      final currentAds = state.maybeWhen(
        data: (ads) => ads,
        orElse: () => <AdsListViewModel>[],
      );
      final updatedAds = [ad, ...currentAds];
      state = AsyncData(updatedAds);

      // Dodajemy id do SharedPreferences (upewnijmy się, że nie powtarzamy)
      if (!prefsList.contains(ad.id.toString())) {
        prefsList.add(ad.id.toString());
      }
    }

    await prefs.setStringList('BrowseLists', prefsList);
  }

  Future<void> clearBrowseLists() async {
    try {
      final response = await ApiServices.delete(
        PortalUrls.portalBrowseListClear,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        if (kDebugMode) debugPrint('removed');

        final prefs = await SharedPreferences.getInstance();
        // Przypisanie pustej listy:
        await prefs.setStringList('BrowseLists', []);
      } else {
        // Obsługa błędu
      }
    } catch (e) {
      // Obsługa wyjątku
      if (kDebugMode) debugPrint(e.toString());
    }
  }

  Future<void> applyFilters(dynamic ref) async {
    if (!mounted) return;
    state = const AsyncValue.loading();

    if (ApiServices.token == null) {
      state = AsyncValue.error('Token not found'.tr, StackTrace.current);
      return;
    }

    try {
      final response = await ApiServices.get(
        ref: ref,
        PortalUrls.portalBrowseList,
        hasToken: true,
        queryParameters: {
          ...filters,
          if (searchQuery.isNotEmpty) 'search': searchQuery,
          if (excludeQuery.isNotEmpty) 'exclude': excludeQuery,
          if (sortOrder.isNotEmpty) 'sort': sortOrder,
        },
      );

      if (!mounted) return;
      if (response != null && response.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final listingsJson = json.decode(decodedBody) as List<dynamic>;
        final ads =
            listingsJson
                .map(
                  (item) =>
                      AdsListViewModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
        state = AsyncValue.data(ads);
      } else {
        state = AsyncValue.error(
          'Failed to load BrowseList ads'.tr,
          StackTrace.current,
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> syncOfflineAdsWithApi(List<int> apiAdIds, dynamic ref) async {
    final prefs = await SharedPreferences.getInstance();
    final offlineRaw = prefs.getStringList('offline_browse_list') ?? [];
    clearState();
    if (offlineRaw.isEmpty) {
      debugPrint('✅ No offline ads to sync.');
      await applyFilters(ref);
      return;
    }

    final List<int> addedIds = [];

    for (final raw in offlineRaw) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          final adId = decoded['id'] as int?;
          if (adId != null && !apiAdIds.contains(adId)) {
            await addToBrowseLists(adId); // Add to API
            addedIds.add(adId);
          }
        }
      } catch (e) {
        debugPrint('❌ Error syncing ad from SharedPreferences: $e');
      }
    }

    if (offlineRaw.isNotEmpty) {
      await prefs.remove('offline_browse_list');
      debugPrint(
        '🧹 Cleared SharedPreferences after syncing ${addedIds.length} ads',
      );
    }
    await applyFilters(ref);
    syncAfterLogin(ref);
  }

  void clearState() {
    state = const AsyncValue.data([]);
  }

  Future<void> syncAfterLogin(WidgetRef ref) async {
    final apiResult = ref.read(browseListProvider);
    final List<int> apiIds = apiResult.maybeWhen(
      data: (ads) => ads.map((a) => a.id).whereType<int>().toList(),
      orElse: () => <int>[],
    );

    await syncOfflineAdsWithApi(apiIds, ref);
  }
}

final browseListProvider = StateNotifierProvider<
  BrowseListLogicNotifier,
  AsyncValue<List<AdsListViewModel>>
>((ref) {
  return BrowseListLogicNotifier(ref);
});
