import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';


final userLocationProvider = StateProvider<LatLng?>((ref) => null);

final userLocationFutureProvider = FutureProvider<LatLng?>((ref) async {
  Position position = await Geolocator.getCurrentPosition();
  return LatLng(position.latitude, position.longitude);
});
