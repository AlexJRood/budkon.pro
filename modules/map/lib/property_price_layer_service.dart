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
import 'map_wms_utils.dart';

class PropertyPriceLayerService extends AppMapLayerService
    implements AppMapCacheableService {
  @override
  final String id;

  final http.Client client;
  final MapGeoService geo;
  final bool persistentCacheEnabled;
  final Duration cacheTtl;
  final int maxCacheEntries;

  PropertyPriceLayerService({
    required this.client,
    required this.geo,
    this.id = 'property_price_layer',
    this.persistentCacheEnabled = true,
    this.cacheTtl = const Duration(days: 30),
    this.maxCacheEntries = 180,
  });

  static const String _baseUrl =
      'https://integracja.gugik.gov.pl/cgi-bin/KrajowaIntegracjaCenNieruchomosci?language=pol';

  bool showLayer = false;

  bool showImplementations = true;
  bool showGrouping = true;
  bool showTransactions = true;
  bool showBasketTransactions = false;

  double opacity = 0.72;

  double _implementationsMinZoom = 8.5;
  double _groupingMinZoom = 11.5;
  double _detailsMinZoom = 14.5;

  double get implementationsMinZoom => _implementationsMinZoom;
  double get groupingMinZoom => _groupingMinZoom;
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
    'Cena',
    'Cena transakcyjna',
    'Cena za m²',
    'Cena za m2',
    'Waluta',
    'Data transakcji',
    'Rodzaj nieruchomości',
    'Typ nieruchomości',
    'Forma transakcji',
    'Powierzchnia',
    'Powierzchnia użytkowa',
    'Powierzchnia lokalu',
    'Powierzchnia użytkowa lokalu',
    'Metraż',
    'Lokalizacja',
    'Miejscowość',
    'Gmina',
    'Powiat',
    'Województwo',
    'Źródło danych',
    'Id',
    'Id transakcji',
  ];

  static const Map<String, String> _fieldLabels = {
    'Cena': 'Cena',
    'Cena transakcyjna': 'Cena transakcyjna',
    'Cena za m²': 'Cena za m²',
    'Cena za m2': 'Cena za m²',
    'Waluta': 'Waluta',
    'Data transakcji': 'Data transakcji',
    'Rodzaj nieruchomości': 'Rodzaj nieruchomości',
    'Typ nieruchomości': 'Typ nieruchomości',
    'Forma transakcji': 'Forma transakcji',
    'Powierzchnia': 'Powierzchnia',
    'Powierzchnia użytkowa': 'Powierzchnia użytkowa',
    'Powierzchnia lokalu': 'Powierzchnia lokalu',
    'Powierzchnia użytkowa lokalu': 'Powierzchnia użytkowa lokalu',
    'Metraż': 'Metraż',
    'Lokalizacja': 'Lokalizacja',
    'Miejscowość': 'Miejscowość',
    'Gmina': 'Gmina',
    'Powiat': 'Powiat',
    'Województwo': 'Województwo',
    'Źródło danych': 'Źródło danych',
    'Id': 'Id',
    'Id transakcji': 'Id transakcji',
  };

  static const List<String> _priceAliases = [
    'Cena transakcyjna',
    'Cena',
    'Cena transakcji',
    'Kwota transakcji',
    'Wartość transakcji',
    'Wartość',
  ];

  static const List<String> _pricePerSqmAliases = [
    'Cena za m²',
    'Cena za m2',
    'Cena 1 m²',
    'Cena 1 m2',
    'Cena za 1 m²',
    'Cena za 1 m2',
    'Cena jednostkowa',
    'Wartość za m²',
    'Wartość za m2',
  ];

  static const List<String> _areaAliases = [
    'Powierzchnia użytkowa',
    'Powierzchnia',
    'Powierzchnia lokalu',
    'Powierzchnia użytkowa lokalu',
    'Metraż',
  ];

  static const List<String> _typeAliases = [
    'Typ nieruchomości',
    'Rodzaj nieruchomości',
    'Typ',
    'Rodzaj',
    'Funkcja',
  ];

  bool canShowImplementations(double zoom) =>
      showLayer && showImplementations && zoom >= _implementationsMinZoom;

  bool canShowGrouping(double zoom) =>
      showLayer && showGrouping && zoom >= _groupingMinZoom;

  bool canShowDetails(double zoom) =>
      showLayer && _activeDetailLayers.isNotEmpty && zoom >= _detailsMinZoom;

  List<String> get _activeDetailLayers {
    final result = <String>[];

    if (showTransactions) {
      result.add('transakcje');
    }

    if (showBasketTransactions) {
      result.add('transakcje-koszyk');
    }

    return result;
  }

  List<String> _layersForZoom(double zoom) {
    if (canShowDetails(zoom)) {
      return _activeDetailLayers;
    }

    if (canShowGrouping(zoom)) {
      final result = <String>[];

      if (showGrouping) {
        result.add('grupowanie');
      }

      return result;
    }

    if (canShowImplementations(zoom)) {
      final result = <String>[];

      if (showImplementations) {
        result.add('wdrozenia');
      }

      return result;
    }

    return const [];
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

    const snapMeters = 5.0;

    return [
      id,
      'feature_info',
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

  Future<void> _writeCachedInfo(
    String key,
    Map<String, String> fields,
  ) async {
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
    showLayer = value;

    if (!value) {
      clearSelection();
    }

    notifyListeners();
  }

  void setShowImplementations(bool value) {
    showImplementations = value;
    notifyListeners();
  }

  void setShowGrouping(bool value) {
    showGrouping = value;
    notifyListeners();
  }

  void setShowTransactions(bool value) {
    showTransactions = value;

    if (!showTransactions && !showBasketTransactions) {
      clearSelection();
    }

    notifyListeners();
  }

  void setShowBasketTransactions(bool value) {
    showBasketTransactions = value;

    if (!showTransactions && !showBasketTransactions) {
      clearSelection();
    }

    notifyListeners();
  }

  void setOpacity(double value) {
    opacity = value;
    notifyListeners();
  }

  void setImplementationsMinZoom(double value) {
    _implementationsMinZoom = value.clamp(6.0, 18.0).toDouble();

    if (_groupingMinZoom <= _implementationsMinZoom) {
      _groupingMinZoom =
          (_implementationsMinZoom + 0.5).clamp(6.5, 19.0).toDouble();
    }

    if (_detailsMinZoom <= _groupingMinZoom) {
      _detailsMinZoom = (_groupingMinZoom + 0.5).clamp(7.0, 20.0).toDouble();
    }

    notifyListeners();
  }

  void setGroupingMinZoom(double value) {
    final minAllowed = (_implementationsMinZoom + 0.5).clamp(6.5, 19.0);
    _groupingMinZoom = value.clamp(minAllowed, 19.0).toDouble();

    if (_detailsMinZoom <= _groupingMinZoom) {
      _detailsMinZoom = (_groupingMinZoom + 0.5).clamp(7.0, 20.0).toDouble();
    }

    notifyListeners();
  }

  void setDetailsMinZoom(double value) {
    final minAllowed = (_groupingMinZoom + 0.5).clamp(7.0, 20.0);
    _detailsMinZoom = value.clamp(minAllowed, 20.0).toDouble();
    notifyListeners();
  }

  void clearSelection() {
    selectedInfo = null;
    infoError = null;
    infoLoading = false;
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

      final sw92 = geo.wgs84ToCs92(bounds.southWest);
      final ne92 = geo.wgs84ToCs92(bounds.northEast);

      final minX = sw92.x < ne92.x ? sw92.x : ne92.x;
      final minY = sw92.y < ne92.y ? sw92.y : ne92.y;
      final maxX = sw92.x > ne92.x ? sw92.x : ne92.x;
      final maxY = sw92.y > ne92.y ? sw92.y : ne92.y;

      final bbox = '$minX,$minY,$maxX,$maxY';

      final width = camera.size.width.round();
      final height = camera.size.height.round();

      if (width <= 0 || height <= 0) {
        throw Exception('invalid_map_size_for_get_feature_info'.tr);
      }

      final baseI = relative.dx.round().clamp(0, width - 1).toInt();
      final baseJ = relative.dy.round().clamp(0, height - 1).toInt();

      final cacheKey = _buildInfoRequestKey(
        minX: minX,
        minY: minY,
        maxX: maxX,
        maxY: maxY,
        width: width,
        height: height,
        i: baseI,
        j: baseJ,
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

      _registerNetworkFetch();

      final fields = await _tryFetchFeatureInfoNearTap(
        bbox: bbox,
        width: width,
        height: height,
        baseI: baseI,
        baseJ: baseJ,
        detailLayers: detailLayers,
      );

      if (fields.isNotEmpty) {
        await _writeCachedInfo(cacheKey, fields);
      }

      selectedInfo = fields.isEmpty ? null : fields;
      infoError = fields.isEmpty
          ? 'no_transaction_data_found_for_selected_point'.tr
          : null;

      infoLoading = false;
      notifyListeners();

      return fields.isNotEmpty;
    } catch (e) {
      final message = e.toString().toLowerCase();

      if (message.contains('no matching record') ||
          message.contains('search returned no results') ||
          message.contains('layer named') ||
          message.contains('does not exist') ||
          message.contains('msquerybypoint')) {
        infoError = 'no_transaction_data_found_for_selected_point'.tr;
      } else {
        infoError = 'failed_to_load_transaction_data'.tr;
      }

      selectedInfo = null;
      infoLoading = false;
      notifyListeners();

      return false;
    }
  }

  Future<Map<String, String>> _tryFetchFeatureInfoNearTap({
    required String bbox,
    required int width,
    required int height,
    required int baseI,
    required int baseJ,
    required List<String> detailLayers,
  }) async {
    const offsets = <Offset>[
      Offset(0, 0),
      Offset(-3, 0),
      Offset(3, 0),
      Offset(0, -3),
      Offset(0, 3),
      Offset(-6, 0),
      Offset(6, 0),
      Offset(0, -6),
      Offset(0, 6),
      Offset(-3, -3),
      Offset(3, -3),
      Offset(-3, 3),
      Offset(3, 3),
      Offset(-8, 0),
      Offset(8, 0),
      Offset(0, -8),
      Offset(0, 8),
    ];

    const infoFormats = <String>[
      'text/html',
      'text/plain',
      'application/vnd.ogc.gml',
    ];

    for (final offset in offsets) {
      final i = (baseI + offset.dx.round()).clamp(0, width - 1).toInt();
      final j = (baseJ + offset.dy.round()).clamp(0, height - 1).toInt();

      for (final layer in detailLayers) {
        for (final infoFormat in infoFormats) {
          try {
            final uri = _buildFeatureInfoUri(
              bbox: bbox,
              width: width,
              height: height,
              i: i,
              j: j,
              detailLayers: [layer],
              infoFormat: infoFormat,
            );

            final finalBody = await _resolveFeatureInfoPayload(uri);

            if (_isNoResultPayload(finalBody) ||
                _isLayerErrorPayload(finalBody)) {
              continue;
            }

            final fields = _extractFeatureInfoFields(finalBody);
            if (fields.isNotEmpty) {
              return fields;
            }

            final looseFields = _extractFieldsFromLooseText(finalBody);
            if (looseFields.isNotEmpty) {
              return looseFields;
            }
          } catch (_) {
            // Try next layer / offset / format.
          }
        }
      }
    }

    return const <String, String>{};
  }

  Uri _buildFeatureInfoUri({
    required String bbox,
    required int width,
    required int height,
    required int i,
    required int j,
    required List<String> detailLayers,
    required String infoFormat,
  }) {
    return Uri.parse(
      'https://integracja.gugik.gov.pl/cgi-bin/KrajowaIntegracjaCenNieruchomosci',
    ).replace(
      queryParameters: {
        'language': 'pol',
        'SERVICE': 'WMS',
        'VERSION': '1.3.0',
        'REQUEST': 'GetFeatureInfo',
        'LAYERS': detailLayers.join(','),
        'QUERY_LAYERS': detailLayers.join(','),
        'STYLES': List.filled(detailLayers.length, 'default').join(','),
        'CRS': 'EPSG:2180',
        'BBOX': bbox,
        'WIDTH': width.toString(),
        'HEIGHT': height.toString(),
        'I': i.toString(),
        'J': j.toString(),
        'INFO_FORMAT': infoFormat,
        'FEATURE_COUNT': '5',
        'FORMAT': 'image/png',
        'TRANSPARENT': 'true',
      },
    );
  }

  Future<String> _resolveFeatureInfoPayload(
    Uri uri, {
    int depth = 0,
  }) async {
    final response = await client.get(
      uri,
      headers: const {
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('GetFeatureInfo failed: ${response.statusCode}');
    }

    final body = _decodeResponseBody(response.bodyBytes);

    if (depth >= 2) {
      return body;
    }

    final embeddedUri = _extractEmbeddedFeatureInfoUri(
      body,
      currentUri: uri,
    );

    if (embeddedUri == null) {
      return body;
    }

    if (embeddedUri.toString() == uri.toString()) {
      return body;
    }

    return _resolveFeatureInfoPayload(embeddedUri, depth: depth + 1);
  }

  String _decodeResponseBody(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  Uri? _extractEmbeddedFeatureInfoUri(
    String raw, {
    required Uri currentUri,
  }) {
    final decoded = _decodeHtmlEntities(raw);

    final iframeMatch = RegExp(
      r'''<iframe[^>]*\bsrc\s*(?:=)?\s*["']([^"']+)["']''',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(decoded);

    if (iframeMatch != null) {
      final candidate = iframeMatch.group(1)?.trim();
      final resolved = _resolvePossiblyRelativeUri(candidate, currentUri);
      if (resolved != null) return resolved;
    }

    final metaRefreshMatch = RegExp(
      r'''<meta[^>]*http-equiv\s*=\s*["']refresh["'][^>]*content\s*=\s*["'][^"']*url=([^"']+)["']''',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(decoded);

    if (metaRefreshMatch != null) {
      final candidate = metaRefreshMatch.group(1)?.trim();
      final resolved = _resolvePossiblyRelativeUri(candidate, currentUri);
      if (resolved != null) return resolved;
    }

    return null;
  }

  Uri? _resolvePossiblyRelativeUri(String? value, Uri currentUri) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final cleaned = _decodeHtmlEntities(value).trim();
    final parsed = Uri.tryParse(cleaned);
    if (parsed == null) return null;

    if (parsed.hasScheme) {
      return parsed;
    }

    return currentUri.resolveUri(parsed);
  }

  Map<String, String> _extractFeatureInfoFields(String raw) {
    final result = <String, String>{};
    final decoded = _decodeHtmlEntities(raw);

    if (_isNoResultPayload(decoded) || _isLayerErrorPayload(decoded)) {
      return result;
    }

    void addPair(String rawKey, String rawValue) {
      final key = _normalizeText(_stripHtml(rawKey));
      final value = _normalizeText(_stripHtml(rawValue));

      if (key.isEmpty || value.isEmpty) return;
      if (_looksLikeHtmlNoise(key) || _looksLikeHtmlNoise(value)) return;

      result[key] = value;
    }

    final htmlTablePatterns = [
      RegExp(
        r'<tr[^>]*>\s*<th[^>]*>(.*?)</th>\s*<td[^>]*>(.*?)</td>\s*</tr>',
        caseSensitive: false,
        dotAll: true,
      ),
      RegExp(
        r'<tr[^>]*>\s*<td[^>]*>(.*?)</td>\s*<td[^>]*>(.*?)</td>\s*</tr>',
        caseSensitive: false,
        dotAll: true,
      ),
      RegExp(
        r'<b[^>]*>(.*?)</b>\s*[:=]\s*(.*?)(?:<br\s*/?>|</p>|</div>|$)',
        caseSensitive: false,
        dotAll: true,
      ),
    ];

    for (final pattern in htmlTablePatterns) {
      for (final match in pattern.allMatches(decoded)) {
        addPair(match.group(1) ?? '', match.group(2) ?? '');
      }

      if (result.isNotEmpty) {
        return result;
      }
    }

    final xmlAttrRegExp = RegExp(
      r'<Attribute\s+Name="([^"]+)">(.*?)</Attribute>',
      caseSensitive: false,
      dotAll: true,
    );

    for (final match in xmlAttrRegExp.allMatches(decoded)) {
      var value = match.group(2) ?? '';

      value = value.replaceAllMapped(
        RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true),
        (m) => m.group(1) ?? '',
      );

      addPair(match.group(1) ?? '', value);
    }

    if (result.isNotEmpty) {
      return result;
    }

    final plainLines = _stripHtml(decoded)
        .split(RegExp(r'[\r\n]+'))
        .map(_normalizeText)
        .where((e) => e.isNotEmpty)
        .toList();

    for (final line in plainLines) {
      final separator = line.contains('=')
          ? '='
          : line.contains(':')
              ? ':'
              : null;

      if (separator == null) continue;

      final parts = line.split(separator);
      if (parts.length < 2) continue;

      final key = parts.first.trim();
      final value = parts.sublist(1).join(separator).trim();

      if (key.isNotEmpty &&
          value.isNotEmpty &&
          !_looksLikeHtmlNoise(key) &&
          !_looksLikeHtmlNoise(value)) {
        result[key] = value;
      }
    }

    return result;
  }

  Map<String, String> _extractFieldsFromLooseText(String raw) {
    if (_isNoResultPayload(raw) || _isLayerErrorPayload(raw)) {
      return const <String, String>{};
    }

    final decoded = _decodeHtmlEntities(raw);
    final text = _normalizeText(_stripHtml(decoded));

    if (text.isEmpty) {
      return const <String, String>{};
    }

    String? findFirst(List<RegExp> patterns) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(text);
        final value = match?.group(1)?.trim();

        if (value != null && value.isNotEmpty) {
          return value;
        }
      }

      return null;
    }

    final result = <String, String>{};

    final pricePerSqm = findFirst([
      RegExp(
        r'(?i)cena(?:\s+za)?\s*(?:1\s*)?m[²2]\s*[:=]?\s*([0-9\s.,]+(?:\s*(?:zł|pln))?)',
      ),
      RegExp(
        r'(?i)cena\s+jednostkowa\s*[:=]?\s*([0-9\s.,]+(?:\s*(?:zł|pln))?)',
      ),
      RegExp(
        r'(?i)wartość\s+za\s*m[²2]\s*[:=]?\s*([0-9\s.,]+(?:\s*(?:zł|pln))?)',
      ),
    ]);

    final price = findFirst([
      RegExp(
        r'(?i)cena(?:\s+transakcyjna)?\s*[:=]?\s*([0-9\s.,]+(?:\s*(?:zł|pln))?)',
      ),
      RegExp(
        r'(?i)wartość(?:\s+transakcji)?\s*[:=]?\s*([0-9\s.,]+(?:\s*(?:zł|pln))?)',
      ),
      RegExp(
        r'(?i)kwota(?:\s+transakcji)?\s*[:=]?\s*([0-9\s.,]+(?:\s*(?:zł|pln))?)',
      ),
    ]);

    final area = findFirst([
      RegExp(
        r'(?i)powierzch(?:nia|ni[a-ząćęłńóśźż]*)\s*[:=]?\s*([0-9\s.,]+(?:\s*m[²2])?)',
      ),
      RegExp(
        r'(?i)metraż\s*[:=]?\s*([0-9\s.,]+(?:\s*m[²2])?)',
      ),
    ]);

    final type = findFirst([
      RegExp(r'(?i)typ(?:\s+nieruchomości)?\s*[:=]?\s*([^,;]+)'),
      RegExp(r'(?i)rodzaj(?:\s+nieruchomości)?\s*[:=]?\s*([^,;]+)'),
    ]);

    if (price != null) {
      result['Cena transakcyjna'] = price;
    }

    if (pricePerSqm != null) {
      result['Cena za m²'] = pricePerSqm;
    }

    if (area != null) {
      result['Powierzchnia'] = area;
    }

    if (type != null) {
      result['Typ nieruchomości'] = type;
    }

    return result;
  }

  bool _isNoResultPayload(String raw) {
    final text =
        _normalizeText(_stripHtml(_decodeHtmlEntities(raw))).toLowerCase();

    return text.contains('search returned no results') ||
        text.contains('no matching record') ||
        text.contains('no matching records') ||
        text.contains('brak danych') ||
        text.contains('nie znaleziono') ||
        text.contains('no results');
  }

  bool _isLayerErrorPayload(String raw) {
    final text =
        _normalizeText(_stripHtml(_decodeHtmlEntities(raw))).toLowerCase();

    return text.contains('layer named') ||
        text.contains('does not exist') ||
        text.contains('general error message') ||
        text.contains('msquerybypoint');
  }

  String _decodeHtmlEntities(String input) {
    var current = input;
    String previous;

    do {
      previous = current;
      current = current
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&apos;', "'")
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAllMapped(
            RegExp(r'&#x([0-9a-fA-F]+);'),
            (m) {
              final code = int.tryParse(m.group(1) ?? '', radix: 16);
              if (code == null) return m.group(0) ?? '';
              return String.fromCharCode(code);
            },
          )
          .replaceAllMapped(
            RegExp(r'&#(\d+);'),
            (m) {
              final code = int.tryParse(m.group(1) ?? '');
              if (code == null) return m.group(0) ?? '';
              return String.fromCharCode(code);
            },
          );
    } while (current != previous);

    return current;
  }

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]+>', dotAll: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _looksLikeHtmlNoise(String value) {
    final normalized = value.toLowerCase();

    return normalized.contains('<iframe') ||
        normalized.contains('<meta') ||
        normalized.contains('<html') ||
        normalized.contains('<body') ||
        normalized.contains('</') ||
        normalized.startsWith('script') ||
        normalized.startsWith('style');
  }

  String _normalizeText(String value) {
    return value
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeLookupKey(String value) {
    return value
        .toLowerCase()
        .replaceAll('²', '2')
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'[^a-z0-9ąćęłńóśźż]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _findFirstValueByAliases(
    Map<String, String> source,
    List<String> aliases,
  ) {
    final entries = source.entries
        .map((e) => MapEntry(_normalizeLookupKey(e.key), e.value))
        .toList();

    for (final alias in aliases) {
      final normalizedAlias = _normalizeLookupKey(alias);

      for (final entry in entries) {
        if (entry.key == normalizedAlias) {
          return entry.value;
        }
      }
    }

    for (final alias in aliases) {
      final normalizedAlias = _normalizeLookupKey(alias);

      for (final entry in entries) {
        if (entry.key.contains(normalizedAlias) ||
            normalizedAlias.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    return null;
  }

  double? _parseLocalizedNumber(String? raw) {
    if (raw == null) return null;

    var text = _normalizeText(raw)
        .replaceAll(RegExp(r'(?i)\bzł\b|\bpln\b|\bm2\b|\bm²\b|\bzl\b'), ' ')
        .replaceAll(RegExp(r'[^0-9,.\- ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (text.isEmpty) return null;

    final match = RegExp(r'-?\d[\d\s.,]*').firstMatch(text);
    if (match == null) return null;

    text = (match.group(0) ?? '').replaceAll(' ', '');
    if (text.isEmpty) return null;

    if (text.contains(',') && text.contains('.')) {
      if (text.lastIndexOf(',') > text.lastIndexOf('.')) {
        text = text.replaceAll('.', '').replaceAll(',', '.');
      } else {
        text = text.replaceAll(',', '');
      }
    } else if (text.contains(',')) {
      final idx = text.lastIndexOf(',');
      final digitsAfter = text.length - idx - 1;

      if (digitsAfter == 3) {
        text = text.replaceAll(',', '');
      } else {
        text = text.replaceAll(',', '.');
      }
    } else if (text.contains('.')) {
      final idx = text.lastIndexOf('.');
      final digitsAfter = text.length - idx - 1;

      if (digitsAfter == 3) {
        text = text.replaceAll('.', '');
      }
    }

    return double.tryParse(text);
  }

  String _formatNumber(num value, {int decimals = 0}) {
    final negative = value < 0;
    final absValue = value.abs();
    final fixed = absValue.toStringAsFixed(decimals);
    final parts = fixed.split('.');

    final intPart = parts[0];
    final buffer = StringBuffer();

    for (int i = 0; i < intPart.length; i++) {
      final reverseIndex = intPart.length - i;
      buffer.write(intPart[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(' ');
      }
    }

    var result = buffer.toString();

    if (decimals > 0 && parts.length > 1) {
      result = '$result,${parts[1]}';
    }

    return negative ? '-$result' : result;
  }

  String _formatPrice(double value) {
    final decimals = value % 1 == 0 ? 0 : 2;
    return '${_formatNumber(value, decimals: decimals)} zł';
  }

  String _formatArea(double value) {
    final decimals = value % 1 == 0 ? 0 : 2;
    return '${_formatNumber(value, decimals: decimals)} m²';
  }

  String _formatPricePerSqm(double value) {
    final decimals = value >= 100 ? 0 : 2;
    return '${_formatNumber(value, decimals: decimals)} zł/m²';
  }

  Map<String, Object?> _buildTransactionSummary() {
    final source = selectedInfo ?? const <String, String>{};

    String? findByKeyPredicate(bool Function(String key) test) {
      for (final entry in source.entries) {
        final key = _normalizeLookupKey(entry.key);

        if (test(key)) {
          final value = _normalizeText(entry.value);

          if (value.isNotEmpty) {
            return value;
          }
        }
      }

      return null;
    }

    String? rawPrice = _findFirstValueByAliases(source, _priceAliases);
    rawPrice ??= findByKeyPredicate((key) {
      final isPrice = key.contains('cena') || key.contains('wartosc');
      final isPerSqm =
          key.contains('m2') || key.contains('metr') || key.contains('jednostk');

      return isPrice && !isPerSqm;
    });

    String? rawPricePerSqm =
        _findFirstValueByAliases(source, _pricePerSqmAliases);
    rawPricePerSqm ??= findByKeyPredicate((key) {
      final isPrice = key.contains('cena') || key.contains('wartosc');
      final isPerSqm =
          key.contains('m2') || key.contains('metr') || key.contains('jednostk');

      return isPrice && isPerSqm;
    });

    String? rawArea = _findFirstValueByAliases(source, _areaAliases);
    rawArea ??= findByKeyPredicate((key) {
      return key.contains('powierzch') ||
          key.contains('metraz') ||
          key.contains('uzytkowa');
    });

    String? rawType = _findFirstValueByAliases(source, _typeAliases);
    rawType ??= findByKeyPredicate((key) {
      return key.contains('typ') ||
          key.contains('rodzaj') ||
          key.contains('funkcja');
    });

    final price = _parseLocalizedNumber(rawPrice);
    final explicitPricePerSqm = _parseLocalizedNumber(rawPricePerSqm);
    final area = _parseLocalizedNumber(rawArea);

    double? pricePerSqm = explicitPricePerSqm;

    if (pricePerSqm == null && price != null && area != null && area > 0) {
      pricePerSqm = price / area;
    }

    return {
      'price': price,
      'pricePerSqm': pricePerSqm,
      'area': area,
      'type': rawType != null ? _normalizeText(rawType) : null,
    };
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

  Widget _buildMetricTile({
    required ThemeColors theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.themeColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(180),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
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
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth < 520 ? screenWidth - 24 : 410.0;

    final summary = _buildTransactionSummary();
    final summaryPrice = summary['price'] as double?;
    final summaryPricePerSqm = summary['pricePerSqm'] as double?;
    final summaryArea = summary['area'] as double?;
    final summaryType = summary['type'] as String?;

    final hasSummary = summaryPrice != null ||
        summaryPricePerSqm != null ||
        summaryArea != null ||
        (summaryType != null && summaryType.isNotEmpty);

    return [
      SafeArea(
        minimum: const EdgeInsets.only(top: 16, right: 16, left: 8),
        child: Align(
          alignment: Alignment.topRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: panelWidth,
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
                            'loading_transaction_data'.tr,
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
                                    'property_prices_title'.tr,
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
                                  Icons.attach_money_rounded,
                                  color: theme.themeColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'property_prices_title'.tr,
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
                            if (hasSummary) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.themeColor.withAlpha(18),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.themeColor.withAlpha(50),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'transaction_summary'.tr,
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (summaryPrice != null)
                                          _buildMetricTile(
                                            theme: theme,
                                            icon: Icons.payments_rounded,
                                            label: 'price_label'.tr,
                                            value: _formatPrice(summaryPrice),
                                          ),
                                        if (summaryPricePerSqm != null)
                                          _buildMetricTile(
                                            theme: theme,
                                            icon: Icons.grid_view_rounded,
                                            label: 'price_per_sqm_label'.tr,
                                            value: _formatPricePerSqm(
                                              summaryPricePerSqm,
                                            ),
                                          ),
                                        if (summaryArea != null)
                                          _buildMetricTile(
                                            theme: theme,
                                            icon: Icons.square_foot_rounded,
                                            label: 'area_label'.tr,
                                            value: _formatArea(summaryArea),
                                          ),
                                        if (summaryType != null &&
                                            summaryType.isNotEmpty)
                                          _buildMetricTile(
                                            theme: theme,
                                            icon: Icons.home_work_rounded,
                                            label: 'type_label'.tr,
                                            value: summaryType,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Flexible(
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
  String get cacheDisplayName => 'Ceny nieruchomości / GetFeatureInfo';

  @override
  String get cacheDescription =>
      'Cache odpowiedzi GetFeatureInfo dla kliknięć w warstwę cen nieruchomości. Raster WMS nie jest tu cachowany persistent.';

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
      memoryEntries: _memoryInfoCache.length,
      persistentEntries: stats?.entries ?? 0,
      approxBytes: persistentBytes,
      memoryBytes: null,
      persistentBytes: persistentBytes,
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
      networkFetches: _networkFetches,
      lastWarmupAt: _lastWarmupAt,
      note:
          'Cache działa po realnym punkcie mapy w EPSG:2180 zaokrąglonym do kilku metrów, więc jest stabilniejszy niż cache po bbox/pixel.',
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

    if (clearVisibleState) {
      clearSelection();
    }
  }

  @override
  Future<void> clearAllCache({bool clearVisibleState = true}) async {
    _memoryInfoCache.clear();

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