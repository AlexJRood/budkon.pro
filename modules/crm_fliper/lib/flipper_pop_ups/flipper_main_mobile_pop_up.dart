import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_fliper/flipper_pop_ups/flipper_pop_up_bottom_navigation_bar.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/transaction_pop_up_mobile_screen.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/transaction_sidebar.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/nigotiation_header_widget.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';

class FlipperMainMobilePopUp extends ConsumerWidget {
  const FlipperMainMobilePopUp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final selectedIndex = ref.watch(selectedIndexProvider);

    final List<Widget> screens = [
      const TransactionPopUpMobileScreen(),
      const TransactionPopUpMobileScreen(),
      const TransactionPopUpMobileScreen(),
      const TransactionPopUpMobileScreen(),
    ];

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isTopAppBarOff: true,
      childMobile: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Column(
              spacing: 20.h,
              children: [
                const NegotiationHeaderWidget(isMobile: true),
                Expanded(child: screens[selectedIndex]),
              ],
            ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                decoration: const BoxDecoration(color: Colors.black),
                child: FlipperPopUpBottomNavigationBar(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
