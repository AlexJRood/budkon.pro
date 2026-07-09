import 'dart:async';
import 'package:map/map_urls.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PortalTileCacheService {
  static const String _storeName = 'portal_browse_osm';
  static const Duration _cachedValidDuration = Duration(days: 14);
  static const String _bustVersionKey = 'portal_tile_cache_bust_version';

  static PortalTileCacheService? _instance;
  static PortalTileCacheService get instance {
    _instance ??= PortalTileCacheService._();
    return _instance!;
  }

  PortalTileCacheService._();

  bool _ready = false;
  bool _initStarted = false;

  Future<void> ensureInitialized() async {
    if (_initStarted) return;
    _initStarted = true;

    try {
      await FMTCObjectBoxBackend().initialise();
      final store = FMTCStore(_storeName);
      if (!await store.manage.ready) {
        await store.manage.create();
      }
      _ready = true;
      // Fire bust check in background — must not block startup
      unawaited(_checkAndBustIfNeeded());
    } catch (e) {
      debugPrint('[PortalTileCache] init failed, falling back to network: $e');
      _ready = false;
    }
  }

  /// Fetches the remote tile cache version and clears local tiles if it changed.
  /// Call this to force all users to reload tiles (e.g. when switching tile server).
  Future<void> _checkAndBustIfNeeded() async {
    try {
      final response = await http
          .get(Uri.parse(MapUrls.tileCacheVersion))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return;
      final remoteVersion = response.body.trim();
      if (remoteVersion.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final localVersion = prefs.getString(_bustVersionKey) ?? '';

      if (remoteVersion != localVersion) {
        await _resetStore();
        await prefs.setString(_bustVersionKey, remoteVersion);
        debugPrint(
          '[PortalTileCache] tiles busted: "$localVersion" → "$remoteVersion"',
        );
      }
    } catch (e) {
      // Non-fatal — if the endpoint doesn't exist yet or network is unavailable,
      // the cached tiles remain usable.
      debugPrint('[PortalTileCache] version check skipped: $e');
    }
  }

  Future<void> _resetStore() async {
    try {
      final store = FMTCStore(_storeName);
      if (await store.manage.ready) {
        await store.manage.reset();
      }
    } catch (e) {
      debugPrint('[PortalTileCache] store reset failed: $e');
    }
  }

  TileProvider buildProvider() {
    if (!_ready) return CancellableNetworkTileProvider();

    return FMTCTileProvider(
      stores: {_storeName: BrowseStoreStrategy.readUpdateCreate},
      loadingStrategy: BrowseLoadingStrategy.cacheFirst,
      cachedValidDuration: _cachedValidDuration,
      recordHitsAndMisses: false,
    );
  }

  void dispose() {
    _ready = false;
    _initStarted = false;
    _instance = null;
  }
}
