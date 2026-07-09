import 'dart:convert';

import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:core/theme/apptheme.dart';
import 'package:get/get_utils/get_utils.dart';

import 'app_map_cacheable_service.dart';
import 'app_map_layer_service.dart';
import 'map_geo_service.dart';
import 'map_layer_local_cache.dart';
import 'map_wms_utils.dart';

class ParcelLayerService extends AppMapLayerService
    implements AppMapCacheableService {
  @override
  final String id;

  final http.Client client;
  final MapGeoService geo;
  final bool persistentCacheEnabled;
  final Duration cacheTtl;
  final int maxCacheEntries;

  ParcelLayerService({
    required this.client,
    required this.geo,
    this.id = 'parcel_layer',
    this.persistentCacheEnabled = true,
    this.cacheTtl = const Duration(days: 30),
    this.maxCacheEntries = 120,
  });

  static const String _baseUrl =
      'https://integracja.gugik.gov.pl/cgi-bin/KrajowaIntegracjaEwidencjiGruntow?language=pol';

  static const String _uldkBaseUrl = 'https://uldk.gugik.gov.pl/';

  bool showBoundaries = true;
  double opacity = 0.75;

  double _precinctsMinZoom = 12.0;
  double _detailsMinZoom = 15.5;

  double get precinctsMinZoom => _precinctsMinZoom;
  double get detailsMinZoom => _detailsMinZoom;

  Map<String, String>? selectedInfo;
  bool infoLoading = false;
  String? infoError;

  MapLayerLocalCache? _cache;
  Future<MapLayerLocalCache?>? _cacheFuture;

  final Map<String, Map<String, String>> _memoryInfoCache = {};
  final Map<String, List<List<LatLng>>> _parcelGeometryCache = {};

  static const int _maxMemoryInfoCacheEntries = 80;
  static const int _maxParcelGeometryCacheEntries = 30;

  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _networkFetches = 0;
  DateTime? _lastWarmupAt;

  List<List<LatLng>>? _selectedParcelGeometry;

  static const List<String> _fieldOrder = [
    'Identyfikator działki',
    'Numer działki',
    'Województwo',
    'Powiat',
    'Gmina',
    'Obręb',
    'Pole pow. w ewidencji gruntów (ha)',
    'Grupa rejestrowa',
    'Oznaczenie użytku',
    'Oznaczenie konturu',
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
    'Grupa rejestrowa': 'Grupa rejestrowa',
    'Oznaczenie użytku': 'Użytek',
    'Oznaczenie konturu': 'Kontur',
    'Data publikacji danych': 'Data publikacji',
    'Informacje o pochodzeniu danych': 'Pochodzenie danych',
    'Informacje dodatkowe o działce': 'Dodatkowe informacje',
  };

  bool canShowDetails(double zoom) => zoom >= _detailsMinZoom;

  bool canShowPrecincts(double zoom) =>
      zoom >= _precinctsMinZoom && zoom < _detailsMinZoom;

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

  void setPrecinctsMinZoom(double value) {
    final next = value.clamp(8.0, 19.5).toDouble();
    _precinctsMinZoom = next;

    if (_detailsMinZoom <= _precinctsMinZoom) {
      _detailsMinZoom = (_precinctsMinZoom + 0.5).clamp(8.5, 20.0).toDouble();
    }

    notifyListeners();
  }

  void setDetailsMinZoom(double value) {
    final minAllowed = (_precinctsMinZoom + 0.5).clamp(8.5, 20.0).toDouble();
    _detailsMinZoom = value.clamp(minAllowed, 20.0).toDouble();

    notifyListeners();
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
  }) {
    final safeWidth = width <= 0 ? 1 : width;
    final safeHeight = height <= 0 ? 1 : height;

    final x = minX + (((i + 0.5) / safeWidth) * (maxX - minX));
    final y = maxY - (((j + 0.5) / safeHeight) * (maxY - minY));

    const snapMeters = 2.0;

    return [
      id,
      'parcel_feature_info',
      _snapMetric(x, snapMeters).toString(),
      _snapMetric(y, snapMeters).toString(),
    ].join('|');
  }

  void setShowBoundaries(bool value) {
    showBoundaries = value;

    if (!value) {
      selectedInfo = null;
      infoError = null;
      _selectedParcelGeometry = null;
    }

    notifyListeners();
  }

  void setOpacity(double value) {
    opacity = value;
    notifyListeners();
  }

  void clearSelection() {
    selectedInfo = null;
    infoError = null;
    infoLoading = false;
    _selectedParcelGeometry = null;
    notifyListeners();
  }

  @override
  List<Widget> buildLayers({
    required BuildContext context,
    required WidgetRef ref,
    required MapController mapController,
    required ThemeColors theme,
    required double zoom,
  }) {
    if (!showBoundaries) {
      return const [];
    }

    final layers = canShowDetails(zoom)
        ? const ['dzialki']
        : canShowPrecincts(zoom)
            ? const ['obreby']
            : const <String>[];

    if (layers.isEmpty) {
      return const [];
    }

    final result = <Widget>[
      buildWmsTileLayer(
        baseUrl: _baseUrl,
        layers: layers,
        opacity: opacity,
        layerKey:
            '$id|${layers.join(",")}|${opacity.toStringAsFixed(2)}|${zoom.floor()}',
      ),
    ];

    final highlightedPolygons = _buildHighlightedParcelPolygons(theme);

    if (highlightedPolygons.isNotEmpty) {
      result.add(
        PolygonLayer(
          polygons: highlightedPolygons,
        ),
      );
    }

    return result;
  }

  @override
  Future<bool> onTap({
    required WidgetRef ref,
    required MapController mapController,
    required TapPosition tapPosition,
  }) async {
    if (!showBoundaries) return false;
    if (!canShowDetails(mapController.camera.zoom)) return false;

    infoLoading = true;
    infoError = null;
    _selectedParcelGeometry = null;
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

      final relative = tapPosition.relative;
      if (relative == null) {
        throw Exception('TapPosition.relative is null');
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
      );

      final cached = await _readCachedInfo(cacheKey);

      if (cached != null && cached.isNotEmpty) {
        selectedInfo = cached;
        infoError = null;

        final parcelId = (cached['Identyfikator działki'] ?? '').trim();

        if (parcelId.isNotEmpty) {
          try {
            await _loadSelectedParcelGeometry(parcelId, notify: false);
          } catch (_) {
            _selectedParcelGeometry = null;
          }
        }

        infoLoading = false;
        notifyListeners();

        return true;
      }

      final uri = Uri.parse(
        'https://integracja.gugik.gov.pl/cgi-bin/KrajowaIntegracjaEwidencjiGruntow',
      ).replace(
        queryParameters: {
          'language': 'pol',
          'SERVICE': 'WMS',
          'VERSION': '1.3.0',
          'REQUEST': 'GetFeatureInfo',
          'LAYERS': 'dzialki,numery_dzialek',
          'QUERY_LAYERS': 'dzialki,numery_dzialek',
          'STYLES': 'default',
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
      infoError = fields.isEmpty ? 'Nie znaleziono działki.' : null;

      final parcelId = (fields['Identyfikator działki'] ?? '').trim();

      if (parcelId.isNotEmpty) {
        try {
          await _loadSelectedParcelGeometry(parcelId, notify: false);
        } catch (_) {
          _selectedParcelGeometry = null;
        }
      } else {
        _selectedParcelGeometry = null;
      }

      infoLoading = false;
      notifyListeners();

      return fields.isNotEmpty;
    } catch (e) {
      infoError = e.toString();
      selectedInfo = null;
      infoLoading = false;
      _selectedParcelGeometry = null;
      notifyListeners();

      return false;
    }
  }

  Future<void> _loadSelectedParcelGeometry(
    String parcelId, {
    bool notify = true,
  }) async {
    final cached = _parcelGeometryCache[parcelId];

    if (cached != null && cached.isNotEmpty) {
      _selectedParcelGeometry = cached;

      if (notify) {
        notifyListeners();
      }

      return;
    }

    final uri = Uri.parse(_uldkBaseUrl).replace(
      queryParameters: {
        'request': 'GetParcelById',
        'id': parcelId,
        'result': 'geom_wkt',
        'srid': '4326',
      },
    );

    final response = await client.get(uri).timeout(
          const Duration(seconds: 12),
        );

    if (response.statusCode != 200) {
      throw Exception('ULDK failed: ${response.statusCode}');
    }

    final raw = utf8.decode(response.bodyBytes, allowMalformed: true);
    final wkt = _extractWktFromUldkResponse(raw);

    if (wkt == null || wkt.isEmpty) {
      _selectedParcelGeometry = null;

      if (notify) {
        notifyListeners();
      }

      return;
    }

    final polygons = _parseWktGeometry(wkt);
    _selectedParcelGeometry = polygons.isEmpty ? null : polygons;

    if (_selectedParcelGeometry != null) {
      if (_parcelGeometryCache.length >= _maxParcelGeometryCacheEntries) {
        _parcelGeometryCache.remove(_parcelGeometryCache.keys.first);
      }
      _parcelGeometryCache[parcelId] = _selectedParcelGeometry!;
    }

    if (notify) {
      notifyListeners();
    }
  }

  List<Polygon> _buildHighlightedParcelPolygons(ThemeColors theme) {
    final geometries = _selectedParcelGeometry;

    if (geometries == null || geometries.isEmpty) {
      return const [];
    }

    return geometries
        .where((ring) => ring.length >= 3)
        .map(
          (ring) => Polygon(
            points: ring,
            color: theme.themeColor.withAlpha(55),
            borderColor: theme.themeColor.withAlpha(235),
            borderStrokeWidth: 3,
          ),
        )
        .toList();
  }

  String? _extractWktFromUldkResponse(String raw) {
    final trimmed = raw.trim();

    if (trimmed.isEmpty) return null;

    final upper = trimmed.toUpperCase();

    final multiIndex = upper.indexOf('MULTIPOLYGON');
    if (multiIndex >= 0) {
      return trimmed.substring(multiIndex).trim();
    }

    final polygonIndex = upper.indexOf('POLYGON');
    if (polygonIndex >= 0) {
      return trimmed.substring(polygonIndex).trim();
    }

    final lines = trimmed
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final line in lines.reversed) {
      final lineUpper = line.toUpperCase();

      final lineMultiIndex = lineUpper.indexOf('MULTIPOLYGON');
      if (lineMultiIndex >= 0) {
        return line.substring(lineMultiIndex).trim();
      }

      final linePolygonIndex = lineUpper.indexOf('POLYGON');
      if (linePolygonIndex >= 0) {
        return line.substring(linePolygonIndex).trim();
      }
    }

    return null;
  }

  List<List<LatLng>> _parseWktGeometry(String wkt) {
    final source = wkt.trim();
    final upper = source.toUpperCase();

    if (upper.startsWith('MULTIPOLYGON')) {
      final body = _extractOuterBody(
        source.substring('MULTIPOLYGON'.length).trim(),
      );

      final polygonBodies = _extractTopLevelGroups(body);
      final result = <List<LatLng>>[];

      for (final polygonBody in polygonBodies) {
        final rings = _extractTopLevelGroups(polygonBody);
        if (rings.isEmpty) continue;

        final outerRing = _parseRing(rings.first);

        if (outerRing.length >= 3) {
          result.add(_ensureClosedRing(outerRing));
        }
      }

      return result;
    }

    if (upper.startsWith('POLYGON')) {
      final body = _extractOuterBody(
        source.substring('POLYGON'.length).trim(),
      );

      final rings = _extractTopLevelGroups(body);
      if (rings.isEmpty) return const [];

      final outerRing = _parseRing(rings.first);
      if (outerRing.length < 3) return const [];

      return [_ensureClosedRing(outerRing)];
    }

    return const [];
  }

  String _extractOuterBody(String value) {
    final trimmed = value.trim();

    if (trimmed.length < 2) return trimmed;
    if (!trimmed.startsWith('(') || !trimmed.endsWith(')')) return trimmed;

    return trimmed.substring(1, trimmed.length - 1).trim();
  }

  List<String> _extractTopLevelGroups(String text) {
    final groups = <String>[];

    int depth = 0;
    int? start;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (char == '(') {
        depth++;

        if (depth == 1) {
          start = i + 1;
        }
      } else if (char == ')') {
        if (depth == 1 && start != null) {
          groups.add(text.substring(start, i).trim());
          start = null;
        }

        depth--;
      }
    }

    return groups;
  }

  List<LatLng> _parseRing(String ringText) {
    final points = <LatLng>[];

    for (final pair in ringText.split(',')) {
      final normalized = pair.trim().replaceAll(RegExp(r'\s+'), ' ');

      if (normalized.isEmpty) continue;

      final parts = normalized.split(' ');
      if (parts.length < 2) continue;

      final x = double.tryParse(parts[0]);
      final y = double.tryParse(parts[1]);

      if (x == null || y == null) continue;

      points.add(LatLng(y, x));
    }

    return points;
  }

  List<LatLng> _ensureClosedRing(List<LatLng> ring) {
    if (ring.length < 3) return ring;

    final first = ring.first;
    final last = ring.last;

    final samePoint = (first.latitude - last.latitude).abs() < 0.000000001 &&
        (first.longitude - last.longitude).abs() < 0.000000001;

    if (samePoint) return ring;

    return [...ring, first];
  }

  Future<void> clearFeatureInfoCache() async {
    _memoryInfoCache.clear();
    _parcelGeometryCache.clear();

    final cache = await _ensureCache();
    await cache?.clear();
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

      if (key.isNotEmpty) {
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

      if (key.isNotEmpty) {
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

  bool _hasVisibleInfoState() =>
      infoLoading ||
      infoError != null ||
      (selectedInfo != null && selectedInfo!.isNotEmpty);

  bool _mobileSheetOpen = false;

  Widget _buildPanelHeader(ThemeColors theme) {
    return Row(
      children: [
        Icon(
          Icons.crop_square_rounded,
          color: theme.themeColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'parcel_data'.tr,
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
    );
  }

  Widget _buildPanelBody(ThemeColors theme, {ScrollController? scrollController}) {
    if (infoLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'loading_parcel_data'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        ],
      );
    }

    if (infoError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(theme),
          Text(
            infoError!,
            style: TextStyle(color: theme.textColor),
          ),
        ],
      );
    }

    final orderedEntries = _orderedEntries();
    final parcelId = (selectedInfo?['Identyfikator działki'] ?? '').trim();
    final entries = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: orderedEntries
          .where((entry) => entry.key != 'Identyfikator działki')
          .map(
            (entry) => _buildInfoRow(
              _fieldLabel(entry.key),
              entry.value,
              theme,
            ),
          )
          .toList(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: scrollController == null ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _buildPanelHeader(theme),
        if (parcelId.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(35),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: theme.themeColor.withAlpha(90)),
            ),
            child: SelectableText(
              parcelId,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (scrollController == null)
          Flexible(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(child: entries),
            ),
          )
        else
          Expanded(
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                child: entries,
              ),
            ),
          ),
      ],
    );
  }

  void _showMobileInfoSheet(BuildContext context, ThemeColors theme) {
    if (_mobileSheetOpen) return;
    _mobileSheetOpen = true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // The nested DraggableScrollableSheet already owns vertical drag
      // gestures for resizing; letting the outer sheet ALSO treat a
      // downward drag as dismiss races both gesture handlers and can pop
      // an extra route (kicking the user out to the landing page).
      // Dismissal on drag is handled below via the drag-to-min-extent
      // notification instead, which reuses the same clean pop path as
      // the close button.
      enableDrag: false,
      builder: (sheetContext) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            if (notification.extent <= notification.minExtent + 0.001) {
              clearSelection();
            }
            return false;
          },
          child: DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.22,
            maxChildSize: 0.85,
            expand: false,
            builder: (ctx, scrollController) {
              return AnimatedBuilder(
                animation: this,
                builder: (ctx, _) {
                  if (!_hasVisibleInfoState()) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (Navigator.of(sheetContext).canPop()) {
                        Navigator.of(sheetContext).pop();
                      }
                    });
                  }

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer.withAlpha(245),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      border: Border.all(color: Colors.white.withAlpha(35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: theme.textColor.withAlpha(60),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildPanelBody(
                            theme,
                            scrollController: scrollController,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      _mobileSheetOpen = false;
      if (_hasVisibleInfoState()) {
        clearSelection();
      }
    });
  }

  @override
  List<Widget> buildOverlays({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeColors theme,
  }) {
    if (!_hasVisibleInfoState()) {
      return const [];
    }

    if (DeviceTypeUtil.isMobile(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _showMobileInfoSheet(context, theme);
      });

      return const [];
    }

    return [
      SafeArea(
        minimum: const EdgeInsets.only(top: 16, left: 16),
        child: Align(
          alignment: Alignment.centerLeft,
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
              child: _buildPanelBody(theme),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  String get cacheDisplayName => 'Działki / GetFeatureInfo';

  @override
  String get cacheDescription =>
      'Cache odpowiedzi GetFeatureInfo dla kliknięć na działki. Raster WMS nie jest tu cachowany persistent.';

  @override
  bool get supportsMemoryCache => true;

  @override
  bool get supportsPersistentCache => persistentCacheEnabled;

  @override
  Future<AppMapCacheSummary> getCacheSummary() async {
    final cache = await _ensureCache();
    final stats = await cache?.stats();

    final persistentBytes = stats?.approxBytes ?? 0;

    return AppMapCacheSummary(
      memoryEntries: _memoryInfoCache.length + _parcelGeometryCache.length,
      persistentEntries: stats?.entries ?? 0,
      approxBytes: persistentBytes,
      memoryBytes: null,
      persistentBytes: persistentBytes,
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
      networkFetches: _networkFetches,
      lastWarmupAt: _lastWarmupAt,
      note:
          'Cache dotyczy odpowiedzi GetFeatureInfo oraz geometrii działek. Klucz cache jest oparty o realny punkt mapy, a nie o bbox viewportu.',
    );
  }

  @override
  Future<void> clearMemoryCache({bool clearVisibleState = true}) async {
    _memoryInfoCache.clear();
    _parcelGeometryCache.clear();

    if (clearVisibleState) {
      clearSelection();
    }
  }

  @override
  Future<void> clearPersistentCache({bool clearVisibleState = false}) async {
    final cache = await _ensureCache();
    await cache?.clear();

    if (clearVisibleState) {
      clearSelection();
    }
  }

  @override
  Future<void> clearAllCache({bool clearVisibleState = true}) async {
    _memoryInfoCache.clear();
    _parcelGeometryCache.clear();

    final cache = await _ensureCache();
    await cache?.clear();

    _cacheHits = 0;
    _cacheMisses = 0;
    _networkFetches = 0;
    _lastWarmupAt = null;

    if (clearVisibleState) {
      clearSelection();
    }
  }
}