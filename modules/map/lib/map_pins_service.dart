import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map/map_pin_model.dart';

class MapPinEntry<T> {
  final String sourceId;
  final MapPinModel pin;
  final T data;

  const MapPinEntry({
    required this.sourceId,
    required this.pin,
    required this.data,
  });

  String get uniqueKey => '$sourceId:${pin.uniqueKey}';
}

abstract class MapPinsSource {
  String get sourceId;
  AsyncValue<List<MapPinEntry<dynamic>>> watch(WidgetRef ref);
}

class ProviderMapPinsSource<T> implements MapPinsSource {
  @override
  final String sourceId;

  final ProviderListenable<AsyncValue<List<T>>> provider;
  final MapPinModel Function(T item) pinMapper;
  final bool Function(T item)? filter;

  ProviderMapPinsSource({
    required this.sourceId,
    required this.provider,
    required this.pinMapper,
    this.filter,
  });

  @override
  AsyncValue<List<MapPinEntry<T>>> watch(WidgetRef ref) {
    final asyncValue = ref.watch(provider);

    return asyncValue.whenData((items) {
      final filtered = filter == null ? items : items.where(filter!).toList();

      return filtered
          .map(
            (item) => MapPinEntry<T>(
              sourceId: sourceId,
              pin: pinMapper(item),
              data: item,
            ),
          )
          .toList();
    });
  }
}

class MapPinsSnapshot {
  final List<MapPinEntry<dynamic>> entries;
  final bool isLoading;
  final Object? error;

  const MapPinsSnapshot({
    required this.entries,
    required this.isLoading,
    required this.error,
  });

  bool get hasEntries => entries.isNotEmpty;

  MapPinsSnapshot copyWith({
    List<MapPinEntry<dynamic>>? entries,
    bool? isLoading,
    Object? error = _noErrorOverride,
  }) {
    return MapPinsSnapshot(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _noErrorOverride) ? this.error : error,
    );
  }

  static const _noErrorOverride = Object();
}

class MapPinsService {
  const MapPinsService();

  MapPinsSnapshot watch(WidgetRef ref, List<MapPinsSource> sources) {
    final entries = <MapPinEntry<dynamic>>[];
    bool isLoading = false;
    Object? error;

    for (final source in sources) {
      final asyncValue = source.watch(ref);

      isLoading = isLoading || asyncValue.isLoading;
      error ??= asyncValue.hasError ? asyncValue.error : null;
      entries.addAll(asyncValue.valueOrNull ?? const []);
    }

    return MapPinsSnapshot(
      entries: entries,
      isLoading: isLoading,
      error: error,
    );
  }
}