import 'package:crm/crm/finance/charts/remote_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class FinanceChartLegend extends ConsumerWidget {
  final ThemeColors theme;

  const FinanceChartLegend({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(financeChartDataConfigProvider);
    final notifier =
        ref.read(financeChartDataConfigProvider.notifier);

    if (config.series.isEmpty) {
      return Text(
        'no_series_defined_message'.tr,
        style: TextStyle(color: theme.textColor),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < config.series.length; i++)
          _legendCheckbox(
            index: i,
            cfg: config.series[i],
            onToggle: () => notifier.toggleSeriesVisibility(i),
          ),
      ],
    );
  }

  Widget _legendCheckbox({
    required int index,
    required FinanceChartSeriesConfig cfg,
    required VoidCallback onToggle,
  }) {
    final color = _parseColor(cfg.colorHex, _fallbackColor(index));

    return InkWell(
      onTap: onToggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: cfg.visible,
            onChanged: (_) => onToggle(),
            visualDensity: VisualDensity.compact,
            activeColor: color,
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            cfg.name,
            style: TextStyle(
              fontSize: 11,
              color: theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  Color _fallbackColor(int index) {
    const palette = [
      Colors.green,
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    return palette[index % palette.length];
  }
}
