// ignore_for_file: unused_result

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/network_monitoring_urls.dart';
import 'package:network_monitoring/providers/saved_search/add_client.dart';
import 'package:network_monitoring/providers/saved_search/inbox_providers.dart';
import 'api.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/secure_storage.dart';

final removeSavedSearchProvider =
Provider((ref) => RemoveSavedSearchProvider(ref));

class RemoveSavedSearchProvider {
  final Ref ref;
  final SecureStorage secureStorage = SecureStorage();

  RemoveSavedSearchProvider(this.ref);

  Future<bool> removeSavedSearch(int savedSearchId) async {
    if (ApiServices.token == null) return false;

    try {
      final response = await ApiServices.delete(
        NetworkMonitoringUrls.deleteSavedSearch('$savedSearchId'),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        final selectedId = ref.read(selectedSavedSearchIdProvider);

        if (selectedId == savedSearchId) {
          ref.read(selectedSavedSearchIdProvider.notifier).state = null;
        }

        ref.invalidate(savedSearchesWithCountersProvider);
        ref.invalidate(savedSearchesProvider);
        ref.invalidate(addClientToSavedSearch);
        ref.invalidate(selectedSavedSearchProvider);
        ref.invalidate(savedSearchInboxProvider);

        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }}