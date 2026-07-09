import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class PoiCategory {
  final int count;
  final String icon;
  final List<String> nearest;

  const PoiCategory({
    required this.count,
    required this.icon,
    this.nearest = const [],
  });

  factory PoiCategory.fromJson(Map<String, dynamic> j) => PoiCategory(
        count: (j['count'] as num?)?.toInt() ?? 0,
        icon: j['icon']?.toString() ?? '',
        nearest: ((j['nearest'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => e['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toList(),
      );
}

class PoiData {
  final int radiusM;
  final Map<String, PoiCategory> categories;

  const PoiData({required this.radiusM, required this.categories});

  factory PoiData.fromJson(Map<String, dynamic> j) {
    final raw = (j['categories'] as Map<String, dynamic>?) ?? {};
    return PoiData(
      radiusM: (j['radius_m'] as num?)?.toInt() ?? 1000,
      categories: raw.map(
        (k, v) => MapEntry(
          k,
          PoiCategory.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
    );
  }
}

class PoiParams {
  final String address;
  final String city;
  final int radius;

  const PoiParams({
    required this.address,
    required this.city,
    this.radius = 1000,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PoiParams &&
          address == other.address &&
          city == other.city &&
          radius == other.radius;

  @override
  int get hashCode => Object.hash(address, city, radius);
}

final reportPoiProvider = FutureProvider.family<PoiData?, PoiParams>(
  (ref, params) async {
    if (params.address.isEmpty || params.city.isEmpty) return null;
    try {
      final url = ReportsUrls.poi(
        address: params.address,
        city: params.city,
        radius: params.radius,
      );
      final response = await ApiServices.get(url, hasToken: true, ref: ref);
      if (response == null || response.statusCode != 200) {
        log('[POI] fetch failed: ${response?.statusCode}');
        return null;
      }
      final raw = _toMap(response.data);
      return PoiData.fromJson(raw);
    } catch (e) {
      log('[POI] error: $e');
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
