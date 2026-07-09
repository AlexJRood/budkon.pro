import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:network_monitoring/screens/map/map_state.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:core/platform/url.dart';
import 'package:core/common/autocompletion/autocomplete.dart';

final hoveredNetworkMonitoringPropertyProvider =
    StateProvider<MonitoringAdsModel?>((ref) => null);

class FilterNetworkMonitoringLogicNotifier
    extends StateNotifier<AsyncValue<List<MonitoringAdsModel>>> {
  FilterNetworkMonitoringLogicNotifier(this.ref)
      : super(const AsyncValue.data([]));
  // No initial applyFiltersNM() call — the PagingController handles the first
  // load via fetchAdvertisementsNM. Calling it here would trigger _filtersSub
  // and cause a double reload after the paging controller already loaded page 1.

  final Ref ref;

  Map<String, dynamic> filters = {};
  String searchQuery = '';
  String excludeQuery = '';
  String sortOrder = 'date_desc';
  String selectedCurrency = 'PLN';

  Map<dynamic, dynamic> _decodeResponseMap(dynamic rawBody) {
    dynamic decoded;

    if (rawBody is List<int>) {
      decoded = json.decode(utf8.decode(rawBody));
    } else if (rawBody is String) {
      decoded = json.decode(rawBody);
    } else {
      decoded = rawBody;
    }

    return decoded as Map<dynamic, dynamic>;
  }

  /// Keep optional WidgetRef for backward compatibility with existing NM calls.
  void applyFiltersFromCacheNM(
    FilterCacheNotifier cache, [
    WidgetRef? _widgetRef,
  ]) {
    filters = Map<String, dynamic>.from(cache.filters);
    searchQuery = cache.searchQuery;
    excludeQuery = cache.excludeQuery;
    sortOrder = cache.sortOrder;
    selectedCurrency = cache.selectedCurrency;

    if (kDebugMode) {
      debugPrint('[NM][applyFiltersFromCacheNM]');
      debugPrint('[NM] searchQuery="$searchQuery"');
      debugPrint('[NM] excludeQuery="$excludeQuery"');
      debugPrint('[NM] sortOrder="$sortOrder"');
      debugPrint('[NM] selectedCurrency="$selectedCurrency"');
      debugPrint('[NM] filters=$filters');
    }

    applyFiltersNM();
  }

  Future<void> applyFiltersNM() async {
    state = const AsyncValue.loading();

    Map<String, dynamic> authFilters = {};
    if (ApiServices.token != null && ApiServices.token!.isNotEmpty) {
      authFilters = {
        if (filters.containsKey('exclude_favorites'))
          'exclude_favorites': filters['exclude_favorites'],
        if (filters.containsKey('exclude_hide'))
          'exclude_hide': filters['exclude_hide'],
        if (filters.containsKey('exclude_displayed'))
          'exclude_displayed': filters['exclude_displayed'],
      };
    }

    try {
      final filterCache = ref.read(networkMonitoringFilterCacheProvider.notifier);
      final searchParams = filterCache.getSearchParams();

      final Map<String, dynamic> queryParameters = {
        ...filters,
        ...searchParams,
        'sort': sortOrder.isNotEmpty ? sortOrder : 'date_desc',
        'currency': selectedCurrency,
        ...authFilters,
      };

      if (kDebugMode) {
        debugPrint('[NM][applyFiltersNM] called');
        debugPrint('[NM][applyFiltersNM] searchQuery: "$searchQuery"');
        debugPrint('[NM][applyFiltersNM] excludeQuery: "$excludeQuery"');
        debugPrint('[NM][applyFiltersNM] searchParams from cache: $searchParams');
        debugPrint('[NM][applyFiltersNM] queryParameters: $queryParameters');
        debugPrint('[NM][applyFiltersNM] URL: ${URLs.singleAdMonitoring}');
      }

      final response = await ApiServices.get(
        ref: ref,
        URLs.singleAdMonitoring,
        hasToken: true,
        queryParameters: queryParameters,
      );

      if (!mounted) return;

      if (response != null && response.statusCode == 200) {
        final listingsJson = _decodeResponseMap(response.data);
        final newList = listingsJson['results'] as List<dynamic>;
        final count = listingsJson['count'] as int? ?? 0;

        final ads = newList
            .map(
              (item) =>
                  MonitoringAdsModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        ref.read(networkMonitoringTotalCountProvider.notifier).state = count;
        state = AsyncValue.data(ads);

        if (kDebugMode) {
          debugPrint(
            '[NM][applyFiltersNM] success, loaded ${ads.length} ads, total=$count',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint('[NM][applyFiltersNM] error response=${response?.statusCode}');
        }

        state = AsyncValue.error(
          'failed_to_load_advertisements'.tr,
          StackTrace.current,
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[NM][applyFiltersNM] exception: $e');
      }
      state = AsyncValue.error(e, st);
    }
  }

  /// Whether the draft filters in [cache] differ from what's currently applied.
  /// Used to auto-apply pending changes when the filter sheet is dismissed
  /// without an explicit "Search" tap.
  bool hasPendingChangesNM(FilterCacheNotifier cache) {
    if (searchQuery != cache.searchQuery) return true;
    if (excludeQuery != cache.excludeQuery) return true;
    if (sortOrder != cache.sortOrder) return true;
    if (selectedCurrency != cache.selectedCurrency) return true;
    if (filters.length != cache.filters.length) return true;

    for (final entry in cache.filters.entries) {
      if (filters[entry.key]?.toString() != entry.value?.toString()) {
        return true;
      }
    }

    return false;
  }

  Future<List<MonitoringAdsModel>> fetchAdvertisementsNM(
    int pageKey,
    int pageSize, {
    Map<String, dynamic> extraQueryParameters = const {},
  }) async {
    try {
      final filterCache = ref.read(networkMonitoringFilterCacheProvider.notifier);
      final searchParams = filterCache.getSearchParams();

      final Map<String, dynamic> queryParameters = {
        ...filters,
        ...searchParams,
        'sort': sortOrder.isNotEmpty ? sortOrder : 'date_desc',
        'currency': selectedCurrency,
        'page': pageKey,
        'pageSize': pageSize,
        ...extraQueryParameters,
      };

      if (kDebugMode) {
        debugPrint('[NM][fetchAdvertisementsNM] called');
        debugPrint('[NM][fetchAdvertisementsNM] searchParams: $searchParams');
        debugPrint(
          '[NM][fetchAdvertisementsNM] extraQueryParameters: $extraQueryParameters',
        );
        debugPrint('[NM][fetchAdvertisementsNM] queryParameters: $queryParameters');
      }

      final response = await ApiServices.get(
        ref: ref,
        URLs.singleAdMonitoring,
        hasToken: true,
        queryParameters: queryParameters,
      );

      if (response != null && response.statusCode == 200) {
        final listingsJson = _decodeResponseMap(response.data);
        final newList = listingsJson['results'] as List<dynamic>;

        if (pageKey == 1) {
          final count = listingsJson['count'] as int? ?? 0;
          ref.read(networkMonitoringTotalCountProvider.notifier).state = count;
        }

        log('[NM] New List: ${newList.length}');
        log('[NM] pageKey: $pageKey');
        log('[NM] pageSize: $pageSize');
        log('[NM] searchParams: $searchParams');
        log('[NM] extraQueryParameters: $extraQueryParameters');

        return newList.map((item) {
          return MonitoringAdsModel.fromJson(item as Map<String, dynamic>);
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NM][fetchAdvertisementsNM] exception: $e');
      }
      throw Exception('failed_to_fetch_advertisements'.tr);
    }

    return [];
  }
}

class FilterCacheNotifier extends StateNotifier<Map<String, dynamic>> {
  FilterCacheNotifier() : super({});

  Map<String, dynamic> filters = {};
  String searchQuery = '';
  String excludeQuery = '';
  String sortOrder = 'date_desc';
  String selectedCurrency = 'PLN';

  String _toCleanString(dynamic value) => value?.toString().trim() ?? '';

  void _syncDerivedQueriesFromFilters() {
    searchQuery = _toCleanString(filters[FilterPopConst.search]);
    excludeQuery = _toCleanString(filters[FilterPopConst.exclude]);
  }

  void _emitState() {
    state = {
      'filters': Map<String, dynamic>.from(filters),
      'searchQuery': searchQuery,
      'excludeQuery': excludeQuery,
      'sortOrder': sortOrder,
      'selectedCurrency': selectedCurrency,
    };
  }

  List<String> _splitKeywords(String input) {
    if (input.isEmpty) return [];

    return input
        .split(',')
        .map((keyword) => keyword.trim())
        .where((keyword) => keyword.isNotEmpty)
        .toList();
  }

  List<String> _deduplicateKeywords(List<String> keywords) {
    final seen = <String>{};
    final result = <String>[];

    for (final keyword in keywords) {
      final lower = keyword.toLowerCase();
      if (!seen.contains(lower)) {
        seen.add(lower);
        result.add(keyword);
      }
    }

    return result;
  }

  Map<String, String> getSearchParams() {
    final params = <String, String>{};

    if (kDebugMode) {
      debugPrint('[NM][FilterCacheNotifier] getSearchParams called');
      debugPrint('[NM][FilterCacheNotifier] Current filters: $filters');
    }

    final rawSearch = _toCleanString(filters[FilterPopConst.search]);
    if (rawSearch.isNotEmpty) {
      final searchKeywords = _deduplicateKeywords(_splitKeywords(rawSearch));
      if (kDebugMode) {
        debugPrint('[NM][FilterCacheNotifier] Parsed searchKeywords: $searchKeywords');
      }
      if (searchKeywords.isNotEmpty) {
        params[FilterPopConst.search] = searchKeywords.join(',');
      }
    }

    final rawExclude = _toCleanString(filters[FilterPopConst.exclude]);
    if (rawExclude.isNotEmpty) {
      final excludeKeywords = _deduplicateKeywords(_splitKeywords(rawExclude));
      if (kDebugMode) {
        debugPrint(
          '[NM][FilterCacheNotifier] Parsed excludeKeywords: $excludeKeywords',
        );
      }
      if (excludeKeywords.isNotEmpty) {
        params[FilterPopConst.exclude] = excludeKeywords.join(',');
      }
    }

    if (kDebugMode) {
      debugPrint('[NM][FilterCacheNotifier] getSearchParams returning: $params');
    }

    return params;
  }

  void setSortOrderNM(String order, {WidgetRef? ref}) {
    sortOrder = order;
    _emitState();

    if (ref != null) {
      ref
          .read(networkMonitoringFilterProvider.notifier)
          .applyFiltersFromCacheNM(this, ref);
    }
  }

  void setSelectedCurrencyNM(String currency, {WidgetRef? ref}) {
    selectedCurrency = currency;
    _emitState();

    if (ref != null) {
      ref
          .read(networkMonitoringFilterProvider.notifier)
          .applyFiltersFromCacheNM(this, ref);
    }
  }

  void setSearchQueryNM(String query, {WidgetRef? ref}) {
    final value = query.trim();

    if (value.isEmpty) {
      filters.remove(FilterPopConst.search);
    } else {
      filters[FilterPopConst.search] = value;
    }

    _syncDerivedQueriesFromFilters();
    _emitState();

    if (kDebugMode) {
      debugPrint('[NM][FilterCacheNotifier] setSearchQueryNM -> "$searchQuery"');
      debugPrint('[NM][FilterCacheNotifier] filters: $filters');
    }

    if (ref != null) {
      ref
          .read(networkMonitoringFilterProvider.notifier)
          .applyFiltersFromCacheNM(this, ref);
    }
  }

  void setExcludeQueryNM(String query, {WidgetRef? ref}) {
    final value = query.trim();

    if (value.isEmpty) {
      filters.remove(FilterPopConst.exclude);
    } else {
      filters[FilterPopConst.exclude] = value;
    }

    _syncDerivedQueriesFromFilters();
    _emitState();

    if (kDebugMode) {
      debugPrint('[NM][FilterCacheNotifier] setExcludeQueryNM -> "$excludeQuery"');
      debugPrint('[NM][FilterCacheNotifier] filters: $filters');
    }

    if (ref != null) {
      ref
          .read(networkMonitoringFilterProvider.notifier)
          .applyFiltersFromCacheNM(this, ref);
    }
  }

  void addFilterNM(String key, dynamic value, {WidgetRef? ref}) {
    final stringValue = value?.toString().trim();

    if (value != null && stringValue != null && stringValue.isNotEmpty) {
      filters[key] = value;
    } else {
      filters.remove(key);
    }

    _syncDerivedQueriesFromFilters();
    _emitState();

    if (kDebugMode) {
      debugPrint('[NM][FilterCacheNotifier] addFilterNM -> $filters');
    }

    if (ref != null) {
      ref
          .read(networkMonitoringFilterProvider.notifier)
          .applyFiltersFromCacheNM(this, ref);
    }
  }

  void removeFilterNM(String key, {WidgetRef? ref}) {
    filters.remove(key);
    _syncDerivedQueriesFromFilters();
    _emitState();

    if (ref != null) {
      ref
          .read(networkMonitoringFilterProvider.notifier)
          .applyFiltersFromCacheNM(this, ref);
      nmRefreshMapPins(ref);
    }
  }

  void clearFiltersNM({
    WidgetRef? ref,
    bool clearMapSelection = true,
  }) {
    filters.clear();
    searchQuery = '';
    excludeQuery = '';
    sortOrder = 'date_desc';
    selectedCurrency = 'PLN';

    state = {
      'filters': <String, dynamic>{},
      'searchQuery': '',
      'excludeQuery': '',
      'sortOrder': 'date_desc',
      'selectedCurrency': 'PLN',
      'clearedAt': DateTime.now().millisecondsSinceEpoch,
    };

    if (ref != null) {
      if (clearMapSelection) {
        nmClearMapSelectionKeepViewport(ref, refreshPinsAfter: true);
      } else {
        nmRefreshMapPins(ref);
      }

      ref
          .read(networkMonitoringFilterProvider.notifier)
          .applyFiltersFromCacheNM(this, ref);
    }
  }

  void clearSearchExcludeSilentlyNM({WidgetRef? ref}) {
    filters.remove(FilterPopConst.search);
    filters.remove(FilterPopConst.exclude);
    _syncDerivedQueriesFromFilters();
    _emitState();

    if (kDebugMode) {
      debugPrint('[NM][FilterCacheNotifier] clearSearchExcludeSilentlyNM');
    }

    if (ref != null) {
      ref
          .read(networkMonitoringFilterProvider.notifier)
          .applyFiltersFromCacheNM(this, ref);
      nmRefreshMapPins(ref);
    }
  }

  /// district => city + state + district + geo
  /// locality => city + state, clears district
  /// voivodeship => state only, clears city/district
  void setLocationSelectionNM(LocationSelection sel, {WidgetRef? ref}) {
    void clearLocation() {
      filters.remove('city');
      filters.remove('state');
      filters.remove('district');
      filters.remove('geo_type');
      filters.remove('geo_id');
    }

    if (sel.isEmpty) {
      clearLocation();
      _emitState();

      if (kDebugMode) {
        debugPrint('[NM][CACHE] location cleared');
      }

      if (ref != null) {
        ref
            .read(networkMonitoringFilterProvider.notifier)
            .applyFiltersFromCacheNM(this, ref);
        nmRefreshMapPins(ref);
      }
      return;
    }

    final city = sel.city.trim();
    final stateValue = sel.state.trim();
    final geoType = sel.type.trim();
    final geoId = sel.id.trim();

    if (city.isEmpty && stateValue.isNotEmpty) {
      filters.remove('city');
      filters.remove('district');
      filters['state'] = stateValue;

      if (geoType.isNotEmpty) {
        filters['geo_type'] = geoType;
      } else {
        filters.remove('geo_type');
      }

      if (geoId.isNotEmpty) {
        filters['geo_id'] = geoId;
      } else {
        filters.remove('geo_id');
      }

      _emitState();

      if (kDebugMode) {
        debugPrint(
          '[NM][CACHE] location set => state="$stateValue" geo_id="$geoId" geo_type="$geoType"',
        );
      }

      if (ref != null) {
        ref
            .read(networkMonitoringFilterProvider.notifier)
            .applyFiltersFromCacheNM(this, ref);
        nmRefreshMapPins(ref);
      }
      return;
    }

    if (city.isNotEmpty) {
      filters['city'] = city;
    } else {
      filters.remove('city');
    }

    if (stateValue.isNotEmpty) {
      filters['state'] = stateValue;
    } else {
      filters.remove('state');
    }

    if (sel.districts.isNotEmpty) {
      final district = sel.districts.first.trim();
      if (district.isNotEmpty) {
        filters['district'] = district;
      } else {
        filters.remove('district');
      }
    } else {
      filters.remove('district');
    }

    if (geoType.isNotEmpty) {
      filters['geo_type'] = geoType;
    } else {
      filters.remove('geo_type');
    }

    if (geoId.isNotEmpty) {
      filters['geo_id'] = geoId;
    } else {
      filters.remove('geo_id');
    }

    _emitState();

    if (kDebugMode) {
      debugPrint(
        '[NM][CACHE] location set => city="${filters['city']}" '
        'state="${filters['state']}" district="${filters['district']}" '
        'geo_id="${filters['geo_id']}" geo_type="${filters['geo_type']}"',
      );
    }

    if (ref != null) {
      ref
          .read(networkMonitoringFilterProvider.notifier)
          .applyFiltersFromCacheNM(this, ref);
      nmRefreshMapPins(ref);
    }
  }

  void setFiltersFromJson(Map<String, dynamic> json, {WidgetRef? ref}) {
    filters = (json['filters'] as Map?)?.cast<String, dynamic>() ?? {};
    searchQuery = (json['search_query'] ?? '').toString();
    excludeQuery = (json['exclude_query'] ?? '').toString();
    sortOrder = (json['sort_order'] ?? '').toString();
    selectedCurrency = (json['currency'] ?? 'PLN').toString();

    _syncDerivedQueriesFromFilters();
    _emitState();

    if (kDebugMode) {
      debugPrint('[NM][CACHE] setFiltersFromJson => $state');
    }

    if (ref != null) {
      ref
          .read(networkMonitoringFilterProvider.notifier)
          .applyFiltersFromCacheNM(this, ref);
      nmRefreshMapPins(ref);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'filters': filters,
      'search_query': searchQuery,
      'exclude_query': excludeQuery,
      'sort_order': sortOrder,
      'currency': selectedCurrency,
    };
  }
}

final networkMonitoringFilterCacheProvider =
    StateNotifierProvider<FilterCacheNotifier, Map<String, dynamic>>((ref) {
  return FilterCacheNotifier();
});

final networkMonitoringFilterProvider = StateNotifierProvider<
    FilterNetworkMonitoringLogicNotifier,
    AsyncValue<List<MonitoringAdsModel>>>((ref) {
  return FilterNetworkMonitoringLogicNotifier(ref);
});

final networkMonitoringTotalCountProvider = StateProvider<int>((ref) => 0);

final networkMonitoringMapFiltersProvider =
    Provider<Map<String, dynamic>>((ref) {
  ref.watch(networkMonitoringFilterCacheProvider);

  final cache = ref.read(networkMonitoringFilterCacheProvider.notifier);

  Map<String, dynamic> authFilters = {};
  if (ApiServices.token != null && ApiServices.token!.isNotEmpty) {
    authFilters = {
      if (cache.filters.containsKey('exclude_favorites'))
        'exclude_favorites': cache.filters['exclude_favorites'],
      if (cache.filters.containsKey('exclude_hide'))
        'exclude_hide': cache.filters['exclude_hide'],
      if (cache.filters.containsKey('exclude_displayed'))
        'exclude_displayed': cache.filters['exclude_displayed'],
    };
  }

  return {
    ...Map<String, dynamic>.from(cache.filters),
    ...cache.getSearchParams(),
    'sort': cache.sortOrder.isNotEmpty ? cache.sortOrder : 'date_desc',
    'currency': cache.selectedCurrency,
    ...authFilters,
  };
});