// lib/crm/finance/charts/sheet.dart

import 'package:crm/crm/finance/charts/chart_settings.dart';
import 'package:crm/crm/finance/charts/remote_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

/// Przykładowe opcje – możesz podmienić na dane z API / providerów.
const kSuggestedTransactionTypes = <String>[
  'subscription',
  'commission',
  'sale',
  'rent',
];

const kSuggestedPaymentMethods = <String>[
  'card',
  'transfer',
  'cash',
  'stripe',
];

/// Helper to open the draggable scrollable sheet.
/// Use from anywhere you have BuildContext + WidgetRef.
///
/// Example:
/// await showFinanceChartSettingsSheet(context, ref);
Future<void> showFinanceChartSettingsSheet(
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
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.98,
        expand: false,
        builder: (context, scrollController) {
          return ProviderScope(
            // pass down same Riverpod scope
            parent: ProviderScope.containerOf(context),
            child: FinanceChartSettingsSheet(
              scrollController: scrollController,
              theme: theme,
            ),
          );
        },
      );
    },
  );
}

/// Draggable sheet with full chart settings editor (visual + data_config).
class FinanceChartSettingsSheet extends ConsumerWidget {
  final ScrollController scrollController;
  final ThemeColors theme;

  const FinanceChartSettingsSheet({
    super.key,
    required this.scrollController,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visual = ref.watch(financeChartSettingsProvider);
    final visualNotifier = ref.read(financeChartSettingsProvider.notifier);

    final dataConfig = ref.watch(financeChartDataConfigProvider);
    final dataNotifier = ref.read(financeChartDataConfigProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(64),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildHandle(theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildHeader(context, visualNotifier),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // TIME RANGE
                _buildSectionTitle('time_range_title'.tr),
                _buildRangeChips(visual, visualNotifier, dataNotifier),
                const SizedBox(height: 16),

                // CHART TYPE
                _buildSectionTitle('chart_type_title'.tr),
                _buildChartTypeChips(visual, visualNotifier),
                const SizedBox(height: 16),

                // GROUP BY + METRIC
                _buildSectionTitle('grouping_and_metric_title'.tr),
                _buildGroupByChips(dataConfig, dataNotifier),
                const SizedBox(height: 8),
                _buildMetricChips(dataConfig, dataNotifier),
                const SizedBox(height: 16),

                // GLOBAL FILTERS
                _buildSectionTitle('global_filters_title'.tr),
                _buildGlobalFilters(dataConfig, dataNotifier),
                const SizedBox(height: 16),

                // SERIES CONFIG
                _buildSectionTitle('data_series_title'.tr),
                const SizedBox(height: 8),
                _buildSeriesList(dataConfig, dataNotifier),
                const SizedBox(height: 16),

                // LINES OPTIONS
                _buildSectionTitle('line_options_title'.tr),
                _buildLineOptions(visual, visualNotifier),
                const SizedBox(height: 24),

                _buildBottomButtons(context, visualNotifier),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER / HANDLE
  // ---------------------------------------------------------------------------

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

  Widget _buildHeader(
    BuildContext context,
    FinanceChartSettingsNotifier visualNotifier,
  ) {
    return Row(
      children: [
        Text(
          'chart_settings_pro_title'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            visualNotifier.saveSettingsToBackend();
            Navigator.of(context).maybePop();
          },
          child: Text(
            'save_button'.tr,
            style: TextStyle(
              color: theme.themeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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

  // ---------------------------------------------------------------------------
  // RANGE
  // ---------------------------------------------------------------------------

  Widget _buildRangeChips(
    FinanceChartSettings visual,
    FinanceChartSettingsNotifier visualNotifier,
    FinanceChartDataConfigNotifier dataNotifier,
  ) {
    void _applyRange(FinanceChartRange range) {
      visualNotifier.updateRange(range);
      final now = DateTime.now();
      late DateTime start;
      switch (range) {
        case FinanceChartRange.week:
          start = now.subtract(const Duration(days: 6));
          break;
        case FinanceChartRange.month:
          start = now.subtract(const Duration(days: 29));
          break;
        case FinanceChartRange.year:
          start = now.subtract(const Duration(days: 364));
          break;
      }
      dataNotifier.setDateRange(start, now);
    }

    return Wrap(
      spacing: 8,
      children: [
        _chip(
          selected: visual.range == FinanceChartRange.week,
          label: '7_days_label'.tr,
          onTap: () => _applyRange(FinanceChartRange.week),
        ),
        _chip(
          selected: visual.range == FinanceChartRange.month,
          label: '30_days_label'.tr,
          onTap: () => _applyRange(FinanceChartRange.month),
        ),
        _chip(
          selected: visual.range == FinanceChartRange.year,
          label: '365_days_label'.tr,
          onTap: () => _applyRange(FinanceChartRange.year),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CHART TYPE
  // ---------------------------------------------------------------------------

  Widget _buildChartTypeChips(
    FinanceChartSettings visual,
    FinanceChartSettingsNotifier notifier,
  ) {
    return Wrap(
      spacing: 8,
      children: [
        _chip(
          selected: visual.chartType == FinanceChartType.line,
          label: 'line_chart_label'.tr,
          icon: Icons.show_chart,
          onTap: () => notifier.updateChartType(FinanceChartType.line),
        ),
        _chip(
          selected: visual.chartType == FinanceChartType.bar,
          label: 'bar_chart_label'.tr,
          icon: Icons.bar_chart,
          onTap: () => notifier.updateChartType(FinanceChartType.bar),
        ),
        _chip(
          selected: visual.chartType == FinanceChartType.pie,
          label: 'pie_chart_label'.tr,
          icon: Icons.pie_chart,
          onTap: () => notifier.updateChartType(FinanceChartType.pie),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // GROUP BY / METRIC (DATA CONFIG)
  // ---------------------------------------------------------------------------

  Widget _buildGroupByChips(
    FinanceChartDataConfig config,
    FinanceChartDataConfigNotifier notifier,
  ) {
    return Wrap(
      spacing: 8,
      children: [
        _chip(
          selected: config.groupBy == FinanceRemoteGroupBy.day,
          label: 'day_label'.tr,
          onTap: () => notifier.setGroupBy(FinanceRemoteGroupBy.day),
        ),
        _chip(
          selected: config.groupBy == FinanceRemoteGroupBy.week,
          label: 'week_label'.tr,
          onTap: () => notifier.setGroupBy(FinanceRemoteGroupBy.week),
        ),
        _chip(
          selected: config.groupBy == FinanceRemoteGroupBy.month,
          label: 'month_label'.tr,
          onTap: () => notifier.setGroupBy(FinanceRemoteGroupBy.month),
        ),
      ],
    );
  }

  Widget _buildMetricChips(
    FinanceChartDataConfig config,
    FinanceChartDataConfigNotifier notifier,
  ) {
    return Wrap(
      spacing: 8,
      children: [
        _chip(
          selected: config.metric == FinanceRemoteMetric.sumTotalAmount,
          label: 'sum_amount_label'.tr,
          onTap: () =>
              notifier.setMetric(FinanceRemoteMetric.sumTotalAmount),
        ),
        _chip(
          selected: config.metric == FinanceRemoteMetric.count,
          label: 'transaction_count_label'.tr,
          onTap: () => notifier.setMetric(FinanceRemoteMetric.count),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // GLOBAL FILTERS (company_id etc.)
  // ---------------------------------------------------------------------------

  Widget _buildGlobalFilters(
    FinanceChartDataConfig config,
    FinanceChartDataConfigNotifier notifier,
  ) {
    final companyController = TextEditingController(
      text: config.companyId?.toString() ?? '',
    );

    return Row(
      children: [
        Expanded(
          child: CoreTextField(
            label: 'company_id_optional_label'.tr,
            hintText: 'all_companies_hint'.tr,
            controller: companyController,
            keyboardType: TextInputType.number,
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isEmpty) {
                notifier.setCompanyId(null);
                return;
              }
              final parsed = int.tryParse(trimmed);
              notifier.setCompanyId(parsed);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'clear_company_filter_tooltip'.tr,
          onPressed: () {
            notifier.setCompanyId(null);
          },
          icon: Icon(Icons.clear, color: theme.textColor),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SERIES LIST (DATA CONFIG)
  // ---------------------------------------------------------------------------

  Widget _buildSeriesList(
    FinanceChartDataConfig config,
    FinanceChartDataConfigNotifier notifier,
  ) {
    final series = config.series;

    return Column(
      children: [
        if (series.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.textFieldColor.withAlpha(153),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: theme.textColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'no_series_defined_message'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (series.isNotEmpty) ...[
          for (int i = 0; i < series.length; i++) ...[
            _buildSeriesCard(
              index: i,
              config: series[i],
              onChanged: (updated) => notifier.updateSeries(i, updated),
              onRemove: () => notifier.removeSeries(i),
            ),
            const SizedBox(height: 12),
          ]
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              notifier.addSeries(
                const FinanceChartSeriesConfig(
                  name: 'Nowa seria',
                  kind: 'revenue',
                  isPaid: null,
                  tags: [],
                  // UWAGA: tutaj możesz dodać pola: visible/colorHex/factor/invert
                ),
              );
            },
            icon: Icon(Icons.add, color: theme.themeColor),
            label: Text(
              'add_series_button'.tr,
              style: TextStyle(
                color: theme.themeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeriesCard({
    required int index,
    required FinanceChartSeriesConfig config,
    required ValueChanged<FinanceChartSeriesConfig> onChanged,
    required VoidCallback onRemove,
  }) {
    // nazwa
    final nameController = TextEditingController(text: config.name);

    // transaction_type
    final txTypeController = TextEditingController(
      text: config.transactionType ?? '',
    );

    // payment_methods
    final payMethodController = TextEditingController(
      text: config.paymentMethods ?? '',
    );

    // tags
    final tagsController = TextEditingController(
      text: config.tags.join(', '),
    );

    // prosta matma – na razie zakładamy, że w FinanceChartSeriesConfig
    // dodasz pola: double? factor, bool invert, i użyjesz ich w render.dart.
    // Tutaj pokażemy tylko dropdown na UI.
    final mathPreset = _detectMathPreset(config);

    FinanceChartSeriesConfig update({
      String? name,
      String? kind,
      bool? isPaid,
      bool clearIsPayed = false,
      String? transactionType,
      bool clearTransactionType = false,
      String? paymentMethods,
      bool clearPaymentMethods = false,
      List<String>? tags,
      // poniższe pola muszą istnieć w FinanceChartSeriesConfig,
      // jeśli je dodasz (factor, invert, visible, colorHex).
      bool? visible,
      double? factor,
      bool clearFactor = false,
      bool? invert,
    }) {
      return config.copyWith(
        name: name,
        kind: kind,
        isPaid: isPaid,
        clearIsPayed: clearIsPayed,
        transactionType: transactionType,
        clearTransactionType: clearTransactionType,
        paymentMethods: paymentMethods,
        clearPaymentMethods: clearPaymentMethods,
        tags: tags,
        visible: visible,
        factor: clearFactor ? null : factor,
        invert: invert,
      );
    }

    void applyMathPreset(_FinanceMathPreset preset) {
      switch (preset) {
        case _FinanceMathPreset.none:
          onChanged(update(clearFactor: true, invert: false));
          break;
        case _FinanceMathPreset.negate:
          onChanged(update(factor: 1.0, invert: true));
          break;
        case _FinanceMathPreset.timesThousand:
          onChanged(update(factor: 1000.0, invert: false));
          break;
        case _FinanceMathPreset.divideThousand:
          onChanged(update(factor: 0.001, invert: false));
          break;
      }
    }

    Widget buildIsPayedChips() {
      final selected = config.isPaid;

      return Wrap(
        spacing: 6,
        children: [
          ChoiceChip(
            label: Text('all_label'.tr),
            selected: selected == null,
            onSelected: (_) =>
                onChanged(update(isPaid: null, clearIsPayed: true)),
            selectedColor: theme.themeColor.withAlpha(51),
            labelStyle: TextStyle(
              color: selected == null ? theme.themeColor : theme.textColor,
              fontSize: 11,
            ),
            backgroundColor: theme.textFieldColor,
          ),
          ChoiceChip(
            label: Text('paid_label'.tr),
            selected: selected == true,
            onSelected: (_) => onChanged(update(isPaid: true)),
            selectedColor: theme.themeColor.withAlpha(51),
            labelStyle: TextStyle(
              color: selected == true ? theme.themeColor : theme.textColor,
              fontSize: 11,
            ),
            backgroundColor: theme.textFieldColor,
          ),
          ChoiceChip(
            label: Text('unpaid_label'.tr),
            selected: selected == false,
            onSelected: (_) => onChanged(update(isPaid: false)),
            selectedColor: theme.themeColor.withAlpha(51),
            labelStyle: TextStyle(
              color: selected == false ? theme.themeColor : theme.textColor,
              fontSize: 11,
            ),
            backgroundColor: theme.textFieldColor,
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.textFieldColor.withAlpha(153),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.textColor.withAlpha(31),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row (name + delete)
          Row(
            children: [
              Expanded(
                child: CoreTextField(
                  label: 'series_name_label'.tr,
                  controller: nameController,
                  onChanged: (value) => onChanged(
                    update(
                      name: value.trim().isEmpty ? 'Series' : value.trim(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'remove_series_tooltip'.tr,
                icon: Icon(Icons.delete_outline, color: theme.textColor),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Type + (opcjonalnie) widoczność/matema później
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: config.kind,
                  items: [
                    DropdownMenuItem(
                      value: 'revenue',
                      child: Text('revenues_label'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'expense',
                      child: Text('expenses_label'.tr),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == null) return;
                    onChanged(update(kind: val));
                  },
                  decoration: InputDecoration(
                    labelText: 'data_source_label'.tr,
                    labelStyle: TextStyle(color: theme.textColor),
                  ),
                  dropdownColor: theme.dashboardContainer,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              const SizedBox(width: 12),
              // Prosta matma – dropdown presetów
              Expanded(
                child: DropdownButtonFormField<_FinanceMathPreset>(
                  value: mathPreset,
                  items: [
                    DropdownMenuItem(
                      value: _FinanceMathPreset.none,
                      child: Text('no_modification_label'.tr),
                    ),
                    DropdownMenuItem(
                      value: _FinanceMathPreset.negate,
                      child: Text('negate_sign_label'.tr),
                    ),
                    DropdownMenuItem(
                      value: _FinanceMathPreset.timesThousand,
                      child: Text('× 1000'.tr),
                    ),
                    DropdownMenuItem(
                      value: _FinanceMathPreset.divideThousand,
                      child: Text('÷ 1000'.tr),
                    ),
                  ],
                  onChanged: (preset) {
                    if (preset == null) return;
                    applyMathPreset(preset);
                  },
                  decoration: InputDecoration(
                    labelText: 'value_modification_label'.tr,
                    labelStyle: TextStyle(color: theme.textColor),
                  ),
                  dropdownColor: theme.dashboardContainer,
                  style: TextStyle(color: theme.textColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            'payment_status_label'.tr,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.textColor.withAlpha(204),
            ),
          ),
          const SizedBox(height: 4),
          buildIsPayedChips(),
          const SizedBox(height: 12),

          // transaction_type + payment_methods z dropdownami
          Row(
            children: [
              Expanded(
                child: CoreTextField(
                  label: 'transaction_type_label'.tr,
                  controller: txTypeController,
                  onChanged: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty) {
                      onChanged(update(
                        transactionType: null,
                        clearTransactionType: true,
                      ));
                    } else {
                      onChanged(update(transactionType: trimmed));
                    }
                  },
                  suffixIcon: PopupMenuButton<String>(
                    icon: Icon(Icons.arrow_drop_down, color: theme.textColor),
                    onSelected: (val) {
                      txTypeController.text = val;
                      onChanged(update(transactionType: val));
                    },
                    itemBuilder: (ctx) => [
                      for (final opt in kSuggestedTransactionTypes)
                        PopupMenuItem(
                          value: opt,
                          child: Text(opt),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CoreTextField(
                  label: 'payment_methods_label'.tr,
                  controller: payMethodController,
                  onChanged: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty) {
                      onChanged(update(
                        paymentMethods: null,
                        clearPaymentMethods: true,
                      ));
                    } else {
                      onChanged(update(paymentMethods: trimmed));
                    }
                  },
                  suffixIcon: PopupMenuButton<String>(
                    icon: Icon(Icons.arrow_drop_down, color: theme.textColor),
                    onSelected: (val) {
                      payMethodController.text = val;
                      onChanged(update(paymentMethods: val));
                    },
                    itemBuilder: (ctx) => [
                      for (final opt in kSuggestedPaymentMethods)
                        PopupMenuItem(
                          value: opt,
                          child: Text(opt),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // tags jako CoreTextField
          CoreTextField(
            label: 'tags_comma_separated_label'.tr,
            controller: tagsController,
            onChanged: (value) {
              final list = value
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              onChanged(update(tags: list));
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LINE OPTIONS (VISUAL)
  // ---------------------------------------------------------------------------

  Widget _buildLineOptions(
    FinanceChartSettings visual,
    FinanceChartSettingsNotifier notifier,
  ) {
    return Column(
      children: [
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'smooth_lines_label'.tr,
            style: TextStyle(color: theme.textColor),
          ),
          value: visual.smoothLines,
          onChanged: (_) => notifier.toggleSmoothLines(),
        ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'show_dots_label'.tr,
            style: TextStyle(color: theme.textColor),
          ),
          value: visual.showDots,
          onChanged: (_) => notifier.toggleShowDots(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM BUTTONS
  // ---------------------------------------------------------------------------

  Widget _buildBottomButtons(
    BuildContext context,
    FinanceChartSettingsNotifier visualNotifier,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              visualNotifier.applyDashboardPreset();
            },
            child: Text(
              'reset_to_defaults_visual_button'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.themeColor,
              foregroundColor: theme.themeTextColor,
            ),
            onPressed: () async {
              await visualNotifier.saveSettingsToBackend();
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
            child: Text(
              'save_and_close_button'.tr,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  Widget _chip({
    required bool selected,
    required String label,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
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

  _FinanceMathPreset _detectMathPreset(FinanceChartSeriesConfig cfg) {
    // Zakładamy, że w configu (po Twojej stronie) dodasz:
    //  - double? factor
    //  - bool invert
    // Jeżeli jeszcze ich nie ma, ten helper możesz chwilowo podmienić
    // na stałą wartość: return _FinanceMathPreset.none;
    final double? factor = cfg.factor; // wymaga pola w modelu
    final bool invert = cfg.invert ?? false; // wymaga pola w modelu

    if (invert && (factor == null || factor == 1.0)) {
      return _FinanceMathPreset.negate;
    }
    if (!invert && (factor == null || factor == 1.0)) {
      return _FinanceMathPreset.none;
    }
    if (!invert && factor == 1000.0) {
      return _FinanceMathPreset.timesThousand;
    }
    if (!invert && factor == 0.001) {
      return _FinanceMathPreset.divideThousand;
    }
    // fallback
    return _FinanceMathPreset.none;
  }
}

enum _FinanceMathPreset {
  none,
  negate,
  timesThousand,
  divideThousand,
}
