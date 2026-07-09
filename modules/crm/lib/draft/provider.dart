import 'dart:convert';

import 'package:crm/draft/filter_model.dart';
import 'package:crm/draft_ads_listview_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final draftFilterProvider =
    StateProvider<DraftAdFilter>((ref) => DraftAdFilter());

final draftAdvertsProvider =
    FutureProvider.family<List<DraftAdsListViewModel>, int>((ref, page) async {
  final filter = ref.watch(draftFilterProvider);

  final response = await ApiServices.get(
    'https://www.superbee.cloud/portal/draft/advertisements/?include_linked=false',
    queryParameters: {
      ...filter.toQueryParams(),
      'page': page.toString(),
      'page_size': '20',
    },
    hasToken: true,
    ref: ref,
  );

  if (response == null || response.statusCode != 200) {
    throw Exception('Failed to load listings');
  }

  final dynamic rawData = response.data;
  late final Map<String, dynamic> listingsJson;

  if (rawData is Map<String, dynamic>) {
    listingsJson = rawData;
  } else if (rawData is Map) {
    listingsJson = Map<String, dynamic>.from(rawData);
  } else if (rawData is List<int>) {
    listingsJson = json.decode(utf8.decode(rawData)) as Map<String, dynamic>;
  } else if (rawData is String) {
    listingsJson = json.decode(rawData) as Map<String, dynamic>;
  } else {
    throw Exception('Unsupported response format: ${rawData.runtimeType}');
  }

  final List<dynamic> results = listingsJson['results'] ?? [];

  return results
      .map((e) => DraftAdsListViewModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();
});