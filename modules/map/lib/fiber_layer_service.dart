import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

import 'app_map_cacheable_service.dart';
import 'app_map_layer_service.dart';
import 'map_layer_state_storage.dart';
import 'map_wms_utils.dart';

class FiberLayerService extends AppMapLayerService
    implements AppMapCacheableService {
  @override
  final String id;

  FiberLayerService({this.id = 'fiber_layer'}) {
    _restoreState();
  }

  // internet.gov.pl — publiczny GeoServer bez autoryzacji
  // GetCapabilities: https://internet.gov.pl/geoserver/public/wms?SERVICE=WMS&REQUEST=GetCapabilities
  // Dane SIDUSIS (MF/IL-PIB): zasięg szerokopasmowy wg punktów adresowych i budynków
  static const String _baseUrl =
      'https://internet.gov.pl/geoserver/public/wms?';

  // Dostępne publiczne warstwy
  static const String _layerAddressPoints = 'public:address_points';
  static const String _layerBuildings = 'public:buildings';
  static const String _layerSimba2 = 'public:simba2';

  String get _stateNamespace => '${id}_state';

  // Minimum zoom for each layer (based on WMS MaxScaleDenominator):
  //   buildings:       scale ≤ 54168  ≈ zoom 14
  //   address_points:  scale ≤  2500  ≈ zoom 17
  //   simba2:          scale ≤  2500  ≈ zoom 17
  static const double _buildingsMinZoom = 14.0;
  static const double _detailMinZoom = 17.0;

  bool showLayer = false;
  bool showAddressPoints = true;
  bool showBuildings = false;
  bool showSimba2 = false;
  double opacity = 0.75;
  double minZoom = 14.0;

  bool canShow(double zoom) => zoom >= minZoom;

  Future<void> _restoreState() async {
    final raw = await MapLayerStateStorage.read(namespace: _stateNamespace) ??
        await MapLayerStateStorage.read(namespace: id);

    if (raw == null) return;

    showLayer = raw['showLayer'] == true;
    showAddressPoints = raw['showAddressPoints'] != false;
    showBuildings = raw['showBuildings'] == true;
    showSimba2 = raw['showSimba2'] == true;
    opacity = ((raw['opacity'] as num?)?.toDouble() ?? 0.75)
        .clamp(0.05, 1.0)
        .toDouble();
    minZoom = ((raw['minZoom'] as num?)?.toDouble() ?? 14.0)
        .clamp(6.0, 18.0)
        .toDouble();

    notifyListeners();
  }

  Future<void> _persistState() async {
    await MapLayerStateStorage.write(
      namespace: _stateNamespace,
      data: {
        'showLayer': showLayer,
        'showAddressPoints': showAddressPoints,
        'showBuildings': showBuildings,
        'showSimba2': showSimba2,
        'opacity': opacity,
        'minZoom': minZoom,
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

  void setShowAddressPoints(bool value) {
    if (showAddressPoints == value) return;
    showAddressPoints = value;
    _saveAndNotify();
  }

  void setShowBuildings(bool value) {
    if (showBuildings == value) return;
    showBuildings = value;
    _saveAndNotify();
  }

  void setShowSimba2(bool value) {
    if (showSimba2 == value) return;
    showSimba2 = value;
    _saveAndNotify();
  }

  void setOpacity(double value) {
    final next = value.clamp(0.05, 1.0).toDouble();
    if (opacity == next) return;
    opacity = next;
    _saveAndNotify();
  }

  void setMinZoom(double value) {
    final next = value.clamp(6.0, 18.0).toDouble();
    if (minZoom == next) return;
    minZoom = next;
    _saveAndNotify();
  }

  void resetSettings() {
    showLayer = false;
    showAddressPoints = true;
    showBuildings = false;
    showSimba2 = false;
    opacity = 0.75;
    minZoom = 14.0;
    _saveAndNotify();
  }

  /// Returns only layers visible at the current zoom level.
  /// internet.gov.pl WMS honours MaxScaleDenominator per layer, so requesting
  /// detail layers at low zoom returns blank tiles — we skip them entirely.
  List<String> _activeLayers(double zoom) {
    final layers = <String>[];
    if (showBuildings && zoom >= _buildingsMinZoom) {
      layers.add(_layerBuildings);
    }
    if (showSimba2 && zoom >= _detailMinZoom) {
      layers.add(_layerSimba2);
    }
    if (showAddressPoints && zoom >= _detailMinZoom) {
      layers.add(_layerAddressPoints);
    }
    return layers;
  }

  @override
  List<Widget> buildLayers({
    required BuildContext context,
    required WidgetRef ref,
    required MapController mapController,
    required ThemeColors theme,
    required double zoom,
  }) {
    if (!showLayer || !canShow(zoom)) return const [];

    final layers = _activeLayers(zoom);
    if (layers.isEmpty) return const [];

    // Style names must match layer names — internet.gov.pl rejects 'default'.
    final layerStyles = layers.toList();

    return [
      buildWmsTileLayer(
        baseUrl: _baseUrl,
        layers: layers,
        styles: layerStyles,
        opacity: opacity,
        layerKey:
            '$id|${layers.join(",")}|${opacity.toStringAsFixed(2)}|${zoom.floor()}',
      ),
    ];
  }

  @override
  String get cacheDisplayName => 'Zasięg szerokopasmowy / internet.gov.pl';

  @override
  String get cacheDescription =>
      'Zapis ustawień warstwy zasięgu internetu szerokopasmowego (SIDUSIS / internet.gov.pl) do local storage.';

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
          'Cache obejmuje zapisane ustawienia warstwy. Kafelki WMS cachowane przez tile provider.',
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
      showAddressPoints = true;
      showBuildings = false;
      showSimba2 = false;
      opacity = 0.75;
      minZoom = 10.0;
      notifyListeners();
    }
  }

  @override
  Future<void> clearAllCache({bool clearVisibleState = true}) async {
    await clearPersistentCache(clearVisibleState: clearVisibleState);
  }
}
