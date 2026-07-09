import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:reports/reports/report_pdf_page/provider/report_flood_risk_provider.dart';

const _primaryText = Color(0xFF171A1F);
const _secondaryText = Color(0xFF667085);
const _lightText = Color(0xFF98A2B3);
const _card = Colors.white;
const _border = Color(0xFFE7ECF2);
const _accent = Color(0xFF5FCDD9);
const _green = Color(0xFF16A34A);
const _yellow = Color(0xFFF59E0B);
const _orange = Color(0xFFEA580C);
const _red = Color(0xFFEF4444);

class ReportFloodRiskSection extends ConsumerWidget {
  final String address;
  final String city;
  final bool isMobile;

  const ReportFloodRiskSection({
    super.key,
    required this.address,
    required this.city,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (address.isEmpty || city.isEmpty) return const SizedBox.shrink();

    final params = FloodRiskParams(address: address, city: city);
    final async = ref.watch(reportFloodRiskProvider(params));

    return async.when(
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        return _FloodRiskCard(data: data, isMobile: isMobile);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _FloodRiskCard extends StatelessWidget {
  final FloodRiskData data;
  final bool isMobile;

  const _FloodRiskCard({required this.data, required this.isMobile});

  Color get _riskColor {
    switch (data.overallRisk) {
      case 'critical':
        return _red;
      case 'high':
        return _orange;
      case 'moderate':
        return _yellow;
      default:
        return _green;
    }
  }

  IconData get _riskIcon {
    switch (data.overallRisk) {
      case 'critical':
      case 'high':
        return Icons.warning_rounded;
      case 'moderate':
        return Icons.info_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  String get _riskLabel => 'flood_risk_${data.overallRisk}'.tr;

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
                _buildRiskBadge(),
                const SizedBox(height: 16),
                if (isMobile) ...[
                  if (data.nearestStation != null) _buildStationCard(),
                  const SizedBox(height: 8),
                  if (data.floodZone != null) _buildZoneCard(),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.nearestStation != null)
                        Expanded(child: _buildStationCard()),
                      if (data.nearestStation != null && data.floodZone != null)
                        const SizedBox(width: 12),
                      if (data.floodZone != null)
                        Expanded(child: _buildZoneCard()),
                    ],
                  ),
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
          const Icon(Icons.water_rounded, size: 18, color: _accent),
          const SizedBox(width: 8),
          Text(
            'flood_risk_title'.tr,
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

  Widget _buildRiskBadge() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _riskColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _riskColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_riskIcon, size: 14, color: _riskColor),
              const SizedBox(width: 6),
              Text(
                _riskLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _riskColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'flood_risk_overall'.tr,
          style: const TextStyle(fontSize: 12, color: _secondaryText),
        ),
      ],
    );
  }

  Widget _buildStationCard() {
    final s = data.nearestStation!;
    final isAlarm = s.levelStatus == 'alarm';
    final isWarning = s.levelStatus == 'warning';
    final levelColor =
        isAlarm ? _red : (isWarning ? _yellow : _green);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors_rounded, size: 13, color: _accent),
              const SizedBox(width: 4),
              Text(
                'flood_risk_station'.tr,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (s.stationName != null)
            Text(
              s.stationName!,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _primaryText),
            ),
          if (s.riverName != null)
            Text(
              s.riverName!,
              style: const TextStyle(fontSize: 11, color: _secondaryText),
            ),
          if (s.distanceKm != null) ...[
            const SizedBox(height: 4),
            Text(
              '${s.distanceKm!.toStringAsFixed(1)} km ${'flood_risk_away'.tr}',
              style: const TextStyle(fontSize: 11, color: _secondaryText),
            ),
          ],
          if (s.waterLevelCm != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: levelColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${s.waterLevelCm!.toStringAsFixed(0)} cm',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: levelColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${s.levelStatus})',
                  style: const TextStyle(fontSize: 10, color: _lightText),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildZoneCard() {
    final zone = data.floodZone!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: zone.inFloodZone
            ? _red.withValues(alpha: 0.05)
            : _green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: zone.inFloodZone
              ? _red.withValues(alpha: 0.2)
              : _green.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flood_rounded, size: 13, color: _accent),
              const SizedBox(width: 4),
              Text(
                'flood_risk_zone'.tr,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                zone.inFloodZone
                    ? Icons.warning_rounded
                    : Icons.check_circle_rounded,
                size: 16,
                color: zone.inFloodZone ? _red : _green,
              ),
              const SizedBox(width: 4),
              Text(
                zone.inFloodZone
                    ? 'flood_risk_in_zone'.tr
                    : 'flood_risk_not_in_zone'.tr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: zone.inFloodZone ? _red : _green,
                ),
              ),
            ],
          ),
          if (zone.inFloodZone && zone.worstZone != null) ...[
            const SizedBox(height: 4),
            Text(
              '${'flood_risk_worst_zone'.tr}: ${zone.worstZone}',
              style: const TextStyle(fontSize: 11, color: _secondaryText),
            ),
            if (zone.zones.isNotEmpty)
              Text(
                zone.zones.join(', '),
                style: const TextStyle(fontSize: 10, color: _lightText),
              ),
          ],
        ],
      ),
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
