// import 'dart:collection';

// import 'package:flutter/widgets.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
// import 'package:get/get_utils/get_utils.dart';
// import 'package:http/http.dart' as http;

// import 'offline_city_pack_model.dart';
// import 'offline_tile_source_config.dart';

// class OfflineMapDownloadService {
//   final OfflineTileSourceConfig config;
//   final http.Client httpClient;

//   bool _initAttempted = false;
//   bool _backendAvailable = false;
//   String? _backendError;

//   final Map<String, FMTCTileProvider> _tileProviders = HashMap();

//   OfflineMapDownloadService({
//     required this.config,
//     required this.httpClient,
//   });

//   bool get backendAvailable => _backendAvailable;
//   String? get backendError => _backendError;

//   Future<bool> ensureBackendAvailable() async {
//     if (_initAttempted) return _backendAvailable;
//     _initAttempted = true;

//     try {
//       WidgetsFlutterBinding.ensureInitialized();

//       await FMTCObjectBoxBackend().initialise();

//       if (config.allowBrowseCache) {
//         final browseStore = FMTCStore(config.browseStoreName);
//         final ready = await browseStore.manage.ready;
//         if (!ready) {
//           await browseStore.manage.create();
//         }
//       }

//       _backendAvailable = true;
//       _backendError = null;
//       return true;
//     } catch (e) {
//       _backendAvailable = false;
//       _backendError = e.toString();
//       return false;
//     }
//   }

//   Future<void> initialise() async {
//     final ok = await ensureBackendAvailable();
//     if (!ok) {
//       throw StateError(
//         _backendError ?? 'offline_backend_unavailable'.tr,
//       );
//     }
//   }

//   String _providerKey(Iterable<String> extraStores) {
//     final sorted = extraStores.toList()..sort();
//     return '${config.providerId}|${sorted.join(",")}';
//   }

//   FMTCTileProvider? tryGetTileProvider({
//     Iterable<String> extraStores = const [],
//   }) {
//     if (!_backendAvailable) return null;

//     final key = _providerKey(extraStores);
//     final existing = _tileProviders[key];
//     if (existing != null) return existing;

//     final stores = <String, BrowseStoreStrategy?>{
//       if (config.allowBrowseCache)
//         config.browseStoreName: BrowseStoreStrategy.readUpdateCreate,
//       for (final name in extraStores) name: BrowseStoreStrategy.read,
//     };

//     final provider = FMTCTileProvider(
//       stores: stores,
//       loadingStrategy: BrowseLoadingStrategy.cacheFirst,
//       cachedValidDuration: config.cachedValidDuration,
//       recordHitsAndMisses: true,
//       httpClient: httpClient,
//       headers: config.headers,
//     );

//     _tileProviders[key] = provider;
//     return provider;
//   }

//   FMTCTileProvider getOrCreateTileProvider({
//     Iterable<String> extraStores = const [],
//   }) {
//     final provider = tryGetTileProvider(extraStores: extraStores);
//     if (provider == null) {
//       throw StateError(
//         _backendError ?? 'offline_backend_unavailable'.tr,
//       );
//     }
//     return provider;
//   }

//   Future<void> ensurePackStore(OfflineCityPack pack) async {
//     final ok = await ensureBackendAvailable();
//     if (!ok) {
//       throw StateError(
//         _backendError ?? 'offline_backend_unavailable'.tr,
//       );
//     }

//     final store = FMTCStore(config.cityStoreName(pack.id));
//     final ready = await store.manage.ready;
//     if (!ready) {
//       await store.manage.create();
//     }

//     await store.metadata.setBulk(
//       kvs: {
//         'packId': pack.id,
//         'title': pack.title,
//         'providerId': pack.sourceProviderId,
//         'minZoom': '${pack.minZoom}',
//         'maxZoom': '${pack.maxZoom}',
//         'west': '${pack.bounds.west}',
//         'south': '${pack.bounds.south}',
//         'east': '${pack.bounds.east}',
//         'north': '${pack.bounds.north}',
//       },
//     );
//   }

//   TileLayer _downloadTileLayerOptions() {
//     return config.toTileLayer();
//   }

//   DownloadableRegion<BaseRegion> _toDownloadableRegion(OfflineCityPack pack) {
//     final region = RectangleRegion(pack.bounds);
//     return region.toDownloadable(
//       minZoom: pack.minZoom,
//       maxZoom: pack.maxZoom,
//       options: _downloadTileLayerOptions(),
//     );
//   }

//   Future<int> estimatePackTiles(OfflineCityPack pack) async {
//     final ok = await ensureBackendAvailable();
//     if (!ok) {
//       throw StateError(
//         _backendError ?? 'offline_backend_unavailable'.tr,
//       );
//     }

//     final region = _toDownloadableRegion(pack);
//     return FMTCStore(config.cityStoreName(pack.id)).download.countTiles(region);
//   }

//   Future<({
//     Stream<DownloadProgress> downloadProgress,
//     Stream<TileEvent> tileEvents,
//   })> startPackDownload(OfflineCityPack pack) async {
//     final ok = await ensureBackendAvailable();
//     if (!ok) {
//       throw StateError(
//         _backendError ?? 'offline_backend_unavailable'.tr,
//       );
//     }

//     if (!config.allowBulkDownload) {
//       throw StateError(
//             'bulk_download_disabled_for_provider'.trParams({
//             'providerId': config.providerId
// }),
//       );
//     }

//     await ensurePackStore(pack);

//     final region = _toDownloadableRegion(pack);

//     return FMTCStore(config.cityStoreName(pack.id)).download.startForeground(
//       region: region,
//       parallelThreads: 5,
//       maxBufferLength: 300,
//       skipExistingTiles: true,
//       skipSeaTiles: true,
//       retryFailedRequestTiles: true,
//     );
//   }

//   Future<void> deletePack(OfflineCityPack pack) async {
//     final ok = await ensureBackendAvailable();
//     if (!ok) return;

//     final store = FMTCStore(config.cityStoreName(pack.id));
//     final ready = await store.manage.ready;
//     if (ready) {
//       await store.manage.delete();
//     }
//   }

//   String packStoreName(OfflineCityPack pack) => config.cityStoreName(pack.id);
// }