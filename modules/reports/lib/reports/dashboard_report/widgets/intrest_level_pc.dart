import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reports/reports/dashboard_report/provider/dashboard_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as sf_charts;
import 'package:core/theme/backgroundgradient.dart';
import 'package:get/get_utils/get_utils.dart';
class InterestLevelsChart extends ConsumerWidget {
  final bool isMobile;

  const InterestLevelsChart({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    return dashboardDataAsync.when(
      data: (dashboardData) {
        final cities = dashboardData.marketPressure;

        if (cities.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: CustomColors.secondaryWidgetTextColor(
                  context,
                  ref,
                ).withAlpha(76),
              ),
              color: CustomColors.secondaryWidgetColor(context, ref),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'no_market_pressure_data_available'.tr,
                style: TextStyle(
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                ),
              ),
            ),
          );
        }

        final chartData =
            cities
                .map(
                  (e) => _MarketPressureData(
                    city: e.city,
                    value: e.pressureIndex,
                    removed: e.removedListings30d,
                    added: e.newListings30d,
                    medianDays: e.medianDisappearanceDays ?? 0,
                    label: e.label,
                  ),
                )
                .toList();

        final maxValue =
            chartData
                .map((e) => e.value)
                .reduce((a, b) => a > b ? a : b);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: CustomColors.secondaryWidgetTextColor(
                context,
                ref,
              ).withAlpha(76),
            ),
            color: CustomColors.secondaryWidgetColor(context, ref),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'market_pressure'.tr,
                style: TextStyle(
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 16 : 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'higher_score_means_stronger_demand'.tr,
                style: TextStyle(
                  color: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ).withAlpha(220),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: sf_charts.SfCartesianChart(
                  tooltipBehavior: sf_charts.TooltipBehavior(
                    enable: true,
                    color: Colors.black87,
                    builder: (
                      dynamic data,
                      dynamic point,
                      dynamic series,
                      int pointIndex,
                      int seriesIndex,
                    ) {
                      final item = chartData[pointIndex];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.city}\n'
                          'Pressure: ${item.value.toStringAsFixed(1)}\n'
                          'New: ${item.added}\n'
                          'Removed: ${item.removed}\n'
                          'Median: ${item.medianDays.toStringAsFixed(1)} d\n'
                          '${item.label}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                  primaryXAxis: sf_charts.CategoryAxis(
                    axisLine: const sf_charts.AxisLine(width: 0),
                    majorGridLines: const sf_charts.MajorGridLines(width: 0),
                    labelStyle: TextStyle(
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        ref,
                      ),
                      fontSize: isMobile ? 10 : 12,
                    ),
                  ),
                  primaryYAxis: sf_charts.NumericAxis(
                    labelStyle: TextStyle(
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        ref,
                      ),
                      fontSize: isMobile ? 10 : 12,
                    ),
                    majorGridLines: sf_charts.MajorGridLines(
                      width: 0.5,
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        ref,
                      ).withAlpha(60),
                    ),
                    axisLine: const sf_charts.AxisLine(width: 0),
                    minimum: 0,
                    maximum: maxValue > 0 ? maxValue * 1.2 : 100,
                  ),
                  plotAreaBorderWidth: 0,
                  series: <sf_charts.CartesianSeries<dynamic, dynamic>>[
                    sf_charts.ColumnSeries<_MarketPressureData, String>(
                      dataSource: chartData,
                      xValueMapper: (datum, _) => datum.city,
                      yValueMapper: (datum, _) => datum.value,
                      pointColorMapper: (datum, _) => datum.color,
                      width: 0.6,
                      enableTooltip: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading:
          () => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: CustomColors.secondaryWidgetTextColor(
                  context,
                  ref,
                ).withAlpha(76),
              ),
              color: CustomColors.secondaryWidgetColor(context, ref),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stack) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: CustomColors.secondaryWidgetTextColor(
                  context,
                  ref,
                ).withAlpha(76),
              ),
              color: CustomColors.secondaryWidgetColor(context, ref),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'error_loading_market_pressure'.tr,
                style: TextStyle(
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                ),
              ),
            ),
          ),
    );
  }
}

class _MarketPressureData {
  final String city;
  final double value;
  final int removed;
  final int added;
  final double medianDays;
  final String label;

  _MarketPressureData({
    required this.city,
    required this.value,
    required this.removed,
    required this.added,
    required this.medianDays,
    required this.label,
  });

  Color get color {
    if (value >= 75) return Colors.redAccent;
    if (value >= 55) return Colors.orangeAccent;
    if (value >= 35) return Colors.amber;
    return Colors.green;
  }
}