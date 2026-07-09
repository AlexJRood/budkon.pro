import 'package:crm/crm/finance/charts/chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';

class FinanceFullChartPopup extends ConsumerWidget {
  const FinanceFullChartPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.dashboardContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
          'full_finance_view_title'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 12),

          // Rozszerzony wykres – możesz dodać inne filtry itp.
          const Expanded(
            child: FinanceAppChart(
              // w popupie nie otwieramy kolejnego popupu
              onOpenFullFinance: null,
            ),
          ),
        ],
      ),
    );
  }
}
