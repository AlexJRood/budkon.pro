import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:reports/reports/dashboard_report/models/dashboard_data_model.dart';
import 'package:reports/reports/report_pdf_page/models/pdf_report_model.dart';
import 'package:reports/reports/report_pdf_page/provider/report_market_velocity_provider.dart';

class ReportMarketVelocitySection extends ConsumerWidget {
  final ReportData reportData;
  final bool isMobile;

  const ReportMarketVelocitySection({
    super.key,
    required this.reportData,
    required this.isMobile,
  });

  static const Color _primaryText = Color(0xFF171A1F);
  static const Color _secondaryText = Color(0xFF667085);
  static const Color _lightText = Color(0xFF98A2B3);
  static const Color _accent = Color(0xFF5FCDD9);
  static const Color _accentStrong = Color(0xFF2FB8C6);
  static const Color _green = Color(0xFF16A34A);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);
  static const Color _background = Color(0xFFF6F7F9);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFE7ECF2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ReportVelocityParams(
      city: reportData.city,
      state: reportData.state,
      country: reportData.country,
      estateType: reportData.propertyType,
    );

    final asyncVelocity = ref.watch(reportMarketVelocityProvider(params));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          asyncVelocity.when(
            loading: () => _buildLoading(),
            error: (_, __) => _buildError(),
            data: (velocity) {
              if (velocity == null || velocity.summary.activeInventory == 0 && velocity.histogram.isEmpty) {
                return _buildEmpty();
              }
              return _buildContent(velocity);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.speed_rounded, color: _accentStrong, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'market_velocity'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _accentStrong),
            ),
            const SizedBox(width: 12),
            Text(
              'loading_market_velocity'.tr,
              style: const TextStyle(fontSize: 13, color: _secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'no_market_velocity_data'.tr,
          style: const TextStyle(fontSize: 13, color: _lightText),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'no_market_velocity_data'.tr,
          style: const TextStyle(fontSize: 13, color: _lightText),
        ),
      ),
    );
  }

  Widget _buildContent(MarketVelocity velocity) {
    final summary = velocity.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScoreRow(summary),
        const SizedBox(height: 20),
        _buildKpiGrid(summary),
        if (velocity.histogram.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildHistogram(velocity.histogram),
        ],
      ],
    );
  }

  Widget _buildScoreRow(MarketVelocitySummary summary) {
    final score = summary.velocityScore;
    final label = summary.label;
    final scoreColor = _scoreColor(score);

    return Row(
      children: [
        _buildScoreCircle(score, scoreColor),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _velocityLabelTranslated(label),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scoreColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${'velocity_score'.tr}: ${score.toStringAsFixed(0)}/100',
                style: const TextStyle(fontSize: 13, color: _secondaryText),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (score / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: _background,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCircle(double score, Color color) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        color: color.withOpacity(0.08),
      ),
      child: Center(
        child: Text(
          score.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildKpiGrid(MarketVelocitySummary summary) {
    final kpis = [
      (
        'active_inventory'.tr,
        '${summary.activeInventory}',
        Icons.inventory_2_outlined,
      ),
      (
        'median_dom'.tr,
        '${summary.medianDaysOnMarket.toStringAsFixed(1)} ${'days_short'.tr}',
        Icons.timer_outlined,
      ),
      (
        'new_7d'.tr,
        '+${summary.newListings7d}',
        Icons.arrow_upward_rounded,
      ),
      (
        'removed_7d'.tr,
        '-${summary.removedListings7d}',
        Icons.arrow_downward_rounded,
      ),
      (
        'absorption'.tr,
        '${(summary.absorptionRate30d * 100).toStringAsFixed(1)}%',
        Icons.sync_alt_rounded,
      ),
      (
        'fast_market_share'.tr,
        '${(summary.fastMarketShare * 100).toStringAsFixed(0)}%',
        Icons.bolt_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 3,
        childAspectRatio: isMobile ? 2.4 : 2.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: kpis.length,
      itemBuilder: (_, i) => _buildKpiTile(kpis[i].$1, kpis[i].$2, kpis[i].$3),
    );
  }

  Widget _buildKpiTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: _secondaryText),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistogram(List<VelocityBucket> buckets) {
    final maxCount = buckets.fold<int>(0, (m, b) => b.count > m ? b.count : m);
    if (maxCount == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'time_on_market_distribution'.tr,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _secondaryText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: buckets.map((bucket) {
            final ratio = bucket.count / maxCount;
            final barHeight = 60.0 * ratio;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    Text(
                      '${bucket.count}',
                      style: const TextStyle(fontSize: 10, color: _secondaryText),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: barHeight.clamp(4, 60),
                      decoration: BoxDecoration(
                        color: _accentStrong.withOpacity(0.7 + 0.3 * ratio),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bucket.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9, color: _lightText),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _scoreColor(double score) {
    if (score >= 70) return _green;
    if (score >= 45) return _orange;
    return _red;
  }

  String _velocityLabelTranslated(String label) {
    switch (label.toLowerCase()) {
      case 'very fast':
        return 'velocity_very_fast'.tr;
      case 'fast':
        return 'velocity_fast'.tr;
      case 'balanced':
        return 'velocity_balanced'.tr;
      case 'slow':
        return 'velocity_slow'.tr;
      default:
        return label;
    }
  }
}
