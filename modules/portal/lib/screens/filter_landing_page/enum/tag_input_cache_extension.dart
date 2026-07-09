import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filter_landing_page/providers/tag_input_provider.dart';

extension TagInputCacheExtension on WidgetRef {
  void initializeTagInputFromCache({
    required String providerId,
    required String cacheKey,
    required FilterCacheNotifier cache,
  }) {
    final cacheValue = cache.filters[cacheKey];

    if (cacheValue != null && cacheValue is String && cacheValue.trim().isNotEmpty) {
      final items = cacheValue
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      read(tagInputProvider(providerId).notifier).setItems(items);
    } else {
      read(tagInputProvider(providerId).notifier).clearAll();
    }
  }

  void syncTagInputToCache({
    required String providerId,
    required String cacheKey,
    required FilterCacheNotifier cache,
    required WidgetRef ref,
  }) {
    final state = read(tagInputProvider(providerId));
    final items = state.items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (items.isEmpty) {
      cache.removeFilter(cacheKey, ref: ref);
    } else {
      cache.addFilter(cacheKey, items.join(','), ref: ref);
    }
  }
}