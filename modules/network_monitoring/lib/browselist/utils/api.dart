import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/network_monitoring_urls.dart';

// ignore_for_file: empty_catches

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import '../../providers/saved_search/add_client.dart';
import 'package:core/platform/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';


@immutable
class BrowseScope {
  final int? transactionId;
  final int? clientId;
  const BrowseScope({this.transactionId, this.clientId});

  Map<String, dynamic> toQuery() => {
    if (transactionId != null) 'transaction_id': transactionId,
    if (clientId != null) 'client_id': clientId,
  };

  String prefsKey() {
    final t = transactionId != null ? '_tx_$transactionId' : '';
    final c = clientId != null ? '_client_$clientId' : '';
    return 'BrowseListsNM_networkMonitoring$t$c';
  }

  @override
  bool operator ==(Object o) =>
      o is BrowseScope &&
      o.transactionId == transactionId &&
      o.clientId == clientId;

  @override
  int get hashCode => Object.hash(transactionId, clientId);
}

class BrowseListLogicNotifier
    extends StateNotifier<AsyncValue<List<MonitoringAdsModel>>> {
  BrowseListLogicNotifier(this._ref, this.scope)
      : super(const AsyncValue.loading()) {
    _loadFiltersAndApply(_ref);
  }

  final Ref _ref;
  final BrowseScope scope;

  Map<String, dynamic> filters = {};
  String searchQuery = '';
  String excludeQuery = '';
  String sortOrder = 'date_desc';

  Future<void> _loadFiltersAndApply(dynamic ref) async {
    final prefs = await SharedPreferences.getInstance();
    // Filtry trzymamy wspólne; jak chcesz, znamespacuj je per scope tak jak browse list key.
    searchQuery = prefs.getString('searchQuery') ?? '';
    excludeQuery = prefs.getString('excludeQuery') ?? '';
    applyFilters(ref);
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('searchQuery', searchQuery);
    await prefs.setString('excludeQuery', excludeQuery);
  }

  void setSortOrder(String order, dynamic ref) { sortOrder = order; _saveFilters(); applyFilters(ref); }
  void setSearchQuery(String q, dynamic ref) { searchQuery = q; _saveFilters(); applyFilters(ref); }
  void setExcludeQuery(String q, dynamic ref) { excludeQuery = q; _saveFilters(); applyFilters(ref); }

  void addFilter(String key, dynamic value, dynamic ref) {
    if (value != null && value.toString().isNotEmpty) {
      filters[key] = value;
    } else {
      filters.remove(key);
    }
    _saveFilters();
    applyFilters(ref);
  }

  void removeFilter(String key, dynamic ref) { filters.remove(key); _saveFilters(); applyFilters(ref); }
  void clearFilters(dynamic ref) { filters.clear(); searchQuery = ''; excludeQuery = ''; _saveFilters(); applyFilters(ref); }

  // Szybkie sprawdzenie po stanie (per-scope)
  bool isInBrowseListSync(int adId) {
    final ids = state.maybeWhen(data: (ads) => ads.map((e) => e.id), orElse: () => <int>[]);
    return ids.contains(adId);
  }

  // SP trzymamy tylko jako cache „pamiętaj co kliknięto” – per-scope
  Future<bool> isInBrowseListPrefs(int adId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(scope.prefsKey()) ?? const <String>[];
    return list.contains(adId.toString());
  }

  Future<void> removeFromBrowseListsNM(int adId) async {
    try {
      // użyj POST, żeby przekazać scope w body (DELETE zwykle nie ma body)
      final response = await ApiServices.post(
        NetworkMonitoringUrls.networkMonitoringBrowseListRemove('$adId'),
        hasToken: true,
        data: <String, dynamic>{
          if (scope.transactionId != null) 'transaction': scope.transactionId,
          if (scope.clientId != null) 'client': scope.clientId,
        },
      );

      if (response != null && response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final key = scope.prefsKey();
        final list = prefs.getStringList(key) ?? <String>[];
        list.remove(adId.toString());
        await prefs.setStringList(key, list);
      }
    } catch (_) {}
  }

  Future<void> addToBrowseListsNMNM(int adId, int? transactionId, int? clientId) async {
    try {
      final response = await ApiServices.post(
        NetworkMonitoringUrls.networkMonitoringBrowseListAdd('$adId'),
        data: <String, dynamic>{
          if (transactionId != null) 'transaction': transactionId,
          if (clientId != null) 'client': clientId,
        },
        hasToken: true,
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        final prefs = await SharedPreferences.getInstance();
        final key = scope.prefsKey();
        final list = prefs.getStringList(key) ?? <String>[];
        if (!list.contains(adId.toString())) {
          list.add(adId.toString());
          await prefs.setStringList(key, list);
        }
      }
    } catch (_) {}
  }

  Future<String?> toggleBrowseListNM(
    MonitoringAdsModel ad,
    int? transactionId,
    int? clientId,
  ) async {
    final isInList = state.maybeWhen(
      data: (ads) => ads.any((e) => e.id == ad.id),
      orElse: () => false,
    );

    final prefs = await SharedPreferences.getInstance();
    final key = scope.prefsKey();
    final prefsList = prefs.getStringList(key) ?? <String>[];

    String? message;
    if (isInList) {
      await removeFromBrowseListsNM(ad.id);
      message = 'removed_from_browse_list'.tr;

      final current = state.maybeWhen(data: (ads) => ads, orElse: () => <MonitoringAdsModel>[]);
      state = AsyncData(current.where((e) => e.id != ad.id).toList());

      prefsList.remove(ad.id.toString());
    } else {
      await addToBrowseListsNMNM(ad.id, transactionId, clientId);
      message = 'Added to viewing list'.tr;

      final current = state.maybeWhen(data: (ads) => ads, orElse: () => <MonitoringAdsModel>[]);
      state = AsyncData([ad, ...current]);
      if (!prefsList.contains(ad.id.toString())) prefsList.add(ad.id.toString());
    }

    await prefs.setStringList(key, prefsList);
    return message;
  }


Future<void> clearBrowseListsNM(int? transactionId, int? clientId) async {
  try {
    // 1) Wybór endpointu wg scope (priorytet: transaction > client > global)
    final resp = (transactionId != null)
        ? await ApiServices.delete(
            NetworkMonitoringUrls.networkMonitoringBrowseListClearTransaction('$transactionId'),
            hasToken: true,
          )
        : (clientId != null)
            ? await ApiServices.delete(
                NetworkMonitoringUrls.networkMonitoringBrowseListClearClient('$clientId'),
                hasToken: true,
              )
            : await ApiServices.delete(
                NetworkMonitoringUrls.networkMonitoringBrowseListClear,
                hasToken: true,
              );

    final ok = resp != null &&
        resp.statusCode != null &&
        resp.statusCode! >= 200 &&
        resp.statusCode! < 300;

    if (!ok) return;

    // 2) Ustal localScope na podstawie argumentów (albo bieżącego scope, jeśli brak)
    final localScope = BrowseScope(
      transactionId: transactionId ?? scope.transactionId,
      clientId: clientId ?? scope.clientId,
    );

    // 3) Wyczyść właściwy klucz w SP dla TEGO scope'u
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(localScope.prefsKey(), const <String>[]);

    // 4) Odśwież UI:
    final isCurrentScope = localScope.transactionId == scope.transactionId &&
        localScope.clientId == scope.clientId;

    if (isCurrentScope) {
      // czyścisz aktualnie oglądany scope → wyzeruj stan
      state = const AsyncValue.data(<MonitoringAdsModel>[]);
    } else {
      // czyścisz inny scope → tylko zainwaliduj tamten provider
      _ref.invalidate(networkMonitoringBrowseListProvider(localScope));
    }
  } catch (e, st) {
    debugPrint('clearBrowseListsNM error: $e\n$st');
  }
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
        NetworkMonitoringUrls.networkMonitoringBrowseList,
        hasToken: true,
        queryParameters: {
          // scope najważniejszy:
          ...scope.toQuery(),
          // a tu normalne filtry widoku:
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
            .map((item) => MonitoringAdsModel.fromJson(item as Map<String, dynamic>))
            .toList();
        state = AsyncValue.data(ads);
      } else {
        state = AsyncValue.error('Failed to load BrowseList ads'.tr, StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}


final networkMonitoringBrowseListProvider =
    StateNotifierProvider.family<BrowseListLogicNotifier,
        AsyncValue<List<MonitoringAdsModel>>, BrowseScope>((ref, scope) {
  return BrowseListLogicNotifier(ref, scope);
});


// Helper poza notifierem:
bool isBrowseInScope(WidgetRef ref, int adId, BrowseScope scope) {
  final asyncAds = ref.watch(networkMonitoringBrowseListProvider(scope));
  final ids = asyncAds.maybeWhen<Set<int>>(
    data: (ads) => { for (final a in ads) a.id },
    orElse: () => const <int>{},
  );
  return ids.contains(adId);
}

