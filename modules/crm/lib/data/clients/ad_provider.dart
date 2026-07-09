import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core/common/custom_error_handler.dart';

class FiltersLogicNotifier extends StateNotifier<AsyncValue<List<MonitoringAdsModel>>> {
  FiltersLogicNotifier(dynamic ref) : super(const AsyncValue.loading()) {
    _loadFiltersAndApply(ref);
  }

  String? _extractErrorMessage(dynamic data) {
    try {
      if (data == null) return null;
      if (data is Map) {
        final v = data['error'] ?? data['message'];
        return v?.toString();
      }
      if (data is String) {
        final parsed = json.decode(data);
        if (parsed is Map) {
          final v = parsed['error'] ?? parsed['message'];
          return v?.toString();
        }
        return data;
      }
      if (data is List<int>) {
        final str = utf8.decode(data);
        final parsed = json.decode(str);
        if (parsed is Map) {
          final v = parsed['error'] ?? parsed['message'];
          return v?.toString();
        }
        return str;
      }
    } catch (_) {}
    return null;
  }

  // NEW: support multiple saved searches
  Set<int> selectedSavedSearchIds = {}; // multi
  String selectedSavedSearchId = ''; // backward-compat (single)

  bool filterByClientId = false;
  bool filterByTransactionId = false;

  String savedSearchClientId = '';
  String savedSearchTransactionId = '';
  String clientId = '';
  String transactionId = '';

  String searchQuery = '';
  String excludeQuery = '';
  String sortOrder = '';
  String selectedCurrency = 'PLN';

  Map<String, dynamic> filters = {};

  Future<void> _loadFiltersAndApply(dynamic ref) async {
    final prefs = await SharedPreferences.getInstance();
    searchQuery = prefs.getString('searchQuery') ?? '';
    excludeQuery = prefs.getString('excludeQuery') ?? '';
    selectedSavedSearchId = prefs.getString('selectedSavedSearchId') ?? '';
    final csv = prefs.getString('selectedSavedSearchIds') ?? '';

    if (csv.isNotEmpty) {
      selectedSavedSearchIds = csv
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && int.tryParse(s) != null)
          .map(int.parse)
          .toSet();
    } else if (selectedSavedSearchId.isNotEmpty && int.tryParse(selectedSavedSearchId) != null) {
      selectedSavedSearchIds = {int.parse(selectedSavedSearchId)};
    }

    savedSearchClientId = prefs.getString('savedSearchClientId') ?? '';
    savedSearchTransactionId = prefs.getString('savedSearchTransactionId') ?? '';
    applyFilters(ref);
  }

  void applyFiltersFromCache(FilterCacheNotifier cache, dynamic ref) {
    // cache.filters contains also special keys: search/exclude/sort/currency
    // plus location keys: city/voivodeship/district
    filters = cache.filters;
    searchQuery = cache.searchQuery;
    excludeQuery = cache.excludeQuery;
    sortOrder = cache.sortOrder;
    selectedCurrency = cache.selectedCurrency;
    applyFilters(ref);
  }

  Future<void> applyFilters(dynamic ref) async {
    state = const AsyncValue.loading();

      Map<String, dynamic> authFilters = {};
    if (ApiServices.token != null && ApiServices.token!.isNotEmpty) {
      authFilters = {
        if (filters.containsKey('exclude_favorites')) 'exclude_favorites': filters['exclude_favorites'],
        if (filters.containsKey('exclude_hide')) 'exclude_hide': filters['exclude_hide'],
        if (filters.containsKey('exclude_displayed')) 'exclude_displayed': filters['exclude_displayed'],
      };
    }

    final filterCache = ref.read(filterCacheProvider.notifier);
    final searchParams = filterCache.getSearchParams();

    final multiCsv = selectedSavedSearchIds.isNotEmpty
        ? selectedSavedSearchIds.join(',')
        : (selectedSavedSearchId.isNotEmpty ? selectedSavedSearchId : '');

    final Map<String, dynamic> queryParameters = {
      ...filters,      ...searchParams,  
      if (sortOrder.isNotEmpty) 'sort': sortOrder,
      'currency': selectedCurrency,
      ...authFilters,
      if (multiCsv.isNotEmpty) 'saved_search_id': multiCsv,
      if (savedSearchClientId.isNotEmpty) 'saved_search_client_id': savedSearchClientId,
      if (savedSearchTransactionId.isNotEmpty) 'saved_search_transaction_id': savedSearchTransactionId,
      if (clientId.isNotEmpty) 'client': clientId,
      if (transactionId.isNotEmpty) 'transaction': transactionId,
    };
    queryParameters.remove('search');
    queryParameters.remove('exclude');
    queryParameters.removeWhere((k, v) {
      if (v == null) return true;
      if (v is String) return v.trim().isEmpty;
      if (v is Iterable) return v.isEmpty;
      if (v is Map) return v.isEmpty;
      return false;
    });
    if (kDebugMode) {
      debugPrint('[NM] queryParameters = ${jsonEncode(queryParameters)}');
    }

    try {
      final response = await ApiServices.get(
        ref: ref,
        URLs.singleAdMonitoring,
        hasToken: true,
        queryParameters: queryParameters,
      );

      if (kDebugMode) {
        debugPrint('[NM] GET singleAdMonitoring -> status=${response?.statusCode}');
        if (response?.data != null) {
          debugPrint('[NM] payload type: ${response!.data.runtimeType}');
        } else {
          debugPrint('[NM] payload: <null>');
        }
      }

      if (response != null && response.statusCode == 200) {
        Map<String, dynamic> root;
        final data = response.data;

        if (data is Map) {
          root = data.cast<String, dynamic>();
        } else if (data is String) {
          root = json.decode(data) as Map<String, dynamic>;
        } else if (data is List<int>) {
          root = json.decode(utf8.decode(data)) as Map<String, dynamic>;
        } else {
          throw Exception('Unexpected response format');
        }

        final list = (root['results'] as List<dynamic>)
            .map((item) => MonitoringAdsModel.fromJson(item as Map<String, dynamic>))
            .toList();

        state = AsyncValue.data(list);
        return;
      }

      final code = response?.statusCode;
      final msg = _extractErrorMessage(response?.data);

      final askedTxSaved = savedSearchTransactionId.isNotEmpty ||
          (queryParameters['saved_search_transaction_id']?.toString().isNotEmpty ?? false);
      final askedClientSaved = savedSearchClientId.isNotEmpty ||
          (queryParameters['saved_search_client_id']?.toString().isNotEmpty ?? false);
      final askedSavedIds = (queryParameters['saved_search_id']?.toString().isNotEmpty ?? false);

      String? friendly = msg;
      if ((code == 404 || code == null) && askedTxSaved) {
        friendly ??= 'no_saved_filters_for_transaction'.tr;
      } else if ((code == 404 || code == null) && askedClientSaved) {
        friendly ??='no_saved_searches_for_client'.tr;
      } else if ((code == 404 || code == null) && askedSavedIds) {
        friendly ??= 'no_saved_searches_found'.tr;
      }

      if (friendly != null && friendly.isNotEmpty) {
        state = AsyncValue.error(friendly, StackTrace.current);
      } else {
        state = AsyncValue.error(
          '${'failed_to_load_advertisements'.tr}${code != null ? ' (HTTP $code)' : ''}',
          StackTrace.current,
        );
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = _extractErrorMessage(e.response?.data);

      if (kDebugMode) {
        debugPrint('[NM] DioException status=$code, msg=$msg');
      }

      final askedTxSaved = savedSearchTransactionId.isNotEmpty ||
          (queryParameters['saved_search_transaction_id']?.toString().isNotEmpty ?? false);
      final askedClientSaved = savedSearchClientId.isNotEmpty ||
          (queryParameters['saved_search_client_id']?.toString().isNotEmpty ?? false);
      final askedSavedIds = (queryParameters['saved_search_id']?.toString().isNotEmpty ?? false);

      String? friendly = msg;
      if ((code == 404 || code == null) && askedTxSaved) {
        friendly ??= 'no_saved_filters_for_transaction'.tr;
      } else if ((code == 404 || code == null) && askedClientSaved) {
        friendly ??= 'no_saved_searches_for_client'.tr;
      } else if ((code == 404 || code == null) && askedSavedIds) {
        friendly ??= 'no_saved_searches_found'.tr;
      }

      if (friendly != null && friendly.isNotEmpty) {
        state = AsyncValue.error(friendly, StackTrace.current);
      } else {
        state = AsyncValue.error(e, StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void setSavedSearch(String searchId, dynamic ref) {
    selectedSavedSearchId = searchId;
    selectedSavedSearchIds = {};
    _saveFilters();
    applyFilters(ref);
  }

  void setSavedSearches(Set<int>? ids, dynamic ref, int? transactionId) {
    if (ids == null || ids.isEmpty) {
      setTransactionId(transactionId.toString(), ref);
      selectedSavedSearchIds.clear();
      selectedSavedSearchId = '';
    } else {
      setTransactionId('', ref);
      selectedSavedSearchIds = ids;
      selectedSavedSearchId = ids.length == 1 ? ids.first.toString() : '';
    }
    _saveFilters();
    applyFilters(ref);
  }

  void clearSavedSearches(dynamic ref) {
    selectedSavedSearchIds.clear();
    selectedSavedSearchId = '';
    _saveFilters();
    applyFilters(ref);
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedSavedSearchId', selectedSavedSearchId);
    await prefs.setString('selectedSavedSearchIds', selectedSavedSearchIds.join(','));
    await prefs.setString('savedSearchClientId', savedSearchClientId);
    await prefs.setString('savedSearchTransactionId', savedSearchTransactionId);
    await prefs.setString('client', clientId);
    await prefs.setString('transaciton', transactionId);
  }

  void setClientId(String newClientId, dynamic ref) {
    savedSearchClientId = newClientId;
    _saveFilters();
  }

  void setTransactionId(String newTransactionId, dynamic ref) {
    savedSearchTransactionId = newTransactionId;
    _saveFilters();
  }

  void filteredScope(int? scopeClientId, int? scopeTransactionId, dynamic ref) {
    clientId = scopeClientId.toString();
    transactionId = scopeTransactionId.toString();
    _saveFilters();
  }

  int? _extractSavedSearchIdFromResponse(dynamic data) {
    try {
      if (data == null) return null;
      Map<String, dynamic>? map;

      if (data is Map) {
        map = data.cast<String, dynamic>();
      } else if (data is String) {
        map = json.decode(data) as Map<String, dynamic>;
      } else if (data is List<int>) {
        map = json.decode(utf8.decode(data)) as Map<String, dynamic>;
      }

      if (map == null) return null;
      final v = map['saved_search_id'] ?? map['id'];
      if (v is int) return v;
      if (v is String && int.tryParse(v) != null) return int.parse(v);
      return null;
    } catch (_) {
      return null;
    }
  }


  




  Future<void> saveFilters({
  required BuildContext context,
  required FilterCacheNotifier filters,
  int? clientId,
  int? transactionId,
  Map<String, String>? tags,
  String? title,
  String? description,

  // ✅ NEW
  bool? enableNotifications,
  bool? enableEmailNotification,

  Future<void> Function(int savedSearchId)? onSuccess,
  List<int>? customAvatarData,
}) async {
  try {
    if (ApiServices.token == null) {
      if (kDebugMode) debugPrint('Authorization token not found'.tr);
      if (context.mounted) {
        final sb = Customsnackbar().showSnackBar(
          "Warning".tr,
          'authorization_token_not_found'.tr,
          "warning", // ✅ keep stable type key
          () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        );
        ScaffoldMessenger.of(context).showSnackBar(sb);
      }
      return;
    }

    final Map<String, dynamic> raw = {
      "transaction": transactionId,
      "client": clientId,
      "title": title,
      "description": description,

      // ✅ NEW (snake_case)
      "enable_notifications": enableNotifications,
      "enable_email_notification": enableEmailNotification,

      "tags": tags == null ? null : jsonEncode(tags),
      "filters": jsonEncode(filters.filters),
    }..removeWhere((_, v) => v == null || (v is String && v.trim().isEmpty));

    if (kDebugMode) debugPrint('Data to send (cleaned): $raw');

    final formData = FormData.fromMap(raw);
    if (customAvatarData != null) {
      formData.files.add(
        MapEntry(
          'avatar',
          MultipartFile.fromBytes(customAvatarData, filename: 'custom_avatar.png'),
        ),
      );
    }

    final response = await ApiServices.post(
      URLs.savedSearch,
      formData: formData,
      hasToken: true,
    );

    if (response != null && response.statusCode == 201) {
      final savedId = _extractSavedSearchIdFromResponse(response.data);
      if (kDebugMode) debugPrint('Search saved successfully. id=$savedId');

      if (savedId != null) {
        await onSuccess?.call(savedId);
      }

      if (context.mounted) {
        final sb = Customsnackbar().showSnackBar(
          "success",
          'search_saved_successfully'.tr,
          "success",
          () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        );
        ScaffoldMessenger.of(context).showSnackBar(sb);
      }
      return;
    }

    if (context.mounted) {
      final msg = response?.statusMessage;
      final sb = Customsnackbar().showSnackBar(
        "Error".tr,
        '${'failed_to_save_search'.tr}${msg != null ? ' ($msg)' : ''}',
        "error",
        () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      );
      ScaffoldMessenger.of(context).showSnackBar(sb);
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('saveFilters error: $e');
      debugPrint(st.toString());
    }
    if (context.mounted) {
      final sb = Customsnackbar().showSnackBar(
        "Error".tr,
        'unexpected_error_saving_search'.tr,
        "error",
        () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      );
      ScaffoldMessenger.of(context).showSnackBar(sb);
    }
  }
}

Future<void> updateSavedFilters({
  required BuildContext context,
  required int savedSearchId,
  required FilterCacheNotifier filters,
  int? clientId,
  int? transactionId,
  Map<String, String>? tags,
  String? title,
  String? description,

  // ✅ NEW
  bool? enableNotifications,
  bool? enableEmailNotification,

  Future<void> Function(int savedSearchId)? onSuccess,
  List<int>? customAvatarData,
}) async {
  try {
    if (ApiServices.token == null) {
      if (kDebugMode) debugPrint('Authorization token not found');
      if (context.mounted) {
        final sb = Customsnackbar().showSnackBar(
          "Warning".tr,
          'authorization_token_not_found'.tr,
          "warning", // ✅ keep stable type key
          () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        );
        ScaffoldMessenger.of(context).showSnackBar(sb);
      }
      return;
    }

    final Map<String, dynamic> raw = {
      "transaction": transactionId,
      "client": clientId,
      "title": title,
      "description": description,

      // ✅ NEW
      "enable_notifications": enableNotifications,
      "enable_email_notification": enableEmailNotification,

      "tags": tags == null ? null : jsonEncode(tags),
      "filters": jsonEncode(filters.filters),
    }..removeWhere((_, v) => v == null || (v is String && v.trim().isEmpty));

    if (kDebugMode) debugPrint('Data to update (cleaned): $raw');

    final formData = FormData.fromMap(raw);
    if (customAvatarData != null) {
      formData.files.add(
        MapEntry(
          'avatar',
          MultipartFile.fromBytes(customAvatarData, filename: 'custom_avatar.png'),
        ),
      );
    }

    final url = URLs.editSavedSearch(savedSearchId.toString());

    final response = await ApiServices.put(
      url,
      formData: formData,
      hasToken: true,
    );

    if (response != null && (response.statusCode == 200 || response.statusCode == 204)) {
      final updatedId = _extractSavedSearchIdFromResponse(response.data) ?? savedSearchId;
      await onSuccess?.call(updatedId);

      if (context.mounted) {
        final sb = Customsnackbar().showSnackBar(
          "success",
          'search_updated_successfully'.tr,
          "success",
          () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        );
        ScaffoldMessenger.of(context).showSnackBar(sb);
      }
      return;
    }

    if (context.mounted) {
      final msg = _extractErrorMessage(response?.data) ?? response?.statusMessage;
      final sb = Customsnackbar().showSnackBar(
        "Error".tr,
        '${'failed_to_update_search'.tr}${msg != null ? ' ($msg)' : ''}',
        "error",
        () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      );
      ScaffoldMessenger.of(context).showSnackBar(sb);
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('updateSavedFilters error: $e');
      debugPrint(st.toString());
    }
    if (context.mounted) {
      final sb = Customsnackbar().showSnackBar(
        "Error".tr,
        'unexpected_error_updating_search'.tr,
        "error",
        () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      );
      ScaffoldMessenger.of(context).showSnackBar(sb);
    }
  }
}
}

class FilterCacheNotifier extends StateNotifier<Map<String, dynamic>> {
  FilterCacheNotifier() : super({});

  /// All filters that will be JSON-encoded and saved in SavedSearch.filters
  Map<String, dynamic> filters = {};

  /// Convenience fields (kept in sync with filters['search'|'exclude'|'sort'|'currency'])
  String searchQuery = '';
  String excludeQuery = '';
  String sortOrder = '';
  String selectedCurrency = 'PLN';

  void _syncSpecialFromFilters() {
    final s = filters['search'];
    searchQuery = (s != null && s.toString().trim().isNotEmpty) ? s.toString() : '';

    final e = filters['exclude'];
    excludeQuery = (e != null && e.toString().trim().isNotEmpty) ? e.toString() : '';

    final so = filters['sort'];
    sortOrder = (so != null && so.toString().trim().isNotEmpty) ? so.toString() : '';

    final cur = filters['currency'];
    selectedCurrency = (cur != null && cur.toString().trim().isNotEmpty) ? cur.toString() : 'PLN';
  }

  void setSortOrder(String order) {
    final v = order.trim();
    sortOrder = v;

    if (v.isEmpty) {
      filters.remove('sort');
    } else {
      filters['sort'] = v;
    }

    state = {...state, 'sortOrder': v, 'filters': filters};
  }

  void setSearchQuery(dynamic query) {
    final v = (query ?? '').toString().trim();
    searchQuery = v;

    if (v.isEmpty) {
      filters.remove('search');
    } else {
      filters['search'] = v;
    }

    state = {...state, 'searchQuery': v, 'filters': filters};
  }

  void setExcludeQuery(String query) {
    final v = query.trim();
    excludeQuery = v;

    if (v.isEmpty) {
      filters.remove('exclude');
    } else {
      filters['exclude'] = v;
    }

    state = {...state, 'excludeQuery': v, 'filters': filters};
  }
List<String> _splitKeywords(String input) {
    if (input.isEmpty) return [];
    
    // Split by comma and trim whitespace
    return input.split(',')
      .map((keyword) => keyword.trim())
      .where((keyword) => keyword.isNotEmpty)
      .toList();
  }

  // Helper method to remove duplicates (case-insensitive)
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

  // Get formatted search parameters for API
  Map<String, dynamic> getSearchParams() {
    final params = <String, dynamic>{};
    
    // Process search keywords
    if (searchQuery.isNotEmpty) {
      final searchKeywords = _deduplicateKeywords(_splitKeywords(searchQuery));
      if (searchKeywords.isNotEmpty) {
        // API supports both CSV format and repeated params
        // We'll use CSV format for simplicity
        params['search'] = searchKeywords.join(',');
      }
    }
    
    // Process exclude keywords
    if (excludeQuery.isNotEmpty) {
      final excludeKeywords = _deduplicateKeywords(_splitKeywords(excludeQuery));
      if (excludeKeywords.isNotEmpty) {
        params['exclude'] = excludeKeywords.join(',');
      }
    }
    
    return params;
  }
  void setSelectedCurrency(String currency) {
    final v = currency.trim().isEmpty ? 'PLN' : currency.trim();
    selectedCurrency = v;

    filters['currency'] = v;

    state = {...state, 'selectedCurrency': v, 'filters': filters};
  }

  void addFilter(String key, dynamic value) {
    // Special keys
    if (key == 'search') {
      setSearchQuery(value);
      return;
    }
    if (key == 'exclude') {
      setExcludeQuery((value ?? '').toString());
      return;
    }
    if (key == 'sort') {
      setSortOrder((value ?? '').toString());
      return;
    }
    if (key == 'currency') {
      setSelectedCurrency((value ?? 'PLN').toString());
      return;
    }

    bool isEmptyValue(dynamic v) {
      if (v == null) return true;
      if (v is String) return v.trim().isEmpty;
      if (v is Iterable) return v.isEmpty; // ✅ List/Set
      if (v is Map) return v.isEmpty;      // ✅ Map
      return v.toString().trim().isEmpty;
    }

    if (isEmptyValue(value)) {
      filters.remove(key); // ✅ remove key instead of keeping []
    } else {
      filters[key] = value;
    }

    _syncSpecialFromFilters();
    state = {...state, 'filters': filters};
  }

  void removeFilter(String key) {
    filters.remove(key);

    if (key == 'search') searchQuery = '';
    if (key == 'exclude') excludeQuery = '';
    if (key == 'sort') sortOrder = '';
    if (key == 'currency') selectedCurrency = 'PLN';

    state = {...state, 'filters': filters};
  }

  void clearFilters() {
    filters.clear();
    searchQuery = '';
    excludeQuery = '';
    sortOrder = '';
    selectedCurrency = 'PLN';
    state = {};
  }
}

final filterProvider = StateNotifierProvider<FiltersLogicNotifier, AsyncValue<List<MonitoringAdsModel>>>((ref) {
  return FiltersLogicNotifier(ref);
});

final filterCacheProvider = StateNotifierProvider<FilterCacheNotifier, Map<String, dynamic>>((ref) {
  return FilterCacheNotifier();
});
