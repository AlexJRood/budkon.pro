import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

import 'package:network_monitoring/models/nm_map_pins.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/screens/map/map_state.dart';

import 'package:network_monitoring/models/monitoring_ads_model.dart';


const int nmMapAdsPageSize = 200;

final networkMonitoringMapAdvertisementsProvider =
    FutureProvider.autoDispose<List<MonitoringAdsModel>>((ref) async {
  final viewport = ref.watch(nmMapViewportProvider);

  // ma odświeżać się po zmianie filtrów
  ref.watch(networkMonitoringFilterProvider);

  if (!viewport.isReady) {
    return [];
  }

  return ref.read(networkMonitoringFilterProvider.notifier).fetchAdvertisementsNM(
    1,
    nmMapAdsPageSize,
    extraQueryParameters: {
      'bbox': viewport.bbox!,
      if (viewport.polygon.length >= 3)
        'polygon': viewport.polygon
            .map((p) => '${p.latitude},${p.longitude}')
            .join('|'),
    },
  );
});

String _latLngListToPolygonString(List<LatLng> points) {
  return points.map((p) => '${p.latitude},${p.longitude}').join('|');
}

Map<String, dynamic> _normalizeQueryParams(Map<String, dynamic> raw) {
  final result = <String, dynamic>{};

  raw.forEach((key, value) {
    if (value == null) return;

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      result[key] = trimmed;
      return;
    }

    if (value is Iterable) {
      final cleaned = value
          .map((e) => e?.toString().trim())
          .where((e) => e != null && e!.isNotEmpty)
          .cast<String>()
          .toList();

      if (cleaned.isEmpty) return;
      result[key] = cleaned.join(',');
      return;
    }

    result[key] = value;
  });

  return result;
}

Map<dynamic, dynamic> _decodeResponseMap(dynamic rawBody) {
  dynamic decoded;

  if (rawBody is List<int>) {
    decoded = json.decode(utf8.decode(rawBody));
  } else if (rawBody is String) {
    decoded = json.decode(rawBody);
  } else {
    decoded = rawBody;
  }

  return decoded as Map<dynamic, dynamic>;
}

final networkMonitoringMapPinsProvider =
    FutureProvider.autoDispose<List<NetworkMonitoringMapPinModel>>((ref) async {
  final viewport = ref.watch(nmMapViewportProvider);
  final refresh = ref.watch(nmMapPinsRefreshTriggerProvider);
  final filters = ref.watch(networkMonitoringMapFiltersProvider);

  if (!viewport.isReady && viewport.polygon.length < 3) {
    if (kDebugMode) {
      debugPrint(
        '[networkMonitoringMapPinsProvider] skip fetch: viewport not ready and polygon too small',
      );
    }
    return [];
  }

  final query = <String, dynamic>{
    ..._normalizeQueryParams(filters),
    'limit': 1000,
  };

  if (viewport.bbox != null && viewport.bbox!.isNotEmpty) {
    query['bbox'] = viewport.bbox;
  }

  if (viewport.polygon.length >= 3) {
    query['polygon'] = _latLngListToPolygonString(viewport.polygon);
  }

  // Force dependency tracking / refresh by trigger.
  // ignore: unused_local_variable
  final _ = refresh;

  if (kDebugMode) {
    debugPrint('[networkMonitoringMapPinsProvider] queryParameters: $query');
  }

  final response = await ApiServices.get(
    ref: ref,
    URLs.networkMonitoringMapPins,
    hasToken: true,
    queryParameters: query,
  );

  if (response == null) {
    if (kDebugMode) {
      debugPrint('[networkMonitoringMapPinsProvider] response is null');
    }
    return [];
  }

  if (response.statusCode != 200) {
    if (kDebugMode) {
      debugPrint(
        '[networkMonitoringMapPinsProvider] bad response status: ${response.statusCode}',
      );
    }
    return [];
  }

  final data = _decodeResponseMap(response.data);
  final rawResults = data['results'];

  if (rawResults is! List) {
    if (kDebugMode) {
      debugPrint('[networkMonitoringMapPinsProvider] results is not a List');
    }
    return [];
  }

  return rawResults
      .whereType<Map>()
      .map((item) => NetworkMonitoringMapPinModel.fromJson(
            Map<String, dynamic>.from(item),
          ))
      .toList();
});