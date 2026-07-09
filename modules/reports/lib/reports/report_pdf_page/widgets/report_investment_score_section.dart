import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:reports/reports/report_pdf_page/models/pdf_report_model.dart';

const _primaryText = Color(0xFF171A1F);
const _secondaryText = Color(0xFF667085);
const _lightText = Color(0xFF98A2B3);
const _accent = Color(0xFF5FCDD9);
const _accentStrong = Color(0xFF2FB8C6);
const _background = Color(0xFFF6F7F9);
const _card = Colors.white;
const _border = Color(0xFFE7ECF2);
const _green = Color(0xFF16A34A);
const _orange = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);

class ReportInvestmentScoreSection extends StatelessWidget {
  final PdfReportModel reportData;
  final bool isMobile;

  const ReportInvestmentScoreSection({
    super.key,
    required this.reportData,
    required this.isMobile,
  });

  // ── Score calculation ──────────────────────────────────────────────────────

  /// Score for rental yield (0–25 pts)
  int _roiScore() {
    final roi = reportData.rentalData?.roi;
    if (roi == null) return 0;
    final gross = roi.grossYieldPct ?? 0;
    if (gross >= 6) return 25;
    if (gross >= 4) return 18;
    if (gross >= 2) return 10;
    return 3;
  }

  /// Score for market accuracy/data quality (0–20 pts)
  int _accuracyScore() {
    final acc = reportData.accuracyIndex;
    if (acc == null) return 0;
    final pct = acc.percentage ?? 0;
    if (pct >= 90) return 20;
    if (pct >= 75) return 15;
    if (pct >= 60) return 10;
    return 5;
  }

  /// Score for amenities count (0–15 pts)
  int _amenitiesScore() {
    final r = reportData.report;
    if (r == null) return 0;
    final count = [
      r.hasBalcony,
      r.hasElevator,
      r.hasParking,
      r.hasGym,
      r.hasSauna,
      r.hasAirConditioning,
      r.hasGarden,
      r.hasBasement,
    ].where((v) => v).length;
    return (count * 15 / 8).round().clamp(0, 15);
  }

  /// Score for building age (0–15 pts)
  int _ageScore() {
    final year = reportData.report?.yearBuilt ?? 0;
    if (year == 0) return 5;
    if (year >= 2015) return 15;
    if (year >= 2005) return 11;
    if (year >= 1995) return 7;
    if (year >= 1980) return 4;
    return 2;
  }

  /// Score for comparable sample size = market liquidity (0–15 pts)
  int _liquidityScore() {
    final count = reportData.comparableCount ?? reportData.comparable?.length ?? 0;
    if (count >= 50) return 15;
    if (count >= 25) return 12;
    if (count >= 10) return 8;
    if (count >= 3) return 4;
    return 0;
  }

  /// Score for price position vs. market median (0–10 pts)
  int _pricePositionScore() {
    final dist = reportData.pricePerM2Distribution;
    if (dist == null) return 5;
    final pct = dist.subjectVsMedianPct;
    if (pct == null) return 5;
    // Below or at median = good for buyers; above = less attractive
    if (pct <= -10) return 10; // Well below median — bargain
    if (pct <= 0) return 8;    // Below or at median
    if (pct <= 10) return 6;   // Slightly above
    if (pct <= 25) return 4;   // Moderately above
    return 2;                  // Significantly above market
  }

  List<_ScoreItem> _scoreItems() {
    return [
      _ScoreItem(
        label: 'score_rental_yield'.tr,
        score: _roiScore(),
        maxScore: 25,
        icon: Icons.percent_rounded,
        detail: _roiDetail(),
      ),
      _ScoreItem(
        label: 'score_data_quality'.tr,
        score: _accuracyScore(),
        maxScore: 20,
        icon: Icons.analytics_outlined,
        detail: _accuracyDetail(),
      ),
      _ScoreItem(
        label: 'score_amenities'.tr,
        score: _amenitiesScore(),
        maxScore: 15,
        icon: Icons.star_outline_rounded,
        detail: _amenitiesDetail(),
      ),
      _ScoreItem(
        label: 'score_building_age'.tr,
        score: _ageScore(),
        maxScore: 15,
        icon: Icons.domain_rounded,
        detail: _ageDetail(),
      ),
      _ScoreItem(
        label: 'score_market_liquidity'.tr,
        score: _liquidityScore(),
        maxScore: 15,
        icon: Icons.show_chart_rounded,
        detail: _liquidityDetail(),
      ),
      _ScoreItem(
        label: 'score_price_position'.tr,
        score: _pricePositionScore(),
        maxScore: 10,
        icon: Icons.price_check_rounded,
        detail: _pricePositionDetail(),
      ),
    ];
  }

  String _roiDetail() {
    final gross = reportData.rentalData?.roi?.grossYieldPct;
    if (gross == null) return 'no_rental_data'.tr;
    return '${gross.toStringAsFixed(1)}% ${'gross_yield'.tr}';
  }

  String _accuracyDetail() {
    final pct = reportData.accuracyIndex?.percentage;
    if (pct == null) return 'no_data'.tr;
    return '${pct.toStringAsFixed(1)}% ${'accuracy'.tr}';
  }

  String _amenitiesDetail() {
    final r = reportData.report;
    if (r == null) return 'no_data'.tr;
    final count = [
      r.hasBalcony, r.hasElevator, r.hasParking, r.hasGym,
      r.hasSauna, r.hasAirConditioning, r.hasGarden, r.hasBasement,
    ].where((v) => v).length;
    return '$count / 8 ${'amenities'.tr}';
  }

  String _ageDetail() {
    final year = reportData.report?.yearBuilt;
    if (year == null || year == 0) return 'year_unknown'.tr;
    return '${'built_in'.tr} $year';
  }

  String _liquidityDetail() {
    final count = reportData.comparableCount ?? reportData.comparable?.length ?? 0;
    return '$count ${'comparable_offers'.tr}';
  }

  String _pricePositionDetail() {
    final pct = reportData.pricePerM2Distribution?.subjectVsMedianPct;
    if (pct == null) return 'no_data'.tr;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}% ${'vs_market_median'.tr}';
  }

  int _totalScore() {
    return _scoreItems().fold(0, (sum, item) => sum + item.score);
  }

  int _maxTotalScore() {
    return _scoreItems().fold(0, (sum, item) => sum + item.maxScore);
  }

  String _grade(int score, int maxScore) {
    final pct = maxScore == 0 ? 0 : score / maxScore;
    if (pct >= 0.80) return 'A';
    if (pct >= 0.65) return 'B';
    if (pct >= 0.50) return 'C';
    if (pct >= 0.35) return 'D';
    return 'F';
  }

  Color _scoreColor(int score, int maxScore) {
    final pct = maxScore == 0 ? 0 : score / maxScore;
    if (pct >= 0.65) return _green;
    if (pct >= 0.40) return _orange;
    return _red;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final items = _scoreItems();
    final total = _totalScore();
    final maxTotal = _maxTotalScore();
    final grade = _grade(total, maxTotal);
    final color = _scoreColor(total, maxTotal);

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(total, maxTotal, grade, color),
          const SizedBox(height: 20),
          _buildScoreRow(total, maxTotal, color),
          const SizedBox(height: 20),
          _buildScoreGrid(items),
        ],
      ),
    );
  }

  Widget _buildHeader(int total, int max, String grade, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.insights_rounded,
              size: 20, color: _accentStrong),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'investment_score'.tr,
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                ),
              ),
              Text(
                'investment_score_subtitle'.tr,
                style: const TextStyle(
                    fontSize: 12, color: _secondaryText),
              ),
            ],
          ),
        ),
        // Grade badge
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.4), width: 2),
          ),
          child: Center(
            child: Text(
              grade,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRow(int total, int max, Color color) {
    final fraction = max == 0 ? 0.0 : total / max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 8,
                  backgroundColor: _border,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$total / $max',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'investment_score_description'.tr,
          style: const TextStyle(fontSize: 11, color: _lightText),
        ),
      ],
    );
  }

  Widget _buildScoreGrid(List<_ScoreItem> items) {
    if (isMobile) {
      return Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ScoreTile(item: item),
                ))
            .toList(),
      );
    }

    // 2-column grid for desktop
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final a = items[i];
      final b = i + 1 < items.length ? items[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(child: _ScoreTile(item: a)),
              const SizedBox(width: 10),
              Expanded(child: b != null ? _ScoreTile(item: b) : const SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _ScoreItem {
  final String label;
  final int score;
  final int maxScore;
  final IconData icon;
  final String detail;

  const _ScoreItem({
    required this.label,
    required this.score,
    required this.maxScore,
    required this.icon,
    required this.detail,
  });

  Color get color {
    final pct = maxScore == 0 ? 0 : score / maxScore;
    if (pct >= 0.65) return _green;
    if (pct >= 0.40) return _orange;
    return _red;
  }
}

class _ScoreTile extends StatelessWidget {
  final _ScoreItem item;

  const _ScoreTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final fraction =
        item.maxScore == 0 ? 0.0 : item.score / item.maxScore;
    final color = item.color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${item.score}/${item.maxScore}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.detail,
            style:
                const TextStyle(fontSize: 11, color: _secondaryText),
          ),
        ],
      ),
    );
  }
}
