// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:get/get_utils/get_utils.dart';
// import 'offline_city_pack_model.dart';
// import 'offline_city_pack_registry.dart';
// import 'offline_map_download_service.dart';
// import 'offline_tile_source_config.dart';
// import 'package:flutter_map/flutter_map.dart';


// final offlineTileSourceConfigProvider =
//     Provider<OfflineTileSourceConfig>((ref) {
//   // Swap this provider later to your self-hosted / paid tile source.
//   return portalPublicOsmTileSource;
// });

// final offlineMapDownloadServiceProvider =
//     Provider<OfflineMapDownloadService>((ref) {
//   final config = ref.watch(offlineTileSourceConfigProvider);
//   final service = OfflineMapDownloadService(
//     config: config,
//     httpClient: http.Client(),
//   );

//   ref.onDispose(() {
//     service.httpClient.close();
//   });

//   return service;
// });

// @immutable
// class OfflineCityPacksState {
//   final bool loading;
//   final bool busy;
//   final String? error;
//   final List<OfflineCityPack> packs;

//   const OfflineCityPacksState({
//     this.loading = false,
//     this.busy = false,
//     this.error,
//     this.packs = const [],
//   });

//   OfflineCityPacksState copyWith({
//     bool? loading,
//     bool? busy,
//     String? error,
//     List<OfflineCityPack>? packs,
//     bool clearError = false,
//   }) {
//     return OfflineCityPacksState(
//       loading: loading ?? this.loading,
//       busy: busy ?? this.busy,
//       error: clearError ? null : (error ?? this.error),
//       packs: packs ?? this.packs,
//     );
//   }

//   List<String> enabledStoreNames(OfflineMapDownloadService service) {
//     return packs
//         .where((e) =>
//             e.enabledForBrowsing &&
//             e.status == OfflineCityPackStatus.downloaded)
//         .map(service.packStoreName)
//         .toList();
//   }
// }

// final offlineCityPacksProvider =
//     StateNotifierProvider<OfflineCityPacksController, OfflineCityPacksState>(
//   (ref) => OfflineCityPacksController(
//     service: ref.watch(offlineMapDownloadServiceProvider),
//   )..load(),
// );

// class OfflineCityPacksController extends StateNotifier<OfflineCityPacksState> {
//   final OfflineMapDownloadService service;

//   OfflineCityPacksController({
//     required this.service,
//   }) : super(const OfflineCityPacksState());

// Future<void> load() async {
//   state = state.copyWith(loading: true, clearError: true);

//   try {
//     final ok = await service.ensureBackendAvailable();
//     if (!ok) {
//       state = state.copyWith(
//         loading: false,
//         packs: const [],
//         error: 'offline_cache_backend_unavailable'.tr,
//       );
//       return;
//     }

//     final packs = await OfflineCityPackRegistry.readAll();

//     state = state.copyWith(
//       loading: false,
//       packs: packs
//           .where((e) => e.sourceProviderId == service.config.providerId)
//           .toList(),
//     );
//   } catch (e) {
//     state = state.copyWith(
//       loading: false,
//       error: 'failed_to_load_offline_packs'.tr,
//     );
//   }
// }

//   Future<void> _persist(List<OfflineCityPack> packs) async {
//     final all = await OfflineCityPackRegistry.readAll();
//     final filtered =
//         all.where((e) => e.sourceProviderId != service.config.providerId).toList();
//     await OfflineCityPackRegistry.writeAll([...filtered, ...packs]);
//   }

//   Future<void> addViewportPack({
//     required String title,
//     required LatLngBounds bounds,
//     int minZoom = 12,
//     int maxZoom = 16,
//   }) async {
//     final id = '${DateTime.now().millisecondsSinceEpoch}';

//     final pack = OfflineCityPack(
//       id: id,
//       sourceProviderId: service.config.providerId,
//       title: title,
//       bounds: bounds,
//       minZoom: minZoom,
//       maxZoom: maxZoom,
//       status: OfflineCityPackStatus.idle,
//     );

//     final next = [...state.packs, pack];
//     await _persist(next);
//     state = state.copyWith(packs: next, clearError: true);
//   }

//   Future<void> estimate(String packId) async {
//     final index = state.packs.indexWhere((e) => e.id == packId);
//     if (index == -1) return;

//     final original = state.packs[index];
//     final working = original.copyWith(
//       status: OfflineCityPackStatus.estimating,
//       clearErrorMessage: true,
//     );

//     final temp = [...state.packs]..[index] = working;
//     state = state.copyWith(packs: temp, clearError: true);

//     try {
//       final tiles = await service.estimatePackTiles(working);

//       final updated = working.copyWith(
//         status: OfflineCityPackStatus.readyToDownload,
//         estimatedTiles: tiles,
//       );

//       final next = [...state.packs]..[index] = updated;
//       await _persist(next);
//       state = state.copyWith(packs: next);
//     } catch (e) {
//       final failed = working.copyWith(
//         status: OfflineCityPackStatus.failed,
//         errorMessage: e.toString(),
//       );

//       final next = [...state.packs]..[index] = failed;
//       await _persist(next);
//       state = state.copyWith(packs: next, error: e.toString());
//     }
//   }

//   Future<void> download(String packId) async {
//     final index = state.packs.indexWhere((e) => e.id == packId);
//     if (index == -1) return;

//     var pack = state.packs[index];
//     if (pack.estimatedTiles == null) {
//       await estimate(packId);
//       final refreshedIndex = state.packs.indexWhere((e) => e.id == packId);
//       if (refreshedIndex == -1) return;
//       pack = state.packs[refreshedIndex];
//       if (pack.status == OfflineCityPackStatus.failed) return;
//     }

//     final downloading = pack.copyWith(
//       status: OfflineCityPackStatus.downloading,
//       progress01: 0,
//       downloadedTiles: 0,
//       clearErrorMessage: true,
//     );

//     var next = [...state.packs];
//     next[index] = downloading;
//     state = state.copyWith(busy: true, packs: next, clearError: true);

//     final done = Completer<void>();
//     StreamSubscription? progressSub;
//     StreamSubscription? tileSub;

//     try {
//       final streams = await service.startPackDownload(downloading);

//       progressSub = streams.downloadProgress.listen(
//         (progress) async {
//           final currentIndex = state.packs.indexWhere((e) => e.id == packId);
//           if (currentIndex == -1) return;

//           final current = state.packs[currentIndex];
//           final updated = current.copyWith(
//             status: OfflineCityPackStatus.downloading,
//             progress01: ((progress?.percentageProgress ?? 0) / 100.0).clamp(0, 1),
//             downloadedTiles: progress?.successfulTilesCount,
//             estimatedTiles: progress?.maxTilesCount,
//           );

//           final currentPacks = [...state.packs]..[currentIndex] = updated;
//           state = state.copyWith(packs: currentPacks);
//         },
//         onDone: () {
//           if (!done.isCompleted) done.complete();
//         },
//         onError: (error, stack) {
//           if (!done.isCompleted) done.completeError(error, stack);
//         },
//       );

//       tileSub = streams.tileEvents.listen((_) {});

//       await done.future;

//       final currentIndex = state.packs.indexWhere((e) => e.id == packId);
//       if (currentIndex != -1) {
//         final finished = state.packs[currentIndex].copyWith(
//           status: OfflineCityPackStatus.downloaded,
//           progress01: 1,
//           lastDownloadedAt: DateTime.now(),
//           enabledForBrowsing: true,
//         );

//         next = [...state.packs]..[currentIndex] = finished;
//         await _persist(next);
//         state = state.copyWith(
//           busy: false,
//           packs: next,
//         );
//       } else {
//         state = state.copyWith(busy: false);
//       }
//     } catch (e) {
//       final currentIndex = state.packs.indexWhere((item) => item.id == packId);
//       if (currentIndex != -1) {
//         final failed = state.packs[currentIndex].copyWith(
//           status: OfflineCityPackStatus.failed,
//           errorMessage: e.toString(),
//         );
//         next = [...state.packs]..[currentIndex] = failed;
//         await _persist(next);
//         state = state.copyWith(
//           busy: false,
//           packs: next,
//           error: e.toString(),
//         );
//       } else {
//         state = state.copyWith(busy: false, error: e.toString());
//       }
//     } finally {
//       await progressSub?.cancel();
//       await tileSub?.cancel();
//     }
//   }

//   Future<void> remove(String packId) async {
//     final pack = state.packs.where((e) => e.id == packId).firstOrNull;
//     if (pack == null) return;

//     await service.deletePack(pack);

//     final next = state.packs.where((e) => e.id != packId).toList();
//     await _persist(next);
//     state = state.copyWith(packs: next);
//   }

//   Future<void> setEnabled(String packId, bool enabled) async {
//     final index = state.packs.indexWhere((e) => e.id == packId);
//     if (index == -1) return;

//     final nextPack = state.packs[index].copyWith(enabledForBrowsing: enabled);
//     final next = [...state.packs]..[index] = nextPack;
//     await _persist(next);
//     state = state.copyWith(packs: next);
//   }
// }