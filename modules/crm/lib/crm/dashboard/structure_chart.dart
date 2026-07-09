import 'package:crm/data/components/structure_chart/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/design.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:intl/intl.dart';

import 'package:get/get_utils/get_utils.dart';

class TransactionTypeChartScreen extends StatefulWidget {
  const TransactionTypeChartScreen({super.key});

  @override
  _TransactionTypeChartScreenState createState() =>
      _TransactionTypeChartScreenState();
}

class _TransactionTypeChartScreenState extends State<TransactionTypeChartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Type Charts'.tr),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Expenses'.tr),
            Tab(text: 'Revenues'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TransactionTypePieChart(isExpenses: true),
          TransactionTypePieChart(isExpenses: false),
        ],
      ),
    );
  }
}

class TransactionTypePieChart extends ConsumerStatefulWidget {
  final bool isExpenses;

  const TransactionTypePieChart({
    required this.isExpenses,
    super.key,
  });

  @override
  _TransactionTypePieChartState createState() =>
      _TransactionTypePieChartState();
}

class _TransactionTypePieChartState
    extends ConsumerState<TransactionTypePieChart> {
  int touchedIndex = -1;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'pl_PL',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(transactionTypeProvider);

    return data.when(
      data: (data) {
        final items = List<Map<String, dynamic>>.from(widget.isExpenses
            ? (data['expenses'] ?? [])
            : (data['revenues'] ?? []));

        if (items.isEmpty) {
          return Center(
            child: Text(
              "No Data Found".tr,
              style: AppTextStyles.interMedium14
                  .copyWith(color: Theme.of(context).iconTheme.color),
            ),
          );
        }

        final List<Color> colors = [
          AppColors.expensesRed,
          Colors.blue,
          AppColors.revenueGreen,
          Colors.orange,
          Colors.purple,
          Colors.yellow,
          Colors.cyan,
          Colors.pink,
        ];

        final List<PieChartSectionData> sections = [];
        final List<Widget> legendItems = [];

        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          final color = colors[i % colors.length];
          final formattedAmount = currencyFormat
              .format(double.parse(item['total_amount'].toString()));

          sections.add(
            PieChartSectionData(
              title: item['transaction_type'] ?? 'Unknown'.tr,
              value: double.parse(item['total_amount'].toString()),
              color: color,
              radius: touchedIndex == i ? 100 : 80,
              titleStyle: AppTextStyles.interMedium16,
              badgeWidget: touchedIndex == i
                  ? _Badge('$formattedAmount ${item['currency']}', color)
                  : null,
              badgePositionPercentageOffset: .98,
            ),
          );

          legendItems.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item['transaction_type'] ?? 'Unknown'.tr}: $formattedAmount ${item['currency']}',
                      style: AppTextStyles.interMedium14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: sections,
                    centerSpaceRadius: 50,
                    sectionsSpace: 5,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: legendItems,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => ShimmerPlaceholder(height: 200, width: double.infinity),
      error: (error, stackTrace) => Center(
        child: Text(
          '${'Error'.tr} $error'.tr,
          style: TextStyle(color: Theme.of(context).iconTheme.color),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.9).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: AppTextStyles.interMedium14),
    );
  }
}
