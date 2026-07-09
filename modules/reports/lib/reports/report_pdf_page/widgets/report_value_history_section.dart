import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:intl/intl.dart';
import 'package:reports/reports/report_pdf_page/provider/report_value_history_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

const _primaryText = Color(0xFF171A1F);
const _secondaryText = Color(0xFF667085);
const _lightText = Color(0xFF98A2B3);
const _accent = Color(0xFF5FCDD9);
const _accentStrong = Color(0xFF2FB8C6);
const _background = Color(0xFFF6F7F9);
const _card = Colors.white;
const _border = Color(0xFFE7ECF2);
const _green = Color(0xFF16A34A);
const _red = Color(0xFFEF4444);

class ReportValueHistorySection extends ConsumerStatefulWidget {
  final int reportId;
  final double currentValue;
  final String currency;
  final bool isMobile;

  const ReportValueHistorySection({
    super.key,
    required this.reportId,
    required this.currentValue,
    required this.currency,
    required this.isMobile,
  });

  @override
  ConsumerState<ReportValueHistorySection> createState() =>
      _ReportValueHistorySectionState();
}

class _ReportValueHistorySectionState
    extends ConsumerState<ReportValueHistorySection> {
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _record());
  }

  void _record() {
    if (_recorded) return;
    _recorded = true;
    ref.read(reportValueHistoryProvider.notifier).recordSnapshot(
          widget.reportId,
          widget.currentValue,
          widget.currency,
        );
  }

  String _formatMoney(double value, String currency) {
    final fmt = NumberFormat.currency(
      locale: 'pl_PL',
      symbol: '',
      decimalDigits: 0,
    );
    return '${fmt.format(value).trim()} $currency'.trim();
  }

  String _formatDate(DateTime dt) =>
      DateFormat('dd.MM.yy').format(dt);

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(reportValueHistoryProvider);

    return historyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (allHistory) {
        final history = allHistory[widget.reportId] ?? [];

        return Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(history),
              if (history.length >= 2) ...[
                const SizedBox(height: 20),
                _buildChart(history),
                const SizedBox(height: 12),
                _buildTable(history),
              ] else ...[
                const SizedBox(height: 16),
                _buildFirstVisitNote(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(List<ValueSnapshot> history) {
    double? change;
    bool positive = true;
    if (history.length >= 2) {
      final first = history.first.value;
      final last = history.last.value;
      change = ((last - first) / first) * 100;
      positive = change >= 0;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.trending_up_rounded,
              size: 20, color: _accentStrong),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'estimate_history'.tr,
                style: TextStyle(
                  fontSize: widget.isMobile ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                ),
              ),
              Text(
                'estimate_history_subtitle'.tr,
                style: const TextStyle(fontSize: 12, color: _secondaryText),
              ),
            ],
          ),
        ),
        if (change != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (positive ? _green : _red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (positive ? _green : _red).withOpacity(0.3),
              ),
            ),
            child: Text(
              '${positive ? '+' : ''}${change.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: positive ? _green : _red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChart(List<ValueSnapshot> history) {
    final entries = history.asMap().entries.toList();
    final values = history.map((s) => s.value).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxVal - minVal) * 0.15 + 1;

    final isUp = history.last.value >= history.first.value;
    final lineColor = isUp ? _green : _red;

    return SizedBox(
      height: 140,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        primaryXAxis: CategoryAxis(
          isVisible: false,
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
        ),
        primaryYAxis: NumericAxis(
          isVisible: false,
          minimum: minVal - padding,
          maximum: maxVal + padding,
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          builder: (data, point, series, pointIndex, seriesIndex) {
            final snap = history[pointIndex];
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryText,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatMoney(snap.value, snap.currency),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _formatDate(snap.recordedAt),
                    style: const TextStyle(
                        color: _lightText, fontSize: 11),
                  ),
                ],
              ),
            );
          },
        ),
        series: <CartesianSeries>[
          AreaSeries<MapEntry<int, ValueSnapshot>, String>(
            dataSource: entries,
            xValueMapper: (e, _) => e.key.toString(),
            yValueMapper: (e, _) => e.value.value,
            color: lineColor.withOpacity(0.08),
            borderColor: lineColor,
            borderWidth: 2.5,
            markerSettings: MarkerSettings(
              isVisible: true,
              height: 6,
              width: 6,
              borderColor: lineColor,
              color: Colors.white,
              borderWidth: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<ValueSnapshot> history) {
    // Show at most the last 5 entries
    final shown = history.length > 5
        ? history.sublist(history.length - 5)
        : history;

    return Container(
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: shown.asMap().entries.map((e) {
          final i = e.key;
          final snap = e.value;
          final prev = i > 0 ? shown[i - 1].value : null;
          double? delta;
          bool up = true;
          if (prev != null) {
            delta = ((snap.value - prev) / prev) * 100;
            up = delta >= 0;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: i > 0
                  ? const Border(top: BorderSide(color: _border))
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(snap.recordedAt),
                    style: const TextStyle(
                        fontSize: 12, color: _secondaryText),
                  ),
                ),
                Text(
                  _formatMoney(snap.value, snap.currency),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                  ),
                ),
                if (delta != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${up ? '+' : ''}${delta.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: up ? _green : _red,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFirstVisitNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: _lightText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'estimate_history_first_visit'.tr,
              style: const TextStyle(fontSize: 13, color: _secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}
