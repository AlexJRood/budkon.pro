import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final nmUserLocationProvider = StateProvider<LatLng?>((ref) => null);
final nmMapCenterProvider = StateProvider<LatLng?>((ref) => null);
final nmMapZoomProvider = StateProvider<double>((ref) => 13.0);

enum NmMapInteractionMode { browse, draw }

final nmMapInteractionModeProvider =
    StateProvider<NmMapInteractionMode>((ref) => NmMapInteractionMode.browse);

final nmHoveredMapAdIdProvider = StateProvider<int?>((ref) => null);

/// Drives which page of the mobile feed PageView is shown:
/// false = list, true = map.
final nmMapViewActiveProvider = StateProvider<bool>((ref) => false);

/// Used to force refresh of NM map pins when needed,
/// even if bbox stayed the same.
final nmMapPinsRefreshTriggerProvider = StateProvider<int>((ref) => 0);

class NmMapViewportState {
  final String? bbox;
  final List<LatLng> polygon;

  const NmMapViewportState({
    this.bbox,
    this.polygon = const [],
  });

  NmMapViewportState copyWith({
    String? bbox,
    List<LatLng>? polygon,
  }) {
    return NmMapViewportState(
      bbox: bbox ?? this.bbox,
      polygon: polygon ?? this.polygon,
    );
  }

  bool get isReady => bbox != null && bbox!.isNotEmpty;
}

final nmMapViewportProvider =
    StateProvider<NmMapViewportState>((ref) => const NmMapViewportState());

class NmFreehandPolygonNotifier extends StateNotifier<List<LatLng>> {
  NmFreehandPolygonNotifier() : super(const []);

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

final nmFreehandPolygonProvider =
    StateNotifierProvider<NmFreehandPolygonNotifier, List<LatLng>>(
  (ref) => NmFreehandPolygonNotifier(),
);

class NmMapInitialTarget {
  final LatLng center;
  final double zoom;
  final String source;
  final String signature;

  const NmMapInitialTarget({
    required this.center,
    required this.zoom,
    required this.source,
    required this.signature,
  });
}

const NmMapInitialTarget nmPolandDefaultMapTarget = NmMapInitialTarget(
  center: LatLng(52.0693, 19.4803),
  zoom: 6.2,
  source: 'poland',
  signature: 'nm_poland_default',
);

void nmRefreshMapPins(WidgetRef ref) {
  ref.read(nmMapPinsRefreshTriggerProvider.notifier).state++;
}

/// Clears only the selection/filtering geometry on the NM map,
/// but keeps current bbox / center / zoom intact.
void nmClearMapSelectionKeepViewport(
  WidgetRef ref, {
  bool refreshPinsAfter = true,
}) {
  final currentViewport = ref.read(nmMapViewportProvider);

  ref.read(nmFreehandPolygonProvider.notifier).clear();
  ref.read(nmMapInteractionModeProvider.notifier).state =
      NmMapInteractionMode.browse;
  ref.read(nmHoveredMapAdIdProvider.notifier).state = null;

  ref.read(nmMapViewportProvider.notifier).state = currentViewport.copyWith(
    polygon: const [],
  );

  if (refreshPinsAfter) {
    nmRefreshMapPins(ref);
  }
}