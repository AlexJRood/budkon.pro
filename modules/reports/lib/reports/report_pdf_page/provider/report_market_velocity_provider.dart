import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reports/reports/dashboard_report/models/dashboard_data_model.dart';
import 'package:core/platform/api_services.dart';

class ReportVelocityParams {
  final String? city;
  final String? state;
  final String? country;
  final String? estateType;

  const ReportVelocityParams({
    this.city,
    this.state,
    this.country,
    this.estateType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportVelocityParams &&
          city == other.city &&
          state == other.state &&
          country == other.country &&
          estateType == other.estateType;

  @override
  int get hashCode => Object.hash(city, state, country, estateType);
}

final reportMarketVelocityProvider = FutureProvider.family<MarketVelocity?, ReportVelocityParams>(
  (ref, params) async {
    try {
      final url = ReportsUrls.marketVelocityForReport(
        city: params.city,
        state: params.state,
        country: params.country,
        estateType: params.estateType,
      );

      final response = await ApiServices.get(url, hasToken: true, ref: ref);

      if (response == null || response.statusCode != 200) {
        log('Market velocity fetch failed: ${response?.statusCode}');
        return null;
      }

      final raw = _decodeToMap(response.data);
      log('Market velocity for report keys: ${raw.keys.toList()}');
      return MarketVelocity.fromJson(raw);
    } catch (e) {
      log('Error fetching market velocity for report: $e');
      return null;
    }
  },
);

Map<String, dynamic> _decodeToMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String) return json.decode(data) as Map<String, dynamic>;
  if (data is Uint8List) return json.decode(utf8.decode(data)) as Map<String, dynamic>;
  throw FormatException('Unsupported response type: ${data.runtimeType}');
}
