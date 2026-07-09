import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LandingApiUrls {
  static const String base = 'https://www.superbee.cloud/portal/';
  static const String stats = '${base}public/landing/stats/';
}

class LandingStats {
  final int advertisementsCount;
  final int advertisementViewsLast30d;
  final int usersCount;
  final int investmentsCount;
  final int investmentsAvailableUnits;
  final int investmentsTotalUnits;
  final DateTime? generatedAt;

  const LandingStats({
    required this.advertisementsCount,
    required this.advertisementViewsLast30d,
    required this.usersCount,
    required this.investmentsCount,
    required this.investmentsAvailableUnits,
    required this.investmentsTotalUnits,
    required this.generatedAt,
  });

  factory LandingStats.fromJson(Map<String, dynamic> json) {
    return LandingStats(
      advertisementsCount: _parseInt(json['advertisements_count']),
      advertisementViewsLast30d:
          _parseInt(json['advertisement_views_last_30d']),
      usersCount: _parseInt(json['users_count']),
      investmentsCount: _parseInt(json['investments_count']),
      investmentsAvailableUnits: _parseInt(json['investments_available_units']),
      investmentsTotalUnits: _parseInt(json['investments_total_units']),
      generatedAt: _parseDateTime(json['generated_at']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

final landingStatsDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );
});

final landingStatsProvider = FutureProvider<LandingStats>((ref) async {
  final dio = ref.read(landingStatsDioProvider);

  final response = await dio.get(LandingApiUrls.stats);

  final data = response.data;

  if (data is! Map<String, dynamic>) {
    throw Exception('Invalid landing stats response');
  }

  return LandingStats.fromJson(data);
});