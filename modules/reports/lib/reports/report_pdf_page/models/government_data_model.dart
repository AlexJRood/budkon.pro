import 'dart:math' as math;

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.'));
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value == null) return false;
  final text = value.toString().trim().toLowerCase();
  return text == 'true' ||
      text == '1' ||
      text == 'yes' ||
      text == 'ok' ||
      text == 'available';
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .where((e) => e is Map)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
}

double? _average(Iterable<double?> values) {
  final clean = values.whereType<double>().toList();
  if (clean.isEmpty) return null;
  final total = clean.fold<double>(0, (sum, v) => sum + v);
  return total / clean.length;
}

class ReportGovernmentServiceStatus {
  final bool serviceAvailable;
  final String? serviceUrl;
  final int? statusCode;
  final String? contentType;
  final DateTime? checkedAt;

  const ReportGovernmentServiceStatus({
    required this.serviceAvailable,
    this.serviceUrl,
    this.statusCode,
    this.contentType,
    this.checkedAt,
  });

  factory ReportGovernmentServiceStatus.fromJson(Map<String, dynamic> json) {
    return ReportGovernmentServiceStatus(
      serviceAvailable: _asBool(json['service_available']),
      serviceUrl: json['service_url']?.toString(),
      statusCode: _asInt(json['status_code']),
      contentType: json['content_type']?.toString(),
      checkedAt: _asDateTime(json['checked_at']),
    );
  }
}

class ReportGovernmentWeatherClimateSummary {
  final double? avgAnnualTemperature;
  final double? avgAnnualPressure;
  final double? avgAnnualHumidity;
  final double? avgAnnualWindSpeed;
  final double? avgAnnualPrecipitation;
  final double? avgMinTemperature;
  final double? avgMaxTemperature;
  final double? annualAmplitude;
  final int? sampleDays;

  const ReportGovernmentWeatherClimateSummary({
    this.avgAnnualTemperature,
    this.avgAnnualPressure,
    this.avgAnnualHumidity,
    this.avgAnnualWindSpeed,
    this.avgAnnualPrecipitation,
    this.avgMinTemperature,
    this.avgMaxTemperature,
    this.annualAmplitude,
    this.sampleDays,
  });

  factory ReportGovernmentWeatherClimateSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReportGovernmentWeatherClimateSummary(
      avgAnnualTemperature: _asDouble(json['avg_annual_temperature']),
      avgAnnualPressure: _asDouble(json['avg_annual_pressure']),
      avgAnnualHumidity: _asDouble(json['avg_annual_humidity']),
      avgAnnualWindSpeed: _asDouble(json['avg_annual_wind_speed']),
      avgAnnualPrecipitation: _asDouble(json['avg_annual_precipitation']),
      avgMinTemperature: _asDouble(json['avg_min_temperature']),
      avgMaxTemperature: _asDouble(json['avg_max_temperature']),
      annualAmplitude: _asDouble(json['annual_amplitude']),
      sampleDays: _asInt(json['sample_days']),
    );
  }
}

class ReportGovernmentAirQualityStatus {
  final ReportGovernmentServiceStatus? monitoringAqd;
  final ReportGovernmentServiceStatus? monitoringChem;

  const ReportGovernmentAirQualityStatus({
    this.monitoringAqd,
    this.monitoringChem,
  });

  factory ReportGovernmentAirQualityStatus.fromJson(Map<String, dynamic> json) {
    return ReportGovernmentAirQualityStatus(
      monitoringAqd: _asMap(json['monitoring_aqd']) != null
          ? ReportGovernmentServiceStatus.fromJson(
              _asMap(json['monitoring_aqd'])!,
            )
          : null,
      monitoringChem: _asMap(json['monitoring_chem']) != null
          ? ReportGovernmentServiceStatus.fromJson(
              _asMap(json['monitoring_chem'])!,
            )
          : null,
    );
  }
}

class ReportGovernmentWeatherPoint {
  final String? station;
  final int? stationId;
  final double? pressure;
  final double? precipitationSum;
  final double? temperature;
  final String? measurementDate;
  final int? measurementHour;
  final int? windDirection;
  final double? windSpeed;
  final double? humidityRelative;

  const ReportGovernmentWeatherPoint({
    this.station,
    this.stationId,
    this.pressure,
    this.precipitationSum,
    this.temperature,
    this.measurementDate,
    this.measurementHour,
    this.windDirection,
    this.windSpeed,
    this.humidityRelative,
  });

  factory ReportGovernmentWeatherPoint.fromJson(Map<String, dynamic> json) {
    return ReportGovernmentWeatherPoint(
      station: json['stacja']?.toString(),
      stationId: _asInt(json['id_stacji']),
      pressure: _asDouble(json['cisnienie']),
      precipitationSum: _asDouble(json['suma_opadu']),
      temperature: _asDouble(json['temperatura']),
      measurementDate: json['data_pomiaru']?.toString(),
      measurementHour: _asInt(json['godzina_pomiaru']),
      windDirection: _asInt(json['kierunek_wiatru']),
      windSpeed: _asDouble(json['predkosc_wiatru']),
      humidityRelative: _asDouble(json['wilgotnosc_wzgledna']),
    );
  }
}

class ReportGovernmentHydrologyPoint {
  final double? lat;
  final double? lon;
  final String? river;
  final String? station;
  final double? flow;
  final int? stationId;
  final double? waterLevel;
  final String? voivodeship;
  final String? flowDate;
  final int? icePhenomenon;
  final double? waterTemperature;
  final int? overgrowthPhenomenon;
  final DateTime? waterLevelMeasurementAt;
  final DateTime? waterTemperatureMeasurementAt;

  const ReportGovernmentHydrologyPoint({
    this.lat,
    this.lon,
    this.river,
    this.station,
    this.flow,
    this.stationId,
    this.waterLevel,
    this.voivodeship,
    this.flowDate,
    this.icePhenomenon,
    this.waterTemperature,
    this.overgrowthPhenomenon,
    this.waterLevelMeasurementAt,
    this.waterTemperatureMeasurementAt,
  });

  factory ReportGovernmentHydrologyPoint.fromJson(Map<String, dynamic> json) {
    return ReportGovernmentHydrologyPoint(
      lat: _asDouble(json['lat']),
      lon: _asDouble(json['lon']),
      river: json['rzeka']?.toString(),
      station: json['stacja']?.toString(),
      flow: _asDouble(json['przeplyw']),
      stationId: _asInt(json['id_stacji']),
      waterLevel: _asDouble(json['stan_wody']),
      voivodeship: json['wojewodztwo']?.toString(),
      flowDate: json['przeplyw_data']?.toString(),
      icePhenomenon: _asInt(json['zjawisko_lodowe']),
      waterTemperature: _asDouble(json['temperatura_wody']),
      overgrowthPhenomenon: _asInt(json['zjawisko_zarastania']),
      waterLevelMeasurementAt: _asDateTime(json['stan_wody_data_pomiaru']),
      waterTemperatureMeasurementAt: _asDateTime(
        json['temperatura_wody_data_pomiaru'],
      ),
    );
  }
}

class ReportGovernmentSchoolInfo {
  final String? city;
  final String? name;
  final String? street;
  final double? latitude;
  final double? longitude;
  final String? postCode;

  const ReportGovernmentSchoolInfo({
    this.city,
    this.name,
    this.street,
    this.latitude,
    this.longitude,
    this.postCode,
  });

  factory ReportGovernmentSchoolInfo.fromJson(Map<String, dynamic> json) {
    return ReportGovernmentSchoolInfo(
      city: json['city']?.toString(),
      name: json['name']?.toString(),
      street: json['street']?.toString(),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      postCode: json['post_code']?.toString(),
    );
  }
}

class ReportGovernmentSchoolSmogData {
  final double? pm10Avg;
  final double? pm25Avg;
  final double? humidityAvg;
  final double? pressureAvg;
  final double? temperatureAvg;

  const ReportGovernmentSchoolSmogData({
    this.pm10Avg,
    this.pm25Avg,
    this.humidityAvg,
    this.pressureAvg,
    this.temperatureAvg,
  });

  factory ReportGovernmentSchoolSmogData.fromJson(Map<String, dynamic> json) {
    return ReportGovernmentSchoolSmogData(
      pm10Avg: _asDouble(json['pm10_avg']),
      pm25Avg: _asDouble(json['pm25_avg']),
      humidityAvg: _asDouble(json['humidity_avg']),
      pressureAvg: _asDouble(json['pressure_avg']),
      temperatureAvg: _asDouble(json['temperature_avg']),
    );
  }
}

class ReportGovernmentSchoolSmogPoint {
  final ReportGovernmentSchoolInfo? school;
  final ReportGovernmentSchoolSmogData? data;
  final DateTime? timestamp;

  const ReportGovernmentSchoolSmogPoint({
    this.school,
    this.data,
    this.timestamp,
  });

  factory ReportGovernmentSchoolSmogPoint.fromJson(Map<String, dynamic> json) {
    return ReportGovernmentSchoolSmogPoint(
      school: _asMap(json['school']) != null
          ? ReportGovernmentSchoolInfo.fromJson(_asMap(json['school'])!)
          : null,
      data: _asMap(json['data']) != null
          ? ReportGovernmentSchoolSmogData.fromJson(_asMap(json['data'])!)
          : null,
      timestamp: _asDateTime(json['timestamp']),
    );
  }
}

class ReportGovernmentDataModel {
  final List<ReportGovernmentWeatherPoint> weatherSynopApi;
  final List<ReportGovernmentHydrologyPoint> hydrologicalApi;
  final List<ReportGovernmentSchoolSmogPoint> schoolsSmogApi;
  final List<Map<String, dynamic>> hospitalsApi;

  final ReportGovernmentServiceStatus? asbestosWms;
  final ReportGovernmentServiceStatus? lotsWms;
  final ReportGovernmentServiceStatus? bdot10kWms;
  final ReportGovernmentAirQualityStatus? airQualityData;
  final ReportGovernmentWeatherClimateSummary? weatherClimateSummary;

  final List<dynamic> errors;
  final DateTime? fetchedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReportGovernmentDataModel({
    this.weatherSynopApi = const [],
    this.hydrologicalApi = const [],
    this.schoolsSmogApi = const [],
    this.hospitalsApi = const [],
    this.asbestosWms,
    this.lotsWms,
    this.bdot10kWms,
    this.airQualityData,
    this.weatherClimateSummary,
    this.errors = const [],
    this.fetchedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ReportGovernmentDataModel.fromJson(Map<String, dynamic> json) {
    return ReportGovernmentDataModel(
      weatherSynopApi: _asMapList(json['weather_synop_api'])
          .map(ReportGovernmentWeatherPoint.fromJson)
          .toList(),
      hydrologicalApi: _asMapList(json['hydrological_api'])
          .map(ReportGovernmentHydrologyPoint.fromJson)
          .toList(),
      schoolsSmogApi: _asMapList(json['schools_smog_api'])
          .map(ReportGovernmentSchoolSmogPoint.fromJson)
          .toList(),
      hospitalsApi: _asMapList(json['hospitals_api']),
      asbestosWms: _asMap(json['asbestos_wms']) != null
          ? ReportGovernmentServiceStatus.fromJson(
              _asMap(json['asbestos_wms'])!,
            )
          : null,
      lotsWms: _asMap(json['lots_wms']) != null
          ? ReportGovernmentServiceStatus.fromJson(
              _asMap(json['lots_wms'])!,
            )
          : null,
      bdot10kWms: _asMap(json['bdot10k_wms']) != null
          ? ReportGovernmentServiceStatus.fromJson(
              _asMap(json['bdot10k_wms'])!,
            )
          : null,
      airQualityData: _asMap(json['air_quality_data']) != null
          ? ReportGovernmentAirQualityStatus.fromJson(
              _asMap(json['air_quality_data'])!,
            )
          : null,
      errors:
          json['errors'] is List ? List<dynamic>.from(json['errors']) : const [],
      fetchedAt: _asDateTime(json['fetched_at']),
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
      weatherClimateSummary: _asMap(json['weather_climate_summary']) != null
          ? ReportGovernmentWeatherClimateSummary.fromJson(
              _asMap(json['weather_climate_summary'])!,
            )
          : null,
    );
  }

  int get weatherCount => weatherSynopApi.length;
  int get hydrologicalCount => hydrologicalApi.length;
  int get schoolsCount => schoolsSmogApi.length;
  int get hospitalsCount => hospitalsApi.length;

  double? get averagePm10 =>
      _average(schoolsSmogApi.map((e) => e.data?.pm10Avg));

  double? get averagePm25 =>
      _average(schoolsSmogApi.map((e) => e.data?.pm25Avg));

  double? get averageSchoolTemperature =>
      _average(schoolsSmogApi.map((e) => e.data?.temperatureAvg));

  double? get averageSchoolHumidity =>
      _average(schoolsSmogApi.map((e) => e.data?.humidityAvg));

  ReportGovernmentWeatherPoint? get primaryWeather =>
      weatherSynopApi.isEmpty ? null : weatherSynopApi.first;

  ReportGovernmentHydrologyPoint? get primaryHydrology =>
      hydrologicalApi.isEmpty ? null : hydrologicalApi.first;

  List<ReportGovernmentServiceStatus> get allServiceChecks {
    final services = <ReportGovernmentServiceStatus>[];
    if (asbestosWms != null) services.add(asbestosWms!);
    if (lotsWms != null) services.add(lotsWms!);
    if (bdot10kWms != null) services.add(bdot10kWms!);
    if (airQualityData?.monitoringAqd != null) {
      services.add(airQualityData!.monitoringAqd!);
    }
    if (airQualityData?.monitoringChem != null) {
      services.add(airQualityData!.monitoringChem!);
    }
    return services;
  }

  int get availableServiceCount =>
      allServiceChecks.where((e) => e.serviceAvailable).length;

  int get totalServiceCount => allServiceChecks.length;

  List<String> get readableErrors {
    if (errors.isEmpty) return const [];

    final result = <String>[];
    for (final item in errors) {
      if (item is Map) {
        item.forEach((key, value) {
          result.add('$key: $value');
        });
      } else {
        result.add(item.toString());
      }
    }
    return result;
  }

  bool get hasAnyData {
    return weatherSynopApi.isNotEmpty ||
        hydrologicalApi.isNotEmpty ||
        schoolsSmogApi.isNotEmpty ||
        hospitalsApi.isNotEmpty ||
        asbestosWms != null ||
        lotsWms != null ||
        bdot10kWms != null ||
        airQualityData != null ||
        weatherClimateSummary != null ||
        readableErrors.isNotEmpty;
  }

  double? get derivedEnvironmentScore {
    final pm10 = averagePm10;
    final pm25 = averagePm25;

    double score = 100;

    if (pm10 != null) {
      score -= math.min(pm10, 80) * 0.55;
    }

    if (pm25 != null) {
      score -= math.min(pm25, 60) * 0.9;
    }

    if (availableServiceCount > 0 && totalServiceCount > 0) {
      final serviceRatio = availableServiceCount / totalServiceCount;
      score = (score * 0.85) + (serviceRatio * 100 * 0.15);
    }

    return score.clamp(0, 100).toDouble();
  }
}