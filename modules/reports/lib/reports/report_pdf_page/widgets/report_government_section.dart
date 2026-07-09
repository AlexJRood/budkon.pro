import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reports/reports/report_pdf_page/models/government_data_model.dart';
import 'package:get/get_utils/get_utils.dart';
class ReportGovernmentSection extends StatelessWidget {
  final ReportGovernmentDataModel governmentData;

  const ReportGovernmentSection({
    super.key,
    required this.governmentData,
  });

  static const Color backgroundColor = Color(0xFFF6F7F9);
  static const Color cardColor = Colors.white;
  static const Color primaryTextColor = Color(0xFF171A1F);
  static const Color secondaryTextColor = Color(0xFF667085);
  static const Color lightTextColor = Color(0xFF98A2B3);
  static const Color accentColor = Color(0xFF5FCDD9);
  static const Color borderColor = Color(0xFFE7ECF2);
  static const Color successColor = Color(0xFF16A34A);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('dd.MM.yyyy • HH:mm').format(value.toLocal());
  }

  String _formatMeasurementDate(String? date, int? hour) {
    if (date == null || date.trim().isEmpty) return '-';
    if (hour == null) return date;
    final hh = hour.toString().padLeft(2, '0');
    return '$date $hh:00';
  }

  String _formatNumber(
    num? value, {
    int decimals = 1,
    String suffix = '',
  }) {
    if (value == null) return '-';

    final isWhole = value % 1 == 0;
    final text = isWhole
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(decimals);

    return '$text$suffix';
  }

  Color _scoreColor(double? value) {
    if (value == null) return secondaryTextColor;
    if (value >= 80) return successColor;
    if (value >= 60) return warningColor;
    return dangerColor;
  }

  String _airQualityLabel(double? pm10, double? pm25) {
    if (pm10 == null && pm25 == null) return 'no_data'.tr;

    final p10 = pm10 ?? 999;
    final p25 = pm25 ?? 999;

    if (p10 <= 20 && p25 <= 12) return 'good_air_quality_label'.tr;
    if (p10 <= 35 && p25 <= 20) return 'moderate_air_quality_label'.tr;
    return 'weaker_air_quality_label'.tr;
  }

  Color _airQualityColor(double? pm10, double? pm25) {
    final label = _airQualityLabel(pm10, pm25);

    switch (label) {
      case 'Good':
        return successColor;
      case 'Moderate':
        return warningColor;
      case 'Weaker':
        return dangerColor;
      default:
        return secondaryTextColor;
    }
  }

  double _airQualityVisualValue(double? pm10, double? pm25) {
    final label = _airQualityLabel(pm10, pm25);

    switch (label) {
      case 'Good':
        return 0.82;
      case 'Moderate':
        return 0.55;
      case 'Weaker':
        return 0.28;
      default:
        return 0.12;
    }
  }

  String _airQualityMeaning(double? pm10, double? pm25) {
    final label = _airQualityLabel(pm10, pm25);

    switch (label) {
      case 'Good':
        return 'good_air_quality_meaning'.tr;
      case 'Moderate':
         return 'moderate_air_quality_meaning'.tr;
      case 'Weaker':
         return 'weaker_air_quality_meaning'.tr;
      default:
        return 'no_air_quality_data_meaning'.tr;
    }
  }

  String _buyerSummaryText() {
    final weather = governmentData.primaryWeather;
    final hydrology = governmentData.primaryHydrology;
    final climate = governmentData.weatherClimateSummary;

    final currentWeatherText = weather?.temperature != null
        ? 'current_temperature_text'.tr + 
          _formatNumber(weather!.temperature, suffix: '°C') +  
          'current_temperature_humidity'.tr + 
          _formatNumber(weather.humidityRelative, suffix: '%') + 
          'current_temperature_end'.tr
         : 'no_weather_reading'.tr;

    final hydrologyText = hydrology?.waterLevel != null
        ? 'hydrology_text'.tr + 
           _formatNumber(hydrology!.waterLevel, decimals: 0, suffix: ' cm') + 
           'hydrology_text_end'.tr
         : 'no_hydrology_reading'.tr;

    final airText = _airQualityMeaning(
      governmentData.averagePm10,
      governmentData.averagePm25,
    );

    final climateText = climate == null
        ? 'climate_summary_not_available'.tr
        : 'climate_text'.tr + 
           _formatNumber(climate.avgAnnualTemperature, suffix: '°C') + 
          'climate_text_middle'.tr + 
          _formatNumber(climate.annualAmplitude, suffix: '°C') + 
         'climate_text_end'.tr;


    return '$airText $currentWeatherText $hydrologyText $climateText';
  }

  @override
  Widget build(BuildContext context) {
    if (!governmentData.hasAnyData) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 920;

        return _buildSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildTopMetrics(),
              const SizedBox(height: 20),
              _buildBuyerMeaningCard(),
              const SizedBox(height: 20),
              if (isCompact) ...[
                _buildWeatherCard(),
                const SizedBox(height: 16),
                _buildHydrologyCard(),
                const SizedBox(height: 16),
                _buildCoverageCard(),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildWeatherCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildHydrologyCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCoverageCard()),
                  ],
                ),
              if (governmentData.weatherClimateSummary != null) ...[
                const SizedBox(height: 16),
                _buildClimateCard(),
              ],
              if (governmentData.schoolsSmogApi.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSchoolsSmogCard(),
              ],
              if (governmentData.readableErrors.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildErrorsCard(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.public_rounded,
            color: accentColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                'government_public_datasets'.tr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                governmentData.fetchedAt != null
                    ? 'latest_sync'.tr + _formatDateTime(governmentData.fetchedAt)
                    : 'public_data_attached_to_property_report'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopMetrics() {
    final weather = governmentData.primaryWeather;
    final hydrology = governmentData.primaryHydrology;
    final envScore = governmentData.derivedEnvironmentScore;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _metricCard(
          icon: Icons.device_thermostat_rounded,
          title: 'current_temperature'.tr,
          value: weather?.temperature != null
              ? _formatNumber(weather!.temperature, suffix: '°C')
              : '-',
          subtitle: weather?.station ??  'no_current_station'.tr,
        ),
        _metricCard(
          icon: Icons.air_rounded,
          title: 'air_quality'.tr,
          value: _airQualityLabel(
            governmentData.averagePm10,
            governmentData.averagePm25,
          ),
          subtitle: 
          governmentData.schoolsCount.toString() + 'school_sensors_nearby'.tr,
          valueColor: _airQualityColor(
            governmentData.averagePm10,
            governmentData.averagePm25,
          ),
        ),
        _metricCard(
          icon: Icons.water_drop_rounded,
          title: 'water_context'.tr,
          value: hydrology?.waterLevel != null
              ? _formatNumber(
                  hydrology!.waterLevel,
                  decimals: 0,
                  suffix: ' cm',
                )
              : '-',
          subtitle: hydrology?.river ?? 'no_water_station'.tr,
        ),
        _metricCard(
          icon: Icons.verified_outlined,
          title: 'public_data_coverage'.tr,
          value: governmentData.totalServiceCount > 0
              ? '${governmentData.availableServiceCount}/${governmentData.totalServiceCount}'
              : '-',
          subtitle: 'verified_public_sources'.tr,
        ),
        _metricCard(
          icon: Icons.insights_rounded,
          title: 'environment_score'.tr,
          value: envScore != null ? '${envScore.toStringAsFixed(0)}/100' : '-',
          subtitle: 'buyer_oriented_summary'.tr,
          valueColor: _scoreColor(envScore),
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    Color? valueColor,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? primaryTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: lightTextColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerMeaningCard() {
    return _subCard(
     title: 'what_it_means_for_the_buyer'.tr,
      icon: Icons.lightbulb_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _buyerSummaryText(),
            style: const TextStyle(
              fontSize: 13,
              color: primaryTextColor,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          _bulletLine(
            _airQualityMeaning(
              governmentData.averagePm10,
              governmentData.averagePm25,
            ),
          ),
          _bulletLine(
            'public_datasets_help'.tr
          ),
          _bulletLine(
            'disclaimer_text'.tr
          ),
        ],
      ),
    );
  }

  Widget _bulletLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: primaryTextColor,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    final item = governmentData.primaryWeather;

    return _subCard(
      title: 'weather_snapshot'.tr,
      icon: Icons.wb_sunny_outlined,
      child: item == null
          ?_emptyState('no_weather_data_available'.tr)
          : Column(
              children: [
                _dataRow('station'.tr, item.station ?? '-'),
                _dataRow(
                  'measurement'.tr,
                  _formatMeasurementDate(
                    item.measurementDate,
                    item.measurementHour,
                  ),
                ),
                _dataRow(
                  'current_temperature'.tr,
                  item.temperature != null
                      ? _formatNumber(item.temperature, suffix: '°C')
                      : '-',
                ),
                _dataRow(
                  'humidity'.tr,
                  item.humidityRelative != null
                      ? _formatNumber(item.humidityRelative, suffix: '%')
                      : '-',
                ),
                _dataRow(
                   'pressure'.tr,
                  item.pressure != null
                      ? _formatNumber(item.pressure, suffix: ' hPa')
                      : '-',
                ),
                _dataRow(
                  'wind'.tr,
                  item.windSpeed != null
                      ? _formatNumber(item.windSpeed, suffix: ' m/s')
                      : '-',
                ),
                _dataRow(
                  'precipitation'.tr,
                  item.precipitationSum != null
                      ? _formatNumber(item.precipitationSum, suffix: ' mm')
                      : '-',
                ),
              ],
            ),
    );
  }

  Widget _buildHydrologyCard() {
    final item = governmentData.primaryHydrology;

    return _subCard(
      title: 'hydrology_snapshot'.tr,
      icon: Icons.water_outlined,
      child: item == null
          ? _emptyState('no_hydrological_data_available'.tr)
          : Column(
              children: [
                _dataRow('river'.tr, item.river ?? '-'),
                _dataRow('station'.tr, item.station ?? '-'),
                _dataRow(
                  'water_level'.tr,
                  item.waterLevel != null
                      ? _formatNumber(
                          item.waterLevel,
                          decimals: 0,
                          suffix: ' cm',
                        )
                      : '-',
                ),
                _dataRow(
                  'water_temperature'.tr,
                  item.waterTemperature != null
                      ? _formatNumber(item.waterTemperature, suffix: '°C')
                      : '-',
                ),
                _dataRow(
                  'measurement'.tr,
                  _formatDateTime(item.waterLevelMeasurementAt),
                ),
                _dataRow(
                  'voivodeship'.tr,
                  item.voivodeship ?? '-',
                ),
              ],
            ),
    );
  }

  Widget _buildCoverageCard() {
    return _subCard(
      title: 'what_public_data_can_help_verify'.tr,
      icon: Icons.map_outlined,
      child: Column(
        children: [
          _coverageRow(
            'parcels_land_boundaries'.tr,
            governmentData.lotsWms?.serviceAvailable == true,
            'parcels_description'.tr,
          ),
          _coverageRow(
            'built_environment_surroundings'.tr,
            governmentData.bdot10kWms?.serviceAvailable == true,
            'built_environment_description'.tr,
          ),
          _coverageRow(
            'air_quality_background'.tr,
            governmentData.airQualityData?.monitoringAqd?.serviceAvailable ==
                true,
            'air_quality_background_description'.tr,
          ),
          _coverageRow(
            'environmental_risk_context'.tr,
            governmentData.asbestosWms?.serviceAvailable == true,
            'environmental_risk_description'.tr,
          ),
        ],
      ),
    );
  }

  Widget _coverageRow(
    String title,
    bool available,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: available ? successColor : warningColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: available
                  ? successColor.withOpacity(0.10)
                  : warningColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              available ? 'available'.tr : 'missing'.tr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: available ? successColor : warningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClimateCard() {
    final climate = governmentData.weatherClimateSummary;
    if (climate == null) return const SizedBox.shrink();

    return _subCard(
     title: 'annual_climate_profile'.tr,
      icon: Icons.thermostat_auto_outlined,
      child: Column(
        children: [
          _dataRow(
            'average_annual_temperature'.tr,
            _formatNumber(climate.avgAnnualTemperature, suffix: '°C'),
          ),
          _dataRow(
            'average_annual_pressure'.tr,
            _formatNumber(climate.avgAnnualPressure, suffix: ' hPa'),
          ),
          _dataRow(
            'average_annual_humidity'.tr,
            _formatNumber(climate.avgAnnualHumidity, suffix: '%'),
          ),
          _dataRow(
            'average_annual_wind_speed'.tr, 
            _formatNumber(climate.avgAnnualWindSpeed, suffix: ' m/s'),
          ),
          _dataRow(
            'average_precipitation'.tr,
            _formatNumber(climate.avgAnnualPrecipitation, suffix: ' mm'),
          ),
          _dataRow(
            'average_annual_low_temperature'.tr,
            _formatNumber(climate.avgMinTemperature, suffix: '°C'),
          ),
          _dataRow(
            'average_annual_high_temperature'.tr,
            _formatNumber(climate.avgMaxTemperature, suffix: '°C'),
          ),
          _dataRow(
            'annual_amplitude'.tr,
            _formatNumber(climate.annualAmplitude, suffix: '°C'),
          ),
          _dataRow('data_range'.tr, climate.sampleDays != null ? climate.sampleDays.toString() + 'days'.tr: '-'),
        ],
      ),
    );
  }

  Widget _buildSchoolsSmogCard() {
    final avgPm10 = governmentData.averagePm10;
    final avgPm25 = governmentData.averagePm25;
    final label = _airQualityLabel(avgPm10, avgPm25);
    final labelColor = _airQualityColor(avgPm10, avgPm25);
    final visualValue = _airQualityVisualValue(avgPm10, avgPm25);

    return _subCard(
      title: 'air_quality_from_nearby_school_sensors'.tr,
      icon: Icons.air_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: labelColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: labelColor.withOpacity(0.20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'overall_air_quality'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: labelColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        color: labelColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: visualValue,
                    minHeight: 10,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(labelColor),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _airQualityMeaning(avgPm10, avgPm25),
                  style: const TextStyle(
                    fontSize: 13,
                    color: primaryTextColor,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _pill(
                      'avg_pm10'.tr,
                      avgPm10 != null
                          ? '${avgPm10.toStringAsFixed(1)} µg/m³'
                          : '-',
                    ),
                    _pill(
                      'avg_pm25'.tr,
                      avgPm25 != null
                          ? '${avgPm25.toStringAsFixed(1)} µg/m³'
                          : '-',
                    ),
                    _pill(
                      'sensors'.tr,
                      '${governmentData.schoolsCount}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...governmentData.schoolsSmogApi.take(3).map(_buildSchoolTile),
        ],
      ),
    );
  }

  Widget _buildSchoolTile(ReportGovernmentSchoolSmogPoint item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.school?.name ?? 'school_sensor'.tr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              item.school?.street,
              item.school?.city,
              item.school?.postCode,
            ].where((e) => e != null && e.trim().isNotEmpty).join(', '),
            style: const TextStyle(
              fontSize: 12,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill(
                'pm10'.tr,
                item.data?.pm10Avg != null
                    ? '${item.data!.pm10Avg!.toStringAsFixed(1)} µg/m³'
                    : '-',
              ),
              _pill(
                'pm2_5'.tr,
                item.data?.pm25Avg != null
                    ? '${item.data!.pm25Avg!.toStringAsFixed(1)} µg/m³'
                    : '-',
              ),
              _pill(
                'temp'.tr,
                item.data?.temperatureAvg != null
                    ? '${item.data!.temperatureAvg!.toStringAsFixed(1)}°C'
                    : '-',
              ),
              _pill(
                'humidity'.tr,
                item.data?.humidityAvg != null
                    ? '${item.data!.humidityAvg!.toStringAsFixed(1)}%'
                    : '-',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${'timestamp'.tr}: ${_formatDateTime(item.timestamp)}',
            style: const TextStyle(
              fontSize: 11,
              color: lightTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsCard() {
    return _subCard(
    title: 'dataset_warnings'.tr,
      icon: Icons.error_outline_rounded,
      child: Column(
        children: governmentData.readableErrors
            .map(
              (e) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dangerColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: dangerColor.withOpacity(0.18)),
                ),
                child: Text(
                  e,
                  style: const TextStyle(
                    fontSize: 12,
                    color: primaryTextColor,
                    height: 1.4,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            color: primaryTextColor,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: secondaryTextColor,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: secondaryTextColor,
        ),
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}