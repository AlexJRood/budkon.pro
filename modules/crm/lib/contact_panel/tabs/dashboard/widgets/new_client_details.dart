import 'package:crm/contact_panel/data/client_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import 'package:intl/intl.dart';

class NewClientDetails extends ConsumerStatefulWidget {
  final int clientId;
  const NewClientDetails({super.key, required this.clientId});

  @override
  ConsumerState<NewClientDetails> createState() => _NewClientDetailsState();
}

class _NewClientDetailsState extends ConsumerState<NewClientDetails> {
  // Format currency nicely (e.g. 1 234 567,89 zł) using Polish locale.
  final NumberFormat _currencyPl = NumberFormat.currency(
    locale: 'pl_PL',
    symbol: 'zł', // change to '$' if you really want USD
    decimalDigits: 2,
  );

  // Format plain integers with grouping (e.g. 1 234 567)
  final NumberFormat _intPl = NumberFormat.decimalPattern('pl_PL');

  String _money(num? value) {
    final v = (value ?? 0);
    return _currencyPl.format(v);
  }

  String _int(num? value) {
    final v = (value ?? 0);
    return _intPl.format(v);
  }

  @override
  Widget build(BuildContext context) {
    final clientData = ref.watch(clientDetailsProvider(widget.clientId));

    return SizedBox(
      height: 348,
      child: clientData.when(
        loading: () => Center(child: AppLottie.loading(size: 450)),
        error: (err, _) => Center(child: AppLottie.error(size: 450)),
        data: (details) {
          if (details == null) {
            return Center(child: Text('no_client_data_available'.tr));
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Customclienttile(
                title: 'total_profit_label'.tr,
                data: _money(details.totalProfit),
              ),
              Customclienttile(
                title: 'active_projects_label'.tr,
                data: _int(details.activeProjects),
              ),
              Customclienttile(
                title: 'total_projects_label'.tr,
                data: _int(details.totalProjects),
              ),
              Customclienttile(
                title: 'average_transaction_label'.tr,
                data: _money(details.averageTransaction),
              ),
            ],
          );
        },
      ),
    );
  }
}

class Customclienttile extends ConsumerWidget {
  final String title;
  final String data;
  const Customclienttile({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: theme.dashboardBoarder),
        color: theme.dashboardContainer,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(color: theme.textColor, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  data,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
