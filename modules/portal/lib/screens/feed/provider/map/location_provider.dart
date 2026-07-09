import 'dart:convert';
import 'package:portal/portal_urls.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:core/platform/api_services.dart';
import 'package:latlong2/latlong.dart';

import 'package:get/get_utils/get_utils.dart';

final userLocationProvider = StateProvider<LatLng?>((ref) => null);

final locationProvider =
    Provider<LocationService>((ref) => LocationService(ref));

class LocationService {
  final Ref ref;

  LocationService(this.ref);

  Future<void> determinePosition({String? address}) async {
    LatLng? coordinates;

    // Jeśli jest podany adres, użyj go do ustalenia lokalizacji
    if (address != null && address.isNotEmpty) {
      coordinates = await getCoordinatesFromAddress(address);
      if (coordinates != null) {
        ref.read(userLocationProvider.notifier).state = coordinates;
        return;
      }
    }

    // Sprawdzenie i zarządzanie dostępem do lokalizacji urządzenia
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setDefaultLocation();
      return Future.error(
          'location_services_disabled_default_location_set'.tr);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setDefaultLocation();
        return Future.error(
            'location_permission_denied_default_location_set'.tr);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _setDefaultLocation();
      return Future.error(
          'location_permission_permanently_denied_default_location_set'.tr);
    }

    Position position = await Geolocator.getCurrentPosition();
    ref.read(userLocationProvider.notifier).state =
        LatLng(position.latitude, position.longitude);
  }

  void _setDefaultLocation() {
    ref.read(userLocationProvider.notifier).state =
        const LatLng(52.229676, 21.012229); // Współrzędne Warszawy
  }

  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    final String encodedAddress = Uri.encodeComponent(address);

    try {
      final response = await ApiServices.get(
        ref:ref,
        PortalUrls.nominatimMap(encodedAddress),
        headers: {
          'User-Agent': 'Hously1.0',
        },
      );

      if (response != null && response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.data);
        if (data.isNotEmpty) {
          final Map<String, dynamic> firstResult = data.first;
          final double lat = double.parse(firstResult['lat']);
          final double lon = double.parse(firstResult['lon']);
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      // Handle exception
    }

    return null;
  }
}
