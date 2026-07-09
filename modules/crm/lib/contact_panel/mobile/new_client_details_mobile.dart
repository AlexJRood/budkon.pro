import 'package:crm/contact_panel/data/client_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class NewClientDetailsMobile extends ConsumerWidget {
  final int clientId;
  const NewClientDetailsMobile({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientData = ref.watch(clientDetailsProvider(clientId));

    return clientData.when(
      loading: () => Center(child: AppLottie.loading(size: 450)),
      error: (err, _) => Center(child: AppLottie.error(size: 450)),
      data: (details) {
        if (details == null) {
          return Center(child: Text('no_client_data_available'.tr));
        }

        return Column(
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomClientTile(
                    title: 'total_profit'.tr,
                    data: "\$${details.totalProfit.toStringAsFixed(2)}",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomClientTile(
                    title:'active_projects'.tr,
                    data: "${details.activeProjects}",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomClientTile(
                    title: 'total_projects'.tr,
                    data: "${details.totalProjects}",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomClientTile(
                    title: 'average_transaction_size'.tr,
                    data: "\$${details.averageTransaction.toStringAsFixed(2)}",
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class CustomClientTile extends ConsumerWidget {
  final String title;
  final String data;

  const CustomClientTile({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.dashboardContainer,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: theme.mobileTextcolor, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            data,
            style: TextStyle(
              color: theme.mobileTextcolor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
