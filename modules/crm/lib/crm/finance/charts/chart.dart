// lib/crm/finance/charts/chart.dart (przykładowa nazwa)

import 'package:crm/crm/finance/charts/chart_settings.dart';
import 'package:crm/crm/finance/charts/export.dart';
import 'package:crm/crm/finance/charts/remote_data.dart';
import 'package:crm/crm/finance/charts/render.dart';
import 'package:crm/crm/finance/charts/sheet.dart';
import 'package:crm/crm/finance/charts/sheet_presets.dart';
import 'package:crm/crm/finance/charts/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

class FinanceAppChart extends ConsumerStatefulWidget {
  /// Optional callback to open full finance view.
  final VoidCallback? onOpenFullFinance;

  const FinanceAppChart({super.key, this.onOpenFullFinance});

  @override
  ConsumerState<FinanceAppChart> createState() => _FinanceAppChartState();
}

class _FinanceAppChartState extends ConsumerState<FinanceAppChart> {
  /// Key used for capturing chart as image
  final GlobalKey _chartKey = GlobalKey();

  bool _loadedFromBackend = false;

  @override
  void initState() {
    super.initState();
    // Load visual settings (colors, legend visibility, type, etc.) from backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(financeChartSettingsProvider.notifier);
      notifier.loadSettingsFromBackend().then((_) {
        if (mounted) {
          setState(() {
            _loadedFromBackend = true;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final settings = ref.watch(financeChartSettingsProvider);
    final settingsNotifier = ref.read(financeChartSettingsProvider.notifier);

    final remoteAsync = ref.watch(financeChartRemoteProvider);
    final dataConfig = ref.watch(financeChartDataConfigProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border.all(color: theme.dashboardBoarder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          /// TOP BAR – title + range + chart type + actions
          FinanceChartTopBar(
            theme: theme,
            settings: settings,
            onRangeChanged: (range) {
              settingsNotifier.updateRange(range);
              settingsNotifier.saveSettingsToBackend();

              final dataConfigNotifier = ref.read(
                financeChartDataConfigProvider.notifier,
              );
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
              dataConfigNotifier.setDateRange(start, now);
            },
            onChartTypeChanged: (type) {
              settingsNotifier.updateChartType(type);
              settingsNotifier.saveSettingsToBackend();
            },
            onOpenPresets: () async {
              await showFinanceChartPresetsSheet(context, ref);
            },
            onOpenSettings: () async {
              await showFinanceChartSettingsSheet(context, ref); // Pro
            },
            onOpenFullFinance: widget.onOpenFullFinance,
            onExportSelected: (value) async {
              if (value == 'image') {
                await exportFinanceChartAsPng(context, _chartKey);
              } else if (value == 'pdf') {
                await exportFinanceChartAsPdf(context, _chartKey);
              }
            },
          ),

          const SizedBox(height: 8),

          /// CHART AREA – wrapped with RepaintBoundary for export
          Expanded(
            child: GestureDetector(
              onTap: widget.onOpenFullFinance,
              child: RepaintBoundary(
                key: _chartKey,
                child: remoteAsync.when(
                  data: (remote) {
                    return buildFinanceChartWidget(
                      context: context,
                      theme: theme,
                      settings: settings,
                      remote: remote,
                      config: dataConfig,
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (e, st) => Center(
                        child: Text(
                          'Error: $e',
                          style: TextStyle(color: theme.textColor),
                        ),
                      ),
                ),
              ),
            ),
          ),
          // Legendę możesz zostawić lub potem zbudować ją dynamicznie
          // na bazie config.series (widoczność / kolor).
        ],
      ),
    );
  }
}
