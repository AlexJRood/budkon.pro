import 'dart:convert';
import 'package:network_monitoring/network_monitoring_urls.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';


class SavedSearch {
  final int id;
  final Map<String, List<String>> queryParams;
  final DateTime searchTime;
  final int resultsCount;
  final String description;
  final int user;

  SavedSearch({
    required this.id,
    required this.queryParams,
    required this.searchTime,
    required this.resultsCount,
    required this.description,
    required this.user,
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'],
      queryParams: Map<String, List<String>>.from(
        json['query_params'].map((k, v) => MapEntry(k, List<String>.from(v))),
      ),
      searchTime: DateTime.parse(json['search_time']),
      resultsCount: json['results_count'],
      description: json['description'],
      user: json['user'],
    );
  }
}

class SavedSearchResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<SavedSearch> results;

  SavedSearchResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory SavedSearchResponse.fromJson(Map<String, dynamic> json) {
    return SavedSearchResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List)
          .map((item) => SavedSearch.fromJson(item))
          .toList(),
    );
  }
}



final lastSearchProvider =
StateNotifierProvider<LastSearchNotifier, List<SavedSearch>>(
      (ref) => LastSearchNotifier(ref),
);

class LastSearchNotifier extends StateNotifier<List<SavedSearch>> {
  final Ref ref;

  LastSearchNotifier(this.ref) : super([]);

  Future<void> fetchSavedSearches() async {
    try {
      final response = await ApiServices.get(
        NetworkMonitoringUrls.fetchNetworkSavedSearches,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        dynamic jsonData = response.data;

        // 🔧 Fix: decode bytes if needed
        if (jsonData is Uint8List) {
          jsonData = jsonDecode(utf8.decode(jsonData));
        }

        final parsed = SavedSearchResponse.fromJson(jsonData);
        state = parsed.results;

        debugPrint('✅ Saved searches fetched: ${state.length} items');
        for (final search in state) {
          debugPrint('---');
          debugPrint('🔹 ID: ${search.id}');
          debugPrint('🕒 Search Time: ${search.searchTime}');
          debugPrint('📊 Results Count: ${search.resultsCount}');
          debugPrint('📋 Description: ${search.description}');
          debugPrint('🔍 Query Params:');
          search.queryParams.forEach((key, value) {
            debugPrint('   • $key: $value');
          });
        }
      } else {
        debugPrint('❌ Data fetching failed: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('🔥 Exception while fetching saved searches: $e');
    }
  }
}
