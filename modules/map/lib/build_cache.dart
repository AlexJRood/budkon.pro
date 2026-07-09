// import 'package:flutter/widgets.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_map/flutter_map.dart';

// import 'offline_city_packs_provider.dart';

// Widget buildCachedBaseTileLayer(WidgetRef ref) {
//   final service = ref.watch(offlineMapDownloadServiceProvider);
//   final state = ref.watch(offlineCityPacksProvider);

//   final tileProvider = service.getOrCreateTileProvider(
//     extraStores: state.enabledStoreNames(service),
//   );

//   return service.config.toTileLayer(
//     tileProvider: tileProvider,
//   );
// }