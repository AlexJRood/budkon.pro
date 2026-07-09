import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:reports/reports/dashboard_report/provider/dashboard_provider.dart';
import 'package:core/theme/backgroundgradient.dart';

class ReportsCategoryWidget extends ConsumerWidget {
  final bool isMobile;

  const ReportsCategoryWidget({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    return dashboardDataAsync.when(
      data: (dashboardData) {
        final categories = dashboardData.categoryActivity;

        if (categories.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
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
                'no_category_activity_data_available'.tr,
                style: TextStyle(
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
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
              Text(
                'category_activity'.tr,
                style: TextStyle(
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 16 : 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'active_stock_fresh_supply_and_removals'.tr,
                style: TextStyle(
                  color: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ).withAlpha(220),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = categories[index];
                    final share = (item.sharePct / 100).clamp(0.0, 1.0);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    color: CustomColors.secondaryWidgetTextColor(
                                      context,
                                      ref,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.activeInventory} ${'active'.tr}',
                                style: TextStyle(
                                  color: CustomColors.secondaryWidgetTextColor(
                                    context,
                                    ref,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: share,
                            minHeight: 7,
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.greenAccent,
                            backgroundColor:
                                CustomColors.secondaryWidgetTextColor(
                                  context,
                                  ref,
                                ).withAlpha(35),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoChip(
                                label: 'new_30d'.tr,
                                value: '${item.newListings30d}',
                              ),
                              _InfoChip(
                                label: 'removed_30d'.tr,
                                value: '${item.removedListings30d}',
                              ),
                              _InfoChip(
                                label: 'Share'.tr,
                                value: '${item.sharePct.toStringAsFixed(1)}%',
                              ),
                              _InfoChip(
                                label: 'avg_per_m2'.tr,
                                value:
                                    item.averagePricePerSqm == null
                                        ? '—'
                                        : '${item.currency} ${NumberFormat('#,###').format(item.averagePricePerSqm)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
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
            padding: const EdgeInsets.all(16),
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
                'error_loading_category_activity'.tr,
                style: TextStyle(
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                ),
              ),
            ),
          ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.white),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.white70),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}