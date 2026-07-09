import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payments/emma/anchores/payments_emma_anchors.dart';
import 'package:core/platform/route_constant.dart';
import 'package:payments/go_pro/checkout/components/checkout_components.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:portal/bars/top_app_bar_portal.dart';
import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:lottie/lottie.dart';

class PaymentFailurePage extends ConsumerWidget {
  const PaymentFailurePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.watch(themeColorsProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      layoutTypePc: LayoutTypePc.column,
      appModule: AppModule.back,

      childrenPc:  [
            Expanded(
              child: Container(
                color: theme.checkoutbackground,
                child: Column(
                  children: [
                    TopAppBarPortal(), // Place the TopAppBar at the top
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 400,
                                  height: 400,
                                  child: Lottie.asset(
                                    
                                    'assets/lottie/payment_failure.json',
                                    repeat: false,
                                    animate: true,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'we werent able to process your payment,please try again...'.tr,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Something Went Wrong".tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        color: Colors.lightBlueAccent,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: 400,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: EmmaUiAnchorTarget(
                                          anchorKey: PaymentsEmmaAnchors.tryAgainButton.anchorKey,

                                          spec: PaymentsEmmaAnchors.tryAgainButton,
                                          runtimeMode: PaymentsEmmaAnchors.tryAgainButton.runtimeMode,
                                          tapMode: PaymentsEmmaAnchors.tryAgainButton.tapMode,
                                          child: Failiurepagebutton(
                                            buttonheight: 40,
                                            onTap: () {},
                                            text: 'Try Again'.tr,
                                            hasicon: true,
                                            isborder: true,
                                            backgroundcolor: false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: EmmaUiAnchorTarget(
                                          anchorKey: PaymentsEmmaAnchors.goToDashboardButton.anchorKey,

                                          spec: PaymentsEmmaAnchors.goToDashboardButton,
                                          runtimeMode: PaymentsEmmaAnchors.goToDashboardButton.runtimeMode,
                                          tapMode: PaymentsEmmaAnchors.goToDashboardButton.tapMode,
                                          child: Failiurepagebutton(
                                            buttonheight: 40,
                                            onTap: () {
                                              ref
                                                  .read(navigationService)
                                                  .pushNamedScreen(
                                                      Routes.entry);
                                            },
                                            text: 'Go to Dashboard'.tr,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
            ),
          ],
    );
  }
}
