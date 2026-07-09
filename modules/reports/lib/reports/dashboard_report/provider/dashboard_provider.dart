import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reports/reports/dashboard_report/models/dashboard_data_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:get/get_utils/get_utils.dart';

final dashboardDataProvider =
    StateNotifierProvider<DashboardDataNotifier, AsyncValue<DashboardData>>((
      ref,
    ) {
      return DashboardDataNotifier(ref);
    });

class DashboardDataNotifier extends StateNotifier<AsyncValue<DashboardData>> {
  final Ref ref;

  DashboardDataNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      state = const AsyncValue.loading();

      final response = await ApiServices.get(
        ReportsUrls.dashboardreport,
        ref: ref,
        hasToken: true,
      );

      if (response == null || response.statusCode != 200) {
        state = AsyncValue.error(
          'failed_to_load_dashboard_data'.tr,
          StackTrace.current,
        );
        log('Failed to fetch dashboard data: ${response?.statusCode}');
        return;
      }

      final Map<String, dynamic> jsonData = _extractJsonMap(response.data);
      final rawVelocity = _extractRawMarketVelocity(jsonData);

      log('Dashboard root keys: ${jsonData.keys.toList()}');
      log('Dashboard raw market_velocity keys: ${rawVelocity.keys.toList()}');

      final dashboardData = DashboardData.fromJson(jsonData);

      log(
        'Dashboard parsed market_velocity meta: '
        '${dashboardData.marketVelocity.meta}',
      );

      state = AsyncValue.data(dashboardData);
      log('Dashboard data fetched successfully');
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      log('Error fetching dashboard data: $e');
    }
  }

  Future<void> refresh() async {
    await fetchDashboardData();
  }

  Map<String, dynamic> _extractJsonMap(dynamic rawData) {
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    if (rawData is String) {
      return Map<String, dynamic>.from(json.decode(rawData));
    }

    if (rawData is List<int>) {
      return Map<String, dynamic>.from(json.decode(utf8.decode(rawData)));
    }

    if (rawData is Uint8List) {
      return Map<String, dynamic>.from(json.decode(utf8.decode(rawData)));
    }

    throw FormatException(
      'Unsupported response payload: ${rawData.runtimeType}',
    );
  }

  Map<String, dynamic> _extractRawMarketVelocity(Map<String, dynamic> jsonData) {
    final direct = jsonData['market_velocity'];
    if (direct is Map<String, dynamic>) {
      return direct;
    }
    if (direct is Map) {
      return Map<String, dynamic>.from(direct);
    }

    final fallbackKeys = {
      'summary',
      'stats_hours',
      'stats_days',
      'histogram',
      'trend',
      'top_fastest',
      'top_slowest',
      'by_offer_type',
      'by_market_type',
      'by_estate_type',
      'by_city',
      'meta',
    };

    final fallback = <String, dynamic>{};
    for (final entry in jsonData.entries) {
      if (fallbackKeys.contains(entry.key)) {
        fallback[entry.key] = entry.value;
      }
    }

    return fallback;
  }
}