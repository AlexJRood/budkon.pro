import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final userLocationProvider = StateProvider<LatLng?>((ref) => null);
final mapCenterProvider = StateProvider<LatLng?>((ref) => null);
final mapZoomProvider = StateProvider<double>((ref) => 13.0);

enum MapInteractionMode { browse, draw }

final mapInteractionModeProvider =
    StateProvider<MapInteractionMode>((ref) => MapInteractionMode.browse);

final hoveredMapAdIdProvider = StateProvider<int?>((ref) => null);

/// Used to force refresh of map pins when needed,
/// even if bbox stayed the same.
final mapPinsRefreshTriggerProvider = StateProvider<int>((ref) => 0);

class MapViewportState {
  final String? bbox;
  final List<LatLng> polygon;

  const MapViewportState({
    this.bbox,
    this.polygon = const [],
  });

  MapViewportState copyWith({
    String? bbox,
    List<LatLng>? polygon,
  }) {
    return MapViewportState(
      bbox: bbox ?? this.bbox,
      polygon: polygon ?? this.polygon,
    );
  }

  bool get isReady => bbox != null && bbox!.isNotEmpty;
}

final mapViewportProvider =
    StateProvider<MapViewportState>((ref) => const MapViewportState());

class FreehandPolygonNotifier extends StateNotifier<List<LatLng>> {
  FreehandPolygonNotifier() : super(const []);

  bool _isDrawing = false;
  final Distance _distance = const Distance();

  void start(LatLng point) {
    _isDrawing = true;
    state = [point];
  }

  void add(LatLng point) {
    if (!_isDrawing) return;

    if (state.isNotEmpty) {
      final meters = _distance.as(LengthUnit.Meter, state.last, point);
      if (meters < 8) return;
    }

    state = [...state, point];
  }

  void finish() {
    _isDrawing = false;

    if (state.length < 3) return;

    final closed = [...state];
    final first = closed.first;
    final last = closed.last;

    if (first.latitude != last.latitude || first.longitude != last.longitude) {
      closed.add(first);
    }

    state = _compress(closed);
  }

  List<LatLng> _compress(List<LatLng> points) {
    if (points.length <= 3) return points;

    final result = <LatLng>[points.first];

    for (final p in points.skip(1)) {
      final meters = _distance.as(LengthUnit.Meter, result.last, p);
      if (meters >= 8) {
        result.add(p);
      }
    }

    if (result.length >= 3) {
      final first = result.first;
      final last = result.last;
      if (first.latitude != last.latitude || first.longitude != last.longitude) {
        result.add(first);
      }
    }

    return result;
  }

  void clear() {
    _isDrawing = false;
    state = const [];
  }
}

final freehandPolygonProvider =
    StateNotifierProvider<FreehandPolygonNotifier, List<LatLng>>(
  (ref) => FreehandPolygonNotifier(),
);

class MapInitialTarget {
  final LatLng center;
  final double zoom;
  final String source;
  final String signature;

  const MapInitialTarget({
    required this.center,
    required this.zoom,
    required this.source,
    required this.signature,
  });
}

const MapInitialTarget polandDefaultMapTarget = MapInitialTarget(
  center: LatLng(52.0693, 19.4803),
  zoom: 6.2,
  source: 'poland',
  signature: 'poland_default',
);

void refreshMapPins(WidgetRef ref) {
  ref.read(mapPinsRefreshTriggerProvider.notifier).state++;
}

/// Clears only the selection/filtering geometry on the map,
/// but keeps current bbox / center / zoom intact.
void clearMapSelectionKeepViewport(
  WidgetRef ref, {
  bool refreshPinsAfter = true,
}) {
  final currentViewport = ref.read(mapViewportProvider);

  ref.read(freehandPolygonProvider.notifier).clear();
  ref.read(mapInteractionModeProvider.notifier).state =
      MapInteractionMode.browse;
  ref.read(hoveredMapAdIdProvider.notifier).state = null;

  ref.read(mapViewportProvider.notifier).state = currentViewport.copyWith(
    polygon: const [],
  );

  if (refreshPinsAfter) {
    refreshMapPins(ref);
  }
}