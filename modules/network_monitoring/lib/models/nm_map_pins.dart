import 'package:map/map_pin_model.dart';

class NetworkMonitoringMapPinModel {
  final int id;
  final double lat;
  final double lon;
  final bool isArchive;
  final String title;
  final double? price;
  final String? currency;
  final String? estateType;
  final String? offerType;
  final bool isPremium;
  final double? squareFootage;
  final double? pricePerM2;
  final String? thumb;
  final String? url;

  final bool isCluster;
  final int clusterCount;
  final String? clusterKey;
  final MapPinClusterBbox? clusterBbox;

  const NetworkMonitoringMapPinModel({
    required this.id,
    required this.lat,
    required this.lon,
    required this.isArchive,
    required this.title,
    required this.isPremium,
    this.price,
    this.currency,
    this.estateType,
    this.offerType,
    this.squareFootage,
    this.pricePerM2,
    this.thumb,
    this.url,
    this.isCluster = false,
    this.clusterCount = 1,
    this.clusterKey,
    this.clusterBbox,
  });

  factory NetworkMonitoringMapPinModel.fromJson(Map<String, dynamic> json) {
    final rawClusterBbox = json['cluster_bbox'];

    return NetworkMonitoringMapPinModel(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      isArchive: json['isArchive'] == true,
      title: (json['title'] ?? '').toString(),
      price: json['price'] == null ? null : (json['price'] as num).toDouble(),
      currency: json['currency']?.toString(),
      estateType: json['estate_type']?.toString(),
      offerType: json['offer_type']?.toString(),
      isPremium: json['is_premium'] == true,
      squareFootage: json['square_footage'] == null
          ? null
          : (json['square_footage'] as num).toDouble(),
      pricePerM2: json['price_per_m2'] == null
          ? null
          : (json['price_per_m2'] as num).toDouble(),
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