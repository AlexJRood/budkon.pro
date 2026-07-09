import 'package:flutter/foundation.dart';
import 'package:crm/crm/finance/features/pop/status_transaction_pop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:crm/crm/finance/components/side_buttons.dart';

class FinanaceTransactionsButtons extends StatelessWidget {
  final bool isMobile;
  final WidgetRef ref;

  const FinanaceTransactionsButtons({super.key, required this.ref,this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(navigationService);
    final path = nav.currentPath;

    return Align(
      alignment: Alignment.centerRight,
      child: IntrinsicWidth(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 45.h,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ///////// Feature to finish in version 2.0 ////////
                  // SideButtonsDashboard(
                  //   onPressed: () {
                  //     ref
                  //         .read(navigationService)
                  //         .pushNamedScreen(Routes.proPlans);
                  //   },
                  //   icon: Icons.monetization_on_outlined,
                  //   text: 'Plany finansowe'.tr,
                  // ),
                  const SizedBox(width: 10),
                  SideButtonsTransactionFiltersButton(isMobile: isMobile),
                  const SizedBox(width: 10),
                  SideButtonsDashboard(
                    onPressed: () {
                      debugPrint('$path/${Routes.statusPop}');
                      showDialog(
                        context: context,
                        useRootNavigator: true,
                        barrierDismissible: true,
                        barrierColor: Colors.transparent,
                        builder: (_) {
                          return const StatusPopTrasaction(
                            transaction: null,
                            isFilter: false,
                          );
                        },
                      );
                    },
                    icon: Icons.edit,
                    text: 'edit_statuses_button'.tr,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
