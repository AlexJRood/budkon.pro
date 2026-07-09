import 'dart:convert';
import 'package:network_monitoring/network_monitoring_urls.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/browselist/utils/pie_menu.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';





@immutable
class HideScope {
  final int? transactionId;
  final int? clientId;
  const HideScope({this.transactionId, this.clientId});

  Map<String, dynamic> toQuery() => {
    if (transactionId != null) 'transaction_id': transactionId,
    if (clientId != null) 'client_id': clientId,
  };

  String prefsKey() {
    final t = transactionId != null ? '_tx_$transactionId' : '';
    final c = clientId != null ? '_client_$clientId' : '';
    return 'hideNM_networkMonitoring$t$c';
  }

  @override
  bool operator ==(Object o) =>
      o is HideScope &&
      o.transactionId == transactionId &&
      o.clientId == clientId;

  @override
  int get hashCode => Object.hash(transactionId, clientId);
}



class NMHideFiltersLogicNotifier
    extends StateNotifier<AsyncValue<List<MonitoringAdsModel>>> {
  NMHideFiltersLogicNotifier(this._ref, this.scope)
  : super(const AsyncValue.loading()) {
    _loadFiltersAndApplyNM(_ref);
  }

  final Ref _ref;
  Map<String, dynamic> filters = {};
  String searchQuery = '';
  String excludeQuery = '';
  String sortOrder = '';
  final HideScope scope;

  Future<void> _loadFiltersAndApplyNM(dynamic ref) async {
    final prefs = await SharedPreferences.getInstance();
    searchQuery = prefs.getString('searchQuery') ?? '';
    excludeQuery = prefs.getString('excludeQuery') ?? '';
    // Załaduj inne filtry, jeśli są potrzebne

    // Po załadowaniu filtrów zastosuj je
    applyFiltersNM(ref);
  }

  Future<void> _saveFiltersNM() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('searchQuery', searchQuery);
    await prefs.setString('excludeQuery', excludeQuery);
    // Zapisz inne filtry, jeśli są potrzebne
  }

  void setSortOrderNM(String order,dynamic ref) {
    sortOrder = order;
    _saveFiltersNM();
    applyFiltersNM(ref);
  }

  void setSearchQueryNM(String query,dynamic ref) {
    searchQuery = query;
    _saveFiltersNM();
    applyFiltersNM(ref);
  }

  void setExcludeQueryNM(String query,dynamic ref) {
    excludeQuery = query;
    _saveFiltersNM();
    applyFiltersNM(ref);
  }

  void addFilterNM(String key, dynamic value,dynamic ref) {
    if (value != null && value.toString().isNotEmpty) {
      filters[key] = value;
    } else {
      filters.remove(key);
    }
    _saveFiltersNM();
    applyFiltersNM(ref);
  }

  void removeFilterNM(String key,dynamic ref) {
    filters.remove(key);
    _saveFiltersNM();
    applyFiltersNM(ref);
  }

  void clearFiltersNM(dynamic ref) {
    filters.clear();
    searchQuery = '';
    excludeQuery = '';
    _saveFiltersNM();
    applyFiltersNM(ref);
  }









  // Szybkie sprawdzenie po stanie (per-scope)
  bool isInHideSync(int adId) {
    final ids = state.maybeWhen(data: (ads) => ads.map((e) => e.id), orElse: () => <int>[]);
    return ids.contains(adId);
  }

  // SP trzymamy tylko jako cache „pamiętaj co kliknięto” – per-scope
  Future<bool> isInHidePrefs(int adId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(scope.prefsKey()) ?? const <String>[];
    return list.contains(adId.toString());
  }

  Future<void> removeFromHideNM(int adId) async {
    try {
      // użyj POST, żeby przekazać scope w body (DELETE zwykle nie ma body)
      final response = await ApiServices.post(
        NetworkMonitoringUrls.removeHideMonitoring('$adId'),
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

  Future<void> addToHideNM(int adId, int? transactionId, int? clientId) async {
    try {
      final response = await ApiServices.post(
        NetworkMonitoringUrls.addHideMonitoring('$adId'),
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

  Future<void> toggleHideNM(
    MonitoringAdsModel ad,
    int? transactionId,
    int? clientId,
    BuildContext context,
  ) async {
    final isInList = state.maybeWhen(
      data: (ads) => ads.any((e) => e.id == ad.id),
      orElse: () => false,
    );

    final prefs = await SharedPreferences.getInstance();
    final key = scope.prefsKey();
    final prefsList = prefs.getStringList(key) ?? <String>[];

    if (isInList) {
      await removeFromHideNM(ad.id);
      if (!context.mounted) return;
      context.showSnackBarLikeSection('removed_from_hidden'.tr);

      final current = state.maybeWhen(data: (ads) => ads, orElse: () => <MonitoringAdsModel>[]);
      state = AsyncData(current.where((e) => e.id != ad.id).toList());

      prefsList.remove(ad.id.toString());
    } else {
      await addToHideNM(ad.id, transactionId, clientId);
      if (!context.mounted) return;
      context.showSnackBarLikeSection('added_to_hidden'.tr);

      final current = state.maybeWhen(data: (ads) => ads, orElse: () => <MonitoringAdsModel>[]);
      state = AsyncData([ad, ...current]);
      if (!prefsList.contains(ad.id.toString())) prefsList.add(ad.id.toString());
    }

    await prefs.setStringList(key, prefsList);
  }


















    // W notifierze:
    bool isHideNM(int adId) {
      final ids = state.maybeWhen<Set<int>>(
        data: (ads) => { for (final a in ads) a.id },
        orElse: () => const <int>{},
      );
      return ids.contains(adId);
    }





  // Future<bool> isHideNM(int adId) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final hideList = prefs.getStringList('hide') ?? [];
  //   return hideList.contains(adId.toString());
  // }



  Future<void> applyFiltersNM(dynamic ref) async {
    state = const AsyncValue.loading();

    try {
      final response = await ApiServices.get(
        ref: ref,
        NetworkMonitoringUrls.networkMonitoring,
        hasToken: true,
        queryParameters: {
          ...filters,
          if (searchQuery.isNotEmpty) 'search': searchQuery,
          if (excludeQuery.isNotEmpty) 'exclude': excludeQuery,
          if (sortOrder.isNotEmpty) 'sort': sortOrder,
        },
      );

      if (!mounted) return; // ✅ CRITICAL

      if (response != null && response.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final listingsJson = json.decode(decodedBody) as Map<dynamic, dynamic>;
        final adsResults = (listingsJson['results'] as List<dynamic>? ?? const []);

        final adsData = adsResults
            .map((item) => MonitoringAdsModel.fromJson(item as Map<String, dynamic>))
            .toList();

        if (!mounted) return; // ✅ extra safe
        state = AsyncValue.data(adsData);
      } else {
        if (!mounted) return;
        state = AsyncValue.error(
          'Failed to load displayed ads'.tr,
          StackTrace.current,
        );
      }
    } catch (e, st) {
      if (!mounted) return; // ✅
      state = AsyncValue.error(e, st);
    }
  }
}


final nMHideAdsProvider =
    StateNotifierProvider.family<NMHideFiltersLogicNotifier,
        AsyncValue<List<MonitoringAdsModel>>, HideScope>((ref, scope) {
  return NMHideFiltersLogicNotifier(ref, scope);
});



// Helper poza notifierem:
bool isHideInScope(WidgetRef ref, int adId, HideScope scope) {
  final asyncAds = ref.watch(nMHideAdsProvider(scope));
  final ids = asyncAds.maybeWhen<Set<int>>(
    data: (ads) => { for (final a in ads) a.id },
    orElse: () => const <int>{},
  );
  return ids.contains(adId);
}
