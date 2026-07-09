

import 'package:crm/crm/finance/charts/chart_settings.dart';
import 'package:crm/crm/finance/charts/remote_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';









/// Helper: basic presets + szybka edycja (range / groupBy / metric)
Future<void> showFinanceChartPresetsSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final theme = ref.read(themeColorsProvider);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return ProviderScope(
            parent: ProviderScope.containerOf(context),
            child: FinanceChartPresetsSheet(
              scrollController: scrollController,
              theme: theme,
            ),
          );
        },
      );
    },
  );
}

class FinanceChartPresetsSheet extends ConsumerWidget {
  final ScrollController scrollController;
  final ThemeColors theme;

  const FinanceChartPresetsSheet({
    super.key,
    required this.scrollController,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(financeChartDataConfigProvider);
    final cfgNotifier =
        ref.read(financeChartDataConfigProvider.notifier);
    final settings = ref.watch(financeChartSettingsProvider);
    final settingsNotifier =
        ref.read(financeChartSettingsProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildHandle(theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildHeader(context),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildSectionTitle('chart_presets_title'.tr),
                const SizedBox(height: 8),
                _presetTile(
                  context: context,
                  title: 'cashflow_7_days_preset'.tr,
                  subtitle:
                      'cashflow_7_days_subtitle'.tr,
                  onTap: () {
                    final now = DateTime.now();
                    final from = now.subtract(const Duration(days: 6));
                    cfgNotifier
                      ..setDateRange(from, now)
                      ..setGroupBy(FinanceRemoteGroupBy.day)
                      ..setMetric(FinanceRemoteMetric.sumTotalAmount)
                      ..setSeries(const [
                        FinanceChartSeriesConfig(
                          name: 'Przychody opłacone',
                          kind: 'revenue',
                          isPaid: true,
                          visible: true,
                        ),
                        FinanceChartSeriesConfig(
                          name: 'Wydatki opłacone',
                          kind: 'expense',
                          isPaid: true,
                          visible: true,
                        ),
                      ]);
                    settingsNotifier.updateChartType(FinanceChartType.line);
                    Navigator.of(context).maybePop();
                  },
                ),
                _presetTile(
                  context: context,
                  title: 'cashflow_30_days_full_preset'.tr,
                  subtitle:
                      'cashflow_30_days_full_subtitle'.tr,
                  onTap: () {
                    final now = DateTime.now();
                    final from = now.subtract(const Duration(days: 29));
                    cfgNotifier
                      ..setDateRange(from, now)
                      ..setGroupBy(FinanceRemoteGroupBy.day)
                      ..setMetric(FinanceRemoteMetric.sumTotalAmount)
                      ..setSeries([
                        FinanceChartSeriesConfig(
                          name: 'Przychody opłacone',
                          kind: 'revenue',
                          isPaid: true,
                          visible: true,
                        ),
                        FinanceChartSeriesConfig(
                          name: 'Wydatki opłacone'.tr,
                          kind: 'expense',
                          isPaid: true,
                          visible: true,
                        ),
                        FinanceChartSeriesConfig(
                          name:'Przychody nieopłacone'.tr,
                          kind: 'revenue',
                          isPaid: false,
                          visible: true,
                        ),
                        FinanceChartSeriesConfig(
                          name:'Wydatki nieopłacone'.tr,
                          kind: 'expense',
                          isPaid: false,
                          visible: true,
                        ),
                      ]);
                    settingsNotifier.updateChartType(FinanceChartType.line);
                    Navigator.of(context).maybePop();
                  },
                ),
                _presetTile(
                  context: context,
                  title: 'yearly_revenue_vs_expenses_preset'.tr,
                  subtitle:'yearly_revenue_vs_expenses_subtitle'.tr,
                  onTap: () {
                    final now = DateTime.now();
                    final from = DateTime(now.year - 1, now.month, 1);
                    cfgNotifier
                      ..setDateRange(from, now)
                      ..setGroupBy(FinanceRemoteGroupBy.month)
                      ..setMetric(FinanceRemoteMetric.sumTotalAmount)
                      ..setSeries([
                        FinanceChartSeriesConfig(
                          name: 'Przychody (wszystkie)'.tr,
                          kind: 'revenue',
                          visible: true,
                        ),
                        FinanceChartSeriesConfig(
                          name: 'Wydatki (wszystkie)'.tr,
                          kind: 'expense',
                          visible: true,
                        ),
                      ]);
                    settingsNotifier.updateChartType(FinanceChartType.bar);
                    Navigator.of(context).maybePop();
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionTitle('quick_edit_basic_title'.tr),
                const SizedBox(height: 8),

                // Range quick chips
                Text(
                  'time_range_label'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textColor.withAlpha(204),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip(
                      selected:
                          _isRange(cfg, days: 7),
                      label: '7_days_label'.tr,
                      onTap: () {
                        final now = DateTime.now();
                        final from =
                            now.subtract(const Duration(days: 6));
                        cfgNotifier.setDateRange(from, now);
                      },
                    ),
                    _chip(
                      selected:
                          _isRange(cfg, days: 30),
                      label: '30_days_label'.tr,
                      onTap: () {
                        final now = DateTime.now();
                        final from =
                            now.subtract(const Duration(days: 29));
                        cfgNotifier.setDateRange(from, now);
                      },
                    ),
                    _chip(
                      selected:
                          _isRange(cfg, days: 365),
                      label: '365_days_label'.tr,
                      onTap: () {
                        final now = DateTime.now();
                        final from =
                            now.subtract(const Duration(days: 364));
                        cfgNotifier.setDateRange(from, now);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  'grouping_label'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textColor.withAlpha(204),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip(
                      selected: cfg.groupBy == FinanceRemoteGroupBy.day,
                      label: 'day_label'.tr,
                      onTap: () =>
                          cfgNotifier.setGroupBy(FinanceRemoteGroupBy.day),
                    ),
                    _chip(
                      selected: cfg.groupBy == FinanceRemoteGroupBy.week,
                      label: 'week_label'.tr,
                      onTap: () =>
                          cfgNotifier.setGroupBy(FinanceRemoteGroupBy.week),
                    ),
                    _chip(
                      selected: cfg.groupBy == FinanceRemoteGroupBy.month,
                      label: 'month_label'.tr,
                      onTap: () =>
                          cfgNotifier.setGroupBy(FinanceRemoteGroupBy.month),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  'metric_label'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textColor.withAlpha(204),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip(
                      selected: cfg.metric ==
                          FinanceRemoteMetric.sumTotalAmount,
                      label: 'sum_amount_label'.tr,
                      onTap: () => cfgNotifier
                          .setMetric(FinanceRemoteMetric.sumTotalAmount),
                    ),
                    _chip(
                      selected: cfg.metric == FinanceRemoteMetric.count,
                      label: 'transaction_count_label'.tr,
                      onTap: () => cfgNotifier
                          .setMetric(FinanceRemoteMetric.count),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _buildSectionTitle('chart_type_label'.tr),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip(
                      selected: settings.chartType ==
                          FinanceChartType.line,
                      label: 'line_chart_label'.tr,
                      onTap: () => settingsNotifier
                          .updateChartType(FinanceChartType.line),
                    ),
                    _chip(
                      selected: settings.chartType ==
                          FinanceChartType.bar,
                      label: 'bar_chart_label'.tr,
                      onTap: () => settingsNotifier
                          .updateChartType(FinanceChartType.bar),
                    ),
                    _chip(
                      selected: settings.chartType ==
                          FinanceChartType.pie,
                      label: 'pie_chart_label'.tr,
                      onTap: () => settingsNotifier
                          .updateChartType(FinanceChartType.pie),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(ThemeColors theme) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.textColor.withAlpha(64),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          'chart_presets_header'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.close,
            color: theme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.textColor.withAlpha(204),
      ),
    );
  }

  Widget _presetTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: theme.adPopBackground,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.textColor.withAlpha(26)),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: theme.textColor.withAlpha(178),
            fontSize: 11,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.textColor.withAlpha(178),
        ),
      ),
    );
  }

  bool _isRange(FinanceChartDataConfig cfg, {required int days}) {
    if (cfg.dateFrom == null || cfg.dateTo == null) return false;
    final diff = cfg.dateTo!.difference(cfg.dateFrom!).inDays + 1;
    return diff == days;
  }

  Widget _chip({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.themeColor.withAlpha(51),
      labelStyle: TextStyle(
        color: selected ? theme.themeColor : theme.textColor,
        fontSize: 12,
      ),
      backgroundColor: theme.textFieldColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
