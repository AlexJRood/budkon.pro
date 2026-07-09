import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class PriceTrendBucket {
  final String month;
  final double avgPriceM2;
  final int count;

  const PriceTrendBucket({
    required this.month,
    required this.avgPriceM2,
    required this.count,
  });

  factory PriceTrendBucket.fromJson(Map<String, dynamic> j) => PriceTrendBucket(
        month: j['month']?.toString() ?? '',
        avgPriceM2: (j['avg_price_m2'] as num?)?.toDouble() ?? 0,
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

class PriceTrendSummary {
  final String? firstMonth;
  final String? lastMonth;
  final double? firstAvgPriceM2;
  final double? lastAvgPriceM2;
  final double? pctChange;
  final int totalBuckets;

  const PriceTrendSummary({
    this.firstMonth,
    this.lastMonth,
    this.firstAvgPriceM2,
    this.lastAvgPriceM2,
    this.pctChange,
    this.totalBuckets = 0,
  });

  factory PriceTrendSummary.fromJson(Map<String, dynamic> j) => PriceTrendSummary(
        firstMonth: j['first_month']?.toString(),
        lastMonth: j['last_month']?.toString(),
        firstAvgPriceM2: (j['first_avg_price_m2'] as num?)?.toDouble(),
        lastAvgPriceM2: (j['last_avg_price_m2'] as num?)?.toDouble(),
        pctChange: (j['pct_change'] as num?)?.toDouble(),
        totalBuckets: (j['total_buckets'] as num?)?.toInt() ?? 0,
      );
}

class PriceTrendData {
  final String city;
  final List<PriceTrendBucket> trend;
  final PriceTrendSummary? summary;

  const PriceTrendData({
    required this.city,
    required this.trend,
    this.summary,
  });

  factory PriceTrendData.fromJson(Map<String, dynamic> j) {
    final rawTrend = j['trend'] as List<dynamic>? ?? [];
    return PriceTrendData(
      city: j['city']?.toString() ?? '',
      trend: rawTrend
          .whereType<Map<String, dynamic>>()
          .map(PriceTrendBucket.fromJson)
          .toList(),
      summary: j['summary'] != null
          ? PriceTrendSummary.fromJson(
              Map<String, dynamic>.from(j['summary'] as Map))
          : null,
    );
  }
}

class PriceTrendParams {
  final String city;
  final String? estateType;
  final String? offerType;
  final int months;

  const PriceTrendParams({
    required this.city,
    this.estateType,
    this.offerType,
    this.months = 24,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceTrendParams &&
          city == other.city &&
          estateType == other.estateType &&
          offerType == other.offerType &&
          months == other.months;

  @override
  int get hashCode => Object.hash(city, estateType, offerType, months);
}

final reportPriceTrendProvider =
    FutureProvider.family<PriceTrendData?, PriceTrendParams>(
  (ref, params) async {
    if (params.city.isEmpty) return null;
    try {
      final url = ReportsUrls.priceTrendForReport(
        city: params.city,
        estateType: params.estateType,
        offerType: params.offerType,
        months: params.months,
      );
      final response = await ApiServices.get(url, hasToken: true, ref: ref);
      if (response == null || response.statusCode != 200) {
        log('[PriceTrend] fetch failed: ${response?.statusCode}');
        return null;
      }
      final raw = _toMap(response.data);
      final trend = raw['trend'] as List?;
      if (trend == null || trend.isEmpty) return null;
      return PriceTrendData.fromJson(raw);
    } catch (e) {
      log('[PriceTrend] error: $e');
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
