import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:intl/intl.dart';
import 'package:reports/reports/report_pdf_page/models/pdf_report_model.dart';
import 'package:core/theme/backgroundgradient.dart';

class ReportMortgageCalculatorSection extends ConsumerStatefulWidget {
  final PdfReportModel reportData;
  final bool isMobile;

  const ReportMortgageCalculatorSection({
    super.key,
    required this.reportData,
    required this.isMobile,
  });

  @override
  ConsumerState<ReportMortgageCalculatorSection> createState() =>
      _ReportMortgageCalculatorSectionState();
}

class _ReportMortgageCalculatorSectionState
    extends ConsumerState<ReportMortgageCalculatorSection> {
  late double _propertyPrice;
  late double _downPaymentPct;
  late double _annualRatePct;
  late int    _termYears;

  final _fmt = NumberFormat.currency(locale: 'pl_PL', symbol: '', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _propertyPrice   = (widget.reportData.report?.valueEstimate ??
        widget.reportData.estimation?.estimatedValue ??
        400000).toDouble();
    _downPaymentPct  = 20;
    _annualRatePct   = 7.5;
    _termYears       = 25;
  }

  // ── Calculations ──────────────────────────────────────────────────────────

  double get _loanAmount    => _propertyPrice * (1 - _downPaymentPct / 100);
  double get _monthlyRate   => _annualRatePct / 100 / 12;
  int    get _totalMonths   => _termYears * 12;
  double get _ltv           => (1 - _downPaymentPct / 100) * 100;

  double get _monthlyPayment {
    final r = _monthlyRate;
    final n = _totalMonths;
    final p = _loanAmount;
    if (r == 0) return p / n;
    return p * r * math.pow(1 + r, n) / (math.pow(1 + r, n) - 1);
  }

  double get _totalPaid    => _monthlyPayment * _totalMonths;
  double get _totalInterest => _totalPaid - _loanAmount;

  String _fmtMoney(double v) {
    final cur = widget.reportData.report?.currency ?? 'PLN';
    return '${_fmt.format(v)} $cur';
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textColor = CustomColors.secondaryWidgetTextColor(context, ref);
    final bgColor   = CustomColors.secondaryWidgetColor(context, ref);
    const accent    = Color(0xFF5FCDD9);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_outlined, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'mortgage_calculator'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          widget.isMobile
              ? _buildColumnLayout(textColor, accent)
              : _buildRowLayout(textColor, accent),
        ],
      ),
    );
  }

  Widget _buildRowLayout(Color textColor, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSliders(textColor, accent)),
        const SizedBox(width: 24),
        SizedBox(width: 220, child: _buildResults(textColor, accent)),
      ],
    );
  }

  Widget _buildColumnLayout(Color textColor, Color accent) {
    return Column(
      children: [
        _buildSliders(textColor, accent),
        const SizedBox(height: 20),
        _buildResults(textColor, accent),
      ],
    );
  }

  Widget _buildSliders(Color textColor, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SliderRow(
          label: 'property_price'.tr,
          value: _propertyPrice,
          min: 100000,
          max: 5000000,
          divisions: 490,
          display: _fmtMoney(_propertyPrice),
          color: accent,
          textColor: textColor,
          onChanged: (v) => setState(() => _propertyPrice = v),
        ),
        const SizedBox(height: 16),
        _SliderRow(
          label: 'down_payment'.tr,
          value: _downPaymentPct,
          min: 10,
          max: 80,
          divisions: 70,
          display: '${_downPaymentPct.toStringAsFixed(0)}%',
          color: accent,
          textColor: textColor,
          onChanged: (v) => setState(() => _downPaymentPct = v),
        ),
        const SizedBox(height: 16),
        _SliderRow(
          label: 'interest_rate'.tr,
          value: _annualRatePct,
          min: 1,
          max: 20,
          divisions: 190,
          display: '${_annualRatePct.toStringAsFixed(2)}%',
          color: accent,
          textColor: textColor,
          onChanged: (v) => setState(() => _annualRatePct = v),
        ),
        const SizedBox(height: 16),
        _SliderRow(
          label: 'loan_term_years'.tr,
          value: _termYears.toDouble(),
          min: 5,
          max: 35,
          divisions: 30,
          display: '$_termYears ${'years'.tr}',
          color: accent,
          textColor: textColor,
          onChanged: (v) => setState(() => _termYears = v.round()),
        ),
      ],
    );
  }

  Widget _buildResults(Color textColor, Color accent) {
    final secondary = textColor.withValues(alpha: 0.6);

    return Column(
      children: [
        _ResultCard(
          label: 'monthly_payment'.tr,
          value: _fmtMoney(_monthlyPayment),
          isHighlighted: true,
          accent: accent,
          textColor: textColor,
        ),
        const SizedBox(height: 10),
        _ResultCard(
          label: 'loan_amount'.tr,
          value: _fmtMoney(_loanAmount),
          textColor: textColor,
          accent: accent,
        ),
        const SizedBox(height: 10),
        _ResultCard(
          label: 'total_interest'.tr,
          value: _fmtMoney(_totalInterest),
          textColor: textColor,
          accent: accent,
        ),
        const SizedBox(height: 10),
        _ResultCard(
          label: 'total_repayment'.tr,
          value: _fmtMoney(_totalPaid),
          textColor: textColor,
          accent: accent,
        ),
        const SizedBox(height: 16),
        // LTV badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _ltvColor().withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LTV', style: TextStyle(fontSize: 12, color: secondary)),
              Text(
                '${_ltv.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _ltvColor(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _ltvHint(),
          style: TextStyle(fontSize: 10, color: secondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _ltvColor() {
    if (_ltv <= 60) return Colors.green;
    if (_ltv <= 80) return Colors.orange;
    return Colors.red;
  }

  String _ltvHint() {
    if (_ltv <= 60) return 'ltv_low_hint'.tr;
    if (_ltv <= 80) return 'ltv_medium_hint'.tr;
    return 'ltv_high_hint'.tr;
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final Color color;
  final Color textColor;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.color,
    required this.textColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.7))),
            Text(display, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            overlayColor: color.withValues(alpha: 0.15),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;
  final Color accent;
  final Color textColor;

  const _ResultCard({
    required this.label,
    required this.value,
    required this.textColor,
    required this.accent,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted ? accent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? accent : textColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlighted ? 13 : 12,
              color: textColor.withValues(alpha: isHighlighted ? 0.9 : 0.65),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 16 : 13,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? accent : textColor,
            ),
          ),
        ],
      ),
    );
  }
}
