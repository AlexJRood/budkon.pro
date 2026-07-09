import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

import 'app_map_cacheable_service.dart';
import 'app_map_layer_service.dart';
import 'map_layer_state_storage.dart';
import 'map_wms_utils.dart';

class BdotLayerService extends AppMapLayerService
    implements AppMapCacheableService {
  @override
  final String id;

  BdotLayerService({this.id = 'bdot_layer'}) {
    _restoreState();
  }

  static const String _baseUrl =
      'https://integracja.gugik.gov.pl/cgi-bin/KrajowaIntegracjaBazDanychObiektowTopograficznych?language=pol';

  String get _stateNamespace => '${id}_state';

  bool showLayer = false;
  bool showImplementations = true;
  bool showBdot = true;
  double opacity = 0.82;

  double _implementationsMinZoom = 8.5;
  double _bdotMinZoom = 14.0;

  double get implementationsMinZoom => _implementationsMinZoom;
  double get bdotMinZoom => _bdotMinZoom;

  bool canShowImplementations(double zoom) {
    return showLayer &&
        showImplementations &&
        zoom >= _implementationsMinZoom &&
        zoom < _bdotMinZoom;
  }

  bool canShowBdot(double zoom) {
    return showLayer && showBdot && zoom >= _bdotMinZoom;
  }

  Future<void> _restoreState() async {
    final raw = await MapLayerStateStorage.read(namespace: _stateNamespace) ??
        await MapLayerStateStorage.read(namespace: id);

    if (raw == null) return;

    showLayer = raw['showLayer'] == true;
    showImplementations = raw['showImplementations'] != false;
    showBdot = raw['showBdot'] != false;

    opacity = ((raw['opacity'] as num?)?.toDouble() ?? 0.82)
        .clamp(0.05, 1.0)
        .toDouble();

    _implementationsMinZoom =
        ((raw['implementationsMinZoom'] as num?)?.toDouble() ?? 8.5)
            .clamp(6.0, 19.5)
            .toDouble();

    _bdotMinZoom = ((raw['bdotMinZoom'] as num?)?.toDouble() ?? 14.0)
        .clamp(6.5, 20.0)
        .toDouble();

    if (_bdotMinZoom <= _implementationsMinZoom) {
      _bdotMinZoom =
          (_implementationsMinZoom + 0.5).clamp(6.5, 20.0).toDouble();
    }

    notifyListeners();
  }

  Future<void> _persistState() async {
    await MapLayerStateStorage.write(
      namespace: _stateNamespace,
      data: {
        'showLayer': showLayer,
        'showImplementations': showImplementations,
        'showBdot': showBdot,
        'opacity': opacity,
        'implementationsMinZoom': _implementationsMinZoom,
        'bdotMinZoom': _bdotMinZoom,
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

  void setShowImplementations(bool value) {
    if (showImplementations == value) return;
    showImplementations = value;
    _saveAndNotify();
  }

  void setShowBdot(bool value) {
    if (showBdot == value) return;
    showBdot = value;
    _saveAndNotify();
  }

  void setOpacity(double value) {
    final next = value.clamp(0.05, 1.0).toDouble();
    if (opacity == next) return;

    opacity = next;
    _saveAndNotify();
  }

  void setImplementationsMinZoom(double value) {
    final next = value.clamp(6.0, 19.5).toDouble();
    if (_implementationsMinZoom == next) return;

    _implementationsMinZoom = next;

    if (_bdotMinZoom <= _implementationsMinZoom) {
      _bdotMinZoom =
          (_implementationsMinZoom + 0.5).clamp(6.5, 20.0).toDouble();
    }

    _saveAndNotify();
  }

  void setBdotMinZoom(double value) {
    final minAllowed = (_implementationsMinZoom + 0.5)
        .clamp(6.5, 20.0)
        .toDouble();

    final next = value.clamp(minAllowed, 20.0).toDouble();
    if (_bdotMinZoom == next) return;

    _bdotMinZoom = next;
    _saveAndNotify();
  }

  void resetSettings() {
    showLayer = false;
    showImplementations = true;
    showBdot = true;
    opacity = 0.82;
    _implementationsMinZoom = 8.5;
    _bdotMinZoom = 14.0;
    _saveAndNotify();
  }

  List<String> _layersForZoom(double zoom) {
    if (showBdot && zoom >= _bdotMinZoom) {
      return const ['bdot'];
    }

    if (showImplementations && zoom >= _implementationsMinZoom) {
      return const ['wdrozenia'];
    }

    return const [];
  }

  @override
  List<Widget> buildLayers({
    required BuildContext context,
    required WidgetRef ref,
    required MapController mapController,
    required ThemeColors theme,
    required double zoom,
  }) {
    if (!showLayer) {
      return const [];
    }

    final layers = _layersForZoom(zoom);
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
  String get cacheDisplayName => 'BDOT';

  @override
  String get cacheDescription =>
      'Zapis stanu warstwy BDOT do local storage. Same kafelki WMS nie są tutaj cachowane persistent.';

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
          'Cache BDOT obejmuje zapisane ustawienia warstwy. Raster WMS wymaga osobnego tile-cache providera.',
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
      showImplementations = true;
      showBdot = true;
      opacity = 0.82;
      _implementationsMinZoom = 8.5;
      _bdotMinZoom = 14.0;
      notifyListeners();
    }
  }

  @override
  Future<void> clearAllCache({bool clearVisibleState = true}) async {
    await clearPersistentCache(clearVisibleState: clearVisibleState);
  }
}