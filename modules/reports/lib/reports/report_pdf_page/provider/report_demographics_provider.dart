import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class NeighborhoodDemographics {
  final String city;
  final double? population;
  final int? populationYear;
  final double? density;
  final int? densityYear;
  final double? naturalIncrease;
  final int? naturalIncreaseYear;
  final double? births;
  final double? deaths;
  final double? unemploymentRate;
  final int? unemploymentYear;
  final String source;

  const NeighborhoodDemographics({
    required this.city,
    this.population,
    this.populationYear,
    this.density,
    this.densityYear,
    this.naturalIncrease,
    this.naturalIncreaseYear,
    this.births,
    this.deaths,
    this.unemploymentRate,
    this.unemploymentYear,
    this.source = 'GUS BDL',
  });

  factory NeighborhoodDemographics.fromJson(Map<String, dynamic> j) =>
      NeighborhoodDemographics(
        city: j['city']?.toString() ?? '',
        population: (j['population'] as num?)?.toDouble(),
        populationYear: (j['population_year'] as num?)?.toInt(),
        density: (j['density'] as num?)?.toDouble(),
        densityYear: (j['density_year'] as num?)?.toInt(),
        naturalIncrease: (j['natural_increase'] as num?)?.toDouble(),
        naturalIncreaseYear: (j['natural_increase_year'] as num?)?.toInt(),
        births: (j['births'] as num?)?.toDouble(),
        deaths: (j['deaths'] as num?)?.toDouble(),
        unemploymentRate: (j['unemployment_rate'] as num?)?.toDouble(),
        unemploymentYear: (j['unemployment_year'] as num?)?.toInt(),
        source: j['source']?.toString() ?? 'GUS BDL',
      );
}

final reportDemographicsProvider =
    FutureProvider.family<NeighborhoodDemographics?, String>(
  (ref, city) async {
    if (city.isEmpty) return null;
    try {
      final url = ReportsUrls.neighborhoodDemographics(city: city);
      final response = await ApiServices.get(url, hasToken: true, ref: ref);
      if (response == null || response.statusCode != 200) {
        log('[Demographics] fetch failed: ${response?.statusCode}');
        return null;
      }
      final raw = _toMap(response.data);
      if (raw['unit_id'] == null) return null;
      return NeighborhoodDemographics.fromJson(raw);
    } catch (e) {
      log('[Demographics] error: $e');
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
