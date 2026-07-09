import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:intl/intl.dart';
import 'package:reports/reports/dashboard_report/models/dashboard_data_model.dart';
import 'package:reports/reports/dashboard_report/provider/dashboard_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as sf_charts;
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';

class PriceChartWidget extends ConsumerStatefulWidget {
  final bool isMobile;

  const PriceChartWidget({super.key, this.isMobile = false});

  @override
  ConsumerState<PriceChartWidget> createState() => _PriceChartWidgetState();
}

class _PriceChartWidgetState extends ConsumerState<PriceChartWidget> {
  String selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    return dashboardDataAsync.when(
      data: (dashboardData) {
        final filterOptions = _buildFilterOptions(dashboardData.priceTrend);
        final safeSelected =
            filterOptions.any((e) => e.value == selectedCategory)
                ? selectedCategory
                : 'all';

        final selectedLabel =
            filterOptions
                .firstWhere((e) => e.value == safeSelected)
                .label;

        final filteredTrend =
            dashboardData.priceTrend
                .where(
                  (e) =>
                      safeSelected == 'all' ||
                      e.propertyType == safeSelected,
                )
                .toList()
              ..sort((a, b) => a.periodKey.compareTo(b.periodKey));

        final List<_PriceTrendChartPoint> chartData;
        if (safeSelected == 'all') {
          final grouped = <String, List<PriceTrendPoint>>{};
          for (final e in filteredTrend) {
            grouped.putIfAbsent(e.periodKey, () => []).add(e);
          }
          final sortedKeys = grouped.keys.toList()..sort();
          chartData = sortedKeys.map((key) {
            final points = grouped[key]!;
            final totalCount = points.fold<int>(0, (s, p) => s + p.listingCount);
            final weightedPrice = totalCount > 0
                ? points.fold<double>(0, (s, p) => s + p.averagePricePerSqm * p.listingCount) / totalCount
                : points.fold<double>(0, (s, p) => s + p.averagePricePerSqm) / points.length;
            return _PriceTrendChartPoint(
              label: points.first.periodLabel,
              value: weightedPrice,
              count: totalCount,
              currency: points.first.currency,
            );
          }).toList();
        } else {
          chartData = filteredTrend
              .map(
                (e) => _PriceTrendChartPoint(
                  label: e.periodLabel,
                  value: e.averagePricePerSqm,
                  count: e.listingCount,
                  currency: e.currency,
                ),
              )
              .toList();
        }

        double minPrice = 0;
        double maxPrice = 10000;
        if (chartData.isNotEmpty) {
          final prices = chartData.map((e) => e.value).toList();
          final min = prices.reduce((a, b) => a < b ? a : b);
          final max = prices.reduce((a, b) => a > b ? a : b);
          minPrice = (min * 0.9).floorToDouble();
          maxPrice = (max * 1.1).ceilToDouble();
        }

        return Container(
          padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: CustomColors.secondaryWidgetColor(context, ref),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CustomColors.secondaryWidgetTextColor(
                context,
                ref,
              ).withAlpha(76),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'average_market_price_per_m2'.tr,
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            color: CustomColors.secondaryWidgetTextColor(
                              context,
                              ref,
                            ),
                            fontSize: widget.isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: widget.isMobile ? 2 : 4),
                        Text(
                          selectedLabel,
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            color: CustomColors.secondaryWidgetTextColor(
                              context,
                              ref,
                            ).withAlpha(230),
                            fontSize: widget.isMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: widget.isMobile ? 36 : 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          ref,
                        ).withAlpha(76),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: CustomColors.secondaryWidgetColor(context, ref),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 10 : 15,
                    ),
                    child: DropdownButton<String>(
                      padding: EdgeInsets.all(widget.isMobile ? 3 : 5),
                      borderRadius: BorderRadius.circular(10),
                      value: safeSelected,
                      items:
                          filterOptions
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.value,
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: widget.isMobile ? 12 : 14,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue ?? 'all';
                        });
                      },
                      style: TextStyle(
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          ref,
                        ).withAlpha(204),
                      ),
                      icon: AppIcons.iosArrowDown(
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          ref,
                        ),
                      ),
                      dropdownColor: CustomColors.secondaryWidgetColor(
                        context,
                        ref,
                      ),
                      underline: Container(),
                    ),
                  ),
                  if (!widget.isMobile) ...[
                    const SizedBox(width: 30),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: AppIcons.enLarge(
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          ref,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: widget.isMobile ? 12 : 16),
              SizedBox(
                height: widget.isMobile ? 42 : 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filterOptions.length,
                  separatorBuilder: (_, __) => SizedBox(width: widget.isMobile ? 6 : 8),
                  itemBuilder: (context, index) {
                    final item = filterOptions[index];
                    final isSelected = item.value == safeSelected;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = item.value;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isMobile ? 10 : 14,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? CustomColors.secondaryWidgetTextColor(
                                    context,
                                    ref,
                                  ).withAlpha(26)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isSelected
                                    ? CustomColors.secondaryWidgetTextColor(
                                      context,
                                      ref,
                                    )
                                    : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ),
                              fontSize: widget.isMobile ? 12 : 14,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: widget.isMobile ? 16 : 24),
              Expanded(
                child:
                    chartData.isEmpty
                        ? Center(
                          child: Text(
                            'no_market_price_data_for_this_filter'.tr,
                            style: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ),
                            ),
                          ),
                        )
                        : sf_charts.SfCartesianChart(
                          plotAreaBorderWidth: 0,
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
                              final pointData = chartData[pointIndex];
                              return Container(
                                padding: EdgeInsets.all(
                                  widget.isMobile ? 8 : 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${pointData.label}\n'
                                  '${pointData.currency} ${NumberFormat('#,###').format(pointData.value)} / m²\n'
                                  '${pointData.count} ${'listings'.tr}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                          primaryXAxis: sf_charts.CategoryAxis(
                            labelStyle: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ),
                              fontSize: widget.isMobile ? 10 : 12,
                            ),
                            majorGridLines: const sf_charts.MajorGridLines(width: 0),
                            axisLine: const sf_charts.AxisLine(width: 0),
                          ),
                          primaryYAxis: sf_charts.NumericAxis(
                            labelStyle: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ),
                              fontSize: widget.isMobile ? 10 : 12,
                            ),
                            majorGridLines: sf_charts.MajorGridLines(
                              width: 0.5,
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ).withAlpha(80),
                            ),
                            axisLine: const sf_charts.AxisLine(width: 0),
                            minimum: minPrice,
                            maximum: maxPrice,
                            majorTickLines: const sf_charts.MajorTickLines(size: 0),
                          ),
                          series: <sf_charts.CartesianSeries<_PriceTrendChartPoint, String>>[
                            sf_charts.SplineAreaSeries<_PriceTrendChartPoint, String>(
                              dataSource: chartData,
                              xValueMapper: (data, _) => data.label,
                              yValueMapper: (data, _) => data.value,
                              borderColor: Colors.greenAccent,
                              color: Colors.greenAccent.withAlpha(50),
                              borderWidth: 2,
                              markerSettings: sf_charts.MarkerSettings(
                                isVisible: true,
                                height: widget.isMobile ? 4 : 5,
                                width: widget.isMobile ? 4 : 5,
                                color: Colors.greenAccent,
                                borderColor: CustomColors.secondaryWidgetTextColor(
                                  context,
                                  ref,
                                ),
                                borderWidth: 1,
                              ),
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
            padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: CustomColors.secondaryWidgetColor(context, ref),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CustomColors.secondaryWidgetTextColor(
                  context,
                  ref,
                ).withAlpha(76),
              ),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stack) => Container(
            padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: CustomColors.secondaryWidgetColor(context, ref),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CustomColors.secondaryWidgetTextColor(
                  context,
                  ref,
                ).withAlpha(76),
              ),
            ),
            child: Center(
              child: Text(
                'error_loading_market_price_data'.tr,
                style: TextStyle(
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                ),
              ),
            ),
          ),
    );
  }

  List<_FilterOption> _buildFilterOptions(List<PriceTrendPoint> points) {
    final options = <_FilterOption>[
      _FilterOption(value: 'all', label: 'All'.tr),
    ];

    final seen = <String>{'all'};
    final categories =
        points
            .map((e) => e.propertyType.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    for (final category in categories) {
      if (seen.add(category)) {
        options.add(
          _FilterOption(
            value: category,
            label: category.tr,
          ),
        );
      }
    }

    return options;
  }
}

class _FilterOption {
  final String value;
  final String label;

  _FilterOption({
    required this.value,
    required this.label,
  });
}

class _PriceTrendChartPoint {
  final String label;
  final double value;
  final int count;
  final String currency;

  _PriceTrendChartPoint({
    required this.label,
    required this.value,
    required this.count,
    required this.currency,
  });
}