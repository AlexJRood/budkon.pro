import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:crm_agent/crm/models/daily_market_overview_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

class ReportOverviewParams {
  final String? city;
  final String? state;
  final String? country;

  const ReportOverviewParams({this.city, this.state, this.country});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportOverviewParams &&
          city == other.city &&
          state == other.state &&
          country == other.country;

  @override
  int get hashCode => Object.hash(city, state, country);
}

final reportDailyMarketOverviewProvider =
    FutureProvider.family<DailyMarketOverviewModel?, ReportOverviewParams>(
  (ref, params) async {
    try {
      final base = URLs.dailyMarketOverview;
      final queryParts = <String>[];
      if (params.city != null && params.city!.isNotEmpty) {
        queryParts.add('city=${Uri.encodeComponent(params.city!)}');
      }
      if (params.state != null && params.state!.isNotEmpty) {
        queryParts.add('state=${Uri.encodeComponent(params.state!)}');
      }
      if (params.country != null && params.country!.isNotEmpty) {
        queryParts.add('country=${Uri.encodeComponent(params.country!)}');
      }
      final url =
          queryParts.isEmpty ? base : '$base?${queryParts.join('&')}';

      final response = await ApiServices.get(url, hasToken: true, ref: ref);

      if (response == null || response.statusCode != 200) {
        log('Daily market overview fetch failed: ${response?.statusCode}');
        return null;
      }

      final json = _decodeToMap(response.data);
      return DailyMarketOverviewModel.fromJson(json);
    } catch (e) {
      log('Error fetching daily market overview for report: $e');
      return null;
    }
  },
);

Map<String, dynamic> _decodeToMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String) return json.decode(data) as Map<String, dynamic>;
  if (data is Uint8List) {
    return json.decode(utf8.decode(data)) as Map<String, dynamic>;
  }
  throw FormatException('Unsupported response type: ${data.runtimeType}');
}
