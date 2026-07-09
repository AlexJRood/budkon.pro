import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reports/reports/dashboard_report/provider/dashboard_provider.dart';
import 'package:reports/reports/dashboard_report/widgets/components/report_stats_card.dart';
import 'package:get/get_utils/get_utils.dart';

class ReportStatsWidgetPc extends ConsumerWidget {
  const ReportStatsWidgetPc({super.key, this.isMobile = false});

  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    return dashboardDataAsync.when(
      data: (dashboardData) {
        final overview = dashboardData.overview;

        final cards = [
          ReportStatCard(
            title: 'active_inventory'.tr,
            value: '${overview.activeInventory}',
            subtitle: 'currently_active_listings'.tr,
            icon: Icons.inventory_2_outlined,
          ),
          ReportStatCard(
            title: 'new_listings_7d'.tr,
            value: '${overview.newListings7d}',
            percentage: overview.newListings7dChangePct,
            subtitle: 'vs_previous_7_days'.tr,
            icon: Icons.add_business_outlined,
          ),
          ReportStatCard(
            title: 'removed_from_market_7d'.tr,
            value: '${overview.removedListings7d}',
            percentage: overview.removedListings7dChangePct,
            subtitle: 'vs_previous_7_days'.tr,
            icon: Icons.trending_down_outlined,
          ),
          ReportStatCard(
            title: 'median_time_to_disappear'.tr,
            value: overview.medianDisappearanceDays == null
                ? '—'
                : '${overview.medianDisappearanceDays!.toStringAsFixed(1)} d',
            percentage: overview.medianDisappearanceDaysChangePct,
            positiveWhenDown: true,
            subtitle: 'lower_is_better'.tr,
            icon: Icons.speed_outlined,
          ),
        ];

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 1 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isMobile ? 2.6 : 2.2,
          children: cards,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('error_loading_stats'.tr)),
    );
  }
}