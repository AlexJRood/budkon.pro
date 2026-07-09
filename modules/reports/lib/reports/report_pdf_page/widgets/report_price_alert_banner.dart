import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:intl/intl.dart';
import 'package:reports/reports/report_pdf_page/provider/report_value_history_provider.dart';

const _primaryText = Color(0xFF171A1F);
const _border = Color(0xFFE7ECF2);
const _green = Color(0xFF16A34A);
const _red = Color(0xFFEF4444);
const _orange = Color(0xFFF59E0B);

// ── per-report dismiss state (in-memory, resets on restart) ──────────────────

final _dismissedAlertsProvider =
    StateProvider<Set<int>>((ref) => const {});

// ── main widget ──────────────────────────────────────────────────────────────

class ReportPriceAlertBanner extends ConsumerWidget {
  final int reportId;
  final double currentValue;
  final String currency;
  final bool isMobile;

  /// Minimum absolute % change to show an alert.
  static const double _thresholdPct = 0.5;

  const ReportPriceAlertBanner({
    super.key,
    required this.reportId,
    required this.currentValue,
    required this.currency,
    required this.isMobile,
  });

  String _formatMoney(double value, String currency) {
    final fmt = NumberFormat.currency(
      locale: 'pl_PL',
      symbol: '',
      decimalDigits: 0,
    );
    return '${fmt.format(value).trim()} $currency'.trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(_dismissedAlertsProvider);
    if (dismissed.contains(reportId)) return const SizedBox.shrink();

    final historyAsync = ref.watch(reportValueHistoryProvider);

    return historyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (allHistory) {
        final history = allHistory[reportId] ?? [];

        // Find the last entry from a PREVIOUS day
        final today = DateTime.now();
        final todayKey =
            '${today.year}-${today.month}-${today.day}';
        final previousEntry = history.lastWhereOrNull((s) {
          final d = s.recordedAt;
          final k = '${d.year}-${d.month}-${d.day}';
          return k != todayKey;
        });

        if (previousEntry == null) return const SizedBox.shrink();

        final prev = previousEntry.value;
        if (prev <= 0) return const SizedBox.shrink();

        final changePct = ((currentValue - prev) / prev) * 100;
        if (changePct.abs() < _thresholdPct) return const SizedBox.shrink();

        final isUp = changePct > 0;
        final color = isUp ? _green : _red;
        final bgColor = color.withOpacity(0.06);
        final borderColor = color.withOpacity(0.25);
        final icon = isUp
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded;

        final absDiff = currentValue - prev;
        final sign = isUp ? '+' : '';

        return Container(
          margin: EdgeInsets.only(bottom: isMobile ? 16 : 20),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUp
                          ? 'price_alert_up'.tr
                          : 'price_alert_down'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${'price_alert_since'.tr} ${_formatDate(previousEntry.recordedAt)}: '
                      '${_formatMoney(prev, currency)} → '
                      '${_formatMoney(currentValue, currency)} '
                      '($sign${_formatMoney(absDiff.abs(), currency)}, '
                      '$sign${changePct.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: _primaryText.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  ref
                      .read(_dismissedAlertsProvider.notifier)
                      .update((s) => {...s, reportId});
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      size: 16,
                      color: _primaryText.withOpacity(0.35)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'today'.tr;
    if (diff == 1) return 'yesterday'.tr;
    return DateFormat('dd.MM.yyyy').format(dt);
  }
}

extension _ListExt<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}
