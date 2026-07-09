import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:reports/reports/report_pdf_page/provider/report_air_quality_provider.dart';

const _primaryText = Color(0xFF171A1F);
const _secondaryText = Color(0xFF667085);
const _lightText = Color(0xFF98A2B3);
const _accent = Color(0xFF5FCDD9);
const _card = Colors.white;
const _border = Color(0xFFE7ECF2);

// GIOŚ index colours (0=very good → 5=very bad)
const _indexColors = [
  Color(0xFF16A34A), // 0 very good
  Color(0xFF84CC16), // 1 good
  Color(0xFFF59E0B), // 2 moderate
  Color(0xFFEA580C), // 3 sufficient
  Color(0xFFEF4444), // 4 bad
  Color(0xFF7C3AED), // 5 very bad
];

Color _indexColor(int? idx) {
  if (idx == null || idx < 0 || idx >= _indexColors.length) {
    return const Color(0xFF98A2B3);
  }
  return _indexColors[idx];
}

// EU WHO guideline limits (µg/m³) for colour coding individual sensors
const _limits = {
  'PM2.5': 15.0,
  'PM10': 45.0,
  'NO2': 25.0,
  'O3': 100.0,
  'SO2': 40.0,
};

Color _sensorColor(String param, double value) {
  final limit = _limits[param];
  if (limit == null) return _primaryText;
  if (value <= limit) return const Color(0xFF16A34A);
  if (value <= limit * 2) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

class ReportAirQualitySection extends ConsumerWidget {
  final String address;
  final String city;
  final bool isMobile;

  const ReportAirQualitySection({
    super.key,
    required this.address,
    required this.city,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (address.isEmpty || city.isEmpty) return const SizedBox.shrink();

    final params = AirQualityParams(address: address, city: city);
    final async = ref.watch(reportAirQualityProvider(params));

    return async.when(
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        return _AirQualityCard(data: data, isMobile: isMobile);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AirQualityCard extends StatelessWidget {
  final AirQualityData data;
  final bool isMobile;

  const _AirQualityCard({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: _border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIndexBadge(),
                if (data.station != null) ...[
                  const SizedBox(height: 8),
                  _buildStationInfo(),
                ],
                const SizedBox(height: 16),
                _buildMeasurements(),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.air_rounded, size: 18, color: _accent),
          const SizedBox(width: 8),
          Text(
            'air_quality_title'.tr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexBadge() {
    final color = _indexColor(data.aqIndex);
    final labelKey = data.aqLabel != null
        ? 'aq_${data.aqLabel!.toLowerCase().replaceAll(' ', '_')}'
        : 'aq_unknown';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                labelKey.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text('air_quality_index'.tr,
            style: const TextStyle(fontSize: 12, color: _secondaryText)),
      ],
    );
  }

  Widget _buildStationInfo() {
    final s = data.station!;
    final parts = [s.name, s.city].where((v) => v != null && v.isNotEmpty);
    return Row(
      children: [
        const Icon(Icons.sensors_rounded, size: 12, color: _lightText),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            parts.join(', '),
            style: const TextStyle(fontSize: 11, color: _secondaryText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (data.distanceKm != null)
          Text(
            '${data.distanceKm!.toStringAsFixed(1)} km',
            style: const TextStyle(fontSize: 11, color: _lightText),
          ),
      ],
    );
  }

  Widget _buildMeasurements() {
    final m = data.measurements;
    final entries = <MapEntry<String, double>>[
      if (m.pm25 != null) MapEntry('PM2.5', m.pm25!),
      if (m.pm10 != null) MapEntry('PM10', m.pm10!),
      if (m.no2 != null) MapEntry('NO2', m.no2!),
      if (m.o3 != null) MapEntry('O3', m.o3!),
      if (m.so2 != null) MapEntry('SO2', m.so2!),
      if (m.co != null) MapEntry('CO', m.co!),
    ];

    if (entries.isEmpty) {
      return Text(
        'air_quality_no_data'.tr,
        style: const TextStyle(fontSize: 12, color: _lightText),
      );
    }

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < entries.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: _SensorTile(entry: entries[i])),
                  const SizedBox(width: 8),
                  if (i + 1 < entries.length)
                    Expanded(child: _SensorTile(entry: entries[i + 1]))
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries
          .map((e) => SizedBox(width: 100, child: _SensorTile(entry: e)))
          .toList(),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        data.source,
        style: const TextStyle(fontSize: 10, color: _lightText),
      ),
    );
  }
}

class _SensorTile extends StatelessWidget {
  final MapEntry<String, double> entry;

  const _SensorTile({required this.entry});

  String get _unit => entry.key == 'CO' ? 'mg/m³' : 'µg/m³';

  @override
  Widget build(BuildContext context) {
    final color = _sensorColor(entry.key, entry.value);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.key,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            entry.value.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          Text(_unit, style: const TextStyle(fontSize: 9, color: _lightText)),
        ],
      ),
    );
  }
}
