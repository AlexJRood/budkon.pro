import 'package:crm/data/components/plans_chart/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/design.dart';
import 'package:core/common/loading_widgets.dart';

import 'package:get/get_utils/get_utils.dart';

class FinancialPlansBarChart extends ConsumerStatefulWidget {
  const FinancialPlansBarChart({
    super.key,
  });

  @override
  _FinancialPlansBarChartState createState() => _FinancialPlansBarChartState();
}

class _FinancialPlansBarChartState
    extends ConsumerState<FinancialPlansBarChart> {
  int? touchedGroupIndex;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(financialPlansProvider);
    double screenHeight = MediaQuery.of(context).size.height;

    double pieChartScreenHeight = screenHeight / 5 * 2 - 54;

    return data.when(
      data: (data) {
        final expenses =
            List<Map<String, dynamic>>.from(data['expenses'] ?? []);
        final revenues =
            List<Map<String, dynamic>>.from(data['revenues'] ?? []);

        if (expenses.isEmpty && revenues.isEmpty) {
          return Center(
            child: Text(
              "No Data Found".tr,
              style: AppTextStyles.interMedium14
                  .copyWith(color: Theme.of(context).iconTheme.color),
            ),
          );
        }

        final maxExpenses = expenses.isNotEmpty
            ? expenses
                .map((e) => double.parse(e['total_amount'].toString()))
                .reduce((a, b) => a > b ? a : b)
            : 0.0;
        final maxRevenues = revenues.isNotEmpty
            ? revenues
                .map((r) =>
                    double.parse((r['total_amount'] ?? '0.0').toString()))
                .reduce((a, b) => a > b ? a : b)
            : 0.0;

        final maxY =
            (maxExpenses > maxRevenues ? maxExpenses : maxRevenues) * 1.1;

        return Padding(
          padding: const EdgeInsets.all(30.0),
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.black,
                ),
                touchCallback:
                    (FlTouchEvent event, BarTouchResponse? touchResponse) {
                  setState(() {
                    if (touchResponse != null && touchResponse.spot != null) {
                      touchedGroupIndex =
                          touchResponse.spot!.touchedBarGroupIndex;
                    } else {
                      touchedGroupIndex = -1;
                    }
                  });
                },
              ),
              barGroups: [
                ...expenses.asMap().entries.map((entry) {
                  final e = entry.value;
                  final index = entry.key;
                  final isTouched = index == touchedGroupIndex;

                  final expenseValue =
                      double.parse(e['total_amount'].toString());
                  final revenueValue = double.parse(revenues
                      .firstWhere((r) => revenues.indexOf(r) == index,
                          orElse: () => {'total_amount': '0'})['total_amount']
                      .toString());

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: expenseValue,
                        color:
                            isTouched ? Colors.orange : AppColors.expensesRed,
                        width: isTouched ? 40 : 30,
                        borderRadius: BorderRadius.circular(0),
                      ),
                      BarChartRodData(
                        toY: revenueValue,
                        color: isTouched ? Colors.blue : AppColors.revenueGreen,
                        width: isTouched ? 40 : 30,
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ],
                  );
                }),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 80,
                    getTitlesWidget: (value, meta) {
                      return Center(
                        child: Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
                drawHorizontalLine: true,
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        );
      },
      loading: () => ShimmerPlaceholder(
          height: pieChartScreenHeight, width: double.infinity),
      error: (error, stackTrace) => Center(
        child: Text(
          '${'Error'.tr} $error'.tr,
          style: TextStyle(color: Theme.of(context).iconTheme.color),
        ),
      ),
    );
  }
}
