import 'dart:math' as math;

import 'package:crm_agent/crm/models/daily_market_overview_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:intl/intl.dart';
import 'package:reports/reports/report_pdf_page/models/pdf_report_model.dart';
import 'package:reports/reports/report_pdf_page/provider/report_daily_market_overview_provider.dart';

class ReportDailyMarketOverviewSection extends ConsumerWidget {
  final ReportData reportData;
  final bool isMobile;

  const ReportDailyMarketOverviewSection({
    super.key,
    required this.reportData,
    required this.isMobile,
  });

  // Same color palette as report_preview_widget.dart
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
    final params = ReportOverviewParams(
      city: reportData.city,
      state: reportData.state,
      country: reportData.country,
    );

    final asyncOverview = ref.watch(reportDailyMarketOverviewProvider(params));

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
          _buildHeader(context, asyncOverview.valueOrNull),
          const SizedBox(height: 20),
          asyncOverview.when(
            loading: _buildLoading,
            error: (_, __) => _buildEmpty(),
            data: (data) {
              if (data == null) return _buildEmpty();
              return _buildContent(context, data);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, DailyMarketOverviewModel? data) {
    return Row(
      children: [
        const Icon(Icons.bar_chart_rounded, color: _accentStrong, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'daily_market_overview'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                ),
              ),
              if (reportData.city != null && reportData.city!.isNotEmpty)
                Text(
                  reportData.city!,
                  style: const TextStyle(fontSize: 13, color: _secondaryText),
                ),
            ],
          ),
        ),
        if (data != null)
          _buildExpandButton(context, data),
      ],
    );
  }

  Widget _buildExpandButton(
      BuildContext context, DailyMarketOverviewModel data) {
    return GestureDetector(
      onTap: () => _showFullDialog(context, data),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_full_rounded,
                size: 14, color: _accentStrong),
            const SizedBox(width: 6),
            Text(
              'full_view'.tr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _accentStrong,
              ),
            ),
          ],
        ),
      ),
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
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _accentStrong),
            ),
            const SizedBox(width: 12),
            Text(
              'market_overview_loading'.tr,
              style: const TextStyle(fontSize: 13, color: _secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'market_overview_error'.tr,
          style: const TextStyle(fontSize: 13, color: _lightText),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, DailyMarketOverviewModel data) {
    final overview = data.overview;
    final narrative = data.narrative;
    final bullets = List<String>.from(
      (narrative['bullets'] as List<dynamic>? ?? const [])
          .map((e) => e?.toString() ?? '')
          .where((s) => s.trim().isNotEmpty),
    );
    final headline =
        (narrative['headline'] ?? 'market_overview_default_headline')
            .toString();
    final summary =
        (narrative['summary'] ?? 'market_overview_default_summary')
            .toString();
    final pulseLabel =
        (overview['pulse_label'] ?? 'Balanced').toString();
    final pulseColor = _pulseColor(pulseLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pulse + date chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(
              _pulseKey(pulseLabel).tr,
              background: pulseColor.withOpacity(0.12),
              foreground: pulseColor,
            ),
            _chip(
              '${'market_overview_based_on'.tr} ${data.sampleSize}',
              background: _background,
              foreground: _secondaryText,
            ),
            if (data.generatedAt != null && data.generatedAt!.isNotEmpty)
              _chip(
                _formatDate(data.generatedAt),
                background: _background,
                foreground: _lightText,
              ),
          ],
        ),
        const SizedBox(height: 18),

        // Narrative card
        _buildNarrativeCard(headline, summary, bullets),
        const SizedBox(height: 18),

        // KPI row
        _buildKpiRow(overview),
        const SizedBox(height: 18),

        // Price snapshot + market flow
        if (isMobile) ...[
          _buildPriceSnapshot(data.saleSnapshot, data.rentSnapshot, data.currency),
          const SizedBox(height: 12),
          _buildFlowBar(overview),
        ] else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildPriceSnapshot(
                    data.saleSnapshot, data.rentSnapshot, data.currency),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildFlowBar(overview)),
              ],
            ),
          ),

        // Fastest segments
        if (data.fastestSegments.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildFastestSegments(data.fastestSegments),
        ],
      ],
    );
  }

  Widget _buildNarrativeCard(
      String headline, String summary, List<String> bullets) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                color: _accentStrong.withOpacity(0.75),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 13, color: _accentStrong),
                      const SizedBox(width: 6),
                      Text(
                        'market_overview_summary_title'.tr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _accentStrong,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    headline,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _primaryText,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _secondaryText,
                      height: 1.55,
                    ),
                  ),
                  if (bullets.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(color: _border, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.signal_cellular_alt_rounded,
                            size: 12, color: _lightText),
                        const SizedBox(width: 6),
                        Text(
                          'market_overview_key_signals'.tr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _lightText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...bullets.take(3).map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                color: _accentStrong,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                b,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _secondaryText,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow(Map<String, dynamic> overview) {
    final kpis = [
      ('market_overview_active_inventory'.tr,
        _fmt(overview['active_inventory']),
        Icons.inventory_2_outlined),
      ('market_overview_new_7_days'.tr,
        _fmt(overview['new_listings_7d']),
        Icons.north_east_rounded),
      ('market_overview_removed_7_days'.tr,
        _fmt(overview['removed_listings_7d']),
        Icons.south_east_rounded),
      ('market_overview_median_days'.tr,
        _fmtD(overview['median_days_on_market']),
        Icons.timelapse_rounded),
    ];

    return Row(
      children: kpis.asMap().entries.map((entry) {
        final i = entry.key;
        final kpi = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < kpis.length - 1 ? 10 : 0),
            child: _buildKpiTile(kpi.$1, kpi.$2, kpi.$3),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKpiTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: _accent),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _lightText),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSnapshot(
    Map<String, dynamic> sale,
    Map<String, dynamic> rent,
    String currency,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'market_overview_price_snapshot'.tr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow(
            Icons.home_outlined,
            'market_overview_sale'.tr,
            sale['average_price_per_sqm'],
            currency,
            sale['sample_size'],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: _border, height: 1),
          ),
          _buildPriceRow(
            Icons.key_outlined,
            'market_overview_rent'.tr,
            rent['average_price_per_sqm'],
            currency,
            rent['sample_size'],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    IconData icon,
    String label,
    dynamic pricePerM2,
    String currency,
    dynamic sampleSize,
  ) {
    final price = double.tryParse((pricePerM2 ?? '').toString());
    final priceText = price != null
        ? '${NumberFormat('#,##0', 'pl_PL').format(price)} $currency/m²'
        : '-';

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: _accentStrong.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Icon(icon, size: 13, color: _accentStrong)),
        ),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _primaryText)),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              priceText,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _accentStrong),
            ),
            Text(
              '${'market_overview_based_on_short'.tr} ${(sampleSize ?? 0)}',
              style:
                  const TextStyle(fontSize: 10, color: _lightText),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlowBar(Map<String, dynamic> overview) {
    final newCount =
        double.tryParse((overview['new_listings_7d'] ?? 0).toString()) ?? 0;
    final removedCount =
        double.tryParse((overview['removed_listings_7d'] ?? 0).toString()) ?? 0;
    final total = newCount + removedCount;
    final newRatio =
        total > 0 ? (newCount / total).clamp(0.0, 1.0) : 0.5;
    final removedRatio =
        total > 0 ? (removedCount / total).clamp(0.0, 1.0) : 0.5;

    String signalKey;
    if (removedCount > newCount * 1.1) {
      signalKey = 'market_overview_flow_demand_ahead';
    } else if (newCount > removedCount * 1.1) {
      signalKey = 'market_overview_flow_supply_ahead';
    } else {
      signalKey = 'market_overview_flow_balanced';
    }

    final newFlex = math.max(1, (newRatio * 100).round());
    final removedFlex = math.max(1, (removedRatio * 100).round());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'market_overview_market_flow'.tr,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _primaryText),
          ),
          const SizedBox(height: 6),
          Text(signalKey.tr,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _accentStrong)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: newFlex,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: _accentStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: removedFlex,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _flowLegend(_accentStrong,
                  'market_overview_new_7_days'.tr, _fmt(overview['new_listings_7d'])),
              const SizedBox(width: 12),
              _flowLegend(_red,
                  'market_overview_removed_7_days'.tr, _fmt(overview['removed_listings_7d'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flowLegend(Color color, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '$label: $value',
              style:
                  const TextStyle(fontSize: 11, color: _secondaryText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFastestSegments(List<dynamic> segments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'market_overview_fastest_segments'.tr,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: _secondaryText),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: segments.take(5).map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            final propertyType =
                (map['property_type'] ?? 'Unknown').toString().tr;
            final pulse = _pulseKey((map['label'] ?? 'Balanced').toString());
            final color = _pulseColorFromKey(pulse);

            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '$propertyType • ${pulse.tr}',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _chip(String label,
      {required Color background, required Color foreground}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }

  void _showFullDialog(BuildContext context, DailyMarketOverviewModel data) {
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = math.min(width * 0.92, isMobile ? 700.0 : 1100.0);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: 20),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 22, isMobile ? 16 : 20, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${'daily_market_overview'.tr} — ${data.city}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _primaryText,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _background,
                          shape: BoxShape.circle,
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: _secondaryText),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _border),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 22),
                  child: _buildContent(context, data),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  String _fmt(dynamic value) {
    final parsed = double.tryParse((value ?? '').toString());
    if (parsed == null) return '-';
    return NumberFormat('#,##0', 'pl_PL').format(parsed);
  }

  String _fmtD(dynamic value) {
    final parsed = double.tryParse((value ?? '').toString());
    if (parsed == null) return '-';
    return NumberFormat('#,##0.#', 'pl_PL').format(parsed);
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  String _pulseKey(String label) {
    switch (label.trim().toLowerCase()) {
      case 'hot':
        return 'pulse_hot';
      case 'warm':
        return 'pulse_warm';
      case 'slow':
        return 'pulse_slow';
      default:
        return 'pulse_balanced';
    }
  }

  Color _pulseColor(String label) =>
      _pulseColorFromKey(_pulseKey(label));

  Color _pulseColorFromKey(String key) {
    switch (key) {
      case 'pulse_hot':
        return Colors.redAccent;
      case 'pulse_warm':
        return _orange;
      case 'pulse_slow':
        return Colors.blueGrey;
      default:
        return _accentStrong;
    }
  }
}
