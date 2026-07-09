// lib/crm/finance/charts/render.dart

import 'package:crm/crm/finance/charts/chart_settings.dart';
import 'package:crm/crm/finance/charts/remote_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

Color _parseColor(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  try {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  } catch (_) {
    return fallback;
  }
}

Color _seriesColor(int index, FinanceChartSeriesConfig cfg) {
  if (cfg.colorHex != null && cfg.colorHex!.isNotEmpty) {
    return _parseColor(cfg.colorHex, Colors.blue);
  }

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

double _applyMath(FinanceChartSeriesConfig cfg, double raw) {
  double v = raw;
  if (cfg.invert) {
    v = -v;
  }
  if (cfg.factor != null) {
    v *= cfg.factor!;
  }
  return v;
}

/// Główny builder wykresu – w 100% oparty na remote + data_config
Widget buildFinanceChartWidget({
  required BuildContext context,
  required ThemeColors theme,
  required FinanceChartSettings settings,
  required FinanceChartRemoteResponse remote,
  required FinanceChartDataConfig config,
}) {
  // Brak danych
  if (remote.labels.isEmpty || remote.series.isEmpty) {
    return Center(
      child: Text(
        'no_data_to_display_label'.tr,
        style: TextStyle(color: theme.textColor),
      ),
    );
  }

  switch (settings.chartType) {
    case FinanceChartType.line:
      return _buildLineChart(theme, settings, remote, config);
    case FinanceChartType.bar:
      return _buildBarChart(theme, settings, remote, config);
    case FinanceChartType.pie:
      return _buildPieChart(theme, settings, remote, config);
  }
}

/// LINE CHART – dowolna liczba serii
Widget _buildLineChart(
  ThemeColors theme,
  FinanceChartSettings settings,
  FinanceChartRemoteResponse remote,
  FinanceChartDataConfig config,
) {
  final lineBars = <LineChartBarData>[];
  final allValues = <double>[];

  for (int sIndex = 0; sIndex < remote.series.length; sIndex++) {
    final seriesResult = remote.series[sIndex];

    // Jeśli config.series jest krótszy niż remote.series – domyślnie widoczne.
    final cfg = (sIndex < config.series.length)
        ? config.series[sIndex]
        : FinanceChartSeriesConfig(
            name: seriesResult.name,
            kind: 'revenue',
          );

    if (!cfg.visible) continue;

    final spots = <FlSpot>[];
    for (int i = 0; i < remote.labels.length; i++) {
      final raw = (i < seriesResult.values.length)
          ? seriesResult.values[i]
          : 0.0;
      final y = _applyMath(cfg, raw);
      spots.add(FlSpot(i.toDouble(), y));
      allValues.add(y);
    }

    final color = _seriesColor(sIndex, cfg);

    lineBars.add(
      LineChartBarData(
        spots: spots,
        isCurved: settings.smoothLines,
        barWidth: 2,
        dotData: FlDotData(show: settings.showDots),
        color: color,
      ),
    );
  }

  if (allValues.isEmpty) {
    return Center(
      child: Text(
        'no_data_to_display_label'.tr,
        style: TextStyle(color: theme.textColor),
      ),
    );
  }

  allValues.add(0.0);
  final maxY = allValues.reduce((a, b) => a > b ? a : b);

  return LineChart(
    LineChartData(
      minY: 0,
      maxY: maxY == 0 ? 1 : maxY * 1.2,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 10,
                color: theme.textColor,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (remote.labels.length / 4)
                .clamp(1, remote.labels.length)
                .toDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= remote.labels.length) {
                return const SizedBox.shrink();
              }

              final label = remote.labels[index];
              // Możesz tu dodać formatowanie zależne od group_by (day/week/month)
              return Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: theme.textColor,
                ),
              );
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: theme.textColor.withAlpha(40),
        ),
      ),
      lineBarsData: lineBars,
    ),
  );
}

/// BAR CHART – każdy bucket = grupa słupków (po jednej na serię)
Widget _buildBarChart(
  ThemeColors theme,
  FinanceChartSettings settings,
  FinanceChartRemoteResponse remote,
  FinanceChartDataConfig config,
) {
  final groups = <BarChartGroupData>[];

  for (int x = 0; x < remote.labels.length; x++) {
    final rods = <BarChartRodData>[];

    for (int sIndex = 0; sIndex < remote.series.length; sIndex++) {
      final seriesResult = remote.series[sIndex];
      final cfg = (sIndex < config.series.length)
          ? config.series[sIndex]
          : FinanceChartSeriesConfig(
              name: seriesResult.name,
              kind: 'revenue',
            );

      if (!cfg.visible) continue;

      final raw = (x < seriesResult.values.length)
          ? seriesResult.values[x]
          : 0.0;
      final y = _applyMath(cfg, raw);
      final color = _seriesColor(sIndex, cfg);

      rods.add(
        BarChartRodData(
          toY: y,
          width: 6,
          color: color,
        ),
      );
    }

    groups.add(
      BarChartGroupData(
        x: x,
        barRods: rods,
        barsSpace: 2,
      ),
    );
  }

  double maxY = 0;
  for (final g in groups) {
    for (final r in g.barRods) {
      if (r.toY > maxY) maxY = r.toY;
    }
  }
  if (maxY == 0) maxY = 1;

  return BarChart(
    BarChartData(
      maxY: maxY * 1.2,
      barGroups: groups,
      gridData: FlGridData(show: true),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: theme.textColor.withAlpha(40)),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 10,
                color: theme.textColor,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: (remote.labels.length / 4)
                .clamp(1, remote.labels.length)
                .toDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= remote.labels.length) {
                return const SizedBox.shrink();
              }
              final label = remote.labels[index];
              return Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: theme.textColor,
                ),
              );
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
    ),
  );
}

/// PIE CHART – każdy wynik = suma serii w całym okresie
Widget _buildPieChart(
  ThemeColors theme,
  FinanceChartSettings settings,
  FinanceChartRemoteResponse remote,
  FinanceChartDataConfig config,
) {
  final sections = <PieChartSectionData>[];

  for (int sIndex = 0; sIndex < remote.series.length; sIndex++) {
    final seriesResult = remote.series[sIndex];
    final cfg = (sIndex < config.series.length)
        ? config.series[sIndex]
        : FinanceChartSeriesConfig(
            name: seriesResult.name,
            kind: 'revenue',
          );

    if (!cfg.visible) continue;

    double total = 0;
    for (final raw in seriesResult.values) {
      total += _applyMath(cfg, raw);
    }

    if (total == 0) continue;

    final color = _seriesColor(sIndex, cfg);

    sections.add(
      PieChartSectionData(
        value: total,
        color: color,
        title: '${cfg.name} ${total.toStringAsFixed(0)}',
        radius: 60,
        titleStyle: TextStyle(
          color: theme.themeTextColor,
          fontSize: 10,
        ),
      ),
    );
  }

  if (sections.isEmpty) {
    return Center(
      child: Text(
        'no_data_to_display_label'.tr,
        style: TextStyle(color: theme.textColor),
      ),
    );
  }

  return PieChart(
    PieChartData(
      sections: sections,
      sectionsSpace: 2,
      centerSpaceRadius: 40,
    ),
  );
}
