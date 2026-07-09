import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:math' as math;

import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reports/emma/anchors/anchors_reports.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_investment_score_section.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_versions_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:intl/intl.dart';
import 'package:reports/reports/report_pdf_page/models/pdf_report_model.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_daily_market_overview_section.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_air_quality_section.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_demographics_section.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_flood_risk_section.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_maintenance_cost_section.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_poi_section.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_government_section.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_market_velocity_section.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_price_trend_section.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_notes_section.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_price_alert_banner.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_value_history_section.dart';
import 'package:reports/reports/report_editor/model/report_template_model.dart';
import 'package:reports/reports/report_pdf_page/widgets/report_mortgage_calculator_section.dart';
import 'package:reports/reports/report_editor/provider/report_template_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportPreviewWidget extends ConsumerWidget {
  final PdfReportModel reportData;
  final bool isDialog;
  final VoidCallback? onClose;
  final bool forceMobileLayout;

  const ReportPreviewWidget({
    super.key,
    required this.reportData,
    this.isDialog = false,
    this.onClose,
    this.forceMobileLayout = false,
  });

  static const Color backgroundColor = Color(0xFFF6F7F9);
  static const Color cardColor = Colors.white;
  static const Color primaryTextColor = Color(0xFF171A1F);
  static const Color secondaryTextColor = Color(0xFF667085);
  static const Color lightTextColor = Color(0xFF98A2B3);
  static const Color accentColor = Color(0xFF5FCDD9);
  static const Color accentColorStrong = Color(0xFF2FB8C6);
  static const Color greenColor = Color(0xFF16A34A);
  static const Color orangeColor = Color(0xFFF59E0B);
  static const Color redColor = Color(0xFFEF4444);
  static const Color priceColor = Color(0xFF101828);
  static const Color borderColor = Color(0xFFE7ECF2);

  String _formatMoney(num? amount, String? currency) {
    if (amount == null) return '-';

    final fmt = NumberFormat.currency(
      locale: 'pl_PL',
      symbol: '',
      decimalDigits: 2,
    );
    final cur = (currency ?? '').trim().toLowerCase();
    final money = fmt.format(amount).trim();
    return cur.isEmpty ? money : '$money $cur';
  }

  String _formatCompactValue(num? value, String? unit) {
    if (value == null) return '-';

    final abs = value.abs();
    double display = value.toDouble();
    String suffix = '';

    if (abs >= 1000000) {
      display /= 1000000;
      suffix = 'M';
    } else if (abs >= 1000) {
      display /= 1000;
      suffix = 'K';
    }

    final text = display % 1 == 0
        ? display.toStringAsFixed(0)
        : display.toStringAsFixed(1);

    if (unit == null || unit.trim().isEmpty) return '$text$suffix';
    return '$text$suffix ${unit.trim()}';
  }

  String _formatPercent(num? value) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(1)}%';
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    return DateFormat('dd.MM.yyyy • HH:mm').format(parsed.toLocal());
  }

  Future<void> _openLink(String? url) async {
    if (url == null || url.trim().isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );
  }

  Color _positionColor(String? label) {
    switch (label) {
      case 'below_local_median':
        return greenColor;
      case 'above_local_median':
        return orangeColor;
      case 'near_local_median':
        return accentColorStrong;
      default:
        return secondaryTextColor;
    }
  }

  String _positionLabel(String? label) {
    switch (label) {
      case 'below_local_median':
        return 'Below local median'.tr;
      case 'above_local_median':
        return 'Above local median'.tr;
      case 'near_local_median':
        return 'Near local median'.tr;
      default:
        return 'No comparison'.tr;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = forceMobileLayout || width < 850;
    final tpl = ref.watch(activeReportTemplateProvider).valueOrNull ??
        const ReportTemplateModel();

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isMobile ? 18 : 24),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tpl.showPriceAlert &&
                reportData.report?.id != null &&
                reportData.estimation?.estimatedValue != null) ...[
              ReportPriceAlertBanner(
                reportId: reportData.report!.id!,
                currentValue: reportData.estimation!.estimatedValue!,
                currency: reportData.report!.currency ?? 'PLN',
                isMobile: isMobile,
              ),
            ],
            _buildHeader(isMobile),
            SizedBox(height: isMobile ? 20 : 28),
            _buildLocationSection(isMobile),
            SizedBox(height: isMobile ? 20 : 24),
            _buildEstimatedPrice(isMobile),
            SizedBox(height: isMobile ? 20 : 24),
            if (tpl.showValueHistory &&
                reportData.report?.id != null &&
                reportData.estimation?.estimatedValue != null) ...[
              EmmaUiAnchorTarget(
                // @emma-backend: EmmaAnchors.reportsPdfValueHistorySection
                anchorKey: EmmaAnchors.reportsPdfValueHistorySection.anchorKey,

                spec: EmmaAnchors.reportsPdfValueHistorySection,
                tapMode: EmmaUiAnchorTapMode.disabled,
                child: ReportValueHistorySection(
                  reportId: reportData.report!.id!,
                  currentValue: reportData.estimation!.estimatedValue!,
                  currency: reportData.report!.currency ?? 'PLN',
                  isMobile: isMobile,
                ),
              ),
              SizedBox(height: isMobile ? 20 : 28),
            ],
            if (reportData.pricesInArea != null) ...[
              _buildPricesChart(isMobile),
              SizedBox(height: isMobile ? 20 : 24),
            ],
            if (tpl.showPriceDistribution &&
                reportData.pricePerM2Distribution != null) ...[
              _buildDistributionChartCard(
                chart: reportData.pricePerM2Distribution!,
                isMobile: isMobile,
                moneyMode: false,
                titleKey: 'price_per_m2_distribution',
                descKey: 'price_per_m2_distribution_desc',
              ),
              SizedBox(height: isMobile ? 20 : 24),
            ],
            if (tpl.showPriceDistribution &&
                reportData.adjustedTotalPriceDistribution != null) ...[
              _buildDistributionChartCard(
                chart: reportData.adjustedTotalPriceDistribution!,
                isMobile: isMobile,
                moneyMode: true,
                titleKey: 'adjusted_total_price_distribution',
                descKey: 'adjusted_total_price_distribution_desc',
              ),
              SizedBox(height: isMobile ? 20 : 24),
            ],
            if (tpl.showAccuracyIndex && reportData.accuracyIndex != null) ...[
              _buildAccuracyIndex(isMobile),
              SizedBox(height: isMobile ? 20 : 24),
            ],
            _buildMapCard(context, isMobile),
            SizedBox(height: isMobile ? 20 : 24),
            if (tpl.showRentalData && reportData.rentalData != null) ...[
              _buildRentalData(isMobile),
              SizedBox(height: isMobile ? 20 : 24),
              _buildRentalRoi(isMobile),
              SizedBox(height: isMobile ? 20 : 24),
            ],
            if (reportData.estimation != null) ...[
              _buildEstimationDetails(isMobile),
              SizedBox(height: isMobile ? 20 : 24),
            ],
            if (tpl.showInvestmentScore) ...[
              ReportInvestmentScoreSection(
                reportData: reportData,
                isMobile: isMobile,
              ),
              SizedBox(height: isMobile ? 20 : 24),
            ],
            if (reportData.report != null) ...[
              if (tpl.showDailyMarketOverview) ...[
                EmmaUiAnchorTarget(
                  // @emma-backend: EmmaAnchors.reportsPdfDailyMarketOverviewSection
                  anchorKey: EmmaAnchors.reportsPdfDailyMarketOverviewSection.anchorKey,

                  spec: EmmaAnchors.reportsPdfDailyMarketOverviewSection,
                  tapMode: EmmaUiAnchorTapMode.disabled,
                  child: ReportDailyMarketOverviewSection(
                    reportData: reportData.report!,
                    isMobile: isMobile,
                  ),
                ),
                SizedBox(height: isMobile ? 20 : 24),
              ],
              if (tpl.showMarketVelocity) ...[
                EmmaUiAnchorTarget(
                  // @emma-backend: EmmaAnchors.reportsPdfMarketVelocitySection
                  anchorKey: EmmaAnchors.reportsPdfMarketVelocitySection.anchorKey,

                  spec: EmmaAnchors.reportsPdfMarketVelocitySection,
                  tapMode: EmmaUiAnchorTapMode.disabled,
                  child: ReportMarketVelocitySection(
                    reportData: reportData.report!,
                    isMobile: isMobile,
                  ),
                ),
                SizedBox(height: isMobile ? 20 : 24),
              ],
            ],
            if (tpl.showGovernmentData &&
                reportData.report?.governmentData != null) ...[
              ReportGovernmentSection(
                governmentData: reportData.report!.governmentData!,
              ),
              const SizedBox(height: 24),
            ],
            if (reportData.report?.city != null) ...[
              if (tpl.showDemographics) ...[
                ReportDemographicsSection(
                  city: reportData.report!.city!,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),
              ],
              if (tpl.showPriceTrend) ...[
                ReportPriceTrendSection(
                  city: reportData.report!.city!,
                  estateType: reportData.report?.propertyType,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),
              ],
            ],
            if (reportData.report?.streetAddress != null &&
                reportData.report?.city != null) ...[
              if (tpl.showFloodRisk) ...[
                ReportFloodRiskSection(
                  address: reportData.report!.streetAddress!,
                  city: reportData.report!.city!,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),
              ],
              if (tpl.showAirQuality) ...[
                ReportAirQualitySection(
                  address: reportData.report!.streetAddress!,
                  city: reportData.report!.city!,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),
              ],
              if (tpl.showPoi) ...[
                ReportPoiSection(
                  address: reportData.report!.streetAddress!,
                  city: reportData.report!.city!,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),
              ],
            ],
            if (tpl.showMaintenanceCost) ...[
              ReportMaintenanceCostSection(
                reportData: reportData,
                isMobile: isMobile,
              ),
              const SizedBox(height: 16),
            ],
            if (tpl.showMortgageCalculator) ...[
              ReportMortgageCalculatorSection(
                reportData: reportData,
                isMobile: isMobile,
              ),
              const SizedBox(height: 16),
            ],
            if (tpl.showComparables &&
                reportData.comparable != null &&
                reportData.comparable!.isNotEmpty) ...[
              _buildComparables(isMobile),
              SizedBox(height: isMobile ? 20 : 24),
            ],
            if (tpl.showReportVersions && reportData.report?.id != null) ...[
              ReportVersionsSection(
                currentReportId: reportData.report!.id!,
                streetAddress: reportData.report!.streetAddress,
                city: reportData.report!.city,
                isMobile: isMobile,
              ),
              SizedBox(height: isMobile ? 20 : 24),
            ],
            if (tpl.showAgentNotes && reportData.report?.id != null) ...[
              EmmaUiAnchorTarget(
                // @emma-backend: EmmaAnchors.reportsPdfAgentNotesSection
                anchorKey: EmmaAnchors.reportsPdfAgentNotesSection.anchorKey,

                spec: EmmaAnchors.reportsPdfAgentNotesSection,
                tapMode: EmmaUiAnchorTapMode.disabled,
                child: ReportNotesSection(
                  reportId: reportData.report!.id!,
                  isMobile: isMobile,
                ),
              ),
              SizedBox(height: isMobile ? 20 : 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Property Report'.tr,
            style: TextStyle(
              fontSize: isMobile ? 22 : 26,
              fontWeight: FontWeight.w700,
              color: primaryTextColor,
            ),
          ),
        ),
        if (onClose != null)
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        if (!isMobile)
          const Text(
            'HOUSLY',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: primaryTextColor,
              letterSpacing: 2,
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(24),
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

  Widget _buildSectionTitle(
    String title, {
    String? subtitle,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: accentColorStrong),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null && subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection(bool isMobile) {
    final location = reportData.location;
    final report = reportData.report;

    return _buildSectionCard(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: accentColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  location?.fullAddress ??
                      location?.address ??
                      report?.streetAddress ??
                      'Address not available'.tr,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 21,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            [
              report?.propertyType,
              report?.typeOfBuilding,
              report?.buildingMaterial,
            ].where((e) => e != null && e!.trim().isNotEmpty).join(' • '),
            style: const TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (report?.floorArea != null)
                _buildChip(
                  Icons.square_foot,
                  '${report!.floorArea!.toStringAsFixed(0)} m²',
                ),
              if (report?.bedrooms != null)
                _buildChip(
                  Icons.bed_outlined,
                  '${report!.bedrooms} ${'roms'.tr}',
                ),
              if (report?.bathrooms != null)
                _buildChip(
                  Icons.bathtub_outlined,
                  '${report!.bathrooms} ${'bathrooms'.tr}',
                ),
              if (report?.floorLevel != null)
                _buildChip(
                  Icons.layers_outlined,
                  '${'floor'.tr}: ${report!.floorLevel}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: secondaryTextColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatedPrice(bool isMobile) {
    final price =
        reportData.report?.valueEstimate ?? reportData.estimation?.estimatedValue;
    final currency =
        reportData.report?.currency ?? reportData.estimation?.currency;

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatMoney(price, currency),
            style: TextStyle(
              fontSize: isMobile ? 30 : 40,
              fontWeight: FontWeight.w700,
              color: priceColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estimated selling price'.tr,
            style: const TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricesChart(bool isMobile) {
    final prices = reportData.pricesInArea!;
    final currency = prices.currency;

    final min = prices.minPrice ?? 0;
    final avg = prices.averagePrice ?? 0;
    final max = prices.maxPrice ?? 0;

    final barValues = <double>[
      min,
      min + (avg - min) * 0.2,
      min + (avg - min) * 0.55,
      avg,
      avg + (max - avg) * 0.3,
      avg + (max - avg) * 0.65,
      max,
    ];

    return _buildSectionCard(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'prices_in_the_area'.tr,
            subtitle:
                '${prices.sampleSize ?? 0} ${'offers_in_sample'.tr} • ${'not_enough_data_to_build_this_distribution'.tr}',
            icon: Icons.bar_chart_rounded,
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              barValues.length,
              (index) {
                final ratio = barValues.length <= 1
                    ? 1.0
                    : (index + 1) / barValues.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildBar(barValues[index], max, ratio, isMobile),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPricePoint(
                'min'.tr,
                _formatMoney(min, currency),
              ),
              _buildPricePoint(
                'average'.tr,
                _formatMoney(avg, currency),
                isPrimary: true,
              ),
              _buildPricePoint(
                'max'.tr,
                _formatMoney(max, currency),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(
    double value,
    double maxValue,
    double intensity,
    bool isMobile,
  ) {
    final heightRatio = maxValue > 0 ? (value / maxValue).clamp(0.1, 1.0) : 0.1;
    final maxHeight = isMobile ? 110.0 : 150.0;

    return Container(
      width: isMobile ? 26 : 42,
      height: maxHeight * heightRatio,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            accentColor.withOpacity(0.35 + (0.25 * intensity)),
            accentColor.withOpacity(0.82),
          ],
        ),
      ),
    );
  }

  Widget _buildPricePoint(String label, String value, {bool isPrimary = false}) {
    return Column(
      crossAxisAlignment:
          isPrimary ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isPrimary ? 18 : 14,
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: lightTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionChartCard({
    required DistributionChartData chart,
    required bool isMobile,
    required bool moneyMode,
    String? titleKey,
    String? descKey,
  }) {
    final resolvedTitle = titleKey != null ? titleKey.tr : (chart.title ?? 'market_distribution'.tr);
    final resolvedDesc = descKey != null ? descKey.tr : (chart.description ?? 'bars_show_how_many_comparable_offers_fall_into_each_price_range'.tr);

    if (!chart.hasData) {
      return _buildSectionCard(
        padding: EdgeInsets.all(isMobile ? 18 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              resolvedTitle,
              subtitle: resolvedDesc,
              icon: Icons.query_stats_rounded,
            ),
            const SizedBox(height: 16),
            Text(
             'not_enough_data_to_build_this_distribution'.tr,
              style: const TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    final maxCount = chart.maxBinCount <= 0 ? 1 : chart.maxBinCount;
    final subjectColor = _positionColor(chart.subjectPositionLabel);
    final unit = chart.unitLabel;
    final currencyForMoney =
        moneyMode ? unit : (unit?.split('/').first.trim().isEmpty == true ? null : unit?.split('/').first.trim());

    return _buildSectionCard(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            resolvedTitle,
            subtitle: resolvedDesc,
            icon: Icons.stacked_bar_chart_rounded,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildInfoPill(
                Icons.dataset_outlined,
                '${chart.sampleSize} ${'offers'.tr}',
              ),
              if (chart.subjectValue != null)
                _buildInfoPill(
                  Icons.home_work_outlined,
                  moneyMode
                      ? _formatMoney(chart.subjectValue, currencyForMoney)
                      : _formatCompactValue(chart.subjectValue, chart.unitLabel),
                  color: subjectColor.withOpacity(0.12),
                  textColor: subjectColor,
                ),
              if (chart.subjectVsMedianPct != null)
                _buildInfoPill(
                  Icons.compare_arrows_rounded,
                  '${chart.subjectVsMedianPct! >= 0 ? '+' : ''}${chart.subjectVsMedianPct!.toStringAsFixed(1)}% ${'vs_median'.tr}',
                  color: subjectColor.withOpacity(0.12),
                  textColor: subjectColor,
                ),
              if (chart.subjectPositionLabel != null)
                _buildInfoPill(
                  Icons.insights_outlined,
                  _positionLabel(chart.subjectPositionLabel),
                  color: subjectColor.withOpacity(0.12),
                  textColor: subjectColor,
                ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: isMobile ? 210 : 250,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                chart.bins.length,
                (index) {
                  final bin = chart.bins[index];
                  final isSubjectBin = chart.subjectBinIndex == index;
                  final ratio = (bin.count / maxCount).clamp(0.0, 1.0);
                  final barHeight = (isMobile ? 110.0 : 145.0) * ratio + 18;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${bin.count}',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.w700,
                              color: isSubjectBin
                                  ? accentColorStrong
                                  : secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            height: barHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: isSubjectBin
                                    ? [
                                        accentColorStrong.withOpacity(0.70),
                                        accentColorStrong,
                                      ]
                                    : [
                                        accentColor.withOpacity(0.35),
                                        accentColor.withOpacity(0.80),
                                      ],
                              ),
                              border: isSubjectBin
                                  ? Border.all(
                                      color: accentColorStrong,
                                      width: 2,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: (isSubjectBin
                                          ? accentColorStrong
                                          : accentColor)
                                      .withOpacity(0.14),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: isSubjectBin
                                ? Align(
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'this_ad'.tr,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            moneyMode
                                ? '${_formatCompactValue(bin.fromValue, currencyForMoney)} - ${_formatCompactValue(bin.toValue, currencyForMoney)}'
                                : '${_formatCompactValue(bin.fromValue, chart.unitLabel)} - ${_formatCompactValue(bin.toValue, chart.unitLabel)}',
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 11,
                              height: 1.25,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSummaryMetric(
                'min'.tr,
                moneyMode
                    ? _formatMoney(chart.minValue, currencyForMoney)
                    : _formatCompactValue(chart.minValue, chart.unitLabel),
              ),
              _buildSummaryMetric(
                'median'.tr,
                moneyMode
                    ? _formatMoney(chart.medianValue, currencyForMoney)
                    : _formatCompactValue(chart.medianValue, chart.unitLabel),
              ),
              _buildSummaryMetric(
                'average'.tr,
                moneyMode
                    ? _formatMoney(chart.averageValue, currencyForMoney)
                    : _formatCompactValue(chart.averageValue, chart.unitLabel),
              ),
              _buildSummaryMetric(
                'max'.tr,
                moneyMode
                    ? _formatMoney(chart.maxValue, currencyForMoney)
                    : _formatCompactValue(chart.maxValue, chart.unitLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: lightTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(
    IconData icon,
    String text, {
    Color? color,
    Color? textColor,
  }) {
    final bg = color ?? accentColor.withOpacity(0.10);
    final fg = textColor ?? primaryTextColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: fg.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyIndex(bool isMobile) {
    final accuracy = reportData.accuracyIndex!;

    return _buildSectionCard(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'accuracy_index'.tr,
            subtitle:
                'the_quoted_price_is_calculated_based_on_asking_prices_and_comparable_listings'.tr,
            icon: Icons.verified_outlined,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _buildMetricCard(
                icon: Icons.verified_outlined,
                title: 'confidence'.tr,
                value: '${(accuracy.percentage ?? 0).toStringAsFixed(1)}%',
              ),
              _buildMetricCard(
                icon: Icons.description_outlined,
                title: 'comparable_offers'.tr,
                value: '${accuracy.offersCount ?? 0}',
              ),
              _buildMetricCard(
                icon: Icons.square_foot_outlined,
                title: 'estimated_error_range'.tr,
                value: accuracy.areaM2 != null
                    ? '${accuracy.areaM2!.toStringAsFixed(1)} m²'
                    : '-',
              ),
              _buildMetricCard(
                icon: Icons.tune,
                title: 'median_area_delta'.tr,
                value: accuracy.medianAreaDeltaPct != null
                    ? '${(accuracy.medianAreaDeltaPct! * 100).toStringAsFixed(1)}%'
                    : '-',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
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
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accentColorStrong,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(BuildContext context, bool isMobile) {
    final location = reportData.location;
    final report = reportData.report;
    final hasCoordinates =
        (location?.hasCoordinates ?? false) || (report?.hasCoordinates ?? false);

    final lat = location?.lat ?? report?.lat;
    final lon = location?.lon ?? report?.lon;

    return _buildSectionCard(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'location_overview'.tr,
            icon: Icons.location_searching,
          ),
          const SizedBox(height: 16),
          Container(
            height: isMobile ? 190 : 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.10),
                  const Color(0xFFEFF7FA),
                ],
              ),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: hasCoordinates
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_searching,
                          size: 42,
                          color: accentColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          location?.fullAddress ??
                              location?.address ??
                             'coordinates_available'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${lat?.toStringAsFixed(6)}, ${lon?.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _openLink(
                            'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
                          ),
                          icon: const Icon(Icons.open_in_new),
                          label: Text('open_map'.tr),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          size: 48,
                          color: lightTextColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'map_coordinates_are_not_available'.tr,
                          style: const TextStyle(
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalData(bool isMobile) {
    final rental = reportData.rentalData!;

    return _buildSectionCard(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'rental_information'.tr,
            subtitle:
                '${rental.sampleSize ?? 0} ${'rental_comparables'.tr}',
            icon: Icons.home_work_outlined,
          ),
          const SizedBox(height: 18),
          _buildDataRow(
            'monthly_rental'.tr,
            _formatMoney(rental.rental, rental.currency),
          ),
          _buildDataRow(
            'administrative_fees'.tr,
            _formatMoney(rental.administrativeFees, rental.currency),
          ),
          _buildDataRow(
            'estimated_annual_rental'.tr,
            _formatMoney(rental.estimatedRentalPrice, rental.currency),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalRoi(bool isMobile) {
    final rental = reportData.rentalData;
    final roi = rental?.roi;

    if (rental == null || roi == null) {
      return const SizedBox.shrink();
    }

    return _buildSectionCard(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'rental_roi'.tr,
            subtitle:
                'gross_roi_uses_annual_rent_net_roi_subtracts_estimated_administrative_fees'.tr,
            icon: Icons.pie_chart_outline_rounded,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _buildMetricCard(
                icon: Icons.percent_rounded,
                title: 'gross_yield'.tr,
                value: _formatPercent(roi.grossYieldPct),
              ),
              _buildMetricCard(
                icon: Icons.savings_outlined,
                title: 'net_yield'.tr,
                value: _formatPercent(roi.netYieldPct),
              ),
              _buildMetricCard(
                icon: Icons.calendar_month_outlined,
                title: 'annual_net_income'.tr,
                value: _formatMoney(roi.annualNetIncome, rental.currency),
              ),
              _buildMetricCard(
                icon: Icons.payments_outlined,
                title: 'monthly_net_income'.tr,
                value: _formatMoney(roi.monthlyNetIncome, rental.currency),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDataRow(
            'reference_sale_value'.tr,
            _formatMoney(roi.referenceSaleValue, rental.currency),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimationDetails(bool isMobile) {
    final estimation = reportData.estimation!;

    return _buildSectionCard(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'valuation_details'.tr,
            icon: Icons.calculate_outlined,
          ),
          const SizedBox(height: 18),
          _buildDataRow(
            'estimated_value'.tr,
            _formatMoney(estimation.estimatedValue, estimation.currency),
          ),
          _buildDataRow(
            'price_per_m2'.tr,
            _formatMoney(estimation.estimatedPricePerM2, estimation.currency),
          ),
          _buildDataRow(
            'low_estimate'.tr,
            _formatMoney(estimation.lowValue, estimation.currency),
          ),
          _buildDataRow(
            'high_estimate'.tr,
            _formatMoney(estimation.highValue, estimation.currency),
          ),
          _buildDataRow(
            'confidence_percent'.tr,
            '${((estimation.confidence ?? 0) * 100).toStringAsFixed(1)}%',
          ),
          _buildDataRow(
            'comparables_used'.tr,
            '${estimation.comparablesUsed ?? 0}',
          ),
        ],
      ),
    );
  }


  Widget _buildComparables(bool isMobile) {
    final comparables = reportData.comparable ?? [];
    final excludedDuplicates = reportData.excludedDuplicateCount ?? 0;
    final excludedOutliers = reportData.excludedOutlierCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'comparable_properties'.tr,
          subtitle:
              'top_matches_used_after_removing_duplicate_and_suspicious_offers'.tr,
          icon: Icons.apartment_outlined,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildInfoPill(
              Icons.list_alt_rounded,
              '${comparables.length} ${'visible_matches'.tr}'
            ),
            if (excludedDuplicates > 0)
              _buildInfoPill(
                Icons.copy_all_rounded,
                '$excludedDuplicates ${'duplicates_excluded'.tr}',
                color: orangeColor.withOpacity(0.12),
                textColor: orangeColor,
              ),
            if (excludedOutliers > 0)
              _buildInfoPill(
                Icons.warning_amber_rounded,
                '$excludedOutliers ${'suspicious_offers_excluded'.tr}',
                color: redColor.withOpacity(0.12),
                textColor: redColor,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: _CsvExportButton(
            comparables: comparables,
            reportAddress: reportData.report?.streetAddress ??
                reportData.location?.address ??
                'report',
          ),
        ),
        const SizedBox(height: 12),
        ...comparables.take(10).map(
          (comp) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: comp.link != null ? () => _openLink(comp.link) : null,
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 14 : 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: isMobile
                      ? _buildComparableMobile(comp)
                      : _buildComparableDesktop(comp),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparableDesktop(ComparableProperty comp) {
    return Row(
      children: [
        Container(
          width: 94,
          height: 94,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.22),
                accentColor.withOpacity(0.08),
              ],
            ),
          ),
          child: const Icon(
            Icons.home_work_outlined,
            size: 34,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comp.title ?? 'comparable_property'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                comp.fullAddress.isNotEmpty
                    ? comp.fullAddress
                    : 'Address not available'.tr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  if (comp.floorArea != null)
                    _smallInfo(
                      Icons.square_foot_outlined,
                      '${comp.floorArea!.toStringAsFixed(0)} m²',
                    ),
                  if (comp.rooms != null)
                    _smallInfo(
                      Icons.bed_outlined,
                      '${comp.rooms} ${'roms'.tr}',
                    ),
                  if (comp.bathrooms != null)
                    _smallInfo(
                      Icons.bathtub_outlined,
                      '${comp.bathrooms} ${'bath'.tr}',
                    ),
                  if (comp.pricePerM2 != null)
                    _smallInfo(
                      Icons.payments_outlined,
                      _formatMoney(comp.pricePerM2, comp.currency),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (comp.similarityScore != null)
                    _scoreBadge(
                      'Score'.tr,
                      comp.similarityScore!.toStringAsFixed(2),
                    ),
                  if (comp.areaDeltaPct != null)
                    _scoreBadge(
                      'area_delta'.tr,
                      '${(comp.areaDeltaPct! * 100).toStringAsFixed(1)}%',
                    ),
                  if (comp.priceDeltaPct != null)
                    _scoreBadge(
                      'price_delta'.tr,
                      '${(comp.priceDeltaPct! * 100).toStringAsFixed(1)}%',
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatMoney(comp.price, comp.currency),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: priceColor,
              ),
            ),
            const SizedBox(height: 6),
            if (comp.link != null)
              Text(
                'open_listing'.tr,
                style: const TextStyle(
                  fontSize: 12,
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparableMobile(ComparableProperty comp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.22),
                    accentColor.withOpacity(0.08),
                  ],
                ),
              ),
              child: const Icon(
                Icons.home_work_outlined,
                size: 30,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                comp.title ?? 'comparable_property'.tr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          comp.fullAddress.isNotEmpty
              ? comp.fullAddress
              : 'Address not available'.tr,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (comp.floorArea != null)
              _smallInfo(
                Icons.square_foot_outlined,
                '${comp.floorArea!.toStringAsFixed(0)} m²',
              ),
            if (comp.rooms != null)
              _smallInfo(
                Icons.bed_outlined,
                '${comp.rooms} ${'roms'.tr}',
              ),
            if (comp.bathrooms != null)
              _smallInfo(
                Icons.bathtub_outlined,
                '${comp.bathrooms} ${'bath'.tr}',
              ),
            if (comp.pricePerM2 != null)
              _smallInfo(
                Icons.payments_outlined,
                _formatMoney(comp.pricePerM2, comp.currency),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (comp.similarityScore != null)
              _scoreBadge(
                'Score'.tr,
                comp.similarityScore!.toStringAsFixed(2),
              ),
            if (comp.areaDeltaPct != null)
              _scoreBadge(
                'area_delta'.tr,
                '${(comp.areaDeltaPct! * 100).toStringAsFixed(1)}%',
              ),
            if (comp.priceDeltaPct != null)
              _scoreBadge(
                 'price_delta'.tr,
                '${(comp.priceDeltaPct! * 100).toStringAsFixed(1)}%',
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                _formatMoney(comp.price, comp.currency),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: priceColor,
                ),
              ),
            ),
            if (comp.link != null)
              Text(
                'open_listing'.tr,
                style: const TextStyle(
                  fontSize: 12,
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _smallInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: secondaryTextColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _scoreBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          color: primaryTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
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
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CSV export button ─────────────────────────────────────────────────────────

class _CsvExportButton extends StatefulWidget {
  final List<ComparableProperty> comparables;
  final String reportAddress;

  const _CsvExportButton({
    required this.comparables,
    required this.reportAddress,
  });

  @override
  State<_CsvExportButton> createState() => _CsvExportButtonState();
}

class _CsvExportButtonState extends State<_CsvExportButton> {
  bool _exporting = false;
  bool _done = false;

  static const _accent = ReportPreviewWidget.accentColor;
  static const _accentStrong = ReportPreviewWidget.accentColorStrong;
  static const _green = ReportPreviewWidget.greenColor;
  static const _border = ReportPreviewWidget.borderColor;
  static const _light = ReportPreviewWidget.lightTextColor;

  String _buildCsv() {
    final sb = StringBuffer();
    // Header row
    sb.writeln(
        'Title,Address,City,Offer Type,Rooms,Bathrooms,Floor,Area (m²),Price,Price/m²,Currency,Similarity (%),URL');

    for (final c in widget.comparables) {
      String _q(String? v) {
        if (v == null) return '';
        final escaped = v.replaceAll('"', '""');
        return '"$escaped"';
      }

      sb.writeln([
        _q(c.title),
        _q(c.fullAddress.isNotEmpty ? c.fullAddress : c.street),
        _q(c.city),
        _q(c.offerType),
        c.rooms?.toString() ?? '',
        c.bathrooms?.toString() ?? '',
        c.floor?.toString() ?? '',
        c.floorArea?.toStringAsFixed(1) ?? '',
        c.price?.toStringAsFixed(0) ?? '',
        c.pricePerM2?.toStringAsFixed(0) ?? '',
        _q(c.currency),
        c.similarityScore != null
            ? (c.similarityScore! * 100).toStringAsFixed(1)
            : '',
        _q(c.link),
      ].join(','));
    }
    return sb.toString();
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      final csv = _buildCsv();
      final bytes = const Utf8Encoder().convert(csv);

      final dir = await getTemporaryDirectory();
      final safe = widget.reportAddress
          .replaceAll(RegExp(r'[^\w\s]'), '_')
          .replaceAll(' ', '_')
          .toLowerCase();
      final path = '${dir.path}${Platform.pathSeparator}comparables_$safe.csv';
      await File(path).writeAsBytes(bytes);

      final uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }

      if (!mounted) return;
      setState(() {
        _exporting = false;
        _done = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _done = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('${'export_csv_error'.tr}: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _exporting ? null : _export,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _done
              ? _green.withOpacity(0.1)
              : _accentStrong.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _done
                ? _green.withOpacity(0.3)
                : _accentStrong.withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _exporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: ReportPreviewWidget.accentColorStrong),
                  )
                : Icon(
                    _done
                        ? Icons.check_rounded
                        : Icons.download_rounded,
                    size: 15,
                    color: _done ? _green : _accentStrong,
                  ),
            const SizedBox(width: 7),
            Text(
              _done
                  ? 'exported'.tr
                  : 'export_csv'.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _done ? _green : _accentStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}