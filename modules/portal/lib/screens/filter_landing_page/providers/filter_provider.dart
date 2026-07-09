import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:map/map_state.dart';
import 'package:portal/screens/landing_page/providers/landing_page_provider.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:core/platform/url.dart';

final hoveredPropertyProvider = StateProvider<AdsListViewModel?>((ref) => null);

class FiltersLogicNotifier
    extends StateNotifier<AsyncValue<List<AdsListViewModel>>> {
  FiltersLogicNotifier(dynamic ref) : super(const AsyncValue.loading()) {
    applyFilters(ref);
  }

  String get fullAddress {
    return [
      filters['street'],
      filters['city'],
      filters['state'],
      filters['country'],
    ]
        .where((element) => element != null && element.toString().isNotEmpty)
        .join(', ');
  }

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

  void applyFiltersFromCache(FilterCacheNotifier cache, dynamic ref) {
    filters = Map<String, dynamic>.from(cache.filters);
    searchQuery = cache.searchQuery;
    excludeQuery = cache.excludeQuery;
    sortOrder = cache.sortOrder;
    selectedCurrency = cache.selectedCurrency;
    applyFilters(ref);
  }

  void updateSearchQuery(String query, dynamic ref) {
    searchQuery = query.trim();

    if (searchQuery.isEmpty) {
      filters.remove(FilterPopConst.search);
    } else {
      filters[FilterPopConst.search] = searchQuery;
    }

    applyFilters(ref);
  }

  void updateExcludeQuery(String query, dynamic ref) {
    excludeQuery = query.trim();

    if (excludeQuery.isEmpty) {
      filters.remove(FilterPopConst.exclude);
    } else {
      filters[FilterPopConst.exclude] = excludeQuery;
    }

    applyFilters(ref);
  }

  Future<void> applyFilters(dynamic ref) async {
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
      final filterCache = ref.read(filterCacheProvider.notifier);
      final searchParams = filterCache.getSearchParams();

      final Map<String, dynamic> queryParameters = {
        ...filters,
        ...searchParams, // normalized search/exclude overwrite raw values
        'sort': sortOrder.isNotEmpty ? sortOrder : 'date_desc',
        'currency': selectedCurrency,
        ...authFilters,
      };

      if (kDebugMode) {
        debugPrint('[FiltersLogicNotifier] applyFilters called');
        debugPrint('[FiltersLogicNotifier] searchQuery: "$searchQuery"');
        debugPrint('[FiltersLogicNotifier] excludeQuery: "$excludeQuery"');
        debugPrint('[FiltersLogicNotifier] searchParams from cache: $searchParams');
        debugPrint('[FiltersLogicNotifier] queryParameters: $queryParameters');
        debugPrint(
          '[FiltersLogicNotifier] Making API call to: ${URLs.apiAdvertisements}',
        );
      }

      final response = await ApiServices.get(
        ref: ref,
        URLs.apiAdvertisements,
        hasToken: true,
        queryParameters: queryParameters,
      );

      if (response != null && response.statusCode == 200) {
        final listingsJson = _decodeResponseMap(response.data);
        final newList = listingsJson['results'] as List<dynamic>;

        final ads = newList
            .map(
              (item) =>
                  AdsListViewModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        state = AsyncValue.data(ads);

        if (kDebugMode) {
          debugPrint(
            '[FiltersLogicNotifier] applyFilters successful, loaded ${ads.length} ads',
          );
        }
      } else {
        state = AsyncValue.error(
          'Failed to load advertisements',
          StackTrace.current,
        );
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<List<AdsListViewModel>> fetchAdvertisements(
    int pageKey,
    int pageSize,
    dynamic ref, {
    Map<String, dynamic> extraQueryParameters = const {},
  }) async {
    try {
      final filterCache = ref.read(filterCacheProvider.notifier);
      final searchParams = filterCache.getSearchParams();

      final Map<String, dynamic> queryParameters = {
        ...filters,
        ...searchParams, // normalized search/exclude overwrite raw values
        'sort': sortOrder.isNotEmpty ? sortOrder : 'date_desc',
        'currency': selectedCurrency,
        'page': pageKey,
        'pageSize': pageSize,
        ...extraQueryParameters,
      };

      if (kDebugMode) {
        debugPrint('[FiltersLogicNotifier] fetchAdvertisements called');
        debugPrint('[FiltersLogicNotifier] searchParams: $searchParams');
        debugPrint(
          '[FiltersLogicNotifier] extraQueryParameters: $extraQueryParameters',
        );
        debugPrint('[FiltersLogicNotifier] queryParameters: $queryParameters');
      }

      final response = await ApiServices.get(
        ref: ref,
        URLs.apiAdvertisements,
        hasToken: true,
        queryParameters: queryParameters,
      );

      if (response != null && response.statusCode == 200) {
        final listingsJson = _decodeResponseMap(response.data);
        final newList = listingsJson['results'] as List<dynamic>;

        log('New List: ${newList.length}');
        log('pagekey $pageKey');
        log('pageSize $pageSize');
        log('Search params: $searchParams');
        log('Extra query params: $extraQueryParameters');

        return newList.map((item) {
          return AdsListViewModel.fromJson(item as Map<String, dynamic>);
        }).toList();
      }
    } catch (e) {
      throw Exception('Failed to fetch advertisements');
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

  void setSortOrder(String order, {WidgetRef? ref}) {
    sortOrder = order;
    _emitState();

    if (ref != null) {
      ref.read(filterProvider.notifier).applyFiltersFromCache(this, ref);
    }
  }

  void setSearchQuery(String query, {WidgetRef? ref}) {
    final value = query.trim();

    if (value.isEmpty) {
      filters.remove(FilterPopConst.search);
    } else {
      filters[FilterPopConst.search] = value;
    }

    _syncDerivedQueriesFromFilters();
    _emitState();

    if (kDebugMode) {
      debugPrint('[FilterCacheNotifier] setSearchQuery -> "$searchQuery"');
      debugPrint('[FilterCacheNotifier] filters: $filters');
    }

    if (ref != null) {
      ref.read(filterProvider.notifier).applyFiltersFromCache(this, ref);
    }
  }

  void setExcludeQuery(String query, {WidgetRef? ref}) {
    final value = query.trim();

    if (value.isEmpty) {
      filters.remove(FilterPopConst.exclude);
    } else {
      filters[FilterPopConst.exclude] = value;
    }

    _syncDerivedQueriesFromFilters();
    _emitState();

    if (kDebugMode) {
      debugPrint('[FilterCacheNotifier] setExcludeQuery -> "$excludeQuery"');
      debugPrint('[FilterCacheNotifier] filters: $filters');
    }

    if (ref != null) {
      ref.read(filterProvider.notifier).applyFiltersFromCache(this, ref);
    }
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
      debugPrint('[FilterCacheNotifier] getSearchParams called');
      debugPrint('[FilterCacheNotifier] Current filters: $filters');
    }

    final rawSearch = _toCleanString(filters[FilterPopConst.search]);
    if (rawSearch.isNotEmpty) {
      final searchKeywords = _deduplicateKeywords(_splitKeywords(rawSearch));
      if (kDebugMode) {
        debugPrint('[FilterCacheNotifier] Parsed searchKeywords: $searchKeywords');
      }
      if (searchKeywords.isNotEmpty) {
        params[FilterPopConst.search] = searchKeywords.join(',');
      }
    }

    final rawExclude = _toCleanString(filters[FilterPopConst.exclude]);
    if (rawExclude.isNotEmpty) {
      final excludeKeywords = _deduplicateKeywords(_splitKeywords(rawExclude));
      if (kDebugMode) {
        debugPrint('[FilterCacheNotifier] Parsed excludeKeywords: $excludeKeywords');
      }
      if (excludeKeywords.isNotEmpty) {
        params[FilterPopConst.exclude] = excludeKeywords.join(',');
      }
    }

    if (kDebugMode) {
      debugPrint('[FilterCacheNotifier] getSearchParams returning: $params');
    }

    return params;
  }

  void setSelectedCurrency(String currency, {WidgetRef? ref}) {
    selectedCurrency = currency;
    _emitState();

    if (ref != null) {
      ref.read(filterProvider.notifier).applyFiltersFromCache(this, ref);
    }
  }

  void addFilter(String key, dynamic value, {WidgetRef? ref}) {
    final stringValue = value?.toString().trim();

    if (value != null && stringValue != null && stringValue.isNotEmpty) {
      filters[key] = value;
      if (kDebugMode) {
        debugPrint(filters.toString());
      }
    } else {
      filters.remove(key);
    }

    _syncDerivedQueriesFromFilters();
    _emitState();

    if (kDebugMode) {
      debugPrint(state.toString());
    }

    if (ref != null) {
      ref.read(filterProvider.notifier).applyFiltersFromCache(this, ref);
    }
  }

  void removeFilter(String key, {WidgetRef? ref}) {
    filters.remove(key);
    _syncDerivedQueriesFromFilters();
    _emitState();

    if (ref != null) {
      ref.read(filterProvider.notifier).applyFiltersFromCache(this, ref);
      refreshMapPins(ref);
    }
  }

  void clearFilters({
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
      resetLandingFilterUiProviders(ref);

      if (clearMapSelection) {
        clearMapSelectionKeepViewport(ref, refreshPinsAfter: true);
      } else {
        refreshMapPins(ref);
      }

      ref.read(filterProvider.notifier).applyFiltersFromCache(this, ref);
    }
  }
}

final filterProvider = StateNotifierProvider<
    FiltersLogicNotifier,
    AsyncValue<List<AdsListViewModel>>>((ref) {
  return FiltersLogicNotifier(ref);
});

final filterCacheProvider =
    StateNotifierProvider<FilterCacheNotifier, Map<String, dynamic>>((ref) {
  return FilterCacheNotifier();
});