import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

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
import 'map_layer_state_storage.dart';

class StreetFeature {
  final String id;
  final String name;
  final List<List<LatLng>> lines;
  final Map<String, dynamic> properties;

  const StreetFeature({
    required this.id,
    required this.name,
    required this.lines,
    required this.properties,
  });

  factory StreetFeature.fromJson(Map<String, dynamic> json) {
    final rawLines = (json['lines'] as List?) ?? const [];
    final lines = <List<LatLng>>[];

    for (final rawLine in rawLines) {
      if (rawLine is! List) continue;

      final points = <LatLng>[];
      for (final rawPoint in rawLine) {
        if (rawPoint is! Map) continue;

        final point = Map<String, dynamic>.from(rawPoint);
        final lat = (point['lat'] as num?)?.toDouble();
        final lng = (point['lng'] as num?)?.toDouble();

        if (lat == null || lng == null) continue;
        points.add(LatLng(lat, lng));
      }

      if (points.length >= 2) {
        lines.add(points);
      }
    }

    return StreetFeature(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lines: lines,
      properties: json['properties'] is Map
          ? Map<String, dynamic>.from(json['properties'] as Map)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lines': lines
          .map(
            (line) => line
                .map(
                  (point) => {
                    'lat': point.latitude,
                    'lng': point.longitude,
                  },
                )
                .toList(),
          )
          .toList(),
      'properties': properties,
    };
  }

  String get displayName {
    final candidates = [
      name,
      properties['cecha_i_nazwa'],
      properties['pelna_nazwa'],
      properties['ulica'],
      properties['nazwa'],
      properties['name'],
      properties['street_name'],
      properties['nazwa_ulicy'],
      properties['full_name'],
      properties['label'],
      properties['idUlicy'],
      properties['id_ulicy'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    return 'Ulica';
  }
}

class StreetLayerService extends AppMapLayerService
    implements AppMapCacheableService {
  @override
  final String id;

  final http.Client client;
  final MapGeoService geo;
  final bool persistentCacheEnabled;
  final Duration cacheTtl;
  final int maxCacheEntries;
  final int maxMemoryEntries;

  StreetLayerService({
    required this.client,
    required this.geo,
    this.id = 'street_layer',
    this.persistentCacheEnabled = true,
    this.cacheTtl = const Duration(days: 30),
    this.maxCacheEntries = 260,
    this.maxMemoryEntries = 120,
  }) {
    _restoreState();
  }

  static const String _baseUrl =
      'https://mapy.geoportal.gov.pl/wss/ext/KrajowaIntegracjaNumeracjiAdresowej';

  bool showLayer = false;
  double opacity = 0.95;
  double strokeWidth = 4.0;
  double minVisibleZoom = 16.0;

  bool _loading = false;
  bool _bypassCacheOnce = false;

  String? _error;
  String? _lastRequestKey;

  int _requestToken = 0;

  List<StreetFeature> _features = [];
  StreetFeature? _selected;

  MapLayerLocalCache? _cache;
  Future<MapLayerLocalCache?>? _cacheFuture;

  final LinkedHashMap<String, _StreetMemoryCacheEntry> _memoryCache =
      LinkedHashMap();

  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _networkFetches = 0;
  DateTime? _lastWarmupAt;

  bool _isDisposed = false;
  Timer? _retryTimer;
  WidgetRef? _lastRef;
  MapController? _lastMapController;
  int _autoRetryCount = 0;
  static const int _maxAutoRetries = 5;

  @override
  bool get isBusy => _loading;

  @override
  String? get busyText => _loading ? 'loading_streets'.tr : null;

  @override
  String? get errorText => _error;

  bool canShow(double zoom) => zoom >= minVisibleZoom;

  List<StreetFeature> get features => _features;
  StreetFeature? get selectedStreet => _selected;

  Future<void> _restoreState() async {
    final raw = await MapLayerStateStorage.read(namespace: '${id}_state');
    if (raw == null) return;

    showLayer = raw['showLayer'] == true;
    opacity = (raw['opacity'] as num?)?.toDouble() ?? 0.95;
    strokeWidth = (raw['strokeWidth'] as num?)?.toDouble() ?? 4.0;
    minVisibleZoom = (raw['minVisibleZoom'] as num?)?.toDouble() ?? 16.0;

    notifyListeners();
  }

  Future<void> _persistState() async {
    await MapLayerStateStorage.write(
      namespace: '${id}_state',
      data: {
        'showLayer': showLayer,
        'opacity': opacity,
        'strokeWidth': strokeWidth,
        'minVisibleZoom': minVisibleZoom,
      },
    );
  }

  void _saveAndNotify() {
    notifyListeners();
    unawaited(_persistState());
  }

  Future<MapLayerLocalCache?> _ensureCache() async {
    if (!persistentCacheEnabled) return null;
    if (_cache != null) return _cache;

    _cacheFuture ??= () async {
      final cache = await MapLayerLocalCache.create(
        namespace: id,
        ttl: cacheTtl,
        maxEntries: maxCacheEntries,
      );

      _cache = cache;
      return cache;
    }();

    return _cacheFuture!;
  }

  int _zoomBucket(double zoom) => zoom.floor();

  double _gridSizeMetersForZoom(int zoomBucket) {
    if (zoomBucket >= 19) return 60;
    if (zoomBucket >= 18) return 90;
    if (zoomBucket >= 17) return 150;
    return 260;
  }

  int _featureCountForZoomBucket(int zoomBucket) {
    if (zoomBucket >= 18) return 2200;
    if (zoomBucket >= 17) return 1800;
    return 1200;
  }

  double _snapDown(double value, double step) {
    return (value / step).floorToDouble() * step;
  }

  double _snapUp(double value, double step) {
    return (value / step).ceilToDouble() * step;
  }

  _StreetProjectedBounds _snapProjectedBounds(
    _StreetProjectedBounds bounds,
    int zoomBucket,
  ) {
    final step = _gridSizeMetersForZoom(zoomBucket);

    return _StreetProjectedBounds(
      west: _snapDown(bounds.west, step),
      south: _snapDown(bounds.south, step),
      east: _snapUp(bounds.east, step),
      north: _snapUp(bounds.north, step),
    );
  }

  String _buildRequestKey(_StreetProjectedBounds bounds, int zoomBucket) {
    return [
      zoomBucket.toString(),
      bounds.west.round().toString(),
      bounds.south.round().toString(),
      bounds.east.round().toString(),
      bounds.north.round().toString(),
    ].join('|');
  }

  LatLngBounds _fetchBounds(LatLngBounds bounds) {
    final latSpan = bounds.north - bounds.south;
    final lngSpan = bounds.east - bounds.west;

    final latPadding = math.max(latSpan * 0.45, 0.0025);
    final lngPadding = math.max(lngSpan * 0.45, 0.0035);

    return LatLngBounds(
      LatLng(bounds.south - latPadding, bounds.west - lngPadding),
      LatLng(bounds.north + latPadding, bounds.east + lngPadding),
    );
  }

  bool _isTransientError(Object error) {
    final raw = error.toString().toLowerCase();

    return error is TimeoutException ||
        error is http.ClientException ||
        raw.contains('connection closed before full header was received') ||
        raw.contains('timeout') ||
        raw.contains('socketexception') ||
        raw.contains('clientexception') ||
        raw.contains('truncated'); // TCP drop mid-stream — safe to retry
  }

  bool _isFresh(DateTime savedAt) {
    return DateTime.now().difference(savedAt) <= cacheTtl;
  }

  int _estimatePayloadBytes({
    required int zoomBucket,
    required _StreetProjectedBounds projectedBounds,
    required List<StreetFeature> features,
  }) {
    final payload = {
      'zoomBucket': zoomBucket,
      'bounds': {
        'west': projectedBounds.west,
        'south': projectedBounds.south,
        'east': projectedBounds.east,
        'north': projectedBounds.north,
      },
      'features': features.map((e) => e.toJson()).toList(),
    };

    return utf8.encode(jsonEncode(payload)).length;
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

  void _rememberMemory(_StreetMemoryCacheEntry entry) {
    _memoryCache.remove(entry.key);
    _memoryCache[entry.key] = entry;
    _pruneMemory();
  }

  void _touchMemory(String key) {
    final entry = _memoryCache.remove(key);
    if (entry == null) return;

    _memoryCache[key] = entry.copyWith(
      lastUsedAt: DateTime.now(),
    );
  }

  void _pruneMemory() {
    while (_memoryCache.length > maxMemoryEntries) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
  }

  _StreetCachedPayload? _findContainingMemoryPayload({
    required _StreetProjectedBounds requestBounds,
    required int zoomBucket,
  }) {
    for (final entry in _memoryCache.values.toList().reversed) {
      if (entry.zoomBucket != zoomBucket) continue;
      if (!_isFresh(entry.savedAt)) continue;
      if (!entry.projectedBounds.contains(requestBounds)) continue;

      _touchMemory(entry.key);
      _registerCacheHit();

      return _StreetCachedPayload(
        key: entry.key,
        features: entry.features,
        savedAt: entry.savedAt,
        isFresh: true,
        isExactMatch: false, // containing bounds — triggers background refresh
        projectedBounds: entry.projectedBounds,
        zoomBucket: entry.zoomBucket,
      );
    }

    return null;
  }

  _StreetCachedPayload? _decodeCachedEntry(MapLayerCacheEntry entry) {
    final rawFeatures = (entry.data['features'] as List?) ?? const [];
    final rawBounds = entry.data['bounds'];
    final rawZoomBucket = (entry.data['zoomBucket'] as num?)?.toInt();

    if (rawBounds is! Map || rawZoomBucket == null) return null;

    final boundsMap = Map<String, dynamic>.from(rawBounds);
    final west = (boundsMap['west'] as num?)?.toDouble();
    final south = (boundsMap['south'] as num?)?.toDouble();
    final east = (boundsMap['east'] as num?)?.toDouble();
    final north = (boundsMap['north'] as num?)?.toDouble();

    if (west == null || south == null || east == null || north == null) {
      return null;
    }

    final projectedBounds = _StreetProjectedBounds(
      west: west,
      south: south,
      east: east,
      north: north,
    );

    final parsed = <StreetFeature>[];
    for (final item in rawFeatures) {
      if (item is! Map) continue;
      parsed.add(StreetFeature.fromJson(Map<String, dynamic>.from(item)));
    }

    return _StreetCachedPayload(
      key: entry.key,
      features: parsed,
      savedAt: entry.savedAt,
      isFresh: !entry.isExpired,
      isExactMatch: false, // overridden by caller for exact key matches
      projectedBounds: projectedBounds,
      zoomBucket: rawZoomBucket,
    );
  }

  Future<_StreetCachedPayload?> _readCachedPayload({
    required String requestKey,
    required _StreetProjectedBounds requestBounds,
    required int zoomBucket,
  }) async {
    final exactMemory = _memoryCache[requestKey];

    if (exactMemory != null && _isFresh(exactMemory.savedAt)) {
      _touchMemory(requestKey);
      _registerCacheHit();

      return _StreetCachedPayload(
        key: exactMemory.key,
        features: exactMemory.features,
        savedAt: exactMemory.savedAt,
        isFresh: true,
        isExactMatch: true,
        projectedBounds: exactMemory.projectedBounds,
        zoomBucket: exactMemory.zoomBucket,
      );
    }

    final containingMemory = _findContainingMemoryPayload(
      requestBounds: requestBounds,
      zoomBucket: zoomBucket,
    );

    if (containingMemory != null) {
      return containingMemory;
    }

    final cache = await _ensureCache();
    if (cache == null) {
      _registerCacheMiss();
      return null;
    }

    final exactPersistent = await cache.read(requestKey, touch: true);
    if (exactPersistent != null) {
      final decoded = _decodeCachedEntry(exactPersistent);

      if (decoded != null) {
        _rememberMemory(
          _StreetMemoryCacheEntry(
            key: requestKey,
            zoomBucket: decoded.zoomBucket,
            projectedBounds: decoded.projectedBounds,
            features: decoded.features,
            savedAt: decoded.savedAt,
            lastUsedAt: DateTime.now(),
            approxBytes: exactPersistent.approxBytes,
          ),
        );

        _registerCacheHit();
        return decoded.copyWith(isExactMatch: true);
      }
    }

    final containingPersistent = await cache.findContainingBounds(
      zoomBucket: zoomBucket,
      west: requestBounds.west,
      south: requestBounds.south,
      east: requestBounds.east,
      north: requestBounds.north,
      allowExpired: true,
      touch: true,
    );

    if (containingPersistent != null) {
      final decoded = _decodeCachedEntry(containingPersistent);

      if (decoded != null && decoded.zoomBucket == zoomBucket) {
        _rememberMemory(
          _StreetMemoryCacheEntry(
            key: containingPersistent.key,
            zoomBucket: decoded.zoomBucket,
            projectedBounds: decoded.projectedBounds,
            features: decoded.features,
            savedAt: decoded.savedAt,
            lastUsedAt: DateTime.now(),
            approxBytes: containingPersistent.approxBytes,
          ),
        );

        _registerCacheHit();
        return decoded; // isExactMatch = false → triggers background refresh
      }
    }

    _registerCacheMiss();
    return null;
  }

  Future<void> _writeCachedPayload({
    required String requestKey,
    required _StreetProjectedBounds projectedBounds,
    required int zoomBucket,
    required List<StreetFeature> features,
  }) async {
    final now = DateTime.now();
    final approxBytes = _estimatePayloadBytes(
      zoomBucket: zoomBucket,
      projectedBounds: projectedBounds,
      features: features,
    );

    _rememberMemory(
      _StreetMemoryCacheEntry(
        key: requestKey,
        zoomBucket: zoomBucket,
        projectedBounds: projectedBounds,
        features: features,
        savedAt: now,
        lastUsedAt: now,
        approxBytes: approxBytes,
      ),
    );

    final cache = await _ensureCache();

    await cache?.write(
      requestKey,
      {
        'zoomBucket': zoomBucket,
        'bounds': {
          'west': projectedBounds.west,
          'south': projectedBounds.south,
          'east': projectedBounds.east,
          'north': projectedBounds.north,
        },
        'features': features.map((e) => e.toJson()).toList(),
      },
      metadata: MapLayerCacheMetadata(
        zoomBucket: zoomBucket,
        west: projectedBounds.west,
        south: projectedBounds.south,
        east: projectedBounds.east,
        north: projectedBounds.north,
      ),
    );
  }

  Future<void> clearCache({bool clearVisibleState = false}) async {
    _memoryCache.clear();

    final cache = await _ensureCache();
    await cache?.clear();

    await MapLayerStateStorage.clear(namespace: '${id}_state');

    _cacheHits = 0;
    _cacheMisses = 0;
    _networkFetches = 0;
    _lastWarmupAt = null;

    if (clearVisibleState) {
      _clearVisibleState(resetRequestKey: true);
      showLayer = false;
      opacity = 0.95;
      strokeWidth = 4.0;
      minVisibleZoom = 16.0;
      notifyListeners();
    }
  }

  Future<void> clearCurrentViewportCache() async {
    final key = _lastRequestKey;
    if (key == null) return;

    _memoryCache.remove(key);

    final cache = await _ensureCache();
    await cache?.remove(key);

    _lastRequestKey = null;
  }

  Future<MapLayerCacheStats?> getCacheStats() async {
    final cache = await _ensureCache();
    return cache?.stats();
  }

  int _memoryBytes() {
    return _memoryCache.values.fold(
      0,
      (sum, item) => sum + item.approxBytes,
    );
  }

  void clearVisibleData() {
    _clearVisibleState(resetRequestKey: true);
  }

  void setEnabled(bool value) {
    showLayer = value;
    _error = null;

    if (!value) {
      _clearVisibleState(resetRequestKey: true);
    } else {
      _lastRequestKey = null;
      notifyListeners();
    }

    unawaited(_persistState());
  }

  void setOpacity(double value) {
    opacity = value;
    _saveAndNotify();
  }

  void setStrokeWidth(double value) {
    strokeWidth = value;
    _saveAndNotify();
  }

  void setMinVisibleZoom(double value) {
    final next = value.clamp(12.0, 20.0);

    if (minVisibleZoom == next) return;

    minVisibleZoom = next;
    _lastRequestKey = null;
    _saveAndNotify();
  }

  void clearSelectedStreet() {
    _selected = null;
    notifyListeners();
  }

  void _clearVisibleState({required bool resetRequestKey}) {
    _features = [];
    _selected = null;
    _error = null;
    _loading = false;

    if (resetRequestKey) {
      _lastRequestKey = null;
    }

    notifyListeners();
  }

  void _restoreSelectedFeature(List<StreetFeature> parsed) {
    if (_selected == null) return;

    final selectedId = _selected!.id;
    for (final feature in parsed) {
      if (feature.id == selectedId) {
        _selected = feature;
        return;
      }
    }

    _selected = null;
  }

  @override
  Future<void> refreshCurrentViewport({
    required WidgetRef ref,
    required MapController mapController,
  }) async {
    _bypassCacheOnce = true;
    _lastRequestKey = null;
    _autoRetryCount = 0; // manual refresh resets the backoff

    await onViewportChanged(
      ref: ref,
      mapController: mapController,
    );
  }

  void _scheduleAutoRetry() {
    if (_isDisposed || _autoRetryCount >= _maxAutoRetries) return;
    _autoRetryCount++;
    _retryTimer = Timer(const Duration(seconds: 3), () {
      if (_isDisposed || !showLayer) return;
      final ref = _lastRef;
      final mc = _lastMapController;
      if (ref == null || mc == null) return;
      unawaited(onViewportChanged(ref: ref, mapController: mc));
    });
  }

  @override
  Future<void> onViewportChanged({
    required WidgetRef ref,
    required MapController mapController,
  }) async {
    _lastRef = ref;
    _lastMapController = mapController;
    _retryTimer?.cancel(); // cancel pending retry — fresh viewport event takes over

    if (!showLayer) {
      if (_features.isNotEmpty ||
          _selected != null ||
          _error != null ||
          _loading ||
          _lastRequestKey != null) {
        _clearVisibleState(resetRequestKey: true);
      }
      return;
    }

    final zoom = mapController.camera.zoom;
    if (!canShow(zoom)) {
      if (_features.isNotEmpty ||
          _selected != null ||
          _error != null ||
          _loading ||
          _lastRequestKey != null) {
        _clearVisibleState(resetRequestKey: true);
      }
      return;
    }

    final zoomBucket = _zoomBucket(zoom);
    final visibleBounds = mapController.camera.visibleBounds;
    final fetchBounds = _fetchBounds(visibleBounds);

    final sw92 = geo.wgs84ToCs92(fetchBounds.southWest);
    final ne92 = geo.wgs84ToCs92(fetchBounds.northEast);

    final rawProjectedBounds = _StreetProjectedBounds(
      west: math.min(sw92.x, ne92.x),
      south: math.min(sw92.y, ne92.y),
      east: math.max(sw92.x, ne92.x),
      north: math.max(sw92.y, ne92.y),
    );

    final requestBounds = _snapProjectedBounds(rawProjectedBounds, zoomBucket);
    final requestKey = _buildRequestKey(requestBounds, zoomBucket);
    final shouldBypassCache = _bypassCacheOnce;

    _bypassCacheOnce = false;

    if (!shouldBypassCache &&
        _lastRequestKey == requestKey &&
        _error == null &&
        !_loading) {
      return;
    }

    _lastRequestKey = requestKey;
    final requestToken = ++_requestToken;

    if (!shouldBypassCache) {
      final cached = await _readCachedPayload(
        requestKey: requestKey,
        requestBounds: requestBounds,
        zoomBucket: zoomBucket,
      );

      if (requestToken != _requestToken) return;

      if (cached != null) {
        _features = cached.features;
        _restoreSelectedFeature(cached.features);
        _error = null;
        // Exact + fresh → done. Containing bounds or stale → show data
        // immediately but still fetch from network in background.
        _loading = !cached.isFresh || !cached.isExactMatch;
        notifyListeners();

        if (cached.isFresh && cached.isExactMatch) {
          return;
        }
      } else {
        _loading = true;
        _error = null;
        notifyListeners();
      }
    } else {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _registerNetworkFetch();

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'SERVICE': 'WFS',
          'VERSION': '2.0.0',
          'REQUEST': 'GetFeature',
          'TYPENAME': 'ms:prg-ulice',
          'TYPENAMES': 'ms:prg-ulice',
          'SRSNAME': 'urn:ogc:def:crs:EPSG::2180',
          'BBOX':
              '${requestBounds.west},${requestBounds.south},${requestBounds.east},${requestBounds.north},urn:ogc:def:crs:EPSG::2180',
          'COUNT': _featureCountForZoomBucket(zoomBucket).toString(),
          'STARTINDEX': '0',
          'OUTPUTFORMAT': 'application/gml+xml; version=3.2',
        },
      );

      Object? lastError;

      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          final response = await client
              .get(uri)
              .timeout(Duration(seconds: attempt == 0 ? 12 : 20));

          if (response.statusCode != 200) {
            throw Exception('Street WFS failed: ${response.statusCode}');
          }

          final rawBody = utf8.decode(response.bodyBytes, allowMalformed: true);

          if (rawBody.contains('ExceptionReport') ||
              rawBody.contains('ows:Exception') ||
              rawBody.contains('ServiceException')) {
            throw Exception('Street WFS returned exception payload');
          }

          // Detect truncated response — body cut before closing tag means
          // the TCP connection dropped mid-stream after a 200 header.
          final isComplete = rawBody.contains('</wfs:FeatureCollection>') ||
              rawBody.contains('</FeatureCollection>');
          if (!isComplete) {
            throw Exception('Street WFS response was truncated');
          }

          final parsed = _parseStreetFeaturesFromGml(rawBody);
          final allFeatures = await _fetchAllPages(
            uri: uri,
            firstPageBody: rawBody,
            firstPageFeatures: parsed,
            requestToken: requestToken,
          );

          if (requestToken != _requestToken) {
            return;
          }

          _features = allFeatures;
          _restoreSelectedFeature(allFeatures);
          _error = null;
          _loading = false;
          _autoRetryCount = 0; // reset backoff after a clean fetch

          await _writeCachedPayload(
            requestKey: requestKey,
            projectedBounds: requestBounds,
            zoomBucket: zoomBucket,
            features: allFeatures,
          );

          notifyListeners();
          return;
        } catch (e) {
          lastError = e;

          if (attempt == 0) {
            await Future.delayed(const Duration(milliseconds: 200));
            continue;
          }
        }
      }

      throw lastError ?? Exception('Unknown street layer error');
    } catch (e) {
      if (requestToken != _requestToken) return;

      final transient = _isTransientError(e);

      _loading = false;

      if (transient) {
        // Transient failure: hide error, clear key, auto-retry in 3 s.
        // Applies to both first-load (no data yet) and mid-session cuts.
        _error = null;
        _lastRequestKey = null;
        _scheduleAutoRetry();
      } else {
        _error = e.toString();
        _autoRetryCount = 0;
      }

      notifyListeners();
    }
  }

  @override
  Future<bool> onTap({
    required WidgetRef ref,
    required MapController mapController,
    required TapPosition tapPosition,
  }) async {
    if (!showLayer) return false;
    if (!canShow(mapController.camera.zoom)) return false;

    final relative = tapPosition.relative;
    if (relative == null) return false;

    final hit = _findStreetHit(mapController, relative);

    if (hit == null) {
      if (_selected != null) {
        _selected = null;
        notifyListeners();
      }
      return false;
    }

    _selected = hit;
    notifyListeners();
    return true;
  }

  int? _parseWfsNumber(String raw, String attribute) {
    final m = RegExp('$attribute="(\\d+)"').firstMatch(raw);
    return m != null ? int.tryParse(m.group(1) ?? '') : null;
  }

  /// If the WFS server returned fewer features than it has (COUNT limit hit),
  /// fetches additional pages and returns a deduplicated merged list.
  Future<List<StreetFeature>> _fetchAllPages({
    required Uri uri,
    required String firstPageBody,
    required List<StreetFeature> firstPageFeatures,
    required int requestToken,
  }) async {
    final numberMatched = _parseWfsNumber(firstPageBody, 'numberMatched');
    final numberReturned =
        _parseWfsNumber(firstPageBody, 'numberReturned') ?? firstPageFeatures.length;

    if (numberMatched == null || numberMatched <= numberReturned) {
      return firstPageFeatures;
    }

    if (numberMatched > 4000) {
      debugPrint(
        '[Street] $numberMatched features in view, limit hit — returning first $numberReturned',
      );
      return firstPageFeatures;
    }

    debugPrint('[Street] Paginating: got $numberReturned of $numberMatched — fetching rest');

    final allFeatures = List<StreetFeature>.from(firstPageFeatures);
    final seen = firstPageFeatures.map((f) => f.id).toSet();
    int startIndex = numberReturned;
    int pagesLeft = 2; // max 3 pages total → ~3000 features

    while (startIndex < numberMatched && pagesLeft > 0) {
      if (requestToken != _requestToken) return allFeatures;
      pagesLeft--;

      final pageUri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'STARTINDEX': '$startIndex',
          'COUNT': '${(numberMatched - startIndex).clamp(1, 1000)}',
        },
      );

      try {
        final r = await client.get(pageUri).timeout(const Duration(seconds: 15));
        if (r.statusCode != 200) break;

        final body = utf8.decode(r.bodyBytes, allowMalformed: true);
        if (!body.contains('</wfs:FeatureCollection>') &&
            !body.contains('</FeatureCollection>')) {
          break;
        }

        final pageParsed = _parseStreetFeaturesFromGml(body);
        for (final f in pageParsed) {
          if (seen.add(f.id)) {
            allFeatures.add(f);
          }
        }

        final pageReturned =
            _parseWfsNumber(body, 'numberReturned') ?? pageParsed.length;
        if (pageReturned == 0) break;
        startIndex += pageReturned;
      } catch (e) {
        debugPrint('[Street] Pagination page failed at STARTINDEX=$startIndex: $e');
        break;
      }
    }

    debugPrint('[Street] Pagination done: ${allFeatures.length} total features');
    return allFeatures;
  }

  List<StreetFeature> _parseStreetFeaturesFromGml(String raw) {
    final parsed = <StreetFeature>[];

    final featureRegex = RegExp(
      r'<(?:ms:)?prg-ulice\b[^>]*?(?:gml:id="([^"]+)")?[^>]*>(.*?)</(?:ms:)?prg-ulice>',
      caseSensitive: false,
      dotAll: true,
    );

    final attrRegex = RegExp(
      r'<ms:([a-zA-Z0-9_]+)>(.*?)</ms:\1>',
      caseSensitive: false,
      dotAll: true,
    );

    final posListRegex = RegExp(
      r'<gml:posList[^>]*>(.*?)</gml:posList>',
      caseSensitive: false,
      dotAll: true,
    );

    final posRegex = RegExp(
      r'<gml:pos[^>]*>(.*?)</gml:pos>',
      caseSensitive: false,
      dotAll: true,
    );

    String stripTags(String value) {
      return value
          .replaceAllMapped(
            RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true),
            (m) => m.group(1) ?? '',
          )
          .replaceAll(RegExp(r'<[^>]+>', dotAll: true), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&nbsp;', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    List<LatLng> posListToLatLng(String text) {
      final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleaned.isEmpty) return const [];

      final values = cleaned
          .split(' ')
          .map((e) => double.tryParse(e))
          .whereType<double>()
          .toList();

      if (values.length < 4) return const [];

      final points = <LatLng>[];
      for (int i = 0; i + 1 < values.length; i += 2) {
        final x = values[i];
        final y = values[i + 1];
        points.add(geo.cs92ToWgs84(x, y));
      }
      return points;
    }

    for (final featureMatch in featureRegex.allMatches(raw)) {
      final featureId =
          (featureMatch.group(1) ?? 'street_${parsed.length}').trim();
      final body = featureMatch.group(2) ?? '';

      final properties = <String, dynamic>{};

      for (final attrMatch in attrRegex.allMatches(body)) {
        final key = (attrMatch.group(1) ?? '').trim();
        final value = stripTags(attrMatch.group(2) ?? '');
        if (key.isNotEmpty && value.isNotEmpty) {
          properties[key] = value;
        }
      }

      final lines = <List<LatLng>>[];

      for (final posListMatch in posListRegex.allMatches(body)) {
        final line = posListToLatLng(posListMatch.group(1) ?? '');
        if (line.length >= 2) {
          lines.add(line);
        }
      }

      if (lines.isEmpty) {
        final singlePoints = <LatLng>[];
        for (final posMatch in posRegex.allMatches(body)) {
          final line = posListToLatLng(posMatch.group(1) ?? '');
          if (line.isNotEmpty) {
            singlePoints.addAll(line);
          }
        }
        if (singlePoints.length >= 2) {
          lines.add(singlePoints);
        }
      }

      if (lines.isEmpty) continue;

      final nameCandidates = [
        properties['cecha_i_nazwa'],
        properties['pelna_nazwa'],
        properties['ulica'],
        properties['nazwa'],
        properties['nazwa_ulicy'],
        properties['name'],
      ];

      String resolvedName = '';
      for (final candidate in nameCandidates) {
        final value = candidate?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          resolvedName = value;
          break;
        }
      }

      parsed.add(
        StreetFeature(
          id: featureId,
          name: resolvedName,
          lines: lines,
          properties: properties,
        ),
      );
    }

    return parsed;
  }

  double _distancePointToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;

    if (dx == 0 && dy == 0) {
      return (p - a).distance;
    }

    final t = (((p.dx - a.dx) * dx) + ((p.dy - a.dy) * dy)) /
        ((dx * dx) + (dy * dy));

    final clampedT = t.clamp(0.0, 1.0);
    final projection = Offset(
      a.dx + (dx * clampedT),
      a.dy + (dy * clampedT),
    );

    return (p - projection).distance;
  }

  double _tapThreshold(double zoom) {
    if (zoom >= 18.0) return 20.0;
    if (zoom >= 17.0) return 16.0;
    return 12.0;
  }

  StreetFeature? _findStreetHit(MapController mapController, Offset tapOffset) {
    if (_features.isEmpty) return null;

    final zoom = mapController.camera.zoom;
    final threshold = _tapThreshold(zoom);

    double bestDistance = double.infinity;
    StreetFeature? bestFeature;

    for (final feature in _features) {
      for (final line in feature.lines) {
        if (line.length < 2) continue;

        for (int i = 0; i < line.length - 1; i++) {
          final a = mapController.camera.latLngToScreenOffset(line[i]);
          final b = mapController.camera.latLngToScreenOffset(line[i + 1]);

          final distance = _distancePointToSegment(tapOffset, a, b);
          if (distance < bestDistance) {
            bestDistance = distance;
            bestFeature = feature;
          }
        }
      }
    }

    if (bestDistance <= threshold) {
      return bestFeature;
    }

    return null;
  }

  String _streetLabel(String key) {
    const labels = {
      'idUlicy': 'ID ulicy',
      'id_ulicy': 'ID ulicy',
      'ulica': 'Ulica',
      'nazwa': 'Nazwa',
      'name': 'Name',
      'street_name': 'Street name',
      'nazwa_ulicy': 'Nazwa ulicy',
      'cecha': 'Cecha',
      'cecha_i_nazwa': 'Pełna nazwa',
      'pelna_nazwa': 'Pełna nazwa',
      'full_name': 'Pełna nazwa',
      'teryt': 'TERYT',
      'wojewodztwo': 'Województwo',
      'powiat': 'Powiat',
      'gmina': 'Gmina',
      'miejscowosc': 'Miejscowość',
      'zrodlo': 'Źródło',
      'source': 'Źródło',
    };

    if (labels.containsKey(key)) return labels[key]!;

    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'(^\w)|(\s\w)'),
          (m) => m.group(0)!.toUpperCase(),
        );
  }

  List<MapEntry<String, String>> _orderedStreetEntries() {
    final source = _selected?.properties ?? const <String, dynamic>{};
    final entries = <MapEntry<String, String>>[];

    source.forEach((key, value) {
      final v = value?.toString().trim() ?? '';
      if (v.isEmpty) return;
      entries.add(MapEntry(key, v));
    });

    const priority = [
      'cecha_i_nazwa',
      'pelna_nazwa',
      'ulica',
      'nazwa',
      'cecha',
      'idUlicy',
      'id_ulicy',
      'teryt',
      'wojewodztwo',
      'powiat',
      'gmina',
      'miejscowosc',
      'source',
      'zrodlo',
    ];

    entries.sort((a, b) {
      final ai = priority.indexOf(a.key);
      final bi = priority.indexOf(b.key);

      if (ai == -1 && bi == -1) return a.key.compareTo(b.key);
      if (ai == -1) return 1;
      if (bi == -1) return -1;
      return ai.compareTo(bi);
    });

    return entries;
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
  List<Widget> buildLayers({
    required BuildContext context,
    required WidgetRef ref,
    required MapController mapController,
    required ThemeColors theme,
    required double zoom,
  }) {
    if (!showLayer) return const [];
    if (!canShow(zoom)) return const [];
    if (_features.isEmpty) return const [];

    final polylines = <Polyline>[];

    for (final feature in _features) {
      final isSelected = _selected?.id == feature.id;

      for (final line in feature.lines) {
        polylines.add(
          Polyline(
            points: line,
            strokeWidth: isSelected ? strokeWidth + 2.0 : strokeWidth,
            color: isSelected
                ? Colors.orangeAccent.withAlpha((opacity * 255).round())
                : theme.themeColor.withAlpha((opacity * 255).round()),
          ),
        );
      }
    }

    return [
      PolylineLayer(polylines: polylines),
    ];
  }

  @override
  List<Widget> buildOverlays({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeColors theme,
  }) {
    if (_selected == null) {
      return const [];
    }

    final entries = _orderedStreetEntries();

    return [
      SafeArea(
        minimum: const EdgeInsets.only(left: 16, bottom: 20),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 390,
              constraints: const BoxConstraints(maxHeight: 360),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.route_rounded,
                        color: theme.themeColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selected!.displayName,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: clearSelectedStreet,
                        icon: Icon(Icons.close, color: theme.textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: entries
                              .map(
                                (entry) => _buildInfoRow(
                                  _streetLabel(entry.key),
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
  void dispose() {
    _isDisposed = true;
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  String get cacheDisplayName => 'Ulice';

  @override
  String get cacheDescription =>
      'SQLite cache geometrii ulic: szybkie wyszukiwanie po boundsach, RAM cache, TTL, LRU i odświeżanie bieżącego viewportu.';

  @override
  bool get supportsMemoryCache => true;

  @override
  bool get supportsPersistentCache => persistentCacheEnabled;

  @override
  Future<AppMapCacheSummary> getCacheSummary() async {
    final cache = await _ensureCache();
    final stats = await cache?.stats();
    final stateStats =
        await MapLayerStateStorage.stats(namespace: '${id}_state');

    final memoryBytes = _memoryBytes();
    final persistentBytes = (stats?.approxBytes ?? 0) + stateStats.approxBytes;

    return AppMapCacheSummary(
      memoryEntries: _memoryCache.length,
      persistentEntries: (stats?.entries ?? 0) + (stateStats.exists ? 1 : 0),
      approxBytes: memoryBytes + persistentBytes,
      memoryBytes: memoryBytes,
      persistentBytes: persistentBytes,
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
      networkFetches: _networkFetches,
      lastWarmupAt: _lastWarmupAt,
      note:
          'Persistent cache używa SQLite. Wyszukiwanie odbywa się po boundsach bez skanowania wszystkich wpisów.',
    );
  }

  @override
  Future<void> clearMemoryCache({bool clearVisibleState = true}) async {
    _memoryCache.clear();

    if (clearVisibleState) {
      _clearVisibleState(resetRequestKey: true);
    }
  }

  @override
  Future<void> clearPersistentCache({bool clearVisibleState = false}) async {
    final cache = await _ensureCache();
    await cache?.clear();

    await MapLayerStateStorage.clear(namespace: '${id}_state');

    if (clearVisibleState) {
      _clearVisibleState(resetRequestKey: true);
      showLayer = false;
      opacity = 0.95;
      strokeWidth = 4.0;
      minVisibleZoom = 16.0;
      notifyListeners();
    }
  }

  @override
  Future<void> clearAllCache({bool clearVisibleState = true}) async {
    _memoryCache.clear();

    final cache = await _ensureCache();
    await cache?.clear();

    await MapLayerStateStorage.clear(namespace: '${id}_state');

    _cacheHits = 0;
    _cacheMisses = 0;
    _networkFetches = 0;
    _lastWarmupAt = null;

    if (clearVisibleState) {
      _clearVisibleState(resetRequestKey: true);
      showLayer = false;
      opacity = 0.95;
      strokeWidth = 4.0;
      minVisibleZoom = 16.0;
      notifyListeners();
    }
  }
}

class _StreetProjectedBounds {
  final double west;
  final double south;
  final double east;
  final double north;

  const _StreetProjectedBounds({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  bool contains(_StreetProjectedBounds other) {
    return west <= other.west &&
        south <= other.south &&
        east >= other.east &&
        north >= other.north;
  }
}

class _StreetMemoryCacheEntry {
  final String key;
  final int zoomBucket;
  final _StreetProjectedBounds projectedBounds;
  final List<StreetFeature> features;
  final DateTime savedAt;
  final DateTime lastUsedAt;
  final int approxBytes;

  const _StreetMemoryCacheEntry({
    required this.key,
    required this.zoomBucket,
    required this.projectedBounds,
    required this.features,
    required this.savedAt,
    required this.lastUsedAt,
    required this.approxBytes,
  });

  _StreetMemoryCacheEntry copyWith({
    String? key,
    int? zoomBucket,
    _StreetProjectedBounds? projectedBounds,
    List<StreetFeature>? features,
    DateTime? savedAt,
    DateTime? lastUsedAt,
    int? approxBytes,
  }) {
    return _StreetMemoryCacheEntry(
      key: key ?? this.key,
      zoomBucket: zoomBucket ?? this.zoomBucket,
      projectedBounds: projectedBounds ?? this.projectedBounds,
      features: features ?? this.features,
      savedAt: savedAt ?? this.savedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      approxBytes: approxBytes ?? this.approxBytes,
    );
  }
}

class _StreetCachedPayload {
  final String key;
  final List<StreetFeature> features;
  final DateTime savedAt;
  final bool isFresh;
  final bool isExactMatch;
  final _StreetProjectedBounds projectedBounds;
  final int zoomBucket;

  const _StreetCachedPayload({
    required this.key,
    required this.features,
    required this.savedAt,
    required this.isFresh,
    required this.isExactMatch,
    required this.projectedBounds,
    required this.zoomBucket,
  });

  _StreetCachedPayload copyWith({bool? isExactMatch}) {
    return _StreetCachedPayload(
      key: key,
      features: features,
      savedAt: savedAt,
      isFresh: isFresh,
      isExactMatch: isExactMatch ?? this.isExactMatch,
      projectedBounds: projectedBounds,
      zoomBucket: zoomBucket,
    );
  }
}