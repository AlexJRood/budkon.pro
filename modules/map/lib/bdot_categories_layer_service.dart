import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

import 'app_map_cacheable_service.dart';
import 'app_map_layer_service.dart';
import 'bdot_category_catalog.dart';
import 'map_layer_state_storage.dart';
import 'map_wms_utils.dart';

class BdotCategoryState {
  final bool enabled;
  final double minZoom;
  final int colorValue;

  const BdotCategoryState({
    required this.enabled,
    required this.minZoom,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  BdotCategoryState copyWith({
    bool? enabled,
    double? minZoom,
    int? colorValue,
  }) {
    return BdotCategoryState(
      enabled: enabled ?? this.enabled,
      minZoom: minZoom ?? this.minZoom,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'minZoom': minZoom,
      'colorValue': colorValue,
    };
  }

  factory BdotCategoryState.fromJson(
    Map<String, dynamic>? json,
    BdotCategoryDefinition def,
  ) {
    final enabledRaw = json?['enabled'];

    final rawMinZoom = (json?['minZoom'] as num?)?.toDouble();
    final minZoom = (rawMinZoom ?? def.defaultMinZoom)
        .clamp(6.0, 20.0)
        .toDouble();

    return BdotCategoryState(
      enabled: enabledRaw is bool ? enabledRaw : def.defaultEnabled,
      minZoom: minZoom,
      colorValue:
          (json?['colorValue'] as num?)?.toInt() ?? def.defaultColor.value,
    );
  }

  factory BdotCategoryState.defaults(BdotCategoryDefinition def) {
    return BdotCategoryState(
      enabled: def.defaultEnabled,
      minZoom: def.defaultMinZoom,
      colorValue: def.defaultColor.value,
    );
  }
}

class BdotCategoriesLayerService extends AppMapLayerService
    implements AppMapCacheableService {
  @override
  final String id;

  BdotCategoriesLayerService({this.id = 'bdot_categories_layer'}) {
    _restoreState();
  }

  String get _stateNamespace => '${id}_state';

  final Map<BdotCategory, BdotCategoryState> _states = {
    for (final def in BdotCategoryCatalog.definitions)
      def.category: BdotCategoryState.defaults(def),
  };

  double opacity = 0.82;
  double tintStrength = 0.26;

  Future<void> _restoreState() async {
    final raw = await MapLayerStateStorage.read(namespace: _stateNamespace) ??
        await MapLayerStateStorage.read(namespace: id);

    if (raw == null) return;

    opacity = ((raw['opacity'] as num?)?.toDouble() ?? 0.82)
        .clamp(0.05, 1.0)
        .toDouble();

    tintStrength = ((raw['tintStrength'] as num?)?.toDouble() ?? 0.26)
        .clamp(0.0, 1.0)
        .toDouble();

    final categories = raw['categories'];

    if (categories is Map) {
      for (final def in BdotCategoryCatalog.definitions) {
        final item = categories[def.id];

        if (item is Map) {
          _states[def.category] = BdotCategoryState.fromJson(
            Map<String, dynamic>.from(item),
            def,
          );
        } else {
          _states[def.category] ??= BdotCategoryState.defaults(def);
        }
      }
    }

    notifyListeners();
  }

  Future<void> _persistState() async {
    final categories = <String, dynamic>{};

    for (final def in BdotCategoryCatalog.definitions) {
      categories[def.id] = stateOf(def.category).toJson();
    }

    await MapLayerStateStorage.write(
      namespace: _stateNamespace,
      data: {
        'opacity': opacity,
        'tintStrength': tintStrength,
        'categories': categories,
      },
    );
  }

  void _saveAndNotify() {
    notifyListeners();
    unawaited(_persistState());
  }

  BdotCategoryState stateOf(BdotCategory category) {
    final existing = _states[category];
    if (existing != null) return existing;

    final def = BdotCategoryCatalog.byCategory(category);
    final fallback = BdotCategoryState.defaults(def);
    _states[category] = fallback;

    return fallback;
  }

  bool isEnabled(BdotCategory category) => stateOf(category).enabled;

  double minZoomOf(BdotCategory category) => stateOf(category).minZoom;

  Color colorOf(BdotCategory category) => stateOf(category).color;

  bool canShow(BdotCategory category, double zoom) {
    final def = BdotCategoryCatalog.byCategory(category);
    final state = stateOf(category);

    return def.isRenderable && state.enabled && zoom >= state.minZoom;
  }

  void setCategoryEnabled(BdotCategory category, bool value) {
    final current = stateOf(category);
    if (current.enabled == value) return;

    _states[category] = current.copyWith(enabled: value);
    _saveAndNotify();
  }

  void setCategoryMinZoom(BdotCategory category, double value) {
    final current = stateOf(category);
    final next = value.clamp(6.0, 20.0).toDouble();

    if (current.minZoom == next) return;

    _states[category] = current.copyWith(minZoom: next);
    _saveAndNotify();
  }

  void setCategoryColor(BdotCategory category, Color color) {
    final current = stateOf(category);

    if (current.colorValue == color.value) return;

    _states[category] = current.copyWith(colorValue: color.value);
    _saveAndNotify();
  }

  void resetCategoryColor(BdotCategory category) {
    final def = BdotCategoryCatalog.byCategory(category);
    final current = stateOf(category);

    if (current.colorValue == def.defaultColor.value) return;

    _states[category] = current.copyWith(
      colorValue: def.defaultColor.value,
    );

    _saveAndNotify();
  }

  void resetCategory(BdotCategory category) {
    final def = BdotCategoryCatalog.byCategory(category);
    _states[category] = BdotCategoryState.defaults(def);
    _saveAndNotify();
  }

  void resetAllCategories() {
    for (final def in BdotCategoryCatalog.definitions) {
      _states[def.category] = BdotCategoryState.defaults(def);
    }

    _saveAndNotify();
  }

  void setOpacity(double value) {
    final next = value.clamp(0.05, 1.0).toDouble();
    if (opacity == next) return;

    opacity = next;
    _saveAndNotify();
  }

  void setTintStrength(double value) {
    final next = value.clamp(0.0, 1.0).toDouble();
    if (tintStrength == next) return;

    tintStrength = next;
    _saveAndNotify();
  }

  void resetSettings() {
    opacity = 0.82;
    tintStrength = 0.26;

    for (final def in BdotCategoryCatalog.definitions) {
      _states[def.category] = BdotCategoryState.defaults(def);
    }

    _saveAndNotify();
  }

  List<BdotCategoryDefinition> activeDefinitions(double zoom) {
    return BdotCategoryCatalog.definitionsInUiOrder.where((def) {
      final state = stateOf(def.category);
      return def.isRenderable && state.enabled && zoom >= state.minZoom;
    }).toList();
  }

  @override
  List<Widget> buildLayers({
    required BuildContext context,
    required WidgetRef ref,
    required MapController mapController,
    required ThemeColors theme,
    required double zoom,
  }) {
    final defs = activeDefinitions(zoom);

    if (defs.isEmpty) {
      return const [];
    }

    return defs.map((def) {
      final state = stateOf(def.category);

      return buildWmsTileLayer(
        baseUrl: def.serviceUrl!,
        layers: def.layers,
        opacity: opacity,
        tintColor: state.color,
        tintStrength: tintStrength,
        layerKey:
            '$id|${def.id}|${def.layers.join(",")}|${opacity.toStringAsFixed(2)}|${tintStrength.toStringAsFixed(2)}|${state.colorValue}|${zoom.floor()}',
      );
    }).toList();
  }

  @override
  String get cacheDisplayName => 'BDOT10k';

  @override
  String get cacheDescription =>
      'Zapis stanu logicznych warstw BDOT10k: włączone kategorie, zoomy, kolory, opacity i tint. Same kafelki WMS nie są tutaj cachowane persistent.';

  @override
  bool get supportsMemoryCache => false;

  @override
  bool get supportsPersistentCache => true;

  int get enabledCategoriesCount {
    return BdotCategoryCatalog.definitions.where((def) {
      return stateOf(def.category).enabled;
    }).length;
  }

  int get renderableEnabledCategoriesCount {
    return BdotCategoryCatalog.definitions.where((def) {
      return def.isRenderable && stateOf(def.category).enabled;
    }).length;
  }

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
          'Aktywnych kategorii BDOT10k: $enabledCategoriesCount, renderowalnych: $renderableEnabledCategoriesCount.',
    );
  }

  @override
  Future<void> clearMemoryCache({bool clearVisibleState = true}) async {}

  @override
  Future<void> clearPersistentCache({bool clearVisibleState = false}) async {
    await MapLayerStateStorage.clear(namespace: _stateNamespace);
    await MapLayerStateStorage.clear(namespace: id);

    if (clearVisibleState) {
      opacity = 0.82;
      tintStrength = 0.26;

      for (final def in BdotCategoryCatalog.definitions) {
        _states[def.category] = BdotCategoryState.defaults(def);
      }

      notifyListeners();
    }
  }

  @override
  Future<void> clearAllCache({bool clearVisibleState = true}) async {
    await clearPersistentCache(clearVisibleState: clearVisibleState);
  }
}