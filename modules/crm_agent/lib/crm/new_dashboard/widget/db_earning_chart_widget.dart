import 'package:crm/crm/finance/charts/chart_settings.dart';
import 'package:crm/crm/finance/charts/remote_data.dart';
import 'package:crm/crm/finance/charts/render.dart';
import 'package:crm_agent/crm/new_dashboard/widget/earning_chart_settings_provider.dart';
import 'package:crm_agent/crm/new_dashboard/widget/earning_chart_settings_sheet.dart';
import 'package:crm_agent/crm/providers/transaction_type_summary_provider.dart';
import 'package:crm_fliper/finance/widget/finance_custom_tap_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class DbEarningChartWidget extends ConsumerStatefulWidget {
  const DbEarningChartWidget({super.key});

  @override
  ConsumerState<DbEarningChartWidget> createState() =>
      _DbEarningChartWidgetState();
}

class _DbEarningChartWidgetState extends ConsumerState<DbEarningChartWidget> {
  late final PageController _pageController;
  bool _isHoveringSection = false;

  @override
  void initState() {
    super.initState();
    final initialPage = ref.read(currentPageProvider);
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePieTouch(FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
    if (event is FlPointerHoverEvent) {
      final hovering =
          pieTouchResponse?.touchedSection?.touchedSectionIndex != null;
      if (hovering != _isHoveringSection) {
        setState(() => _isHoveringSection = hovering);
      }
      return;
    }
    if (event is FlPointerExitEvent) {
      if (_isHoveringSection) setState(() => _isHoveringSection = false);
      return;
    }

    if (event is! FlTapUpEvent) return;
    final touched = pieTouchResponse?.touchedSection;
    if (touched == null) return;

    final i = touched.touchedSectionIndex;
    if (i == 0) {
      ref.read(navigationService).pushNamedScreen(Routes.proDraggable);
      ref.read(financeTabIndexProvider.notifier).state = 1;
    } else {
      ref.read(navigationService).pushNamedScreen(Routes.proDraggable);
      ref.read(financeTabIndexProvider.notifier).state = 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final settings = ref.watch(dashboardEarningChartSettingsProvider);
    final showBg = ref.watch(earningChartShowBackgroundProvider);
    final isPie = settings.chartType == FinanceChartType.pie;

    return Container(
      height: 420,
      width: double.infinity,
      decoration: showBg
          ? BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dashboardBoarder),
            )
          : const BoxDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(context, theme, settings, isPie),
          const SizedBox(height: 10),
          Expanded(
            child: isPie ? _PieChartArea(onPieTouch: _handlePieTouch) : _LineBarChartArea(settings: settings),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeColors theme,
    FinanceChartSettings settings,
    bool isPie,
  ) {
    return Row(
      children: [
        Text(
          'Earnings'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        _ProBadge(),
        const Spacer(),
        if (isPie) _PieRangeDropdown(settings: settings),
        IconButton(
          onPressed: () => showEarningChartSettings(context),
          icon: Icon(Icons.tune_rounded, color: theme.textColor, size: 20),
          tooltip: 'Chart settings'.tr,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

// ── Pie chart area (existing logic) ──────────────────────────────────────────

class _PieChartArea extends ConsumerStatefulWidget {
  final void Function(FlTouchEvent, PieTouchResponse?) onPieTouch;
  const _PieChartArea({required this.onPieTouch});

  @override
  ConsumerState<_PieChartArea> createState() => _PieChartAreaState();
}

class _PieChartAreaState extends ConsumerState<_PieChartArea> {
  late final PageController _pageController;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ref.read(currentPageProvider));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final chartData = ref.watch(chartDataProvider);
    final summary = ref.watch(transactionTypeSummaryProvider);
    final currentPage = ref.watch(currentPageProvider);

    final hasPages = chartData.isNotEmpty;
    final safePage = hasPages ? currentPage.clamp(0, chartData.length - 1) : 0;
    final sections = hasPages ? chartData[safePage] : const <PieChartSectionData>[];

    return summary.when(
      loading: () => Center(child: AppLottie.loading(size: 300)),
      error: (err, _) => Center(child: Text('${'Error'.tr}: $err')),
      data: (data) {
        if ((data.expenses.isEmpty && data.revenues.isEmpty) || !hasPages) {
          return AppLottie.noResults(size: 300);
        }

        return Column(
          children: [
            Expanded(
              flex: 2,
              child: MouseRegion(
                cursor: _isHovering
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: chartData.isEmpty ? 1 : chartData.length,
                  onPageChanged: (index) {
                    if (chartData.isEmpty) return;
                    ref.read(currentPageProvider.notifier).state = index;
                  },
                  itemBuilder: (context, index) {
                    if (chartData.isEmpty) {
                      return Center(child: AppLottie.noResults(size: 200));
                    }
                    return PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: chartData[index],
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            if (event is FlPointerHoverEvent) {
                              final h = response?.touchedSection?.touchedSectionIndex != null;
                              if (h != _isHovering) setState(() => _isHovering = h);
                            }
                            if (event is FlPointerExitEvent) {
                              if (_isHovering) setState(() => _isHovering = false);
                            }
                            widget.onPieTouch(event, response);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sections.isNotEmpty)
                  LegendItem(
                    color: sections[0].color,
                    text: 'Revenue'.tr,
                    textColor: theme.textColor,
                  ),
                if (sections.length >= 2) ...[
                  const SizedBox(height: 6),
                  LegendItem(
                    color: sections[1].color,
                    text: 'Expenses'.tr,
                    textColor: theme.textColor,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                chartData.length,
                (index) => GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: PageIndicator(isActive: safePage == index),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Line / Bar chart area ─────────────────────────────────────────────────────

class _LineBarChartArea extends ConsumerWidget {
  final FinanceChartSettings settings;
  const _LineBarChartArea({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final remote = ref.watch(dashboardEarningChartRemoteProvider);

    // Build a FinanceChartDataConfig that mirrors the current settings
    // so buildFinanceChartWidget knows about series visibility/colors.
    final cfg = _buildConfig(settings);

    return remote.when(
      loading: () => Center(child: AppLottie.loading(size: 200)),
      error: (err, _) => Center(
        child: Text('${'Error'.tr}: $err',
            style: TextStyle(color: theme.textColor)),
      ),
      data: (response) => buildFinanceChartWidget(
        context: context,
        theme: theme,
        settings: settings,
        remote: response,
        config: cfg,
      ),
    );
  }

  FinanceChartDataConfig _buildConfig(FinanceChartSettings s) {
    final now = DateTime.now();
    final DateTime from;
    switch (s.range) {
      case FinanceChartRange.week:
        from = now.subtract(const Duration(days: 6));
      case FinanceChartRange.month:
        from = DateTime(now.year, now.month, 1);
      case FinanceChartRange.year:
        from = DateTime(now.year, 1, 1);
    }

    final series = <FinanceChartSeriesConfig>[
      if (s.showRevenuePaid)
        FinanceChartSeriesConfig(
          name: 'paid_revenues_label'.tr,
          kind: 'revenue',
          isPaid: true,
          visible: true,
          colorHex: _hexFromColor(s.revenuePaidColor),
        ),
      if (s.showRevenueUnpaid)
        FinanceChartSeriesConfig(
          name: 'unpaid_revenues_label'.tr,
          kind: 'revenue',
          isPaid: false,
          visible: true,
          colorHex: _hexFromColor(s.revenueUnpaidColor),
        ),
      if (s.showExpensePaid)
        FinanceChartSeriesConfig(
          name: 'paid_expenses_label'.tr,
          kind: 'expense',
          isPaid: true,
          visible: true,
          colorHex: _hexFromColor(s.expensePaidColor),
        ),
      if (s.showExpenseUnpaid)
        FinanceChartSeriesConfig(
          name: 'unpaid_expenses_label'.tr,
          kind: 'expense',
          isPaid: false,
          visible: true,
          colorHex: _hexFromColor(s.expenseUnpaidColor),
        ),
    ];

    return FinanceChartDataConfig(
      dateFrom: from,
      dateTo: now,
      groupBy: switch (s.groupBy) {
        FinanceChartGroupBy.day => FinanceRemoteGroupBy.day,
        FinanceChartGroupBy.week => FinanceRemoteGroupBy.week,
        FinanceChartGroupBy.month => FinanceRemoteGroupBy.month,
      },
      metric: switch (s.metric) {
        FinanceChartMetric.sumAmount => FinanceRemoteMetric.sumTotalAmount,
        FinanceChartMetric.countTransactions => FinanceRemoteMetric.count,
      },
      series: series,
    );
  }

  String _hexFromColor(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
}

// ── Pie range dropdown (inline, lightweight) ──────────────────────────────────

class _PieRangeDropdown extends ConsumerWidget {
  final FinanceChartSettings settings;
  const _PieRangeDropdown({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final range = ref.watch(selectedRangeProvider);

    return DropdownButton<TimeRange>(
      value: range,
      dropdownColor: theme.adPopBackground,
      underline: const SizedBox.shrink(),
      style: TextStyle(color: theme.textColor, fontSize: 13),
      icon: Icon(Icons.keyboard_arrow_down, color: theme.textColor, size: 18),
      items: [
        DropdownMenuItem(
          value: TimeRange.thisMonth,
          child: Text('This month'.tr),
        ),
        DropdownMenuItem(
          value: TimeRange.lastMonth,
          child: Text('Last month'.tr),
        ),
        DropdownMenuItem(
          value: TimeRange.thisYear,
          child: Text('This year'.tr),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        ref.read(selectedRangeProvider.notifier).state = value;
        ref
            .read(transactionTypeSummaryProvider.notifier)
            .fetchTransactionTypeSummary();
      },
    );
  }
}

// ── PRO badge ─────────────────────────────────────────────────────────────────

class _ProBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  final Color textColor;

  const LegendItem({
    super.key,
    required this.color,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: textColor, fontSize: 12)),
      ],
    );
  }
}

class PageIndicator extends StatelessWidget {
  final bool isActive;
  const PageIndicator({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? 8 : 6,
      height: isActive ? 8 : 6,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
