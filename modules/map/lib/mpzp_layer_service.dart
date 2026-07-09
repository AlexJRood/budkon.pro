import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

import 'app_map_cacheable_service.dart';
import 'app_map_layer_service.dart';
import 'map_layer_state_storage.dart';
import 'map_wms_utils.dart';

class MpzpLayerService extends AppMapLayerService
    implements AppMapCacheableService {
  @override
  final String id;

  MpzpLayerService({this.id = 'mpzp_layer'}) {
    _restoreState();
  }

  static const String _baseUrl =
      'https://mapy.geoportal.gov.pl/wss/ext/KrajowaIntegracjaMiejscowychPlanowZagospodarowaniaPrzestrzennego?';

  String get _stateNamespace => '${id}_state';

  bool showLayer = false;
  bool showBoundaries = true;
  bool showZones = true;
  bool showBuildingLines = false;
  double opacity = 0.60;

  bool canShow(double zoom) => zoom >= 13.0;

  Future<void> _restoreState() async {
    final raw = await MapLayerStateStorage.read(namespace: _stateNamespace) ??
        await MapLayerStateStorage.read(namespace: id);

    if (raw == null) return;

    showLayer = raw['showLayer'] == true;
    showBoundaries = raw['showBoundaries'] != false;
    showZones = raw['showZones'] != false;
    showBuildingLines = raw['showBuildingLines'] == true;
    opacity = ((raw['opacity'] as num?)?.toDouble() ?? 0.60).clamp(0.0, 1.0);

    notifyListeners();
  }

  Future<void> _persistState() async {
    await MapLayerStateStorage.write(
      namespace: _stateNamespace,
      data: {
        'showLayer': showLayer,
        'showBoundaries': showBoundaries,
        'showZones': showZones,
        'showBuildingLines': showBuildingLines,
        'opacity': opacity,
      },
    );
  }

  void _saveAndNotify() {
    notifyListeners();
    unawaited(_persistState());
  }

  void setShowLayer(bool value) {
    if (showLayer == value) return;
    showLayer = value;
    _saveAndNotify();
  }

  void setShowBoundaries(bool value) {
    if (showBoundaries == value) return;
    showBoundaries = value;
    _saveAndNotify();
  }

  void setShowZones(bool value) {
    if (showZones == value) return;
    showZones = value;
    _saveAndNotify();
  }

  void setShowBuildingLines(bool value) {
    if (showBuildingLines == value) return;
    showBuildingLines = value;
    _saveAndNotify();
  }

  void setOpacity(double value) {
    final next = value.clamp(0.05, 1.0).toDouble();
    if (opacity == next) return;
    opacity = next;
    _saveAndNotify();
  }

  List<String> _layers() {
    final layers = <String>[];

    if (showBoundaries) {
      layers.add('plany_granice');
    }

    if (showZones) {
      layers.add('wektor-str');
    }

    if (showBuildingLines) {
      layers.add('wektor-lzb');
    }

    return layers;
  }

  void resetSettings() {
    showLayer = false;
    showBoundaries = true;
    showZones = true;
    showBuildingLines = false;
    opacity = 0.60;
    _saveAndNotify();
  }

  @override
  List<Widget> buildLayers({
    required BuildContext context,
    required WidgetRef ref,
    required MapController mapController,
    required ThemeColors theme,
    required double zoom,
  }) {
    if (!showLayer || !canShow(zoom)) {
      return const [];
    }

    final layers = _layers();
    if (layers.isEmpty) {
      return const [];
    }

    return [
      buildWmsTileLayer(
        baseUrl: _baseUrl,
        layers: layers,
        opacity: opacity,
        layerKey:
            '$id|${layers.join(",")}|${opacity.toStringAsFixed(2)}|${zoom.floor()}',
      ),
    ];
  }

  @override
  String get cacheDisplayName => 'MPZP';

  @override
  String get cacheDescription =>
      'Zapis stanu warstwy MPZP do local storage. Same kafelki WMS nie są tutaj cachowane persistent.';

  @override
  bool get supportsMemoryCache => false;

  @override
  bool get supportsPersistentCache => true;

  @override
  Future<AppMapCacheSummary> getCacheSummary() async {
    final stateStats =
        await MapLayerStateStorage.stats(namespace: _stateNamespace);
    final legacyStats = await MapLayerStateStorage.stats(namespace: id);

    final persistentEntries =
        (stateStats.exists ? 1 : 0) + (legacyStats.exists ? 1 : 0);

    final persistentBytes = stateStats.approxBytes + legacyStats.approxBytes;

    return AppMapCacheSummary(
      memoryEntries: 0,
      persistentEntries: persistentEntries,
      approxBytes: persistentBytes,
      memoryBytes: 0,
      persistentBytes: persistentBytes,
      note:
          'Cache MPZP obejmuje zapisane ustawienia warstwy. Raster WMS wymaga osobnego tile-cache providera.',
    );
  }

  @override
  Future<void> clearMemoryCache({bool clearVisibleState = true}) async {}

  @override
  Future<void> clearPersistentCache({bool clearVisibleState = false}) async {
    await MapLayerStateStorage.clear(namespace: _stateNamespace);
    await MapLayerStateStorage.clear(namespace: id);

    if (clearVisibleState) {
      showLayer = false;
      showBoundaries = true;
      showZones = true;
      showBuildingLines = false;
      opacity = 0.60;
      notifyListeners();
    }
  }

  @override
  Future<void> clearAllCache({bool clearVisibleState = true}) async {
    await clearPersistentCache(clearVisibleState: clearVisibleState);
  }
}