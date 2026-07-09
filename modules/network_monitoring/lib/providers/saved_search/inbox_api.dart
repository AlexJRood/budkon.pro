import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';

import 'inbox_models.dart';

final networkMonitoringSavedSearchApiBaseUrlProvider = Provider<String>(
  (ref) => 'https://www.superbee.cloud/',
);

final savedSearchInboxApiProvider = Provider<SavedSearchInboxApi>((ref) {
  return SavedSearchInboxApi(
    ref: ref,
    baseUrl: ref.watch(networkMonitoringSavedSearchApiBaseUrlProvider),
  );
});

class SavedSearchInboxApi {
  SavedSearchInboxApi({
    required this.ref,
    required this.baseUrl,
  });

  final Ref ref;
  final String baseUrl;

  String _u(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    final b = baseUrl.trim();

    if (b.isEmpty) return p;
    if (b.endsWith('/')) {
      return '${b.substring(0, b.length - 1)}$p';
    }
    return '$b$p';
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;

    if (data is String) {
      final s = data.trim();
      if (s.isEmpty) return const [];
      try {
        final decoded = jsonDecode(s);
        if (decoded is List) return decoded;
      } catch (_) {}
    }

    return const [];
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;

    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    if (data is String) {
      final s = data.trim();
      if (s.isEmpty) return <String, dynamic>{};
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {}
    }

    return <String, dynamic>{};
  }

  Future<SavedSearchesWithCountersPageModel> fetchSavedSearchesWithCounters({
    int? clientId,
    int? transactionId,
    List<int>? ids,
    String? q,
    bool? hasNew,
    bool? hasResults,
    bool? enableNotifications,
    bool? enableEmailNotification,
    String? scope,
    String? ordering,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };

    if (clientId != null) query['client_id'] = clientId;
    if (transactionId != null) query['transaction_id'] = transactionId;
    if (ids != null && ids.isNotEmpty) query['ids'] = ids.join(',');
    if ((q ?? '').trim().isNotEmpty) query['q'] = q!.trim();
    if (hasNew != null) query['has_new'] = hasNew ? 'true' : 'false';
    if (hasResults != null) query['has_results'] = hasResults ? 'true' : 'false';
    if (enableNotifications != null) {
      query['enable_notifications'] = enableNotifications ? 'true' : 'false';
    }
    if (enableEmailNotification != null) {
      query['enable_email_notification'] =
          enableEmailNotification ? 'true' : 'false';
    }
    if ((scope ?? '').trim().isNotEmpty) query['scope'] = scope!.trim();
    if ((ordering ?? '').trim().isNotEmpty) {
      query['ordering'] = ordering!.trim();
    }

    final response = await ApiServices.get(
      _u('/saved_searches/with_counters/'),
      queryParameters: query,
      hasToken: true,
      responseType: ResponseType.json,
      ref: ref,
    );

    if (response == null) {
     throw Exception('failed_to_fetch_saved_searches_with_counters'.tr);
    }

    final rawMap = _asMap(response.data);
    if (rawMap.isNotEmpty && rawMap.containsKey('results')) {
      return SavedSearchesWithCountersPageModel.fromJson(rawMap);
    }

    final rawList = _asList(response.data);
    final fallbackResults = rawList
        .whereType<Map>()
        .map(
          (e) => SavedSearchWithCountersModel.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();

    return SavedSearchesWithCountersPageModel(
      count: fallbackResults.length,
      next: null,
      previous: null,
      results: fallbackResults,
      meta: const <String, dynamic>{},
    );
  }


Future<SavedSearchInboxPageModel> fetchInbox({
  List<int>? savedSearchIds,
  int? clientId,
  int? transactionId,
  bool onlyNew = true,
  bool includeInactive = false,
  bool includeArchived = false,
  bool excludeFavorites = false,
  bool excludeHide = false,
  bool excludeDisplayed = false,
  int page = 1,
  int pageSize = 20,
}) async {
  final ids = (savedSearchIds ?? [])
      .where((e) => e > 0)
      .toSet()
      .toList()
    ..sort();

  final query = <String, dynamic>{
    'only_new': onlyNew ? 1 : 0,
    'include_inactive': includeInactive ? 1 : 0,
    'include_archived': includeArchived ? 1 : 0,
    'exclude_favorites': excludeFavorites ? 1 : 0,
    'exclude_hide': excludeHide ? 1 : 0,
    'exclude_displayed': excludeDisplayed ? 1 : 0,
    'page': page,
    'page_size': pageSize,
  };

  if (ids.isNotEmpty) {
    query['saved_search_ids'] = ids.join(',');
  }

  if (clientId != null) {
    query['client_id'] = clientId;
  }

  if (transactionId != null) {
    query['transaction_id'] = transactionId;
  }

  final response = await ApiServices.get(
    _u('/saved_searches/inbox/'),
    queryParameters: query,
    hasToken: true,
    responseType: ResponseType.json,
    ref: ref,
  );

  if (response == null) {
    throw Exception('failed_to_fetch_saved_search_inbox'.tr);
  }

  final map = _asMap(response.data);
  if (map.isEmpty) {
    return SavedSearchInboxPageModel.empty();
  }

  return SavedSearchInboxPageModel.fromJson(map);
}

  Future<void> markInboxSeen({
    required List<int> representativeAdIds,
    List<int>? savedSearchIds,
    int? clientId,
    int? transactionId,
  }) async {
    if (representativeAdIds.isEmpty) {
      return;
    }

    final data = <String, dynamic>{
      'representative_ad_ids': representativeAdIds,
    };

    if (savedSearchIds != null && savedSearchIds.isNotEmpty) {
      data['saved_search_ids'] = savedSearchIds;
    }

    if (clientId != null) {
      data['client_id'] = clientId;
    }

    if (transactionId != null) {
      data['transaction_id'] = transactionId;
    }

    final response = await ApiServices.post(
      _u('/saved_searches/inbox/mark_seen/'),
      data: data,
      hasToken: true,
      ref: ref,
    );

    if (response == null) {
      throw Exception('failed_to_mark_inbox_items_as_seen'.tr);
    }

    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(
        'failed_to_mark_inbox_items_as_seen_status'.trParams({'statusCode': statusCode.toString()}),
      );
    }
  }
}