import 'package:crm/crm/finance/charts/chart_settings.dart';
import 'package:crm_agent/crm/new_dashboard/widget/earning_chart_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';

void showEarningChartSettings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _EarningChartSettingsSheet(),
  );
}

class _EarningChartSettingsSheet extends ConsumerWidget {
  const _EarningChartSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final settings = ref.watch(dashboardEarningChartSettingsProvider);
    final notifier = ref.read(dashboardEarningChartSettingsProvider.notifier);
    final showBg = ref.watch(earningChartShowBackgroundProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _SheetHandle(theme: theme),
              _SheetHeader(theme: theme),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    // ── DISPLAY ──────────────────────────────────────────
                    _SectionLabel(label: 'Display'.tr, theme: theme),
                    _SettingRow(
                      label: 'Background'.tr,
                      theme: theme,
                      trailing: Switch(
                        value: showBg,
                        activeColor: theme.themeColor,
                        onChanged: (v) => ref
                            .read(earningChartShowBackgroundProvider.notifier)
                            .set(v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SegmentedRow<FinanceChartType>(
                      label: 'Chart type'.tr,
                      theme: theme,
                      value: settings.chartType,
                      options: const [
                        (FinanceChartType.pie, 'Pie'),
                        (FinanceChartType.line, 'Line'),
                        (FinanceChartType.bar, 'Bar'),
                      ],
                      onChanged: notifier.updateChartType,
                    ),

                    // ── DATA (only for line / bar) ────────────────────────
                    if (settings.chartType != FinanceChartType.pie) ...[
                      _SectionLabel(label: 'Data'.tr, theme: theme),
                      _SegmentedRow<FinanceChartRange>(
                        label: 'Range'.tr,
                        theme: theme,
                        value: settings.range,
                        options: const [
                          (FinanceChartRange.week, 'Week'),
                          (FinanceChartRange.month, 'Month'),
                          (FinanceChartRange.year, 'Year'),
                        ],
                        onChanged: notifier.updateRange,
                      ),
                      const SizedBox(height: 10),
                      _SegmentedRow<FinanceChartGroupBy>(
                        label: 'Group by'.tr,
                        theme: theme,
                        value: settings.groupBy,
                        options: const [
                          (FinanceChartGroupBy.day, 'Day'),
                          (FinanceChartGroupBy.week, 'Week'),
                          (FinanceChartGroupBy.month, 'Month'),
                        ],
                        onChanged: notifier.updateGroupBy,
                      ),
                      const SizedBox(height: 10),
                      _SegmentedRow<FinanceChartMetric>(
                        label: 'Metric'.tr,
                        theme: theme,
                        value: settings.metric,
                        options: const [
                          (FinanceChartMetric.sumAmount, 'Amount'),
                          (FinanceChartMetric.countTransactions, 'Count'),
                        ],
                        onChanged: notifier.updateMetric,
                      ),
                    ],

                    // ── SERIES ────────────────────────────────────────────
                    if (settings.chartType != FinanceChartType.pie) ...[
                      _SectionLabel(label: 'Series'.tr, theme: theme),
                      _SeriesRow(
                        label: 'Revenue (paid)'.tr,
                        color: settings.revenuePaidColor,
                        value: settings.showRevenuePaid,
                        theme: theme,
                        onChanged: (_) => notifier.toggleRevenuePaid(),
                      ),
                      _SeriesRow(
                        label: 'Revenue (unpaid)'.tr,
                        color: settings.revenueUnpaidColor,
                        value: settings.showRevenueUnpaid,
                        theme: theme,
                        onChanged: (_) => notifier.toggleRevenueUnpaid(),
                      ),
                      _SeriesRow(
                        label: 'Expenses (paid)'.tr,
                        color: settings.expensePaidColor,
                        value: settings.showExpensePaid,
                        theme: theme,
                        onChanged: (_) => notifier.toggleExpensePaid(),
                      ),
                      _SeriesRow(
                        label: 'Expenses (unpaid)'.tr,
                        color: settings.expenseUnpaidColor,
                        value: settings.showExpenseUnpaid,
                        theme: theme,
                        onChanged: (_) => notifier.toggleExpenseUnpaid(),
                      ),
                    ],

                    // ── LINE OPTIONS ──────────────────────────────────────
                    if (settings.chartType == FinanceChartType.line) ...[
                      _SectionLabel(label: 'Line options'.tr, theme: theme),
                      _SettingRow(
                        label: 'Smooth lines'.tr,
                        theme: theme,
                        trailing: Switch(
                          value: settings.smoothLines,
                          activeColor: theme.themeColor,
                          onChanged: (_) => notifier.toggleSmoothLines(),
                        ),
                      ),
                      _SettingRow(
                        label: 'Show dots'.tr,
                        theme: theme,
                        trailing: Switch(
                          value: settings.showDots,
                          activeColor: theme.themeColor,
                          onChanged: (_) => notifier.toggleShowDots(),
                        ),
                      ),
                    ],

                    // ── PIE RANGE ─────────────────────────────────────────
                    if (settings.chartType == FinanceChartType.pie) ...[
                      _SectionLabel(label: 'Time range'.tr, theme: theme),
                      _SegmentedRow<FinanceChartRange>(
                        label: 'Range'.tr,
                        theme: theme,
                        value: settings.range,
                        options: const [
                          (FinanceChartRange.week, 'Week'),
                          (FinanceChartRange.month, 'Month'),
                          (FinanceChartRange.year, 'Year'),
                        ],
                        onChanged: notifier.updateRange,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Internal helpers ──────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  final ThemeColors theme;
  const _SheetHandle({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.textColor.withAlpha(60),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final ThemeColors theme;
  const _SheetHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Text(
            'Chart settings'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          _ProBadge(),
        ],
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B61FF), Color(0xFFAA8EFF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final ThemeColors theme;
  const _SectionLabel({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: theme.textColor.withAlpha(120),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final ThemeColors theme;
  const _SettingRow({
    required this.label,
    required this.trailing,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textColor, fontSize: 14)),
          trailing,
        ],
      ),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final ThemeColors theme;

  const _SegmentedRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: theme.textColor, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: options.map((opt) {
              final (optValue, optLabel) = opt;
              final isSelected = value == optValue;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(optValue),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.themeColor
                          : theme.dashboardContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.themeColor
                            : theme.dashboardBoarder,
                      ),
                    ),
                    child: Text(
                      optLabel.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.textColor.withAlpha(160),
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SeriesRow extends StatelessWidget {
  final String label;
  final Color color;
  final bool value;
  final ThemeColors theme;
  final ValueChanged<bool> onChanged;

  const _SeriesRow({
    required this.label,
    required this.color,
    required this.value,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: theme.textColor, fontSize: 14),
              ),
            ),
            Switch(
              value: value,
              activeColor: theme.themeColor,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
