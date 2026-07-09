import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:reports/reports/report_pdf_page/provider/report_price_trend_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

const _primaryText = Color(0xFF171A1F);
const _lightText = Color(0xFF98A2B3);
const _accent = Color(0xFF5FCDD9);
const _accentFill = Color(0xFFE6F8FA);
const _card = Colors.white;
const _border = Color(0xFFE7ECF2);
const _green = Color(0xFF16A34A);
const _red = Color(0xFFEF4444);

class ReportPriceTrendSection extends ConsumerWidget {
  final String city;
  final String? estateType;
  final String? offerType;
  final bool isMobile;

  const ReportPriceTrendSection({
    super.key,
    required this.city,
    this.estateType,
    this.offerType,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (city.isEmpty) return const SizedBox.shrink();

    final params = PriceTrendParams(
      city: city,
      estateType: estateType,
      offerType: offerType,
      months: 24,
    );
    final async = ref.watch(reportPriceTrendProvider(params));

    return async.when(
      data: (data) {
        if (data == null || data.trend.length < 2) return const SizedBox.shrink();
        return _PriceTrendCard(data: data, isMobile: isMobile);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PriceTrendCard extends StatelessWidget {
  final PriceTrendData data;
  final bool isMobile;

  const _PriceTrendCard({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    final pct = summary?.pctChange;
    final isPositive = (pct ?? 0) >= 0;

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
          _Header(city: data.city, pct: pct, isPositive: isPositive),
          const Divider(height: 1, color: _border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary != null) _SummaryRow(summary: summary),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: _TrendChart(buckets: data.trend),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'GUS BDL / superbee.cloud'.tr,
              style: const TextStyle(fontSize: 10, color: _lightText),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String city;
  final double? pct;
  final bool isPositive;

  const _Header({required this.city, this.pct, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, size: 18, color: _accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'price_trend_title'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
          ),
          if (pct != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPositive
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 12,
                    color: isPositive ? _green : _red,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${pct!.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? _green : _red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final PriceTrendSummary summary;

  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (summary.firstAvgPriceM2 != null)
          _StatChip(
            label: summary.firstMonth ?? '',
            value: '${summary.firstAvgPriceM2!.toStringAsFixed(0)} PLN/m²',
          ),
        const Spacer(),
        if (summary.lastAvgPriceM2 != null)
          _StatChip(
            label: summary.lastMonth ?? '',
            value: '${summary.lastAvgPriceM2!.toStringAsFixed(0)} PLN/m²',
            isHighlighted: true,
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _StatChip({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isHighlighted ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: _lightText)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isHighlighted ? _accent : _primaryText,
          ),
        ),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<PriceTrendBucket> buckets;

  const _TrendChart({required this.buckets});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      primaryXAxis: CategoryAxis(
        isVisible: true,
        labelStyle: const TextStyle(fontSize: 9, color: _lightText),
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        interval: (buckets.length / 4).ceil().toDouble(),
      ),
      primaryYAxis: NumericAxis(
        isVisible: false,
        majorGridLines: const MajorGridLines(width: 0),
      ),
      series: <CartesianSeries>[
        AreaSeries<PriceTrendBucket, String>(
          dataSource: buckets,
          xValueMapper: (b, _) => b.month.length >= 7 ? b.month.substring(0, 7) : b.month,
          yValueMapper: (b, _) => b.avgPriceM2,
          color: _accentFill,
          borderColor: _accent,
          borderWidth: 2,
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),
      ],
    );
  }
}
