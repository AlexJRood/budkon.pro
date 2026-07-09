import 'package:latlong2/latlong.dart';
import "package:flutter_map/flutter_map.dart";

class MapPinClusterBbox {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const MapPinClusterBbox({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  factory MapPinClusterBbox.fromJson(Map<String, dynamic> json) {
    return MapPinClusterBbox(
      minLat: (json['min_lat'] as num).toDouble(),
      maxLat: (json['max_lat'] as num).toDouble(),
      minLon: (json['min_lon'] as num).toDouble(),
      maxLon: (json['max_lon'] as num).toDouble(),
    );
  }

  LatLngBounds toBounds() {
    return LatLngBounds(
      LatLng(minLat, minLon),
      LatLng(maxLat, maxLon),
    );
  }

  bool get isValid =>
      minLat.isFinite &&
      maxLat.isFinite &&
      minLon.isFinite &&
      maxLon.isFinite &&
      minLat <= maxLat &&
      minLon <= maxLon;
}

class MapPinModel {
  final int id;
  final String? slug;
  final double lat;
  final double lon;
  final String title;
  final double? price;
  final String? currency;
  final bool isPremium;
  final bool isArchive;
  final String? thumb;
  final String? url;

  final bool isCluster;
  final int clusterCount;
  final String? clusterKey;
  final MapPinClusterBbox? clusterBbox;

  const MapPinModel({
    required this.id,
    required this.lat,
    required this.lon,
    required this.title,
    required this.isPremium,
    required this.isArchive,
    this.slug,
    this.price,
    this.currency,
    this.thumb,
    this.url,
    this.isCluster = false,
    this.clusterCount = 1,
    this.clusterKey,
    this.clusterBbox,
  });

  LatLng get point => LatLng(lat, lon);

  bool get isSingleOffer => !isCluster;

  String get uniqueKey {
    if (isCluster) {
      final stableClusterKey =
          clusterKey ??
          'cluster_${lat.toStringAsFixed(6)}_${lon.toStringAsFixed(6)}_$clusterCount';
      return stableClusterKey;
    }
    return 'pin_$id';
  }

  factory MapPinModel.fromJson(Map<String, dynamic> json) {
    final rawClusterBbox = json['cluster_bbox'];
    final parsedId = json['id'];

    return MapPinModel(
      id: parsedId is int ? parsedId : int.parse(parsedId.toString()),
      slug: json['slug']?.toString(),
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      title: (json['title'] ?? '').toString(),
      price: json['price'] == null ? null : (json['price'] as num).toDouble(),
      currency: json['currency']?.toString(),
      isPremium: json['is_premium'] == true,
      isArchive: json['isArchive'] == true,
      thumb: json['thumb']?.toString(),
      url: json['url']?.toString(),
      isCluster: json['isCluster'] == true,
      clusterCount: json['cluster_count'] is int
          ? json['cluster_count'] as int
          : int.tryParse('${json['cluster_count']}') ?? 1,
      clusterKey: json['cluster_key']?.toString(),
      clusterBbox: rawClusterBbox is Map<String, dynamic>
          ? MapPinClusterBbox.fromJson(rawClusterBbox)
          : rawClusterBbox is Map
          ? MapPinClusterBbox.fromJson(
              rawClusterBbox.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
          : null,
    );
  }
}