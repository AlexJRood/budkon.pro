import 'package:crm/crm/finance/charts/chart_settings.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class FinanceChartTopBar extends StatelessWidget {
  final ThemeColors theme;
  final FinanceChartSettings settings;

  final ValueChanged<FinanceChartRange> onRangeChanged;
  final ValueChanged<FinanceChartType> onChartTypeChanged;

  /// Basic presets sheet
  final VoidCallback? onOpenPresets;

  /// Pro / advanced sheet (ta ultra Emma edition)
  final VoidCallback? onOpenSettings;

  /// Otwórz pełny widok finansów
  final VoidCallback? onOpenFullFinance;

  /// Eksport wykresu (image/pdf)
  final Future<void> Function(String value)? onExportSelected;

  const FinanceChartTopBar({
    super.key,
    required this.theme,
    required this.settings,
    required this.onRangeChanged,
    required this.onChartTypeChanged,
    this.onOpenPresets,
    this.onOpenSettings,
    this.onOpenFullFinance,
    this.onExportSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 450;

        return Column(
          children: [
            Row(
              children: [
                Text(
                  'finance_chart_title'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                ),
                const Spacer(),
                if (onOpenPresets != null)
                  isNarrow
                      ? IconButton(
                        onPressed: onOpenPresets,
                        icon: const Icon(Icons.tune, size: 16),
                        tooltip: 'Presety'.tr,
                        color: theme.textColor,
                      )
                      : TextButton.icon(
                        onPressed: onOpenPresets,
                        icon: const Icon(Icons.tune, size: 16),
                        label: Text(
                          'presets_button'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                const SizedBox(width: 4),
                if (onOpenSettings != null)
                  isNarrow
                      ? IconButton(
                        onPressed: onOpenSettings,
                        icon: const Icon(Icons.auto_graph, size: 16),
                        tooltip: 'Pro'.tr,
                        color: theme.themeColor,
                      )
                      : TextButton.icon(
                        onPressed: onOpenSettings,
                        icon: const Icon(Icons.auto_graph, size: 16),
                        label: Text(
                          'pro_button'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.themeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                const SizedBox(width: 4),
                if (onOpenFullFinance != null)
                  IconButton(
                    tooltip: 'full_finance_module_tooltip'.tr,
                    onPressed: onOpenFullFinance,
                    icon: Icon(
                      Icons.open_in_full,
                      size: 18,
                      color: theme.textColor,
                    ),
                  ),
                if (onExportSelected != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.textColor,
                      size: 18,
                    ),
                    onSelected: (value) => onExportSelected!(value),
                    itemBuilder:
                        (ctx) => [
                          PopupMenuItem(
                            value: 'image',
                            child: Text('export_as_png_label'.tr),
                          ),
                          PopupMenuItem(
                            value: 'pdf',
                            child: Text('export_as_pdf_label'.tr),
                          ),
                        ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Range
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _chip(
                        selected: settings.range == FinanceChartRange.week,
                        label: '7_days_label'.tr,
                        onTap: () => onRangeChanged(FinanceChartRange.week),
                      ),
                      _chip(
                        selected: settings.range == FinanceChartRange.month,
                        label: '30_days_label'.tr,
                        onTap: () => onRangeChanged(FinanceChartRange.month),
                      ),
                      _chip(
                        selected: settings.range == FinanceChartRange.year,
                        label: '365_days_label'.tr,
                        onTap: () => onRangeChanged(FinanceChartRange.year),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Typ wykresu
                Wrap(
                  spacing: 4,
                  children: [
                    _iconChip(
                      icon: Icons.show_chart,
                      tooltip: 'line_chart_tooltip'.tr,
                      selected: settings.chartType == FinanceChartType.line,
                      onTap: () => onChartTypeChanged(FinanceChartType.line),
                    ),
                    _iconChip(
                      icon: Icons.bar_chart,
                      tooltip: 'bar_chart_tooltip'.tr,
                      selected: settings.chartType == FinanceChartType.bar,
                      onTap: () => onChartTypeChanged(FinanceChartType.bar),
                    ),
                    _iconChip(
                      icon: Icons.pie_chart,
                      tooltip: 'pie_chart_tooltip'.tr,
                      selected: settings.chartType == FinanceChartType.pie,
                      onTap: () => onChartTypeChanged(FinanceChartType.pie),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _chip({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: selected ? theme.themeColorText : theme.textColor,
        ),
      ),
      selected: selected,
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        final isSelected = states.contains(WidgetState.selected);
        return isSelected ? theme.themeColor : theme.dashboardContainer;
      }),
      checkmarkColor: theme.themeColorText,
      onSelected: (_) => onTap(),
      selectedColor: theme.themeColorText,
      backgroundColor: theme.themeColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _iconChip({
    required IconData icon,
    required String tooltip,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:
                selected ? theme.themeColor.withAlpha(46) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? theme.themeColor : theme.textColor,
          ),
        ),
      ),
    );
  }
}
