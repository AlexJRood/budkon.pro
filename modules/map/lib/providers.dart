import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:map/property_price_layer_service.dart';

import 'fiber_layer_service.dart';
import 'gesut_layer_service.dart';
import 'map_geo_service.dart';
import 'mpzp_layer_service.dart';
import 'parcel_layer_service.dart';
import 'street_layer_service.dart';

import 'package:flutter_map/flutter_map.dart';
import 'land_use_layer_service.dart';
import 'bdot_layer_service.dart';
import 'bdot_categories_layer_service.dart';

final bdotCategoriesLayerServiceProvider =
    Provider<BdotCategoriesLayerService>((ref) {
  final service = BdotCategoriesLayerService();
  ref.onDispose(service.dispose);
  return service;
});

final mapGeoServiceProvider = Provider<MapGeoService>(
  (ref) => const MapGeoService(),
);

/// Shared HTTP client for all GUGIK WMS/WFS services (same host pool).
final gugikHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final parcelLayerServiceProvider = Provider<ParcelLayerService>((ref) {
  final service = ParcelLayerService(
    client: ref.watch(gugikHttpClientProvider),
    geo: ref.read(mapGeoServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final portalMapControllerProvider =
    StateProvider<MapController?>((ref) => null);

final streetLayerServiceProvider = Provider<StreetLayerService>((ref) {
  final service = StreetLayerService(
    client: ref.watch(gugikHttpClientProvider),
    geo: ref.read(mapGeoServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final mpzpLayerServiceProvider = Provider<MpzpLayerService>((ref) {
  final service = MpzpLayerService();
  ref.onDispose(service.dispose);
  return service;
});

final gesutLayerServiceProvider = Provider<GesutLayerService>((ref) {
  final service = GesutLayerService();
  ref.onDispose(service.dispose);
  return service;
});

final landUseLayerServiceProvider = Provider<LandUseLayerService>((ref) {
  final service = LandUseLayerService(
    client: ref.watch(gugikHttpClientProvider),
    geo: ref.read(mapGeoServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final propertyPriceLayerServiceProvider =
    Provider<PropertyPriceLayerService>((ref) {
  final service = PropertyPriceLayerService(
    client: ref.watch(gugikHttpClientProvider),
    geo: ref.read(mapGeoServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});


final bdotLayerServiceProvider = Provider<BdotLayerService>((ref) {
  final service = BdotLayerService();

  ref.onDispose(service.dispose);

  return service;
});

final fiberLayerServiceProvider = Provider<FiberLayerService>((ref) {
  final service = FiberLayerService();
  ref.onDispose(service.dispose);
  return service;
});