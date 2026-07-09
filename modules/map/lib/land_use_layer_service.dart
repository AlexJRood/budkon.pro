import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:core/theme/apptheme.dart';
import 'package:get/get_utils/get_utils.dart';

import 'app_map_cacheable_service.dart';
import 'app_map_layer_service.dart';
import 'map_geo_service.dart';
import 'map_layer_local_cache.dart';
import 'map_layer_state_storage.dart';
import 'map_wms_utils.dart';

class LandUseLayerService extends AppMapLayerService
    implements AppMapCacheableService {
  @override
  final String id;

  final http.Client client;
  final MapGeoService geo;
  final bool persistentCacheEnabled;
  final Duration cacheTtl;
  final int maxCacheEntries;

  LandUseLayerService({
    required this.client,
    required this.geo,
    this.id = 'land_use_layer',
    this.persistentCacheEnabled = true,
    this.cacheTtl = const Duration(days: 30),
    this.maxCacheEntries = 140,
  }) {
    _restoreState();
  }

  static const String _baseUrl =
      'https://integracja.gugik.gov.pl/cgi-bin/KrajowaIntegracjaUzytkowGruntowych?language=pol';

  String get _stateNamespace => '${id}_state';

  bool showLayer = false;

  bool showPowiaty = true;
  bool showUzytki = true;
  bool showKontury = false;
  bool showKlasouzytki = true;

  double opacity = 0.65;

  double _overviewMinZoom = 9.5;
  double _detailsMinZoom = 15.0;

  double get overviewMinZoom => _overviewMinZoom;
  double get detailsMinZoom => _detailsMinZoom;

  Map<String, String>? selectedInfo;
  bool infoLoading = false;
  String? infoError;

  MapLayerLocalCache? _cache;
  Future<MapLayerLocalCache?>? _cacheFuture;

  final Map<String, Map<String, String>> _memoryInfoCache = {};

  static const int _maxMemoryInfoCacheEntries = 80;

  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _networkFetches = 0;
  DateTime? _lastWarmupAt;

  static const List<String> _fieldOrder = [
    'Identyfikator działki',
    'Numer działki',
    'Województwo',
    'Powiat',
    'Gmina',
    'Obręb',
    'Pole pow. w ewidencji gruntów (ha)',
    'Liczba użytków',
    'Oznaczenie użytku',
    'Oznaczenie konturu',
    'Klasoużytki',
    'Data publikacji danych',
    'Informacje o pochodzeniu danych',
    'Informacje dodatkowe o działce',
  ];

  static const Map<String, String> _fieldLabels = {
    'Identyfikator działki': 'Identyfikator',
    'Numer działki': 'Numer działki',
    'Województwo': 'Województwo',
    'Powiat': 'Powiat',
    'Gmina': 'Gmina',
    'Obręb': 'Obręb',
    'Pole pow. w ewidencji gruntów (ha)': 'Powierzchnia (ha)',
    'Liczba użytków': 'Liczba użytków',
    'Oznaczenie użytku': 'Użytek',
    'Oznaczenie konturu': 'Kontur',
    'Klasoużytki': 'Klasoużytki',
    'Data publikacji danych': 'Data publikacji',
    'Informacje o pochodzeniu danych': 'Pochodzenie danych',
    'Informacje dodatkowe o działce': 'Dodatkowe informacje',
  };

  bool canShowOverview(double zoom) {
    return showLayer &&
        showPowiaty &&
        zoom >= _overviewMinZoom &&
        zoom < _detailsMinZoom;
  }

  bool canShowDetails(double zoom) {
    return showLayer && zoom >= _detailsMinZoom && _activeDetailLayers.isNotEmpty;
  }

  List<String> get _activeDetailLayers {
    final result = <String>[];

    if (showUzytki) {
      result.add('uzytki');
    }

    if (showKontury) {
      result.add('kontury');
    }

    if (showKlasouzytki) {
      result.add('klasouzytki');
    }

    return result;
  }

  List<String> _layersForZoom(double zoom) {
    if (canShowDetails(zoom)) {
      return _activeDetailLayers;
    }

    if (canShowOverview(zoom)) {
      return const ['powiaty'];
    }

    return const [];
  }

  Future<void> _restoreState() async {
    final raw = await MapLayerStateStorage.read(namespace: _stateNamespace);

    if (raw == null) return;

    showLayer = raw['showLayer'] == true;
    showPowiaty = raw['showPowiaty'] != false;
    showUzytki = raw['showUzytki'] != false;
    showKontury = raw['showKontury'] == true;
    showKlasouzytki = raw['showKlasouzytki'] != false;
    opacity = ((raw['opacity'] as num?)?.toDouble() ?? 0.65).clamp(0.0, 1.0);

    _overviewMinZoom =
        ((raw['overviewMinZoom'] as num?)?.toDouble() ?? 9.5)
            .clamp(6.0, 18.5)
            .toDouble();

    _detailsMinZoom =
        ((raw['detailsMinZoom'] as num?)?.toDouble() ?? 15.0)
            .clamp(_overviewMinZoom + 0.5, 20.0)
            .toDouble();

    notifyListeners();
  }

  Future<void> _persistState() async {
    await MapLayerStateStorage.write(
      namespace: _stateNamespace,
      data: {
        'showLayer': showLayer,
        'showPowiaty': showPowiaty,
        'showUzytki': showUzytki,
        'showKontury': showKontury,
        'showKlasouzytki': showKlasouzytki,
        'opacity': opacity,
        'overviewMinZoom': _overviewMinZoom,
        'detailsMinZoom': _detailsMinZoom,
      },
    );
  }

  void _saveAndNotify() {
    notifyListeners();
    unawaited(_persistState());
  }

  void _clearSelectionSilently() {
    selectedInfo = null;
    infoError = null;
    infoLoading = false;
  }

  Future<MapLayerLocalCache?> _ensureCache() async {
    if (!persistentCacheEnabled) return null;
    if (_cache != null) return _cache;

    _cacheFuture ??= () async {
      final cache = await MapLayerLocalCache.create(
        namespace: '${id}_feature_info',
        ttl: cacheTtl,
        maxEntries: maxCacheEntries,
      );

      _cache = cache;
      return cache;
    }();

    return _cacheFuture!;
  }

  void _registerCacheHit() {
    _cacheHits++;
  }

  void _registerCacheMiss() {
    _cacheMisses++;
  }

  void _registerNetworkFetch() {
    _networkFetches++;
    _lastWarmupAt = DateTime.now();
  }

  int _snapMetric(double value, double step) {
    return (value / step).round();
  }

  String _buildInfoRequestKey({
    required double minX,
    required double minY,
    required double maxX,
    required double maxY,
    required int width,
    required int height,
    required int i,
    required int j,
    required List<String> detailLayers,
  }) {
    final safeWidth = width <= 0 ? 1 : width;
    final safeHeight = height <= 0 ? 1 : height;

    final x = minX + (((i + 0.5) / safeWidth) * (maxX - minX));
    final y = maxY - (((j + 0.5) / safeHeight) * (maxY - minY));

    const snapMeters = 2.0;

    return [
      id,
      'land_use_feature_info',
      detailLayers.join(','),
      _snapMetric(x, snapMeters).toString(),
      _snapMetric(y, snapMeters).toString(),
    ].join('|');
  }

  Future<Map<String, String>?> _readCachedInfo(String key) async {
    final memory = _memoryInfoCache[key];

    if (memory != null && memory.isNotEmpty) {
      _registerCacheHit();
      return memory;
    }

    final cache = await _ensureCache();
    final entry = await cache?.read(key, touch: true);

    if (entry == null || entry.isExpired) {
      _registerCacheMiss();
      return null;
    }

    final raw = entry.data['fields'];
    if (raw is! Map) {
      _registerCacheMiss();
      return null;
    }

    final fields = <String, String>{};

    raw.forEach((k, v) {
      final fieldKey = k.toString().trim();
      final value = v.toString().trim();

      if (fieldKey.isNotEmpty && value.isNotEmpty) {
        fields[fieldKey] = value;
      }
    });

    if (fields.isEmpty) {
      _registerCacheMiss();
      return null;
    }

    _setCachedInfo(key, fields);
    _registerCacheHit();

    return fields;
  }

  void _setCachedInfo(String key, Map<String, String> fields) {
    if (_memoryInfoCache.length >= _maxMemoryInfoCacheEntries) {
      _memoryInfoCache.remove(_memoryInfoCache.keys.first);
    }
    _memoryInfoCache[key] = fields;
  }

  Future<void> _writeCachedInfo(String key, Map<String, String> fields) async {
    if (fields.isEmpty) return;

    _setCachedInfo(key, fields);

    final cache = await _ensureCache();

    await cache?.write(
      key,
      {
        'fields': fields,
      },
    );
  }

  void setShowLayer(bool value) {
    if (showLayer == value) return;

    showLayer = value;

    if (!value) {
      _clearSelectionSilently();
    }

    _saveAndNotify();
  }

  void setShowPowiaty(bool value) {
    if (showPowiaty == value) return;
    showPowiaty = value;
    _saveAndNotify();
  }

  void setShowUzytki(bool value) {
    if (showUzytki == value) return;
    showUzytki = value;

    if (_activeDetailLayers.isEmpty) {
      _clearSelectionSilently();
    }

    _saveAndNotify();
  }

  void setShowKontury(bool value) {
    if (showKontury == value) return;
    showKontury = value;

    if (_activeDetailLayers.isEmpty) {
      _clearSelectionSilently();
    }

    _saveAndNotify();
  }

  void setShowKlasouzytki(bool value) {
    if (showKlasouzytki == value) return;
    showKlasouzytki = value;

    if (_activeDetailLayers.isEmpty) {
      _clearSelectionSilently();
    }

    _saveAndNotify();
  }

  void setOpacity(double value) {
    final next = value.clamp(0.05, 1.0).toDouble();
    if (opacity == next) return;
    opacity = next;
    _saveAndNotify();
  }

  void setOverviewMinZoom(double value) {
    final next = value.clamp(6.0, 18.5).toDouble();

    _overviewMinZoom = next;

    if (_detailsMinZoom <= _overviewMinZoom) {
      _detailsMinZoom = (_overviewMinZoom + 0.5).clamp(6.5, 20.0).toDouble();
    }

    _saveAndNotify();
  }

  void setDetailsMinZoom(double value) {
    final minAllowed = (_overviewMinZoom + 0.5).clamp(6.5, 20.0).toDouble();
    _detailsMinZoom = value.clamp(minAllowed, 20.0).toDouble();

    _saveAndNotify();
  }

  void clearSelection() {
    _clearSelectionSilently();
    notifyListeners();
  }

  void resetSettings() {
    showLayer = false;
    showPowiaty = true;
    showUzytki = true;
    showKontury = false;
    showKlasouzytki = true;
    opacity = 0.65;
    _overviewMinZoom = 9.5;
    _detailsMinZoom = 15.0;
    _clearSelectionSilently();
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
    if (!showLayer) return const [];

    final layers = _layersForZoom(zoom);
    if (layers.isEmpty) return const [];

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
  Future<bool> onTap({
    required WidgetRef ref,
    required MapController mapController,
    required TapPosition tapPosition,
  }) async {
    if (!showLayer) return false;
    if (!canShowDetails(mapController.camera.zoom)) return false;

    final relative = tapPosition.relative;
    if (relative == null) return false;

    final detailLayers = _activeDetailLayers;
    if (detailLayers.isEmpty) return false;

    infoLoading = true;
    infoError = null;
    notifyListeners();

    try {
      final camera = mapController.camera;
      final bounds = camera.visibleBounds;

      final sw = geo.latLngToWebMercator(bounds.southWest);
      final ne = geo.latLngToWebMercator(bounds.northEast);

      final minX = sw.dx < ne.dx ? sw.dx : ne.dx;
      final minY = sw.dy < ne.dy ? sw.dy : ne.dy;
      final maxX = sw.dx > ne.dx ? sw.dx : ne.dx;
      final maxY = sw.dy > ne.dy ? sw.dy : ne.dy;

      final bbox = '$minX,$minY,$maxX,$maxY';

      final width = camera.size.width.round();
      final height = camera.size.height.round();

      if (width <= 0 || height <= 0) {
        throw Exception('invalid_map_size_for_get_feature_info'.tr);
      }

      final i = relative.dx.round().clamp(0, width - 1).toInt();
      final j = relative.dy.round().clamp(0, height - 1).toInt();

      final cacheKey = _buildInfoRequestKey(
        minX: minX,
        minY: minY,
        maxX: maxX,
        maxY: maxY,
        width: width,
        height: height,
        i: i,
        j: j,
        detailLayers: detailLayers,
      );

      final cached = await _readCachedInfo(cacheKey);

      if (cached != null && cached.isNotEmpty) {
        selectedInfo = cached;
        infoError = null;
        infoLoading = false;
        notifyListeners();

        return true;
      }

      final uri = Uri.parse(
        'https://integracja.gugik.gov.pl/cgi-bin/KrajowaIntegracjaUzytkowGruntowych',
      ).replace(
        queryParameters: {
          'language': 'pol',
          'SERVICE': 'WMS',
          'VERSION': '1.3.0',
          'REQUEST': 'GetFeatureInfo',
          'LAYERS': detailLayers.join(','),
          'QUERY_LAYERS': detailLayers.join(','),
          'STYLES': List.filled(detailLayers.length, 'default').join(','),
          'CRS': 'EPSG:3857',
          'BBOX': bbox,
          'WIDTH': width.toString(),
          'HEIGHT': height.toString(),
          'I': i.toString(),
          'J': j.toString(),
          'INFO_FORMAT': 'text/xml',
          'FEATURE_COUNT': '10',
          'FORMAT': 'image/png',
          'TRANSPARENT': 'true',
        },
      );

      _registerNetworkFetch();

      final response = await client.get(uri).timeout(
            const Duration(seconds: 12),
          );

      if (response.statusCode != 200) {
        throw Exception('GetFeatureInfo failed: ${response.statusCode}');
      }

      final rawBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      final fields = _extractFeatureInfoFields(rawBody);

      if (fields.isNotEmpty) {
        await _writeCachedInfo(cacheKey, fields);
      }

      selectedInfo = fields.isEmpty ? null : fields;
      infoError = fields.isEmpty ? 'no_data_found_for_selected_location'.tr : null;
      infoLoading = false;
      notifyListeners();

      return fields.isNotEmpty;
    } catch (e) {
      infoError = e.toString();
      selectedInfo = null;
      infoLoading = false;
      notifyListeners();

      return false;
    }
  }

  Map<String, String> _extractFeatureInfoFields(String raw) {
    final result = <String, String>{};

    String decodeBasicEntities(String value) {
      return value
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .trim();
    }

    String stripHtml(String value) {
      return value.replaceAll(RegExp(r'<[^>]+>', dotAll: true), '').trim();
    }

    final xmlAttrRegExp = RegExp(
      r'<Attribute\s+Name="([^"]+)">(.*?)</Attribute>',
      caseSensitive: false,
      dotAll: true,
    );

    for (final match in xmlAttrRegExp.allMatches(raw)) {
      final key = decodeBasicEntities(match.group(1) ?? '').trim();

      var value = match.group(2) ?? '';

      value = value.replaceAllMapped(
        RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true),
        (m) => m.group(1) ?? '',
      );

      value = decodeBasicEntities(stripHtml(value));

      if (key.isNotEmpty && value.isNotEmpty) {
        result[key] = value;
      }
    }

    if (result.isNotEmpty) {
      return result;
    }

    final htmlRowRegExp = RegExp(
      r'<tr>\s*<th[^>]*>(.*?)</th>\s*<td[^>]*>(.*?)</td>\s*</tr>',
      caseSensitive: false,
      dotAll: true,
    );

    for (final match in htmlRowRegExp.allMatches(raw)) {
      final key = decodeBasicEntities(stripHtml(match.group(1) ?? ''));
      final value = decodeBasicEntities(stripHtml(match.group(2) ?? ''));

      if (key.isNotEmpty && value.isNotEmpty) {
        result[key] = value;
      }
    }

    return result;
  }

  String _normalizeText(String value) {
    return value
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _fieldLabel(String key) => _fieldLabels[key] ?? key;

  List<MapEntry<String, String>> _orderedEntries() {
    final source = selectedInfo ?? {};
    final normalized = <String, String>{};

    source.forEach((key, value) {
      final normalizedKey = _normalizeText(key);
      final normalizedValue = _normalizeText(value);

      if (normalizedKey.isNotEmpty && normalizedValue.isNotEmpty) {
        normalized[normalizedKey] = normalizedValue;
      }
    });

    final ordered = <MapEntry<String, String>>[];

    for (final key in _fieldOrder) {
      final value = normalized.remove(key);

      if (value != null && value.isNotEmpty) {
        ordered.add(MapEntry(key, value));
      }
    }

    final remaining = normalized.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    ordered.addAll(remaining);

    return ordered;
  }

  Widget _buildInfoRow(String key, String value, ThemeColors theme) {
    final isLongText = value.length > 80;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: TextStyle(
              color: theme.textColor.withAlpha(180),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontSize: isLongText ? 13 : 14,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  List<Widget> buildOverlays({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeColors theme,
  }) {
    if (!infoLoading &&
        infoError == null &&
        (selectedInfo == null || selectedInfo!.isEmpty)) {
      return const [];
    }

    final orderedEntries = _orderedEntries();

    return [
      SafeArea(
        minimum: const EdgeInsets.only(top: 16, right: 16),
        child: Align(
          alignment: Alignment.topRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 390,
              constraints: const BoxConstraints(maxHeight: 560),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.dashboardContainer.withAlpha(245),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withAlpha(35)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 14,
                    color: Colors.black26,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: infoLoading
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'loading_land_use_data'.tr,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      ],
                    )
                  : infoError != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'land_use'.tr,
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: clearSelection,
                                  icon: Icon(
                                    Icons.close,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              infoError!,
                              style: TextStyle(color: theme.textColor),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.terrain_rounded,
                                  color: theme.themeColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'land_use'.tr,
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: clearSelection,
                                  icon: Icon(
                                    Icons.close,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Flexible(
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: orderedEntries
                                        .map(
                                          (entry) => _buildInfoRow(
                                            _fieldLabel(entry.key),
                                            entry.value,
                                            theme,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  String get cacheDisplayName => 'Użytki gruntowe / GetFeatureInfo';

  @override
  String get cacheDescription =>
      'Cache odpowiedzi GetFeatureInfo dla kliknięć w warstwę użytków gruntowych oraz zapis ustawień warstwy. Raster WMS nie jest tutaj cachowany persistent.';

  @override
  bool get supportsMemoryCache => true;

  @override
  bool get supportsPersistentCache => persistentCacheEnabled;

  @override
  Future<AppMapCacheSummary> getCacheSummary() async {
    final cache = await _ensureCache();
    final stats = await cache?.stats();
    final stateStats =
        await MapLayerStateStorage.stats(namespace: _stateNamespace);

    final persistentBytes = (stats?.approxBytes ?? 0) + stateStats.approxBytes;
    final persistentEntries = (stats?.entries ?? 0) + (stateStats.exists ? 1 : 0);

    return AppMapCacheSummary(
      memoryEntries: _memoryInfoCache.length,
      persistentEntries: persistentEntries,
      approxBytes: persistentBytes,
      memoryBytes: null,
      persistentBytes: persistentBytes,
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
      networkFetches: _networkFetches,
      lastWarmupAt: _lastWarmupAt,
      note:
          'Cache działa po realnym punkcie mapy w EPSG:3857 zaokrąglonym do kilku metrów oraz zapisuje ustawienia warstwy.',
    );
  }

  @override
  Future<void> clearMemoryCache({bool clearVisibleState = true}) async {
    _memoryInfoCache.clear();

    if (clearVisibleState) {
      clearSelection();
    }
  }

  @override
  Future<void> clearPersistentCache({bool clearVisibleState = false}) async {
    final cache = await _ensureCache();
    await cache?.clear();

    await MapLayerStateStorage.clear(namespace: _stateNamespace);

    if (clearVisibleState) {
      showLayer = false;
      showPowiaty = true;
      showUzytki = true;
      showKontury = false;
      showKlasouzytki = true;
      opacity = 0.65;
      _overviewMinZoom = 9.5;
      _detailsMinZoom = 15.0;
      clearSelection();
    }
  }

  @override
  Future<void> clearAllCache({bool clearVisibleState = true}) async {
    _memoryInfoCache.clear();

    final cache = await _ensureCache();
    await cache?.clear();

    await MapLayerStateStorage.clear(namespace: _stateNamespace);

    _cacheHits = 0;
    _cacheMisses = 0;
    _networkFetches = 0;
    _lastWarmupAt = null;

    if (clearVisibleState) {
      showLayer = false;
      showPowiaty = true;
      showUzytki = true;
      showKontury = false;
      showKlasouzytki = true;
      opacity = 0.65;
      _overviewMinZoom = 9.5;
      _detailsMinZoom = 15.0;
      clearSelection();
    }
  }
}