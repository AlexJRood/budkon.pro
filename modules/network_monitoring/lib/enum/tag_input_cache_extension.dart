import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/providers/tag_input_provider.dart';

extension NMTagInputCacheExtension on WidgetRef {
  void initializeNMTagInputFromCache({
    required String providerId,
    required String cacheKey,
    required FilterCacheNotifier cache,
  }) {
    final cacheValue = cache.filters[cacheKey];
    if (cacheValue != null && cacheValue is String) {
      final items = cacheValue.split(',').where((item) => item.trim().isNotEmpty).toList();
      read(nmTagInputProvider(providerId).notifier).setItems(items);
    }
  }

  void syncNMTagInputToCache({
    required String providerId,
    required String cacheKey,
    required FilterCacheNotifier cache,
  }) {
    final items = read(nmTagInputProvider(providerId)).items;
    if (items.isNotEmpty) {
      cache.addFilterNM(cacheKey, items.join(','));
    } else {
      cache.removeFilterNM(cacheKey);
    }
  }
}