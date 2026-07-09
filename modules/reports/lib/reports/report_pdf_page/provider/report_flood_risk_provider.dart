import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class FloodZoneInfo {
  final bool inFloodZone;
  final List<String> zones;
  final String? worstZone;

  const FloodZoneInfo({
    required this.inFloodZone,
    required this.zones,
    this.worstZone,
  });

  factory FloodZoneInfo.fromJson(Map<String, dynamic> j) => FloodZoneInfo(
        inFloodZone: j['in_flood_zone'] as bool? ?? false,
        zones: List<String>.from(j['zones'] as List? ?? []),
        worstZone: j['worst_zone']?.toString(),
      );
}

class NearestStation {
  final String? stationName;
  final String? riverName;
  final double? distanceKm;
  final double? waterLevelCm;
  final double? alarmLevelCm;
  final double? warningLevelCm;
  final String levelStatus;

  const NearestStation({
    this.stationName,
    this.riverName,
    this.distanceKm,
    this.waterLevelCm,
    this.alarmLevelCm,
    this.warningLevelCm,
    this.levelStatus = 'unknown',
  });

  factory NearestStation.fromJson(Map<String, dynamic> j) => NearestStation(
        stationName: j['station_name']?.toString(),
        riverName: j['river_name']?.toString(),
        distanceKm: (j['distance_km'] as num?)?.toDouble(),
        waterLevelCm: (j['water_level_cm'] as num?)?.toDouble(),
        alarmLevelCm: (j['alarm_level_cm'] as num?)?.toDouble(),
        warningLevelCm: (j['warning_level_cm'] as num?)?.toDouble(),
        levelStatus: j['level_status']?.toString() ?? 'unknown',
      );
}

class FloodRiskData {
  final String overallRisk;
  final String? proximityRisk;
  final FloodZoneInfo? floodZone;
  final NearestStation? nearestStation;
  final String source;

  const FloodRiskData({
    required this.overallRisk,
    this.proximityRisk,
    this.floodZone,
    this.nearestStation,
    this.source = 'IMGW-PIB + ISOK',
  });

  factory FloodRiskData.fromJson(Map<String, dynamic> j) => FloodRiskData(
        overallRisk: j['overall_risk']?.toString() ?? 'unknown',
        proximityRisk: j['proximity_risk']?.toString(),
        floodZone: j['flood_zone'] != null
            ? FloodZoneInfo.fromJson(
                Map<String, dynamic>.from(j['flood_zone'] as Map))
            : null,
        nearestStation: j['nearest_station'] != null
            ? NearestStation.fromJson(
                Map<String, dynamic>.from(j['nearest_station'] as Map))
            : null,
        source: j['source']?.toString() ?? 'IMGW-PIB + ISOK',
      );
}

class FloodRiskParams {
  final String address;
  final String city;

  const FloodRiskParams({required this.address, required this.city});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FloodRiskParams &&
          address == other.address &&
          city == other.city;

  @override
  int get hashCode => Object.hash(address, city);
}

final reportFloodRiskProvider =
    FutureProvider.family<FloodRiskData?, FloodRiskParams>(
  (ref, params) async {
    if (params.address.isEmpty || params.city.isEmpty) return null;
    try {
      final url = ReportsUrls.floodRisk(address: params.address, city: params.city);
      final response = await ApiServices.get(url, hasToken: true, ref: ref);
      if (response == null || response.statusCode != 200) {
        log('[FloodRisk] fetch failed: ${response?.statusCode}');
        return null;
      }
      final raw = _toMap(response.data);
      return FloodRiskData.fromJson(raw);
    } catch (e) {
      log('[FloodRisk] error: $e');
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
