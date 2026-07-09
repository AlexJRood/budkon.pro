import 'package:flutter/material.dart';
import 'package:core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/ui/buttons/app_buttons.dart';

import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';

class SettingsPaymentsMobile extends ConsumerWidget {
  const SettingsPaymentsMobile({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);

    return Scaffold(
      backgroundColor: theme.mobileBackground,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: CustomBackgroundGradients.getMainMenuBackground(
            context,
            ref,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar Section
            MobileSettingsAppbar(
              title: "Payments".tr,
              onPressed: () => ref.read(navigationService).beamPop(),
            ),

            // Scrollable Fields Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          "Payment Methods".tr,
                          style: TextStyle(color: theme.mobileTextcolor),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "No saved payment method".tr,
                          style: TextStyle(
                            color: theme.mobileTextcolor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "faster_transactions_by_saving_your_method".tr,
                          style: TextStyle(
                            color: theme.mobileTextcolor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 15),
                        CustomElevatedButton(
                          text: 'add_payment_method_button'.tr,
                          backgroundColor: theme.dashboardContainer,
                          textColor: theme.textColor,
                          onTap: () {
                            ref
                                .read(navigationService)
                                .pushNamedScreen(Routes.addpayment);
                          },
                        ),
                        const SizedBox(height: 30),
                        Text(
                          "transaction_history".tr,
                          style: TextStyle(
                            color: theme.mobileTextcolor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "view_details_of_your_previous_payments_and_invoices".tr,
                          style: TextStyle(
                            color: theme.mobileTextcolor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 15),
                        SettingsButton(
                          isPc: false,
                          buttonheight: 40,
                          onTap: () {},
                          text: "view_history".tr
                        ),
                      ],
                    ),
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
