import 'dart:convert';
import 'package:portal/portal_urls.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:map/map_pin_model.dart';
import 'package:map/map_state.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/platform/api_services.dart';

String _valueAsString(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

String _buildAddressFromFilters(Map<String, dynamic> filters) {
  final street = _valueAsString(filters['street']);
  final district = _valueAsString(filters['district']);
  final city = _valueAsString(filters['city']);
  final state = _valueAsString(filters['state']);
  final zipcode = _valueAsString(filters['zipcode']);
  final country = _valueAsString(filters['country']);

  final parts = <String>[
    if (street.isNotEmpty) street,
    if (district.isNotEmpty) district,
    if (city.isNotEmpty) city,
    if (state.isNotEmpty) state,
    if (zipcode.isNotEmpty) zipcode,
    if (country.isNotEmpty) country,
  ];

  return parts.join(', ');
}

double _estimateZoomFromFilters(Map<String, dynamic> filters) {
  final street = _valueAsString(filters['street']);
  final district = _valueAsString(filters['district']);
  final city = _valueAsString(filters['city']);
  final state = _valueAsString(filters['state']);
  final zipcode = _valueAsString(filters['zipcode']);
  final country = _valueAsString(filters['country']);

  if (street.isNotEmpty || zipcode.isNotEmpty) return 14.0;
  if (district.isNotEmpty) return 12.5;
  if (city.isNotEmpty) return 11.0;
  if (state.isNotEmpty) return 8.5;
  if (country.isNotEmpty) return 6.8;

  return 6.2;
}

Future<LatLng?> getCoordinatesFromAddress(String address, Ref ref) async {
  if (address.trim().isEmpty) return null;

  final encodedAddress = Uri.encodeComponent(address);

  try {
    final response = await ApiServices.get(
      ref: ref,
      PortalUrls.nominatimMap(encodedAddress),
      hasToken: false,
      headers: {'User-Agent': 'Hously1.0'},
    );

    if (response != null && response.statusCode == 200) {
      dynamic decoded;
      final body = response.data;

      if (body is List<int>) {
        decoded = json.decode(utf8.decode(body));
      } else if (body is String) {
        decoded = json.decode(body);
      } else {
        decoded = body;
      }

      if (decoded is List && decoded.isNotEmpty) {
        final first = Map<String, dynamic>.from(decoded.first);
        final lat = double.tryParse(first['lat']?.toString() ?? '');
        final lon = double.tryParse(first['lon']?.toString() ?? '');

        if (lat != null && lon != null) {
          return LatLng(lat, lon);
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[getCoordinatesFromAddress] error for "$address": $e');
    }
  }

  return null;
}

final resolvedDefaultMapTargetProvider =
    FutureProvider<MapInitialTarget>((ref) async {
  final filterState = ref.watch(filterCacheProvider);
  final userLocation = ref.watch(userLocationProvider);

  final rawFilters = filterState['filters'];
  final filters = rawFilters is Map
      ? Map<String, dynamic>.from(rawFilters)
      : <String, dynamic>{};

  final addressFromFilters = _buildAddressFromFilters(filters);

  if (addressFromFilters.isNotEmpty) {
    final coords = await getCoordinatesFromAddress(addressFromFilters, ref);
    if (coords != null) {
      return MapInitialTarget(
        center: coords,
        zoom: _estimateZoomFromFilters(filters),
        source: 'filters',
        signature: 'filters:$addressFromFilters',
      );
    }
  }

  if (userLocation != null) {
    return MapInitialTarget(
      center: userLocation,
      zoom: 13.0,
      source: 'user',
      signature:
          'user:${userLocation.latitude.toStringAsFixed(5)},${userLocation.longitude.toStringAsFixed(5)}',
    );
  }

  return polandDefaultMapTarget;
});

final mapPinsProvider =
    FutureProvider.autoDispose<List<MapPinModel>>((ref) async {
  final viewport = ref.watch(mapViewportProvider);

  ref.watch(filterCacheProvider);
  ref.watch(mapPinsRefreshTriggerProvider);

  if (!viewport.isReady) {
    return [];
  }

  final cache = ref.read(filterCacheProvider.notifier);

  final queryParameters = <String, dynamic>{
    ...cache.filters,
    ...cache.getSearchParams(),
    if (cache.sortOrder.isNotEmpty) 'sort': cache.sortOrder,
    'currency': cache.selectedCurrency,
    'bbox': viewport.bbox!,
    'limit': 5000,
    if (viewport.polygon.length >= 3)
      'polygon': viewport.polygon
          .map((p) => '${p.latitude},${p.longitude}')
          .join('|'),
  };

  if (kDebugMode) {
    debugPrint('[mapPinsProvider] queryParameters: $queryParameters');
  }

  final response = await ApiServices.get(
    ref: ref,
    PortalUrls.apiAdvertisementsMapPins,
    hasToken: true,
    queryParameters: queryParameters,
  );

  if (response == null || response.statusCode != 200) {
    throw Exception('Failed to load map pins');
  }

  dynamic decoded;
  final body = response.data;

  if (body is List<int>) {
    decoded = json.decode(utf8.decode(body));
  } else if (body is String) {
    decoded = json.decode(body);
  } else {
    decoded = body;
  }

  final results = (decoded['results'] as List<dynamic>? ?? [])
      .map((e) => MapPinModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  results.sort((a, b) {
    if (a.isPremium == b.isPremium) {
      return a.id.compareTo(b.id);
    }
    return a.isPremium ? -1 : 1;
  });

  return results;
});