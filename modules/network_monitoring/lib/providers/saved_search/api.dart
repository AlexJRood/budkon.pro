import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/network_monitoring_urls.dart';
import 'package:network_monitoring/models/saved_search_model.dart';
import 'package:core/platform/api_services.dart';
import 'dart:convert';

import 'package:get/get_utils/get_utils.dart';

final apiServiceSavedSearchesProvider = Provider<ApiServiceSavedSearches>((ref) {
  return ApiServiceSavedSearches();
});

final savedSearchesProvider = FutureProvider<List<SavedSearchModel>>((ref) async {
  final apiService = ref.read(apiServiceSavedSearchesProvider);
  return apiService.getSavedSearches(ref);
});

class ApiServiceSavedSearches {
  Future<List<SavedSearchModel>> getSavedSearches(dynamic ref) async {
    try {
      final response =
      await ApiServices.get(NetworkMonitoringUrls.savedSearches, ref: ref, hasToken: true);

      if (response != null && response.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final listingsJson = json.decode(decodedBody) as List<dynamic>;

        final statuses = listingsJson
            .map((item) => SavedSearchModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // ✅ Sort by created_at DESC (newest first)
        statuses.sort((a, b) {
          DateTime parse(dynamic v) {
            if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
            // handle both DateTime or String backing fields
            if (v is DateTime) return v;
            return DateTime.tryParse(v.toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
          }

          // Try common field names on the model; fall back to toJson() if needed
          final aCreated = parse(
            // ignore: unnecessary_null_comparison
            (a as dynamic).createdAt ?? (a as dynamic).created_at ?? a.toJson()['created_at'],
          );
          final bCreated = parse(
            (b as dynamic).createdAt ?? (b as dynamic).created_at ?? b.toJson()['created_at'],
          );

          return bCreated.compareTo(aCreated);
        });

        return statuses;
      } else {
        throw Exception('Failed to load saved searches'.tr);
      }
    } catch (e) {
      throw Exception('Failed to load saved searches: $e'.tr);
    }
  }
}
