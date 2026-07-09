import 'package:core/ui/device_type_util.dart';
import 'package:crm/crm/finance/charts/pop_up.dart';
import 'package:crm/crm/finance/dashboard/api_dashboard.dart';
import 'package:crm/crm/finance/dashboard/list_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class FinanceDashboard extends ConsumerWidget {
  final WidgetRef? refFromParent;

  const FinanceDashboard({super.key, this.refFromParent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(upcomingUnpaidTransactionsProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;
    final width = MediaQuery.of(context).size.width;
    final theme = ref.watch(themeColorsProvider);
    final isTablet = width >= 800 && width <= 1200;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 8 : 14),
      child: Container(
        margin: EdgeInsets.only(top: TopAppBarSize.clearPage(context)),
        decoration: BoxDecoration(
          color: theme.dashboardContainer.withAlpha(210),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.textColor.withAlpha(22)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.themeColor.withAlpha(35),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.payments_outlined,
                      color: theme.themeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upcoming unpaid'.tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Invoices, revenues and costs waiting for payment'.tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(145),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.textColor.withAlpha(22)),
            Expanded(
              flex: isTablet ? 1 : 3,
              child: asyncData.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: AppLottie.noResults(size: isMobile ? 260 : 380),
                    );
                  }

                  return FinanceTransactionsListWidget(
                    data: list,
                    isMobile: isMobile,
                    isTablet: isTablet,
                  );
                },
                loading:
                    () => Center(
                      child: AppLottie.loading(size: isMobile ? 260 : 380),
                    ),
                error:
                    (e, st) => Center(
                      child: Text(
                        'Error: $e',
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FinanceFullChartPage extends ConsumerWidget {
  const FinanceFullChartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 8 : 14),
      child: Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer.withAlpha(210),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.textColor.withAlpha(22)),
        ),
        clipBehavior: Clip.antiAlias,
        child: const FinanceFullChartPopup(),
      ),
    );
  }
}
