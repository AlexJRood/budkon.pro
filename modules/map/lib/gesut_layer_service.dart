import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

import 'app_map_cacheable_service.dart';
import 'app_map_layer_service.dart';
import 'map_layer_state_storage.dart';
import 'map_wms_utils.dart';

class GesutLayerService extends AppMapLayerService
    implements AppMapCacheableService {
  @override
  final String id;

  GesutLayerService({this.id = 'gesut_layer'}) {
    _restoreState();
  }

  static const String _baseUrl =
      'https://integracja.gugik.gov.pl/cgi-bin/KrajowaIntegracjaUzbrojeniaTerenu?';

  String get _stateNamespace => '${id}_state';

  bool showLayer = false;
  bool showWater = true;
  bool showSewer = true;
  bool showGas = false;
  bool showPower = false;
  bool showTelecom = false;
  bool showHeat = false;
  bool showDevices = false;
  double opacity = 0.85;

  bool canShow(double zoom) => zoom >= 17.0;

  Future<void> _restoreState() async {
    final raw = await MapLayerStateStorage.read(namespace: _stateNamespace) ??
        await MapLayerStateStorage.read(namespace: id);

    if (raw == null) return;

    showLayer = raw['showLayer'] == true;
    showWater = raw['showWater'] != false;
    showSewer = raw['showSewer'] != false;
    showGas = raw['showGas'] == true;
    showPower = raw['showPower'] == true;
    showTelecom = raw['showTelecom'] == true;
    showHeat = raw['showHeat'] == true;
    showDevices = raw['showDevices'] == true;
    opacity = ((raw['opacity'] as num?)?.toDouble() ?? 0.85)
        .clamp(0.05, 1.0)
        .toDouble();

    notifyListeners();
  }

  Future<void> _persistState() async {
    await MapLayerStateStorage.write(
      namespace: _stateNamespace,
      data: {
        'showLayer': showLayer,
        'showWater': showWater,
        'showSewer': showSewer,
        'showGas': showGas,
        'showPower': showPower,
        'showTelecom': showTelecom,
        'showHeat': showHeat,
        'showDevices': showDevices,
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

  void setShowWater(bool value) {
    if (showWater == value) return;
    showWater = value;
    _saveAndNotify();
  }

  void setShowSewer(bool value) {
    if (showSewer == value) return;
    showSewer = value;
    _saveAndNotify();
  }

  void setShowGas(bool value) {
    if (showGas == value) return;
    showGas = value;
    _saveAndNotify();
  }

  void setShowPower(bool value) {
    if (showPower == value) return;
    showPower = value;
    _saveAndNotify();
  }

  void setShowTelecom(bool value) {
    if (showTelecom == value) return;
    showTelecom = value;
    _saveAndNotify();
  }

  void setShowHeat(bool value) {
    if (showHeat == value) return;
    showHeat = value;
    _saveAndNotify();
  }

  void setShowDevices(bool value) {
    if (showDevices == value) return;
    showDevices = value;
    _saveAndNotify();
  }

  void setOpacity(double value) {
    final next = value.clamp(0.05, 1.0).toDouble();
    if (opacity == next) return;

    opacity = next;
    _saveAndNotify();
  }

  void resetSettings() {
    showLayer = false;
    showWater = true;
    showSewer = true;
    showGas = false;
    showPower = false;
    showTelecom = false;
    showHeat = false;
    showDevices = false;
    opacity = 0.85;
    _saveAndNotify();
  }

  List<String> _layers() {
    final layers = <String>[];

    if (showWater) {
      layers.add('przewod_wodociagowy');
    }

    if (showSewer) {
      layers.add('przewod_kanalizacyjny');
    }

    if (showGas) {
      layers.add('przewod_gazowy');
    }

    if (showPower) {
      layers.add('przewod_elektroenergetyczny');
    }

    if (showTelecom) {
      layers.add('przewod_telekomunikacyjny');
    }

    if (showHeat) {
      layers.add('przewod_cieplowniczy');
    }

    if (showDevices) {
      layers.add('przewod_urzadzenia');
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
  String get cacheDisplayName => 'GESUT';

  @override
  String get cacheDescription =>
      'Zapis stanu warstwy GESUT do local storage. Same kafelki WMS nie są tutaj cachowane persistent.';

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
          'Cache GESUT obejmuje zapisane ustawienia warstwy. Raster WMS wymaga osobnego tile-cache providera.',
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
      showWater = true;
      showSewer = true;
      showGas = false;
      showPower = false;
      showTelecom = false;
      showHeat = false;
      showDevices = false;
      opacity = 0.85;
      notifyListeners();
    }
  }

  @override
  Future<void> clearAllCache({bool clearVisibleState = true}) async {
    await clearPersistentCache(clearVisibleState: clearVisibleState);
  }
}