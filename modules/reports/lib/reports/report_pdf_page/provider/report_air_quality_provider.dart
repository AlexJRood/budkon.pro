import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class AirMeasurements {
  final double? pm10;
  final double? pm25;
  final double? no2;
  final double? o3;
  final double? so2;
  final double? co;

  const AirMeasurements({
    this.pm10,
    this.pm25,
    this.no2,
    this.o3,
    this.so2,
    this.co,
  });

  factory AirMeasurements.fromJson(Map<String, dynamic> j) => AirMeasurements(
        pm10: (j['PM10'] as num?)?.toDouble(),
        pm25: (j['PM2.5'] as num?)?.toDouble(),
        no2: (j['NO2'] as num?)?.toDouble(),
        o3: (j['O3'] as num?)?.toDouble(),
        so2: (j['SO2'] as num?)?.toDouble(),
        co: (j['CO'] as num?)?.toDouble(),
      );
}

class AirQualityStation {
  final String? name;
  final String? city;
  final String? address;

  const AirQualityStation({this.name, this.city, this.address});

  factory AirQualityStation.fromJson(Map<String, dynamic> j) =>
      AirQualityStation(
        name: j['name']?.toString(),
        city: j['city']?.toString(),
        address: j['address']?.toString(),
      );
}

class AirQualityData {
  final AirQualityStation? station;
  final double? distanceKm;
  final int? aqIndex;
  final String? aqLabel;
  final AirMeasurements measurements;
  final String source;

  const AirQualityData({
    this.station,
    this.distanceKm,
    this.aqIndex,
    this.aqLabel,
    required this.measurements,
    this.source = 'GIOŚ',
  });

  factory AirQualityData.fromJson(Map<String, dynamic> j) => AirQualityData(
        station: j['station'] != null
            ? AirQualityStation.fromJson(
                Map<String, dynamic>.from(j['station'] as Map))
            : null,
        distanceKm: (j['distance_km'] as num?)?.toDouble(),
        aqIndex: (j['aq_index'] as num?)?.toInt(),
        aqLabel: j['aq_label']?.toString(),
        measurements: j['measurements'] != null
            ? AirMeasurements.fromJson(
                Map<String, dynamic>.from(j['measurements'] as Map))
            : const AirMeasurements(),
        source: j['source']?.toString() ?? 'GIOŚ',
      );
}

class AirQualityParams {
  final String address;
  final String city;

  const AirQualityParams({required this.address, required this.city});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AirQualityParams &&
          address == other.address &&
          city == other.city;

  @override
  int get hashCode => Object.hash(address, city);
}

final reportAirQualityProvider =
    FutureProvider.family<AirQualityData?, AirQualityParams>(
  (ref, params) async {
    if (params.address.isEmpty || params.city.isEmpty) return null;
    try {
      final url = ReportsUrls.airQuality(address: params.address, city: params.city);
      final response = await ApiServices.get(url, hasToken: true, ref: ref);
      if (response == null || response.statusCode != 200) {
        log('[AirQuality] fetch failed: ${response?.statusCode}');
        return null;
      }
      final raw = _toMap(response.data);
      return AirQualityData.fromJson(raw);
    } catch (e) {
      log('[AirQuality] error: $e');
      return null;
    }
  },
);

Map<String, dynamic> _toMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String) return json.decode(data) as Map<String, dynamic>;
  if (data is Uint8List) return json.decode(utf8.decode(data)) as Map<String, dynamic>;
  throw FormatException('Unsupported type: ${data.runtimeType}');
}
